# afresto-claude-skills

Marketplace plugin **privat** untuk skill Claude Code yang dipakai BERSAMA lintas repo Afresto
(projectTwo & afresto-next-mobile) — satu sumber, satu standar.

## Isi
- `afresto-shared` -> skill `desain-afresto` (sistem desain Ocean, web + mobile).

Skill khas satu repo (deploy, db-change, penilaian, mobile) TIDAK di sini — tinggal di
`.claude/skills/` repo masing-masing.

## Cara tim memasang (sekali per orang)
```
/plugin marketplace add ristology/afresto-claude-skills
/plugin install afresto-shared@afresto
/reload-plugins
```
Atau otomatis: repo projectTwo & mobile memuat `extraKnownMarketplaces` + `enabledPlugins`
di `.claude/settings.json` -> tim ditawari pasang saat clone & trust folder.

Dipanggil: `/afresto-shared:desain-afresto`.

## Update
Naikkan `version` di `marketplace.json` & `plugin.json`, lalu tim: `/plugin marketplace update afresto` -> `/reload-plugins`. Perubahan lewat PR.
