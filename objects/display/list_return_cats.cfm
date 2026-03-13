<cfparam name="url.action" default="">

<cfset dsn = "boyahane">
<cfset remoteServiceUrl = "http://w3.rasihcelik.com/pbs_functions/objects.cfc">

<!--- Download ve Sync işlemi --->
<cfif url.action EQ "downloadSync">
    <cfset syncResults = structNew()>
    <cfset syncResults.addedToLocal = arrayNew(1)>
    <cfset syncResults.addedToRemote = arrayNew(1)>
    <cfset syncResults.errors = arrayNew(1)>

    <cftry>
        <!--- 1. CFHTTP ile servisten veri çek --->
        <cfhttp url="#remoteServiceUrl#" method="GET" result="httpResult" timeout="30">
            <cfhttpparam type="url" name="method" value="getReturnCats">
        </cfhttp>

        <cfif httpResult.statusCode EQ "200 OK">
            <cfset remoteData = deserializeJSON(httpResult.fileContent)>
            
            <!--- 2. Local veritabanından mevcut verileri çek --->
            <cfquery name="getLocalData" datasource="#dsn#">
                SELECT RETURN_CAT_ID, RETURN_CAT
                FROM return_cats
                ORDER BY RETURN_CAT_ID
            </cfquery>

            <!--- 3. Serviste olup bizde olmayanları local'e ekle --->
            <cfloop array="#remoteData#" index="remoteItem">
                <cfquery name="checkExists" datasource="#dsn#">
                    SELECT COUNT(*) as CNT
                    FROM return_cats
                    WHERE RETURN_CAT_ID = <cfqueryparam value="#remoteItem.RETURN_CAT_ID#" cfsqltype="cf_sql_integer">
                </cfquery>

                <cfif checkExists.CNT EQ 0>
                    <!--- Local'e ekle --->
                    <cftry>
                        <cfquery datasource="#dsn#">
                            INSERT INTO return_cats (
                                RETURN_CAT_ID,
                                RETURN_CAT,
                                RECORD_EMP,
                                RECORD_IP,
                                RECORD_DATE
                            ) VALUES (
                                <cfqueryparam value="#remoteItem.RETURN_CAT_ID#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="#remoteItem.RETURN_CAT#" cfsqltype="cf_sql_varchar">,
                                1,
                                <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                                NOW()
                            )
                        </cfquery>
                        <cfset arrayAppend(syncResults.addedToLocal, remoteItem.RETURN_CAT)>
                    <cfcatch>
                        <cfset arrayAppend(syncResults.errors, "Local'e eklenemedi: " & remoteItem.RETURN_CAT)>
                    </cfcatch>
                    </cftry>
                </cfif>
            </cfloop>

            <!--- 4. Bizde olup serviste olmayanları servise ekle --->
            <cfloop query="getLocalData">
                <cfset existsInRemote = false>
                <cfloop array="#remoteData#" index="remoteItem">
                    <cfif remoteItem.RETURN_CAT_ID EQ getLocalData.RETURN_CAT_ID>
                        <cfset existsInRemote = true>
                        <cfbreak>
                    </cfif>
                </cfloop>

                <cfif NOT existsInRemote>
                    <!--- Servise ekle - CFHTTP ile POST --->
                    <cftry>
                        <cfhttp url="#remoteServiceUrl#" method="POST" result="insertResult" timeout="30">
                            <cfhttpparam type="url" name="method" value="insertReturnCat">
                            <cfhttpparam type="url" name="RETURN_CAT" value="#getLocalData.RETURN_CAT#">
                            <cfhttpparam type="url" name="RECORD_EMP" value="1">
                            <cfhttpparam type="url" name="RECORD_IP" value="#cgi.REMOTE_ADDR#">
                        </cfhttp>

                        <cfif insertResult.statusCode EQ "200 OK">
                            <cfset response = deserializeJSON(insertResult.fileContent)>
                            <cfif structKeyExists(response, "success") AND response.success>
                                <cfset arrayAppend(syncResults.addedToRemote, getLocalData.RETURN_CAT)>
                            <cfelse>
                                <cfset arrayAppend(syncResults.errors, "Servise eklenemedi: " & getLocalData.RETURN_CAT)>
                            </cfif>
                        <cfelse>
                            <cfset arrayAppend(syncResults.errors, "Servise eklenemedi (HTTP): " & getLocalData.RETURN_CAT)>
                        </cfif>
                    <cfcatch>
                        <cfset arrayAppend(syncResults.errors, "Servise eklenemedi (Error): " & getLocalData.RETURN_CAT)>
                    </cfcatch>
                    </cftry>
                </cfif>
            </cfloop>
        <cfelse>
            <cfset arrayAppend(syncResults.errors, "Servis bağlantı hatası: " & httpResult.statusCode)>
        </cfif>

    <cfcatch>
        <cfset arrayAppend(syncResults.errors, "Genel hata: " & cfcatch.message)>
    </cfcatch>
    </cftry>
</cfif>

<!--- Yeni kayıt ekleme --->
<cfif url.action EQ "add" AND structKeyExists(form, "RETURN_CAT")>
    <cftry>
        <!--- 1. Local'e ekle --->
        <cfquery name="insertLocal" datasource="#dsn#">
            INSERT INTO return_cats (
                RETURN_CAT,
                RECORD_EMP,
                RECORD_IP,
                RECORD_DATE
            ) VALUES (
                <cfqueryparam value="#form.RETURN_CAT#" cfsqltype="cf_sql_varchar">,
                1,
                <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                NOW()
            )
        </cfquery>

        <!--- 2. Servise de ekle - CFHTTP ile --->
        <cfhttp url="#remoteServiceUrl#" method="POST" result="remoteInsertResult" timeout="30">
            <cfhttpparam type="url" name="method" value="insertReturnCat">
            <cfhttpparam type="url" name="RETURN_CAT" value="#form.RETURN_CAT#">
            <cfhttpparam type="url" name="RECORD_EMP" value="1">
            <cfhttpparam type="url" name="RECORD_IP" value="#cgi.REMOTE_ADDR#">
        </cfhttp>

        <cfset addSuccess = true>
        <cfset addMessage = "Kayıt başarıyla eklendi (hem local hem remote).">
    <cfcatch>
        <cfset addSuccess = false>
        <cfset addMessage = "Hata: " & cfcatch.message>
    </cfcatch>
    </cftry>
</cfif>

<!--- Güncelleme --->
<cfif url.action EQ "update" AND structKeyExists(form, "RETURN_CAT_ID")>
    <cftry>
        <!--- 1. Local'i güncelle --->
        <cfquery datasource="#dsn#">
            UPDATE return_cats
            SET RETURN_CAT = <cfqueryparam value="#form.RETURN_CAT#" cfsqltype="cf_sql_varchar">,
                UPDATE_EMP = 1,
                UPDATE_IP = <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                UPDATE_DATE = NOW()
            WHERE RETURN_CAT_ID = <cfqueryparam value="#form.RETURN_CAT_ID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <!--- 2. Remote'u güncelle - CFHTTP ile --->
        <cfhttp url="#remoteServiceUrl#" method="POST" result="remoteUpdateResult" timeout="30">
            <cfhttpparam type="url" name="method" value="updateReturnCat">
            <cfhttpparam type="url" name="RETURN_CAT_ID" value="#form.RETURN_CAT_ID#">
            <cfhttpparam type="url" name="RETURN_CAT" value="#form.RETURN_CAT#">
            <cfhttpparam type="url" name="UPDATE_EMP" value="1">
            <cfhttpparam type="url" name="UPDATE_IP" value="#cgi.REMOTE_ADDR#">
        </cfhttp>

        <cfset updateSuccess = true>
        <cfset updateMessage = "Kayıt başarıyla güncellendi (hem local hem remote).">
    <cfcatch>
        <cfset updateSuccess = false>
        <cfset updateMessage = "Hata: " & cfcatch.message>
    </cfcatch>
    </cftry>
</cfif>

<!--- Verileri çek --->
<cfquery name="getData" datasource="#dsn#">
    SELECT 
        RETURN_CAT_ID,
        RETURN_CAT,
        RECORD_EMP,
        RECORD_IP,
        RECORD_DATE,
        UPDATE_EMP,
        UPDATE_IP,
        UPDATE_DATE
    FROM return_cats
    ORDER BY RETURN_CAT_ID
</cfquery>



    <style>
        body {
            background-color: #f8f9fa;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .header {
            margin-bottom: 30px;
            border-bottom: 2px solid #007bff;
            padding-bottom: 15px;
        }
        .loading {
            text-align: center;
            padding: 50px;
        }
        .btn-refresh {
            margin-left: 10px;
        }
        .table-responsive {
            margin-top: 20px;
        }
        .badge-info {
            background-color: #17a2b8;
        }
        .sync-info {
            margin-top: 15px;
            padding: 10px;
            background-color: #e7f3ff;
            border-radius: 5px;
            border-left: 4px solid #007bff;
        }
        .sync-result {
            margin-top: 10px;
        }
    </style>

    
        <div class="header">
            <div class="row align-items-center">
                <div class="col">
                    <h2><i class="fas fa-list"></i> Return Kategorileri</h2>
                </div>
                <div class="col text-end">
                    <a href="index.cfm?fuseaction=admin.list_return_cats&action=downloadSync" class="btn btn-success">
                        <i class="fas fa-download"></i> Download & Sync
                    </a>
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#editModal" onclick="clearForm()">
                        <i class="fas fa-plus"></i> Yeni Ekle
                    </button>
                    <a href="index.cfm?fuseaction=admin.list_return_cats" class="btn btn-secondary btn-refresh">
                        <i class="fas fa-sync-alt"></i> Yenile
                    </a>
                </div>
            </div>
        </div>

        <!--- Mesajlar --->
        <cfif structKeyExists(variables, "addSuccess")>
            <div class="alert <cfif addSuccess>alert-success<cfelse>alert-danger</cfif> alert-dismissible fade show">
                <cfoutput>#addMessage#</cfoutput>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        </cfif>

        <cfif structKeyExists(variables, "updateSuccess")>
            <div class="alert <cfif updateSuccess>alert-success<cfelse>alert-danger</cfif> alert-dismissible fade show">
                <cfoutput>#updateMessage#</cfoutput>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        </cfif>

        <!--- Senkronizasyon Sonuçları --->
        <cfif structKeyExists(variables, "syncResults")>
            <div class="sync-info">
                <h6><i class="fas fa-info-circle"></i> Senkronizasyon Sonuçları</h6>
                
                <cfif arrayLen(syncResults.addedToLocal) GT 0>
                    <div class="alert alert-success sync-result">
                        <strong>Lokal sisteme eklendi (<cfoutput>#arrayLen(syncResults.addedToLocal)#</cfoutput>):</strong><br>
                        <cfoutput>#arrayToList(syncResults.addedToLocal, ", ")#</cfoutput>
                    </div>
                </cfif>

                <cfif arrayLen(syncResults.addedToRemote) GT 0>
                    <div class="alert alert-info sync-result">
                        <strong>Servise eklendi (<cfoutput>#arrayLen(syncResults.addedToRemote)#</cfoutput>):</strong><br>
                        <cfoutput>#arrayToList(syncResults.addedToRemote, ", ")#</cfoutput>
                    </div>
                </cfif>

                <cfif arrayLen(syncResults.errors) GT 0>
                    <div class="alert alert-danger sync-result">
                        <strong>Hatalar:</strong><br>
                        <cfoutput>#arrayToList(syncResults.errors, "<br>")#</cfoutput>
                    </div>
                </cfif>

                <cfif arrayLen(syncResults.addedToLocal) EQ 0 AND arrayLen(syncResults.addedToRemote) EQ 0 AND arrayLen(syncResults.errors) EQ 0>
                    <div class="alert alert-info sync-result">
                        <i class="fas fa-check-circle"></i> Tüm veriler senkronize. Yeni ekleme yok.
                    </div>
                </cfif>
            </div>
        </cfif>

        <div class="row mb-3">
            <div class="col-md-6">
                <input type="text" id="searchInput" class="form-control" placeholder="Ara..." onkeyup="filterTable()">
            </div>
            <div class="col-md-6 text-end">
                <span class="badge badge-info bg-info" id="recordCount"><cfoutput>#getData.recordCount#</cfoutput> kayıt</span>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th width="10%">ID</th>
                        <th width="70%">Kategori</th>
                        <th width="20%" class="text-center">İşlemler</th>
                    </tr>
                </thead>
                <tbody id="dataTableBody">
                    <cfoutput query="getData">
                        <tr>
                            <td>#RETURN_CAT_ID#</td>
                            <td>#RETURN_CAT#</td>
                            <td class="text-center">
                                <button class="btn btn-sm btn-warning" onclick="editRecord(#RETURN_CAT_ID#, '#JSStringFormat(RETURN_CAT)#')">
                                    <i class="fas fa-edit"></i> Düzenle
                                </button>
                            </td>
                        </tr>
                    </cfoutput>
                    <cfif getData.recordCount EQ 0>
                        <tr>
                            <td colspan="3" class="text-center">Kayıt bulunamadı</td>
                        </tr>
                    </cfif>
                </tbody>
            </table>
        </div>
    

    <!-- Modal for Add/Edit -->
    <div class="modal fade" id="editModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <form method="post" id="editForm">
                    <div class="modal-header">
                        <h5 class="modal-title" id="modalTitle">Yeni Kategori</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <input type="hidden" name="RETURN_CAT_ID" id="editId">
                        <div class="mb-3">
                            <label for="editReturnCat" class="form-label">Kategori Adı</label>
                            <input type="text" class="form-control" name="RETURN_CAT" id="editReturnCat" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                        <button type="submit" class="btn btn-primary">Kaydet</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <!-- Bootstrap JS -->
    

    <script>
        function filterTable() {
            const input = document.getElementById('searchInput');
            const filter = input.value.toLowerCase();
            const table = document.getElementById('dataTableBody');
            const rows = table.getElementsByTagName('tr');
            let visibleCount = 0;

            for (let i = 0; i < rows.length; i++) {
                const cells = rows[i].getElementsByTagName('td');
                let found = false;
                
                for (let j = 0; j < cells.length; j++) {
                    const cell = cells[j];
                    if (cell) {
                        const textValue = cell.textContent || cell.innerText;
                        if (textValue.toLowerCase().indexOf(filter) > -1) {
                            found = true;
                            break;
                        }
                    }
                }
                
                if (found) {
                    rows[i].style.display = '';
                    visibleCount++;
                } else {
                    rows[i].style.display = 'none';
                }
            }

            document.getElementById('recordCount').textContent = visibleCount + ' kayıt';
        }

        function clearForm() {
            document.getElementById('modalTitle').textContent = 'Yeni Kategori';
            document.getElementById('editId').value = '';
            document.getElementById('editReturnCat').value = '';
            document.getElementById('editForm').action = 'index.cfm?fuseaction=admin.list_return_cats&action=add';
        }

        function editRecord(id, cat) {
            document.getElementById('modalTitle').textContent = 'Kategori Düzenle';
            document.getElementById('editId').value = id;
            document.getElementById('editReturnCat').value = cat;
            document.getElementById('editForm').action = 'index.cfm?fuseaction=admin.list_return_cats&action=update';
            
            const modal = new bootstrap.Modal(document.getElementById('editModal'));
            modal.show();
        }
    </script>
</body>
</html>
