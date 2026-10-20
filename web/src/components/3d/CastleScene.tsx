import { Torches } from "./Materials";
import { Stage, Landscape, Model, Smoke } from "./Scene";
import { useGame } from "../../game/engine/store";
import { canBuild } from "../../game/engine/simulation";
import { GRID, buildings, type Building } from "../../game/data/buildings";
export default function CastleScene({
  chosen,
  cell,
  onCell,
}: {
  chosen: Building;
  cell: { x: number; z: number } | null;
  onCell: (p: { x: number; z: number }) => void;
}) {
  const { state, quality } = useGame();
  return (
    <Stage quality={quality}>
      <Landscape quality={quality} destinations={state.buildings} />
      <gridHelper
        args={[GRID, GRID, "#aca98a", "#95967b"]}
        position={[-0.5, 0.015, -0.5]}
      />
      <mesh
        rotation={[-Math.PI / 2, 0, 0]}
        position={[-0.5, 0.02, -0.5]}
        onClick={(e) => {
          e.stopPropagation();
          if (e.delta > 5) return;
          onCell({
            x: Math.floor(e.point.x + GRID / 2 + 0.5),
            z: Math.floor(e.point.z + GRID / 2 + 0.5),
          });
        }}
      >
        <planeGeometry args={[GRID, GRID]} />
        <meshBasicMaterial transparent opacity={0} depthWrite={false} />
      </mesh>
      {state.buildings.map((b) => (
        <group
          key={`${b.x}:${b.z}`}
          position={[b.x - GRID / 2, 0, b.z - GRID / 2]}
        >
          <Model type={b.type} />
          {quality === "high" &&
            state.buildings
              .filter((p) => p.type === "keep" || p.type === "gate")
              .slice(0, 2)
              .includes(b) && <Torches />}
        </group>
      ))}
      {cell && (
        <mesh
          position={[
            cell.x - GRID / 2,
            buildings[chosen].height / 2,
            cell.z - GRID / 2,
          ]}
        >
          <boxGeometry args={[0.9, buildings[chosen].height, 0.9]} />
          <meshBasicMaterial
            color={
              canBuild(state, chosen, cell.x, cell.z) ? "#8ace8f" : "#e17665"
            }
            transparent
            opacity={0.5}
            depthWrite={false}
          />
        </mesh>
      )}
      <Smoke sources={state.buildings.filter((b) => b.type === "woodcutter")} />
    </Stage>
  );
}
