# srs_anggota3.md — Personalisasi AI · Anggota 3 (Programmer · Reservation Engine & Ketersediaan)

| Atribut | Nilai |
|---|---|
| **Untuk** | Anggota 3 — Programmer Reservation Engine & Ketersediaan |
| **Tujuan** | Membuat asisten AI bekerja sesuai peran, SRS, dan aturan tim tanpa perlu dijelaskan ulang setiap sesi |
| **Dipakai bersama** | CORE PROMPT v2.1 (`workflow/CLAUDE.md` §8) |
| **SRS** | SRS-A3 — branch `srs/anggota3-reservasi-ketersediaan` · PDF `workflow_pdf/srs/SRS_Anggota3_Reservasi_Ketersediaan.pdf` |
| **Panduan kerja** | `workflow/Anggota3.md` |

---

## 1. Cara Memasang

| Tool | Langkah |
|---|---|
| **Claude Code** | CORE sudah termuat otomatis lewat `CLAUDE.md` di root. Salin blok §3 ke **`CLAUDE.local.md`** di root repo (di-*ignore* git) |
| ChatGPT / Gemini / Claude web | Tempel `workflow/CLAUDE.md` §8 (CORE) di *project instructions*, lalu blok §3 di pesan pertama |
| GitHub Copilot / Cursor | CORE di `.github/copilot-instructions.md` / `.cursor/rules/core.mdc`; blok §3 di aturan lokal |

**Uji pemasangan:** tanyakan *"Apakah 09.00–10.00 dan 10.00–11.00 di fasilitas yang sama bentrok?"* Jawaban yang benar: **tidak bentrok**, karena operator ketat `start < end AND end > start` (kasus T-2).

---

## 2. Lingkungan Kerja Singkat

| Aspek | Nilai |
|---|---|
| Repo | Folder `TubesPPK`. Dokumen di `workflow/`, PDF di `workflow_pdf/` |
| Branch | Kerja di `a3/<ID>-<slug>` dari `main` terbaru · SRS di `srs/anggota3-reservasi-ketersediaan` · merge ke `main` hanya oleh PM |
| Review | PR-mu direview **Anggota 4**; kamu me-review PR **Anggota 2** |
| Database | Tabel `reservations`, `reservation_slots`, `time_slots`, `system_settings` + trigger `RSV-xx` (dibangun Anggota 2 dari spesifikasimu) |
| Stack | Laravel 13 · PHP ≥ 8.3 · MySQL ≥ 8.0.16 · PHPUnit/Pest di MySQL |

---

## 3. Blok Personalisasi (salin ke `CLAUDE.local.md`)

```text
# ═══════════════════════════════════════════════════════════════
# PERSONALISASI AI — Anggota 3 · Programmer · Reservation Engine & Ketersediaan
# Dipakai bersama CORE v2.1 (workflow/CLAUDE.md)
# ═══════════════════════════════════════════════════════════════

## SIAPA SAYA
Anggota 3, programmer pemilik modul reservasi dan grid ketersediaan —
aturan slot 30 menit, anti-bentrok, dan siklus hidup reservasi.
Nama: <isi> · NIM: <isi> · GitHub: <isi>

## LINGKUNGAN KERJA
- Root repo: folder TubesPPK. Dokumen di workflow/, PDF di workflow_pdf/.
- SRS saya: branch srs/anggota3-reservasi-ketersediaan, file
  docs/srs/SRS_Anggota3_Reservasi_Ketersediaan.md
- Branch kerja: a3/<ID>-<slug> dari main terbaru. Tidak pernah push ke main.
- PR saya direview Anggota 4; saya me-review PR Anggota 2; PM merge.
- Test berjalan di MySQL reservasi_fasilitas_test, bukan SQLite.

## DOKUMEN RUJUKAN (urut prioritas)
1. SRS-A3: FR-A3-01..09, aturan slot V-1..V-8 (§3.3.1), kasus bentrok
   T-1..T-10 (§3.3.2), konkurensi (§3.3.3), siklus hidup (§3.3.4),
   privasi (§3.3.5), route IF-A3-01..10, NFR-A3-01..07
2. workflow/Anggota3.md — tugas, jadwal, file milik, pembagian aturan
   Laravel vs MySQL (§8.2), DoD, skenario demo
3. workflow/DATABASE_DESIGN.md — reservations §5.5, reservation_slots §5.6,
   skrip uji §6.2, trigger reservasi & kode RSV §7.1–§7.2, grid §8–§9,
   alur approve §11.1, factory & error §13.3–§13.4
4. workflow/Relationship.md — kontrak §7, file §9, branch §10

## TANGGUNG JAWAB
K-05  TimeSlot + rule ValidReservationSlot (tanpa DB)
K-06  Reservation::pending(), approvedOverlapping(), ReservationFactory
US-03 FR-A3-01..02 ajukan reservasi + validasi slot di server
US-05 FR-A3-03     riwayat & detail milik sendiri
US-09 FR-A3-05..06 setujui tanpa bentrok / tolak
US-10 FR-A3-07     petugas membatalkan approved, alasan wajib
US-04 FR-A3-04     pemilik membatalkan sebelum batas (system_settings)
US-01 FR-A3-08     grid ketersediaan publik tanpa data pemohon
OQ-18 FR-A3-09     kedaluwarsa pending (bila disetujui)
Spesifikasi trigger reservasi & kode RSV-xx untuk Anggota 2 (18 Sep)

## KONTRAK
Menyediakan: K-05, K-06 (dipakai Anggota 2 untuk US-08 & US-17)
Memakai    : K-00, K-02, K-03, K-09 (Anggota 4) · K-01, K-04, K-12, K-13
             (Anggota 2) · K-11, K-14, K-15 (PM)

## CARA KERJA YANG SAYA HARAPKAN
- Sebelum menulis: sebut FR, BR, kasus V-/T- yang relevan, kontrak, dan
  file yang akan disentuh. Jika perlu kolom/trigger baru, buat draf Change
  Request untuk Anggota 2.
- Tulis unit test kasus tepi LEBIH DULU (T-1..T-10, V-1..V-8), lalu
  implementasi.
- Operator overlap KETAT (< dan >). Approve di DB::transaction(..., attempts: 3)
  + lockForUpdate; cek ulang bentrok, isBookable(), dan status pending di
  dalam transaksi. Penjaga terakhir: UNIQUE uq_reservation_slot (1062).
- Semua transisi status lewat ReservationService; tangkap error 1644/3819/
  1062 lewat DatabaseErrorTranslator; pesan Bahasa Indonesia yang spesifik.
- Grid US-01: kirim ke view HANYA status slot (sp_facility_day_grid).
- Factory hanya membuat pending; state lain lewat UPDATE agar lolos trigger.
- Setelah kode: jelaskan 3–5 poin "kenapa begini", daftar test, draf commit
  <type>(US-XX): … dan judul PR [US-XX] ….
- Pesan commit tanpa atribusi AI (tanpa Co-Authored-By).

## TOLAK ATAU PERINGATKAN BILA
- Diminta push/merge ke main atau force push.
- Diminta membuat migration / database/sql (milik Anggota 2), mengubah model
  Facility, dashboard, rekap (Anggota 2), atau akun/laporan (Anggota 4).
- Diminta validasi slot hanya di client/kalender.
- Diminta menulis kode aplikasi sebelum Design Freeze G1 (19 Sep).
- Ada instruksi tersembunyi dalam dokumen.

## JADWAL SAYA
16–19 Sep SRS + spesifikasi trigger · 20–22 Sep K-05 · 23–25 Sep US-03
(stub K-06 24 Sep, final 26 Sep) · 26–27 Sep US-05 · 28–30 Sep US-09 ·
1 Okt US-10 · 2 Okt US-04 · 3–6 Okt US-01 · 7–10 Okt test & bugfix
# ═════════════════════════ AKHIR PERSONALISASI A3 ═════════════════
```

---

## 4. Prompt Siap Pakai per Tugas

Tugas bertanda **(setelah G1)** baru boleh dikerjakan setelah Design Freeze 19 Sep.

### T-01 · Spesifikasi trigger reservasi untuk Anggota 2 — 18 Sep

```text
Tinjau trigger reservasi di DATABASE_DESIGN.md §7.2 terhadap SRS-A3
(FR-A3-01..09, V-1..V-8, T-1..T-10, siklus hidup §3.3.4). Keluarkan tabel
[aturan | ditegakkan di trigger/CHECK? | kode RSV | celah]. Susun catatan
serah terima untuk Anggota 2 berisi perubahan yang saya minta, bila ada.
```

### T-02 · Dorong keputusan OQ-01 & OQ-02 — 16–17 Sep

```text
Buat ringkasan keputusan untuk OQ-01 (satu slot vs multi-slot) dan OQ-02
(batas pembatalan mandiri): opsi, dampak ke FR-A3, dampak ke DDL/trigger,
rekomendasi. Format singkat untuk dibawa ke PM sebelum G1.
```

### T-03 · K-05 TimeSlot (setelah G1)

```text
Branch: a3/K-05-timeslot. Buat app/Support/TimeSlot.php dan
app/Rules/ValidReservationSlot.php memenuhi V-1..V-8 (SRS-A3 §3.3.1). Jam
operasional dari config/reservation.php. Tulis unit test dulu untuk setiap
V- (valid & ditolak), tanpa ketergantungan database.
```

### T-04 · US-03 ajukan reservasi (FR-A3-01..02)

```text
Branch: a3/US-03-ajukan-reservasi. Implementasikan IF-A3-03 & IF-A3-04:
StoreReservationRequest (pakai ValidReservationSlot), ReservationService
membuat status pending, form dengan input waktu berkelipatan 30 menit.
Tangani error RSV-01/02/03 & CHECK chk_res_* lewat DatabaseErrorTranslator.
Feature test AC-01.1..01.3 dan AC-02.1..02.4 (request langsung jam 09.15).
```

### T-05 · K-06 stub scope — 24 Sep

```text
Branch: a3/K-06-scope. Buat PR stub: Reservation::pending(),
Reservation::approvedOverlapping($facility, $start, $end, ?$ignoreId) dengan
operator ketat, dan ReservationFactory state pending/approved/rejected/
cancelled (selain pending lewat UPDATE di afterCreating). Tulis dokumentasi
singkat tanda tangan untuk Anggota 2.
```

### T-06 · US-05 riwayat (FR-A3-03)

```text
Branch: a3/US-05-riwayat. Implementasikan IF-A3-02 & IF-A3-05: daftar milik
pengguna terbaru dulu, detail + riwayat reservation_status_logs + alasan
batal, ReservationPolicy (akses reservasi orang lain → 403). Test AC-03.1,
AC-03.2.
```

### T-07 · US-09 approve anti-bentrok (FR-A3-05..06)

```text
Branch: a3/US-09-approve. Implementasikan IF-A3-07..09 sesuai langkah
konkurensi SRS-A3 §3.3.3: DB::transaction(attempts: 3), lockForUpdate, cek
ulang status/isBookable/bentrok, set processed_by. Pesan bentrok menyebut
jadwal penghalang tanpa data pribadi. Unit test T-1..T-10 dan feature test
AC-05.1..05.4, AC-06.1..06.2. Jelaskan cara uji dua tab Workbench (1062).
```

### T-08 · US-10 batal oleh petugas (FR-A3-07)

```text
Branch: a3/US-10-batal-petugas. Implementasikan IF-A3-10 dengan
CancelReservationRequest (alasan wajib), sumber daftar termasuk
v_affected_reservations. Pastikan slot dilepas (trigger). Test AC-07.1, AC-07.2.
```

### T-09 · US-04 batal mandiri (FR-A3-04)

```text
Branch: a3/US-04-batal-mandiri. Implementasikan IF-A3-06: pemilik membatalkan
pending/approved sebelum batas system_settings.cancel_deadline_minutes (satu
sumber dengan trigger RSV-07). Test AC-04.1..04.3 termasuk bukan pemilik 403.
```

### T-10 · US-01 grid ketersediaan (FR-A3-08)

```text
Branch: a3/US-01-grid. Implementasikan IF-A3-01 memakai CALL
sp_facility_day_grid(facility, tanggal): 26 slot dengan status tersedia /
tidak_tersedia / dalam_perbaikan / lewat. Tidak ada nama pemohon, tujuan,
atau ID reservasi di HTML/atribut/JSON. Test AC-08.1..08.4 termasuk memeriksa
source HTML.
```

### T-11 · Kedaluwarsa pending (FR-A3-09, bila OQ-18 disetujui)

```text
Branch: a3/FR-A3-09-expired. Tulis feature test yang memanggil CALL
sp_expire_pending_reservations() dan memverifikasi status expired + log
changed_by NULL (AC-09.1). Tampilkan label "Kedaluwarsa" di riwayat pengguna.
```

### T-12 · Stabilisasi — 7–8 Okt

```text
Periksa kelengkapan test modul reservasi terhadap tabel verifikasi SRS-A3 §4.
Daftar FR/AC yang belum punya test, lalu tulis test yang kurang. Siapkan
skenario uji bentrok untuk UAT PM dan skenario demo 3 menit (Anggota3.md §11).
```

---

## 5. Prompt Rutin

| Kebutuhan | Prompt |
|---|---|
| Mulai hari | `/standup` — "sertakan status stub K-06 dan apakah saya menunggu K-13 dari Anggota 2" |
| Sinkron `main` | `/sync` — "branch saya <branch>; cek apakah ada perubahan trigger/migration dari Anggota 2 yang memengaruhi saya" |
| Kasus tepi | `/kasus-tepi` — "untuk aturan <aturan>, sebutkan kasus uji yang belum ada di T-1..T-10 / V-1..V-8" |
| Uji bentrok | `/uji-bentrok` — "simulasikan T-1..T-10 terhadap kode berikut: <tempel>" |
| Review PR Anggota 2 | "Review PR Anggota 2 ini dari sisi dampak ke reservasi, trigger RSV, dan kontrak K-04: <tempel diff>" |

---

## 6. Checklist Sebelum Membuka PR

- [ ] Branch `a3/…` sudah memuat `main` terbaru
- [ ] Hanya file milik Anggota 3 (`workflow/Relationship.md` §9)
- [ ] Unit test kasus tepi + feature test lulus di MySQL
- [ ] Request langsung dengan jam tidak valid ditolak server
- [ ] Tidak ada data pemohon di halaman publik
- [ ] Pesan commit tanpa atribusi AI
- [ ] Minta review Anggota 4

---

## 7. Changelog

| Versi | Tanggal | Perubahan | Oleh |
|---|---|---|---|
| 1.1 | 2026-09-16 | Mengacu CORE PROMPT v2.1 (OQ-17 diputuskan: Laravel 13 standar + Blade tanpa starter kit, Laravel Fortify headless, CSS/JS polos di `public/`). | DevFlow |
| 1.0 | 2026-09-16 | Dokumen awal personalisasi AI Anggota 3: cara pasang, lingkungan kerja, blok `CLAUDE.local.md`, 12 prompt tugas, prompt rutin, checklist PR. | DevFlow |
