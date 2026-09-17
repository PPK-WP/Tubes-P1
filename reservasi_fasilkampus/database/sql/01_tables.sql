-- 01_tables.sql — disalin dari workflow/DATABASE_DESIGN.md §5
-- Jangan ubah file ini tanpa memperbarui DATABASE_DESIGN.md (dan sebaliknya).
-- MySQL >= 8.0.16 · InnoDB · utf8mb4

-- Referensi untuk MySQL Workbench. Migration Laravel membangun tabel yang sama.

-- =========================================================================
-- 01_tables.sql · DATABASE_DESIGN.md §5 · MySQL >= 8.0.16 · InnoDB · utf8mb4
-- =========================================================================

-- 5.1 users ---------------------------------------------------------- US-13..15
CREATE TABLE users (
  id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name               VARCHAR(255) NOT NULL,
  email              VARCHAR(255) NOT NULL,
  email_verified_at  TIMESTAMP NULL,
  password           VARCHAR(255) NOT NULL,
  role               ENUM('admin','petugas','pengguna') NOT NULL DEFAULT 'pengguna',
  account_status     ENUM('pending','active','rejected') NOT NULL DEFAULT 'pending',
  remember_token     VARCHAR(100) NULL,
  created_at         TIMESTAMP NULL,
  updated_at         TIMESTAMP NULL,
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT chk_users_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  INDEX idx_users_verification (account_status, role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.2 facilities ----------------------------------------------------- US-02, US-12, US-16
CREATE TABLE facilities (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(150) NOT NULL,
  type         ENUM('ruang_kelas','aula','laboratorium','alat','lapangan') NOT NULL,
  location     VARCHAR(150) NOT NULL,
  capacity     SMALLINT UNSIGNED NOT NULL,
  description  TEXT NULL,
  status       ENUM('active','under_repair','inactive') NOT NULL DEFAULT 'active',
  created_at   TIMESTAMP NULL,
  updated_at   TIMESTAMP NULL,
  CONSTRAINT uq_facilities_name_location UNIQUE (name, location),
  CONSTRAINT chk_fac_name     CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT chk_fac_capacity CHECK (capacity > 0),
  INDEX idx_fac_search (status, type, location, capacity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.3 time_slots ------------------------------------------------------ BR-01, BR-02
CREATE TABLE time_slots (
  id          TINYINT UNSIGNED PRIMARY KEY,
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  CONSTRAINT uq_time_slots_start UNIQUE (start_time),
  CONSTRAINT chk_ts_id       CHECK (id BETWEEN 1 AND 26),
  CONSTRAINT chk_ts_duration CHECK (TIMEDIFF(end_time, start_time) = '00:30:00'),
  CONSTRAINT chk_ts_range    CHECK (start_time >= '07:00:00' AND end_time <= '20:00:00'),
  CONSTRAINT chk_ts_grid     CHECK (MINUTE(start_time) IN (0, 30) AND SECOND(start_time) = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 26 slot (07.00-07.30 ... 19.30-20.00) lewat recursive CTE
INSERT INTO time_slots (id, start_time, end_time)
WITH RECURSIVE s (n, t) AS (
  SELECT 1, CAST('07:00:00' AS TIME)
  UNION ALL
  SELECT n + 1, ADDTIME(t, '00:30:00') FROM s WHERE n < 26
)
SELECT n, t, ADDTIME(t, '00:30:00') FROM s;

-- 5.4 system_settings -------------------------------------------------- OQ-02, US-08
CREATE TABLE system_settings (
  setting_key    VARCHAR(64)  PRIMARY KEY,
  setting_value  VARCHAR(255) NOT NULL,
  description    VARCHAR(255) NULL,
  updated_at     TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
  ('cancel_deadline_minutes',       '120', 'Batas batal mandiri sebelum start_time (OQ-02, nilai sementara)'),
  ('queue_urgent_reservation_hours', '24', 'Reservasi pending ditandai mendesak bila mulai kurang dari N jam'),
  ('queue_overdue_report_hours',     '48', 'Laporan new ditandai terlambat bila lebih dari N jam');

-- 5.5 reservations ------------------------------------------------------ US-03..US-05, US-09, US-10
CREATE TABLE reservations (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id           BIGINT UNSIGNED NOT NULL,
  facility_id       BIGINT UNSIGNED NOT NULL,
  start_time        DATETIME NOT NULL,
  end_time          DATETIME NOT NULL,
  purpose           VARCHAR(255) NOT NULL,
  status            ENUM('pending','approved','rejected','cancelled','expired') NOT NULL DEFAULT 'pending',
  reservation_date  DATE     GENERATED ALWAYS AS (CAST(start_time AS DATE)) STORED,
  duration_minutes  SMALLINT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, start_time, end_time)) STORED,
  processed_by      BIGINT UNSIGNED NULL,
  processed_at      DATETIME NULL,
  cancelled_by      BIGINT UNSIGNED NULL,
  cancelled_at      DATETIME NULL,
  cancel_reason     VARCHAR(255) NULL,
  created_at        TIMESTAMP NULL,
  updated_at        TIMESTAMP NULL,

  CONSTRAINT fk_reservations_users      FOREIGN KEY (user_id)      REFERENCES users (id),
  CONSTRAINT fk_reservations_facilities FOREIGN KEY (facility_id)  REFERENCES facilities (id),
  CONSTRAINT fk_reservations_processor  FOREIGN KEY (processed_by) REFERENCES users (id),
  CONSTRAINT fk_reservations_canceller  FOREIGN KEY (cancelled_by) REFERENCES users (id),

  -- BR-01..BR-03 ditegakkan di level database
  CONSTRAINT chk_res_order      CHECK (end_time > start_time),
  CONSTRAINT chk_res_same_day   CHECK (CAST(start_time AS DATE) = CAST(end_time AS DATE)),
  CONSTRAINT chk_res_open       CHECK (CAST(start_time AS TIME) >= '07:00:00'),
  CONSTRAINT chk_res_close      CHECK (CAST(end_time   AS TIME) <= '20:00:00'),
  CONSTRAINT chk_res_grid_start CHECK (MINUTE(start_time) IN (0, 30) AND SECOND(start_time) = 0),
  CONSTRAINT chk_res_grid_end   CHECK (MINUTE(end_time)   IN (0, 30) AND SECOND(end_time)   = 0),
  CONSTRAINT chk_res_purpose    CHECK (CHAR_LENGTH(TRIM(purpose)) > 0),
  CONSTRAINT chk_res_cancel_ts  CHECK ((status = 'cancelled') = (cancelled_at IS NOT NULL)),

  INDEX idx_res_conflict (facility_id, status, start_time, end_time),
  INDEX idx_res_user     (user_id, created_at),
  INDEX idx_res_queue    (status, start_time),
  INDEX idx_res_recap    (reservation_date, facility_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.6 reservation_slots -------------------------------------------------- BR-04 (penjaga utama)
-- Hanya berisi baris untuk reservasi berstatus approved. Diisi & dihapus oleh trigger (§7).
CREATE TABLE reservation_slots (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reservation_id  BIGINT UNSIGNED NOT NULL,
  facility_id     BIGINT UNSIGNED NOT NULL,
  slot_date       DATE NOT NULL,
  time_slot_id    TINYINT UNSIGNED NOT NULL,
  CONSTRAINT fk_rslots_reservations FOREIGN KEY (reservation_id) REFERENCES reservations (id) ON DELETE CASCADE,
  CONSTRAINT fk_rslots_facilities   FOREIGN KEY (facility_id)    REFERENCES facilities (id),
  CONSTRAINT fk_rslots_time_slots   FOREIGN KEY (time_slot_id)   REFERENCES time_slots (id),
  CONSTRAINT uq_reservation_slot UNIQUE (facility_id, slot_date, time_slot_id),
  INDEX idx_rslots_reservation (reservation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.7 reservation_status_logs ----------------------------------------------- audit trail
CREATE TABLE reservation_status_logs (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reservation_id  BIGINT UNSIGNED NOT NULL,
  from_status     VARCHAR(20) NULL,
  to_status       VARCHAR(20) NOT NULL,
  changed_by      BIGINT UNSIGNED NULL,               -- NULL = sistem (event scheduler)
  note            VARCHAR(255) NULL,
  changed_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rlogs_reservations FOREIGN KEY (reservation_id) REFERENCES reservations (id),
  CONSTRAINT fk_rlogs_users        FOREIGN KEY (changed_by)     REFERENCES users (id),
  INDEX idx_rlogs_reservation (reservation_id, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.8 reports ------------------------------------------------------------- US-06, US-07, US-11
CREATE TABLE reports (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id          BIGINT UNSIGNED NOT NULL,
  facility_id      BIGINT UNSIGNED NOT NULL,
  category         ENUM('kerusakan_fisik','kelistrikan','peralatan','kebersihan','keamanan','lainnya') NOT NULL,
  description      TEXT NOT NULL,
  photo_path       VARCHAR(255) NOT NULL,
  status           ENUM('new','in_progress','resolved','rejected') NOT NULL DEFAULT 'new',
  resolution_note  TEXT NULL,
  handled_by       BIGINT UNSIGNED NULL,
  resolved_at      DATETIME NULL,
  created_at       TIMESTAMP NULL,
  updated_at       TIMESTAMP NULL,

  CONSTRAINT fk_reports_users      FOREIGN KEY (user_id)     REFERENCES users (id),
  CONSTRAINT fk_reports_facilities FOREIGN KEY (facility_id) REFERENCES facilities (id),
  CONSTRAINT fk_reports_handler    FOREIGN KEY (handled_by)  REFERENCES users (id),

  CONSTRAINT chk_rep_description CHECK (CHAR_LENGTH(TRIM(description)) > 0),
  CONSTRAINT chk_rep_resolution  CHECK (status NOT IN ('resolved','rejected')
                                        OR CHAR_LENGTH(TRIM(COALESCE(resolution_note, ''))) > 0),
  CONSTRAINT chk_rep_resolved_ts CHECK ((status IN ('resolved','rejected')) = (resolved_at IS NOT NULL)),

  INDEX idx_rep_queue    (status, created_at),
  INDEX idx_rep_facility (facility_id, created_at),
  INDEX idx_rep_user     (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.9 report_status_logs ------------------------------------------------------ audit trail
CREATE TABLE report_status_logs (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  report_id    BIGINT UNSIGNED NOT NULL,
  from_status  VARCHAR(20) NULL,
  to_status    VARCHAR(20) NOT NULL,
  changed_by   BIGINT UNSIGNED NULL,
  note         TEXT NULL,
  changed_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_plogs_reports FOREIGN KEY (report_id)  REFERENCES reports (id),
  CONSTRAINT fk_plogs_users   FOREIGN KEY (changed_by) REFERENCES users (id),
  INDEX idx_plogs_report (report_id, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
