# Boyahane v2 - Docker Setup

## 🚀 Hızlı Başlangıç

### Gereksinimler
- Docker Desktop (Windows/Mac/Linux)
- Docker Compose v2+

### Kurulum ve Çalıştırma

1. **Docker Container'ları Başlat:**
```powershell
docker-compose up -d
```

2. **Logları İzle:**
```powershell
docker-compose logs -f
```

3. **Container'ları Durdur:**
```powershell
docker-compose down
```

4. **Tüm Verileri Sil ve Yeniden Başlat:**
```powershell
docker-compose down -v
docker-compose up -d --build
```

## 📦 Servisler

| Servis | URL | Açıklama |
|--------|-----|----------|
| **Lucee Web** | http://localhost:3000 | Ana uygulama |
| **Lucee Admin** | http://localhost:3001/lucee/admin/server.cfm | Lucee yönetim paneli |
| **PostgreSQL** | localhost:5433 | Veritabanı sunucusu |
| **Adminer** | http://localhost:9090 | Veritabanı yönetim arayüzü |

## 🔐 Varsayılan Şifreler

### Lucee Admin
- **Şifre:** `admin123`

### PostgreSQL
- **Veritabanı:** `boyahane`
- **Kullanıcı:** `boyahane_user`
- **Şifre:** `boyahane_pass123`
- **Host:** `postgres` (container içinden) veya `localhost` (host'tan)
- **Port:** `5432`

### Adminer (Veritabanı Yönetimi)
- **Sistem:** `PostgreSQL`
- **Sunucu:** `postgres`
- **Kullanıcı:** `boyahane_user`
- **Şifre:** `boyahane_pass123`
- **Veritabanı:** `boyahane`

## 🛠️ Yararlı Komutlar

### Container Durumu Kontrol
```powershell
docker-compose ps
```

### Container İçine Giriş
```powershell
# Lucee container
docker exec -it boyahane_lucee bash

# PostgreSQL container
docker exec -it boyahane_postgres psql -U boyahane_user -d boyahane
```

### PostgreSQL Komutları
```powershell
# Veritabanına bağlan
docker exec -it boyahane_postgres psql -U boyahane_user -d boyahane

# SQL dosyası çalıştır
docker exec -i boyahane_postgres psql -U boyahane_user -d boyahane < backup.sql

# Backup al
docker exec boyahane_postgres pg_dump -U boyahane_user boyahane > backup.sql
```

### Logları Görüntüle
```powershell
# Tüm servisler
docker-compose logs -f

# Sadece Lucee
docker-compose logs -f lucee

# Sadece PostgreSQL
docker-compose logs -f postgres
```

### Container'ları Yeniden Başlat
```powershell
docker-compose restart
```

### Sadece Belirli Servisi Yeniden Başlat
```powershell
docker-compose restart lucee
docker-compose restart postgres
```

## 🔧 Yapılandırma

### Application.cfc DataSource Ayarları
```coldfusion
this.datasources["boyahane"] = {
    class: 'org.postgresql.Driver',
    connectionString: 'jdbc:postgresql://postgres:5432/boyahane',
    username: 'boyahane_user',
    password: 'boyahane_pass123'
};
```

### Environment Variables
`.env` dosyası oluşturun (`.env.example` dosyasından kopyalayın):
```powershell
Copy-Item .env.example .env
```

## 📊 Veritabanı Şeması

İlk çalıştırmada `docker/init-db/01-init.sql` dosyası otomatik olarak çalışır ve test veritabanını oluşturur.

Yeni tablolar eklemek için:
1. `docker/init-db/` klasörüne yeni `.sql` dosyası ekleyin (örn: `02-create-tables.sql`)
2. Container'ları yeniden oluşturun: `docker-compose down -v && docker-compose up -d`

## 🐛 Sorun Giderme

### Port Çakışması
Eğer portlar kullanımdaysa, `docker-compose.yml` dosyasında port numaralarını değiştirin:
```yaml
ports:
  - "8080:80"  # Sol tarafı değiştirin (örn: "9090:80")
```

### Lucee Başlamıyor
```powershell
docker-compose logs lucee
docker-compose restart lucee
```

### PostgreSQL Bağlantı Hatası
```powershell
# Veritabanının hazır olduğunu kontrol edin
docker exec boyahane_postgres pg_isready -U boyahane_user

# Bağlantıyı test edin
docker exec -it boyahane_postgres psql -U boyahane_user -d boyahane -c "SELECT version();"
```

## 📝 Geliştirme Notları

- Dosya değişiklikleri otomatik olarak container'a yansır (volume mount)
- Lucee admin'de datasource manuel olarak eklenebilir veya Application.cfc'de tanımlanabilir
- Production'da şifreleri mutlaka değiştirin!
- `.env` dosyasını Git'e eklemeyin

## 🚀 Production Deployment

Production için:
1. Şifreleri güçlü ve unique yapın
2. `APP_ENV=production` olarak ayarlayın
3. `APP_DEBUG=false` yapın
4. Volume'ları production'a uygun yapılandırın
5. Nginx reverse proxy ekleyin
6. SSL sertifikası ekleyin

## 📚 İlgili Dökümanlar

- [Lucee Documentation](https://docs.lucee.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
