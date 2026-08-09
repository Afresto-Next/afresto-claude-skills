---
name: afresto-deploy
description: >-
  Prosedur commit & deploy Afresto Next (repo projectTwo: backend Go + web React/Cloudflare
  Worker; repo terpisah afresto-next-mobile RN/Expo). WAJIB dibaca sebelum commit/push/deploy/
  OTA di project ini. Berisi urutan aman + JEBAKAN yang sudah menggigit: banyak tab agent aktif
  (jangan git add -a), migrasi harus di commit TIP (migrate.yml lihat HEAD~1), build web dari
  WORKTREE BERSIH (npm build baca seluruh tree), path worktree wajib pendek, eas --environment wajib.
---

# Deploy Afresto Next

Tumpukan: **backend Go** (push→GHCR→Watchtower ~5 mnt) · **web React** (Vite→Cloudflare Worker,
manual `wrangler deploy`) · **mobile** RN/Expo di **repo terpisah** `<repo-mobile>`
(EAS OTA). Deploy produksi = **selalu minta izin user dulu** (mereka menyetujui tiap kali).

## 🔴 Aturan #1 — repo ini sering dipakai BANYAK TAB AGENT sekaligus
`git status` kerap menampilkan berkas termodifikasi **milik sesi lain**. Karena itu:
- **JANGAN `git add -a` / `git commit -a` / `git add .`** — akan menyapu pekerjaan setengah jadi sesi lain masuk commit-mu.
- **Stage SELEKTIF** tiap berkas milikmu, lalu **verifikasi**: `git diff --cached --name-only` — pastikan tak ada berkas asing (yang sering nyasar: `web/src/pages/ChatPage.tsx`, `backend/internal/db/dbgen/models.go` bila bukan hasil regen-mu).
- Berkas **dipakai bersama** dua sesi (mis. ExamPage) & kamu hanya mau hunk-mu: jangan `stash`/`reset` (menarik berkas dari bawah kaki agent lain). Sunting **index Git** lewat blob:
  `git show :path > tmp` → buang hunk mereka dari `tmp` → `SHA=$(git hash-object -w tmp)` → `git update-index --cacheinfo 100644,$SHA,path`. Berkas di disk tak tersentuh.
- 🚨 **cwd tool Bash bisa MENETAP** dari `cd .../web` (atau worktree) di panggilan sebelumnya. Lalu `git add backend/...` GAGAL `pathspec did not match` (atau MEN-stage tree yang salah). Sebelum stage selektif, **`cd <repo-root> &&`** dulu (atau pakai path absolut). Verifikasi `git diff --cached --name-only` menampilkan path relatif-root yang benar (bukan `../backend`, `src/...`).
- **Setelah deploy**: cek `git status` — pastikan berkas kerja sesi lain masih utuh.

## Gerbang mutu Go (sebelum commit backend)
Padanan **Pint + PHPStan** ala Laravel untuk Go. Jalankan lokal sebelum stage berkas backend:
- **Format:** `cd backend && gofmt -l .` → **harus KOSONG**. Ada isi → `gofmt -w .` (auto-fix), stage hasilnya. (Padanan `pint --test`.)
- **Build + vet:** `go build ./... && go vet ./...` hijau.
- **Analisis statis (target):** `golangci-lint run ./...` (bungkus gofmt/govet/staticcheck/errcheck/ineffassign/unused/misspell). Padanan `phpstan analyse`.
- ⚠️ **Status: gerbang CI belum aktif.** Belum ada `backend/.golangci.yml` maupun `.github/workflows/ci.yml`, dan `staticcheck` masih usang → jadi **format+build+vet ini manual dulu**. Rencana enforce di CI + config lengkap: **`docs/plan/00-tooling-quality-gate.md`**. Kode generated `internal/db/dbgen` **dikecualikan** dari lint.
- Test menyertai perubahan → skill **afresto-testing** (`go test ./...`; integration ter-skip tanpa `TEST_DATABASE_URL`).

## 🔴 Aturan #0 — JANGAN commit/push langsung ke `main` (tim 4 orang, sejak 25 Jul 2026)
Semua kerja lewat **cabang + Pull Request**; hanya reviewer yang merge ke `main` (merge = pemicu deploy).
1. **Sebelum mulai**: `git checkout main && git pull` — bila ada migrasi baru, **jalankan migrasi** dulu.
2. **Buat/checkout cabang bertema** SEBELUM menyentuh kode:
   - fitur → `feat/<nama>` · bug → `bugfix/<nama>` · bug ber-issue → cabang baru + pelajari issue-nya.
3. Commit selektif → **`git push -u origin <cabang>`** (BUKAN ke main).
4. **Buka PR ke `main`**: `gh pr create` bila `gh` login; kalau belum, beri user URL
   `https://github.com/Afresto-Next/next/compare/main...<cabang>?expand=1`.
5. Reviewer approve & **merge** → deploy. **JANGAN merge PR sendiri.**
- Bagian "Push backend / Deploy WEB" di bawah = mekanik yang jalan **SETELAH PR merge ke main**
  (biasanya oleh yang bertugas deploy), bukan izin push langsung ke main.
- Perubahan **skill** pun lewat PR (CODEOWNERS).

## Urutan langkah

### 1. Commit (Bash tool = Git Bash / sh, BUKAN PowerShell)
- Pesan multi-baris: **heredoc** `git commit -q -F - <<'EOF' … EOF`. JANGAN `@'…'@` (itu here-string PowerShell → subjek tercemar jadi `@ ...`).
- Akhiri pesan: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Warning "CRLF will be replaced by LF" = normal, abaikan.
- Commit ke **cabang tugasmu** (`feat/*` · `bugfix/*`), **bukan** `main` (lihat Aturan #0). User commit saat diminta.

#### 🔴 JANGAN `git add -A` / `git add <dir>/` — sudah 3x menyapu berkas user
Repo ini menyimpan **banyak berkas kerja user yang belum terlacak**: `docs/bskap/` (gambar+PDF),
`docs/analisis butir soal/`, `elibrary/`, `cloudflare/**/.wrangler/` (cache akun). Sekali `-A`,
semuanya ikut.

Kejadian nyata: `git add docs/` menyeret PDF/xls/gambar BSKAP (25 Jul & 2 Agu); `git add -A`
menyeret **446 berkas** termasuk `wrangler-account.json` (9 Agu).

```sh
git add path/ke/berkas1 path/ke/berkas2        # SATU PER SATU, selalu
git commit -q -F - <<'EOF'
...
EOF
git show --name-only --format="" HEAD | wc -l   # cocok dgn yang kamu niatkan?
```
Kalau jumlahnya melenceng: `git reset --soft HEAD~1 && git reset`, stage ulang yang benar.
Bila sudah ter-push ke **cabang sendiri**, `git push --force-with-lease` aman.

### 2. Migrasi DB — WAJIB di commit TIP
`.github/workflows/migrate.yml` mendeteksi migrasi via `git diff --name-only HEAD~1 HEAD` (hanya commit teratas), berjalan **setelah** "Build & Push Docker Images" sukses (`workflow_run`).
- Bila push berisi migrasi → migrasi **harus ada di commit TIP** (satu commit berisi migrasi+kode = aman).
- Migrasi jalan **otomatis** di self-hosted runner VM setelah build. `run --rm migrate` sinkron → job GAGAL keras bila error (bukan senyap).
- **Verifikasi migrasi**: cek tab **Actions → "Migrate DB" hijau** untuk commit itu (`gh` CLI **tersedia**: `gh run list --workflow="Migrate DB (self-hosted)" --limit 1` — agen bisa cek sendiri, tak perlu menyuruh user). Watchtower tukar image `api` di poll berikutnya (~5 mnt), hampir selalu setelah migrasi selesai.
- **SEBELUM** push migrasi, verifikasi SQL-nya via psql `BEGIN; … ROLLBACK;` di DB lokal (v102 = prod). Lihat skill `afresto-db-change` / jebakan-rekayasa §4.

#### 🔴 Nomor migrasi: periksa ulang TEPAT SEBELUM MERGE, bukan saat membuat cabang
Rekan tim bisa men-merge seri migrasi lain **selagi cabangmu terbuka**. Nomor kembar membuat
**goose PANIK di `sortAndConnectMigrations`** — bukan galat SQL, jadi mudah salah dibaca.
✅ Tak ada kerusakan data: panik terjadi saat *mengumpulkan* daftar, sebelum satu pun dijalankan.

Kejadian nyata (9 Agu 2026): dipilih `00138` saat membuat cabang; saat merge, tim sudah memakai
`00138`–`00140`. Perbaikan pertama menamainya `00140` dan **masih bentrok** — karena menebak lagi.
**Hitung, jangan tebak:**
```sh
git pull                                        # WAJIB dulu, biar lihat migrasi rekan
MAX=$(ls backend/migrations/ | sed 's/_.*//' | sort -n | tail -1)
NEXT=$(printf "%05d" $((10#$MAX + 1)))
ls backend/migrations/ | sed 's/_.*//' | sort | uniq -d   # HARUS KOSONG
```
Kalau sudah terlanjur: `git mv` ke nomor baru, PR kecil, merge, lalu jalankan ulang workflow
**"Migrate DB (self-hosted)"** dari tab Actions.

### 3. Push backend (SETELAH PR merge ke `main` — lihat Aturan #0)
Merge PR → `main` diperbarui → GHCR → **Watchtower ~5 mnt** menukar image. Tak ada perubahan backend = tak perlu tunggu Watchtower. (Saat mengembangkan: `git push -u origin <cabang>` lalu PR — jangan push `main`.)

#### ⚠️ SETELAH merge backend: CEK 502 (sudah kambuh 6x)
Membuat-ulang container `api`/`worker` sering memicu outage total — semua container `Up` tapi
seluruh rute 502. Praktis **tiap merge backend adalah lemparan dadu**.
```sh
curl -s -o /dev/null -w "%{http_code}
" --max-time 15 https://next.afresto.co/api/v1/auth/me
# 401 = SEHAT (minta autentikasi) · 502 = outage
```
Bila 502 → **Actions → "Ops — pulihkan API" → `restart-docker`** (tanpa SSH, pulih <1 menit).
Jangan membedah fitur yang baru di-deploy: 502 + container `Up` = restart daemon Docker.
Detail: `docs/ops-auto-pulih.md`.

### 4. Deploy WEB — dari WORKTREE BERSIH (karena banyak tab agent)
`npm run build` membaca **SELURUH working tree** → pekerjaan setengah jadi sesi lain ikut terbit. Jadi build & deploy dari worktree di commit-mu:
```bash
rm -rf /c/wtd 2>/dev/null; git worktree add --detach /c/wtd <SHA-commit-mu>
cd /c/wtd && git status --short   # harus KOSONG (bersih)
cd /c/wtd/web && npm ci && npm run build
cd /c/wtd/cloudflare/web-worker && npx wrangler deploy
cd <repo-projectTwo> && git worktree remove --force /c/wtd && git worktree prune
```
- 🔥 **Path worktree WAJIB PENDEK** (`/c/wtd`) — scratchpad dalam + nama PDF kaldik DKI yang panjang → error Windows *"Filename too long"* saat checkout.
- Verifikasi bundel benar bila perlu: `grep -rl "<penanda fiturmu>" /c/wtd/web/dist/assets/*.js` — tapi hati-hati **positif palsu** (penanda umum bisa dari fitur lain).
- Cloudflare cache aset ~20 dtk → uji dengan **Ctrl+F5**. (200 tapi ukuran ~397 byte = fallback, bukan aset asli.)

### 5. Mobile OTA — repo terpisah, `--environment` WAJIB
```bash
cd "<repo-mobile>"
npx eas update --channel preview --environment preview --message "…" --non-interactive
```
- 🔥 `--environment preview` **WAJIB** (tanpa itu update salah environment/gagal).
- Production: `--channel production` (klien pasang dari Play). Repo mobile **tanpa remote git** → commit lokal saja.
- Repo mobile pun bisa berisi kerja sesi lain → stage selektif; bila perlu build/OTA bersih pakai pola worktree yang sama.
- OTA hanya JS/aset. Perubahan **modul native** → CRASH bila via OTA → wajib build ulang (bukan OTA).

## 🏢 GHCR & organisasi GitHub — repo kini di org `Afresto-Next`
Repo (`next`, `afresto-next-mobile`, `afresto-claude-skills`) pindah dari `ristology/*` → **org `Afresto-Next`** (20 Jul 2026). Runbook transfer lengkap: **`docs/runbook-transfer-next-org.md`**.
- 🚨 **Transfer repo ke org = path GHCR ikut owner → Watchtower BEKU DIAM-DIAM.** CI tag image `ghcr.io/${GITHUB_REPOSITORY_OWNER}/afresto-next-{api,web,migrate}` — owner mengikuti pemilik repo. Setelah transfer, image baru masuk `ghcr.io/afresto-next/*` TAPI VM `docker-compose.prod.yml` masih pull `ghcr.io/${GHCR_OWNER:-ristology}/*` → **produksi tak update** (image lama tetap jalan, TANPA error). **Package GHCR TIDAK ikut pindah** (tetap milik akun lama; org bikin package BARU yang **private**).
  **FIX di VM** (`~/afresto-next`): set `GHCR_OWNER=afresto-next` di `.env` → `docker login ghcr.io` (PAT `read:packages`) → `pull api web migrate` → `up -d` → **`restart watchtower`** (watchtower bind `~/.docker/config.json`; tanpa restart pakai creds lama → auto-update mati senyap).
  **Runner self-hosted + variabel Actions `DEPLOY_DIR` IKUT pindah otomatis** (tak perlu daftar ulang; tetap verifikasi Settings→Actions→Runners online). **Rollback**: balik `GHCR_OWNER` lama + pull/up. 🚫 **JANGAN hapus package `ghcr.io/ristology/*` lama** sampai path baru stabil beberapa siklus.
- 🪤 **`docker compose pull` (tanpa argumen) GAGAL untuk image `:local`** (caddy/backup dibangun DI VM, bukan GHCR) → *"pull access denied … afresto-next-caddy"* — **WAJAR, abaikan**. Pull selektif `pull api web migrate`. `up -d` tak menariknya (image lokal sudah ada).

## Verifikasi tanpa akses langsung (probe dari luar)
- **Rute baru ada?** `curl -o /dev/null -w '%{http_code}' https://afresto.co/api/v1/<rute>` → **401 = terdaftar** (backend baru naik), **404 = belum**. Host benar: `afresto.co` / `origin.afresto.co` + prefix `/api/v1`. `api.afresto.co` TIDAK ADA (selalu 404).
- **Migrasi `schools` sehat?** `GET https://afresto.co/api/v1/public/branding?subdomain=demo` → 200 = `SELECT * schools` sehat.
- **Perubahan PERILAKU** (bukan rute baru) tak bisa di-probe → jangan klaim "terverifikasi", sebut tunggu Watchtower / uji di `next.afresto.co` (demo, bebas dicoba).

## 🔥 Checklist ringkas sebelum bilang "selesai"
0. Backend? `gofmt -l backend` kosong + `go build`/`vet` hijau + test menyertai (afresto-testing).
1. `git status` → hanya berkasku ter-stage; sesi lain utuh.
2. Migrasi (bila ada) di commit TIP; Actions "Migrate DB" hijau.
3. Web dari worktree bersih `/c/wtd`; worktree dibersihkan setelahnya.
4. OTA pakai `--environment`.
5. Backend butuh Watchtower ~5 mnt sebelum diuji; web cukup Ctrl+F5.
6. Sentuh auth/nilai? Pertimbangkan `/code-review` pada diff dulu.

Terkait: `afresto-db-change` · `afresto-code-style` (arsitektur berlapis) · `afresto-testing` · `docs/plan/00` (gerbang mutu) · memori `afresto-next-jebakan-rekayasa` (§11b migrate.yml, §11 heredoc), `afresto-next-progress-2026-07-17-sore` (pola worktree), `afresto-next-gcp-vm-deploy`, `afresto-next-frontend-cloudflare-worker`.
