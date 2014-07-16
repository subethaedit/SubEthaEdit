<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output indent="no" encoding="UTF-8" method="xml" 
		doctype-system="http://www.apple.com/DTDs/PropertyList-1.0.dtd" 
		doctype-public="-//Apple//DTD PLIST 1.0//EN"
		media-type="xml/plist"/>
	
	<xsl:template match="/">
		<xsl:text>&#xA;</xsl:text>
		
		<xsl:element name="plist">
			<xsl:attribute name="version">1.0</xsl:attribute>
			<xsl:text>&#xA;</xsl:text>
			
			<xsl:element name="dict">
				<xsl:call-template name="sort"/>
				<xsl:text>&#xA;</xsl:text>
			</xsl:element>
			<xsl:text>&#xA;</xsl:text>
			
		</xsl:element>
		<xsl:text>&#xA;</xsl:text>
		
	</xsl:template>
	
	<xsl:template name="sort" match="@*|node()|text()|comment()|processing-instruction()">
		<xsl:apply-templates select="plist/dict/key[text()='CFBundleIdentifier']/following-sibling::string[1]"/>
		<xsl:apply-templates select="plist/dict/key[text()='CFBundleName']/following-sibling::string[1]"/>
		
		<xsl:apply-templates select="plist/dict/key[text()='NSHumanReadableCopyright']/following-sibling::string[1]"/>
		
		<xsl:apply-templates select="plist/dict/key[text()='CFBundleShortVersionString']/following-sibling::string[1]"/>
		<xsl:apply-templates select="plist/dict/key[text()='CFBundleVersion']/following-sibling::string[1]"/>
		<xsl:apply-templates select="plist/dict/key[text()='SEEMinimumEngineVersion']/following-sibling::string[1]"/>
		
		<xsl:apply-templates select="plist/dict/key[text()='CFBundleInfoDictionaryVersion']/following-sibling::string[1]"/>
	</xsl:template>
	
	<xsl:template match="string">
		<xsl:text>&#xA;</xsl:text>
		<xsl:text>&#x9;</xsl:text>
		<key><xsl:value-of select="preceding-sibling::key[1]"/></key>
		
		<xsl:text>&#xA;</xsl:text>
		<xsl:text>&#x9;</xsl:text>
		<string><xsl:value-of select="." /></string>
	</xsl:template>
	
</xsl:stylesheet>

<!-- 
CFBundleIdentifier
CFBundleName

NSHumanReadableCopyright

CFBundleShortVersionString
CFBundleVersion
SEEMinimumEngineVersion

CFBundleInfoDictionaryVersion

Tab:
&#x9;
<xsl:text>&#x9;</xsl:text>

LineFeed:
&#xA;
<xsl:text>&#xA;</xsl:text>
-->
