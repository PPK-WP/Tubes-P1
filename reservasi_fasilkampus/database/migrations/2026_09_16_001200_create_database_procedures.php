<?php

use App\Support\SqlObjectLoader;
use Illuminate\Database\Migrations\Migration;

/**
 * K-13 · DATABASE_DESIGN.md §9 stored procedure grid & rekap.
 * Sumber: database/sql/04_procedures.sql. Tidak dibungkus DB::transaction (implicit commit).
 */
return new class extends Migration
{
    public function up(): void
    {
        SqlObjectLoader::run('04_procedures.sql');
    }

    public function down(): void
    {
        SqlObjectLoader::drop('04_procedures.sql');
    }
};
