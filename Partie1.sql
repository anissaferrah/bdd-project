/* création des tables spaces*/
CREATE TABLESPACE SQL3_TBS 
DATAFILE 'sql3_tbs.dbf' SIZE 50M 
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE SQL3_TempTBS 
TEMPFILE 'sql3_temp_tbs.dbf' SIZE 20M 
AUTOEXTEND ON NEXT 5M MAXSIZE UNLIMITED;

/* création de user*/
CREATE USER SQL3 
IDENTIFIED BY monmotdepasse
DEFAULT TABLESPACE SQL3_TBS
TEMPORARY TABLESPACE SQL3_TempTBS;

/* affectation des priviléges*/
GRANT ALL PRIVILEGES TO SQL3;

/* création des types*/
CREATE or REPLACE TYPE TMoytransport AS OBJECT  (
    abreviation Varchar2(3),
    heureOuverture TIME ,
    heureFermeture TIME ,
    nbMoyenVoyageurs integer
);

CREATE or REPLACE TYPE TLigne AS OBJECT  (
    codeLigne VARCHAR(10)
);

CREATE or REPLACE TYPE TStation AS OBJECT  (
    Code_S INTEGER,
    nom VARCHAR(100),
    latitude FLOAT,
    longitude FLOAT,
    estPrincipale BOOLEAN
);

CREATE or REPLACE TYPE TTroncon AS OBJECT (
    num_tr INTEGER,
    longueurKm FLOAT
);

CREATE or REPLACE TYPE TNavette AS OBJECT (
    num_nav VARCHAR(20),
    marque VARCHAR(50),
    anneeCirculation INTEGER
);

CREATE TYPE TVoyage AS OBJECT (
    num_voyage VARCHAR(20),
    duree INTEGER,
    dateVoyage DATE,
    heureDebut TIME,
    sens VARCHAR(5),  -- 'Aller' ou 'Retour'
    nbVoyageurs INTEGER,
    observation VARCHAR(10),   
);
/* les associations:*/
CREATE TYPE T_Set_Ref_Troncon AS TABLE OF REF TTroncon;
/* compléter les types */
alter type TLigne add attribute stationDepart REF TStation cascade;
alter type TLigne add attribute stationArrivee REF TStation cascade;
alter type TLigne add attribute  moyenTransport REF TMoytransport cascade;
alter type TLigne add attribute  troncons T_Set_Ref_Troncon cascade;


alter type TTroncon add attribute stationDebut REF TStation cascade;
alter type TTroncon add attribute stationFin REF TStation cascade;


alter type TVoyage add attribute navette REF NavetteType cascade;


