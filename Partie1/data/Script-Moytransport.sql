--@ "C:\Users\HERO-INFO\Desktop\M1-sii\s2\bdd\projet bdd 2024-2025\bda-project\bdd-project\Script-Moytransport.sql"
--------------------------------------------------insertion dans la table Moytransport:--------------------------------------------------------------------
INSERT INTO Moytransport VALUES ('BUS','06:00','21:00', 200, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('MET','05:30','23:30', 300, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('TRM','06:00','23:59', 500, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
INSERT INTO Moytransport VALUES ('TRN','05:00','22:00', 400, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());

-- Insertion des moyens de transport
--si NbMoyenVoyageurs<0
INSERT INTO Moytransport VALUES ('TRN6','05:00','23:59',  -17, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
--si HeureOuverture>=HeureFermeture
INSERT INTO Moytransport VALUES ('BUS','22:00','05:00', 200, T_Set_Ref_Ligne(), T_Set_Ref_Station(), T_Set_Ref_Navette());
