# Dropbox distribution — 2026-10-20

The user approved using Dropbox for source assets, release downloads and save backups, one step at a time. This first step distributes the **existing verified 0.9.1 Data**, not a new APK or completed cloud-save feature.

## Completed

- Dropbox searches for Iron/Castle returned no matches; listing the accessible root returned no entries. No existing personal file contents were read.
- Created `/Iron Crowns/Releases 0.9.1`, `/Iron Crowns/Source Assets`, and `/Iron Crowns/Save Backups` without replacing existing files.
- Uploaded Data, its manifest, a Sorani installation guide and SHA-256 checksum file. Uploads used add-only/conflict rejection.
- Only the release folder has a public, viewer/download link. Source Assets and Save Backups were **not** shared.

[Download Data and installation guide](https://www.dropbox.com/scl/fo/l6hzmhekdtk2oe58rcjhw/AMqrZzQbl1Sga0hfOP6MaS4?rlkey=dskejp87dq3sr1pgi661lgro4&dl=0)

Data bytes: **20,083,426**, 56 raw assets, API 1 revision 3. Locally rebuilt Data matches the published GitHub release byte-for-byte:

- SHA-256: `74c6b041c8ac1e60450db2413df484e1abe4d998430e1de08978bea870900386`
- Dropbox content hash (SHA-256 over concatenated SHA-256 hashes of 4-MiB blocks): `1798c577272a2342e64080e5895dd1b84722c032063bd2a36421fb7088f3a8c9`

The Dropbox upload returned exactly the same size/content hash, independently checked locally.

## Not completed / limitations

The **174,702,809-byte APK was not uploaded to Dropbox**. This session's upload connector accepts files no larger than 100 MB; that is a connector limit, not Dropbox's general file-size limit. The Sorani guide links to the existing verified GitHub APK instead. No binary was truncated, disguised or represented as uploaded when it was not.

Download the Data to Android's Downloads first if it is not visible in the native picker; the current importer requests local documents. Creating a Save Backups folder does not implement Android export, import, automatic synchronization, or cross-package migration. No save files were uploaded or made public.

The existing Supabase project was listed as ACTIVE_HEALTHY. Only public table names were inspected to avoid conflicting with unrelated applications. No user rows, keys or credentials were fetched, and no Supabase schema/auth/data changes were applied in this distribution step. Android cloud saves remain unimplemented.

No source graphics were available in the accessible Dropbox root. Future assets require provenance/license review before redistribution. A >1-GB used-content library, API-2 streaming, professional graphics/animation, new missions and siege machinery remain separate unfinished work; this upload does not complete them.
