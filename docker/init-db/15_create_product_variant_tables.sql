-- ================================================
-- PRODUCT SPECIFICATION & VARIANT TABLES
-- ================================================
-- Ürün varyantları, ağaç yapıları ve operasyon tabloları
-- ================================================

-- ================================================
-- PRODUCT_TREE TABLE (Ürün Ağacı/Reçete - BOM)
-- ================================================
CREATE TABLE product_tree (
    product_tree_id SERIAL PRIMARY KEY,
    related_id INTEGER,
    product_id INTEGER,
    hierarchy VARCHAR(100),
    is_tree BOOLEAN DEFAULT false,
    amount NUMERIC(18,6),
    unit_id INTEGER,
    stock_id INTEGER,
    is_configure BOOLEAN,
    is_sevk BOOLEAN DEFAULT false,
    spect_main_id INTEGER,
    line_number INTEGER,
    operation_type_id INTEGER,
    operation_duration VARCHAR(43),
    station_id INTEGER,
    is_phantom BOOLEAN DEFAULT false,
    question_id INTEGER,
    related_product_tree_id INTEGER,
    process_stage INTEGER,
    main_stock_id INTEGER,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    history_date TIMESTAMP WITHOUT TIME ZONE,
    history_emp INTEGER,
    is_free_amount BOOLEAN,
    fire_amount NUMERIC(18,6),
    fire_rate NUMERIC(18,6),
    detail VARCHAR(150),
    product_property INTEGER,
    last_price NUMERIC(18,6),
    supplier_company_id INTEGER,
    alternative_stock_id INTEGER,
    product_sample_id INTEGER,
    product_length INTEGER,
    technical_point INTEGER,
    product_height INTEGER,
    target_price NUMERIC(18,6),
    tree_type INTEGER,
    target_price_currency VARCHAR(10),
    production_code VARCHAR(50),
    product_width INTEGER,
    amount2 NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_product_tree_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_unit FOREIGN KEY (unit_id) REFERENCES setup_unit(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_supplier FOREIGN KEY (supplier_company_id) REFERENCES company(company_id) ON DELETE SET NULL
);

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
-- SPECT_MAIN_ROW TABLE (Ana Varyant Satırları)
-- ================================================
CREATE TABLE spect_main_row (
    spect_main_row_id SERIAL PRIMARY KEY,
    spect_main_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    amount NUMERIC(18,6),
    property_id INTEGER,
    variation_id INTEGER,
    total_min NUMERIC(18,6),
    total_max NUMERIC(18,6),
    product_name VARCHAR(500),
    is_property INTEGER,
    is_configure BOOLEAN,
    is_sevk BOOLEAN,
    total_value NUMERIC(18,6),
    tolerance INTEGER,
    product_space NUMERIC(18,6),
    product_display NUMERIC(18,6),
    product_rate NUMERIC(18,6),
    product_list_price NUMERIC(18,6),
    calculate_type INTEGER,
    related_main_spect_id INTEGER,
    related_main_spect_name VARCHAR(150),
    line_number INTEGER,
    dimension NUMERIC(18,6),
    configurator_variation_id INTEGER,
    is_phantom BOOLEAN DEFAULT false,
    related_tree_id INTEGER,
    operation_type_id INTEGER,
    question_id INTEGER,
    station_id INTEGER,
    is_free_amount BOOLEAN,
    fire_amount NUMERIC(18,6),
    fire_rate NUMERIC(18,6),
    detail VARCHAR(150),
    is_quality_type BOOLEAN,
    quality_type_id INTEGER,
    quality_standart_value NUMERIC(18,6),
    quality_measure NUMERIC(18,6),
    quality_tolerance NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_spect_main_row_main FOREIGN KEY (spect_main_id) REFERENCES spect_main(spect_main_id) ON DELETE CASCADE,
    CONSTRAINT fk_spect_main_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spect_main_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- SPECTS TABLE (Varyantlar/Specifications)
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
-- SPECTS_ROW TABLE (Varyant Satırları)
-- ================================================
CREATE TABLE spects_row (
    spect_row_id SERIAL PRIMARY KEY,
    spect_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    amount_value NUMERIC(18,6),
    total_value NUMERIC(18,6),
    money_currency VARCHAR(43),
    property_id INTEGER,
    variation_id INTEGER,
    total_min NUMERIC(18,6),
    total_max NUMERIC(18,6),
    product_name VARCHAR(500),
    is_property INTEGER,
    is_configure BOOLEAN,
    diff_price NUMERIC(18,6),
    product_cost NUMERIC(18,6),
    product_cost_money VARCHAR(43),
    product_cost_id INTEGER,
    is_sevk BOOLEAN DEFAULT false,
    tolerance INTEGER,
    related_spect_id INTEGER,
    shelf_number VARCHAR(43),
    product_manufact_code VARCHAR(100),
    product_space NUMERIC(18,6),
    product_display NUMERIC(18,6),
    product_rate NUMERIC(18,6),
    product_list_price NUMERIC(18,6),
    line_number INTEGER,
    configurator_variation_id INTEGER,
    dimension NUMERIC(18,6),
    related_tree_id INTEGER,
    operation_type_id INTEGER,
    is_quality_type BOOLEAN,
    quality_type_id INTEGER,
    quality_standart_value NUMERIC(18,6),
    quality_measure NUMERIC(18,6),
    quality_tolerance NUMERIC(18,6),
    fire_amount NUMERIC(18,6),
    product_height NUMERIC(18,6),
    product_thickness NUMERIC(18,6),
    tree_type INTEGER,
    product_size NUMERIC(18,6),
    product_width NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_spects_row_spect FOREIGN KEY (spect_id) REFERENCES spects(spect_var_id) ON DELETE CASCADE,
    CONSTRAINT fk_spects_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spects_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

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
-- WORKSTATIONS_PRODUCTS TABLE (İstasyon-Ürün İlişkisi)
-- ================================================
CREATE TABLE workstations_products (
    ws_p_id SERIAL PRIMARY KEY,
    ws_id INTEGER,
    stock_id INTEGER,
    capacity NUMERIC(18,6),
    production_time NUMERIC(18,6),
    production_time_type NUMERIC(18,6),
    setup_time NUMERIC(18,6),
    min_product_amount NUMERIC(18,6),
    production_type BOOLEAN,
    process VARCHAR(250),
    main_stock_id INTEGER,
    operation_type_id INTEGER,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE,
    asset_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_ws_products_ws FOREIGN KEY (ws_id) REFERENCES workstations(station_id) ON DELETE CASCADE,
    CONSTRAINT fk_ws_products_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_ws_products_operation FOREIGN KEY (operation_type_id) REFERENCES operation_types(operation_type_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes - PRODUCT_TREE
-- ================================================
CREATE INDEX idx_product_tree_product ON product_tree(product_id);
CREATE INDEX idx_product_tree_stock ON product_tree(stock_id);
CREATE INDEX idx_product_tree_related ON product_tree(related_id);
CREATE INDEX idx_product_tree_hierarchy ON product_tree(hierarchy);
CREATE INDEX idx_product_tree_spect_main ON product_tree(spect_main_id);
CREATE INDEX idx_product_tree_operation ON product_tree(operation_type_id);
CREATE INDEX idx_product_tree_station ON product_tree(station_id);

-- ================================================
-- İndeksler / Indexes - SPECT_MAIN
-- ================================================
CREATE INDEX idx_spect_main_product ON spect_main(product_id);
CREATE INDEX idx_spect_main_stock ON spect_main(stock_id);
CREATE INDEX idx_spect_main_status ON spect_main(spect_status);
CREATE INDEX idx_spect_main_wrk ON spect_main(wrk_id);

-- ================================================
-- İndeksler / Indexes - SPECT_MAIN_ROW
-- ================================================
CREATE INDEX idx_spect_main_row_main ON spect_main_row(spect_main_id);
CREATE INDEX idx_spect_main_row_product ON spect_main_row(product_id);
CREATE INDEX idx_spect_main_row_stock ON spect_main_row(stock_id);

-- ================================================
-- İndeksler / Indexes - SPECTS
-- ================================================
CREATE INDEX idx_spects_product ON spects(product_id);
CREATE INDEX idx_spects_stock ON spects(stock_id);
CREATE INDEX idx_spects_main ON spects(spect_main_id);
CREATE INDEX idx_spects_wrk ON spects(wrk_id);
CREATE INDEX idx_spects_product_cat ON spects(product_cat);

-- ================================================
-- İndeksler / Indexes - SPECTS_ROW
-- ================================================
CREATE INDEX idx_spects_row_spect ON spects_row(spect_id);
CREATE INDEX idx_spects_row_product ON spects_row(product_id);
CREATE INDEX idx_spects_row_stock ON spects_row(stock_id);

-- ================================================
-- İndeksler / Indexes - OPERATION_TYPES
-- ================================================
CREATE INDEX idx_operation_types_stock ON operation_types(stock_id);
CREATE INDEX idx_operation_types_code ON operation_types(operation_code);
CREATE INDEX idx_operation_types_status ON operation_types(operation_status);

-- ================================================
-- İndeksler / Indexes - WORKSTATIONS
-- ================================================
CREATE INDEX idx_workstations_department ON workstations(department);
CREATE INDEX idx_workstations_product ON workstations(product);
CREATE INDEX idx_workstations_partner ON workstations(outsource_partner);
CREATE INDEX idx_workstations_active ON workstations(active);
CREATE INDEX idx_workstations_branch ON workstations(branch);

-- ================================================
-- İndeksler / Indexes - WORKSTATIONS_PRODUCTS
-- ================================================
CREATE INDEX idx_ws_products_ws ON workstations_products(ws_id);
CREATE INDEX idx_ws_products_stock ON workstations_products(stock_id);
CREATE INDEX idx_ws_products_operation ON workstations_products(operation_type_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================

COMMENT ON TABLE product_tree IS 'Ürün ağacı/reçete tablosu (BOM - Bill of Materials)';
COMMENT ON TABLE spect_main IS 'Ana varyant yapılandırma şablonları';
COMMENT ON TABLE spect_main_row IS 'Ana varyant şablon satırları';
COMMENT ON TABLE spects IS 'Ürün varyantları ve özellikleri (kaynak parametreleri dahil)';
COMMENT ON TABLE spects_row IS 'Varyant detay satırları';
COMMENT ON TABLE operation_types IS 'Üretim operasyon tipleri ve süreleri';
COMMENT ON TABLE workstations IS 'Üretim iş istasyonları ve kapasiteleri';
COMMENT ON TABLE workstations_products IS 'İstasyon-ürün ilişki tablosu';

COMMENT ON COLUMN product_tree.is_tree IS 'Ağaç yapısı var mı?';
COMMENT ON COLUMN product_tree.is_phantom IS 'Hayalet ürün (stoksuz)';
COMMENT ON COLUMN spect_main.spect_status IS 'Varyant şablonu aktif mi?';
COMMENT ON COLUMN spects.spect_var_name IS 'Varyant adı';
COMMENT ON COLUMN spects.is_mix_product IS 'Karma ürün mü?';
COMMENT ON COLUMN operation_types.operation_type IS 'Operasyon tipi adı';
COMMENT ON COLUMN operation_types.operation_cost IS 'Operasyon maliyeti';
COMMENT ON COLUMN workstations.station_name IS 'İstasyon adı';
COMMENT ON COLUMN workstations.capacity IS 'İstasyon kapasitesi';
COMMENT ON COLUMN workstations_products.production_time IS 'Üretim süresi';
