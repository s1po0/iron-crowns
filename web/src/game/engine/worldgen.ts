import { createNoise2D } from "simplex-noise";
import { MAP, TERRAIN, terrainCost } from "../data/world";
export type Point = { x: number; y: number };
export type Settlement = Point & {
  id: number;
  faction: number;
  kind: "town" | "village" | "camp";
  tile: number;
};
export type World = {
  seed: number;
  tiles: Uint8Array;
  base: Uint8Array;
  heights: Float32Array;
  owner: Int8Array;
  settlements: Settlement[];
};
export function random(seed: number) {
  let a = seed >>> 0;
  return () => {
    a += 0x6d2b79f5;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
export const center = (id: number): Point => ({
  x: ((id % MAP.size) + 0.5) * MAP.tile,
  y: (Math.floor(id / MAP.size) + 0.5) * MAP.tile,
});
export const tileAt = (p: Point) =>
  Math.floor(p.y / MAP.tile) * MAP.size + Math.floor(p.x / MAP.tile);
export const neighbors = (id: number) => {
  const x = id % MAP.size,
    y = Math.floor(id / MAP.size);
  const r: number[] = [];
  if (x > 0) r.push(id - 1);
  if (x < MAP.size - 1) r.push(id + 1);
  if (y > 0) r.push(id - MAP.size);
  if (y < MAP.size - 1) r.push(id + MAP.size);
  return r;
};
export const walkable = (w: Pick<World, "tiles">, id: number) =>
  id >= 0 && id < w.tiles.length && Number.isFinite(terrainCost[w.tiles[id]]);
class Heap {
  a: { id: number; f: number }[] = [];
  push(id: number, f: number) {
    const v = { id, f };
    let i = this.a.length;
    this.a.push(v);
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (this.a[p].f <= f) break;
      this.a[i] = this.a[p];
      i = p;
    }
    this.a[i] = v;
  }
  pop() {
    const root = this.a[0],
      v = this.a.pop()!;
    if (this.a.length) {
      let i = 0;
      while (i * 2 + 1 < this.a.length) {
        let c = i * 2 + 1;
        if (c + 1 < this.a.length && this.a[c + 1].f < this.a[c].f) c++;
        if (this.a[c].f >= v.f) break;
        this.a[i] = this.a[c];
        i = c;
      }
      this.a[i] = v;
    }
    return root.id;
  }
}
/** Four-neighbor weighted A*: no diagonal water/corner cutting. Admissible road-cost heuristic. */
export function findPath(
  w: Pick<World, "tiles">,
  start: number,
  end: number,
): number[] {
  if (!walkable(w, start) || !walkable(w, end)) return [];
  if (start === end) return [start];
  const n = MAP.size * MAP.size,
    g = new Float64Array(n).fill(Infinity),
    from = new Int32Array(n).fill(-1),
    closed = new Uint8Array(n),
    heap = new Heap();
  const h = (id: number) =>
    (Math.abs((id % MAP.size) - (end % MAP.size)) +
      Math.abs(Math.floor(id / MAP.size) - Math.floor(end / MAP.size))) *
    terrainCost[TERRAIN.road];
  g[start] = 0;
  heap.push(start, h(start));
  while (heap.a.length) {
    const id = heap.pop();
    if (closed[id]) continue;
    if (id === end) {
      const path = [end];
      let at = end;
      while (at !== start) {
        at = from[at];
        path.push(at);
      }
      return path.reverse();
    }
    closed[id] = 1;
    for (const next of neighbors(id)) {
      if (closed[next] || !walkable(w, next)) continue;
      const score = g[id] + terrainCost[w.tiles[next]];
      if (score < g[next]) {
        g[next] = score;
        from[next] = id;
        heap.push(next, score + h(next));
      }
    }
  }
  return [];
}
function largestLand(tiles: Uint8Array) {
  const seen = new Uint8Array(tiles.length);
  let biggest: number[] = [];
  for (let i = 0; i < tiles.length; i++) {
    if (seen[i] || !walkable({ tiles }, i)) continue;
    const component = [i];
    seen[i] = 1;
    for (let a = 0; a < component.length; a++)
      for (const next of neighbors(component[a]))
        if (!seen[next] && walkable({ tiles }, next)) {
          seen[next] = 1;
          component.push(next);
        }
    if (component.length > biggest.length) biggest = component;
  }
  return biggest;
}
const worlds = new Map<number, World>();
export function getWorld(seed: number): World {
  seed = seed >>> 0;
  if (worlds.has(seed)) return worlds.get(seed)!;
  const rng = random(seed),
    noise = createNoise2D(rng),
    wet = createNoise2D(random(seed ^ 0xabc123)),
    n = MAP.size * MAP.size,
    tiles = new Uint8Array(n),
    heights = new Float32Array(n);
  for (let y = 0; y < MAP.size; y++)
    for (let x = 0; x < MAP.size; x++) {
      const id = y * MAP.size + x,
        dx = (x - 64) / 60,
        dy = (y - 64) / 57;
      const h =
        0.68 -
        0.47 * (dx * dx + dy * dy) +
        noise(x * 0.035, y * 0.035) * 0.2 +
        noise(x * 0.105, y * 0.105) * 0.055;
      heights[id] = h;
      tiles[id] =
        h < 0.12
          ? TERRAIN.water
          : h > 0.73
            ? TERRAIN.mountains
            : h > 0.59
              ? TERRAIN.hills
              : wet(x * 0.065, y * 0.065) > 0.05
                ? TERRAIN.forest
                : TERRAIN.plains;
    }
  // Rivers meander downhill toward the nearer shoreline; never turn water into a road.
  for (let r = 0; r < 3; r++) {
    let x = 34 + r * 28,
      y = 25 + Math.floor(rng() * 15);
    for (let step = 0; step < 100; step++) {
      const id = y * MAP.size + x;
      if (tiles[id] === TERRAIN.water) break;
      tiles[id] = TERRAIN.river;
      const choices = [
        { x: x - 1, y: y + 1 },
        { x, y: y + 1 },
        { x: x + 1, y: y + 1 },
      ].filter((p) => p.x > 2 && p.x < 125 && p.y < 126);
      if (!choices.length) break;
      choices.sort(
        (a, b) =>
          heights[a.y * 128 + a.x] +
          wet(a.x * 0.2, a.y * 0.2) * 0.06 -
          (heights[b.y * 128 + b.x] + wet(b.x * 0.2, b.y * 0.2) * 0.06),
      );
      const next = choices[0]; // Fill diagonal gap so the river is contiguous.
      if (next.x !== x) tiles[y * 128 + next.x] = TERRAIN.river;
      x = next.x;
      y = next.y;
    }
  }
  for (const y of [52, 84])
    for (let x = 1; x < 127; x++)
      if (tiles[y * 128 + x] === TERRAIN.river)
        tiles[y * 128 + x] = TERRAIN.plains;
  const land = largestLand(tiles),
    anchors = [
      [32, 47],
      [96, 45],
      [65, 96],
    ],
    settlements: Settlement[] = [];
  const available = land.map((id) => ({ id, jitter: rng() * 28 }));
  for (let f = 0; f < 3; f++) {
    const [ax, ay] = anchors[f];
    const choices = [...available].sort(
      (a, b) =>
        Math.hypot((a.id % 128) - ax, Math.floor(a.id / 128) - ay) +
        a.jitter -
        Math.hypot((b.id % 128) - ax, Math.floor(b.id / 128) - ay) -
        b.jitter,
    );
    for (let k = 0; k < 8; k++) {
      const candidate = choices.find((c) =>
        settlements.every(
          (s) =>
            Math.hypot(
              (s.tile % 128) - (c.id % 128),
              Math.floor(s.tile / 128) - Math.floor(c.id / 128),
            ) >= MAP.spacing,
        ),
      );
      if (!candidate) throw Error("World settlement spacing failed");
      const id = f * 8 + k;
      settlements.push({
        ...center(candidate.id),
        tile: candidate.id,
        id,
        faction: f,
        kind: k < 3 ? "town" : "village",
      });
      tiles[candidate.id] = TERRAIN.plains;
    }
  }
  for (let k = 0; k < MAP.camps; k++) {
    const choices = [...available].sort((a, b) => a.jitter - b.jitter);
    const c = choices.find((c) =>
      settlements.every(
        (s) =>
          Math.hypot(
            (s.tile % 128) - (c.id % 128),
            Math.floor(s.tile / 128) - Math.floor(c.id / 128),
          ) >= MAP.spacing,
      ),
    );
    if (!c) throw Error("World camp spacing failed");
    settlements.push({
      ...center(c.id),
      tile: c.id,
      id: 24 + k,
      faction: -1,
      kind: "camp",
    });
    tiles[c.id] = TERRAIN.plains;
  }
  const base = tiles.slice(),
    owner = new Int8Array(n).fill(-1),
    world: World = { seed, tiles, base, heights, owner, settlements };
  // Prim spanning tree connects all locations. Every edge is routed by weighted A*.
  const connected = new Set([0]);
  while (connected.size < settlements.length) {
    let best = Infinity,
      a = 0,
      b = 0;
    for (const i of connected)
      for (let j = 0; j < settlements.length; j++) {
        if (connected.has(j)) continue;
        const d = Math.hypot(
          settlements[i].x - settlements[j].x,
          settlements[i].y - settlements[j].y,
        );
        if (d < best) {
          best = d;
          a = i;
          b = j;
        }
      }
    const path = findPath(world, settlements[a].tile, settlements[b].tile);
    if (!path.length) throw Error("Disconnected settlement");
    for (const id of path) tiles[id] = TERRAIN.road;
    connected.add(b);
  }
  for (let i = 0; i < n; i++) {
    if (!walkable(world, i)) continue;
    let d = Infinity;
    for (const s of settlements) {
      if (s.faction < 0) continue;
      const dist = Math.hypot(
        (i % 128) - (s.tile % 128),
        Math.floor(i / 128) - Math.floor(s.tile / 128),
      );
      if (dist < d) {
        d = dist;
        owner[i] = s.faction;
      }
    }
  }
  worlds.set(seed, world);
  if (worlds.size > 3) worlds.delete(worlds.keys().next().value!);
  return world;
}
export function reveal(explored: string, p: Point) {
  const tile = tileAt(p),
    x = tile % 128,
    y = Math.floor(tile / 128);
  let chars: string[] | null = null;
  for (let dy = -MAP.vision; dy <= MAP.vision; dy++)
    for (let dx = -MAP.vision; dx <= MAP.vision; dx++) {
      const tx = x + dx,
        ty = y + dy;
      if (
        tx < 0 ||
        ty < 0 ||
        tx >= 128 ||
        ty >= 128 ||
        dx * dx + dy * dy > MAP.vision ** 2
      )
        continue;
      const id = ty * 128 + tx;
      if (explored[id] !== "1") {
        chars ??= explored.split("");
        chars[id] = "1";
      }
    }
  return chars ? chars.join("") : explored;
}
export function nearestLand(w: World, p: Point) {
  let best = w.settlements[0].tile,
    d = Infinity;
  for (let id = 0; id < w.tiles.length; id++) {
    if (!walkable(w, id)) continue;
    const c = center(id),
      distance = Math.hypot(c.x - p.x, c.y - p.y);
    if (distance < d) {
      d = distance;
      best = id;
    }
  }
  return center(best);
}
