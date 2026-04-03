<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cfcontent reset="true">
<cfscript>
    var result = {};
    var updated = [];

    try {
        // TCMB XML'ini çek
        httpResult = new http(
            url     = "https://www.tcmb.gov.tr/kurlar/today.xml",
            method  = "GET",
            timeout = 20,
            charset = "UTF-8"
        ).send().getPrefix();

        if (httpResult.statusCode neq "200 OK") {
            result = { "success": false, "message": "TCMB servisine bağlanılamadı: #httpResult.statusCode#" };
            writeOutput(serializeJSON(result));
            abort;
        }

        // XML'i parse et
        xmlDoc = xmlParse(httpResult.fileContent);

        // Tarih bilgisini al (XML attribute'tan)
        // <Tarih_Date Tarih="19.03.2026" Date="03/19/2026" ...>
        var validateDate = now();
        var validateHour = timeFormat(now(), "HH:mm");

        // Sistemde kayıtlı para birimleri (currency_code ile eşleşiyoruz)
        var qMoney = queryExecute(
            "SELECT money_id, money, currency_code FROM setup_money WHERE currency_code IS NOT NULL AND currency_code <> '' AND money_status = true",
            {},
            { datasource: "boyahane" }
        );

        // currency_code → money_id map
        var moneyMap = {};
        for (var row in qMoney) {
            moneyMap[uCase(row.currency_code)] = { "money_id": row.money_id, "money": row.money };
        }

        // XML Currency node'larını işle
        var currencyNodes = xmlSearch(xmlDoc, "//Currency");

        for (var node in currencyNodes) {
            var code = "";
            if (structKeyExists(node.xmlAttributes, "CurrencyCode")) {
                code = uCase(trim(node.xmlAttributes.CurrencyCode));
            }
            if (code eq "" OR !structKeyExists(moneyMap, code)) continue;

            // Değerleri güvenli al
            var fxBuy  = 0; var fxSell = 0; var bnBuy  = 0; var bnSell = 0;
            try { fxBuy  = val(trim(node.ForexBuying.xmlText));    } catch(e) {}
            try { fxSell = val(trim(node.ForexSelling.xmlText));   } catch(e) {}
            try { bnBuy  = val(trim(node.BanknoteBuying.xmlText)); } catch(e) {}
            try { bnSell = val(trim(node.BanknoteSelling.xmlText));} catch(e) {}

            var avg = (fxBuy > 0 AND fxSell > 0) ? (fxBuy + fxSell) / 2 : max(fxBuy, fxSell);
            var mId = moneyMap[code].money_id;
            var mCode = moneyMap[code].money;

            // setup_money güncelle
            queryExecute("
                UPDATE setup_money SET
                    rate1          = :r1,
                    rate2          = :r2,
                    rate3          = :r3,
                    dsp_rate_sale  = :r2,
                    dsp_rate_pur   = :r1,
                    effective_sale = :bnSell,
                    effective_pur  = :bnBuy,
                    dsp_effective_sale = :bnSell,
                    dsp_effective_pur  = :bnBuy,
                    dsp_update_date    = :now,
                    update_date        = :now,
                    update_ip          = :ip
                WHERE money_id = :mid
            ", {
                r1:     { value: fxBuy,  cfsqltype: "cf_sql_numeric" },
                r2:     { value: fxSell, cfsqltype: "cf_sql_numeric" },
                r3:     { value: avg,    cfsqltype: "cf_sql_numeric" },
                bnBuy:  { value: bnBuy,  cfsqltype: "cf_sql_numeric" },
                bnSell: { value: bnSell, cfsqltype: "cf_sql_numeric" },
                now:    { value: now(),  cfsqltype: "cf_sql_timestamp" },
                ip:     { value: cgi.remote_addr, cfsqltype: "cf_sql_varchar" },
                mid:    { value: mId,    cfsqltype: "cf_sql_integer" }
            }, { datasource: "boyahane" });

            // money_history'e ekle
            queryExecute("
                INSERT INTO money_history (money, rate1, rate2, rate3, effective_sale, effective_pur, validate_date, validate_hour, record_date, record_ip)
                VALUES (:money, :r1, :r2, :r3, :bnSell, :bnBuy, :vdate, :vhour, :now, :ip)
            ", {
                money:  { value: mCode,         cfsqltype: "cf_sql_varchar" },
                r1:     { value: fxBuy,          cfsqltype: "cf_sql_numeric" },
                r2:     { value: fxSell,         cfsqltype: "cf_sql_numeric" },
                r3:     { value: avg,            cfsqltype: "cf_sql_numeric" },
                bnBuy:  { value: bnBuy,          cfsqltype: "cf_sql_numeric" },
                bnSell: { value: bnSell,         cfsqltype: "cf_sql_numeric" },
                vdate:  { value: validateDate,   cfsqltype: "cf_sql_timestamp" },
                vhour:  { value: validateHour,   cfsqltype: "cf_sql_varchar" },
                now:    { value: now(),          cfsqltype: "cf_sql_timestamp" },
                ip:     { value: cgi.remote_addr,cfsqltype: "cf_sql_varchar" }
            }, { datasource: "boyahane" });

            arrayAppend(updated, {
                "money": mCode,
                "rate1": fxBuy,
                "rate2": fxSell,
                "rate3": avg,
                "effective_pur": bnBuy,
                "effective_sale": bnSell
            });
        }

        if (arrayLen(updated) eq 0) {
            result = { "success": false, "message": "Sistemde kayıtlı para birimleriyle eşleşen kur bulunamadı. currency_code alanlarını kontrol edin." };
        } else {
            result = { "success": true, "message": arrayLen(updated) & " para birimi güncellendi.", "updated": updated };
        }

    } catch(any e) {
        result = { "success": false, "message": "Hata: #e.message#" };
    }

    writeOutput(serializeJSON(result));
</cfscript>
<cfabort>