<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:functx="http://www.functx.com"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:snac="snac"
                exclude-result-prefixes="#all"
                version="2.0">


    <!--
        av_ is mnemonic for Attribute Value. These constitute a controlled vocabulary of values for attributes
        like localType in CPF. There is a big list in lib.xsl.
    -->

    <xsl:variable name="av_DatabaseName" select="'http://socialarchive.iath.virginia.edu/control/term#DatabaseName'"/>

    <xsl:variable name="av_suspiciousDate" select="'http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate'"/>
    <xsl:variable name="av_active " select="'http://socialarchive.iath.virginia.edu/control/term#Active'"/>
    <xsl:variable name="av_born" select="'http://socialarchive.iath.virginia.edu/control/term#Birth'"/>
    <xsl:variable name="av_died" select="'http://socialarchive.iath.virginia.edu/control/term#Death'"/>
    <xsl:variable name="av_associatedSubject" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedSubject'"/>
    <xsl:variable name="av_associatedPlace" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedPlace'"/>
    <xsl:variable name="av_extractRecordId" select="'http://socialarchive.iath.virginia.edu/control/term#ExtractedRecordId'"/>
    <xsl:variable name="av_Leader06" select="'http://socialarchive.iath.virginia.edu/control/term#Leader06'"/>
    <xsl:variable name="av_Leader07" select="'http://socialarchive.iath.virginia.edu/control/term#Leader07'"/>
    <xsl:variable name="av_Leader08" select="'http://socialarchive.iath.virginia.edu/control/term#Leader08'"/>
    <xsl:variable name="av_derivedFromRole" select="'http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole'"/>

    <xsl:variable name="av_CorporateBody" select="'http://socialarchive.iath.virginia.edu/control/term#CorporateBody'"/>
    <xsl:variable name="av_Family" select="'http://socialarchive.iath.virginia.edu/control/term#Family'"/>
    <xsl:variable name="av_Person" select="'http://socialarchive.iath.virginia.edu/control/term#Person'"/>
    <xsl:variable name="av_associatedWith" select="'http://socialarchive.iath.virginia.edu/control/term#associatedWith'"/>
    <xsl:variable name="av_correspondedWith" select="'http://socialarchive.iath.virginia.edu/control/term#correspondedWith'"/>
    <xsl:variable name="av_creatorOf" select="'http://socialarchive.iath.virginia.edu/control/term#creatorOf'"/>
    <xsl:variable name="av_referencedIn" select="'http://socialarchive.iath.virginia.edu/control/term#referencedIn'"/>
    <xsl:variable name="av_archivalResource" select="'http://socialarchive.iath.virginia.edu/control/term#ArchivalResource'"/>

    <!-- As far as I know these aren't used in any of Tom's XSLT that generates CPF. -->
    <xsl:variable name="av_mergedRecord" select="'http://socialarchive.iath.virginia.edu/control/term#MergedRecord'"/>
    <xsl:variable name="av_BibliographicResource" select="'http://socialarchive.iath.virginia.edu/control/term#BibliographicResource'"/>
    <xsl:variable name="av_mayBeSameAs" select="'http://socialarchive.iath.virginia.edu/control/term#mayBeSameAs'"/>
    <xsl:variable name="av_sameAs" select="'http://www.w3.org/2002/07/owl#sameAs'"/>

    <!-- New values used in EAD extraction -->

    <xsl:variable name="av_note" select="'http://socialarchive.iath.virginia.edu/control/term#ead/note'"/>
    <xsl:variable name="av_title" select="'http://socialarchive.iath.virginia.edu/control/term#ead/title'"/>
    <xsl:variable name="av_head" select="'http://socialarchive.iath.virginia.edu/control/term#ead/head'"/>
    <xsl:variable name="av_deflist" select="'http://socialarchive.iath.virginia.edu/control/term#ead/deflist'"/>
    <xsl:variable name="av_item" select="'http://socialarchive.iath.virginia.edu/control/term#ead/item'"/>
    <xsl:variable name="av_label" select="'http://socialarchive.iath.virginia.edu/control/term#ead/label'"/>
    <!-- Used for @href, found in extref, maybe other elements -->
    <xsl:variable name="av_href" select="'http://socialarchive.iath.virginia.edu/control/term#ead/href'"/>


    <!-- New for alternativeName so Ray and Yiming know which name to match. Internal use only. -->
    <xsl:variable name="av_match" select="'http://socialarchive.iath.virginia.edu/control/term#Matchtarget'"/>

</xsl:stylesheet>
