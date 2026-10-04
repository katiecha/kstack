---
name: create-3d
description: Best practices for building interactive 3D scenes with React Three Fiber (R3F), Three.js, and Drei in a Next.js App Router project. Use when adding a new 3D scene, animated component, GLSL shader, or canvas-based interactive feature.
---

# Interactive 3D with React Three Fiber

R3F + Three.js + Drei patterns for Next.js App Router. Distilled from a production sailing game with GLSL ocean shaders, physics-based sail simulation, animated fish, and postprocessing.

---

## Component structure

### Always mark interactive 3D components `"use client"`
R3F uses browser APIs (`WebGLRenderer`, `requestAnimationFrame`). Any file with `<Canvas>` or `useFrame` needs the directive.

```tsx
"use client";
import { Canvas, useFrame } from "@react-three/fiber";
```

### Isolate the Canvas in a scene component
Keep the `<Canvas>` in its own component (`SailboatScene`, `GalleryOceanBackground`), not in the page. The page just mounts the scene component and overlays DOM UI on top.

```tsx
// page.tsx
export default function Page() {
  return (
    <main className="relative w-screen h-[100dvh] overflow-hidden touch-none">
      <MyScene />                      {/* full-bleed canvas */}
      <div className="absolute ...">  {/* DOM UI overlaid */}
        <button>...</button>
      </div>
    </main>
  );
}
```

For background-only canvases (gallery pages, loading screens), wrap the Canvas in a `pointer-events-none fixed inset-0 z-0` div so DOM content stays interactive:

```tsx
<div className="pointer-events-none fixed inset-0 z-0">
  <Canvas ...>...</Canvas>
</div>
```

---

## Performance

### Never use `useState` for per-frame values
Calling `setState` inside `useFrame` triggers a React re-render on every frame (60×/sec). Use `useRef` for anything that changes every frame:

```tsx
// Wrong, causes re-render every frame
const [elapsed, setElapsed] = useState(0);
useFrame((_, delta) => setElapsed(t => t + delta));

// Correct, mutate the ref directly
const elapsedRef = useRef(0);
useFrame((_, delta) => { elapsedRef.current += delta; });
```

Same rule for: velocity, keys held, mouse position, animation angles.

### Accumulate time with a ref, not `state.clock`
This lets the scene reset or pause independently of the global clock:

```tsx
const elapsedRef = useRef(0);
useFrame((_, delta) => {
  elapsedRef.current += delta;
  const t = elapsedRef.current;
  // use t for sine/cosine animation
});
```

### Always multiply motion by `delta` for frame-rate independence
```tsx
// Wrong, speed tied to frame rate
boat.position.z -= 0.1;

// Correct, consistent at any FPS
boat.position.z -= SPEED * delta;
```

### Memoize uniforms and procedural textures
Uniform objects and `CanvasTexture` creation are expensive. Wrap in `useMemo`:

```tsx
const uniforms = useMemo(() => ({
  uTime: { value: 0 },
  uDeepColor: { value: new THREE.Color("#002147") },
}), []);

const stoneMap = useMemo(() => {
  const canvas = document.createElement("canvas");
  // ... draw on canvas ...
  return new THREE.CanvasTexture(canvas);
}, []);
```

### Tune geometry subdivision counts
More vertices = more GPU work. Use the minimum that looks good:
- Ocean plane: `[300, 300, 70, 70]` not `140×140` (75% fewer vertices)
- Sail cloth: `[1.8, 4, 8, 12]`: needs enough segments for cloth ripple
- Decorative spheres: `[r, 8, 6]` not `[r, 32, 32]`

### PostProcessing: keep multisampling low
```tsx
<EffectComposer multisampling={2}>  {/* not 4, half the MSAA cost */}
  <Bloom luminanceThreshold={0.65} intensity={0.45} />
  <Vignette offset={0.18} darkness={0.45} />
</EffectComposer>
```

---

## Animation patterns

### Cloth/flag: mutate BufferGeometry vertices in `useFrame`
```tsx
const flagRef = useRef<THREE.Mesh>(null);

useFrame((_, delta) => {
  const flag = flagRef.current;
  if (!flag) return;
  const pos = flag.geometry.attributes.position;
  const arr = pos.array as Float32Array;
  for (let i = 0; i < arr.length; i += 3) {
    const x = arr[i];
    const freeEdge = THREE.MathUtils.smoothstep(x, -0.24, 0.24);
    arr[i + 2] = Math.sin(x * 12 + t * 5.2) * 0.035 * freeEdge;
  }
  pos.needsUpdate = true;               // required, tells GPU to re-upload
  flag.geometry.computeVertexNormals(); // re-compute lighting normals
});
```

### Smooth transitions with `lerp`
Avoid hard snapping. Use lerp in `useFrame` for camera follow, sail rotation, bank angle:

```tsx
// Smooth camera follow
camera.position.lerp(targetPosition, 0.05);

// Smooth sail rotation
sail.rotation.y = THREE.MathUtils.lerp(sail.rotation.y, targetAngle, 0.08);

// Smooth bank on turn
boat.rotation.z = THREE.MathUtils.lerp(boat.rotation.z, bankTarget, 0.1);
```

### Random animation offset with a `phase` prop
When reusing animated components (grass tufts, fish), pass a `phase` prop so they're not synchronized:

```tsx
function GrassTuft({ position, phase = 0 }) {
  useFrame((_, delta) => {
    ref.current.rotation.z = Math.sin(t * 1.3 + phase) * 0.14; // desync via phase
  });
}

// At the call site, give each one a different phase
<GrassTuft position={[2.8, 1.45, 1.5]} phase={0.0} />
<GrassTuft position={[-2.5, 1.45, 2.2]} phase={1.4} />
```

### Initialize random data once with a lazy `useState` initializer
For particle systems (fish, sparks), generate random data once at mount:

```tsx
const [fishData] = useState<FishDatum[]>(() => makeFishData(count, spread));
// The () => form only runs once. Math.random() isn't called on re-renders
```

---

## Imperative handles

### Use `forwardRef` + `useImperativeHandle` to expose reset/control from parent

```tsx
export type SailboatHandle = { reset: () => void };

export const Sailboat = forwardRef<SailboatHandle, SailboatProps>(
  function Sailboat(props, ref) {
    const groupRef = useRef<THREE.Group>(null);
    const velocity = useRef(0);

    useImperativeHandle(ref, () => ({
      reset() {
        if (!groupRef.current) return;
        groupRef.current.position.set(0, WATER_CLEARANCE, 0);
        groupRef.current.rotation.set(0, 0, 0);
        velocity.current = 0;
      },
    }), []);

    // ...
  }
);

// In parent:
const sailboatRef = useRef<SailboatHandle>(null);
<Sailboat ref={sailboatRef} ... />
<button onClick={() => sailboatRef.current?.reset()}>⌂</button>
```

---

## Stale closure trap in event listeners

When an `addEventListener` needs a value that changes over time (e.g., `nearIslandId`), a `useEffect` with that value in deps re-registers the listener too slowly. Use a ref to always have the latest value:

```tsx
// Wrong, stale closure: the space handler captures old nearIslandId
useEffect(() => {
  window.addEventListener("keydown", (e) => {
    if (e.code === "Space" && nearIslandId) navigate(nearIslandId); // stale!
  });
}, [nearIslandId]);

// Correct, ref is always current, no stale closure
const nearIslandIdRef = useRef<string | null>(null);
const handleNearIsland = useCallback((id: string | null) => {
  nearIslandIdRef.current = id;  // sync ref immediately
  setNearIslandId(id);           // also set state for React renders
}, []);

useEffect(() => {
  const onKey = (e: KeyboardEvent) => {
    const id = nearIslandIdRef.current; // always fresh
    if (e.code !== "Space" || !id) return;
    navigate(id);
  };
  window.addEventListener("keydown", onKey);
  return () => window.removeEventListener("keydown", onKey);
}, []); // no nearIslandId dep needed
```

---

## Drei `Html`: pointer events gotcha

Drei's `<Html>` wraps its children in a div with `pointer-events: auto` by default. This blocks canvas raycasting (click-to-enter stops working). Always disable pointer events on labels:

```tsx
// Wrong, wrapper div eats canvas clicks even with inner pointer-events-none
<Html position={[0, 13, 0]} center distanceFactor={22}>
  <p className="pointer-events-none">Label</p>
</Html>

// Correct, disable on the Html component itself
<Html position={[0, 13, 0]} center distanceFactor={22} style={{ pointerEvents: 'none' }}>
  <p className="pointer-events-none whitespace-nowrap">Label</p>
</Html>
```

For interactive Html (buttons that appear near islands), omit the style override so the click registers.

---

## GLSL shaders

### Keep shader math mirrored in JS when you need scene sync
The ocean vertex shader moves geometry on the GPU. The boat needs to ride the waves, so duplicate the wave math in JS:

```ts
// In Ocean.tsx (GLSL vertex shader)
float longWave = sin(p.x * 0.13 + t * 0.42) * 0.34;

// In Sailboat.tsx (JS, must match exactly)
function getOceanHeight(x: number, z: number, t: number) {
  const longWave = Math.sin(x * 0.13 + t * 0.42) * 0.34;
  return longWave + crossWave + chop;
}
```

### Transparent water setup
```tsx
<shaderMaterial
  transparent
  depthWrite={false}          // prevents z-fighting with objects below water
  side={THREE.DoubleSide}     // visible from underwater camera angles
  // fragment shader outputs gl_FragColor = vec4(color, 0.72)
/>
```

---

## R3F raycasting for click-to-enter

Attach `onClick` to R3F `<group>` elements. R3F handles raycasting automatically:

```tsx
<group
  position={position}
  onClick={isNear && isUnlocked ? () => onDiscover(id, route) : undefined}
>
  {/* Island geometry */}
</group>
```

Conditionally attach the handler (not always `undefined`): this avoids raycasting overhead on islands the player is far from.

---

## Scene layering (z-index)

```
z-0   Canvas (background)
z-10  Persistent HUD controls (buttons)
z-40  Modal overlays (map, help panel)
```

Keep modal backdrop semi-transparent with `backdrop-blur` for depth:
```tsx
<div className="absolute inset-0 z-40 flex items-center justify-center bg-[#002147]/10 backdrop-blur-[2px]">
```

---

## TypeScript tips

- Type all `useRef` with the Three.js class: `useRef<THREE.Group>(null)`, `useRef<THREE.ShaderMaterial>(null)`
- Export handle types alongside the component: `export type SailboatHandle = { reset: () => void }`
- Use `as Float32Array` when accessing `BufferAttribute.array` (TypeScript sees `ArrayLike<number>`)

---

## Checklist before shipping a 3D component

- [ ] `"use client"` at top of file
- [ ] No `setState` inside `useFrame`
- [ ] All per-frame values stored in `useRef`
- [ ] Motion multiplied by `delta`
- [ ] Uniforms / procedural textures wrapped in `useMemo`
- [ ] Event listener `useEffect` returns a cleanup function
- [ ] Drei `Html` labels have `style={{ pointerEvents: 'none' }}`
- [ ] Geometry subdivision count is the minimum that looks good
