<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" doctype-system="http://www.apple.com/DTDs/PropertyList-1.0.dtd" doctype-public="-//Apple//DTD PLIST 1.0//EN" media-type="xml/plist" />
    <xsl:param name="lang">xml</xsl:param>
	<xsl:template name="plist">
	<xsl:param name="lang"/>
<plist version="1.0">
<dict>
<!--	<key>keyword.control.js</key>
	<string>if else class new do while</string>-->
	<xsl:for-each select="//scope[example[contains(@lang,$lang)]]">
	<key><xsl:value-of select="@name"/></key>
	<string>
		<xsl:for-each select="example[contains(@lang,$lang)]">
			<xsl:choose>
				<xsl:when test="position() = 1">
					<xsl:value-of select="."/>
				</xsl:when>
					<xsl:otherwise><xsl:value-of select="concat(' ',.)" />
				</xsl:otherwise>
			</xsl:choose>
				
		</xsl:for-each>
	</string>
	</xsl:for-each>
</dict>
</plist>
</xsl:template>

	<xsl:template match="/">
		<xsl:call-template name="plist">
			<xsl:with-param name="lang" select="$lang"/>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>
