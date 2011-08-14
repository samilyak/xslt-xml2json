<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                exclude-result-prefixes="test xs"
                xmlns="http://www.w3.org/1999/xhtml">
  
<xsl:template match="/">
  <xsl:apply-templates select="." mode="test:html-report" />
</xsl:template>  
  
<xsl:template match="test:report" mode="test:html-report">
  <html>
    <head>
      <title>Test Report for <xsl:value-of select="test:format-URI(@stylesheet)" /></title>
      <link rel="stylesheet" type="text/css" 
            href="{resolve-uri('test-report.css', static-base-uri())}" />
    </head>
    <body>
      <h1>Test Report</h1>
      <p>Stylesheet:  <a href="{@stylesheet}"><xsl:value-of select="test:format-URI(@stylesheet)" /></a></p>
      <p>
        <xsl:text>Tested: </xsl:text>
        <xsl:value-of select="format-dateTime(@date, '[D] [MNn] [Y] at [H01]:[m01]')" />
      </p>
      <h2>Summary</h2>
      <p>
        Passed <xsl:value-of select="count(test:tests/test:test[@successful = 'true'])"
          />/<xsl:value-of select="count(test:tests/test:test)" />
      </p>
      <table>
        <thead>
          <tr>
            <th>Test ID</th>
            <th>Title</th>
            <th>Success/Total</th>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="test:tests">
            <xsl:choose>
              <xsl:when test="test:test[@successful = 'false']">
                <tr class="failed">
                  <td>
                    <a href="#{@id}">
                      <xsl:value-of select="@id" />
                    </a>
                  </td>
                  <td>
                    <a href="#{@id}">
                      <xsl:value-of select="test:title" />
                    </a>
                  </td>
                  <td>
                    <xsl:value-of select="count(test:test[@successful = 'true'])" />
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="count(test:test)" />
                  </td>
                </tr>
              </xsl:when>
              <xsl:otherwise>
                <tr class="successful">
                  <td><xsl:value-of select="@id" /></td>
                  <td><xsl:value-of select="test:title" /></td>
                  <td>
                    <xsl:value-of select="count(test:test[@successful = 'true'])" />
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="count(test:test)" />
                  </td>
                </tr>
              </xsl:otherwise>
            </xsl:choose>            
          </xsl:for-each>
        </tbody>
      </table>
      <xsl:apply-templates select="test:tests[test:test[@successful = 'false']]" mode="test:html-report" />
    </body>
  </html>
</xsl:template>
  
<xsl:template match="test:tests" mode="test:html-report">
  <h2 id="{@id}">
    <xsl:value-of select="@id" />
    <xsl:if test="test:title">: <xsl:value-of select="test:title" /></xsl:if>
  </h2>
  <table>
    <thead>
      <tr>
        <th>Test ID</th>
        <th>Test Title</th>
        <th>Success/Failure</th>
      </tr>
    </thead>
    <tbody>
      <xsl:for-each select="test:test">
        <xsl:choose>
          <xsl:when test="@successful = 'true'">
            <tr class="successful">
              <td><xsl:value-of select="@id" /></td>
              <td><xsl:value-of select="test:title" /></td>
              <td>Success</td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <tr class="failed">                  
              <td>
                <a href="#{@id}"><xsl:value-of select="@id" /></a>
              </td>
              <td>
                <a href="#{@id}"><xsl:value-of select="test:title" /></a>
              </td>
              <td>Failure</td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </tbody>
  </table>
  <h3>Tested XSLT</h3>
  <xsl:apply-templates select="test:xslt" mode="test:html-report" />
  <xsl:apply-templates select="test:test[@successful = 'false']" mode="test:html-report" />
</xsl:template>  
  
<xsl:template match="test:test" mode="test:html-report">
  <h3 id="{@id}">
    <xsl:value-of select="@id" />
    <xsl:if test="test:title">: <xsl:value-of select="test:title" /></xsl:if>
  </h3>
  <xsl:if test="test:global">
    <h4>Global variables/parameters</h4>
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="test:global">
          <tr>
            <td><xsl:value-of select="@name" /></td>
            <td>
              <xsl:apply-templates select="." mode="test:html-report" />
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:if>
  <xsl:if test="test:context">
    <h4>Context</h4>
    <xsl:apply-templates select="test:context" mode="test:html-report"/>
  </xsl:if>
  <xsl:if test="test:param">
    <h4>Parameters</h4>
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="test:param">
          <tr>
            <td><xsl:value-of select="@name" /></td>
            <td>
              <xsl:apply-templates select="." mode="test:html-report" />
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:if>
  <h4>Results</h4>
  <table>
    <thead>
      <tr>
        <th>Expected Result</th>
        <th>Actual Result</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>
          <xsl:apply-templates select="test:expect" mode="test:html-report" />
        </td>
        <td>
          <xsl:apply-templates select="test:result" mode="test:html-report" />
        </td>
      </tr>
    </tbody>
  </table>
</xsl:template>  

<xsl:template match="test:global | test:context | test:expect | test:result | 
                     test:param | test:xslt"
              mode="test:html-report">
  <xsl:choose>
    <xsl:when test="@href or node()">
      <xsl:if test="@select">
        <p>XPath <code><xsl:value-of select="@select" /></code> from:</p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="@href">
          <p><a href="{@href}"><xsl:value-of select="test:format-URI(@href)" /></a></p>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="indentation"
            select="string-length(substring-after(text()[1], '&#xA;'))" />
          <pre>
            <xsl:apply-templates select="node()" mode="test:serialize">
              <xsl:with-param name="indentation" tunnel="yes"
                select="$indentation" />
            </xsl:apply-templates>
          </pre>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <pre><xsl:value-of select="@select" /></pre>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>  
  
<xsl:template match="*" mode="test:serialize">
  <xsl:param name="level" as="xs:integer" select="0" tunnel="yes" />
  <xsl:text>&lt;</xsl:text>
  <xsl:value-of select="name()" />
  <xsl:variable name="attribute-indent" as="xs:string">
    <xsl:value-of>
      <xsl:text>&#xA;</xsl:text>
      <xsl:for-each select="1 to $level"><xsl:text>   </xsl:text></xsl:for-each>
      <xsl:value-of select="replace(name(parent::*), '.', ' ')" />
    </xsl:value-of>
  </xsl:variable>
  <xsl:for-each select="@*">
    <xsl:if test="position() > 1">
      <xsl:value-of select="$attribute-indent" />
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()" />
    <xsl:text>="</xsl:text>
    <xsl:value-of select="replace(translate(., '&quot;', '&amp;quot;'),
      '\s(\s+)', '&#xA;$1')" />
    <xsl:text>"</xsl:text>
  </xsl:for-each>
  <xsl:choose>
    <xsl:when test="child::node()">
      <xsl:text>&gt;</xsl:text>
      <xsl:apply-templates mode="test:serialize">
        <xsl:with-param name="level" select="$level + 1" tunnel="yes" />
      </xsl:apply-templates>
      <xsl:text>&lt;/</xsl:text>
      <xsl:value-of select="name()" />
      <xsl:text>&gt;</xsl:text>
    </xsl:when>
    <xsl:otherwise> /&gt;</xsl:otherwise>
  </xsl:choose>
</xsl:template>  
  
<xsl:template match="comment()" mode="test:serialize">
  <xsl:text>&lt;--</xsl:text>
  <xsl:value-of select="." />
  <xsl:text>--&gt;</xsl:text>
</xsl:template>  
  
<xsl:template match="processing-instruction()" mode="test:serialize">
  <xsl:text>&lt;?</xsl:text>
  <xsl:value-of select="name()" />
  <xsl:text> </xsl:text>
  <xsl:value-of select="." />
  <xsl:text>?&gt;</xsl:text>
</xsl:template>  
  
<xsl:template match="text()[not(normalize-space())]" mode="test:serialize">
  <xsl:param name="indentation" as="xs:integer" tunnel="yes" select="0" />
  <xsl:value-of select="concat('&#xA;', substring(., $indentation + 2))" />
</xsl:template>  
  
<xsl:function name="test:format-URI" as="xs:string">
  <xsl:param name="URI" as="xs:anyURI" />
  <xsl:choose>
    <xsl:when test="starts-with($URI, 'file:/')">
      <xsl:value-of select="replace(substring-after($URI, 'file:/'), '%20', ' ')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$URI" />
    </xsl:otherwise>
  </xsl:choose>  
</xsl:function>  
  
</xsl:stylesheet>
