# Data API 1 authoring

API 1 is implemented in `godot/scripts/content_bundle.gd`, `content_assets.gd`,
`catalog.gd` and the world renderer. The compatibility contract is the supported
raw data schema, **not arbitrary executable mods**.

## Build

Edit supported resources under `godot/assets/{content,materials,audio}`. Run:

```sh
python3 scripts/build-content-bundle.py /absolute/path/My-Data.icdata --revision 2
```

This writes a manifest beside the installable file. The game needs only `.icdata`.
The full APK + initial Data build remains `bash scripts/godot-build-split.sh`.

Container: eight-byte ASCII `ICDATA01`, little-endian uint32 manifest byte count,
UTF-8 JSON manifest, then raw file contents in manifest order. There is no archive
extraction, resource-pack mounting or script loading. The manifest declares API,
world ID, revision and file paths, sizes and SHA-256. It is **not signed**.

Limits include 256 MiB total payload, 16 MiB per file, 256 files, 32–96 settlements,
4–8 factions, and world extents of 900–6000 by 680–4000 units. Definitions must
satisfy the validator; these are ceilings, not guaranteed mobile performance budgets.
Use stable contiguous settlement IDs and retain old IDs when extending a world.
The starter world is 2700×2040 with 64 settlements and six factions.

Only supported appearance settings and raw head/scalp OBJ models are consumed by
the current character implementation. Do not assume an arbitrary full-body GLB,
new skeleton, gameplay script or Bannerlord module is supported. The staged
full-body human rig under `art-source/human/generated` is deliberately not shipped
as current runtime content.

## Integrity and recovery

A new pack is written into a separate private bundle directory. File checksums,
paths, supported definitions and raw geometry are validated before the active
pointer is replaced. Failed updates keep the previous active directory. Previously
installed directories are retained; repeated updates consume storage. Clearing app
data removes them **and the campaign save**, so do not suggest clearing data as a
save-preserving cleanup method.

The engine tests exercise corrupt content, path traversal, executable resource
rejection, incompatible API, malformed human fields and continued use of the old
pack after an unsuccessful update. The Android smoke changes the Data catalog and
revision on the same installed APK and restarts against that revision.
