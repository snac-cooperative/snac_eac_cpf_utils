<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:functx="http://www.functx.com"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:snac="http://socialarchive.iath.virginia.edu/worldcat"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:mads="http://www.loc.gov/mads/"
                exclude-result-prefixes="eac lib xs saxon xsl madsrdf rdf mads functx marc snac"
                >
    <!-- 
         Author: Tom Laudeman
         The Institute for Advanced Technology in the Humanities

         Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
         "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
         License at
         
         http://www.osedu.org/licenses/ECL-2.0
         
         Unless required by applicable law or agreed to in writing, software distributed under the License is
         distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
         the License for the specific language governing permissions and limitations under the License.

         This is a library of xml templates and functions shared by several XSLT scripts.
         
         match_record -> tpt_all_xx -> lib:edate_core -> tpt_exist_dates returns tokens
                                       '             '-> tpt_show_date takes tokens and returns exist_dates
                                       '-> var tokens returned by lib:edate_core)
                                       '-> var exist_dates returned by lib:edate_core)
                                       
         Template match_record is in try_date_regex.xsl or oclc_marc2cpf.xsl.                                       
                                       
         Template name="match_record" calls template tpt_all_xx to create a node
         set that is later used to create the .c and .r output files.
         tpt_all_xx builds a node set of the .c and .r nameEntry/part. Inside
         tpt_all_xx, the var temp_node includes a exist dates which it gets by
         calling lib:edate_core().  lib:edate_core() calls tpt_exist_dates when
         it has something it wants a date for.
         
         I suggest changing lib: to eac: maybe so that all the code and
         functions are in the same namespace. I'm not sure it makes any
         difference since it seems necessary to explicitly set the namespace
         since it is difficult to know the current context namespace. Using the
         current context namespace broke this code when it was refactored into a
         more-or-less portable set of templates and functions.

         match_record -> tpt_all_xx -> edate_core -> tpt_exist_dates
                                       '-> var exist_dates-> tpt_show_dates
    -->

    <!-- <xsl:output method="xml" /> -->
    <xsl:variable name="occupations" select="document('occupations.xml')/*"/>
    <xsl:variable name="relators" select="document('vocabularyrelators.rdf')/*"/>
    <xsl:variable name="languages" select="document('vocabularylanguages.rdf')/*"/>
    <xsl:variable name="org_codes" select="document('worldcat_code.xml')/*"/>
    
    <xsl:template mode="get_lang" match="*">
         <xsl:choose>
             <xsl:when test="madsrdf:authoritativeLabel">
                 <xsl:value-of select="madsrdf:authoritativeLabel"/>
             </xsl:when>
             <xsl:when test="madsrdf:deprecatedLabel">
                 <xsl:value-of select="madsrdf:deprecatedLabel"/>
                 <!-- <xsl:text> (deprecated) </xsl:text> -->
             </xsl:when>
         </xsl:choose>
     </xsl:template>
     
     <xsl:template name="tpt_lang_decl" xmlns="urn:isbn:1-931666-33-4">
         <!--
             This is control/languageDeclaration. I'm pretty sure there is only a single
             040$b per record, but for-each sets the context, so that is
             good. When we have an 040$b, use it, otherwise default to English.
             
             (description/languageUsed is derived from the 041$a; see tpt_language)
         -->
         <xsl:choose>
             <xsl:when test="boolean(marc:datafield[@tag='040']/marc:subfield[@code='b'])">
                 <xsl:for-each select="marc:datafield[@tag='040']/marc:subfield[@code='b']">
                     <xsl:variable name="lang_code" select="."/>
                     <xsl:element name="languageDeclaration" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:element name="language" xmlns:eac="urn:isbn:1-931666-33-4">
                             <xsl:attribute name="languageCode" select="$lang_code"/>
                             <xsl:apply-templates mode="get_lang" select="$languages/madsrdf:Topic[madsrdf:code = $lang_code]"/>
                         </xsl:element>
                         <xsl:element name="script" xmlns:eac="urn:isbn:1-931666-33-4">
                             <xsl:attribute name="scriptCode" select="'Zyyy'"/>
                             <xsl:text>Unknown</xsl:text>
                         </xsl:element>
                     </xsl:element>
                 </xsl:for-each>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:element name="languageDeclaration" xmlns:eac="urn:isbn:1-931666-33-4">
                     <xsl:element name="language" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="languageCode" select="'eng'"/>
                         <xsl:text>English</xsl:text>
                     </xsl:element>
                     <xsl:element name="script" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="scriptCode" select="'Zyyy'"/>
                         <xsl:text>Unknown</xsl:text>
                     </xsl:element>
                 </xsl:element>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template name="tpt_is_cp">
         <xsl:variable name="temp">
             <xsl:for-each select="marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='700' or @tag='710' or @tag='711']/marc:subfield[@code='v']">
                 <val>
                     <xsl:value-of select="matches(., 'correspondence', 'i')"/>
                 </val>
             </xsl:for-each>
         </xsl:variable>
         <!--
             Use boolean() so that true returns true, and "" returns false. XSLT will not automatically cast "" to
             false. We will get true if there is at least one true value.
         -->
         <xsl:value-of select="boolean($temp/val[.=true()][1])"/>
     </xsl:template>
     

     <xsl:template name="tpt_geo" xmlns="urn:isbn:1-931666-33-4">
         <!--
             Build a node set regardless of empty placeEntry values or duplicates. Then copy removing empties
             and duplicates. The elements are for output, so we create them in the eac namespace.
         -->
         <xsl:variable name="geo_651">
             <!--
                 Create a temporary node set in variable $df with a prev
                 attribute so we can check for $a followed by ($z
                 repeating). Template mode do_subfield is below. Call
                 do_subfield with a sequence of all the subfield elements of the
                 current datafield. 
             -->
             <xsl:variable name="df">
                 <xsl:for-each select="marc:datafield[@tag='651']">
                     <datafield xmlns="http://www.loc.gov/MARC21/slim">
                         <xsl:copy-of select="@*" />
                         <xsl:text>&#x0A;</xsl:text>
                         <xsl:call-template name="do_subfield">
                             <xsl:with-param name="sub" select="marc:subfield"/>
                             <xsl:with-param name="prev" select="''"/>
                         </xsl:call-template>
                     </datafield>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:for-each>
             </xsl:variable>

             <!--
                 With the proper meta-data, building the geo subject is possible.
                 Three cases: $a regardless of following, $a with contiguous
                 following $z (repeating), $z repeating not contiguous with $a.
                 
                 $df has been forced to be namespace ns as all input from the marc records, so continue using
                 the marc: prefix here. Must use xsl:element to force <place> and <placeEntry> are output into
                 the eac: namespace. Literals inherit the "current namespace", but "current" has some odd,
                 non-current characteristics.
             -->
             <xsl:for-each select="$df/marc:datafield">
                 <xsl:if test="marc:subfield[@code='a' or (@code='z' and @prev='a')]">
                     <place localType="snac:associatedPlace">
                         <placeEntry>
                             <xsl:for-each select="marc:subfield[@code='a' or (@code='z' and @prev='a')]">
                                 <xsl:if test="not(position()=1)">
                                     <xsl:text>--</xsl:text>
                                 </xsl:if>
                                 <xsl:value-of select="lib:norm-punct(.)"/>
                             </xsl:for-each>
                         </placeEntry>
                     </place>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:if>
                 
                 <xsl:if test="marc:subfield[@code='z' and (@prev='' or @prev='z')]">
                     <place localType="snac:associatedPlace">
                         <placeEntry>
                             <xsl:for-each select="marc:subfield[@code='z' and (@prev='' or @prev='z')]">
                                 <xsl:if test="not(position()=1)">
                                     <xsl:text>--</xsl:text>
                                 </xsl:if>
                                 <xsl:value-of select="lib:norm-punct(.)"/>
                             </xsl:for-each>
                         </placeEntry>
                     </place>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:if>
                 
             </xsl:for-each>
         </xsl:variable>

         <xsl:variable name="geo1">
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="650"/>
             </xsl:call-template>
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="656"/>
             </xsl:call-template>
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="657"/>
             </xsl:call-template>
             <xsl:copy-of select="$geo_651"/>
         </xsl:variable>
         
         <!--
             Deduping a node set in 6 lines of code, but subtle. We need to
             compare each node to every other node in the node set. That is
             impossible in a single conditional because pname-match() takes
             string args, not node set args. Looking at it another way, we have
             two separate contexts to compare, so one of them will have to be
             saved to a variable. somepath[] will implicitly for-each over nodes
             in the []. We must use a variable for the outer context (an explicit
             for-each) since the context inside the [] is different. The xsl:if
             will map all preceding placeEntry values through pname-match()
             against the current $geo1 node in $curr. To state the problem
             another way, we can only have one implicit loop in [], so that loop
             must be the preceding nodes. We need to loop through $geo1 comparing
             the current node to all (by looping over) the preceding nodes.
             
             We are deduping a list against itself. We loop over each node while
             implicitly looping over all preceding nodes. The outer loop is an
             (explicit) for-each. The inner loop is an implicit mapping of values
             inside preceding::placeEntry[].
             
             The final confusing part is that the preceding::placeEntry will
             return 0 or more matching nodes, as opposed to returing true or
             false. If there are any matching nodes then we have a
             duplicate. Thus we put not() around the whole preceding::placeEntry expression.
             
             This short method (the 6 line deduping algorighm) requires an outer container element. In this
             case I suppose the outer element is <place> and we are deduping <placeEntry>. (Or it could be
             that I didn't understand how to use /* to for-each over nodes in a variable without referring to
             a root node.)
         -->
         
         <xsl:for-each select="$geo1/eac:place[string-length(eac:placeEntry) > 0]">
             <xsl:variable name="curr" select="."/>
             <xsl:if test="not(preceding::eac:placeEntry[lib:pname-match(text(),  $curr/eac:placeEntry)])">
                 <xsl:copy-of select="$curr" />
             </xsl:if>
         </xsl:for-each>
     </xsl:template> <!-- end tpt_geo -->

     
     <xsl:template name="do_subfield" xmlns="http://www.loc.gov/MARC21/slim">
         <xsl:param name="sub"/>
         <xsl:param name="prev"/>
         <!-- 
              This recursively builds a node set that tells us when 'a' or 'z'
              immediately precedes 'z'. Each node in the node set has the code
              and $prev as well as the value of the subfield.
         -->
         <xsl:variable name="code" select="$sub[1]/@code"/>
         
         <subfield code="{$code}" prev="{$prev}">
             <xsl:value-of select="$sub" />
         </subfield>

         <!--
             $ancestral_a is the state of the current node that we're passing to
             the next recursive iteration. The variable name fits since it could
             be restated as "do I have a direct 'a' ancestral lineage?".
         -->
         <xsl:variable name="ancestral_a">
             <xsl:choose>
                 <xsl:when test="$code = 'a' or ($code = 'z' and $prev = 'a')">
                     <xsl:value-of select="'a'"/>
                 </xsl:when>
                 <xsl:when test="$code = 'z' or $prev = 'z'">
                     <xsl:value-of select="'z'"/>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:value-of select="''"/>
                 </xsl:otherwise>
             </xsl:choose>
         </xsl:variable>

         <!--
             Recurse on the remaining sibling subfields.
         -->
         <xsl:if test="boolean($sub/following-sibling::marc:subfield)">
             <xsl:call-template name="do_subfield">
                 <xsl:with-param name="sub" select="$sub/following-sibling::marc:subfield"/>
                 <xsl:with-param name="prev" select="$ancestral_a"/>
             </xsl:call-template>
         </xsl:if>
     </xsl:template>


     <xsl:template name="tpt_arc_role">
         <xsl:param name="is_c_flag"/>
         <xsl:param name="is_cp"/>
         <xsl:param name="is_r_flag"/>

         <!--
             I think the probably ends up in /eac-cpf/cpfDescription/relations/resourceRelation in the output
             template eac_cpf.xsl.
         --> 

         
         <xsl:choose>
             <xsl:when test="$is_c_flag or (eac:e_name/@is_creator=true())">
                 <xsl:text>snac:creatorOf</xsl:text>
             </xsl:when>
             <xsl:when test="$is_cp">
                 <xsl:text>snac:correspondedWith</xsl:text>
             </xsl:when>
             <xsl:when test="$is_r_flag">
                 <xsl:text>snac:referencedIn</xsl:text>
             </xsl:when>
             <xsl:otherwise>
                 <!-- This can't happen given current logic. (Really?) -->
                 <xsl:text>snac:associatedWith</xsl:text>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>
     
     <xsl:template name="tpt_rules">
	 <xsl:choose>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='b'">
		 <xsl:text>aacr1</xsl:text>
	     </xsl:when>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='c'">
		 <xsl:text>aacr2</xsl:text>
	     </xsl:when>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='d'">
		 <xsl:text>aacr2compatible</xsl:text>
	     </xsl:when>
	     <xsl:otherwise>unknown</xsl:otherwise>
	 </xsl:choose>
     </xsl:template>

    <xsl:template name="tpt_65x_geo" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tag"/>
        <!--
            Deal with mutiple elements with the same tag value. For example,
            multiple 650$z elements. Simply join all $z, contiguous or not.
        -->
        <xsl:for-each select="marc:datafield[@tag=$tag]" >
            <!-- removed xmlns="urn:isbn:1-931666-33-4" and moved to enclosing template element. -->
            <place localType="snac:associatedPlace">
                <placeEntry>
                    <xsl:for-each select="marc:subfield[@code='z']">
                        <xsl:if test="not(position() = 1)">
                            <xsl:text>--</xsl:text>
                        </xsl:if>
                        <xsl:value-of select="lib:norm-punct(.)"/>
                    </xsl:for-each>
                </placeEntry>
            </place>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_topical_subject"  xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="record_position"/>
        <xsl:param name="record_id"/>
        <!-- 
             Removing the xmlns above may break this, and the name of the namespace must be "eac" as required
             by the deduping loop at the end of this template.

             Originally, some subfields were captured based on non-repeating or
             repeating, but the data is bad for a few records, so now we capture
             all the desired subfields as though they are repeating. Assume that
             XSLT XPath "or" clauses are processed in order, and have short
             circuit optimization.
             
             Must use xsl:element for localDescription with xmlns. Also need to use xsl:element for term, but
             it inherits eac: which is a tiny bit odd because xsl:element is not supposed to inherit, but I
             guess it doesn't inherit the current namespace, but an explicit namespace is subtly different
             from "current namespace". Current namespace in the for-each is marc:. As a shortcut, the marc:
             can be turned off in the output by putting marc into the exclude-result-prefixes, but that
             masquerades potential problems. While it is not necessary to put an explicit namespace on
             xsl:element term, I did anyway because namespace inheritance is clearly not clear.
        -->
        <xsl:variable name="all_ts">
            <xsl:for-each select="marc:datafield[@tag='650']">
                <localDescription localType="snac:associatedSubject">
                    <term>
                        <xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='v' or @code='x' or @code='y']">
                            <xsl:if test="not(position() = 1)">
                                <xsl:text>--</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="lib:norm-punct(.)"/>
                        </xsl:for-each>
                    </term>
                </localDescription>
            </xsl:for-each>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.
             
             Context is localDescription so paths below are term being relative to the context node.
        -->
        <xsl:for-each select="$all_ts/eac:localDescription[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>

            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template> <!-- end tpt_topical_subject -->
     
     <xsl:template name="tpt_language"
                   xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             This is description/languageUsed. First put each 041$a lang into var $all, then dedup $all and
             wrap each lang with languageUsed to go into description.
             
             (control/languageDeclaration is derived 040$b; see tpt_lang_decl)

             <subfield code="a">gereng</subfield>
             
             This is in the <description> element in the cpf template.

             <languageUsed>
             <language languageCode="ger">German</language>
             <language languageCode="eng">English</language>
             <script scriptCode="Zyyy">Unknown</script>
             </languageUsed>
             
             An empty sequence is not allowed as the @select attribute of xsl:analyze-string.
             
             Use for-each to make sure the context is something non-empty.
        -->
        <xsl:variable name="all">
            <xsl:for-each select="marc:datafield[@tag='041']/marc:subfield[@code='a']">
                <xsl:analyze-string select="." regex="...">
                    <xsl:matching-substring>
                        <xsl:variable name="lang_code" select="regex-group(0)"/>
                        <language languageCode="{$lang_code}">
                            <xsl:apply-templates mode="get_lang" select="$languages/madsrdf:Topic[madsrdf:code = $lang_code]"/>
                        </language>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo. This is a little different since
             $all has no container element, so we for-each on $all/* rather than $all/container. Also, our
             test is = instead of lib:pname-match() or some other function. Apparently /* is perfectly legal
             and robust.  http://www.dpawson.co.uk/xsl/sect2/root.html
        -->
        <xsl:for-each select="$all/*[string-length() > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:language[text() = $curr/text()])">
                <languageUsed>
                    <xsl:copy-of select="$curr"/>
                    <script scriptCode="Zyyy">
                        <xsl:text>Unknown</xsl:text>
                    </script>
                </languageUsed>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_language -->
        

    <xsl:template name="tpt_occupation" xmlns:eac="urn:isbn:1-931666-33-4">
        <xsl:param name="df"/>
        <!--
            If we are a person/family with a 656 occupation then use it, else try to use [167]00$e or [167]00$4 via some lookups in the
            relator xml authority files. (Remember, $e and $4 are relator fields.) Across x00, x10, and x11,
            relator fields are somewhat inconsistent ($e and $j).
        -->
        <xsl:variable name="all">
            <xsl:if test="$df/marc:datafield[@tag ='100' or @tag ='600' or @tag ='700'] and 
                          (boolean($df/marc:datafield/marc:subfield[@code='e']) or
                          boolean($df/marc:datafield/marc:subfield[@code='4']))">
                <xsl:for-each select="$df/marc:datafield/marc:subfield[@code='e']">
                    <xsl:call-template name="tpt_ocfu_e">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="'occupation'"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:for-each select="$df/marc:datafield/marc:subfield[@code='4']">
                    <xsl:call-template name="tpt_ocfu_4">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="'occupation'"/>
                    </xsl:call-template>
                </xsl:for-each>
                <!-- <xsl:apply-templates mode="tpt_occ_e" select="$df/marc:datafield/marc:subfield[@code='e']"/> -->
                <!-- <xsl:apply-templates mode="tpt_occ_4" select="$df/marc:datafield/marc:subfield[@code='4']"/> -->
            </xsl:if>
            <!-- do 657 for 100 as occupation per email Mar 14 2013 1:49 pm -->
            <xsl:if test="$df/marc:datafield[@tag ='100'] and boolean(marc:datafield[@tag='656' or @tag='657'])">
                <xsl:for-each select="marc:datafield[@tag='656' or @tag='657']">
                    <xsl:call-template name="tpt_occ_65x">
                        <xsl:with-param name="ocfu" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.
        -->
        <xsl:for-each select="$all/eac:occupation[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_occupation -->

    <xsl:template name="tpt_function" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="df"/>
        <!-- 
             Must use for-each in case there a multiple $e or $4. Or in the x11 $j.
        -->
        <xsl:variable name="all">
            <xsl:if test="$df/marc:datafield[matches(@tag, '110|610|710')] and
                                (boolean($df/marc:datafield/marc:subfield[@code='e']) or
                                boolean($df/marc:datafield/marc:subfield[@code='4']))">
                <xsl:for-each select="$df/marc:datafield/marc:subfield[@code='e']">
                    <xsl:call-template name="tpt_ocfu_e">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="'function'"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:for-each select="$df/marc:datafield/marc:subfield[@code='4']">
                    <xsl:call-template name="tpt_ocfu_4">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="'function'"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

            <xsl:if test="$df/marc:datafield[matches(@tag, '111|611|711')] and
                          boolean($df/marc:datafield/marc:subfield[@code='j'])">
                <xsl:for-each select="$df/marc:datafield/marc:subfield[@code='j']">
                    <xsl:call-template name="tpt_ocfu_e">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="'function'"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

            <xsl:if test="$df/marc:datafield[@tag ='110' or @tag ='111']">
                <xsl:for-each select="marc:datafield[@tag='657']">
                    <function>
                        <term>
                            <xsl:if test="marc:subfield[@code='a']">
                                <xsl:value-of select="lib:norm-punct(marc:subfield[@code='a'])"/>
                            </xsl:if>
                            
                            <xsl:for-each select="marc:subfield[@code='x' or @code='y' or @code='z']">
                                <xsl:text>--</xsl:text>
                                <xsl:value-of select="lib:norm-punct(.)"/>
                            </xsl:for-each>
                        </term>
                    </function>
                </xsl:for-each>
                <!-- do 656 for 110 and 111 as function per email Mar 14 2013 1:49 pm -->
                <xsl:for-each select="marc:datafield[@tag='656']">
                    <function>
                        <term>
                            <xsl:if test="marc:subfield[@code='a']">
                                <xsl:value-of select="lib:norm-punct(marc:subfield[@code='a'])"/>
                            </xsl:if>
                            <xsl:for-each select="marc:subfield[@code='x' or @code='y' or @code='z']">
                                <xsl:text>--</xsl:text>
                                <xsl:value-of select="lib:norm-punct(.)"/>
                            </xsl:for-each>
                        </term>
                    </function>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>

        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.  Context is function so paths
             below are term being relative to the context node.
        -->
        <xsl:for-each select="$all/eac:function[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_ocfu_4" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="sfield"/>
        <xsl:param name="cname"/>
        <!-- 
             Works just like tpt_occ_4. 
        -->
        <xsl:variable name="test_code" select="lib:unpunct($sfield)"/>
        <xsl:for-each select="$relators/madsrdf:Authority[madsrdf:code = $test_code]">
            <xsl:variable name="unp" select="lower-case(lib:unpunct(madsrdf:authoritativeLabel/text()))"/>
            <xsl:element name="{$cname}">
                <xsl:attribute name="localType" select="'snac:derivedFromRole'"/>
                <xsl:for-each select="$occupations/mads:mads[mads:variant[@otherType='singular']/mads:occupation[text() = $unp]]">
                    <term>
                        <xsl:value-of select="mads:authority/mads:occupation"/>
                    </term>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_ocfu_e" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="sfield"/>
        <xsl:param name="cname"/>
        <!--
            Works just like tpt_occ_e.
        -->
        <xsl:variable name="unp" select="lower-case(lib:unpunct($sfield))"/>

        <xsl:for-each select="$occupations/mads:mads[mads:variant[@otherType='singular']/mads:occupation[text() = $unp]]">
            <xsl:element name="{$cname}">
                <xsl:attribute name="localType" select="'snac:derivedFromRole'"/>
                <term>
                    <xsl:value-of select="mads:authority/mads:occupation"/>
                </term>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_occ_65x" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="ocfu"/>
        <!-- 656 and 657 work the same as occupation, and I suspect they are mutually exclusive. -->
        <occupation>
            <term>
                <xsl:if test="$ocfu/marc:subfield[@code='a']">
                    <xsl:value-of select="marc:subfield[@code='a']"/>
                </xsl:if>
                
                <xsl:for-each select="$ocfu/marc:subfield[@code='x']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>

                <xsl:for-each select="$ocfu/marc:subfield[@code='y']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>

                <xsl:for-each select="$ocfu/marc:subfield[@code='z']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </term>
        </occupation>
    </xsl:template>


    <xsl:template name="tpt_show_date" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tokens"/> 
        <xsl:param name="is_family"/> 
        <xsl:param name="rec_pos"/> 
        <!--
            Date determination logic is here, using the tokenized date. Some of this code is a bit
            dense. existDates must have same namespace as its parent element eac-cpf.
            
            We start of with several tests to determine dates that we cannot parse, and put them in a variable
            to neaten up the code and allow us to only have a single place where the unparsed date node set is
            constructed. Anything that makes it through these tests should be parse-able, although there is a
            catch-all otherwise at the end of the parsing choose.
        -->
        <xsl:if test="$debug">
            <xsl:message>
                <xsl:text>tokens: </xsl:text>
                <xsl:copy-of select="$tokens" />
                <xsl:text>&#x0A;</xsl:text>
            </xsl:message>
        </xsl:if>

        <xsl:variable name="is_unparsed" as="xs:boolean">
            <xsl:choose>
                <!-- 
                     If there are no numeric tokens, the date is unparsed. Note
                     that since we only support integer values for years, we are
                     not checking all valid XML formats for numbers, only
                     [0-9]. Century numbers are a special case, so we have to
                     check them too.
                -->
                <!-- <xsl:when test="count($tokens/tok[matches(text(), '^\d+$|\d+.*century')]) = 0"> -->
                <xsl:when test="count($tokens/tok[text() = 'num']) = 0">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <!--
                    If there are two adjacent number tokens, then unparsed. Due to
                    the declarative nature of xpath, position() will be relative to
                    the context which will change as xpath iterates through the
                    first half of the xpath.
                -->
                <xsl:when test="$tokens/tok[text() = 'num']/following-sibling::tok[position()=1 and text() = 'num']">
                    <xsl:value-of select="true()"/>
                </xsl:when>

                <!--
                    Alphabetic tokens that aren't our known list must be unparsed dates. Note that the second
                    regex matches against the full length of the token.
                -->
                <xsl:when test="$tokens/tok[matches(text(), '[A-Za-z]+') and
                                not(matches(text(), '^(num|approximately|or|active|century|b|d|st|nd|rd|th)$'))]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <!--
                    Unrecognized tokens should only be year numbers. Any
                    supposed-year-numbers that are NAN or numbers > 2013 are errors
                    are unparsed dates. Also, notBefore and notAfter should never be
                    NaN.
                -->
                <xsl:when test="$tokens/tok[@notBefore='NaN' or
                                @notBefore='0' or
                                @notAfter='NaN' or
                                @notAfter='0' or
                                (not(matches(text(), '^(approximately|or|active|century|b|d|st|nd|rd|th|-)$')) and string(@std) = 'NaN') or
                                @std > 2013 or 
                                @std = 0 ]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <!-- There is another unparsed "suspicious" date below in the otherwise element of this choose. -->
            <xsl:when test="$is_unparsed">
                <existDates>
                    <date localType="snac:suspiciousFormat">
                        <xsl:value-of select="$tokens/odate"/>
                    </date>
                </existDates>
            </xsl:when>
        
            <!--
                This test may be meaningless now that numeric tokens have the value 'num'. Except for century,
                we don't like any token that mixes digits and non-digits. We also to not like strings of 5 or
                more digits.
            -->

            <xsl:when test="$tokens/tok[(matches(@std, '\d+[^\d]+|[^\d]+\d+') or matches(@std, '\d{5}')) and not(matches(@val, 'century'))]">
                <existDates>
                    <date localType="snac:suspiciousFormat">
                        <xsl:value-of select="$tokens/odate"/>
                    </date>
                </existDates>
            </xsl:when>

            <!-- born -->

            <xsl:when test="$tokens/tok = 'b'  or (($tokens/tok)[last()] = '-')">
                <!-- No active since that is illogical with 'born' for persons. -->
                <xsl:variable name="loc_type">
                    <xsl:if test="$is_family">
                        <xsl:text>snac:active</xsl:text>
                    </xsl:if>
                    <xsl:if test="not($is_family)">
                        <xsl:text>snac:born</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="curr_tok" select="$tokens/tok[text() = 'num'][1]"/>
                <existDates>
                    <dateRange>
                        <fromDate>
                            <xsl:attribute name="standardDate" select="$curr_tok/@std"/>
                            <xsl:attribute name="localType" select="$loc_type"/>
                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$curr_tok[text() = 'num'][1]/@*[matches(name(), '^not')]">
                                <xsl:choose>
                                    <xsl:when test="string-length(.)>0">
                                        <xsl:attribute name="{name()}">
                                            <xsl:value-of select="format-number(., '0000')"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>
                                            <xsl:copy-of select="$rec_pos" />
                                            <xsl:text> line 395 fromDate empty attr: </xsl:text>
                                            <xsl:copy-of select="." />
                                        </xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                            <!--
                                is_family doesn't have an active token so we need
                                to add it here. Maybe it should have been added
                                earlier.
                            -->

                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>
                                        
                            <!--
                                We know this is a birth date so make that clear in the human readable part of
                                the date by putting a '-' (hyphen, dash) after the date.
                                
                                Put @sep in. If it is blank that's fine, but if not blank, we need it.
                            -->
                            <!-- all tokens before the first date, this includes things like "approximately" -->
                            <xsl:for-each select="$tokens/tok[text() = 'num'][1]/preceding-sibling::tok">
                                <xsl:choose>
                                    <xsl:when test="text() = 'b' or text() = '-'">
                                        <!-- Skip. We already added human readable "born" above. -->
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(., ' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>

                            <xsl:value-of select="normalize-space(concat($curr_tok/@val, $curr_tok/@sep))"/>

                        </fromDate>
                        <toDate/>
                    </dateRange>
                </existDates>
            </xsl:when>
            
            <!-- died --> 
            <xsl:when test="($tokens/tok = 'd') or ($tokens/tok[1] = '-')">
                <!--
                    No active since that is illogical with 'died', unless $is_family in which case this is "active" and not "died".
                -->
                <xsl:variable name="loc_type">
                    <xsl:if test="$is_family">
                        <xsl:text>snac:active</xsl:text>
                    </xsl:if>
                    <xsl:if test="not($is_family)">
                        <xsl:text>snac:died</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="curr_tok" select="$tokens/tok[text() = 'num'][1]"/>
                <existDates>
                    <dateRange>
                        <fromDate/>
                        <toDate>
                            <xsl:attribute name="standardDate" select="$curr_tok/@std"/>
                            <xsl:attribute name="localType" select="$loc_type"/>
                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$curr_tok/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!-- is_family doesn't have an active token so we need
                                 to add it here. Maybe it should have been added
                                 earlier. -->
                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>

                            <!-- all tokens before the first date, this includes things like "approximately" -->
                            <xsl:for-each select="$tokens/tok[text() = 'num'][1]/preceding-sibling::tok">
                                <xsl:choose>
                                    <xsl:when test="text() = 'd' or text() = '-'">
                                        <!-- Skip. We already added human readable "died" above. -->
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(., ' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                            <xsl:value-of select="normalize-space(concat($curr_tok/@val, ' ', $curr_tok/@sep))"/>
                        </toDate>
                    </dateRange>
                </existDates>
            </xsl:when>

            <xsl:when test="count($tokens/tok[text() = '-']) > 0 and count($tokens/tok[text() = 'num']) > 1">
                <!--
                    We have a hyphen and two numbers so it must be from-to.
                -->
                <existDates>
                    <dateRange>
                        <fromDate>
                            <xsl:variable name="curr_tok" select="$tokens/tok[text() = 'num'][1]"/>
                            <xsl:variable name="is_century" select="$curr_tok[matches(@val, 'century')]"/>
                            <xsl:attribute name="standardDate" select="$curr_tok/@std"/>
                            <!--
                                if we have an 'active' token before the hyphen, then then make the subject 'active'.
                            -->
                            <xsl:choose>
                                <xsl:when test="($tokens/tok[text() = '-']/preceding-sibling::tok = 'active') or $is_family or $is_century">
                                    <xsl:attribute name="localType">
                                        <xsl:text>snac:active</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="localType">
                                        <xsl:text>snac:born</xsl:text>
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>

                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$curr_tok/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!-- Text of all tokens before the first date such as "active", "approximately". -->
                            <xsl:for-each select="$tokens/tok[text() = 'num'][1]/preceding-sibling::tok">
                                <xsl:value-of select="concat(., ' ')"/>
                            </xsl:for-each>
                            
                            <!--
                                is_family doesn't have an active token so we need to add it here. Maybe it
                                should have been added earlier.
                            -->
                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>

                            <xsl:value-of select="concat($curr_tok/@val, $curr_tok/@sep)"/>
                        </fromDate>

                        <toDate>
                            <xsl:variable name="curr_tok" select="$tokens/tok[text() = 'num'][2]"/>
                            <xsl:variable name="is_century" select="$curr_tok[matches(@val, 'century')]"/>
                            <xsl:attribute name="standardDate" select="$curr_tok/@std"/>
                            <!--
                                if we have an 'active' token anywhere  or $is_family then 'active' else 'died'
                            -->
                            <xsl:choose>
                                <xsl:when test="($tokens/tok[text() = 'active']) or $is_family or $is_century">
                                    <xsl:attribute name="localType">
                                        <xsl:text>snac:active</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="localType">
                                        <xsl:text>snac:died</xsl:text>
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>

                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$curr_tok/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!--
                                An 'active' token anywhere makes both dates active, and we need the active
                                keyword in the element value (aka human readable).  All tokens after the
                                hyphen. Assume that anything in @sep of a token should be in the output.
                            -->

                            <xsl:if test="$tokens/tok[text() = 'active'] or $is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>

                            <xsl:value-of select="$curr_tok/@val"/>

                            <xsl:for-each select="$tokens/tok[matches(text(), '-')]/following-sibling::tok">
                                <xsl:value-of select="@sep"/>
                                <xsl:if test="not(text() = 'num')">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                                <!-- no @sep or active here. It would look odd to humans. -->
                            </xsl:for-each>
                        </toDate>
                    </dateRange>
                </existDates>
            </xsl:when>

            <xsl:when test="count($tokens/tok[text() = '-']) = 0 and count($tokens/tok[text() = 'num']) = 1">
                <!--
                    No hyphen and only one number so this is a single date.  If we have an 'active' token then
                    'snac:active'.
                -->
                <xsl:variable name="curr_tok" select="$tokens/tok[text() = 'num']"/>
                <existDates>
                    <date>
                        <xsl:attribute name="standardDate" select="$curr_tok/@std"/>
                        <xsl:if test="($tokens/tok[text() = 'active']) or $is_family">
                            <xsl:attribute name="localType">
                                <xsl:text>snac:active</xsl:text>
                            </xsl:attribute>
                        </xsl:if>

                        <!-- Add attributes notBefore, notAfter.  -->
                        <!-- <xsl:for-each select="$tokens/tok[text() = 'num']/@*[matches(name(), '^not')]"> -->
                        <xsl:for-each select="$curr_tok/@*[matches(name(), '^not')]">
                            <xsl:choose>
                                <xsl:when test="string-length(.)>0">
                                    <xsl:attribute name="{name()}">
                                        <xsl:value-of select="format-number(., '0000')"/>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>
                                        <xsl:copy-of select="$rec_pos" />
                                        <xsl:text> line 576 date empty attr: </xsl:text>
                                        <xsl:copy-of select="." />
                                        <xsl:text>&#x0A;</xsl:text>
                                        <xsl:copy-of select="$tokens" />
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>

                        <!-- 
                             is_family doesn't have an active token so we need to add literal text here. Maybe
                             it should have been added earlier.
                        -->
                        <xsl:if test="$is_family">
                            <xsl:text>active </xsl:text>
                        </xsl:if>

                        <!-- all tokens before the first date -->
                        <xsl:for-each select="$curr_tok[text() = 'num'][1]/preceding-sibling::tok">
                            <xsl:value-of select="concat(., ' ')"/>
                        </xsl:for-each>
                        
                        <!-- the date itself, with @sep. -->
                        <xsl:value-of select="concat($curr_tok/@val, $curr_tok/@sep)"/>

                    </date>
                </existDates>
            </xsl:when>

            <xsl:otherwise>
                <existDates>
                    <date localType="snac:suspiciousFormat">
                        <xsl:value-of select="$tokens/odate"/>
                    </date>
                </existDates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- end tpt_show_date -->

    
    <xsl:template name="simple_date_range" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="from" />
        <xsl:param name="from_type"/>
        <xsl:param name="to" />
        <xsl:param name="to_type" />
        <!--
            If there is no "to" then we only have one date. Must always have at least one date.
        -->
        <xsl:choose>
            <xsl:when test="string-length($to) = 0">
                <date standardDate="{$from}" localType="{$from_type}">
                    <xsl:value-of select="$from"/>
                </date>
            </xsl:when>
            <xsl:otherwise>
                <dateRange>
                    <xsl:if test="string-length($from) > 0">
                        <fromDate standardDate="{$from}" localType="{$from_type}"><xsl:value-of select="$from"/></fromDate>
                    </xsl:if>
                    <xsl:if test="string-length($to) > 0">
                        <toDate standardDate="{$to}" localType="{$to_type}"><xsl:value-of select="$to"/></toDate>
                    </xsl:if>
                </dateRange>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_exist_dates">
        <xsl:param name="xx_tag"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="rec_pos"/>
        <xsl:param name="subfield_d"/>
        <!-- 
             MARC date parsing. Normalize various abbreviations and short
             hand. Support 1st, 2nd, 3rd, 4th century,
             
             1) Chew input string one token at a time with using a regular expression character class
             as separator. Put the tokens into a node set.
             
             2) Make several tranformation passes, each time copying "good" data to a new node set.
             
             3) Return the node set so that tpt_show_date can run rules on the
             final node set of tokens to build date elements.
             
             Examples: NNNN-NNNN, NNNN or N, NNNN(approx.), fl. NNNN, b. NNNN,
             d. NNNN, b. ca. NNNN, d. ca. NNNN, Nth cent., fl. Nth cent., Nth
             cent./Mth cent., nnnn(approx.) - nnnn, NNNNs.
        -->
        <xsl:if test="boolean(normalize-space($subfield_d))">
            <!-- break the date into tokens -->
            <xsl:variable name="token_1">
                <xsl:copy-of select="lib:tokenize(normalize-space($subfield_d))"/>
            </xsl:variable>

            <!-- Fix normal "or" and "century or" by creating new token "cyr" -->
            <xsl:variable name="pass_1b">
                <xsl:copy-of select="lib:pass_1b($token_1)"/>
            </xsl:variable>
            
            <!-- Deal with NNNNs as in 1870s as well as "or N" -->
            <xsl:variable name="pass_2">
                <xsl:copy-of select="lib:pass_2($pass_1b)"/>
            </xsl:variable>
            
            <!-- Fix century values. -->
            <xsl:variable name="pass_3">
                <xsl:copy-of select="lib:pass_3($pass_2)"/>
            </xsl:variable>

            <!-- Turn remaining fully numeric tokens into @std, @val, and tok element value 'num'. -->
            <xsl:copy-of select="lib:pass_4($pass_3)"/>

            <!-- <xsl:message> -->
            <!--     <xsl:text>p3: </xsl:text> -->
            <!--     <xsl:copy-of select="lib:pass_3($pass_2)"/> -->
            <!--     <xsl:text>&#x0A;</xsl:text> -->
            <!-- </xsl:message> -->

        </xsl:if>
    </xsl:template>


   <xsl:function name="lib:edate_core">
        <xsl:param name="record_id"/>
        <xsl:param name="record_position"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="df"/>
        <xsl:param name="alt_date"/>
        <!-- 
             $df only contains a single marc:datafield.
        -->
        <xsl:variable name="is_1xx" 
                      select="boolean($df/marc:datafield[@tag='100' or @tag='110' or @tag='111'])"/>
        
        <!--
            1xx is an entity (person/corporate/meeting/family(?)) name, and 7xx is creatorOf (more or
            less). Only when true can entities use the 245$f as an active date.
        -->
        <xsl:variable name="is_17xx"
                      select="boolean($df/marc:datafield[@tag='100' or @tag='110' or @tag='111' or @tag='700' or @tag='710' or @tag='711'])"/>

        <!-- 
             It seems odd to have a boolean for these two. 7xx is creator and 6xx is subject.
        -->
        <xsl:variable name="is_67xx"
                      select="boolean($df/marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='700' or @tag='710' or @tag='711'])"/>
        
        <xsl:variable name="xx_tag">
            <xsl:value-of select="$df/marc:datafield/@tag"/>
        </xsl:variable>
        
        <xsl:variable name="rec_pos"
                      select="concat('offset: ', $record_position, ' id:', $record_id)"/>

        <xsl:variable name="tokens">
            <xsl:choose>
                <!--
                    Get date tokens. Below we pass these to tpt_show_date to
                    generate actual normative dates as a node set.  Any person
                    is equivalent as long as $df contains that person's info,
                    whether 1xx or 6xx/7xx.
                -->
                <xsl:when test="$entity_type = 'person' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <!-- 
                     1xx and 7xx persons with 245$f dates as active dates. We get here if the person does not
                     have a $d date.
                -->

                <xsl:when test="$is_17xx and $entity_type = 'person' and string-length($alt_date)>0">
                    <xsl:call-template name="tpt_parse_alt">
                        <xsl:with-param name="alt_date" select="$alt_date"/>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_1xx and $entity_type = 'family' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_1xx and $entity_type = 'family' and $alt_date">
                    <!-- Family with no $d but which does have a 245$f aka alt_date. -->
                    <xsl:call-template name="tpt_parse_alt">
                        <xsl:with-param name="alt_date" select="$alt_date"/>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_67xx and $entity_type = 'family' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test="$entity_type = 'corporateBody' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <!-- 
                        When corporateBody and 167xx$d then use $d as active date.
                    -->
                    <xsl:call-template name="tpt_parse_alt">
                        <xsl:with-param name="alt_date" select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                    </xsl:call-template>
                </xsl:when>
                
                <xsl:when test="$is_17xx and $entity_type = 'corporateBody' and string-length($alt_date)>0">
                    <!-- 
                         When corporateBody and no $d (test above) and have a 245$f, then use 245$f as an alt
                         date.
                    -->
                    <xsl:call-template name="tpt_parse_alt">
                        <xsl:with-param name="alt_date" select="$alt_date"/>
                    </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                    <!-- Nothing. -->
                </xsl:otherwise>

            </xsl:choose>
        </xsl:variable> <!-- end tokens -->
        
        <!-- <xsl:message> -->
        <!--     <xsl:text>epx: </xsl:text> -->
        <!--     <xsl:apply-templates mode="copy-no-ns" select="$tokens"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->
        <!--
            Test the string-length() since boolean() of a valid but empty variable is still true.
        -->

        <xsl:variable name="exist_dates">
            <xsl:choose>
                <xsl:when test="$tokens/eac:odate[@is_alt = 1]">
                    <xsl:call-template name="tpt_pa_3">
                        <xsl:with-param name="tokens" select="$tokens"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="string-length($tokens) > 0">
                    <xsl:call-template name="tpt_show_date">
                        <xsl:with-param name="tokens" select="$tokens"/>
                        <xsl:with-param name="is_family" select="$entity_type = 'family'"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$debug">
            <xsl:message>
                <xsl:value-of select="$rec_pos"/>
                <xsl:text> et: </xsl:text>
                <xsl:value-of select="$entity_type"/>
                <xsl:text> alt_date: </xsl:text>
                <xsl:value-of select="$alt_date"/>
                <xsl:text> is_1xx: </xsl:text>
                <xsl:value-of select="$is_1xx"/>
                <xsl:text> is_67xx: </xsl:text>
                <xsl:value-of select="$is_67xx"/>
                <xsl:text> 1xx: </xsl:text>
                <xsl:apply-templates mode="copy-no-ns" select="$df"/>
                <xsl:text>&#x0A;</xsl:text>
                <xsl:copy-of select="$exist_dates"/>
                <xsl:text>&#x0A;</xsl:text>
            </xsl:message>
        </xsl:if>

        <xsl:copy-of select="$tokens"/>
        <xsl:copy-of select="$exist_dates"/>
    </xsl:function> <!-- lib:edate_core -->

    <xsl:template name="tpt_file_suffix">
        <xsl:param name="xx_tag"/>
        <xsl:param name="count"/>
        <xsl:choose>
            <xsl:when test="$xx_tag = '100' or $xx_tag = '110' or $xx_tag = '111'">
                <xsl:text>c</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>r</xsl:text>
                <xsl:value-of select="format-number($count, '00')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_expanded_suffix">
        <xsl:param name="xx_tag"/>
        <xsl:param name="count"/>
        <xsl:param name="status"/>
        <!--
            context is the full marc record, so we should have access to anything we need.
        -->
        <xsl:choose>
            <xsl:when test="$status='a' or $status='c' or $status='n' or $status='C'">
                <xsl:text>A</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '600'">
                <xsl:text>P</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '610' or $xx_tag = '611'">
                <xsl:text>C</xsl:text>
            </xsl:when>
            <xsl:when test="marc:datafield[@tag='774' and matches(marc:subfield[@code='o'],'\(SIA\sAH\d+\)')]">
                <xsl:text>S</xsl:text>
            </xsl:when>
            <xsl:when test="marc:datafield[@tag='780' or @tag='785']">
                <xsl:text>EL</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>r</xsl:text>
                <xsl:value-of select="format-number($count, '00')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="tpt_tens">
        <xsl:param name="xx_tag"/>
        <!--
            Create variable for tens positions of the n00 n10 and n11 for 100 600 700. Could probably use substring,
            modulo or a regex, but this is simple and clear even if it isn't very elegant.
        -->
        <xsl:choose>
            <xsl:when test="$xx_tag = '100' or $xx_tag = '600' or $xx_tag = '700'">
                <xsl:text>00</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '110' or $xx_tag = '610' or $xx_tag = '710'">
                <xsl:text>10</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '111' or $xx_tag = '611' or $xx_tag = '711'">
                <xsl:text>11</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    

    
    <xsl:template name="tpt_name_entry">
        <xsl:param name="xx_tag"/>
        <xsl:param name="record_position"/>
        <xsl:param name="record_id"/>
        <!-- 
             The "name entry" is the name in $a plus other fields. Thus
             "Lansdown, Andrew, 1954-" is considred different from "Lansdown,
             Andrew, 1?54-". There could be even more extreme examples that
             differ by only one subfield, rather than differing by a date-typo
             as in this example.
        -->

        <xsl:variable name="has_n">
            <xsl:value-of select="count(marc:subfield[@code = 'n'])" />
        </xsl:variable>

        <xsl:variable name='t167_tens'>
            <xsl:call-template name="tpt_tens">
                <xsl:with-param name="xx_tag" select="$xx_tag"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- 
             The $a subfield is not out here by itself (that is: outside the
             for-each loops below). Even though $a is common to all the loops
             below simply because heaven forbid that $a wasn't the first
             subfield. The cleanest, most reliable algorithm treats the $a like
             the rest of the subfields and retains the original subfield order
             of the original XML record.
        -->
        <xsl:if test="$t167_tens = '00'">
            <xsl:for-each
                select="./marc:subfield[@code = 'a' or @code = 'b' or @code = 'c' or @code='d'  or @code='j'  or @code='q']">
                <xsl:text> </xsl:text>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$t167_tens = '10'">
            <!-- Get the @code preceding a $n and use that code to test for not $t and not $k.-->
            <xsl:variable name="pre_n">
                <xsl:value-of select="marc:subfield[@code = 'n'][1]/preceding-sibling::*[1]/@code" />
            </xsl:variable>

            <xsl:for-each select="marc:subfield">
                <xsl:if test="@code = 'a' or @code = 'b' or @code = 'c' or @code='d' or (@code='n' and not($pre_n = 't') and not($pre_n = 'k'))">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$t167_tens = '11'">
            <!-- Get the @code preceding a $n and use that code to test for not $t and not $k.-->
            <xsl:variable name="pre_n">
                <xsl:value-of select="marc:subfield[@code = 'n'][1]/preceding-sibling::*[1]/@code" />
            </xsl:variable>

            <xsl:for-each select="marc:subfield">
                <xsl:if test="@code = 'a' or @code = 'c' or @code = 'd' or @code='e' or @code='q' or @code='n'">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template> <!-- end tpt_name_entry -->


    <xsl:template name="tpt_mods" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="all_xx"/>
        <xsl:param name="agency_info"/>
        <!--
            We assume that we have at least one 1xx or 7xx name in
            $all_xx/container/ename. Title from MARC 245 (all subfields
            except $6 and $8). If 245 lacks $f and $g then append space 260
            $c (Doing the usual "if present" test first.)
        -->
        <xsl:variable name="title">
            <xsl:for-each select="marc:datafield[@tag = '245']/marc:subfield[not(@code = '6') and not(@code = '8')]">
                <xsl:if test="not(position() = 1)">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="."/>
            </xsl:for-each>
            <xsl:if
                test="boolean(marc:datafield[@tag = '260']/marc:subfield[@code = 'c']) and
                      boolean(marc:datafield[@tag = '245']/marc:subfield[not(@code = 'f') and
                      not(@code = 'g')])">
                <xsl:text> </xsl:text>
                <xsl:value-of select="marc:datafield[@tag = '260']/marc:subfield[@code = 'c']"/>
            </xsl:if>
        </xsl:variable>

        <!-- 
             In the code below, we include an e_name in the MODS <name> if it is 1xx or
             is_creator(). It turns out that over in tpt_all_xx (lib.xsl) we set is_creator true
             for 7xx, or for a 6xx that is a duplicate of a 7xx. tpt_all_xx also sets is_creator
             for 1xx, and while that is probably redundant, is it consistent. In the code below
             we could probably use is_creator or match against [17]xx and get the same
             effect. This all seems somewhat un-robust, but it was necessary as a workaround to
             completely rewriting tpt_all_xx.
        -->
	<xsl:element name="objectXMLWrap" xmlns:eac="urn:isbn:1-931666-33-4">
            <mods xmlns="http://www.loc.gov/mods/v3">
                <xsl:for-each select="$all_xx/eac:container/eac:e_name[matches(@tag, '1(00|10|11)') or @is_creator=true()]">
                    <name>
                        <namePart><xsl:value-of select="."/></namePart>
                        <role>
                            <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
                        </role>
                    </name>
                </xsl:for-each>
                <titleInfo>
                    <title><xsl:value-of select="$title"/></title>
                </titleInfo>
                <xsl:if test="count(marc:datafield[@tag = '520']/marc:subfield[@code = 'a']) >= 1">
                    <abstract>
                        <xsl:for-each select="marc:datafield[@tag = '520']/marc:subfield[@code = 'a']">
                            <xsl:value-of select="."/>
                            <xsl:text> </xsl:text>
                        </xsl:for-each>
                    </abstract>
                </xsl:if>
                <xsl:if test="string-length($agency_info/eac:agencyName) > 0">
                    <name>
                        <namePart><xsl:value-of select="$agency_info/eac:agencyName"/></namePart>
                        <role>
                            <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/rps">Repository</roleTerm>
                        </role>
                    </name>
                </xsl:if>
            </mods>
        </xsl:element>
    </xsl:template> <!-- end tpt_mods -->


    <xsl:template name="tpt_agency_info" xmlns="urn:isbn:1-931666-33-4" >
        <!-- 
             If there is a single marc query result then use it. When there are two or more records for a given
             orig_query, use literal "OCLC" for org code, no name, and add a descriptive note. When no result,
             no org code, name is original query, add descriptive note. The only allowed attribute is
             localType so use span tags inside p for all the data. Elements p and descptiveNote do not allow
             localType, so everything must be in span.
        -->
        <xsl:variable name="org_query" select="normalize-space(marc:datafield[@tag='040']/marc:subfield[@code='a'])"/>

        <!-- 
             $ainfo must be created with copy-of and not the selected attribute shortcut because the shortcut
             prevents selecting each container separately. Don't know why. The code below works, so use it.
        -->
        <xsl:variable name="ainfo">
            <xsl:copy-of select="$org_codes/snac:container[snac:orig_query = $org_query]"/>
        </xsl:variable>
        
        <xsl:variable name="fallback_code">
            <!-- 
                 If the original 040$a aka $org_query is conservatively safe for use as a filename, then use
                 it as our fallback agency code. A small number of 040$a values are wacky, and can't be used
                 as filenames. And / is not ok, so we have to fix that if we find one.
                 
                 http://www.bs.dk/isil/structure.htm
                 [A-Za-z0-9\-\/:]
            -->
            <xsl:choose>
                <xsl:when test="matches($org_query, '^[A-Z\-]+$', 'i')">
                    <xsl:value-of select="lib:fn-safe($org_query)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$fallback_default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($ainfo/snac:container)=1 and string-length($ainfo/snac:container/snac:isil)>0">
                <agencyCode >
                    <!--
                        We have ISIL codes from OCLC with things like # in them, and the standard allows /, so
                        munge any stuff not compatible with file names into 3 character decimal numeric
                        strings. # becomes 035 and / becomes 047. So OCLC-4X# becomes OCLC-4X035. Ugly, but
                        a valid file name. Hex might be better, but XSLT doesn't have a native hex conversion,
                        as far as I can tell.
                    -->
                    <xsl:value-of select="lib:fn-safe($ainfo/snac:container/snac:isil)"/>
                </agencyCode>
                <agencyName >
                    <xsl:value-of select="$ainfo/snac:container/snac:name"/>
                </agencyName>
            </xsl:when>
            <xsl:when test="count($ainfo/snac:container)>1">
                <agencyCode>
                    <xsl:value-of select="$fallback_code"/>
                </agencyCode>
                <agencyName>
                    <xsl:text>Unknown</xsl:text>
                </agencyName>
                <descriptiveNote>
                    <xsl:for-each select="$ainfo/snac:container">
                        <p>
                            <span localType="snac:multipleRegistryResults"/>
                            <span localType="snac:original"><xsl:value-of select="$org_query"/></span>
                            <span localType="snac:inst"><xsl:value-of select="snac:name"/></span>
                            <span localType="snac:isil"><xsl:value-of select="snac:isil"/></span>
                        </p>
                    </xsl:for-each>
                </descriptiveNote>
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    There is some crazy stuff in $org_query. Will it all validate in CPF? Use "EAC-CPF" as a
                    placeholder for unknown agency codes.
                -->
                <agencyCode >
                    <xsl:value-of select="$fallback_code"/>
                </agencyCode>
                <agencyName>
                    <xsl:text>Unknown</xsl:text>
                </agencyName>
                    <descriptiveNote >
                        <p>
                            <span localType="snac:noRegistryResults"/>
                            <span localType="snac:original">
                                <xsl:value-of select="$org_query"/>
                            </span>
                        </p>
                    </descriptiveNote>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="tpt_tag_545" xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             biogHist. Remove newlines. After some discussion, we're keeping all
             the subfields.  Historically, that this only used the 545$a (which
             could be repeating), so if there were any 545$b they would have
             been ignored (lost).
        -->
        <!-- <xsl:for-each select="marc:datafield[@tag='545']/marc:subfield[@code='a']" > -->
        <xsl:for-each select="marc:datafield[@tag='545']/marc:subfield" >
            <p>
                <xsl:value-of select="normalize-space(replace(self::node(), '&#x0A;', ''))"/>
            </p>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_all_xx" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="record_id"/>
        <xsl:param name="index"/>
        <xsl:param name="tag"/>
        <xsl:param name="curr" /><!-- forcing data type seems to be optional as="node()*" -->
        <xsl:param name="unique_count" as="xs:integer"/>
        <xsl:param name="record_position"/>
        <xsl:param name="creator_info"/>
        <xsl:param name="status"/>
        <!-- 
             Recurse over all the [167]xx records creating a var containing a node set we will eventually use
             to create potentially multiple output files. We de-duplicate (dedupe) during the recursion by
             checking the current value against values we have already accumulated. Unfortunately, this
             recusive algorithm prevents us from looking ahead for things like a 700 record to use as a
             creatorOf arcrole. The non-recursive method with post-node-set-creation de-duplication is more
             flexible.
             
             Var $df is working because the context is the original record for all depths of recursion. (At
             least in this case since we don't change the context.)
             
             http://stackoverflow.com/questions/10324122/explicitly-typed-variables-in-xsl
             XSLT 1.0 does not have explicit types for variables and params. XTLT 2.0 uses the "as" attribute.
             
             This template generates info that is destined for output, so it is explicitly in the eac
             namespace, which means that $all_xx is in the eac namespace.
        -->
        <xsl:variable name="df">
            <xsl:copy-of
                select="marc:datafield[@tag='100' or
                        @tag='110' or @tag='111' or
                        @tag='600' or @tag='610' or
                        @tag='611' or @tag='700' or
                        @tag='710' or @tag='711'][$index]"/>
        </xsl:variable>

        <!-- <xsl:message> -->
        <!--     <xsl:text>df: </xsl:text> -->
        <!--     <xsl:apply-templates mode="copy-no-ns" select="$df"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!--     <xsl:text>tag: </xsl:text> -->
        <!--     <xsl:value-of select="$df/marc:datafield/@tag"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->
        
        <xsl:choose>
            <xsl:when test="string($df) and matches($df/marc:datafield/marc:subfield[@code='a'][1], '[A-Za-z0-9]+')">
                <!--
                    We need to have some value in $df, and it needs to include
                    some alpha numeric values. A single comma as the value is
                    not good. There is at least one 700$a that is "," and that
                    kind of thing upsets XSLT's regex engine, and is not a sensible name entry.
                    
                    Build the full name entity name entry. Use for-each to set
                    $df as the context. tpt_name_entry relies on the context.
                -->
                <xsl:variable name="ne_temp">
                    <xsl:for-each select="$df/marc:datafield">
                        <xsl:call-template name="tpt_name_entry">
                            <xsl:with-param name="xx_tag" select="$tag"/>
                            <xsl:with-param name="record_position" select="$record_position"/>
                            <xsl:with-param name="record_id" select="$record_id"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:variable>

                <!-- Determine the entity type. -->
                <xsl:variable name="temp_et">
                    <xsl:call-template name="tpt_entity_type">
                        <xsl:with-param name="df">
                            <xsl:copy-of select="$df"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- 
                     New: count of unique entries is totally separate from position().
                -->
                <xsl:variable name="fn_suffix">
                    <xsl:call-template name="tpt_file_suffix">
                        <xsl:with-param name="xx_tag" select="$df/marc:datafield/@tag"/>
                        <xsl:with-param name="count" select="$unique_count - 1"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="expanded_suffix">
                    <xsl:call-template name="tpt_expanded_suffix">
                        <xsl:with-param name="xx_tag" select="$df/marc:datafield/@tag"/>
                        <xsl:with-param name="count" select="$unique_count - 1"/>
                        <xsl:with-param name="status" select="$status"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!--
                    Mnemonic for "entity type first capital" since the http://RDVocab.info/uri/schema/FRBRentitiesRDA/ uses
                    first letter capitalization.
                -->
                <xsl:variable name="entity_type_fc">
                    <xsl:if test="$temp_et = 'person'">
                        <xsl:text>Person</xsl:text>
                    </xsl:if>
                    <xsl:if test="$temp_et = 'family'">
                        <xsl:text>Family</xsl:text>
                    </xsl:if>
                    <xsl:if test="$temp_et = 'corporateBody'">
                        <xsl:text>CorporateBody</xsl:text>
                    </xsl:if>
                </xsl:variable>
                
                <xsl:variable name="occupation">
                    <xsl:call-template name="tpt_occupation">
                        <xsl:with-param name="df" select="$df"/>
                    </xsl:call-template>
                </xsl:variable>
                 
                <xsl:variable name="function">
                    <xsl:call-template name="tpt_function">
                        <xsl:with-param name="df" select="$df"/>
                    </xsl:call-template>
                </xsl:variable>
                
                
                <xsl:variable name="temp_node">
                    <!-- 
                         See variable creator_info in oclc_marc2cpf.xsl. There can be non-7xx duplicate
                         names. Changing the de-duplicating code here would require a full rewrite of
                         tpt_all_xx, so when there is a matching 7xx, I just mark the first occurance (whether
                         6xx or 7xx) as is_creator="true()", no matter what the $df tag value. Also, if the
                         current tag is 7xx, then is_creator="true()".
                         
                         We can only parse a single date, so (implicitly) concat all 245$f by using
                         xsl:value-of. If there is only one, it will probably parse. Two dates are used as
                         fromDate and toDate, and multiple are parsed for min fromDate and max toDate. See
                         tpt_parse_alt.
                    -->
                    <xsl:variable name="alt_date">
                        <xsl:value-of select="marc:datafield[@tag = '245']/marc:subfield[@code = 'f']"/>
                    </xsl:variable>

                    <!--
                        Namespace for the scope of the current template is eac due to xmlns attr in opening
                        template element above.
                    -->
                    <container> 
                        <e_name>
                            <xsl:attribute name="tag" select="$df/marc:datafield/@tag"/>
                            <xsl:attribute name="record_id" select="$record_id"/>
                            <xsl:attribute name="entity_type" select="$temp_et"/>
                            <xsl:attribute name="entity_type_fc" select="$entity_type_fc"/>
                            <xsl:attribute name="fn_suffix" select="$fn_suffix"/>
                            <xsl:attribute name="expanded_suffix" select="$expanded_suffix"/>
                            <xsl:attribute name="is_creator">
                                <xsl:choose>
                                    <xsl:when test="lib:pname-match($creator_info/marc:creator_name, $ne_temp)">
                                        <xsl:value-of  select="true()"/>
                                    </xsl:when>
                                    <xsl:when test="$df/marc:datafield[matches(@tag, '[17]{1}(00|10|11)')]">
                                        <xsl:value-of  select="true()"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="false()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:value-of select="normalize-space($ne_temp)"/>
                        </e_name>
                        <occ>
                            <xsl:copy-of select="$occupation"/>
                        </occ>

                        <func>
                            <xsl:copy-of select="$function"/>
                        </func>

                        <xsl:copy-of select="lib:edate_core($record_id, $record_position, $temp_et, $df, $alt_date)"/>

                        <subordinateAgency>
		            <xsl:for-each select="marc:datafield[@tag='774']">
		                <xsl:if test="matches(marc:subfield[@code='o'],'\(SIA\sAH\d+\)')">
			            <xsl:copy-of select="."/>
		                </xsl:if>
		            </xsl:for-each>
                        </subordinateAgency>

	                <earlierLaterEntries>
		            <xsl:for-each select="marc:datafield[@tag='780' or @tag='785']">
		                <xsl:copy-of select="."/>
		            </xsl:for-each>
                        </earlierLaterEntries>
                    </container>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:variable>
                <!-- 
                     Return either true or false, explicitly. In order to get the
                     $unique_count working, we need a variable to carry the
                     unique-ness due to scoping problems. Failure to explicitly
                     type cast is_unique_flag to boolean will cause all tests
                     against it to be evaluated as strings, even though it is being
                     assigned a boolean value. test="" will silently evaluate its
                     argument, often contrary to how testing variables works in
                     other programming languages.
                     
                     Must check for zero length strings first, or we get a data
                     type error. If (not ( $curr and $curr already has the value
                     of $temp_node)) then add $temp_node to our node set. In
                     other words, if $curr is empty then add $temp_node. If
                     $temp_node is not a duplicate then add $temp_node.
                     
                     XPTY0019: Required item type of first operand of '/' is
                     node(); supplied value has item type xs:string
                     
                     New: Use regex matches() to do case insensitive
                     comparison. Escape the regular expression (the second arg)
                     since things like . / - [ ] ( ) etc. in a string are regex
                     special characters. If we only wanted lower-case() matching, we
                     could lower-case() both arguments. In this instance we want a
                     special name/puncutation match, so this demonstrates how we can
                     do regex matching. This may be about the same speed as
                     lower-casing both strings and then comparing.
                     
                     Note that we must use the eac: namespace here with $curr and $temp_node since all_xx is
                     explicitly in the eac namespace.
                -->
                
                <xsl:variable name="is_unique_flag" as="xs:boolean" >
                    <xsl:choose>
                        <xsl:when test="not(boolean($curr))">
                            <xsl:value-of select="true()"/>
                        </xsl:when>
                        <xsl:when
                            test="$curr/eac:container/eac:e_name[lib:pname-match(text(), $temp_node/eac:container/eac:e_name/text())]">
                            <!-- skip a duplicate -->
                            <xsl:value-of select="false()"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="true()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="new_uc">
                    <xsl:choose>
                        <xsl:when test="$is_unique_flag">
                            <xsl:value-of select="$unique_count + 1"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$unique_count"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="new_curr">
                    <xsl:copy-of select="$curr"/>
                    <xsl:if test="boolean($is_unique_flag)">
                        <xsl:copy-of select="$temp_node"/>
                    </xsl:if>
                </xsl:variable>

                <!--
                    Recurse. Use "as" to be sure that curr and
                    unique_count have the proper type. The default
                    behavior seems to be to convert anything to a string,
                    rather than using the thing's data type.
                -->
                <xsl:call-template name="tpt_all_xx">
                    <xsl:with-param name="record_id" select="$record_id"/>
                    <xsl:with-param name="index" select="$index+1"/>
                    <xsl:with-param name="tag" select="$tag"/>
                    <xsl:with-param name="curr" as="node()*">
                        <xsl:copy-of select="$new_curr"/>
                    </xsl:with-param>
                    <xsl:with-param name="unique_count" select="$new_uc" as="xs:integer"/>
                    <xsl:with-param name="record_position" select="$record_position"/>
                    <xsl:with-param name="creator_info" select="$creator_info"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- 
                     When we run out of Zxx datafields, stop recursing (by not
                     calling template tpt_all_xx) and return a copy of $curr
                     which we have been building all along through the
                     recursion.
                -->
                <xsl:copy-of select="$curr"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- end tpt_all_xx -->
      
      
    <xsl:function name="lib:date_cat" as="xs:string" >
        <xsl:param name="date" as="xs:string?"/> 
        <xsl:param name="cat" as="xs:string?"/> 
        <xsl:sequence select="concat(substring($date, 1, string-length($date) - string-length($cat)), $cat)"/>
    </xsl:function>


    <xsl:template name="tpt_parse_alt" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="alt_date" as="xs:string?"/> 
        <!-- 
             Use a much simpler date parsing that looks for 1 or 2 \d{4} (four digit) numbers and uses them as
             active year values. Because this is called from inside lib:edate_core, we need to return a
             typical token node list, but with <odate is_alt="1">. Back in lib:edate_core the final
             token-to-date pass is tpt_pa_3 for this data (normal dates go through tpt_show_date). One
             difference is that here we're using the eac: namespace (prefix), based on the reasoning that we
             are creating output (and our new-found dedication to always using explicit namespaces because
             otherwise namespaces are prone to extreme time wasting and frustration). The other date parser
             uses the implicit current namespace which is apparently marc:, but could be lib:.
        -->

        <xsl:variable name="pass_1">
            <xsl:call-template name="tpt_pa_1">
                <xsl:with-param name="alt_date" select="$alt_date"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="pass_2">
        <xsl:call-template name="tpt_pa_2">
            <xsl:with-param name="tokens" select="$pass_1"/>
        </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="tpt_pa_21">
            <xsl:with-param name="tokens" select="$pass_2"/>
        </xsl:call-template>
        
        <!-- Return tokens from the last pass. final parsing is called from back in lib:edate_core -->
    </xsl:template>

    <xsl:template name="tpt_pa_3" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tokens" as="node()*"/> 
        <xsl:choose>
            <xsl:when test="count($tokens/eac:tok[matches(., '\d{4}')]) = 1">
                <xsl:variable name="local_date">
                    <xsl:copy-of select="$tokens/eac:tok[matches(., '\d{4}')]"/>
                </xsl:variable>
                <existDates>
                    <date localType="snac:active" standardDate="{format-number($local_date, '0000')}">
                        <xsl:text>active </xsl:text>
                        <xsl:if test="$local_date/eac:tok[@approx = 1]">
                            <xsl:text>approximately </xsl:text>
                        </xsl:if>
                        <xsl:value-of select="format-number($local_date, '0000')"/>
                    </date>
                </existDates>
            </xsl:when>

            <xsl:when test="count($tokens/eac:tok[matches(., '\d{4}')]) = 2">
                <xsl:variable name="local_date">
                    <xsl:copy-of select="$tokens/eac:tok[matches(., '\d{4}')]"/>
                </xsl:variable>
                <existDates>
                    <dateRange>
                        <fromDate localType="snac:active" standardDate="{format-number($local_date/eac:tok[1], '0000')}">
                            <xsl:text>active </xsl:text>
                            <xsl:if test="$local_date/eac:tok[1][@approx = 1]">
                                <xsl:text>approximately </xsl:text>
                            </xsl:if>
                            <xsl:value-of select="format-number($local_date/eac:tok[1], '0000')"/>
                        </fromDate>
                        <toDate localType="snac:active" standardDate="{format-number($local_date/eac:tok[2], '0000')}">
                            <xsl:text>active </xsl:text>
                            <xsl:if test="$local_date/eac:tok[2][@approx = 1]">
                                <xsl:text>approximately </xsl:text>
                            </xsl:if>
                            <xsl:value-of select="format-number($local_date/eac:tok[2], '0000')"/>
                        </toDate>
                    </dateRange>
                </existDates>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_pa_21" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             If we have more than 2 four digit numbers, then only keep the min and max. Because min and max
             will change numeric strings into double, we have to cast the numbers back to strings in order to
             compare them to the text of the (implied) context node. Extra tokens are discarded. It seems nice
             to separate them with a hyphen token, but it will/should never be used.
        -->
        <xsl:copy-of select="$tokens/eac:odate"/>
        <xsl:copy-of select="$tokens/eac:untok"/>
        <xsl:choose>
            <xsl:when test="count($tokens/eac:tok[matches(., '\d{4}')]) > 2">
                <xsl:copy-of select="$tokens/eac:tok[text() = xs:string(min($tokens/eac:tok[matches(., '\d{4}')]))]"/>
                <tok>-</tok>
                <xsl:copy-of select="$tokens/eac:tok[text() = xs:string(max($tokens/eac:tok[matches(., '\d{4}')]))]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$tokens/eac:tok"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_pa_2" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Normalize token ca to attribute "approx"
        -->
        <xsl:copy-of select="$tokens/eac:odate"/>
        <xsl:copy-of select="$tokens/eac:untok"/>
        <xsl:for-each select="$tokens/eac:tok">
            <xsl:choose>
                <xsl:when test="matches(., '\d{4}') and
                                (following-sibling::eac:tok[1][matches(text(), 'ca')] or
                                preceding-sibling::eac:tok[1][matches(text(), 'ca')])">
                    <untok approx="1">
                        <xsl:value-of select="."/>
                    </untok>
                </xsl:when>

                <xsl:when test="matches(., 'ca')">
                    <!-- Don't copy; this becomes part of and an adjacent token. -->
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_pa_1" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="alt_date" as="xs:string?"/> 
        <!-- Tokenize alt dates. Similar to lib:tokenize -->
        <odate is_alt="1">
            <xsl:value-of select="lower-case(normalize-space($alt_date))"/>
        </odate>
        <xsl:analyze-string select="$alt_date"
                            regex="([ ;/,\.\-\?:\(\)\[\]]+)|([^ ;/,\.\-\?:\(\)\[\]]+)">
            <xsl:matching-substring>
                <xsl:choose>

                    <xsl:when test="matches(regex-group(1), '-') or matches(regex-group(1), '\?')">
                        <!--
                            Date separators can be '?', '-', or '?-' so we need a couple of if
                            statements. Note that the '?' if statement must be first. We do not support '-?'
                            because it seems wrong. It could be accomodated by creating tokens in order with a
                            for-each based on the chars in regex-group(1).
                        -->
                        <xsl:if test="matches(regex-group(1), '\?')">
                            <tok>?</tok>
                        </xsl:if>
                        <xsl:if  test="matches(regex-group(1), '-')">
                            <tok>-</tok>
                        </xsl:if>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(1), '/')">
                        <tok>or</tok>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(2), '\d+s')">
                        <!--
                            There was a time when we didn't like 1800s 1940s or any number with "s" on the
                            end, but now we try to parse them.
                        -->
                        <tok>
                            <xsl:value-of select="regex-group(2)"/>
                        </tok>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(2), 'approx')">
                        <!--
                            This is not a keyword, but simply a normalized token. The token is 'approx'. Do
                            not change to 'approximately' unless you are prepared to change and fix all the
                            other code relying on 'approx'. In fact, if you want to change it, change it to
                            'aprx_tok' or something distinctly token-ish.
                        -->
                        <tok>approx</tok>
                    </xsl:when>

                    <xsl:when test="string-length(regex-group(2)) > 0">
                        <tok>
                            <xsl:value-of select="lower-case(normalize-space(regex-group(2)))"/>
                        </tok>
                    </xsl:when>

                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <untok>
                    <xsl:value-of select="normalize-space(.)"/>
                </untok>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <xsl:function name="lib:tokenize">
        <xsl:param name="subfield_d" as="xs:string?"/> 
        <!--
            For the purposes of initial tokenizing, everything is either separator or not-separator. If
            separator matches '-' then create a "-" token. If separator matches '/' then create an "or"
            token. "1601/2" is conceptually "1601 or 2". If - or / occur in some other context, bad things may
            happen. All other separators are discarded.
        -->
        <xsl:element name="odate">
            <xsl:value-of select="lower-case(normalize-space($subfield_d))"/>
        </xsl:element>
        <xsl:analyze-string select="$subfield_d"
                            regex="([ ;/,\.\-\?:\(\)\[\]]+)|([^ ;/,\.\-\?:\(\)\[\]]+)">
            <xsl:matching-substring>
                <xsl:choose>

                    <xsl:when test="matches(regex-group(1), '-') or matches(regex-group(1), '\?')">
                        <!--
                            Separators can be '?', '-', or '?-' so we need a couple of if statements. Note
                            that the '?' if statement must be first. We do not support '-?'  because it seems
                            wrong. It could be accomodated by creating tokens in order with a for-each based
                            on the chars in regex-group(1).
                        -->
                        <xsl:if test="matches(regex-group(1), '\?')">
                            <xsl:element name="tok">?</xsl:element>
                        </xsl:if>
                        <xsl:if  test="matches(regex-group(1), '-')">
                            <xsl:element name="tok">-</xsl:element>
                        </xsl:if>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(1), '/')">
                        <xsl:element name="tok">or</xsl:element>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(2), 'approx')">
                        <!--
                            This is not a keyword, but simply a normalized token. The token is 'approx'. Do
                            not change to 'approximately' unless you are prepared to change and fix all the
                            other code relying on 'approx'. In fact, if you want to change it, change it to
                            'aprx_tok' or something distinctly token-ish.
                        -->
                        <xsl:element name="tok">approx</xsl:element>
                    </xsl:when>

                    <xsl:when test="string-length(regex-group(2)) > 0">
                        <!-- <tok> -->
                        <xsl:element name="tok">
                            <xsl:value-of select="lower-case(normalize-space(regex-group(2)))"/>
                        </xsl:element>
                        <!-- </tok> -->
                    </xsl:when>

                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:element name="untok">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function> <!-- end lib:tokenize -->


    <xsl:function name="lib:pass_1b">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Disambiguate (normal "or") and ("century or") by making ("century or") into a token "cyr".
        -->
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <xsl:for-each select="$tokens/tok">
            <xsl:choose>

                <xsl:when test="text() = 'or' and following-sibling::tok[matches(text(), 'cent')]">
                    <xsl:element name="tok">
                        <xsl:text>cyr</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="lib:pass_2">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Process NNNNs (1870s) and "or N".
        -->
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <xsl:for-each select="$tokens/tok">
            <xsl:variable name="p_tok"
                          select="preceding-sibling::tok[1]"/>
            <xsl:variable name="f_tok"
                          select="following-sibling::tok[1]"/>

            <xsl:choose>

                <!-- Make sure this won't match 1st -->
                <xsl:when test="matches(., '\d+s$')">
                    <xsl:analyze-string select="."
                                        regex="(\d+)s">
                        <xsl:matching-substring>
                            <tok>
                                <xsl:attribute name="notBefore"><xsl:value-of select="lib:min_ess(regex-group(1))"/></xsl:attribute>
                                <xsl:attribute name="notAfter"><xsl:value-of select="lib:max_ess(regex-group(1))"/></xsl:attribute>
                                <xsl:attribute name="sep"><xsl:text>s</xsl:text></xsl:attribute>
                                <xsl:attribute name="std" select="format-number(lib:min_ess(regex-group(1)), '0000')"/>
                                <xsl:attribute name="val" select="format-number(lib:min_ess(regex-group(1)), '0000')"/>
                                <xsl:text>num</xsl:text>
                            </tok>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>

                <xsl:when test="$f_tok = 'or'">
                    <!-- if following is '-' (or whatever) we want that since it is used during analysis later. -->
                    <xsl:variable name="or_date"
                                  select="format-number(number(lib:date_cat(text(), following-sibling::tok[2])), '0000')"/>
                    <tok>
                        <xsl:attribute name="notBefore"><xsl:value-of select="."/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="$or_date"/></xsl:attribute>
                        <!-- <xsl:attribute name="sep"><xsl:value-of select="concat('or ', following-sibling::tok[2])"/></xsl:attribute> -->
                        <xsl:attribute name="sep"><xsl:value-of select="concat(' or ', $or_date)"/></xsl:attribute>
                        <xsl:attribute name="std" select="format-number(., '0000')"/>
                        <xsl:attribute name="val" select="format-number(., '0000')"/>
                        <xsl:text>num</xsl:text>
                    </tok>
                </xsl:when>

                <xsl:when test="($p_tok = 'or') or (text() = 'or')">
                    <!--
                        Does first preceding tok match 'or'? For example "or 2"
                        and this is token "2". If so, we processed this already
                        so we do not want to see it again. Same if this token
                        matches 'or'. 
                    -->
                </xsl:when>

                <xsl:when test="$f_tok = '?'">
                    <!-- If the following token is ? then do a date range. -->
                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="number(.) -1"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="number(.) + 1"/></xsl:attribute>
                        <!-- <xsl:attribute name="sep"><xsl:value-of select="'?'"/></xsl:attribute> -->
                        <xsl:attribute name="std" select="format-number(., '0000')"/>
                        <xsl:attribute name="val" select="format-number(., '0000')"/>
                        <xsl:text>num</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = '?'">
                    <!--
                        ? tokens have already been processed so throw them away.
                    -->
                </xsl:when>

                <xsl:when test="$p_tok = 'ca' or $p_tok = 'c' or $p_tok = 'circa' or $f_tok = 'approx'">
                    <!--
                        If the preceding token is circa (in any form) then +3 -3
                        date range. Ditto if following token is 'approx'. If the
                        following token is 'approx' then insert a 'circa' token
                        before our date so this date will be just like a normal
                        circa date.
                    -->
                    <xsl:if test="$f_tok = 'approx'">
                        <xsl:element name="tok">
                            <xsl:text>approximately</xsl:text>
                        </xsl:element>
                    </xsl:if>
                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="number(.) - 3"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="number(.) + 3"/></xsl:attribute>
                        <xsl:attribute name="std" select="format-number(., '0000')"/>
                        <xsl:attribute name="val" select="format-number(., '0000')"/>
                        <xsl:text>num</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = 'approx'">
                    <!--
                        Do nothing for approx since they will be converted into
                        leading 'approximately' tokens by the code above.
                    -->
                </xsl:when>

                <xsl:when test="text() = 'ca' or text() = 'c' or text() = 'circa'">
                    <xsl:element name="tok">
                        <xsl:text>approximately</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="matches(., 'fl', 'i')">
                    <xsl:element name="tok">
                        <xsl:value-of select="'active'"/>
                    </xsl:element>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
                        
    <xsl:function name="lib:pass_3">
        <xsl:param name="tokens" as="node()*"/> 
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <!--
            This is a parsing pass to deal with ordinal century values. As far as I know, rdinals only occur
            in reference to century dates.  New: "1st/2nd century" and "1st century - 2nd century" and
            "1st-2nd century" all mean fromDate=1st toDate=2nd. See old_pass_3 for the previous code.
        -->
        <xsl:variable name="has_century">
            <xsl:if test="$tokens/tok = 'century'">
                <xsl:value-of select="true()"/>
            </xsl:if>
        </xsl:variable>

        <xsl:for-each select="$tokens/tok">
            <xsl:choose> 
                <xsl:when test="matches(text(), '\d+(st|nd|rd|th)') and $has_century">
                    <xsl:variable name="cent1"
                        select="lib:ordinal_number(text())"/>
                    <!--
                        The algebraic formula is only slightly confusing. In XSLT "/" is a path and "div" is
                        the division operator. No division here.
                    -->
                    <tok>
                        <xsl:attribute name="notBefore"><xsl:value-of select="(($cent1/num -1) * 100) + 1"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="$cent1/num * 100"/></xsl:attribute>
                        <xsl:attribute name="std" select="format-number((($cent1/num -1) * 100) + 1, '0000')"/>
                        <!-- Don't format-number for val since this is 1st, 2nd, etc. -->
                        <xsl:attribute name="val" select="concat(., ' century')"/>
                        <xsl:text>num</xsl:text>
                    </tok>
                </xsl:when>

                <!--
                    cyr becomes - (hyphen) since this is a date range "nnnn - nnnn", not a "nnnn or
                    nnnn". Later parsing phases treat "-" tokens very differently from "cyr" or "or" tokens,
                    so we're setting up the tokens to get the parse result we want.
                 -->
                <xsl:when test="text() = 'cyr'">
                    <tok>-</tok>
                </xsl:when>

                <xsl:when test="matches(text(), 'cent')">
                    <!-- nothing, skip -->
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="lib:pass_4">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Turn all fully numeric tokens into @std, @val, and tok element value 'num'.
        -->
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <xsl:for-each select="$tokens/tok">
            <xsl:choose>

                <xsl:when test="matches(text(), '^\d+$')">
                    <tok std="{format-number(., '0000')}" val="{format-number(., '0000')}">
                        <xsl:text>num</xsl:text>
                    </tok>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>



    <xsl:function name="lib:old_pass_3">
        <xsl:param name="tokens" as="node()*"/> 
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>

        <xsl:for-each select="$tokens/tok">
            <xsl:choose> 
                <!--
                    We stopped using this mar 20 2013. This parsing function implements the old view. Dates
                    "1st/2nd" and "1st - 2nd" meant a single date 1st through 2nd. I'm leaving the code here
                    in case we ever want this behavior for some reason, and for historical reference.

                    Remember that "cyr" is the token for "century or" as "1st century or 2nd century", usually
                    a "/" char in the original string "1st/2nd century"
                    
                -->
                <xsl:when test="matches(text(),
                                '\d+(st|nd|rd|th)') and following-sibling::tok[1] = 'cyr' and matches(following-sibling::tok[2],
                                '\d+(st|nd|rd|th)')">
                    <xsl:variable name="cent1"
                        select="lib:ordinal_number(text())"/>
                    
                    <xsl:variable name="cent2"
                        select="lib:ordinal_number(following-sibling::tok[2])"/>
                    
                    <!--
                        The algebraic formula is only slightly confusing. In XSLT "/" is a path and "div" is the
                        division operator. No division here.
                    -->

                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="(($cent1/num -1) * 100) + 1"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="$cent2/num * 100"/></xsl:attribute>
                        <xsl:value-of select="concat($cent1/num, $cent1/suffix)"/>
                        <xsl:value-of select="concat('/', $cent2/num, $cent2/suffix)"/>
                        <xsl:value-of select="' century'"/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = 'cyr' or preceding-sibling::tok[1] = 'cyr'">
                    <!-- Skip, ignore. This is ignoring the "cyr" token as well
                         as the following token. If the tokens are 19th, cyr,
                         20th, we utilize cyr and 20th in other steps, so we
                         ignore them here. -->
                </xsl:when>

                <xsl:when test="matches(text(), '\d+(st|nd|rd|th)') and matches(following-sibling::tok[1], 'cent')">
                    <xsl:analyze-string select="text()"
                                        regex="(\d+)(st|nd|rd|th)">
                        <xsl:matching-substring>
                            <xsl:variable name="cent">
                                <xsl:value-of select="number(regex-group(1))"/>
                            </xsl:variable>
                            <xsl:element name="tok">
                                <xsl:attribute name="notBefore"><xsl:value-of select="(($cent -1) * 100) + 1"/></xsl:attribute>
                                <xsl:attribute name="notAfter"><xsl:value-of select="$cent * 100"/></xsl:attribute>
                                <xsl:value-of select="concat($cent, regex-group(2), ' century')"/>
                            </xsl:element>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>

                <xsl:when test="matches(text(), 'cent')">
                    <!-- nothing, skip -->
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>




    <xsl:function name="lib:ordinal_number">
        <xsl:param name="date" as="xs:string?"/>
        <!--
            Get the digits from 1st 2nd 3rd 4th, etc. Must have an outer element
            or xpath for the inner elements is tricky. For input "20th" output
            is <ord><num>20</num><suffix>th</suffix></ord>.
        -->
        <xsl:analyze-string select="$date" regex="(\d+)(.*)">
            <xsl:matching-substring>
                <xsl:element name="ord">
                    <xsl:element name="num">
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:element>
                    <xsl:element name="suffix">
                        <xsl:value-of select="regex-group(2)"/>
                    </xsl:element>
                </xsl:element>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>


    <xsl:function name="lib:min_ess" as="xs:integer">
        <xsl:param name="date"/>
        <!--
            Return the minimum number for 1800s. This is trivial now, but it
            seems like it might need future complexity, so it is here in a
            function. Companion to max_ess() below.
        -->
        <xsl:value-of select="$date"/>
    </xsl:function>


    <xsl:function name="lib:max_ess" as="xs:integer">
        <xsl:param name="date"/>
        <!--
            Return the max number for 1800s. For now we only handle 100s or 10s, for example 1800s or
            1820s. Companion to min_ess() above. Returning zero upon failure is dubious, and I don't think it
            will ever happen. Saxon 8 didn't care, but 9he knows when there's no xsl:otherwise.
        -->
        <xsl:choose>
            <xsl:when test="(number($date) mod 100) = 0">
                <xsl:value-of select="number($date) + 99"/>
            </xsl:when>
            <xsl:when test="(number($date) mod 10) = 0">
                <xsl:value-of select="number($date) + 9"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:template mode="copy-no-ns" match="*" >
        <!--
            Print elements withtout the pesky namespace. This is mostly for
            debugging where the namespace is just extraneous text that
            interferes with legibility. Seems that we need to replace this line to
            prevent namespace from printing.  <xsl:element name="{name(.)}"
            namespace="{namespace-uri(.)}">

            Using local-name() works way better than name(). In fact, if you ask
            this template to print something with a namespace unknown to this
            file, it throws an error when using name().

            Interestingly, having a namespace such as the following in the
            stylesheet header causes that namespace to output regardless of the
            tricks below.
            
            xmlns="http://www.loc.gov/MARC21/slim"

            Also interesting is that if we put xmlns="urn:isbn:1-931666-33-4"
            into the opening template element above, that problem goes
            away. Putting the xmlns into the apply-templates or the outer
            template in eac-cpf.xsl changes nothing.
            -->
        <xsl:element name="{local-name(.)}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="copy-no-ns"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="tpt_entity_type" xmlns:ns="http://www.loc.gov/MARC21/slim"> 
        <xsl:param name="df"/>
        <!--
            Determine the entity type. Give the template a name so we can talk about it in the documentataion and
            comments. The input param $df must be a copy-of node set, not a value-of string.
        -->
        <xsl:choose>
            <xsl:when test="$df/marc:datafield[(@tag='100' or @tag='600' or @tag='700') and @ind1 = '3']">
                <xsl:text>family</xsl:text>
            </xsl:when >
            <xsl:when test="$df/marc:datafield[(@tag='100' or @tag='600' or @tag='700') and not(@ind1 = '3')]">
                <xsl:text>person</xsl:text>
            </xsl:when>
            <xsl:when test="$df/marc:datafield[@tag='110' or @tag='111' or @tag='610' or @tag='611' or @tag='710' or @tag='711']">
                <xsl:text>corporateBody</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- 
         Deep copy via identity replacing the existing namespace with a new one. This is not a common thing to
         do since usually you would want to use the value of the input document element as an element with a
         new name in the output. This does want people wish copy-namespace="no" or something similar would do,
         but does not. 

         <xsl:call-template name="renamespace">
         <xsl:with-param name="ns" select="'urn:isbn:1-931666-33-4'" />
         </xsl:call-template>
    -->
    <xsl:template name="renamespace" >
        <xsl:param name="ns"/>
        <xsl:element name="{local-name(.)}" namespace="{$ns}">
            <xsl:copy-of select="@*"/>	
            <!--
                Use for-each to set the context to the children elements of '.'. It iterates once for each
                child.
            -->
            <xsl:for-each select="./*">
                <xsl:call-template name="renamespace"/>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>


    <xsl:function name="functx:is-node-in-sequence-deep-equal" as="xs:boolean" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="node" as="node()?"/> 
        <xsl:param name="seq" as="node()*"/> 
        <xsl:sequence select=" 
                              some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
                              "/>
    </xsl:function>
    
    <xsl:function name="functx:distinct-deep" as="node()*" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="nodes" as="node()*"/> 
        <xsl:sequence select=" 
                              for $seq in (1 to count($nodes))
                              return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                              .,$nodes[position() &lt; $seq]))]
                              "/>
    </xsl:function>
    
    <xsl:function name="functx:escape-for-regex" as="xs:string" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="arg" as="xs:string?"/> 
        <!--
            I wonder why this is a sequence and not value of? Blindly copied
            from other functions.
        -->
        <xsl:value-of select="
                              replace($arg,
                              '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
                              "/>
    </xsl:function>

    <xsl:function name="lib:norm-punct" as="xs:string">
        <xsl:param name="str" as="xs:string?"/>
        <!--
            Normalize space and remove trailing punctuation. So far only period
            and comma.  Do a second replace to normalize "etc" to "etc.". There
            are probably other abbreviations lurking in the data.
        -->
        <xsl:value-of select="replace(replace(normalize-space($str), '[\.,]+$', ''), 'etc$', 'etc.')"/>
    </xsl:function>

    <xsl:function name="lib:pname-match" as="xs:boolean">
        <xsl:param name="str1" as="xs:string?"/>
        <xsl:param name="str2" as="xs:string?"/>
        <!--
            Punctuation-normalized name match. Preserve leading comma. If the
            length is different after un-punctuating the strings must be
            different then return false. Else return the results of
            matches(). Order of arguments to matches() doesn't matter because
            the two un-punctuated strings are the same length.
            
            No need to lower case both strings because we're using a regex with 'i'.
            
            Add an additional replace() around the lib:unpunct() call because
            there is one record with '\&', but after hours of trying to get xslt
            to take that in some escaped form in a regex, I've given up, and
            just delete it from both strings. We only care about comparing
            punctuation-clean strings, so we only need to clean both strings the
            same way. We cannot modify/break lib:unpunct() because that is used
            elsewhere to unpunctuate strings that are real data in the cpf
            output.
        -->
        <xsl:variable name="clean1" select="lower-case(lib:unpunct($str1))"/>
        <xsl:variable name="clean2" select="lower-case(lib:unpunct($str2))"/>
        <xsl:choose>
            <xsl:when test="not(string-length($clean1) = string-length($clean2))">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- <xsl:message> -->
                <!--     <xsl:text>clean1: </xsl:text> -->
                <!--     <xsl:copy-of select="$clean1"/> -->
                <!--     <xsl:text> clean2: </xsl:text> -->
                <!--     <xsl:copy-of select="$clean2"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->
                <xsl:value-of select="$clean1 = $clean2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="lib:unpunct" as="xs:string*" >
        <xsl:param name="str" as="xs:string?"/>
        <!--
            Forcing return type does not prevent error "A sequence of more than
            one item..."
            
            Replace some chars with space, then delete some chars,
            then normalize-space().  Preserve leading comma. We are only
            implementing the relevant parts. LOC has details. The key thing is
            that some chars are converted to space, while other chars are
            deleted.  http://www.loc.gov/aba/pcc/naco/normrule-2.html

            ampersand is &#x26; " is &#x22; The list we care about: ,.(){}[]:;?/&#x22;[]#!=@
            We have to do &#x27;&#x27; to get a single quote. Unclear why '' doesn't work.
            
           Need a special pass for '\&' that occurs in one place. Remove it for unpunctuated text.
        -->
        <xsl:variable name="pass_1">
            <xsl:value-of select="replace($str, '[\{\}\(\):,!>\-&lt;\.\?&#x22;]', ' ')"/>
        </xsl:variable>

        <xsl:variable name="pass_2">
            <xsl:value-of select="replace($pass_1, '[&#x27;&#x27;\[\]]', '')"/>
        </xsl:variable>

        <!-- 
             Carefully return a string, not a sequence.
        -->

        <xsl:choose>
            <xsl:when test="substring($str,1,1) = ','">
                <xsl:value-of select="concat(',',normalize-space($pass_2))"/> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($pass_2)"/> 
            </xsl:otherwise>
        </xsl:choose>
   </xsl:function>

    <xsl:function name="lib:unpluralize">
        <xsl:param name="str" as="xs:string?"/>
        <xsl:variable name="pass_1">
            <xsl:value-of select="replace($str, 'ies$', 'y')"/>
        </xsl:variable>

        <xsl:variable name="pass_2">
            <xsl:value-of select="replace($pass_1, 's$', '')"/>
        </xsl:variable>

        <xsl:variable name="pass_3">
            <xsl:value-of select="replace($pass_2, 'men$', 'man')"/>
        </xsl:variable>

        <xsl:value-of select="normalize-space($pass_3)"/>
    </xsl:function>

    <xsl:function name="lib:fn-safe">
        <xsl:param name="str"/>

        <xsl:choose>
            <xsl:when test="matches($str, '[^A-Za-z0-9\-]')">
                <xsl:analyze-string select="$str" regex="."> 
                    <xsl:matching-substring>
                        <xsl:choose>
                            <xsl:when test="matches(., '[^A-Za-z0-9\-]')">
                                <xsl:value-of select="format-number( string-to-codepoints(.), '000')"/> 
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/> 
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$str"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


</xsl:stylesheet>
