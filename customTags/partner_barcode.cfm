<cfset Randomize(round(rand()*1000000))/>
<cfparam name="attributes.value" default="Workcube 2D Barcode">
<cfparam name="attributes.resolution" default="50">
<cfparam name="attributes.show" default="0">
<cfparam name="attributes.id" default="barcode_#round(rand()*10000000)#">
<cfparam name="attributes.path" default="/documents/barcode">
<cfparam name="attributes.shape" default="SQUARE">
<cfparam name="attributes.format" default="png">
<cfparam name="attributes.type" default="datamatrix">
<cfparam name="attributes.width" default="100">
<cfparam name="attributes.height" default="40">
<cfparam name="attributes.rotate" default="0">
<cfset unique_number = round(rand()*10000000)>

<cfif attributes.type eq 'datamatrix'>
	<cfset Reader 	= createObject("java","org.krysalis.barcode4j.impl.datamatrix.DataMatrixBean")>
    <cfset sharpner	= createObject("java","org.krysalis.barcode4j.impl.datamatrix.SymbolShapeHint")>
    <cfset out 	= CreateObject("java","java.io.FileOutputStream").Init(CreateObject("java","java.io.File").Init('#attributes.path##attributes.id#.#attributes.format#'))/>
    
    <cfswitch expression="#attributes.format#">
        <cfcase value="eps">
            <!--- EPS file format --->
            <cfset canvas 	= CreateObject('java','org.krysalis.barcode4j.output.eps.EPSCanvasProvider').init(out,0)>
            <cfset ctype	= "application/postscript">
        </cfcase>
        <cfcase value="jpg">
            <!--- JPG file format --->
            <cfset BufferedImage 	= CreateObject('java',"java.awt.image.BufferedImage")>
            <cfset canvas = CreateObject('java','org.krysalis.barcode4j.output.bitmap.BitmapCanvasProvider').init(out, "image/jpeg", JavaCast('double',attributes.resolution), BufferedImage.TYPE_BYTE_BINARY, false, 0)>
            <cfset ctype	= "image/jpeg">
        </cfcase>
        <cfdefaultcase>
            <!--- PNG file format --->
            <cfset BufferedImage 	= CreateObject('java',"java.awt.image.BufferedImage")>
            <cfset canvas = CreateObject('java','org.krysalis.barcode4j.output.bitmap.BitmapCanvasProvider').init(out, "image/x-png", JavaCast('double',attributes.resolution), BufferedImage.TYPE_BYTE_BINARY, false, 0)>
            <cfset ctype	= "image/png">
        </cfdefaultcase>
    </cfswitch>
    
    <cfset Reader.setModuleWidth(JavaCast('int',1))>
    
    <cfswitch expression="#attributes.shape#">
        <cfcase value="SQUARE">
            <cfset Reader.setShape(sharpner.FORCE_SQUARE)>
        </cfcase>
        <cfcase value="RECTANGLE">
            <cfset Reader.setShape(sharpner.FORCE_RECTANGLE)>
        </cfcase>
        <cfdefaultcase>
            <cfset Reader.setShape(sharpner.FORCE_NONE)>
        </cfdefaultcase>
    </cfswitch>
    <cfset Reader.generateBarcode(canvas, JavaCast('string',attributes.value))>
    <cfset canvas.finish()>
    <cfset out.close()>
    <cfif attributes.show eq 1>
        <cfimage action="writeToBrowser" source="#attributes.path##attributes.id#.#attributes.format#">
    </cfif>
<cfelse>
    <cftry>
        <cfswitch expression="#attributes.type#">
            <cfcase value="ean13">
                <cfset writer = createObject("java","com.google.zxing.oned.EAN13Writer").init() />
                <cfset b_format = "BarcodeFormat.EAN_13">
				<cfif len(attributes.value) eq 12>
                    <cfset kontrol = attributes.value>
                    <cfset toplam_cift = 0>
                    <cfset toplam_tek = 0>
                    <cfset toplam = 0>
                    
                    <cfloop index="aa" from="1" to="12">
                         <cfif (aa mod 2) eq 1>
                            <cfset toplam_cift = toplam_cift + Mid(kontrol,aa,1)>
                        <cfelse>
                            <cfset toplam_tek = toplam_tek + Mid(kontrol,aa,1)>
                        </cfif>
                    </cfloop>
                    <cfset toplam_tek = toplam_tek * 3>
                    <cfset toplam = toplam_cift + toplam_tek>
                    <cfset kontrol_degiskeni = toplam mod 10>
                    <cfset attributes.value = attributes.value & kontrol_degiskeni>
                </cfif>
            </cfcase>
            <cfcase value="ean8">
                <cfset writer = createObject("java","com.google.zxing.oned.EAN8Writer").init() />
                <cfset b_format = "BarcodeFormat.EAN_8">
            </cfcase>
            <cfcase value="code128">
                <cfset writer = createObject("java","com.google.zxing.oned.Code128Writer").init() />
                <cfset b_format = "BarcodeFormat.CODE_128">
            </cfcase>
            <cfcase value="qrcode">
                <cfset writer = createObject("java","com.google.zxing.qrcode.QRCodeWriter").init() />
                <cfset b_format = "BarcodeFormat.QR_CODE">
            </cfcase>
            <cfcase value="code39">
                <cfset writer = createObject("java","com.google.zxing.oned.Code39Writer").init() />
                <cfset b_format = "BarcodeFormat.CODE_39">
            </cfcase>
            <cfcase value="itf">
                <cfset writer = createObject("java","com.google.zxing.oned.ITFWriter").init() />
                <cfset b_format = "BarcodeFormat.ITF">
            </cfcase>
            <cfcase value="upc_a">
                <cfset writer = createObject("java","com.google.zxing.oned.UPCAWriter").init() />
                <cfset b_format = "BarcodeFormat.UPC_A">
            </cfcase>
            <cfcase value="pdf417">
                <cfset writer = createObject("java","com.google.zxing.oned.PDF417Writer").init() />
                <cfset b_format = "BarcodeFormat.PDF417">
            </cfcase>
        </cfswitch> 	
                            
        <cfset qr_value = ReplaceList(#attributes.value#,'Ş,ş,İ,ı,Ğ,ğ','S,s,I,i,G,g')>
        <cfset BarcodeFormat = createObject("java","com.google.zxing.BarcodeFormat") />
        
        <cfset bitMatrix = writer.encode(qr_value,evaluate(b_format), attributes.width, attributes.height)>
        <cfset converter = createObject("java","com.google.zxing.client.j2se.MatrixToImageWriter")>
        <cfset buff = converter.toBufferedImage( bitMatrix ) />
        <cfset img = ImageNew( buff ) /> 
        
        <cfif attributes.show eq 1>
        	<cfif attributes.rotate neq 1>
	            <cfimage id="#attributes.id#" action="writeToBrowser" source="#img#" format="jpg">
            <cfelse>
            	<cfimage source="#img#" name="barcod" overwrite="yes" action="write" destination="\documents\barcode\barkod#attributes.value#.jpg">
            	<cfimage name="#attributes.id#2" id="#attributes.id#2" action="rotate" angle="90" source="\documents\barcode\barkod#attributes.value#.jpg" format="jpg">
                <cfimage source="\documents\barcode\barkod#attributes.value#.jpg" name="barkod#attributes.value#" action="write" destination="\documents\barcode\barkod#attributes.value#.jpg" overwrite = "yes">
                <cfoutput>
	                <!---<img id="barcode#attributes.value#_#unique_number#" src="\documents\barcode\barkod#attributes.value#.jpg"/><!---  style="-webkit-transform: rotate(270deg); -moz-transform: rotate(270deg); -ms-transform: rotate(270deg); -o-transform: rotate(270deg); transform: rotate(270deg);"  --->--->
					<cfset myImage=ImageNew("\documents\barcode\barkod#attributes.value#.jpg")>
                    <cfset ImageSetAntialiasing(myImage,"on")>
                    <!--- Rotate the image by 10 degrees. --->
                    <cfset ImageRotate(myImage,90)>
                    <cfimage source="#myImage#" action="writeToBrowser">
                </cfoutput>
				<!---<script type="text/javascript" src="/JS/jquery_1_5.js"></script>
                <script type="text/javascript" src="/JS/jQueryRotate.js"></script>
                <script type="text/javascript">
                <cfoutput>
                    $(document).ready(function()
                {
                    $("##barcode#attributes.value#_#unique_number#").rotate(270);
                });
                </cfoutput>
                </script>--->
            </cfif>
        </cfif>
	<cfcatch>
    	<cfoutput><cfdump  var="#cfcatch#"></cfoutput>	
    </cfcatch>
    </cftry>
</cfif>
