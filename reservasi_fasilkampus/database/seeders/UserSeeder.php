<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/**
 * Akun demo per aktor (US-13..US-15). Password semua akun: "password".
 */
class UserSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make('password');
        $now = now();

        $users = [
            ['Admin Sarpras', 'admin@kampus.test', 'admin', 'active'],
            ['Budi Petugas', 'petugas@kampus.test', 'petugas', 'active'],
            ['Sari Petugas', 'petugas2@kampus.test', 'petugas', 'active'],
            ['Andi Mahasiswa', 'mahasiswa@kampus.test', 'pengguna', 'active'],
            ['Rina Dosen', 'dosen@kampus.test', 'pengguna', 'active'],
            ['Joko Staf', 'staf@kampus.test', 'pengguna', 'active'],
            ['Calon Pengguna', 'pending@kampus.test', 'pengguna', 'pending'],
        ];

        DB::table('users')->insert(array_map(fn (array $user) => [
            'name' => $user[0],
            'email' => $user[1],
            'email_verified_at' => $now,
            'password' => $password,
            'role' => $user[2],
            'account_status' => $user[3],
            'created_at' => $now,
            'updated_at' => $now,
        ], $users));
    }
}
