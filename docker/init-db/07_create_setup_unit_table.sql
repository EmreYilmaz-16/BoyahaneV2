-- SETUP_UNIT Tablosu
CREATE TABLE IF NOT EXISTS setup_unit (
    unit_id SERIAL PRIMARY KEY,
    unit VARCHAR(43),
    unit_code VARCHAR(50),
    unece_name VARCHAR(50),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50)
);

-- İndeksler
CREATE INDEX idx_setup_unit_code ON setup_unit(unit_code);
CREATE INDEX idx_setup_unit_name ON setup_unit(unit);

-- Yorum satırları
COMMENT ON TABLE setup_unit IS 'Birim tanımları (kg, m, adet, vb.)';
COMMENT ON COLUMN setup_unit.unit IS 'Birim adı';
COMMENT ON COLUMN setup_unit.unit_code IS 'Birim kodu';
COMMENT ON COLUMN setup_unit.unece_name IS 'UN/ECE standart birim adı';

-- Örnek veriler
INSERT INTO setup_unit (unit, unit_code, unece_name) VALUES
('Kilogram', 'KG', 'KGM'),
('Metre', 'M', 'MTR'),
('Adet', 'AD', 'C62'),
('Litre', 'LT', 'LTR'),
('Ton', 'TON', 'TNE'),
('Metrekare', 'M2', 'MTK'),
('Metreküp', 'M3', 'MTQ'),
('Paket', 'PKT', 'PK'),
('Koli', 'KOL', 'CT'),
('Kutu', 'KUT', 'BX')
ON CONFLICT DO NOTHING;
