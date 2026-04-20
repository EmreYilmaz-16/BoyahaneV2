-- ================================================================
-- ARAÇ OPERASYONLARİ: YAKIT VE SERVİS KAYIT TABLOLARI
-- 22_create_asset_management_tables.sql'den eksik kalan tablolar
-- ================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS vehicle_fuel_logs (
    fuel_log_id   SERIAL PRIMARY KEY,
    asset_id      INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    fuel_date     DATE NOT NULL,
    odometer_km   NUMERIC(18,1),
    liters        NUMERIC(18,3) NOT NULL,
    amount        NUMERIC(18,2) NOT NULL,
    station_name  VARCHAR(150),
    invoice_no    VARCHAR(50),
    note          TEXT,
    record_date   TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vehicle_fuel_asset  ON vehicle_fuel_logs(asset_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_fuel_date   ON vehicle_fuel_logs(fuel_date);

CREATE TABLE IF NOT EXISTS vehicle_service_logs (
    service_id          SERIAL PRIMARY KEY,
    asset_id            INTEGER NOT NULL REFERENCES asset_master(asset_id) ON DELETE CASCADE,
    service_type        VARCHAR(40) NOT NULL CHECK (service_type IN ('PERIODIC','REPAIR','TIRE','ACCIDENT_REPAIR','OTHER')),
    service_date        DATE NOT NULL,
    odometer_km         NUMERIC(18,1),
    supplier_company_id INTEGER,
    labor_cost          NUMERIC(18,2) DEFAULT 0,
    material_cost       NUMERIC(18,2) DEFAULT 0,
    total_cost          NUMERIC(18,2) GENERATED ALWAYS AS (COALESCE(labor_cost,0)+COALESCE(material_cost,0)) STORED,
    next_service_date   DATE,
    note                TEXT,
    record_date         TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vehicle_service_asset ON vehicle_service_logs(asset_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_service_date  ON vehicle_service_logs(service_date);

COMMIT;
