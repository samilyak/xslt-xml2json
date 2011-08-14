<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:test="http://www.jenitennison.com/xslt/unit-test" xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xsl:import href="generate-tests-utils.xsl"/>
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="xsl:stylesheet">
				<!--
					By convention the input document is the XSL to be tested.
				-->
				<xsl:processing-instruction name="xml-stylesheet">type="text/xsl" href="file:/E:/MappingTool/test/tennison-tests/main/src/xslt/format-report.xsl"</xsl:processing-instruction>
				<test:report stylesheet="{resolve-uri(xsl:stylesheet/xsl:import[@test:stylesheet]/@href)}" date="{current-dateTime()}">
					<xsl:for-each select="*/test:suite/test:tests/test:test">
						<test:tests id="{generate-id(.)}">
							 <xsl:copy-of select="test:title" />
							<xsl:variable name="inputURI" select="resolve-uri(test:context/@href, base-uri(.))"/>
							<xsl:variable name="expectURI" select="resolve-uri(test:expect/@href, base-uri(.))"/>
							<xsl:variable name="actualResult" as="document-node()">
								<xsl:document validation="lax">
									<xsl:apply-templates select="document($inputURI)"/>
								</xsl:document>
							</xsl:variable>
							<!--<xsl:message>actualResult = <xsl:copy-of select="$actualResult"/>
							</xsl:message>-->
							<xsl:variable name="expectedResult" select="document($expectURI)"/>
							<!--<xsl:message>expectedResult = <xsl:copy-of select="$expectedResult"/>
							</xsl:message>-->							
							<xsl:variable name="successful" select="test:deep-equal($expectedResult, $actualResult)"/>
							<xsl:message>successful=<xsl:copy-of select="$successful"/></xsl:message>
							<xsl:if test="not($successful)">
								<xsl:message>  Failed </xsl:message>
							</xsl:if>
							<xsl:if test="$successful">
								<xsl:message>  Passed </xsl:message>
							</xsl:if>
							<test:test id="{concat(generate-id(.),'.',position())}" successful="{$successful}">
							 <xsl:copy-of select="test:title" />
								<test:context href="{$inputURI}"/>
								<test:expect href="{$expectURI}"/>
								<xsl:call-template name="test:report-value">									
									<xsl:with-param name="value" select="$actualResult"/>									
								</xsl:call-template>
							</test:test>
						</test:tests>
					</xsl:for-each>
				</test:report>
			</xsl:when>
			<xsl:otherwise>
				<!--<xsl:message>input doc = <xsl:copy-of select="."/></xsl:message>-->
				<xsl:next-match/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>