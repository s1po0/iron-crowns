import { lazy, Suspense, useState } from "react";
import { useGame } from "../game/engine/store";
import { buildings, type Building } from "../game/data/buildings";
import { build, canBuild, advanceDay } from "../game/engine/simulation";
import { t, num } from "../i18n";
import {
  Castle as CastleIcon,
  Hammer,
  Heart,
  Sun,
  Coins,
  Trees,
  Mountain,
} from "lucide-react";
import { SceneBoundary, Empty } from "../components/UI";
const CastleScene = lazy(() => import("../components/3d/CastleScene"));
export default function Castle() {
  const { state, update, started } = useGame(),
    [chosen, setChosen] = useState<Building>("woodcutter"),
    [cell, setCell] = useState<{ x: number; z: number } | null>(null);
  return (
    <div className="castle-layout">
      <section className="castle-panel">
        <div className="panel-heading">
          <div>
            <span className="eyebrow">{t.building}</span>
            <h1>{t.castle}</h1>
            <p>{t.castleHint}</p>
          </div>
          <CastleIcon size={30} />
        </div>
        <div className="castle-viewport">
          <SceneBoundary>
            <Suspense fallback={<Empty>{t.loading}</Empty>}>
              <CastleScene chosen={chosen} cell={cell} onCell={setCell} />
            </Suspense>
          </SceneBoundary>
          <div className="scene-label">
            <span className="live-dot" />
            {t.buildHint}
          </div>
          {cell && (
            <div className="build-confirm">
              <span>
                {t.buildingNames[chosen]} • {num(cell.x + 1)}، {num(cell.z + 1)}
              </span>
              <button
                className="primary"
                disabled={!started || !canBuild(state, chosen, cell.x, cell.z)}
                onClick={() => {
                  update((s) => build(s, chosen, cell.x, cell.z));
                  setCell(null);
                }}
              >
                {canBuild(state, chosen, cell.x, cell.z)
                  ? t.confirmBuild
                  : t.invalidBuild}
              </button>
            </div>
          )}
        </div>
        <div className="building-palette">
          {(Object.keys(buildings) as Building[]).map((b) => (
            <button
              key={b}
              className={
                chosen === b ? "building-choice active" : "building-choice"
              }
              onClick={() => setChosen(b)}
            >
              <CastleIcon size={20} />
              <span>{t.buildingNames[b]}</span>
            </button>
          ))}
        </div>
      </section>
      <aside className="castle-sidebar">
        <div className="faction-card">
          <div className="section-label">
            <Hammer size={17} />
            {t.buildingNames[chosen]}
          </div>
          <p className="muted">{t.buildingDescriptions[chosen]}</p>
          <div className="cost-row">
            <span>
              <Trees size={15} />
              {num(buildings[chosen].wood)}
            </span>
            <span>
              <Mountain size={15} />
              {num(buildings[chosen].stone)}
            </span>
            <span>
              <Coins size={15} />
              {num(buildings[chosen].gold)}
            </span>
          </div>
          <small className="muted">
            {t.production}:{" "}
            {Object.entries(buildings[chosen].production)
              .map(([k, n]) => `${t[k as "wood"]} +${num(n)}`)
              .join(" / ") || "—"}
          </small>
        </div>
        <div className="faction-card">
          <div className="section-label">
            <Heart size={17} />
            {t.popularity}
            <b className="gold">{num(state.popularity)}٪</b>
          </div>
          <div className="meter">
            <span style={{ width: `${state.popularity}%` }} />
          </div>
          <p className="muted">{t.economy}</p>
          <label>{t.taxes}</label>
          <div className="segmented">
            {t.taxNames.map((name, i) => (
              <button
                key={i}
                className={state.tax === i ? "active" : ""}
                disabled={!started}
                onClick={() =>
                  update((s) => ({ ...s, tax: i, revision: s.revision + 1 }))
                }
              >
                {name}
              </button>
            ))}
          </div>
          <div className="toggle-row">
            <span>{t.ale}</span>
            <button
              className={state.ale ? "switch on" : "switch"}
              role="switch"
              aria-checked={state.ale}
              aria-label={t.ale}
              disabled={!started}
              onClick={() =>
                update((s) => ({ ...s, ale: !s.ale, revision: s.revision + 1 }))
              }
            >
              <span />
            </button>
          </div>
          <small className="muted">{t.aleHint}</small>
          <button
            className="secondary wide"
            disabled={!started}
            onClick={() => update(advanceDay)}
          >
            <Sun size={16} />
            {t.wait}
          </button>
        </div>
      </aside>
    </div>
  );
}
