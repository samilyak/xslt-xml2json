<?xml version="1.0" encoding="utf-8" ?>
<!--
  @fileoverview Templates for building all json data types.
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


  <!--
    @param {Nodeset|RTF} data
    @param {Nodeset|string} string_elems
    @param {boolean} skip_root
    @return {string}
  -->
  <xsl:template name="core:convert">
    <xsl:param name="data" />
    <xsl:param name="string_elems" />
    <xsl:param name="skip_root" />

    <xsl:choose>
      <!--
        Convert $data to temporary tree and process its child nodes
        if $data is a result tree fragment (RTF)
        -->
      <xsl:when test="exsl:object-type($data) = 'RTF'">
        <xsl:call-template name="core:process_string_elems">
          <xsl:with-param name="dataset" select="exsl:node-set($data)/node()" />
          <xsl:with-param name="skip_root" select="$skip_root" />
          <xsl:with-param name="string_elems" select="$string_elems" />
        </xsl:call-template>
      </xsl:when>

      <!--
        Check $data structure if it's a nodeset.
      -->
      <xsl:when test="exsl:object-type($data) = 'node-set'">
        <xsl:choose>
          <!--
            Just work with child nodes
            if $data is a root of a tree (no matter it's input tree
            or temporary tree).

            We can't use just `name($data) = name(/)` check here
            because it's true for `/root_element = /`,
            but we want to distinguish root element and root itself.
            -->
          <xsl:when test="$data[($data = /) and (name($data) = name(/))]">
            <xsl:call-template name="core:process_string_elems">
              <xsl:with-param name="dataset" select="$data/node()" />
              <xsl:with-param name="skip_root" select="$skip_root" />
              <xsl:with-param name="string_elems" select="$string_elems" />
            </xsl:call-template>
          </xsl:when>

          <!--
            Process $data nodeset as is otherwise
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
        Process $data as a primitive json value here
        -->
      <xsl:otherwise>
        <xsl:call-template name="core:make_simple_value">
          <xsl:with-param name="string_data" select="$data" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--
    @param {Nodeset} dataset
    @param {Nodeset|string} string_nodes
    @param {boolean} skip_root
    @return {string}
    -->
  <xsl:template name="core:process_string_elems">
    <xsl:param name="dataset" />
    <xsl:param name="string_elems" />
    <xsl:param name="skip_root" />

    <xsl:choose>
      <!--
        Use $string_elems as is if it's a nodeset
        -->
      <xsl:when test="exsl:object-type($string_elems) = 'node-set'">
        <xsl:call-template name="core:process_dataset">
          <xsl:with-param name="dataset" select="$dataset" />
          <xsl:with-param name="skip_root" select="$skip_root" />
          <xsl:with-param name="string_nodes" select="$string_elems" />
        </xsl:call-template>
      </xsl:when>

      <!--
        Treat $string_elems as a string containing XPath otherwise.
        We need to eval this XPath to obtain nodeset.
        -->
      <xsl:otherwise>
        <!--
          for-each loop is just to enter $dataset nodeset context.
        -->
        <xsl:for-each select="$dataset[1]">
          <xsl:variable name="root" select="/" />

          <!--
            Now we should to set context to the root of a tree containing
            $dataset. We need this to make evaluate() function to work
            in this root context (that context could be an input tree
            or a temporary tree).
            -->
          <xsl:for-each select="$root">
            <xsl:choose>

              <!-- Saxon -->
              <xsl:when test="
                normalize-space($string_elems) and
                function-available('saxon:evaluate')
              ">
                <xsl:call-template name="core:process_dataset">
                  <xsl:with-param name="dataset" select="$dataset" />
                  <xsl:with-param name="skip_root" select="$skip_root" />
                  <xsl:with-param
                    name="string_nodes" select="saxon:evaluate($string_elems)"
                  />
                </xsl:call-template>
              </xsl:when>

              <!-- libxslt, Xalan -->
              <xsl:when test="
                normalize-space($string_elems) and
                function-available('dyn:evaluate')
              ">
                <xsl:call-template name="core:process_dataset">
                  <xsl:with-param name="dataset" select="$dataset" />
                  <xsl:with-param name="skip_root" select="$skip_root" />
                  <xsl:with-param
                    name="string_nodes" select="dyn:evaluate($string_elems)"
                  />
                </xsl:call-template>
              </xsl:when>

              <!-- Any other xslt processor - discard $string_elems -->
              <xsl:otherwise>
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
  


  <!--
    @param {Nodeset} dataset
    @param {Nodeset} string_nodes
    @param {boolean} skip_root
    @return {string}
    -->
  <xsl:template name="core:process_dataset">
    <xsl:param name="dataset" />
    <xsl:param name="string_nodes" />
    <xsl:param name="skip_root" />

    <!--
      Skip comments and whitespace text nodes
      -->
    <xsl:variable
      name="clean_dataset"
      select="$dataset[
        not(self::comment()) and
        not(self::text()[not(normalize-space())])
      ]"
    />

    <xsl:choose>
      <!--
        We have nodeset here - we need to know the structure of this nodeset
        -->
      <xsl:when test="count($clean_dataset) > 1">
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
            Print array of similar items if we have elements only
            (neither attributes nor text nodes) where all of them
            have the same name.
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
                Print json object if we have elements only with distinct names
                -->
              <xsl:when
                test="$is_elements_only and $is_all_names_different = 'true'
              ">
                <xsl:call-template name="core:make_object">
                  <xsl:with-param name="set" select="$clean_dataset" />
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:call-template>
              </xsl:when>

              <!--
                Print array of mixed items otherwise
               -->
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

      <!--
        We have 1 node here - just process this node
        -->
      <xsl:otherwise>
        <xsl:choose>
          <!--
            Process node content if we're forced to skip root object
            -->
          <xsl:when test="$skip_root">
            <xsl:apply-templates
              select="$clean_dataset" mode="core:process_node"
            >
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:apply-templates>
          </xsl:when>

          <!--
            Print object that have 1 key with node content otherwise
            { <$dataset node name> : <$dataset content> }
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


  <!--
    @param {Nodeset} string_nodes
    @return {string}
  -->
  <xsl:template match="* | @*" mode="core:process_node">
    <xsl:param name="string_nodes" />

    <xsl:choose>
      <!--
        Attribute 'json-type' is a config attribute - skip it.
        -->
      <xsl:when test="name() = '&CONFIG_ATTR_NAME;'"/>

      <!--
        Output node content as a string if its attribute json-type="string"
        or this node is passed in $string_nodes parameter.
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
            Print array of similar items if node contains elements only
            (except whitespace text nodes) where all of them has the same name.
            Another condition - number of child element is more than 1 or we're
            forced to print json array by attribute json-type="array".
            {
              "item" : [
                true,
                { "key": "value" },
                "megastring"
              ]
            }
            'item' is the name of each child element.
            -->
          <xsl:when test="
            not(text()[normalize-space()]) and $is_all_names_equals = 'true'
            and (count(*) > 1 or @*[name() = '&CONFIG_ATTR_NAME;'] = 'array')
          ">
            <xsl:choose>
              <!--
                Don't print root object with a dumb single key { "item": ... }
                if we're forced to print json array by json-type="array"
              -->
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
                Print json object if all child elements have distinct names
                (so we can ensure json object keys uniqueness)
                and there are no elements and non-whitespace text nodes
                at the same time.
                -->
              <xsl:when test="
                $is_all_names_different = 'true' and
                not(* and text()[normalize-space()])
              ">
                <xsl:apply-templates select="." mode="core:object">
                  <xsl:with-param name="string_nodes" select="$string_nodes" />
                </xsl:apply-templates>
              </xsl:when>

              <!--
                Print array of mixed items otherwise (elements names
                aren't distinct or elements are mixed with text nodes)
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
        Output primitive json value if there are neither child elements
        nor attributes. That's always the case whe context node is attribute
        or text node.
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
      Print text node if it has no sibling element nodes
      or it does delimit element nodes but it's whitespace text node.
      -->
    <xsl:if test="not(../*) or normalize-space(.)">
      <xsl:call-template name="core:make_simple_value">
        <xsl:with-param name="string_data" select="." />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <!--
    Outputs json array of similar items.
    Applied for node containing elements only
    where all of them has the same name.

    <characters main="true">
      <item>Mark Greene</item>
      <item sexy="false">Doug Ross</item>
      <item>Susan Lewis</item>
      <item student="true">
        <first_name>John</first_name>
        <last_name>Carter</last_name>
      </item>
    </characters>

    ==>

    {
      "$main" : true,
      "item" : [
      "Mark Greene",
      { "$sexy": false, "$": "Doug Ross" },
      "Susan Lewis",
      { "$student": true, "first_name": "John", "last_name": "Carter" }
      ]
    }

    @param {Nodeset} string_nodes
    @param {boolean=} skip_root
    @return {string}
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
    Outputs json array of mixed items.
    Applied for:
      - node containing elements *and* text nodes
      - node containing elements that have not distinct names

    <cast season="1" episode="4">
      <chief>Anthony Edwards</chief>
      <chief>William Macy</chief>
      George Clooney
      <stupid name="Sherry">
        <sirname>Stringfield</sirname>
      </stupid>
      <student>Noah Wyle</student>
    </cast>

    ==>

    [
      { "$season": 1, "$episode": 4 },
      { "chief": "Anthony Edwards" },
      { "chief": "William Macy" },
      "George Clooney",
      { "stupid": { "$name": "Sherry", "sirname": "Stringfield" } },
      { "student": "Noah Wyle" }
    ]

    @param {Nodeset} string_nodes
    @return {string}
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
    Outputs json object of arbitrary structure.
    Applied for node containing elements only and all of them have
    distinct names.

    <episodes>
      <one>24 Hours</one>
      <two>
        <first night="false">Day</first>
        <second>One</second>
      </two>
      <three name="Going Home" />
    </episodes>

    ==>

    {
      "one": "24 Hours",
      "two": { "first": { "$night": false, "$": "Day" }, "second": "One" },
      "three": { "$name": "Going Home" }
    }

    @param {Nodeset} string_nodes
    @param {boolean=} is_make_root
    @return {string}
    -->
  <xsl:template match="* | @*" mode="core:object">
    <xsl:param name="string_nodes" />
    <xsl:param name="is_make_root" select="false()" />

    <xsl:variable
      name="is_empty" select="not(*) and not(@*) and not(normalize-space(.))"
    />

    <xsl:choose>
      <!--
        Print 'null' if node is empty and we aren't forced to print object.
        -->
      <xsl:when test="$is_empty and not($is_make_root)">
        <xsl:call-template name="core:make_simple_value">
          <xsl:with-param name="string_data" select="'null'" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>
          <!--
            Process context node itself if it has neither child nodes
            nor attributes or we're forced to print object.
            -->
          <xsl:when test="(not(*) and not(@*)) or $is_make_root">
            <xsl:call-template name="core:make_object">
              <xsl:with-param name="set" select="." />
              <xsl:with-param name="string_nodes" select="$string_nodes" />
            </xsl:call-template>
          </xsl:when>

          <!--
            Process child nodes otherwise.
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
    Outputs text node as a primitive json value.

    @param {Nodeset} string_nodes
    @return {string}
    -->
  <xsl:template match="text()" mode="core:object">
    <xsl:param name="string_nodes" />

    <xsl:apply-templates select="." mode="core:process_node">
      <xsl:with-param name="string_nodes" select="$string_nodes" />
    </xsl:apply-templates>
  </xsl:template>


  <!--
    Converts context node to string containing xml.

    Sometimes we want to pass html markup as a json string.
    For example, this xml:
    <description>
      <p><strong>ER</strong> is an American medical drama television series</p>
    </description>

    this templates converts to string:
    "<p><strong>ER</strong> is an American medical drama television series</p>"

    while regular conversion would do this:
    {"p": [{"strong": "ER"}, " is an American medical drama television series"]}


    @return {string}
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
    Outputs json object using nodes names of a $set parameter.
    Node's name is used an object key.
    {
      "one": "24 Hours",
      "two": { "title": "Day One" },
      "three": { "$name": "Going Home" }
    }

    @param {Nodeset} set
    @param {string=} raw_string_data
    @param {Nodeset} string_nodes
    @return {string}
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
    Outputs json object key depending on context node type:
      - '$' for text node
      - '$<attribute name>' for attribute node
      - '<element name>' for element node

    Returned string will be suffixed with semicolon ':'
    (json object's key-value delimiter).

    @return {string}
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
    Outputs json array of mixed items:
    [
      { "key": -0.35 },
      "text node",
      { "item": "hasta-la-vista" }
    ]

    @param {Nodeset} set
    @param {string} raw_string_data
    @param {Nodeset} string_nodes
    @return {string}
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
    Outputs json array of similar items:
    {
      "item" : [
        true,
        { "key": "value" },
        "megastring"
      ]
    }
    'item' is a common name of each element in a $set parameter

    @param {Nodeset} set
    @param {Nodeset} extraset
    @param {boolean=} skip_root
    @param {Nodeset} string_nodes
    @return {string}
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
    Outputs json primitive value - null, true, false, number or string

    @param {string} string_data
    @return {string}
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
        <xsl:value-of select="number($string_data)" />
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
    Constructs json string - escapes it and surrounds it with quotes

    @param {string} str
    @return {string}
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
    Json sting escaping:
      \  =>  \\
      "  =>  \"
      new line => \n
      carriage return => \r
      tab => \t

    @param {string} str
    @return {string}
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
    Json string unescaping:
      \\  =>  \
      \"  =>  "

    @param {string} str
    @return {string}
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