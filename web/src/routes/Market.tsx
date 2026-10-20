import { useGame } from "../game/engine/store";
import { goods, type Good } from "../game/data/goods";
import { townAt, price, trade, unload } from "../game/engine/simulation";
import { t, num } from "../i18n";
import {
  Wheat,
  Trees,
  Anvil,
  Scroll,
  ArrowDownLeft,
  ArrowUpRight,
  MapPin,
} from "lucide-react";
import { Link } from "@tanstack/react-router";
const icons = { grain: Wheat, wood: Trees, iron: Anvil, cloth: Scroll };
export default function Market() {
  const { state, update, started } = useGame(),
    town = townAt(state);
  return (
    <div className="page">
      <div className="page-title">
        <span className="eyebrow">{t.exchange}</span>
        <h1>
          {t.market}
          {town && (
            <span className="title-secondary">
              {" "}
              / {t.settlementNames[town.id]}
            </span>
          )}
        </h1>
        <p>{t.marketHint}</p>
      </div>
      {!town && (
        <div className="notice">
          <MapPin size={18} />
          {t.marketHint}
          <Link to="/">{t.map}</Link>
        </div>
      )}
      <div className="goods-grid">
        {(Object.keys(goods) as Good[]).map((g) => {
          const Icon = icons[g],
            buy = town ? price(state, town.id, g) : goods[g].price,
            sell = town ? price(state, town.id, g, false) : 0;
          return (
            <section key={g} className="good-card">
              <div className="good-illustration">
                <Icon size={60} strokeWidth={1} />
                <span className="corner-mark">✦</span>
              </div>
              <div className="good-body">
                <h2>{t.goodNames[g]}</h2>
                <div className="good-stats">
                  <span>
                    {t.inventory}
                    <b>{num(state.cargo[g])}</b>
                  </span>
                  <span>
                    {t.supply}
                    <b>{town ? num(state.supplies[town.id][g]) : "—"}</b>
                  </span>
                </div>
                <div className="trade-actions">
                  <button
                    className="primary"
                    disabled={
                      !started ||
                      !town ||
                      !!state.destination ||
                      state.resources.gold < buy ||
                      (town && state.supplies[town.id][g] === 0)
                    }
                    onClick={() =>
                      town && update((s) => trade(s, town.id, g, true))
                    }
                  >
                    <ArrowDownLeft size={16} />
                    {t.buy} {num(buy)}
                  </button>
                  <button
                    className="secondary"
                    disabled={
                      !started ||
                      !town ||
                      !!state.destination ||
                      state.cargo[g] === 0
                    }
                    onClick={() =>
                      town && update((s) => trade(s, town.id, g, false))
                    }
                  >
                    <ArrowUpRight size={16} />
                    {t.sell} {num(sell)}
                  </button>
                  {"resource" in goods[g] && (
                    <button
                      className="text-link"
                      disabled={!started || state.cargo[g] === 0}
                      onClick={() => update((s) => unload(s, g))}
                    >
                      {t.unload}
                    </button>
                  )}
                </div>
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
