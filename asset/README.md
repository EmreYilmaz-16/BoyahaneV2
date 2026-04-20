# Asset Management Modülü (Fiziki Varlık + BT Varlıkları + Motorlu Taşıt)

Bu modül, Workcube içinde **tek bir merkezden varlık yaşam döngüsü yönetimi** yapmak için hazırlanmıştır.

Kapsam:
- Fiziki varlık yönetimi (demirbaş, makine, ekipman vb.)
- BT varlık yönetimi (donanım, lisans, ağ topolojisi)
- Motorlu taşıt yönetimi (yakıt, bakım, hasar, sürücü atama)

---

## 1) Kurulum

### 1.1 Veritabanı tablolarını oluşturma
Aşağıdaki migration dosyası çalıştırılmalıdır:

- `docker/update-db/22_create_asset_management_tables.sql`

Bu script aşağıdaki ana tabloları oluşturur:
- Referans: `asset_categories`, `asset_locations`
- Ana varlık: `asset_master`
- Ortak süreç: `asset_movements`, `asset_maintenance`, `asset_depreciation`
- BT özel: `it_asset_details`, `it_software_licenses`, `it_network_topology`
- Araç özel: `vehicle_details`, `vehicle_fuel_logs`, `vehicle_service_logs`, `vehicle_accidents`, `vehicle_driver_assignments`

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
- Cihaz teknik özellikleri: `it_asset_details`
- Lisans uyumluluğu ve maliyet: `it_software_licenses`
- Cihazlar arası bağlantı: `it_network_topology`

### 3.6 Motorlu taşıt yönetimi
- Araç kimlik ve yasal takip bilgileri: `vehicle_details`
- Yakıt tüketimi: `vehicle_fuel_logs`
- Servis/bakım: `vehicle_service_logs`
- Kaza/hasar: `vehicle_accidents`
- Sürücü atama/rotasyon: `vehicle_driver_assignments`

---

## 4) Menü / Fuseaction Yapısı

Aşağıdaki action kayıtları tanımlıdır:

- `asset.list_assets`
- `asset.add_asset`
- `asset.save_asset`
- `asset.delete_asset`
- `asset.list_maintenances`
- `asset.save_maintenance`
- `asset.list_it_licenses`
- `asset.save_it_license`
- `asset.list_vehicle_operations`
- `asset.save_vehicle_fuel`
- `asset.save_vehicle_service`
- `asset.save_vehicle_accident`

> Not: Bu modül için temel `.cfm` ekran/action dosyaları oluşturulmuştur (`asset/display/*`, `asset/form/*`). İhtiyaca göre ek validasyon ve UI iyileştirmeleri yapılabilir.

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

---

## 6) Geliştirme Notları

- Tablolar PostgreSQL uyumlu tasarlanmıştır.
- Birçok alanda `CHECK` kısıtı kullanılarak veri kalitesi korunur.
- `asset_master` üstünden genel envanter ekranı; alt tablolardan tür bazlı detay ekranı önerilir.
- İleride şu genişletmeler eklenebilir:
  - Doküman yönetimi (ruhsat, sözleşme, garanti PDF vb.)
  - Bildirim/hatırlatma mekanizması (muayene, sigorta, lisans bitiş)
  - KPI dashboard (MTBF, bakım maliyeti trendi, araç başı yakıt verimliliği)

---

## 7) Dosya Referansları

- Ana taslak: `tempsql3.sql`
- Migration: `docker/update-db/22_create_asset_management_tables.sql`
- PBS object kayıtları: `asset/insert_pbs_objects.sql`

