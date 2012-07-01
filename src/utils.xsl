<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview Low level utils (such as cross processor string replace)
  @author Alexander Samilyak (aleksam241@gmail.com)

  This source code follows Formatting section of Google C++ Style Guide
  http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Formatting
  -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  xmlns:xpath="http://www.w3.org/2005/xpath-functions"

  xmlns:utils="http://localhost/xsl/xml2json/utils"

  extension-element-prefixes="str xpath"
  exclude-result-prefixes="utils"
>


  <!--
    Performs good old string replace (not the same as translate(),
    because we have 1-to-1 symbol substitution there).

    @param {string} str
    @param {string} search
    @param {string=} replace  Defaults to empty string.
    @return {string}
  -->
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

          <!--
            Xalan.
            Use hack where splitting string by $search and then joining with
            $replace as a delimiter.
          -->
          <xsl:when test="function-available('str:split')">
            <xsl:call-template name="utils:join">
              <xsl:with-param name="set" select="str:split($str, $search)" />
              <xsl:with-param name="delimiter" select="$replace" />
            </xsl:call-template>


            <!--
              Xalan's behaviour:
              str:split('one|two|', '|') =>
              <token>one</token><token>two</token>

              Meanwhile:
              str:split('|one|two', '|') =>
              <token></token><token>one</token><token>two</token>

              We do have to append $replace if $str ends with $search.
              We don't have to prepend $replace, if $str starts with $search.
              Weird, right?
              -->
            <xsl:if test="
              substring(
                $str,
                string-length($str) - string-length($search) + 1
              )
              = $search
            ">
              <xsl:value-of select="$replace" disable-output-escaping="yes" />
            </xsl:if>
          </xsl:when>

          <!--
            Saxon.
            Here we have XPath 2.0 replace function that accepts RegEx patterns
            (not simple strings) as search and replace parameters.
            It means that we have to escape \ symbol (regex special symbol)
            in search and replace parameters with additional \ symbol.
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
            Old school fallback - recursion.

            === WARNING ===
            All XSLT processors have protection system from infinite recursion.
            If self-calling depth of some template becomes more than some
            constant (normally about 3000), processor throws an exception.
            That's why proper work of this replace method is not guaranteed
            if you deal with really long strings containing a lot of $replace
            symbols.
            -->
          <xsl:otherwise>
            <xsl:value-of
              select="substring-before($str, $search)"
              disable-output-escaping="yes"
            />
            <xsl:value-of select="$replace" disable-output-escaping="yes" />
            <xsl:call-template name="utils:str_replace">
              <xsl:with-param
                name="str" select="substring-after($str, $search)"
              />
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
  

  <!--
    Joins nodes of $set to one string using $delimiter

    @param {Nodeset} set
    @param {string=} delimiter  Defaults to comma ','
    @return {string}
  -->
  <xsl:template name="utils:join">
    <xsl:param name="set" />
    <xsl:param name="delimiter" select="','" />

    <xsl:choose>

      <!-- Saxon -->
      <xsl:when test="function-available('xpath:string-join')">
        <xsl:value-of
          select="xpath:string-join($set, $delimiter)"
          disable-output-escaping="yes"
        />
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


  <!--
    Checks if all nodes in $set have distinct names

    @param {Nodeset} set
    @return {boolean}  String 'true' or 'false'.
    -->
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


  <!--
    Checks if all nodes in $set have same names

    @param {Nodeset} set
    @return {boolean}  String 'true' or 'false'.
    -->
  <xsl:template name="utils:is_all_names_equals">
    <xsl:param name="set" />

    <xsl:choose>
      <xsl:when test="$set[name() != name($set[1])]">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>
