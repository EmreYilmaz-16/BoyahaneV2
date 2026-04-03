-- ================================================
-- OPERATION_TYPES TABLE (Operasyon Tipleri)
-- ================================================

CREATE TABLE operation_types (
    operation_type_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(250),
    o_hour INTEGER,
    o_minute INTEGER,
    comment VARCHAR(100),
    comment2 VARCHAR(100),
    file_name TEXT,
    operation_cost NUMERIC(18,6),
    money VARCHAR(50),
    file_server_id INTEGER,
    operation_code VARCHAR(50),
    operation_status BOOLEAN,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    ezgi_h_sure NUMERIC(18,6),
    is_virtual BOOLEAN,
    ezgi_formul VARCHAR(250),
    stock_id INTEGER,
    product_name VARCHAR(150),
    
    -- Foreign Keys
    CONSTRAINT fk_operation_types_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_operation_types_stock ON operation_types(stock_id);
CREATE INDEX idx_operation_types_code ON operation_types(operation_code);
CREATE INDEX idx_operation_types_status ON operation_types(operation_status);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE operation_types IS 'Üretim operasyon tipleri ve süreleri';
COMMENT ON COLUMN operation_types.operation_type IS 'Operasyon tipi adı';
COMMENT ON COLUMN operation_types.operation_cost IS 'Operasyon maliyeti';
