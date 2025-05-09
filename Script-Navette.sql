--@ "C:\Users\HERO-INFO\Desktop\M1-sii\s2\bdd\projet bdd 2024-2025\bda-project\bdd-project\Script-Navette.sql";
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
-- Vérifier que le moyen de transport de la navette correspond à celui de la ligne
INSERT INTO Navette VALUES (
  'N018', 'Bombardier', 2015,
  (SELECT REF(l) FROM Ligne l WHERE l.CodeLigne = 'TN006'),
  (SELECT REF(m) FROM Moytransport m WHERE m.Abreviation = 'BUS'),
T_Set_Ref_Voyage()
);

