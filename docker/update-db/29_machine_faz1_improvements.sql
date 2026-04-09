-- ================================================================
-- MACHINE MAINTENANCE FAZ 1 — Kök Neden, SLA Kuralları, Duruş Kategorisi
-- ================================================================
-- Çalıştırma:
--   docker exec -i boyahane_postgres psql -U boyahane_user -d boyahane < docker/update-db/29_machine_faz1_improvements.sql

-- 1) Arıza tablosuna kök neden kodu ekle
ALTER TABLE machine_faults
    ADD COLUMN IF NOT EXISTS root_cause_code VARCHAR(30),
    ADD COLUMN IF NOT EXISTS downtime_category VARCHAR(30) NOT NULL DEFAULT 'unplanned';

COMMENT ON COLUMN machine_faults.root_cause_code IS 'mechanical | electrical | pneumatic | hydraulic | operator_error | wear | other';
COMMENT ON COLUMN machine_faults.downtime_category IS 'unplanned | planned | production_change | cleaning';

-- 2) SLA kural tablosu
CREATE TABLE IF NOT EXISTS machine_sla_rules (
    sla_rule_id           SERIAL PRIMARY KEY,
    priority_level        INTEGER NOT NULL UNIQUE,   -- 1:Düşük 2:Orta 3:Yüksek 4:Kritik
    priority_label        VARCHAR(30) NOT NULL,
    response_target_min   INTEGER NOT NULL DEFAULT 120,  -- İlk müdahale hedef süresi (dk)
    close_target_min      INTEGER NOT NULL DEFAULT 1440, -- Kapanış hedef süresi (dk)
    is_active             BOOLEAN NOT NULL DEFAULT true,
    record_date           TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE machine_sla_rules IS 'Arıza öncelik seviyesine göre SLA hedef süreler (dakika)';

-- 3) Varsayılan SLA kuralları
INSERT INTO machine_sla_rules (priority_level, priority_label, response_target_min, close_target_min)
VALUES
    (1, 'Düşük',   240,  2880),  -- Yanıt: 4s  | Kapanış: 48s
    (2, 'Orta',    120,  1440),  -- Yanıt: 2s  | Kapanış: 24s
    (3, 'Yüksek',   60,   480),  -- Yanıt: 1s  | Kapanış: 8s
    (4, 'Kritik',   30,   240)   -- Yanıt: 30dk | Kapanış: 4s
ON CONFLICT (priority_level) DO NOTHING;

-- 4) İndeks
CREATE INDEX IF NOT EXISTS idx_machine_faults_root_cause ON machine_faults(root_cause_code);
CREATE INDEX IF NOT EXISTS idx_machine_faults_downtime_cat ON machine_faults(downtime_category);
