<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns="http://www.loc.gov/MARC21/slim"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                >
    
    <!--
         Author: Tom Laudeman

         Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
         "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
         License at
         
         http://www.osedu.org/licenses/ECL-2.0
         
         Unless required by applicable law or agreed to in writing, software distributed under the License is
         distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
         the License for the specific language governing permissions and limitations under the License.
    -->

    <xsl:output method="text" indent="yes"/>
    <!-- Need this or every apply-templates emits a newline -->
    <xsl:strip-space elements="*"/>
    
    <xsl:template mode="agency" match="*">
        <xsl:param name="record_id"/> 
        <xsl:param name="sub_c"/> 
        <xsl:param name="sub_d"/> 

        <!-- <xsl:text>record_id:</xsl:text> -->
        <!-- <xsl:value-of select="$record_id"/> -->

        <!--
            We need the literal "040$a: " text so we can pull our data out of the log file with a Perl
            one-liner. 
            
            cat agency_code.log | perl -ne 'if ($_ =~ m/040\$a: (.*)/) { print "$1\n";} ' | sort -fu > agency_unique.txt
            
            We want to stay compatible with exec_record.pl, and this seems easier than trying to
            get result-document to output text. (And more fun.)
        -->

        <xsl:text> 040$a: </xsl:text>
        <xsl:value-of select="."/>

        <!-- <xsl:text> c: </xsl:text> -->
        <!-- <xsl:value-of select="$sub_c"/> -->

        <!-- <xsl:text> d: </xsl:text> -->
        <!-- <xsl:value-of select="$sub_d"/> -->

        <xsl:text>&#x0A;</xsl:text>
    </xsl:template>
    
    <xsl:template match="marc:record">
        <xsl:variable name="record_id" 
                      select="normalize-space(marc:controlfield[@tag='001'])"/>
        <xsl:apply-templates mode="agency" select="marc:datafield[@tag='040']/marc:subfield[@code='a']">
            <xsl:with-param name="record_id" select="$record_id"/>
            <xsl:with-param name="sub_c" select="marc:datafield[@tag='040']/marc:subfield[@code='c']"/>
            <xsl:with-param name="sub_d" select="marc:datafield[@tag='040']/marc:subfield[@code='d']"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="/marc:collection">
        <xsl:if test="position() = 1">
            <xsl:text>&#x0A;</xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="*">
    </xsl:template>

</xsl:stylesheet>
