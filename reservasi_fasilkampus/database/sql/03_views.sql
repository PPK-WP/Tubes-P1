-- 03_views.sql — disalin dari workflow/DATABASE_DESIGN.md §8
-- Jangan ubah file ini tanpa memperbarui DATABASE_DESIGN.md (dan sebaliknya).
-- MySQL >= 8.0.16 · InnoDB · utf8mb4

-- US-01 · BR-09: hanya fakta "slot terisi", tanpa siapa & untuk apa
CREATE OR REPLACE VIEW v_public_slot_occupancy AS
SELECT rs.facility_id, rs.slot_date, ts.id AS time_slot_id, ts.start_time, ts.end_time
FROM reservation_slots rs
JOIN time_slots ts ON ts.id = rs.time_slot_id;

-- US-08: satu antrian gabungan reservasi pending + laporan terbuka
CREATE OR REPLACE VIEW v_staff_queue AS
SELECT 'reservation'          AS item_type,
       r.id                   AS item_id,
       r.status               AS item_status,
       f.name                 AS facility_name,
       f.location,
       u.name                 AS requester_name,
       r.start_time           AS reference_time,
       r.created_at,
       (r.start_time <= NOW() + INTERVAL s.v HOUR) AS is_flagged
FROM reservations r
JOIN facilities f ON f.id = r.facility_id
JOIN users u      ON u.id = r.user_id
CROSS JOIN (SELECT CAST(setting_value AS UNSIGNED) AS v
            FROM system_settings WHERE setting_key = 'queue_urgent_reservation_hours') s
WHERE r.status = 'pending'
UNION ALL
SELECT 'report', p.id, p.status, f.name, f.location, u.name, p.created_at, p.created_at,
       (p.status = 'new' AND p.created_at <= NOW() - INTERVAL s.v HOUR)
FROM reports p
JOIN facilities f ON f.id = p.facility_id
JOIN users u      ON u.id = p.user_id
CROSS JOIN (SELECT CAST(setting_value AS UNSIGNED) AS v
            FROM system_settings WHERE setting_key = 'queue_overdue_report_hours') s
WHERE p.status IN ('new', 'in_progress');

-- US-12 -> US-10: daftar yang perlu dibatalkan petugas setelah fasilitas ditutup
CREATE OR REPLACE VIEW v_affected_reservations AS
SELECT r.id AS reservation_id, r.facility_id, f.name AS facility_name, f.status AS facility_status,
       r.start_time, r.end_time, u.name AS requester_name
FROM reservations r
JOIN facilities f ON f.id = r.facility_id
JOIN users u      ON u.id = r.user_id
WHERE r.status = 'approved'
  AND f.status <> 'active'
  AND r.start_time > NOW();

-- US-17: okupansi harian per fasilitas (hanya reservasi approved, karena slot hanya ada untuk approved)
CREATE OR REPLACE VIEW v_recap_daily_occupancy AS
SELECT rs.facility_id, f.name AS facility_name, f.location, rs.slot_date,
       COUNT(*)                         AS slots_used,
       ROUND(COUNT(*) / 26 * 100, 2)    AS occupancy_pct
FROM reservation_slots rs
JOIN facilities f ON f.id = rs.facility_id
GROUP BY rs.facility_id, f.name, f.location, rs.slot_date;

-- US-17: frekuensi kerusakan bulanan per fasilitas & kategori
CREATE OR REPLACE VIEW v_recap_damage_monthly AS
SELECT p.facility_id, f.name AS facility_name, f.location, p.category,
       DATE_FORMAT(p.created_at, '%Y-%m')                                      AS period_month,
       COUNT(*)                                                                AS total_reports,
       SUM(p.status = 'resolved')                                              AS resolved_reports,
       ROUND(AVG(CASE WHEN p.status = 'resolved'
                      THEN TIMESTAMPDIFF(HOUR, p.created_at, p.resolved_at) END), 1) AS avg_resolution_hours
FROM reports p
JOIN facilities f ON f.id = p.facility_id
WHERE p.status <> 'rejected'
GROUP BY p.facility_id, f.name, f.location, p.category, DATE_FORMAT(p.created_at, '%Y-%m');
