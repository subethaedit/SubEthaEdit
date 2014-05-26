<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="text" />
    <xsl:param name="lang">xml</xsl:param>
	<xsl:template name="plist">
	<xsl:param name="lang"/>
	<xsl:for-each select="//scope[contains(example/@lang,$lang)]">
@"<xsl:value-of select="@name"/>",</xsl:for-each>
</xsl:template>
	<xsl:template match="/">
		<xsl:call-template name="plist">
			<xsl:with-param name="lang" select="$lang"/>
		</xsl:call-template>
		nil
	</xsl:template>
</xsl:stylesheet>
