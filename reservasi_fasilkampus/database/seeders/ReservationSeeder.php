<?php

namespace Database\Seeders;

use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Reservasi demo (US-03..US-05, US-09, US-10).
 *
 * Trigger MySQL menolak reservasi di masa lalu dan status awal selain pending,
 * sehingga semua reservasi dibuat di hari mendatang lalu diproses lewat UPDATE.
 */
class ReservationSeeder extends Seeder
{
    public function run(): void
    {
        $user = fn (string $email) => DB::table('users')->where('email', $email)->value('id');
        $facility = fn (string $name) => DB::table('facilities')->where('name', $name)->value('id');
        $at = fn (int $days, string $time) => CarbonImmutable::today()->addDays($days)->setTimeFromTimeString($time);

        $create = function (string $email, string $facilityName, int $days, string $start, string $end, string $purpose) use ($user, $facility, $at) {
            return DB::table('reservations')->insertGetId([
                'user_id' => $user($email),
                'facility_id' => $facility($facilityName),
                'start_time' => $at($days, $start),
                'end_time' => $at($days, $end),
                'purpose' => $purpose,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        };

        $petugas = $user('petugas@kampus.test');
        $petugas2 = $user('petugas2@kampus.test');

        $seminar = $create('mahasiswa@kampus.test', 'Aula Utama', 1, '09:00', '11:00', 'Seminar himpunan mahasiswa');
        $create('dosen@kampus.test', 'Aula Utama', 1, '10:00', '12:00', 'Kuliah umum dosen tamu');
        $pelatihan = $create('staf@kampus.test', 'Laboratorium Komputer 1', 2, '13:00', '15:00', 'Pelatihan aplikasi kepegawaian');
        $basket = $create('mahasiswa@kampus.test', 'Lapangan Basket', 3, '16:00', '17:30', 'Latihan tim basket fakultas');
        $kuis = $create('dosen@kampus.test', 'Ruang Kelas A101', 1, '07:00', '08:30', 'Kuis susulan mata kuliah');
        $create('mahasiswa@kampus.test', 'Ruang Kelas B204', 4, '08:00', '10:00', 'Rapat BEM');
        $presentasi = $create('staf@kampus.test', 'Proyektor Portabel 01', 2, '09:00', '12:00', 'Presentasi rapat unit');

        foreach ([$seminar, $pelatihan, $kuis, $presentasi] as $id) {
            DB::table('reservations')->where('id', $id)->update([
                'status' => 'approved',
                'processed_by' => $petugas,
                'updated_at' => now(),
            ]);
        }

        DB::table('reservations')->where('id', $basket)->update([
            'status' => 'rejected',
            'processed_by' => $petugas2,
            'updated_at' => now(),
        ]);

        DB::table('reservations')->where('id', $kuis)->update([
            'status' => 'cancelled',
            'cancelled_by' => $petugas,
            'cancel_reason' => 'Ruangan dipakai ujian mendadak',
            'updated_at' => now(),
        ]);
    }
}
