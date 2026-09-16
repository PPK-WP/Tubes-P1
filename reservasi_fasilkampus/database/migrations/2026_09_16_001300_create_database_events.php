<?php

use App\Support\SqlObjectLoader;
use Illuminate\Database\Migrations\Migration;

/**
 * K-13 · DATABASE_DESIGN.md §10 event kedaluwarsa reservasi pending (OQ-18).
 * Sumber: database/sql/05_events.sql. Tidak dibungkus DB::transaction (implicit commit).
 */
return new class extends Migration
{
    public function up(): void
    {
        SqlObjectLoader::run('05_events.sql');
    }

    public function down(): void
    {
        SqlObjectLoader::drop('05_events.sql');
    }
};
