<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" 
		doctype-system="http://www.w3.org/TR/2000/REC-xhtml1-20000126/DTD/xhtml1-strict.dtd" 
		doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" 
		media-type="xml/xhtml"/>
	
	<xsl:template match="/">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title>SubEthaEdit Syntax Scope Style Guide</title>
				<style type="text/css">
    body {
    background: #999;
    font: 14px "Helvetica Neue",Helvetica,"Arial Unicode MS",Arial,sans-serif;
    color: #000;
    margin: 0 10px;
    padding: 0;
    line-height: 1.4;
    text-align: center;
    text-rendering: optimizeLegibility
    }
    div#content {
      background: #ddd;
      min-width:500px;
      max-width:900px;
      text-align:left;
      padding: 5px 10px;
      margin: 10px auto;
      -webkit-border-radius: 12px;
      -webkit-box-shadow: inset 0px 0px 4px #000;
    }
    h1 {
    text-align:center;
    }
    h2,h3,h4,h5,h6 {
      padding:0;
      margin:10px 0px 2px 0px;
      font-weight: normal;
    }
    tt, p.code, code {
      font-family: Consolas, Monaco, "Lucida Console", monospace;
    }
    p {
      margin:0; 
      padding:0;
      margin-top: 4px;
    }
    div.syntax_scope_name {
      border-top: 2px solid #aaa;
      padding-top: 8px;
    }
    div.syntax_scope_name > tt {
      font-weight: bold;
      display:block;
    }
    div.syntax_scope {
      margin: 4px 0px;
      padding: 7px 6px;
      background: #fff;
      -moz-border-radius: 8px;
      -webkit-border-radius: 8px;
      -webkit-box-shadow: inset 0px 1px 2px #666;
    }
    div#content > p , div.syntax_scope_area, div.syntax_scope_area > p {
      margin: 4px 4px 0px 12px;
    }
    div.examples {
      text-align:right;
      background:#fff;
      margin:0px;
      padding:0px 0px;
    }
    div.examples > tt {
      display:inline;
      padding: 0px 2px 0px 10px;
    }
    span.language {
    	font-size:9px;
    	-webkit-border-radius: 6px;
      	-webkit-box-shadow: 0px 0px 2px #000;
      	background-color:#aab;
      	color: white;
      	font-weight:bold;
      	padding: 1px 2px;
    }
    table {
    	width: 100%;
		border-collapse:collapse;
    }
    tr, td {
    	margin:0;
    	padding:0;
    }
    tr.scope td {
    	border-bottom:1px solid #ccc;
    }
    td.description {
    	color:#653;
    	border-bottom:1px #875 solid;
    	padding-top:10px;
    }
  </style>
			</head>
			<body>
				<h1>SubEthaEdit Syntax Scope Style Guide</h1>
				<div id="content">
					<h2>Overview</h2>
					<ul><li>Syntax Highlighting is defined using hierachical Syntax Scopes</li>
					   <li>Styles are assigned to Syntax Scopes in a Style Sheet File (e.g. "Bright Dom.sss") that has similiar syntax to an CSS file</li>
					   <li>However, the .sss files do not support selectors, they are just a list of scope -> style assignments. E.g. <pre style="display:block; background:#fff; font-size:0.8em; margin:0 auto 0 0; padding:2px 10px; width: 300px;">style.value.numeric {
  background-color:#ffffff;
  color:#0000ff;
  font-strike-through:strike-through;
  font-style:normal;
  font-underline:underline;
  font-weight:normal;
}</pre></li>
          <li>Scope matching is done using simple prefix matching. E.g.: if <tt>style</tt> is defined in a Style sheet, then <tt>style.value.numeric</tt> will use this style unless a more specific scope (e.g. <tt>style.value</tt>) is defined</li>
          <li>If a Style does not specify all attributes, it inherits from the next less specific style. In the end all Styles inherit from <tt>meta.default</tt></li>
          <li>Style sheets should represent a complete color scheme, providing at least all high level scopes</li>
					</ul>
					<h2>Scope Areas</h2>
					<xsl:apply-templates select="/document/scope_area"/>
				</div>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="scope_area">
		<div class="syntax_scope_area">
			<h3>
				<xsl:value-of select="title"/>
			</h3>
			<p>
				<xsl:value-of select="description"/>
			</p>
			<xsl:apply-templates select="scope_group"/>
		</div>
	</xsl:template>
	
	<xsl:template match="scope_group">
		<div class="syntax_scope">
			<p class="syntax_scope_description">
				<xsl:value-of select="description"/>
			</p>
			<div class="syntax_scope_name">
				<table>
					<xsl:apply-templates select="scope | sub_group"/>
				</table>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="scope_group/sub_group">
		<tr>
			<td colspan="2" class="description">
				<xsl:copy-of select="description"/>
			</td>
		</tr>
		<xsl:apply-templates select="scope"/>
	</xsl:template>

	<xsl:template match="scope">
		<tr class="scope">
			<td>
				<tt><xsl:value-of select="@name"/></tt>
			</td>
			<td>
				<div class="examples">
					<xsl:for-each select="example">
						<tt><xsl:value-of select="."/></tt><span class="language"><xsl:value-of select="@lang"/></span>
					</xsl:for-each>
				</div>
			</td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
