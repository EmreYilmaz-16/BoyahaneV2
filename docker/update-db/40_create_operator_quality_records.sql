-- Kalite operatör cihaz/web servis kayıtlarının hata ve operatör detaylarını saklar.
CREATE TABLE IF NOT EXISTS operator_quality_records (
    record_id SERIAL PRIMARY KEY,
    roll_id INTEGER REFERENCES ship_roll(roll_id) ON DELETE SET NULL,
    request_payload TEXT,
    error_category VARCHAR(200),
    error_code VARCHAR(50),
    error_description VARCHAR(500),
    operator_name VARCHAR(100),
    operator_surname VARCHAR(100),
    operator_userid VARCHAR(100),
    operator_role VARCHAR(50),
    notes TEXT,
    last_measurement VARCHAR(200),
    saved_at TIMESTAMP,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_operator_quality_records_roll_id ON operator_quality_records(roll_id);
CREATE INDEX IF NOT EXISTS idx_operator_quality_records_saved_at ON operator_quality_records(saved_at);
CREATE INDEX IF NOT EXISTS idx_operator_quality_records_operator_userid ON operator_quality_records(operator_userid);

COMMENT ON TABLE operator_quality_records IS 'Kalite operatör web servisinden gelen sarım/top ölçüm kayıt ek bilgileri';
COMMENT ON COLUMN operator_quality_records.roll_id IS 'ship_roll tablosundaki oluşturulan top kaydı';
COMMENT ON COLUMN operator_quality_records.request_payload IS 'Cihazdan gelen ham JSON payload';
