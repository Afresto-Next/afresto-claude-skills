---
name: desain-afresto
description: >-
  Panduan desain & sistem UI Afresto Next — WAJIB dibaca sebelum membuat/mengubah
  komponen visual di web (React + Tailwind v4, repo projectTwo) ATAU mobile
  (React Native/Expo, repo afresto-next-mobile). Berisi palet Ocean yang sudah
  DIHITUNG kontrasnya, konvensi komponen, dan JEBAKAN yang sudah menggigit (warna
  gagal WCAG, FAB tak bisa ditekan di Android, letterSpacing terpotong, hover mati di
  layar sentuh, picker/bottom sheet menabrak nav bar Android). Picu saat: bikin
  halaman/komponen, pilih warna, header/gradien, kartu/tombol/modal/picker/bottom sheet,
  tema Ocean, ikon berwarna, bilah tab, atau apa pun yang menyentuh safe area (atas/bawah).
---

# Sistem Desain Afresto ("Ocean")

Satu identitas visual untuk **web** (dashboard admin/guru) dan **mobile** (app siswa/guru/ortu).
Aturan di bawah bukan selera — banyak lahir dari kegagalan NYATA yang terukur. Ikuti; kalau
perlu warna/aturan baru, TAMBAHKAN ke sumber tunggal, jangan tempel nilai lepas di komponen.

Sumber tunggal:
- **Mobile**: `afresto-next-mobile/lib/ocean/tokens.ts` (warna, jarak, radius, bayangan, tipografi).
- **Web**: `projectTwo/web/src/index.css` (`--color-ocean-*`, `.bg-ocean`) + komponen `web/src/components/ui/`.

---

## 1. Prinsip

1. **Kontras dulu, baru cantik.** Setiap warna yang menanggung teks WAJIB ≥ 4,5:1 (AA). Angka di
   bawah sudah dihitung, bukan dikira. Kalau ragu — HITUNG, jangan tebak.
2. **Ocean = hijau→teal→biru.** Gradien merek. Aksen emas hanya untuk sorotan kecil.
3. **Satu sumber warna.** Web: variabel `--color-ocean-*` + kelas Tailwind. Mobile: `tokens.ts`.
   Jangan sebar hex telanjang di komponen.
4. **Hemat GPU di mobile.** HP kelas bawah (Samsung A04e / PowerVR GE8320) nyata dipakai siswa.
   Bayangan bertingkat & blur real-time mahal → pakai tangga `shadow(0..3)`, maks tingkat 1 di list.

---

## 2. Warna

### Gradien merek (web + mobile SAMA)
```
linear-gradient(135deg, #10b981 0% → #14b8a6 45% → #0284c7 100%)   // emerald → teal → biru
```
- Web: kelas `.bg-ocean` (header Topbar, tombol primer). Teks gradien: `.text-ocean-gradient`.
- Mobile: `grad.header` + `locations={gradHeaderLoc}` (0/0,45/1).
- 🚨 Warna ini **cerah tapi TIDAK lolos AA** untuk teks putih (ujung emerald ~2,5:1). Legibilitas
  teks putih di atasnya dijaga **terpisah** dgn bayangan tipis (`textShadowMerek` di mobile;
  di web pakai teks tebal / area gelap), **BUKAN** dengan menggelapkan gradien.

### Warna teks & ikon (yang AMAN)
| Peran | Mobile (tokens) | Web (Tailwind) |
|---|---|---|
| Teks utama | `ink[900]` #0B1F26 (16,9:1) | `text-slate-800` |
| Teks sekunder | `ink[600]` #41616C (6,7:1) | `text-slate-500` |
| Batas bawah teks | `ink[500]` #5E7B85 (4,5:1) | `text-slate-500` |
| Aksen teal (teks/ikon) | `primary[600]` #0B7C6E (5,1:1) | `text-teal-600` |
| Ikon dekoratif / garis | `ink[400]` #8AA3AB — 🚨 **JANGAN untuk teks** | `text-slate-300/400` |
| Latar halaman | `surface.bg` #F2F6F7 | `bg-cyan-100/teal-50` gradien lembut |

### 🚨 Warna yang DILARANG untuk teks
- **`#0d9488`** (teal lama) = **3,74:1 → GAGAL AA.** Pernah dipakai 235× di mobile. Ganti `primary[600]`.
- **`#94a3b8`** (slate-400) = **2,56:1 → gagal telak** sebagai teks. Untuk teks pakai slate-500+.
- **Warna MEREK** `#02CA9B` (2,1) · `#0191D7` (3,5) · `#F5B301` (1,9) — **HARAM** jadi latar teks
  putih. Hanya untuk DEKORASI (garis, isian bar, titik aksen, splash). Teks di atas emas WAJIB gelap.

### Semantik (status)
`sukses` hijau · `peringatan` emas · `bahaya` koral #C0293C (SATU-satunya merah) · `info` biru ·
`netral` abu. Di mobile tiap status punya `fill/tint/ink/dot`. Jangan tandai status **hanya** dengan
warna — ~8% pria buta warna merah-hijau → sertakan bentuk/ikon/teks pendamping.

---

## 3. Komponen & pola

### Web (React + Tailwind v4)
- Pakai komponen `ui/` yang ada: **`Card`, `StatCard`, `Button`, `Modal`, `Input`, `Avatar`**.
  Jangan bikin ulang kartu/modal dari nol.
- **StatCard/HeroChip** menerima `onClick` opsional → otomatis jadi tombol aksesibel
  (role=button, fokus keyboard, Enter/Space, panah "buka").
- **Modal** (`ui/Modal.tsx`): portal ke body, backdrop blur, `Esc` menutup, `lockScroll()`.
  Backdrop **sengaja TIDAK menutup** saat diklik (cegah kehilangan input) — tutup via X/Esc.
- Sorot hover baris/menu: kelas `.ocean-hover` (glow ocean).

### Mobile (React Native)
- Ambil semua dari `tokens.ts`: `sp` (jarak), `r` (radius), `shadow(0..3)`, `type` (tipografi),
  `size` (ukuran komponen), `surface`, `ink`, `primary`, `state`, `grad`.
- **Ubin ikon berwarna** (Menu Cepat & tab Menu): ikon warna penuh di atas `tint` lembut sewarna.
  Ikon yang sama untuk fitur yang sama di mana pun (konsistensi = "satu aplikasi").
- **Header gradien membulat** (`components/ocean/OceanHeader.tsx`) dipakai semua halaman via prop
  `header` di layout — bukan diedit tiap layar.

### Safe area (WAJIB — atas & bawah, Android + iOS)
Hormati safe area lewat `react-native-safe-area-context` (`useSafeAreaInsets()`), **jangan** hardcode
tinggi status/nav bar (beda tiap HP & versi OS).
- **Atas** (status bar / notch): konten mulai di bawah `insets.top`. Header Ocean sudah menanganinya;
  konten kustom di luar header pakai `insets.top`.
- **Bawah** (nav bar 3-tombol/gesture Android + home indicator iOS): setiap **bottom sheet / picker /
  modal / action sheet** dan **CTA yang menempel di bawah** WAJIB memberi ruang bawah:
  - kontainer sheet: `paddingBottom: Math.max(insets.bottom, sp[3])`;
  - list di dalam sheet: `contentContainerStyle={{ paddingBottom: insets.bottom + sp[3] }}`.
  Tujuan: item terakhir & tombol **tidak pernah** ketutup bilah bawah. Uji di HP Android bernavigasi
  gesture **dan** 3-tombol (tinggi berbeda).

### Tipografi
- Mobile: **Sora hanya untuk ≥18sp** (judul & angka besar). Teks tubuh/label = **font sistem**
  (lebih cepat, akrab). Family & bobot sudah DIPASANGKAN di `type` — jangan campur sendiri.
- Web: sistem/Inter. Judul `font-semibold text-slate-800`.

---

## 4. 🔥 JEBAKAN (semua sudah MENGGIGIT — jangan ulangi)

1. **FAB mengambang di atas bilah tab = TAK BISA DITEKAN di Android.** Android tak meneruskan
   sentuhan ke anak DI LUAR batas induk. Tombol yang menyembul keluar bilah tampil sempurna & mati
   total. **iOS meneruskannya → bug ini tak pernah muncul saat uji di iPhone.** ➡️ Tombol menonjol
   lewat WARNA/BENTUK, tetap DI DALAM batas induk.
2. **`letterSpacing` TIDAK diukur RN Android** → teks dirender lebih lebar dari kotaknya →
   UJUNGNYA TERPOTONG (terbukti "AFRESTO"→"AFREST" di layar 360dp). ➡️ Jangan pakai letterSpacing
   pada Text yang boleh membungkus; kalau perlu: ≤0,4 + padding + `numberOfLines={1}`.
3. **Warna cerah bisa gagal WCAG diam-diam.** API/TS tak akan mengeluh soal kontras. UKUR sendiri
   (rasio ≥4,5 teks normal, ≥3 teks besar). Gradien merek gagal → jaga teks dgn bayangan, bukan
   dgn menggelapkan warna.
4. **Tailwind v4 membungkus `hover:` dalam `@media(hover:hover)`** → hover MATI di laptop layar
   sentuh. Fix sudah ada: `@custom-variant hover (&:hover)` di `index.css`. Jangan hapus.
5. **Status hanya-warna tak cukup** (buta warna) → sertakan ikon/bentuk/teks.
6. **Modal backdrop-click menutup = kehilangan input.** Pola Afresto: tutup hanya via X/Esc.
7. **Bottom sheet / picker menabrak nav bar Android.** Daftar pilihan (mis. picker Mapel di "Buat
   Materi") yang tak memberi `paddingBottom: insets.bottom` → item terakhir **ketutup** tombol/gesture
   navigasi bawah Android (dan home indicator iOS). Terbukti nyata. ➡️ Semua sheet/picker/modal & CTA
   bawah WAJIB tambah `insets.bottom` via `useSafeAreaInsets` (lihat §3 "Safe area"). Jangan hardcode
   tinggi nav bar — beda-beda per HP. Bug ini **tak muncul di simulator/HP tertentu** → uji lintas HP.

---

## 5. Alur kerja saat mendesain

1. Buka sumber tunggal (`tokens.ts` / `index.css`) — pakai token yang ADA. Warna baru → tambah di sana.
2. Untuk komponen web, cek dulu `ui/` — kemungkinan besar sudah ada.
3. Setiap warna teks: pastikan lolos AA (lihat tabel §2). Ragu → hitung.
4. Mobile: pilih `shadow()` tingkat sekecil mungkin; hindari nested shadow di list.
5. Mobile: layar baru & **setiap picker/sheet/modal/CTA-bawah** → tambah `insets.bottom` (dan hormati
   `insets.top`) via `useSafeAreaInsets`. Jangan hardcode tinggi bar.
6. Lewati checklist §4 sebelum menyatakan selesai — terutama FAB (Android), letterSpacing & safe area.

Terkait catatan proyek: design system Ocean & jebakan UI ada di memori
`afresto-next-ui-redesign-ocean` dan `afresto-next-tailwind-hover-touchscreen`.
