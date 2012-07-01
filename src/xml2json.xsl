<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview XSLT 1.0 based XML to JSON converter.
  Tested with XSLT processors:
    - libxslt 1.1
    - Xalan-Java 2.7.1
    - Saxon-Java 9.1.0.8
  This file contains converter's public API.

  @author Alexander Samilyak (aleksam241@gmail.com)
  @see https://github.com/samilyak/xslt-xml2json

  This source code follows Formatting section of Google C++ Style Guide
  http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Formatting
  -->

<!DOCTYPE xsl:stylesheet[
  <!ENTITY % const SYSTEM "constants.dtd">
  %const;
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:core="http://localhost/xsl/xml2json/core"
  exclude-result-prefixes="core"
>


  <xsl:import href="core.xsl" />
  <xsl:import href="utils.xsl" />
  <xsl:import href="xml2str.xsl" />

  <xsl:output omit-xml-declaration="yes" indent="no" />

  <!--
    Converts xml to json.

    @param {Nodeset|RTF=} Xml that should be converted to json.
    Default to current node.

    @param {Nodeset|string=} Nodes that should be converted to json-string
    no matter what's the content of these nodes.
    If you pass a string it's treated as an XPath expression to evaluate
    desired nodes. Context node for this evaluation is a root of the tree
    containing first node of $data nodeset.
    Defaults to empty string.

    This parameter is useful when you have xml containing html and you want
    to convert this html to json string. For example:

    <xsl:call-template name="xml2json">
      <xsl:with-param name="data">
        <article>
          <content>
            <p><strong>Lorem ipsum</strong> dolor sit amet</p>
          </content>
        </article>
      </xsl:with-param>
      <xsl:with-param name="string_elems" select="'/article/content'" />
    </xsl:call-template>

    ==>

    {
      article : {
        content : "<p><strong>Lorem ipsum</strong> dolor sit amet</p>"
      }
    }

    @param {boolean=} Should we skip the root of the result json object
    and therefore print value of the this object's single key.
    This parameter is useful when $data is 1 node or nodeset of elements that
    have the same name. Defaults to false().
    For example:

    <xsl:call-template name="xml2json">
      <xsl:with-param name="data">
        <article>
          <content>Lorem ipsum dolor sit amet</content>
        </article>
      </xsl:with-param>
      <xsl:with-param name="skip_root" select="true()" />
    </xsl:call-template>

    ==>

    { content: "Lorem ipsum dolor sit amet" }

    (there is no 1st level 'article' key).

    @return {string}
    -->
  <xsl:template name="xml2json">
    <xsl:param name="data" select="." />
    <xsl:param name="string_elems" select="''" />
    <xsl:param name="skip_root" select="false()" />

    <xsl:call-template name="core:convert">
      <xsl:with-param name="data" select="$data" />
      <xsl:with-param name="string_elems" select="$string_elems" />
      <xsl:with-param name="skip_root" select="$skip_root" />
    </xsl:call-template>
  </xsl:template>


  <!--
    Converts xml to json and saves it to html attribute.
    This template is using template name="xml2json" internally
    (check its parameters reference).

    Example #1 ('onclick' attribute):

    <xsl:call-template name="xml2json_attr">
      <xsl:with-param name="data">
        <article>
          <content>Lorem ipsum</content>
        </article>
      </xsl:with-param>
    </xsl:call-template>

    ==>

    onclick='return {"article":{"content":"Lorem ipsum"}}'

    ========================================================

    Example #2 (attribute starting with 'data-', e.g. 'data-content'):

    <xsl:call-template name="xml2json_attr">
      <xsl:with-param name="attr" select="'data-data'" />
      <xsl:with-param name="data">
        <root>
          <elem width="640" src="http://www.google.com/" />
        </root>
      </xsl:with-param>
      <xsl:with-param name="string_elems" select="'/root'" />
      <xsl:with-param name="skip_root" select="true()" />
    </xsl:call-template>

    ==>

    data-data="&lt;elem width=&quot;640&quot; src=&quot;http://www.google.com/&quot;/&gt;"


    @param {Nodeset|RTF=} Xml that should be converted to json.
    Default to current node.
    @param {Nodeset|string=} Nodes that should be converted to json-string
    no matter what's the content of these nodes. Defaults to empty string.
    @param {boolean=} Should we skip the root of the result json object.
    Defaults to false.
    @param {string=} Html attribute name that is used to save result json.
    We'll print 'return ' in front of result json if attribute name doesn't
    start with 'data-' (prefix data).
    If attribute name does start with 'data-' and result json is a string then
    this string won't be surrounded with json quotes and won't be json escaped
    (see Example #2 above).
    Defaults to 'onclick'.

    @return {string}
  -->
  <xsl:template name="xml2json_attr">
    <xsl:param name="data" select="." />
    <xsl:param name="string_elems" select="''" />
    <xsl:param name="skip_root" select="false()" />
    <xsl:param name="attr" select="'onclick'" />

    <xsl:variable name="json">
      <xsl:call-template name="core:convert">
        <xsl:with-param name="data" select="$data" />
        <xsl:with-param name="string_elems" select="$string_elems" />
        <xsl:with-param name="skip_root" select="$skip_root" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="normalize-space($json)">
      <xsl:variable
        name="is_attr_with_prefix_data" select="starts-with($attr, 'data-')"
      />
      <xsl:variable
        name="is_json_string" select="starts-with($json, '&quot;')"
      />

      <xsl:attribute name="{$attr}">
        <xsl:if test="not($is_attr_with_prefix_data)">
          <xsl:text>return </xsl:text>
        </xsl:if>

        <xsl:choose>
          <xsl:when test="$is_attr_with_prefix_data and $is_json_string">
            <xsl:variable
              name="str_without_outer_quotes"
              select="substring($json, 2, string-length($json) - 2)"
            />

            <xsl:variable name="unescaped_str">
              <xsl:call-template name="core:string_unescape">
                <xsl:with-param name="str" select="$str_without_outer_quotes" />
              </xsl:call-template>
            </xsl:variable>

            <xsl:value-of
              select="$unescaped_str" disable-output-escaping="yes"
            />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$json" disable-output-escaping="yes" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>