<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Fasilitas demo (US-02, US-12, US-16), termasuk satu dalam perbaikan dan satu nonaktif.
 */
class FacilitySeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $facilities = [
            ['Aula Utama', 'aula', 'Gedung Rektorat Lt. 1', 300, 'Aula dengan panggung, sound system, dan proyektor.', 'active'],
            ['Ruang Kelas A101', 'ruang_kelas', 'Gedung A Lt. 1', 40, 'Ruang kelas ber-AC dengan papan tulis dan proyektor.', 'active'],
            ['Ruang Kelas B204', 'ruang_kelas', 'Gedung B Lt. 2', 35, 'Ruang kelas dengan meja diskusi.', 'active'],
            ['Laboratorium Komputer 1', 'laboratorium', 'Gedung C Lt. 3', 30, '30 unit PC dan jaringan internet.', 'active'],
            ['Laboratorium Jaringan', 'laboratorium', 'Gedung C Lt. 2', 25, 'Perangkat router dan switch untuk praktikum.', 'under_repair'],
            ['Lapangan Basket', 'lapangan', 'Area Olahraga', 50, 'Lapangan outdoor dengan tribun kecil.', 'active'],
            ['Proyektor Portabel 01', 'alat', 'Gudang Sarpras', 1, 'Proyektor portabel beserta kabel HDMI.', 'active'],
            ['Ruang Seminar Lama', 'ruang_kelas', 'Gedung A Lt. 3', 60, 'Tidak digunakan sejak renovasi gedung.', 'inactive'],
        ];

        DB::table('facilities')->insert(array_map(fn (array $facility) => [
            'name' => $facility[0],
            'type' => $facility[1],
            'location' => $facility[2],
            'capacity' => $facility[3],
            'description' => $facility[4],
            'status' => $facility[5],
            'created_at' => $now,
            'updated_at' => $now,
        ], $facilities));
    }
}
