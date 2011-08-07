<?xml version="1.0" encoding="utf-8" ?>

<!--
  @fileoverview Builder for xml2json XSL source code.
  It takes root XSL file xml2json.xsl, look through all its imports,
  and concatenates it all at one resulting XSL document,
  which is the output of this template.
  Tested with libxslt 1.1 only!
  @author Alexander Samilyak (aleksam241@gmail.com)

  This source code follows Formatting section of Google C++ Style Guide
  http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Formatting
  -->

<!DOCTYPE xsl:stylesheet [
	<!ENTITY SRC_DIR    "../src">
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:sets="http://exslt.org/sets"
  xmlns:str="http://exslt.org/strings"
  xmlns:dyn="http://exslt.org/dynamic"

  xmlns:build="http://localhost/xsl/xml2json/build"

  extension-element-prefixes="exsl sets str dyn"
  exclude-result-prefixes="build"
>

  <xsl:output indent="yes" method="xml" encoding="utf-8" />


  <!--
    We need to make one single XPath-string to xsl:stylesheet elements
    of all source code XSL templates (root template and all its imports).
    It has to look like this:
    /xsl:stylesheet | document('file2.xsl')/xsl:stylesheet | document('file3.xsl')/xsl:stylesheet
    -->
  <xsl:variable name="build:stylesheets_xpath">
    <xsl:text>/xsl:stylesheet</xsl:text>
    <xsl:for-each select="xsl:stylesheet/xsl:import">
      <xsl:text> | </xsl:text>
      <xsl:value-of select="concat(
        'document(&quot;', '&SRC_DIR;', '/', @href, '&quot;)',
        '/xsl:stylesheet'
       )"/>
    </xsl:for-each>
  </xsl:variable>

  <!--
    Now we evaluate constructed XPath-string to get node-set
    that contains all xsl:stylesheet elements
    -->
  <xsl:variable
    name="build:stylesheets" select="dyn:evaluate($build:stylesheets_xpath)"
  />


  <xsl:template match="/">
    <xsl:call-template name="build:info" />

    <xsl:element name="xsl:stylesheet">
      <xsl:call-template name="build:stylesheet_attrs_and_namespaces" />
      <xsl:call-template name="build:prefixes_to_exclude" />
      <xsl:call-template name="build:common_directives" />
      <xsl:call-template name="build:stylesheets_code" />
    </xsl:element>
  </xsl:template>


  <xsl:template name="build:info">
    <xsl:text>&#xA;</xsl:text>
    <xsl:comment>
      <xsl:value-of select="document('info.xml')/info" />

      <xsl:text>&#xA;This code is generated automatically. </xsl:text>
      <xsl:text>Please, DO NOT EDIT.&#xA;</xsl:text>
    </xsl:comment>
    <xsl:text>&#xA;&#xA;</xsl:text>
  </xsl:template>


  <!--
    Attributes extension-element-prefixes and exclude-result-prefixes
    need special processing
    so we copy all other xsl:stylesheet attributes and all its namespaces
    -->
  <xsl:template name="build:stylesheet_attrs_and_namespaces">
    <xsl:copy-of select="
      $build:stylesheets/@*[
        not(name(.) = 'extension-element-prefixes') and
        not(name(.) = 'exclude-result-prefixes')
      ]
      |
      $build:stylesheets/namespace::*
    "/>
  </xsl:template>


  <!--
    Joining extension-element-prefixes and exclude-result-prefixes
    attributes of all XSL files
    and put result in one attribute exclude-result-prefixes.
    -->
  <xsl:template name="build:prefixes_to_exclude">
    <xsl:variable name="prefixes_to_exclude">
      <xsl:for-each select="
        $build:stylesheets/@extension-element-prefixes |
        $build:stylesheets/@exclude-result-prefixes
      ">
        <xsl:value-of select="." /><xsl:text> </xsl:text>
      </xsl:for-each>
    </xsl:variable>

    <!--
      We don't need duplicates of prefixes so we call sets:distinct function
      -->
    <xsl:variable
      name="distinct_prefixes_to_exclude"
      select="sets:distinct(str:split(normalize-space($prefixes_to_exclude)))"
    />

    <xsl:attribute name="exclude-result-prefixes">
      <xsl:for-each select="$distinct_prefixes_to_exclude">
        <xsl:value-of select="." />
        <xsl:if test="position() != last()">
          <xsl:text> </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:attribute>
  </xsl:template>



  <xsl:variable name="build:common_directives">
    <output />
    <strip-space />
    <preserve-space />
  </xsl:variable>

  <xsl:variable name="build:excluding_directives">
    <import />
    <include />
  </xsl:variable>

  <!--
    Takes common XSL directives (such as xsl:output) from _main stylesheet_
    and copy it as is
    -->
  <xsl:template name="build:common_directives">
    <xsl:variable name="main_stylesheet" select="/xsl:stylesheet" />
    <xsl:for-each select="exsl:node-set($build:common_directives)/*">
      <xsl:copy-of
        select="$main_stylesheet/*[local-name(.) = name(current())]"
      />
    </xsl:for-each>
  </xsl:template>


  <!--
    Takes from all XSL files xsl:stylesheet child elements
    (excluding common XSL directives and xsl:import or xsl:include)
    and copy it with whitespaces and formatting but without comments
    -->
  <xsl:template name="build:stylesheets_code">
    <xsl:variable
      name="directives_not_to_copy"
      select="
        exsl:node-set($build:common_directives)/* |
        exsl:node-set($build:excluding_directives)/*
      "
    />

    <xsl:for-each select="$build:stylesheets/node()">
      <xsl:if test="
        not($directives_not_to_copy[name(.) = local-name(current())])
      ">
        <xsl:apply-templates select="." mode="build:code_element" />
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="*" mode="build:code_element">
    <xsl:element name="{name(.)}">
      <xsl:copy-of select="@* | namespace::*" />
      <xsl:apply-templates select="node()" mode="build:code_element" />
    </xsl:element>
  </xsl:template>


</xsl:stylesheet>