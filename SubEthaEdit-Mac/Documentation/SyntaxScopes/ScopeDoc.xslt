<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" doctype-system="http://www.w3.org/TR/2000/REC-xhtml1-20000126/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="xml/xhtml"/>
	<xsl:template name="page">
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
      border-bottom: 1px solid #aaa;
      margin-bottom: 8px;
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
    }
    tr, td {
    	margin:0;
    	padding:0;
    }
  </style>
			</head>
			<body>
				<h1>SubEthaEdit Syntax Scope Style Guide</h1>
				<div id="content">
					<h2>Overview</h2>
					<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eleifend ipsum ac tortor condimentum posuere. Donec in rhoncus metus. Nullam mollis mollis ante vel pharetra. Duis quis ipsum velit. Fusce commodo consectetur felis, vitae sagittis orci convallis id. Quisque suscipit faucibus justo ut egestas. Maecenas sed lorem elit, nec faucibus velit.</p>
					<p>Ut convallis, risus in gravida eleifend, urna sapien ultricies tellus, eget congue dui ante vitae est. Maecenas luctus tincidunt eros, vel aliquet dui semper sed. In hendrerit facilisis ipsum, eget bibendum purus blandit at. Suspendisse eu urna ut mauris pretium accumsan eu id urna. Maecenas a dolor hendrerit turpis posuere fermentum id eget enim. Donec justo sapien, dictum at consectetur a, posuere sed diam. Nullam a cursus est. Nullam risus orci, commodo id interdum malesuada, dapibus eu metus.</p>
					<h2>Scope Areas</h2>
					<xsl:call-template name="scope_areas"/>
				</div>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="/">
		<xsl:call-template name="page"/>
	</xsl:template>
	<xsl:template name="scope_areas">
		<xsl:for-each select="/document/scope_area">
			<div class="syntax_scope_area">
				<h3>
					<xsl:value-of select="title"/>
				</h3>
				<p>
					<xsl:value-of select="description"/>
				</p>
				<xsl:for-each select="scope_group">
					<div class="syntax_scope">
						<div class="syntax_scope_name">
							<table>
							<xsl:for-each select="scope">
							<tr><td><tt>
									<xsl:value-of select="@name"/>
								</tt></td><td>
							<div class="examples">
								<xsl:for-each select="example">
									<tt>
										<xsl:value-of select="."/>
									</tt><span class="language"><xsl:value-of select="@lang"/></span>
								</xsl:for-each>
							</div>
							</td></tr>
								
							</xsl:for-each>
							</table>
						</div>
						<p class="syntax_scope_description">
							<xsl:value-of select="description"/>
						</p>
					</div>
				</xsl:for-each>
			</div>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>