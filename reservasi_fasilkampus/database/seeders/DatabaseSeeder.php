<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Data demo: akun tiap role, fasilitas, reservasi, dan laporan.
     * Semua status lanjutan dibuat lewat UPDATE agar lolos trigger MySQL.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            FacilitySeeder::class,
            ReservationSeeder::class,
            ReportSeeder::class,
        ]);
    }
}
