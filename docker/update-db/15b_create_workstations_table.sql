-- ================================================
-- WORKSTATIONS TABLE (İş İstasyonları)
-- ================================================

CREATE TABLE workstations (
    station_id SERIAL PRIMARY KEY,
    is_capacity BOOLEAN,
    project_id INTEGER,
    up_station INTEGER,
    station_name VARCHAR(100),
    branch INTEGER,
    department INTEGER,
    product INTEGER,
    capacity INTEGER,
    value_station NUMERIC(18,6),
    energy INTEGER,
    emp_id VARCHAR(500),
    outsource_partner INTEGER,
    comment VARCHAR(250),
    down_stations INTEGER,
    active BOOLEAN,
    cost NUMERIC(18,6),
    cost_money VARCHAR(43),
    employee_number INTEGER,
    set_period_hour INTEGER,
    set_period_minute INTEGER,
    avg_capacity_day INTEGER,
    avg_capacity_hour INTEGER,
    asset_id INTEGER,
    basic_input_id INTEGER,
    avg_cost NUMERIC(18,6),
    exit_dep_id INTEGER,
    exit_loc_id INTEGER,
    enter_dep_id INTEGER,
    enter_loc_id INTEGER,
    production_dep_id INTEGER,
    production_loc_id INTEGER,
    width NUMERIC(18,6),
    length NUMERIC(18,6),
    height NUMERIC(18,6),
    electric_type INTEGER,
    design_info TEXT,
    marina_part_type_id INTEGER,
    record_ip VARCHAR(50),
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    update_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE,
    reflection_type INTEGER,
    unit2 VARCHAR(43),
    ezgi_setup_time NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_workstations_department FOREIGN KEY (department) REFERENCES department(department_id) ON DELETE SET NULL,
    CONSTRAINT fk_workstations_product FOREIGN KEY (product) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_workstations_partner FOREIGN KEY (outsource_partner) REFERENCES company(company_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_workstations_department ON workstations(department);
CREATE INDEX idx_workstations_product ON workstations(product);
CREATE INDEX idx_workstations_partner ON workstations(outsource_partner);
CREATE INDEX idx_workstations_active ON workstations(active);
CREATE INDEX idx_workstations_branch ON workstations(branch);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE workstations IS 'Üretim iş istasyonları ve kapasiteleri';
COMMENT ON COLUMN workstations.station_name IS 'İstasyon adı';
COMMENT ON COLUMN workstations.capacity IS 'İstasyon kapasitesi';
