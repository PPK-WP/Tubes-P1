<?php

use Carbon\CarbonImmutable;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * K-01 · BR-01, BR-02 — 26 slot 30 menit (07.00–20.00). DATABASE_DESIGN.md §5.3
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('time_slots', function (Blueprint $table) {
            $table->unsignedTinyInteger('id')->primary();
            $table->time('start_time');
            $table->time('end_time');

            $table->unique('start_time', 'uq_time_slots_start');
        });

        $opening = CarbonImmutable::createFromTimeString('07:00:00');

        DB::table('time_slots')->insert(array_map(fn (int $i) => [
            'id' => $i + 1,
            'start_time' => $opening->addMinutes(30 * $i)->format('H:i:s'),
            'end_time' => $opening->addMinutes(30 * ($i + 1))->format('H:i:s'),
        ], range(0, 25)));
    }

    public function down(): void
    {
        Schema::dropIfExists('time_slots');
    }
};
