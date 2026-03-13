-- İade Nedenleri Tablosu (Return Categories)
CREATE TABLE IF NOT EXISTS return_cats (
    return_cat_id SERIAL PRIMARY KEY,
    return_cat VARCHAR(50),
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP
);

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_return_cats_record_date ON return_cats(record_date);
CREATE INDEX IF NOT EXISTS idx_return_cats_record_emp ON return_cats(record_emp);

-- Trigger for auto-update of update_date
CREATE OR REPLACE FUNCTION update_return_cats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_return_cats_updated_at ON return_cats;
CREATE TRIGGER update_return_cats_updated_at
    BEFORE UPDATE ON return_cats
    FOR EACH ROW
    EXECUTE FUNCTION update_return_cats_updated_at();

-- Örnek veriler
INSERT INTO return_cats (return_cat, record_date) VALUES
('Kalite Problemi', CURRENT_TIMESTAMP),
('Ölçü Hatası', CURRENT_TIMESTAMP),
('Renk Uyuşmazlığı', CURRENT_TIMESTAMP),
('Leke/Delik', CURRENT_TIMESTAMP),
('Yanlış Ürün', CURRENT_TIMESTAMP),
('Gecikme', CURRENT_TIMESTAMP),
('Müşteri İsteği', CURRENT_TIMESTAMP),
('Diğer', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE return_cats IS 'İade nedenleri tablosu - Mal girişlerde kullanılır';
COMMENT ON COLUMN return_cats.return_cat_id IS 'Benzersiz iade nedeni ID';
COMMENT ON COLUMN return_cats.return_cat IS 'İade nedeni açıklaması';
COMMENT ON COLUMN return_cats.record_emp IS 'Kaydı oluşturan çalışan ID';
COMMENT ON COLUMN return_cats.record_ip IS 'Kaydı oluşturan IP adresi';
COMMENT ON COLUMN return_cats.record_date IS 'Kayıt oluşturma tarihi';
COMMENT ON COLUMN return_cats.update_emp IS 'Son güncelleyen çalışan ID';
COMMENT ON COLUMN return_cats.update_ip IS 'Son güncelleme IP adresi';
COMMENT ON COLUMN return_cats.update_date IS 'Son güncelleme tarihi';
