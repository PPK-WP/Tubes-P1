<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-01 · US-02, US-12, US-16 (FR-A2-01..06) — DATABASE_DESIGN.md §5.2
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('facilities', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->enum('type', ['ruang_kelas', 'aula', 'laboratorium', 'alat', 'lapangan']);
            $table->string('location', 150);
            $table->unsignedSmallInteger('capacity');
            $table->text('description')->nullable();
            $table->enum('status', ['active', 'under_repair', 'inactive'])->default('active');
            $table->timestamps();

            $table->unique(['name', 'location'], 'uq_facilities_name_location');
            $table->index(['status', 'type', 'location', 'capacity'], 'idx_fac_search');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('facilities');
    }
};
