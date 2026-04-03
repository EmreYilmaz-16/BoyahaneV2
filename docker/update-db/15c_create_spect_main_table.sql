-- ================================================
-- SPECT_MAIN TABLE (Ana Varyant Yapılandırması)
-- ================================================

CREATE TABLE spect_main (
    spect_main_id SERIAL PRIMARY KEY,
    wrk_id VARCHAR(100),
    spect_main_name VARCHAR(500),
    spect_type INTEGER,
    detail TEXT,
    product_id INTEGER,
    stock_id INTEGER,
    is_tree BOOLEAN,
    spect_status BOOLEAN DEFAULT true,
    fuseaction VARCHAR(150),
    is_limited_stock BOOLEAN DEFAULT true,
    special_code_1 VARCHAR(250),
    special_code_2 VARCHAR(250),
    special_code_3 VARCHAR(250),
    special_code_4 VARCHAR(250),
    record_emp INTEGER,
    record_par INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE,
    update_emp INTEGER,
    update_par INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE,
    record_con INTEGER,
    update_con INTEGER,
    is_mix_product BOOLEAN DEFAULT false,
    stage INTEGER,
    employee_id INTEGER,
    save_date TIMESTAMP WITHOUT TIME ZONE,
    
    -- Foreign Keys
    CONSTRAINT fk_spect_main_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spect_main_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_spect_main_product ON spect_main(product_id);
CREATE INDEX idx_spect_main_stock ON spect_main(stock_id);
CREATE INDEX idx_spect_main_status ON spect_main(spect_status);
CREATE INDEX idx_spect_main_wrk ON spect_main(wrk_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE spect_main IS 'Ana varyant yapılandırma şablonları';
COMMENT ON COLUMN spect_main.spect_status IS 'Varyant şablonu aktif mi?';
