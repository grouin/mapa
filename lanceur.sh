#!/usr/bin/bash

# Nettoyage des fichiers de prénoms (conservation des prénoms de plus
# de trois caractères et d'une fréquence > 200, conservation de la
# majuscule initiale et mise en minuscule du reste, réintroduction des
# diacritiques, et identification du genre) ; liste finale de 2277
# prénoms francisés (sur la base de 209 310 prénoms tout en
# majuscules, avec fautes, sans diacritiques, etc.) et 6535 noms
# francisés.

# perl nettoieListePrenoms.pl data/prenom.csv data/prenom-fr.csv 200
# perl nettoieListePrenoms.pl data/patronymes.csv data/patronymes-fr.csv 200

# => cette version est abandonnée, au profit d'une nouvelle version
# (récupération perso de fichiers de la base Sirene) :

cd data/sirene/
perl traite.pl all.csv
perl ../../nettoieListePrenoms.pl liste-noms-brut.csv liste-noms.csv 3
perl ../../nettoieListePrenoms.pl liste-prenoms-fem-brut.csv liste-prenoms-fem.csv 3
perl ../../nettoieListePrenoms.pl liste-prenoms-masc-brut.csv liste-prenoms-masc.csv 3
cd ../../

# Production d'une liste de 10000 noms prénoms pour le français

perl produit-combi-nom-pre.pl



# Listes par fréquence décroissante (pour le script d'Ona)

# cat data/prenom-fr.csv | egrep "F$" | sort -nr | cut -f2 >gazetteers/female_names.txt
# cat data/prenom-fr.csv | egrep "M$" | sort -nr | cut -f2 | head -1032 >gazetteers/male_names.txt
# cat data/patronymes-fr.csv | sort -nr | cut -f2 | head -1032 >gazetteers/surnames.txt

# Script d'Ona pour générer 10000 combinaisons de prénoms+noms
# (suppose des listes de 5000 prénoms féminins, autant de masculins,
# et de noms).
#
# https://github.com/onadegibert/syn-corpus-builder/blob/main/generate_random_names.py

# Script modifié pour travailler sur des listes de 1032 entrées
# (nombre de prénoms féminins). Génère plusieurs occurrences des mêmes
# entrées (même prénom, même nom : "Marie Martin" présente 22 fois,
# "Marie Bernard" 19 fois, "Jean Martin" 19 fois, "Jean Durand" 11
# fois, etc.) en raison de la fréquence d'utilisation élevée, mais
# aussi du script qui suit une distribution de Zipf. Peut-être pas
# pertinent.
#python3 generate_random_names.py

#cat 10k_random_names_zipf_repetition.txt | awk '{print $2,$3}' | sort | uniq -c | sort -nr
#tar -cvzf ona.tar.gz gazetteers/ generate_random_names.py 10k_random_names_zipf_repetition.txt

# Ajout de noms et prénoms de personne, noms de société, et adresses
# dans les fichiers de jurisprudence

perl juris_modifie-donnees.pl corpus/mapa/ corpus/mapa2/
perl juris_modifie-donnees.pl corpus/CIVILE/ corpus/CIVILE2/
egrep "[^\[]\.\.\." corpus/CIVILE2/*
egrep Helvet corpus/CIVILE2/*


# Archive

#tar -cvjf adapte-corpus-mapa.tar.bz2 juris_modifie-donnees.pl nettoieListePrenoms.pl data/prenom.csv data/prenom-fr.csv data/codepostaux2019.csv data/patronymes.csv data/patronymes-fr.csv
tar -cvjf adapte-corpus-mapa.tar.bz2 juris_modifie-donnees.pl data/codepostaux2019.csv data/sirene/liste-noms.csv data/sirene/liste-prenoms-fem.csv data/sirene/liste-prenoms-masc.csv corpus/CIVILE/ corpus/CIVILE2/
mv adapte-corpus-mapa.tar.bz2 ~/Bureau/
