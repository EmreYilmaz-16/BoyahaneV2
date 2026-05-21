-- Migration: order_row tablosuna amount2 ve unit2 kolonları ekle
-- Tarih: 2025
-- Açıklama: kg bilgisini ayrı satır yerine ana satırda saklamak için

ALTER TABLE order_row
    ADD COLUMN IF NOT EXISTS amount2 NUMERIC(14,4),
    ADD COLUMN IF NOT EXISTS unit2 VARCHAR(50);

-- Ayrıca daha önce eklenmemiş ise ek_aciklama da ekle
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS ek_aciklama VARCHAR(500);
