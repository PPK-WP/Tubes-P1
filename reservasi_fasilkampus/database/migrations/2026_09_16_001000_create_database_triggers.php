<?php

use App\Support\SqlObjectLoader;
use Illuminate\Database\Migrations\Migration;

/**
 * K-13 · DATABASE_DESIGN.md §7 trigger reservasi & laporan + kode RSV/RPT.
 * Sumber: database/sql/02_triggers.sql. Tidak dibungkus DB::transaction (implicit commit).
 */
return new class extends Migration
{
    public function up(): void
    {
        SqlObjectLoader::run('02_triggers.sql');
    }

    public function down(): void
    {
        SqlObjectLoader::drop('02_triggers.sql');
    }
};
