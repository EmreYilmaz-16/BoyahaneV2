-- Company and Partner Management Tables for PostgreSQL

-- COMPANY_CAT Table (firma kategorileri)
CREATE TABLE IF NOT EXISTS company_cat (
    companycat_id SERIAL PRIMARY KEY,
    companycat VARCHAR(43),
    detail VARCHAR(100),
    is_active BOOLEAN,
    companycat_type BOOLEAN,
    is_view BOOLEAN,
    record_emp INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50)
);

-- COMPANY Table (firmalar)
CREATE TABLE IF NOT EXISTS company (
    company_id SERIAL PRIMARY KEY,
    company_status BOOLEAN NOT NULL DEFAULT true,
    companycat_id INTEGER NOT NULL DEFAULT 0,
    member_code VARCHAR(50),
    partner_id INTEGER,
    discount INTEGER DEFAULT 0,
    manager_partner_id INTEGER,
    nickname VARCHAR(150),
    fullname VARCHAR(250),
    taxoffice VARCHAR(50),
    taxno VARCHAR(43),
    company_email VARCHAR(100),
    homepage VARCHAR(50),
    company_telcode VARCHAR(43),
    company_tel1 VARCHAR(43),
    company_tel2 VARCHAR(43),
    company_tel3 VARCHAR(43),
    company_fax VARCHAR(43),
    mobil_code VARCHAR(43),
    mobiltel VARCHAR(43),
    company_postcode VARCHAR(43),
    company_address VARCHAR(200),
    dukkan_no VARCHAR(50),
    main_street VARCHAR(50),
    street VARCHAR(50),
    district_id INTEGER,
    semt VARCHAR(50),
    county INTEGER,
    city INTEGER,
    country INTEGER,
    ispotantial BOOLEAN DEFAULT false,
    is_buyer BOOLEAN DEFAULT false,
    is_seller BOOLEAN DEFAULT false,
    ozel_kod VARCHAR(75),
    ozel_kod_1 VARCHAR(75),
    ozel_kod_2 VARCHAR(75),
    company_fax_code VARCHAR(43),
    ref_no VARCHAR(50),
    is_related_company BOOLEAN DEFAULT false,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    is_person BOOLEAN DEFAULT false,
    CONSTRAINT fk_company_cat FOREIGN KEY (companycat_id) REFERENCES company_cat(companycat_id)
);

-- COMPANY_BRANCH Table (firma şubeleri)
CREATE TABLE IF NOT EXISTS company_branch (
    compbranch_id SERIAL PRIMARY KEY,
    compbranch_status BOOLEAN DEFAULT false,
    company_id INTEGER NOT NULL,
    emp_id INTEGER,
    pos_code INTEGER,
    partner_id INTEGER,
    compbranch__name VARCHAR(50),
    compbranch__nickname VARCHAR(100),
    compbranch_code VARCHAR(50),
    compbranch_alias VARCHAR(100),
    compbranch_email VARCHAR(100),
    compbranch_telcode VARCHAR(43),
    compbranch_tel1 VARCHAR(43),
    compbranch_tel2 VARCHAR(43),
    compbranch_tel3 VARCHAR(43),
    compbranch_fax VARCHAR(43),
    homepage VARCHAR(50),
    compbranch_address VARCHAR(250),
    compbranch_postcode VARCHAR(43),
    semt VARCHAR(50),
    county_id INTEGER,
    city_id INTEGER,
    country_id INTEGER,
    member_type INTEGER,
    branch_id INTEGER,
    zone_id INTEGER,
    manager_partner_id INTEGER,
    record_member INTEGER,
    record_par INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_ip VARCHAR(50),
    update_par INTEGER,
    update_date TIMESTAMP,
    update_ip VARCHAR(50),
    update_member INTEGER,
    is_ship_address BOOLEAN,
    is_invoice_address BOOLEAN,
    coordinate_1 VARCHAR(43),
    coordinate_2 VARCHAR(43),
    compbranch_mobil_code VARCHAR(43),
    compbranch_mobiltel VARCHAR(43),
    sz_id INTEGER,
    CONSTRAINT fk_branch_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE CASCADE
);

-- COMPANY_PARTNER Table (firma yetkilileri)
CREATE TABLE IF NOT EXISTS company_partner (
    partner_id SERIAL PRIMARY KEY,
    company_partner_status BOOLEAN DEFAULT true,
    company_id INTEGER,
    company_partner_username VARCHAR(50),
    company_partner_password VARCHAR(300),
    time_zone INTEGER DEFAULT 0,
    member_code VARCHAR(50),
    is_agenda_open BOOLEAN DEFAULT true,
    language_id VARCHAR(43),
    design_id INTEGER,
    compbranch_id INTEGER,
    company_partner_name VARCHAR(50),
    company_partner_surname VARCHAR(50),
    company_partner_email VARCHAR(100),
    imcat_id INTEGER,
    im VARCHAR(50),
    imcat2_id INTEGER,
    im2 VARCHAR(50),
    mobil_code VARCHAR(43),
    mobiltel VARCHAR(43),
    company_partner_telcode VARCHAR(43),
    company_partner_tel VARCHAR(43),
    company_partner_tel_ext VARCHAR(43),
    company_partner_fax VARCHAR(43),
    company_partner_address VARCHAR(200),
    company_partner_postcode VARCHAR(43),
    homepage VARCHAR(50),
    photo VARCHAR(50),
    member_type INTEGER,
    sex INTEGER,
    _partner_card_no VARCHAR(43),
    title VARCHAR(50),
    mission INTEGER,
    department INTEGER,
    want_email BOOLEAN DEFAULT true,
    assistance_status INTEGER,
    depot_relation INTEGER,
    graduate_year INTEGER,
    is_sms INTEGER,
    is_university INTEGER,
    mail VARCHAR(50),
    number_of_child VARCHAR(50),
    purchase_authority INTEGER,
    county INTEGER,
    city INTEGER,
    country INTEGER,
    semt VARCHAR(50),
    is_hamsis BOOLEAN,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_par INTEGER,
    record_member INTEGER,
    record_ip VARCHAR(50),
    update_par INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_member INTEGER,
    update_member_type INTEGER,
    cp_status_id INTEGER,
    photo_server_id INTEGER,
    tc_identity VARCHAR(43),
    last_password_change TIMESTAMP,
    is_send_finance_mail BOOLEAN,
    start_date TIMESTAMP,
    finish_date TIMESTAMP,
    hierarchy_partner_id INTEGER,
    related_consumer_id INTEGER,
    web_user_key VARCHAR(40),
    birthdate TIMESTAMP,
    want_sms BOOLEAN DEFAULT true,
    pdks_number VARCHAR(50),
    pdks_type_id INTEGER,
    district_id INTEGER,
    is_send_earchive_mail BOOLEAN,
    partner_kep_adress VARCHAR(250),
    resource_id INTEGER,
    want_call BOOLEAN,
    CONSTRAINT fk_partner_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_partner_branch FOREIGN KEY (compbranch_id) REFERENCES company_branch(compbranch_id)
);

-- SHIP_METHOD Table (sevkiyat yöntemleri)
CREATE TABLE IF NOT EXISTS ship_method (
    ship_method_id SERIAL PRIMARY KEY,
    ship_method VARCHAR(50) NOT NULL,
    calculate VARCHAR(250),
    ship_day VARCHAR(43),
    ship_hour VARCHAR(43),
    is_opposite BOOLEAN,
    is_internet BOOLEAN,
    record_ip VARCHAR(50),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    update_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP
);

-- SETUP_PAYMETHOD Table (ödeme yöntemleri)
CREATE TABLE IF NOT EXISTS setup_paymethod (
    paymethod_id SERIAL PRIMARY KEY,
    paymethod VARCHAR(100) NOT NULL,
    detail TEXT,
    in_advance INTEGER,
    due_date_rate NUMERIC(10,2),
    due_day INTEGER,
    due_month INTEGER,
    compound_rate INTEGER,
    financial_compound_rate BOOLEAN,
    balanced_payment BOOLEAN,
    no_compound_rate BOOLEAN,
    payment_vehicle INTEGER,
    money VARCHAR(43),
    first_interest_rate NUMERIC(10,2),
    delay_interest_day INTEGER,
    delay_interest_rate NUMERIC(10,2),
    due_start_day INTEGER,
    paymethod_status BOOLEAN,
    due_start_month INTEGER,
    is_partner BOOLEAN,
    is_public BOOLEAN,
    bank_id INTEGER,
    is_due_endofmonth BOOLEAN DEFAULT false,
    payment_means_code VARCHAR(50),
    payment_means_code_name VARCHAR(150),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    is_date_control BOOLEAN,
    next_day INTEGER,
    is_business_due_day BOOLEAN,
    is_due_beginofmonth BOOLEAN
);

-- COMPANY_CREDIT Table (firma kredi/risk limitleri)
CREATE TABLE IF NOT EXISTS company_credit (
    company_credit_id SERIAL PRIMARY KEY,
    process_stage INTEGER,
    company_id INTEGER,
    consumer_id INTEGER,
    open_account_risk_limit NUMERIC(18,2),
    open_account_risk_limit_other NUMERIC(18,2),
    forward_sale_limit NUMERIC(18,2),
    forward_sale_limit_other NUMERIC(18,2),
    total_risk_limit NUMERIC(18,2),
    total_risk_limit_other NUMERIC(18,2),
    money VARCHAR(50),
    paymethod_id INTEGER,
    due_datex INTEGER,
    first_payment_interest NUMERIC(10,2),
    last_payment_interest NUMERIC(10,2),
    payment_blokaj NUMERIC(10,2),
    payment_blokaj_type INTEGER,
    document_type INTEGER,
    option_status INTEGER,
    branch_id INTEGER,
    ship_method_id INTEGER,
    price_cat INTEGER,
    revmethod_id INTEGER,
    is_instalment_info BOOLEAN,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_par INTEGER,
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    transport_comp_id INTEGER,
    transport_deliver_id INTEGER,
    is_blacklist BOOLEAN,
    blacklist_info INTEGER,
    blacklist_date TIMESTAMP,
    card_revmethod_id INTEGER,
    card_paymethod_id INTEGER,
    payment_rate_type INTEGER,
    price_cat_purchase INTEGER,
    CONSTRAINT fk_credit_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_credit_paymethod FOREIGN KEY (paymethod_id) REFERENCES setup_paymethod(paymethod_id),
    CONSTRAINT fk_credit_shipmethod FOREIGN KEY (ship_method_id) REFERENCES ship_method(ship_method_id)
);

-- İndeksler
CREATE INDEX idx_company_cat_active ON company_cat(is_active);
CREATE INDEX idx_company_status ON company(company_status);
CREATE INDEX idx_company_cat_id ON company(companycat_id);
CREATE INDEX idx_company_taxno ON company(taxno);
CREATE INDEX idx_company_buyer ON company(is_buyer);
CREATE INDEX idx_company_seller ON company(is_seller);
CREATE INDEX idx_company_branch_company ON company_branch(company_id);
CREATE INDEX idx_company_branch_status ON company_branch(compbranch_status);
CREATE INDEX idx_company_partner_company ON company_partner(company_id);
CREATE INDEX idx_company_partner_username ON company_partner(company_partner_username);
CREATE INDEX idx_company_partner_email ON company_partner(company_partner_email);
CREATE INDEX idx_company_credit_company ON company_credit(company_id);
CREATE INDEX idx_company_credit_blacklist ON company_credit(is_blacklist);

-- Yorum satırları
COMMENT ON TABLE company_cat IS 'Firma kategorileri';
COMMENT ON TABLE company IS 'Firma/Müşteri/Tedarikçi bilgileri';
COMMENT ON TABLE company_branch IS 'Firma şubeleri';
COMMENT ON TABLE company_partner IS 'Firma yetkilileri/çalışanları';
COMMENT ON TABLE ship_method IS 'Sevkiyat yöntemleri';
COMMENT ON TABLE setup_paymethod IS 'Ödeme yöntemleri';
COMMENT ON TABLE company_credit IS 'Firma kredi ve risk limit bilgileri';

COMMENT ON COLUMN company.is_buyer IS 'Müşteri mi?';
COMMENT ON COLUMN company.is_seller IS 'Tedarikçi mi?';
COMMENT ON COLUMN company.is_person IS 'Gerçek kişi mi?';
COMMENT ON COLUMN company.taxno IS 'Vergi numarası';
COMMENT ON COLUMN company_credit.open_account_risk_limit IS 'Açık hesap risk limiti';
COMMENT ON COLUMN company_credit.is_blacklist IS 'Kara listede mi?';
