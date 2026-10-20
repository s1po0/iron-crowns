import { SurfaceMaterial, Sky, Banner } from "./Materials";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import { useEffect, useMemo, useRef, type ReactNode } from "react";
import * as THREE from "three";
import type { OrbitControls as Controls } from "three-stdlib";
import { buildings, GRID, type Building } from "../../game/data/buildings";
import { qualitySettings, type Quality } from "../../game/data/world";
function FrameLimit({ quality }: { quality: Quality }) {
  const advance = useThree((s) => s.advance);
  useEffect(() => {
    let frame = 0,
      last = 0;
    const draw = (now: number) => {
      frame = requestAnimationFrame(draw);
      if (
        !document.hidden &&
        now - last >= 1000 / qualitySettings[quality].fps
      ) {
        last = now;
        advance(now / 1000, true);
      }
    };
    frame = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(frame);
  }, [advance, quality]);
  return null;
}
function CameraControls() {
  const controls = useRef<Controls>(null);
  const { gl, camera } = useThree();
  useEffect(() => {
    let last: number | null = null;
    const rotate = (e: TouchEvent) => {
      if (e.touches.length !== 2) {
        last = null;
        return;
      }
      const [a, b] = [e.touches[0], e.touches[1]],
        angle = Math.atan2(b.clientY - a.clientY, b.clientX - a.clientX);
      if (last !== null && controls.current) {
        const delta = Math.atan2(
          Math.sin(angle - last),
          Math.cos(angle - last),
        );
        camera.position
          .sub(controls.current.target)
          .applyAxisAngle(new THREE.Vector3(0, 1, 0), -delta)
          .add(controls.current.target);
        controls.current.update();
      }
      last = angle;
    };
    const end = () => {
      last = null;
    };
    gl.domElement.addEventListener("touchmove", rotate, { passive: true });
    gl.domElement.addEventListener("touchend", end);
    return () => {
      gl.domElement.removeEventListener("touchmove", rotate);
      gl.domElement.removeEventListener("touchend", end);
    };
  }, [gl, camera]);
  useFrame(() => {
    if (controls.current) {
      const target = controls.current.target;
      const x = THREE.MathUtils.clamp(target.x, -4, 4),
        z = THREE.MathUtils.clamp(target.z, -4, 4);
      camera.position.x += x - target.x;
      camera.position.z += z - target.z;
      target.x = x;
      target.z = z;
    }
  });
  return (
    <OrbitControls
      ref={controls}
      makeDefault
      minDistance={8}
      maxDistance={28}
      minPolarAngle={0.35}
      maxPolarAngle={1.25}
      enableDamping
      dampingFactor={0.1}
      target={[0, 0, 0]}
    />
  );
}
export function Stage({
  children,
  quality,
}: {
  children: ReactNode;
  quality: Quality;
}) {
  return (
    <Canvas
      frameloop="never"
      dpr={Math.min(window.devicePixelRatio || 1, qualitySettings[quality].dpr)}
      shadows={false}
      camera={{ position: [13, 15, 16], fov: 42, near: 0.1, far: 120 }}
      gl={{ antialias: quality !== "low", powerPreference: "low-power" }}
    >
      <color attach="background" args={["#1e3036"]} />
      <fog attach="fog" args={["#a4b7b4", 25, 65]} />
      <Sky />
      <ambientLight intensity={0.45} />
      <hemisphereLight args={["#e7e9cd", "#4c6151", 1.5]} />
      <directionalLight position={[8, 15, 4]} intensity={2.1} color="#ffe2b0" />
      <FrameLimit quality={quality} />
      <CameraControls />
      {children}
    </Canvas>
  );
}
function Box({
  position = [0, 0, 0],
  size = [1, 1, 1],
  color = "#b1a68e",
}: {
  position?: [number, number, number];
  size?: [number, number, number];
  color?: string;
}) {
  return (
    <mesh position={position}>
      <boxGeometry args={size} />
      <SurfaceMaterial
        color={color}
        kind={color === "#65503a" || color === "#6e5337" ? "wood" : "stone"}
      />
    </mesh>
  );
}
export function Model({ type }: { type: Building }) {
  const d = buildings[type];
  if (type === "farm")
    return (
      <group>
        <Box size={[0.9, 0.12, 0.9]} position={[0, 0.06, 0]} color="#6e5337" />
        {Array.from({ length: 5 }, (_, i) => (
          <Box
            key={i}
            position={[-0.35 + i * 0.17, 0.17, 0]}
            size={[0.07, 0.14, 0.8]}
            color="#c4aa58"
          />
        ))}
      </group>
    );
  if (type === "wall")
    return (
      <group>
        <Box size={[0.95, 1.1, 0.32]} position={[0, 0.55, 0]} color={d.color} />
        {[-0.32, 0, 0.32].map((x) => (
          <Box key={x} position={[x, 1.17, 0]} size={[0.18, 0.2, 0.35]} />
        ))}
      </group>
    );
  if (type === "stockpile" || type === "quarry")
    return (
      <group>
        {Array.from({ length: 6 }, (_, i) => (
          <Box
            key={i}
            position={[
              ((i % 3) - 1) * 0.25,
              0.16 + Math.floor(i / 3) * 0.21,
              Math.floor(i / 3) * 0.23,
            ]}
            size={[0.22, 0.24, 0.32]}
            color={d.color}
          />
        ))}
      </group>
    );
  if (type === "gate")
    return (
      <group>
        <Box position={[-0.35, 0.7, 0]} size={[0.24, 1.4, 0.5]} />
        <Box position={[0.35, 0.7, 0]} size={[0.24, 1.4, 0.5]} />
        <Box position={[0, 1.35, 0]} size={[0.9, 0.32, 0.55]} />
        <Box
          position={[0, 0.55, 0.12]}
          size={[0.45, 1.1, 0.1]}
          color="#65503a"
        />
      </group>
    );
  const castle = type === "keep" || type === "tower";
  return (
    <group>
      <Box
        position={[0, d.height / 2, 0]}
        size={[0.8, d.height, 0.8]}
        color={d.color}
      />
      {type === "tower" && (
        <mesh position={[0, d.height + 0.35, 0]} rotation={[0, Math.PI / 4, 0]}>
          <coneGeometry args={[0.75, 0.7, 4]} />
          <SurfaceMaterial kind="wood" color="#707b78" />
        </mesh>
      )}
      {castle ? (
        [-0.3, 0.3].flatMap((x) =>
          [-0.3, 0.3].map((z) => (
            <Box
              key={`${x}${z}`}
              position={[x, d.height + 0.12, z]}
              size={[0.24, 0.3, 0.24]}
            />
          )),
        )
      ) : (
        <mesh position={[0, d.height + 0.25, 0]} rotation={[0, Math.PI / 4, 0]}>
          <coneGeometry args={[0.72, 0.55, 4]} />
          <SurfaceMaterial kind="thatch" />
        </mesh>
      )}
      <Box
        position={[0, 0.24, 0.405]}
        size={[0.2, 0.48, 0.02]}
        color="#3b4035"
      />
      {castle && (
        <>
          <Box
            position={[0, d.height + 0.55, 0]}
            size={[0.03, 0.8, 0.03]}
            color="#443f30"
          />
          <Banner height={d.height + 0.8} />
          {[-0.22, 0.22].map((x) => (
            <Box
              key={x}
              position={[x, d.height * 0.68, 0.405]}
              size={[0.1, 0.22, 0.02]}
              color="#3e493d"
            />
          ))}
        </>
      )}
      {type === "woodcutter" && (
        <Box
          position={[0.2, d.height + 0.3, 0.1]}
          size={[0.15, 0.6, 0.16]}
          color="#999585"
        />
      )}
    </group>
  );
}
function Trees({ quality }: { quality: Quality }) {
  const mesh = useRef<THREE.InstancedMesh>(null),
    n = qualitySettings[quality].trees;
  useEffect(() => {
    const o = new THREE.Object3D();
    for (let i = 0; i < n; i++) {
      const angle = i * 2.399,
        rad = 8 + (i % 9) * 0.7;
      o.position.set(Math.cos(angle) * rad, 0.7, Math.sin(angle) * rad);
      o.scale.setScalar(0.6 + (i % 5) * 0.12);
      o.updateMatrix();
      mesh.current!.setMatrixAt(i, o.matrix);
    }
    mesh.current!.instanceMatrix.needsUpdate = true;
  }, [n]);
  return (
    <instancedMesh ref={mesh} args={[undefined, undefined, n]}>
      <coneGeometry args={[0.5, 1.7, 6]} />
      <meshStandardMaterial color="#405f4b" />
    </instancedMesh>
  );
}
function Workers({
  quality,
  destinations,
}: {
  quality: Quality;
  destinations: { x: number; z: number }[];
}) {
  const bodies = useRef<THREE.InstancedMesh>(null),
    heads = useRef<THREE.InstancedMesh>(null),
    n = qualitySettings[quality].workers,
    o = useMemo(() => new THREE.Object3D(), []);
  useFrame(({ clock }) => {
    for (let i = 0; i < n; i++) {
      const phase = clock.elapsedTime * 0.12 + i * 0.37,
        index = Math.floor(phase),
        progress = phase % 1;
      const a = destinations[(index + i) % destinations.length] || {
          x: 5,
          z: 5,
        },
        b = destinations[(index + i + 1) % destinations.length] || a;
      // Footpaths bend at right angles between active building entrances.
      const x =
        progress < 0.5 ? THREE.MathUtils.lerp(a.x, b.x, progress * 2) : b.x;
      const z =
        progress < 0.5
          ? a.z
          : THREE.MathUtils.lerp(a.z, b.z, (progress - 0.5) * 2);
      o.position.set(
        x - GRID / 2 + 0.5,
        0.22 + Math.abs(Math.sin(clock.elapsedTime * 5 + i)) * 0.025,
        z - GRID / 2 + 0.55,
      );
      o.scale.set(1, 1, 1);
      o.updateMatrix();
      bodies.current!.setMatrixAt(i, o.matrix);
      o.position.y += 0.24;
      o.updateMatrix();
      heads.current!.setMatrixAt(i, o.matrix);
    }
    bodies.current!.instanceMatrix.needsUpdate = true;
    heads.current!.instanceMatrix.needsUpdate = true;
  });
  return (
    <>
      <instancedMesh ref={bodies} args={[undefined, undefined, n]}>
        <boxGeometry args={[0.17, 0.3, 0.13]} />
        <meshStandardMaterial color="#8f795c" />
      </instancedMesh>
      <instancedMesh ref={heads} args={[undefined, undefined, n]}>
        <sphereGeometry args={[0.09, 6, 4]} />
        <meshStandardMaterial color="#cfb293" />
      </instancedMesh>
    </>
  );
}
function Smoke({ sources }: { sources: { x: number; z: number }[] }) {
  const m = useRef<THREE.InstancedMesh>(null),
    o = useMemo(() => new THREE.Object3D(), []);
  useFrame(({ clock }) => {
    sources.forEach((s, i) => {
      for (let j = 0; j < 4; j++) {
        const phase = (clock.elapsedTime * 0.3 + j * 0.25) % 1;
        o.position.set(
          s.x - GRID / 2 + 0.2 + phase * 0.5,
          1.5 + phase * 1.7,
          s.z - GRID / 2 + 0.1,
        );
        o.scale.setScalar(0.1 + phase * 0.22);
        o.updateMatrix();
        m.current!.setMatrixAt(i * 4 + j, o.matrix);
      }
    });
    if (m.current) m.current.instanceMatrix.needsUpdate = true;
  });
  return (
    <instancedMesh
      ref={m}
      args={[undefined, undefined, Math.max(1, sources.length * 4)]}
      count={sources.length * 4}
    >
      <sphereGeometry args={[1, 6, 4]} />
      <meshBasicMaterial
        color="#c4c7b9"
        transparent
        opacity={0.23}
        depthWrite={false}
      />
    </instancedMesh>
  );
}
export function Landscape({
  quality,
  destinations,
}: {
  quality: Quality;
  destinations: { x: number; z: number }[];
}) {
  return (
    <>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.05, 0]}>
        <planeGeometry args={[80, 80]} />
        <SurfaceMaterial kind="ground" color="#81926f" />
      </mesh>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.02, 0]}>
        <planeGeometry args={[GRID, GRID]} />
        <SurfaceMaterial kind="ground" />
      </mesh>
      <Trees quality={quality} />
      <Workers quality={quality} destinations={destinations} />
    </>
  );
}
export { Smoke };
