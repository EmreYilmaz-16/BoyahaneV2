<!---
    box.cfm — Bootstrap 5 kart (card) konteyneri
    boyahanev2.rasihcelik.com sistemine uyarlanmış versiyon.

    Nitelikler (Attributes):
        id               - Benzersiz kutu kimliği (varsayılan: otomatik)
        title            - Kart başlık metni (varsayılan: "")
        collapsed        - Başlangıçta kapalı mı? 1/0 (varsayılan: 0)
        collapsable      - Aç/kapat butonu göster? 1/0 (varsayılan: 1)
        closable         - Kapat (X) butonu göster? 1/0 (varsayılan: 0)
        class            - Karta eklenecek ek CSS sınıfları (varsayılan: "")
        style            - Dış wrapper div inline stili (varsayılan: "")
        body_style       - Card-body inline stili (varsayılan: "")
        body_height      - Sabit gövde yüksekliği + scroll (varsayılan: "")
        add_href         - "Ekle" butonu URL'si (varsayılan: "")
        add_href_title   - "Ekle" tooltip başlığı (varsayılan: "Ekle")
        edit_href        - "Düzenle" butonu URL'si (varsayılan: "")
        edit_href_title  - "Düzenle" tooltip başlığı (varsayılan: "Düzenle")
        print_href       - "Yazdır" butonu URL'si (varsayılan: "")
        print_href_title - "Yazdır" tooltip başlığı (varsayılan: "Yazdır")
        info_href        - "Detay" butonu URL'si (varsayılan: "")
        info_title       - "Detay" tooltip başlığı (varsayılan: "Detay")
        history_href     - "Tarihçe" butonu URL'si (varsayılan: "")
        history_title    - "Tarihçe" tooltip başlığı (varsayılan: "Tarihçe")
        bill_href        - "Fatura" butonu URL'si (varsayılan: "")
        bill_title       - "Fatura" tooltip başlığı (varsayılan: "Fatura")
        is_blank         - Bağlantıları yeni sekmede aç? 1/0 (varsayılan: 0)
        pure             - Kart çerçevesiz sade mod? 1/0 (varsayılan: 0)
        popup_box        - Kapatılabilir popup kutu? 1/0 (varsayılan: 0)

    Kullanım:
        <cf_box title="Sipariş Listesi" add_href="index.cfm?fuseaction=order.add">
            ... içerik ...
        </cf_box>
--->

<!--- boxparams struct desteği (eski sistemden taşınan kodlar için) --->
<cfif isDefined("attributes.boxparams") and isStruct(attributes.boxparams)>
    <cfloop array="#structKeyArray(attributes.boxparams)#" index="boxkey">
        <cfif attributes.boxparams[boxkey] eq "true">
            <cfset attributes[boxkey] = 1>
        <cfelseif attributes.boxparams[boxkey] eq "false">
            <cfset attributes[boxkey] = 0>
        <cfelse>
            <cfset attributes[boxkey] = attributes.boxparams[boxkey]>
        </cfif>
    </cfloop>
</cfif>

<!--- Fuseaction tespiti (yeni sistemde attributes.fuseaction url/form'dan geliyor) --->
<cfif not isDefined("attributes.fuseaction")>
    <cfif isDefined("caller.attributes.fuseaction")>
        <cfset attributes.fuseaction = caller.attributes.fuseaction>
    <cfelse>
        <cfset attributes.fuseaction = "">
    </cfif>
</cfif>

<!--- Parametreler --->
<cfparam name="attributes.id"               default="box_#replace(createUUID(),'-','','ALL')#">
<cfparam name="attributes.title"            default="">
<cfparam name="attributes.class"            default="">
<cfparam name="attributes.style"            default="">
<cfparam name="attributes.body_style"       default="">
<cfparam name="attributes.body_height"      default="">
<cfparam name="attributes.collapsed"        default="0">
<cfparam name="attributes.collapsable"      default="1" type="boolean">
<cfparam name="attributes.closable"         default="0" type="boolean">
<cfparam name="attributes.pure"             default="0" type="boolean">
<cfparam name="attributes.popup_box"        default="0">
<cfparam name="attributes.is_blank"         default="0">
<cfparam name="attributes.add_href"         default="">
<cfparam name="attributes.add_href_title"   default="Ekle">
<cfparam name="attributes.edit_href"        default="">
<cfparam name="attributes.edit_href_title"  default="Düzenle">
<cfparam name="attributes.print_href"       default="">
<cfparam name="attributes.print_href_title" default="Yazdır">
<cfparam name="attributes.info_href"        default="">
<cfparam name="attributes.info_title"       default="Detay">
<cfparam name="attributes.history_href"     default="">
<cfparam name="attributes.history_title"    default="Tarihçe">
<cfparam name="attributes.bill_href"        default="">
<cfparam name="attributes.bill_title"       default="Fatura">

<!--- popup_box = 1 ise kapatma aktif --->
<cfif val(attributes.popup_box) eq 1>
    <cfset attributes.closable = 1>
</cfif>

<!--- Draggable modal içinde açılmışsa modal_id URL'den okunur --->
<cfparam name="attributes.modal_id" default="#url.modal_id ?: ''#">

<!--- Çağrıcı sayfaya last_box_id bilgisini ver --->
<cfset caller.last_box_id = attributes.id>

<!--- Yeni sekmede aç niteliği --->
<cfset blankAttr = val(attributes.is_blank) eq 1 ? ' target="_blank"' : ''>

<!--- Başlık satırı gerekli mi? --->
<cfset hasHeader = len(attributes.title)
    or val(attributes.collapsable)
    or val(attributes.closable)
    or len(attributes.add_href)
    or len(attributes.edit_href)
    or len(attributes.print_href)
    or len(attributes.info_href)
    or len(attributes.history_href)
    or len(attributes.bill_href)>

<cfoutput>
<cfif thisTag.executionMode eq "start">

    <cfif NOT val(attributes.pure)>
    <!--- ===== KART BAŞLANGICI ===== --->
    <div id="unique_#attributes.id#" class="box-wrapper ">
        <div class="card shadow-sm #attributes.class#" id="#attributes.id#"<cfif len(attributes.style)> style="#attributes.style#"</cfif>>

            <cfif hasHeader>
            <div class="card-header d-flex align-items-center py-2 px-3 gap-2">

                <cfif val(attributes.collapsable)>
                <!--- Aç/kapat başlığı --->
                <a href="javascript:void(0)"
                   class="d-flex align-items-center gap-2 text-decoration-none text-dark flex-grow-1"
                   onclick="bxToggle('#attributes.id#_body', this)"
                   title="<cfif val(attributes.collapsed)>Aç<cfelse>Kapat</cfif>">
                    <i class="fas fa-chevron-<cfif val(attributes.collapsed)>right<cfelse>down</cfif> fa-xs text-muted bx-chevron"></i>
                    <cfif len(attributes.title)>
                    <span class="fw-semibold" style="font-size:.875rem;">#attributes.title#</span>
                    </cfif>
                </a>
                <cfelse>
                    <cfif len(attributes.title)>
                    <span class="fw-semibold flex-grow-1" style="font-size:.875rem;">#attributes.title#</span>
                    </cfif>
                </cfif>

                <!--- Başlık aksiyonları --->
                <div class="d-flex align-items-center gap-1 ms-auto">
                    <cfif len(attributes.add_href)>
                    <a href="#attributes.add_href#" title="#attributes.add_href_title#"
                       class="btn btn-sm btn-outline-primary px-2"#blankAttr#>
                        <i class="fas fa-plus fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif len(attributes.edit_href)>
                    <a href="#attributes.edit_href#" title="#attributes.edit_href_title#"
                       class="btn btn-sm btn-outline-secondary px-2"#blankAttr#>
                        <i class="fas fa-pen fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif len(attributes.info_href)>
                    <a href="#attributes.info_href#" title="#attributes.info_title#"
                       class="btn btn-sm btn-outline-info px-2"#blankAttr#>
                        <i class="fas fa-circle-info fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif len(attributes.bill_href)>
                    <a href="#attributes.bill_href#" title="#attributes.bill_title#"
                       class="btn btn-sm btn-outline-warning px-2"#blankAttr#>
                        <i class="fas fa-file-invoice fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif len(attributes.history_href)>
                    <a href="#attributes.history_href#" title="#attributes.history_title#"
                       class="btn btn-sm btn-outline-secondary px-2"#blankAttr#>
                        <i class="fas fa-clock-rotate-left fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif len(attributes.print_href)>
                    <a href="#attributes.print_href#" title="#attributes.print_href_title#"
                       class="btn btn-sm btn-outline-secondary px-2"
                       onclick="window.open(this.href,'_blank','width=900,height=700,scrollbars=yes'); return false;">
                        <i class="fas fa-print fa-xs"></i>
                    </a>
                    </cfif>
                    <cfif val(attributes.closable)>
                    <button type="button" class="btn btn-sm btn-outline-danger px-2"
                            onclick="bxClose(this,'#attributes.modal_id#','unique_#attributes.id#')"
                            title="Kapat">
                        <i class="fas fa-xmark fa-xs"></i>
                    </button>
                    </cfif>
                </div>
            </div>
            </cfif><!--- /card-header --->

            <div id="#attributes.id#_body"
                 class="card-body<cfif val(attributes.collapsed)> d-none</cfif>"
                 <cfif len(attributes.body_style) or len(attributes.body_height)>
                 style="<cfif len(attributes.body_style)>#attributes.body_style#;<cfelse></cfif><cfif len(attributes.body_height)>max-height:#attributes.body_height#;overflow-y:auto;</cfif>"
                 </cfif>>
    <cfelse>
    <!--- Pure mod: çerçevesiz --->
    <div id="#attributes.id#" class="#attributes.class#"<cfif len(attributes.style)> style="#attributes.style#"</cfif>>
    </cfif><!--- /pure check --->

<cfelse><!--- executionMode: end --->

    <cfif NOT val(attributes.pure)>
        </div><!--- /#attributes.id#_body --->
    </div><!--- /.card --->
    </div><!--- /#unique_attributes.id# --->
    <cfelse>
    </div><!--- /#attributes.id# pure --->
    </cfif>

</cfif><!--- /executionMode --->
</cfoutput>

<cfif thisTag.executionMode eq "end">
<!--- bxToggle ve bxClose fonksiyonlarını istek başına bir kez tanımla --->
<cfif NOT isDefined("request.bxToggleDefined")>
    <cfset request.bxToggleDefined = true>
    <script>
    function bxToggle(bodyId, btn) {
        var body = document.getElementById(bodyId);
        if (!body) return;
        var chevron = btn ? btn.querySelector('.bx-chevron') : null;
        var isHidden = body.classList.contains('d-none');
        body.classList.toggle('d-none', !isHidden);
        if (chevron) {
            chevron.classList.toggle('fa-chevron-down', isHidden);
            chevron.classList.toggle('fa-chevron-right', !isHidden);
        }
        if (btn) {
            btn.title = isHidden ? 'Kapat' : 'Aç';
        }
    }

    function bxClose(btn, modalId, wrapperId) {
        /* 1) Draggable modal içinde mi? Varsa popup_box_xxx'i tamamen kaldır */
        var popupEl = null;
        if (modalId && modalId !== '') {
            popupEl = document.getElementById('popup_box_' + modalId);
        }
        if (!popupEl) {
            /* modal_id yoksa veya bulunamazsa butona en yakın popup_box_* elementi ara */
            popupEl = btn.closest('[id^="popup_box_"]');
        }
        if (popupEl) {
            popupEl.remove();
            document.body.classList.remove('modal-opened');
            return;
        }
        /* 2) Normal sayfa içi kutu: sadece wrapper'ı gizle */
        var wrapper = document.getElementById(wrapperId);
        if (wrapper) wrapper.style.display = 'none';
    }
    </script>
</cfif>
</cfif>
