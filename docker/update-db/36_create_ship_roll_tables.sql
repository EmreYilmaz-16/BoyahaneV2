-- ================================================
-- SHIP ROLL TABLES (Sevkiyat Sarım / Top Tabloları)
-- ================================================
-- SHIP_ROLL_PLAN: Sevkiyat bazlı sarım planı
-- SHIP_ROLL: Sarılan/toplanan top detayları
-- ================================================

-- ================================================
-- SHIP_ROLL_PLAN TABLE (Sevkiyat Sarım Planı)
-- ================================================
CREATE TABLE IF NOT EXISTS ship_roll_plan (
    plan_id SERIAL PRIMARY KEY,
    order_id INTEGER,
    ship_id INTEGER,
    refakat_barcode VARCHAR(100),
    sarim_tipi VARCHAR(20) NOT NULL,
    hedef_metre NUMERIC(18,6),
    hedef_kg NUMERIC(18,6),
    hedef_top_adedi INTEGER,
    tolerans_metre NUMERIC(18,6),
    tolerans_kg NUMERIC(18,6),
    record_emp INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_ship_roll_plan_sarim_tipi
        CHECK (sarim_tipi IN ('standart', 'kg_bazli', 'topa_top')),

    -- Foreign Keys
    CONSTRAINT fk_ship_roll_plan_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_ship_roll_plan_ship FOREIGN KEY (ship_id) REFERENCES ship(ship_id) ON DELETE CASCADE
);

-- ================================================
-- SHIP_ROLL TABLE (Sevkiyat Top Detayları)
-- ================================================
CREATE TABLE IF NOT EXISTS ship_roll (
    roll_id SERIAL PRIMARY KEY,
    plan_id INTEGER,
    order_id INTEGER,
    ship_id INTEGER,
    roll_no INTEGER,
    roll_barcode VARCHAR(100),
    metre NUMERIC(18,6),
    kg NUMERIC(18,6),
    paket_durumu VARCHAR(50),
    etiket_print_count INTEGER DEFAULT 0,
    record_emp INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_emp INTEGER,
    update_date TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_ship_roll_plan FOREIGN KEY (plan_id) REFERENCES ship_roll_plan(plan_id) ON DELETE CASCADE,
    CONSTRAINT fk_ship_roll_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_ship_roll_ship FOREIGN KEY (ship_id) REFERENCES ship(ship_id) ON DELETE CASCADE,

    -- Unique Constraints
    CONSTRAINT uq_ship_roll_barcode UNIQUE (roll_barcode)
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX IF NOT EXISTS idx_ship_roll_plan ON ship_roll(plan_id);
CREATE INDEX IF NOT EXISTS idx_ship_roll_order ON ship_roll(order_id);
CREATE INDEX IF NOT EXISTS idx_ship_roll_ship ON ship_roll(ship_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE ship_roll_plan IS 'Sevkiyat sarım/top planı';
COMMENT ON COLUMN ship_roll_plan.plan_id IS 'Birincil anahtar';
COMMENT ON COLUMN ship_roll_plan.order_id IS 'Sipariş ID (ORDERS tablosu)';
COMMENT ON COLUMN ship_roll_plan.ship_id IS 'Sevkiyat ID (SHIP tablosu)';
COMMENT ON COLUMN ship_roll_plan.refakat_barcode IS 'Refakat barkodu';
COMMENT ON COLUMN ship_roll_plan.sarim_tipi IS 'Sarım tipi: standart, kg_bazli, topa_top';
COMMENT ON COLUMN ship_roll_plan.hedef_metre IS 'Hedef metre';
COMMENT ON COLUMN ship_roll_plan.hedef_kg IS 'Hedef kilogram';
COMMENT ON COLUMN ship_roll_plan.hedef_top_adedi IS 'Hedef top adedi';
COMMENT ON COLUMN ship_roll_plan.tolerans_metre IS 'Metre toleransı';
COMMENT ON COLUMN ship_roll_plan.tolerans_kg IS 'Kilogram toleransı';

COMMENT ON TABLE ship_roll IS 'Sevkiyat sarım/top detayları';
COMMENT ON COLUMN ship_roll.roll_id IS 'Birincil anahtar';
COMMENT ON COLUMN ship_roll.plan_id IS 'Sarım planı ID (SHIP_ROLL_PLAN tablosu)';
COMMENT ON COLUMN ship_roll.order_id IS 'Sipariş ID (ORDERS tablosu)';
COMMENT ON COLUMN ship_roll.ship_id IS 'Sevkiyat ID (SHIP tablosu)';
COMMENT ON COLUMN ship_roll.roll_no IS 'Top sıra numarası';
COMMENT ON COLUMN ship_roll.roll_barcode IS 'Top barkodu';
COMMENT ON COLUMN ship_roll.metre IS 'Top metre bilgisi';
COMMENT ON COLUMN ship_roll.kg IS 'Top kilogram bilgisi';
COMMENT ON COLUMN ship_roll.paket_durumu IS 'Paket durumu';
COMMENT ON COLUMN ship_roll.etiket_print_count IS 'Etiket yazdırma sayısı';
