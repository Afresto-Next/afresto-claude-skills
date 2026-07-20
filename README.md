# afresto-claude-skills

Marketplace plugin **publik** untuk skill Claude Code yang dipakai **BERSAMA** lintas repo Afresto
(projectTwo & afresto-next-mobile) — satu sumber, satu standar.

> **Publik = baca-saja untuk umum.** Siapa pun boleh `clone`, tapi hak tulis tetap milik.
> owner/collaborator. Isinya hanya panduan sistem desain (tanpa token/rahasia). Repo dibuat.
> publik supaya tim tak perlu diundang satu-satu untuk memakainya.

## Isi
Plugin `afresto-shared` berisi standar tim yang dipakai **bersama**:
- `desain-afresto` — sistem desain **Ocean** (web + mobile).
- `afresto-code-style` — gaya penulisan & **arsitektur modul** backend Go (routes/handler/service/repository/deps/dto, kelas A/B/C) + struktur web/mobile.
- `afresto-testing` — strategi & konvensi test backend Go (piramida, mock tanpa library).
- `afresto-deploy` — prosedur commit & deploy + gerbang mutu Go.

Skill khas satu repo (`afresto-db-change`, `afresto-penilaian`, `afresto-mobile`)
**TIDAK di sini** — mereka tinggal di `.claude/skills/` repo masing-masing dan ikut otomatis saat `git pull`.

> **Ekstensi VS Code tidak memuat plugin marketplace** (lihat bawah). Karena itu, tiap skill di sini
> juga di-mirror ke **`~/.claude/skills/`** (user-level) di mesin developer pengguna ekstensi — sumber
> kebenaran tetap repo ini, user-level hanya salinan sinkron.

## ⚠️ Penting: skill dari marketplace butuh CLI
`/plugin` (manajemen marketplace) **hanya tersedia di Claude Code CLI (terminal)** — **bukan** di
ekstensi VS Code. Jadi `desain-afresto` hanya termuat kalau pakai CLI. Skill repo di atas tetap
jalan di ekstensi.

## Onboarding tim (sekali per orang)
1. Pasang **Node.js** (kalau belum), lalu pasang CLI:
   ```
   npm i -g @anthropic-ai/claude-code
   ```
2. `clone`/`pull` repo kerja (mis. `next`), buka terminal, `cd` ke folder repo, jalankan:
   ```
   claude
   ```
3. Saat muncul **"Trust marketplace afresto?"** → pilih **ya**.
   (Otomatis karena repo kerja memuat `extraKnownMarketplaces` + `enabledPlugins` di `.claude/settings.json`.)
4. Kalau tab **Errors** sempat menampilkan **"Plugin afresto-shared not cached"** (error basi saat pertama):
   ketik **`/exit`**, lalu buka **`claude`** lagi → error hilang.
5. Verifikasi: ketik **`/skills`** → pastikan skill repo (`afresto-*`) **dan** `desain-afresto` muncul.

Pasang manual (kalau auto tak jalan):
```
/plugin marketplace add Afresto-Next/afresto-claude-skills
/plugin install afresto-shared@afresto
/reload-plugins
```
Dipanggil: `/afresto-shared:desain-afresto`.

## Update skill
1. Edit `plugins/afresto-shared/skills/<nama-skill>/SKILL.md` (sumber tunggal).
2. Naikkan `version` di `.claude-plugin/marketplace.json` **dan** `plugins/afresto-shared/.claude-plugin/plugin.json`.
3. Commit + push (perubahan sebaiknya lewat **PR**).
4. Tim (CLI) ambil versi baru: `/plugin marketplace update afresto` → `/reload-plugins`.
5. Pengguna **ekstensi VS Code**: sinkronkan mirror user-level → salin folder skill yang berubah ke `~/.claude/skills/`.
