<!---
    box_search.cfm — Arama / Filtreleme paneli (Bootstrap 5)
    boyahanev2.rasihcelik.com sistemine uyarlanmış versiyon.

    Nitelikler (Attributes):
        id       - Panel benzersiz kimliği (varsayılan: fuseaction'dan türetilir)
        more     - "Daha Fazlası" genişletme butonu göster? 1/0 (varsayılan: 1)
        plus     - Yeni kayıt "+" butonu göster? 1/0 (varsayılan: 0)
        add_href - "+" butonunun gideceği URL (varsayılan: "")

    Kullanım:
        <cf_box_search>
            <div class="me-2">
                <input class="form-control form-control-sm" name="keyword" placeholder="Ara...">
            </div>
            <button class="btn btn-sm btn-primary" id="wrk_search_button">
                <i class="fas fa-search fa-xs"></i> Ara
            </button>
            <!--- Genişletilmiş filtreler bx-extra sınıfıyla işaretlenir --->
            <div class="me-2 bx-extra">
                <input class="form-control form-control-sm" name="date_from" placeholder="Başlangıç Tarihi">
            </div>
        </cf_box_search>

    Not: "bx-extra" CSS sınıfı taşıyan elemanlar "Daha Fazlası" butonuyla gösterilen
    genişletilmiş filtre alanını oluşturur.
--->

<!--- Fuseaction tespiti --->
<cfif not isDefined("attributes.fuseaction")>
    <cfif isDefined("caller.attributes.fuseaction")>
        <cfset attributes.fuseaction = caller.attributes.fuseaction>
    <cfelse>
        <cfset attributes.fuseaction = "search">
    </cfif>
</cfif>

<cfparam name="attributes.id"       default="bxsearch_#replace(attributes.fuseaction, '.', '_', 'ALL')#">
<cfparam name="attributes.more"     default="1">
<cfparam name="attributes.plus"     default="0">
<cfparam name="attributes.add_href" default="">

<!--- Nokta karakterleri HTML ID'de sorun yaratır --->
<cfset attributes.id = replace(attributes.id, '.', '_', 'ALL')>

<!--- Çağrıcı sayfaya son tablo/panel ID'sini ver --->
<cfset caller.last_table_id = attributes.id>

<cfoutput>
<cfif thisTag.executionMode eq "start">

    <div class="card shadow-sm mb-3 bx-search-panel" id="#attributes.id#">
        <div class="card-body py-2 px-3">
            <!--- Ana filtre satırı --->
            <div class="d-flex flex-wrap align-items-center gap-2" id="#attributes.id#_row">

<cfelse><!--- executionMode: end --->

            </div><!--- /#attributes.id#_row --->

            <!--- Genişletilmiş filtre alanı (bx-extra sınıflı elemanlar JS ile buraya taşınır) --->
            <div class="d-none mt-2 pt-2 border-top" id="#attributes.id#_extra"></div>

        </div><!--- /.card-body --->
    </div><!--- /.card --->

    <cfif val(attributes.more) eq 1 or (val(attributes.plus) eq 1 and len(attributes.add_href))>
    <script>
    (function () {
        var row   = document.getElementById('#attributes.id#_row');
        var extra = document.getElementById('#attributes.id#_extra');
        if (!row) return;

        <cfif val(attributes.more) eq 1>
        <!--- bx-extra sınıflı elemanları genişletilmiş alana taşı --->
        var extraItems = Array.from(row.querySelectorAll('.bx-extra'));
        if (extraItems.length > 0) {
            extraItems.forEach(function (el) { extra.appendChild(el); });

            var moreBtn = document.createElement('button');
            moreBtn.type = 'button';
            moreBtn.className = 'btn btn-sm btn-outline-secondary';
            moreBtn.innerHTML = '<i class="fas fa-angle-down fa-xs me-1"></i>Daha Fazlası';
            moreBtn.onclick = function () {
                var hidden = extra.classList.contains('d-none');
                extra.classList.toggle('d-none', !hidden);
                moreBtn.innerHTML = hidden
                    ? '<i class="fas fa-angle-up fa-xs me-1"></i>Daha Az'
                    : '<i class="fas fa-angle-down fa-xs me-1"></i>Daha Fazlası';
            };
            row.appendChild(moreBtn);
        }
        </cfif>

        <cfif val(attributes.plus) eq 1 and len(attributes.add_href)>
        <!--- Yeni kayıt ekleme butonu --->
        var addBtn = document.createElement('a');
        addBtn.href      = '#attributes.add_href#';
        addBtn.className = 'btn btn-sm btn-outline-primary';
        addBtn.title     = 'Yeni Ekle';
        addBtn.innerHTML = '<i class="fas fa-plus fa-xs"></i>';
        row.appendChild(addBtn);
        </cfif>
    })();
    </script>
    </cfif>

</cfif><!--- /executionMode --->
</cfoutput>


