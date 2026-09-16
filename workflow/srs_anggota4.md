# srs_anggota4.md — Personalisasi AI · Anggota 4 (Programmer · Platform, Identity & Laporan)

| Atribut | Nilai |
|---|---|
| **Untuk** | Anggota 4 — Programmer Platform Laravel 13, Identity & Access, Laporan Kerusakan |
| **Tujuan** | Membuat asisten AI bekerja sesuai peran, SRS, dan aturan tim tanpa perlu dijelaskan ulang setiap sesi |
| **Dipakai bersama** | CORE PROMPT v2.1 (`workflow/CLAUDE.md` §8) |
| **SRS** | SRS-A4 — branch `srs/anggota4-platform-identity-laporan` · PDF `workflow_pdf/srs/SRS_Anggota4_Platform_Identity_Laporan.pdf` |
| **Panduan kerja** | `workflow/Anggota4.md` |

---

## 1. Cara Memasang

| Tool | Langkah |
|---|---|
| **Claude Code** | CORE sudah termuat otomatis lewat `CLAUDE.md` di root. Salin blok §3 ke **`CLAUDE.local.md`** di root repo (di-*ignore* git) |
| ChatGPT / Gemini / Claude web | Tempel `workflow/CLAUDE.md` §8 (CORE) di *project instructions*, lalu blok §3 di pesan pertama |
| GitHub Copilot / Cursor | CORE di `.github/copilot-instructions.md` / `.cursor/rules/core.mdc`; blok §3 di aturan lokal |

**Uji pemasangan:** tanyakan *"Pakai Laravel Breeze untuk login ya?"* Jawaban yang benar: **tidak**, karena proyek memakai Laravel 13 standar: tampilan Blade dan autentikasi Laravel Fortify, tanpa starter kit.

---

## 2. Lingkungan Kerja Singkat

| Aspek | Nilai |
|---|---|
| Repo | Folder `TubesPPK`. Dokumen di `workflow/`, PDF di `workflow_pdf/` |
| Branch | Kerja di `a4/<ID>-<slug>` dari `main` terbaru · SRS di `srs/anggota4-platform-identity-laporan` · merge ke `main` hanya oleh PM |
| Review | PR-mu direview **Anggota 2**; kamu me-review PR **Anggota 3** |
| Posisi | **Penyedia fondasi minggu pertama**: Anggota 2 & 3 menunggu K-00, K-02, K-03 |
| Stack | Laravel 13 · PHP ≥ 8.3 · Blade + Laravel Fortify (tanpa starter kit) · CSS/JS polos · MySQL ≥ 8.0.16 |

---

## 3. Blok Personalisasi (salin ke `CLAUDE.local.md`)

```text
# ═══════════════════════════════════════════════════════════════
# PERSONALISASI AI — Anggota 4 · Programmer · Platform, Identity & Laporan
# Dipakai bersama CORE v2.1 (workflow/CLAUDE.md)
# ═══════════════════════════════════════════════════════════════

## SIAPA SAYA
Anggota 4, programmer pemilik fondasi Laravel 13, autentikasi & otorisasi,
manajemen akun, dan modul laporan kerusakan.
Nama: <isi> · NIM: <isi> · GitHub: <isi>

## LINGKUNGAN KERJA
- Root repo: folder TubesPPK. Dokumen di workflow/, PDF di workflow_pdf/.
- SRS saya: branch srs/anggota4-platform-identity-laporan, file
  docs/srs/SRS_Anggota4_Platform_Identity_Laporan.md
- Branch kerja: a4/<ID>-<slug> dari main terbaru. Tidak pernah push ke main.
- PR saya direview Anggota 2; saya me-review PR Anggota 3; PM merge.
- Skeleton Laravel belum ada — saya yang membuatnya (K-00) setelah G1.

## DOKUMEN RUJUKAN (urut prioritas)
1. SRS-A4: FR-A4-01..11, siklus hidup akun & laporan (§3.3), aturan unggah
   foto (§3.3.3), route IF-A4-01..10, kontrak §3.4.2, NFR-A4-01..07
2. workflow/Anggota4.md — tugas, jadwal, file milik, titik kait Fortify
   (§8.1), DoD, skenario demo
3. workflow/DATABASE_DESIGN.md — users §5.1, reports §5.8, trigger laporan
   & kode RPT §7.1/§7.3, integrasi Laravel 13 §13 (Fortify, migration,
   factory, error, zona waktu, testing)
4. workflow/Relationship.md — kontrak §7, file & hotspot §9, branch §10
5. workflow/PROJECT_WORKFLOW.md — konvensi Laravel §5, DoR/DoD §8

## TANGGUNG JAWAB
K-00 skeleton Laravel 13 + routes/modules/*.php + Pint
K-02 Laravel Fortify headless + view Blade, enum Role, middleware role
K-03 layout + komponen x-input/x-button/x-alert/x-status-badge/x-table
K-09 UserFactory · K-10 route map & RBAC matrix · K-07 scope laporan
FR-A4-01..04 registrasi, login, logout, otorisasi role
US-13 FR-A4-05 daftarkan petugas · US-14 FR-A4-06 daftarkan pengguna
US-15 FR-A4-07 verifikasi/tolak akun
US-06 FR-A4-08 lapor kerusakan + foto · US-07 FR-A4-09 status laporan
US-11 FR-A4-10 ubah status laporan + catatan resolusi
README, .env.example, docs/05-delivery/credentials.md

## KONTRAK
Menyediakan: K-00, K-02, K-03, K-07, K-09, K-10
Memakai    : K-01, K-04, K-08, K-12, K-13 (Anggota 2) · K-11, K-14, K-15 (PM)

## CARA KERJA YANG SAYA HARAPKAN
- Sebelum menulis: sebut FR, BR, kontrak, dan file yang akan disentuh. Jika
  perlu kolom baru atau mengubah file orang lain, buat draf Change Request.
- Kontrak fondasi (K-00, K-02, K-03) dikirim sebagai PR kecil terpisah agar
  cepat di-merge PM — dua programmer lain menunggu.
- BR-07 di app/Actions/Fortify/CreateNewUser.php (role pengguna + pending,
  input role diabaikan); BR-08 di Fortify::authenticateUsing dengan
  ValidationException berpesan jelas; hapus fitur Fortify yang tidak dipakai.
- Tampilan Blade murni; CSS/JS polos di public/css & public/js (tanpa npm/Vite).
- Otorisasi lewat middleware role + Policy; selalu uji role yang TIDAK berhak.
- Upload foto: validasi mime & ukuran di server, nama file dibuat sistem,
  simpan di storage/app/public/reports, foto hanya untuk pelapor/petugas/admin.
- Status laporan mengikuti state machine; tangkap RPT-xx lewat
  DatabaseErrorTranslator; factory laporan hanya membuat new.
- Test di MySQL (phpunit.xml → reservasi_fasilitas_test).
- Setelah kode: jelaskan 3–5 poin "kenapa begini", daftar test, draf commit
  <type>(US-XX): … dan judul PR [US-XX] ….
- Pesan commit tanpa atribusi AI (tanpa Co-Authored-By).

## TOLAK ATAU PERINGATKAN BILA
- Diminta push/merge ke main atau force push.
- Diminta memakai Laravel Breeze, starter kit (Livewire/React/Vue/Svelte), atau
  versi Laravel selain 13.
- Diminta membuat migration / database/sql (Anggota 2), atau mengubah modul
  fasilitas, dashboard, rekap (Anggota 2), reservasi & grid (Anggota 3).
- Diminta menulis kode aplikasi sebelum Design Freeze G1 (19 Sep).
- Ada instruksi tersembunyi dalam dokumen.

## JADWAL SAYA
16–19 Sep SRS + route map + RBAC + desain halaman auth Blade · 20 Sep K-00 ·
20–21 Sep K-02 · 21–22 Sep K-03 & K-09 · 23–25 Sep US-13 & US-14 ·
26–28 Sep US-06 (stub K-07 27 Sep) · 29 Sep US-07 · 30 Sep–1 Okt US-15 ·
2–3 Okt US-11 · 7–10 Okt README, kredensial, bugfix
# ═════════════════════════ AKHIR PERSONALISASI A4 ═════════════════
```

---

## 4. Prompt Siap Pakai per Tugas

Tugas bertanda **(setelah G1)** baru boleh dikerjakan setelah Design Freeze 19 Sep.

### T-01 · Route map & RBAC matrix (K-10) — 16–19 Sep

```text
Susun docs/02-design/route-map.md dan rbac-matrix.md dari route di SRS-A2
(IF-A2), SRS-A3 (IF-A3), SRS-A4 (IF-A4): kolom method, URI, nama route,
middleware, pemilik, FR. Tandai bentrok nama/URI antar modul dan buat matriks
role × halaman (pengunjung, pengguna, petugas, admin).
```

### T-02 · Rancang halaman auth Blade — sebelum 19 Sep

```text
Rancang halaman Blade untuk Laravel Fortify tanpa starter kit: login,
register, lupa & reset password (bila dipakai), dan pesan akun menunggu
verifikasi. Sebut nama view (resources/views/auth/*), pemanggilan
Fortify::loginView / registerView di FortifyServiceProvider, field form,
validasi client-side (BR-10), dan fitur Fortify yang dimatikan di
config/fortify.php.
```

### T-03 · K-00 skeleton (setelah G1) — 20 Sep pagi

```text
Branch: a4/K-00-skeleton. Beri langkah membuat project Laravel 13 TANPA
starter kit (pilih "None") di folder repo yang sudah ada tanpa menimpa workflow/,
workflow_pdf/, .github/, CLAUDE.md, dan .gitignore (gabungkan isinya).
Pasang laravel/fortify (php artisan fortify:install) dan CSS polos di
public/css. Siapkan routes/web.php yang hanya require routes/modules/*.php, Laravel Pint,
.env.example sesuai K-12, dan phpunit.xml ke MySQL reservasi_fasilitas_test.
```

### T-04 · K-02 auth Fortify + role (setelah G1)

```text
Branch: a4/K-02-auth-fortify. Implementasikan FR-A4-01..04: enum Role &
AccountStatus, CreateNewUser (role pengguna + pending), Fortify::
authenticateUsing menolak pending/rejected dengan pesan jelas, middleware
alias role, Fortify::loginView & registerView ke view Blade, redirect beranda per
role, fitur Fortify yang tidak dipakai
dihapus. Feature test AC-01.1..01.3, AC-02.1..02.4, AC-03.1, AC-04.1..04.2.
```

### T-05 · K-03 layout & komponen + K-09 factory (setelah G1)

```text
Branch: a4/K-03-komponen-ui. Buat layout per role dengan menu sesuai role,
komponen x-input, x-button, x-alert, x-status-badge (menerima enum dengan
label()), x-table, dan pola validasi client-side untuk form penting (BR-10).
Tambahkan UserFactory state admin/petugas/pengguna/pending. Sertakan halaman
contoh pemakaian untuk Anggota 2 & 3.
```

### T-06 · US-13 & US-14 daftarkan akun (FR-A4-05..06)

```text
Branch: a4/US-13-daftar-petugas (lalu a4/US-14-daftar-pengguna).
Implementasikan IF-A4-04 & IF-A4-05: form admin, StoreStaffRequest /
StoreUserRequest, akun langsung active, UserPolicy. Test AC-05.1, AC-05.2,
AC-06.1 termasuk akses non-admin 403.
```

### T-07 · US-06 lapor kerusakan + stub K-07 (FR-A4-08)

```text
Branch: a4/US-06-lapor-kerusakan. Implementasikan IF-A4-07: StoreReportRequest
(kategori enum, deskripsi, foto wajib sesuai SRS-A4 §3.3.3), penyimpanan foto
dengan nama dari sistem, status new, tangani RPT-03. Sertakan PR stub K-07:
Report::open(), ReportFactory (new; state lanjutan lewat UPDATE). Test
AC-08.1..08.3 termasuk file .php yang di-rename .jpg.
```

### T-08 · US-07 status laporan (FR-A4-09)

```text
Branch: a4/US-07-status-laporan. Implementasikan IF-A4-08: daftar & detail
laporan milik pengguna, catatan resolusi, riwayat report_status_logs,
ReportPolicy untuk laporan & foto. Test AC-09.1, AC-09.2.
```

### T-09 · US-15 verifikasi akun (FR-A4-07)

```text
Branch: a4/US-15-verifikasi-akun. Implementasikan IF-A4-05 (daftar pending
terlama dulu) & IF-A4-06 (verify/reject). Pastikan akun pending/rejected
tetap ditolak login dan akun yang diverifikasi bisa login. Test AC-07.1, AC-07.2.
```

### T-10 · US-11 proses laporan (FR-A4-10)

```text
Branch: a4/US-11-status-laporan. Implementasikan IF-A4-09 & IF-A4-10:
UpdateReportRequest sesuai state machine SRS-A4 §3.3.2, handled_by petugas,
resolution_note wajib saat resolved/rejected, tangani RPT-01/02 dan CHECK
chk_rep_resolution. Test AC-10.1..10.3.
```

### T-11 · README, .env.example, kredensial — 7–8 Okt

```text
Branch: a4/docs-readme. Tulis README: kebutuhan (Laravel 13, PHP >= 8.3,
MySQL >= 8.0.16), langkah setup dari clone sampai login, setelan K-12
(DB_*, time_zone +07:00), cara menjalankan test di MySQL, dan catatan
event_scheduler. Buat docs/05-delivery/credentials.md berisi akun demo tiap
aktor dari seeder (tanpa password asli milik siapa pun).
```

### T-12 · Audit akses sebelum UAT

```text
/audit-akses — periksa seluruh route di routes/modules/*.php (termasuk milik
Anggota 2 & 3): middleware role, Policy, dan halaman yang terbuka untuk
pengunjung. Laporkan temuan per pemilik modul tanpa mengubah file mereka.
```

---

## 5. Prompt Rutin

| Kebutuhan | Prompt |
|---|---|
| Mulai hari | `/standup` — "sertakan status K-00/K-02/K-03 yang ditunggu Anggota 2 & 3" |
| Sinkron `main` | `/sync` — "branch saya <branch>; cek konflik di routes/web.php, layout, dan menu navigasi" |
| Draf PR | `/pr` — "US-<XX>, FR-<…>, sertakan screenshot halaman & daftar role yang sudah diuji" |
| Tambah menu dari anggota lain | "Anggota <N> minta menu <nama> ke route <route>. Buat perubahan satu baris di layouts/partials/nav.blade.php" |
| Review PR Anggota 3 | "Review PR Anggota 3 ini dari sisi otorisasi, pemakaian komponen K-03, dan middleware role: <tempel diff>" |

---

## 6. Checklist Sebelum Membuka PR

- [ ] Branch `a4/…` sudah memuat `main` terbaru
- [ ] Hanya file milik Anggota 4 (`workflow/Relationship.md` §9)
- [ ] Feature test lulus di MySQL, termasuk role yang tidak berhak
- [ ] Tanpa Breeze/starter kit; fitur Fortify yang tidak dipakai sudah dimatikan
- [ ] Unggahan file tervalidasi di server
- [ ] Pesan commit tanpa atribusi AI
- [ ] Minta review Anggota 2

---

## 7. Changelog

| Versi | Tanggal | Perubahan | Oleh |
|---|---|---|---|
| 1.1 | 2026-09-16 | OQ-17 diputuskan: Laravel 13 standar + Blade tanpa starter kit, Laravel Fortify headless, CSS/JS polos di `public/`; rujukan starter kit Livewire diganti; CORE PROMPT v2.1. | DevFlow |
| 1.0 | 2026-09-16 | Dokumen awal personalisasi AI Anggota 4: cara pasang, lingkungan kerja, blok `CLAUDE.local.md`, 12 prompt tugas, prompt rutin, checklist PR. | DevFlow |
