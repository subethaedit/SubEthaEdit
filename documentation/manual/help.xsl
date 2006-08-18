<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:redirect="http://xml.apache.org/xalan/redirect"
	extension-element-prefixes="redirect">


	<!-- Parameter -->

	<xsl:param name="format"/>
	<xsl:param name="software"/>
	<xsl:param name="type"/>
	<xsl:param name="version"/>
	<xsl:param name="version_add"/>
	<xsl:param name="edition_lite"/>
	<xsl:param name="edition_pro"/>
	<xsl:param name="edition_se"/>
	<xsl:param name="edition_ee"/>
	<xsl:param name="helphome"/>
	
	<!-- Globale Variablen -->
	
	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	
	<!-- Vorlagen zur Wiederverwendung -->
	
	<xsl:template name="software">
		<xsl:choose>
			<xsl:when test="$software = 'subethaedit'">
				<xsl:text>SubEthaEdit</xsl:text>
			</xsl:when>
			<xsl:when test="$software = 'devonagent'">
				<xsl:text>DEVONagent</xsl:text>
			</xsl:when>
			<xsl:when test="$software = 'devonthink'">
				<xsl:text>DEVONthink</xsl:text>
			</xsl:when>
			<xsl:when test="$software = 'devonthinkpro'">
				<xsl:text>DEVONthink Pro</xsl:text>
			</xsl:when>
			<xsl:when test="$software = 'dtransporter'">
				<xsl:text>Desktop Transporter</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>TheCodingMonkeys Application</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	


	<!-- Untervorlagen -->

	<xsl:template name="insert_section">
		<p>
			<font face="Lucida Grande,Arial,sans-serif">
				<xsl:element name="a">
					<xsl:attribute name="href">
						<xsl:value-of select="concat(../@id,'-',@id,'.html')"/>
					</xsl:attribute>
					<xsl:value-of select="@name"/>
				</xsl:element>
			</font>
		</p>
		
		<redirect:write select="concat(../@id,'-',@id,'.html')">

			<html>
			
			<head>
				<meta http-equiv="content-type" content="text/html;charset=utf-8"/>
				<title>
					<xsl:value-of select="concat(../@name,' &gt; ',@name)"/>
				</title>
				<meta name="dategen" content="Thursday, February 3, 2005 10:16:31 AM"/>
				<meta name="generator" content="DEVONtech HS 1.0"/>
				<link href="../sty/task_tbl_style.css" rel="stylesheet" media="all"/>
				<meta name="keywords" content="introduction, overview, intro"/>
				<xsl:element name="meta">
					<xsl:attribute name="name">description</xsl:attribute>
					<xsl:attribute name="content">
						<xsl:call-template name="software"/><xsl:text> </xsl:text><xsl:value-of select="$type"/>
					</xsl:attribute>
				</xsl:element>
			</head>
			
			<body leftmargin="15" bgcolor="#ffffff">
			
			<!-- Anchor for help system -->
			<xsl:if test="attribute::id != ''">
				<xsl:element name="a">
					<xsl:attribute name="name">
						<xsl:value-of select="concat(../@id,'-',@id,'.html')"/>
					</xsl:attribute>
					<xsl:text> </xsl:text>
				</xsl:element>
			</xsl:if>

			<!-- Div with conditional top margin -->
			<xsl:element name="div">
				<xsl:attribute name="align">left</xsl:attribute>
				<xsl:if test="count(subsection) &gt; 2">
					<xsl:attribute name="style">margin-top: 0px</xsl:attribute>
				</xsl:if>
				<xsl:attribute name="id">mainbox</xsl:attribute>

				<!-- Quick Links -->
				<xsl:if test="count(subsection) &gt; 2">
					<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><td>
					<table border="0" cellspacing="0" cellpadding="0" align="right">
						<tr align="right">
							<td valign="top">
								<font face="Lucida Grande,Arial,sans-serif" color="#777777">
									Quick links:
								</font>
							</td>
							<td width="8px">
								&#160;
							</td>
							<td align="left">
								<xsl:for-each select="subsection">
									<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
											($edition_pro = 'yes' and attribute::edition_pro='yes') or
											($edition_se = 'yes' and attribute::edition_se='yes') or
											($edition_ee = 'yes' and attribute::edition_ee='yes')">
										<xsl:if test="attribute::id != ''">
											<xsl:element name="a">
												<xsl:attribute name="href">
													<xsl:value-of select="concat(../../@id,'-',../@id,'.html#',@id)"/>
												</xsl:attribute>
												<font color="#777777">
													<xsl:value-of select="@name"/>
											</font>
											</xsl:element>
											<xsl:element name="br"/>
										</xsl:if>
									</xsl:if>
								</xsl:for-each>
							</td>
						</tr>
					</table>
					</td></tr></table>
				</xsl:if>
				
				<!-- Headline -->
				<table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr valign="bottom" height="32">
					<td width="3" height="32">&#160;</td>
					<td width="32" height="32"><img src="../gfx/icon.png" alt="Application Icon" height="32" width="32"/></td>
					<td width="8" height="32">&#160;</td>
					<td valign="bottom" height="32">
						<font size="4" face="Lucida Grande,Arial,sans-serif" id="topic">
							<b>
								<xsl:value-of select="@name"/>
							</b>
						</font>
					</td>
					</tr>
					<tr height="10">
					<td colspan="4" height="10">&#160;</td>
					</tr>
				</table>
				
				<!-- Body -->
				<table width="100%" border="0" cellspacing="0" cellpadding="3">
					<tr>
						<td>
							<p><font face="Lucida Grande,Arial,sans-serif">
								<xsl:apply-templates/>
							</font></p>
						</td>
					</tr>
					<tr>
						<td>&#160;</td>
					</tr>
				</table>

			</xsl:element>
			</body>
			</html>	
		</redirect:write>
	</xsl:template>
	
	<xsl:template name="insert_subsection">
		<xsl:if test="attribute::name != ''">
			<xsl:if test="attribute::id != ''">
				<xsl:element name="a">
					<xsl:attribute name="name">
						<xsl:value-of select="@id"/>
					</xsl:attribute>
					<xsl:text> </xsl:text>
				</xsl:element>
			</xsl:if>
			<p>
				<br/>
				<font face="Lucida Grande,Geneva,Arial" color="#009900">
					<b><xsl:value-of select="@name"/></b>
				</font>
			</p>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="insert_paragraph">
		<p>
			<xsl:if test="attribute::name != ''">
				<font face="Lucida Grande,Geneva,Arial">
					<b><xsl:value-of select="@name"/>:<xsl:text> </xsl:text></b>
				</font>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<xsl:template name="insert_sourcecode">
		<pre>
			<font face="Courier,Monaco">
				<xsl:apply-templates/>
			</font>
		</pre>
	</xsl:template>

	<xsl:template name="insert_note">
		<div id="taskbox">
		<table width="100%" border="0" cellspacing="0" cellpadding="9">
			<tr>
				<td>
					<p>
						<b>Note:<xsl:text> </xsl:text></b>
						<xsl:apply-templates/>
					</p>
				</td>
			</tr>
		</table>
		</div>
	</xsl:template>
	
	<xsl:template name="insert_example">
		<div id="examplebox">
		<table width="100%" border="0" cellspacing="0" cellpadding="9">
			<tr>
				<td>
					<p>
						<b>Example:<xsl:text> </xsl:text></b>
						<xsl:apply-templates/>
					</p>
				</td>
			</tr>
		</table>
		</div>
	</xsl:template>	
	
	<xsl:template name="insert_image">
		<xsl:if test="@src_html != ''">
			<xsl:element name="p">
				<!-- <xsl:if test="@align != ''">
					<xsl:attribute name="align">
						<xsl:value-of select="@align"/>
					</xsl:attribute>
				</xsl:if> -->
				<xsl:attribute name="align">center</xsl:attribute>
				<xsl:element name="img">
					<xsl:attribute name="src">../gfx/<xsl:value-of select="@src_html"/></xsl:attribute>
					<xsl:attribute name="alt">
						<xsl:value-of select="@name"/>
					</xsl:attribute>
				</xsl:element>
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template name="insert_list">
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template name="insert_item">
		<li type="square">
			<font face="Lucida Grande,Geneva,Arial">
			<xsl:if test="@name !=''">
				<font face="Lucida Grande,Arial,sans-serif" color="#006600">
					<b><xsl:value-of select="@name"/>:</b>
				</font>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:apply-templates/>
			</font>
		</li>
	</xsl:template>



	<!-- Einzelvorlagen -->
	
	<xsl:template match="chapter">
	
		<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
				($edition_pro = 'yes' and @edition_pro='yes') or
				($edition_se = 'yes' and @edition_se='yes') or
				($edition_ee = 'yes' and @edition_ee='yes')">

			<p>
				<font face="Lucida Grande,Arial,sans-serif">
					<xsl:element name="a">
						<xsl:attribute name="href">
							<xsl:value-of select="concat(@id,'.html')"/>
						</xsl:attribute>
						<xsl:value-of select="@name"/>
					</xsl:element>
				</font>
			</p>
			
			<redirect:write select="concat(@id,'.html')">
				<html>
					<head>
						<meta http-equiv="content-type" content="text/html;charset=utf-8"/>
						<title>
							<xsl:call-template name="software"/><xsl:text> </xsl:text><xsl:value-of select="$type"/>
						</title>
						<link href="../sty/task_tbl_style.css" rel="stylesheet" media="all"/>
						<meta name="robots" content="anchors"/>
					</head>
					<body leftmargin="15" bgcolor="#ffffff">
						<!-- Anchor for help system -->
						<xsl:if test="attribute::id != ''">
							<xsl:element name="a">
								<xsl:attribute name="name">
									<xsl:value-of select="concat(@id,'.html')"/>
								</xsl:attribute>
								<xsl:text> </xsl:text>
							</xsl:element>
						</xsl:if>
						<!-- Main body -->
						<div id="mainbox" align="left" style="margin-top: 0px">
							<table width="100%" border="0" cellspacing="0" cellpadding="0">
								<tr height="28">
									<td width="3" height="28">&#160;</td>
									<td valign="top" height="28">
										<p><font face="Lucida Grande,Arial,sans-serif">
											<xsl:element name="a">
												<xsl:attribute name="href">
													../<xsl:value-of select="$helphome"/>
												</xsl:attribute>
												<xsl:call-template name="software"/><xsl:text> </xsl:text><xsl:value-of select="$type"/>
											</xsl:element>
										</font></p>
									</td>
								</tr>
							</table>
							<table width="100%" border="0" cellspacing="0" cellpadding="0">
								<tr align="left" valign="top">
									<td valign="bottom" width="3"></td>
									<td valign="bottom" width="120"><font id="topic" size="4" face="Lucida Grande,Arial,sans-serif"><b>Contents</b></font></td>
									<td rowspan="3" valign="middle" width="24" background="../gfx/vertline2.gif">&#160;</td>
									<td rowspan="3" valign="middle" width="7"></td>
									<td valign="bottom" width="32"><img src="../gfx/icon.png" alt="App Icon" height="32" width="32"/></td>
									<td valign="bottom" width="7"></td>
									<td valign="bottom">
										<font id="topic" size="4" face="Lucida Grande,Arial,sans-serif">
										<b>
											<xsl:value-of select="@name"/>
										</b>
										</font>
									</td>
								</tr>
								<tr align="left" valign="top" height="18">
									<td width="3" height="18"></td>
									<td width="120" height="18"></td>
									<td colspan="3" height="18"></td>
								</tr>
								<tr align="left" valign="top">
									<td width="3"></td>
									<td width="120">
										<xsl:for-each select="/book/chapter">
											<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
													($edition_pro = 'yes' and @edition_pro='yes') or
													($edition_se = 'yes' and @edition_se='yes') or
													($edition_ee = 'yes' and @edition_ee='yes')">
												<p>
													<font face="Lucida Grande,Arial,sans-serif">
													<xsl:element name="a">
														<xsl:attribute name="href">
															<xsl:value-of select="concat(@id,'.html')"/>
														</xsl:attribute>
														<xsl:value-of select="@name"/>
													</xsl:element>
													</font>
												</p>
											</xsl:if>
										</xsl:for-each>
									</td>
									<td colspan="3">
										<table border="0" cellspacing="0" cellpadding="4">
											<tr valign="top">
												<td>
														<xsl:apply-templates/>
												</td>
											</tr>
										</table>
									</td>
								</tr>
								<tr>
									<td>&#160;</td>
								</tr>
							</table>
						</div>
					</body>
				</html>
			</redirect:write>

		</xsl:if>

	</xsl:template>
	
	<xsl:template match="section">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_section"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_section"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_section"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_section"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="phrase">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:apply-templates/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:apply-templates/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:apply-templates/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:apply-templates/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="subsection">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_subsection"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_subsection"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_subsection"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_subsection"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="paragraph">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_paragraph"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_paragraph"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_paragraph"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_paragraph"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="sourcecode">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_sourcecode"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_sourcecode"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_sourcecode"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_sourcecode"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="note">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_note"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_note"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_note"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_note"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="example">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_example"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_example"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_example"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_example"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="link">
		<xsl:element name="a">
			<xsl:attribute name="href">
				<xsl:value-of select="@href"/>
			</xsl:attribute>
			<xsl:attribute name="target">
				_blank
			</xsl:attribute>
			<xsl:value-of select="."/>
		</xsl:element>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="reference">
		<xsl:element name="a">
			<xsl:attribute name="href">
				<xsl:choose>
					<xsl:when test="@subsection != ''">
						<xsl:value-of select="concat(@chapter,'-',@section,'.html#',@subsection)"/>
					</xsl:when>
					<xsl:when test="@section != ''">
						<xsl:value-of select="concat(@chapter,'-',@section,'.html')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat(@chapter,'.html')"/>
					</xsl:otherwise>
				</xsl:choose>					
			</xsl:attribute>
			<xsl:choose>
				<xsl:when test=". != ''">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>[Read more...]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="image">
		<xsl:if test="@src_html != ''">
			<xsl:choose>
				<xsl:when test="$edition_lite = 'yes'">
					<xsl:if test="@edition_lite = 'yes'">
						<xsl:call-template name="insert_image"/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$edition_pro = 'yes'">
					<xsl:if test="@edition_pro = 'yes'">
						<xsl:call-template name="insert_image"/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$edition_se = 'yes'">
					<xsl:if test="@edition_se = 'yes'">
						<xsl:call-template name="insert_image"/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$edition_ee = 'yes'">
					<xsl:if test="@edition_ee = 'yes'">
						<xsl:call-template name="insert_image"/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="list">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_list"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_list"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_list"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_list"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="item">
		<xsl:choose>
			<xsl:when test="$edition_lite = 'yes'">
				<xsl:if test="@edition_lite = 'yes'">
					<xsl:call-template name="insert_item"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_pro = 'yes'">
				<xsl:if test="@edition_pro = 'yes'">
					<xsl:call-template name="insert_item"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_se = 'yes'">
				<xsl:if test="@edition_se = 'yes'">
					<xsl:call-template name="insert_item"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$edition_ee = 'yes'">
				<xsl:if test="@edition_ee = 'yes'">
					<xsl:call-template name="insert_item"/>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="nameofsoftware">
		<xsl:call-template name="software"/>
	</xsl:template>
	


	<!-- Hauptvorlage -->

	<xsl:template match="/">
		<xsl:for-each select="book">

			<html>
			
				<head>
					<meta http-equiv="content-type" content="text/html;charset=utf-8"/>
					<title>
						<xsl:call-template name="software"/><xsl:text> </xsl:text><xsl:value-of select="$type"/>
					</title>
					<link href="../sty/task_tbl_style.css" rel="stylesheet" media="all"/>
					<meta name="robots" content="anchors"/>
				</head>
			
				<body leftmargin="15" bgcolor="#ffffff">
					<div id="mainbox" align="left" style="margin-top: 0px">
						<table width="100%" border="0" cellspacing="0" cellpadding="0">
							<tr height="28">
								<td width="3" height="28">&#160;</td>
								<td valign="top" height="28">
									<p><font face="Lucida Grande,Arial,sans-serif">
										<xsl:element name="a">
											<xsl:attribute name="href">
												<xsl:text>../</xsl:text><xsl:value-of select="$helphome"/>
											</xsl:attribute>
											<xsl:call-template name="software"/><xsl:text> </xsl:text><xsl:value-of select="$type"/>
										</xsl:element>
										<a name="anchor"></a>
									</font></p>
								</td>
							</tr>
						</table>
						<table width="100%" border="0" cellspacing="0" cellpadding="0">
							<tr align="left" valign="top">
								<td valign="bottom" width="3"></td>
								<td valign="bottom" width="120"><font id="topic" size="4" face="Lucida Grande,Arial,sans-serif"><b>Contents</b></font></td>
								<td rowspan="3" valign="middle" width="24" background="../gfx/vertline2.gif">&#160;</td>
								<td rowspan="3" valign="middle" width="7"></td>
								<td valign="bottom" width="32"><img src="../gfx/icon.png" alt="App Icon" height="32" width="32"/></td>
								<td valign="bottom" width="7"></td>
								<td valign="bottom"><font id="topic" size="4" face="Lucida Grande,Arial,sans-serif"><b>Discover what you can do</b></font></td>
							</tr>
							<tr align="left" valign="top" height="18">
								<td width="3" height="18"></td>
								<td width="120" height="18"></td>
								<td colspan="3" height="18"></td>
							</tr>
							<tr align="left" valign="top">
								<td width="3"></td>
								<td width="120">
									<xsl:apply-templates/>
								</td>
								<td colspan="3">
									<p>
										<font face="Lucida Grande,Arial, sans-serif">
											Use this reference guide to learn more about <xsl:call-template name="software"/>.
										</font>
									</p>
									<table border="0" cellspacing="0" cellpadding="4">
										<tr valign="top">
											<td width="16">
												<p><img src="../gfx/blkbullet.gif" alt="" height="12" width="12" align="absmiddle" border="0"/></p>
											</td>
											<td>
												<p>
													<font face="Lucida Grande,Arial,sans-serif">
														To quickly find answers to specific questions, type a word or phrase in the search box above and press Return.
													</font>
												</p>
												<p>
													<font face="Lucida Grande,Arial,sans-serif">
														To choose what you want to search, click the magnifying glass and choose an item from the pop-up menu, then type your search phrase in the box and press Return.
													</font>
												</p>
											</td>
										</tr>
									</table>
									<table border="0" cellspacing="0" cellpadding="4">
										<tr valign="top">
											<td width="16">
												<p><img src="../gfx/blkbullet.gif" alt="" height="12" width="12" align="absmiddle" border="0"/></p>
											</td>
											<td>
												<p>
													<font face="Lucida Grande,Arial,sans-serif">
														To explore what the menu items, window gadgets and panels in <xsl:call-template name="software"/> do, click an item on the left.
													</font>
												</p>
											</td>
										</tr>
									</table>
								</td>
							</tr>
						</table>
					</div>
				</body>
			</html>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
