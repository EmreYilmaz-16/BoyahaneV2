<!--- json_type parametresi 1 : tab menü, 2: page bar, null : page designer 
	objectID parametresi gelirse pageBar duzenleniyor
--->
	
<cfcomponent>
	<cffunction name="params" access="remote" returntype="struct">
    	<cfscript>
			var systemParam.dsn = 'catalyst_prod';
			var systemParam.dsn3 = 'catalyst_prod_1';
			if(isDefined("session.ep.PERIOD_YEAR")){
				var systemParam.dsn2 = 'catalyst_prod_#session.ep.PERIOD_YEAR#_1';
			}else{
			var systemParam.dsn2 = 'catalyst_prod_#year(now())#_1';}
			var systemParam.uploadFolder = '\\devappsrv\documents\';
			dir_seperator = '\';
		</cfscript>
        <cfreturn systemParam>
    </cffunction>
	<cffunction method="post" name="changeSystemParams"  access="remote" returntype="struct">
		<cfargument  name="CompanyId">
		<cfargument  name="PeriodYear">
		<cfscript>
			var systemParam.dsn = 'catalyst_prod';
			var systemParam.dsn3 = 'catalyst_prod_#arguments.CompanyId#';
			
			//	var systemParam.dsn2 = 'catalyst_prod_#arguments.PeriodYear#_#arguments.CompanyId#';
			
			var systemParam.dsn2 = 'catalyst_prod_#arguments.PeriodYear#_#arguments.CompanyId#';
			var systemParam.uploadFolder = '\\devappsrv\documents\';
			dir_seperator = '\';
		</cfscript>
        <cfreturn systemParam>
    </cffunction>
</cfcomponent>