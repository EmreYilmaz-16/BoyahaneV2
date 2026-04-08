-- ================================================================
-- MACHINE MAINTENANCE & FAULT MANAGEMENT TABLES
-- ================================================================

CREATE TABLE IF NOT EXISTS machine_machines (
    machine_id SERIAL PRIMARY KEY,
    machine_code VARCHAR(50) NOT NULL UNIQUE,
    machine_name VARCHAR(150) NOT NULL,
    department_id INTEGER,
    location_text VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT true,
    current_status_code INTEGER NOT NULL DEFAULT 1, -- 1:Arıza Yok, 2:Bakımda, 3:Arızalı
    current_status_note VARCHAR(500),
    installation_date DATE,
    last_maintenance_date TIMESTAMP,
    next_maintenance_date TIMESTAMP,
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    CONSTRAINT fk_machine_department FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS machine_status_history (
    status_history_id SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL,
    status_code INTEGER NOT NULL,
    status_note VARCHAR(1000),
    source_type VARCHAR(30) NOT NULL DEFAULT 'manual', -- manual/maintenance/fault
    source_id INTEGER,
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    record_emp INTEGER,
    CONSTRAINT fk_machine_status_machine FOREIGN KEY (machine_id) REFERENCES machine_machines(machine_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS machine_maintenance_plans (
    plan_id SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL,
    plan_title VARCHAR(200) NOT NULL,
    period_days INTEGER NOT NULL,
    start_date DATE,
    next_planned_date TIMESTAMP,
    last_done_date TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT true,
    notes VARCHAR(1000),
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    record_emp INTEGER,
    update_date TIMESTAMP,
    update_emp INTEGER,
    CONSTRAINT fk_machine_plan_machine FOREIGN KEY (machine_id) REFERENCES machine_machines(machine_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS machine_maintenance_logs (
    maintenance_log_id SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL,
    plan_id INTEGER,
    maintenance_type VARCHAR(30) NOT NULL DEFAULT 'planned', -- planned/unplanned
    maintenance_start TIMESTAMP,
    maintenance_end TIMESTAMP,
    maintenance_result VARCHAR(30) NOT NULL DEFAULT 'completed', -- completed/partial/failed
    result_note VARCHAR(2000),
    performed_by INTEGER,
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    record_emp INTEGER,
    CONSTRAINT fk_machine_maintenance_machine FOREIGN KEY (machine_id) REFERENCES machine_machines(machine_id) ON DELETE CASCADE,
    CONSTRAINT fk_machine_maintenance_plan FOREIGN KEY (plan_id) REFERENCES machine_maintenance_plans(plan_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS machine_faults (
    fault_id SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL,
    fault_no VARCHAR(50) NOT NULL UNIQUE,
    fault_title VARCHAR(200) NOT NULL,
    fault_description VARCHAR(4000),
    priority_level INTEGER NOT NULL DEFAULT 2, -- 1:Düşük 2:Orta 3:Yüksek 4:Kritik
    fault_status VARCHAR(20) NOT NULL DEFAULT 'open', -- open/in_progress/resolved/cancelled
    opened_at TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_at TIMESTAMP,
    resolved_at TIMESTAMP,
    opened_by INTEGER,
    assigned_emp_id INTEGER,
    intervention_note VARCHAR(2000),
    resolution_note VARCHAR(2000),
    record_date TIMESTAMP NOT NULL DEFAULT NOW(),
    update_date TIMESTAMP,
    CONSTRAINT fk_machine_fault_machine FOREIGN KEY (machine_id) REFERENCES machine_machines(machine_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS machine_fault_events (
    fault_event_id SERIAL PRIMARY KEY,
    fault_id INTEGER NOT NULL,
    event_type VARCHAR(30) NOT NULL, -- opened/assigned/intervention/resolved/cancelled
    event_note VARCHAR(2000),
    event_date TIMESTAMP NOT NULL DEFAULT NOW(),
    employee_id INTEGER,
    CONSTRAINT fk_machine_fault_event_fault FOREIGN KEY (fault_id) REFERENCES machine_faults(fault_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_machine_machines_status ON machine_machines(current_status_code);
CREATE INDEX IF NOT EXISTS idx_machine_plans_next_date ON machine_maintenance_plans(next_planned_date);
CREATE INDEX IF NOT EXISTS idx_machine_faults_status ON machine_faults(fault_status);
CREATE INDEX IF NOT EXISTS idx_machine_faults_machine ON machine_faults(machine_id);
CREATE INDEX IF NOT EXISTS idx_machine_faults_opened_at ON machine_faults(opened_at);

COMMENT ON TABLE machine_machines IS 'Makine ana kayıtları';
COMMENT ON TABLE machine_maintenance_plans IS 'Makine periyodik bakım planları';
COMMENT ON TABLE machine_maintenance_logs IS 'Gerçekleşen bakım kayıtları';
COMMENT ON TABLE machine_faults IS 'Makine arıza kayıtları';
COMMENT ON TABLE machine_fault_events IS 'Arıza yaşam döngüsü olayları';
