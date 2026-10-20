import { atWar } from "../../game/engine/campaign";
import { useEffect, useRef, useState } from "react";
import { Plus, Minus, LocateFixed } from "lucide-react";
import {
  factions,
  WORLD,
  MAP,
  TERRAIN,
  terrainColors,
  renderBudget,
  qualitySettings,
} from "../../game/data/world";
import { getWorld, tileAt, type World } from "../../game/engine/worldgen";
import { move } from "../../game/engine/simulation";
import { useGame } from "../../game/engine/store";
import { t, num } from "../../i18n";
const hash = (x: number, y: number) => {
  const n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
  return n - Math.floor(n);
};
function chunk(w: World, cx: number, cy: number) {
  const c = document.createElement("canvas"),
    size = MAP.chunk * MAP.tile;
  c.width = c.height = size;
  const g = c.getContext("2d")!;
  for (let ly = 0; ly < MAP.chunk; ly++)
    for (let lx = 0; lx < MAP.chunk; lx++) {
      const tx = cx * MAP.chunk + lx,
        ty = cy * MAP.chunk + ly,
        id = ty * MAP.size + tx,
        x = lx * MAP.tile,
        y = ly * MAP.tile,
        base = w.base[id],
        n = hash(tx, ty),
        tile = MAP.tile;
      g.fillStyle = terrainColors[base];
      g.fillRect(x, y, tile, tile);
      // Feather neighboring biomes into the base color without allocating per-frame textures.
      for (const [dx, dy] of [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        const nx = tx + dx,
          ny = ty + dy;
        if (nx < 0 || ny < 0 || nx >= 128 || ny >= 128) continue;
        const other = w.base[ny * 128 + nx];
        if (other === base) continue;
        const gradient = g.createLinearGradient(
          x + 12,
          y + 12,
          x + 12 + dx * 12,
          y + 12 + dy * 12,
        );
        gradient.addColorStop(0, terrainColors[base] + "00");
        gradient.addColorStop(1, terrainColors[other] + "88");
        g.fillStyle = gradient;
        g.fillRect(x, y, tile, tile);
      }
      g.fillStyle = n > 0.5 ? "#fff7c00a" : "#14231312";
      g.fillRect(x, y, tile, tile);
      if (w.tiles[id] === TERRAIN.road) {
        g.strokeStyle = "#544934";
        g.lineWidth = 7;
        g.beginPath();
        g.moveTo(x + 12, y + 12);
        for (const [dx, dy] of [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ])
          if (
            tx + dx >= 0 &&
            tx + dx < 128 &&
            ty + dy >= 0 &&
            ty + dy < 128 &&
            w.tiles[id + dy * 128 + dx] === TERRAIN.road
          ) {
            g.moveTo(x + 12, y + 12);
            g.lineTo(x + 12 + dx * 12, y + 12 + dy * 12);
          }
        g.stroke();
        g.strokeStyle = "#c1ac80";
        g.lineWidth = 4;
        g.stroke();
        continue;
      }
      if (base === TERRAIN.forest) {
        for (let k = 0; k < 3; k++) {
          const px = x + 4 + hash(tx + k, ty) * 17,
            py = y + 6 + hash(tx, ty + k) * 15;
          g.fillStyle = "#10231930";
          g.beginPath();
          g.ellipse(px + 3, py + 3, 6, 3, 0, 0, 7);
          g.fill();
          g.fillStyle = "#4b4531";
          g.fillRect(px, py - 3, 2, 6);
          g.fillStyle = k % 2 ? "#344f3b" : "#416049";
          g.beginPath();
          g.moveTo(px - 5, py);
          g.lineTo(px + 1, py - 13);
          g.lineTo(px + 7, py);
          g.fill();
          g.fillStyle = "#6a8260";
          g.beginPath();
          g.moveTo(px + 1, py - 13);
          g.lineTo(px + 1, py - 2);
          g.lineTo(px - 4, py - 2);
          g.fill();
        }
      }
      if (base === TERRAIN.hills || base === TERRAIN.mountains) {
        const high = base === TERRAIN.mountains;
        g.fillStyle = "#26362e30";
        g.beginPath();
        g.ellipse(x + 14, y + 19, 10, 4, 0, 0, 7);
        g.fill();
        g.fillStyle = high ? "#b3b2a1" : "#a49c7a";
        g.beginPath();
        g.moveTo(x + 2, y + 20);
        g.quadraticCurveTo(x + 9, y + (high ? -6 : 5), x + 13, y + 3);
        g.lineTo(x + 23, y + 20);
        g.fill();
        g.fillStyle = high ? "#686f67" : "#747955";
        g.beginPath();
        g.moveTo(x + 13, y + 3);
        g.lineTo(x + 12, y + 20);
        g.lineTo(x + 23, y + 20);
        g.fill();
        if (high) {
          g.fillStyle = "#d9d9ca";
          g.beginPath();
          g.moveTo(x + 9, y + 7);
          g.lineTo(x + 13, y + 3);
          g.lineTo(x + 16, y + 9);
          g.fill();
        }
      }
      const owner = w.owner[id];
      if (owner >= 0) {
        g.strokeStyle = factions[owner].color + "80";
        g.lineWidth = 1;
        g.setLineDash([3, 3]);
        if (tx < 127 && w.owner[id + 1] >= 0 && w.owner[id + 1] !== owner) {
          g.beginPath();
          g.moveTo(x + 24, y);
          g.lineTo(x + 24, y + 24);
          g.stroke();
        }
        if (ty < 127 && w.owner[id + 128] >= 0 && w.owner[id + 128] !== owner) {
          g.beginPath();
          g.moveTo(x, y + 24);
          g.lineTo(x + 24, y + 24);
          g.stroke();
        }
        g.setLineDash([]);
      }
    }
  return c;
}
export default function WorldMap() {
  const { state, update, quality, started } = useGame(),
    canvas = useRef<HTMLCanvasElement>(null),
    mini = useRef<HTMLCanvasElement>(null),
    live = useRef({ state, started, quality });
  live.current = { state, started, quality };
  const camera = useRef({ x: state.hero.x, y: state.hero.y, z: 1, target: 1 }),
    [message, setMessage] = useState("");
  const locate = () => {
    camera.current.x = live.current.state.hero.x;
    camera.current.y = live.current.state.hero.y;
    camera.current.target = window.innerWidth < 700 ? 1.25 : 1.5;
  };
  useEffect(() => {
    locate();
  }, [state.worldSeed]);
  useEffect(() => {
    const c = canvas.current!,
      g = c.getContext("2d")!,
      m = mini.current!,
      mg = m.getContext("2d")!,
      cache = new Map<string, HTMLCanvasElement>();
    let raf = 0,
      last = 0,
      width = 1,
      height = 1,
      oldFog = "",
      oldSeed = -1;
    const miniBase = document.createElement("canvas");
    miniBase.width = miniBase.height = 128;
    const bg = miniBase.getContext("2d")!;
    const resize = () => {
      const r = c.getBoundingClientRect();
      width = r.width;
      height = r.height;
      const dpr = Math.min(devicePixelRatio, 1.5);
      c.width = width * dpr;
      c.height = height * dpr;
      g.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    const observer = new ResizeObserver(resize);
    observer.observe(c);
    resize();
    const draw = (now: number) => {
      raf = requestAnimationFrame(draw);
      const { state: s, quality: q } = live.current;
      if (now - last < 1000 / qualitySettings[q].fps) return;
      last = now;
      const w = getWorld(s.worldSeed),
        cam = camera.current;
      let minZoom = 0.3;
      while (
        (Math.ceil(width / (384 * minZoom)) + 1) *
          (Math.ceil(height / (384 * minZoom)) + 1) >
          renderBudget[q].chunks &&
        minZoom < 3
      )
        minZoom += 0.025;
      cam.target = Math.max(minZoom, cam.target);
      cam.z = Math.max(minZoom, cam.z + (cam.target - cam.z) * 0.18);
      cam.x = Math.max(0, Math.min(WORLD.width, cam.x));
      cam.y = Math.max(0, Math.min(WORLD.height, cam.y));
      g.clearRect(0, 0, width, height);
      g.fillStyle = "#101c21";
      g.fillRect(0, 0, width, height);
      g.save();
      g.translate(width / 2, height / 2);
      g.scale(cam.z, cam.z);
      g.translate(-cam.x, -cam.y);
      const x0 = Math.max(0, Math.floor((cam.x - width / 2 / cam.z) / 24)),
        x1 = Math.min(127, Math.ceil((cam.x + width / 2 / cam.z) / 24)),
        y0 = Math.max(0, Math.floor((cam.y - height / 2 / cam.z) / 24)),
        y1 = Math.min(127, Math.ceil((cam.y + height / 2 / cam.z) / 24));
      for (let cy = Math.floor(y0 / 16); cy <= Math.floor(y1 / 16); cy++)
        for (let cx = Math.floor(x0 / 16); cx <= Math.floor(x1 / 16); cx++) {
          const key = `${s.worldSeed}:${cx}:${cy}`;
          let image = cache.get(key);
          if (!image) image = chunk(w, cx, cy);
          cache.delete(key);
          cache.set(key, image);
          g.drawImage(image, cx * 384, cy * 384);
        }
      while (cache.size > renderBudget[q].chunks)
        cache.delete(cache.keys().next().value!);
      const heroTile = tileAt(s.hero),
        hx = heroTile % 128,
        hy = Math.floor(heroTile / 128),
        visible = (id: number) =>
          Math.hypot((id % 128) - hx, Math.floor(id / 128) - hy) <= MAP.vision;
      // Moving highlights only on visible water tiles; never reveal enemies in remembered land.
      for (let y = y0; y <= y1; y++)
        for (let x = x0; x <= x1; x++) {
          const id = y * 128 + x;
          if (
            s.explored[id] === "1" &&
            visible(id) &&
            (w.tiles[id] === 0 || w.tiles[id] === 5)
          ) {
            g.strokeStyle = "#b9e2dd30";
            g.lineWidth = 1;
            g.beginPath();
            const off = Math.sin(now * 0.001 + x + y) * 3;
            g.moveTo(x * 24 + 4, y * 24 + 12 + off);
            g.quadraticCurveTo(
              x * 24 + 12,
              y * 24 + 8 + off,
              x * 24 + 20,
              y * 24 + 12 + off,
            );
            g.stroke();
          }
        }
      if (s.path.length) {
        g.strokeStyle = "#f5d785";
        g.lineWidth = 2 / cam.z;
        g.setLineDash([6 / cam.z, 4 / cam.z]);
        g.lineDashOffset = -now * 0.015;
        g.beginPath();
        g.moveTo(s.hero.x, s.hero.y);
        for (const id of s.path)
          g.lineTo(((id % 128) + 0.5) * 24, (Math.floor(id / 128) + 0.5) * 24);
        g.stroke();
        g.setLineDash([]);
      }
      for (const p of w.settlements) {
        if (
          p.x < x0 * 24 - 60 ||
          p.x > x1 * 24 + 60 ||
          p.y < y0 * 24 - 40 ||
          p.y > y1 * 24 + 40 ||
          s.explored[p.tile] !== "1"
        )
          continue;
        const color = p.faction < 0 ? "#b16b50" : factions[p.faction].color;
        g.save();
        g.translate(p.x, p.y);
        g.fillStyle = "#18231a66";
        g.beginPath();
        g.ellipse(4, 9, 20, 7, 0, 0, 7);
        g.fill();
        g.fillStyle = "#c9bd97";
        g.fillRect(-12, -11, 24, 21);
        if (p.kind === "town") {
          g.fillStyle = "#7b8074";
          g.fillRect(-17, -19, 8, 29);
          g.fillRect(9, -19, 8, 29);
          for (let k = -16; k < 18; k += 6) g.fillRect(k, -23, 3, 5);
        } else {
          g.fillStyle = p.kind === "camp" ? "#785c42" : "#6c4838";
          g.beginPath();
          g.moveTo(-17, -9);
          g.lineTo(0, -25);
          g.lineTo(17, -9);
          g.fill();
        }
        g.fillStyle = "#37372b";
        g.fillRect(-3, -1, 6, 11);
        g.strokeStyle = "#d6c7a3";
        g.lineWidth = 1.5;
        g.beginPath();
        g.moveTo(0, -15);
        g.lineTo(0, -40);
        g.stroke();
        g.fillStyle = color;
        g.beginPath();
        g.moveTo(0, -40);
        g.lineTo(15, -37 + Math.sin(now * 0.003 + p.id));
        g.lineTo(13, -26);
        g.lineTo(0, -29);
        g.fill();
        g.font = `bold ${12 / cam.z}px Vazirmatn`;
        g.textAlign = "center";
        g.lineWidth = 4 / cam.z;
        g.strokeStyle = "#18201f";
        g.strokeText(t.settlementNames[p.id], 0, 24);
        g.fillStyle = "#f2e7cb";
        g.fillText(t.settlementNames[p.id], 0, 24);
        g.restore();
      }
      for (const e of s.enemies) {
        if (!e.alive || !visible(tileAt(e))) continue;
        g.fillStyle =
          e.kind === "bandit" || atWar(s, w.settlements[e.home].faction)
            ? "#a75440"
            : factions[w.settlements[e.home].faction].color;
        g.beginPath();
        g.moveTo(e.x, e.y - 12);
        g.lineTo(e.x + 8, e.y + 5);
        g.lineTo(e.x - 8, e.y + 5);
        g.fill();
        g.font = `${11 / cam.z}px Vazirmatn`;
        g.textAlign = "center";
        g.fillStyle = "#f5c5a1";
        g.fillText(
          `${e.kind === "bandit" ? t.banditCamp : t.patrol} ${num(e.strength)}`,
          e.x,
          e.y + 20,
        );
      }
      for (let y = y0; y <= y1; y++)
        for (let x = x0; x <= x1; x++) {
          const id = y * 128 + x;
          if (s.explored[id] !== "1") {
            g.fillStyle = "#15232b";
            g.fillRect(x * 24, y * 24, 24.5, 24.5);
          } else if (!visible(id)) {
            g.fillStyle = "#111d2b88";
            g.fillRect(x * 24, y * 24, 24.5, 24.5);
          }
        }
      g.save();
      g.translate(s.hero.x, s.hero.y);
      const bob = s.destination
        ? Math.sin(now * 0.012) * 2
        : Math.sin(now * 0.002) * 0.5;
      g.fillStyle = "#07131070";
      g.beginPath();
      g.ellipse(3, 8, 12, 5, 0, 0, 7);
      g.fill();
      g.fillStyle = "#d1a851";
      g.beginPath();
      g.moveTo(-7, 3 + bob);
      g.lineTo(-5, -17 + bob);
      g.lineTo(7, -17 + bob);
      g.lineTo(10, 6 + bob);
      g.fill();
      g.fillStyle = "#b9c3bc";
      g.fillRect(-4, -18 + bob, 8, 12);
      g.fillStyle = "#e4c49b";
      g.beginPath();
      g.arc(0, -22 + bob, 4, 0, 7);
      g.fill();
      g.strokeStyle = "#f8e5a7";
      g.lineWidth = 1.5;
      g.beginPath();
      g.arc(0, 1, 15, 0, 7);
      g.stroke();
      g.restore();
      g.restore();
      if (oldFog !== s.explored || oldSeed !== s.worldSeed) {
        const data = bg.createImageData(128, 128);
        for (let id = 0; id < 16384; id++) {
          const color =
            s.explored[id] === "1" ? terrainColors[w.tiles[id]] : "#15232b";
          data.data[id * 4] = parseInt(color.slice(1, 3), 16);
          data.data[id * 4 + 1] = parseInt(color.slice(3, 5), 16);
          data.data[id * 4 + 2] = parseInt(color.slice(5, 7), 16);
          data.data[id * 4 + 3] = 255;
        }
        bg.putImageData(data, 0, 0);
        oldFog = s.explored;
        oldSeed = s.worldSeed;
      }
      mg.drawImage(miniBase, 0, 0);
      mg.strokeStyle = "#f6ddb0";
      mg.lineWidth = 1;
      mg.strokeRect(
        (cam.x - width / 2 / cam.z) / 24,
        (cam.y - height / 2 / cam.z) / 24,
        width / cam.z / 24,
        height / cam.z / 24,
      );
      mg.fillStyle = "#fff3bc";
      mg.beginPath();
      mg.arc(s.hero.x / 24, s.hero.y / 24, 2, 0, 7);
      mg.fill();
    };
    raf = requestAnimationFrame(draw);
    const points = new Map<number, { x: number; y: number }>();
    let down = { x: 0, y: 0 },
      dragged = false,
      pinch = 0;
    const worldPoint = (x: number, y: number) => {
      const r = c.getBoundingClientRect(),
        cam = camera.current;
      return {
        x: cam.x + (x - r.left - width / 2) / cam.z,
        y: cam.y + (y - r.top - height / 2) / cam.z,
      };
    };
    const onDown = (e: PointerEvent) => {
      c.setPointerCapture(e.pointerId);
      points.set(e.pointerId, { x: e.clientX, y: e.clientY });
      down = { x: e.clientX, y: e.clientY };
      if (points.size === 1) dragged = false;
      if (points.size === 2) {
        dragged = true;
        const [a, b] = [...points.values()];
        pinch = Math.hypot(a.x - b.x, a.y - b.y);
      }
    };
    const onMove = (e: PointerEvent) => {
      const previous = points.get(e.pointerId);
      if (!previous) return;
      points.set(e.pointerId, { x: e.clientX, y: e.clientY });
      if (points.size === 2) {
        const [a, b] = [...points.values()],
          d = Math.hypot(a.x - b.x, a.y - b.y);
        camera.current.target = Math.max(
          0.3,
          Math.min(3, (camera.current.target * d) / (pinch || d)),
        );
        pinch = d;
        return;
      }
      if (Math.hypot(e.clientX - down.x, e.clientY - down.y) > 6)
        dragged = true;
      if (dragged) {
        camera.current.x -= (e.clientX - previous.x) / camera.current.z;
        camera.current.y -= (e.clientY - previous.y) / camera.current.z;
      }
    };
    const onUp = (e: PointerEvent) => {
      points.delete(e.pointerId);
      if (!dragged && live.current.started && e.type !== "pointercancel") {
        const hit = worldPoint(e.clientX, e.clientY);
        const current = live.current.state;
        const location = getWorld(current.worldSeed).settlements.find(
          (p) =>
            current.explored[p.tile] === "1" &&
            Math.hypot(hit.x - p.x, hit.y - p.y) < 42,
        );
        const p = location ? { x: location.x, y: location.y } : hit;
        const next = move(current, p);
        setMessage(next === current ? t.unreachable : "");
        if (next !== current) update((current) => move(current, p));
      }
    };
    const wheel = (e: WheelEvent) => {
      e.preventDefault();
      camera.current.target = Math.max(
        0.3,
        Math.min(3, camera.current.target * Math.exp(-e.deltaY * 0.001)),
      );
    };
    c.addEventListener("pointerdown", onDown);
    c.addEventListener("pointermove", onMove);
    c.addEventListener("pointerup", onUp);
    c.addEventListener("pointercancel", onUp);
    c.addEventListener("wheel", wheel, { passive: false });
    return () => {
      cancelAnimationFrame(raf);
      observer.disconnect();
      c.removeEventListener("pointerdown", onDown);
      c.removeEventListener("pointermove", onMove);
      c.removeEventListener("pointerup", onUp);
      c.removeEventListener("pointercancel", onUp);
      c.removeEventListener("wheel", wheel);
      cache.clear();
    };
  }, [update]);
  return (
    <div className="map-canvas">
      <canvas
        ref={canvas}
        aria-label={t.map}
        style={{ width: "100%", height: "100%", touchAction: "none" }}
      />
      <div className="map-tools">
        <button
          aria-label={t.zoomIn}
          onClick={() =>
            (camera.current.target = Math.min(3, camera.current.target * 1.3))
          }
        >
          <Plus />
        </button>
        <button
          aria-label={t.zoomOut}
          onClick={() =>
            (camera.current.target = Math.max(0.3, camera.current.target / 1.3))
          }
        >
          <Minus />
        </button>
        <button aria-label={t.locate} onClick={locate}>
          <LocateFixed />
        </button>
      </div>
      <canvas
        ref={mini}
        className="world-minimap"
        width={128}
        height={128}
        aria-label={t.minimap}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          const delta = e.shiftKey ? 384 : 96;
          if (e.key === "ArrowLeft") camera.current.x -= delta;
          if (e.key === "ArrowRight") camera.current.x += delta;
          if (e.key === "ArrowUp") camera.current.y -= delta;
          if (e.key === "ArrowDown") camera.current.y += delta;
          if (e.key === "Enter") locate();
          if (e.key.startsWith("Arrow")) e.preventDefault();
        }}
        onPointerDown={(e) => {
          const r = e.currentTarget.getBoundingClientRect();
          camera.current.x = ((e.clientX - r.left) / r.width) * WORLD.width;
          camera.current.y = ((e.clientY - r.top) / r.height) * WORLD.height;
        }}
      />
      <span className="world-seed">
        {t.seed}: {num(state.worldSeed)}
      </span>
      {message && (
        <p className="map-message" role="status">
          {message}
        </p>
      )}
    </div>
  );
}
