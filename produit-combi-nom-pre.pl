# Produit une liste combinant des noms et prénoms pour le français
# (livrable) : 5000 identités féminines, 5000 identités masculines, en
# vérifiant qu'il n'existe pas de doublons. Les noms et prénoms sont
# aléatoirement tirés, en conservant la distribution des noms et
# prénoms en France (permet d'avoir plus de personnes nommées Martin,
# Petit, Durand, Dubois, etc.).

use strict;

my (@noms,@prenomsF,@prenomsM);
my %origines=();
my $sep="\t"; # Séparateur prénom/nom


# Récupération du contenu des listes de noms et prénoms

#open(E,'<:utf8',"data/patronymes-fr.csv");
open(E,'<:utf8',"data/sirene/liste-noms.csv");
while (my $l=<E>) {
    chomp $l;
    my ($f,$t,$g,$o)=split(/\t/,$l);
    for (my $i=0;$i<$f;$i++) { push(@noms,$t); $origines{$t}=$o; }
}
close(E);

# open(E,'<:utf8',"data/prenom-fr.csv");
# while (my $l=<E>) {
#     chomp $l;
#     my ($f,$t,$g,$o)=split(/\t/,$l);
#     if ($g eq "M") {
# 	for (my $i=0;$i<$f;$i++) { push(@prenomsM,$t); $origines{$t}=$o; }
#     } else {
# 	for (my $i=0;$i<$f;$i++) { push(@prenomsF,$t); $origines{$t}=$o; }
#     }
# }
# close(E);

open(E,'<:utf8',"data/sirene/liste-prenoms-fem.csv");
while (my $l=<E>) {
    chomp $l;
    my ($f,$t,$g,$o)=split(/\t/,$l);
    for (my $i=0;$i<$f;$i++) { push(@prenomsF,$t); $origines{$t}=$o; }
}
close(E);

open(E,'<:utf8',"data/sirene/liste-prenoms-masc.csv");
while (my $l=<E>) {
    chomp $l;
    my ($f,$t,$g,$o)=split(/\t/,$l);
    for (my $i=0;$i<$f;$i++) { push(@prenomsM,$t); $origines{$t}=$o; }
}
close(E);


# Combinaison pour générer 10000 personnes fictives, la première
# moitié d'identités féminines, la deuxième moitié d'identités
# masculines. Tirage aléatoire d'un nom et d'un prénom, et
# vérification si la combinaison n'existe pas déjà

my ($nom,$prenom,%deja);

for (my $i=0;$i<10000;$i++) {
    $nom=$noms[int(rand($#noms))];
    # Tirage aléatoire
    if ($i<5000) { $prenom=$prenomsF[int(rand($#prenomsF))]; } else { $prenom=$prenomsM[int(rand($#prenomsM))]; }

    # Nouveau tirage si combinaison déjà existante
    while (exists $deja{"$prenom$sep$nom"}) {
	$nom=$noms[int(rand($#noms))];
	if ($i<5000) { $prenom=$prenomsF[int(rand($#prenomsF))]; } else { $prenom=$prenomsM[int(rand($#prenomsM))]; }
    }
    $deja{"$prenom$sep$nom"}++;
}


# Production du fichier de sortie

open(S,'>:utf8',"liste-10000.txt");
foreach my $l (sort keys %deja) { print S "$l\n"; }
close(S);
