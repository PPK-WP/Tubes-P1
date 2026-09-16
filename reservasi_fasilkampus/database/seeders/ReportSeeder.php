<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Laporan kerusakan demo (US-06, US-07, US-11). Foto memakai path contoh.
 * Status lanjutan dibuat lewat UPDATE agar lolos trigger & CHECK MySQL.
 */
class ReportSeeder extends Seeder
{
    public function run(): void
    {
        $user = fn (string $email) => DB::table('users')->where('email', $email)->value('id');
        $facility = fn (string $name) => DB::table('facilities')->where('name', $name)->value('id');
        $petugas = $user('petugas@kampus.test');
        $petugas2 = $user('petugas2@kampus.test');

        $create = function (string $email, string $facilityName, string $category, string $description, int $number, int $hoursAgo) use ($user, $facility) {
            return DB::table('reports')->insertGetId([
                'user_id' => $user($email),
                'facility_id' => $facility($facilityName),
                'category' => $category,
                'description' => $description,
                'photo_path' => "reports/contoh-{$number}.jpg",
                'created_at' => now()->subHours($hoursAgo),
                'updated_at' => now()->subHours($hoursAgo),
            ]);
        };

        $stopKontak = $create('mahasiswa@kampus.test', 'Laboratorium Jaringan', 'kelistrikan', 'Stop kontak meja 3–8 tidak berfungsi dan berbau hangus.', 1, 30);
        $create('dosen@kampus.test', 'Aula Utama', 'peralatan', 'Mikrofon wireless sering putus saat dipakai.', 2, 72);
        $ac = $create('staf@kampus.test', 'Ruang Kelas A101', 'kebersihan', 'AC bocor sehingga lantai licin.', 3, 50);
        $create('mahasiswa@kampus.test', 'Lapangan Basket', 'kerusakan_fisik', 'Ring basket sisi timur miring.', 4, 5);
        $duplikat = $create('dosen@kampus.test', 'Ruang Kelas B204', 'lainnya', 'Kursi rusak (laporan ganda).', 5, 20);

        foreach ([$stopKontak, $ac] as $id) {
            DB::table('reports')->where('id', $id)->update([
                'status' => 'in_progress',
                'handled_by' => $petugas,
                'updated_at' => now(),
            ]);
        }

        DB::table('reports')->where('id', $ac)->update([
            'status' => 'resolved',
            'resolution_note' => 'AC diservis dan saluran pembuangan dibersihkan.',
            'updated_at' => now(),
        ]);

        DB::table('reports')->where('id', $duplikat)->update([
            'status' => 'rejected',
            'handled_by' => $petugas2,
            'resolution_note' => 'Duplikat dari laporan sebelumnya.',
            'updated_at' => now(),
        ]);
    }
}
