<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview XSLT 1.0 based XML to JSON converter.
      Tested with these XSLT processors:
        libxslt 1.1
        Xalan-Java 2.7.1
        Saxon-Java 9.1.0.8
  @author Alexander Samilyak (aleksam241@gmail.com)
  @version 0.1
  @link https://github.com/samilyak/xslt-xml2json

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
    @description Превращет xml в json
    @param {Nodeset|RTF} [data = .]  Набор узлов, подлежащих превращению в json
    @param {Nodeset|String} [string_elems = ''] Узлы,
        содержимое которых должно быть превращено в json-строку,
        даже если внутри есть узлы-элементы.
        Можно передавать как набор узлов, так и XPath-строку для их вычисления
        (контекстом исполнения XPath-строки будет дерево,
        в котором находится первый узел параметра $data)

        Этот параметр удобно использовать,
        когда в json'е нужно передать html-разметку как строку.
        Например:
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

        ====>

        {
          article : {
            content : "<p><strong>Lorem ipsum</strong> dolor sit amet</p>"
          }
        }

    @param {Boolean} [skip_root = false()] Убрать ли корень результирующего
        json-объекта и отдать лишь содержимое его ключа.
        Параметр имеет смысл, если в первом параметре $data
        на обработку отдан один xml-узел
        (на выходе получаем json-объект с одним ключом)
        или набор xml-узлов с одним и тем же именем
        (на выходе получаем json-массив).

        <xsl:call-template name="xml2json">
          <xsl:with-param name="data">
            <article>
              <content>Lorem ipsum dolor sit amet</content>
            </article>
          </xsl:with-param>
          <xsl:with-param name="skip_root" select="true()" />
        </xsl:call-template>

        ====>

        { content: "Lorem ipsum dolor sit amet" }

        (обёрточного ключа article нет)
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
    @description Превращет xml в json и отдаёт html-атрибут onclick,
        который возвращает этот json.

        <xsl:call-template name="xml2json_attr">
          <xsl:with-param name="data">
            <article>
              <content>Lorem ipsum</content>
            </article>
          </xsl:with-param>
        </xsl:call-template>

        ====>

        onclick='return {"article":{"content":"Lorem ipsum"}}'

    @param {Nodeset|RTF} [data = .]  Набор узлов, подлежащих превращению в json
    @param {Nodeset|String} [string_elems = '']  Узлы, содержимое которых
        должно быть превращено в json-строку,
        даже если внутри есть узлы-элементы
    @param {Boolean} [skip_root = false()]  Убрать ли корень результирующего
        json-объекта и отдать лишь содержимое его ключа
    @param {String} [attr = "onclick"] Имя html-атрибута,
        в который нужно положить получившийся json
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
      <xsl:attribute name="{$attr}">
        <xsl:text>return </xsl:text>
        <xsl:value-of select="$json" disable-output-escaping="yes" />
      </xsl:attribute>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>