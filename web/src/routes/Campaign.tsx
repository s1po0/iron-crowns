import { useGame } from "../game/engine/store";
import { t, num } from "../i18n";
import {
  skills,
  equipment,
  type Item,
  difficulties,
} from "../game/data/progression";
import {
  train,
  buyEquipment,
  equip,
  diplomacy,
  atWar,
  converse,
  offers,
  acceptContract,
  claimContracts,
  setDifficulty,
  atTown,
} from "../game/engine/campaign";
import { fill } from "../game/engine/content";
import { getWorld } from "../game/engine/worldgen";
import { move, strength } from "../game/engine/simulation";
export function Difficulty() {
  const { state, update, started } = useGame();
  return (
    <fieldset className="campaign-options">
      <legend>{t.difficulty}</legend>
      <p className="muted">{t.difficultyHelp}</p>
      {(Object.keys(difficulties) as (keyof typeof difficulties)[]).map((d) => (
        <button
          key={d}
          className={
            state.campaign.difficulty === d ? "secondary active" : "secondary"
          }
          aria-pressed={state.campaign.difficulty === d}
          disabled={
            !started ||
            state.day !== 1 ||
            !!state.destination ||
            !!state.victories ||
            !!state.campaign.completed
          }
          onClick={() => update((s) => setDifficulty(s, d))}
        >
          {t.difficultyNames[d]}
        </button>
      ))}
    </fieldset>
  );
}
export default function Campaign() {
  const { state: s, update, started } = useGame(),
    c = s.campaign,
    town = atTown(s),
    available = offers(s),
    locked = !started || !!c.end || s.battle !== null || !!s.result;
  return (
    <div className="campaign-page">
      <header>
        <h1>{t.campaign}</h1>
        <p>{t.victoryHelp}</p>
        <p>
          {t.strength}: {num(strength(s))} • {t.victoryCount}:{" "}
          {num(s.victories)} • {t.completedContracts}: {num(c.completed)}
        </p>
      </header>
      <div className="campaign-grid">
        <section className="campaign-card">
          <h2>{t.skillsTitle}</h2>
          <p>{t.skillHelp}</p>
          <strong>
            {t.points}: {num(c.points)}
          </strong>
          {skills.map((skill) => (
            <div className="campaign-row" key={skill}>
              <span>
                {t.skillNames[skill]} {num(c.skills[skill])}/١٠
              </span>
              <button
                className="secondary"
                disabled={locked || c.points < 1 || c.skills[skill] >= 10}
                onClick={() => update((s) => train(s, skill))}
              >
                {t.trainSkill}
              </button>
            </div>
          ))}
          <Difficulty />
        </section>
        <section className="campaign-card">
          <h2>{t.equipmentTitle}</h2>
          <p>{t.gearHelp}</p>
          {(Object.keys(equipment) as Item[]).map((id) => {
            const d = equipment[id],
              owned = c.inventory.includes(id),
              worn = c.equipped[d.slot] === id;
            return (
              <div className="campaign-row" key={id}>
                <span>
                  {t.itemNames[id]} <small>+{num(d.bonus * 100)}٪</small>
                </span>
                <button
                  className="secondary"
                  aria-pressed={worn}
                  disabled={
                    locked ||
                    (!owned &&
                      (!town ||
                        atWar(s, town.faction) ||
                        !!s.destination ||
                        s.resources.gold < d.price))
                  }
                  onClick={() =>
                    update((s) => (owned ? equip(s, id) : buyEquipment(s, id)))
                  }
                >
                  {owned
                    ? worn
                      ? t.unequip
                      : t.equip
                    : `${t.buy} ${num(d.price)}`}
                </button>
              </div>
            );
          })}
        </section>
        <section className="campaign-card">
          <h2>{t.diplomacy}</h2>
          <p>{t.relationsHelp}</p>
          {t.factionNames.map((name, f) => (
            <div className="campaign-row" key={f}>
              <span>
                {name}
                <small>
                  {atWar(s, f) ? t.war : t.peace} • {num(c.relations[f])}
                </small>
              </span>
              <button
                className="secondary"
                disabled={locked || (atWar(s, f) && s.resources.gold < 150)}
                onClick={() => update((s) => diplomacy(s, f, !atWar(s, f)))}
              >
                {atWar(s, f) ? t.makePeace : t.declareWar}
              </button>
            </div>
          ))}
        </section>
        <section className="campaign-card">
          <h2>{t.tavern}</h2>
          <p>{t.contractHelp}</p>
          <div className="campaign-actions">
            {(["tavern", "rumors", "lords"] as const).map((kind, i) => (
              <button
                key={kind}
                className="secondary"
                disabled={
                  locked ||
                  !town ||
                  !!s.destination ||
                  (!!town && atWar(s, town.faction))
                }
                onClick={() => update((s) => converse(s, kind))}
              >
                {[t.talk, t.rumor, t.lord][i]}
              </button>
            ))}
          </div>
          {!town && <p>{t.marketHint}</p>}
          {available.map((o) => (
            <article className="contract" key={o.id}>
              <p>{fill(o.entry.text, o.ctx.values)}</p>
              <button
                className="secondary"
                disabled={locked || c.contracts.length >= 3}
                onClick={() => update((s) => acceptContract(s, o.id))}
              >
                {t.acceptContract}
              </button>
            </article>
          ))}
        </section>
        <section className="campaign-card">
          <h2>{t.contractsTitle}</h2>
          {!c.contracts.length && <p>{t.noContracts}</p>}
          {c.contracts.map((q) => (
            <article className="contract" key={q.id}>
              <h3>
                {t.questTypes[q.type]} • {t.settlementNames[q.target]}
              </h3>
              <p>{q.text}</p>
              <small>
                {t.deadline}: {num(q.deadline)}
              </small>
              <button
                className="secondary"
                disabled={locked}
                onClick={() =>
                  update((s) =>
                    move(
                      s,
                      q.type === "hunt"
                        ? (s.enemies
                            .filter((e) => e.alive && e.kind === "bandit")
                            .sort(
                              (a, b) =>
                                Math.hypot(a.x - s.hero.x, a.y - s.hero.y) -
                                Math.hypot(b.x - s.hero.x, b.y - s.hero.y),
                            )[0] ?? s.hero)
                        : getWorld(s.worldSeed).settlements[q.target],
                    ),
                  )
                }
              >
                {t.travelTo}
              </button>
            </article>
          ))}
          <button
            className="secondary"
            disabled={locked || !c.contracts.length}
            onClick={() => update(claimContracts)}
          >
            {t.claimContracts}
          </button>
        </section>
        <section className="campaign-card" aria-live="polite">
          <h2>{t.journal}</h2>
          {c.memory.log.length ? (
            c.memory.log.map((line, i) => (
              <p className="journal-line" key={`${i}:${line}`}>
                {line}
              </p>
            ))
          ) : (
            <p>{t.noLines}</p>
          )}
        </section>
      </div>
    </div>
  );
}
