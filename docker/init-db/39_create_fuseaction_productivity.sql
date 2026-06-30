-- Fuseaction bazlı not, görev ve takip tabloları
CREATE TABLE IF NOT EXISTS fuseaction_notes (
    note_id SERIAL PRIMARY KEY,
    fuseaction VARCHAR(255) NOT NULL,
    note_title VARCHAR(255) NOT NULL,
    note_body TEXT NOT NULL DEFAULT '',
    created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_fuseaction_notes_fuseaction ON fuseaction_notes (fuseaction);

CREATE TABLE IF NOT EXISTS fuseaction_tasks (
    task_id SERIAL PRIMARY KEY,
    fuseaction VARCHAR(255) NOT NULL,
    task_title VARCHAR(255) NOT NULL,
    task_description TEXT NOT NULL DEFAULT '',
    stage VARCHAR(30) NOT NULL DEFAULT 'beklemede',
    created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_fuseaction_tasks_stage CHECK (stage IN ('beklemede','calisiliyor','bitti'))
);
CREATE INDEX IF NOT EXISTS idx_fuseaction_tasks_fuseaction ON fuseaction_tasks (fuseaction);

CREATE TABLE IF NOT EXISTS fuseaction_task_followups (
    followup_id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES fuseaction_tasks(task_id) ON DELETE CASCADE,
    followup_note TEXT NOT NULL,
    created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_fuseaction_task_followups_task ON fuseaction_task_followups (task_id);

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sayfa Notları', 21, false, 'standart', 'productivity.page_notes', '/productivity/display/page_notes.cfm', 980, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'productivity.page_notes');

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sayfa Görevleri', 21, false, 'standart', 'productivity.page_tasks', '/productivity/display/page_tasks.cfm', 981, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'productivity.page_tasks');
