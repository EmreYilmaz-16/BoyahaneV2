-- Kullanıcı bazlı modül yetkilendirme tablosu
CREATE TABLE IF NOT EXISTS user_module_permissions (
    permission_id SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL,
    module_id     INTEGER NOT NULL,
    can_view      BOOLEAN NOT NULL DEFAULT false,
    can_update    BOOLEAN NOT NULL DEFAULT false,
    can_delete    BOOLEAN NOT NULL DEFAULT false,
    record_date   TIMESTAMP NOT NULL DEFAULT NOW(),
    update_date   TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_ump_user FOREIGN KEY (user_id) REFERENCES kullanicilar(id) ON DELETE CASCADE,
    CONSTRAINT fk_ump_module FOREIGN KEY (module_id) REFERENCES pbs_module(module_id) ON DELETE CASCADE,
    CONSTRAINT uq_ump_user_module UNIQUE (user_id, module_id)
);

CREATE INDEX IF NOT EXISTS idx_ump_user ON user_module_permissions (user_id);
CREATE INDEX IF NOT EXISTS idx_ump_module ON user_module_permissions (module_id);
