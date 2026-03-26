-- ================================================
-- GENERAL_PAPERS TABLE (Belge Numaratörleri)
-- ================================================
-- Sistemdeki tüm belge tiplerinin numaratörlerini tutar
-- Her belge tipi için NO (metin) ve NUMBER (sayaç) çifti vardır
-- ================================================

CREATE TABLE general_papers (
    general_papers_id SERIAL PRIMARY KEY,
    
    -- Teklif / Offer
    offer_no VARCHAR(50),
    offer_number INTEGER,
    
    -- Sipariş / Order
    order_no VARCHAR(50),
    order_number INTEGER,
    
    -- Belge Tipi / Paper Type
    paper_type BOOLEAN,
    zone_type INTEGER DEFAULT 0,
    
    -- Kampanya / Campaign
    campaign_no VARCHAR(50),
    campaign_number INTEGER,
    
    -- Promosyon / Promotion
    promotion_no VARCHAR(50),
    promotion_number INTEGER,
    
    -- Katalog / Catalog
    catalog_no VARCHAR(50),
    catalog_number INTEGER,
    
    -- Hedef Pazar / Target Market
    target_market_no VARCHAR(50),
    target_market_number INTEGER,
    
    -- Katalog Promosyon / Catalog Promotion
    cat_prom_no VARCHAR(50),
    cat_prom_number INTEGER,
    
    -- Üretim Emri / Production Order
    prod_order_no VARCHAR(50),
    prod_order_number INTEGER,
    
    -- Destek / Support
    support_no VARCHAR(50),
    support_number INTEGER,
    
    -- Fırsat / Opportunity
    opportunity_no VARCHAR(50),
    opportunity_number INTEGER,
    
    -- Servis Başvurusu / Service Application
    service_app_no VARCHAR(50),
    service_app_number INTEGER,
    
    -- Stok Fişi / Stock Document
    stock_fis_no VARCHAR(50),
    stock_fis_number INTEGER,
    
    -- Sevk Fişi / Ship Document
    ship_fis_no VARCHAR(50),
    ship_fis_number INTEGER,
    
    -- Abonelik / Subscription
    subscription_no VARCHAR(50),
    subscription_number INTEGER,
    
    -- Üretim Sonucu / Production Result
    production_result_no VARCHAR(50),
    production_result_number INTEGER,
    
    -- Üretim Partisi / Production Lot
    production_lot_no VARCHAR(50),
    production_lot_number INTEGER,
    
    -- Kredi / Credit
    credit_no VARCHAR(50),
    credit_number INTEGER,
    
    -- Üretim Malzemesi / Production Material
    pro_material_no VARCHAR(50),
    pro_material_number INTEGER,
    
    -- İç Belge / Internal Document
    internal_no VARCHAR(50),
    internal_number INTEGER,
    
    -- Virman
    virman_no VARCHAR(50),
    virman_number INTEGER,
    
    -- Gelen Transfer / Incoming Transfer
    incoming_transfer_no VARCHAR(50),
    incoming_transfer_number INTEGER,
    
    -- Giden Transfer / Outgoing Transfer
    outgoing_transfer_no VARCHAR(50),
    outgoing_transfer_number INTEGER,
    
    -- Alış Döviz / Purchase Foreign Exchange
    purchase_doviz_no VARCHAR(50),
    purchase_doviz_number INTEGER,
    
    -- Satış Döviz / Sale Foreign Exchange
    sale_doviz_no VARCHAR(50),
    sale_doviz_number INTEGER,
    
    -- Kredi Kartı Tahsilat / Credit Card Revenue
    creditcard_revenue_no VARCHAR(50),
    creditcard_revenue_number INTEGER,
    
    -- Kredi Kartı Ödeme / Credit Card Payment
    creditcard_payment_no VARCHAR(50),
    creditcard_payment_number INTEGER,
    
    -- Cari-Cari Transfer
    cari_to_cari_no VARCHAR(50),
    cari_to_cari_number INTEGER,
    
    -- Borç Alacak / Debit Claim
    debit_claim_no VARCHAR(50),
    debit_claim_number INTEGER,
    
    -- Kasa-Kasa Transfer / Cash to Cash
    cash_to_cash_no VARCHAR(50),
    cash_to_cash_number INTEGER,
    
    -- Kasa Ödeme / Cash Payment
    cash_payment_no VARCHAR(50),
    cash_payment_number INTEGER,
    
    -- Gider Masraf / Expense Cost
    expense_cost_no VARCHAR(50),
    expense_cost_number INTEGER,
    
    -- Gelir Masraf / Income Cost
    income_cost_no VARCHAR(50),
    income_cost_number INTEGER,
    
    -- Bütçe Planı / Budget Plan
    budget_plan_no VARCHAR(50),
    budget_plan_number INTEGER,
    
    -- Yazışma / Correspondence
    correspondence_no VARCHAR(50),
    correspondence_number INTEGER,
    
    -- Satın Alma Talebi / Purchase Demand
    purchasedemand_no VARCHAR(50),
    purchasedemand_number INTEGER,
    
    -- Harcama Talebi / Expenditure Request
    expenditure_request_no VARCHAR(50),
    expenditure_request_number INTEGER,
    
    -- Kalite Kontrol / Quality Control
    quality_control_no VARCHAR(50),
    quality_control_number INTEGER,
    
    -- Üretim Kalite Kontrol / Production Quality Control
    production_quality_control_no VARCHAR(50),
    production_quality_control_number INTEGER,
    
    -- Kredi Kartı Borç Ödeme / Credit Card Debit Payment
    creditcard_debit_payment_no VARCHAR(50),
    creditcard_debit_payment_number INTEGER,
    
    -- Teminat Fonu / Secure Fund
    securefund_no VARCHAR(50),
    securefund_number INTEGER,
    
    -- Kredi Tahsilat / Credit Revenue
    credit_revenue_no VARCHAR(50),
    credit_revenue_number INTEGER,
    
    -- Kredi Ödeme / Credit Payment
    credit_payment_no VARCHAR(50),
    credit_payment_number INTEGER,
    
    -- Kredi Kartı Banka İşlemi / Credit Card Bank Action
    creditcard_cc_bank_action_no VARCHAR(50),
    creditcard_cc_bank_action_number INTEGER,
    
    -- Menkul Kıymet Alım / Buying Securities
    buying_securities_no VARCHAR(50),
    buying_securities_number INTEGER,
    
    -- Menkul Kıymet Satış / Securities Sale
    securities_sale_no VARCHAR(50),
    securities_sale_number INTEGER,
    
    -- Tahakkuk Planı / Accrual Plan
    tahakkuk_plan_no VARCHAR(40),
    tahakkuk_plan_number INTEGER,
    
    -- Sistem Belgesi / System Paper
    system_paper_no VARCHAR(50),
    system_paper_number INTEGER,
    
    -- Makbuz / Receipt
    receipt_no VARCHAR(50),
    receipt_number INTEGER,
    
    -- Seyahat Talebi / Travel Demand
    travel_demand_no VARCHAR(40) DEFAULT 'STN',
    travel_demand_number INTEGER DEFAULT 0,
    
    -- MKDAD
    mkdad_no VARCHAR(40),
    mkdad_number INTEGER,
    
    -- Bütçe Transfer Talebi / Budget Transfer Demand
    budget_transfer_demand_no VARCHAR(40) DEFAULT 'BTD',
    budget_transfer_demand_number INTEGER DEFAULT 0,
    
    -- İç Sevkiyat / Ship Internal
    ship_internal_no VARCHAR(50) DEFAULT 'SVKT',
    ship_internal_number INTEGER DEFAULT 0,
    
    -- Talep / Request
    req_number INTEGER,
    req_no VARCHAR(50),
    
    -- Üretim Partisi / Production Party
    production_party_number INTEGER,
    production_party_no VARCHAR(50),
    
    -- Atık Toplama / Waste Collection
    waste_collection_number INTEGER,
    waste_operation_no VARCHAR(50),
    
    -- Numune Analiz / Sample Analysis
    sample_analysis_number INTEGER,
    waste_collection_no VARCHAR(50),
    
    -- Atık İşlem / Waste Operation
    waste_operation_number INTEGER,
    work_number INTEGER,
    
    -- Numune Analiz / Sample Analysis
    sample_analysis_no VARCHAR(50),
    
    -- İş / Work
    work_no VARCHAR(40),
    work_head VARCHAR(50),
    
    -- Kasa Kaydı / Cash Register
    cashregister_no VARCHAR(50),
    cashregister_number INTEGER
);

-- ================================================
-- İndeksler / Indexes
-- ================================================

CREATE INDEX idx_genpapers_offer ON general_papers(offer_number);
CREATE INDEX idx_genpapers_order ON general_papers(order_number);
CREATE INDEX idx_genpapers_campaign ON general_papers(campaign_number);
CREATE INDEX idx_genpapers_ship ON general_papers(ship_fis_number);
CREATE INDEX idx_genpapers_stock ON general_papers(stock_fis_number);
CREATE INDEX idx_genpapers_production ON general_papers(prod_order_number);
CREATE INDEX idx_genpapers_zone ON general_papers(zone_type);
CREATE INDEX idx_genpapers_paper_type ON general_papers(paper_type);

-- ================================================
-- Açıklamalar / Comments
-- ================================================

COMMENT ON TABLE general_papers IS 'Tüm sistem belgelerinin numaratörlerini tutan merkezi tablo';
COMMENT ON COLUMN general_papers.general_papers_id IS 'Birincil anahtar';
COMMENT ON COLUMN general_papers.paper_type IS 'Belge tipi (true/false)';
COMMENT ON COLUMN general_papers.zone_type IS 'Bölge tipi (0: varsayılan)';
COMMENT ON COLUMN general_papers.offer_no IS 'Teklif numarası formatı (ör: TEK-2026-0001)';
COMMENT ON COLUMN general_papers.offer_number IS 'Teklif sayacı';
COMMENT ON COLUMN general_papers.order_no IS 'Sipariş numarası formatı';
COMMENT ON COLUMN general_papers.order_number IS 'Sipariş sayacı';
COMMENT ON COLUMN general_papers.ship_fis_no IS 'Sevk fişi numarası formatı';
COMMENT ON COLUMN general_papers.ship_fis_number IS 'Sevk fişi sayacı';
COMMENT ON COLUMN general_papers.stock_fis_no IS 'Stok fişi numarası formatı';
COMMENT ON COLUMN general_papers.stock_fis_number IS 'Stok fişi sayacı';
COMMENT ON COLUMN general_papers.travel_demand_no IS 'Seyahat talebi öneki (varsayılan: STN)';
COMMENT ON COLUMN general_papers.budget_transfer_demand_no IS 'Bütçe transfer talebi öneki (varsayılan: BTD)';
COMMENT ON COLUMN general_papers.ship_internal_no IS 'İç sevkiyat öneki (varsayılan: SVKT)';

-- ================================================
-- Örnek Başlangıç Kaydı / Sample Initial Record
-- ================================================

INSERT INTO general_papers (
    zone_type,
    offer_no, offer_number,
    order_no, order_number,
    ship_fis_no, ship_fis_number,
    stock_fis_no, stock_fis_number,
    campaign_no, campaign_number,
    prod_order_no, prod_order_number
) VALUES (
    0,
    'TEK', 0,
    'SIP', 0,
    'SVK', 0,
    'STK', 0,
    'KMP', 0,
    'URE', 0
);
