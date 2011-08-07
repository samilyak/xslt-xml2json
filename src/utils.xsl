<?xml version="1.0" encoding="utf-8" ?>
<!--
	@author Alexander Samilyak (aleksam241@gmail.com)
	-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:str="http://exslt.org/strings"
	xmlns:xpath="http://www.w3.org/2005/xpath-functions"

	xmlns:utils="http://localhost/xsl/xml2json/utils"

	extension-element-prefixes="str xpath"
	exclude-result-prefixes="utils"
>

	<xsl:template name="utils:str_replace">
		<xsl:param name="str" />
		<xsl:param name="search" />
		<xsl:param name="replace" select="''" />

		<xsl:choose>
			<xsl:when test="contains($str, $search)">
				<xsl:choose>
					<!-- libxslt -->
					<xsl:when test="function-available('str:replace')">
						<xsl:value-of
							select="str:replace($str, $search, $replace)"
							disable-output-escaping="yes"
						/>
					</xsl:when>

					<!-- Xalan -->
					<xsl:when test="function-available('str:split')">
						<xsl:call-template name="utils:join">
							<xsl:with-param name="set" select="str:split($str, $search)" />
							<xsl:with-param name="delimiter" select="$replace" />
						</xsl:call-template>
						<!--
							If $str ends with $search, we have to append $replace, because in Xalan
								str:split('one|two|', '|') =>
								<token>one</token><token>two</token>
							But if $str STARTS with $search we DON'T have to prepend $replace, because in Xalan
								str:split('|one|two', '|') =>
								<token></token><token>one</token><token>two</token>
							Weird, right?
							-->
						<xsl:if test="substring($str, string-length($str) - string-length($search) + 1) = $search">
							<xsl:value-of select="$replace" disable-output-escaping="yes" />
						</xsl:if>
					</xsl:when>

					<!--
						Saxon.
						Here we have XPath 2.0 replace function which accepts RegEx patterns (not simple strings)
						as search- and replace-parameters.
						It means that we have to escape \ char (regex special char) in search- and replace-parameters
						with additional \ char.
						-->
					<xsl:when test="function-available('xpath:replace')">
						<xsl:value-of
							select="xpath:replace(
								$str,
								xpath:replace($search, '\\', '\\\\'),
								xpath:replace($replace, '\\', '\\\\')
							)"
							disable-output-escaping="yes"
						/>
					</xsl:when>

					<!--
						Old school - recursion method, for any other XSLT 1.0 processors.
						=== WARNING ===
						All XSLT processors have protection system from infinite recursions.
						If self-calling depth of some template would be more than some constant (normally about 3000),
						processor throw an exception.
						That's why proper work of this replace method is not guaranteed
						if you deal with really long strings containing a lot of $replace chars.
						-->
					<xsl:otherwise>
						<xsl:value-of select="substring-before($str, $search)" disable-output-escaping="yes" />
						<xsl:value-of select="$replace" disable-output-escaping="yes" />
						<xsl:call-template name="utils:str_replace">
							<xsl:with-param name="str" select="substring-after($str, $search)" />
							<xsl:with-param name="search" select="$search" />
							<xsl:with-param name="replace" select="$replace" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str" disable-output-escaping="yes" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template name="utils:join">
		<xsl:param name="set" />
		<xsl:param name="delimiter" select="','" />

		<xsl:choose>
			<!-- Saxon -->
			<xsl:when test="function-available('xpath:string-join')">
				<xsl:value-of select="xpath:string-join($set, $delimiter)" disable-output-escaping="yes" />
			</xsl:when>

			<!-- libxslt, Xalan -->
			<xsl:otherwise>
				<xsl:for-each select="$set">
					<xsl:if test="position() != 1">
						<xsl:value-of select="$delimiter" disable-output-escaping="yes" />
					</xsl:if>
					<xsl:value-of select="." disable-output-escaping="yes" />
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="utils:is_all_names_different">
		<xsl:param name="set" />

		<xsl:variable name="names_duplicates">
			<xsl:for-each select="$set">
				<xsl:if test="count($set[name() = name(current())]) > 1">1</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="contains($names_duplicates, '1')">false</xsl:when>
			<xsl:otherwise>true</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="utils:is_all_names_equals">
		<xsl:param name="set" />

		<xsl:choose>
			<xsl:when test="$set[name() != name($set[1])]">false</xsl:when>
			<xsl:otherwise>true</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
