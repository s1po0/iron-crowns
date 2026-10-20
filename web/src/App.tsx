import { Outlet, Link, useRouterState } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import {
  Crown,
  Map,
  Castle,
  Users,
  Store,
  Trophy,
  Settings,
  Coins,
  Trees,
  Mountain,
  Wheat,
  Sun,
  LogIn,
  Cloud,
  Pause,
  Play,
  HelpCircle,
  LogOut,
  Save,
  Check,
  ChevronLeft,
} from "lucide-react";
import { useGame } from "./game/engine/store";
import { supabase } from "./lib/supabase";
import { t, num } from "./i18n";
import { BattleOverlay, Modal } from "./components/UI";
import type { Quality } from "./game/data/world";
const navigation = [
  { to: "/", label: t.map, icon: Map },
  { to: "/castle", label: t.castle, icon: Castle },
  { to: "/party", label: t.party, icon: Users },
  { to: "/market", label: t.market, icon: Store },
] as const;
function Auth({ close }: { close: () => void }) {
  const [signup, setSignup] = useState(false),
    [email, setEmail] = useState(""),
    [password, setPassword] = useState(""),
    [busy, setBusy] = useState(false),
    [message, setMessage] = useState("");
  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMessage("");
    try {
      const { error } = signup
        ? await supabase.auth.signUp({
            email,
            password,
            options: { emailRedirectTo: location.origin },
          })
        : await supabase.auth.signInWithPassword({ email, password });
      if (error) setMessage(t.authError);
      else if (signup) setMessage(t.confirmEmail);
      else close();
    } catch {
      setMessage(t.authError);
    } finally {
      setBusy(false);
    }
  }
  return (
    <Modal title={signup ? t.signup : t.login} onClose={close}>
      <p className="muted">{t.authHint}</p>
      <form onSubmit={submit}>
        <label>
          {t.email}
          <input
            type="email"
            dir="ltr"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </label>
        <label>
          {t.password}
          <input
            type="password"
            dir="ltr"
            minLength={8}
            autoComplete={signup ? "new-password" : "current-password"}
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        {message && (
          <p role="status" className="notice">
            {message}
          </p>
        )}
        <button className="primary wide" disabled={busy}>
          {busy ? t.loading : signup ? t.signup : t.login}
        </button>
      </form>
      <button className="text-link wide" onClick={() => setSignup(!signup)}>
        {signup ? t.login : t.signup}
      </button>
    </Modal>
  );
}
export default function App() {
  const g = useGame(),
    path = useRouterState({ select: (s) => s.location.pathname }),
    [auth, setAuth] = useState(false),
    [settings, setSettings] = useState(false),
    [tutorialStep, setTutorialStep] = useState(0);
  return (
    <div className="app-shell">
      <header className="top-header">
        <Link to="/" className="brand">
          <div className="brand-icon">
            <Crown size={29} />
          </div>
          <div>
            <b>{t.title}</b>
            <small>{t.subtitle}</small>
          </div>
        </Link>
        <nav className="desktop-nav">
          {navigation.map((n) => (
            <Link
              to={n.to}
              key={n.to}
              className={path === n.to ? "nav-item active" : "nav-item"}
            >
              <n.icon size={18} />
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="header-actions">
          <Link
            to="/leaderboard"
            className={path === "/leaderboard" ? "icon-btn active" : "icon-btn"}
            title={t.leaderboard}
          >
            <Trophy size={19} />
          </Link>
          <button
            className="icon-btn"
            aria-label={t.settings}
            onClick={() => setSettings(true)}
          >
            <Settings size={19} />
          </button>
          {g.session ? (
            <button
              className="account-button"
              title={t.logout}
              onClick={() => {
                void g.save().then(() => supabase.auth.signOut());
              }}
            >
              <LogOut size={17} />
              <span>{t.logout}</span>
            </button>
          ) : (
            <button className="account-button" onClick={() => setAuth(true)}>
              <LogIn size={17} />
              <span>{t.login}</span>
            </button>
          )}
        </div>
      </header>
      <div className="resource-bar">
        <div className="resource-group">
          {(
            [
              { key: "gold", icon: Coins },
              { key: "wood", icon: Trees },
              { key: "stone", icon: Mountain },
              { key: "food", icon: Wheat },
            ] as const
          ).map((r) => (
            <div className={`resource ${r.key}`} key={r.key}>
              <r.icon size={21} />
              <div>
                <small>{t[r.key]}</small>
                <b>{num(g.state.resources[r.key])}</b>
              </div>
            </div>
          ))}
        </div>
        <div className="day-control">
          <Sun size={22} />
          <span>
            {t.day} <b>{num(g.state.day)}</b>
            <small>{t.season}</small>
          </span>
          <button
            aria-label={g.paused ? t.resume : t.pause}
            onClick={() => g.setPaused(!g.paused)}
          >
            {g.paused ? <Play size={15} /> : <Pause size={15} />}
          </button>
        </div>
      </div>
      <main>
        <Outlet />
      </main>
      <footer className="app-footer">
        <span>
          <Cloud size={13} />
          {g.status}
        </span>
        <span>{t.rules}</span>
        <button
          onClick={() => {
            setTutorialStep(0);
            g.setTutorial(true);
          }}
        >
          <HelpCircle size={15} />
          {t.tutorial}
        </button>
      </footer>
      <nav className="bottom-nav">
        {navigation.map((n) => (
          <Link to={n.to} key={n.to} className={path === n.to ? "active" : ""}>
            <n.icon size={20} />
            <span>{n.label}</span>
          </Link>
        ))}
      </nav>
      {auth && <Auth close={() => setAuth(false)} />}
      {settings && (
        <Modal title={t.settings} onClose={() => setSettings(false)}>
          <label>
            {t.name}
            <input
              maxLength={48}
              value={g.state.name}
              disabled={!g.started}
              onChange={(e) =>
                g.update((s) => ({
                  ...s,
                  name: e.target.value,
                  revision: s.revision + 1,
                }))
              }
            />
          </label>
          <h3>{t.quality}</h3>
          <p className="muted">{t.qualityHint}</p>
          <div className="quality-options">
            {(["low", "medium", "high"] as Quality[]).map((q, i) => (
              <button
                key={q}
                className={
                  g.quality === q ? "quality-option active" : "quality-option"
                }
                onClick={() => g.setQuality(q)}
              >
                <span>{t.qualities[i]}</span>
                {g.quality === q && <Check size={16} />}
              </button>
            ))}
          </div>
          <button
            className="secondary wide"
            disabled={!g.started}
            onClick={() => void g.save()}
          >
            <Save size={16} />
            {t.editSave}
          </button>
          <button
            className="secondary wide"
            onClick={() => {
              if (confirm(t.resetConfirm)) {
                g.start(true);
                setSettings(false);
              }
            }}
          >
            {t.newGame}
          </button>
        </Modal>
      )}
      {g.tutorial && (
        <Modal title={t.tutorialTitle} onClose={() => g.setTutorial(false)}>
          <div className="tutorial-art">
            <Crown size={52} />
            <span>
              {num(tutorialStep + 1)} / {num(t.tutorialSteps.length)}
            </span>
          </div>
          <p className="tutorial-copy">{t.tutorialSteps[tutorialStep]}</p>
          <div className="tutorial-dots">
            {t.tutorialSteps.map((_, i) => (
              <span key={i} className={i === tutorialStep ? "active" : ""} />
            ))}
          </div>
          <button
            className="primary wide"
            onClick={() => {
              if (tutorialStep < t.tutorialSteps.length - 1)
                setTutorialStep((v) => v + 1);
              else {
                g.setTutorial(false);
                setTutorialStep(0);
              }
            }}
          >
            {tutorialStep === t.tutorialSteps.length - 1 ? t.start : t.continue}
            <ChevronLeft size={16} />
          </button>
        </Modal>
      )}
      <BattleOverlay />
    </div>
  );
}
