-- Kullanıcı bazlı varsayılan giriş sayfası desteği
ALTER TABLE kullanicilar
ADD COLUMN IF NOT EXISTS default_fuseaction VARCHAR(255);

COMMENT ON COLUMN kullanicilar.default_fuseaction IS 'Kullanıcının giriş sonrası açılacak varsayılan fuseaction değeri';
