-- Renk numarası alanı eklendi
ALTER TABLE color_info ADD COLUMN IF NOT EXISTS renk_no VARCHAR(100);
