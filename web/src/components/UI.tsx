import { Component, type ReactNode, lazy, Suspense, useEffect } from "react";
import { Crown, X, Swords, ShieldCheck, Coins, Users } from "lucide-react";
import { t, num } from "../i18n";
import { useGame } from "../game/engine/store";
import { resolveBattle } from "../game/engine/simulation";
import { rules } from "../game/data/world";
export function Modal({
  title,
  children,
  onClose,
}: {
  title: string;
  children: ReactNode;
  onClose?: () => void;
}) {
  return (
    <div className="modal-backdrop">
      <section
        className="modal"
        role="dialog"
        aria-modal="true"
        aria-label={title}
      >
        <header>
          <h2>{title}</h2>
          {onClose && (
            <button aria-label={t.close} onClick={onClose}>
              <X size={20} />
            </button>
          )}
        </header>
        {children}
      </section>
    </div>
  );
}
export function Empty({ children }: { children: ReactNode }) {
  return (
    <div className="empty">
      <Crown size={40} />
      <p>{children}</p>
    </div>
  );
}
export class SceneBoundary extends Component<
  { children: ReactNode },
  { error: boolean }
> {
  state = { error: false };
  static getDerivedStateFromError() {
    return { error: true };
  }
  render() {
    return this.state.error ? (
      <Empty>{t.webglError}</Empty>
    ) : (
      this.props.children
    );
  }
}
const BattleScene = lazy(() => import("./3d/BattleScene"));
export function BattleOverlay() {
  const { state, update, started } = useGame();
  useEffect(() => {
    if (!started || state.battle === null) return;
    const timer = setTimeout(
      () => update(resolveBattle),
      rules.battleSeconds * 1000,
    );
    return () => clearTimeout(timer);
  }, [state.battle, started]);
  if (!started || (state.battle === null && !state.result)) return null;
  return (
    <Modal
      title={
        state.result ? (state.result.won ? t.victory : t.defeat) : t.battle
      }
    >
      {state.result ? (
        <>
          <div className="battle-emblem">
            <ShieldCheck size={60} />
          </div>
          <div className="stat-row">
            <div>
              <Users />
              <b>{num(state.result.losses)}</b>
              <small>{t.losses}</small>
            </div>
            <div>
              <Coins />
              <b>{num(state.result.loot)}</b>
              <small>{t.loot}</small>
            </div>
          </div>
          <button
            className="primary wide"
            onClick={() =>
              update((s) => ({ ...s, result: null, revision: s.revision + 1 }))
            }
          >
            {t.returnMap}
          </button>
        </>
      ) : (
        <>
          <p>{state.campaign.memory.log[0]}</p>
          <div className="battle-view">
            <SceneBoundary>
              <Suspense fallback={<Empty>{t.loading}</Empty>}>
                <BattleScene />
              </Suspense>
            </SceneBoundary>
          </div>
          <p className="muted">
            <Swords size={16} />
            {t.battleHint}
          </p>
          <div
            className="battle-progress"
            style={{ animationDuration: `${rules.battleSeconds}s` }}
          />
        </>
      )}
    </Modal>
  );
}
