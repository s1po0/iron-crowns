import com.ironcrowns.game.Campaign;
public class CampaignTest {
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        Campaign c = new Campaign();
        check(c.valid(), "initial campaign");
        c.gold = 0; check(!c.recruit() && c.soldiers == 14, "no free recruitment");
        check(!c.buyFood() && !c.train() && !c.buyGrain(0), "no negative spending");
        c.gold = 1000; c.soldiers = 29;
        check(c.recruit() && c.soldiers == 30 && c.gold == 990, "partial cap recruitment");
        check(!c.recruit(), "army capacity");
        check(!c.sellGrain(0), "no selling nonexistent cargo");
        int before = c.gold;
        c.buyGrain(0); c.sellGrain(0); check(c.gold < before, "local arbitrage forbidden");
        c.soldiers = 3; c.veterans = 0; c.train(); check(c.veterans == 3, "training clamp");
        c.food = 0; c.advanceDay(); check(c.soldiers == 1 && c.veterans == 1, "starvation conservation");
        c.contract = 1; c.resolve(true, 1, 2);
        check(c.owns(2) && c.holdings() == 1 && c.contract == 2, "victory commit");
        c.resolve(false, 0, -1); check(c.soldiers == 4 && c.valid(), "defeat recovery");
        c.x = Float.NaN; check(!c.valid(), "reject corrupt position");
        for (int seed = 0; seed < 100; seed++) {
            c = new Campaign(); java.util.Random random = new java.util.Random(seed);
            for (int i = 0; i < 1000; i++) {
                switch (random.nextInt(8)) {
                    case 0: c.recruit(); break;
                    case 1: c.buyFood(); break;
                    case 2: c.train(); break;
                    case 3: c.buyGrain(random.nextInt(4)); break;
                    case 4: c.sellGrain(random.nextInt(4)); break;
                    case 5: c.advanceDay(); break;
                    case 6: c.resolve(random.nextBoolean(), random.nextInt(31), random.nextInt(4)-1); break;
                    default: break;
                }
                check(c.valid(), "invariant seed " + seed + " step " + i);
            }
        }
        System.out.println("Campaign tests passed: transactions, defeat recovery, corruption and 100,000 randomized steps.");
    }
}
