#!/usr/bin/env bash
#
# Skill berubah WAJIB menaikkan versi plugin.
#
# Kenapa pagar ini ada: 20 Agu 2026 `afresto-deploy/SKILL.md` berubah +40/-6 tanpa versi
# dinaikkan. Akibatnya pembaruan otomatis menyimpulkan "sudah terbaru" dan TAK menarik apa pun —
# seluruh tim memakai skill deploy versi lama selama 15 hari tanpa ada satu pun tanda. README
# sudah mengatur langkahnya sejak awal; yang tak ada adalah yang menegakkannya.
#
# 🪤 Versi ada di DUA berkas dan keduanya harus naik:
#   - .claude-plugin/marketplace.json          (dibaca saat memasang dari marketplace)
#   - plugins/<plugin>/.claude-plugin/plugin.json  (dibaca plugin itu sendiri)
# Menaikkan salah satu saja adalah cara paling mudah membuat pagar ini lolos tapi update tetap
# tak sampai — jadi keduanya diperiksa terpisah.
#
# Dipakai CI (.github/workflows/versi-plugin.yml). Bisa dijalankan lokal:
#   BASE=<sha-lama> HEAD=<sha-baru> bash .github/scripts/cek-versi-plugin.sh
set -euo pipefail

# 🪤 Git Bash (Windows) menerjemahkan "sha:path" jadi path Windows sehingga `git show` gagal —
# dan dulu kegagalan itu tertelan, membuat pagar ini LOLOS pada perubahan yang seharusnya
# ditolak. Diabaikan di Linux; wajib ada agar pengujian lokal jujur.
export MSYS_NO_PATHCONV=1

BASE="${BASE:?BASE (sha dasar) wajib diisi}"
HEAD="${HEAD:?HEAD (sha perubahan) wajib diisi}"

MARKET=".claude-plugin/marketplace.json"

# 🪤 Pilih penafsir dengan MENJALANKANNYA, bukan dengan `command -v`. Di Windows `python3` sering
# berupa pintasan Microsoft Store yang ADA menurut command -v tapi gagal begitu dipanggil —
# cukup untuk membuat pengujian lokal menyesatkan.
PY_BIN="${PY_BIN:-}"
if [ -z "$PY_BIN" ]; then
  for kandidat in python3 python; do
    if "$kandidat" -c 'import sys, json' >/dev/null 2>&1; then PY_BIN="$kandidat"; break; fi
  done
fi
[ -n "$PY_BIN" ] || { echo "GALAT: butuh python3 (atau python) yang bisa dijalankan." >&2; exit 2; }

# Dibaca dengan python3, bukan jq: python3 ada di runner GitHub DAN di mesin pengembang
# (Git Bash Windows tak membawa jq), jadi pagar ini bisa diuji lokal sebelum dipercaya.
#
# 🔴 GAGAL-TERTUTUP. Versi sebelumnya menelan galat baca lalu menyimpulkan "plugin baru" —
# pagarnya meloloskan justru perubahan yang harus ditolak. Sekarang: berkas tak ada = kasus sah
# (plugin memang baru), tapi berkas ADA namun gagal dibaca = BERHENTI dengan galat.
ada() { git cat-file -e "$1:$2" 2>/dev/null; }

baca_versi() { # <rev> <path> <ekspresi-python>
  local isi
  if ! isi="$(git show "$1:$2" 2>&1)"; then
    echo "GALAT: tak bisa membaca $2 pada $1 — $isi" >&2
    exit 2
  fi
  printf '%s' "$isi" | "$PY_BIN" -c "$3" "${4:-}" || { echo "GALAT: $2 pada $1 bukan JSON yang sah." >&2; exit 2; }
}

versi_plugin() {
  ada "$1" "plugins/$2/.claude-plugin/plugin.json" || return 1
  baca_versi "$1" "plugins/$2/.claude-plugin/plugin.json"     'import json,sys; print(json.load(sys.stdin).get("version",""))'
}
versi_market() {
  ada "$1" "$MARKET" || return 1
  baca_versi "$1" "$MARKET"     'import json,sys; n=sys.argv[1]; print(next((p.get("version","") for p in json.load(sys.stdin).get("plugins",[]) if p.get("name")==n), ""))' "$2"
}

# Naik = versi berbeda DAN yang baru lebih besar menurut urutan versi. Sengaja bukan sekadar
# "berbeda": menurunkan versi juga membuat klien mengira dirinya sudah terbaru.
naik() {
  local lama="$1" baru="$2"
  [ -n "$baru" ] || return 1
  [ "$lama" != "$baru" ] || return 1
  [ "$(printf '%s\n%s\n' "$lama" "$baru" | sort -V | tail -1)" = "$baru" ]
}

berubah="$(git diff --name-only "$BASE" "$HEAD" -- 'plugins/*/skills/*' || true)"
if [ -z "$berubah" ]; then
  echo "✓ Tak ada berkas skill yang berubah — pagar versi tak berlaku."
  exit 0
fi

echo "Berkas skill yang berubah:"
echo "$berubah" | sed 's/^/  /'
echo

gagal=0
for plugin in $(echo "$berubah" | awk -F/ 'NF>3 {print $2}' | sort -u); do
  # `|| true` hanya menampung "berkas tak ada" (return 1); galat baca sudah keluar exit 2.
  pl_lama="$(versi_plugin "$BASE" "$plugin" || true)"
  pl_baru="$(versi_plugin "$HEAD" "$plugin" || true)"
  mk_lama="$(versi_market "$BASE" "$plugin" || true)"
  mk_baru="$(versi_market "$HEAD" "$plugin" || true)"

  # Plugin BARU (plugin.json belum ada di commit dasar) tak perlu dinaikkan — versinya perdana.
  if ! ada "$BASE" "plugins/$plugin/.claude-plugin/plugin.json"; then
    echo "✓ $plugin: plugin baru (versi perdana $pl_baru) — tak perlu dinaikkan."
    continue
  fi

  for pasangan in "plugin.json|$pl_lama|$pl_baru" "marketplace.json|$mk_lama|$mk_baru"; do
    IFS='|' read -r berkas lama baru <<<"$pasangan"
    if naik "$lama" "$baru"; then
      echo "✓ $plugin — $berkas: $lama → $baru"
    else
      echo "✗ $plugin — $berkas: $lama → ${baru:-(tak ada)}  TIDAK NAIK"
      gagal=1
    fi
  done
done

if [ "$gagal" -ne 0 ]; then
  cat <<'PESAN'

──────────────────────────────────────────────────────────────────────────
Skill berubah tapi versi plugin tidak naik.

Tanpa kenaikan versi, pembaruan otomatis menyimpulkan "sudah terbaru" dan
perubahan ini TIDAK AKAN PERNAH sampai ke tim — tanpa galat, tanpa tanda.

Naikkan versi di KEDUA berkas ini, lalu push lagi:
  .claude-plugin/marketplace.json
  plugins/<plugin>/.claude-plugin/plugin.json

Prosedur lengkap ada di README, bagian "Update skill".
──────────────────────────────────────────────────────────────────────────
PESAN
  exit 1
fi

echo
echo "✓ Versi sudah dinaikkan untuk semua plugin yang skill-nya berubah."
