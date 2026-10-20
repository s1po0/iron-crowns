import { useEffect, useRef, useState } from "react";
import { Plus, Minus, LocateFixed } from "lucide-react";
import { factions, settlements, WORLD } from "../../game/data/world";
import { move } from "../../game/engine/simulation";
import { useGame } from "../../game/engine/store";
import { t, num } from "../../i18n";
const noise = (x: number, y: number) => {
  const n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
  return n - Math.floor(n);
};
function terrain() {
  const c = document.createElement("canvas");
  c.width = WORLD.width;
  c.height = WORLD.height;
  const g = c.getContext("2d")!;
  g.fillStyle = "#263f48";
  g.fillRect(0, 0, c.width, c.height);
  const land = (x: number, y: number) => {
    const nx = (x - 710) / 655,
      ny = (y - 510) / 440;
    return (
      nx * nx + ny * ny <
        1 + 0.1 * Math.sin(y / 60) + 0.08 * Math.cos(x / 55) &&
      !(x < 370 && y > 760) &&
      !(x > 1100 && y < 160)
    );
  };
  for (let y = 0; y < c.height; y += 12)
    for (let x = 0; x < c.width; x += 12) {
      if (land(x, y)) {
        const n = noise(x, y),
          coast =
            !land(x - 18, y) ||
            !land(x + 18, y) ||
            !land(x, y - 18) ||
            !land(x, y + 18);
        g.fillStyle = coast
          ? `hsl(43 21% ${43 + n * 8}%)`
          : x > 950
            ? `hsl(48 17% ${35 + n * 6}%)`
            : `hsl(${82 + n * 12} 13% ${31 + n * 6}%)`;
        g.fillRect(x, y, 13, 13);
      } else if (noise(x, y) > 0.93) {
        g.strokeStyle = "#45616a44";
        g.beginPath();
        g.moveTo(x, y);
        g.lineTo(x + 14, y);
        g.stroke();
      }
    }
  g.lineCap = "round";
  for (const [i, s] of settlements.entries()) {
    const to = settlements[i % 5 === 4 ? i - 4 : i + 1] || settlements[0];
    g.beginPath();
    g.moveTo(s.x, s.y);
    g.quadraticCurveTo(
      (s.x + to.x) / 2 + 20,
      (s.y + to.y) / 2 - 15,
      to.x,
      to.y,
    );
    g.strokeStyle = "#333e2e";
    g.lineWidth = 7;
    g.stroke();
    g.strokeStyle = "#b0a07977";
    g.lineWidth = 3;
    g.stroke();
  }
  g.setLineDash([]);
  g.beginPath();
  g.moveTo(800, 140);
  g.bezierCurveTo(870, 330, 580, 480, 870, 900);
  g.strokeStyle = "#b6b39555";
  g.lineWidth = 21;
  g.stroke();
  g.strokeStyle = "#345660";
  g.lineWidth = 12;
  g.stroke();
  g.strokeStyle = "#66858a66";
  g.lineWidth = 3;
  g.stroke();
  for (let i = 0; i < 850; i++) {
    const x = noise(i, 9) * 1400,
      y = noise(i, 4) * 1000;
    if (
      !land(x, y) ||
      settlements.some((s) => Math.hypot(s.x - x, s.y - y) < 47) ||
      noise(x / 100, y / 100) < 0.25 ||
      x > 1000
    )
      continue;
    g.fillStyle = "#1d302b55";
    g.beginPath();
    g.ellipse(x + 4, y + 4, 8, 3, 0, 0, 7);
    g.fill();
    g.fillStyle = i % 2 ? "#2a4036" : "#3c5141";
    g.beginPath();
    g.moveTo(x, y - 13);
    g.lineTo(x - 5, y + 2);
    g.lineTo(x + 6, y + 2);
    g.closePath();
    g.fill();
    g.fillStyle = "#8d85634d";
    g.fillRect(x, y - 9, 1, 8);
  }
  for (let i = 0; i < 65; i++) {
    const x = 360 + noise(i, 21) * 300,
      y = 140 + noise(i, 22) * 150,
      h = 20 + noise(i, 23) * 54;
    g.fillStyle = "#2b343144";
    g.beginPath();
    g.moveTo(x, y);
    g.lineTo(x + 55, y + 23);
    g.lineTo(x + 20, y - 10);
    g.fill();
    g.fillStyle = "#a3a291";
    g.beginPath();
    g.moveTo(x - 24, y);
    g.lineTo(x, y - h);
    g.lineTo(x + 28, y);
    g.fill();
    g.fillStyle = "#626e66";
    g.beginPath();
    g.moveTo(x, y - h);
    g.lineTo(x + 28, y);
    g.lineTo(x + 6, y - 4);
    g.fill();
    g.fillStyle = "#dad9c5";
    g.beginPath();
    g.moveTo(x, y - h);
    g.lineTo(x - 9, y - h + 20);
    g.lineTo(x - 1, y - h + 16);
    g.lineTo(x + 10, y - h + 24);
    g.fill();
  }
  const vignette = g.createRadialGradient(700, 500, 230, 700, 500, 820);
  vignette.addColorStop(0, "#07141600");
  vignette.addColorStop(1, "#07141677");
  g.fillStyle = vignette;
  g.fillRect(0, 0, 1400, 1000);
  return c;
}
export default function WorldMap() {
  const { state, update, started } = useGame(),
    ref = useRef<HTMLCanvasElement>(null),
    terrainRef = useRef<HTMLCanvasElement | null>(null),
    stateRef = useRef(state),
    view = useRef({ x: 0, y: 0, z: 1 }),
    pointers = useRef(new Map<number, { x: number; y: number }>()),
    gesture = useRef({ x: 0, y: 0, moved: false, distance: 0 }),
    [selected, setSelected] = useState<number | null>(null);
  stateRef.current = state;
  useEffect(() => {
    const canvas = ref.current!,
      ctx = canvas.getContext("2d")!;
    terrainRef.current = terrain();
    let w = 0,
      h = 0,
      frame = 0,
      last = 0;
    const resize = new ResizeObserver(() => {
      const r = canvas.getBoundingClientRect();
      w = r.width;
      h = r.height;
      canvas.width = w * Math.min(devicePixelRatio, 2);
      canvas.height = h * Math.min(devicePixelRatio, 2);
    });
    resize.observe(canvas);
    const render = (now: number) => {
      frame = requestAnimationFrame(render);
      if (now - last < 40) return;
      last = now;
      const dpr = Math.min(devicePixelRatio, 2);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.fillStyle = "#233c43";
      ctx.fillRect(0, 0, w, h);
      const v = view.current,
        scale = Math.min(w / 1400, h / 1000) * v.z;
      ctx.translate(w / 2 + v.x, h / 2 + v.y);
      ctx.scale(scale, scale);
      ctx.translate(-700, -500);
      ctx.drawImage(terrainRef.current!, 0, 0);
      ctx.textAlign = "center";
      ctx.font = "500 22px Vazirmatn";
      factions.forEach((f) => {
        ctx.fillStyle = f.color + "99";
        ctx.fillText(t.factionNames[f.id], f.at[0], f.at[1] - 80);
      });
      settlements.forEach((s) => {
        const color = factions[s.faction].color;
        ctx.fillStyle = "#15282c99";
        ctx.beginPath();
        ctx.ellipse(s.x + 5, s.y + 10, s.kind === "town" ? 25 : 13, 7, 0, 0, 7);
        ctx.fill();
        if (s.kind === "town") {
          ctx.fillStyle = "#c9c1a5";
          ctx.fillRect(s.x - 13, s.y - 9, 26, 22);
          ctx.fillRect(s.x - 19, s.y - 19, 9, 32);
          ctx.fillRect(s.x + 10, s.y - 19, 9, 32);
          ctx.fillStyle = "#324138";
          ctx.fillRect(s.x - 4, s.y + 2, 8, 11);
          for (const dx of [-19, -14, 10, 15])
            ctx.fillRect(s.x + dx, s.y - 22, 4, 4);
        } else {
          ctx.fillStyle = "#a59b7a";
          ctx.fillRect(s.x - 7, s.y - 4, 14, 13);
          ctx.fillStyle = "#63514b";
          ctx.beginPath();
          ctx.moveTo(s.x - 11, s.y - 4);
          ctx.lineTo(s.x, s.y - 14);
          ctx.lineTo(s.x + 11, s.y - 4);
          ctx.fill();
        }
        ctx.strokeStyle = "#e4d6ae";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(s.x, s.y - 16);
        ctx.lineTo(s.x, s.y - 43);
        ctx.stroke();
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.moveTo(s.x, s.y - 43);
        ctx.lineTo(s.x + 19, s.y - 40);
        ctx.lineTo(s.x + 16, s.y - 27);
        ctx.lineTo(s.x, s.y - 30);
        ctx.fill();
        ctx.font = `${s.kind === "town" ? 18 : 13}px Vazirmatn`;
        const label = t.settlementNames[s.id];
        const lw = ctx.measureText(label).width;
        ctx.fillStyle = "#142127dd";
        ctx.fillRect(s.x - lw / 2 - 10, s.y + 20, lw + 20, 27);
        ctx.fillStyle = s.kind === "town" ? "#e9dec2" : "#b9c2af";
        ctx.fillText(label, s.x, s.y + 40);
      });
      const s = stateRef.current;
      if (s.destination) {
        ctx.strokeStyle = "#e4c184";
        ctx.setLineDash([8, 7]);
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(s.hero.x, s.hero.y);
        ctx.lineTo(s.destination.x, s.destination.y);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.beginPath();
        ctx.arc(s.destination.x, s.destination.y, 9, 0, Math.PI * 2);
        ctx.stroke();
      }
      s.enemies
        .filter((e) => e.alive)
        .forEach((e) => {
          ctx.fillStyle = "#a86054";
          ctx.save();
          ctx.translate(e.x, e.y);
          ctx.rotate(Math.PI / 4);
          ctx.fillRect(-8, -8, 16, 16);
          ctx.restore();
          ctx.strokeStyle = "#e5ab91";
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.moveTo(e.x - 4, e.y - 4);
          ctx.lineTo(e.x + 4, e.y + 4);
          ctx.moveTo(e.x + 4, e.y - 4);
          ctx.lineTo(e.x - 4, e.y + 4);
          ctx.stroke();
        });
      ctx.strokeStyle = "#f7d99a77";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(s.hero.x, s.hero.y, 21 + Math.sin(now / 400) * 3, 0, 7);
      ctx.stroke();
      ctx.fillStyle = "#e8c689";
      ctx.beginPath();
      ctx.arc(s.hero.x, s.hero.y, 12, 0, 7);
      ctx.fill();
      ctx.fillStyle = "#263830";
      ctx.beginPath();
      ctx.moveTo(s.hero.x, s.hero.y - 7);
      ctx.lineTo(s.hero.x - 6, s.hero.y + 6);
      ctx.lineTo(s.hero.x + 6, s.hero.y + 6);
      ctx.fill();
    };
    frame = requestAnimationFrame(render);
    const wheel = (e: WheelEvent) => {
      e.preventDefault();
      view.current.z = Math.max(
        0.7,
        Math.min(3.5, view.current.z * Math.exp(-e.deltaY * 0.001)),
      );
    };
    canvas.addEventListener("wheel", wheel, { passive: false });
    return () => {
      resize.disconnect();
      cancelAnimationFrame(frame);
      canvas.removeEventListener("wheel", wheel);
    };
  }, []);
  const onDown = (e: React.PointerEvent) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    gesture.current = {
      x: e.clientX,
      y: e.clientY,
      moved: pointers.current.size > 1,
      distance: 0,
    };
  };
  const onMove = (e: React.PointerEvent) => {
    const old = pointers.current.get(e.pointerId);
    if (!old) return;
    const pts = [...pointers.current.values()];
    const oldD =
      pts.length === 2
        ? Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y)
        : 0;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (
      Math.hypot(e.clientX - gesture.current.x, e.clientY - gesture.current.y) >
      5
    )
      gesture.current.moved = true;
    if (pts.length === 2) {
      const p = [...pointers.current.values()],
        d = Math.hypot(p[0].x - p[1].x, p[0].y - p[1].y);
      if (oldD)
        view.current.z = Math.max(
          0.7,
          Math.min(3.5, (view.current.z * d) / oldD),
        );
      gesture.current.moved = true;
    }
    view.current.x = Math.max(
      -900,
      Math.min(900, view.current.x + (e.clientX - old.x) / pts.length),
    );
    view.current.y = Math.max(
      -700,
      Math.min(700, view.current.y + (e.clientY - old.y) / pts.length),
    );
  };
  const up = (e: React.PointerEvent) => {
    pointers.current.delete(e.pointerId);
    if (gesture.current.moved || !started) return;
    const r = ref.current!.getBoundingClientRect(),
      v = view.current,
      k = Math.min(r.width / 1400, r.height / 1000) * v.z,
      p = {
        x: (e.clientX - r.left - r.width / 2 - v.x) / k + 700,
        y: (e.clientY - r.top - r.height / 2 - v.y) / k + 500,
      };
    const nearest = settlements.find(
      (s) => Math.hypot(s.x - p.x, s.y - p.y) < 45,
    );
    setSelected(nearest?.id ?? null);
    update((s) => move(s, nearest || p));
  };
  return (
    <div className="map-canvas">
      <canvas
        ref={ref}
        aria-label={t.map}
        onPointerDown={onDown}
        onPointerMove={onMove}
        onPointerUp={up}
        onPointerCancel={(e) => {
          pointers.current.delete(e.pointerId);
          gesture.current.moved = true;
        }}
      />
      <div className="map-compass">
        ✧<span>{t.north}</span>
      </div>
      <div className="map-tools">
        <button
          aria-label={t.zoomIn}
          onClick={() => (view.current.z = Math.min(3.5, view.current.z * 1.2))}
        >
          <Plus size={18} />
        </button>
        <button
          aria-label={t.zoomOut}
          onClick={() => (view.current.z = Math.max(0.7, view.current.z / 1.2))}
        >
          <Minus size={18} />
        </button>
        <button
          aria-label={t.locate}
          onClick={() => {
            view.current = { x: 0, y: 0, z: 1 };
          }}
        >
          <LocateFixed size={18} />
        </button>
      </div>
      <div className="map-caption">
        <span className="live-dot" />
        {selected === null
          ? t.worldHint
          : `${t.destination}: ${t.settlementNames[selected]}`}
        <span className="map-scale">{num(100)} ━━━</span>
      </div>
    </div>
  );
}
