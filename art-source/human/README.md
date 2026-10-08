# Human source assets

Upstream: https://github.com/makehumancommunity/makehuman
Revision: a8bc2d54ff0ac92e78ff71431b1023eda42bf482
Files: makehuman/data/3dobjs/base.obj, makehuman/data/rigs/default.mhskel,
makehuman/data/rigs/default_weights.mhw.

The OBJ header explicitly releases the mesh as CC0 (September 2020).
The skeleton and weights explicitly declare CC0 in their metadata.
The complete license is bundled in art-source/human/LICENSE-CC0.txt.
Copyright/attribution: Data Collection AB, Joel Palmius, Jonas Hauquier.

These are not Bannerlord or Warhammer assets. User screenshots are references,
not distributable models. No proprietary mesh has been extracted from them.

Run `python3 scripts/build-human-model.py` to generate the mobile skeleton GLB.
Only the anatomical `body` group is exported; helper geometry is omitted.
The generated model is a rigging foundation, not a finished clothed character.
Do not publish it as a completed character overhaul before engine visual review.

Staging: generated/ is intentionally outside the released Godot project. The
existing 0.6 pack and APK are not silently changed by unfinished art.
