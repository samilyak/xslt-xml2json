<?xml version="1.0" encoding="utf-8" ?>
<!--
	@author Alexander Samilyak (aleksam241@gmail.com)
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

  <xsl:variable name="xml2str:empty_tags">
		<area/> <base/> <basefont/> <br/> <col/> <frame/> <hr/> <img/> <input/> <isindex/> <link/> <meta/> <param/>
	</xsl:variable>
	<xsl:variable name="xml2str:empty_tags_set" select="exsl:node-set($xml2str:empty_tags)/*" />

	<!--
		Превращает контент отданного узла (включая все элементы) в строку
	  -->
	<xsl:template match="*" mode="xml2str:convert">
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name()" />
		<xsl:apply-templates select="." mode="xml2str:convert_attrs" />

		<xsl:choose>
			<!--
				Если имя тэга находится в списке html-тэгов, которые должны быть самозакрыты,
				и если внутри тэга пусто, то выводим самозакрытый тэг
			  -->
			<xsl:when test="$xml2str:empty_tags_set[name() = name(current())] and not(node())">
				<xsl:text>/&gt;</xsl:text>
			</xsl:when>
			<!--
				Иначе выводим и открывающий, и закрывающий тэг
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


	<xsl:template name="xml2str:escape">
		<xsl:param name="str" select="''" />

		<!--
			Представим, что нужно вывести строку "Procter&Gamble" в html-абзаце p.
			Для этого в исходном xml'е надо написать
			<p>Procter&amp;Gamble</p>
			А сюда в xsl это приходит как
			<p>Procter&Gamble</p>.
			В таком виде это нельзя выводить, потому что это невалидный xml (& должен быть написан как &amp;).
			Чтобы сохранить валидность, экранируем служебные символы
			&    ==>   &amp;
			<    ==>   &lt;
			]]>  ==>   ]]&gt;
		  -->
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

	<xsl:template name="xml2str:escape_attr">
		<xsl:param name="str" select="''" />

		<!--
			В значениях атрибутов, кроме обычного html-экранирования,
			нужно ещё заэкранировать двойную и одинарную кавычки
		  -->
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