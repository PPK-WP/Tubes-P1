<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-01 · US-03..US-05, US-09, US-10 (FR-A3-01..07) — DATABASE_DESIGN.md §5.5
 *
 * start_time/end_time bertipe DATETIME (jam dinding WIB), bukan TIMESTAMP.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reservations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id');
            $table->foreignId('facility_id');
            $table->dateTime('start_time');
            $table->dateTime('end_time');
            $table->string('purpose', 255);
            $table->enum('status', ['pending', 'approved', 'rejected', 'cancelled', 'expired'])->default('pending');
            $table->date('reservation_date')->storedAs('CAST(start_time AS DATE)');
            $table->smallInteger('duration_minutes')->storedAs('TIMESTAMPDIFF(MINUTE, start_time, end_time)');
            $table->foreignId('processed_by')->nullable();
            $table->dateTime('processed_at')->nullable();
            $table->foreignId('cancelled_by')->nullable();
            $table->dateTime('cancelled_at')->nullable();
            $table->string('cancel_reason', 255)->nullable();
            $table->timestamps();

            $table->index(['facility_id', 'status', 'start_time', 'end_time'], 'idx_res_conflict');
            $table->index(['user_id', 'created_at'], 'idx_res_user');
            $table->index(['status', 'start_time'], 'idx_res_queue');
            $table->index(['reservation_date', 'facility_id', 'status'], 'idx_res_recap');

            $table->foreign('user_id', 'fk_reservations_users')->references('id')->on('users');
            $table->foreign('facility_id', 'fk_reservations_facilities')->references('id')->on('facilities');
            $table->foreign('processed_by', 'fk_reservations_processor')->references('id')->on('users');
            $table->foreign('cancelled_by', 'fk_reservations_canceller')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reservations');
    }
};
