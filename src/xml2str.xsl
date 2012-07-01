<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview Templates for converting XML to json string containing that XML.
  The main goal is to convert HTML to json strings.
  @author Alexander Samilyak (aleksam241@gmail.com)

  This source code follows Formatting section of Google C++ Style Guide
  http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Formatting
  -->

<!DOCTYPE xsl:stylesheet[
  <!ENTITY % const SYSTEM "constants.dtd">
  %const;
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"

  xmlns:xml2str="http://localhost/xsl/xml2json/xml2string"
  xmlns:utils="http://localhost/xsl/xml2json/utils"

  extension-element-prefixes="exsl"
  exclude-result-prefixes="xml2str utils"
>

  <xsl:import href="utils.xsl" />

  <!--
    All HTML4 self closed empty tags.
    -->
  <xsl:variable name="xml2str:empty_html_tags_rtf">
    <area />
    <base />
    <basefont />
    <br />
    <col />
    <frame />
    <hr />
    <img />
    <input />
    <isindex />
    <link />
    <meta />
    <param />
  </xsl:variable>

  <xsl:variable
    name="xml2str:empty_html_tags"
    select="exsl:node-set($xml2str:empty_html_tags_rtf)/*"
  />


  <!--
    Converts context node content to string (including child elements).
    This is recursive conversion.

    @return {string}
    -->
  <xsl:template match="*" mode="xml2str:convert">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()" />
    <xsl:apply-templates select="." mode="xml2str:convert_attrs" />

    <xsl:choose>
      <!--
        Print self closed tag (<tag />) if the name
        is in $xml2str:empty_html_tags and the element is empty.
        -->
      <xsl:when test="
        $xml2str:empty_html_tags[name() = name(current())] and
        not(node())
      ">
        <xsl:text>/&gt;</xsl:text>
      </xsl:when>

      <!--
        Print closing tag otherwise (<tag>possible content</tag>).
        -->
      <xsl:otherwise>
        <xsl:text>&gt;</xsl:text>

        <xsl:apply-templates mode="xml2str:convert" />

        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()" />
        <xsl:text>&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="@* | text()" mode="xml2str:convert">
    <xsl:call-template name="xml2str:escape">
      <xsl:with-param name="str" select="." />
    </xsl:call-template>
  </xsl:template>


  <xsl:template match="*" mode="xml2str:convert_attrs">
    <xsl:for-each select="@*">
      <xsl:value-of select="concat(' ', name(), '=')" />
      <xsl:text>&ATTR_VALUE_QUOTE;</xsl:text>

      <xsl:call-template name="xml2str:escape_attr">
        <xsl:with-param name="str" select="." />
      </xsl:call-template>

      <xsl:text>&ATTR_VALUE_QUOTE;</xsl:text>
    </xsl:for-each>
  </xsl:template>


  <!--
    Escapes xml special symbols '&', '<', ']]>'.

    Suppose we need to print string 'Procter&Gamble' wrapped with <p>.
    Then we should write in input xml:
    <p>Procter&amp;Gamble</p>

    But here in xsl we'll have that xml as:
    <p>Procter&Gamble</p>
    (&amp; was substitued with &)

    We can't print it as is because this is invalid xml.
    So we have to escape xml special symbols:
      &  => &amp;
      <  => &lt;
      ]]> => ]]&gt;


    @param {string=} str
    @return {string}
  -->
  <xsl:template name="xml2str:escape">
    <xsl:param name="str" select="''" />

    <xsl:variable name="step1">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$str" />
        <xsl:with-param name="search" select="'&amp;'" />
        <xsl:with-param name="replace" select="'&amp;amp;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step2">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step1" />
        <xsl:with-param name="search" select="'&lt;'" />
        <xsl:with-param name="replace" select="'&amp;lt;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step3">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step2" />
        <xsl:with-param name="search" select="']]>'" />
        <xsl:with-param name="replace" select="']]&amp;gt;'" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:copy-of select="$step3" />
  </xsl:template>


  <!--
    Escapes single and double quote for attribute values (apart from regular xml
    escaping by name="xml2str:escape", it's called internally).

    @param {string=} str
    @return {string}
  -->
  <xsl:template name="xml2str:escape_attr">
    <xsl:param name="str" select="''" />

    <xsl:variable name="str_common_escaped">
      <xsl:call-template name="xml2str:escape">
        <xsl:with-param name="str" select="$str" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="step1">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$str_common_escaped" />
        <xsl:with-param name="search" select="'&quot;'" />
        <xsl:with-param name="replace" select="'&amp;quot;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step2">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step1" />
        <xsl:with-param name="search" select='"&apos;"' />
        <xsl:with-param name="replace" select="'&amp;apos;'" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:copy-of select="$step2" />
  </xsl:template>


</xsl:stylesheet>