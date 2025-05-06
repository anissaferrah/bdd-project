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

CREATE OR REPLACE TYPE TLigne AS OBJECT (
    CodeLigne Varchar2(10)
);

CREATE OR REPLACE TYPE TStation AS OBJECT (
    CodeStation Varchar2(10),
    NomStation Varchar2(100),
    Longitude FLOAT,
    Latitude FLOAT,
    EstPrincipale NUMBER(1)
);

CREATE OR REPLACE TYPE TTroncon AS OBJECT (
    NumeroTroncon Varchar2(10),
    LongueurKm FLOAT
);

CREATE OR REPLACE TYPE TNavette AS OBJECT (
    NumeroNavette Varchar2(20),
    Marque Varchar2(50),
    AnneeMiseEnCirculation INTEGER
);

CREATE TYPE TVoyage AS OBJECT (
    NumeroVoyage Varchar2(20),
    Duree INTEGER,
    DateVoyage DATE,
    HeureDebut DATE,
    Sens VARCHAR2(6),  -- 'Aller' ou 'Retour'
    NbVoyageurs INTEGER,
    Observation Varchar2(20)
);

-- Associations
CREATE TYPE T_Set_Ref_Moyen AS TABLE OF REF TMoytransport;
CREATE TYPE T_Set_Ref_Station AS TABLE OF REF TStation;
CREATE TYPE T_Set_Ref_Ligne AS TABLE OF REF TLigne;
CREATE TYPE T_Set_Ref_Navette AS TABLE OF REF TNavette;
CREATE TYPE T_Set_Ref_Voyage AS TABLE OF REF TVoyage;
CREATE TYPE T_Set_Ref_Troncon AS TABLE OF REF TTroncon;

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

ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationDebut REF TStation CASCADE;
ALTER TYPE TTroncon ADD ATTRIBUTE Troncon_StationFin REF TStation CASCADE;

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
--Méthode Calculer pour chaque navette, le nombre total de voyages effectués.
ALTER TYPE TNavette ADD MEMBER FUNCTION CalculerNombreVoyages(p_dateDebut DATE, p_dateFin DATE) RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TNavette AS
    MEMBER FUNCTION CalculerNombreVoyages(p_dateDebut DATE, p_dateFin DATE) RETURN INTEGER IS
        v_nb INTEGER := 0;
    BEGIN
        IF p_dateDebut > p_dateFin THEN
            RAISE_APPLICATION_ERROR(-20001, 'La date de début ne peut pas être postérieure à la date de fin.');
        END IF;

        SELECT COUNT(*)
        INTO   v_nb
        FROM   Voyage v
        WHERE  v.Voyage_Navette IS NOT NULL
             AND DEREF(v.Voyage_Navette).NumeroNavette = SELF.NumeroNavette
             AND v.DateVoyage BETWEEN p_dateDebut AND p_dateFin;

        RETURN v_nb;
    END CalculerNombreVoyages;
END;
/

-- ajouter la méthode RetournerNavettes pour chaque ligne, la liste des navettes qui la desservent.
ALTER TYPE TLigne ADD MEMBER FUNCTION RetournerNavettes() RETURN T_Set_Ref_Navette CASCADE;
-- méthode Retourner pour chaque ligne, la liste des navettes qui la desservent.
CREATE OR REPLACE TYPE BODY TLigne AS
    MEMBER FUNCTION RetournerNavettes() RETURN T_Set_Ref_Navette IS
        v_navettes T_Set_Ref_Navette := T_Set_Ref_Navette();
    BEGIN
        SELECT CAST(COLLECT(REF(n)) AS T_Set_Ref_Navette)
        INTO   v_navettes
        FROM   Navette n
        WHERE  DEREF(n.Navette_Ligne).CodeLigne = SELF.CodeLigne;

        RETURN v_navettes;
    END RetournerNavettes;
END;
/




-- Méthode pour calculer le nombre de voyages d'une ligne
ALTER TYPE TLigne ADD MEMBER FUNCTION NombreVoyagesLigne(p_dateDebut DATE, p_dateFin DATE) RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY TLigne AS
  MEMBER FUNCTION NombreVoyagesLigne(p_dateDebut DATE, p_dateFin DATE) RETURN INTEGER IS
    v_nb INTEGER;
  BEGIN
    SELECT COUNT(*)
    INTO   v_nb
    FROM   TVoyage v
    JOIN   TNavette n ON v.NumeroNavette = n.NumeroNavette
    WHERE  n.CodeLigne = SELF.CodeLigne
      AND  v.DateVoyage BETWEEN p_dateDebut AND p_dateFin;
    RETURN v_nb;
  END;
END;
/

-- Méthode pour renommer une station
ALTER TYPE TStation ADD MEMBER PROCEDURE RenommerStation(p_nouveauNom IN VARCHAR2) CASCADE;

CREATE OR REPLACE TYPE BODY TStation AS
  MEMBER PROCEDURE RenommerStation(p_nouveauNom IN VARCHAR2) IS
  BEGIN
    UPDATE THE (SELECT * FROM Station WHERE CodeStation = SELF.CodeStation)
      SET NomStation = p_nouveauNom;

    FOR ref_ligne IN (
      SELECT REF(l) AS r
        FROM Ligne l
       WHERE DEREF(l.Ligne_StationDepart).CodeStation = SELF.CodeStation
          OR DEREF(l.Ligne_StationArrivee).CodeStation = SELF.CodeStation
    ) LOOP
      UPDATE THE (SELECT * FROM Station WHERE CodeStation = SELF.CodeStation)
        SET NomStation = p_nouveauNom;
    END LOOP;

    FOR ref_troncon IN (
      SELECT REF(t) AS r
        FROM Troncon t
       WHERE DEREF(t.Troncon_StationDebut).CodeStation = SELF.CodeStation
          OR DEREF(t.Troncon_StationFin).CodeStation = SELF.CodeStation
    ) LOOP
      UPDATE THE (SELECT * FROM Station WHERE CodeStation = SELF.CodeStation)
        SET NomStation = p_nouveauNom;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END RenommerStation;
END;
/

CREATE OR REPLACE TRIGGER trg_controle_moyen_transport_station
BEFORE INSERT OR UPDATE ON TMoytransport
FOR EACH ROW
DECLARE
    nb_stations INTEGER;
BEGIN
    -- Compter le nombre de stations associées au moyen de transport
    SELECT COUNT(*) INTO nb_stations
    FROM TABLE(:NEW.Moytransport_Station);

    -- Si plus d'une station est associée à un moyen de transport => erreur
    IF nb_stations > 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 
            '❌ Un moyen de transport ne peut pas être associé à plus d''une station.');
    END IF;
END;
/

-- 8. Définition des tables
CREATE TABLE TMoytransport OF TMoytransport (
    Abreviation PRIMARY KEY,
    CONSTRAINT chk_abreviation CHECK (Abreviation IN ('BUS', 'MET', 'TRM', 'TRN')),
    CONSTRAINT chk_heure_ouverture_fermeture CHECK (HeureOuverture < HeureFermeture)
) NESTED TABLE Moytransport_Ligne STORE AS table_Moytransport_Ligne,
    NESTED TABLE Moytransport_Station STORE AS table_Moytransport_Station;

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
    CONSTRAINT chk_station_debut_fin CHECK (Troncon_StationDebut != Troncon_StationFin)
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
INSERT INTO TMoytransport VALUES ('BUS', TO_DATE('06:00', 'HH24:MI'), TO_DATE('22:00', 'HH24:MI'), 50);
INSERT INTO TMoytransport VALUES ('MET', TO_DATE('05:30', 'HH24:MI'), TO_DATE('23:30', 'HH24:MI'), 200);
INSERT INTO TMoytransport VALUES ('TRM', TO_DATE('06:00', 'HH24:MI'), TO_DATE('23:00', 'HH24:MI'), 100);
INSERT INTO TMoytransport VALUES ('TRN', TO_DATE('05:00', 'HH24:MI'), TO_DATE('23:59', 'HH24:MI'), 300);


-- Insertion des stations
INSERT INTO Station VALUES ('S001', 'Station A', 48.8566, 2.3522, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S002', 'Station B', 48.8570, 2.3530, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S003', 'Station C', 48.8575, 2.3540, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S004', 'Station D', 48.8580, 2.3550, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S005', 'BEZ', 42.2557, 3.3550, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S006', 'Station E', 48.8590, 2.3560, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S007', 'Station F', 48.8600, 2.3570, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S008', 'Station G', 48.8610, 2.3580, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S009', 'Station H', 48.8620, 2.3590, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S010', 'Station I', 48.8630, 2.3600, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S011', 'Station J', 48.8640, 2.3610, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S012', 'Station K', 48.8650, 2.3620, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S013', 'Station L', 48.8660, 2.3630, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S014', 'Station M', 48.8670, 2.3640, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S015', 'Station N', 48.8680, 2.3650, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S016', 'Station O', 48.8690, 2.3660, 0, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S017', 'Station P', 48.8700, 2.3670, 1, NULL, NULL, NULL);
INSERT INTO Station VALUES ('S018', 'Station Q', 48.8710, 2.3680, 0, NULL, NULL, NULL);

-- Insertion des lignes
INSERT INTO Ligne VALUES ('B001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL, NULL);
INSERT INTO Ligne VALUES ('B002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL, NULL);
INSERT INTO Ligne VALUES ('B003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL, NULL);
INSERT INTO Ligne VALUES ('B004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL, NULL);
INSERT INTO Ligne VALUES ('B005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL, NULL);
INSERT INTO Ligne VALUES ('M001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL, NULL);
INSERT INTO Ligne VALUES ('M002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL, NULL);
INSERT INTO Ligne VALUES ('M003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL, NULL);
INSERT INTO Ligne VALUES ('M004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL, NULL);
INSERT INTO Ligne VALUES ('M005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL, NULL);
INSERT INTO Ligne VALUES ('TR001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), NULL, NULL);
INSERT INTO Ligne VALUES ('TR002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);
INSERT INTO Ligne VALUES ('TR003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), NULL, NULL);
INSERT INTO Ligne VALUES ('TR004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), NULL, NULL);
INSERT INTO Ligne VALUES ('TN001', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);
INSERT INTO Ligne VALUES ('TN002', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);
INSERT INTO Ligne VALUES ('TN003', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S011'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);
INSERT INTO Ligne VALUES ('TN004', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S012'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);
INSERT INTO Ligne VALUES ('TN005', (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S013'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL, NULL);

-- Insertion des tronçons
INSERT INTO Troncon VALUES ('T001', 2.5, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S001'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'));
INSERT INTO Troncon VALUES ('T002', 3.0, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S002'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'));
INSERT INTO Troncon VALUES ('T003', 1.5, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S003'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'));
INSERT INTO Troncon VALUES ('T004', 4.0, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S004'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'));
INSERT INTO Troncon VALUES ('T005', 2.0, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S005'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'));
INSERT INTO Troncon VALUES ('T006', 3.5, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S006'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'));
INSERT INTO Troncon VALUES ('T007', 1.0, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S007'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'));
INSERT INTO Troncon VALUES ('T008', 2.5, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S008'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'));
INSERT INTO Troncon VALUES ('T009', 3.0, (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S009'), (SELECT REF(s) FROM Station s WHERE s.CodeStation = 'S010'));

-- Insertion des navettes
INSERT INTO Navette VALUES ('N001', 'Mercedes', 2020, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'B001'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'BUS'), NULL);
INSERT INTO Navette VALUES ('N002', 'Renault', 2019, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'M001'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'MET'), NULL);
INSERT INTO Navette VALUES ('N003', 'Peugeot', 2021, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TR001'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRM'), NULL);
INSERT INTO Navette VALUES ('N004', 'Citroën', 2022, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TR002'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL);
INSERT INTO Navette VALUES ('N005', 'Fiat', 2023, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN001'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL);
INSERT INTO Navette VALUES ('N006', 'Toyota', 2024, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN002'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL);
INSERT INTO Navette VALUES ('N007', 'Honda', 2025, (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN003'), (SELECT REF(m) FROM TMoytransport m WHERE m.Abreviation = 'TRN'), NULL);

-- Insertion des voyages
INSERT INTO Voyage VALUES ('V0001', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('06:00', 'HH24:MI'), 'Aller', 40, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0002', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('07:00', 'HH24:MI'), 'Retour', 35, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0003', 20, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('06:30', 'HH24:MI'), 'Aller', 150, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0004', 20, TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('07:30', 'HH24:MI'), 'Retour', 140, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0005', 50, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('08:30', 'HH24:MI'), 'Retour', 140, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0006', 50, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('09:30', 'HH24:MI'), 'Aller', 140, 'accident', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0007', 40, TO_DATE('01-02-2025', 'DD-MM-YYYY'), TO_DATE('10:30', 'HH24:MI'), 'Retour', 140, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N004'));



--E- Langage d’interrogation de données
--10. Lister tous les voyages (num, date, moyen de transport, navette) ayant enregistré un quelconque problème (panne, retard, accident, …)

SELECT  v.NumeroVoyage, v.DateVoyage, DEREF(n.Navette_Moytransport).Abreviation, n.NumeroNavette
FROM Voyage v
JOIN Navette n ON DEREF(v.Voyage_Navette).NumeroNavette = n.NumeroNavette
WHERE v.Observation IN ('panne','retard','accident');
--11. Lister toutes les lignes (numéro, début et fin) comportant une station principale
SELECT 
    l.CodeLigne AS Numero,
    DEREF(l.Ligne_StationDepart).NomStation AS Debut,
    DEREF(l.Ligne_StationArrivee).NomStation AS Fin
FROM 
    Ligne l
JOIN 
    Station s ON DEREF(l.Ligne_StationDepart).CodeStation = s.CodeStation OR DEREF(l.Ligne_StationArrivee).CodeStation = s.CodeStation
WHERE DEREF(l.Ligne_StationDepart).EstPrincipale = 1
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
