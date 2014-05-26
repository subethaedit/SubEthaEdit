<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output indent="yes" encoding="UTF-8" method="xml" 
		doctype-system="http://www.apple.com/DTDs/PropertyList-1.0.dtd" 
		doctype-public="-//Apple//DTD PLIST 1.0//EN"
		media-type="xml/plist"/>
		
	<xsl:param name="key">NSHumanReadableCopyright</xsl:param>
	<xsl:param name="to">© 2014 TheCodingMonkeys
http://www.codingmonkeys.de</xsl:param>

	<xsl:template match="/">
		<xsl:call-template name="change-value">
			<xsl:with-param name="key" select="$key" />
			<xsl:with-param name="to" select="$to" />
		</xsl:call-template>
	</xsl:template>
	
	<!-- Copy everything -->
	<xsl:template name="change-value" match="@*|node()|text()|comment()|processing-instruction()">
		<xsl:param name="key"/>
		<xsl:param name="to"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()|text()|comment()|processing-instruction()">
				<xsl:with-param name="key" select="$key" />
				<xsl:with-param name="to" select="$to" />
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
 
	<xsl:template match="string">
		<xsl:param name="from"/>
		<xsl:param name="to"/>

		<xsl:param name="my_key">
			<xsl:value-of select="preceding-sibling::key[1]"/>		
		</xsl:param>
			
		<xsl:choose>
			<xsl:when test="$my_key = $key">
				 <string><xsl:value-of select="$to" /></string>
			</xsl:when>
			<xsl:otherwise>
				 <string><xsl:value-of select="." /></string>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>

<!--
Workaround for newlines in values: replace :when with this:

			<xsl:when test="$my_key = 'NSHumanReadableCopyright'">
				 <string>© 2014 TheCodingMonkeys
http://www.codingmonkeys.de</string>
			</xsl:when>
			
-->