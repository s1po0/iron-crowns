package com.ironcrowns.game;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.view.MotionEvent;
import android.view.View;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Random;

/** Offline, native Canvas vertical slice. Virtual viewport: 1000 x 620. */
public final class GameView extends View implements Runnable {
    private static final int BG = Color.rgb(15, 25, 33), PANEL = Color.rgb(24, 38, 47);
    private static final int GOLD = Color.rgb(220, 182, 111), WHITE = Color.rgb(230, 232, 222);
    private static final int MUTED = Color.rgb(153, 172, 171), GREEN = Color.rgb(103, 190, 154);
    private static final int RED = Color.rgb(227, 117, 102), BLUE = Color.rgb(104, 180, 217);
    private final Paint paint = new Paint(3);
    private final ArrayList<Button> buttons = new ArrayList<>();
    private final ArrayList<Unit> units = new ArrayList<>();
    private final ArrayList<Shot> shots = new ArrayList<>();
    private final SharedPreferences prefs;
    private final Random random = new Random(371);
    private Campaign campaign;
    private String screen = "title", order = "HOLD", message = "", result = "";
    private boolean running, paused, help, travel, won, attacking, blocking;
    private float scale = 1, offsetX, offsetY, timer, noticeTime, mapClock;
    private float targetX, targetY, joystickX, joystickY, holdX = 260, holdY = 300;
    private int town = -1, battleTarget = -1, movePointer = -1, attackPointer = -1, blockPointer = -1;
    private int kills, initialFriends, initialEnemies;
    private long previous;
    private Unit hero;
    private final float[][] towns = {{205,320},{425,205},{520,440},{785,325}};
    private final String[] townNames = {"ASHFORD", "NORTHWATCH", "GOLDEN FIELDS", "CROWNKEEP"};
    private final float[][] forts = {{665,180},{815,485},{360,465}};
    private final String[] fortNames = {"FROSTGATE", "RED BASTION", "DUSK TOWER"};

    private static final class Button {
        RectF rect; String label; Runnable action;
        Button(float x,float y,float w,float h,String label,Runnable action) {
            rect=new RectF(x,y,x+w,y+h); this.label=label; this.action=action;
        }
    }
    private static final class Unit {
        float x,y,hp,maxHp,cooldown,flash,angle; boolean ally,archer,player;
        Unit(float x,float y,boolean ally,boolean archer,boolean player,float hp) {
            this.x=x;this.y=y;this.ally=ally;this.archer=archer;this.player=player;this.hp=hp;maxHp=hp;
        }
    }
    private static final class Shot {
        float x,y,tx,ty,life; boolean ally;
        Shot(float x,float y,float tx,float ty,boolean ally) {
            this.x=x;this.y=y;this.tx=tx;this.ty=ty;this.ally=ally;life=.16f;
        }
    }
    public GameView(Context context) {
        super(context); prefs=context.getSharedPreferences("iron_crowns_v1",Context.MODE_PRIVATE);
        campaign=load(); setFocusable(true); setContentDescription("Iron Crowns strategy and battle prototype");
    }
    public void resume() { running=true; previous=System.nanoTime(); removeCallbacks(this); post(this); }
    public void suspend() { running=false; removeCallbacks(this); resetInput(); if(screen.equals("battle")) paused=true; save(); }
    public void back() {
        resetInput();
        if(help) { help=false; return; }
        if(screen.equals("battle")) paused=!paused;
        else if(screen.equals("map") && town>=0) town=-1;
        else if(screen.equals("map")) { save(); screen="title"; }
        else if(screen.equals("result")) screen="map";
        else help=true;
        invalidate();
    }
    private void resetInput() { movePointer=attackPointer=blockPointer=-1; joystickX=joystickY=0; attacking=blocking=false; }
    @Override public void run() {
        if(!running) return;
        long now=System.nanoTime(); float dt=Math.min(.05f,(now-previous)/1_000_000_000f); previous=now;
        if(!help && !paused) update(dt);
        invalidate(); postDelayed(this,16);
    }
    private void notice(String text) { message=text; noticeTime=5; }
    private void update(float dt) {
        timer+=dt; noticeTime=Math.max(0,noticeTime-dt);
        if(screen.equals("map") && travel && town<0) {
            float dx=targetX-campaign.x,dy=targetY-campaign.y,d=(float)Math.hypot(dx,dy);
            if(d<4) { travel=false; arrive(); save(); }
            else {
                float step=Math.min(d,dt*(campaign.food>0?66:38));
                campaign.x+=dx/d*step; campaign.y+=dy/d*step;
                mapClock+=dt;
                if(mapClock>12) { mapClock-=12; notice(campaign.advanceDay()); save(); }
            }
        }
        if(screen.equals("battle")) updateBattle(dt);
    }
    private void arrive() {
        for(int i=0;i<towns.length;i++) if(distance(campaign.x,campaign.y,towns[i][0],towns[i][1])<32) { town=i; return; }
        for(int i=0;i<forts.length;i++) if(distance(campaign.x,campaign.y,forts[i][0],forts[i][1])<32) { town=4+i; return; }
    }
    private static float distance(float x,float y,float a,float b) { return (float)Math.hypot(x-a,y-b); }
    private void startBattle(int target) {
        town=-1; travel=false; battleTarget=target; campaign.seed++; save();
        random.setSeed(campaign.seed); screen="battle"; paused=false; resetInput(); units.clear(); shots.clear();
        kills=0; order="HOLD"; holdX=260;holdY=300;
        hero=new Unit(210,310,true,false,true,180); units.add(hero);
        initialFriends=campaign.soldiers;
        initialEnemies=target>=0?26+target*2:Math.min(26,14+campaign.victories*2);
        for(int i=0;i<initialFriends;i++) units.add(new Unit(260+(i%3)*23,170+(i/3)*27,true,i%4==0,false,i<campaign.veterans?100:65));
        for(int i=0;i<initialEnemies;i++) units.add(new Unit(720+(i%3)*25,160+(i/3)*27,false,i%5==0,false,target>=0?80:60));
        notice("Left stick: move • Hold STRIKE to fight • Orders control your army");
    }
    private int alive(boolean ally) {
        int n=0; for(Unit u:units) if(u.ally==ally&&!u.player&&u.hp>0) n++; return n;
    }
    private void updateBattle(float dt) {
        for(int i=shots.size()-1;i>=0;i--) { shots.get(i).life-=dt; if(shots.get(i).life<=0) shots.remove(i); }
        for(Unit u:units) { u.cooldown=Math.max(0,u.cooldown-dt); u.flash=Math.max(0,u.flash-dt); }
        if(hero.hp>0) {
            hero.x=clamp(hero.x+joystickX*130*dt,30,970); hero.y=clamp(hero.y+joystickY*130*dt,135,490);
            if(joystickX!=0||joystickY!=0) hero.angle=(float)Math.atan2(joystickY,joystickX);
            if(attacking && !blocking && hero.cooldown<=0) {
                hero.cooldown=.48f; hero.flash=.18f;
                Unit nearest=nearest(hero);
                if(nearest!=null && distance(hero.x,hero.y,nearest.x,nearest.y)<65) {
                    hero.angle=(float)Math.atan2(nearest.y-hero.y,nearest.x-hero.x); hit(nearest,42);
                }
            }
        }
        int index=0;
        for(Unit u:units) {
            if(u.hp<=0 || u.player) continue;
            Unit enemy=nearest(u); if(enemy==null) continue;
            float d=distance(u.x,u.y,enemy.x,enemy.y), range=u.archer?170:25;
            float tx=enemy.x,ty=enemy.y;
            boolean defending=u.ally&&!order.equals("CHARGE");
            if(defending && d>range+20) {
                if(order.equals("FOLLOW")&&hero.hp>0) { tx=hero.x+30+(index%4)*19;ty=hero.y-50+(index/4)*18; }
                else { tx=holdX+(index%3)*22; ty=holdY-95+(index/3)*23; }
            }
            if(d<=range && u.cooldown<=0) {
                u.angle=(float)Math.atan2(enemy.y-u.y,enemy.x-u.x);
                u.cooldown=u.archer?1.45f:.85f+random.nextFloat()*.3f;
                float damage=u.archer?12:10+(u.maxHp>70?4:0);
                if(enemy.player&&blocking) damage*=.2f;
                if(enemy.ally&&order.equals("WALL")) damage*=.65f;
                hit(enemy,damage);
                if(u.archer) shots.add(new Shot(u.x,u.y,enemy.x,enemy.y,u.ally));
            } else if(d>range || defending) {
                float dx=tx-u.x,dy=ty-u.y,dist=(float)Math.hypot(dx,dy);
                if(dist>7) {
                    float speed=u.ally&&order.equals("WALL")?32: u.archer?43:54;
                    u.x+=dx/dist*speed*dt;u.y+=dy/dist*speed*dt;u.angle=(float)Math.atan2(dy,dx);
                }
            }
            // Bounded local separation; this small prototype intentionally uses simple O(n²) AI.
            for(Unit other:units) if(other!=u&&other.hp>0) {
                float dx=u.x-other.x,dy=u.y-other.y,dist2=dx*dx+dy*dy;
                if(dist2>0.001f&&dist2<225) { float dist=(float)Math.sqrt(dist2); u.x+=dx/dist*12*dt;u.y+=dy/dist*12*dt; }
            }
            u.x=clamp(u.x,30,970);u.y=clamp(u.y,135,490);index++;
        }
        if(alive(false)==0) finishBattle(true);
        else if(alive(true)==0&&hero.hp<=0) finishBattle(false);
    }
    private Unit nearest(Unit u) {
        Unit closest=null;float best=Float.MAX_VALUE;
        for(Unit other:units) if(other.hp>0&&other.ally!=u.ally) {
            float d=(other.x-u.x)*(other.x-u.x)+(other.y-u.y)*(other.y-u.y);
            if(d<best) {best=d;closest=other;}
        }
        return closest;
    }
    private void hit(Unit u,float damage) { boolean living=u.hp>0;u.hp=Math.max(0,u.hp-damage);u.flash=.13f;if(living&&u.hp==0&&!u.ally) kills++; }
    private void finishBattle(boolean victory) {
        if(!screen.equals("battle")) return;
        won=victory;int survivors=alive(true), lost=initialFriends-survivors;
        boolean bounty=campaign.contract==1&&victory;
        campaign.resolve(victory,survivors,battleTarget);
        result=(victory?"The field is yours.":"Your survivors found safe passage.")+"\n"+
            (initialEnemies-alive(false))+" enemies defeated  •  "+lost+" soldiers lost\n"+
            (victory?(battleTarget>=0?"A new fief pays 18 gold each day.":"Spoils: 65 gold, 10 provisions."):"Ransom: up to 35 gold. Your campaign continues.")+"\n"+
            (bounty?"Roadwarden contract completed: +90 gold.":"Replenish your army before the next engagement.");
        screen="result";paused=false;resetInput();save();
    }
    private static float clamp(float x,float lo,float hi) {return Math.max(lo,Math.min(hi,x));}

    @Override protected void onDraw(Canvas real) {
        super.onDraw(real); real.drawColor(BG);
        scale=Math.min(getWidth()/1000f,getHeight()/620f);
        if(scale<=0) return;
        offsetX=(getWidth()-1000*scale)/2;offsetY=(getHeight()-620*scale)/2;
        real.save();real.translate(offsetX,offsetY);real.scale(scale,scale);buttons.clear();
        if(screen.equals("title")) drawTitle(real);
        else if(screen.equals("map")) drawMap(real);
        else if(screen.equals("battle")) drawBattle(real);
        else drawResult(real);
        if(help) drawHelp(real);
        else if(paused) drawPause(real);
        if(noticeTime>0&&!help&&!paused&&!screen.equals("title")) {
            rect(real,150,105,700,36,Color.argb(235,15,25,33),8);
            text(real,message,500,128,13,WHITE,true);
        }
        real.restore();
    }
    private void text(Canvas c,String s,float x,float y,float size,int color,boolean center) {
        paint.setColor(color);paint.setTextSize(size);paint.setStyle(Paint.Style.FILL);
        paint.setTypeface(Typeface.create("sans-serif",Typeface.NORMAL));paint.setTextAlign(center?Paint.Align.CENTER:Paint.Align.LEFT);
        c.drawText(s,x,y,paint);
    }
    private void title(Canvas c,String s,float x,float y,float size) {
        paint.setColor(GOLD);paint.setTextSize(size);paint.setTextAlign(Paint.Align.LEFT);
        paint.setTypeface(Typeface.create("serif",Typeface.BOLD));paint.setStyle(Paint.Style.FILL);c.drawText(s,x,y,paint);
    }
    private void rect(Canvas c,float x,float y,float w,float h,int color,float radius) {
        paint.setColor(color);paint.setStyle(Paint.Style.FILL);c.drawRoundRect(x,y,x+w,y+h,radius,radius,paint);
    }
    private void line(Canvas c,float x,float y,float tx,float ty,int color,float width) {
        paint.setColor(color);paint.setStrokeWidth(width);c.drawLine(x,y,tx,ty,paint);
    }
    private void circle(Canvas c,float x,float y,float r,int color) {paint.setColor(color);paint.setStyle(Paint.Style.FILL);c.drawCircle(x,y,r,paint);}
    private void button(Canvas c,String label,float x,float y,float w,float h,boolean accent,Runnable action) {
        rect(c,x,y,w,h,accent?GOLD:Color.rgb(42,59,67),8);
        text(c,label,x+w/2,y+h/2+5,14,accent?BG:WHITE,true);
        buttons.add(new Button(x,y,w,h,label,action));
    }
    private void drawTitle(Canvas c) {
        drawLandscape(c);
        rect(c,0,0,1000,620,Color.argb(165,10,20,29),0);
        text(c,"A KINGDOM IS NOT GIVEN. IT IS FORGED.",70,102,13,MUTED,false);
        title(c,"IRON",65,193,78);title(c,"CROWNS",65,270,78);
        line(c,70,300,400,300,GOLD,2);
        text(c,"Lead your company. Trade the roads. Claim the realm.",70,337,17,WHITE,false);
        text(c,"Offline Android prototype  /  0.1.0",70,369,13,MUTED,false);
        button(c,prefs.contains("save")?"CONTINUE CAMPAIGN":"BEGIN CAMPAIGN",70,411,275,54,true,()->{screen="map";town=-1;paused=false;save();});
        button(c,"HOW TO PLAY",70,479,170,50,false,()->help=true);
        button(c,"NEW CAMPAIGN",253,479,170,50,false,()->{screen="reset";});
        text(c,"Original 2D vertical slice • No purchases • No network permissions",70,582,12,MUTED,false);
        // Emblem / fortress vignette.
        circle(c,753,268,125,Color.argb(100,220,182,111));
        castle(c,753,289,3.6f,GOLD);text(c,"THE ASHEN MARCHES",753,439,17,GOLD,true);
    }
    private void drawLandscape(Canvas c) {
        rect(c,0,0,1000,620,Color.rgb(33,54,54),0);
        Random r=new Random(17);
        for(int i=0;i<80;i++) {
            float x=r.nextInt(1000),y=145+r.nextInt(450);
            circle(c,x,y,25+r.nextInt(70),Color.argb(30,104,144,103));
        }
        Path river=new Path();river.moveTo(580,80);river.cubicTo(430,260,740,370,560,620);
        paint.setColor(Color.rgb(42,80,94));paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(22);c.drawPath(river,paint);paint.setStyle(Paint.Style.FILL);
        for(int i=0;i<25;i++) {
            float x=60+r.nextInt(870),y=155+r.nextInt(360);
            if(x>450&&x<630) continue;
            Path tree=new Path();tree.moveTo(x,y-13);tree.lineTo(x-8,y+6);tree.lineTo(x+8,y+6);tree.close();
            paint.setColor(Color.rgb(28,49,44));c.drawPath(tree,paint);
        }
        for(int i=0;i<9;i++) {
            float x=580+i*37,y=155+(i%3)*16;
            Path p=new Path();p.moveTo(x-24,y);p.lineTo(x,y-48);p.lineTo(x+26,y);p.close();
            paint.setColor(Color.rgb(70,83,79));c.drawPath(p,paint);line(c,x,y-45,x+10,y-26,MUTED,2);
        }
    }
    private void castle(Canvas c,float x,float y,float s,int color) {
        rect(c,x-12*s,y-8*s,24*s,20*s,color,0);
        rect(c,x-18*s,y-15*s,9*s,29*s,color,1);rect(c,x+9*s,y-15*s,9*s,29*s,color,1);
        for(int i=0;i<3;i++) {rect(c,x-19*s+i*4*s,y-19*s,3*s,6*s,color,0);rect(c,x+9*s+i*4*s,y-19*s,3*s,6*s,color,0);}
        rect(c,x-4*s,y+2*s,8*s,12*s,BG,3*s);
        line(c,x,y-8*s,x,y-29*s,color,s);line(c,x,y-26*s,x+9*s,y-23*s,color,3*s);
    }
    private void header(Canvas c,String section) {
        rect(c,0,0,1000,92,BG,0);
        title(c,"IRON CROWNS",26,38,25);text(c,section,27,65,11,MUTED,false);
        text(c,"GOLD",293,28,10,MUTED,false);text(c,""+campaign.gold,293,56,23,GOLD,false);
        text(c,"PROVISIONS",393,28,10,MUTED,false);text(c,""+campaign.food,393,56,23,WHITE,false);
        text(c,"COMPANY",522,28,10,MUTED,false);text(c,campaign.soldiers+" / 30",522,56,23,WHITE,false);
        text(c,"RENOWN",669,28,10,MUTED,false);text(c,""+campaign.renown,669,56,23,WHITE,false);
        text(c,"DAY "+campaign.day,785,45,15,GOLD,false);
        button(c,"?",860,21,49,49,false,()->{resetInput();help=true;});
        button(c,"MENU",922,21,65,49,false,()->{resetInput();if(screen.equals("battle"))paused=true;else {save();screen="title";}});
    }
    private void drawMap(Canvas c) {
        drawLandscape(c);
        for(int i=0;i<towns.length-1;i++) line(c,towns[i][0],towns[i][1],towns[i+1][0],towns[i+1][1],Color.rgb(113,109,77),3);
        for(int i=0;i<towns.length;i++) {
            circle(c,towns[i][0],towns[i][1],22,Color.argb(100,220,182,111));castle(c,towns[i][0],towns[i][1],.8f,GOLD);
            text(c,townNames[i],towns[i][0],towns[i][1]+38,12,WHITE,true);
        }
        for(int i=0;i<forts.length;i++) {
            int color=campaign.owns(i)?GREEN:RED;
            castle(c,forts[i][0],forts[i][1],.8f,color);text(c,fortNames[i],forts[i][0],forts[i][1]+36,11,color,true);
        }
        if(travel) {line(c,campaign.x,campaign.y,targetX,targetY,GOLD,2);circle(c,targetX,targetY,5,GOLD);}
        circle(c,campaign.x,campaign.y,18,Color.argb(65,240,220,170));circle(c,campaign.x,campaign.y,9,GOLD);
        line(c,campaign.x,campaign.y,campaign.x,campaign.y-25,WHITE,2);line(c,campaign.x,campaign.y-23,campaign.x+15,campaign.y-19,GOLD,5);
        header(c,"CAMPAIGN / THE ASHEN MARCHES");
        rect(c,0,557,1000,63,BG,0);
        text(c,travel?"ON THE MARCH":"Tap a settlement to travel",25,583,15,WHITE,false);
        text(c,"Fiefs "+campaign.holdings()+" / 3  •  Veterans "+campaign.veterans+"  •  Cargo "+campaign.grain+" / 12",25,605,12,MUTED,false);
        button(c,travel?"STOP":"MAKE CAMP",365,567,145,44,false,()->{if(travel)travel=false;else{notice(campaign.advanceDay());save();}});
        button(c,"HUNT BANDITS",525,567,165,44,false,()->{if(campaign.soldiers<4)notice("Recruit at a settlement first.");else startBattle(-1);});
        button(c,campaign.contract==0?"TAKE CONTRACT":campaign.contract==1?"CONTRACT ACTIVE":"CONTRACT DONE",706,567,190,44,campaign.contract==0,()->{
            if(campaign.contract==0){campaign.contract=1;notice("Roadwarden: win a battle for 90 bonus gold. No time limit.");save();}
            else notice(campaign.contract==1?"Win any battle to claim the Roadwarden bounty.":"You fulfilled the Roadwarden contract.");});
        if(campaign.holdings()==3) {text(c,"SOVEREIGN OF THE MARCHES",500,155,20,GOLD,true);}
        if(town>=0) drawSettlement(c);
    }
    private void drawSettlement(Canvas c) {
        buttons.clear(); rect(c,0,92,1000,528,Color.argb(150,5,12,18),0);
        rect(c,190,154,620,380,PANEL,14);
        boolean fort=town>=4;int id=town-4;
        title(c,fort?fortNames[id]:townNames[town],220,198,27);
        button(c,"CLOSE",700,173,82,46,false,()->town=-1);
        if(fort) {
            boolean owned=campaign.owns(id);
            text(c,owned?"YOUR FIEF • +18 GOLD EACH DAY":"HOSTILE KEEP • "+(26+id*2)+" DEFENDERS",220,240,15,owned?GREEN:RED,false);
            text(c,owned?"Your banner flies above these walls.":"Capture the field outside the keep to claim this fief.",220,281,16,WHITE,false);
            text(c,"Prototype: castle battles use a field arena, not a siege map.",220,311,13,MUTED,false);
            text(c,"Holdings provide income whenever a campaign day passes.",220,341,13,MUTED,false);
            button(c,owned?"COLLECT NEXT DAY / REST":"ATTACK THE GARRISON",220,378,560,52,true,()->{
                if(campaign.owns(id)){notice(campaign.advanceDay());save();}else startBattle(id);
            });
            button(c,"RETURN TO MAP",220,448,560,48,false,()->town=-1);
        } else {
            text(c,"A safe haven for your company. Transactions save immediately.",220,237,14,MUTED,false);
            button(c,"RECRUIT 4 • 40 GOLD",220,260,270,52,true,()->transact(campaign.recruit(),"Recruits joined your company.","Need gold or free space (30 maximum)."));
            button(c,"20 FOOD • 20 GOLD",510,260,270,52,false,()->transact(campaign.buyFood(),"Provisions restocked.","Not enough gold, or stores full."));
            button(c,"TRAIN 4 • 50 GOLD",220,329,270,52,false,()->transact(campaign.train(),"Veterans have stronger armor and attacks.","Need 50 gold and untrained soldiers."));
            button(c,"REST / NEXT DAY",510,329,270,52,false,()->{notice(campaign.advanceDay());save();});
            button(c,"BUY GRAIN • "+campaign.buyPrice(town),220,398,270,52,false,()->transact(campaign.buyGrain(town),"Grain loaded. Sell at another town.","Insufficient gold or cargo full."));
            button(c,"SELL GRAIN • "+campaign.sellPrice(town),510,398,270,52,false,()->transact(campaign.sellGrain(town),"Grain sold.","You have no grain cargo."));
            text(c,"Trade tip: buy in Ashford, sell in Crownkeep. Travel consumes supplies.",220,488,13,GOLD,false);
        }
    }
    private void transact(boolean success,String yes,String no) {notice(success?yes:no);if(success)save();}
    private void drawBattle(Canvas c) {
        rect(c,0,92,1000,435,Color.rgb(59,70,52),0);
        Random r=new Random(65);
        for(int i=0;i<65;i++){float x=r.nextInt(1000),y=130+r.nextInt(365);line(c,x,y,x+5,y-3,Color.rgb(75,86,64),1);}
        line(c,25,130,975,130,Color.rgb(100,103,78),2);line(c,25,501,975,501,Color.rgb(100,103,78),2);
        if(!order.equals("CHARGE")) {
            for(int i=0;i<6;i++) line(c,holdX-15,holdY-100+i*30,holdX+60,holdY-100+i*30,Color.argb(60,105,186,215),1);
        }
        for(Unit u:units) {
            if(u.hp<=0){circle(c,u.x,u.y,5,Color.argb(90,15,20,20));continue;}
            int color=u.flash>0?WHITE:u.player?GOLD:u.ally?BLUE:RED;
            circle(c,u.x+2,u.y+4,u.player?12:9,Color.argb(95,0,0,0));
            circle(c,u.x,u.y,u.player?11:8,color);
            float ax=(float)Math.cos(u.angle),ay=(float)Math.sin(u.angle);
            line(c,u.x+ax*8,u.y+ay*8,u.x+ax*(u.player?24:16),u.y+ay*(u.player?24:16),u.archer?GOLD:WHITE,2);
            if(u.archer) circle(c,u.x,u.y,3,BG);
            if(u.player&&blocking){paint.setColor(BLUE);paint.setStrokeWidth(3);paint.setStyle(Paint.Style.STROKE);c.drawCircle(u.x,u.y,19,paint);paint.setStyle(Paint.Style.FILL);}
            if(u.hp<u.maxHp){rect(c,u.x-10,u.y-17,20,3,BG,0);rect(c,u.x-10,u.y-17,20*u.hp/u.maxHp,3,color,0);}
        }
        for(Shot shot:shots) line(c,shot.x,shot.y,shot.tx,shot.ty,shot.ally?GOLD:RED,1.5f);
        header(c,battleTarget<0?"BATTLE / ROADWARDEN":"BATTLE / "+fortNames[battleTarget]);
        text(c,"ALLIES "+alive(true),32,116,13,BLUE,false);text(c,"ENEMIES "+alive(false),867,116,13,RED,false);
        rect(c,0,520,1000,100,BG,0);
        text(c,hero.hp>0?"COMMANDER "+(int)hero.hp+" / 180":"COMMANDER DOWN • YOUR TROOPS FIGHT ON",215,546,12,hero.hp>0?GOLD:RED,false);
        String[] orders={"HOLD","CHARGE","WALL","FOLLOW"};
        for(int i=0;i<orders.length;i++) {String next=orders[i];button(c,next,213+i*104,560,96,47,order.equals(next),()->{
            order=next;if(next.equals("HOLD")||next.equals("WALL")){holdX=hero.hp>0?hero.x:260;holdY=hero.hp>0?hero.y:300;}
        });}
        circle(c,95,542,54,Color.rgb(39,58,65));circle(c,95+joystickX*35,542+joystickY*35,22,MUTED);
        text(c,"MOVE",95,612,10,MUTED,true);
        circle(c,900,548,49,attacking?WHITE:GOLD);text(c,"STRIKE",900,553,14,BG,true);
        circle(c,774,553,39,blocking?BLUE:Color.rgb(47,69,79));text(c,"BLOCK",774,558,13,WHITE,true);
        button(c,"RETREAT",660,463,112,43,false,()->{paused=true;resetInput();});
    }
    private void drawResult(Canvas c) {
        rect(c,0,0,1000,620,BG,0);
        if(screen.equals("reset")) {
            title(c,"Begin a new chronicle?",160,210,38);
            text(c,"This replaces the local campaign. It cannot be undone.",160,265,19,MUTED,false);
            button(c,"KEEP MY CAMPAIGN",160,335,300,58,false,()->screen="title");
            button(c,"START NEW CAMPAIGN",490,335,320,58,true,()->{campaign=new Campaign();screen="map";town=-1;travel=false;mapClock=0;noticeTime=0;save();});return;
        }
        text(c,"THE CHRONICLE / DAY "+campaign.day,120,140,14,MUTED,false);
        title(c,won?"Victory, captain.":"Battered. Not broken.",120,213,48);
        String[] lines=result.split("\n");for(int i=0;i<lines.length;i++)text(c,lines[i],120,280+i*38,18,i==0?WHITE:MUTED,false);
        text(c,"Company: "+campaign.soldiers+"  •  Gold: "+campaign.gold+"  •  Fiefs: "+campaign.holdings()+" / 3",120,470,18,GOLD,false);
        button(c,"RETURN TO THE MARCHES",120,510,355,58,true,()->{screen="map";noticeTime=0;});
    }
    private void drawPause(Canvas c) {
        buttons.clear();rect(c,0,0,1000,620,Color.argb(210,8,16,23),0);
        title(c,"Battle paused",300,213,42);
        text(c,"Leaving the app preserves your pre-battle campaign checkpoint.",180,273,18,MUTED,false);
        button(c,"RESUME",300,315,400,55,true,()->{paused=false;resetInput();});
        button(c,"RETREAT / ACCEPT LOSSES",300,390,400,55,false,()->finishBattle(false));
        button(c,"HOW TO PLAY",300,465,400,50,false,()->help=true);
    }
    private void drawHelp(Canvas c) {
        buttons.clear();rect(c,0,0,1000,620,Color.argb(248,15,25,33),0);
        title(c,"A captain's field guide",65,78,36);
        String[] lines={
            "YOUR GOAL   Capture all three hostile keeps and unite the Ashen Marches.",
            "TRAVEL   Tap a town or keep. Your company travels there automatically.",
            "PREPARE   Recruit up to 30 soldiers, buy food, and train veterans in towns.",
            "TRADE   Buy grain in Ashford, sell in Crownkeep. Cargo is not army food.",
            "BATTLE   Drag the left stick. Hold STRIKE near an enemy; BLOCK reduces damage.",
            "COMMAND   CHARGE attacks. HOLD anchors at you. WALL defends. FOLLOW escorts.",
            "SURVIVE   Archers fire automatically. Your troops fight even if you fall.",
            "GOVERN   Captured keeps pay 18 gold/day. Travel and resting advance days.",
            "SAVE   Campaign actions autosave. Closed battles restart from before the fight.",
            "PROTOTYPE   2D field combat; no 3D, mounted combat, siege interiors, or multiplayer."
        };
        for(int i=0;i<lines.length;i++)text(c,lines[i],65,127+i*38,16,i%2==0?WHITE:MUTED,false);
        button(c,"UNDERSTOOD",65,535,270,55,true,()->{help=false;resetInput();});
    }

    @Override public boolean onTouchEvent(MotionEvent e) {
        if(scale<=0) return true;
        int action=e.getActionMasked(),idx=e.getActionIndex(),id=e.getPointerId(idx);
        float x=(e.getX(idx)-offsetX)/scale,y=(e.getY(idx)-offsetY)/scale;
        if(action==MotionEvent.ACTION_DOWN||action==MotionEvent.ACTION_POINTER_DOWN) {
            boolean combat=screen.equals("battle")&&!paused&&!help;
            if(combat&&x<185&&y>455&&movePointer<0) {movePointer=id;moveStick(x,y);return true;}
            if(combat&&distance(x,y,900,548)<58) {attackPointer=id;attacking=true;return true;}
            if(combat&&distance(x,y,774,553)<48) {blockPointer=id;blocking=true;return true;}
            for(int i=buttons.size()-1;i>=0;i--) {
                Button b=buttons.get(i);if(b.rect.contains(x,y)){b.action.run();invalidate();return true;}
            }
            if(screen.equals("map")&&!help&&town<0&&y>140&&y<550) {
                targetX=clamp(x,35,965);targetY=clamp(y,145,540);
                for(float[] t:towns)if(distance(x,y,t[0],t[1])<48){targetX=t[0];targetY=t[1];}
                for(float[] f:forts)if(distance(x,y,f[0],f[1])<48){targetX=f[0];targetY=f[1];}
                travel=true;
            }
        } else if(action==MotionEvent.ACTION_MOVE) {
            int pointer=e.findPointerIndex(movePointer);
            if(pointer>=0)moveStick((e.getX(pointer)-offsetX)/scale,(e.getY(pointer)-offsetY)/scale);
        } else if(action==MotionEvent.ACTION_UP||action==MotionEvent.ACTION_POINTER_UP) {
            if(id==movePointer){movePointer=-1;joystickX=joystickY=0;}
            if(id==attackPointer){attackPointer=-1;attacking=false;}
            if(id==blockPointer){blockPointer=-1;blocking=false;}
            if(action==MotionEvent.ACTION_UP)performClick();
        } else if(action==MotionEvent.ACTION_CANCEL) resetInput();
        return true;
    }
    @Override public boolean performClick(){super.performClick();return true;}
    private void moveStick(float x,float y) {
        float dx=(x-95)/44,dy=(y-542)/44,d=(float)Math.hypot(dx,dy);
        joystickX=d>1?dx/d:dx;joystickY=d>1?dy/d:dy;
    }
    private void save() {
        try {
            JSONObject j=new JSONObject(); j.put("version",1);
            j.put("gold",campaign.gold);j.put("food",campaign.food);j.put("soldiers",campaign.soldiers);j.put("veterans",campaign.veterans);
            j.put("day",campaign.day);j.put("renown",campaign.renown);j.put("grain",campaign.grain);j.put("victories",campaign.victories);
            j.put("castles",campaign.castles);j.put("contract",campaign.contract);j.put("x",campaign.x);j.put("y",campaign.y);j.put("seed",campaign.seed);
            String old=prefs.getString("save",null);
            SharedPreferences.Editor editor=prefs.edit();
            if(old!=null)editor.putString("backup",old);
            if(!editor.putString("save",j.toString()).commit())notice("Storage full: campaign could not be saved.");
        } catch(Exception exception) {notice("Save failed. Free device storage and try again.");}
    }
    private Campaign load() {
        for(String key:new String[]{"save","backup"}) {
            try {
                String raw=prefs.getString(key,null);if(raw==null)continue;
                JSONObject j=new JSONObject(raw);if(j.getInt("version")!=1)continue;
                Campaign c=new Campaign();c.gold=j.getInt("gold");c.food=j.getInt("food");c.soldiers=j.getInt("soldiers");c.veterans=j.getInt("veterans");
                c.day=j.getInt("day");c.renown=j.getInt("renown");c.grain=j.getInt("grain");c.victories=j.getInt("victories");
                c.castles=j.getInt("castles");c.contract=j.getInt("contract");c.x=(float)j.getDouble("x");c.y=(float)j.getDouble("y");c.seed=j.getInt("seed");
                if(c.valid())return c;
            } catch(Exception ignored) { /* Try the last checkpoint; never crash on malformed save data. */ }
        }
        return new Campaign();
    }
}
