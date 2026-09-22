---
name: migrasi-memory-ke-docs
description: >-
  Pindahkan PENGETAHUAN PRODUK dari memory Claude Code pribadi (di laptop masing-masing, tak
  terlihat siapa pun) ke docs repo yang bisa dibaca tim dan agent AI (pra-triase Error Log HUB).
  Hasil: docs/inbox/catatan_<nama>.md + PR. Picu saat: user minta "migrasi memory", "pindahkan
  catatan ke docs", "catatan_<nama>", awal bulan (rutin), atau sebelum membangun fitur AI yang
  membaca docs. Memory TIDAK dihapus — hanya dicatat sudah dipindah, jadi aman dijalankan berulang.
---

# Migrasi memory → docs

## Kenapa ini ada

Memory Claude Code (`~/.claude/projects/<repo>/memory/*.md`) hidup di laptop tiap orang. Yang
tercatat di sana — *"ini rancangan yang disengaja"*, *"insiden X sudah diputuskan begini"*,
*"guru sering mengira Y bug padahal cara pakainya Z"* — **tidak pernah terlihat** oleh anggota tim
lain maupun oleh agent AI di GitHub Actions yang menilai laporan Error Log dari Afresto HUB.
Per 22 Sep 2026, satu mesin saja menyimpan 261 catatan seperti itu; docs repo tertinggal jauh.

Skill ini memindahkan **hanya pengetahuan produk** ke `docs/inbox/catatan_<nama>.md` lewat PR.
Konsolidasi ke `docs/feature/<modul>.md` dan `docs/ai-pra-triase.md` dilakukan terpisah oleh
pemilik produk — jangan lakukan di skill ini (9 orang menulis berkas yang sama = konflik & gaya
campur aduk).

## Langkah

### 1. Tanya nama & temukan memory
- Tanya: **"Nama untuk berkas catatan? (mis. risto → docs/inbox/catatan_risto.md)"** — huruf kecil,
  tanpa spasi. Kalau sudah disebut user, jangan tanya lagi.
- Folder memory proyek ini: `~/.claude/projects/<cwd-terkode>/memory/`. Kode = path cwd dengan
  `:`, `\`, `/` diganti `-`. Cari dengan:
  ```bash
  ls ~/.claude/projects/ | grep -i "$(basename "$PWD")"
  ```
  Kalau ada lebih dari satu (clone di beberapa path), tanyakan mana yang dipakai; boleh gabungkan.
- Tidak ada folder / kosong → laporkan, selesai. Jangan mengarang.

### 2. Baca `memory/_migrasi_ke_docs.md` kalau ada
Berkas ini (dibuat skill ini) mencatat nama berkas memory yang **sudah** dipindah + tanggalnya.
Lewati berkas yang sudah tercatat, **kecuali** `modified` di frontmatter-nya lebih baru dari
tanggal migrasi terakhirnya → baca ulang, tandai "diperbarui".

### 3. Baca semua berkas memory yang tersisa
Baca `MEMORY.md` (indeks) dulu untuk peta, lalu **setiap berkas** — jangan menilai dari judul
saja. Untuk tiap berkas, pilah:

| Masuk docs (PENGETAHUAN PRODUK) | Lewati (CATATAN KERJA PRIBADI) |
|---|---|
| perilaku yang **disengaja** & alasannya | preferensi cara kerja pribadi / cara berkomunikasi dengan Claude |
| **keputusan** produk/arsitektur & alasannya | status pekerjaan sementara ("lanjut besok", "PR belum merge") |
| **insiden** nyata: gejala → akar → penanganan | catatan lingkungan mesin sendiri (path, token, env) |
| **kesalahpahaman umum** pengguna & jawaban yang benar | pengingat pribadi tanpa nilai untuk orang lain |
| **jebakan** modul (pola yang sudah menggigit) | apa pun yang memuat **kredensial / rahasia / data pribadi siswa-guru** — TIDAK PERNAH |
| aturan bisnis yang tak tertulis di docs | |

Satu berkas bisa memuat keduanya — ambil bagian produknya saja. Ragu → masukkan, beri tanda
`(perlu verifikasi)`.

### 4. Tulis `docs/inbox/catatan_<nama>.md`
Format **tetap** (konsolidator membacanya lintas 9 orang — keseragaman lebih penting dari gaya):

```markdown
# Catatan <nama> — migrasi memory → docs

> Dibuat <YYYY-MM-DD> oleh skill `migrasi-memory-ke-docs` dari <N> berkas memory (<M> dipindah,
> <K> dilewati sebagai catatan pribadi). Belum dikonsolidasi — jangan dirujuk sebagai spesifikasi
> sampai masuk `docs/feature/*` atau `docs/ai-pra-triase.md`.

## <Modul, mis. Ujian>

### <Judul singkat fakta>
- **Tipe:** rancangan-disengaja | keputusan | insiden | kesalahpahaman-umum | jebakan | aturan-bisnis
- **Fakta:** 2–6 kalimat. Konkret: apa perilakunya, kenapa, sejak kapan, apa yang BUKAN bug.
- **Rujukan kode/docs (kalau ada):** `path/berkas.go`, `docs/08-exam.md §3`
- **Sumber:** memory `nama-berkas.md` (<tanggal modified>) · **Status:** masih berlaku | perlu verifikasi
```

Aturan isi:
- Kelompokkan per **modul** memakai nama modul backend/menu (Ujian, Presensi, Penilaian, Materi,
  Pengguna, Mobile Siswa, Exam App, …). Tidak jelas → `## Lintas modul`.
- Fakta ditulis untuk pembaca yang **tidak** ikut sesi asalnya — tanpa "kita", "tadi", "kemarin".
- Tanggal relatif → tanggal absolut (ambil dari `modified` frontmatter).
- Duplikat antar-berkas memory → satu entri, sebut semua sumbernya.
- Bertentangan antar-berkas → tulis keduanya, tandai `⚠️ bertentangan` supaya konsolidator memutuskan.
- Jangan menulis ke `docs/feature/*`, `docs/*.md` bernomor, atau `docs/ai-pra-triase.md`.

### 5. Catat di memory (bukan hapus)
Tulis/perbarui `memory/_migrasi_ke_docs.md` (frontmatter `type: reference`) berisi daftar
`nama-berkas.md → catatan_<nama>.md (YYYY-MM-DD)`. Berkas memory asli **tidak dihapus dan tidak
diubah** — memory tetap berguna untuk sesi pribadi; docs-lah yang jadi milik tim.

### 6. Cabang + PR
```bash
git checkout -b docs/catatan-<nama> origin/main
git add docs/inbox/catatan_<nama>.md
git commit -m "docs(inbox): catatan <nama> — migrasi memory → docs (<M> entri)"
git push -u origin docs/catatan-<nama>
gh pr create --base main --fill
```
Jangan `git add -A` (repo ini sering punya berkas kerja lain). Kalau `gh` tidak ada, beri tahu user
untuk membuka PR manual. PR **tidak** perlu menunggu review panjang — isinya inbox, bukan spesifikasi.

### 7. Laporkan ke user
Ringkas: berapa berkas dibaca / dipindah / dilewati, modul mana yang paling banyak, entri yang
ditandai `perlu verifikasi` atau `⚠️ bertentangan`, tautan PR.

## Jebakan
- **Jangan mengandalkan judul berkas memory** — judul sering "insiden-X" padahal isinya juga
  keputusan rancangan yang berharga.
- **`modified` di frontmatter bisa lebih tua dari isi** kalau berkas diedit tanpa memperbarui
  frontmatter; kalau ragu pakai `git log`-nya tidak ada (memory bukan git) → tulis "≤ <tanggal>".
- **Kredensial**: memory kadang menyimpan token/kata sandi "sementara". Skill ini tidak boleh
  menyalinnya dalam bentuk apa pun, bahkan yang sudah kedaluwarsa.
- **Path repo berbeda per orang** → folder memory berbeda; itu normal. Yang penting cwd = repo ini.
- Menjalankan ulang tanpa perubahan harus menghasilkan **nol entri baru** — kalau tidak, langkah 2
  tidak dibaca.
