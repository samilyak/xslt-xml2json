<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                extension-element-prefixes="test"
                xmlns="http://www.w3.org/1999/XSL/TransformAlias"
                xmlns:t="http://www.jenitennison.com/xslt/unit-testAlias"
                exclude-result-prefixes="#default t xs"
                xmlns:o="http://www.w3.org/1999/XSL/TransformAliasAlias">
  
<xsl:namespace-alias stylesheet-prefix="#default" result-prefix="xsl"/>
<xsl:namespace-alias stylesheet-prefix="t" result-prefix="test"/>
  
<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xsl:text"/>
  
<xsl:output indent="yes" encoding="ISO-8859-1" />  
  
<xsl:variable name="test:config-att" as="attribute()?" 
  select="/xsl:*/@test:config | /test:suite/@config" />  
  
<xsl:variable name="test:config" as="xs:anyURI?" 
  select="if ($test:config-att) 
          then resolve-uri($test:config-att, base-uri(/*)) 
          else ()" />

<xsl:variable name="stylesheet" as="document-node()"
  select="if (/test:suite)
          then doc(resolve-uri(/test:suite/@stylesheet, base-uri(.)))
          else /" />
  
<xsl:key name="functions" 
         match="xsl:function" 
         use="resolve-QName(@name, .)" />
<xsl:key name="named-templates" 
         match="xsl:template[@name]"
         use="resolve-QName(@name, .)" />
<xsl:key name="matching-templates" 
         match="xsl:template[@match]" 
         use="concat('match=', @match, '+',
                     'mode=', @mode)" />
  
<xsl:template match="/">
  <xsl:apply-templates mode="test:generate-tests" />
</xsl:template>  
  
<xsl:template match="/xsl:stylesheet | /xsl:transform | /test:suite" mode="test:generate-tests">
  <xsl:variable name="stylesheet-uri" as="xs:anyURI" 
    select="base-uri($stylesheet)" />
  <stylesheet version="2.0"
              exclude-result-prefixes="o">
    <xsl:for-each select="namespace::*">
      <xsl:namespace name="{name()}" select="." />
    </xsl:for-each>
    <import href="{resolve-uri('generate-tests-utils.xsl', static-base-uri())}"/>
    <xsl:if test="exists($test:config)">
      <import href="{$test:config}" />
    </xsl:if>
    <import href="{$stylesheet-uri}"/>
    <namespace-alias stylesheet-prefix="o" result-prefix="xsl" />
    <output indent="yes" />
    <template match="/">
      <call-template name="main" />
    </template>
    <template name="main">
      <processing-instruction name="xml-stylesheet">
        <xsl:text>type="text/xsl" href="</xsl:text>
        <xsl:value-of select="resolve-uri('format-report.xsl',
          static-base-uri())" />
        <xsl:text>"</xsl:text>
      </processing-instruction>
      <t:report stylesheet="{$stylesheet-uri}"
                date="{{current-dateTime()}}">
        <xsl:apply-templates select="test:tests" mode="test:generate-calls" />
      </t:report>
    </template>
    <xsl:apply-templates select="test:*" mode="test:generate-tests" />
  </stylesheet>
</xsl:template>  
  
<xsl:template match="test:tests" mode="test:generate-calls">
  <t:tests id="{test:generate-id(.)}">
    <xsl:copy-of select="test:title" />
    <t:xslt>
      <xsl:apply-templates select="test:related-xslt-element(.)"
                           mode="test:alias-xsl" />
    </t:xslt>
    <xsl:for-each select="test:test">
      <call-template name="{test:generate-id(.)}" />
    </xsl:for-each>
  </t:tests>
</xsl:template>  
  
<xsl:template match="test:tests" mode="test:generate-tests">
  <xsl:variable name="next-xslt-element" as="element()"
    select="test:related-xslt-element(.)" />
  <xsl:choose>
    <xsl:when test="$next-xslt-element instance of element(xsl:template)">
      <xsl:apply-templates select="test:test" mode="test:generate-template-test">
        <xsl:with-param name="template" select="$next-xslt-element" />
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="$next-xslt-element instance of element(xsl:function)">
      <xsl:apply-templates select="test:test" mode="test:generate-function-test">
        <xsl:with-param name="function" select="$next-xslt-element" />
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>
        <xsl:text>Warning: Test applies to unsupported XSLT element: </xsl:text>
        <xsl:value-of select="name($next-xslt-element)" />
      </xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>  
  
<xsl:template match="test:test" mode="test:generate-template-test">
  <xsl:param name="template" required="yes" as="element(xsl:template)" />
  <template name="{test:generate-id(.)}">
    <xsl:apply-templates select="test:global" mode="test:generate-tests" />
    <xsl:apply-templates select="test:context" mode="test:generate-tests" />
    <xsl:apply-templates select="test:expect" mode="test:generate-tests" />
    <variable name="actual-result" as="item()*">
      <xsl:apply-templates select="test:param"
        mode="test:generate-tests" />
      <xsl:choose>
        <xsl:when test="$template/@name">
          <xsl:variable name="template-call">
            <call-template name="{$template/@name}">
              <xsl:for-each select="test:param">
                <with-param name="{@name}" select="${@name}" />
              </xsl:for-each>
            </call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="test:context">
              <for-each select="$context">
                <xsl:copy-of select="$template-call" />
              </for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="$template-call" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <apply-templates select="$context">
            <xsl:variable name="mode">
              <xsl:choose>
                <xsl:when test="test:context/@mode">
                  <xsl:value-of select="test:context/@mode" />
                </xsl:when>
                <xsl:when test="$template/@mode">
                  <xsl:value-of select="tokenize($template/@mode, '\s+')[1]" />
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:if test="string($mode)">
              <xsl:attribute name="mode" select="$mode" />
            </xsl:if>
            <xsl:for-each select="test:param">
              <with-param name="{@name}" select="${@name}" />
            </xsl:for-each>
          </apply-templates>
        </xsl:otherwise>
      </xsl:choose>      
    </variable>
    <xsl:apply-templates select="." mode="test:report" />
  </template>
</xsl:template>

<xsl:template match="test:test" mode="test:generate-function-test">
  <xsl:param name="function" required="yes" as="element(xsl:function)" />
  <template name="{test:generate-id(.)}">
    <xsl:apply-templates select="test:param" mode="test:generate-tests" />
    <xsl:apply-templates select="test:expect" mode="test:generate-tests" />
    <variable name="actual-result" as="item()*">
      <xsl:attribute name="select">
        <xsl:value-of select="$function/@name" />
        <xsl:text>(</xsl:text>
        <xsl:for-each select="$function/xsl:param">
          <xsl:text>$</xsl:text>
          <xsl:value-of select="@name" />
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:attribute>
    </variable>
    <xsl:apply-templates select="." mode="test:report" />
  </template>
</xsl:template>

<xsl:template match="test:context" mode="test:generate-tests">
  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
    <xsl:with-param name="var" select="'context'" />
  </xsl:apply-templates>
</xsl:template>  
  
<xsl:template match="test:expect" mode="test:generate-tests">
  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
    <xsl:with-param name="var" select="'expected-result'" />
  </xsl:apply-templates>
</xsl:template>
  
<xsl:template match="test:global | test:param" mode="test:generate-tests">
  <xsl:apply-templates select="." mode="test:generate-variable-declarations">
    <xsl:with-param name="var" select="@name" />
  </xsl:apply-templates>
</xsl:template>  
  
<xsl:template match="test:global | test:context | test:param | test:expect"
  mode="test:generate-variable-declarations">
  <xsl:param name="var" as="xs:string" required="yes" />
  <xsl:choose>
    <xsl:when test="node() or @href">
      <variable name="{$var}-doc" as="document-node()">
        <xsl:choose>
          <xsl:when test="@href">
            <xsl:attribute name="select">
              <xsl:text>doc('</xsl:text>
              <xsl:value-of select="resolve-uri(@href, base-uri(.))" />
              <xsl:text>')</xsl:text>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <document>
              <xsl:apply-templates mode="test:create-xslt-generator" />
            </document>
          </xsl:otherwise>
        </xsl:choose>
      </variable>
      <variable name="{$var}"
        select="{if (@select) 
                 then concat('$', $var, '-doc/(', @select, ')')
                 else concat('$', $var, '-doc/*')}" />
    </xsl:when>
    <xsl:otherwise>
      <variable name="{$var}" select="{@select}" />
    </xsl:otherwise>
  </xsl:choose>        
</xsl:template>  

<xsl:template match="*" mode="test:create-xslt-generator">
  <xsl:copy>
    <xsl:copy-of select="@*" />
    <xsl:apply-templates mode="test:create-xslt-generator" />
  </xsl:copy>
</xsl:template>  
  
<xsl:template match="text()" mode="test:create-xslt-generator">
  <text><xsl:value-of select="." /></text>
</xsl:template>  
  
<xsl:template match="comment()" mode="test:create-xslt-generator">
  <comment><xsl:value-of select="." /></comment>
</xsl:template>
  
<xsl:template match="processing-instruction()" mode="test:create-xslt-generator">
  <processing-instruction name="{name()}">
    <xsl:value-of select="." />
  </processing-instruction>
</xsl:template>
  
<xsl:template match="test:test" mode="test:report">
  <xsl:variable name="id" as="xs:string" select="test:generate-id(.)" />
  <variable name="successful" 
    select="test:deep-equal($expected-result, $actual-result)" />
  <if test="not($successful)">
    <message>
      <xsl:text>  Failed </xsl:text>
      <xsl:value-of select="$id" />
      <xsl:if test="test:title">: <xsl:value-of select="test:title" /></xsl:if>
    </message>
  </if>
  <xsl:copy>
    <xsl:attribute name="id" select="$id" />
    <xsl:copy-of select="@*" />
    <xsl:attribute name="successful">{$successful}</xsl:attribute>
    <xsl:apply-templates select="test:*" mode="test:report" />
    <call-template name="test:report-value">
      <with-param name="value" select="$actual-result" />
    </call-template>
  </xsl:copy>
</xsl:template>  
  
<xsl:template match="test:*[@href]" mode="test:report">
  <xsl:copy>
    <xsl:copy-of select="@*" />
    <xsl:attribute name="href" select="resolve-uri(@href, base-uri(.))" />
    <xsl:copy-of select="node()" />
  </xsl:copy>
</xsl:template>  
  
<xsl:template match="test:*" mode="test:report">
  <xsl:copy-of select="." />
</xsl:template>  
  
<xsl:template match="xsl:*" mode="test:alias-xsl">
  <xsl:element name="o:{local-name()}">
    <xsl:apply-templates select="@*|node()" mode="test:alias-xsl" />
  </xsl:element>
</xsl:template>  
  
<xsl:template match="@xsl:*" mode="test:alias-xsl">
  <xsl:attribute name="o:{local-name()}" 
    select="replace(replace(., '\{', '{{'), '\}', '}}')" />
</xsl:template>  
  
<xsl:template match="*" mode="test:alias-xsl">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="test:alias-xsl" />
  </xsl:copy>
</xsl:template>

<xsl:template match="@*" mode="test:alias-xsl">
  <xsl:attribute name="{name(.)}" namespace="{namespace-uri(.)}"
    select="replace(replace(., '\{', '{{'), '\}', '}}')" />
</xsl:template>  
  
<xsl:function name="test:related-xslt-element" as="element()+">
  <xsl:param name="tests" as="element(test:tests)" />
  <xsl:choose>
    <xsl:when test="$tests/test:xslt">
      <xsl:variable name="xslt" as="element()" 
        select="$tests/test:xslt/xsl:*" />
      <xsl:choose>
        <xsl:when test="$xslt instance of element(xsl:function)">
          <xsl:sequence select="key('functions', 
                                    resolve-QName($xslt/@name, $xslt), 
                                    $stylesheet)" />
        </xsl:when>
        <xsl:when test="$xslt instance of element(xsl:template) and
                        $xslt/@name">
          <xsl:sequence select="key('named-templates', 
                                    resolve-QName($xslt/@name, $xslt), 
                                    $stylesheet)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="key('matching-templates',
                                    concat('match=', $xslt/@match, '+',
                                           'mode=', $xslt/@mode),
                                    $stylesheet)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$tests/following-sibling::xsl:*[1]" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<xsl:function name="test:generate-id" as="xs:string">
  <xsl:param name="test" as="element()" />
  <xsl:choose>
    <xsl:when test="$test/@id">
      <xsl:value-of select="$test/@id" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$test instance of element(test:test)">
          <xsl:value-of select="concat(test:generate-id($test/..), '.',
                                       count($test/preceding-sibling::test:test) + 1)" />
        </xsl:when>
        <xsl:when test="$test instance of element(test:tests)">
          <xsl:variable name="related-xslt-element" as="element()"
            select="test:related-xslt-element($test)[1]" />
          <xsl:choose>
            <xsl:when test="$related-xslt-element instance of element(xsl:function)
                            or $related-xslt-element[self::xsl:template[@name]]">
              <xsl:value-of select="local-name-from-QName(
                                      resolve-QName($related-xslt-element/@name,
                                                    $related-xslt-element))" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="generate-id($test)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="generate-id($test)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
</xsl:stylesheet>
