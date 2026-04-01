-- ============================================================
-- Kullanıcı Kısayolları / Favoriler Tablosu
-- ============================================================
CREATE TABLE IF NOT EXISTS user_favorites (
    favorite_id   SERIAL          PRIMARY KEY,
    user_id       INTEGER         NOT NULL,
    fuseaction    VARCHAR(255)    NOT NULL,
    page_title    VARCHAR(255)    NOT NULL DEFAULT '',
    page_icon     VARCHAR(100)    NOT NULL DEFAULT 'fas fa-star',
    display_order INTEGER         NOT NULL DEFAULT 0,
    added_date    TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_favorites_user
        FOREIGN KEY (user_id) REFERENCES kullanicilar(id) ON DELETE CASCADE,

    CONSTRAINT uq_user_fuseaction
        UNIQUE (user_id, fuseaction)
);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user
    ON user_favorites (user_id);

COMMENT ON TABLE user_favorites IS 'Kullanıcılara ait sayfa kısayolları/favoriler';
