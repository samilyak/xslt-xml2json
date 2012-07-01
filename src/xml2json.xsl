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
    @description Превращет xml в json и отдаёт html-атрибут, содержащий этот
    json.

    Пример 1 (атрибут onclick):

    <xsl:call-template name="xml2json_attr">
      <xsl:with-param name="data">
        <article>
          <content>Lorem ipsum</content>
        </article>
      </xsl:with-param>
    </xsl:call-template>

    =>

    onclick='return {"article":{"content":"Lorem ipsum"}}'

    ========================================================

    Пример 2 (атрибут начинается с data-):

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

    =>

    data-data="&lt;elem width=&quot;640&quot; src=&quot;http://www.google.com/&quot;/&gt;"


    @param {Nodeset|RTF} [data = .]  Набор узлов, подлежащих превращению в json

    @param {Nodeset|String} [string_elems = '']  Узлы, содержимое которых
    должно быть превращено в json-строку, даже если внутри есть узлы-элементы.

    @param {Boolean} [skip_root = false()]  Убрать ли корень результирующего
    json-объекта и отдать лишь содержимое его ключа.

    @param {String} [attr = "onclick"] Имя html-атрибута, в который нужно
    положить получившийся json. Если имя начинается с 'data-', то в значении
    атрибута не будет 'return ' в начале, а будет только сам json.
    При этом если json является строкой, то эта строка не будет заключена
    в кавычки и не будет иметь json-экранирования (см. пример 2 выше).
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