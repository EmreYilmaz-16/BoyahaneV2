-- ============================================================
-- Kullanıcı Bazlı Fuseaction Erişim Kısıtı
-- ============================================================
CREATE TABLE IF NOT EXISTS user_fuseaction_deny (
    deny_id      SERIAL        PRIMARY KEY,
    user_id      INTEGER       NOT NULL,
    fuseaction   VARCHAR(255)  NOT NULL,
    reason       VARCHAR(255)  NOT NULL DEFAULT '',
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_fuseaction_deny_user
        FOREIGN KEY (user_id) REFERENCES kullanicilar(id) ON DELETE CASCADE,

    CONSTRAINT uq_user_fuseaction_deny
        UNIQUE (user_id, fuseaction)
);

CREATE INDEX IF NOT EXISTS idx_user_fuseaction_deny_user
    ON user_fuseaction_deny (user_id);

COMMENT ON TABLE user_fuseaction_deny IS 'Kullanıcı bazlı fuseaction görüntüleme engel listesi';
