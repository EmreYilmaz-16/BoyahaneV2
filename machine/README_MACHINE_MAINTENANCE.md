# Makine Bakım / Onarım / Arıza Takip Modülü

Bu modül aşağıdaki süreçleri uçtan uca yönetir:

- Makine kartı açma
- Periyodik bakım planı tanımlama
- Bakım sonucu girme
- Arıza bildirimi açma
- Teknik personelin arıza aşamalarını yönetmesi (atandı, müdahale, çözüldü)
- Arıza yaşam döngüsü süre takibi (açılış → ilk müdahale → kapanış)
- Tüm makineleri tek ekranda dashboard ile izleme

## 1) Kurulum

### Veritabanı tabloları
Aşağıdaki migration dosyaları eklendi:

- `docker/init-db/26_create_machine_maintenance_tables.sql`
- `docker/update-db/28_create_machine_maintenance_tables.sql`

Temiz kurulum için Docker volume sıfırlanarak başlatılabilir:

```bash
docker compose down -v
docker compose up -d --build
```

Mevcut ortama update dosyası çalıştırılacaksa:

```bash
docker exec -i boyahane_postgres psql -U boyahane_user -d boyahane < docker/update-db/28_create_machine_maintenance_tables.sql
```

### Menü/fuseaction kayıtları
`machine/insert_pbs_objects.sql` dosyasını çalıştırın.

Dashboard fuseaction:

- `machine.dashboard`

## 2) Kullanım Akışı

### A) Makine ekleme
1. `Makine Bakım & Arıza Dashboard` ekranına girin.
2. `Makine Ekle` butonuna tıklayın.
3. Kod, ad, departman, lokasyon ve başlangıç durumunu girin.
4. Kaydedin.

### B) Bakım planı oluşturma
1. `Bakım Planı` butonuna tıklayın.
2. Makineyi seçin, plan başlığı ve periyot gününü girin.
3. İsterseniz ilk plan tarihini girin.

### C) Bakım sonucu girme
1. `Bakım Sonucu` butonuna tıklayın.
2. Makine ve (varsa) bakım planını seçin.
3. Başlangıç / bitiş saatlerini girin.
4. Sonuç notunu kaydedin.

> Bu işlem sonrası makine durumu otomatik olarak "Arıza Yok" olarak güncellenir.

### D) Arıza bildirimi açma
1. `Arıza Bildir` butonuna tıklayın.
2. Makineyi seçin.
3. Arıza başlığı, öncelik ve açıklamayı girin.
4. Kaydedin.

> Arıza açıldığında makine durumu otomatik olarak "Arızalı" olur.

### E) Teknik personel arıza kapatma
Arızalar sekmesindeki **Aksiyon** kolonundan:
- `Aşama Güncelle` → personel ID ataması + aşama geçişi (Atandı/Müdahale/Çöz/İptal)
- `Tarihçe` → arızaya ait tüm işlem geçmişini modal içinde gösterir

Örnek zaman akışı:
- Açılış: 01.01.2026 17:00
- Müdahale: 01.01.2026 18:00
- Bitiş: 01.01.2026 19:00

Sistem bu kayıtlar üzerinden:
- İlk müdahale süresi (dk)
- Toplam kapanış süresi (dk)

alanlarını dashboard tablosunda otomatik hesaplar.

## 3) Dashboard İçeriği

Dashboard üst kartlarında:
- Toplam makine
- Arıza yok / bakımda / arızalı makine sayısı
- Son 30 gün açık/devam eden arıza sayısı

Sekmeler:
- **Makineler**: canlı durum, açık arıza adedi, sonraki bakım tarihi
- **Arızalar**: arıza listesi + aşama yönetimi + süre metrikleri
- **Bakım Planları**: periyodik planlar
- **Bakım Kayıtları**: gerçekleşen bakım sonuçları ve süre
- **Makine Arıza Analiz**: geçmiş arıza kayıtları + makine bazlı en sık arıza tipi takibi

## 4) Önerilen Ek Geliştirmeler

İsterseniz sonraki fazda şu özellikler eklenebilir:

- SLA hedefleri (örn. ilk müdahale < 30 dk)
- Geciken bakım alarmı (e-posta / bildirim)
- Arıza kök neden kodları (RCA)
- MTTR / MTBF KPI raporu
- Personel performans raporu
- Yedek parça tüketim entegrasyonu

## 5) Dosya Listesi

- `machine/display/dashboard.cfm`
- `machine/form/save_machine.cfm`
- `machine/form/save_maintenance_plan.cfm`
- `machine/form/save_maintenance_result.cfm`
- `machine/form/save_fault.cfm`
- `machine/form/update_fault_stage.cfm`
- `machine/insert_pbs_objects.sql`
