<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet SYSTEM "entities.dtd">

<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common"
	xmlns:als="http://design.ru/"
	extension-element-prefixes="exsl"
	exclude-result-prefixes="als"
>

	<xsl:import href="../src/xml2json.xsl" />
	<!--<xsl:import href="../lib/xmltojsonv1.xsl" />-->

	<xsl:output
		omit-xml-declaration="yes"
		indent="no"
		method="html"
	/>


	<xsl:template match="/">

		<xsl:variable name="tmp">
			<glaz1>null</glaz1>
			<glaz>123</glaz>
		</xsl:variable>
		
		<xsl:variable name="tree">
			<!--<temp_tree>-->
				<!--<doc>-->
					<f size="15 КБ" src="/f/1/o&lt;rder/invoice.css">
						<mm elem="super1">.45</mm>
						<ttt>ес&#xD;ом\</ttt>
					</f>
					<__g235 />pizdec
					<file1 size="2 КБ" src="/f/1/order/order.css">g&lt;"o2&amp;</file1>
					<file size="192 B" src="/f/1/cart/css_src/bill.css" json-type="string1">
						<item>1</item>
						<item>FalSe Байт</item>
						<item> </item>
						<!--<input> &nbsp;</input>-->
						<input value="mmm123"/>
						<item fuck="t'he&lt; war" />
						<als:item>
							<xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes" />
							    <xsl:copy-of select="$tmp" />
							<xsl:value-of select="']]&gt;'" disable-output-escaping="yes" />
						</als:item>
					</file>
					dj&lt;opa
					<file2 megaattr="us&lt;a" super="187">
						<item>-0.35</item>
						<!--&lt;piz&apos;dec&amp;]]&gt;"-->
						<item djopa="123" main="dfas">tr"ue</item>
						<item>300</item>
						<item mmm="15" main="fdj&apos;slafs&quot;"> </item>
						<!--<p />-->
						<item>&#160;</item>
						<item>&#8212;</item>
						<item>
							<dd>123</dd>
						</item>
					</file2>
				<!--</doc>-->
			<!--</temp_tree>-->
		</xsl:variable>

		<!--<xsl:copy-of select="$tree" />-->

		<xsl:call-template name="xml2json">
			<!--<xsl:with-param name="data" select="exsl:node-set($tree)/temp_tree/node()" />-->
			<!--<xsl:with-param name="data">-->
				<!--<xsl:for-each select="exsl:node-set($tree2)//gallery/photo">-->
					<!--<photo>-->
						<!--<xsl:value-of select="full/@src" />-->
					<!--</photo>-->
				<!--</xsl:for-each>-->
			<!--</xsl:with-param>-->
			<!--<xsl:with-param name="skip_root" select="true()" />-->

			<!--<xsl:with-param name="data" select="doc/f | doc/file | doc/text()" />-->
			<!--<xsl:with-param name="data" select="/descendant::file1[1] | /descendant::file[1]" />-->
			<!--<xsl:with-param name="data" select="/descendant::file" />-->
			<!--<xsl:with-param name="data" select="/doc" />-->
			<xsl:with-param name="data" select="/" />
			<!--<xsl:with-param name="data" select="'null'" />-->
			<!--<xsl:with-param name="data" select="true()" />-->
			<!--<xsl:with-param name="data" select="148" />-->
			<!--<xsl:with-param name="data" select="'str'" />-->
			<!--<xsl:with-param name="data" select="/descendant::text()[position() &lt; 4]" />-->

			<!--<xsl:with-param name="string_elems" select="'/doc/f | //item[glaz]'" />-->
			<!--<xsl:with-param name="skip_root" select="true()" />-->
		</xsl:call-template>


		<!--<xsl:call-template name="test_attr" />-->

		<!--<xsl:apply-templates select="/" mode="keith" />-->
		

		<!--<xsl:call-template name="xml2json" />-->


		

	</xsl:template>



	<xsl:template name="test_attr">
		<div>
			<xsl:call-template name="xml2json_attr">
				<xsl:with-param name="data">
					<article>
						<content>Lorem ipsum</content>
					</article>
				</xsl:with-param>
				<!--<xsl:with-param name="string_elems" select="'/article'" />-->
				<!--<xsl:with-param name="skip_root" select="true()" />-->
				<!--<xsl:with-param name="attr" select="'onfocus'" />-->
			</xsl:call-template>
		</div>
	</xsl:template>


</xsl:stylesheet>