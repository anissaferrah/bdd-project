--connexion à la base de données pluggable
ALTER PLUGGABLE DATABASE orclpdb OPEN;
connect sys@orclpdb as sysdba

--creation des tablespaces et l'utilisateur sql  se connecte à la base de données pluggable
create tablespace  SQL3_TBS datafile 'C:\tablespaces\tbs_002.dat' size 100M autoextend on;
create temporary tablespace SQL3_TempTBS  tempfile 'C:\tablespaces\temp_002.dat' size 100M autoextend on;
create user  SQL3 identified by sql3 default tablespace SQL3_TBS temporary tablespace SQL3_TempTBS;
grant all privileges to SQL3;
connect SQL3/sql3@orclpdb;
--creation de la table et insertion des données