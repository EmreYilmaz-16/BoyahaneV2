-- ================================================
-- ORDER TABLES (Sipariş Tabloları)
-- ================================================
-- ORDERS: Ana sipariş tablosu
-- ORDER_ROW: Sipariş satırları (ürün detayları)
-- ORDER_ROW_RESERVED: Sipariş rezervasyonları
-- ================================================

-- ================================================
-- ORDERS TABLE (Ana Sipariş Tablosu)
-- ================================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    
    -- Temel Bilgiler / Basic Info
    wrk_id VARCHAR(43),
    order_head VARCHAR(200),
    order_detail TEXT,
    order_number VARCHAR(250) NOT NULL,
    order_date TIMESTAMP WITHOUT TIME ZONE,
    order_currency INTEGER,
    order_stage INTEGER,
    commethod_id INTEGER,
    order_status BOOLEAN DEFAULT false,
    order_zone BOOLEAN DEFAULT false,
    purchase_sales BOOLEAN,
    
    -- İlgili Taraflar / Related Parties
    company_id INTEGER,
    partner_id INTEGER,
    employee_id INTEGER,
    consumer_id INTEGER,
    ref_company_id INTEGER,
    ref_partner_id INTEGER,
    ref_consumer_id INTEGER,
    offer_id INTEGER,
    sales_partner_id INTEGER,
    sales_consumer_id INTEGER,
    order_employee_id INTEGER,
    
    -- Öncelik ve İş / Priority & Work
    priority_id INTEGER,
    is_work INTEGER DEFAULT 0,
    is_processed BOOLEAN DEFAULT false,
    included_kdv BOOLEAN,
    member_type INTEGER,
    invisible BOOLEAN DEFAULT false,
    ship_method INTEGER,
    reserved BOOLEAN,
    work_id INTEGER,
    project_id INTEGER,
    
    -- Tarihler / Dates
    startdate TIMESTAMP WITHOUT TIME ZONE,
    finishdate TIMESTAMP WITHOUT TIME ZONE,
    deliverdate TIMESTAMP WITHOUT TIME ZONE,
    
    -- Tutarlar / Amounts
    discounttotal NUMERIC(18,6),
    grosstotal NUMERIC(18,6),
    tax NUMERIC(18,6),
    nettotal NUMERIC(18,6),
    otv_total NUMERIC(18,6),
    taxtotal NUMERIC(18,6) DEFAULT 0,
    
    -- Döviz ve Ödeme / Currency & Payment
    other_money VARCHAR(43),
    other_money_value NUMERIC(18,6),
    paymethod INTEGER,
    pay_formul TEXT,
    publishdate TIMESTAMP WITHOUT TIME ZONE,
    
    -- Teslimat / Delivery
    deliver_dept_id INTEGER,
    location_id INTEGER,
    catalog_id INTEGER,
    is_viewed_p TEXT,
    ship_date TIMESTAMP WITHOUT TIME ZONE,
    internaldemand_id INTEGER,
    ship_address VARCHAR(500),
    city_id INTEGER,
    county_id INTEGER,
    district_id INTEGER,
    due_date TIMESTAMP WITHOUT TIME ZONE,
    ref_no VARCHAR(100),
    
    -- İndirim ve Promosyon / Discount & Promotion
    sa_discount NUMERIC(18,6) DEFAULT 0,
    general_prom_id INTEGER,
    general_prom_limit INTEGER,
    general_prom_discount NUMERIC(18,6),
    general_prom_amount NUMERIC(18,6),
    
    -- Bedava Promosyon / Free Promotion
    free_prom_id INTEGER,
    free_prom_limit INTEGER,
    free_prom_amount NUMERIC(18,6),
    free_prom_stock_id INTEGER,
    free_stock_price NUMERIC(18,6),
    free_stock_money VARCHAR(43),
    free_prom_cost NUMERIC(18,6),
    
    -- Kredi Kartı / Credit Card
    card_paymethod_id INTEGER,
    card_paymethod_rate NUMERIC(18,6),
    
    -- Durum Bilgileri / Status Info
    is_paid BOOLEAN DEFAULT false,
    is_produced BOOLEAN,
    zone_id INTEGER,
    resource_id INTEGER,
    ims_code_id INTEGER,
    customer_value_id INTEGER,
    sales_add_option_id INTEGER,
    print_count INTEGER,
    is_enduser_price BOOLEAN DEFAULT false,
    campaign_id INTEGER,
    add_flag INTEGER,
    is_instalment BOOLEAN,
    
    -- İptal Bilgileri / Cancellation Info
    cancel_type_id INTEGER,
    cancel_date TIMESTAMP WITHOUT TIME ZONE,
    cancel_detail VARCHAR(100),
    consumer_reference_code VARCHAR(500),
    partner_reference_code VARCHAR(250),
    
    -- İç Talep ve Web Servisi / Internal Demand & Webservice
    internaldemand_flag INTEGER,
    is_dispatch BOOLEAN DEFAULT false,
    is_send_webservice BOOLEAN DEFAULT false,
    deliver_comp_id INTEGER,
    deliver_cons_id INTEGER,
    is_member_risk BOOLEAN DEFAULT true,
    frm_branch_id INTEGER,
    subscription_id INTEGER,
    cargo_invoice_no VARCHAR(50),
    ship_address_id INTEGER,
    
    -- İptal Eden Bilgileri / Cancelled By
    cancel_con INTEGER,
    cancel_par INTEGER,
    cancel_emp INTEGER,
    
    -- Ödeme ve Kampanya / Payment & Campaign
    order_payment_value NUMERIC(18,6),
    camp_id INTEGER,
    
    -- Kayıt Bilgileri / Record Info
    record_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_par INTEGER,
    record_con INTEGER,
    
    -- Güncelleme Bilgileri / Update Info
    update_date TIMESTAMP WITHOUT TIME ZONE,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    update_par INTEGER,
    update_con INTEGER,
    
    -- Vergi Adresi / Tax Address
    tax_address_id INTEGER,
    tax_address VARCHAR(500),
    
    -- Yabancı / Foreign
    is_foreign BOOLEAN DEFAULT false,
    country_id INTEGER,
    is_received_webservice BOOLEAN DEFAULT false,
    postcode INTEGER,
    email VARCHAR(50),
    contract_id INTEGER,
    process_cat INTEGER,
    order_code VARCHAR(50),
    
    -- Foreign Keys
    CONSTRAINT fk_orders_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_currency FOREIGN KEY (order_currency) REFERENCES setup_money(money_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_ship_method FOREIGN KEY (ship_method) REFERENCES ship_method(ship_method_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_paymethod FOREIGN KEY (paymethod) REFERENCES setup_paymethod(paymethod_id) ON DELETE SET NULL
);

-- ================================================
-- ORDER_ROW TABLE (Sipariş Satırları)
-- ================================================
CREATE TABLE order_row (
    order_row_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    
    -- Ürün Bilgileri / Product Info
    stock_id INTEGER,
    product_id INTEGER,
    paymethod_id INTEGER,
    product_name VARCHAR(500),
    description VARCHAR(255),
    
    -- Miktar ve Fiyat / Quantity & Price
    duedate INTEGER,
    quantity NUMERIC(18,6),
    price NUMERIC(18,6),
    price_other NUMERIC(18,6),
    unit VARCHAR(50),
    unit_id INTEGER,
    tax NUMERIC(18,6),
    nettotal NUMERIC(18,6),
    pay_method INTEGER,
    order_row_currency INTEGER,
    
    -- Teslimat / Delivery
    deliver_date TIMESTAMP WITHOUT TIME ZONE,
    deliver_dept INTEGER,
    deliver_location INTEGER,
    
    -- 10 İndirim Alanı / 10 Discount Fields
    discount_1 NUMERIC(18,6) DEFAULT 0,
    discount_2 NUMERIC(18,6) DEFAULT 0,
    discount_3 NUMERIC(18,6) DEFAULT 0,
    discount_4 NUMERIC(18,6) DEFAULT 0,
    discount_5 NUMERIC(18,6) DEFAULT 0,
    discount_6 NUMERIC(18,6) DEFAULT 0,
    discount_7 NUMERIC(18,6) DEFAULT 0,
    discount_8 NUMERIC(18,6) DEFAULT 0,
    discount_9 NUMERIC(18,6) DEFAULT 0,
    discount_10 NUMERIC(18,6) DEFAULT 0,
    
    -- Varyant ve Döviz / Variant & Currency
    spect_var_id INTEGER,
    spect_var_name VARCHAR(500),
    other_money VARCHAR(43),
    other_money_value NUMERIC(18,6),
    lot_no VARCHAR(100),
    
    -- Maliyet / Cost
    cost_id INTEGER,
    cost_price NUMERIC(18,6),
    extra_cost NUMERIC(18,6),
    marj NUMERIC(18,6),
    prom_comission NUMERIC(18,6),
    prom_cost NUMERIC(18,6),
    discount_cost NUMERIC(18,6),
    
    -- Promosyon / Promotion
    is_promotion BOOLEAN,
    prom_id INTEGER,
    prom_stock_id INTEGER,
    is_commission BOOLEAN DEFAULT false,
    unique_relation_id VARCHAR(100),
    
    -- Ek Bilgiler / Additional Info
    product_name2 VARCHAR(500),
    extra_price_other_total NUMERIC(18,6),
    unit2 VARCHAR(50),
    extra_price NUMERIC(18,6),
    shelf_number INTEGER,
    product_manufact_code VARCHAR(100),
    row_discounttotal NUMERIC(18,6),
    extra_price_total NUMERIC(18,6),
    
    -- ÖTV / Special Consumption Tax
    otv_oran NUMERIC(18,6),
    otvtotal NUMERIC(18,6) DEFAULT 0,
    
    -- Sepet Ek Bilgisi / Basket Extra Info
    basket_extra_info_id INTEGER,
    select_info_extra INTEGER,
    detail_info_extra VARCHAR(500),
    prom_relation_id VARCHAR(100),
    
    -- Rezervasyon / Reservation
    reserve_type INTEGER,
    reserve_date TIMESTAMP WITHOUT TIME ZONE,
    price_cat INTEGER,
    catalog_id INTEGER,
    list_price NUMERIC(18,6),
    number_of_installment INTEGER,
    basket_employee_id INTEGER,
    
    -- Karma Ürün / Composite Product
    karma_product_id INTEGER,
    amount2 NUMERIC(18,6),
    ek_tutar_price NUMERIC(18,6),
    
    -- İç Talep / Internal Demand
    row_internaldemand_id INTEGER,
    related_internaldemand_row_id INTEGER,
    row_pro_material_id INTEGER,
    is_general_prom BOOLEAN,
    is_product_promotion_noneffect BOOLEAN,
    
    -- WRK İlişkileri / WRK Relations
    wrk_row_id VARCHAR(40),
    wrk_row_relation_id VARCHAR(40),
    related_action_id INTEGER,
    related_action_table VARCHAR(43),
    
    -- Boyutlar / Dimensions
    depth_value NUMERIC(18,6),
    width_value NUMERIC(18,6),
    height_value NUMERIC(18,6),
    
    -- Proje ve İptal / Project & Cancellation
    row_project_id INTEGER,
    cancel_type_id INTEGER,
    cancel_amount NUMERIC(18,6) DEFAULT 0,
    deliver_amount NUMERIC(18,6),
    row_work_id INTEGER,
    invoice_amount NUMERIC(18,6),
    ship_amount NUMERIC(18,6),
    
    -- Gider Merkezi / Expense Center
    expense_center_id INTEGER,
    expense_item_id INTEGER,
    activity_type_id INTEGER,
    acc_code VARCHAR(100),
    subscription_id INTEGER,
    assetp_id INTEGER,
    
    -- Vergi ve Kesintiler / Tax & Deductions
    bsmv_rate NUMERIC(18,6),
    bsmv_amount NUMERIC(18,6),
    bsmv_currency NUMERIC(18,6),
    oiv_rate NUMERIC(18,6),
    oiv_amount NUMERIC(18,6),
    tevkifat_rate NUMERIC(18,6),
    tevkifat_amount NUMERIC(18,6),
    
    -- Sebep / Reason
    reason_code INTEGER,
    reason_name VARCHAR(250),
    gtip_number VARCHAR(50),
    
    -- ÖTV Detay / OTV Detail
    otv_type NUMERIC(18,6),
    otv_discount NUMERIC(18,6),
    
    -- Ağırlık ve Hacim / Weight & Volume
    specific_weight NUMERIC(18,6),
    volume NUMERIC(18,6),
    weight NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_order_row_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_row_unit FOREIGN KEY (unit_id) REFERENCES setup_unit(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_row_currency FOREIGN KEY (order_row_currency) REFERENCES setup_money(money_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_row_price_cat FOREIGN KEY (price_cat) REFERENCES price_cat(price_catid) ON DELETE SET NULL
);

-- ================================================
-- ORDER_ROW_RESERVED TABLE (Sipariş Rezervasyonları)
-- ================================================
CREATE TABLE order_row_reserved (
    row_reserved_id SERIAL PRIMARY KEY,
    
    -- Ürün Bilgileri / Product Info
    stock_id INTEGER,
    product_id INTEGER,
    spect_var_id INTEGER,
    
    -- Sipariş İlişkileri / Order Relations
    order_id INTEGER,
    order_row_id INTEGER,
    ship_id INTEGER,
    invoice_id INTEGER,
    period_id INTEGER,
    
    -- Rezervasyon Miktarları / Reservation Quantities
    reserve_stock_in NUMERIC(18,6) DEFAULT 0,
    reserve_stock_out NUMERIC(18,6) DEFAULT 0,
    reserve_cancel_amount NUMERIC(18,6) DEFAULT 0,
    stock_in NUMERIC(18,6) DEFAULT 0,
    stock_out NUMERIC(18,6) DEFAULT 0,
    
    -- Konum Bilgileri / Location Info
    department_id INTEGER,
    location_id INTEGER,
    shelf_number INTEGER,
    
    -- Diğer / Other
    pre_order_id VARCHAR(60),
    stock_strategy_id INTEGER,
    is_basket INTEGER,
    order_wrk_row_id VARCHAR(40),
    
    -- Foreign Keys
    CONSTRAINT fk_reserved_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_reserved_order_row FOREIGN KEY (order_row_id) REFERENCES order_row(order_row_id) ON DELETE CASCADE,
    CONSTRAINT fk_reserved_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_reserved_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_reserved_department FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE SET NULL
    -- Note: location_id reference removed - stocks_location.location_id is not unique
);

-- ================================================
-- İndeksler / Indexes - ORDERS
-- ================================================
CREATE INDEX idx_orders_company ON orders(company_id);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_sales ON orders(purchase_sales);
CREATE INDEX idx_orders_employee ON orders(employee_id);
CREATE INDEX idx_orders_partner ON orders(partner_id);
CREATE INDEX idx_orders_consumer ON orders(consumer_id);
CREATE INDEX idx_orders_offer ON orders(offer_id);
CREATE INDEX idx_orders_work ON orders(work_id);
CREATE INDEX idx_orders_project ON orders(project_id);
CREATE INDEX idx_orders_currency ON orders(order_currency);
CREATE INDEX idx_orders_record_date ON orders(record_date);
CREATE INDEX idx_orders_wrk_id ON orders(wrk_id);

-- ================================================
-- İndeksler / Indexes - ORDER_ROW
-- ================================================
CREATE INDEX idx_order_row_order ON order_row(order_id);
CREATE INDEX idx_order_row_stock ON order_row(stock_id);
CREATE INDEX idx_order_row_product ON order_row(product_id);
CREATE INDEX idx_order_row_deliver_date ON order_row(deliver_date);
CREATE INDEX idx_order_row_wrk_id ON order_row(wrk_row_id);
CREATE INDEX idx_order_row_price_cat ON order_row(price_cat);
CREATE INDEX idx_order_row_prom ON order_row(prom_id);
CREATE INDEX idx_order_row_unit ON order_row(unit_id);

-- ================================================
-- İndeksler / Indexes - ORDER_ROW_RESERVED
-- ================================================
CREATE INDEX idx_reserved_order ON order_row_reserved(order_id);
CREATE INDEX idx_reserved_order_row ON order_row_reserved(order_row_id);
CREATE INDEX idx_reserved_stock ON order_row_reserved(stock_id);
CREATE INDEX idx_reserved_product ON order_row_reserved(product_id);
CREATE INDEX idx_reserved_department ON order_row_reserved(department_id);
CREATE INDEX idx_reserved_location ON order_row_reserved(location_id);
CREATE INDEX idx_reserved_wrk_id ON order_row_reserved(order_wrk_row_id);

-- ================================================
-- Açıklamalar / Comments - ORDERS
-- ================================================
COMMENT ON TABLE orders IS 'Ana sipariş tablosu - alış ve satış siparişlerini tutar';
COMMENT ON COLUMN orders.order_id IS 'Birincil anahtar';
COMMENT ON COLUMN orders.order_number IS 'Sipariş numarası (benzersiz)';
COMMENT ON COLUMN orders.order_head IS 'Sipariş başlığı';
COMMENT ON COLUMN orders.order_date IS 'Sipariş tarihi';
COMMENT ON COLUMN orders.purchase_sales IS 'Sipariş tipi: true=Satış, false=Alış';
COMMENT ON COLUMN orders.order_status IS 'Sipariş durumu: true=Aktif, false=Pasif';
COMMENT ON COLUMN orders.company_id IS 'İlgili firma (COMPANY tablosu)';
COMMENT ON COLUMN orders.grosstotal IS 'Brüt toplam tutar';
COMMENT ON COLUMN orders.nettotal IS 'Net toplam tutar';
COMMENT ON COLUMN orders.taxtotal IS 'Toplam KDV tutarı';
COMMENT ON COLUMN orders.discounttotal IS 'Toplam indirim tutarı';
COMMENT ON COLUMN orders.deliverdate IS 'Teslim tarihi';
COMMENT ON COLUMN orders.is_paid IS 'Ödendi mi? true=Evet, false=Hayır';
COMMENT ON COLUMN orders.is_dispatch IS 'Sevk edildi mi?';
COMMENT ON COLUMN orders.ship_method IS 'Sevkiyat yöntemi (SHIP_METHOD tablosu)';
COMMENT ON COLUMN orders.paymethod IS 'Ödeme yöntemi (SETUP_PAYMETHOD tablosu)';

-- ================================================
-- Açıklamalar / Comments - ORDER_ROW
-- ================================================
COMMENT ON TABLE order_row IS 'Sipariş satırları - siparişin ürün detaylarını tutar';
COMMENT ON COLUMN order_row.order_row_id IS 'Birincil anahtar';
COMMENT ON COLUMN order_row.order_id IS 'Üst sipariş (ORDERS tablosu)';
COMMENT ON COLUMN order_row.stock_id IS 'Stok kartı (STOCKS tablosu)';
COMMENT ON COLUMN order_row.product_id IS 'Ürün (PRODUCT tablosu)';
COMMENT ON COLUMN order_row.quantity IS 'Miktar';
COMMENT ON COLUMN order_row.price IS 'Birim fiyat';
COMMENT ON COLUMN order_row.nettotal IS 'Net tutar (KDV dahil)';
COMMENT ON COLUMN order_row.tax IS 'KDV oranı (%)';
COMMENT ON COLUMN order_row.discount_1 IS '1. indirim oranı (%)';
COMMENT ON COLUMN order_row.discount_2 IS '2. indirim oranı (%)';
COMMENT ON COLUMN order_row.discount_3 IS '3. indirim oranı (%)';
COMMENT ON COLUMN order_row.unit_id IS 'Birim (SETUP_UNIT tablosu)';
COMMENT ON COLUMN order_row.deliver_date IS 'Satır bazında teslim tarihi';
COMMENT ON COLUMN order_row.price_cat IS 'Fiyat kategorisi (PRICE_CAT tablosu)';
COMMENT ON COLUMN order_row.is_promotion IS 'Promosyon ürünü mü?';

-- ================================================
-- Açıklamalar / Comments - ORDER_ROW_RESERVED
-- ================================================
COMMENT ON TABLE order_row_reserved IS 'Sipariş stok rezervasyonları';
COMMENT ON COLUMN order_row_reserved.row_reserved_id IS 'Birincil anahtar';
COMMENT ON COLUMN order_row_reserved.order_id IS 'İlgili sipariş (ORDERS tablosu)';
COMMENT ON COLUMN order_row_reserved.order_row_id IS 'İlgili sipariş satırı (ORDER_ROW tablosu)';
COMMENT ON COLUMN order_row_reserved.stock_id IS 'Rezerve edilen stok (STOCKS tablosu)';
COMMENT ON COLUMN order_row_reserved.reserve_stock_in IS 'Rezerve giriş miktarı';
COMMENT ON COLUMN order_row_reserved.reserve_stock_out IS 'Rezerve çıkış miktarı';
COMMENT ON COLUMN order_row_reserved.department_id IS 'Depo/Departman (DEPARTMENT tablosu)';
COMMENT ON COLUMN order_row_reserved.location_id IS 'Stok yeri (STOCKS_LOCATION tablosu)';
