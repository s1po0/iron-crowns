import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { Session } from "@supabase/supabase-js";
import { newGame, tick, score, type GameState } from "./simulation";
import { qualitySettings, rules, type Quality } from "../data/world";
import { supabase, publicKey, supabaseUrl } from "../../lib/supabase";
import { t } from "../../i18n";
import { migrateSave, parseSave, type LoadResult } from "./migrations";
type Store = {
  state: GameState;
  update: (f: (s: GameState) => GameState) => void;
  started: boolean;
  start: (fresh: boolean, name?: string) => void;
  hasSave: boolean;
  session: Session | null;
  authReady: boolean;
  quality: Quality;
  setQuality: (q: Quality) => void;
  save: () => Promise<void>;
  status: string;
  saveNotice: string;
  paused: boolean;
  setPaused: (v: boolean) => void;
  tutorial: boolean;
  setTutorial: (v: boolean) => void;
};
const Context = createContext<Store>(null!);
const key = (id?: string) => `iron-web-v1-${id || "guest"}`;
function readInfo(id?: string): LoadResult {
  try {
    return parseSave(localStorage.getItem(key(id)));
  } catch {
    return { state: null, status: "unsupported" };
  }
}
function read(id?: string) {
  return readInfo(id).state;
}
function backup(id?: string, raw?: string) {
  try {
    const backupKey = key(id) + "-pre-schema2" + (raw ? "-cloud" : "");
    if (!localStorage.getItem(backupKey)) {
      const value = raw || localStorage.getItem(key(id));
      if (value) localStorage.setItem(backupKey, value);
    }
  } catch {
    /* A full storage quota must not crash the recovery screen. */
  }
}
const notice = (result: LoadResult) =>
  result.status === "unsupported"
    ? t.incompatibleSave
    : result.status === "migrated"
      ? t.migratedSave
      : "";
export function Provider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<GameState>(
      () => read() || newGame(t.hero),
    ),
    [saveNotice, setSaveNotice] = useState(notice(readInfo())),
    [started, setStarted] = useState(false),
    [hasSave, setHasSave] = useState(!!read()),
    [session, setSession] = useState<Session | null>(null),
    [authReady, setAuthReady] = useState(false),
    [syncing, setSyncing] = useState(false),
    [quality, setQualityState] = useState<Quality>("medium"),
    [status, setStatus] = useState(t.local),
    [paused, setPaused] = useState(false),
    [tutorial, setTutorial] = useState(false);
  const current = useRef(state),
    sessionRef = useRef(session),
    loadedUser = useRef<string | undefined>(undefined),
    saveQueue = useRef(Promise.resolve());
  current.current = state;
  sessionRef.current = session;
  useEffect(() => {
    let alive = true;
    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (alive) {
          setSession(data.session);
          setAuthReady(true);
        }
      })
      .catch(() => setAuthReady(true));
    const { data } = supabase.auth.onAuthStateChange((_e, s) => {
      if (alive) {
        setSession(s);
        setAuthReady(true);
      }
    });
    return () => {
      alive = false;
      data.subscription.unsubscribe();
    };
  }, []);
  useEffect(() => {
    if (!authReady) return;
    let alive = true;
    const id = session?.user.id;
    loadedUser.current = id;
    setStarted(false);
    const cachedInfo = readInfo(id);
    const cached = cachedInfo.state;
    setSaveNotice(notice(cachedInfo));
    setState(cached || newGame(t.hero));
    setHasSave(!!cached);
    setStatus(id ? t.pendingCloud : t.local);
    const q = localStorage.getItem(`iron-quality-${id || "guest"}`);
    setQualityState(q && q in qualitySettings ? (q as Quality) : "medium");
    if (id) {
      setSyncing(true);
      (async () => {
        const [{ data, error }, { data: profile }] = await Promise.all([
          supabase
            .from("saves")
            .select("game_state")
            .eq("user_id", id)
            .abortSignal(AbortSignal.timeout(10000))
            .maybeSingle(),
          supabase
            .from("profiles")
            .select("iron_quality")
            .eq("id", id)
            .abortSignal(AbortSignal.timeout(10000))
            .maybeSingle(),
        ]);
        if (!alive) return;
        const loaded = migrateSave(data?.game_state);
        if (
          !error &&
          loaded.status !== "empty" &&
          loaded.status !== "current"
        ) {
          setSaveNotice(notice(loaded));
          backup(id, JSON.stringify(data?.game_state));
        }
        if (
          !error &&
          loaded.state &&
          (!cached || loaded.state.revision > cached.revision)
        ) {
          backup(id);
          setState(loaded.state);
          setHasSave(true);
          localStorage.setItem(key(id), JSON.stringify(loaded.state));
        }
        setStatus(error ? t.saveError : t.cloud);
        setSyncing(false);
        if (profile?.iron_quality in qualitySettings)
          setQualityState(profile!.iron_quality as Quality);
        if (!profile)
          await supabase
            .from("profiles")
            .insert({ id, username: `iron_${id.slice(0, 8)}` });
      })().catch(() => {
        if (alive) {
          setSyncing(false);
          setStatus(t.saveError);
        }
      });
    } else setSyncing(false);
    return () => {
      alive = false;
    };
  }, [session?.user.id, authReady]);
  const save = async () => {
    if (!started) return;
    const snapshot = current.current,
      user = sessionRef.current?.user.id;
    try {
      localStorage.setItem(key(user), JSON.stringify(snapshot));
      setHasSave(true);
    } catch {
      setStatus(t.saveError);
    }
    if (!user) {
      setStatus(t.local);
      return;
    }
    setStatus(t.saving);
    saveQueue.current = saveQueue.current
      .then(async () => {
        const { error } = await supabase.from("saves").upsert({
          user_id: user,
          game_state: snapshot,
          updated_at: new Date().toISOString(),
        });
        if (!error)
          await supabase.from("leaderboard").upsert({
            user_id: user,
            hero_name: snapshot.name.slice(0, 48),
            score: score(snapshot),
            days_survived: snapshot.day,
          });
        if (loadedUser.current === user)
          setStatus(error ? t.saveError : t.saved);
      })
      .catch(() => setStatus(t.saveError));
    await saveQueue.current;
  };
  const saveRef = useRef(save);
  saveRef.current = save;
  useEffect(() => {
    if (!started) return;
    const interval = setInterval(
      () => void saveRef.current(),
      rules.autosaveMs,
    );
    const flush = () => {
      const s = current.current,
        user = sessionRef.current;
      try {
        localStorage.setItem(key(user?.user.id), JSON.stringify(s));
      } catch {}
      if (user) {
        void fetch(`${supabaseUrl}/rest/v1/saves?on_conflict=user_id`, {
          method: "POST",
          keepalive: true,
          headers: {
            apikey: publicKey,
            Authorization: `Bearer ${user.access_token}`,
            "Content-Type": "application/json",
            Prefer: "resolution=merge-duplicates",
          },
          body: JSON.stringify({
            user_id: user.user.id,
            game_state: s,
            updated_at: new Date().toISOString(),
          }),
        }).catch(() => {});
      }
    };
    const hidden = () => {
      if (document.hidden) void saveRef.current();
    };
    window.addEventListener("pagehide", flush);
    document.addEventListener("visibilitychange", hidden);
    return () => {
      clearInterval(interval);
      window.removeEventListener("pagehide", flush);
      document.removeEventListener("visibilitychange", hidden);
    };
  }, [started]);
  useEffect(() => {
    if (!started || paused) return;
    const timer = setInterval(() => {
      if (!document.hidden) setState((s) => tick(s, 0.1));
    }, 100);
    return () => clearInterval(timer);
  }, [started, paused]);
  const update = useCallback(
    (f: (s: GameState) => GameState) =>
      setState((s) => {
        const next = f(s);
        current.current = next;
        try {
          localStorage.setItem(
            key(sessionRef.current?.user.id),
            JSON.stringify(next),
          );
        } catch {}
        return next;
      }),
    [],
  );
  const start = (fresh: boolean, name?: string) => {
    if (fresh) {
      backup(session?.user.id);
      const seed = crypto.getRandomValues(new Uint32Array(1))[0];
      const s = newGame(name?.trim().slice(0, 48) || t.hero, seed);
      s.revision = current.current.revision + 1;
      current.current = s;
      setState(s);
      localStorage.setItem(key(session?.user.id), JSON.stringify(s));
      setHasSave(true);
    }
    if (!fresh) backup(session?.user.id);
    setSaveNotice("");
    setStarted(true);
    setTimeout(() => void saveRef.current(), 0);
    if (!localStorage.getItem("iron-tutorial")) setTutorial(true);
  };
  const setQuality = (q: Quality) => {
    setQualityState(q);
    localStorage.setItem(`iron-quality-${session?.user.id || "guest"}`, q);
    if (session)
      void supabase
        .from("profiles")
        .update({ iron_quality: q })
        .eq("id", session.user.id)
        .then(({ error }) => {
          if (error) setStatus(t.profileError);
        });
  };
  return (
    <Context.Provider
      value={{
        state,
        update,
        started,
        start,
        hasSave,
        session,
        authReady: authReady && !syncing,
        quality,
        setQuality,
        save,
        status,
        saveNotice,
        paused,
        setPaused,
        tutorial,
        setTutorial: (v) => {
          setTutorial(v);
          if (!v) localStorage.setItem("iron-tutorial", "1");
        },
      }}
    >
      {children}
    </Context.Provider>
  );
}
export const useGame = () => useContext(Context);
