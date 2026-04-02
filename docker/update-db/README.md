## Update SQL Queue

Bu klasör, **tek seferlik** update SQL scriptleri içindir.

### Akış
1. Yeni SQL dosyanızı bu klasöre ekleyin (örn: `20260402_add_new_table.sql`).
2. Sistem update (`applyUpdates`) çalıştığında script alfabetik sırada çalıştırılır.
3. Script başarıyla çalışırsa dosya hedef sistemden silinir.

### Not
- Script çalıştırılamazsa dosya silinmez; hata döner ve dosya klasörde kalır.
- Script adlarını artan sıralı/tarihli vermeniz önerilir.
