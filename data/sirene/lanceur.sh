# Exports du site sirene.fr limités à 200.000 entreprises ;
# récupération des PME par tranches depuis
# http://www.sirene.fr/sirene/client//sirene/client/modification-fichier.action?nouveauFichier=true

cat etablissements* >all.csv

# Produit liste-noms.csv, liste-prenoms-feminins.csv, liste-prenoms-masculins.csv
perl traite.pl all.csv

perl ../../nettoieListePrenoms.pl liste-noms-brut.csv liste-noms.csv 3
perl ../../nettoieListePrenoms.pl liste-prenoms-fem-brut.csv liste-prenoms-fem.csv 5
perl ../../nettoieListePrenoms.pl liste-prenoms-masc-brut.csv liste-prenoms-masc.csv 16

rm liste-noms-brut.csv liste-prenoms-fem-brut.csv liste-prenoms-masc-brut.csv
