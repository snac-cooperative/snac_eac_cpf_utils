#!/usr/bin/perl

package av;

# http://stackoverflow.com/questions/7542120/perl-how-to-make-variables-from-requiring-script-available-in-required-script

# The "use" statement and $VERSION seem to be required.
use vars qw($VERSION);
$VERSION = '1';

%av = (
       av_DatabaseName => 'http://socialarchive.iath.virginia.edu/control/term#DatabaseName',
       av_suspiciousDate => 'http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate',
       av_active  => 'http://socialarchive.iath.virginia.edu/control/term#Active',
       av_born => 'http://socialarchive.iath.virginia.edu/control/term#Birth',
       av_died => 'http://socialarchive.iath.virginia.edu/control/term#Death',
       av_associatedSubject => 'http://socialarchive.iath.virginia.edu/control/term#AssociatedSubject',
       av_associatedPlace => 'http://socialarchive.iath.virginia.edu/control/term#AssociatedPlace',

       # Oct 10 2014 I just noticed the missing "ed" in the variable name "extract" instead of "extracted". Not
       # a problem as long as it used the same way everywhere. XSLT will die with an undeclared variable error
       # if someone misspells it.

       av_extractRecordId => 'http://socialarchive.iath.virginia.edu/control/term#ExtractedRecordId',

       av_Leader06 => 'http://socialarchive.iath.virginia.edu/control/term#Leader06',
       av_Leader07 => 'http://socialarchive.iath.virginia.edu/control/term#Leader07',
       av_Leader08 => 'http://socialarchive.iath.virginia.edu/control/term#Leader08',
       av_derivedFromRole => 'http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole',
       av_CorporateBody => 'http://socialarchive.iath.virginia.edu/control/term#CorporateBody',
       av_Family => 'http://socialarchive.iath.virginia.edu/control/term#Family',
       av_Person => 'http://socialarchive.iath.virginia.edu/control/term#Person',
       av_associatedWith => 'http://socialarchive.iath.virginia.edu/control/term#associatedWith',
       av_correspondedWith => 'http://socialarchive.iath.virginia.edu/control/term#correspondedWith',
       av_creatorOf => 'http://socialarchive.iath.virginia.edu/control/term#creatorOf',
       av_referencedIn => 'http://socialarchive.iath.virginia.edu/control/term#referencedIn',
       
       # New for AnF apr 23 2015

       av_hasFamilyRelationTo => 'http://socialarchive.iath.virginia.edu/control/term#hasFamilyRelationTo',
       av_hasChild => 'http://socialarchive.iath.virginia.edu/control/term#hasChild',
       av_hasParent => 'http://socialarchive.iath.virginia.edu/control/term#hasParent',
       av_isSuccessorOf => 'http://socialarchive.iath.virginia.edu/control/term#isSuccessorOf',
       av_isSucceededBy => 'http://socialarchive.iath.virginia.edu/control/term#isSucceededBy',


       # note: case difference between key and value. key has lc 'a' and value has uc 'A'
       av_archivalResource => 'http://socialarchive.iath.virginia.edu/control/term#ArchivalResource',

       # May 8 2015 Only used by the Whitman data resourceRelations which have a URL pointing to a transcription, and/or
       # digitized version.
       av_DigitalArchivalResource => 'http://socialarchive.iath.virginia.edu/control/term#DigitalArchivalResource',

       
       # Apr 15 2015 I thought someone at NARA said "contributor" was a misnomer, and the only relationship is
       # creatorOf. You'll have to check the code to be sure.

       # Jan 26 2015 Added for NARA. In SNAC parlance, contributor may simply be creator, but for now, it is
       # separate.

       av_contributorTo => 'http://socialarchive.iath.virginia.edu/control/term#contributorTo',
       av_donorOf => 'http://socialarchive.iath.virginia.edu/control/term#donorOf',

       # As far as I know these aren't used in any of Tom's XSLT that generates CPF.

       av_mergedRecord => 'http://socialarchive.iath.virginia.edu/control/term#MergedRecord',
       av_BibliographicResource => 'http://socialarchive.iath.virginia.edu/control/term#BibliographicResource',
       av_mayBeSameAs => 'http://socialarchive.iath.virginia.edu/control/term#mayBeSameAs',

       # Used for NARA authority records starting Feb 24 2015

       av_sameAs => 'http://www.w3.org/2002/07/owl#sameAs',

       # New values used in EAD extraction

       av_note => 'http://socialarchive.iath.virginia.edu/control/term#ead/note',
       av_title => 'http://socialarchive.iath.virginia.edu/control/term#ead/title',
       av_head => 'http://socialarchive.iath.virginia.edu/control/term#ead/head',
       av_deflist => 'http://socialarchive.iath.virginia.edu/control/term#ead/deflist',
       av_item => 'http://socialarchive.iath.virginia.edu/control/term#ead/item',
       av_label => 'http://socialarchive.iath.virginia.edu/control/term#ead/label',

       # Used for @href, found in extref, maybe other elements

       av_href => 'http://socialarchive.iath.virginia.edu/control/term#ead/href',

       # Feb 4 2015 The allowed values for cpfDescription/identity/nameEntry/authorizedForm.
       # First used by nara_das2cpf.xsl, and hard coded elsewhere.

       av_authorizedForm => 'authorizedForm',
       av_alternativeForm => 'alternativeForm',

       # As of Oct 10 2014 not used.
       # New for alternativeName so Ray and Yiming know which name to match. Internal use only.

       av_match => 'http://socialarchive.iath.virginia.edu/control/term#Matchtarget'
      );
1;
