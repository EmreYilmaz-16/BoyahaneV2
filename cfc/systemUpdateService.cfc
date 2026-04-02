<cfcomponent output="false">

    <cffunction name="getSettings" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset var result = {success=true}>
        <cfquery name="qSettings" datasource="boyahane">
            SELECT * FROM system_update_settings ORDER BY setting_id ASC LIMIT 1
        </cfquery>
        <cfif qSettings.recordCount>
            <cfset result.data = {
                repo_url = qSettings.repo_url,
                repo_branch = qSettings.repo_branch,
                repo_local_path = qSettings.repo_local_path,
                check_releases = qSettings.check_releases,
                auto_pull_on_release = qSettings.auto_pull_on_release,
                docker_compose_cmd = qSettings.docker_compose_cmd,
                remote_db_host = qSettings.remote_db_host,
                remote_db_port = qSettings.remote_db_port,
                remote_db_name = qSettings.remote_db_name,
                remote_db_user = qSettings.remote_db_user,
                remote_db_password = qSettings.remote_db_password,
                remote_db_schema = qSettings.remote_db_schema
            }>
        <cfelse>
            <cfset result.success = false>
            <cfset result.message = "Ayar kaydı bulunamadı.">
        </cfif>
        <cfreturn result>
    </cffunction>

    <cffunction name="saveSettings" access="remote" returntype="struct" returnformat="json" output="false" method="post">
        <cfset var result = {success=true, message="Ayarlar kaydedildi."}>
        <cfset var payload = deserializeJSON(toString(getHttpRequestData().content))>

        <cfquery datasource="boyahane">
            UPDATE system_update_settings
            SET
                repo_url = <cfqueryparam value="#payload.repo_url#" cfsqltype="cf_sql_varchar">,
                repo_branch = <cfqueryparam value="#payload.repo_branch#" cfsqltype="cf_sql_varchar">,
                repo_local_path = <cfqueryparam value="#payload.repo_local_path#" cfsqltype="cf_sql_varchar">,
                check_releases = <cfqueryparam value="#payload.check_releases#" cfsqltype="cf_sql_boolean">,
                auto_pull_on_release = <cfqueryparam value="#payload.auto_pull_on_release#" cfsqltype="cf_sql_boolean">,
                docker_compose_cmd = <cfqueryparam value="#payload.docker_compose_cmd#" cfsqltype="cf_sql_varchar">,
                remote_db_host = <cfqueryparam value="#payload.remote_db_host#" null="#not len(trim(payload.remote_db_host))#" cfsqltype="cf_sql_varchar">,
                remote_db_port = <cfqueryparam value="#payload.remote_db_port#" null="#not len(trim(payload.remote_db_port))#" cfsqltype="cf_sql_integer">,
                remote_db_name = <cfqueryparam value="#payload.remote_db_name#" null="#not len(trim(payload.remote_db_name))#" cfsqltype="cf_sql_varchar">,
                remote_db_user = <cfqueryparam value="#payload.remote_db_user#" null="#not len(trim(payload.remote_db_user))#" cfsqltype="cf_sql_varchar">,
                remote_db_password = <cfqueryparam value="#payload.remote_db_password#" null="#not len(trim(payload.remote_db_password))#" cfsqltype="cf_sql_varchar">,
                remote_db_schema = <cfqueryparam value="#payload.remote_db_schema#" null="#not len(trim(payload.remote_db_schema))#" cfsqltype="cf_sql_varchar">,
                updated_at = NOW()
            WHERE setting_id = (SELECT setting_id FROM system_update_settings ORDER BY setting_id ASC LIMIT 1)
        </cfquery>

        <cfreturn result>
    </cffunction>

    <cffunction name="checkUpdates" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset var result = {success=true, update_available=false}>
        <cfset var settings = getSettings()>
        <cfset var gitOutput = "">
        <cfset var branchRef = "">
        <cfset var remoteHash = "">
        <cfset var localHash = "">

        <cfif not settings.success>
            <cfreturn settings>
        </cfif>

        <cfset branchRef = "refs/heads/#settings.data.repo_branch#">

        <cftry>
            <cfexecute name="git"
                arguments="-C #settings.data.repo_local_path# rev-parse HEAD"
                variable="localHash"
                timeout="20" />

            <cfexecute name="git"
                arguments="ls-remote #settings.data.repo_url# #branchRef#"
                variable="gitOutput"
                timeout="30" />

            <cfif len(trim(gitOutput))>
                <cfset remoteHash = listFirst(trim(gitOutput), chr(9))>
            </cfif>

            <cfset result.local_hash = trim(localHash)>
            <cfset result.remote_hash = trim(remoteHash)>
            <cfset result.update_available = (len(result.remote_hash) and result.remote_hash neq result.local_hash)>
            <cfset result.message = result.update_available ? "Yeni commit/release bulundu." : "Depo güncel.">

            <cfif settings.data.check_releases and findNoCase("github.com", settings.data.repo_url)>
                <cfset appendReleaseFromGitHub(settings.data.repo_url)>
            </cfif>

            <cfif result.update_available and settings.data.auto_pull_on_release>
                <cfset result.apply_result = applyUpdates()>
            </cfif>

            <cfcatch>
                <cfset result.success = false>
                <cfset result.message = "Güncelleme kontrolü başarısız: #cfcatch.message#">
                <cfset result.detail = cfcatch.detail>
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="applyUpdates" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset var result = {success=true}>
        <cfset var settings = getSettings()>
        <cfset var pullOut = "">
        <cfset var dockerOut = "">
        <cfset var dockerComposeExists = "">
        <cfset var dockerExists = "">
        <cfset var dockerCmd = trim(settings.data.docker_compose_cmd)>
        <cfset var shellSafeCmd = "">

        <cfif not settings.success>
            <cfreturn settings>
        </cfif>

        <cfif not len(dockerCmd)>
            <cfset dockerCmd = "docker compose up -d --build">
        </cfif>

        <cftry>
            <cfexecute name="git"
                arguments="-C #settings.data.repo_local_path# pull origin #settings.data.repo_branch#"
                variable="pullOut"
                timeout="120" />

            <cfexecute name="sh"
                arguments="-lc 'command -v docker-compose >/dev/null 2>&1 && echo yes || echo no'"
                variable="dockerComposeExists"
                timeout="10" />

            <cfexecute name="sh"
                arguments="-lc 'command -v docker >/dev/null 2>&1 && echo yes || echo no'"
                variable="dockerExists"
                timeout="10" />

            <cfif trim(dockerComposeExists) neq "yes" and trim(dockerExists) neq "yes">
                <cfset result.success = false>
                <cfset result.message = "Pull tamamlandı ancak Docker çalıştırılamadı: Sunucuda docker veya docker-compose komutu bulunamadı.">
                <cfset result.git_output = pullOut>
                <cfset result.executed_docker_cmd = dockerCmd>
                <cfreturn result>
            </cfif>

            <cfif trim(dockerComposeExists) neq "yes" and trim(dockerExists) eq "yes">
                <cfset dockerCmd = replaceNoCase(dockerCmd, "docker-compose", "docker compose", "all")>
            </cfif>

            <cfset shellSafeCmd = replace(dockerCmd, "'", "'\''", "all")>

            <cfexecute name="sh"
                arguments="-lc '#shellSafeCmd#'"
                variable="dockerOut"
                timeout="240" />

            <cfset result.message = "Güncellemeler çekildi ve docker build tamamlandı.">
            <cfset result.git_output = pullOut>
            <cfset result.docker_output = dockerOut>
            <cfset result.executed_docker_cmd = dockerCmd>

            <cfcatch>
                <cfset result.success = false>
                <cfset result.message = "Pull/build işlemi başarısız: #cfcatch.message#">
                <cfset result.detail = cfcatch.detail>
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="compareSchema" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset var result = {success=true, missing_tables=[]}>
        <cfset var settings = getSettings()>
        <cfset var localTables = "">
        <cfset var remoteTables = "">
        <cfset var remoteDatasource = {}>
        <cfset var localMap = {}>
        <cfset var i = 0>

        <cfif not settings.success>
            <cfreturn settings>
        </cfif>

        <cfif not len(trim(settings.data.remote_db_host)) or not len(trim(settings.data.remote_db_name)) or not len(trim(settings.data.remote_db_user))>
            <cfset result.success = false>
            <cfset result.message = "Uzak DB bilgileri eksik. Ayarlardan doldurun.">
            <cfreturn result>
        </cfif>

        <cfset remoteDatasource = {
            class: "org.postgresql.Driver",
            connectionString: "jdbc:postgresql://#settings.data.remote_db_host#:#settings.data.remote_db_port#/#settings.data.remote_db_name#",
            username: settings.data.remote_db_user,
            password: settings.data.remote_db_password
        }>

        <cftry>
            <cfset localTables = queryExecute(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = :schema AND table_type='BASE TABLE'",
                {schema:{value:settings.data.remote_db_schema,cfsqltype:"cf_sql_varchar"}},
                {datasource:"boyahane"}
            )>

            <cfset remoteTables = queryExecute(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = :schema AND table_type='BASE TABLE'",
                {schema:{value:settings.data.remote_db_schema,cfsqltype:"cf_sql_varchar"}},
                {datasource:remoteDatasource}
            )>

            <cfloop query="localTables">
                <cfset localMap[localTables.table_name] = true>
            </cfloop>

            <cfloop query="remoteTables">
                <cfif not structKeyExists(localMap, remoteTables.table_name)>
                    <cfset arrayAppend(result.missing_tables, remoteTables.table_name)>
                </cfif>
            </cfloop>

            <cfset result.message = arrayLen(result.missing_tables) ? "Eksik tablolar bulundu." : "Şemalar tablo seviyesinde uyumlu.">

            <cfcatch>
                <cfset result.success = false>
                <cfset result.message = "Şema karşılaştırma hatası: #cfcatch.message#">
                <cfset result.detail = cfcatch.detail>
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="addReleaseNote" access="remote" returntype="struct" returnformat="json" output="false" method="post">
        <cfset var payload = deserializeJSON(toString(getHttpRequestData().content))>
        <cfset var result = {success=true, message="Sürüm notu eklendi."}>

        <cfquery datasource="boyahane">
            INSERT INTO system_release_notes (release_tag, release_name, release_url, published_at, note_body, source_type)
            VALUES (
                <cfqueryparam value="#payload.release_tag#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#payload.release_name#" null="#not len(trim(payload.release_name))#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#payload.release_url#" null="#not len(trim(payload.release_url))#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#payload.published_at#" null="#not len(trim(payload.published_at))#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#payload.note_body#" null="#not len(trim(payload.note_body))#" cfsqltype="cf_sql_longvarchar">,
                'manual'
            )
            ON CONFLICT (release_tag) DO UPDATE SET
                release_name = EXCLUDED.release_name,
                release_url = EXCLUDED.release_url,
                published_at = EXCLUDED.published_at,
                note_body = EXCLUDED.note_body
        </cfquery>

        <cfreturn result>
    </cffunction>

    <cffunction name="getReleaseNotes" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset var result = {success=true}>
        <cfset var notes = []>

        <cfquery name="qNotes" datasource="boyahane">
            SELECT note_id, release_tag, release_name, release_url, published_at, note_body, source_type, created_at
            FROM system_release_notes
            ORDER BY COALESCE(published_at, created_at) DESC, note_id DESC
            LIMIT 50
        </cfquery>

        <cfloop query="qNotes">
            <cfset arrayAppend(notes, {
                note_id = qNotes.note_id,
                release_tag = qNotes.release_tag,
                release_name = qNotes.release_name,
                release_url = qNotes.release_url,
                published_at = qNotes.published_at,
                note_body = qNotes.note_body,
                source_type = qNotes.source_type
            })>
        </cfloop>

        <cfset result.data = notes>
        <cfreturn result>
    </cffunction>

    <cffunction name="appendReleaseFromGitHub" access="private" returntype="void" output="false">
        <cfargument name="repoUrl" type="string" required="true">
        <cfset var cleanPath = "">
        <cfset var apiUrl = "">
        <cfset var releaseData = "">

        <cfset cleanPath = rereplace(arguments.repoUrl, "^https?://github\.com/", "", "all")>
        <cfset cleanPath = rereplace(cleanPath, "\.git$", "", "all")>
        <cfset apiUrl = "https://api.github.com/repos/#cleanPath#/releases/latest">

        <cfhttp url="#apiUrl#" method="get" result="releaseData" timeout="20">
            <cfhttpparam type="header" name="User-Agent" value="BoyahaneV2-UpdateCenter">
            <cfhttpparam type="header" name="Accept" value="application/vnd.github+json">
        </cfhttp>

        <cfif releaseData.statusCode contains "200" and isJSON(releaseData.fileContent)>
            <cfset var rel = deserializeJSON(releaseData.fileContent)>
            <cfif structKeyExists(rel, "tag_name") and len(rel.tag_name)>
                <cfquery datasource="boyahane">
                    INSERT INTO system_release_notes (release_tag, release_name, release_url, published_at, note_body, source_type)
                    VALUES (
                        <cfqueryparam value="#rel.tag_name#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#rel.name#" null="#not len(trim(rel.name))#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#rel.html_url#" null="#not len(trim(rel.html_url))#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#rel.published_at#" null="#not len(trim(rel.published_at))#" cfsqltype="cf_sql_timestamp">,
                        <cfqueryparam value="#left(rel.body, 8000)#" null="#not len(trim(rel.body))#" cfsqltype="cf_sql_longvarchar">,
                        'github'
                    )
                    ON CONFLICT (release_tag) DO NOTHING
                </cfquery>
            </cfif>
        </cfif>
    </cffunction>

</cfcomponent>
