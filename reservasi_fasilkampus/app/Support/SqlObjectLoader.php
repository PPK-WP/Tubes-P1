<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Memuat objek database non-tabel (trigger, view, procedure, event) dari
 * file database/sql/*.sql untuk dipakai migration (DATABASE_DESIGN.md §13.2).
 *
 * Baris DELIMITER hanya dikenal klien MySQL/Workbench, sehingga dibuang dan
 * isi file dipecah per blok sebelum dijalankan dengan DB::unprepared.
 */
final class SqlObjectLoader
{
    private const OBJECT_PATTERN = '/CREATE\s+(?:OR\s+REPLACE\s+)?(TRIGGER|VIEW|PROCEDURE|EVENT)\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?/i';

    /**
     * Buat ulang semua objek di file: drop yang lama, lalu create.
     */
    public static function run(string $file): void
    {
        $statements = self::statements($file);

        foreach (self::objects($statements) as [$type, $name]) {
            DB::unprepared("DROP {$type} IF EXISTS `{$name}`");
        }

        foreach ($statements as $statement) {
            DB::unprepared($statement);
        }
    }

    /**
     * Hapus semua objek yang dibuat oleh file.
     */
    public static function drop(string $file): void
    {
        foreach (array_reverse(self::objects(self::statements($file))) as [$type, $name]) {
            DB::unprepared("DROP {$type} IF EXISTS `{$name}`");
        }
    }

    /**
     * @return list<string>
     */
    public static function statements(string $file): array
    {
        $path = database_path('sql/'.$file);

        if (! is_file($path)) {
            throw new RuntimeException("File SQL tidak ditemukan: {$path}");
        }

        $sql = file_get_contents($path);
        $usesCustomDelimiter = (bool) preg_match('/^\s*DELIMITER\s+\$\$\s*$/mi', $sql);
        $sql = preg_replace('/^\s*DELIMITER\s+\S+\s*$/mi', '', $sql);

        $chunks = $usesCustomDelimiter
            ? explode('$$', $sql)
            : preg_split('/;\s*$/m', $sql);

        return array_values(array_filter(
            array_map('trim', $chunks),
            fn (string $chunk) => trim(preg_replace('/^\s*--.*$/m', '', $chunk)) !== ''
        ));
    }

    /**
     * @param  list<string>  $statements
     * @return list<array{0: string, 1: string}>
     */
    private static function objects(array $statements): array
    {
        $objects = [];

        foreach ($statements as $statement) {
            if (preg_match(self::OBJECT_PATTERN, $statement, $match)) {
                $objects[] = [strtoupper($match[1]), $match[2]];
            }
        }

        return $objects;
    }
}
