<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * K-13 · BR-01..BR-03 dan integritas nilai ditegakkan MySQL (>= 8.0.16).
 * Nama & isi identik dengan DATABASE_DESIGN.md §5.
 */
return new class extends Migration
{
    /** @var array<string, array<string, string>> */
    private array $checks = [
        'users' => [
            'chk_users_name' => 'CHAR_LENGTH(TRIM(name)) > 0',
        ],
        'facilities' => [
            'chk_fac_name' => 'CHAR_LENGTH(TRIM(name)) > 0',
            'chk_fac_capacity' => 'capacity > 0',
        ],
        'time_slots' => [
            'chk_ts_id' => 'id BETWEEN 1 AND 26',
            'chk_ts_duration' => "TIMEDIFF(end_time, start_time) = '00:30:00'",
            'chk_ts_range' => "start_time >= '07:00:00' AND end_time <= '20:00:00'",
            'chk_ts_grid' => 'MINUTE(start_time) IN (0, 30) AND SECOND(start_time) = 0',
        ],
        'reservations' => [
            'chk_res_order' => 'end_time > start_time',
            'chk_res_same_day' => 'CAST(start_time AS DATE) = CAST(end_time AS DATE)',
            'chk_res_open' => "CAST(start_time AS TIME) >= '07:00:00'",
            'chk_res_close' => "CAST(end_time AS TIME) <= '20:00:00'",
            'chk_res_grid_start' => 'MINUTE(start_time) IN (0, 30) AND SECOND(start_time) = 0',
            'chk_res_grid_end' => 'MINUTE(end_time) IN (0, 30) AND SECOND(end_time) = 0',
            'chk_res_purpose' => 'CHAR_LENGTH(TRIM(purpose)) > 0',
            'chk_res_cancel_ts' => "(status = 'cancelled') = (cancelled_at IS NOT NULL)",
        ],
        'reports' => [
            'chk_rep_description' => 'CHAR_LENGTH(TRIM(description)) > 0',
            'chk_rep_resolution' => "status NOT IN ('resolved', 'rejected') OR CHAR_LENGTH(TRIM(COALESCE(resolution_note, ''))) > 0",
            'chk_rep_resolved_ts' => "(status IN ('resolved', 'rejected')) = (resolved_at IS NOT NULL)",
        ],
    ];

    public function up(): void
    {
        foreach ($this->checks as $table => $constraints) {
            foreach ($constraints as $name => $expression) {
                DB::statement("ALTER TABLE `{$table}` ADD CONSTRAINT `{$name}` CHECK ({$expression})");
            }
        }
    }

    public function down(): void
    {
        foreach ($this->checks as $table => $constraints) {
            foreach (array_keys($constraints) as $name) {
                DB::statement("ALTER TABLE `{$table}` DROP CHECK `{$name}`");
            }
        }
    }
};
