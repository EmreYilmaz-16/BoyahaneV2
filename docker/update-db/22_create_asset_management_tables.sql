-- ================================================================
-- WORKCUBE ASSET MANAGEMENT MODULE (Fiziki + BT + Araç)
-- ================================================================
-- Bu script; fiziki varlıklar, BT varlıkları ve motorlu taşıtlar için
-- tek bir yaşam döngüsü yönetimi altyapısı kurar.
-- PostgreSQL uyumlu olarak hazırlanmıştır.
-- ================================================================

BEGIN;

-- ------------------------------------------------
-- 1) REFERANS TABLOLARI
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS asset_categories (
    category_id SERIAL PRIMARY KEY,
    category_code VARCHAR(50) UNIQUE,
    category_name VARCHAR(150) NOT NULL,
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('PHYSICAL','IT','VEHICLE')),
    parent_id INTEGER REFERENCES asset_categories(category_id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS asset_locations (
    location_id SERIAL PRIMARY KEY,
    location_code VARCHAR(50) UNIQUE,
    location_name VARCHAR(150) NOT NULL,
    department_id INTEGER,
    company_id INTEGER,
    address TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------
-- 2) ANA VARLIK TABLOSU
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS asset_master (
    asset_id SERIAL PRIMARY KEY,
    asset_no VARCHAR(50) UNIQUE,
    asset_name VARCHAR(250) NOT NULL,
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('PHYSICAL','IT','VEHICLE')),
    category_id INTEGER REFERENCES asset_categories(category_id) ON DELETE SET NULL,

    brand VARCHAR(100),
    model VARCHAR(100),
    serial_no VARCHAR(100),
    barcode VARCHAR(100),

    purchase_date DATE,
    acquisition_cost NUMERIC(18,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'TRY',
    supplier_company_id INTEGER,

    location_id INTEGER REFERENCES asset_locations(location_id) ON DELETE SET NULL,
    assigned_employee_id INTEGER,
    assigned_department_id INTEGER,

    warranty_start_date DATE,
    warranty_end_date DATE,
    insurance_policy_no VARCHAR(100),
    insurance_start_date DATE,
    insurance_end_date DATE,

    useful_life_months INTEGER,
    residual_value NUMERIC(18,2),
    depreciation_method VARCHAR(30) DEFAULT 'STRAIGHT_LINE',

    asset_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (asset_status IN ('ACTIVE','IN_MAINTENANCE','IN_STOCK','TRANSFERRED','SCRAPPED','SOLD')),

    detail TEXT,

    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_asset_master_type ON asset_master(asset_type);
CREATE INDEX IF NOT EXISTS idx_asset_master_status ON asset_master(asset_status);
CREATE INDEX IF NOT EXISTS idx_asset_master_location ON asset_master(location_id);

-- ------------------------------------------------
-- 3) ORTAK HAREKET / ATAMA / BAKIM
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS asset_movements (
    movement_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    movement_type VARCHAR(20) NOT NULL
        CHECK (movement_type IN ('TRANSFER','ASSIGN','RETURN','SCRAP','SELL','LOCATION_CHANGE')),
    from_location_id INTEGER REFERENCES asset_locations(location_id) ON DELETE SET NULL,
    to_location_id INTEGER REFERENCES asset_locations(location_id) ON DELETE SET NULL,
    from_employee_id INTEGER,
    to_employee_id INTEGER,
    movement_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note TEXT,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS asset_maintenance (
    maintenance_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    maintenance_type VARCHAR(20) NOT NULL CHECK (maintenance_type IN ('PLANNED','UNPLANNED','REPAIR','CALIBRATION','SERVICE')),
    work_order_no VARCHAR(50),
    planned_date DATE,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    end_date TIMESTAMP WITHOUT TIME ZONE,
    supplier_company_id INTEGER,
    labor_cost NUMERIC(18,2) DEFAULT 0,
    spare_part_cost NUMERIC(18,2) DEFAULT 0,
    total_cost NUMERIC(18,2) GENERATED ALWAYS AS (COALESCE(labor_cost,0) + COALESCE(spare_part_cost,0)) STORED,
    maintenance_status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (maintenance_status IN ('OPEN','IN_PROGRESS','COMPLETED','CANCELLED')),
    note TEXT,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS asset_depreciation (
    depreciation_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
    opening_value NUMERIC(18,2) NOT NULL,
    depreciation_amount NUMERIC(18,2) NOT NULL,
    closing_value NUMERIC(18,2) NOT NULL,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(asset_id, period_year, period_month)
);

-- ------------------------------------------------
-- 4) BT VARLIK EK TABLOLARI
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS it_asset_details (
    asset_id INTEGER PRIMARY KEY REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    hostname VARCHAR(150),
    ip_address INET,
    mac_address VARCHAR(50),
    operating_system VARCHAR(100),
    cpu_info VARCHAR(150),
    ram_gb NUMERIC(10,2),
    storage_gb NUMERIC(10,2),
    antivirus_expiry DATE,
    patch_level VARCHAR(100),
    security_compliance_status VARCHAR(20) DEFAULT 'UNKNOWN'
        CHECK (security_compliance_status IN ('COMPLIANT','NON_COMPLIANT','UNKNOWN')),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS it_software_licenses (
    license_id SERIAL PRIMARY KEY,
    asset_id INTEGER REFERENCES asset_master(asset_id) ON DELETE SET NULL,
    software_name VARCHAR(150) NOT NULL,
    vendor_name VARCHAR(150),
    license_key VARCHAR(250),
    total_seat INTEGER DEFAULT 1,
    used_seat INTEGER DEFAULT 0,
    purchase_date DATE,
    expiry_date DATE,
    compliance_status VARCHAR(20) DEFAULT 'VALID' CHECK (compliance_status IN ('VALID','EXPIRED','OVERUSED','UNKNOWN')),
    annual_cost NUMERIC(18,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'TRY',
    note TEXT,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS it_network_topology (
    topology_id SERIAL PRIMARY KEY,
    parent_asset_id INTEGER REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    child_asset_id INTEGER REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    connection_type VARCHAR(50),
    port_info VARCHAR(100),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(parent_asset_id, child_asset_id, port_info)
);

-- ------------------------------------------------
-- 5) ARAÇ YÖNETİMİ EK TABLOLARI
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS vehicle_details (
    asset_id INTEGER PRIMARY KEY REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    plate_no VARCHAR(20) UNIQUE NOT NULL,
    chassis_no VARCHAR(100) UNIQUE,
    engine_no VARCHAR(100),
    model_year INTEGER,
    fuel_type VARCHAR(20) CHECK (fuel_type IN ('GASOLINE','DIESEL','LPG','HYBRID','ELECTRIC','OTHER')),
    lease_start_date DATE,
    lease_end_date DATE,
    current_km NUMERIC(18,1) DEFAULT 0,
    traffic_insurance_end DATE,
    casco_end DATE,
    mtv_due_date DATE,
    inspection_due_date DATE,
    emission_due_date DATE,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_fuel_logs (
    fuel_log_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    fuel_date DATE NOT NULL,
    odometer_km NUMERIC(18,1),
    liters NUMERIC(18,3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    station_name VARCHAR(150),
    invoice_no VARCHAR(50),
    note TEXT,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_service_logs (
    service_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    service_type VARCHAR(40) NOT NULL CHECK (service_type IN ('PERIODIC','REPAIR','TIRE','ACCIDENT_REPAIR','OTHER')),
    service_date DATE NOT NULL,
    odometer_km NUMERIC(18,1),
    supplier_company_id INTEGER,
    labor_cost NUMERIC(18,2) DEFAULT 0,
    material_cost NUMERIC(18,2) DEFAULT 0,
    total_cost NUMERIC(18,2) GENERATED ALWAYS AS (COALESCE(labor_cost,0)+COALESCE(material_cost,0)) STORED,
    next_service_date DATE,
    note TEXT,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_accidents (
    accident_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    accident_date DATE NOT NULL,
    driver_employee_id INTEGER,
    damage_description TEXT,
    estimated_cost NUMERIC(18,2),
    actual_cost NUMERIC(18,2),
    insurance_claim_no VARCHAR(100),
    process_status VARCHAR(20) DEFAULT 'OPEN' CHECK (process_status IN ('OPEN','IN_REPAIR','CLOSED')),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_driver_assignments (
    assignment_id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    employee_id INTEGER NOT NULL,
    assignment_start TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assignment_end TIMESTAMP WITHOUT TIME ZONE,
    is_primary BOOLEAN DEFAULT true,
    note TEXT,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------
-- 6) PBS OBJECTS (Menü / Fuseaction)
-- ------------------------------------------------
-- Not: Gerekirse önce eski kayıtları temizlemek için:
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'asset.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('asset.list_assets',            '/asset/display/list_assets.cfm',            'list_assets',            'Varlık Yönetimi',                  'page', NULL, 10, true, true),
('asset.add_asset',              '/asset/form/add_asset.cfm',                 'add_asset',              'Varlık Ekle / Düzenle',             'page', NULL, 11, true, false),
('asset.save_asset',             '/asset/form/save_asset.cfm',                'save_asset',             'Varlık Kaydet',                     'page', NULL, 12, true, false),
('asset.delete_asset',           '/asset/form/delete_asset.cfm',              'delete_asset',           'Varlık Sil',                        'page', NULL, 13, true, false),
('asset.list_maintenances',      '/asset/display/list_maintenances.cfm',      'list_maintenances',      'Bakım Kayıtları',                   'page', NULL, 14, true, true),
('asset.save_maintenance',       '/asset/form/save_maintenance.cfm',          'save_maintenance',       'Bakım Kaydet',                      'page', NULL, 15, true, false),
('asset.list_it_licenses',       '/asset/display/list_it_licenses.cfm',       'list_it_licenses',       'BT Lisans Yönetimi',                'page', NULL, 16, true, true),
('asset.save_it_license',        '/asset/form/save_it_license.cfm',           'save_it_license',        'BT Lisans Kaydet',                  'page', NULL, 17, true, false),
('asset.list_vehicle_operations','/asset/display/list_vehicle_operations.cfm', 'list_vehicle_operations','Araç Operasyonları',                'page', NULL, 18, true, true),
('asset.save_vehicle_fuel',      '/asset/form/save_vehicle_fuel.cfm',         'save_vehicle_fuel',      'Araç Yakıt Kaydı',                  'page', NULL, 19, true, false),
('asset.save_vehicle_service',   '/asset/form/save_vehicle_service.cfm',      'save_vehicle_service',   'Araç Servis Kaydı',                 'page', NULL, 20, true, false),
('asset.save_vehicle_accident',  '/asset/form/save_vehicle_accident.cfm',     'save_vehicle_accident',  'Araç Hasar/Kaza Kaydı',             'page', NULL, 21, true, false);

COMMIT;
