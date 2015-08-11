

CREATE SEQUENCE pk_seq;


create table file_list (
        recordIdentifier text ,
        entityType text ,
        authorizedNameEntry text ,
        otherNameEntries text ,
        beginningDate text ,
        endDate text ,
        dateType text ,
        legalStatus text ,
        recordIdentifierAtBnF text ,
        ISNI text ,
        recordCreationDate text
);

create table alt_name (
        an_pk int default nextval('pk_seq'),
        rid text, -- fk to file_list.recordIdentifier
        name text
);


