-- Money and Currency Tables for PostgreSQL

-- SETUP_MONEY Table (Para birimi tanımları ve kurları)
CREATE TABLE IF NOT EXISTS setup_money (
    money_id SERIAL PRIMARY KEY,
    money VARCHAR(43),
    rate1 NUMERIC(18,6),
    rate2 NUMERIC(18,6),
    money_status BOOLEAN DEFAULT true,
    period_id INTEGER,
    company_id INTEGER,
    account_950 VARCHAR(50),
    per_account VARCHAR(50),
    rate3 NUMERIC(18,6),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    ratepp2 NUMERIC(18,6),
    ratepp3 NUMERIC(18,6),
    rateww2 NUMERIC(18,6),
    rateww3 NUMERIC(18,6),
    currency_code VARCHAR(43),
    dsp_rate_sale NUMERIC(18,6),
    dsp_rate_pur NUMERIC(18,6),
    dsp_update_date TIMESTAMP,
    effective_sale NUMERIC(18,6),
    effective_pur NUMERIC(18,6),
    money_name VARCHAR(43),
    money_symbol VARCHAR(43),
    dsp_effective_sale NUMERIC(18,6),
    dsp_effective_pur NUMERIC(18,6)
);

-- MONEY_HISTORY Table (Para birimi kur geçmişi)
CREATE TABLE IF NOT EXISTS money_history (
    money_history_id SERIAL PRIMARY KEY,
    money VARCHAR(43),
    rate1 NUMERIC(18,6),
    rate2 NUMERIC(18,6),
    rate3 NUMERIC(18,6),
    validate_date TIMESTAMP,
    validate_hour VARCHAR(43),
    validate_s_hour VARCHAR(43),
    company_id INTEGER,
    period_id INTEGER,
    ratepp2 NUMERIC(18,6),
    ratepp3 NUMERIC(18,6),
    rateww2 NUMERIC(18,6),
    rateww3 NUMERIC(18,6),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    effective_sale NUMERIC(18,6),
    effective_pur NUMERIC(18,6)
);

-- İndeksler
CREATE INDEX idx_setup_money_code ON setup_money(money);
CREATE INDEX idx_setup_money_status ON setup_money(money_status);
CREATE INDEX idx_setup_money_currency ON setup_money(currency_code);
CREATE INDEX idx_money_history_money ON money_history(money);
CREATE INDEX idx_money_history_date ON money_history(validate_date);
CREATE INDEX idx_money_history_company ON money_history(company_id);

-- Yorum satırları
COMMENT ON TABLE setup_money IS 'Para birimi tanımları ve döviz kurları';
COMMENT ON TABLE money_history IS 'Döviz kuru geçmişi';
COMMENT ON COLUMN setup_money.money IS 'Para birimi kodu (TRY, USD, EUR...)';
COMMENT ON COLUMN setup_money.money_name IS 'Para birimi adı (Türk Lirası, Dolar...)';
COMMENT ON COLUMN setup_money.money_symbol IS 'Para birimi sembolü (₺, $, €...)';
COMMENT ON COLUMN setup_money.rate1 IS 'Alış kuru';
COMMENT ON COLUMN setup_money.rate2 IS 'Satış kuru';
COMMENT ON COLUMN setup_money.rate3 IS 'Ortalama kur';
COMMENT ON COLUMN setup_money.effective_sale IS 'Efektif satış kuru';
COMMENT ON COLUMN setup_money.effective_pur IS 'Efektif alış kuru';
COMMENT ON COLUMN setup_money.money_status IS 'Para birimi durumu (true:Aktif, false:Pasif)';
COMMENT ON COLUMN money_history.validate_date IS 'Kur geçerlilik tarihi';

-- Örnek veriler (temel para birimleri)
INSERT INTO setup_money (money, money_name, money_symbol, currency_code, money_status, rate1, rate2, rate3) VALUES
('TRY', 'Türk Lirası', '₺', 'TRY', true, 1.000000, 1.000000, 1.000000),
('USD', 'Amerikan Doları', '$', 'USD', true, 32.50, 32.60, 32.55),
('EUR', 'Euro', '€', 'EUR', true, 35.20, 35.30, 35.25),
('GBP', 'İngiliz Sterlini', '£', 'GBP', true, 41.20, 41.30, 41.25)
ON CONFLICT DO NOTHING;
