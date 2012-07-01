<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview Builds all json data types
  @author Alexander Samilyak (aleksam241@gmail.com)

  This source code follows Formatting section of Google C++ Style Guide
  http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Formatting
  -->

<!DOCTYPE xsl:stylesheet[
  <!ENTITY % const SYSTEM "constants.dtd">
  %const;
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"

  xmlns:dyn="http://exslt.org/dynamic"
  xmlns:sets="http://exslt.org/sets"
  xmlns:saxon="http://saxon.sf.net/"

  xmlns:core="http://localhost/xsl/xml2json/core"
  xmlns:xml2str="http://localhost/xsl/xml2json/xml2string"
  xmlns:utils="http://localhost/xsl/xml2json/utils"

  extension-element-prefixes="exsl dyn sets saxon"
  exclude-result-prefixes="core xml2str utils"
>

  <xsl:import href="xml2str.xsl" />
  <xsl:import href="utils.xsl" />


  <xsl:template name="core:convert">
    <xsl:param name="data" />
    <xsl:param name="string_elems" />
    <xsl:param name="skip_root" />

    <xsl:choose>
      <!--
        Если на обработку отдан фрагмент результирующего дерева,
        то превращаем его в полноценное временное дерево
        и работаем с дочерними узлами созданного временного дерева
        -->
      <xsl:when test="exsl:object-type($data) = 'RTF'">
        <xsl:call-template name="core:process_string_elems">
          <xsl:with-param name="dataset" select="exsl:node-set($data)/node()" />
          <xsl:with-param name="skip_root" select="$skip_root" />
          <xsl:with-param name="string_elems" select="$string_elems" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="exsl:object-type($data) = 'node-set'">
        <xsl:choose>
          <!--
            Если на обработку отдан корень дерева (входящего или временного),
            то работаем с дочерними узлами.
            Проверка name($data) = name(/) нужна потому, что
            / = /root_element выдаёт true, но нас это не устраивает
            -->
          <xsl:when test="$data[($data = /) and (name($data) = name(/))]">
            <xsl:call-template name="core:process_string_elems">
              <xsl:with-param name="dataset" select="$data/node()" />
              <xsl:with-param name="skip_root" select="$skip_root" />
              <xsl:with-param name="string_elems" select="$string_elems" />
            </xsl:call-template>
          </xsl:when>
          <!--
            Иначе нам отдали набор узлов - работаем с этим набором
            -->
          <xsl:otherwise>
            <xsl:call-template name="core:process_string_elems">
              <xsl:with-param name="dataset" select="$data" />
              <xsl:with-param name="skip_root" select="$skip_root" />
              <xsl:with-param name="string_elems" select="$string_elems" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!--
        Нам отдали примитивный тип - выводим примитивным json-значением
        -->
      <xsl:otherwise>
        <xsl:call-template name="core:make_simple_value">
          <xsl:with-param name="string_data" select="$data" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  
  <xsl:template name="core:process_string_elems">
    <xsl:param name="dataset" />
    <xsl:param name="string_elems" />
    <xsl:param name="skip_root" />

    <xsl:choose>
      <!--
        Если строковые узлы отданы в виде набора узлов,
        то используем этот набор
        -->
      <xsl:when test="exsl:object-type($string_elems) = 'node-set'">
        <xsl:call-template name="core:process_dataset">
          <xsl:with-param name="dataset" select="$dataset" />
          <xsl:with-param name="skip_root" select="$skip_root" />
          <xsl:with-param name="string_nodes" select="$string_elems" />
        </xsl:call-template>
      </xsl:when>
      <!--
        Иначе считаем, что нам отдана XPath-строка,
        в который перечислены строковые узлы.
        Нужно исполнить этот XPath и получить необходимые узлы.
        -->
      <xsl:otherwise>
        <xsl:for-each select="$dataset[1]">
          <xsl:variable name="root" select="/" />

          <!--
            Переходим в контекст корня дерева $dataset,
            чтобы функция evaluate исполнилась именно в этом контексте,
            (так как этот контекст может быть как входящим деревом,
            так и временным).
            Далее мы будем обходить дерево $dataset и смотреть,
            не попалось ли нам узлов, возвращённых функцией evaluate.
            -->
          <xsl:for-each select="$root">
            <xsl:choose>
              <xsl:when test="
                normalize-space($string_elems) and
                function-available('saxon:evaluate')
              ">
                <!-- Saxon -->
                <xsl:call-template name="core:process_dataset">
                  <xsl:with-param name="dataset" select="$dataset" />
                  <xsl:with-param name="skip_root" select="$skip_root" />
                  <xsl:with-param
                    name="string_nodes" select="saxon:evaluate($string_elems)"
                  />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="
                normalize-space($string_elems) and
                function-available('dyn:evaluate')
              ">
                <!-- Libxslt и Xalan -->
                <xsl:call-template name="core:process_dataset">
                  <xsl:with-param name="dataset" select="$dataset" />
                  <xsl:with-param name="skip_root" select="$skip_root" />
                  <xsl:with-param
                    name="string_nodes" select="dyn:evaluate($string_elems)"
                  />
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <!-- Другой трансформатор - работаем без строковых узлов -->
                <xsl:call-template name="core:process_dataset">
                  <xsl:with-param name="dataset" select="$dataset" />
                  <xsl:with-param name="skip_root" select="$skip_root" />
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  


  <xsl:template name="core:process_dataset">
    <xsl:param name="dataset" />
    <xsl:param name="string_nodes" />
    <xsl:param name="skip_root" />

    <!--
      Выкидываем комментарии и текстовые узлы, состоящие только из пробелов
      -->
    <xsl:variable
      name="clean_dataset"
      select="$dataset[
        not(self::comment()) and
        not(self::text()[not(normalize-space())])
      ]"
    />

    <xsl:choose>
      <xsl:when test="count($clean_dataset) > 1">
        <!--
          Нам отдали набор узлов - надо определить, какой состав этого набора
          -->
        <xsl:variable
          name="is_elements_only" select="not($clean_dataset[not(self::*)])"
        />
        <xsl:variable name="is_all_names_equals">
          <xsl:call-template name="utils:is_all_names_equals">
            <xsl:with-param name="set" select="$clean_dataset" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <!--
            Если есть только элементы (не атрибуты и не текстовые узлы)
            и все с одинаковыми именами, то делаем массив однородных данных
            -->
          <xsl:when test="$is_elements_only and $is_all_names_equals = 'true'">
            <xsl:call-template name="core:make_array_identical">
              <xsl:with-param name="set" select="$clean_dataset" />
              <xsl:with-param name="string_nodes" select="$string_nodes" />
              <xsl:with-param name="skip_root" select="$skip_root" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="is_all_names_different">
              <xsl:call-template name="utils:is_all_names_different">
                <xsl:with-param name="set" select="$clean_dataset" />
              </xsl:call-template>
            </xsl:variable>

            <xsl:choose>
              <!--
                Если только элементы и все с разными именами,
                то делаем объект
                -->
              <xsl:when
                test="$is_elements_only and $is_all_names_different = 'true'
              ">
                <xsl:call-template name="core:make_object">
                  <xsl:with-param name="set" select="$clean_dataset" />
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:call-template>
              </xsl:when>
              <!-- Иначе делаем массив смешанных данных -->
              <xsl:otherwise>
                <xsl:call-template name="core:make_array_mixed">
                  <xsl:with-param name="set" select="$clean_dataset" />
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- Нам отдали один узел - обрабатываем этот узел -->
      <xsl:otherwise>
        <xsl:choose>
          <!--
            Если сказано не выводить корень объекта,
            то обрабатываем контент узла $dataset
            -->
          <xsl:when test="$skip_root">
            <xsl:apply-templates
              select="$clean_dataset" mode="core:process_node"
            >
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:apply-templates>
          </xsl:when>

          <!--
            Иначе выводим объект, в корне которого один ключ,
            значением которого является контент узла $dataset
            { <имя узла $dataset> : <контент узла $dataset> }
            -->
          <xsl:otherwise>
            <xsl:call-template name="core:make_object">
              <xsl:with-param name="set" select="$clean_dataset" />
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="* | @*" mode="core:process_node">
    <xsl:param name="string_nodes" />

    <xsl:choose>
      <!--
        Атрибут, отвечающий за тип json-данных (json-type),
        считаем служебным и его выводить не надо.
        -->
      <xsl:when test="name() = '&CONFIG_ATTR_NAME;'"/>
      <!--
        Если у текущего узла есть атрибут json-type, значение которого "string",
        или узел является одним из тех, что отдали в параметре $string_nodes,
        то выводим его контент строкой, даже если в нём есть вложенная разметка
        -->
      <xsl:when test="
        @*[name() = '&CONFIG_ATTR_NAME;'] = 'string' or
        ($string_nodes and sets:has-same-node(current(), $string_nodes))
      ">
        <xsl:apply-templates select="." mode="core:object_with_string_content"/>
      </xsl:when>
      <xsl:when test="* or @*">
        <xsl:variable name="is_all_names_equals">
          <xsl:call-template name="utils:is_all_names_equals">
            <xsl:with-param name="set" select="*" />
          </xsl:call-template>
        </xsl:variable>


        <xsl:choose>
          <!--
            Если непробельных текстовых узлов нет,
            а есть несколько узлов-элементов и все имеют одно и то же имя,
            то выводим массив однородных данных вида
            {
              "item" : [
                true,
                { "key": "value" },
                "megastring"
              ]
            }
            где item - имя каждого элемента
            -->
          <xsl:when test="
            not(text()[normalize-space()]) and $is_all_names_equals = 'true' and
            (count(*) > 1 or @*[name() = '&CONFIG_ATTR_NAME;'] = 'array')
          ">
            <xsl:choose>
              <xsl:when test="@*[name() = '&CONFIG_ATTR_NAME;'] = 'array'">
                <xsl:apply-templates select="." mode="core:array_identical">
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                  <xsl:with-param name="skip_root" select="true()" />
                </xsl:apply-templates>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="." mode="core:array_identical">
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="is_all_names_different">
              <xsl:call-template name="utils:is_all_names_different">
                <xsl:with-param name="set" select="*" />
              </xsl:call-template>
            </xsl:variable>

            <xsl:choose>
              <!--
                Если узлы-элементы не перемешаны с текстовыми узлами
                (есть только элементы или только текстовые),
                и все элементы имеют разные имена
                (то есть мы можем обеспечить уникальность ключей json-объекта),
                то выводим json-объект
                -->
              <xsl:when test="
                not(* and text()[normalize-space()]) and
                $is_all_names_different = 'true'
              ">
                <xsl:apply-templates select="." mode="core:object">
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:apply-templates>
              </xsl:when>
              <!--
                Если же есть вперемешку узлы-элементы и текстовые узлы,
                или есть элементы с одинаковыми именами,
                то выводим массив смешанных данных вида
                [
                  { "key": -0.35 },
                  "text node",
                  { "item": "hasta-la-vista" },
                  { "item": "hasta-la-vista-again" }
                ]
                -->
              <xsl:otherwise>
                <xsl:apply-templates select="." mode="core:array_mixed">
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!--
        Если нет атрибутов и дочерних узлов-элементов
        (что всегда истинно, если контекстный узел -
        атрибут или текстовый узел), то выводим примитивное значение
        -->
      <xsl:otherwise>
        <xsl:call-template name="core:make_simple_value">
          <xsl:with-param name="string_data" select="." />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()" mode="core:process_node">
    <!--
      Текстовый узел выводим, если у него нет братьев-элементов
      (то есть он не разделяет элементы),
      или если братья-элементы есть, но тектовый узел содержит не только пробелы
      Нужно это, чтобы не обрабатывать пробелы между элементами.
      -->
    <xsl:if test="not(../*) or normalize-space(.)">
      <xsl:call-template name="core:make_simple_value">
        <xsl:with-param name="string_data" select="." />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>



  
  <!--
    Выводит массив однородных данных.                                                                                                  1
    Применяется для узла, все дети которого имеют одинаковое имя.
    Пример:

    <characters main="true">
      <item>Mark Greene</item>
      <item sexy="false">Doug Ross</item>
      <item>Susan Lewis</item>
      <item student="true">
        <first_name>John</first_name>
        <last_name>Carter</last_name>
      </item>
    </characters>

    ====>

    {
      "$main" : true,
      "item" : [
      "Mark Greene",
      { "$sexy": false, "$": "Doug Ross" },
      "Susan Lewis",
      { "$student": true, "first_name": "John", "last_name": "Carter" }
      ]
    }
    -->
  <xsl:template match="*" mode="core:array_identical">
    <xsl:param name="string_nodes" />
    <xsl:param name="skip_root" select="false()" />

    <xsl:call-template name="core:make_array_identical">
      <xsl:with-param name="set" select="*" />
      <xsl:with-param
        name="extraset" select="@*[name() != '&CONFIG_ATTR_NAME;']"
      />
      <xsl:with-param name="string_nodes" select="$string_nodes" />
      <xsl:with-param name="skip_root" select="$skip_root" />
    </xsl:call-template>
  </xsl:template>


  <!--
    Выводит массив смешанных данных.
    Применяется для узла, детьми которого являются как узлы-элементы,
    так и текстовые узлы,
    а также в случае если есть узлы, как с разными, так и с одинаковыми именами.
    Пример:

    <cast season="1" episode="4">
      <chief>Anthony Edwards</chief>
      <chief>William Macy</chief>
      George Clooney
      <stupid name="Sherry">
        <sirname>Stringfield</sirname>
      </stupid>
      <student>Noah Wyle</student>
    </cast>

    ====>

    [
      { "$season": 1, "$episode": 4 },
      { "chief": "Anthony Edwards" },
      { "chief": "William Macy" },
      "George Clooney",
      { "stupid": { "$name": "Sherry", "sirname": "Stringfield" } },
      { "student": "Noah Wyle" }
    ]  
    -->
  <xsl:template match="*" mode="core:array_mixed">
    <xsl:param name="string_nodes" />

    <xsl:call-template name="core:make_array_mixed">
      <xsl:with-param name="set" select="node()[not(self::comment())]" />
      <xsl:with-param name="raw_string_data">
        <xsl:call-template name="core:make_object">
          <xsl:with-param name="set" select="@*" />
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="string_nodes" select="$string_nodes" />
    </xsl:call-template>
  </xsl:template>


  <!--
    Выводит объект произвольной структуры.
    Применяется для узла,
    все дети которого являются узлами-элементами и имеют разные имена.

    <episodes>
      <one>24 Hours</one>
      <two>
        <first night="false">Day</first>
        <second>One</second>
      </two>
      <three name="Going Home" />
    </episodes>

    ====>

    {
      "one": "24 Hours",
      "two": { "first": { "$night": false, "$": "Day" }, "second": "One" },
      "three": { "$name": "Going Home" }
    }
    -->
  <xsl:template match="* | @*" mode="core:object">
    <xsl:param name="string_nodes" />
    <xsl:param name="is_make_root" select="false()" />

    <xsl:variable
      name="is_empty" select="not(*) and not(@*) and not(normalize-space(.))"
    />

    <xsl:choose>
      <xsl:when test="$is_empty and not($is_make_root)">
        <!--
          Если узел пустой и не сказано всегда выводить объект,
          то выводим null
          -->
        <xsl:call-template name="core:make_simple_value">
          <xsl:with-param name="string_data" select="'null'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <!--
            Если нет дочерних узлов и атрибутов,
            или параметром сказано выводить корень объекта,
            то отправляем на обработку сам пришедший узел
            -->
          <xsl:when test="(not(*) and not(@*)) or $is_make_root">
            <xsl:call-template name="core:make_object">
              <xsl:with-param name="set" select="." />
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:call-template>
          </xsl:when>
          <!--
            Иначе обрабатываем не сам пришедший узел, а его контент
            -->
          <xsl:otherwise>
            <xsl:call-template name="core:make_object">
              <xsl:with-param name="set" select="* | @* | text()" />
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Текстовые узлы выводятся примитивным значением
    -->
  <xsl:template match="text()" mode="core:object">
    <xsl:param name="string_nodes" />

    <xsl:apply-templates select="." mode="core:process_node">
      <xsl:with-param name="string_nodes" select="$string_nodes" />
    </xsl:apply-templates>
  </xsl:template>



  <!--
    Отправляет контент пришедшего узла на вывод в виде строки.
    Это нужно, если мы хотим отдать html-разметку в json-строке,
    несмотря на то что в ней есть вложенные элементы,
    которые по умолчанию вывелись бы дочерними json-объектами.

    Например, такой xml
    <description>
      <p><strong>ER</strong> is an American medical drama television series</p>
    </description>

    этот шаблон сконвертит в
    "<p><strong>ER</strong> is an American medical drama television series</p>"

    тогда как обычное превращение в json должно сделать следующее
    {"p": [{"strong": "ER"}, " is an American medical drama television series"]}
    -->
  <xsl:template match="*" mode="core:object_with_string_content">
    <xsl:variable name="content_as_html">
      <xsl:apply-templates select="node()" mode="xml2str:convert" />
    </xsl:variable>
    <xsl:variable name="content_as_string">
      <xsl:call-template name="core:string">
        <xsl:with-param name="str" select="normalize-space($content_as_html)" />
      </xsl:call-template>
    </xsl:variable>


    <xsl:variable
      name="data_attrs" select="@*[name() != '&CONFIG_ATTR_NAME;']"
    />
    <xsl:choose>
      <xsl:when test="$data_attrs">
        <xsl:call-template name="core:make_object">
          <xsl:with-param name="set" select="$data_attrs" />
          <xsl:with-param name="raw_string_data">
            <xsl:text>"&TEXT_NODE_KEY;":</xsl:text>
            <xsl:value-of
              select="$content_as_string" disable-output-escaping="yes"
            />
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="$content_as_string" disable-output-escaping="yes"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Выводит json-объект,
    последовательно перебирая узлы, пришедшие в параметре $set,
    и создавая для каждого из них новый ключ
    {
      "one": "24 Hours",
      "two": { "title": "Day One" },
      "three": { "$name": "Going Home" }
    }
    -->
  <xsl:template name="core:make_object">
    <xsl:param name="set" />
    <xsl:param name="raw_string_data" select="''" />
    <xsl:param name="string_nodes" />

    <xsl:if test="$set or normalize-space($raw_string_data)">
      <xsl:text>{</xsl:text>

      <xsl:if test="$set">
        <xsl:variable name="items">
          <xsl:for-each select="$set">
            <xsl:variable name="value">
              <xsl:apply-templates select="." mode="core:process_node">
                <xsl:with-param name="string_nodes" select="$string_nodes" />
              </xsl:apply-templates>
            </xsl:variable>

            <xsl:if test="normalize-space($value)">
              <item>
                <xsl:apply-templates select="." mode="core:make_object_key" />
                <xsl:value-of select="$value" disable-output-escaping="yes" />
              </item>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="set_as_string">
          <xsl:call-template name="utils:join">
            <xsl:with-param name="set" select="exsl:node-set($items)/item" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:value-of select="$set_as_string" disable-output-escaping="yes" />

        <xsl:if test="
          normalize-space($set_as_string) and
          normalize-space($raw_string_data)
        ">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:if>

      <xsl:value-of select="$raw_string_data" disable-output-escaping="yes" />

      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>


  <!--
    Выводит ключ json-объекта в зависимости от типа пришедшего узла.
    Базоывае настройки (см. энтити-константы):
      для текстовых узлов - $
      для атрибутов - $<имя атрибута>
      для узлов-элементов - имя элемента
    -->
  <xsl:template match="* | @* | text()" mode="core:make_object_key">
    <xsl:variable name="is_attribute" select="count(. | ../@*) = count(../@*)"/>
    
    <xsl:call-template name="core:string">
      <xsl:with-param name="str">
        <xsl:choose>
          <xsl:when test="self::text()">&TEXT_NODE_KEY;</xsl:when>
          <xsl:otherwise>
            <xsl:if test="$is_attribute">&ATTR_KEY_PREFIX;</xsl:if>
            <xsl:value-of select="name()" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:text>:</xsl:text>
  </xsl:template>


  <!--
    Выводит массив смешанных данных вида
    [
      { "key": -0.35 },
      "text node",
      { "item": "hasta-la-vista" }
    ]
    -->
  <xsl:template name="core:make_array_mixed">
    <xsl:param name="set" />
    <xsl:param name="raw_string_data" />
    <xsl:param name="string_nodes" />


    <xsl:if test="$set or normalize-space($raw_string_data)">
      <xsl:text>[</xsl:text>

      <xsl:value-of select="$raw_string_data" disable-output-escaping="yes" />
      <xsl:if test="normalize-space($raw_string_data)">,</xsl:if>

      <xsl:if test="$set">
        <xsl:variable name="items">
          <xsl:for-each select="$set">
            <xsl:variable name="value">
              <xsl:apply-templates select="." mode="core:object">
                <xsl:with-param name="is_make_root" select="true()" />
                <xsl:with-param name="string_nodes" select="$string_nodes" />
              </xsl:apply-templates>
            </xsl:variable>

            <xsl:if test="normalize-space($value)">
              <item>
                <xsl:value-of select="$value" />
              </item>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:call-template name="utils:join">
          <xsl:with-param name="set" select="exsl:node-set($items)/item" />
        </xsl:call-template>
      </xsl:if>

      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>


  <!--
    Выводит массив однородных данных вида
    {
      "item" : [
        true,
        { "key": "value" },
        "megastring"
      ]
    }
    где item - имя каждого элемента из параметра $set
    -->
  <xsl:template name="core:make_array_identical">
    <xsl:param name="set" />
    <xsl:param name="extraset" />
    <xsl:param name="skip_root" select="false()" />
    <xsl:param name="string_nodes" />

    <xsl:if test="$set">
      <xsl:variable name="array">
        <xsl:text>[</xsl:text>

        <xsl:variable name="items">
          <xsl:for-each select="$set">
            <xsl:variable name="value">
              <xsl:apply-templates select="." mode="core:process_node">
                <xsl:with-param name="string_nodes" select="$string_nodes" />
              </xsl:apply-templates>
            </xsl:variable>

            <xsl:if test="normalize-space($value)">
              <item>
                <xsl:value-of select="$value" />
              </item>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:call-template name="utils:join">
          <xsl:with-param name="set" select="exsl:node-set($items)/item" />
        </xsl:call-template>

        <xsl:text>]</xsl:text>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="not($extraset) and $skip_root">
          <xsl:value-of select="$array" disable-output-escaping="yes" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="core:make_object">
            <xsl:with-param name="set" select="$extraset" />
            <xsl:with-param name="raw_string_data">
              <xsl:apply-templates
                select="$set[1]" mode="core:make_object_key"
              />
              <xsl:value-of select="$array" />
            </xsl:with-param>
            <xsl:with-param name="string_nodes" select="$string_nodes" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>


  <!--
    Выводит примитивное json-значение - null, true, false, число или строку
    -->
  <xsl:template name="core:make_simple_value">
    <xsl:param name="string_data" />

    <xsl:choose>
      <xsl:when test="
        string-length($string_data) = 0 or
        string($string_data) = 'null'"
      >
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:when test="string(number($string_data)) != 'NaN'">
        <xsl:value-of select="normalize-space($string_data)" />
      </xsl:when>
      <xsl:when test="translate($string_data, 'TRUE', 'true') = 'true'">
        <xsl:text>true</xsl:text>
      </xsl:when>
      <xsl:when test="translate($string_data, 'FALSE', 'false') = 'false'">
        <xsl:text>false</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="core:string">
          <xsl:with-param name="str" select="$string_data" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--
    Делает json-строку - экранирует пришедшее значение и оборачивает кавычками
    -->
  <xsl:template name="core:string">
    <xsl:param name="str" />

    <xsl:text>&JSON_STRING_QUOTE;</xsl:text>
    <xsl:call-template name="core:string_escape">
      <xsl:with-param name="str" select="$str" />
    </xsl:call-template>
    <xsl:text>&JSON_STRING_QUOTE;</xsl:text>
  </xsl:template>

  <!--
    Делает json-экранирование:
    \        ==> \\
    "        ==> \"
    перевод строки  ==> \n
    возврат каретки  ==> \r
    табуляция    ==> \t
    -->
  <xsl:template name="core:string_escape">
    <xsl:param name="str" />

    <xsl:variable name="step1">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$str" />
        <xsl:with-param name="search" select="'\'" />
        <xsl:with-param name="replace" select="'\\'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step2">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step1" />
        <xsl:with-param name="search" select="'&quot;'" />
        <xsl:with-param name="replace" select="'\&quot;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step3">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step2" />
        <xsl:with-param name="search" select="'&#xA;'" />
        <xsl:with-param name="replace" select="'\n'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step4">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step3" />
        <xsl:with-param name="search" select="'&#xD;'" />
        <xsl:with-param name="replace" select="'\r'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step5">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step4" />
        <xsl:with-param name="search" select="'&#x9;'" />
        <xsl:with-param name="replace" select="'\t'" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="$step5" disable-output-escaping="yes" />
  </xsl:template>


  <!--
    json unescaping:
      \\  =>  \
      \"  =>  "

    @param {string} str
    -->
  <xsl:template name="core:string_unescape">
    <xsl:param name="str" />

    <xsl:variable name="step1">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$str" />
        <xsl:with-param name="search" select="'\&quot;'" />
        <xsl:with-param name="replace" select="'&quot;'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="step2">
      <xsl:call-template name="utils:str_replace">
        <xsl:with-param name="str" select="$step1" />
        <xsl:with-param name="search" select="'\\'" />
        <xsl:with-param name="replace" select="'\'" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="$step2" disable-output-escaping="yes" />
  </xsl:template>


</xsl:stylesheet>