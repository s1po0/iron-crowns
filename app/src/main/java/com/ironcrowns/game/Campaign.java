package com.ironcrowns.game;

/** Platform-independent campaign rules. All transactions validate before mutation. */
public final class Campaign {
    public int gold = 180, food = 40, soldiers = 14, veterans = 0, day = 1, renown = 0;
    public int grain = 0, victories = 0, castles = 0, contract = 0;
    public float x = 230, y = 320;
    public int seed = 371;
    public boolean owns(int id) { return (castles & (1 << id)) != 0; }
    public int holdings() { return Integer.bitCount(castles); }
    public boolean recruit() {
        if (gold < 40 || soldiers >= 30) return false;
        int count = Math.min(4, 30 - soldiers);
        gold -= count * 10; soldiers += count; return true;
    }
    public boolean buyFood() {
        if (gold < 20 || food > 480) return false;
        gold -= 20; food += 20; return true;
    }
    public boolean train() {
        if (gold < 50 || veterans >= soldiers) return false;
        gold -= 50; veterans = Math.min(soldiers, veterans + 4); return true;
    }
    public int buyPrice(int town) { return town == 0 ? 12 : town == 2 ? 15 : 18; }
    public int sellPrice(int town) { return town == 3 ? 23 : town == 1 ? 20 : 9; }
    public boolean buyGrain(int town) {
        if (gold < buyPrice(town) || grain >= 12) return false;
        gold -= buyPrice(town); grain++; return true;
    }
    public boolean sellGrain(int town) {
        if (grain <= 0) return false;
        gold += sellPrice(town); grain--; return true;
    }
    public String advanceDay() {
        day++;
        int income = holdings() * 18;
        int wages = soldiers / 3 + veterans / 2;
        gold = Math.max(0, gold + income - wages);
        food -= Math.max(2, soldiers / 4);
        if (food < 0) {
            food = 0; soldiers = Math.max(0, soldiers - 2);
            veterans = Math.min(veterans, soldiers);
            return "Supplies exhausted. Two soldiers deserted. Visit a settlement.";
        }
        return "Day " + day + " • wages " + wages + " • fief income " + income;
    }
    public void resolve(boolean won, int survivors, int target) {
        soldiers = Math.max(0, Math.min(soldiers, survivors));
        veterans = Math.min(veterans, soldiers);
        if (won) {
            victories++; renown += target >= 0 ? 30 : 12;
            gold += target >= 0 ? 160 : 65; food += 10;
            if (target >= 0) castles |= 1 << target;
            if (contract == 1) { gold += 90; renown += 10; contract = 2; }
        } else {
            gold = Math.max(0, gold - 35);
        }
        // Defeat has a recovery path: a small rescue party, never a dead campaign.
        if (soldiers < 4) { soldiers = 4; gold = Math.max(gold, 40); }
        advanceDay();
    }
    public boolean valid() {
        return gold >= 0 && gold <= 10000000 && food >= 0 && food <= 1000000 &&
            soldiers >= 0 && soldiers <= 30 && veterans >= 0 && veterans <= soldiers &&
            day > 0 && day < 1000000 && grain >= 0 && grain <= 12 &&
            castles >= 0 && castles <= 7 && contract >= 0 && contract <= 2 &&
            Float.isFinite(x) && Float.isFinite(y) && x >= 35 && x <= 965 && y >= 130 && y <= 550;
    }
}
