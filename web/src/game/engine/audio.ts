import { useEffect, useRef, useState } from "react";
import type { GameState } from "./simulation";
/** Locally synthesized pentatonic ambience and short UI/battle cues. No files or requests. */
export function useAudio(state: GameState, started: boolean) {
  const [muted, setMuted] = useState(() => {
      try {
        return localStorage.getItem("iron-audio-muted") !== "false";
      } catch {
        return true;
      }
    }),
    mutedRef = useRef(muted),
    active = useRef(started),
    ctx = useRef<AudioContext | null>(null),
    gain = useRef<GainNode | null>(null),
    step = useRef(0);
  mutedRef.current = muted;
  active.current = started;
  function tone(
    frequency: number,
    duration: number,
    volume: number,
    type: OscillatorType = "triangle",
  ) {
    const c = ctx.current;
    if (
      !c ||
      c.state !== "running" ||
      mutedRef.current ||
      !active.current ||
      document.hidden
    )
      return;
    const o = c.createOscillator(),
      g = c.createGain(),
      now = c.currentTime;
    o.type = type;
    o.frequency.value = frequency;
    g.gain.setValueAtTime(0, now);
    g.gain.linearRampToValueAtTime(volume, now + 0.025);
    g.gain.exponentialRampToValueAtTime(0.001, now + duration);
    o.connect(g);
    g.connect(gain.current!);
    o.start(now);
    o.stop(now + duration + 0.02);
    o.onended = () => {
      o.disconnect();
      g.disconnect();
    };
  }
  useEffect(() => {
    const unlock = () => {
      try {
        ctx.current ??= new AudioContext();
        if (!gain.current) {
          gain.current = ctx.current.createGain();
          gain.current.gain.value = mutedRef.current ? 0 : 0.3;
          gain.current.connect(ctx.current.destination);
        }
        if (!mutedRef.current) void ctx.current.resume().catch(() => {});
      } catch {
        /* Audio is optional on browsers without Web Audio. */
      }
    };
    const hidden = () => {
      if (document.hidden) void ctx.current?.suspend();
      else if (!mutedRef.current) void ctx.current?.resume().catch(() => {});
    };
    document.addEventListener("pointerdown", unlock);
    document.addEventListener("keydown", unlock);
    document.addEventListener("visibilitychange", hidden);
    const timer = setInterval(() => {
      const notes = [146.83, 220, 261.63, 293.66, 220, 196, 164.81, 220];
      tone(notes[step.current++ % notes.length], 0.65, 0.12, "sine");
      if (step.current % 4 === 0) tone(73.42, 1.4, 0.08, "sine");
    }, 700);
    return () => {
      clearInterval(timer);
      document.removeEventListener("pointerdown", unlock);
      document.removeEventListener("keydown", unlock);
      document.removeEventListener("visibilitychange", hidden);
      void ctx.current?.close();
      ctx.current = null;
      gain.current = null;
    };
  }, []);
  useEffect(() => {
    try {
      localStorage.setItem("iron-audio-muted", String(muted));
    } catch {}
    if (gain.current) gain.current.gain.value = muted ? 0 : 0.3;
    if (!muted) void ctx.current?.resume().catch(() => {});
  }, [muted]);
  const previous = useRef({
    gold: state.resources.gold,
    buildings: state.buildings.length,
    battle: state.battle,
    result: state.result,
  });
  useEffect(() => {
    const p = previous.current;
    if (state.battle !== null && p.battle !== state.battle) {
      tone(82, 0.25, 0.2, "sawtooth");
      tone(123, 0.35, 0.12);
    } else if (state.result && !p.result)
      tone(state.result.won ? 440 : 110, 0.5, 0.18);
    else if (state.buildings.length > p.buildings)
      tone(196, 0.16, 0.18, "square");
    else if (state.resources.gold !== p.gold) tone(660, 0.09, 0.1, "sine");
    previous.current = {
      gold: state.resources.gold,
      buildings: state.buildings.length,
      battle: state.battle,
      result: state.result,
    };
  }, [
    state.resources.gold,
    state.buildings.length,
    state.battle,
    state.result,
  ]);
  return { muted, toggle: () => setMuted((v) => !v) };
}
