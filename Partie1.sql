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
    observation VARCHAR(20),   
);
/* les associations:*/

CREATE TYPE T_Set_Ref_Moyen AS TABLE OF REF TMoytransport;
CREATE TYPE T_Set_Ref_Station AS TABLE OF REF TStation;
CREATE TYPE T_Set_Ref_Ligne AS TABLE OF REF TLigne;
CREATE TYPE T_Set_Ref_Navette AS TABLE OF REF TNavette;
CREATE TYPE T_Set_Ref_Voyage AS TABLE OF REF TVoyage;
CREATE TYPE T_Set_Ref_Troncon AS TABLE OF REF TTroncon;

/* compléter les types */
/*TLigne*/
alter type TLigne add attribute Ligne_StationDepart REF TStation cascade;
alter type TLigne add attribute Ligne_StationArrivee REF TStation cascade;
alter type TLigne add attribute Ligne_MoyenTransport REF TMoytransport cascade;
alter type TLigne add attribute Ligne_Troncon T_Set_Ref_Troncon cascade;
alter type TLigne add attribute Ligne_Navette T_Set_Ref_Navette cascade;

/*Tstation*/

alter type TStation add attribute Station_Ligne T_Set_Ref_Ligne cascade;
alter type TStation add attribute Station_Troncons T_Set_Ref_Troncon cascade;
alter type TStation add attribute Station_MoyenTransport T_Set_Ref_Moyen cascade;

/*TMoytransport*/
alter type TMoytransport add attribute Moytransport_Ligne T_Set_Ref_Ligne cascade;
alter type TMoytransport add attribute Moytransport_Station T_Set_Ref_Station cascade;
/*TTroncon*/
alter type TTroncon add attribute Troncon_StationDebut REF TStation cascade;
alter type TTroncon add attribute Troncon_StationFin REF TStation cascade;
/*TNavette*/
alter type TNavette add attribute Navette_Ligne REF TLigne cascade;
alter type TNavette add attribute Navette_Moytransport REF TMoytransport cascade;
alter type TNavette add attribute Navette_Voyage T_Set_Ref_Voyage cascade;
/*TVoyage*/
alter type TVoyage add attribute Voyage_Navette REF TNavette cascade;
