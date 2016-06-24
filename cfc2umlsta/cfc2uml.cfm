<html>
	<head>
		<style>
			input[type='text'],input[type='file']{
				width:200px;
				height:23px;
				padding:2px;
				margin:5px;
			}
		</style>
		<script type="text/javascript">
			function check(evsrc){
				var fld = document.getElementById("trfolder");
				var fil = document.getElementById("trfile");
				
				switch (evsrc.value.toLowerCase()){
					case "folder":
						fld.disabled=!evsrc.checked;
						fil.disabled=evsrc.checked;				
					break;
					case "file":
						fld.disabled=evsrc.checked;
						fil.disabled=!evsrc.checked;					
					break;
				}
			}
			function checkInput(){
				var retval=false;
				var fld = document.getElementById("trfolder");
				var fil = document.getElementById("trfile");
				var ottype = document.getElementsByName("transtype");
				var ttype = '';

				for (i=0;i<=ottype.length;++i){
					if (ottype[i].checked){
						ttype = ottype[i].value;
						break;
					}
				}


				switch (ttype){
					case "folder":
						retval=(fld.value!='');
					break;
					case "file":
						retval=(fil.value!='');
					break;
				}
				return retval;
			}
		</script>
	</head>
	<body>
		
		<form name="frmCFC2UML" method="post" action="translate.cfm" onsubmit="return checkInput();">
			<h3>Enter folder or file location relative to <cfoutput>#expandPath("../")#</cfoutput>.</h3>
			Scan folder for CFCs:<br>
			<input type="radio" value="folder" name="transtype" id="transtype" checked onclick="check(this)"> 
			<input type="text" name="trfolder" id="trfolder">
			(i.e. "cfc")
			<br>
			Or select single file:<br>
			<input type="radio" value="file" name="transtype" onclick="check(this)"> 
			<input type="text" name="trfile" id="trfile" disabled="true">
			(i.e. "cfc/person.cfc")
			<br>
			<input type="submit" name="trsubmit" value="Translate!">
		</form>
	</body>
</html>