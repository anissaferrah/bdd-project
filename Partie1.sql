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
CREATE TABLESPACE SQL3_TBS DATAFILE 'sql3_tbs.dbf' SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE SQL3_TempTBS TEMPFILE 'sql3_temp_tbs.dbf' SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE UNLIMITED;

-- 4. Création de l'utilisateur
CREATE USER SQL3 IDENTIFIED BY monmotdepasse DEFAULT TABLESPACE SQL3_TBS TEMPORARY TABLESPACE SQL3_TempTBS;

-- 5. Attribution des privilèges
GRANT ALL PRIVILEGES TO SQL3;

-- C. Langage de définition de données
-- 6. Définition des types abstraits et associations
CREATE OR REPLACE TYPE TMoytransport AS OBJECT (
    Abreviation Varchar2(3),
    HeureOuverture DATE,
    HeureFermeture DATE,
    NbMoyenVoyageurs INTEGER
);
/
CREATE OR REPLACE TYPE TLigne AS OBJECT (
    CodeLigne Varchar2(10)
);
CREATE OR REPLACE TYPE TCoordonnees AS OBJECT (
  Longitude FLOAT,
  Latitude FLOAT
);
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
    AnneeMiseEnCirculation INTEGER
);
/
CREATE OR REPLACE TYPE TVoyage AS OBJECT (
    NumeroVoyage Varchar2(20),
    Duree INTEGER,
    DateVoyage DATE,
    HeureDebut DATE,
    Sens Varchar2(5),  -- 'Aller' ou 'Retour'
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

ALTER TYPE TStation ADD ATTRIBUTE Station_Ligne T_Set_Ref_Ligne CASCADE;
ALTER TYPE TStation ADD ATTRIBUTE Station_Troncons T_Set_Ref_Troncon CASCADE;
ALTER TYPE TStation ADD ATTRIBUTE Station_MoyenTransport T_Set_Ref_Moyen CASCADE;

ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Ligne T_Set_Ref_Ligne CASCADE;
ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Station T_Set_Ref_Station CASCADE;
ALTER TYPE TMoytransport ADD ATTRIBUTE Moytransport_Navette T_Set_Ref_Navette CASCADE;

ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationDebut REF TStation CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationFin REF TStation CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon__Ligne1 REF TLigne CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon__Ligne2 REF TLigne CASCADE;

ALTER TYPE TNavette ADD ATTRIBUTE Navette_Ligne REF TLigne CASCADE;
ALTER TYPE TNavette ADD ATTRIBUTE Navette_Moytransport REF TMoytransport CASCADE;
ALTER TYPE TNavette ADD ATTRIBUTE Navette_Voyage T_Set_Ref_Voyage CASCADE;

ALTER TYPE TVoyage ADD ATTRIBUTE Voyage_Navette REF TNavette CASCADE;

-- 7. Définition des méthodes
-- Méthode pour calculer la durée d'un tronçon
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

    v_duree := (SELF.LongueurKm / v_vitesse) * 60;
    RETURN ROUND(v_duree);
  END CalculerDuree;
END;
/


--Méthode pour chaque navette, Calculer le nombre total de voyages effectués  
ALTER TYPE TNavette ADD MEMBER FUNCTION CalculerNombreVoyages() RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TNavette AS
  MEMBER FUNCTION CalculerNombreVoyages() RETURN INTEGER IS
    v_nb INTEGER := 0;
  BEGIN
    SELECT COUNT(*)
    INTO   v_nb
    FROM   TABLE(SELF.Navette_Voyage);
    RETURN v_nb;
  END CalculerNombreVoyages;
END;
/

create or replace type tset_navette as table of tnavette;
-- Ajouter la méthode RetournerNavettes, la liste des navettes qui la desservent pour chaque ligne
ALTER TYPE TLigne ADD MEMBER FUNCTION RetournerNavettes() RETURN TSet_Navette CASCADE;
CREATE OR REPLACE TYPE BODY TLigne AS
  MEMBER FUNCTION RetournerNavettes() RETURN TSet_Navette IS
    liste_navette TSet_Navette;
  BEGIN
    SELECT CAST(MULTISET( select deref(VALUE(n)).Marque 
    FROM TABLE(SELF.Ligne_Navette) n
    WHERE DEREF(DEREF(n).Navette_Ligne).CodeLigne = SELF.CodeLigne) AS TSet_Navette) INTO liste_navette FROM dual;

    RETURN liste_navette;
  END RetournerNavettes;
END;
/

-- Méthode pour calculer le nombre de voyages d'une ligne
 -- Calculer le nombre total de voyages pour toutes les navettes de la ligne
ALTER TYPE TLigne ADD MEMBER FUNCTION NombreVoyagesLigne() RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TLigne AS
  MEMBER FUNCTION NombreVoyagesLigne() RETURN INTEGER IS
    v_nb INTEGER := 0;
  BEGIN
  FOR nav IN (SELECT * FROM TABLE(SELF.Ligne_Navette)) LOOP
    SELECT COUNT(*) INTO v_nb FROM TABLE(nav.Navette_Voyage);
    v_nb := v_nb + v_nb;
  END LOOP;

    RETURN v_nb;
  END NombreVoyagesLigne;
END;
/

-- Méthode pour renommer une station et mettre à jour les lignes/tronçons associées
ALTER TYPE TStation ADD MEMBER PROCEDURE RenommerStationEtMettreAJour(p_nouveauNom IN VARCHAR2) CASCADE;

CREATE OR REPLACE TYPE BODY TStation AS
  MEMBER PROCEDURE RenommerStationEtMettreAJour(p_nouveauNom IN VARCHAR2) IS
  BEGIN
    -- Update the station name
    UPDATE Station
    SET NomStation = p_nouveauNom
    WHERE CodeStation = SELF.CodeStation;

    -- Update lines where this station is the departure or arrival station
    UPDATE Ligne
    SET Ligne_StationDepart = REF(SELF)
    WHERE DEREF(Ligne_StationDepart).CodeStation = SELF.CodeStation;

    UPDATE Ligne
    SET Ligne_StationArrivee = REF(SELF)
    WHERE DEREF(Ligne_StationArrivee).CodeStation = SELF.CodeStation;

    -- Update tronçons where this station is the start or end station
    UPDATE Troncon
    SET Troncon_StationDebut = REF(SELF)
    WHERE DEREF(Troncon_StationDebut).CodeStation = SELF.CodeStation;

    UPDATE Troncon
    SET Troncon_StationFin = REF(SELF)
    WHERE DEREF(Troncon_StationFin).CodeStation = SELF.CodeStation;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END RenommerStationEtMettreAJour;
END;
/
-- Méthode pour calculer pour un moyen de transport donné (Exemple Métro), 
-- le nombre de voyages effectués à une date donnée (Exemple le 28-02-2025) 
-- et le nombre de voyageurs total.

ALTER TYPE TMoytransport ADD MEMBER FUNCTION CalculerVoyagesEtVoyageurs(p_date DATE) RETURN VARCHAR2 CASCADE;

CREATE OR REPLACE TYPE BODY TMoytransport AS
  MEMBER FUNCTION CalculerVoyagesEtVoyageurs(p_date DATE) RETURN VARCHAR2 IS
    v_nbVoyages INTEGER := 0;
    v_nbVoyageurs INTEGER := 0;
  BEGIN
    -- Calculer le nombre de voyages et le nombre total de voyageurs
    SELECT COUNT(DEREF(value(v)).NumeroVoyage), NVL(SUM(DEREF(value(v)).NbVoyageurs), 0)
    INTO   v_nbVoyages, v_nbVoyageurs
    FROM   TABLE(SELF.Moytransport_Navette) n, TABLE(n.Navette_Voyage) v
    WHERE  DEREF(value(v)).DateVoyage = p_date;

    -- Retourner les résultats sous forme de chaîne
    RETURN 'Nombre de voyages: ' || v_nbVoyages || ', Nombre total de voyageurs: ' || v_nbVoyageurs;
  END CalculerVoyagesEtVoyageurs;
END;

CREATE OR REPLACE TRIGGER trg_controle_moyen_transport_station
BEFORE INSERT OR UPDATE ON Station
FOR EACH ROW
DECLARE
    nb_moyens INTEGER;
BEGIN
    -- Apply the constraint only if the station is not principal
    IF :NEW.EstPrincipale = 0 THEN
        -- Count the number of associated means of transport
        SELECT COUNT(*) INTO nb_moyens
        FROM TABLE(:NEW.Station_MoyenTransport);

        -- Raise an error if more than one means of transport is associated
        IF nb_moyens > 1 THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'Une station non principale ne peut être associée qu’à un seul moyen de transport.');
        END IF;
    END IF;
END;
/
--verfication que la station de départ et d'arrivée dessert le moyen de transport choisi
CREATE OR REPLACE TRIGGER trg_verif_transport_sur_ligne
BEFORE INSERT OR UPDATE ON Ligne
FOR EACH ROW
DECLARE
  cnt_depart  INTEGER;
  cnt_arrivee INTEGER;
BEGIN
  -- 1) Vérifier que la station de départ dessert le moyen choisi
  SELECT COUNT(*) 
    INTO cnt_depart
    FROM TABLE(
      (SELECT VALUE(s).Station_MoyenTransport
         FROM Station s
        WHERE REF(s) = :NEW.Ligne_StationDepart)
    ) sm
   WHERE sm = :NEW.Ligne_MoyenTransport;
  
  -- 2) Vérifier que la station d’arrivée dessert le même moyen
  SELECT COUNT(*) 
    INTO cnt_arrivee
    FROM TABLE(
      (SELECT VALUE(s).Station_MoyenTransport
         FROM Station s
        WHERE REF(s) = :NEW.Ligne_StationArrivee)
    ) sm
   WHERE sm = :NEW.Ligne_MoyenTransport;
  
  -- 3) Bloquer si l’une des deux vérifications échoue
  IF cnt_depart = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20010,
      'Erreur : la station de départ ne dessert pas ce moyen de transport.'
    );
  ELSIF cnt_arrivee = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20011,
      'Erreur : la station d’arrivée ne dessert pas ce moyen de transport.'
    );
  END IF;
END;
/
--verfication trg_verif_troncon que le tronçon est valide 
CREATE OR REPLACE TRIGGER trg_verif_troncon
BEFORE INSERT OR UPDATE ON Troncon
FOR EACH ROW
DECLARE
  moyen1 REF TMoytransport;
  moyen2 REF TMoytransport;
  cnt1_deb INTEGER := 0;
  cnt1_fin INTEGER := 0;
  cnt2_deb INTEGER := 0;
  cnt2_fin INTEGER := 0;
BEGIN
  -- 1) Stations différentes
  IF :NEW.Troncon_StationDebut = :NEW.Troncon_StationFin THEN
    RAISE_APPLICATION_ERROR(-20020, 'Un tronçon doit relier deux stations différentes.');
  END IF;

  -- 2) Longueur positive
  IF :NEW.LongueurKm <= 0 THEN
    RAISE_APPLICATION_ERROR(-20021, 'La longueur doit être strictement positive.');
  END IF;

  -- 3) Au moins une ligne
  IF :NEW.Troncon__Ligne1 IS NULL AND :NEW.Troncon__Ligne2 IS NULL THEN
    RAISE_APPLICATION_ERROR(-20022, 'Le tronçon doit appartenir à au moins une ligne.');
  END IF;

  -- 4) Pas deux fois la même ligne
  IF :NEW.Troncon__Ligne1 IS NOT NULL AND :NEW.Troncon__Ligne2 IS NOT NULL AND
     :NEW.Troncon__Ligne1 = :NEW.Troncon__Ligne2 THEN
    RAISE_APPLICATION_ERROR(-20023, 'Le tronçon ne peut pas être lié deux fois à la même ligne.');
  END IF;

  -- 5) Vérification pour la ligne 1
  IF :NEW.Troncon__Ligne1 IS NOT NULL THEN
    -- Récupérer le moyen de transport de la ligne 1
    SELECT VALUE(l).Ligne_MoyenTransport INTO moyen1
    FROM Ligne l WHERE REF(l) = :NEW.Troncon__Ligne1;

    -- Vérifier station de début
    SELECT COUNT(*) INTO cnt1_deb
    FROM TABLE((SELECT VALUE(s).Station_MoyenTransport
                FROM Station s WHERE REF(s) = :NEW.Troncon_StationDebut))
    WHERE VALUE(moyen1) = VALUE(COLUMN_VALUE);

    -- Vérifier station de fin
    SELECT COUNT(*) INTO cnt1_fin
    FROM TABLE((SELECT VALUE(s).Station_MoyenTransport
                FROM Station s WHERE REF(s) = :NEW.Troncon_StationFin))
    WHERE VALUE(moyen1) = VALUE(COLUMN_VALUE);

    IF cnt1_deb = 0 THEN
      RAISE_APPLICATION_ERROR(-20024, 'La station de début ne dessert pas le moyen de transport de la ligne 1.');
    ELSIF cnt1_fin = 0 THEN
      RAISE_APPLICATION_ERROR(-20025, 'La station de fin ne dessert pas le moyen de transport de la ligne 1.');
    END IF;
  END IF;

  -- 6) Vérification pour la ligne 2
  IF :NEW.Troncon__Ligne2 IS NOT NULL THEN
    -- Récupérer le moyen de transport de la ligne 2
    SELECT VALUE(l).Ligne_MoyenTransport INTO moyen2
    FROM Ligne l WHERE REF(l) = :NEW.Troncon__Ligne2;

    -- Vérifier station de début
    SELECT COUNT(*) INTO cnt2_deb
    FROM TABLE((SELECT VALUE(s).Station_MoyenTransport
                FROM Station s WHERE REF(s) = :NEW.Troncon_StationDebut))
    WHERE VALUE(moyen2) = VALUE(COLUMN_VALUE);

    -- Vérifier station de fin
    SELECT COUNT(*) INTO cnt2_fin
    FROM TABLE((SELECT VALUE(s).Station_MoyenTransport
                FROM Station s WHERE REF(s) = :NEW.Troncon_StationFin))
    WHERE VALUE(moyen2) = VALUE(COLUMN_VALUE);

    IF cnt2_deb = 0 THEN
      RAISE_APPLICATION_ERROR(-20026, 'La station de début ne dessert pas le moyen de transport de la ligne 2.');
    ELSIF cnt2_fin = 0 THEN
      RAISE_APPLICATION_ERROR(-20027, 'La station de fin ne dessert pas le moyen de transport de la ligne 2.');
    END IF;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_verif_navette
BEFORE INSERT OR UPDATE ON Navette
FOR EACH ROW
DECLARE
  v_moyen_ligne REF TMoytransport;
BEGIN
  -- Récupérer le moyen de transport de la ligne associée
  SELECT l.Ligne_MoyenTransport
  INTO v_moyen_ligne
  FROM TLigne l
  WHERE REF(l) = :NEW.Navette_Ligne;

  -- Vérifier que le moyen de transport de la navette correspond à celui de la ligne
  IF v_moyen_ligne != :NEW.Navette_MoyenTransport THEN
    RAISE_APPLICATION_ERROR(-20030, 
      'Incohérence : Le moyen de transport de la navette ne correspond pas à celui de la ligne.');
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

-- 8. Définition des tables
CREATE TABLE TMoytransport OF TMoytransport (
    Abreviation PRIMARY KEY,
    CONSTRAINT chk_abreviation CHECK (Abreviation IN ('BUS', 'MET', 'TRM', 'TRN')),
    CONSTRAINT chk_heure_ouverture_fermeture CHECK (HeureOuverture < HeureFermeture)
) NESTED TABLE Moytransport_Ligne STORE AS table_Moytransport_Ligne,
    NESTED TABLE Moytransport_Station STORE AS table_Moytransport_Station,
    NESTED TABLE Moytransport_Navette STORE AS table_Moytransport_Navette;

CREATE TABLE Station OF TStation (
    CodeStation PRIMARY KEY
) NESTED TABLE Station_Ligne STORE AS table_Station_Ligne,
  NESTED TABLE Station_Troncons STORE AS table_Station_Troncons,
  NESTED TABLE Station_MoyenTransport STORE AS table_Station_MoyenTransport;

CREATE TABLE Ligne OF TLigne (
    CodeLigne PRIMARY KEY,
    FOREIGN KEY (Ligne_StationDepart) REFERENCES Station(CodeStation) NOT NULL,
    FOREIGN KEY (Ligne_StationArrivee) REFERENCES Station(CodeStation) NOT NULL,
    FOREIGN KEY (Ligne_MoyenTransport) REFERENCES TMoytransport(Abreviation),
    CONSTRAINT chk_station_depart_arrivee CHECK (Ligne_StationDepart != Ligne_StationArrivee)
) NESTED TABLE Ligne_Troncon STORE AS table_Ligne_Troncon,
  NESTED TABLE Ligne_Navette STORE AS table_Ligne_Navette;

CREATE TABLE Troncon OF TTroncon (
  NumeroTroncon PRIMARY KEY,
  FOREIGN KEY (Troncon_StationDebut) REFERENCES Station(CodeStation) NOT NULL,
  FOREIGN KEY (Troncon_StationFin) REFERENCES Station(CodeStation) NOT NULL,
  FOREIGN KEY (Troncon__Ligne1) REFERENCES Ligne(CodeLigne),
  FOREIGN KEY (Troncon__Ligne2) REFERENCES Ligne(CodeLigne),
  CONSTRAINT chk_station_debut_fin CHECK (Troncon_StationDebut != Troncon_StationFin),
  CONSTRAINT chk_troncon_ligne1_ligne2 CHECK (Troncon__Ligne1 != Troncon__Ligne2)
);

CREATE TABLE Navette OF TNavette (
    NumeroNavette PRIMARY KEY,
    FOREIGN KEY (Navette_Ligne) REFERENCES Ligne(CodeLigne),
    FOREIGN KEY (Navette_Moytransport) REFERENCES TMoytransport(Abreviation)
) NESTED TABLE Navette_Voyage STORE AS table_Navette_Voyage;

CREATE TABLE Voyage OF TVoyage (
    NumeroVoyage PRIMARY KEY,
    FOREIGN KEY (Voyage_Navette) REFERENCES Navette(NumeroNavette),
    CONSTRAINT chk_sens CHECK (Sens IN ('Aller', 'Retour')),
    CONSTRAINT chk_nbvoyageurs CHECK (NbVoyageurs >= 0)
);
-- Insertion des moyens de transport
INSERT INTO TMoytransport VALUES ('BUS', TO_DATE('06:00', 'HH24:MI'), TO_DATE('22:00', 'HH24:MI'), 200,Moytransport_Ligne(),Moytransport_Station(),Moytransport_Navette());
INSERT INTO TMoytransport VALUES ('MET', TO_DATE('05:30', 'HH24:MI'), TO_DATE('23:30', 'HH24:MI'),300, Moytransport_Ligne(),Moytransport_Station(),Moytransport_Navette());
INSERT INTO TMoytransport VALUES ('TRM', TO_DATE('06:00', 'HH24:MI'), TO_DATE('23:00', 'HH24:MI'), 500, Moytransport_Ligne(),Moytransport_Station(),Moytransport_Navette());
INSERT INTO TMoytransport VALUES ('TRN', TO_DATE('05:00', 'HH24:MI'), TO_DATE('23:59', 'HH24:MI'), 400, Moytransport_Ligne(),Moytransport_Station(),Moytransport_Navette());


-- Insertion des stations
INSERT INTO Station VALUES ('S001', 'Station A',TCoordonnees(48.8566, 2.3522), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN'))) ;
INSERT INTO Station VALUES ('S002', 'Station B',TCoordonnees(48.8570, 2.3530), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'))) ;
INSERT INTO Station VALUES ('S003', 'Station C',TCoordonnees( 48.8575, 2.3540), 0, Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S004', 'Station D',TCoordonnees( 48.8580, 2.3550), 1, Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S018', 'BEZ',TCoordonnees(42.2557, 3.3550), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S005', 'Station E',TCoordonnees(48.8590, 2.3560), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S006', 'Station F',TCoordonnees(48.8600, 2.3570), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM')));
INSERT INTO Station VALUES ('S007', 'Station G',TCoordonnees(48.8610, 2.3580), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S008', 'Station H',TCoordonnees(48.8620, 2.3590), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS')));
INSERT INTO Station VALUES ('S009', 'Station I',TCoordonnees(48.8630, 2.3600), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S010', 'Station J',TCoordonnees(48.8640, 2.3610), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S011', 'Station K',TCoordonnees(48.8650, 2.3620), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET')));
INSERT INTO Station VALUES ('S012', 'Station L',TCoordonnees(48.8660, 2.3630), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S013', 'Station M',TCoordonnees(48.8670, 2.3640), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S014', 'Station N',TCoordonnees(48.8680, 2.3650), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS')));
INSERT INTO Station VALUES ('S015', 'Station O',TCoordonnees(48.8690, 2.3660), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S016', 'Station P',TCoordonnees(48.8700, 2.3670), 1,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='BUS'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRM'),(SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='TRN')));
INSERT INTO Station VALUES ('S017', 'Station Q',TCoordonnees(48.8710, 2.3680), 0,Station_Ligne(),station_Troncons(),Station_MoyenTransport((SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation='MET')));

--MISE A JOUR DE Moytransport_Station()
-- 1) BUS
INSERT INTO TABLE(
  SELECT mt.Moytransport_Station 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'BUS'
)
SELECT REF(s)
  FROM Station s
 WHERE EXISTS (
   SELECT 1 FROM TABLE(s.Station_MoyenTransport) sm
    WHERE DEREF(sm).Abreviation = 'BUS'
 );

-- 2) MET
INSERT INTO TABLE(
  SELECT mt.Moytransport_Station 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'MET'
)
SELECT REF(s)
  FROM Station s
 WHERE EXISTS (
   SELECT 1 FROM TABLE(s.Station_MoyenTransport) sm
    WHERE DEREF(sm).Abreviation = 'MET'
 );

-- 3) TRM
INSERT INTO TABLE(
  SELECT mt.Moytransport_Station 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'TRM'
)
SELECT REF(s)
  FROM Station s
 WHERE EXISTS (
   SELECT 1 FROM TABLE(s.Station_MoyenTransport) sm
    WHERE DEREF(sm).Abreviation = 'TRM'
 );

-- 4) TRN
INSERT INTO TABLE(
  SELECT mt.Moytransport_Station 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'TRN'
)
SELECT REF(s)
  FROM Station s
 WHERE EXISTS (
   SELECT 1 FROM TABLE(s.Station_MoyenTransport) sm
    WHERE DEREF(sm).Abreviation = 'TRN'
 );


-- Insertion des lignes
INSERT INTO Ligne VALUES ('B001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('M001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TM001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TN001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('B002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('M002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TM002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('B003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('M003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TM003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TN003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('B004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'BEZ'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('M004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'BEZ'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TM004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'BEZ'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('TN004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'BEZ'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), Ligne_Troncon(), Ligne_Navette());
INSERT INTO Ligne VALUES ('B005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), Ligne_Troncon(), Ligne_Navette());
-- This line is intentionally incorrect to trigger the verification constraint
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), Ligne_Troncon(), Ligne_Navette());

--donner ici tous les lignes et leurs informations
-- 1) Ligne B001 => station départ S001, station arrivée S004, moyen de transport BUS
-- 2) Ligne M001 => station départ S001, station arrivée S004, moyen de transport MET
-- 3) Ligne TM001 => station départ S003, station arrivée S006, moyen de transport TRM
-- 4) Ligne TN001 => station départ S005, station arrivée S009, moyen de transport TRN
-- 5) Ligne B002 => station départ S007, station arrivée S010, moyen de transport BUS
-- 6) Ligne M002 => station départ S007, station arrivée S010, moyen de transport MET
-- 7) Ligne TM002 => station départ S007, station arrivée S010, moyen de transport TRM
-- 8) Ligne TN002 => station départ S005, station arrivée S010, moyen de transport TRN
-- 9) Ligne B003 => station départ S013, station arrivée S016, moyen de transport BUS
-- 10) Ligne M003 => station départ S013, station arrivée S016, moyen de transport MET
-- 11) Ligne TM003 => station départ S013, station arrivée S016, moyen de transport TRM
-- 12) Ligne TN003 => station départ S013, station arrivée S016, moyen de transport TRN
-- 13) Ligne B004 => station départ S018, station arrivée S004, moyen de transport BUS
-- 14) Ligne M004 => station départ S018, station arrivée S004, moyen de transport MET
-- 15) Ligne TM004 => station départ S018, station arrivée S004, moyen de transport TRM
-- 16) Ligne TN004 => station départ S018, station arrivée S004, moyen de transport TRN
-- 17) Ligne B005 => station départ S007, station arrivée S008, moyen de transport BUS

-- mise a jour de Moytransport_Ligne apres insertion de lignes
-- 1) BUS
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'BUS'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'BUS';

-- 2) MET
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'MET'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'MET';

-- 3) TRM
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'TRM'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'TRM';

-- 4) TRN
INSERT INTO TABLE(
  SELECT mt.Moytransport_Ligne 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'TRN'
)
SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_MoyenTransport).Abreviation = 'TRN';


--mise a jour de station_Ligne  apres insertion de lignes
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
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S017' OR DEREF(l.Ligne_StationArrivee).
CodeStation = 'S017');
-- 18) Station BEZ
INSERT INTO TABLE(
  SELECT s.Station_Ligne 
    FROM Station s 
   WHERE s.CodeStation = 'S018'
)
(SELECT REF(l)
  FROM Ligne l
 WHERE DEREF(l.Ligne_StationDepart).CodeStation = 'S018' OR DEREF(l.Ligne_StationArrivee).CodeStation = 'S018');


-- Insertion des tronçons corrigés avec des conditions respectées
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
  'T003',
  7.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M001'),
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
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B002'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T006',
  8.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T007',
  10.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B003'),
  NULL
);

INSERT INTO Troncon VALUES (
  'T008',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  NULL
);

-- Tronçons avec deux lignes associées
INSERT INTO Troncon VALUES (
  'T009',
  6.5,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M002')
);

INSERT INTO Troncon VALUES (
  'T010',
  8.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM002')
);

INSERT INTO Troncon VALUES (
  'T011',
  10.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S016'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M003')
);

INSERT INTO Troncon VALUES (
  'T012',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM004')
);
INSERT INTO Troncon VALUES (
  'T012',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S018'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B001'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM004')
);
--AJOUTER INSETION FAUSSE POUR TESTER LA CONTRAINTE DE VERIFICATION
INSERT INTO Troncon VALUES (
  'T013',
  12.0,
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'),
  (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'),
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M004'),--STATION DE DE FIN NE CONTINENT PAS MOYENN DE TRANSPORT METRO
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TM004')--STATION DE DE DEBUT NE CONTINENT PAS MOYENN DE TRANSPORT TRM
);

--ajouter insertion dans Station_Troncons
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S001'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S001' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S001');
-- 2) Station B
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S002'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S002' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S002');
-- 3) Station C
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S003'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S003' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S003');
-- 4) Station D
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S004'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S004' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S004');
-- 5) Station E
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S005'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S005' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S005');
-- 6) Station F
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S006'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S005' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S006');
-- 7) Station G
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S007'
)
(SELECT REF(t)
  FROM Troncon t
 WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S007' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S007');
-- 8) Station H
INSERT INTO TABLE(
  SELECT s.Station_Troncons 
    FROM Station s 
   WHERE s.CodeStation = 'S008'
)
(SELECT REF(t)
  FROM Troncon t
    WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S008' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S008');
  -- 9) Station I
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S009'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S009' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S009');
  -- 10) Station J
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S010'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S010' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S010');
  -- 11) Station K
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S011'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S011' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S011');
  -- 12) Station L
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S012'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S012' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S012');
  -- 13) Station M
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S013'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S013' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S013');
  -- 14) Station N
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S014'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S014' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S014');
  -- 15) Station O
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S015'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S015' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S015');
  -- 16) Station P
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S016'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S016' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S016');
  -- 17) Station Q
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S017'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S017' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S017');
  -- 18) Station BEZ
  INSERT INTO TABLE(
    SELECT s.Station_Troncons 
     FROM Station s 
    WHERE s.CodeStation = 'S018'
  )
  (SELECT REF(t)
    FROM Troncon t
   WHERE DEREF(t.Troncon_StationDepart).CodeStation = 'S018' OR DEREF(t.Troncon_StationArrivee).CodeStation = 'S018');
  -- ajouter insertion dans Ligne_Troncons
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

-- Insertion des navettes
-- BUS (ligne B001)
INSERT INTO Navette VALUES (
  'N001', 'Mercedes', 2020,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B001'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'),  Navette_Voyage()
);

-- METRO (ligne M001)
INSERT INTO Navette VALUES (
  'N002', 'Alstom', 2019,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M001'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'),
  Navette_Voyage()
);

-- TRAM (ligne TR001)
INSERT INTO Navette VALUES (
  'N003', 'CAF', 2021,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TR001'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'),
  Navette_Voyage()
);

-- TRAIN (ligne TR002)
INSERT INTO Navette VALUES (
  'N004', 'Bombardier', 2022,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TR002'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'),
  Navette_Voyage()
);

-- TRAIN (ligne TN001)
INSERT INTO Navette VALUES (
  'N005', 'Siemens', 2023,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN001'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'),
  Navette_Voyage()
);

-- TRAIN (ligne TN002)
INSERT INTO Navette VALUES (
  'N006', 'Hitachi', 2024,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'),
  Navette_Voyage()
);

-- TRAIN (ligne TN003)
INSERT INTO Navette VALUES (
  'N007', 'Hyundai Rotem', 2025,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN003'),
  (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'),
  Navette_Voyage()
);
--mise a jour dans MoyenTransport_Navette apres insertion de navette
-- 1) BUS
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'BUS'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'BUS';

-- 2) MET
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'MET'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'MET';

-- 3) TRM
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM TMoytransport mt 
   WHERE mt.Abreviation = 'TRM'
)
SELECT REF(n)
  FROM Navette n
 WHERE DEREF(n.Navette_Moytransport).Abreviation = 'TRM';

-- 4) TRN
INSERT INTO TABLE(
  SELECT mt.Moytransport_Navette 
    FROM TMoytransport mt 
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


-- Insertion des voyages
INSERT INTO Voyage VALUES ('V0001', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('06:00', 'HH24:MI'), 'Aller', 40, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0002', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('07:00', 'HH24:MI'), 'Retour', 35, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0003', 20, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('06:30', 'HH24:MI'), 'Aller', 150, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0004', 20, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('07:30', 'HH24:MI'), 'Retour', 140, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0005', 50, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('08:30', 'HH24:MI'), 'Retour', 140, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0006', 50, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('09:30', 'HH24:MI'), 'Aller', 140, 'accident', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0007', 40, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('10:30', 'HH24:MI'), 'Retour', 140, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N004'));
--mise a jour dans Navette_Voyage apres insertion dans voyage pour toutes les navettes
INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N001'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N001');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N002'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N002');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N003'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N003');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N004'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N004');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N005'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N005');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N006'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N006');

INSERT INTO TABLE(
  SELECT n.Navette_Voyage 
    FROM Navette n 
   WHERE n.NumeroNavette = 'N007'
)
(SELECT REF(v)
  FROM Voyage v
 WHERE DEREF(v.Voyage_Navette).NumeroNavette = 'N007');




--E- Langage d’interrogation de données
--10. Lister tous les voyages (num, date, moyen de transport, navette) ayant enregistré un quelconque problème (panne, retard, accident, …)

SELECT 
    v.NumeroVoyage,
    v.DateVoyage,
    DEREF(n.Navette_Moytransport).Abreviation AS MoyenTransport,
    n.NumeroNavette,
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
--13. Quelles sont les stations principales offrant au moins 2 moyens de transport ? (préciser la station et les moyens de transport offerts)
SELECT 
    s.CodeStation AS Station,
    LISTAGG(DEREF(m).Abreviation, ', ') AS MoyensTransportOfferts
FROM 
    Station s
JOIN 
    TABLE(s.Station_MoyenTransport) m
WHERE 
    s.EstPrincipale = 1
GROUP BY 
    s.CodeStation
HAVING 
    COUNT(DISTINCT DEREF(m).Abreviation) >= 2;
