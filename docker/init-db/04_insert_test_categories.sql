-- Test kategorileri ekle
INSERT INTO product_cat (hierarchy, product_cat, detail, record_date, record_emp_ip) VALUES
('01', 'Hammaddeler', 'Üretimde kullanılan hammaddeler', NOW(), '127.0.0.1'),
('01.01', 'İplik', 'Çeşitli iplik türleri', NOW(), '127.0.0.1'),
('01.02', 'Kumaş', 'Ham kumaş çeşitleri', NOW(), '127.0.0.1'),
('02', 'Kimyasallar', 'Boyama ve yıkama kimyasalları', NOW(), '127.0.0.1'),
('02.01', 'Boya Maddeleri', 'Reaktif, dispersiyon, asit boyalar', NOW(), '127.0.0.1'),
('02.02', 'Yardımcı Kimyasallar', 'Yumuşatıcı, fikse maddesi vb.', NOW(), '127.0.0.1'),
('03', 'Makineler', 'Üretim makineleri ve ekipmanlar', NOW(), '127.0.0.1'),
('03.01', 'Boya Makineleri', 'Jet boya, çarmıh vb.', NOW(), '127.0.0.1'),
('03.02', 'Ram Makineleri', 'Kurutma ve fixe makineleri', NOW(), '127.0.0.1'),
('04', 'Yedek Parça', 'Makine yedek parçaları', NOW(), '127.0.0.1');
