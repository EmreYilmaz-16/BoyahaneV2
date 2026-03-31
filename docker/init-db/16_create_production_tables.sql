-- ================================================
-- PRODUCTION MANAGEMENT TABLES (Üretim Yönetimi)
-- ================================================
-- Üretim emirleri, operasyonlar ve sonuçlar
-- ================================================

-- ================================================
-- PRODUCTION_ORDERS TABLE (Üretim Emirleri)
-- ================================================
CREATE TABLE production_orders (
    p_order_id SERIAL PRIMARY KEY,
    stock_id INTEGER,
    dp_order_id INTEGER,
    order_id INTEGER,
    station_id INTEGER,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    finish_date TIMESTAMP WITHOUT TIME ZONE,
    quantity NUMERIC(18,6),
    status_id INTEGER,
    status INTEGER,
    project_id INTEGER,
    p_order_no VARCHAR(50),
    po_related_id INTEGER,
    order_row_id INTEGER,
    spect_var_id INTEGER,
    spect_var_name VARCHAR(500),
    detail VARCHAR(2000),
    prod_order_stage INTEGER,
    is_stock_reserved BOOLEAN,
    print_count INTEGER,
    is_demontaj BOOLEAN,
    lot_no VARCHAR(100),
    reference_no VARCHAR(50),
    production_level VARCHAR(50),
    spec_main_id INTEGER,
    product_name2 VARCHAR(500),
    is_group_lot BOOLEAN,
    is_stage INTEGER,
    wrk_row_id VARCHAR(40),
    exit_dep_id INTEGER,
    exit_loc_id INTEGER,
    demand_no VARCHAR(50),
    production_dep_id INTEGER,
    production_loc_id INTEGER,
    record_ip VARCHAR(50),
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    update_emp INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_ip VARCHAR(50),
    work_id INTEGER,
    result_amount NUMERIC(18,6),
    wrk_row_relation_id VARCHAR(50),
    group_lot_no VARCHAR(50),
    party_id INTEGER,
    partner_work_stage INTEGER,
    is_collected BOOLEAN,
    is_urgent BOOLEAN DEFAULT false,
    quantity_2 INTEGER,
    unit_2 VARCHAR(50),
    is_control_emp INTEGER,
    is_control_date TIMESTAMP WITHOUT TIME ZONE,
    finish_date_real TIMESTAMP WITHOUT TIME ZONE,
    start_date_real TIMESTAMP WITHOUT TIME ZONE,
    start_emp_id INTEGER,
    finish_emp_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_orders_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_order_row FOREIGN KEY (order_row_id) REFERENCES order_row(order_row_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_spect FOREIGN KEY (spect_var_id) REFERENCES spects(spect_var_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_spect_main FOREIGN KEY (spec_main_id) REFERENCES spect_main(spect_main_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_ORDERS_ROW TABLE (Üretim Emri Satırları)
-- ================================================
CREATE TABLE production_orders_row (
    production_order_row_id SERIAL PRIMARY KEY,
    production_order_id INTEGER,
    order_row_id INTEGER,
    order_id INTEGER,
    type INTEGER,
    plan_id INTEGER,
    op_id INTEGER,
    p_order_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_orders_row_prod FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_orders_row_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_row_order_row FOREIGN KEY (order_row_id) REFERENCES order_row(order_row_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_ORDERS_STOCKS TABLE (Üretim Emri Stokları)
-- ================================================
CREATE TABLE production_orders_stocks (
    por_stock_id SERIAL PRIMARY KEY,
    p_order_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    spect_main_id INTEGER,
    amount NUMERIC(18,6),
    type INTEGER,
    product_unit_id INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    is_phantom BOOLEAN DEFAULT false,
    is_sevk BOOLEAN DEFAULT false,
    is_property INTEGER,
    is_free_amount BOOLEAN DEFAULT false,
    fire_amount NUMERIC(18,6),
    fire_rate NUMERIC(18,6),
    spect_main_row_id INTEGER,
    is_flag BOOLEAN,
    wrk_row_id VARCHAR(50),
    line_number INTEGER,
    lot_no VARCHAR(100),
    spect_var_id INTEGER,
    prtotm_detail VARCHAR(150),
    amount2 NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_prod_orders_stocks_prod FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_orders_stocks_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_stocks_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_stocks_spect_main FOREIGN KEY (spect_main_id) REFERENCES spect_main(spect_main_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_stocks_unit FOREIGN KEY (product_unit_id) REFERENCES setup_unit(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_orders_stocks_spect FOREIGN KEY (spect_var_id) REFERENCES spects(spect_var_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_OPERATION TABLE (Üretim Operasyonları)
-- ================================================
CREATE TABLE production_operation (
    p_operation_id SERIAL PRIMARY KEY,
    p_order_id INTEGER,
    amount NUMERIC(18,6),
    station_id INTEGER,
    operation_type_id INTEGER,
    stage INTEGER,
    o_minute NUMERIC(18,6),
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_ip VARCHAR(50),
    related_op_id INTEGER,
    o_setup_time NUMERIC(18,6),
    o_extra_process_time NUMERIC(18,6),
    o_current_number INTEGER,
    o_total_process_time NUMERIC(18,6),
    o_start_date TIMESTAMP WITHOUT TIME ZONE,
    o_finish_date TIMESTAMP WITHOUT TIME ZONE,
    o_station_ip INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_operation_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_operation_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_operation_type FOREIGN KEY (operation_type_id) REFERENCES operation_types(operation_type_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_OPERATION_RESULT TABLE (Operasyon Sonuçları)
-- ================================================
CREATE TABLE production_operation_result (
    operation_result_id SERIAL PRIMARY KEY,
    p_order_id INTEGER,
    operation_id INTEGER,
    station_id INTEGER,
    real_amount NUMERIC(18,6),
    loss_amount NUMERIC(18,6),
    real_time NUMERIC(18,6),
    wait_time NUMERIC(18,6),
    action_employee_id INTEGER,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_ip VARCHAR(50),
    operation_grup_end_id VARCHAR(10),
    action_start_date TIMESTAMP WITHOUT TIME ZONE,
    operation_grup_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_op_result_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_op_result_operation FOREIGN KEY (operation_id) REFERENCES production_operation(p_operation_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_op_result_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_OPERATION_RESULT_MAIN TABLE (Ana Operasyon Sonuçları)
-- ================================================
CREATE TABLE production_operation_result_main (
    main_result_id SERIAL PRIMARY KEY,
    party_id INTEGER,
    operation_id INTEGER,
    station_id INTEGER,
    real_amount NUMERIC(18,6),
    loss_amount NUMERIC(18,6),
    real_time NUMERIC(18,6),
    wait_time NUMERIC(18,6),
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_ip VARCHAR(50),
    action_employee_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_op_result_main_operation FOREIGN KEY (operation_id) REFERENCES production_operation(p_operation_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_op_result_main_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_ORDER_OPERATIONS TABLE (Emirdeki İşlemler)
-- ================================================
CREATE TABLE production_order_operations (
    por_operation_id SERIAL PRIMARY KEY,
    p_order_id INTEGER,
    type INTEGER,
    pause_type INTEGER,
    operation_date TIMESTAMP WITHOUT TIME ZONE,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    employee_id INTEGER,
    asset_id INTEGER,
    serial_no VARCHAR(50),
    amount NUMERIC(18,6),
    pr_order_id INTEGER,
    wrk_row_id VARCHAR(100),
    start_counter NUMERIC(18,6),
    finish_counter NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_prod_order_ops_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE
);

-- ================================================
-- PRODUCTION_ORDER_OPERATIONS_EMPLOYEE TABLE (İşlem Çalışanları)
-- ================================================
CREATE TABLE production_order_operations_employee (
    operations_employee_id SERIAL PRIMARY KEY,
    operation_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_order_ops_emp_operation FOREIGN KEY (operation_id) REFERENCES production_order_operations(por_operation_id) ON DELETE CASCADE
);

-- ================================================
-- PRODUCTION_ORDER_OPERATIONS_PRODUCT TABLE (İşlem Ürünleri)
-- ================================================
CREATE TABLE production_order_operations_product (
    por_p_row_id SERIAL PRIMARY KEY,
    wrk_row_id VARCHAR(100),
    p_order_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    product_name VARCHAR(250),
    amount NUMERIC(18,6),
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    
    -- Foreign Keys
    CONSTRAINT fk_prod_order_ops_prod_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_order_ops_prod_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_ops_prod_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_ORDER_RESULTS TABLE (Üretim Emri Sonuçları)
-- ================================================
CREATE TABLE production_order_results (
    pr_order_id SERIAL PRIMARY KEY,
    p_order_id INTEGER,
    station_id INTEGER,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    finish_date TIMESTAMP WITHOUT TIME ZONE,
    lot_no VARCHAR(100),
    pr_result_no INTEGER,
    process_id INTEGER,
    result_no VARCHAR(43),
    result_number INTEGER,
    order_no VARCHAR(250),
    reference_no VARCHAR(500),
    position_id INTEGER,
    prod_ord_result_stage INTEGER,
    exit_dep_id INTEGER,
    exit_loc_id INTEGER,
    enter_dep_id INTEGER,
    enter_loc_id INTEGER,
    production_dep_id INTEGER,
    production_loc_id INTEGER,
    production_order_no VARCHAR(43),
    station_route_cost NUMERIC(18,6),
    is_stock_fis BOOLEAN,
    labor_cost_system NUMERIC(18,6),
    wrk_row_id VARCHAR(40),
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    expiration_date TIMESTAMP WITHOUT TIME ZONE,
    party_id INTEGER,
    consumer_id INTEGER,
    company_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_order_results_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_order_results_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_results_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_ORDER_RESULTS_MAIN TABLE (Ana Sonuç Kaydı)
-- ================================================
CREATE TABLE production_order_results_main (
    party_result_id SERIAL PRIMARY KEY,
    party_result_no VARCHAR(50),
    party_id INTEGER,
    party_no VARCHAR(50)
);

-- ================================================
-- PRODUCTION_ORDER_RESULTS_ROW TABLE (Sonuç Satırları)
-- ================================================
CREATE TABLE production_order_results_row (
    pr_order_row_id SERIAL PRIMARY KEY,
    type INTEGER,
    pr_order_id INTEGER,
    barcode VARCHAR(43),
    name_product VARCHAR(500),
    stock_id INTEGER,
    product_id INTEGER,
    amount NUMERIC(18,6),
    kdv_price NUMERIC(18,6),
    unit_name VARCHAR(65),
    unit_id INTEGER,
    spect_id INTEGER,
    spect_name VARCHAR(500),
    serial_no VARCHAR(50),
    is_sevkiyat BOOLEAN,
    cost_id INTEGER,
    purchase_extra_cost NUMERIC(18,6),
    purchase_net_system NUMERIC(18,6),
    purchase_net_system_money VARCHAR(43),
    purchase_extra_cost_system NUMERIC(18,6),
    purchase_net_system_total NUMERIC(18,6),
    purchase_net NUMERIC(18,6),
    purchase_net_money VARCHAR(43),
    purchase_net_total NUMERIC(18,6),
    unit2 VARCHAR(50),
    amount2 NUMERIC(18,6),
    spec_main_id INTEGER,
    station_reflection_cost_system NUMERIC(18,6),
    tree_type VARCHAR(43) DEFAULT 'S',
    product_name2 VARCHAR(500),
    is_stock_fis BOOLEAN,
    is_from_spect BOOLEAN DEFAULT false,
    labor_cost_system NUMERIC(18,6),
    fire_amount NUMERIC(18,6),
    purchase_net_2 NUMERIC(18,6),
    purchase_net_money_2 VARCHAR(43),
    is_free_amount BOOLEAN,
    lot_no VARCHAR(100),
    purchase_extra_cost_system_2 NUMERIC(18,6),
    wrk_row_id VARCHAR(50),
    wrk_row_relation_id VARCHAR(50),
    line_number INTEGER,
    is_manual_cost BOOLEAN,
    expiration_date TIMESTAMP WITHOUT TIME ZONE,
    p_order_id INTEGER,
    width NUMERIC(18,6),
    height NUMERIC(18,6),
    length NUMERIC(18,6),
    weight NUMERIC(18,6),
    specific_weight NUMERIC(18,6),
    work_id INTEGER,
    work_head VARCHAR(50),
    
    -- Foreign Keys
    CONSTRAINT fk_prod_order_results_row_result FOREIGN KEY (pr_order_id) REFERENCES production_order_results(pr_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_order_results_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_results_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_results_row_unit FOREIGN KEY (unit_id) REFERENCES setup_unit(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_results_row_spect FOREIGN KEY (spect_id) REFERENCES spects(spect_var_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_order_results_row_prod_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE SET NULL
);

-- ================================================
-- PRODUCTION_PLAN_PARTER TABLE (Üretim Planı - Partner İlişkisi)
-- ================================================
CREATE TABLE production_plan_parter (
    id SERIAL PRIMARY KEY,
    work_start_date TIMESTAMP WITHOUT TIME ZONE,
    work_end_date TIMESTAMP WITHOUT TIME ZONE,
    p_order_id INTEGER,
    station_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_plan_parter_order FOREIGN KEY (p_order_id) REFERENCES production_orders(p_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_plan_parter_station FOREIGN KEY (station_id) REFERENCES workstations(station_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDERS
-- ================================================
CREATE INDEX idx_prod_orders_stock ON production_orders(stock_id);
CREATE INDEX idx_prod_orders_order ON production_orders(order_id);
CREATE INDEX idx_prod_orders_order_row ON production_orders(order_row_id);
CREATE INDEX idx_prod_orders_station ON production_orders(station_id);
CREATE INDEX idx_prod_orders_status ON production_orders(status);
CREATE INDEX idx_prod_orders_stage ON production_orders(prod_order_stage);
CREATE INDEX idx_prod_orders_lot ON production_orders(lot_no);
CREATE INDEX idx_prod_orders_date ON production_orders(start_date);
CREATE INDEX idx_prod_orders_spect ON production_orders(spect_var_id);
CREATE INDEX idx_prod_orders_wrk ON production_orders(wrk_row_id);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDERS_ROW
-- ================================================
CREATE INDEX idx_prod_orders_row_prod ON production_orders_row(p_order_id);
CREATE INDEX idx_prod_orders_row_order ON production_orders_row(order_id);
CREATE INDEX idx_prod_orders_row_order_row ON production_orders_row(order_row_id);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDERS_STOCKS
-- ================================================
CREATE INDEX idx_prod_orders_stocks_prod ON production_orders_stocks(p_order_id);
CREATE INDEX idx_prod_orders_stocks_product ON production_orders_stocks(product_id);
CREATE INDEX idx_prod_orders_stocks_stock ON production_orders_stocks(stock_id);
CREATE INDEX idx_prod_orders_stocks_lot ON production_orders_stocks(lot_no);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_OPERATION
-- ================================================
CREATE INDEX idx_prod_operation_order ON production_operation(p_order_id);
CREATE INDEX idx_prod_operation_station ON production_operation(station_id);
CREATE INDEX idx_prod_operation_type ON production_operation(operation_type_id);
CREATE INDEX idx_prod_operation_stage ON production_operation(stage);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_OPERATION_RESULT
-- ================================================
CREATE INDEX idx_prod_op_result_order ON production_operation_result(p_order_id);
CREATE INDEX idx_prod_op_result_operation ON production_operation_result(operation_id);
CREATE INDEX idx_prod_op_result_station ON production_operation_result(station_id);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDER_OPERATIONS
-- ================================================
CREATE INDEX idx_prod_order_ops_order ON production_order_operations(p_order_id);
CREATE INDEX idx_prod_order_ops_employee ON production_order_operations(employee_id);
CREATE INDEX idx_prod_order_ops_date ON production_order_operations(operation_date);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDER_OPERATIONS_EMPLOYEE
-- ================================================
CREATE INDEX idx_prod_order_ops_emp_operation ON production_order_operations_employee(operation_id);
CREATE INDEX idx_prod_order_ops_emp_employee ON production_order_operations_employee(employee_id);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDER_OPERATIONS_PRODUCT
-- ================================================
CREATE INDEX idx_prod_order_ops_prod_order ON production_order_operations_product(p_order_id);
CREATE INDEX idx_prod_order_ops_prod_product ON production_order_operations_product(product_id);
CREATE INDEX idx_prod_order_ops_prod_stock ON production_order_operations_product(stock_id);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDER_RESULTS
-- ================================================
CREATE INDEX idx_prod_order_results_order ON production_order_results(p_order_id);
CREATE INDEX idx_prod_order_results_station ON production_order_results(station_id);
CREATE INDEX idx_prod_order_results_lot ON production_order_results(lot_no);
CREATE INDEX idx_prod_order_results_company ON production_order_results(company_id);
CREATE INDEX idx_prod_order_results_date ON production_order_results(start_date);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_ORDER_RESULTS_ROW
-- ================================================
CREATE INDEX idx_prod_order_results_row_result ON production_order_results_row(pr_order_id);
CREATE INDEX idx_prod_order_results_row_stock ON production_order_results_row(stock_id);
CREATE INDEX idx_prod_order_results_row_product ON production_order_results_row(product_id);
CREATE INDEX idx_prod_order_results_row_lot ON production_order_results_row(lot_no);

-- ================================================
-- İndeksler / Indexes - PRODUCTION_PLAN_PARTER
-- ================================================
CREATE INDEX idx_prod_plan_parter_order ON production_plan_parter(p_order_id);
CREATE INDEX idx_prod_plan_parter_station ON production_plan_parter(station_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================

COMMENT ON TABLE production_orders IS 'Üretim emirleri - sipariş ve ağaç ile entegre';
COMMENT ON TABLE production_orders_row IS 'Üretim emri satırları - sipariş satırları ilişkisi';
COMMENT ON TABLE production_orders_stocks IS 'Üretim emrinde kullanılacak stoklar/hammaddeler';
COMMENT ON TABLE production_operation IS 'Üretim operasyonları ve süreleri';
COMMENT ON TABLE production_operation_result IS 'Operasyon sonuçları (gerçekleşen miktar/süre)';
COMMENT ON TABLE production_operation_result_main IS 'Parti bazlı operasyon sonuçları';
COMMENT ON TABLE production_order_operations IS 'Üretim emri işlemleri (başlat/durdur/bitir)';
COMMENT ON TABLE production_order_operations_employee IS 'Operasyonda çalışan personeller';
COMMENT ON TABLE production_order_operations_product IS 'Operasyonda kullanılan/üretilen ürünler';
COMMENT ON TABLE production_order_results IS 'Üretim emri sonuçları/tamamlanma';
COMMENT ON TABLE production_order_results_main IS 'Ana üretim sonuç kayıtları (parti bazlı)';
COMMENT ON TABLE production_order_results_row IS 'Üretim sonuç detay satırları';
COMMENT ON TABLE production_plan_parter IS 'Üretim planı - istasyon ilişkisi';

COMMENT ON COLUMN production_orders.p_order_no IS 'Üretim emri numarası';
COMMENT ON COLUMN production_orders.lot_no IS 'Lot/Parti numarası';
COMMENT ON COLUMN production_orders.is_urgent IS 'Acil/öncelikli üretim';
COMMENT ON COLUMN production_orders.prod_order_stage IS 'Üretim aşaması (0:Yeni, 1:Planlı, 2:Başladı, 3:Devam, 4:Tamamlandı)';
COMMENT ON COLUMN production_operation.o_minute IS 'Operasyon süresi (dakika)';
COMMENT ON COLUMN production_operation.o_setup_time IS 'Hazırlık süresi (dakika)';
COMMENT ON COLUMN production_operation_result.real_amount IS 'Gerçekleşen miktar';
COMMENT ON COLUMN production_operation_result.loss_amount IS 'Fire miktarı';
COMMENT ON COLUMN production_orders_stocks.is_phantom IS 'Hayalet ürün (stoktan düşülmez)';
COMMENT ON COLUMN production_order_results_row.tree_type IS 'Ağaç tipi (S: Standart)';
