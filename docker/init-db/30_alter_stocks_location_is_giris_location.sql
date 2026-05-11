ALTER TABLE stocks_location ADD COLUMN IF NOT EXISTS is_giris_location BOOLEAN NOT NULL DEFAULT false;
