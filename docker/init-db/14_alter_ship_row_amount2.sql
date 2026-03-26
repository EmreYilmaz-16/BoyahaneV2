-- =====================================================
-- ship_row tablosuna amount2 kolonu ekle
-- Ham Kumaş: amount = metre, amount2 = kg
-- =====================================================
ALTER TABLE ship_row
    ADD COLUMN IF NOT EXISTS amount2 NUMERIC(18,3);
