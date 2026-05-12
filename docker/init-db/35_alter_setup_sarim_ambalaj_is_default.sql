-- setup_sarim_sekli ve setup_ambalaj tablolarına is_default kolonu ekleme
ALTER TABLE setup_sarim_sekli
    ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

ALTER TABLE setup_ambalaj
    ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

COMMENT ON COLUMN setup_sarim_sekli.is_default IS 'Varsayılan sarım şekli (parti formunda otomatik seçilir)';
COMMENT ON COLUMN setup_ambalaj.is_default      IS 'Varsayılan ambalaj tipi (parti formunda otomatik seçilir)';
