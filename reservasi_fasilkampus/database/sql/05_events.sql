-- 05_events.sql — disalin dari workflow/DATABASE_DESIGN.md §10
-- Jangan ubah file ini tanpa memperbarui DATABASE_DESIGN.md (dan sebaliknya).
-- MySQL >= 8.0.16 · InnoDB · utf8mb4

-- Reservasi pending yang waktunya sudah lewat tidak boleh menumpuk di antrian petugas (US-08)
CREATE EVENT IF NOT EXISTS ev_expire_pending_reservations
ON SCHEDULE EVERY 15 MINUTE
DO CALL sp_expire_pending_reservations();
