-- Ham Kumaş Alış alanları (ship_type=5)
ALTER TABLE ship
    ADD COLUMN IF NOT EXISTS hk_metre      NUMERIC(18,3),
    ADD COLUMN IF NOT EXISTS hk_kg         NUMERIC(18,3),
    ADD COLUMN IF NOT EXISTS hk_top_adedi  INTEGER,
    ADD COLUMN IF NOT EXISTS hk_h_gramaj   NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS hk_gr_mtul    NUMERIC(10,4),
    ADD COLUMN IF NOT EXISTS hk_ucretli    BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS hk_ham_boyali BOOLEAN DEFAULT true;

COMMENT ON COLUMN ship.hk_metre      IS 'Ham Kumaş: Metre';
COMMENT ON COLUMN ship.hk_kg         IS 'Ham Kumaş: Kilogram';
COMMENT ON COLUMN ship.hk_top_adedi  IS 'Ham Kumaş: Top Adedi';
COMMENT ON COLUMN ship.hk_h_gramaj   IS 'Ham Kumaş: Ham Gramaj';
COMMENT ON COLUMN ship.hk_gr_mtul    IS 'Ham Kumaş: Gram/Metül';
COMMENT ON COLUMN ship.hk_ucretli    IS 'Ham Kumaş: Ücretli mi (true=Ücretli)';
COMMENT ON COLUMN ship.hk_ham_boyali IS 'Ham Kumaş: Ham mı (true=Ham, false=Boyalı)';
