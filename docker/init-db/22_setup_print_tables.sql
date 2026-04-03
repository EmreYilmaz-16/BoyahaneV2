CREATE TABLE IF NOT EXISTS SETUP_PRINT_FILES_CATS (
    PRINT_CAT_ID        SERIAL NOT NULL,
    PRINT_MODULE_ID     INTEGER NULL,
    PRINT_NAME          VARCHAR(250) NULL,
    PRINT_NAME_ENG      VARCHAR(250) NULL,
    PRINT_TYPE          INTEGER NULL,
    PRINT_MODULE_NAME   VARCHAR(100) NULL,
    PRINT_DICTIONARY_ID INTEGER NULL,
    CONSTRAINT PK_SETUP_PRINT_FILES_CATS_PRINT_CAT_ID PRIMARY KEY (PRINT_CAT_ID)
);

CREATE TABLE IF NOT EXISTS SETUP_PRINT_FILES (
    FORM_ID                 SERIAL NOT NULL,
    PROCESS_TYPE            INTEGER NULL,
    MODULE_ID               INTEGER NULL,
    ACTIVE                  BOOLEAN NOT NULL DEFAULT FALSE,
    NAME                    VARCHAR(100) NOT NULL,
    TEMPLATE_FILE           VARCHAR(250) NULL,
    DETAIL                  VARCHAR(200) NULL,
    IS_DEFAULT              BOOLEAN NULL,
    TEMPLATE_FILE_SERVER_ID INTEGER NULL,
    IS_STANDART             BOOLEAN NULL,
    IS_PARTNER              BOOLEAN NULL,
    IS_XML                  BOOLEAN NOT NULL DEFAULT FALSE,
    IMAGE_FILE              VARCHAR(250) NULL,
    IMAGE_FILE_SERVER_ID    INTEGER NULL,
    RECORD_DATE             TIMESTAMP NULL,
    RECORD_IP               VARCHAR(50) NULL,
    RECORD_EMP              INTEGER NULL,
    UPDATE_DATE             TIMESTAMP NULL,
    UPDATE_EMP              INTEGER NULL,
    UPDATE_IP               VARCHAR(50) NULL,
    CONTROLLER_NAME         VARCHAR(250) NULL,
    JSON                    TEXT NULL,
    CONSTRAINT PK_SETUP_PRINT_FILES_FORM_ID PRIMARY KEY (FORM_ID)
);

-- Yazdırma kategorileri (process_type karşılıkları)
INSERT INTO SETUP_PRINT_FILES_CATS (PRINT_MODULE_ID, PRINT_NAME, PRINT_NAME_ENG, PRINT_TYPE, PRINT_MODULE_NAME)
VALUES
    (1,  'Stok Giriş Fişi',    'Stock Entry Slip',       1, 'stock'),
    (2,  'Stok Çıkış Fişi',   'Stock Exit Slip',        2, 'stock'),
    (3,  'Stok Transfer Fişi', 'Stock Transfer Slip',    3, 'stock'),
    (4,  'Stok Sayım Fişi',    'Stock Count Slip',       4, 'stock'),
    (5,  'Sipariş Fişi',       'Order Slip',             5, 'order'),
    (6,  'Üretim Emri',        'Production Order',       6, 'production')
ON CONFLICT DO NOTHING;
