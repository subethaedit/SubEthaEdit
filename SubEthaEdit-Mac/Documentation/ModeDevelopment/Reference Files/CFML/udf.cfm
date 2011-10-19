<cfsetting enablecfoutputonly=true>

<cfscript>
/**
 * Strips all non-numeric characters from a string.
 * Modified by RCamden to use one line of code.
 * 
 * @param str 	 String to format. (Required)
 * @return Returns a string. 
 * @author Mindframe, Inc. (info@mindframe.com) 
 * @version 1, September 6, 2002 
 */
function NumbersOnly(str) {
	return reReplace(str,"[^[:digit:]]","","all");
}
request.udf.NumbersOnly = NumbersOnly;

/**
 * Allows you to specify the mask you want added to your phone number.
 * v2 - code optimized by Ray Camden
 * 
 * @param varInput 	 Phone number to be formatted. (Required)
 * @param varMask 	 Mask to use for formatting. x represents a digit. (Required)
 * @return Returns a string. 
 * @author Derrick Rapley (adrapley@rapleyzone.com) 
 * @version 3, August 30, 2005 
 */
function phoneFormat(varInput, varMask) {
	var curPosition = "";
	var newFormat = "";
	var i = "";

	if(len(trim(varInput))) {
		newFormat = " " & reReplace(varInput,"[^[:digit:]]","","all");
		for (i=1; i lte len(trim(varmask)); i=i+1) {
			curPosition = mid(varMask,i,1);
			if(curPosition neq "x") newFormat = insert(curPosition,newFormat, i) & " ";
		}
	}
	return trim(newFormat);
}
request.udf.phoneFormat = phoneFormat;

/**
 * Tests passed value to see if it is a valid e-mail address (supports subdomain nesting and new top-level domains).
 * Update by David Kearns to support '
 * SBrown@xacting.com pointing out regex still wasn't accepting ' correctly.
 * More TLDs
 * Version 4 by P Farrel, supports limits on u/h
 * 
 * @param str 	 The string to check. (Required)
 * @return Returns a boolean. 
 * @author Jeff Guillaume (SBrown@xacting.comjeff@kazoomis.com) 
 * @version 4, December 30, 2005 
 */
function isEmail(str) {
    return (REFindNoCase("^['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|coop|info|museum|name|jobs|travel))$",
arguments.str) AND len(listGetAt(arguments.str, 1, "@")) LTE 64 AND
len(listGetAt(arguments.str, 2, "@")) LTE 255) IS 1;
}
request.udf.isEmail = isEmail;

/**
 * Convert a date in ISO 8601 format to an ODBC datetime.
 * 
 * @param ISO8601dateString 	 The ISO8601 date string. (Required)
 * @param targetZoneOffset 	 The timezone offset. (Required)
 * @return Returns a datetime. 
 * @author David Satz (david_satz@hyperion.com) 
 * @version 1, September 28, 2004 
 */
function DateConvertISO8601(ISO8601dateString, targetZoneOffset) {
	var rawDatetime = left(ISO8601dateString,10) & " " & mid(ISO8601dateString,12,8);
	
	// adjust offset based on offset given in date string
	if (uCase(mid(ISO8601dateString,20,1)) neq "Z")
		targetZoneOffset = targetZoneOffset -  val(mid(ISO8601dateString,20,3)) ;
	
	return DateAdd("h", targetZoneOffset, CreateODBCDateTime(rawDatetime));

}
request.udf.DateConvertISO8601 = DateConvertISO8601;

/**
 * Returns the last index of an occurrence of a substring in a string from a specified starting position.
 * Big update by Shawn Seley (shawnse@aol.com) -
 * UDF was not accepting third arg for start pos 
 * and was returning results off by one.
 * Modified by RCamden, added var, fixed bug where if no match it return len of str
 * 
 * @param Substr 	 Substring to look for. 
 * @param String 	 String to search. 
 * @param SPos 	 Starting position. 
 * @return Returns the last position where a match is found, or 0 if no match is found. 
 * @author Charles Naumer (cmn@v-works.com) 
 * @version 2, February 14, 2002 
 */
function RFind(substr,str) {
  var rsubstr  = reverse(substr);
  var rstr     = "";
  var i        = len(str);
  var rcnt     = 0;

  if(arrayLen(arguments) gt 2 and arguments[3] gt 0 and arguments[3] lte len(str)) i = len(str) - arguments[3] + 1;

  rstr = reverse(Right(str, i));
  rcnt = find(rsubstr, rstr);

  if(not rcnt) return 0;
  return len(str)-rcnt-len(substr)+2;
}
request.udf.RFind = RFind;

/**
 * Generates an 8-character random password free of annoying similar-looking characters such as 1 or l.
 * 
 * @return Returns a string.  
 */
function MakePassword()
{
	var allowed_chars = "ABCDEFGHJKLMNPQRTUVWXYZabcdefghjkmnpqrstuvwxyz2346789";
	var new_password = "";
	var char_index = 0;
	var last_char_index = 0;
	for(i = 1; i LTE 8; i = i + 1) {
		while(char_index EQ last_char_index) {
			char_index = Int(rand() * len(allowed_chars)) + 1;
		}
		new_password = new_password & Mid(allowed_chars, char_index, 1);
		last_char_index = char_index;
	}
	return new_password;
} 
request.udf.MakePassword = MakePassword;

/**
 * Returns the last index of an occurrence of a substring in a string from a specified starting position.
 * Big update by Shawn Seley (shawnse@aol.com) -
 * UDF was not accepting third arg for start pos 
 * and was returning results off by one.
 * Modified by RCamden, added var, fixed bug where if no match it return len of str
 * 
 * @param Substr 	 Substring to look for. 
 * @param String 	 String to search. 
 * @param SPos 	 Starting position. 
 * @return Returns the last position where a match is found, or 0 if no match is found. 
 * @author Charles Naumer (cmn@v-works.com) 
 * @version 2, February 14, 2002 
 */
function CleanText(str) {
  var cleaned = replace(ReReplace(str, "<[^>]*>", "", "all"), "&nbsp;", " ", "all");
  return cleaned;
}
request.udf.CleanText = CleanText;

/**
* Returns TRUE if the string is a valid CF UUID.
* 
* @param str 	 String to be checked. (Required)
* @return Returns a boolean. 
* @author Jason Ellison (jgedev@hotmail.com) 
* @version 1, November 24, 2003 
*/
function IsCFUUID(str) {  	
 return REFindNoCase("^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{16}$", str);
}
request.udf.IsCFUUID = IsCFUUID;

/* from Ray Camden's blog */
function relativeTime(pastdate) {
   var delta = dateDiff("s", pastDate, now());
   if(delta lt 60) {
    return "less than a minute ago";
   } else if(delta lt 120) {
    return "about a minute ago";
   } else if(delta lt (45*60)) {
    return round(delta/60) & " minutes ago";
   } else if(delta lt (90*60)) {
    return "about an hour ago";
   } else if(delta lt (24*60*60)) {
      return round(delta/3600) & " hours ago";
   } else if(delta lt (48*60*60)) {
    return "1 day ago";
   } else {
      return round(delta/86400) & " days ago";
   }
}
request.udf.relativeTime = relativeTime;
</cfscript>

<cffunction name="sendEmail" access="public" hint="generates email based on settings" returntype="void">
	<cfargument name="emailFrom" type="string" required="true">
	<cfargument name="emailTo" type="string" required="true">
	<cfargument name="emailSubject" type="string" required="true">
	<cfargument name="emailBody" type="string" required="true">
	<cfif not compare(application.settings.mailServer,'')> <!--- use settings from administrator --->
		<cfmail to="#arguments.emailTo#" from="#arguments.emailFrom#" 
			subject="#arguments.emailSubject#">#arguments.emailBody#</cfmail>
	<cfelse> <!--- use settings from config file --->
		<cfif application.isCF8 or application.isRailo>
			<cfinclude template="sendMailCF8Railo.cfm">
		<cfelse> <!--- blue dragon and CF6, CF7 do not support SSL/TLS --->
			<cfinclude template="sendMailOther.cfm">
		</cfif>
	</cfif>
</cffunction>
<cfset request.udf.sendEmail = sendEmail>


<cffunction name="CleanHighAscii" access="public" returntype="string" output="false"
	hint="Cleans extended ascii values to make the as web safe as possible.">
 
	<!--- Define arguments. --->
	<cfargument	name="Text"	type="string" required="true" hint="The string that we are going to be cleaning."/>
 
	<!--- Set up local scope. --->
	<cfset var LOCAL = {} />
 
	<!---
		When cleaning the string, there are going to be ascii
		values that we want to target, but there are also going
		to be high ascii values that we don't expect. Therefore,
		we have to create a pattern that simply matches all non
		low-ASCII characters. This will find all characters that
		are NOT in the first 127 ascii values. To do this, we
		are using the 2-digit hex encoding of values.
	--->
	<cfset LOCAL.Pattern = CreateObject("java",	"java.util.regex.Pattern").Compile(JavaCast( "string", "[^\x00-\x7F]" ))/>
 
	<!---
		Create the pattern matcher for our target text. The
		matcher will be able to loop through all the high
		ascii values found in the target string.
	--->
	<cfset LOCAL.Matcher = LOCAL.Pattern.Matcher(JavaCast( "string", ARGUMENTS.Text )) />
 
	<!---
		As we clean the string, we are going to need to build
		a results string buffer into which the Matcher will
		be able to store the clean values.
	--->
	<cfset LOCAL.Buffer = CreateObject("java", "java.lang.StringBuffer").Init() />
 
 
	<!--- Keep looping over high ascii values. --->
	<cfloop condition="LOCAL.Matcher.Find()">
 
		<!--- Get the matched high ascii value. --->
		<cfset LOCAL.Value = LOCAL.Matcher.Group() />
 
		<!--- Get the ascii value of our character. --->
		<cfset LOCAL.AsciiValue = Asc( LOCAL.Value ) />
 
		<!---
			Now that we have the high ascii value, we need to
			figure out what to do with it. There are explicit
			tests we can perform for our replacements. However,
			if we don't have a match, we need a default
			strategy and that will be to just store it as an
			escaped value.
		--->
 
		<!--- Check for Microsoft double smart quotes. --->
		<cfif ((LOCAL.AsciiValue EQ 8220) OR (LOCAL.AsciiValue EQ 8221))>
			<!--- Use standard quote. --->
			<cfset LOCAL.Value = """" />
		<!--- Check for Microsoft single smart quotes. --->
		<cfelseif (	(LOCAL.AsciiValue EQ 8216) OR (LOCAL.AsciiValue EQ 8217))>
			<!--- Use standard quote. --->
			<cfset LOCAL.Value = "'" />
 		<!--- Check for Microsoft elipse. --->
		<cfelseif (LOCAL.AsciiValue EQ 8230)>
 			<!--- Use several periods. --->
			<cfset LOCAL.Value = "..." />
 		<cfelse>
 			<!---
				We didn't get any explicit matches on our
				character, so just store the escaped value.
			--->
			<cfset LOCAL.Value = "&###LOCAL.AsciiValue#;" />
 		</cfif>
 
		<!---
			Add the cleaned high ascii character into the
			results buffer. Since we know we will only be
			working with extended values, we know that we don't
			have to worry about escaping any special characters
			in our target string.
		--->
		<cfset LOCAL.Matcher.AppendReplacement(	LOCAL.Buffer,JavaCast( "string", LOCAL.Value )) />
	</cfloop>
 
	<!---
		At this point there are no further high ascii values
		in the string. Add the rest of the target text to the
		results buffer.
	--->
	<cfset LOCAL.Matcher.AppendTail(LOCAL.Buffer) />
 
	<!--- Return the resultant string. --->
	<cfreturn LOCAL.Buffer.ToString() />
</cffunction>
<cfset request.udf.CleanHighAscii = CleanHighAscii>

<cfsetting enablecfoutputonly=false>