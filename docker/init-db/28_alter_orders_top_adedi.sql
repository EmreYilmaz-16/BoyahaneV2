-- ================================================
-- orders tablosuna top_adedi kolonu ekleme
-- Parti oluşturma ekranlarında Top Adedi kaydı
-- ================================================
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS top_adedi INTEGER;

COMMENT ON COLUMN orders.top_adedi IS 'Parti: Top Adedi';
