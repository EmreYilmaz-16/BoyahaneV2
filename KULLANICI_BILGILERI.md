# Kullanıcı Bilgileri

## 📋 Test Kullanıcıları

Sisteme giriş yapmak için aşağıdaki test kullanıcılarını kullanabilirsiniz:

### 1. Admin Kullanıcı
- **Kullanıcı Adı:** `admin`
- **Şifre:** `admin123`
- **Ad Soyad:** Admin User
- **W3 User ID:** ADM001

### 2. Mehmet Yılmaz
- **Kullanıcı Adı:** `mehmet`
- **Şifre:** `123456`
- **Ad Soyad:** Mehmet Yılmaz
- **W3 User ID:** USR001

### 3. Ayşe Kaya
- **Kullanıcı Adı:** `ayse`
- **Şifre:** `123456`
- **Ad Soyad:** Ayşe Kaya
- **W3 User ID:** USR002

## 🔐 Güvenlik Notları

⚠️ **ÖNEMLİ:** Bu şifreler sadece test amaçlıdır!

**Production (Canlı) ortamda mutlaka:**
1. Şifreleri değiştirin
2. Şifre hash'leme kullanın (bcrypt, argon2 vb.)
3. Güçlü şifre politikası uygulayın
4. 2FA (İki faktörlü doğrulama) ekleyin

## 📊 Veritabanı Tablosu

Kullanıcılar tablosu (`kullanicilar`) şu alanlara sahiptir:

- `id` - Otomatik artan benzersiz ID (PRIMARY KEY)
- `name` - Ad
- `surname` - Soyad
- `username` - Kullanıcı adı (UNIQUE)
- `password` - Şifre (⚠️ Şu anda düz metin - production'da hash'lenmeli!)
- `w3userid` - Workcube kullanıcı ID'si
- `is_active` - Aktif/Pasif durumu (boolean)
- `created_at` - Kayıt tarihi
- `updated_at` - Son güncelleme tarihi
- `last_login` - Son giriş zamanı

## 🚀 Kullanım

1. Tarayıcınızda http://localhost:3000 adresine gidin
2. Otomatik olarak login sayfasına yönlendirileceksiniz
3. Yukarıdaki kullanıcı bilgilerinden birini kullanarak giriş yapın
4. Başarılı girişten sonra ana sayfa açılacak
5. Sağ üst köşeden çıkış yapabilirsiniz

## 🔧 Yeni Kullanıcı Ekleme

### Adminer ile (Web Arayüzü)
1. http://localhost:9090 adresine gidin
2. PostgreSQL seçin, `postgres` sunucusu, `boyahane_user` / `boyahane_pass123` ile giriş yapın
3. `kullanicilar` tablosuna yeni kayıt ekleyin

### SQL ile
```sql
INSERT INTO kullanicilar (name, surname, username, password, w3userid) 
VALUES ('Yeni', 'Kullanıcı', 'yeniuser', 'sifre123', 'USR003');
```

### Terminal ile
```powershell
docker exec -it boyahane_postgres psql -U boyahane_user -d boyahane -c "INSERT INTO kullanicilar (name, surname, username, password, w3userid) VALUES ('Test', 'User', 'test', 'test123', 'TST001');"
```

## 📝 Özellikler

✅ Session tabanlı kimlik doğrulama
✅ Kullanıcı adı ve şifre ile giriş
✅ "Beni Hatırla" özelliği (cookie)
✅ Son giriş zamanı takibi
✅ Aktif/Pasif kullanıcı kontrolü
✅ Responsive login tasarımı
✅ Hata mesajları
✅ Güvenli çıkış (logout)
✅ Navbar'da kullanıcı bilgisi gösterimi

## 🔜 Gelecek Geliştirmeler

- [ ] Şifre hash'leme (bcrypt)
- [ ] Şifre sıfırlama
- [ ] E-posta doğrulama
- [ ] 2FA (İki faktörlü doğrulama)
- [ ] Kullanıcı rolleri ve yetkileri
- [ ] Yönetim paneli
- [ ] Şifre politikası (min uzunluk, karmaşıklık vb.)
- [ ] Başarısız giriş denemesi takibi
- [ ] Hesap kilitleme
- [ ] Activity log
