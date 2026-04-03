-- ================================================
-- SPECTS TABLE (Varyantlar/Specifications)
-- ================================================
-- Bağımlılık: spect_main tablosu önce oluşturulmalıdır (15c)
-- ================================================

CREATE TABLE spects (
    spect_var_id SERIAL PRIMARY KEY,
    wrk_id VARCHAR(100),
    product_configurator_id INTEGER,
    spect_var_name VARCHAR(500),
    spect_type INTEGER,
    detail TEXT,
    product_id INTEGER,
    stock_id INTEGER,
    total_amount NUMERIC(18,6),
    other_money_currency VARCHAR(43),
    other_total_amount NUMERIC(18,6),
    is_tree BOOLEAN,
    product_amount NUMERIC(18,6),
    product_amount_currency VARCHAR(43),
    spect_cost NUMERIC(18,6),
    spect_cost_currency VARCHAR(43),
    spect_main_id INTEGER,
    file_name VARCHAR(50),
    file_server_id INTEGER,
    marj_total_amount NUMERIC(18,6),
    marj_other_total_amount NUMERIC(18,6),
    marj_amount NUMERIC(18,6),
    marj_percent NUMERIC(18,6),
    is_limited_stock BOOLEAN,
    special_code_1 VARCHAR(250),
    special_code_2 VARCHAR(250),
    special_code_3 VARCHAR(250),
    special_code_4 VARCHAR(250),
    record_emp INTEGER,
    record_cons INTEGER,
    record_par INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE,
    update_emp INTEGER,
    update_par INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_cons INTEGER,
    is_mix_product BOOLEAN DEFAULT false,
    stage INTEGER,
    employee_id INTEGER,
    save_date TIMESTAMP WITHOUT TIME ZONE,
    
    -- Kaynak Parametreleri / Welding Parameters
    double_butt_root_gap NUMERIC(18,6),
    double_butt_seam_groove NUMERIC(18,6),
    double_butt_depth_of_root_face NUMERIC(18,6),
    double_butt_cap NUMERIC(18,6),
    butt_root_gap NUMERIC(18,6),
    butt_steel_density NUMERIC(18,6),
    single_butt_alpha1 NUMERIC(18,6),
    single_butt_alpha2 NUMERIC(18,6),
    fillet_butt_cap NUMERIC(18,6),
    welding_id INTEGER,
    single_butt_overlap NUMERIC(18,6),
    butt_cap NUMERIC(18,6),
    size NUMERIC(18,6),
    double_butt_alpha_1 NUMERIC(18,6),
    double_butt_alpha_2 NUMERIC(18,6),
    double_butt_steel_density NUMERIC(18,6),
    quality_id INTEGER,
    double_butt_alpha_3 NUMERIC(18,6),
    double_butt_alpha_4 NUMERIC(18,6),
    diameter NUMERIC(18,6),
    double_butt_cap_2 NUMERIC(18,6),
    product_cat INTEGER,
    cap_unit NUMERIC(18,6),
    butt_sheet_thickness NUMERIC(18,6),
    single_butt_sheet_thickness NUMERIC(18,6),
    single_butt_root_gap NUMERIC(18,6),
    double_butt_overlap NUMERIC(18,6),
    fillet_butt_steel_density NUMERIC(18,6),
    width NUMERIC(18,6),
    outer_unit NUMERIC(18,6),
    fillet_butt_sheet_thickness NUMERIC(18,6),
    single_butt_seam_length NUMERIC(18,6),
    butt_penetration NUMERIC(18,6),
    single_butt_cap NUMERIC(18,6),
    butt_seam_length NUMERIC(18,6),
    single_butt_penetration NUMERIC(18,6),
    thickness NUMERIC(18,6),
    butt_overlap NUMERIC(18,6),
    height NUMERIC(18,6),
    double_butt_seam_length NUMERIC(18,6),
    width_unit NUMERIC(18,6),
    inner_diameter NUMERIC(18,6),
    double_butt_sheet_thickness NUMERIC(18,6),
    single_butt_steel_density NUMERIC(18,6),
    size_unit NUMERIC(18,6),
    fillet_butt_seam_length NUMERIC(18,6),
    outer_diameter NUMERIC(18,6),
    single_butt_depth_of_root_face NUMERIC(18,6),
    welding_json TEXT,
    
    -- Foreign Keys
    CONSTRAINT fk_spects_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spects_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_spects_main FOREIGN KEY (spect_main_id) REFERENCES spect_main(spect_main_id) ON DELETE SET NULL,
    CONSTRAINT fk_spects_product_cat FOREIGN KEY (product_cat) REFERENCES product_cat(product_catid) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_spects_product ON spects(product_id);
CREATE INDEX idx_spects_stock ON spects(stock_id);
CREATE INDEX idx_spects_main ON spects(spect_main_id);
CREATE INDEX idx_spects_wrk ON spects(wrk_id);
CREATE INDEX idx_spects_product_cat ON spects(product_cat);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE spects IS 'Ürün varyantları ve özellikleri (kaynak parametreleri dahil)';
COMMENT ON COLUMN spects.spect_var_name IS 'Varyant adı';
COMMENT ON COLUMN spects.is_mix_product IS 'Karma ürün mü?';
