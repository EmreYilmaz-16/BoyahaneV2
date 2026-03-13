# PBS Menü Tasarımcı

## 🎯 Genel Bakış

PBS (Partner Business Solutions) Menü Tasarımcı, sisteminizdeki hiyerarşik menü yapısını görsel olarak yönetmenizi sağlayan güçlü bir araçtır.

## 🌐 Erişim

**URL:** http://localhost:3000/dev/form/menu_designer.cfm

**Gereksinim:** Login olmanız gerekmektedir.

## 📊 Menü Hiyerarşisi

```
Solution (Çözüm)
    ↓
Family (Aile/Kategori)
    ↓
Module (Modül)
    ↓
Object (Nesne/Sayfa)
```

### Örnek Yapı:
```
Üretim Yönetimi (Solution)
  ├─ Üretim Planlama (Family)
  │   ├─ Üretim Planı (Module)
  │   │   ├─ Yeni Plan Ekle (Object)
  │   │   └─ Plan Listesi (Object)
  │   └─ Kapasite Planlama (Module)
  └─ İş Emirleri (Family)
      └─ İş Emri Girişi (Module)
          ├─ Yeni İş Emri (Object)
          └─ İş Emri Listesi (Object)
```

## ✨ Özellikler

### 1. **Görsel Menü Yönetimi**
- Hiyerarşik ağaç görünümü
- Renkli seviye göstergeleri
- İkon desteği
- Durum rozetleri (Aktif/Pasif, Gizli/Görünür)

### 2. **Sürükle & Bırak**
- ✅ Solution'ları sürükleyerek sıralayın
- ✅ Family'leri sürükleyerek sıralayın
- ✅ Module'leri sürükleyerek sıralayın
- ✅ Object'leri sürükleyerek sıralayın
- ⚡ Anlık kayıt - değişiklikler otomatik kaydedilir

### 3. **CRUD İşlemleri**

#### Yeni Öğe Ekleme
1. İstediğiniz seviyede **"+"** butonuna tıklayın
2. Formu doldurun:
   - **Öğe Adı:** Menüde görünecek isim
   - **İkon:** Font Awesome ikonu seçin
   - **Sıra No:** Görüntüleme sırası
   - **Üst Öğe:** Hangi kategoriye ait olacak (alt öğeler için)
   - **Menüde Göster:** Menüde görünür olsun mu?
   - **Aktif:** Öğe aktif mi?

#### Object (Sayfa) Özel Alanları:
- **Pencere Tipi:** 
  - `standart` - Normal sayfa
  - `popup` - Popup pencere
  - `ajaxpage` - AJAX yüklenen sayfa
- **Full Fuseaction:** Örn: `production.add_plan`
- **Dosya Yolu:** Örn: `/modules/production/add_plan.cfm`

#### Düzenleme
- 📝 Her öğenin yanındaki mavi **düzenle** butonuna tıklayın
- Formu güncelleyin ve kaydedin

#### Silme
- 🗑️ Kırmızı **sil** butonuna tıklayın
- ⚠️ **DİKKAT:** Alt öğeler de silinecektir (CASCADE)

### 4. **İkon Seçici**
- 90+ hazır Font Awesome ikonu
- Arama özelliği
- Önizleme
- Tıkla-seç kolay kullanım

### 5. **İstatistikler**
- Toplam Solution sayısı
- Toplam Family sayısı
- Toplam Module sayısı
- Toplam Object sayısı

## 🎨 Renk Kodları

- **🔵 Mavi (Solution):** En üst seviye çözümler
- **🟢 Yeşil (Family):** Çözüm aileleri/kategoriler
- **🟡 Sarı (Module):** Modüller
- **🔷 Cyan (Object):** Sayfalar/Nesneler

## 🔧 Kullanım Örnekleri

### Örnek 1: Yeni Bir Çözüm Ekleme
1. Üstteki **"Yeni Solution"** butonuna tıklayın
2. Formu doldurun:
   - Öğe Adı: "Kalite Yönetimi"
   - İkon: fa-check-circle
   - Sıra No: 10
   - Menüde Göster: ✓
   - Aktif: ✓
3. **Kaydet**'e tıklayın

### Örnek 2: Sıralama Değiştirme
1. Taşımak istediğiniz öğenin sol tarafındaki **≡** simgesini tutun
2. İstediğiniz yere sürükleyin
3. Bırakın - otomatik kaydedilir!

### Örnek 3: Yeni Sayfa (Object) Ekleme
1. İlgili Module'ün yanındaki **yeşil +** butonuna tıklayın
2. Formu doldurun:
   - Öğe Adı: "Üretim Raporu"
   - Pencere Tipi: standart
   - Full Fuseaction: reports.production_report
   - Dosya Yolu: /reports/production_report.cfm
3. **Kaydet**'e tıklayın

## 💾 Veritabanı Yapısı

### pbs_solution
```sql
- solution_id (PK)
- solution_name
- icon
- show_menu
- order_no
- is_active
```

### pbs_family
```sql
- family_id (PK)
- family_name
- solution_id (FK)
- icon
- show_menu
- order_no
- is_active
```

### pbs_module
```sql
- module_id (PK)
- module_name
- family_id (FK)
- icon
- show_menu
- order_no
- is_active
```

### pbs_objects
```sql
- object_id (PK)
- object_name
- module_id (FK)
- show_menu
- window_type
- full_fuseaction
- file_path
- order_no
- is_active
```

## 🚀 Kısayol Tuşları

- **Ctrl + Shift + R** - Menüyü yenile
- **Escape** - Modal kapat

## 📝 İpuçları

### ✅ En İyi Uygulamalar
- Anlamlı isimler kullanın
- İkon seçerken ilgili olanları tercih edin
- Sıra numaralarını 10'un katları olarak verin (sonradan araya ekleme kolaylığı)
- Kullanılmayan öğeleri silmek yerine pasif yapın
- Test öğeleri için "show_menu" false yapın

### ⚠️ Dikkat Edilmesi Gerekenler
- Silme işlemi geri alınamaz
- Alt öğeleri olan bir öğeyi silerseniz, tüm alt öğeler de silinir
- Aktif olmayan öğeler menüde görünmez
- order_no değerleri benzersiz olmak zorunda değil

## 🔍 Sorun Giderme

### Menü Yüklenmiyor
1. Lucee container'ının çalıştığından emin olun: `docker-compose ps`
2. Veritabanı bağlantısını kontrol edin (Adminer)
3. Tarayıcı console'da hata var mı kontrol edin (F12)

### Sürükle-Bırak Çalışmıyor
1. Sayfayı yenileyin (F5)
2. Başka bir tarayıcıda deneyin
3. JavaScript hatalarını kontrol edin

### Kayıt Olmuyor
- Network sekmesinden AJAX isteğinin 200 döndüğünden emin olun
- Session'ın aktif olduğunu kontrol edin
- Veritabanı bağlantısını test edin

## 📚 Teknik Detaylar

### Kullanılan Teknolojiler
- **Frontend:**
  - Bootstrap 5.3.2 (UI Framework)
  - jQuery 3.7.1 (DOM manipülasyonu)
  - SortableJS 1.15.0 (Drag & Drop)
  - Font Awesome 6.5.1 (İkonlar)

- **Backend:**
  - ColdFusion/Lucee (Server-side)
  - PostgreSQL (Veritabanı)
  - JSON (Veri transferi)

### AJAX Endpoints
- `getMenu` - Tüm menü yapısını getirir
- `getItem` - Tek bir öğeyi getirir
- `saveItem` - Yeni öğe ekler veya günceller
- `deleteItem` - Öğeyi siler
- `updateOrder` - Sıralamayı günceller

## 🎓 Örnek Senaryolar

### Senaryo 1: E-Ticaret Modülü Ekleme
```
1. Yeni Solution: "E-Ticaret"
2. Yeni Family: "Ürün Yönetimi"
3. Yeni Module: "Ürünler"
4. Yeni Objects:
   - Ürün Listesi (standart)
   - Yeni Ürün (popup)
   - Ürün Düzenle (ajaxpage)
```

### Senaryo 2: Raporlama Bölümü
```
1. Yeni Solution: "Raporlar"
2. Yeni Family: "Üretim Raporları"
3. Yeni Module: "Günlük Raporlar"
4. Yeni Object: "Günlük Özet" (standart)
```

## 🔐 Güvenlik

- ✅ Session kontrolü ile korunmuştur
- ✅ SQL injection korumalı (cfqueryparam)
- ✅ CSRF koruması önerilir (production için)
- ✅ XSS koruması (input sanitization)

## 📞 Destek

Sorunlarınız için:
1. Tarayıcı console'u kontrol edin
2. Lucee loglarını inceleyin: `docker-compose logs lucee`
3. PostgreSQL loglarını kontrol edin: `docker-compose logs postgres`

---

**Son Güncelleme:** 13 Mart 2026
**Versiyon:** 1.0.0
**Geliştirici:** Boyahane v2 Team
