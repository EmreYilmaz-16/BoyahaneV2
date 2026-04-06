<!---
    box_footer.cfm — Form buton alanı (Bootstrap 5)
    boyahanev2.rasihcelik.com sistemine uyarlanmış versiyon.

    cf_box içinde kullanılır. Formun alt kısmındaki eylem butonlarını (Kaydet,
    İptal, Sil vb.) barındıran bir flex konteyneri oluşturur.

    Kullanım:
        <cf_box title="Müşteri Formu">
            <cf_box_elements>
                <div class="col-md-6">
                    <label class="form-label">Ad</label>
                    <input type="text" class="form-control" name="name">
                </div>
            </cf_box_elements>

            <cf_box_footer>
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-floppy-disk me-1"></i>Kaydet
                </button>
                <a href="index.cfm?fuseaction=company.list" class="btn btn-outline-secondary">
                    <i class="fas fa-xmark me-1"></i>İptal
                </a>
            </cf_box_footer>
        </cf_box>
--->

<cfoutput>
<cfif thisTag.executionMode eq "start">

    <!--- Çağrıcı sayfaya popup_box_footer bilgisi ver --->
    <cfset caller.popup_box_footer = 1>

    <div class="d-flex flex-wrap align-items-center gap-2 mt-3 pt-3 border-top bx-footer">

<cfelse><!--- executionMode: end --->

    </div><!--- /.bx-footer --->

</cfif><!--- /executionMode --->
</cfoutput>
