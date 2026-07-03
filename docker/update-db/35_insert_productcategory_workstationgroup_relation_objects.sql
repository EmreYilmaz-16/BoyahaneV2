INSERT INTO pbs_objects (object_id, object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active) VALUES
(169, 'Kategori - İş İstasyonu Eşleştirmeleri', 26, true, 'standart', 'production.list_productcategory_workstationgroup_relation', '/production/display/list_productcategory_workstationgroup_relation.cfm', 0, true),
(170, 'Kategori - İş İstasyonu Eşleştirme Ekle', 26, false, 'standart', 'production.add_productcategory_workstationgroup_relation', '/production/form/add_productcategory_workstationgroup_relation.cfm', 0, true),
(171, 'Kategori - İş İstasyonu Eşleştirme Kaydet', 26, false, 'standart', 'production.save_productcategory_workstationgroup_relation', '/production/form/save_productcategory_workstationgroup_relation.cfm', 0, true),
(172, 'Kategori - İş İstasyonu Eşleştirme Sil', 26, false, 'standart', 'production.delete_productcategory_workstationgroup_relation', '/production/form/delete_productcategory_workstationgroup_relation.cfm', 0, true)
ON CONFLICT (object_id) DO NOTHING;
