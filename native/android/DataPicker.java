package com.ironcrowns.data;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** Reads the URI grant itself; never guesses a filesystem path from a document ID. */
public final class DataPicker extends GodotPlugin {
    private static final int REQUEST = 6306;
    private volatile boolean active;
    private long expectedBytes;
    public DataPicker(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "DataPicker"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("data_selected", String.class),
            new SignalInfo("data_error", String.class),
            new SignalInfo("data_progress", Integer.class)));
    }
    @UsedByGodot public void selectData(long bytes) {
        if (active) return;
        if (bytes<=0 || bytes>256L*1024*1024) {
            emitSignal("data_error", "Invalid expected Data size."); return;
        }
        expectedBytes=bytes;
        active=true;
        runOnUiThread(() -> {
            try {
                Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("*/*");
                intent.putExtra(Intent.EXTRA_LOCAL_ONLY,true);
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                getActivity().startActivityForResult(intent,REQUEST);
            } catch (Exception error) {
                active=false;
                emitSignal("data_error","Cannot open Android's document picker.");
            }
        });
    }
    @Override public void onMainActivityResult(int requestCode,int resultCode,Intent data) {
        if (requestCode!=REQUEST) return;
        if (resultCode!=Activity.RESULT_OK || data==null || data.getData()==null) {
            active=false;
            emitSignal("data_error","Selection cancelled. Import the matching Data file to continue.");
            return;
        }
        final Uri uri=data.getData();
        final Activity activity=getActivity();
        // The transient URI grant remains valid while this activity copies the file.
        // Hash verification and atomic promotion are performed by the core game.
        new Thread(() -> {
            File partial=new File(activity.getFilesDir(),"content/selected-data.part");
            try {
                File folder=partial.getParentFile();
                if (!folder.isDirectory() && !folder.mkdirs()) throw new Exception("Storage unavailable");
                try (InputStream input=activity.getContentResolver().openInputStream(uri);
                     FileOutputStream output=new FileOutputStream(partial,false)) {
                    if (input==null) throw new Exception("Unreadable document");
                    byte[] buffer=new byte[65536];
                    long total=0;
                    int previous=-1;
                    int count;
                    while ((count=input.read(buffer))!=-1) {
                        total+=count;
                        if (total>expectedBytes) throw new Exception("Wrong Data size");
                        output.write(buffer,0,count);
                        int percent=(int)(total*100/expectedBytes);
                        if (percent!=previous) {
                            emitSignal("data_progress",percent);
                            previous=percent;
                        }
                    }
                    output.getFD().sync();
                    if (total!=expectedBytes) throw new Exception("Wrong Data size");
                }
                active=false;
                emitSignal("data_selected",partial.getAbsolutePath());
            } catch (Exception error) {
                partial.delete();
                active=false;
                emitSignal("data_error","Data import failed: "+error.getMessage()+". Check the file and free storage.");
            }
        },"IronDataImport").start();
    }
}
