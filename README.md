# EDP — Déterminants du PIB en Europe (2015–2023)

Projet économétrique de données de panel (Académique)

## Objectif

Analyser les déterminants du PIB par habitant dans les pays européens sur la période 2015–2023, avec un focus sur l'impact du choc exogène Covid-19 et le rôle du capital humain (éducation) dans les inégalités de richesse.

## Structure du projet

```
Projet_Panel/
├── data/
│   ├── raw/              # Données sources Eurostat (CSV)
│   └── processed/        # Données Stata compilées (DTA)
├── scripts/              # Scripts d'analyse Stata (.do)
├── output/
│   ├── figures/          # Graphiques exportés (.png)
│   └── reports/          # Rapport final (.pdf, .xlsx)
├── .gitignore
└── README.md
```

## Données

Les données proviennent d'Eurostat et couvrent les pays de l'Union Européenne (hors agrégats UE-27, Norvège, Serbie, Turquie) sur 2015–2023.

| Fichier | Variable | Description |
|---|---|---|
| `pib.csv` | `LPtb` | Log PIB par habitant (variable dépendante) |
| `revenu.csv` | `LCon` | Log revenu disponible |
| `fbcf.csv` | `LIvt` | Taux d'investissement (% du PIB) |
| `emploi.csv` | `Emp` | Taux d'emploi |
| `densite.csv` | `Den` | Densité de population (hab/km²) |
| `esperance.csv` | `Idh` | Espérance de vie |
| `educ.csv` | `Dip` | Capital humain (% diplômés du supérieur) |

## Scripts

| Fichier | Description |
|---|---|
| `scripts/EDP_BERROUHOU_GOURGUECHON_INEZA_2025.do` | Script principal — import, nettoyage, modèles, graphiques |
| `scripts/panel.do` | Script alternatif avec graphique de distribution supplémentaire |

### Exécution

Ouvrir Stata, puis lancer :

```stata
do "C:\Users\maxim\Desktop\Projet_Panel\scripts\EDP_BERROUHOU_GOURGUECHON_INEZA_2025.do"
```

Le script s'exécute depuis la racine du projet (`$myfolder`). Les fichiers intermédiaires sont générés dans `data/processed/` et les graphiques dans `output/figures/`.

## Modèles estimés

| Modèle | Commande Stata |
|---|---|
| POLS — Pooled OLS | `reg` |
| BE — Effets entre | `xtreg, be` |
| FE — Effets fixes | `xtreg, fe` |
| RE — Effets aléatoires | `xtreg, re` |
| FD — Premières différences | `reg D.*` |
| FE + dummy Covid | `xtreg, fe vce(cluster)` |
| FE + effets temporels | `xtreg i.year, fe vce(cluster)` |

Le test de Hausman (`hausman FE RE`) est utilisé pour choisir entre FE et RE.

## Auteurs

- GOURGUECHON Maxime
- INEZA Issia Belinda
- BERROUHOU Aissa
