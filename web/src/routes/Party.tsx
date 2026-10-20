import { useGame } from "../game/engine/store";
import { units, type Unit } from "../game/data/units";
import {
  count,
  strength,
  upkeep,
  recruit,
  townAt,
} from "../game/engine/simulation";
import { t, num } from "../i18n";
import {
  Shield,
  Swords,
  Crosshair,
  PersonStanding,
  Flag,
  Plus,
} from "lucide-react";
const icons = {
  peasant: PersonStanding,
  spearman: Flag,
  archer: Crosshair,
  swordsman: Swords,
  cavalry: Shield,
};
export default function Party() {
  const { state, update, started } = useGame(),
    town = townAt(state);
  return (
    <div className="page">
      <div className="page-title">
        <span className="eyebrow">{t.roster}</span>
        <h1>{t.party}</h1>
        <p>{t.recruitHint}</p>
      </div>
      <div className="summary-grid">
        {[
          [t.troops, count(state)],
          [t.strength, strength(state)],
          [t.upkeep, upkeep(state)],
        ].map(([label, n]) => (
          <div className="summary-card" key={label}>
            <span>{label}</span>
            <b>{num(Number(n))}</b>
          </div>
        ))}
      </div>
      <section className="table-card">
        <div className="section-label">
          {t.tavern}
          {town && <span className="tag">{t.settlementNames[town.id]}</span>}
        </div>
        {(Object.keys(units) as Unit[]).map((u) => {
          const Icon = icons[u];
          return (
            <div className="unit-row" key={u}>
              <div className="unit-icon">
                <Icon size={26} />
              </div>
              <div className="unit-name">
                <b>{t.unitNames[u]}</b>
                <small>
                  {t.strength}: {num(units[u].strength)} · {t.upkeep}:{" "}
                  {num(units[u].upkeep)}
                </small>
              </div>
              <strong>{num(state.party[u])}</strong>
              <button
                className="secondary"
                disabled={
                  !started ||
                  !town ||
                  !!state.destination ||
                  state.resources.gold < units[u].cost
                }
                onClick={() => update((s) => recruit(s, u))}
              >
                <Plus size={15} />
                {t.recruit} <span className="gold">{num(units[u].cost)}</span>
              </button>
            </div>
          );
        })}
      </section>
    </div>
  );
}
