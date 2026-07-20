---
name: afresto-code-style
description: >-
  Konvensi penulisan, ARSITEKTUR MODUL, & PENEMPATAN FILE source code Afresto Next (backend Go,
  web React, mobile RN/Expo). WAJIB dibaca sebelum menulis/mengubah/merapikan kode agar rapi &
  seragam: pisahkan QUERY dari LOGIC (SQL statis → sqlc), backend berlapis routes/handler/service/
  repository/deps/dto dengan kelas modul A/B/C (jangan over-engineer), lintas-modul via interface,
  transaksi di service, DTO terpisah, struktur web (pages/components/ui/lib) & mobile
  (app/components/lib), jangan duplikasi helper. Picu saat: bikin/ubah/refactor handler, query,
  service, repository, komponen, halaman, atau bingung "file ini taruh di mana".
---

# Gaya & Struktur Kode Afresto Next

Tujuan: kode mudah dibaca, query tak bercampur logic, dan tiap hal punya TEMPAT yang jelas.
Aturan di bawah = standar tim. Sebelum menyelesaikan, jalankan **`simplify`** (rapikan diff) &
untuk yang berisiko **`code-review`**.

## Prinsip
1. **Query ≠ Logic.** SQL punya tempatnya sendiri; Go/TS berisi alur, bukan string SQL panjang.
2. **Handler TIPIS.** Handler = bind input → otorisasi → panggil query/service → bentuk respons. Logika bisnis pindah ke service/helper.
3. **Satu sumber.** Helper dipakai bersama (mis. `grading.Objective`, `ai.GradeOpen`) — JANGAN disalin (nilai bisa beda). Warna/token via desain-afresto.
4. **Taruh di lapis yang benar** (lihat penempatan file). Kalau ragu "di mana", jangan tempel di file terdekat — ikuti struktur.

## Backend (Go) — modular monolith berlapis
Lapisan data (tak berubah): **migrations → queries (sqlc) → dbgen**. Di atasnya tiap modul disusun
per **tanggung jawab**, bukan folder per-layer — **package Go = batas enkapsulasi** (layer = file
dalam satu package, bukan `handler/` `service/` `repository/` terpisah yang memaksa semua tipe public).

**Struktur target per modul** `internal/modules/<modul>/` (nama file konsisten):

| File | Isi | Dilarang |
|---|---|---|
| `routes.go` | `RegisterRoutes`: URL → method handler | logic apa pun |
| `handler.go` | HTTP-only: bind → guard → panggil service → `c.JSON` | SQL, kalkulasi bisnis, `pool` langsung |
| `service.go` | logika bisnis + orkestrasi transaksi (boleh `service_*.go`) | `c.JSON`/`gin.*`, query tabel modul lain |
| `repository.go` | SATU-SATUNYA pemegang query **tabel milik modul ini** | query tabel modul lain, logic |
| `deps.go` | **interface** ke modul LAIN yang dibutuhkan (port keluar) | implementasi konkret |
| `dto.go` | request/response + I/O antar-layer | bocorkan kolom mentah (answer_key) |

**Klasifikasikan dulu — JANGAN seragamkan** (layer penuh ke semua modul = over-engineering):

| Kelas | Kriteria | Layer wajib |
|---|---|---|
| **A — Full** | hot path / logic berat / transaksi multi-step: `presensi`, `penilaian`, `content`, `remedial`, `exam` | handler + service + repository + deps |
| **B — Ringan** | CRUD tipis: `class`, `comments`, `dokumen`, `calendar`, `notification` | handler + repository (**SKIP service**) |
| **C — Biarkan** | kecil & wajar, tak tersentuh fitur baru | jangan diubah |

Naikkan B→A **hanya** saat logic-nya benar-benar tumbuh. **Service kosong yang cuma passthrough = anti-pattern.**

**Aturan tak boleh dilanggar:**
- **SQL STATIS → `internal/db/queries/<modul>.sql` (sqlc)** → `~/go/bin/sqlc generate` → `h.q.NamaQuery(...)`. JANGAN string mentah `SELECT/INSERT/UPDATE` di handler/service. `h.db.Query/QueryRow/Exec` (pgx mentah) **HANYA** utk SQL benar-benar dinamis (kolom/WHERE runtime) — minim + komentar alasan.
- **Handler HTTP-only**: parse (`ShouldBindJSON`), guard (`guardLatihanOwner`/`subjectScope`/`security.SchoolID`), panggil 1 method service, `c.JSON`. Tak ada orkestrasi panjang / query mentah di sini.
- **Kepemilikan tabel = source of truth**: hanya repository modul pemilik yang query tabelnya. Butuh **data** modul A → panggil **service A**, jangan query tabel A.
- **Lintas-modul lewat interface milik konsumen** (`deps.go`) — deklarasikan APA yang kamu butuh; JANGAN simpan `*ModulLain.Service` konkret (tak bisa di-mock, rawan import cycle). Structural typing Go: `*A.Service` otomatis memenuhi interface, wiring di `server.go` tak berubah.
- **Transaksi multi-step dipegang service**: `q := s.q.WithTx(tx)`; repository terima `DBTX`. `defer tx.Rollback(ctx)` (no-op setelah commit).
- Regen sqlc setelah ubah skema/query; SELECT * drift → lihat [[afresto-db-change]]. DTO jangan bocorkan kolom mentah → [[afresto-next-jebakan-rekayasa]].

**Penempatan file backend:**
`backend/migrations/NNNNN_*.sql` · `backend/internal/db/queries/<modul>.sql` · generate ke `internal/db/dbgen/` (JANGAN edit tangan) · `backend/internal/modules/<modul>/{routes,handler,service,repository,deps,dto}.go` · DTO lintas-modul → `internal/platform/dto`. Composition root tunggal: `internal/platform/server/server.go`.

> **Refactor bertahap** (satu modul per PR, perilaku tetap, test hijau), contoh interface & transaksi lengkap, roadmap T0–T4, DoD & daftar anti-pattern: **`docs/plan/01-refactor-arsitektur-modul.md`**. Test **ditulis menyertai** tiap refactor → skill **afresto-testing** + `docs/plan/02-strategi-testing.md`. Gerbang mutu (gofmt/golangci-lint/CI) → [[afresto-deploy]] + `docs/plan/00-tooling-quality-gate.md`.

## Web (React + Vite + Tailwind v4)
- **`pages/`** = halaman terpasang rute (satu layar). **`components/`** = komponen reusable. **`components/ui/`** = primitif (`Card`,`Button`,`Modal`,`Input`,`Avatar`) — pakai ini, jangan bikin ulang.
- **`lib/api.ts`** = SEMUA panggilan API (satu pintu). **`lib/`** = hook & util (`useJenjang`, dll).
- Komponen fokus & kecil; **JANGAN definisikan komponen di dalam render** komponen lain (input kehilangan fokus — [[afresto-next-penilaian-rapor-pipeline]]). Ekstrak ke fungsi/berkas.
- Warna/tema lewat token Ocean & komponen `ui/` — lihat skill **desain-afresto**.

## Mobile (React Native / Expo, repo afresto-next-mobile)
- **`app/`** = layar/rute (expo-router). **`components/`** = reusable (mis. `FormKit`, `Comments`). **`lib/`** = `api.ts`, `offlineStore.ts`, util.
- Penyimpanan lokal per-siswa **WAJIB scope `uid`** (HP bersama) — lihat desain-afresto JEBAKAN #8.
- Jangan salin logika penilaian dari backend ke device kecuali sengaja (practice) — kembalikan nilai kanonik dari server.

## Alur kerja
1. Sebelum menulis: cek apakah **query/komponen/helper sudah ada** (grep). Reuse. Modul backend → tentukan **kelas A/B/C** dulu (jangan bikin service kosong).
2. Tulis di **lapis yang benar** (SQL→sqlc, logika→service, akses tabel→repository, lintas-modul→interface `deps.go`, UI→component).
3. `sqlc generate` + `gofmt -w` + `go build`/`vet` (backend) atau `tsc --noEmit` (web/mobile). Tulis **test menyertai** (skill **afresto-testing**), jangan menyusul.
4. Jalankan **`simplify`** pada diff; **`code-review`** bila menyentuh nilai/otorisasi.
5. Verifikasi & deploy + gerbang mutu (gofmt/lint) lewat [[afresto-deploy]] · perubahan DB lewat [[afresto-db-change]] · nilai lewat [[afresto-penilaian]] · test lewat **afresto-testing**.

Terkait: `afresto-testing` · `afresto-db-change` · `afresto-deploy` · `afresto-penilaian` · `desain-afresto` · `docs/plan/` (00 tooling, 01 arsitektur, 02 testing) · memori `afresto-next-backend-setup`, `afresto-next-web-setup`, `afresto-next-jebakan-rekayasa`.
