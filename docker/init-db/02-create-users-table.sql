-- Kullanıcılar tablosu oluşturma
CREATE TABLE IF NOT EXISTS kullanicilar (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    w3userid VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Örnek kullanıcı ekleme (şifre: admin123 - gerçek projede mutlaka hash'lenmiş olmalı)
INSERT INTO kullanicilar (name, surname, username, password, w3userid) 
VALUES 
    ('Admin', 'User', 'admin', 'admin123', 'ADM001'),
    ('Mehmet', 'Yılmaz', 'mehmet', '123456', 'USR001'),
    ('Ayşe', 'Kaya', 'ayse', '123456', 'USR002')
ON CONFLICT (username) DO NOTHING;

-- Index oluşturma
CREATE INDEX IF NOT EXISTS idx_kullanicilar_username ON kullanicilar(username);
CREATE INDEX IF NOT EXISTS idx_kullanicilar_w3userid ON kullanicilar(w3userid);

-- Güncelleme trigger'ı için fonksiyon
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger oluşturma
DROP TRIGGER IF EXISTS update_kullanicilar_updated_at ON kullanicilar;
CREATE TRIGGER update_kullanicilar_updated_at
    BEFORE UPDATE ON kullanicilar
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Log kaydı
DO $$
BEGIN
    RAISE NOTICE 'Kullanicilar tablosu başarıyla oluşturuldu!';
END $$;
