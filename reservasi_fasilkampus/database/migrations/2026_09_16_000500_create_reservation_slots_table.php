<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-13 · BR-04 penjaga anti-bentrok — hanya berisi slot reservasi approved,
 * diisi & dihapus oleh trigger. DATABASE_DESIGN.md §5.6
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reservation_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id');
            $table->foreignId('facility_id');
            $table->date('slot_date');
            $table->unsignedTinyInteger('time_slot_id');

            $table->unique(['facility_id', 'slot_date', 'time_slot_id'], 'uq_reservation_slot');
            $table->index('reservation_id', 'idx_rslots_reservation');

            $table->foreign('reservation_id', 'fk_rslots_reservations')->references('id')->on('reservations')->cascadeOnDelete();
            $table->foreign('facility_id', 'fk_rslots_facilities')->references('id')->on('facilities');
            $table->foreign('time_slot_id', 'fk_rslots_time_slots')->references('id')->on('time_slots');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reservation_slots');
    }
};
