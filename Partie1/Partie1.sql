-- A. Modélisation orientée objet
-- 1. Diagramme UML (non inclus ici, à dessiner séparément)

-- 2. Transformation en schéma relationnel (déjà inclus dans les commentaires des tables)
-- MoyenTransport(Abreviation(PK), HeureOuverture, HeureFermeture, NbMoyenVoyageurs) 
-- Station(CodeStation(PK), NomStation, Longitude, Latitude, EstPrincipale)
-- Ligne(CodeLigne(PK), Abreviation(FK), StationDepart(FK), StationArrivee(FK))
-- Troncon(NumeroTroncon(PK), StationDebut(FK), StationFin(FK), LongueurKm)
-- Navette(NumeroNavette(PK), CodeLigne(FK), Abreviation(FK), Marque, AnneeMiseEnCirculation)
-- Voyage(NumeroVoyage(PK), NumeroNavette(FK), CodeLigne(FK), Duree, DateVoyage, HeureDebut, Sens, NbVoyageurs, Observation)
-- B. Création des TableSpaces et utilisateur
-- 3. Création des TableSpaces
ALTER PLUGGABLE DATABASE orclpdb OPEN;
connect sys@orclpdb as sysdba

CREATE TABLESPACE SQL3_TBS DATAFILE 'sql3_tbs.dbf' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE SQL3_TempTBS TEMPFILE 'sql3_temp_tbs.dbf' SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE UNLIMITED;

-- 4. Création de l'utilisateur
CREATE USER SQL3 IDENTIFIED BY sql3 DEFAULT TABLESPACE SQL3_TBS TEMPORARY TABLESPACE SQL3_TempTBS;

-- 5. Attribution des privilèges
GRANT ALL PRIVILEGES TO SQL3;

connect SQL3/sql3@orclpdb;
-- C. Langage de définition de données
-- 6. Définition des types abstraits et associations
CREATE OR REPLACE TYPE TMoytransport AS OBJECT (
    Abreviation Varchar2(3),
    HeureOuverture VARCHAR2(5),
    HeureFermeture VARCHAR2(5),
    NbMoyenVoyageurs INTEGER
);
/
CREATE OR REPLACE TYPE TLigne AS OBJECT (
    CodeLigne Varchar2(10)
);
/
CREATE OR REPLACE TYPE TCoordonnees AS OBJECT (
  Longitude FLOAT,
  Latitude FLOAT
);
/
CREATE OR REPLACE TYPE TStation AS OBJECT (
    CodeStation Varchar2(10),
    NomStation Varchar2(100),
    Coordonnees TCoordonnees,
    EstPrincipale NUMBER(1)
);
/
CREATE OR REPLACE TYPE TTroncon AS OBJECT (
    NumeroTroncon Varchar2(10),
    LongueurKm FLOAT
);
/
CREATE OR REPLACE TYPE TNavette AS OBJECT (
    NumeroNavette Varchar2(20),
    Marque Varchar2(50),
    AnneeMiseEnCirculation NUMBER(4)
);
/

CREATE OR REPLACE TYPE TVoyage AS OBJECT (
    NumeroVoyage Varchar2(20),
    Duree INTEGER,
    DateVoyage DATE,
    HeureDebut VARCHAR2(5),
    Sens Varchar2(6),  -- 'Aller' ou 'Retour'
    NbVoyageurs INTEGER,
    Observation Varchar2(20)
);
/
-- Associations
CREATE OR REPLACE TYPE T_Set_Ref_Moyen AS TABLE OF REF TMoytransport;
/
CREATE OR REPLACE TYPE T_Set_Ref_Station AS TABLE OF REF TStation;
/
CREATE OR REPLACE TYPE T_Set_Ref_Ligne AS TABLE OF REF TLigne;
/
CREATE OR REPLACE TYPE T_Set_Ref_Navette AS TABLE OF REF TNavette;
/
CREATE OR REPLACE TYPE T_Set_Ref_Voyage AS TABLE OF REF TVoyage;
/
CREATE OR REPLACE TYPE T_Set_Ref_Troncon AS TABLE OF REF TTroncon;
/

-- Compléter les types
ALTER TYPE TLigne ADD ATTRIBUTE Ligne_StationDepart REF TStation CASCADE;
ALTER TYPE TLigne ADD ATTRIBUTE Ligne_StationArrivee REF TStation CASCADE;
ALTER TYPE TLigne ADD ATTRIBUTE Ligne_MoyenTransport REF TMoytransport CASCADE;
ALTER TYPE TLigne ADD ATTRIBUTE Ligne_Troncon T_Set_Ref_Troncon CASCADE;
ALTER TYPE TLigne ADD ATTRIBUTE Ligne_Navette T_Set_Ref_Navette CASCADE;

DESC TLigne;       

ALTER TYPE TStation ADD ATTRIBUTE Station_Ligne T_Set_Ref_Ligne CASCADE;
ALTER TYPE TStation ADD ATTRIBUTE Station_Troncons T_Set_Ref_Troncon CASCADE;
ALTER TYPE TStation ADD ATTRIBUTE Station_MoyenTransport T_Set_Ref_Moyen CASCADE;

DESC TStation;

ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Ligne T_Set_Ref_Ligne CASCADE;
ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Station T_Set_Ref_Station CASCADE;
ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Navette T_Set_Ref_Navette CASCADE;

DESC TMoytransport;

ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationDebut REF TStation CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationFin REF TStation CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon__Ligne1 REF TLigne CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon__Ligne2 REF TLigne CASCADE;

DESC TTroncon;

ALTER TYPE TNavette ADD ATTRIBUTE Navette_Ligne REF TLigne CASCADE;
ALTER TYPE TNavette ADD ATTRIBUTE Navette_Moytransport REF TMoytransport CASCADE;
ALTER TYPE TNavette ADD ATTRIBUTE Navette_Voyage T_Set_Ref_Voyage CASCADE;

DESC TNavette;

ALTER TYPE TVoyage ADD ATTRIBUTE Voyage_Navette REF TNavette CASCADE;

DESC TVoyage;

-- 7. Définition des méthodes
-- Méthode pour calculer la durée d'un tronçon
--vitesse de chaque moyen de transport:
--BUS 20 km/h, MET 35 km/h, TRM 25 km/h, TRN 45 km/h
ALTER TYPE TTroncon ADD MEMBER FUNCTION CalculerDuree(moyen REF TMoytransport) RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TTroncon AS
  MEMBER FUNCTION CalculerDuree(moyen REF TMoytransport) RETURN INTEGER IS
    v_abrev   VARCHAR2(5);
    v_vitesse NUMBER;
    v_duree   NUMBER;
  BEGIN
    SELECT DEREF(moyen).Abreviation INTO v_abrev FROM DUAL;

    IF v_abrev = 'MET' THEN
      v_vitesse := 35;
    ELSIF v_abrev = 'TRM' THEN
      v_vitesse := 25;
    ELSIF v_abrev = 'BUS' THEN
      v_vitesse := 20;
    ELSIF v_abrev = 'TRN' THEN
      v_vitesse := 45;
    ELSE
      v_vitesse := 20;
    END IF;

    v_duree := (SELF.LongueurKm / v_vitesse) * 60; -- Durée en minutes
    RETURN ROUND(v_duree);
  END CalculerDuree;
END;
/
-- Exemple d'utlisation de la mehode : Calculer la durée d'un tronçon=>correct
SELECT t.NumeroTroncon, t.CalculerDuree(REF(m)) AS DureeMinutes
FROM Troncon t, Moytransport m
WHERE m.Abreviation = 'MET' AND t.NumeroTroncon = 'T002';


--Méthode pour chaque navette, Calculer le nombre total de voyages effectués  
ALTER TYPE TNavette ADD MEMBER FUNCTION CalculerNombreVoyages RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TNavette AS
  MEMBER FUNCTION CalculerNombreVoyages RETURN INTEGER IS
    v_nb INTEGER := 0;
  BEGIN
    SELECT COUNT(*)
    INTO   v_nb
    FROM   TABLE(SELF.Navette_Voyage);
    RETURN v_nb;
  END CalculerNombreVoyages;
END;
/
-- Exemple d'utilisation de la méthode CalculerNombreVoyages
SELECT n.NumeroNavette, n.CalculerNombreVoyages() AS NbVoyages
FROM Navette n
WHERE n.NumeroNavette IN ('N001', 'N002', 'N003', 'N004', 'N005', 'N006', 'N007', 'N008', 'N009', 'N010', 'N011', 'N012', 'N013', 'N014', 'N015', 'N016', 'N017');
CREATE OR REPLACE TYPE T_Set_Navette AS TABLE OF TNavette;
/
ALTER TYPE TLigne ADD MEMBER FUNCTION ListeNavettes RETURN T_Set_Navette CASCADE;

CREATE OR REPLACE TYPE BODY TLigne AS
  MEMBER FUNCTION ListeNavettes 
    RETURN T_Set_Navette IS 
    result T_Set_Navette := T_Set_Navette(); 
    v_nav TNavette;
  BEGIN
    FOR ref_nav IN (
      SELECT COLUMN_VALUE AS refNav
      FROM TABLE(SELF.Ligne_Navette)
    ) LOOP
      SELECT DEREF(ref_nav.refNav)
      INTO v_nav
      FROM DUAL;

      result.EXTEND;
      result(result.COUNT) := v_nav;
    END LOOP;
    RETURN result;
  END ListeNavettes;
END;
/  

ALTER TYPE TLigne ADD MEMBER FUNCTION NombreVoyagesPeriode(p_start DATE, p_end DATE) RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TLigne AS
  MEMBER FUNCTION NombreVoyagesPeriode(p_start DATE, p_end DATE)
    RETURN INTEGER IS
    total INTEGER := 0;
  BEGIN
    FOR nav_row IN (
      SELECT DEREF(COLUMN_VALUE) AS nav
      FROM   TABLE(SELF.Ligne_Navette)
    ) LOOP
      FOR voy_row IN (
        SELECT DEREF(COLUMN_VALUE) AS voy
        FROM   TABLE(nav_row.nav.Navette_Voyage)
      ) LOOP
        IF voy_row.voy.DateVoyage BETWEEN p_start AND p_end THEN
          total := total + 1;
        END IF;
      END LOOP;
    END LOOP;
    RETURN total;
  END NombreVoyagesPeriode;
END;
/
--deux methode 
CREATE OR REPLACE TYPE BODY TLigne AS
  -- Fonction ListeNavettes
  MEMBER FUNCTION ListeNavettes RETURN T_Set_Navette IS
    result T_Set_Navette := T_Set_Navette();
    v_nav TNavette;
  BEGIN
    FOR ref_nav IN (
      SELECT COLUMN_VALUE AS refNav
      FROM TABLE(SELF.Ligne_Navette)
    ) LOOP
      SELECT DEREF(ref_nav.refNav)
      INTO v_nav
      FROM DUAL;

      result.EXTEND;
      result(result.COUNT) := v_nav;
    END LOOP;
    RETURN result;
  END ListeNavettes;

  -- Fonction NombreVoyagesPeriode
  MEMBER FUNCTION NombreVoyagesPeriode(p_start DATE, p_end DATE) RETURN INTEGER IS
    total INTEGER := 0;
  BEGIN
    FOR nav_row IN (
      SELECT DEREF(COLUMN_VALUE) AS nav
      FROM TABLE(SELF.Ligne_Navette)
    ) LOOP
      FOR voy_row IN (
        SELECT DEREF(COLUMN_VALUE) AS voy
        FROM TABLE(nav_row.nav.Navette_Voyage)
      ) LOOP
        IF voy_row.voy.DateVoyage BETWEEN p_start AND p_end THEN
          total := total + 1;
        END IF;
      END LOOP;
    END LOOP;
    RETURN total;
  END NombreVoyagesPeriode;
END;
/
-- Exemple d'utilisation de la méthode ListeNavette
--Tu veux lister toutes les navettes de la ligne « TN002 » :
  SELECT l.ListeNavettes() AS Navettes
  FROM Ligne l
  WHERE l.CodeLigne IN (
    'B001', 'M001', 'TM001', 'TN001', 'B002', 'M002', 'TM002', 'TN002',
    'B003', 'M003', 'TM003', 'TN003', 'B004', 'M004', 'TM004', 'TN004',
    'B005', 'TN005', 'B006', 'TM005', 'M005', 'TM006', 'TN006', 'M006'
  );


-- Exemple d'utilisation de la méthode NombreVoyagesPeriode
--Tu veux savoir combien de voyages ont été effectués entre le 01-01-2025 et le 01-02-2025 sur la ligne « TN002 » :
  SELECT l.NombreVoyagesPeriode(TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('15-02-2025', 'DD-MM-YYYY')) AS NbVoyages
  FROM Ligne l
  WHERE l.CodeLigne = 'TN003';

--Changer le nom de la station « BEZ » par « Univ » dans toutes les lignes/tronçons comportant cette station. 
CREATE OR REPLACE PROCEDURE RenommerNomStationBEZEnUniv IS
  v_station TStation;
BEGIN
  FOR ligne_rec IN (SELECT VALUE(l) AS ligne_obj FROM Ligne l) LOOP
    IF ligne_rec.ligne_obj.Ligne_StationDepart IS NOT NULL THEN
      SELECT DEREF(ligne_rec.ligne_obj.Ligne_StationDepart) INTO v_station FROM DUAL;
      IF v_station.NomStation = 'BEZ' THEN
        v_station.NomStation := 'Univ';
      END IF;
    END IF;
    IF ligne_rec.ligne_obj.Ligne_StationArrivee IS NOT NULL THEN
      SELECT DEREF(ligne_rec.ligne_obj.Ligne_StationArrivee) INTO v_station FROM DUAL;
      IF v_station.NomStation = 'BEZ' THEN
        v_station.NomStation := 'Univ';
      END IF;
    END IF;
  END LOOP;
  FOR troncon_rec IN (SELECT VALUE(t) AS troncon_obj FROM Troncon t) LOOP
    IF troncon_rec.troncon_obj.Troncon_StationDebut IS NOT NULL THEN
      SELECT DEREF(troncon_rec.troncon_obj.Troncon_StationDebut) INTO v_station FROM DUAL;
      IF v_station.NomStation = 'BEZ' THEN
        v_station.NomStation := 'Univ';
      END IF;
    END IF;
    IF troncon_rec.troncon_obj.Troncon_StationFin IS NOT NULL THEN
      SELECT DEREF(troncon_rec.troncon_obj.Troncon_StationFin) INTO v_station FROM DUAL;
      IF v_station.NomStation = 'BEZ' THEN
        v_station.NomStation := 'Univ';
      END IF;
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Nom des stations BEZ mis à jour en Univ.');
END;
/
--COMME SELECTIONNER D'abord toutes les lignes/tronçons comportant  station bez. 
SELECT l.CodeLigne, s.NomStation
FROM Ligne l, Station s
WHERE s.CodeStation IN (
    DEREF(l.Ligne_StationDepart).CodeStation, 
    DEREF(l.Ligne_StationArrivee).CodeStation
)
AND s.NomStation = 'BEZ';

SELECT t.NumeroTroncon, s.NomStation
FROM Troncon t, Station s
WHERE s.CodeStation IN (
    DEREF(t.Troncon_StationDebut).CodeStation, 
    DEREF(t.Troncon_StationFin).CodeStation
)
AND s.NomStation = 'BEZ';

--FROM Troncon t, Station s

SELECT l.CodeLigne, s.NomStation
FROM Ligne l, Station s
WHERE s.CodeStation IN (
    DEREF(l.Ligne_StationDepart).CodeStation, 
    DEREF(l.Ligne_StationArrivee).CodeStation
)
AND s.NomStation = 'Univ';

SELECT t.NumeroTroncon, s.NomStation
FROM Troncon t, Station s
WHERE s.CodeStation IN (
    DEREF(t.Troncon_StationDebut).CodeStation, 
    DEREF(t.Troncon_StationFin).CodeStation
)
AND s.NomStation = 'Univ';
-- Exemple d'utilisation de la procédure RenommerNomStationBEZEnUniv
BEGIN
  RenommerNomStationBEZEnUniv;
END;
/
-- Méthode pour calculer pour un moyen de transport donné (Exemple Métro), 
-- le nombre de voyages effectués à une date donnée (Exemple le 28-02-2025) 
-- et le nombre de voyageurs total.
-- 8.1. Méthode pour calculer le nombre de voyages et de voyageurs
ALTER TYPE TMoytransport ADD MEMBER FUNCTION CalculerVoyagesEtVoyageurs(p_date DATE) RETURN VARCHAR2 CASCADE;

CREATE OR REPLACE TYPE BODY TMoytransport AS
  MEMBER FUNCTION CalculerVoyagesEtVoyageurs(p_date DATE)
    RETURN VARCHAR2 IS
    v_nb_voyages INTEGER := 0;
    v_nb_voyageurs INTEGER := 0;
    v_navette TNavette;
    v_voyage TVoyage;
  BEGIN
    FOR ligne_row IN (
      SELECT DEREF(COLUMN_VALUE) AS ligne
      FROM TABLE(SELF.Moytransport_Ligne)
    ) LOOP
      FOR navette_row IN (
        SELECT DEREF(COLUMN_VALUE) AS navette
        FROM TABLE(ligne_row.ligne.Ligne_Navette)
      ) LOOP
        FOR voyage_row IN (
          SELECT DEREF(COLUMN_VALUE) AS voyage
          FROM TABLE(navette_row.navette.Navette_Voyage)
        ) LOOP
          IF voyage_row.voyage.DateVoyage = p_date THEN
            v_nb_voyages := v_nb_voyages + 1;
            v_nb_voyageurs := v_nb_voyageurs + voyage_row.voyage.NbVoyageurs;
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
    RETURN 'Voyages: ' || v_nb_voyages || ', Nombre de voyageurs: ' || v_nb_voyageurs;
  END CalculerVoyagesEtVoyageurs;
END;
/
--EXEMPLE D'UTILISATION DE LA MÉTHODE	
SELECT m.Abreviation, m.CalculerVoyagesEtVoyageurs(TO_DATE('28-02-2025', 'DD-MM-YYYY')) AS Resultat
FROM Moytransport m
WHERE m.Abreviation = 'MET';
-- 9. Définition des contraintes d'intégrité
CREATE OR REPLACE TRIGGER verif_heures
BEFORE INSERT OR UPDATE ON Moytransport
FOR EACH ROW
DECLARE
    heure_ouverture DATE;
    heure_fermeture DATE;
BEGIN
    -- Conversion des chaînes en heure (format HH24:MI)
    heure_ouverture := TO_DATE(:NEW.HeureOuverture, 'HH24:MI');
    heure_fermeture := TO_DATE(:NEW.HeureFermeture, 'HH24:MI');
    
    IF heure_ouverture >= heure_fermeture THEN
        RAISE_APPLICATION_ERROR(-20001, 'HeureOuverture doit être inférieure à HeureFermeture');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_controle_moyen_transport_station
BEFORE INSERT OR UPDATE ON Station
FOR EACH ROW
DECLARE
    nb_moyens INTEGER;
BEGIN
    IF :NEW.EstPrincipale = 1 THEN
        SELECT COUNT(*) INTO nb_moyens
        FROM TABLE(CAST(:NEW.Station_MoyenTransport AS T_Set_Ref_Moyen));

        IF nb_moyens = 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Une station principale doit être associée au moins deux  moyen de transport.');
        END IF;
        IF nb_moyens < 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Une station principale doit être associée au moins deux  moyen de transport.');
        END IF;
    END IF;
    IF :NEW.EstPrincipale = 0 THEN
        SELECT COUNT(*) INTO nb_moyens
        FROM TABLE(CAST(:NEW.Station_MoyenTransport AS T_Set_Ref_Moyen));

        IF nb_moyens > 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Une station secondaire ne peut être associée qu''à un seul moyen de transport.');
        END IF;
        IF nb_moyens < 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Une station secondaire doit être associée à au moins un moyen de transport.');
        END IF;
    END IF;
END;
/
--verfication que la station de départ et d'arrivée dessert le moyen de transport choisi
CREATE OR REPLACE TRIGGER trg_verif_transport_sur_ligne
BEFORE INSERT OR UPDATE ON Ligne
FOR EACH ROW
DECLARE
  cnt_depart  INTEGER := 0;
  cnt_arrivee INTEGER := 0;
BEGIN
  -- Vérification de la station de départ
  SELECT COUNT(*)
  INTO cnt_depart
  FROM Station s
  WHERE REF(s) = :NEW.Ligne_StationDepart
    AND :NEW.Ligne_MoyenTransport MEMBER OF s.Station_MoyenTransport;

  -- Vérification de la station d’arrivée
  SELECT COUNT(*)
  INTO cnt_arrivee
  FROM Station s
  WHERE REF(s) = :NEW.Ligne_StationArrivee
    AND :NEW.Ligne_MoyenTransport MEMBER OF s.Station_MoyenTransport;

  -- Si l’une des vérifications échoue, lever une erreur
  IF cnt_depart = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'Erreur : la station de départ ne dessert pas ce moyen de transport.'
    );
  ELSIF cnt_arrivee = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20003,
      'Erreur : la station d''arrivée ne dessert pas ce moyen de transport.'
    );
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_verif_troncon
BEFORE INSERT OR UPDATE ON Troncon
FOR EACH ROW
DECLARE
  moyen1 REF TMOYTRANSPORT;
  moyen2 REF TMOYTRANSPORT;
  cnt1_deb INTEGER := 0;
  cnt1_fin INTEGER := 0;
  cnt2_deb INTEGER := 0;
  cnt2_fin INTEGER := 0;
BEGIN
  -- 1) Stations différentes
  IF :NEW.Troncon_StationDebut = :NEW.Troncon_StationFin THEN
    RAISE_APPLICATION_ERROR(-20002, 'Un tronçon doit relier deux stations différentes.');
  END IF;

  -- 2) Longueur positive
  IF :NEW.LongueurKm <= 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'La longueur doit être strictement positive.');
  END IF;

  -- 3) Au moins une ligne
  IF :NEW.Troncon__Ligne1 IS NULL AND :NEW.Troncon__Ligne2 IS NULL THEN
    RAISE_APPLICATION_ERROR(-20004, 'Le tronçon doit appartenir à au moins une ligne.');
  END IF;

  -- 4) Pas deux fois la même ligne
  IF :NEW.Troncon__Ligne1 IS NOT NULL AND :NEW.Troncon__Ligne2 IS NOT NULL AND
     :NEW.Troncon__Ligne1 = :NEW.Troncon__Ligne2 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Le tronçon ne peut pas être lié deux fois à la même ligne.');
  END IF;

  -- 5) Vérification pour la ligne 1
  IF :NEW.Troncon__Ligne1 IS NOT NULL THEN
    SELECT l.Ligne_MoyenTransport INTO moyen1
    FROM Ligne l
    WHERE REF(l) = :NEW.Troncon__Ligne1;

    SELECT COUNT(*) INTO cnt1_deb
    FROM Station s
    WHERE REF(s) = :NEW.Troncon_StationDebut
      AND moyen1 MEMBER OF s.Station_MoyenTransport;

    SELECT COUNT(*) INTO cnt1_fin
    FROM Station s
    WHERE REF(s) = :NEW.Troncon_StationFin
      AND moyen1 MEMBER OF s.Station_MoyenTransport;

    IF cnt1_deb = 0 THEN
      RAISE_APPLICATION_ERROR(-20006, 'La station de début ne dessert pas le moyen de transport de la ligne 1.');
    ELSIF cnt1_fin = 0 THEN
      RAISE_APPLICATION_ERROR(-20007, 'La station de fin ne dessert pas le moyen de transport de la ligne 1.');
    END IF;
  END IF;

  -- 6) Vérification pour la ligne 2
  IF :NEW.Troncon__Ligne2 IS NOT NULL THEN
    SELECT l.Ligne_MoyenTransport INTO moyen2
    FROM Ligne l
    WHERE REF(l) = :NEW.Troncon__Ligne2;

    SELECT COUNT(*) INTO cnt2_deb
    FROM Station s
    WHERE REF(s) = :NEW.Troncon_StationDebut
      AND moyen2 MEMBER OF s.Station_MoyenTransport;

    SELECT COUNT(*) INTO cnt2_fin
    FROM Station s
    WHERE REF(s) = :NEW.Troncon_StationFin
      AND moyen2 MEMBER OF s.Station_MoyenTransport;

    IF cnt2_deb = 0 THEN
      RAISE_APPLICATION_ERROR(-20008, 'La station de début ne dessert pas le moyen de transport de la ligne 2.');
    ELSIF cnt2_fin = 0 THEN
      RAISE_APPLICATION_ERROR(-20009, 'La station de fin ne dessert pas le moyen de transport de la ligne 2.');
    END IF;
  END IF;
  -- 7) Vérification que les deux lignes (si présentes) utilisent le même moyen de transport
  IF :NEW.Troncon__Ligne1 IS NOT NULL AND :NEW.Troncon__Ligne2 IS NOT NULL THEN
    IF moyen1 != moyen2 THEN
      RAISE_APPLICATION_ERROR(-20010, 'Les deux lignes doivent utiliser le même moyen de transport.');
    END IF;
  END IF;
END;
/



--donner resumer ce trigger ce que fait le trigger  trg_verif_troncon est de verifier
-- que le tronçon est valide avant de l'insérer ou de le mettre à jour dans la table Troncon.
-- Il effectue plusieurs vérifications :
-- 1) Il s'assure que les stations de début et de fin sont différentes.
-- 2) Il vérifie que la longueur du tronçon est strictement positive.
-- 3) Il s'assure qu'au moins une ligne est associée au tronçon.
-- 4) Il vérifie qu'une même ligne n'est pas associée deux fois au tronçon.
--5) Il vérifie que chaque ligne associée au tronçon a son moyen de transport dans les deux stations.

CREATE OR REPLACE TRIGGER trg_verif_navette
BEFORE INSERT OR UPDATE ON Navette
FOR EACH ROW
DECLARE
  v_moyen_ligne REF TMoytransport;
BEGIN
  -- Récupérer le moyen de transport de la ligne associée
  SELECT l.Ligne_MoyenTransport
  INTO v_moyen_ligne
  FROM Ligne l
  WHERE REF(l) = :NEW.Navette_Ligne;

  -- Vérifier que le moyen de transport de la navette correspond à celui de la ligne
  IF v_moyen_ligne != :NEW.Navette_Moytransport THEN
    RAISE_APPLICATION_ERROR(-20002, 
      'Incohérence : Le moyen de transport de la navette ne correspond pas à celui de la ligne.');
  END IF;
END;
/
-- 8. Définition des tables----------------------------------------------------------------------------------------------------------------
CREATE TABLE Moytransport OF TMoytransport (
    Abreviation PRIMARY KEY,
    HeureOuverture  NOT NULL,
    HeureFermeture  NOT NULL,
    CONSTRAINT chk_abreviation CHECK (Abreviation IN ('BUS', 'MET', 'TRM', 'TRN')),
    CONSTRAINT chk_NbMoyenVoyageurs NbMoyenVoyageurs CHECK (NbMoyenVoyageurs >= 0)
)   NESTED TABLE Moytransport_Ligne STORE AS table_Moytransport_Ligne,
    NESTED TABLE Moytransport_Station STORE AS table_Moytransport_Station,
    NESTED TABLE Moytransport_Navette STORE AS table_Moytransport_Navette;

CREATE TABLE Station OF TStation (
    CodeStation PRIMARY KEY,
    CONSTRAINT chk_EstPrincipale  CHECK (EstPrincipale IN (0,1))
) NESTED TABLE Station_Ligne STORE AS table_Station_Ligne,
  NESTED TABLE Station_Troncons STORE AS table_Station_Troncons,
  NESTED TABLE Station_MoyenTransport STORE AS table_Station_MoyenTransport;

CREATE TABLE Ligne OF TLigne (
    CodeLigne PRIMARY KEY,
    FOREIGN KEY (Ligne_StationDepart) REFERENCES Station, 
    FOREIGN KEY (Ligne_StationArrivee) REFERENCES Station,
    FOREIGN KEY (Ligne_MoyenTransport) REFERENCES Moytransport,
    CONSTRAINT chk_station_depart_arrivee CHECK (Ligne_StationDepart != Ligne_StationArrivee)
) NESTED TABLE Ligne_Troncon STORE AS table_Ligne_Troncon,
  NESTED TABLE Ligne_Navette STORE AS table_Ligne_Navette;

CREATE TABLE Troncon OF TTroncon (
  NumeroTroncon PRIMARY KEY,
  FOREIGN KEY (Troncon_StationDebut) REFERENCES Station,
  FOREIGN KEY (Troncon_StationFin) REFERENCES Station,
  FOREIGN KEY (Troncon__Ligne1) REFERENCES Ligne,
  FOREIGN KEY (Troncon__Ligne2) REFERENCES Ligne,
  CONSTRAINT chk_station_debut_fin CHECK (Troncon_StationDebut != Troncon_StationFin),
  CONSTRAINT chk_troncon_ligne1_ligne2 CHECK (Troncon__Ligne1 != Troncon__Ligne2)
);

CREATE TABLE Navette OF TNavette (
    NumeroNavette PRIMARY KEY,
    FOREIGN KEY (Navette_Ligne) REFERENCES Ligne,
    FOREIGN KEY (Navette_Moytransport) REFERENCES Moytransport
) NESTED TABLE Navette_Voyage STORE AS table_Navette_Voyage;

CREATE TABLE Voyage OF TVoyage (
    NumeroVoyage PRIMARY KEY,
    FOREIGN KEY (Voyage_Navette) REFERENCES Navette,
    CONSTRAINT chk_sens CHECK (Sens IN ('Aller', 'Retour')),
    CONSTRAINT chk_nbvoyageurs CHECK (NbVoyageurs >= 0)
);
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Insertion des moyens de transport
--si NbMoyenVoyageurs<0
INSERT INTO Moytransport VALUES ('TRN','05:00','23:59',   0, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
--si HeureOuverture>=HeureFermeture
INSERT INTO Moytransport VALUES ('BUS','22:00','05:00', 200, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());

--------------------------------------------------insertion dans la table Moytransport:--------------------------------------------------------------------
INSERT INTO Moytransport VALUES ('MET','05:30','23:30', 300, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('TRM','06:00','23:00', 500, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('TRN','05:00','23:59', 400, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('TRN','05:00','23:59', 480, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());

--si principle =1 alors il faut au moins 2 moyens de transport
--Verification de la contrainte d'integrite de la table station si EstPrincipale=1
INSERT INTO Station VALUES ('S000', 'Station A',TCoordonnees(38.8566, 2.3522), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'))) ;


-- --------------------------------------------------Insertion dans la table station:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO Station VALUES ('S001', 'Station A',TCoordonnees(38.8566, 2.3522), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN'))) ;
INSERT INTO Station VALUES ('S002', 'Station B',TCoordonnees(58.8570, 2.3530), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET')));
INSERT INTO Station VALUES ('S003', 'Station C',TCoordonnees(48.8575, 7.3540), 0, T_Set_Ref_Ligne(), T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S004', 'Station D',TCoordonnees(78.8580, 2.3550), 1, T_Set_Ref_Ligne(), T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S005', 'Station E',TCoordonnees(88.8590, 2.3560), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S006', 'Station F',TCoordonnees(48.8600, 3.3570), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S007', 'Station G',TCoordonnees(48.8610, 2.3580), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S008', 'Station H',TCoordonnees(38.8620, 2.3590), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS')));
INSERT INTO Station VALUES ('S009', 'Station I',TCoordonnees(48.8630, 2.3600), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S010', 'Station J',TCoordonnees(48.8640, 5.3610), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S011', 'Station K',TCoordonnees(58.8650, 2.3620), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET')));
INSERT INTO Station VALUES ('S012', 'Station L',TCoordonnees(48.8660, 2.3630), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S013', 'Station M',TCoordonnees(48.8670, 2.3640), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S014', 'Station N',TCoordonnees(48.8680, 8.3650), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS')));
INSERT INTO Station VALUES ('S015', 'Station O',TCoordonnees(48.8690, 2.3660), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S016', 'Station P',TCoordonnees(48.8700, 9.3670), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S017', 'Station Q',TCoordonnees(48.8710, 2.3680), 0,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET')));
INSERT INTO Station VALUES ('S018', 'BEZ',TCoordonnees(42.2557, 3.3550), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));

INSERT INTO Station VALUES ('S019', 'Station R',TCoordonnees(78.8720, 2.3690), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS')));
INSERT INTO Station VALUES ('S020', 'Station S',TCoordonnees(48.8730, 3.3700), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S021', 'Station T',TCoordonnees(48.8740, 4.3710), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S022', 'Station U',TCoordonnees(48.8750, 5.3720), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S023', 'Station V',TCoordonnees(48.8760, 6.3730), 1,T_Set_Ref_Ligne(),T_Set_Ref_Troncon(),T_Set_Ref_Moyen((SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='TRN'),(SELECT REF(m) FROM Moytransport m WHERE m.Abreviation='MET')));

--mise à jour de la table Moytransport_Station
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1) BUS
INSERT INTO TABLE (
  SELECT mt.Moytransport_Station
  FROM Moytransport mt
  WHERE mt.Abreviation = 'BUS'
)
SELECT REF(s)
  FROM Station s,TABLE(s.Station_MoyenTransport) t
  WHERE DEREF(value(t)).Abreviation = 'BUS';


-- 2) MET
INSERT INTO TABLE (
  SELECT mt.Moytransport_Station
  FROM Moytransport mt
  WHERE mt.Abreviation = 'MET'
)
SELECT REF(s)
  FROM Station s,TABLE(s.Station_MoyenTransport) t
  WHERE DEREF(value(t)).Abreviation = 'MET';

-- 3) TRM
INSERT INTO TABLE (
  SELECT mt.Moytransport_Station
  FROM Moytransport mt
  WHERE mt.Abreviation = 'TRM'
)
SELECT REF(s)
  FROM Station s,TABLE(s.Station_MoyenTransport) t
  WHERE DEREF(value(t)).Abreviation = 'TRM';


-- 4) TRN
INSERT INTO TABLE (
  SELECT mt.Moytransport_Station
  FROM Moytransport mt
  WHERE mt.Abreviation = 'TRN'
)
SELECT REF(s)
  FROM Station s,TABLE(s.Station_MoyenTransport) t
  WHERE DEREF(value(t)).Abreviation = 'TRN';
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Insertion des lignes
INSERT INTO Ligne VALUES ('B001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('B002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('B003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('B004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('B005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S019'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S015'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('B006', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S019'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S014'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S020'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S021'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S021'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S023'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TM006', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S022'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S023'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('TN006', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S022'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S019'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
INSERT INTO Ligne VALUES ('M006', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S023'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());

-- This line is intentionally incorrect to trigger the verification constraint
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
 --la station DE depart ne dessert pas ce moyen de transport choisi
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());
-- la station de depart et d'arrivee sont les memes
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'), T_Set_Ref_Troncon(), T_Set_Ref_Navette());

-- mise a jour de Moytransport_Ligne apres insertion de lignes
-- 1) BUS
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'BUS'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'BUS';

-- 2) MET
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'MET'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'MET';

-- 3) TRM
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'TRM'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'TRM';

-- 4) TRN
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'TRN'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'TRN';


----------------------------------------mise a jour de station_Ligne  apres insertion de lignes---------------------------------------
-- 1) Station A
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S001'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S001' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S001');
-- 2) Station B
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S002'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S002' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S002');
-- 3) Station C
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S003'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S003' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S003');
-- 4) Station D
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S004'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S004' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S004');
-- 5) Station E
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S005'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S005' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S005');
-- 6) Station F
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S006'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S006' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S006');
-- 7) Station G
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S007'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S007' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S007');
-- 8) Station H
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S008'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S008' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S008');
-- 9) Station I
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S009'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S009' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S009');
-- 10) Station J
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S010'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S010' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S010');
-- 11) Station K
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S011'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S011' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S011');
-- 12) Station L
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S012'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S012' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S012');
-- 13) Station M
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S013'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S013' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S013');
-- 14) Station N
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S014'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S014' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S014');
-- 15) Station O
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S015'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S015' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S015');
-- 16) Station P
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S016'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S016' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S016');
-- 17) Station Q
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S017'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S017' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S017');
-- 18) Station BEZ
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S018'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S018' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S018');
-- 19) Station R
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S019'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S019' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S019');
-- 20) Station S
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S020'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S020' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S020');
-- 21) Station T
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S021'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S021' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S021');
 -- 22) Station U
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S022'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S022' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S022');
-- 23) Station V
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S023'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S023' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S023');


-- ------------------------------------------------------------Insertion des tronçons----------------------------------------------------- 

-- Tronçons avec une seule ligne associée
INSERT INTO Troncon VALUES (
  'T001',
  5.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M001'),
  NULL
);
INSERT INTO Troncon VALUES (
  'T002',
  3.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M002'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T003',
  7.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM001'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T004',
  4.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN001'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T005',
  6.5,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B004'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T006',
  8.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN003'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T007',
  10.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B001'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T008',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M002'),
  NULL
);


INSERT INTO Troncon VALUES (
  'T009',
  6.5,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B006')
);

INSERT INTO Troncon VALUES (
  'T010',
  8.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN006'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002')
);

INSERT INTO Troncon VALUES (
  'T011',
  10.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B005')
);
INSERT INTO Troncon VALUES (
  'T013',
  5.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B006'),
  NULL
);


INSERT INTO Troncon VALUES (
  'T012',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M005')
);



INSERT INTO Troncon VALUES (
  'T014',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S015'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S012'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN003')
);
INSERT INTO Troncon VALUES (
  'T015',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S019'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S022'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B005'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B006')
);
-- verfication de la contrainte d'integrite de la table troncon
-- 1) Stations différentes
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M003')
);
--  -- 2) Longueur positive
INSERT INTO Troncon VALUES (
  'T013',
  0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M003')
);
  -- 3) Au moins une ligne
  INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  NULL,
  NULL
);
-- 4) Pas deux fois la même ligne
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004')
);
-- 5) La station de départ dessert le moyen de transport choisi
--STATION DE DE DEBUT NE CONTINENT PAS MOYENN DE TRANSPORT METRO
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M003')
);

--STATION DE DE FIN NE CONTINENT PAS MOYENN DE TRANSPORT METRO
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M003')
);
-- 7) Vérification que les deux lignes (si présentes) utilisent le même moyen de transport
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM003')
);

---------------------------------------------------------------------------------------------------------
--ajouter insertion dans Station_Troncons
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S001'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S001' OR DEREF(t.Troncon_StationFin).CodeStation = 'S001');
-- 2) Station B
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S002'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S002' OR DEREF(t.Troncon_StationFin).CodeStation = 'S002');
-- 3) Station C
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S003'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S003' OR DEREF(t.Troncon_StationFin).CodeStation = 'S003');
-- 4) Station D
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S004'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S004' OR DEREF(t.Troncon_StationFin).CodeStation = 'S004');
-- 5) Station E
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S005'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S005' OR DEREF(t.Troncon_StationFin).CodeStation = 'S005');
-- 6) Station F
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S006'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S005' OR DEREF(t.Troncon_StationFin).CodeStation = 'S006');
-- 7) Station G
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S007'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S007' OR DEREF(t.Troncon_StationFin).CodeStation = 'S007');
-- 8) Station H
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S008'
)
(SELECT REF(t)
  FROM Troncon t
    WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S008' OR DEREF(t.Troncon_StationFin).CodeStation = 'S008');
  -- 9) Station I
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S009'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S009' OR DEREF(t.Troncon_StationFin).CodeStation = 'S009');
  -- 10) Station J
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S010'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S010' OR DEREF(t.Troncon_StationFin).CodeStation = 'S010');
  -- 11) Station K
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S011'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S011' OR DEREF(t.Troncon_StationFin).CodeStation = 'S011');
  -- 12) Station L
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S012'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S012' OR DEREF(t.Troncon_StationFin).CodeStation = 'S012');
  -- 13) Station M
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S013'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S013' OR DEREF(t.Troncon_StationFin).CodeStation = 'S013');
  -- 14) Station N
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S014'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S014' OR DEREF(t.Troncon_StationFin).CodeStation = 'S014');
  -- 15) Station O
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S015'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S015' OR DEREF(t.Troncon_StationFin).CodeStation = 'S015');
  -- 16) Station P
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S016'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S016' OR DEREF(t.Troncon_StationFin).CodeStation = 'S016');
  -- 17) Station Q
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S017'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S017' OR DEREF(t.Troncon_StationFin).CodeStation = 'S017');
  -- 18) Station BEZ
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S018'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S018' OR DEREF(t.Troncon_StationFin).CodeStation = 'S018');
   -- 19) Station R
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S019'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S019' OR DEREF(t.Troncon_StationFin).CodeStation = 'S019');
   -- 20) Station S
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S020'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S020' OR DEREF(t.Troncon_StationFin).CodeStation = 'S020');
   -- 21) Station T
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S021'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S021' OR DEREF(t.Troncon_StationFin).CodeStation = 'S021');
   -- 22) Station U
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S022'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S022' OR DEREF(t.Troncon_StationFin).CodeStation = 'S022');
   -- 23) Station V
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S023'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDebut).CodeStation = 'S023' OR DEREF(t.Troncon_StationFin).CodeStation = 'S023');
  -- -----------------------------ajouter insertion dans Ligne_Troncons---------------------------------------------
  -- 1) Ligne B001
  INSERT INTO TABLE(
    SELECT l.Ligne_Troncon 
     FROM Ligne l 
    WHERE l.CodeLigne = 'B001'
  )
  (SELECT REF(t)
    FROM Troncon t
      WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B001' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B001');
-- 2) Ligne M001
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M001'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M001' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M001');
-- 3) Ligne TM001
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM001'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM001' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM001');
-- 4) Ligne TN001
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN001'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN001' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN001');

-- 5) Ligne B002
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'B002'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B002' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B002');
-- 6) Ligne M002
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M002'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M002' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M002');
-- 7) Ligne TM002
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM002'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM002' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM002');
-- 8) Ligne TN002
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN002'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN002' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN002');
-- 9) Ligne B003
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'B003'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B003' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B003');
-- 10) Ligne M003
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M003'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M003' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M003');
     --11) Ligne TM003
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM003'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM003' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM003');
-- 12) Ligne TN003
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN003'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN003' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN003');
-- 13) Ligne B004
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'B004'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B004' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B004');
-- 14) Ligne M004
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M004'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M004' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M004');
-- 15) Ligne TM004
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM004'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM004' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM004');
-- 16) Ligne TN004
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN004'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN004' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN004');
-- 17) Ligne B005=>
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'B005'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B005' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B005');
-- 18) Ligne TN005
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN005'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN005' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN005');
--19) Ligne B006
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'B006'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'B006' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'B006');
--20) Ligne TM005
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM005'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM005' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM005');
--21) Ligne M005
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M005'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M005' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M005');
--22) Ligne TM006
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TM006'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TM006' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TM006');
--23) Ligne TN006
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'TN006'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'TN006' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'TN006');
--24) Ligne M006
    INSERT INTO TABLE(
      SELECT l.Ligne_Troncon 
      FROM Ligne l 
      WHERE l.CodeLigne = 'M006'
    )
    (SELECT REF(t)
      FROM Troncon t
     WHERE DEREF(t.Troncon__Ligne1).CodeLigne = 'M006' OR DEREF(t.Troncon__Ligne2).CodeLigne = 'M006');


-- ---------------------------------------------------Insertion des navettes---------------------------------------------------------------


-- BUS (ligne B001)
INSERT INTO Navette VALUES (
  'N001', 'Mercedes', 2020,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B001'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'),T_Set_Ref_Voyage() 
);

-- METRO (ligne M001)
INSERT INTO Navette VALUES (
  'N002', 'Alstom', 2019,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M001'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'),
T_Set_Ref_Voyage()
);

-- TRAM (ligne TR001)
INSERT INTO Navette VALUES (
  'N003', 'CAF', 2021,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM001'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'),
T_Set_Ref_Voyage()
);

-- TRAIN (ligne TR002)
INSERT INTO Navette VALUES (
  'N004', 'Bombardier', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);

-- TRAIN (ligne TN001)
INSERT INTO Navette VALUES (
  'N005', 'Siemens', 2021,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN001'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);

-- TRAIN (ligne TN002)
INSERT INTO Navette VALUES (
  'N006', 'Hitachi', 2016,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);

-- TRAIN (ligne TN003)
INSERT INTO Navette VALUES (
  'N007', 'Hyundai Rotem', 2025,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN003'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);
-- TRAIN (ligne TN004)
INSERT INTO Navette VALUES (
  'N008', 'Bombardier', 2023,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN004'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage());
-- BUS (ligne B002)
INSERT INTO Navette VALUES (
  'N009', 'Iveco', 2023,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B002'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'),
T_Set_Ref_Voyage()  
);
-- metro (ligne M002)
INSERT INTO Navette VALUES (
  'N010', 'Alstom', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M002'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'),
T_Set_Ref_Voyage()
);
-- TRAM (ligne TM002)
INSERT INTO Navette VALUES (
  'N011', 'CAF', 2021,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM002'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'),
T_Set_Ref_Voyage()
);
-- TRAIN (ligne TN005)
INSERT INTO Navette VALUES (
  'N012', 'Bombardier', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN005'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);
--BUS (ligne B003)
INSERT INTO Navette VALUES (
  'N013', 'Mercedes', 2020,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B003'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'),
T_Set_Ref_Voyage()
);
-- BUS (ligne B004)
INSERT INTO Navette VALUES (
  'N014', 'Mercedes', 2020,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B004'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'),
T_Set_Ref_Voyage()
);
--metro (ligne M006)
INSERT INTO Navette VALUES (
  'N015', 'Alstom', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M006'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'MET'),
T_Set_Ref_Voyage()
);
-- TRAM (ligne TM003)
INSERT INTO Navette VALUES (
  'N016', 'CAF', 2021,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM003'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRM'),
T_Set_Ref_Voyage()
);
-- TRAIN (ligne TN006)
INSERT INTO Navette VALUES (
  'N017', 'Bombardier', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN006'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'TRN'),
T_Set_Ref_Voyage()
);


--mise a jour dans MoyenTransport_Navette apres insertion de navette
-- 1) BUS
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'BUS'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'BUS';

-- 2) MET
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'MET'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'MET';

-- 3) TRM
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'TRM'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'TRM';

-- 4) TRN
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM Moytransport mt 
   WHERE mt.Abreviation = 'TRN'
)
SELECT REF(n)
  FROM Navette n
    WHERE DEREF(n.Navette_Moytransport).Abreviation = 'TRN';
-- Mise à jour dans Ligne_Navette après insertion de navette
    -- 1) Ligne B001
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'B001'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B001');

    -- 2) Ligne M001
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'M001'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M001');

    -- 3) Ligne TM001
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TM001'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM001');

    -- 4) Ligne TN001
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TN001'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN001');
    -- 5) Ligne B002
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'B002'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B002');

    -- 6) Ligne M002
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'M002'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M002');

    -- 7) Ligne TM002
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TM002'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM002');
-- 8) Ligne TN002
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TN002'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN002');

    -- 9) Ligne B003
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'B003'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B003');

    -- 10) Ligne M003
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'M003'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M003');

    -- 11) Ligne TM003
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TM003'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM003');

    -- 12) Ligne TN003
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TN003'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN003');

    -- 13) Ligne B004
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'B004'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B004');

    -- 14) Ligne M004
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'M004'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M004');

    -- 15) Ligne TM004
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TM004'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM004');

    -- 16) Ligne TN004
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette
      FROM Ligne l
      WHERE l.CodeLigne = 'TN004'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN004');
    -- 17) Ligne B005
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'B005'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B005');
    -- 18) Ligne TN005
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'TN005'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN005');
    -- 19) Ligne B006
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'B006'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'B006');
    -- 20) Ligne TM005
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'TM005'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM005');
    -- 21) Ligne M005
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'M005'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M005');
    -- 22) Ligne TM006
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'TM006'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TM006');
    -- 23) Ligne TN006
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'TN006'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'TN006');
    -- 24) Ligne M006
    INSERT INTO TABLE(
      SELECT l.Ligne_Navette  
      FROM Ligne l
      WHERE l.CodeLigne = 'M006'
    )
     (SELECT REF(n)
    FROM Navette n
    WHERE DEREF(n.Navette_Ligne).CodeLigne = 'M006');


-- Insertion des voyages
INSERT INTO Voyage VALUES ('V0001', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'),'06:00', 'Aller', 40, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0002', 30, TO_DATE('02-01-2025', 'DD-MM-YYYY'), '07:00', 'Retour', 35, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0003', 20, TO_DATE('03-01-2025', 'DD-MM-YYYY'), '06:30', 'Aller', 50, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0004', 20, TO_DATE('06-01-2025', 'DD-MM-YYYY'), '07:30', 'Retour', 30, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0005', 50, TO_DATE('08-01-2025', 'DD-MM-YYYY'), '08:30', 'Retour', 60, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0006', 50, TO_DATE('05-01-2025', 'DD-MM-YYYY'), '09:30', 'Aller', 40, 'accident', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0007', 40, TO_DATE('07-01-2025', 'DD-MM-YYYY'), '10:30', 'Retour', 20, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N004'));
INSERT INTO Voyage VALUES ('V0008', 40, TO_DATE('03-02-2025', 'DD-MM-YYYY'), '2:30', 'Retour', 20, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N007'));

--ajouter plusieurs voyages par jour, sur une période de deux mois au minimum du 01-01-2025 au 01-03-2025)
BEGIN
  FOR d IN 1..60 LOOP -- Étendre la période à 60 jours pour deux mois
    FOR v IN 1..5 LOOP -- 5 voyages par jour
      INSERT INTO Voyage VALUES (
        'V' || TO_CHAR(1000 + (d - 1) * 5 + v, 'FM0000'),
        30 + MOD(v, 10), -- Durée aléatoire
        TO_DATE('01-01-2025', 'DD-MM-YYYY') + (d - 1), -- Date incrémentée
        TO_CHAR(TO_DATE('06:00', 'HH24:MI') + NUMTODSINTERVAL(MOD(v, 24), 'HOUR'), 'HH24:MI'), -- Heure départ
        CASE MOD(v, 2) WHEN 0 THEN 'Aller' ELSE 'Retour' END, -- Direction
        50 + MOD(v, 1000), -- Nombre passagers
        CASE MOD(v, 4) 
          WHEN 0 THEN 'On time' 
          WHEN 1 THEN 'retard' 
          WHEN 2 THEN 'accident'
          ELSE 'panne' 
        END, -- Observation
        (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = CASE MOD(v + d, 17) + 1 
          WHEN 1 THEN 'N001' 
          WHEN 2 THEN 'N002' 
          WHEN 3 THEN 'N003' 
          WHEN 4 THEN 'N004' 
          WHEN 5 THEN 'N005' 
          WHEN 6 THEN 'N006' 
          WHEN 7 THEN 'N007' 
          WHEN 8 THEN 'N008' 
          WHEN 9 THEN 'N009' 
          WHEN 10 THEN 'N010' 
          WHEN 11 THEN 'N011' 
          WHEN 12 THEN 'N012' 
          WHEN 13 THEN 'N013' 
          WHEN 14 THEN 'N014' 
          WHEN 15 THEN 'N015' 
          WHEN 16 THEN 'N016' 
          ELSE 'N017' 
        END)
      );
    END LOOP;
  END LOOP;
  -- Mise à jour des voyages dans les navettes
  FOR navette_id IN (
    SELECT DISTINCT DEREF(v.Voyage_Navette).NumeroNavette AS NumeroNavette
    FROM Voyage v
  ) LOOP
    INSERT INTO TABLE(
      SELECT n.Navette_Voyage 
      FROM Navette n 
      WHERE n.NumeroNavette = navette_id.NumeroNavette
    )
    (SELECT REF(v)
      FROM Voyage v
      WHERE DEREF(v.Voyage_Navette).NumeroNavette = navette_id.NumeroNavette);
  END LOOP;
END;
/



--insertion 
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N001'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N001');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N002'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N002');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N003'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N003');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N004'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N004');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N005'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N005');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N006'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N006');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N007'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N007');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N008'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N008');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N009'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N009');
--
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N010'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N010');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N011'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N011');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N012'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N012');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N013'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N013');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N014'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N014');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N015'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N015');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N016'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N016');
 --
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N017'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N017');
-- ---------------------------------------------------Interrogation des données---------------------------------------------------------------



--E- Langage d’interrogation de données
--10. Lister tous les voyages (num, date, moyen de transport, navette) ayant enregistré un quelconque problème (panne, retard, accident, …)

SELECT 
    v.NumeroVoyage,
    v.DateVoyage,
    DEREF(n.Navette_Moytransport).Abreviation AS MoyenTransport,
    n.NumeroNavette,
    n.Marque,
    v.Observation
FROM 
    Voyage v,
    Navette n
WHERE 
    DEREF(v.Voyage_Navette).NumeroNavette = n.NumeroNavette
AND v.Observation IN ('panne','retard','accident');
--11. Lister toutes les lignes (numéro, début et fin) comportant une station principale
SELECT 
    l.CodeLigne,
    DEREF(l.Ligne_StationDepart).NomStation AS StationDepart,
    DEREF(l.Ligne_StationArrivee).NomStation AS StationArrivee
FROM 
    Ligne l
WHERE 
    DEREF(l.Ligne_StationDepart).EstPrincipale = 1
    OR DEREF(l.Ligne_StationArrivee).EstPrincipale = 1;

--12. Quelles sont les navettes (numéro, type de transport, année de mise en service) ayant effectué le maximum de voyages durant le mois de janvier 2025 ? Préciser le nombre de voyages.
SELECT 
    n.NumeroNavette AS NumeroNavette,
    DEREF(n.Navette_Moytransport).Abreviation AS TypeTransport,
    n.AnneeMiseEnCirculation AS AnneeMiseEnService,
    COUNT(v.NumeroVoyage) AS NombreVoyages
FROM 
    Navette n   
JOIN 
    Voyage v ON DEREF(v.Voyage_Navette).NumeroNavette = n.NumeroNavette
WHERE 
    v.DateVoyage BETWEEN TO_DATE('01-01-2025', 'DD-MM-YYYY') AND TO_DATE('31-01-2025', 'DD-MM-YYYY')
GROUP BY 
    n.NumeroNavette, DEREF(n.Navette_Moytransport).Abreviation, n.AnneeMiseEnCirculation
HAVING 
    COUNT(v.NumeroVoyage) = (
        SELECT MAX(NombreVoyages)
        FROM (
            SELECT COUNT(v2.NumeroVoyage) AS NombreVoyages
            FROM Voyage v2
            WHERE v2.DateVoyage BETWEEN TO_DATE('01-01-2025', 'DD-MM-YYYY') AND TO_DATE('31-01-2025', 'DD-MM-YYYY')
            GROUP BY DEREF(v2.Voyage_Navette).NumeroNavette
        )
    );
    --expliquer en dettailes cette requete
-- Cette requête permet de lister les navettes ayant effectué le maximum de voyages durant le mois de janvier 2025.
-- Elle sélectionne le numéro de la navette, le type de transport, l'année de mise en service et le nombre de voyages effectués.
-- La jointure entre Navette et Voyage est effectuée sur le numéro de la navette.
-- La condition WHERE filtre les voyages pour ne garder que ceux effectués en janvier 2025.
---- La sous-requête calcule le nombre de voyages pour chaque navette durant janvier 2025 et retourne le maximum.
-- La clause GROUP BY regroupe les résultats par navette, type de transport et année de mise en service.
-- La clause HAVING compare le nombre de voyages de chaque navette avec le maximum trouvé dans une sous-requête.
-- La sous-requête calcule le nombre de voyages pour chaque navette durant janvier 2025 et retourne le maximum.



--13. Quelles sont les stations  offrant au moins 2 moyens de transport ? (préciser la station et les moyens de transport offerts)
SELECT
    s.CodeStation AS Station,
    LISTAGG(DEREF(VALUE(m)).Abreviation, ', ') AS MoyensTransportOfferts
FROM
    Station s,
    TABLE(s.Station_MoyenTransport) m
GROUP BY
    s.CodeStation
HAVING
    COUNT(DISTINCT DEREF(VALUE(m)).Abreviation) >= 2;
