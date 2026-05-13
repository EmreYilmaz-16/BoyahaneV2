-- Sistem parametreleri tablosu
CREATE TABLE IF NOT EXISTS boyahane_params (
    param_id       SERIAL PRIMARY KEY,
    parametre_adi  VARCHAR(100)  NOT NULL UNIQUE,
    deger          TEXT          NOT NULL DEFAULT '',
    aciklama       VARCHAR(300)  NULL,
    record_date    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_date    TIMESTAMP     NULL
);

COMMENT ON TABLE  boyahane_params              IS 'Sistem geneli anahtar-değer parametre deposu';
COMMENT ON COLUMN boyahane_params.parametre_adi IS 'Parametre adı (benzersiz, kod içinde anahtar olarak kullanılır)';
COMMENT ON COLUMN boyahane_params.deger         IS 'Parametre değeri';
COMMENT ON COLUMN boyahane_params.aciklama      IS 'İsteğe bağlı açıklama';
