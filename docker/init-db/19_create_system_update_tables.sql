-- Sistem güncelleme merkezi tabloları

CREATE TABLE IF NOT EXISTS system_update_settings (
    setting_id SERIAL PRIMARY KEY,
    repo_url VARCHAR(500) NOT NULL,
    repo_branch VARCHAR(150) NOT NULL DEFAULT 'main',
    repo_local_path VARCHAR(500) NOT NULL DEFAULT '/workspace/BoyahaneV2',
    check_releases BOOLEAN NOT NULL DEFAULT TRUE,
    auto_pull_on_release BOOLEAN NOT NULL DEFAULT FALSE,
    docker_compose_cmd VARCHAR(200) NOT NULL DEFAULT 'docker-compose up -d --build',
    remote_db_host VARCHAR(255),
    remote_db_port INTEGER DEFAULT 5432,
    remote_db_name VARCHAR(255),
    remote_db_user VARCHAR(255),
    remote_db_password VARCHAR(255),
    remote_db_schema VARCHAR(120) DEFAULT 'public',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_system_update_settings_singleton ON system_update_settings((1));

CREATE TABLE IF NOT EXISTS system_release_notes (
    note_id SERIAL PRIMARY KEY,
    release_tag VARCHAR(120) NOT NULL,
    release_name VARCHAR(255),
    release_url VARCHAR(500),
    published_at TIMESTAMP,
    note_body TEXT,
    source_type VARCHAR(40) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (release_tag)
);

-- Varsayılan ayar kaydı
INSERT INTO system_update_settings (
    repo_url,
    repo_branch,
    repo_local_path,
    check_releases,
    auto_pull_on_release,
    docker_compose_cmd
)
SELECT
    'https://github.com/example/BoyahaneV2.git',
    'main',
    '/workspace/BoyahaneV2',
    TRUE,
    FALSE,
    'docker-compose up -d --build'
WHERE NOT EXISTS (SELECT 1 FROM system_update_settings);

-- Menüye Update Merkezi sayfası
INSERT INTO pbs_objects (
    object_name,
    module_id,
    show_menu,
    window_type,
    full_fuseaction,
    file_path,
    order_no,
    is_active
)
SELECT
    'Update Merkezi',
    21,
    TRUE,
    'standart',
    'setup.update_center',
    '/setup/display/update_center.cfm',
    999,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.update_center'
);
