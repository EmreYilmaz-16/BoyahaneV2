# Asset Management Modülü (Fiziki Varlık + BT Varlıkları + Motorlu Taşıt + Zimmet)

Bu modül, Workcube içinde **tek bir merkezden varlık yaşam döngüsü yönetimi** yapmak için hazırlanmıştır.

Kapsam:
- Fiziki varlık yönetimi (demirbaş, makine, ekipman vb.)
- BT varlık yönetimi (donanım, lisans, ağ topolojisi)
- Motorlu taşıt yönetimi (yakıt, bakım, hasar, lastik, sürücü atama)
- Kategori yönetimi (hiyerarşik kategori ağacı)
- Zimmet yönetimi (personel/bölüm bazlı zimmet, iade ve belge çıktısı)

---

## 1) Kurulum

### 1.1 Veritabanı tablolarını oluşturma
Aşağıdaki migration dosyası çalıştırılmalıdır:

- `docker/update-db/22_create_asset_management_tables.sql`

Bu script aşağıdaki ana tabloları oluşturur:
- Referans: `asset_categories`, `asset_locations`
- Ana varlık: `asset_master`
- Ortak süreç: `asset_movements`, `asset_maintenance`, `asset_depreciation`
- BT özel: `it_asset_details`, `it_software_licenses`, `it_network_topology`, `it_service_logs`
- Araç özel: `vehicle_details`, `vehicle_fuel_logs`, `vehicle_service_logs`, `vehicle_accidents`, `vehicle_driver_assignments`, `vehicle_tire_logs`
- Zimmet: `asset_assignments`

### 1.2 Menü/Fuseaction kayıtları
Menü ve action kayıtları için:

- `asset/insert_pbs_objects.sql`

Bu dosya `pbs_objects` tablosuna `asset.*` fuseaction kayıtlarını ekler.

---

## 2) Modül Mimari Yaklaşımı

Modül, "**tek ana varlık + tip bazlı detay tabloları**" yaklaşımı ile tasarlanmıştır:

- Tüm varlıklar önce `asset_master` tablosunda tutulur.
- `asset_type` alanı varlığın türünü belirler:
  - `PHYSICAL`
  - `IT`
  - `VEHICLE`
- Türe özel bilgiler ilgili detay tablosunda tutulur:
  - IT için `it_asset_details`
  - Vehicle için `vehicle_details`

Bu yaklaşım;
- tekil envanter görünümü,
- ortak bakım/hareket süreçleri,
- tür bazlı genişleyebilirlik sağlar.

---

## 3) Süreç Akışları (İşleyiş)

### 3.1 Yeni varlık açılışı
1. `asset_categories` içinde kategori belirlenir.
2. `asset_locations` içinde lokasyon doğrulanır/oluşturulur.
3. `asset_master` kaydı açılır.
4. Türe göre detay tablosuna kayıt atılır:
   - IT ise `it_asset_details`
   - Araç ise `vehicle_details`

### 3.2 Atama / Devir / Lokasyon değişimi
- Varlık hareketleri `asset_movements` tablosuna yazılır.
- `movement_type` ile işlem türü izlenir (`TRANSFER`, `ASSIGN`, `RETURN`, `SCRAP`, `SELL`, `LOCATION_CHANGE`).
- Güncel konum/kullanıcı alanları `asset_master` üzerinde güncellenir.

### 3.3 Bakım yönetimi
- Planlı/plansız bakım kayıtları `asset_maintenance` tablosunda tutulur.
- `maintenance_status` ile süreç takibi yapılır (`OPEN`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`).
- İşçilik + yedek parça toplamı `total_cost` alanında otomatik hesaplanır.

### 3.4 Amortisman yönetimi
- Dönemsel amortisman `asset_depreciation` tablosunda tutulur.
- Her varlık için yıl/ay tekilliği vardır (`UNIQUE(asset_id, period_year, period_month)`).

### 3.5 BT varlık yönetimi
- Cihaz teknik özellikleri: `it_asset_details` — hostname, IP, MAC, işletim sistemi, RAM, depolama, antivirüs bitiş, uyumluluk durumu
- Lisans uyumluluğu ve maliyet: `it_software_licenses`
- Cihazlar arası bağlantı: `it_network_topology`
- **Servis & bakım logları:** `it_service_logs` — BT'ye özgü kayıt tipi; araç için `vehicle_service_logs` ile simetrik yapı

`list_it_service_logs.cfm` ekranı:
- İşlem tipleri: `REPAIR` / `SOFTWARE_UPDATE` / `FORMAT` / `COMPONENT_CHANGE` / `ANTIVIRUS` / `NETWORK_CONFIG` / `OTHER`
- Durumlar: `OPEN` / `IN_PROGRESS` / `COMPLETED` / `CANCELLED`
- Alanlar: arıza tanımı, yapılan işlem, değiştirilen parça, teknisyen, garanti kapsamı, maliyet
- DevExtreme masterDetail ile satır genişletme → arıza/çözüm/parça detayları
- Silme işlemi modaldan yapılabilir (is_warranty doğrulaması ile)

### 3.6 Motorlu taşıt yönetimi
- Araç kimlik ve yasal takip bilgileri: `vehicle_details`
  - Sigorta bitiş, muayene bitiş, egzoz bitiş tarihleri ile **renk uyarısı** (yeşil/sarı/kırmızı)
  - Plaka, şasi no, motor no, kilometre, yakıt tipi
- Yakıt tüketimi: `vehicle_fuel_logs`
- Servis/bakım: `vehicle_service_logs`
- Kaza/hasar: `vehicle_accidents`
- Sürücü atama/rotasyon: `vehicle_driver_assignments`
- Lastik değişim/rotasyon geçmişi: `vehicle_tire_logs`

`list_vehicle_operations.cfm` ekranı **5 sekme** ile organize edilmiştir:
1. **Araç Envanter** — plaka/şasi/motor + tarih uyarı rozetleri
2. **Yakıt Kayıtları** — litre, tutar, kilometre girişleri
3. **Servis/Bakım** — açıklama, maliyet, servis tarihi
4. **Kaza/Hasar** — kaza tarihi, hasar tutarı, sigorta takibi
5. **Lastik Kayıtları** — lastik tipi, konum (ön/arka/yedek), değişim kilometre

### 3.7 Kategori yönetimi
- Hiyerarşik kategori ağacı (`asset_categories`): üst kategori → alt kategoriler
- Varlık tipine göre filtreleme: `PHYSICAL`, `IT`, `VEHICLE`
- Varlık atanmış kategori silinemez; aktif/pasif durum yönetimi
- `list_categories.cfm`: özet kartlar + DevExtreme grid + modal ile düzenleme
- `save_category.cfm`: benzersiz kod kontrolü, parent-child ilişkisi
- `delete_category.cfm`: bağlı varlık/alt kategori varsa silmeyi engeller

### 3.8 Zimmet yönetimi
- Varlıkların personele veya bölüme zimmetlenmesi: `asset_assignments`
- Zimmet alanın sistemdeki kullanıcıyla (`kullanicilar`) veya serbest isimle eşleştirilebilmesi
- Bölüm seçimi `department` tablosundan yapılır; alan düzenlenebilir
- Beklenen iade tarihi ile süre takibi
- **İade akışı:** İade tarihi + iade durumu (`GOOD/DAMAGED/LOST`) → `assignment_status` otomatik güncellenir
  - `LOST` → status `LOST`
  - `DAMAGED` → status `DAMAGED`
  - `GOOD` → status `RETURNED`
- **Zimmet Belgesi:** Modaldan veya grid seçiminden tutanak çıktısı (yazdırılabilir) — imza alanları dahil
- `list_assignments.cfm`: özet kartlar (Zimmetli/İade/Kayıp/Hasarlı), filtreler (durum/tip/arama), DevExtreme grid
- `save_assignment.cfm`: INSERT/UPDATE, Lucee-safe null flag pattern
- `return_assignment.cfm`: iade tarihi + koşul kaydı, tekrar iade kontrolü

---

## 4) Menü / Fuseaction Yapısı

Aşağıdaki action kayıtları tanımlıdır:

| Fuseaction | Dosya | Menüde |
|---|---|---|
| `asset.list_assets` | `display/list_assets.cfm` | ✅ |
| `asset.add_asset` | `form/add_asset.cfm` | ❌ |
| `asset.save_asset` | `form/save_asset.cfm` | ❌ |
| `asset.delete_asset` | `form/delete_asset.cfm` | ❌ |
| `asset.list_maintenances` | `display/list_maintenances.cfm` | ✅ |
| `asset.save_maintenance` | `form/save_maintenance.cfm` | ❌ |
| `asset.list_it_licenses` | `display/list_it_licenses.cfm` | ✅ |
| `asset.save_it_license` | `form/save_it_license.cfm` | ❌ |
| `asset.list_vehicle_operations` | `display/list_vehicle_operations.cfm` | ✅ |
| `asset.save_vehicle_fuel` | `form/save_vehicle_fuel.cfm` | ❌ |
| `asset.save_vehicle_service` | `form/save_vehicle_service.cfm` | ❌ |
| `asset.save_vehicle_accident` | `form/save_vehicle_accident.cfm` | ❌ |
| `asset.save_vehicle_detail` | `form/save_vehicle_detail.cfm` | ❌ |
| `asset.save_vehicle_tire` | `form/save_vehicle_tire.cfm` | ❌ |
| `asset.list_categories` | `display/list_categories.cfm` | ✅ |
| `asset.save_category` | `form/save_category.cfm` | ❌ |
| `asset.delete_category` | `form/delete_category.cfm` | ❌ |
| `asset.list_assignments` | `display/list_assignments.cfm` | ✅ |
| `asset.save_assignment` | `form/save_assignment.cfm` | ❌ |
| `asset.return_assignment` | `form/return_assignment.cfm` | ❌ |
| `asset.list_it_service_logs` | `display/list_it_service_logs.cfm` | ✅ |
| `asset.save_it_service_log` | `form/save_it_service_log.cfm` | ❌ |

> Tüm kayıtlar `pbs_objects` tablosunda `module_id = 39` (Varlık Yönetimi) altında tanımlıdır.

---

## 5) Örnek Rapor Sorguları

### 5.1 Aktif varlık listesi
```sql
SELECT asset_id, asset_no, asset_name, asset_type, asset_status
FROM asset_master
WHERE asset_status = 'ACTIVE'
ORDER BY asset_id DESC;
```

### 5.2 Yaklaşan garanti bitişleri
```sql
SELECT asset_id, asset_name, warranty_end_date
FROM asset_master
WHERE warranty_end_date IS NOT NULL
  AND warranty_end_date <= CURRENT_DATE + INTERVAL '30 day'
ORDER BY warranty_end_date;
```

### 5.3 Lisans süresi dolan BT varlıkları
```sql
SELECT license_id, software_name, expiry_date, compliance_status
FROM it_software_licenses
WHERE expiry_date IS NOT NULL
  AND expiry_date < CURRENT_DATE
ORDER BY expiry_date DESC;
```

### 5.4 Araç yakıt tüketim analizi (toplam)
```sql
SELECT asset_id,
       SUM(liters) AS total_liters,
       SUM(amount) AS total_cost
FROM vehicle_fuel_logs
GROUP BY asset_id
ORDER BY total_cost DESC;
```

### 5.5 Aktif zimmetler
```sql
SELECT aa.assignment_id,
       am.asset_no,
       am.asset_name,
       aa.assigned_to_name,
       aa.assigned_to_title,
       aa.department_name,
       aa.assigned_date,
       aa.expected_return_date
FROM asset_assignments aa
INNER JOIN asset_master am ON am.asset_id = aa.asset_id
WHERE aa.assignment_status = 'ACTIVE'
ORDER BY aa.assigned_date DESC;
```

### 5.6 Gecikmiş zimmetler (beklenen iade tarihi geçmiş)
```sql
SELECT aa.assignment_id,
       am.asset_name,
       aa.assigned_to_name,
       aa.expected_return_date,
       CURRENT_DATE - aa.expected_return_date AS gecikme_gun
FROM asset_assignments aa
INNER JOIN asset_master am ON am.asset_id = aa.asset_id
WHERE aa.assignment_status = 'ACTIVE'
  AND aa.expected_return_date IS NOT NULL
  AND aa.expected_return_date < CURRENT_DATE
ORDER BY gecikme_gun DESC;
```

### 5.8 BT servis maliyet analizi (cihaz bazlı)
```sql
SELECT am.asset_name, am.asset_no,
       COUNT(*)              AS islem_sayisi,
       SUM(sl.service_cost)  AS toplam_maliyet,
       SUM(CASE WHEN sl.is_warranty THEN 1 ELSE 0 END) AS garantili_islem
FROM it_service_logs sl
INNER JOIN asset_master am ON am.asset_id = sl.asset_id
WHERE sl.status = 'COMPLETED'
GROUP BY am.asset_name, am.asset_no
ORDER BY toplam_maliyet DESC;
```

### 5.9 Açık BT servis kayıtları
```sql
SELECT sl.log_id, am.asset_name, sl.log_type,
       sl.problem_description, sl.technician_name, sl.log_date
FROM it_service_logs sl
INNER JOIN asset_master am ON am.asset_id = sl.asset_id
WHERE sl.status IN ('OPEN','IN_PROGRESS')
ORDER BY sl.log_date DESC;
```

### 5.10 Araç lastik değişim geçmişi
```sql
SELECT am.asset_name, vtl.log_type, vtl.tire_position,
       vtl.brand, vtl.size, vtl.km_at_change, vtl.log_date
FROM vehicle_tire_logs vtl
INNER JOIN asset_master am ON am.asset_id = vtl.asset_id
ORDER BY vtl.log_date DESC;
```

---

## 6) Geliştirme Notları

- Tablolar PostgreSQL uyumlu tasarlanmıştır.
- Birçok alanda `CHECK` kısıtı kullanılarak veri kalitesi korunur.
- `asset_master` üstünden genel envanter ekranı; alt tablolardan tür bazlı detay ekranı önerilir.
- Lucee CFML'de `null` atama için `javacast("null","")` yerine boolean null-flag pattern kullanılmalıdır:
  ```cfml
  <cfset xNull = not (isDefined("form.x") and isNumeric(form.x) and val(form.x) gt 0)>
  <cfqueryparam value="..." null="#xNull#">
  ```
- `cfquery` içinde `name` ve `result` attribute'ları birlikte kullanılırken `RETURNING` clause çalışmayabilir; sadece `name` kullanın.
- İleride şu genişletmeler eklenebilir:
  - Doküman yönetimi (ruhsat, sözleşme, garanti PDF vb.)
  - Bildirim/hatırlatma mekanizması (muayene, sigorta, lisans bitiş, gecikmiş zimmet)
  - KPI dashboard (MTBF, bakım maliyeti trendi, araç başı yakıt verimliliği, zimmet devir hızı)

---

## 7) Dosya Referansları

| Dosya | Açıklama |
|---|---|
| `tempsql3.sql` | Ana taslak SQL |
| `docker/update-db/22_create_asset_management_tables.sql` | Migration (15 tablo) |
| `asset/insert_pbs_objects.sql` | PBS object kayıtları |
| `asset/display/list_assets.cfm` | Varlık listesi + AJAX silme |
| `asset/form/add_asset.cfm` | Varlık ekleme/düzenleme formu |
| `asset/form/save_asset.cfm` | Varlık kayıt handler |
| `asset/form/delete_asset.cfm` | Varlık silme handler |
| `asset/display/list_categories.cfm` | Kategori yönetimi ekranı |
| `asset/form/save_category.cfm` | Kategori kayıt handler |
| `asset/form/delete_category.cfm` | Kategori silme handler |
| `asset/display/list_maintenances.cfm` | Bakım yönetimi ekranı |
| `asset/form/save_maintenance.cfm` | Bakım kayıt handler |
| `asset/display/list_it_licenses.cfm` | BT lisans ekranı |
| `asset/form/save_it_license.cfm` | Lisans kayıt handler |
| `asset/display/list_vehicle_operations.cfm` | Araç operasyonları (5 sekme) |
| `asset/form/save_vehicle_detail.cfm` | Araç detay UPSERT handler |
| `asset/form/save_vehicle_fuel.cfm` | Yakıt kayıt handler |
| `asset/form/save_vehicle_service.cfm` | Servis kayıt handler |
| `asset/form/save_vehicle_accident.cfm` | Kaza kayıt handler |
| `asset/form/save_vehicle_tire.cfm` | Lastik kayıt handler |
| `asset/display/list_assignments.cfm` | Zimmet yönetimi ekranı |
| `asset/form/save_assignment.cfm` | Zimmet kayıt/güncelleme handler |
| `asset/form/return_assignment.cfm` | Zimmet iade handler |
| `asset/display/list_it_service_logs.cfm` | BT servis & bakım ekranı |
| `asset/form/save_it_service_log.cfm` | BT servis kayıt/güncelleme/silme handler |

