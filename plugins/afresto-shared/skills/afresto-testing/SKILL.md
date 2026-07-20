---
name: afresto-testing
description: >-
  Strategi & konvensi test backend Go Afresto Next (projectTwo/backend). WAJIB dibaca sebelum
  menulis/mengubah test: piramida unit/service/integration, `testing` stdlib (BUKAN testify),
  table-driven, mock TANPA library (interface repo/deps dipenuhi fakeRepo), integration WAJIB skip
  bila TEST_DATABASE_URL kosong, jam disuntik (bukan time.Now internal). Test DITULIS MENYERTAI
  tiap refactor, bukan menyusul. Picu saat: bikin/ubah *_test.go, mau menguji service/handler/query,
  bingung "ini diuji di layer mana", atau setup CI test.
---

# Strategi Test Afresto Next (backend Go)

Test **ditulis menyertai** tiap refactor arsitektur (lihat `afresto-code-style` + `docs/plan/01`),
**bukan** proyek terpisah di belakang — pemisahan handler/service/repository-lah yang membuat
business logic bisa diuji tanpa menyalakan HTTP + DB.

## Piramida (target)

```
   Integration (DB)   repository + sqlc → Postgres nyata (TEST_DATABASE_URL). Sedikit, lambat.
   Service (mock repo) business logic + orkestrasi, repo & deps di-mock. Banyak, cepat (ms), tanpa DB/HTTP.
   Unit (fungsi murni)  kalkulasi/aturan: classifyArrival, evalLocation, parseHHMM. Paling banyak, instan.
```

**Prioritas usaha:** perbanyak **Unit** & **Service** (cepat, deterministik). Integration secukupnya
untuk memvalidasi SQL & mapping sqlc. E2E/HTTP tidak wajib di fase ini. **Bukan** mengejar angka
coverage % — target = **tiap aturan bisnis & jalur error modul kelas A punya test service; tiap query
kritis punya integration test.**

## Apa yang diuji di tiap layer

| Layer | Diuji | TIDAK di sini |
|---|---|---|
| **Unit (pure)** | fungsi tanpa efek samping: `classifyArrival`, `resolveCheckTime`, `evalLocation`, `parseHHMM` | DB, HTTP |
| **Service** | aturan bisnis + alur (idempotent, error domain, urutan panggilan repo) — **repo/deps di-mock** | SQL nyata, JSON HTTP |
| **Repository (integration)** | query sqlc benar, mapping kolom, `ON CONFLICT`, transaksi | logika bisnis |
| **Handler (opsional)** | binding & mapping error→status (1–2 happy/error path) | logika bisnis (sudah di service) |

## Konvensi (wajib konsisten)

1. **Framework: `testing` stdlib.** BUKAN testify (nol dependensi, idiomatik). Boleh helper kecil sendiri.
2. **Table-driven** untuk fungsi murni & service (`cases := []struct{...}` → `for _, tc := range cases { t.Run(tc.name, ...) }`).
3. **Integration WAJIB skip tanpa DB** (pertahankan pola existing):
   `url := os.Getenv("TEST_DATABASE_URL"); if url == "" { t.Skip("TEST_DATABASE_URL tidak diset") }`
4. **Penamaan:** `Test<Fungsi>` / `Test<Service>_<Skenario>`. Integration prefix jelas (`TestRepo...`) → bisa difilter `go test -run TestRepo`.
5. **Isolasi data integration:** tandai data uji (mis. `__TEST_...__`) + bersihkan via `t.Cleanup`, atau bungkus transaksi yang di-rollback.
6. **Tanpa jam nyata:** fungsi yang butuh waktu menerima `time.Time`/`now` sebagai **parameter** (bukan `time.Now()` internal) → deterministik.

## Mock TANPA library — inti kenapa refactor dibutuhkan

Setelah service memegang **interface** ke repository & modul lain (`deps.go`), mock jadi trivial:

```go
// service_test.go
type fakeRepo struct{ settings settings; today *Attendance; upserted CheckInRow }
func (f *fakeRepo) LoadSettings(_ context.Context, _ int64) settings { return f.settings }
func (f *fakeRepo) UpsertCheckIn(_ context.Context, row CheckInRow) (*Attendance, error) {
    f.upserted = row; return &Attendance{ID: 1, Status: row.Status}, nil
}
func TestService_CheckIn_Terlambat(t *testing.T) {
    svc := NewService(&fakeRepo{settings: settings{LateTime: "07:00", CloseTime: "08:00"}})
    res, err := svc.CheckIn(ctx, CheckInInput{ /* jam 07:15 */ })
    if err != nil || res.Record.Status != "terlambat" { t.Fatalf("...") }
}
```

- Repo & deps didefinisikan sebagai **interface di package service** → `fakeRepo` cukup memenuhi interface. Tanpa Postgres.
- Sama untuk deps lintas-modul (mis. `RemedialEvaluator`) → tinggal buat `fakeRemedial`.

## Target cakupan per kelas modul (ikut A/B/C di `afresto-code-style`)

| Kelas | Unit | Service | Integration |
|---|---|---|---|
| **A** (presensi, penilaian, content, remedial) | wajib fungsi murni | wajib skenario inti + error | wajib query kritis |
| **B** (CRUD tipis) | seperlunya | — (tak ada service) | 1 happy-path repo |
| **C** (dibiarkan) | test lama dipertahankan | — | — |

## Definition of Done (test) — per modul direfactor

- [ ] Fungsi murni punya **table-driven unit test**.
- [ ] Skenario inti service + minimal jalur error diuji dengan **repo/deps di-mock**.
- [ ] Query kritis (upsert presensi, hitung nilai) punya **integration test** (skip tanpa DB).
- [ ] `go test ./...` hijau **tanpa** `TEST_DATABASE_URL` (integration ter-skip, unit/service jalan).
- [ ] `go test ./...` hijau **dengan** `TEST_DATABASE_URL` di CI.

## CI (lihat gerbang di [[afresto-deploy]] + `docs/plan/00`)

- **PR (cepat):** `go build ./... && go test ./...` — unit + service jalan, integration ter-skip.
- **Merge / nightly (lengkap):** nyalakan Postgres service, set `TEST_DATABASE_URL`, `go test ./...` termasuk integration. Tambah `go vet ./...`; pertimbangkan `-race` (relevan untuk jalur burst presensi).

## Referensi kode existing (pola yang benar)

- Integration: `internal/modules/penilaian/pohon_db_test.go` (pola skip tanpa DB).
- Unit: `internal/modules/penilaian/engine_test.go`, `internal/modules/content/soalparser_test.go`.
- Detail lengkap + roadmap test menyertai refactor: **`docs/plan/02-strategi-testing.md`**.

Terkait: `afresto-code-style` (arsitektur berlapis = prasyarat test) · `afresto-db-change` · `afresto-deploy` · `docs/plan/01`, `docs/plan/02` · memori [[afresto-next-jebakan-rekayasa]].
