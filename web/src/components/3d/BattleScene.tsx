import { useFrame } from "@react-three/fiber";
import { useMemo, useRef } from "react";
import * as THREE from "three";
import { Stage } from "./Scene";
import { useGame } from "../../game/engine/store";
function Army({ side }: { side: number }) {
  const m = useRef<THREE.InstancedMesh>(null),
    o = useMemo(() => new THREE.Object3D(), []),
    start = useRef<number | null>(null);
  useFrame(({ clock }) => {
    start.current ??= clock.elapsedTime;
    const time = clock.elapsedTime - start.current;
    for (let i = 0; i < 18; i++) {
      o.position.set(
        side * Math.max(0.45, 5 - time * 1.2) + (i % 3) * side * 0.28,
        0.45 + Math.abs(Math.sin(time * 10 + i)) * 0.07,
        (Math.floor(i / 3) - 3) * 0.55,
      );
      o.rotation.set(0, 0, time > 3.5 ? Math.sin(i + time) * 0.1 : 0);
      o.updateMatrix();
      m.current!.setMatrixAt(i, o.matrix);
    }
    m.current!.instanceMatrix.needsUpdate = true;
  });
  return (
    <instancedMesh ref={m} args={[undefined, undefined, 18]}>
      <capsuleGeometry args={[0.16, 0.5, 2, 6]} />
      <meshStandardMaterial color={side > 0 ? "#a45b50" : "#c1ad72"} />
    </instancedMesh>
  );
}
export default function BattleScene() {
  const { quality } = useGame();
  return (
    <Stage quality={quality}>
      <mesh rotation={[-Math.PI / 2, 0, 0]}>
        <planeGeometry args={[80, 80]} />
        <meshStandardMaterial color="#56624b" />
      </mesh>
      <Army side={1} />
      <Army side={-1} />
    </Stage>
  );
}
