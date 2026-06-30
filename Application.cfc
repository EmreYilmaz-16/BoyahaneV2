<!-----------------------------------------------------------------------

*************************************************************************
		Copyright Katalizör Bilgi Teknolojileri Hizmetleri A.Ş www.workcube.com
*************************************************************************

Application	: 	W O R K C U B E    C A T A L Y S T
Motto		:	e-business Now!
Version		:	Cloud Edition New Generation

Version Leader		:	Omer Turhan
Development Team	:	Fatih Ayık, M.Emin Yaşartürk, Cemil Durgan, Emrah Kumru, Semih Akartuna ve tüm yazılım ekibi

Description			:
		Workcube is an e-business platform for corporates.
*************************************************************************
------------------------------------------------------------------------->
<cfcomponent displayname="Application" output="true" hint="Uygulamayı yönetir.">	
	<cfscript>
		this.name = hash(getCurrentTemplatePath()) & 'WORKCUBE';
		this.siteName = 'boyahane.rasihcelik.com';
		this.sessionManagement = True;
		this.sessionTimeout = CreateTimeSpan(0,2,0,0);
		this.clientManagement = True;
		this.setClientCookies = True;
		this.secureJSON = false;
		this.secureJSONPrefix = "";
		this.customtagpaths = '';
      	this.customtagpaths = ListAppend(this.customtagpaths,getDirectoryFromPath(getCurrentTemplatePath()) & "customTags");
		this.customtagpaths = ListAppend(this.customtagpaths,getDirectoryFromPath(getCurrentTemplatePath()) & "Utility/customtag");
		 this.blockedExtForFileUpload = "asp,aspx,cfc,do,jsp,jspx,php";
		// PostgreSQL DataSource Configuration
		this.datasources["boyahane"] = {
			class: 'org.postgresql.Driver',
			bundleName: 'org.postgresql.jdbc',
			bundleVersion: '42.7.2',
			connectionString: 'jdbc:postgresql://postgres:5432/boyahane?useUnicode=true&characterEncoding=UTF-8',
			username: 'boyahane_user',
			password: 'boyahane_pass123',
			connectionLimit: 100,
			connectionTimeout: 1,
			metaCacheTimeout: 60000,
			blob: true,
			clob: true,
			validate: false
		};
		
		// Default DSN
		this.datasource = "boyahane";
	</cfscript>
    <cfset Request.self="index.cfm">
    <!--- Sayfa request özellikleri --->
	<cfsetting requesttimeout="300" showdebugoutput="false" enablecfoutputonly="false" />
    
	<!------------------------ on Application Start -------------------------
        Functions:params, objects, langs, functions, workcube_app
	------------------------------------------------------------------------>
	<cffunction name="OnApplicationStart" access="public" returntype="boolean" output="false" hint="Uygulama başladığı anda çalıştırılacak kodlar. Tek defa çalıştırır.">
		<!--- Application başlatma işlemleri buraya eklenebilir --->
		<cfset application.userFavoritesTableReady = false>
		<cfset application.fuseactionProductivityTablesReady = false>
		<cfset loadSiteParams()>
		<cfreturn true />
	</cffunction>

	<cffunction name="loadSiteParams" access="public" returntype="void" output="false"
			hint="boyahane_params tablosunu application.siteParams struct'ına yükler. Her application restart'ta ve gerektiğinde çağrılır.">
		<cflock scope="application" type="exclusive" timeout="10">
			<cfset application.siteParams = structNew()>
			<cftry>
				<cfquery name="qParams" datasource="#this.datasource#">
					SELECT parametre_adi, deger FROM boyahane_params
				</cfquery>
				<cfloop query="qParams">
					<cfset application.siteParams[parametre_adi] = deger>
				</cfloop>
				<cfcatch type="any">
					<cflog file="application" type="warning" text="boyahane_params yüklenemedi: #cfcatch.message#">
				</cfcatch>
			</cftry>
		</cflock>
	</cffunction>

	<cffunction name="ensureUserFavoritesTable" access="private" returntype="void" output="false" hint="Favoriler tablosu yoksa oluşturur.">
		<cflock scope="application" type="exclusive" timeout="10">
			<cfif structKeyExists(application, "userFavoritesTableReady") AND application.userFavoritesTableReady>
				<cfreturn>
			</cfif>

			<cftry>
				<cfquery datasource="#this.datasource#">
					CREATE TABLE IF NOT EXISTS user_favorites (
						favorite_id   SERIAL          PRIMARY KEY,
						user_id       INTEGER         NOT NULL,
						fuseaction    VARCHAR(255)    NOT NULL,
						page_title    VARCHAR(255)    NOT NULL DEFAULT '',
						page_icon     VARCHAR(100)    NOT NULL DEFAULT 'fas fa-star',
						display_order INTEGER         NOT NULL DEFAULT 0,
						added_date    TIMESTAMP       NOT NULL DEFAULT NOW(),

						CONSTRAINT fk_user_favorites_user
							FOREIGN KEY (user_id) REFERENCES kullanicilar(id) ON DELETE CASCADE,

						CONSTRAINT uq_user_fuseaction
							UNIQUE (user_id, fuseaction)
					)
				</cfquery>

				<cfquery datasource="#this.datasource#">
					CREATE INDEX IF NOT EXISTS idx_user_favorites_user
					ON user_favorites (user_id)
				</cfquery>

				<cfquery datasource="#this.datasource#">
					COMMENT ON TABLE user_favorites IS 'Kullanıcılara ait sayfa kısayolları/favoriler'
				</cfquery>

				<cfset application.userFavoritesTableReady = true>
				<cfcatch type="any">
					<cfset application.userFavoritesTableReady = false>
					<cflog file="application" type="warning" text="user_favorites tablosu hazırlanamadı: #cfcatch.message# - #cfcatch.detail#">
				</cfcatch>
			</cftry>
		</cflock>
	</cffunction>


	<cffunction name="ensureFuseactionProductivityTables" access="private" returntype="void" output="false" hint="Fuseaction bazlı not, görev ve takip tablolarını hazırlar.">
		<cflock scope="application" type="exclusive" timeout="10">
			<cfif structKeyExists(application, "fuseactionProductivityTablesReady") AND application.fuseactionProductivityTablesReady>
				<cfreturn>
			</cfif>
			<cftry>
				<cfquery datasource="#this.datasource#">
					CREATE TABLE IF NOT EXISTS fuseaction_notes (
						note_id SERIAL PRIMARY KEY,
						fuseaction VARCHAR(255) NOT NULL,
						note_title VARCHAR(255) NOT NULL,
						note_body TEXT NOT NULL DEFAULT '',
						created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
						updated_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
						created_at TIMESTAMP NOT NULL DEFAULT NOW(),
						updated_at TIMESTAMP NOT NULL DEFAULT NOW()
					)
				</cfquery>
				<cfquery datasource="#this.datasource#">CREATE INDEX IF NOT EXISTS idx_fuseaction_notes_fuseaction ON fuseaction_notes (fuseaction)</cfquery>
				<cfquery datasource="#this.datasource#">
					CREATE TABLE IF NOT EXISTS fuseaction_tasks (
						task_id SERIAL PRIMARY KEY,
						fuseaction VARCHAR(255) NOT NULL,
						task_title VARCHAR(255) NOT NULL,
						task_description TEXT NOT NULL DEFAULT '',
						stage VARCHAR(30) NOT NULL DEFAULT 'beklemede',
						created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
						updated_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
						created_at TIMESTAMP NOT NULL DEFAULT NOW(),
						updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
						CONSTRAINT chk_fuseaction_tasks_stage CHECK (stage IN ('beklemede','calisiliyor','bitti'))
					)
				</cfquery>
				<cfquery datasource="#this.datasource#">CREATE INDEX IF NOT EXISTS idx_fuseaction_tasks_fuseaction ON fuseaction_tasks (fuseaction)</cfquery>
				<cfquery datasource="#this.datasource#">
					CREATE TABLE IF NOT EXISTS fuseaction_task_followups (
						followup_id SERIAL PRIMARY KEY,
						task_id INTEGER NOT NULL REFERENCES fuseaction_tasks(task_id) ON DELETE CASCADE,
						followup_note TEXT NOT NULL,
						created_by INTEGER REFERENCES kullanicilar(id) ON DELETE SET NULL,
						created_at TIMESTAMP NOT NULL DEFAULT NOW()
					)
				</cfquery>
				<cfquery datasource="#this.datasource#">CREATE INDEX IF NOT EXISTS idx_fuseaction_task_followups_task ON fuseaction_task_followups (task_id)</cfquery>
				<cfquery datasource="#this.datasource#">
					INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
					SELECT 'Sayfa Notları', 21, false, 'standart', 'productivity.page_notes', '/productivity/display/page_notes.cfm', 980, true
					WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'productivity.page_notes')
				</cfquery>
				<cfquery datasource="#this.datasource#">
					INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
					SELECT 'Sayfa Görevleri', 21, false, 'standart', 'productivity.page_tasks', '/productivity/display/page_tasks.cfm', 981, true
					WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'productivity.page_tasks')
				</cfquery>
				<cfquery datasource="#this.datasource#">
					INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
					SELECT 'Not ve Görev Merkezi', 21, true, 'standart', 'productivity.overview', '/productivity/display/productivity_overview.cfm', 979, true
					WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'productivity.overview')
				</cfquery>
				<cfset application.fuseactionProductivityTablesReady = true>
				<cfcatch type="any">
					<cfset application.fuseactionProductivityTablesReady = false>
					<cflog file="application" type="warning" text="Fuseaction productivity tabloları hazırlanamadı: #cfcatch.message# - #cfcatch.detail#">
				</cfcatch>
			</cftry>
		</cflock>
	</cffunction>

	<!---
	*************************************************************************
		OnSessionStart
	*************************************************************************
		Description : ColdFusion'a ilk istek geldiği anda çalışır. CFID,CFTOKEN, SESSIONID gibi değerler burada otomatik oluşur. Kullanıcı giriş ekranından giriş yaptığı zaman oluşan session ile alakası yoktur.
	--->
	<cffunction name="OnSessionStart" access="public" returntype="void" output="false" hint="Kullanıcı oturumu başladığında çalıştırılacak kodlar.">
		<cfreturn/>
	</cffunction>

    <!---
	<cffunction name="OnRequestStart" access="public" returntype="boolean" output="false" hint="Fires at first part of page processing.">
		<cfargument name="TargetPage" type="string" required="true" />
 
		<cfreturn true />
	</cffunction>
	--->
    
    <!---
		*************************************************************************
			onRequest
		*************************************************************************
			Description : En yoğun kullanılan kısımdır. Sayfa isteğinde bulunulduğunda bu kısım çalışır. OnRequestStart fonksiyonu ajax isteklerinde sorun yaratabildiği için geneli buraya toplanmıştır. Ana amacı genel kontroller yaptıktan sonra index.cfm'e yönlenmektir.
			Başlarında yer alan structAppend işleminin amacı application tarafında tutulan parametrik değerlerin, fonksiyonların sistem içersinde kullanılış şeklini değiştirmemektir. Yazılmadığı takdirde örneğin DSN atamalarının application.dsn şekline dönüştürülmesi gerekirdi.
			Index öncesi gelen kontroller sırasıyla şu şekildedir. 
			Session kontrolü (wmo\w3cfsession.cfm) : Kullanıcı sistemden düşmüştür. Başka bir browser'da oturum açmıştır. Bunlar kontrol ediliyor.
			cf_xml_pers_settings_reader : Kullanıcı XML'i okunur. Açık kapalı gelmesini istediği alanlar burada tutulur. 
			secure : Saldırı girişimleri burada yakalanır.
			control_time_cost : Haftalık zaman harcaması kontrolü
			sessionParams : Session'a özgü parametreler yüklenir. Örneğin dsn_2
			getDeniedPages : Yasaklı-Kısıtlı sayfa kontrolleri
	--->
	<cffunction name="onRequest" returnType="void">
		<cfargument name="targetPage" type="string" required="true" /><!--- Burası index.cfm gelir. Ulaşılmak istenen dosya index.cfm içerisindeki wrkTemplate'tir. --->
		<cfsetting showdebugoutput="no">
		<cfif NOT structKeyExists(application, "userFavoritesTableReady") OR NOT application.userFavoritesTableReady>
			<cfset ensureUserFavoritesTable()>
		</cfif>
		<cfif NOT structKeyExists(application, "siteParams")>
			<cfset loadSiteParams()>
		</cfif>
		<cfif NOT structKeyExists(application, "fuseactionProductivityTablesReady") OR NOT application.fuseactionProductivityTablesReady>
			<cfset ensureFuseactionProductivityTables()>
		</cfif>
			<cfscript>
                attributes=structNew();
                StructAppend(attributes, url, "no");
                StructAppend(attributes, form, "no");
            </cfscript>

            <cfinclude template="#ARGUMENTS.targetPage#" />

		<cfreturn />
	</cffunction>


    <!---
		*************************************************************************
			OnRequestEnd
		*************************************************************************
			Description : İstek bittiği anda çalışır. Ajax sayfalarda sorunlar yaratabiliyor. Log kayıtları için kullanılabilir. Fakat bu durumda da dataları buraya taşımak için network meşgul edilecektir. Bu yüzden log kayıtlarını isteğin sonunda tutuyoruz.
	--->
	<cffunction name="OnRequestEnd" access="public" returntype="void" output="true" hint="Request sonrası çalışır.">
 		<cfreturn />
	</cffunction>
    
    <!---
		*************************************************************************
			OnSessionEnd
		*************************************************************************
			Description : ColdFusion session'ı son bulduğunda kullanılabilir. Catalyst'te herhangi bir şekilde ihtiyaç duyulmuyor. Sistemden çıkışlarda kullanıcın sistem session'ı silinir. Buradaki session CF tarafında tutulan session'dır. Kullanıcı sistemde belirtilen süre boyunca işlem yapmadığında otomatik olarak sonlandırılır. 
	--->
    <cffunction name="OnSessionEnd" access="public" returntype="void" output="false" hint="Session kapanırken çalışır.">
		<cfargument name="SessionScope" type="struct" required="true" />
		<cfargument name="ApplicationScope" type="struct" required="false" default="#StructNew()#"	/>
		<cfreturn />
	</cffunction>

    <!---
		*************************************************************************
			OnApplicationEnd
		*************************************************************************
			Description : Application durduğunda çalışır. Kullanılmıyor. Burada da log atılabilir. Fakat manuel application sonlandırmada çalışmaz
	--->
	<cffunction name="OnApplicationEnd" access="public" returntype="void" output="false" hint="Uygulama sonlandığında çalışır.">
 		<cfargument name="ApplicationScope" type="struct" required="false" default="#StructNew()#" 	/>
		<cfreturn />
	</cffunction>

    <!---
		*************************************************************************
			OnError
		*************************************************************************
			Description : Hata durumlarında devreye girer. error.cfc ile bütünleşiktir. Error.cfc içinde tanımlı olan hatalarda dile bağlı olarak hata ekranları oluşturur. Development mod için detay içerir. Hatalarla Geliştirilecek. 
	--->
    <cffunction name="OnError" access="public" returntype="void" output="true" hint="Hataları raporlar.">
		<cfargument name="Exception" type="any" required="true" />
 		<cfargument name="EventName" type="string" required="false" default="" 	/>
        
		<!--- Hata logla --->
		<cflog file="application" type="error" text="Error in #EventName#: #Exception.message# - #Exception.detail#">
		<cfdump var="#Exception#">
		<!--- Development modunda detaylı göster, production'da friendly message --->
		<cfif structKeyExists(variables, "dsn") and findNoCase("_dev", variables.dsn)>
			<cfdump var="#Exception#">
		<cfelse>
			<cfoutput>
				<h2>Bir hata oluştu</h2>
				<p>İşleminiz sırasında bir hata meydana geldi. Lütfen daha sonra tekrar deneyin.</p>
				<p>Hata Kodu: #CreateUUID()#</p>
			</cfoutput>
		</cfif>
		<cfreturn/>
	</cffunction>    
    
</cfcomponent>
