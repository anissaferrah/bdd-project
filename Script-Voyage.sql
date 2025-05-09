--@ "C:\Users\HERO-INFO\Desktop\M1-sii\s2\bdd\projet bdd 2024-2025\bda-project\bdd-project\Script-Voyage.sql";
INSERT INTO Voyage VALUES ('V0001', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'),'06:00', 'Aller', 40, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0002', 30, TO_DATE('02-01-2025', 'DD-MM-YYYY'), '07:00', 'Retour', 35, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0003', 20, TO_DATE('03-01-2025', 'DD-MM-YYYY'), '06:30', 'Aller', 50, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0004', 20, TO_DATE('06-01-2025', 'DD-MM-YYYY'), '07:30', 'Retour', 30, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N002'));
INSERT INTO Voyage VALUES ('V0005', 50, TO_DATE('08-01-2025', 'DD-MM-YYYY'), '08:30', 'Retour', 60, 'panne', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0006', 50, TO_DATE('05-01-2025', 'DD-MM-YYYY'), '09:30', 'Aller', 40, 'accident', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N003'));
INSERT INTO Voyage VALUES ('V0007', 40, TO_DATE('07-01-2025', 'DD-MM-YYYY'), '10:30', 'Retour', 20, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N004'));
INSERT INTO Voyage VALUES ('V0008', 40, TO_DATE('03-02-2025', 'DD-MM-YYYY'), '2:30', 'Retour', 20, 'retard', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N007'));

--contraint 
INSERT INTO Voyage VALUES ('V0009', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'),'06:00', 'Aller', 0, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
INSERT INTO Voyage VALUES ('V0009', 30, TO_DATE('01-01-2025', 'DD-MM-YYYY'),'06:00', 'x', 40, 'On time', (SELECT REF(n) FROM Navette n WHERE n.NumeroNavette = 'N001'));
--ajouter plusieurs voyages par jour, sur une période de deux mois au minimum du 01-01-2025 au 01-03-2025)
/*
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
*/