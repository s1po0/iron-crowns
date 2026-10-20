import { useFrame } from "@react-three/fiber";
import { useMemo, useRef } from "react";
import * as THREE from "three";
import { Stage } from "./Scene";
import { SurfaceMaterial } from "./Materials";
import { useGame } from "../../game/engine/store";
import { renderBudget, type Quality } from "../../game/data/world";
function Army({ side, count }: { side: number; count: number }) {
  const body = useRef<THREE.InstancedMesh>(null),
    heads = useRef<THREE.InstancedMesh>(null),
    weapons = useRef<THREE.InstancedMesh>(null),
    shields = useRef<THREE.InstancedMesh>(null),
    o = useMemo(() => new THREE.Object3D(), []),
    start = useRef<number | null>(null);
  useFrame(({ clock }) => {
    start.current ??= clock.elapsedTime;
    const time = clock.elapsedTime - start.current;
    for (let i = 0; i < count; i++) {
      const contact = time > 3.5,
        x = side * (Math.max(0.5, 5 - time * 1.2) + (i % 3) * 0.55),
        z = (Math.floor(i / 3) - Math.ceil(count / 3) / 2) * 0.6,
        y = 0.48 + Math.abs(Math.sin(time * 10 + i)) * (contact ? 0.02 : 0.06);
      o.position.set(x, y, z);
      o.rotation.set(0, 0, contact ? Math.sin(time * 7 + i) * 0.1 : 0);
      o.scale.set(1, 1, 1);
      o.updateMatrix();
      body.current!.setMatrixAt(i, o.matrix);
      o.position.y = y + 0.43;
      o.updateMatrix();
      heads.current!.setMatrixAt(i, o.matrix);
      o.position.set(x - side * 0.19, y + 0.12, z + 0.2);
      o.rotation.z = contact
        ? side * (0.6 + Math.sin(time * 9 + i) * 1.1)
        : side * 0.3;
      o.updateMatrix();
      weapons.current!.setMatrixAt(i, o.matrix);
      o.position.set(x - side * 0.18, y, z - 0.18);
      o.rotation.set(0, 0, Math.PI / 2);
      o.updateMatrix();
      shields.current!.setMatrixAt(i, o.matrix);
    }
    for (const mesh of [body, heads, weapons, shields])
      mesh.current!.instanceMatrix.needsUpdate = true;
  });
  return (
    <>
      <instancedMesh ref={body} args={[undefined, undefined, count]}>
        <capsuleGeometry args={[0.15, 0.42, 2, 6]} />
        <meshStandardMaterial color={side > 0 ? "#a45b50" : "#b9aa76"} />
      </instancedMesh>
      <instancedMesh ref={heads} args={[undefined, undefined, count]}>
        <sphereGeometry args={[0.13, 7, 5]} />
        <meshStandardMaterial color="#bac0b5" />
      </instancedMesh>
      <instancedMesh ref={weapons} args={[undefined, undefined, count]}>
        <boxGeometry args={[0.04, 0.62, 0.035]} />
        <meshStandardMaterial
          color="#d9ded7"
          metalness={0.55}
          roughness={0.4}
        />
      </instancedMesh>
      <instancedMesh ref={shields} args={[undefined, undefined, count]}>
        <cylinderGeometry args={[0.19, 0.19, 0.05, 8]} />
        <meshStandardMaterial color={side > 0 ? "#704238" : "#746945"} />
      </instancedMesh>
    </>
  );
}
function Effects({ quality }: { quality: Quality }) {
  const dust = useRef<THREE.InstancedMesh>(null),
    arrows = useRef<THREE.InstancedMesh>(null),
    o = useMemo(() => new THREE.Object3D(), []),
    n = renderBudget[quality].particles;
  useFrame(({ clock }) => {
    const t = clock.elapsedTime;
    for (let i = 0; i < n; i++) {
      const p = (t * 0.6 + i * 0.137) % 1;
      o.position.set(
        Math.sin(i * 2.4) * 3 + p * 0.6,
        p * 0.9 + 0.1,
        Math.cos(i * 2.4) * 3,
      );
      o.rotation.set(0, 0, 0);
      o.scale.setScalar(0.1 + p * 0.3);
      o.updateMatrix();
      dust.current!.setMatrixAt(i, o.matrix);
      const flight = (t * 0.7 + i * 0.27) % 1,
        side = i % 2 ? 1 : -1;
      o.position.set(
        side * (5 - flight * 10),
        1 + Math.sin(flight * Math.PI) * 3,
        ((i % 7) - 3) * 0.6,
      );
      o.scale.set(1, 1, 1);
      o.rotation.z = side * Math.atan2(Math.cos(flight * Math.PI) * 9, -10);
      o.updateMatrix();
      arrows.current!.setMatrixAt(i, o.matrix);
    }
    dust.current!.instanceMatrix.needsUpdate =
      arrows.current!.instanceMatrix.needsUpdate = true;
  });
  return (
    <>
      <instancedMesh ref={dust} args={[undefined, undefined, n]}>
        <sphereGeometry args={[1, 5, 3]} />
        <meshBasicMaterial
          color="#c3b28a"
          transparent
          opacity={0.12}
          depthWrite={false}
        />
      </instancedMesh>
      <instancedMesh ref={arrows} args={[undefined, undefined, n]}>
        <boxGeometry args={[0.4, 0.018, 0.018]} />
        <meshBasicMaterial color="#514735" />
      </instancedMesh>
    </>
  );
}
export default function BattleScene() {
  const { quality, state } = useGame(),
    cap = renderBudget[quality].army,
    allies = Object.values(state.party).reduce((a, b) => a + b, 0),
    enemy =
      state.battle === null
        ? 18
        : Math.ceil(state.enemies[state.battle].strength / 4);
  return (
    <Stage quality={quality}>
      <mesh rotation={[-Math.PI / 2, 0, 0]}>
        <planeGeometry args={[80, 80]} />
        <SurfaceMaterial kind="ground" />
      </mesh>
      <Army side={1} count={Math.min(cap, Math.max(1, enemy))} />
      <Army side={-1} count={Math.min(cap, Math.max(1, allies))} />
      <Effects quality={quality} />
    </Stage>
  );
}
