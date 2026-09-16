<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-13 · audit trail status reservasi (DR-A3-02). DATABASE_DESIGN.md §5.7
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reservation_status_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id');
            $table->string('from_status', 20)->nullable();
            $table->string('to_status', 20);
            $table->foreignId('changed_by')->nullable()->comment('NULL = sistem (event scheduler)');
            $table->string('note', 255)->nullable();
            $table->dateTime('changed_at')->useCurrent();

            $table->index(['reservation_id', 'changed_at'], 'idx_rlogs_reservation');

            $table->foreign('reservation_id', 'fk_rlogs_reservations')->references('id')->on('reservations');
            $table->foreign('changed_by', 'fk_rlogs_users')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reservation_status_logs');
    }
};
