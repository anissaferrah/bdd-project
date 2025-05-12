----@ "C:\Users\HERO-INFO\Desktop\M1-sii\s2\bdd\projet bdd 2024-2025\bda-project\bdd-project\Script-Troncon.sql"
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
