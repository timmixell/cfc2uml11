<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfheader name="Content-Type" value="text/xml">
<cfparam name="ideeventinfo">
<cflog log="Application" text="#toString(xmlParse(ideeventinfo))#">
<response>
    <ide>
        <commands>
            <command name="refreshfolder">
	            <params>
	            	<param key="foldername" value="" />
	            </params>
            </command>
        </commands>
    </ide>
</response>