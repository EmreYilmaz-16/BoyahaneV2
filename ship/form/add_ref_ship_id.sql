-- ============================================================
-- Migrasyon: orders tablosuna ref_ship_id FK kolonu ekle
-- Giriş Fişi ↔ Parti ilişkisini metin tabanlı (ref_no) yerine
-- gerçek foreign key (ref_ship_id) ile tutmak için.
-- ============================================================

-- 1. Kolonu ekle
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS ref_ship_id INTEGER;

-- 2. Mevcut verileri göç ettir:
--    orders.ref_no = ship.ship_number eşleştirmesinden ship_id bul
UPDATE orders o
SET ref_ship_id = s.ship_id
FROM ship s
WHERE s.ship_number = o.ref_no
  AND o.ref_no IS NOT NULL
  AND o.ref_no <> ''
  AND o.ref_ship_id IS NULL;

-- 3. Foreign key kısıtı ekle (mevcut NULL kayıtlar için ON DELETE SET NULL)
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_ref_ship
    FOREIGN KEY (ref_ship_id)
    REFERENCES ship(ship_id)
    ON DELETE SET NULL;

-- 4. Performans indeksi
CREATE INDEX IF NOT EXISTS idx_orders_ref_ship_id ON orders(ref_ship_id);

-- Not: orders.ref_no kolonu eski/diğer siparişlerde kullanıcı girişi
-- referans numarası olarak kullanılmaya devam eder, kaldırılmadı.
