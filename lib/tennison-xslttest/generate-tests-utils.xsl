<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdt="http://www.w3.org/2005/04/xpath-datatypes"
                exclude-result-prefixes="xs xdt t"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                extension-element-prefixes="test"
                xmlns:t="http://www.jenitennison.com/xslt/unit-testAlias">
  
<xsl:namespace-alias stylesheet-prefix="t" result-prefix="test"/>  
  
<test:tests>
  <test:title>test:deep-equal function</test:title>
  <test:test>
    <test:title>Identical Sequences</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(1, 2)" />
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>Non-Identical Sequences</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(1, 3)" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="deep-equal.3">
    <test:title>Sequences with Same Items in Different Orders</test:title>
    <test:param name="seq1" select="(1, 2)" />
    <test:param name="seq2" select="(2, 1)" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="deep-equal.4">
    <test:title>Empty Sequences</test:title>
    <test:param name="seq1" select="()" />
    <test:param name="seq2" select="()" />
    <test:expect select="true()" />
  </test:test>
  <test:test>
    <test:title>One empty sequence</test:title>
    <test:param name="seq1" select="()" />
    <test:param name="seq2" select="1" />
    <test:expect select="false()" />
  </test:test>
</test:tests>
<xsl:function name="test:deep-equal" as="xs:boolean">
  <xsl:param name="seq1" as="item()*" />
  <xsl:param name="seq2" as="item()*" />
  <xsl:choose>
    <xsl:when test="empty($seq1) or empty($seq2)">
      <xsl:sequence select="empty($seq1) and empty($seq2)" />
    </xsl:when>
    <xsl:when test="count($seq1) = count($seq2)">
      <xsl:variable name="first-items-equal" as="xs:boolean"
        select="test:item-deep-equal($seq1[1], $seq2[1])" />
      <xsl:choose>
        <xsl:when test="$first-items-equal">
          <xsl:sequence select="test:deep-equal($seq1[position() > 1],
                                                $seq2[position() > 1])" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="false()" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<test:tests>
  <test:title>test:item-deep-equal function</test:title>
  <test:test id="item-deep-equal.1">
    <test:title>Identical Integers</test:title>
    <test:param name="item1" select="1" />
    <test:param name="item2" select="1" />
    <test:expect select="true()" />
  </test:test>
  <test:test id="item-deep-equal.2">
    <test:title>Non-Identical Strings</test:title>
    <test:param name="item1" select="'abc'" />
    <test:param name="item2" select="'def'" />
    <test:expect select="false()" />
  </test:test>
  <test:test id="item-deep-equal.3">
    <test:title>String and Integer</test:title>
    <test:param name="item1" select="'1'" />
    <test:param name="item2" select="1" />
    <test:expect select="false()" />
  </test:test>
</test:tests>
<xsl:function name="test:item-deep-equal" as="xs:boolean">
  <xsl:param name="item1" as="item()" />
  <xsl:param name="item2" as="item()" />
  <xsl:choose>
    <xsl:when test="$item1 instance of node() and
                    $item2 instance of node()">
      <xsl:sequence select="test:node-deep-equal($item1, $item2)" />
    </xsl:when>
    <xsl:when test="not($item1 instance of node()) and
                    not($item2 instance of node())">
      <xsl:sequence select="deep-equal($item1, $item2)" />      
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="false()" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<test:tests>
  <test:title>test:node-deep-equal function</test:title>
  <test:test id="node-deep-equal.1">
    <test:title>Identical Elements</test:title>
    <test:param name="node1" select="/*">
      <result/>
    </test:param>
    <test:param name="node2" select="/*">
      <result/>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.2">
    <test:title>Elements with Identical Attributes in Different Orders</test:title>
    <test:param name="node1" select="/*">
      <result a="1" b="2" />
    </test:param>
    <test:param name="node2" select="/*">
      <result b="2" a="1" />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.3">
    <test:title>Elements with Identical Children</test:title>
    <test:param name="node1" select="/*">
      <result><child1/><child2/></result>
    </test:param>
    <test:param name="node2" select="/*">
      <result><child1/><child2/></result>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.4">
    <test:title>Identical Attributes</test:title>
    <test:param name="node1" select="/*/@a">
      <result a="1" />
    </test:param>
    <test:param name="node2" select="/*/@a">
      <result a="1" />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.5">
    <test:title>Identical Document Nodes</test:title>
    <test:param name="node1" select="/">
      <result />
    </test:param>
    <test:param name="node2" select="/">
      <result />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.6">
    <test:title>Identical Text Nodes</test:title>
    <test:param name="node1" select="/*/text()">
      <result>Test</result>
    </test:param>
    <test:param name="node2" select="/*/text()">
      <result>Test</result>
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.7">
    <test:title>Identical Comments</test:title>
    <test:param name="node1" select="/comment()">
      <!-- Comment -->
      <doc />
    </test:param>
    <test:param name="node2" select="/comment()">
      <!-- Comment -->
      <doc />
    </test:param>
    <test:expect select="true()" />
  </test:test>
  <test:test id="node-deep-equal.8">
    <test:title>Identical Processing Instructions</test:title>
    <test:param name="node1" select="/processing-instruction()">
      <?pi data?>
      <doc />
    </test:param>
    <test:param name="node2" select="/processing-instruction()">
      <?pi data?>
      <doc />
    </test:param>
    <test:expect select="true()" />
  </test:test>
</test:tests>
<xsl:function name="test:node-deep-equal" as="xs:boolean">
  <xsl:param name="node1" as="node()" />
  <xsl:param name="node2" as="node()" />
  <xsl:choose>
    <xsl:when test="$node1 instance of document-node() and
                    $node2 instance of document-node()">
      <xsl:sequence select="test:deep-equal($node1/child::node(),
                                            $node2/child::node())" />
    </xsl:when>
    <xsl:when test="$node1 instance of element() and
                    $node2 instance of element()">
      <xsl:choose>
        <xsl:when test="node-name($node1) eq node-name($node2)">
          <xsl:variable name="atts1" as="attribute()*">
            <xsl:perform-sort select="$node1/@*">
              <xsl:sort select="namespace-uri(.)" />
              <xsl:sort select="local-name(.)" />
            </xsl:perform-sort>
          </xsl:variable>
          <xsl:variable name="atts2" as="attribute()*">
            <xsl:perform-sort select="$node2/@*">
              <xsl:sort select="namespace-uri(.)" />
              <xsl:sort select="local-name(.)" />
            </xsl:perform-sort>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="test:deep-equal($atts1, $atts2)">
              <xsl:variable name="children1" as="node()*" 
                select="test:sorted-children($node1)" />
              <xsl:variable name="children2" as="node()*" 
                select="test:sorted-children($node2)" />
              <xsl:sequence select="test:deep-equal($children1,
                                                    $children2)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="false()" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$node1 instance of text() and
                    $node2 instance of text()">
      <!--
      <xsl:choose>
        <xsl:when test="not(normalize-space($node1)) and 
                        not(normalize-space($node2))">
          <xsl:sequence select="true()" />
        </xsl:when>
        <xsl:otherwise>
        -->
          <xsl:sequence select="string($node1) eq string($node2)" />
        <!--
        </xsl:otherwise>
      </xsl:choose>
      -->
    </xsl:when>
    <xsl:when test="($node1 instance of attribute() and
                     $node2 instance of attribute()) or
                    ($node1 instance of processing-instruction() and
                     $node2 instance of processing-instruction())">
      <xsl:sequence select="node-name($node1) eq node-name($node2) and
                            string($node1) eq string($node2)" />      
    </xsl:when>
    <xsl:when test="$node1 instance of comment() and
                    $node2 instance of comment()">
      <xsl:sequence select="string($node1) eq string($node2)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="false()" />
    </xsl:otherwise>
  </xsl:choose>  
</xsl:function>
  
<test:tests>
  <test:title>test:sorted-children function</test:title>
  <test:test>
    <test:title>Original order preserved</test:title>
    <test:param name="element">
      <foo><bar /><baz /></foo>
    </test:param>
    <test:expect>
      <bar /><baz />
    </test:expect>
  </test:test>
</test:tests>  
<xsl:function name="test:sorted-children" as="node()*">
  <xsl:param name="element" as="element()" />
  <xsl:sequence select="$element/child::node() except $element/text()[not(normalize-space(.))]" />
</xsl:function>
  
<test:tests>
  <test:title>test:report-value function</test:title>
  <test:test id="report-value.1">
    <test:title>Integer</test:title>
    <test:param name="value" select="1" />
    <test:expect select="/test:result">
      <test:result select="1" />
    </test:expect>
  </test:test>
  <test:test id="report-value.2">
    <test:title>Empty Sequence</test:title>
    <test:param name="value" select="()" />
    <test:expect select="/test:result">
      <test:result select="()" />
    </test:expect>
  </test:test>
  <test:test id="report-value.3">
    <test:title>String</test:title>
    <test:param name="value" select="'test'" />
    <test:expect select="/test:result">
      <test:result select="'test'" />
    </test:expect>
  </test:test>
  <test:test id="report-value.4">
    <test:title>URI</test:title>
    <test:param name="value" select="xs:anyURI('test.xml')" />
    <test:expect select="/test:result">
      <test:result select="xs:anyURI('test.xml')" />
    </test:expect>
  </test:test>
  <test:test>
    <test:title>QName</test:title>
    <test:param name="value"
      select="QName('http://www.jenitennison.com/xslt/unit-test', 'tests')" />
    <test:expect select="/test:result">
      <test:result select="QName('http://www.jenitennison.com/xslt/unit-test', 'tests')" />
    </test:expect>
  </test:test>
  <test:test>
    <test:title>Attributes</test:title>
    <test:param name="value" select="/*/@*">
      <doc a="1" b="2" />
    </test:param>
    <test:expect select="/test:result">
      <test:result select="/*/(@* | node())">
        <test:temp a="1" b="2" />
      </test:result>
    </test:expect>
  </test:test>
  <test:test>
    <test:title>Attributes and content</test:title>
    <test:param name="value" select="/*/@*, /*/foo">
      <doc a="1" b="2">
        <foo />
      </doc>
    </test:param>
    <test:expect select="/test:result">
      <test:result select="/*/(@* | node())">
        <test:temp a="1" b="2">
          <foo />
        </test:temp>
      </test:result>
    </test:expect>
  </test:test>
</test:tests>
<xsl:template name="test:report-value">
  <xsl:param name="value" required="yes" />
  <t:result>
    <xsl:choose>
      <xsl:when test="$value[1] instance of attribute()">
        <xsl:attribute name="select">/*/(@* | node())</xsl:attribute>
        <t:temp>
          <xsl:copy-of select="$value" />
        </t:temp>
      </xsl:when>
      <xsl:when test="$value instance of node()+">
        <xsl:choose>
          <xsl:when test="$value instance of document-node()">
            <xsl:attribute name="select">/</xsl:attribute>
          </xsl:when>
          <xsl:when test="not($value instance of element()+)">
            <xsl:attribute name="select">/node()</xsl:attribute>
          </xsl:when>
        </xsl:choose>
        <xsl:copy-of select="$value" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="select">
          <xsl:choose>
<!--			<xsl:when test="$value instance of empty-sequence()">()</xsl:when>  -->
			<xsl:when test="empty($value)">()</xsl:when>
            <xsl:when test="$value instance of item()">
              <xsl:value-of select="test:report-atomic-value($value)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>(</xsl:text>
              <xsl:for-each select="$value">
                <xsl:value-of select="test:report-atomic-value(.)" />
                <xsl:if test="position() != last()">, </xsl:if>
              </xsl:for-each>
              <xsl:text>)</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>        
      </xsl:otherwise>
    </xsl:choose>
  </t:result>
</xsl:template>
    
<test:tests>
  <test:title>test:report-atomic-value function</test:title>
  <test:test id="report-atomic-value.1">
    <test:title>String Containing Single Quotes</test:title>
    <test:param name="value" select="'don''t'" />
    <test:expect select="'''don''''t'''" />
  </test:test>
</test:tests>
<xsl:function name="test:report-atomic-value" as="xs:string">
  <xsl:param name="value" as="item()" />
  <xsl:choose>
    <xsl:when test="$value instance of xs:string">
      <xsl:value-of select="concat('''',
                                   replace($value, '''', ''''''),
                                   '''')" />
    </xsl:when>
    <xsl:when test="$value instance of xs:integer or
                    $value instance of xs:decimal or
                    $value instance of xs:double">
      <xsl:value-of select="$value" />
    </xsl:when>
    <xsl:when test="$value instance of xs:QName">
      <xsl:value-of 
        select="concat('QName(''', namespace-uri-from-QName($value), 
                              ''', ''', if (prefix-from-QName($value)) 
                                        then concat(prefix-from-QName($value), ':') 
                                        else '',
                              local-name-from-QName($value), ''')')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="type" select="test:atom-type($value)" />
      <xsl:value-of select="concat($type, '(',
                                   test:report-atomic-value(string($value)), ')')" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>  
  
<xsl:function name="test:atom-type" as="xs:string">
  <xsl:param name="value" as="xs:anyAtomicType" />
  <xsl:choose>
    <xsl:when test="$value instance of xs:string">xs:string</xsl:when>
    <xsl:when test="$value instance of xs:boolean">xs:boolean</xsl:when>
    <xsl:when test="$value instance of xs:double">xs:double</xsl:when>
    <xsl:when test="$value instance of xs:anyURI">xs:anyURI</xsl:when>
    <xsl:when test="$value instance of xs:dateTime">xs:dateTime</xsl:when>
    <xsl:when test="$value instance of xs:date">xs:date</xsl:when>
    <xsl:when test="$value instance of xs:time">xs:time</xsl:when>
    <xsl:otherwise>xs:anyAtomicType</xsl:otherwise>
  </xsl:choose>  
</xsl:function>
  
</xsl:stylesheet>
