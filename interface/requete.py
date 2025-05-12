from flask import Flask, render_template
import cx_Oracle

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
if __name__ == '__main__':
    app.run(debug=True)
