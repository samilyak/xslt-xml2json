<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsd="http://www.w3.org/2001/XMLSchemaAlias"
                exclude-result-prefixes="xs xsd"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                extension-element-prefixes="test">
  
<test:tests>
  <test:title>test:sorted-children function: XSD-Aware Sorting of Children of a Node</test:title>
  <test:test>
    <test:title>Sorting elements in an xs:all</test:title>
    <test:param name="element">
      <xs:all>
        <xs:annotation>
          <xs:documentation>The order of declarations in an xs:all is insignificant</xs:documentation>
        </xs:annotation>
        <xs:element name="foo" />
        <xs:element name="bar" />
      </xs:all>
    </test:param>
    <test:expect>
      <xs:annotation>
        <xs:documentation>The order of declarations in an xs:all is insignificant</xs:documentation>
      </xs:annotation>
      <xs:element name="bar" />
      <xs:element name="foo" />
    </test:expect>
  </test:test>
  <test:test>
    <test:title>Sorting attribute declarations</test:title>
    <test:param name="element">
      <xs:complexType name="person">
        <xs:sequence>
          <xs:element name="firstname" />
          <xs:element name="surname" />
        </xs:sequence>
        <xs:attribute name="dob" as="xs:date" />
        <xs:attribute name="age" as="xs:integer" />
      </xs:complexType>
    </test:param>
    <test:expect>
      <xs:sequence>
        <xs:element name="firstname" />
        <xs:element name="surname" />
      </xs:sequence>
      <xs:attribute name="age" as="xs:integer" />
      <xs:attribute name="dob" as="xs:date" />
    </test:expect>
  </test:test>
</test:tests>
<xsl:function name="test:sorted-children" as="node()*">
  <xsl:param name="element" as="element()" />
  <xsl:choose>
    <xsl:when test="$element instance of element(xs:all)">
      <xsl:sequence select="$element/xs:annotation" />
      <xsl:perform-sort select="$element/xs:element">
        <xsl:sort select="xsd:expanded-name(.)" />
      </xsl:perform-sort>
    </xsl:when>
    <xsl:when test="$element/(xs:attribute | xs:attributeGroup | xs:anyAttribute)">
      <xsl:sequence select="$element/* 
                              except $element/(xs:attribute | xs:attributeGroup | xs:anyAttribute)" />
      <xsl:perform-sort select="$element/xs:attribute">
        <xsl:sort select="xsd:expanded-name(.)" />
      </xsl:perform-sort>
      <xsl:perform-sort select="$element/xs:attributeGroup">
        <xsl:sort select="resolve-QName(@ref, .)" />
      </xsl:perform-sort>
      <xsl:perform-sort select="$element/xs:anyAttribute">
        <xsl:sort select="xs:anyURI(@namespace)" />
      </xsl:perform-sort>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$element/node() except $element/text()[not(normalize-space(.))]" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<xsl:function name="xsd:expanded-name" as="xs:string">
  <xsl:param name="decl" as="element()" />
  <xsl:choose>
    <xsl:when test="$decl/@name">
      <xsl:choose>
        <xsl:when test="$decl/parent::xs:schema or
                        $decl/@form = 'qualified' or
                        ($decl instance of element(xs:element) and
                         $decl/ancestor::xs:schema/@elementFormDefault = 'qualified') or
                        ($decl instance of element(xs:attribute) and
                         $decl/ancestor::xs:schema/@attributeFormDefault = 'qualified')">
          <xsl:sequence select="concat('{', $decl/ancestor::xs:schema/@targetNamespace, '}', $decl/@name)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="concat('{}', $decl/@name)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="qname" as="xs:QName" 
        select="resolve-QName($decl/@ref, $decl)" />
      <xsl:sequence select="concat('{', namespace-uri-from-QName($qname), '}', local-name-from-QName($qname))" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
</xsl:stylesheet>
