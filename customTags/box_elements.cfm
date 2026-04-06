<!---
    box_elements.cfm — Form elemanları satır konteyneri (Bootstrap 5)
    boyahanev2.rasihcelik.com sistemine uyarlanmış versiyon.

    Nitelikler (Attributes):
        id       - Satır benzersiz kimliği (varsayılan: otomatik)
        vertical - Dikey form düzeni? 1/0 (varsayılan: 0)
                   0 = Yatay (label + input yan yana, Bootstrap col kullanımı)
                   1 = Dikey (label üstte, input altta, Bootstrap form-group)
        mode     - "form" veya "list" (varsayılan: "form")
        class    - Ek CSS sınıfları (varsayılan: "")

    Kullanım:
        <!--- Yatay düzen (col-* ile kontrol edilir) --->
        <cf_box_elements>
            <div class="col-md-6">
                <label class="form-label">Ad</label>
                <input type="text" class="form-control" name="name">
            </div>
            <div class="col-md-6">
                <label class="form-label">Soyad</label>
                <input type="text" class="form-control" name="surname">
            </div>
        </cf_box_elements>

        <!--- Dikey düzen --->
        <cf_box_elements vertical="1">
            <div class="col-12">
                <label class="form-label">Notlar</label>
                <textarea class="form-control" name="notes"></textarea>
            </div>
        </cf_box_elements>
--->

<cfparam name="attributes.id"       default="bxelm_#replace(createUUID(),'-','','ALL')#">
<cfparam name="attributes.vertical" default="0">
<cfparam name="attributes.mode"     default="form">
<cfparam name="attributes.class"    default="">

<cfoutput>
<cfif thisTag.executionMode eq "start">

    <div class="row g-2 mb-2 bx-elements<cfif val(attributes.vertical) eq 1> flex-column</cfif> #attributes.class#"
         id="#attributes.id#">

<cfelse><!--- executionMode: end --->

    </div><!--- /.row.bx-elements --->

</cfif><!--- /executionMode --->
</cfoutput>
