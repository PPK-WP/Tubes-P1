<?php

use App\Support\SqlObjectLoader;
use Illuminate\Database\Migrations\Migration;

/**
 * K-13 · DATABASE_DESIGN.md §8 view privasi, antrian, rekap.
 * Sumber: database/sql/03_views.sql. Tidak dibungkus DB::transaction (implicit commit).
 */
return new class extends Migration
{
    public function up(): void
    {
        SqlObjectLoader::run('03_views.sql');
    }

    public function down(): void
    {
        SqlObjectLoader::drop('03_views.sql');
    }
};
