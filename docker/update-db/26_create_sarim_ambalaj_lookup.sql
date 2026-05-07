-- Sarım şekli ve ambalaj tipi lookup tabloları

CREATE TABLE IF NOT EXISTS setup_sarim_sekli (
    sarim_sekli_id SMALLSERIAL PRIMARY KEY,
    sarim_sekli_adi VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order SMALLINT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS setup_ambalaj (
    ambalaj_id SMALLSERIAL PRIMARY KEY,
    ambalaj_adi VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order SMALLINT DEFAULT 0
);

-- Varsayılan sarım şekilleri
INSERT INTO setup_sarim_sekli (sarim_sekli_adi, sort_order) VALUES
    ('Top',          1),
    ('Rulo',         2),
    ('Kangal',       3),
    ('Katlı',        4),
    ('Masura',       5),
    ('Diğer',        99)
ON CONFLICT DO NOTHING;

-- Varsayılan ambalaj tipleri
INSERT INTO setup_ambalaj (ambalaj_adi, sort_order) VALUES
    ('Naylon Sarım', 1),
    ('Streç Film',   2),
    ('Karton Kutu',  3),
    ('Çuval',        4),
    ('Koli',         5),
    ('Açık',         6),
    ('Diğer',        99)
ON CONFLICT DO NOTHING;
