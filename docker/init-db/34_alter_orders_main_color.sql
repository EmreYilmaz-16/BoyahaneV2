-- ================================================
-- orders tablosuna main_color kolonu ekleme
-- Parti ekranlarında Müşteri Renk / Açıklama kaydı
-- ================================================
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS main_color VARCHAR(200);

COMMENT ON COLUMN orders.main_color IS 'Parti: Müşteri Renk / Açıklama';
