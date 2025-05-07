

-- ***********************************************
-- A- Modélisation orientée document
-- ***********************************************

-- Modélisation orientée document
{
  "_id": "V0001",
  "duree": 30,
  "datevoyage": "2025-01-01",
  "heure_depart": "06:00",
  "sens": "Aller",
  "nb_voyageurs": 40,
  "observation": "On time",
  "navette": {
    "numero": "N001",
    "marque": "Mercedes",
    "annee_mise_en_service": 2020,
    "ligne": {
      "code": "B001",
      "moyen_transport": {
        "abreviation": "BUS",
        "heure_ouverture": "06:00",
        "heure_fermeture": "22:00",
        "nb_moyen_voyageurs": 200
      },
      "station_depart": {
        "code": "S001",
        "nom": "Station A",
        "est_principale": true,
        "coordonnees": {
          "longitude": 48.8566,
          "latitude": 2.3522
        }
      },
      "station_arrivee": {
        "code": "S004",
        "nom": "Station D",
        "est_principale": true,
        "coordonnees": {
          "longitude": 48.8580,
          "latitude": 2.3550
        }
      },
      "troncons": [
        {
          "numero": "T001",
          "longueur_km": 5.0,
          "station_depart": {
            "code": "S001",
            "nom": "Station A"
          },
          "station_arrivee": {
            "code": "S002",
            "nom": "Station B"
          },
          "duree_estimee": 15
        },
        {
          "numero": "T002",
          "longueur_km": 3.0,
          "station_depart": {
            "code": "S002",
            "nom": "Station B"
          },
          "station_arrivee": {
            "code": "S003",
            "nom": "Station C"
          },
          "duree_estimee": 10
        },
        {
          "numero": "T003",
          "longueur_km": 2.0,
          "station_depart": {
            "code": "S003",
            "nom": "Station C"
          },
          "station_arrivee": {
            "code": "S004",
            "nom": "Station D"
          },
          "duree_estimee": 5
        },
        {
          "numero": "T004",
          "longueur_km": 4.0,
          "station_depart": {
            "code": "S004",
            "nom": "Station D"
          },
          "station_arrivee": {
            "code": "S005",
            "nom": "Station E"
          },
          "duree_estimee": 10
        },
        {
          "numero": "T005",
          "longueur_km": 6.0,
          "station_depart": {
            "code": "S005",
            "nom": "Station E"
          },
          "station_arrivee": {
            "code": "S006",
            "nom": "Station F"
          },
          "duree_estimee": 15
        },
        {
          "numero": "T006",
          "longueur_km": 7.0,
          "station_depart": {
            "code": "S006",
            "nom": "Station F"
          },
          "station_arrivee": {
            "code": "S007",
            "nom": "Station G"
          },
          "duree_estimee": 20
        }
      ],
      "navettes": [
        {
          "numero": "N001",
          "marque": "Mercedes",
          "annee_mise_en_service": 2020
        },
        {
          "numero": "N002",
          "marque": "Alstom",
          "annee_mise_en_service": 2019
        },
        {
          "numero": "N003",
          "marque": "CAF",
          "annee_mise_en_service": 2021
        },
        {
          "numero": "N004",
          "marque": "Bombardier",
          "annee_mise_en_service": 2022
        },
        {
          "numero": "N005",
          "marque": "Siemens",
          "annee_mise_en_service": 2023
        },
        {
          "numero": "N006",
          "marque": "Hitachi",
          "annee_mise_en_service": 2024
        },
        {
          "numero": "N007",
          "marque": "Hyundai Rotem",
          "annee_mise_en_service": 2025
        }
      ]
    },
    "voyages": [
      {
        "numero": "V0001",
        "duree": 30,
        "date_voyage": "2025-01-01",
        "heure_depart": "06:00",
        "sens": "Aller",
        "nb_voyageurs": 40,
        "observation": "On time"
      },
      {
        "numero": "V0002",
        "duree": 30,
        "date_voyage": "2025-01-01",
        "heure_depart": "07:00",
        "sens": "Retour",
        "nb_voyageurs": 35,
        "observation": "panne"
      },
      {
        "numero": "V0003",
        "duree": 20,
        "date_voyage": "2025-01-01",
        "heure_depart": "06:30",
        "sens": "Aller",
        "nb_voyageurs": 150,
        "observation": "On time"
      },
      {
        "numero": "V0004",
        "duree": 20,
        "date_voyage": "2025-01-01",
        "heure_depart": "07:30",
        "sens": "Retour",
        "nb_voyageurs": 140,
        "observation": "On time"
      },
      {
        "numero": "V0005",
        "duree": 50,
        "date_voyage": "2025-02-01",
        "heure_depart": "08:30",
        "sens": "Retour",
        "nb_voyageurs": 140,
        "observation": "panne"
      },
      {
        "numero": "V0006",
        "duree": 50,
        "date_voyage": "2025-02-01",
        "heure_depart": "09:30",
        "sens": "Aller",
        "nb_voyageurs": 140,
        "observation": "accident"
      },
      {
        "numero": "V0007",
        "duree": 40,
        "date_voyage": "2025-02-01",
        "heure_depart": "10:30",
        "sens": "Retour",
        "nb_voyageurs": 140,
        "observation": "retard"
      },
    ],
    "moyens_transport": [
      {
        "abreviation": "BUS",
        "heure_ouverture": "06:00",
        "heure_fermeture": "22:00",
        "nb_moyen_voyageurs": 200
      },
      {
        "abreviation": "MET",
        "heure_ouverture": "05:30",
        "heure_fermeture": "23:30",
        "nb_moyen_voyageurs": 300
      },
      {
        "abreviation": "TRM",
        "heure_ouverture": "06:00",
        "heure_fermeture": "22:00",
        "nb_moyen_voyageurs": 150
      },
      {
        "abreviation": "TRN",
        "heure_ouverture": "05:00",
        "heure_fermeture": "23:00",
        "nb_moyen_voyageurs": 400
      }
    ]
  }
}

