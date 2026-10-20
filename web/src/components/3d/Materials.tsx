import { useEffect, useMemo, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
export type Surface = "stone" | "wood" | "thatch" | "ground" | "sky";
export function useTexture(kind: Surface) {
  const texture = useMemo(() => {
    const c = document.createElement("canvas");
    c.width = c.height = 128;
    const g = c.getContext("2d")!;
    if (kind === "sky") {
      const gradient = g.createLinearGradient(0, 0, 0, 128);
      gradient.addColorStop(0, "#496c82");
      gradient.addColorStop(0.6, "#a4b7b4");
      gradient.addColorStop(1, "#e7d8af");
      g.fillStyle = gradient;
      g.fillRect(0, 0, 128, 128);
    } else {
      g.fillStyle = {
        stone: "#c3beaa",
        wood: "#9b7851",
        thatch: "#ba9e5d",
        ground: "#889070",
      }[kind];
      g.fillRect(0, 0, 128, 128);
      let seed = 5381;
      const rnd = () => {
        seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
        return seed / 4294967296;
      };
      for (let i = 0; i < 650; i++) {
        const x = rnd() * 128,
          y = rnd() * 128;
        g.fillStyle = i % 2 ? "#18211915" : "#fff1cc18";
        g.fillRect(x, y, kind === "thatch" ? 2 : 5, kind === "wood" ? 24 : 3);
      }
      g.strokeStyle = "#322f2450";
      g.lineWidth = 2;
      if (kind === "stone")
        for (let y = 0; y < 128; y += 24) {
          g.beginPath();
          g.moveTo(0, y);
          g.lineTo(128, y);
          g.stroke();
          for (let x = y % 48 ? 16 : 0; x < 128; x += 32) {
            g.beginPath();
            g.moveTo(x, y);
            g.lineTo(x, y + 24);
            g.stroke();
          }
        }
      if (kind === "wood")
        for (let x = 0; x < 128; x += 24) {
          g.beginPath();
          g.moveTo(x, 0);
          g.lineTo(x, 128);
          g.stroke();
        }
    }
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.wrapS = tex.wrapT =
      kind === "sky" ? THREE.ClampToEdgeWrapping : THREE.RepeatWrapping;
    if (kind === "ground") tex.repeat.set(4, 4);
    return tex;
  }, [kind]);
  useEffect(() => () => texture.dispose(), [texture]);
  return texture;
}
export function SurfaceMaterial({
  kind = "stone",
  color = "#ffffff",
}: {
  kind?: Surface;
  color?: string;
}) {
  const map = useTexture(kind);
  return <meshStandardMaterial map={map} color={color} roughness={0.95} />;
}
export function Sky() {
  const map = useTexture("sky");
  return (
    <mesh>
      <sphereGeometry args={[90, 24, 16]} />
      <meshBasicMaterial
        map={map}
        side={THREE.BackSide}
        depthWrite={false}
        fog={false}
      />
    </mesh>
  );
}
export function Banner({ height }: { height: number }) {
  const mesh = useRef<THREE.Mesh>(null);
  useFrame(({ clock }) => {
    const p = mesh.current!.geometry.attributes.position;
    for (let i = 0; i < p.count; i++) {
      const x = p.getX(i) + 0.22;
      p.setZ(i, Math.sin(x * 9 - clock.elapsedTime * 4) * x * 0.18);
    }
    p.needsUpdate = true;
  });
  return (
    <mesh ref={mesh} position={[0.22, height, 0]}>
      <planeGeometry args={[0.44, 0.28, 8, 2]} />
      <meshStandardMaterial
        color="#c6a34b"
        side={THREE.DoubleSide}
        roughness={0.8}
      />
    </mesh>
  );
}
export function Torches() {
  const light = useRef<THREE.PointLight>(null),
    flame = useRef<THREE.Mesh>(null);
  useFrame(({ clock }) => {
    const v =
      1 +
      Math.sin(clock.elapsedTime * 13) * 0.18 +
      Math.sin(clock.elapsedTime * 21) * 0.1;
    light.current!.intensity = 3 * v;
    flame.current!.scale.y = v;
  });
  return (
    <group position={[0, 0.9, 0.5]}>
      <mesh position={[0, -0.12, 0]}>
        <cylinderGeometry args={[0.025, 0.025, 0.3, 5]} />
        <meshStandardMaterial color="#57462f" />
      </mesh>
      <mesh ref={flame}>
        <coneGeometry args={[0.06, 0.2, 6]} />
        <meshBasicMaterial color="#ffb343" />
      </mesh>
      <pointLight ref={light} color="#ffb64f" distance={3} decay={2} />
    </group>
  );
}
