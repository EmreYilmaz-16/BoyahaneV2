-- Parti (orders) tablosuna sarım ve ambalaj alanları ekleme
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS sarim_sekli SMALLINT NULL,
    ADD COLUMN IF NOT EXISTS ambalaj     SMALLINT NULL;
