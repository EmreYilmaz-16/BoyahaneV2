-- DEPARTMENT Tablosu
CREATE TABLE IF NOT EXISTS department (
    department_id SERIAL PRIMARY KEY,
    department_head VARCHAR(100) NOT NULL,
    department_detail VARCHAR(150),
    department_status BOOLEAN DEFAULT false,
    is_production BOOLEAN,
    is_store INTEGER,
    branch_id INTEGER,
    admin1_position_code INTEGER,
    admin2_position_code INTEGER,
    hierarchy_dep_id VARCHAR(50),
    hierarchy VARCHAR(75),
    is_organization BOOLEAN,
    _department_name_id INTEGER,
    headquarters_id INTEGER,
    x_coordinate VARCHAR(50),
    y_coordinate VARCHAR(50),
    z_coordinate VARCHAR(50),
    width NUMERIC(10,2),
    height NUMERIC(10,2),
    depth NUMERIC(10,2),
    department_email VARCHAR(50),
    level_no INTEGER,
    change_date TIMESTAMP,
    in_company_reason_id INTEGER,
    dept_stage INTEGER,
    special_code VARCHAR(50),
    point_multiplier NUMERIC(10,2),
    department_cat INTEGER,
    special_code2 VARCHAR(100),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50)
);

-- STOCKS_LOCATION Tablosu
CREATE TABLE IF NOT EXISTS stocks_location (
    id SERIAL PRIMARY KEY,
    location_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    company_id INTEGER,
    consumer_id INTEGER,
    department_location VARCHAR(500),
    comment VARCHAR(75),
    width NUMERIC(10,2),
    height NUMERIC(10,2),
    depth NUMERIC(10,2),
    no_sale BOOLEAN DEFAULT false,
    belongto_institution BOOLEAN DEFAULT false,
    priority BOOLEAN DEFAULT false,
    location_type INTEGER,
    delivery BOOLEAN DEFAULT false,
    status BOOLEAN,
    is_cost_action BOOLEAN DEFAULT false,
    is_end_of_series BOOLEAN DEFAULT false,
    is_scrap BOOLEAN DEFAULT false,
    x_coordinate VARCHAR(50),
    y_coordinate VARCHAR(50),
    z_coordinate VARCHAR(50),
    is_quality BOOLEAN DEFAULT false,
    temperature NUMERIC(10,2),
    pressure NUMERIC(10,2),
    is_recycle_location INTEGER,
    CONSTRAINT fk_stocks_location_dept FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE CASCADE
);

-- İndeksler
CREATE INDEX idx_department_status ON department(department_status);
CREATE INDEX idx_department_branch ON department(branch_id);
CREATE INDEX idx_department_hierarchy ON department(hierarchy);
CREATE INDEX idx_department_cat ON department(department_cat);
CREATE INDEX idx_stocks_location_dept ON stocks_location(department_id);
CREATE INDEX idx_stocks_location_loc ON stocks_location(location_id);
CREATE INDEX idx_stocks_location_company ON stocks_location(company_id);
CREATE INDEX idx_stocks_location_type ON stocks_location(location_type);
CREATE INDEX idx_stocks_location_status ON stocks_location(status);

-- Yorum satırları
COMMENT ON TABLE department IS 'Departman bilgileri';
COMMENT ON TABLE stocks_location IS 'Stok lokasyon bilgileri';
COMMENT ON COLUMN department.department_head IS 'Departman başlığı/adı';
COMMENT ON COLUMN department.department_status IS 'Departman durumu (true:Aktif, false:Pasif)';
COMMENT ON COLUMN department.is_production IS 'Üretim departmanı mı?';
COMMENT ON COLUMN department.is_store IS 'Depo mu?';
COMMENT ON COLUMN department.hierarchy IS 'Hiyerarşi kodu';
COMMENT ON COLUMN stocks_location.department_location IS 'Lokasyon açıklaması';
COMMENT ON COLUMN stocks_location.no_sale IS 'Satışa kapalı';
COMMENT ON COLUMN stocks_location.is_quality IS 'Kalite kontrolde mi?';
COMMENT ON COLUMN stocks_location.is_scrap IS 'Hurda lokasyonu mu?';
