-- ================================================================
-- MACHINE MAINTENANCE & FAULT MANAGEMENT TABLE UPDATES
-- Existing installations: align database schema with machine module code.
-- ================================================================

ALTER TABLE machine_faults ADD COLUMN IF NOT EXISTS root_cause_code VARCHAR(30);
ALTER TABLE machine_faults ADD COLUMN IF NOT EXISTS downtime_category VARCHAR(30) NOT NULL DEFAULT 'unplanned';

CREATE TABLE IF NOT EXISTS machine_used_materials (
    material_id SERIAL PRIMARY KEY,
    source_type VARCHAR(30) NOT NULL,
    source_id INTEGER NOT NULL,
    product_id INTEGER,
    product_name VARCHAR(250) NOT NULL,
    product_code VARCHAR(100),
    quantity NUMERIC(18,4) NOT NULL DEFAULT 1,
    unit VARCHAR(30) NOT NULL DEFAULT 'adet',
    note VARCHAR(1000),
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_machine_used_materials_source_type CHECK (source_type IN ('fault', 'maintenance')),
    CONSTRAINT chk_machine_used_materials_quantity CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS machine_sla_rules (
    sla_rule_id SERIAL PRIMARY KEY,
    priority_level INTEGER NOT NULL UNIQUE,
    response_target_min INTEGER NOT NULL,
    close_target_min INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    update_date TIMESTAMP,
    CONSTRAINT chk_machine_sla_rules_priority CHECK (priority_level BETWEEN 1 AND 4),
    CONSTRAINT chk_machine_sla_rules_response CHECK (response_target_min > 0),
    CONSTRAINT chk_machine_sla_rules_close CHECK (close_target_min > 0)
);

INSERT INTO machine_sla_rules (priority_level, response_target_min, close_target_min, is_active)
VALUES
    (1, 240, 2880, true),
    (2, 120, 1440, true),
    (3, 60, 480, true),
    (4, 30, 240, true)
ON CONFLICT (priority_level) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_machine_faults_root_cause ON machine_faults(root_cause_code);
CREATE INDEX IF NOT EXISTS idx_machine_faults_downtime_category ON machine_faults(downtime_category);
CREATE INDEX IF NOT EXISTS idx_machine_used_materials_source ON machine_used_materials(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_machine_used_materials_product ON machine_used_materials(product_id);
CREATE INDEX IF NOT EXISTS idx_machine_sla_rules_active ON machine_sla_rules(is_active, priority_level);

COMMENT ON COLUMN machine_faults.root_cause_code IS 'Kök neden kodu: mechanical/electrical/pneumatic/hydraulic/operator_error/wear/other';
COMMENT ON COLUMN machine_faults.downtime_category IS 'Duruş kategorisi: unplanned/planned/production_change/cleaning';
COMMENT ON TABLE machine_used_materials IS 'Arıza ve bakım kayıtlarında kullanılan malzemeler';
COMMENT ON TABLE machine_sla_rules IS 'Makine arıza önceliklerine göre SLA hedefleri';
