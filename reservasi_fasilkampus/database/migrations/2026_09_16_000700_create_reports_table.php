<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-01 · US-06, US-07, US-11 (FR-A4-08..10) — DATABASE_DESIGN.md §5.8
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id');
            $table->foreignId('facility_id');
            $table->enum('category', ['kerusakan_fisik', 'kelistrikan', 'peralatan', 'kebersihan', 'keamanan', 'lainnya']);
            $table->text('description');
            $table->string('photo_path', 255);
            $table->enum('status', ['new', 'in_progress', 'resolved', 'rejected'])->default('new');
            $table->text('resolution_note')->nullable();
            $table->foreignId('handled_by')->nullable();
            $table->dateTime('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at'], 'idx_rep_queue');
            $table->index(['facility_id', 'created_at'], 'idx_rep_facility');
            $table->index(['user_id', 'created_at'], 'idx_rep_user');

            $table->foreign('user_id', 'fk_reports_users')->references('id')->on('users');
            $table->foreign('facility_id', 'fk_reports_facilities')->references('id')->on('facilities');
            $table->foreign('handled_by', 'fk_reports_handler')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
