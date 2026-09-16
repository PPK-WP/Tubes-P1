-- 04_procedures.sql — disalin dari workflow/DATABASE_DESIGN.md §9
-- Jangan ubah file ini tanpa memperbarui DATABASE_DESIGN.md (dan sebaliknya).
-- MySQL >= 8.0.16 · InnoDB · utf8mb4

DELIMITER $$

-- US-01: grid 26 slot satu fasilitas pada satu tanggal
CREATE PROCEDURE sp_facility_day_grid(IN p_facility_id BIGINT UNSIGNED, IN p_date DATE)
READS SQL DATA
BEGIN
  SELECT ts.id AS time_slot_id, ts.start_time, ts.end_time,
         CASE
           WHEN f.status = 'under_repair'                      THEN 'dalam_perbaikan'
           WHEN o.time_slot_id IS NOT NULL                     THEN 'tidak_tersedia'
           WHEN TIMESTAMP(p_date, ts.start_time) <= NOW()      THEN 'lewat'
           ELSE 'tersedia'
         END AS slot_status
  FROM time_slots ts
  JOIN facilities f
    ON f.id = p_facility_id AND f.status <> 'inactive'
  LEFT JOIN v_public_slot_occupancy o
    ON o.facility_id = p_facility_id AND o.slot_date = p_date AND o.time_slot_id = ts.id
  ORDER BY ts.id;
END$$

-- US-17: okupansi per fasilitas dalam periode (inklusif)
CREATE PROCEDURE sp_recap_occupancy(IN p_start DATE, IN p_end DATE)
READS SQL DATA
BEGIN
  DECLARE v_days INT;

  IF p_end < p_start THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RCP-01: Tanggal akhir sebelum tanggal awal';
  END IF;
  SET v_days = DATEDIFF(p_end, p_start) + 1;

  SELECT f.id AS facility_id, f.name, f.type, f.location,
         COUNT(rs.id)                                             AS slots_used,
         26 * v_days                                              AS slots_available,
         ROUND(COUNT(rs.id) / (26 * v_days) * 100, 2)             AS occupancy_pct,
         RANK() OVER (ORDER BY COUNT(rs.id) DESC)                 AS rank_overall,
         RANK() OVER (PARTITION BY f.location ORDER BY COUNT(rs.id) DESC) AS rank_in_location
  FROM facilities f
  LEFT JOIN reservation_slots rs
         ON rs.facility_id = f.id
        AND rs.slot_date BETWEEN p_start AND p_end
  GROUP BY f.id, f.name, f.type, f.location
  ORDER BY occupancy_pct DESC;
END$$

-- US-17: frekuensi kerusakan per lokasi & fasilitas dalam periode (inklusif)
CREATE PROCEDURE sp_recap_damage(IN p_start DATE, IN p_end DATE)
READS SQL DATA
BEGIN
  IF p_end < p_start THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RCP-01: Tanggal akhir sebelum tanggal awal';
  END IF;

  SELECT f.location, f.id AS facility_id, f.name,
         COUNT(p.id)                                                         AS total_reports,
         COALESCE(SUM(p.status = 'resolved'), 0)                             AS resolved_reports,
         ROUND(COUNT(p.id) / NULLIF(SUM(COUNT(p.id)) OVER (), 0) * 100, 2)   AS share_pct,
         RANK() OVER (ORDER BY COUNT(p.id) DESC)                             AS rank_overall
  FROM facilities f
  LEFT JOIN reports p
         ON p.facility_id = f.id
        AND p.status     <> 'rejected'
        AND p.created_at >= p_start
        AND p.created_at  < p_end + INTERVAL 1 DAY
  GROUP BY f.location, f.id, f.name
  ORDER BY total_reports DESC;
END$$

-- Dipanggil event scheduler (§10) dan dapat diuji langsung
CREATE PROCEDURE sp_expire_pending_reservations()
MODIFIES SQL DATA
BEGIN
  UPDATE reservations
     SET status = 'expired'
   WHERE status = 'pending'
     AND start_time <= NOW();
END$$

DELIMITER ;
