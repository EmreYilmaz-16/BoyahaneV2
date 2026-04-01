-- PBS Seed Data (pbs_solution, pbs_family, pbs_module, pbs_objects)
-- Generated: 2026-04-02

-- Mevcut verileri temizle (sıralı olarak - FK kısıtları nedeniyle)
TRUNCATE TABLE pbs_objects RESTART IDENTITY CASCADE;
TRUNCATE TABLE pbs_module RESTART IDENTITY CASCADE;
TRUNCATE TABLE pbs_family RESTART IDENTITY CASCADE;
TRUNCATE TABLE pbs_solution RESTART IDENTITY CASCADE;

-- =============================================
-- 1. PBS_SOLUTION
-- =============================================
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (8, 'Depo', 'fa-download', true, 7, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (9, 'Admin', NULL, true, 1, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (11, 'Sistem', NULL, true, 2, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (12, 'Ürünler', NULL, true, 3, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (13, 'Dev', NULL, true, 4, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (14, 'Stok İşlemleri', NULL, true, 5, true);
INSERT INTO pbs_solution (solution_id, solution_name, icon, show_menu, order_no, is_active) VALUES (15, 'ERP', NULL, true, 6, true);

-- Sequence güncelle
SELECT setval('pbs_solution_solution_id_seq', (SELECT MAX(solution_id) FROM pbs_solution));

-- =============================================
-- 2. PBS_FAMILY
-- =============================================
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (8, 'Mal Giriş', 8, NULL, true, 1, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (9, 'Tanımlar', 9, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (11, 'Sistem', 11, NULL, false, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (12, 'Ürünler', 12, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (13, 'Dev', 13, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (14, 'Stok İşlemleri', 14, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (15, 'Satış Dağıtım', 15, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (16, 'Sistem Yönetimi', 11, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (17, 'Finans Muhasebe', 15, NULL, true, 0, true);
INSERT INTO pbs_family (family_id, family_name, solution_id, icon, show_menu, order_no, is_active) VALUES (18, 'Üretim', 15, NULL, true, 0, true);

-- Sequence güncelle
SELECT setval('pbs_family_family_id_seq', (SELECT MAX(family_id) FROM pbs_family));

-- =============================================
-- 3. PBS_MODULE
-- =============================================
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (12, 'Giriş İşlemleri', 8, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (13, 'Sistem Tanımları', 9, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (14, 'Myhome', 11, NULL, false, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (15, 'Ürün  Yönetimi', 12, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (16, 'Dev', 13, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (17, 'Stok Fişi', 14, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (18, 'Depo ve Alan Planlama', 15, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (19, 'Müşteri - Tedarikçi', 15, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (20, 'Sevkiyat ve Lojistik', 15, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (21, 'Genel Ayarlar', 16, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (22, 'Risk-Teminat', 17, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (23, 'Muhasebe İşlemleri', 17, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (24, 'Satış', 15, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (25, 'Fiyat Yönetimi', 15, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (26, 'Üretim Tasarımı', 18, NULL, true, 0, true);
INSERT INTO pbs_module (module_id, module_name, family_id, icon, show_menu, order_no, is_active) VALUES (27, 'Üretim Emirleri', 18, NULL, true, 5, true);

-- Sequence güncelle
SELECT setval('pbs_module_module_id_seq', (SELECT MAX(module_id) FROM pbs_module));

-- =============================================
-- 4. PBS_OBJECTS
-- =============================================
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (17, 'Parti Listesi', 12, true, 'standart', 'stock.list_parti', '/stock/display/list_parti.cfm', 1, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (18, 'İade Kategorileri', 13, true, 'standart', 'admin.list_return_cats', '/objects/display/list_return_cats.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (19, 'Boyahane', 14, false, 'standart', 'myhome.welcome', '/myhome/welcome.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (20, 'Kategoriler', 15, true, 'standart', 'product.list_product_cat', '/product/display/list_product_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (21, 'Kategori Detay', 15, false, 'standart', 'product.view_product_cat', '/product/display/view_product_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (22, 'Ürün Güncelle', 15, false, 'standart', 'product.edit_product_cat', '/product/form/edit_product_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (23, 'Kategori Sil', 15, false, 'popup', 'product.delete_product_cat', '/product/form/delete_product_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (24, 'Ürünler', 15, true, 'standart', 'product.list_product', '/product/display/list_product.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (25, 'Ürün Ekle', 15, false, 'standart', 'product.add_product', '/product/form/add_product.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (26, 'Markalar', 15, true, 'standart', 'product.list_product_brands', '/product/display/list_product_brands.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (27, 'Marka Ekle', 15, true, 'standart', 'product.add_product_brand', '/product/form/add_product_brand.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (28, 'Marka Güncelle', 15, false, 'standart', 'product.edit_product_brands', '/product/form/edit_product_brand.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (29, 'Marka Ekle Popup', 15, false, 'ajaxpage', 'product.add_product_brand_popup', '/product/form/add_product_brand_popup.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (30, 'Kategori Ekle', 15, true, 'standart', 'product.add_product_cat', '/product/form/add_product_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (31, 'Ürün Düzenle', 15, false, 'standart', 'product.edit_product', '/product/form/edit_product.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (32, 'Stok Fişleri', 17, true, 'standart', 'stock.list_stock_fis', '/stock/display/list_fis.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (33, 'Stok Fişi Ekle', 17, true, 'standart', 'stock.add_fis', '/stock/form/add_fis.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (34, 'Departmanlar', 18, true, 'standart', 'stock.list_departments', '/department/display/list_department.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (35, 'Raflar', 18, true, 'standart', 'stock.list_shelves', '/department/display/list_shelves.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (36, 'Kurumsal Hesaplar', 19, true, 'standart', 'company.list_company', '/company/display/list_company.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (37, 'Kurumsal Üye Ekle', 19, true, 'standart', 'company.add_company', '/company/form/add_company.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (38, 'Kurumsal Üye Kategorileri', 19, true, 'standart', 'company.list_company_cat', '/company/display/list_company_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (39, 'Kurumsal Üye Kategorisi Ekle', 19, true, 'standart', 'company.add_company_cat', '/company/form/add_company_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (40, 'Kurumsal Üye Güncelle', 19, false, 'standart', 'company.edit_company', '/company/form/edit_company.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (41, 'Sevk Yöntemleri', 20, true, 'standart', 'company.list_ship_method', 'company/display/list_ship_method.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (42, 'Sevk Yöntemi Ekle', 20, true, 'standart', 'company.add_ship_method', '/company/form/add_ship_method.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (43, 'Sevk Yöntemi Güncelle', 20, false, 'standart', 'company.edit_ship_method', '/company/form/edit_ship_method.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (44, 'Ödeme Yöntemleri', 21, true, 'standart', 'company.list_paymethod', '/company/display/list_paymethod.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (45, 'Ödeme Yöntemi Ekle', 21, true, 'standart', 'company.add_paymethod', '/company/form/add_paymethod.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (46, 'Ödeme Yöntemi Güncelle', 21, false, 'standart', 'company.edit_paymethod', '/company/form/edit_paymethod.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (47, 'Risk Limitleri', 22, true, 'standart', 'company.list_company_credit', '/company/display/list_company_credit.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (48, 'Risk Limiti Ekle', 22, true, 'standart', 'company.add_company_credit', '/company/form/add_company_credit.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (49, 'Riskl Limiti Güncelle', 22, false, 'standart', 'company.edit_company_credit', '/company/form/edit_company_credit.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (50, 'Para Birimleri', 23, true, 'standart', 'money.list_money', '/money/display/list_money.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (51, 'Para Birimi Ekle', 23, true, 'standart', 'money.add_money', '/money/form/add_money.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (52, 'Para Birimi Güncelle', 23, false, 'standart', 'money.edit_money', '/money/form/edit_money.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (53, 'Kurlar', 23, true, 'standart', 'money.list_money_history', '/money/display/list_money_history.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (54, 'Merkez Bankası Kurlarını Al', 23, true, 'standart', 'money.fetch_tcmb', '/money/form/fetch_tcmb.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (55, 'İrsaliyeler', 20, true, 'standart', 'ship.list_ship', '/ship/display/list_ship.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (56, 'İrsaliye Ekle', 20, true, 'standart', 'ship.add_ship', '/ship/form/add_ship.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (57, 'Sayfa Numaraları', 21, true, 'standart', 'papers.list_papers', '/papers/display/list_papers.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (58, 'Sayfa Numarası Ekle', 21, true, 'standart', 'papers.save_papers', '/papers/form/save_papers.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (59, 'Giriş Fişi Ekle', 12, true, 'standart', 'ship.add_giris_fis', '/ship/form/add_giris_fis.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (60, 'Giriş Fişleri', 12, true, 'standart', 'ship.list_giris_fis', '/ship/display/list_giris_fis.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (61, 'Siparişler', 24, true, 'standart', 'order.list_orders', '/order/display/list_orders.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (62, 'Sipariş Oluştur', 24, true, 'standart', 'order.add_order', '/order/form/add_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (63, 'Siparişi Güncelle', 24, true, 'standart', 'order.edit_order', '/order/form/add_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (64, 'Siparişi Görüntüle', 24, true, 'standart', 'order.view_order', '/order/form/add_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (65, 'Sipariş Kaydet (Query)', 24, true, 'standart', 'order.save_order', '/order/form/save_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (66, 'Sipariş Sil (Query)', 24, true, 'standart', 'order.delete_order', '/order/form/delete_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (67, 'Sipariş İptal', 24, true, 'standart', 'order.cancel_order', '/order/form/delete_order.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (68, 'Fiyat Listeleri', 25, true, 'standart', 'price.list_price_cat', '/price/display/list_price_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (69, 'Fiyat Listesi Ekle', 25, false, 'standart', 'price.add_price_cat', '/price/form/add_price_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (70, 'price.edit_price_cat', 25, false, 'standart', 'price.edit_price_cat', '/price/form/add_price_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (71, 'price.save_price_cat', 25, false, 'standart', 'price.save_price_cat', '/price/form/save_price_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (72, 'price.delete_price_cat', 25, false, 'standart', 'price.delete_price_cat', '/price/form/delete_price_cat.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (74, 'Fiyat Kalemleri', 25, false, 'standart', 'price.list_price', '/price/display/list_price.cfm', 35, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (75, 'Fiyat Satırı Kaydet', 25, false, 'standart', 'price.save_price_row', '/price/form/save_price_row.cfm', 36, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (76, 'Fiyat Satırı Sil', 25, false, 'standart', 'price.delete_price_row', '/price/form/delete_price_row.cfm', 37, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (77, 'Toplu Fiyat Güncelleme', 25, false, 'standart', 'price.bulk_price_change', '/price/form/bulk_price_change.cfm', 38, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (78, 'Fiyatları Getir (JSON)', 25, false, 'standart', 'price.get_prices', '/price/form/get_prices.cfm', 39, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (79, 'Parti Ekle', 12, false, 'standart', 'ship.add_parti', '/ship/form/add_parti.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (80, 'Parti Listesi', 12, false, 'standart', 'ship.list_partiler', '/ship/display/list_partiler.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (81, 'İş İstasyonları', 26, true, 'standart', 'production.list_workstations', '/production/display/list_workstations.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (82, 'Yeni İş İstasyonu', 26, false, 'standart', 'production.add_workstation', '/production/form/add_workstation.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (83, 'İstasyon Kaydet', 26, false, 'standart', 'production.save_workstation', '/production/form/save_workstation.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (84, 'İstasyon Sil', 26, false, 'standart', 'production.delete_workstation', '/production/form/delete_workstation.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (85, 'Operasyon Tipleri', 26, true, 'standart', 'production.list_operation_types', '/production/display/list_operation_types.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (86, 'Yeni Operasyon Tipi', 26, false, 'standart', 'production.add_operation_type', '/production/form/add_operation_type.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (87, 'Operasyon Tipi Kaydet', 26, false, 'standart', 'production.save_operation_type', '/production/form/save_operation_type.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (88, 'production.delete_operation_type', 26, false, 'standart', 'production.delete_operation_type', '/production/form/delete_operation_type.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (89, 'Ürün Ağaçları (BOM)', 26, true, 'standart', 'product.list_product_trees', 'product/display/list_product_trees.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (90, 'Ürün Ağacı Görüntüle', 26, false, 'standart', 'product.view_product_tree', '/product/display/view_product_tree.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (91, 'Ürün Ağacı Satır Kaydet', 26, false, 'standart', 'product.save_product_tree_row', '/product/form/save_product_tree_row.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (92, 'Ürün Ağacı Satır Sil', 26, false, 'standart', 'product.delete_product_tree_row', '/product/form/delete_product_tree_row.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (93, 'Renk Listesi', 26, true, 'standart', 'colors.list_colors', '/colors/display/list_colors_ajax.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (94, 'Renk Ekle / Düzenle', 26, true, 'standart', 'colors.add_color', '/colors/form/add_color_v3.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (95, 'colors.save_color', 26, false, 'standart', 'colors.save_color', '/colors/form/save_color.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (96, 'colors.delete_color', 26, false, 'standart', 'colors.delete_color', '/colors/form/delete_color.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (97, 'Ürün Ağacı (Ajax)', 26, true, 'ajaxpage', 'product.view_product_tree_ajax', '/product/display/view_product_tree_ajax.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (98, 'Ürün İmport', 15, true, 'standart', 'product.import_product', '/tools/form/import_product.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (99, 'Kategori İmport', 15, true, 'standart', 'product.import_product_cat', '/tools/form/product_cat_import.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (100, 'Marka İmport', 15, true, 'standart', 'product.import_product_brand', '/tools/form/product_brand_import.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (101, 'Ürün İmport (Kategori Kodlu)', 15, true, 'standart', 'product.import_product_with_product_cat_code', '/tools/form/import_product_hier.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (102, 'Kurumsal Üye İmport', 19, true, 'standart', 'company.import_company', '/tools/form/company_import.cfm', 0, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (103, 'Üretim Emirleri', 27, true, 'standart', 'production.list_production_orders', '/production/display/list_production_orders.cfm', 40, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (104, 'Yeni Üretim Emri', 27, false, 'standart', 'production.add_production_order', '/production/form/add_production_order.cfm', 41, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (105, 'Üretim Emri Detayı', 27, false, 'standart', 'production.view_production_order', '/production/display/view_production_order.cfm', 42, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (106, 'Üretim Emri Kaydet', 27, false, 'standart', 'production.save_production_order', '/production/form/save_production_order.cfm', 43, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (107, 'Üretim Emri Sil', 27, false, 'standart', 'production.delete_production_order', '/production/form/delete_production_order.cfm', 44, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (108, 'Üretim Emri Durum Güncelle', 27, false, 'standart', 'production.update_production_status', '/production/form/update_production_status.cfm', 45, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (109, 'Üretim Emri Sonuçlandır', 27, false, 'standart', 'production.finalize_production_order', '/production/form/finalize_production_order.cfm', 46, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (110, 'Hammadde Tüketim Güncelle', 27, false, 'standart', 'production.save_production_stock', '/production/form/save_production_stock.cfm', 47, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (112, 'Operasyonlar & Duruşlar', 27, false, 'standart', 'production.view_production_operations', 'production/display/view_production_operations.cfm', 170, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (113, 'Üretim Sonuçları', 27, false, 'standart', 'production.view_production_results', 'production/display/view_production_results.cfm', 175, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (114, 'Üretim Sonucu Kaydet', 27, false, 'ajaxpage', 'production.save_production_result', 'production/form/save_production_result.cfm', 176, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (115, 'Üretim Duruş Kaydet', 27, false, 'ajaxpage', 'production.save_production_pause', 'production/form/save_production_pause.cfm', 177, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (116, 'Duruş Tipleri', 27, true, 'standart', 'setup.list_prod_pause_types', 'setup/display/list_prod_pause_types.cfm', 200, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (117, 'Duruş Tipi Kaydet', 27, false, 'ajaxpage', 'setup.save_prod_pause_type', 'setup/form/save_prod_pause_type.cfm', 201, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (118, 'Duruş Tipi Sil', 27, false, 'ajaxpage', 'setup.delete_prod_pause_type', 'setup/form/delete_prod_pause_type.cfm', 202, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (119, 'MES Üretim Takip', 27, true, 'standart', 'production.mes', '/production/display/mes.cfm', 48, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (120, 'Duruş Kaydet', 27, false, 'standart', 'production.save_production_pause', '/production/form/save_production_pause.cfm', 49, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (124, 'Üretim Planlama', 27, true, 'standart', 'production.production_planning', '/production/display/production_planning.cfm', 55, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (125, 'Üretim Planla', 27, false, 'standart', 'production.save_plan', '/production/form/save_plan.cfm', 56, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (126, 'Emirden Plan Kaldır', 27, false, 'standart', 'production.unplan_order', '/production/form/unplan_order.cfm', 57, true);
INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES (127, 'Siparişten Üretim Emri Oluştur', 27, false, 'standart', 'production.send_order_to_production', '/production/form/send_order_to_production.cfm', 50, true);

-- Sequence güncelle
SELECT setval('pbs_objects_object_id_seq', (SELECT MAX(object_id) FROM pbs_objects));
