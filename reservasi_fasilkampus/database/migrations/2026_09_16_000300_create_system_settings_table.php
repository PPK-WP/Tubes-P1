<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * K-01 · BR-05 (OQ-02), US-08 — nilai yang dibaca trigger & view. DATABASE_DESIGN.md §5.4
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->string('setting_key', 64)->primary();
            $table->string('setting_value', 255);
            $table->string('description', 255)->nullable();
            $table->timestamp('updated_at')->nullable();
        });

        DB::table('system_settings')->insert([
            ['setting_key' => 'cancel_deadline_minutes', 'setting_value' => '120', 'description' => 'Batas batal mandiri sebelum start_time (OQ-02, nilai sementara)'],
            ['setting_key' => 'queue_urgent_reservation_hours', 'setting_value' => '24', 'description' => 'Reservasi pending ditandai mendesak bila mulai kurang dari N jam'],
            ['setting_key' => 'queue_overdue_report_hours', 'setting_value' => '48', 'description' => 'Laporan new ditandai terlambat bila lebih dari N jam'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};
