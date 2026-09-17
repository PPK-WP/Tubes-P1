<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * K-13 · audit trail status laporan (DR-A4-03). DATABASE_DESIGN.md §5.9
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_status_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id');
            $table->string('from_status', 20)->nullable();
            $table->string('to_status', 20);
            $table->foreignId('changed_by')->nullable();
            $table->text('note')->nullable();
            $table->dateTime('changed_at')->useCurrent();

            $table->index(['report_id', 'changed_at'], 'idx_plogs_report');

            $table->foreign('report_id', 'fk_plogs_reports')->references('id')->on('reports');
            $table->foreign('changed_by', 'fk_plogs_users')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_status_logs');
    }
};
