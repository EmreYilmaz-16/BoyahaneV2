<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfcontent type="text/html" reset="true">
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Menu Service Test</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f5f5f5; }
        .test { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { border-left: 5px solid #28a745; }
        .error { border-left: 5px solid #dc3545; }
        pre { background: #f8f9fa; padding: 10px; overflow: auto; }
    </style>
</head>
<body>
    <h1>Menu Designer Service Test</h1>
    
    <div class="test">
        <h3>1. Test CFC Creation</h3>
        <cfoutput>
        <cftry>
            <cfset menuService = createObject("component", "cfc.menuDesignerService")>
            <p style="color: green;">✓ CFC created successfully</p>
            
            <cfcatch>
                <p style="color: red;">✗ CFC creation failed</p>
                <pre>#cfcatch.message#
#cfcatch.detail#</pre>
            </cfcatch>
        </cftry>
        </cfoutput>
    </div>
    
    <div class="test">
        <h3>2. Test getMenu() Method</h3>
        <cfoutput>
        <cftry>
            <cfset menuService = createObject("component", "cfc.menuDesignerService")>
            <cfset result = menuService.getMenu()>
            
            <cfif structKeyExists(result, "success") and result.success>
                <p style="color: green;">✓ getMenu() executed successfully</p>
                <p>Solutions found: <cfif structKeyExists(result.data, "solutions")>#arrayLen(result.data.solutions)#<cfelse>0</cfif></p>
            <cfelse>
                <p style="color: orange;">⚠ getMenu() returned but with success=false</p>
                <p>Message: <cfif structKeyExists(result, "message")>#result.message#</cfif></p>
            </cfif>
            
            <h4>Raw Result:</h4>
            <pre>#serializeJSON(result, true)#</pre>
            
            <cfcatch>
                <p style="color: red;">✗ getMenu() execution failed</p>
                <pre>#cfcatch.message#
#cfcatch.detail#</pre>
            </cfcatch>
        </cftry>
        </cfoutput>
    </div>
    
    <div class="test">
        <h3>3. Test JSON Serialization</h3>
        <cfoutput>
        <cftry>
            <cfset menuService = createObject("component", "cfc.menuDesignerService")>
            <cfset result = menuService.getMenu()>
            <cfset jsonString = serializeJSON(result)>
            
            <p style="color: green;">✓ JSON serialization successful</p>
            <p>JSON Length: #len(jsonString)# characters</p>
            <p>First 200 chars: <code>#left(jsonString, 200)#...</code></p>
            
            <h4>Full JSON:</h4>
            <pre>#jsonString#</pre>
            
            <cfcatch>
                <p style="color: red;">✗ JSON serialization failed</p>
                <pre>#cfcatch.message#</pre>
            </cfcatch>
        </cftry>
        </cfoutput>
    </div>
    
    <div class="test">
        <h3>4. Test Direct Database Query</h3>
        <cfoutput>
        <cftry>
            <cfquery name="testQuery" datasource="boyahane">
                SELECT COUNT(*) as solution_count FROM pbs_solution WHERE is_active = true
            </cfquery>
            
            <p style="color: green;">✓ Database query successful</p>
            <p>Active solutions in DB: #testQuery.solution_count#</p>
            
            <cfcatch>
                <p style="color: red;">✗ Database query failed</p>
                <pre>#cfcatch.message#
#cfcatch.detail#</pre>
            </cfcatch>
        </cftry>
        </cfoutput>
    </div>
    
    <div class="test">
        <h3>5. Test Session</h3>
        <cfoutput>
            <cfif structKeyExists(session, "authenticated") and session.authenticated>
                <p style="color: green;">✓ Session authenticated</p>
                <p>Username: <cfif structKeyExists(session, "username")>#session.username#<cfelse>N/A</cfif></p>
                <p>Session keys: #structKeyList(session)#</p>
            <cfelse>
                <p style="color: orange;">⚠ Session not authenticated</p>
            </cfif>
        </cfoutput>
    </div>
    
</body>
</html>
