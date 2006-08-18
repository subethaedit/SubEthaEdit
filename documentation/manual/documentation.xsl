<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" encoding="iso-8859-1"/>

	<!-- Parameter -->

	<xsl:param name="format"/>
	<xsl:param name="software"/>
	<xsl:param name="version"/>
	<xsl:param name="version_add"/>
	<xsl:param name="type"/>
	<xsl:param name="edition_lite"/>
	<xsl:param name="edition_pro"/>
	<xsl:param name="edition_se"/>
	<xsl:param name="edition_ee"/>

	<!-- Globale Variablen -->

	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	<xsl:variable name="copyright">2001-2006</xsl:variable>
	<xsl:variable name="hlcolour">#555555</xsl:variable>
	<xsl:variable name="excolour">#555555</xsl:variable>
	<xsl:variable name="sectioncolour">#000000</xsl:variable>
	<xsl:variable name="subsectioncolour">#333333</xsl:variable>
	<!-- <xsl:variable name="subsectioncolour">#009900</xsl:variable> -->
	<!-- <xsl:variable name="subsectioncolour">#0033CC</xsl:variable> -->
	<!-- <xsl:variable name="paragraphcolour">#6699FF</xsl:variable> -->
	<xsl:variable name="dark-orange">#FF9900</xsl:variable>
	<xsl:variable name="light-orange">#FFCC33</xsl:variable>
	<xsl:variable name="dark-blue">#0033CC</xsl:variable>

	<!-- Vorlagen zur Wiederverwendung -->

	<xsl:template name="software" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:choose>
			<xsl:when test="$software = 'subethaedit'">
				SubEtha<fo:inline font-family="NewCenturySchoolbook" font-style="italic">Edit</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				TCM<fo:inline font-family="NewCenturySchoolbook" font-style="italic"><xsl:value-of select="$software"/></fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="vnum" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:value-of select="$version"/>
		<fo:inline font-family="NewCenturySchoolbook" font-style="italic">
			<xsl:value-of select="$version_add"/>
		</fo:inline>
	</xsl:template>

	<xsl:template name="sidebar" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:if test="$format = 'screen'">
			<fo:static-content flow-name="xsl-region-start">
				<fo:block padding="1cm" text-align="start" color="black">
					<fo:block start-indent="0.5cm" line-height="0.9"
						font-family="Futura" font-weight="bold" font-size="20pt"
						> DEVON </fo:block>
					<fo:block start-indent="0.5cm" line-height="0.9"
						font-family="NewCenturySchoolbook" font-style="italic"
						font-size="20pt" space-after="6pt"> technologies </fo:block>
					<fo:block start-indent="0.5cm" font-family="Futura"
						font-weight="bold" font-size="9pt"> &#169; <xsl:value-of
							select="$copyright"/>
					</fo:block>
					<fo:block start-indent="0.5cm" font-family="Futura"
						font-weight="bold" font-size="9pt" space-after="6pt">
							DEVON<fo:inline font-family="NewCenturySchoolbook"
							font-style="italic">technologies</fo:inline>
					</fo:block>
				</fo:block>
			</fo:static-content>
		</xsl:if>
	</xsl:template>

	<xsl:template name="pagination" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:static-content flow-name="xsl-region-after">
			<fo:block text-align="end" end-indent="1cm" font-family="Futura"
				font-weight="bold" font-size="9pt">
				<xsl:call-template name="software"/>&#160;<xsl:call-template
					name="vnum"/>&#160;<xsl:value-of select="$type"/>, page&#160;<fo:page-number/>
			</fo:block>
		</fo:static-content>
	</xsl:template>



	<!-- Untervorlagen -->

	<xsl:template name="insert_section"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:element name="fo:block">
			<xsl:attribute name="id">
				<xsl:value-of select="concat(../@id,'-',@id)"/>
			</xsl:attribute>
			<xsl:attribute name="font-family">Futura</xsl:attribute>
			<xsl:attribute name="font-weight">bold</xsl:attribute>
			<xsl:attribute name="font-size">14pt</xsl:attribute>
			<xsl:attribute name="color">
				<xsl:value-of select="$sectioncolour"/>
			</xsl:attribute>
			<xsl:attribute name="space-before">24pt</xsl:attribute>
			<xsl:attribute name="space-after">12pt</xsl:attribute>
			<xsl:attribute name="break-before">page</xsl:attribute>
			<xsl:attribute name="keep-with-next">always</xsl:attribute>
			<xsl:if test="@name != ''">
				<!-- <xsl:attribute name="break-before">page</xsl:attribute> -->
				<xsl:variable name="toconvert">
					<xsl:value-of select="@name"/>
				</xsl:variable>
				<xsl:value-of
					select="translate($toconvert,$lcletters,$ucletters)"/>
			</xsl:if>
		</xsl:element>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="insert_subsection" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:block font-family="NewCenturySchoolbook" font-size="12pt"
			space-after="12pt" orphans="3" widows="3">
			<xsl:if test="@name != ''">
				<xsl:element name="fo:block">
					<xsl:attribute name="id">
						<xsl:value-of select="concat(../../@id,'-',../@id,'-',@id)"/>
					</xsl:attribute>
					<xsl:attribute name="font-family">Futura</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
					<xsl:attribute name="color">
						<xsl:value-of select="$subsectioncolour"/>
					</xsl:attribute>
					<xsl:attribute name="space-before">18pt</xsl:attribute>
					<xsl:attribute name="space-after">12pt</xsl:attribute>
					<xsl:attribute name="keep-with-next">always</xsl:attribute>
					<xsl:variable name="toconvert">
						<xsl:value-of select="@name"/>
					</xsl:variable>
					<xsl:value-of
						select="translate($toconvert,$lcletters,$ucletters)"/>
				</xsl:element>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	
	<xsl:template name="insert_paragraph" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:block font-family="NewCenturySchoolbook" font-size="12pt"
			space-after="12pt" orphans="3" widows="3">
			<xsl:if test="@name != ''">
				<fo:inline font-style="italic">
					<xsl:value-of select="@name"/>:<xsl:text> </xsl:text> 
				</fo:inline>
				<!-- <xsl:element name="fo:inline">
					<xsl:attribute name="font-family">NewCenturySchoolbook</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
					<xsl:attribute name="font-style">italic</xsl:attribute>
					<xsl:attribute name="color">
						<xsl:value-of select="$paragraphcolour"/>
					</xsl:attribute>
					<xsl:value-of select="@name"/>:&#160; 
				</xsl:element> -->
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	
	<xsl:template name="insert_note"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:element name="fo:block">
			<xsl:attribute name="font-family">NewCenturySchoolbook</xsl:attribute>
			<xsl:attribute name="font-size">12pt</xsl:attribute>
			<xsl:attribute name="space-after">12pt</xsl:attribute>
			<xsl:attribute name="start-indent">1cm</xsl:attribute>
			<xsl:attribute name="end-indent">1cm</xsl:attribute>
			<xsl:attribute name="orphans">3</xsl:attribute>
			<xsl:attribute name="widows">3</xsl:attribute>
			<xsl:attribute name="color">
				<xsl:value-of select="$hlcolour"/>
			</xsl:attribute>
			Note:<xsl:text> </xsl:text>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template name="insert_example"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:element name="fo:block">
			<xsl:attribute name="font-family">NewCenturySchoolbook</xsl:attribute>
			<xsl:attribute name="font-size">12pt</xsl:attribute>
			<xsl:attribute name="space-after">12pt</xsl:attribute>
			<xsl:attribute name="start-indent">1cm</xsl:attribute>
			<xsl:attribute name="end-indent">1cm</xsl:attribute>
			<xsl:attribute name="orphans">3</xsl:attribute>
			<xsl:attribute name="widows">3</xsl:attribute>
			<xsl:attribute name="color">
				<xsl:value-of select="$excolour"/>
			</xsl:attribute>
			Example:<xsl:text> </xsl:text>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template name="insert_image"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:element name="fo:block">
			<xsl:attribute name="text-align">
				<xsl:value-of select="@align"/>
			</xsl:attribute>
			<xsl:attribute name="space-after">12pt</xsl:attribute>
			<xsl:element name="fo:external-graphic">
				<xsl:attribute name="src">url('images/<xsl:value-of
						select="@src"/>')</xsl:attribute>
				<xsl:attribute name="content-width">
					<xsl:value-of select="@scaling"/>
				</xsl:attribute>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	
	<xsl:template name="insert_list"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:block font-family="NewCenturySchoolbook" font-size="12pt"
			space-after="12pt" keep-with-previous="always">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	
	<xsl:template name="insert_item"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:block start-indent="1cm" text-indent="-0.5cm" end-indent="1cm">
			<fo:inline font-family="Futura" font-size="11.5pt" font-weight="bold">&#8226;</fo:inline>&#160;
				<xsl:if test="@name != ''">
					<fo:inline font-family="NewCenturySchoolbook" font-style="italic">
					<xsl:value-of select="@name"/><xsl:text>: </xsl:text></fo:inline>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	
	<xsl:template name="insert_section_toc"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<fo:block start-indent="0.5cm" color="#555555" text-align-last="justify"
			keep-with-previous="always">
			<xsl:element name="fo:basic-link">
				<xsl:attribute name="internal-destination">
					<xsl:value-of select="concat(../@id,'-',@id)"/>
				</xsl:attribute>
				<xsl:value-of select="@name"/>
			</xsl:element>
			<fo:leader/>
			<xsl:element name="fo:page-number-citation">
				<xsl:attribute name="ref-id">
					<xsl:choose>
						<xsl:when test="@id != ''">
							<xsl:value-of select="concat(../@id,'-',@id)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="../@id"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:element>
		</fo:block>
	</xsl:template>
	
	
	
	<!-- Einzelvorlagen -->
	
	<xsl:template match="chapter" xmlns:fo="http://www.w3.org/1999/XSL/Format">

		<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
				($edition_pro = 'yes' and @edition_pro='yes') or
				($edition_se = 'yes' and @edition_se='yes') or
				($edition_ee = 'yes' and @edition_ee='yes')">

			<xsl:element name="fo:block">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>
				</xsl:attribute>
				<xsl:attribute name="font-family">Futura</xsl:attribute>
				<xsl:attribute name="font-weight">bold</xsl:attribute>
				<xsl:attribute name="font-size">20pt</xsl:attribute>
				<xsl:attribute name="space-after">12pt</xsl:attribute>
				<xsl:attribute name="break-before">page</xsl:attribute>
				<xsl:variable name="toconvert">
					<xsl:value-of select="@name"/>
				</xsl:variable>
				<xsl:value-of select="translate($toconvert,$lcletters,$ucletters)"/>
			</xsl:element>

			<xsl:element name="fo:block">
				<xsl:attribute name="font-family">NewCenturySchoolbook</xsl:attribute>
				<xsl:attribute name="font-size">12pt</xsl:attribute>
				<xsl:attribute name="space-after">12pt</xsl:attribute>
				<xsl:attribute name="start-indent">1cm</xsl:attribute>
				<xsl:attribute name="end-indent">1cm</xsl:attribute>
				<xsl:attribute name="orphans">3</xsl:attribute>
				<xsl:attribute name="widows">3</xsl:attribute>
				<xsl:for-each select="section">
					<xsl:if test="@name != ''">
						<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
								($edition_pro = 'yes' and @edition_pro='yes') or
								($edition_se = 'yes' and @edition_se='yes') or
								($edition_ee = 'yes' and @edition_ee='yes')">
							<xsl:call-template name="insert_section_toc"/>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
			</xsl:element>

			<xsl:apply-templates/>

		</xsl:if>

	</xsl:template>
	
	<xsl:template match="section" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="subsection" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="paragraph" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="phrase" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="note" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="example" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
				($edition_pro = 'yes' and @edition_pro='yes') or
				($edition_se = 'yes' and @edition_se='yes') or
				($edition_ee = 'yes' and @edition_ee='yes')">
			<xsl:call-template name="insert_example"/>
		</xsl:if>
	</xsl:template>

	
	<xsl:template match="image" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:if test="@src != ''">
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
	
	<xsl:template match="list" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="item" xmlns:fo="http://www.w3.org/1999/XSL/Format">
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
	
	<xsl:template match="link" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:element name="fo:inline">
			<xsl:attribute name="text-decoration">underline</xsl:attribute>
			<xsl:attribute name="color">#666666</xsl:attribute>
			<xsl:element name="fo:basic-link">
				<xsl:attribute name="external-destination">
					url(<xsl:value-of select="@href"/>)
				</xsl:attribute>
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:element>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="reference" xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
				($edition_pro = 'yes' and @edition_pro='yes') or
				($edition_se = 'yes' and @edition_se='yes') or
				($edition_ee = 'yes' and @edition_ee='yes')">
			<xsl:element name="fo:inline">
				<xsl:attribute name="text-decoration">underline</xsl:attribute>
				<xsl:attribute name="color">#666666</xsl:attribute>
				<xsl:element name="fo:basic-link">
					<xsl:attribute name="internal-destination">
						<xsl:choose>
							<xsl:when test="@subsection != ''">
								<xsl:value-of select="concat(@chapter,'-',@section,'-',@subsection)"/>
							</xsl:when>
							<xsl:when test="@section != ''">
								<xsl:value-of select="concat(@chapter,'-',@section)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="@chapter"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test=". != ''">
							<xsl:value-of select="."/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>See also p. </xsl:text>
							<xsl:element name="fo:page-number-citation">
								<xsl:attribute name="ref-id">
									<xsl:choose>
										<xsl:when test="@section != ''">
											<xsl:value-of select="concat(@chapter,'-',@section)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@chapter"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
							</xsl:element>ff
						</xsl:otherwise>
					</xsl:choose>
				</xsl:element>
			</xsl:element>
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="nameofsoftware"
		xmlns:fo="http://www.w3.org/1999/XSL/Format">
		<xsl:choose>
			<xsl:when test="$software = 'devonnote'"> DEVONnote </xsl:when>
			<xsl:when test="$software = 'devonthink'"> DEVONthink </xsl:when>
			<xsl:when test="$software = 'devonthinkpro'"> DEVONthink Pro </xsl:when>
			<xsl:when test="$software = 'dtransporter'"> Desktop Transporter </xsl:when>
			<xsl:otherwise> DEVON<xsl:value-of select="$software"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	
	<!-- Hauptvorlage -->
	
	<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format"
			xmlns:rx="http://www.renderx.com/XSL/Extensions">
			<xsl:choose>
				<xsl:when test="$format = 'print'">
					<fo:layout-master-set>
						<fo:simple-page-master master-name="master"
							page-height="29.7cm" page-width="21cm">
							<fo:region-body margin="2cm 2cm 2cm 2cm"/>
							<fo:region-after extent="1.5cm"/>
						</fo:simple-page-master>
						<fo:simple-page-master master-name="cover"
							page-height="29.7cm" page-width="21cm">
							<fo:region-body margin="1cm 1cm 2cm 2cm"/>
							<fo:region-after extent="1.5cm"/>
						</fo:simple-page-master>
					</fo:layout-master-set>
				</xsl:when>
				<xsl:when test="$format = 'screen'">
					<fo:layout-master-set>
						<fo:simple-page-master master-name="master"
							page-height="15cm" page-width="21cm">
							<fo:region-body margin="1cm 1cm 2cm 6cm"/>
							<fo:region-after extent="1.5cm"/>
							<xsl:element name="fo:region-start">
								<xsl:attribute name="extent">5cm</xsl:attribute>
								<xsl:attribute name="background-repeat">no-repeat</xsl:attribute>
								<xsl:attribute name="background-image">
									<xsl:choose>
										<xsl:when test="$software = 'devonthinkpro'">url('../materials/sidebar-devonthinkpro.jpg')</xsl:when>
										<xsl:when test="$software = 'devonthink'">url('../materials/sidebar-devonthink.jpg')</xsl:when>
										<xsl:when test="$software = 'devonnote'">url('../materials/sidebar-devonnote.jpg')</xsl:when>
										<xsl:when test="$software = 'devonagent'">url('../materials/sidebar-devonagent.jpg')</xsl:when>
										<xsl:otherwise>url('../materials/sidebar-generic.jpg')</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
							</xsl:element>
						</fo:simple-page-master>
						<fo:simple-page-master master-name="cover"
							page-height="15cm" page-width="21cm">
							<xsl:choose>
								<xsl:when test="$software = 'devonthinkpro'">
									<fo:region-body
										background-image="url('../materials/background-devonthinkpro.jpg')"
										background-repeat="no-repeat"/>
								</xsl:when>
								<xsl:when test="$software = 'devonthink'">
									<fo:region-body
										background-image="url('../materials/background-devonthink.jpg')"
										background-repeat="no-repeat"/>
								</xsl:when>
								<xsl:when test="$software = 'devonnote'">
									<fo:region-body
										background-image="url('../materials/background-devonnote.jpg')"
										background-repeat="no-repeat"/>
								</xsl:when>
								<xsl:when test="$software = 'devonagent'">
									<fo:region-body
										background-image="url('../materials/background-devonagent.jpg')"
										background-repeat="no-repeat"/>
								</xsl:when>
								<xsl:otherwise>
									<fo:region-body
										background-image="url('../materials/background-generic.jpg')"
										background-repeat="no-repeat"/>
								</xsl:otherwise>
							</xsl:choose>
						</fo:simple-page-master>
					</fo:layout-master-set>
				</xsl:when>
			</xsl:choose>
			<!-- Bookmarks for PDF reader -->
			<rx:outline>
				<xsl:for-each select="book">
					<!-- Separate bookmark for Home -->
					<rx:bookmark internal-destination="Home">
						<rx:bookmark-label>Front Page</rx:bookmark-label>
					</rx:bookmark>
					<!-- Separate bookmark for TOC -->
					<xsl:element name="rx:bookmark">
						<xsl:attribute name="internal-destination">TOC</xsl:attribute>
						<rx:bookmark-label>Table of Contents</rx:bookmark-label>
					</xsl:element>
					<!-- All other bookmarks -->
					<xsl:for-each select="chapter">
						<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
								($edition_pro = 'yes' and @edition_pro='yes') or
								($edition_se = 'yes' and @edition_se='yes') or
								($edition_ee = 'yes' and @edition_ee='yes')">
							<xsl:element name="rx:bookmark">
								<xsl:attribute name="internal-destination">
									<xsl:value-of select="@id"/>
								</xsl:attribute>
								<rx:bookmark-label>
									<xsl:value-of select="@name"/>
								</rx:bookmark-label>
								<xsl:for-each select="section">
									<xsl:if test="@name != ''">
										<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
												($edition_pro = 'yes' and @edition_pro='yes') or
												($edition_se = 'yes' and @edition_se='yes') or
												($edition_ee = 'yes' and @edition_ee='yes')">
											<xsl:element name="rx:bookmark">
												<xsl:attribute name="internal-destination">
													<xsl:value-of select="concat(../@id,'-',@id)"/>
												</xsl:attribute>
												<rx:bookmark-label>
													<xsl:value-of select="@name"/>
												</rx:bookmark-label>
												<xsl:for-each select="subsection">
													<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
															($edition_pro = 'yes' and @edition_pro='yes') or
															($edition_se = 'yes' and @edition_se='yes') or
															($edition_ee = 'yes' and @edition_ee='yes')">
														<xsl:if test="@id != ''">
															<xsl:element name="rx:bookmark">
																<xsl:attribute name="internal-destination">
																	<xsl:value-of select="concat(../../@id,'-',../@id,'-',@id)"/>
																</xsl:attribute>
																<rx:bookmark-label>
																	<xsl:value-of select="@name"/>
																</rx:bookmark-label>
															</xsl:element>
														</xsl:if>
													</xsl:if>
												</xsl:for-each>
											</xsl:element>
										</xsl:if>
									</xsl:if>
								</xsl:for-each>
							</xsl:element>
						</xsl:if>
					</xsl:for-each>
				</xsl:for-each>
			</rx:outline>
			<!-- Titelseite -->
			<fo:page-sequence master-reference="cover">
				<fo:flow flow-name="xsl-region-body">
					<fo:block-container height="1cm"/>
					<xsl:element name="fo:block-container">
						<xsl:attribute name="display-align">before</xsl:attribute>
						<xsl:attribute name="height">2cm</xsl:attribute>
						<xsl:element name="fo:block">
							<xsl:attribute name="id">Home</xsl:attribute>
							<xsl:attribute name="end-indent">1cm</xsl:attribute>
							<xsl:attribute name="text-align">end</xsl:attribute>
							<xsl:attribute name="font-family">Futura</xsl:attribute>
							<xsl:attribute name="font-weight">bold</xsl:attribute>
							<xsl:attribute name="font-size">24pt</xsl:attribute>
							<xsl:choose>
								<xsl:when test="$format = 'print'">
									<xsl:attribute name="color"
									>#000000</xsl:attribute>
								</xsl:when>
								<xsl:when test="$format = 'screen'">
									<xsl:attribute name="color"
									>#000000</xsl:attribute>
								</xsl:when>
							</xsl:choose>
							<xsl:call-template name="software" /><xsl:text> </xsl:text>
							<xsl:call-template name="vnum" /><xsl:text> </xsl:text>
							<xsl:value-of select="$type"/>
						</xsl:element>
					</xsl:element>
					<xsl:choose>
						<xsl:when test="$format = 'print'">
							<fo:block-container height="22cm"/>
						</xsl:when>
						<xsl:when test="$format = 'screen'">
							<fo:block-container height="10cm"/>
						</xsl:when>
					</xsl:choose>
					<fo:block-container height="1cm" display-align="after">
						<xsl:element name="fo:block">
							<xsl:attribute name="end-indent">1cm</xsl:attribute>
							<xsl:attribute name="text-align">end</xsl:attribute>
							<xsl:attribute name="font-family">Futura</xsl:attribute>
							<xsl:attribute name="font-weight">bold</xsl:attribute>
							<xsl:attribute name="font-size">9pt</xsl:attribute>
							<xsl:choose>
								<xsl:when test="$format = 'print'">
									<xsl:attribute name="color"
									>#000000</xsl:attribute>
								</xsl:when>
								<xsl:when test="$format = 'screen'">
									<xsl:attribute name="color"
									>#000000</xsl:attribute>
								</xsl:when>
							</xsl:choose> &#169; <xsl:value-of select="$copyright"
							/> DEVON<fo:inline
								font-family="NewCenturySchoolbook"
								font-style="italic">technologies</fo:inline>
						</xsl:element>
					</fo:block-container>
				</fo:flow>
			</fo:page-sequence>
			<!-- Inhaltsverzeichnis -->
			<fo:page-sequence master-reference="master">
				<xsl:call-template name="sidebar"/>
				<xsl:call-template name="pagination"/>
				<fo:flow flow-name="xsl-region-body">
					<fo:block font-family="Futura" font-weight="bold"
						font-size="20pt" break-before="page" id="TOC"> TABLE OF CONTENTS </fo:block>
					<fo:block font-family="NewCenturySchoolbook"
						font-size="12pt">
						<xsl:for-each select="book">
							<xsl:for-each select="chapter">
								<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
										($edition_pro = 'yes' and @edition_pro='yes') or
										($edition_se = 'yes' and @edition_se='yes') or
										($edition_ee = 'yes' and @edition_ee='yes')">
									<fo:block space-after="12pt" space-before="12pt"
										text-align-last="justify"
										keep-with-next="always">
										<xsl:element name="fo:basic-link">
											<xsl:attribute
											name="internal-destination">
											<xsl:value-of select="@id"/>
											</xsl:attribute>
											<xsl:value-of select="@name"/>
										</xsl:element>
										<fo:leader/>
										<xsl:element name="fo:page-number-citation">
											<xsl:attribute name="ref-id">
											<xsl:value-of select="@id"/>
											</xsl:attribute>
										</xsl:element>
									</fo:block>
									<xsl:for-each select="section">
										<xsl:if test="@name != ''">
											<xsl:if test="($edition_lite = 'yes' and @edition_lite='yes') or
													($edition_pro = 'yes' and @edition_pro='yes') or
													($edition_se = 'yes' and @edition_se='yes') or
													($edition_ee = 'yes' and @edition_ee='yes')">
												<xsl:call-template name="insert_section_toc"/>
											</xsl:if>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:for-each>
						</xsl:for-each>
					</fo:block>
				</fo:flow>
			</fo:page-sequence>
			<!-- Buchblock -->
			<xsl:for-each select="book">
				<fo:page-sequence master-reference="master">
					<xsl:call-template name="sidebar"/>
					<xsl:call-template name="pagination"/>
					<fo:flow flow-name="xsl-region-body">
						<xsl:apply-templates/>
					</fo:flow>
				</fo:page-sequence>
			</xsl:for-each>
		</fo:root>
	</xsl:template>
</xsl:stylesheet>
