from flask import Flask, render_template
import cx_Oracle
from bson import json_util
from pymongo import MongoClient
from datetime import datetime


app = Flask(__name__)

def executer_requete(sql):
    try:
        dsn = cx_Oracle.makedsn("localhost", 1521, service_name="orclpdb")
        conn = cx_Oracle.connect(user="SQL3", password="sql3", dsn=dsn)
        cursor = conn.cursor()
        cursor.execute(sql)
        colonnes = [desc[0] for desc in cursor.description] 
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        return colonnes, results
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        print("Code erreur :", error.code)
        print("Message Oracle :", error.message)
        return [], [] 

def executer_requete_mongodb(numero):
    try:
        client = MongoClient("mongodb://localhost:27017/")
        db = client["transport"]
        if numero == 1:
           result = db.Voyage.find({"date_voyage": datetime(2025, 1, 1)})
        elif numero == 2:
           pipeline = [
             {"$match": {"observation": "On time"}},
             {"$project": {
            "_id": 1,
            "date_voyage": 1,
            "heure_depart": 1,
            "sens": 1,
            "navette.numero": 1,
            "navette.moyen_transport.abreviation": 1,
            "navette.moyen_transport.ligne.code": 1
            }},
            {"$out": "BON-Voyage"}
            ]
           db.Voyage.aggregate(pipeline)

          # Requête d’affichage de la collection "BON-Voyage"
           result = db["BON-Voyage"].find()
        elif numero == 3:
              pipeline = [
                  {"$group": {"_id": "$navette.moyen_transport.ligne.code", "totalVoyages": {"$sum": 1}} },
                  {"$sort": { "totalVoyages": -1 }},
                  {"$out": "Ligne-Voyages"}
              ]
              db.Voyage.aggregate(pipeline)
              result = db["Ligne-Voyages"].find()
        elif numero == 4:
               db.Voyage.update_many(
                 {
                    "navette.moyen_transport.abreviation": "MET",
                   "date_voyage": {"$lt": datetime(2025, 1, 15)}
                 },
                 {
                   "$inc": {"nb_voyageurs": 100}
                 }
                )
               result = db.Voyage.find({
                            "navette.moyen_transport.abreviation": "MET",
                            "date_voyage": {"$lt": datetime(2025, 1, 15)}
                        })
        elif numero == 5:
            map_function = """function() {
                emit(this.navette.moyen_transport.ligne.code, 1);
            }"""
    
            reduce_function = """function(key, values) {
                return Array.sum(values);
            }"""
    
             
            db.Voyage.map_reduce(
                map_function,
                reduce_function,
                out="Ligne-Voyages"  
            )
    
            
            result = db["Ligne-Voyages"].find().sort("value", -1)

        elif numero == 6:
            result = db.Voyage.aggregate([
            {
                "$group": {
                    "_id": {
                        "numeroNavette": "$navette.numero",
                        "abreviation": "$navette.moyen_transport.abreviation"
                    },
                    "totalVoyages": {"$sum": 1}
                }
            },
            {"$sort": {"totalVoyages": -1}},
            {"$limit": 1}
        ])
        else:
            return [], []

        colonnes = set()
        rows = []

        for doc in result:
            flat = json_util.loads(json_util.dumps(doc))  # JSON-safe dict
            colonnes.update(flat.keys())
            rows.append(flat)

        colonnes = list(colonnes)
        table = [[row.get(col, "") for col in colonnes] for row in rows]
        return colonnes, table

    except Exception as e:
        print("Erreur MongoDB :", e)
        return [], []

 

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/reponse/<int:question>')
def get_reponse(question):
    requetes = {
        1:"""
        SELECT t.Abreviation,t.HeureOuverture,t.HeureFermeture,t.NbMoyenVoyageurs from moytransport t
        """,
        2:"""
        SELECT  s.CodeStation,s.NomStation,s.Coordonnees.Longitude as Longitude ,s.Coordonnees.Latitude as Latitude, s.EstPrincipale from station s
        """,
        3:"""
        SELECT l.CodeLigne from ligne l
        """,
        4:"""
        SELECT  t.NumeroTroncon ,t.LongueurKm  from troncon t
        """,
        5:"""
        SELECT   n.NumeroNavette ,n.Marque ,n.AnneeMiseEnCirculation from navette n
        """,
        6:"""
        SELECT  v.NumeroVoyage,v.Duree,v.DateVoyage,v.HeureDebut,v.Sens,v.NbVoyageurs,v.Observation from voyage v
        """,
        7: """
        SELECT
            v.NumeroVoyage,
            v.DateVoyage,
            DEREF(v.Voyage_Navette).NumeroNavette AS NumeroNavette,
            DEREF(v.Voyage_Navette).Marque AS MarqueNavette,
            DEREF(DEREF(v.Voyage_Navette).Navette_Moytransport).Abreviation AS MoyenTransport,
            v.Observation
        FROM Voyage v
        WHERE v.Observation IN ('panne','retard','accident')
        """,

        8: """
        SELECT 
            l.CodeLigne,
            DEREF(l.Ligne_StationDepart).NomStation AS StationDepart,
            DEREF(l.Ligne_StationArrivee).NomStation AS StationArrivee
        FROM Ligne l
        WHERE 
            DEREF(l.Ligne_StationDepart).EstPrincipale = 1
            OR DEREF(l.Ligne_StationArrivee).EstPrincipale = 1
        """,

        9: """
        SELECT 
            n.NumeroNavette,
            DEREF(n.Navette_Moytransport).Abreviation AS TypeTransport,
            n.AnneeMiseEnCirculation,
            COUNT(v.NumeroVoyage) AS NombreVoyages
        FROM Navette n   
        JOIN Voyage v ON DEREF(v.Voyage_Navette).NumeroNavette = n.NumeroNavette
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
            )
        """,

        10: """
        SELECT
            s.CodeStation,
            LISTAGG(DEREF(VALUE(m)).Abreviation, ', ') WITHIN GROUP (ORDER BY DEREF(VALUE(m)).Abreviation) AS MoyensTransportOfferts
        FROM
            Station s,
            TABLE(s.Station_MoyenTransport) m
        GROUP BY
            s.CodeStation
        HAVING
            COUNT(DISTINCT DEREF(VALUE(m)).Abreviation) >= 2
        """,
        11: """
        SELECT t.NumeroTroncon, t.CalculerDuree(REF(m)) AS DureeMinutes
        FROM Troncon t, Moytransport m
        WHERE m.Abreviation = 'TRM' AND t.NumeroTroncon = 'T001'
        """,
        12: """
            SELECT n.NumeroNavette, n.CalculerNombreVoyages() AS NbVoyages
            FROM Navette n
            WHERE n.NumeroNavette IN (
                'N001', 'N002', 'N003', 'N004', 'N005', 'N006', 'N007', 'N008', 'N009', 'N010',
                'N011', 'N012', 'N013', 'N014', 'N015', 'N016', 'N017'
            )
        """,
        13: """
            SELECT 
            nav.NumeroNavette,
            nav.Marque,
            nav.AnneeMiseEnCirculation
            FROM Ligne l,
                TABLE(l.ListeNavettes()) nav
            WHERE l.CodeLigne = 'TN001'
                        
        """,
        14: """
             SELECT l.NombreVoyagesPeriode(TO_DATE('01-01-2025', 'DD-MM-YYYY'), TO_DATE('15-02-2025', 'DD-MM-YYYY')) AS NbVoyages
                FROM Ligne l
                WHERE l.CodeLigne = 'TN003'

        """,
        15: """
            SELECT m.Abreviation, m.CalculerVoyagesEtVoyageurs(TO_DATE('28-02-2025', 'DD-MM-YYYY')) AS Resultat
            FROM Moytransport m
            WHERE m.Abreviation = 'MET'
        """
    }

    if question not in requetes:
        return "<h3>Question invalide !</h3>"

    colonnes, results = executer_requete(requetes[question])
    if not results:
        return """
        <h3>Résultats de la requête</h3>
        <p>Aucun résultat trouvé ou erreur dans la requête.</p>
        <a href='/'>Retour à l'accueil</a>
        """
    else:
        # Générer le tableau HTML
        html_table = '<h3>Résultats de la requête</h3><table border="1">'
        html_table += '<tr>' + ''.join(f'<th>{col}</th>' for col in colonnes) + '</tr>'  # en-têtes
        html_table += ''.join(f'<tr>{"".join(f"<td>{cell}</td>" for cell in row)}</tr>' for row in results)
        html_table += '</table><br><a href="/">Retour à accueil</a>'
        return html_table 
    
@app.route('/reponse_mongo/<int:numero>')
def get_reponse_mongo(numero):
    colonnes, results = executer_requete_mongodb(numero)
    if not results:
        return """
        <h3>Résultats de la requête MongoDB</h3>
        <p>Aucun résultat trouvé ou erreur dans la requête.</p>
        <a href='/'>Retour à l'accueil</a>
        """

    html = '<h3>Résultats de la requête MongoDB</h3>'
    for row in results:
        html += '<pre>{}</pre><hr>'.format(
            json_util.dumps(dict(zip(colonnes, row)), indent=4, ensure_ascii=False)
        )
    html += '<a href="/">Retour à l\'accueil</a>'
    return html

@app.route('/reponse_mongo/<int:numero>')
def get_reponse_mongo(numero):
    colonnes, results = executer_requete_mongodb(numero)
    if not results:
        return """
        <h3>Résultats de la requête </h3>
        <p>Aucun résultat trouvé ou erreur dans la requête.</p>
        <a href='/'>Retour à l'accueil</a>
        """

    # Assure que les valeurs soient lisibles même si elles sont imbriquées (ex: dictionnaires)
    def flatten_value(val):
        if isinstance(val, dict):
            return json_util.dumps(val, ensure_ascii=False)
        return val

    html_table = '<h3>Résultats de la requête </h3><table border="1">'
    html_table += '<tr>' + ''.join(f'<th>{col}</th>' for col in colonnes) + '</tr>'
    for row in results:
        html_table += '<tr>'
        for cell in row:
            html_table += f'<td>{flatten_value(cell)}</td>'
        html_table += '</tr>'
    html_table += '</table><br><a href="/">Retour à l\'accueil</a>'
    return html_table


# === MAIN ===
if __name__ == '__main__':
    app.run(debug=True)
