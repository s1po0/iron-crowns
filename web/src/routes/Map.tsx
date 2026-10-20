import WorldMap from "../components/2d/WorldMap";
import { useGame } from "../game/engine/store";
import { count, strength, upkeep, townAt } from "../game/engine/simulation";
import { factions } from "../game/data/world";
import { t, num } from "../i18n";
import {
  Crown,
  Flag,
  ArrowUpLeft,
  MapPin,
  Shield,
  Swords,
  Compass,
  Coins,
} from "lucide-react";
import { Link } from "@tanstack/react-router";
export default function MapPage() {
  const { state, started, start, hasSave, authReady } = useGame(),
    town = townAt(state);
  return (
    <div className="map-layout">
      <section className="world-panel">
        <div className="panel-heading">
          <div>
            <span className="eyebrow">{t.chapter}</span>
            <h1>{t.overview}</h1>
            <p>{t.overviewSub}</p>
          </div>
          <span className="outlined-badge">
            <Compass size={14} />
            {t.season} • {num(state.day)}
          </span>
        </div>
        <WorldMap />
        <footer className="world-footer">
          <span>{t.factionCount}</span>
          <span>
            <span className="live-dot" />
            {state.destination ? t.traveling : t.paused}
          </span>
        </footer>
      </section>
      <aside className="journey-panel">
        {!started ? (
          <div className="welcome-card">
            <div className="crest">
              <Crown size={35} />
            </div>
            <span className="eyebrow">{t.journey}</span>
            <h2>{t.welcome}</h2>
            <p>{t.intro}</p>
            {hasSave && (
              <button
                className="primary wide"
                disabled={!authReady}
                onClick={() => start(false)}
              >
                {t.continue}
                <ArrowUpLeft size={17} />
              </button>
            )}
            <button
              className={hasSave ? "secondary wide" : "primary wide"}
              disabled={!authReady}
              onClick={() => {
                if (!hasSave || confirm(t.resetConfirm)) start(true);
              }}
            >
              {t.newGame}
              <ArrowUpLeft size={17} />
            </button>
            <small>{t.authHint}</small>
          </div>
        ) : (
          <div className="hero-card">
            <div className="hero-banner">
              <div className="crest">
                <Shield size={36} />
              </div>
            </div>
            <div className="hero-details">
              <span className="eyebrow">{t.heroTitle}</span>
              <h2>{state.name}</h2>
              <span className="level-pill">
                {t.level} {num(state.level)}
              </span>
              <div className="stat-row">
                <div>
                  <Swords size={18} />
                  <b>{num(strength(state))}</b>
                  <small>{t.strength}</small>
                </div>
                <div>
                  <Flag size={18} />
                  <b>{num(count(state))}</b>
                  <small>{t.troops}</small>
                </div>
                <div>
                  <Coins size={18} />
                  <b>{num(upkeep(state))}</b>
                  <small>{t.upkeep}</small>
                </div>
              </div>
              <Link to="/party" className="text-link">
                {t.party}
                <ArrowUpLeft size={16} />
              </Link>
            </div>
          </div>
        )}
        <div className="faction-card">
          <div className="section-label">
            <Flag size={16} />
            {t.kingdoms}
          </div>
          {factions.map((f) => (
            <div key={f.id} className="faction-row">
              <span
                className="faction-shield"
                style={{ color: f.color, background: f.color + "1c" }}
              >
                <Crown size={18} />
              </span>
              <div>
                <b>{t.factionNames[f.id]}</b>
                <small>
                  {num(2)} {t.towns} • {num(3)} {t.villages}
                </small>
              </div>
              <span className="faction-dot" style={{ background: f.color }} />
            </div>
          ))}
        </div>
        <div className="location-card">
          <MapPin size={20} />
          <div>
            <small>{town ? t.nearby : t.destination}</small>
            <b>{town ? t.settlementNames[town.id] : t.journey}</b>
          </div>
          <Link to="/market" aria-label={t.market}>
            <ArrowUpLeft size={20} />
          </Link>
        </div>
      </aside>
    </div>
  );
}
