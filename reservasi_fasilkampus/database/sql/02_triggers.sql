-- 02_triggers.sql — disalin dari workflow/DATABASE_DESIGN.md §7.2–§7.3
-- Jangan ubah file ini tanpa memperbarui DATABASE_DESIGN.md (dan sebaliknya).
-- MySQL >= 8.0.16 · InnoDB · utf8mb4

DELIMITER $$

-- ---------------------------------------------------------------- BEFORE INSERT
CREATE TRIGGER trg_reservations_bi
BEFORE INSERT ON reservations
FOR EACH ROW
BEGIN
  DECLARE v_facility_status VARCHAR(20);

  IF NEW.status <> 'pending' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-01: Reservasi baru harus berstatus pending';
  END IF;

  IF NEW.start_time <= NOW() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-02: Waktu mulai sudah lewat';
  END IF;

  SELECT status INTO v_facility_status FROM facilities WHERE id = NEW.facility_id;
  IF v_facility_status IS NULL OR v_facility_status <> 'active' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-03: Fasilitas tidak dapat dipesan';
  END IF;
END$$

-- ---------------------------------------------------------------- AFTER INSERT
CREATE TRIGGER trg_reservations_ai
AFTER INSERT ON reservations
FOR EACH ROW
BEGIN
  INSERT INTO reservation_status_logs (reservation_id, from_status, to_status, changed_by)
  VALUES (NEW.id, NULL, NEW.status, NEW.user_id);
END$$

-- ---------------------------------------------------------------- BEFORE UPDATE
CREATE TRIGGER trg_reservations_bu
BEFORE UPDATE ON reservations
FOR EACH ROW
BEGIN
  DECLARE v_facility_status VARCHAR(20);
  DECLARE v_actor_role      VARCHAR(20);
  DECLARE v_deadline_min    INT DEFAULT 0;

  IF NEW.user_id <> OLD.user_id OR NEW.facility_id <> OLD.facility_id
     OR NEW.start_time <> OLD.start_time OR NEW.end_time <> OLD.end_time THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-08: Pemilik, fasilitas, dan jadwal tidak boleh diubah';
  END IF;

  IF NEW.status <> OLD.status THEN

    -- Transisi sah: pending -> approved|rejected|cancelled|expired ; approved -> cancelled
    IF NOT (   (OLD.status = 'pending'  AND NEW.status IN ('approved','rejected','cancelled','expired'))
            OR (OLD.status = 'approved' AND NEW.status = 'cancelled') ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-04: Perubahan status reservasi tidak diizinkan';
    END IF;

    -- approved / rejected: wajib dicatat petugasnya
    IF NEW.status IN ('approved','rejected') THEN
      IF NEW.processed_by IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-09: Petugas pemroses wajib diisi';
      END IF;
      SET NEW.processed_at = NOW();
    END IF;

    -- approved: fasilitas masih aktif, belum lewat, tidak bentrok
    IF NEW.status = 'approved' THEN
      SELECT status INTO v_facility_status FROM facilities WHERE id = NEW.facility_id;
      IF v_facility_status <> 'active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-03: Fasilitas tidak dapat dipesan';
      END IF;

      IF NEW.start_time <= NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-02: Waktu mulai sudah lewat';
      END IF;

      IF EXISTS (
        SELECT 1 FROM reservations r
        WHERE r.facility_id = NEW.facility_id
          AND r.status      = 'approved'
          AND r.id         <> NEW.id
          AND r.start_time  < NEW.end_time
          AND r.end_time    > NEW.start_time
      ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-05: Jadwal bentrok dengan reservasi yang sudah disetujui';
      END IF;
    END IF;

    -- cancelled: pemilik (sebelum batas) atau petugas (wajib alasan)
    IF NEW.status = 'cancelled' THEN
      IF NEW.cancelled_by IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-10: Hanya pemilik atau petugas yang boleh membatalkan';
      END IF;
      SET NEW.cancelled_at = NOW();

      SELECT role INTO v_actor_role FROM users WHERE id = NEW.cancelled_by;

      IF NEW.cancelled_by = NEW.user_id THEN
        SELECT CAST(setting_value AS UNSIGNED) INTO v_deadline_min
        FROM system_settings WHERE setting_key = 'cancel_deadline_minutes';
        IF NOW() > NEW.start_time - INTERVAL v_deadline_min MINUTE THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-07: Batas waktu pembatalan mandiri sudah lewat';
        END IF;
      ELSEIF v_actor_role = 'petugas' THEN
        IF CHAR_LENGTH(TRIM(COALESCE(NEW.cancel_reason, ''))) = 0 THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-06: Petugas wajib mengisi alasan pembatalan';
        END IF;
      ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-10: Hanya pemilik atau petugas yang boleh membatalkan';
      END IF;
    END IF;

    -- expired: hanya untuk pending yang waktunya sudah lewat (dipicu event §10)
    IF NEW.status = 'expired' AND NEW.start_time > NOW() THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RSV-04: Perubahan status reservasi tidak diizinkan';
    END IF;

  END IF;
END$$

-- ---------------------------------------------------------------- AFTER UPDATE
CREATE TRIGGER trg_reservations_au
AFTER UPDATE ON reservations
FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status THEN

    -- Kunci slot. Bila slot sudah dimiliki reservasi lain -> 1062 -> seluruh UPDATE dibatalkan.
    IF NEW.status = 'approved' THEN
      INSERT INTO reservation_slots (reservation_id, facility_id, slot_date, time_slot_id)
      SELECT NEW.id, NEW.facility_id, CAST(NEW.start_time AS DATE), ts.id
      FROM time_slots ts
      WHERE ts.start_time >= CAST(NEW.start_time AS TIME)
        AND ts.end_time   <= CAST(NEW.end_time   AS TIME);

    -- Lepas slot saat reservasi approved dibatalkan
    ELSEIF OLD.status = 'approved' AND NEW.status = 'cancelled' THEN
      DELETE FROM reservation_slots WHERE reservation_id = NEW.id;
    END IF;

    INSERT INTO reservation_status_logs (reservation_id, from_status, to_status, changed_by, note)
    VALUES (
      NEW.id, OLD.status, NEW.status,
      CASE NEW.status
        WHEN 'cancelled' THEN NEW.cancelled_by
        WHEN 'expired'   THEN NULL
        ELSE NEW.processed_by
      END,
      NEW.cancel_reason
    );
  END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_reports_bi
BEFORE INSERT ON reports
FOR EACH ROW
BEGIN
  DECLARE v_facility_status VARCHAR(20);

  IF NEW.status <> 'new' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RPT-01: Perubahan status laporan tidak diizinkan';
  END IF;

  SELECT status INTO v_facility_status FROM facilities WHERE id = NEW.facility_id;
  IF v_facility_status IS NULL OR v_facility_status = 'inactive' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RPT-03: Fasilitas nonaktif tidak bisa dilaporkan';
  END IF;
END$$

CREATE TRIGGER trg_reports_ai
AFTER INSERT ON reports
FOR EACH ROW
BEGIN
  INSERT INTO report_status_logs (report_id, from_status, to_status, changed_by)
  VALUES (NEW.id, NULL, NEW.status, NEW.user_id);
END$$

CREATE TRIGGER trg_reports_bu
BEFORE UPDATE ON reports
FOR EACH ROW
BEGIN
  DECLARE v_handler_role VARCHAR(20);

  IF NEW.user_id <> OLD.user_id OR NEW.facility_id <> OLD.facility_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RPT-04: Pelapor dan fasilitas laporan tidak boleh diubah';
  END IF;

  IF NEW.status <> OLD.status THEN
    -- Transisi sah: new -> in_progress|rejected ; in_progress -> resolved|rejected
    IF NOT (   (OLD.status = 'new'         AND NEW.status IN ('in_progress','rejected'))
            OR (OLD.status = 'in_progress' AND NEW.status IN ('resolved','rejected')) ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RPT-01: Perubahan status laporan tidak diizinkan';
    END IF;

    SELECT role INTO v_handler_role FROM users WHERE id = NEW.handled_by;
    IF NEW.handled_by IS NULL OR v_handler_role <> 'petugas' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RPT-02: Petugas penangan wajib diisi dan berperan petugas';
    END IF;

    IF NEW.status IN ('resolved','rejected') THEN
      SET NEW.resolved_at = NOW();   -- catatan resolusi dijaga chk_rep_resolution
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_reports_au
AFTER UPDATE ON reports
FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status THEN
    INSERT INTO report_status_logs (report_id, from_status, to_status, changed_by, note)
    VALUES (NEW.id, OLD.status, NEW.status, NEW.handled_by, NEW.resolution_note);
  END IF;
END$$

DELIMITER ;
