package com.ironcrowns.game;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;

public final class MainActivity extends Activity {
    private GameView game;
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        game = new GameView(this);
        setContentView(game);
    }
    @Override protected void onPause() { super.onPause(); game.suspend(); }
    @Override protected void onResume() { super.onResume(); if (game != null) game.resume(); }
    @Override public void onBackPressed() { game.back(); }
}
