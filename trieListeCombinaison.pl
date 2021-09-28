# Trie la liste existante d'identités féminines et masculines
# (liste-10000.txt) composée exactement de 5000 identités fondées sur
# des prénoms féminins et de 5000 sur des prénoms masculins, pour
# distinguer les identités en fonction du genre. Produit deux fichiers
# en sortie : liste-5000-fem.txt et liste-5000-masc.txt
#
# Problème avec les prénoms épicènes, présents dans les deux listes et
# potentiellement utilisés pour des identités féminines et masculines
# (Alix, Camille, Claude, Dominique, Elie, Sacha, Stéphane, etc.).
#
# A posteriori, il est impossible de savoir si l'identité générée avec
# un tel prénom provenait de la liste féminine ou de la liste
# masculine, ce qui conduit à un déséquilibre entre identités, à
# compenser par des déplacements d'identités épicènes.
# $ wc liste-5000-*

# Les listes de prénoms ont été manuellement nettoyées (sept. 2021)
# pour améliorer la distinction, par la suppression des erreurs ou
# très faibles effectifs (Arsène ou Eugène dans la liste féminine).

# $ perl trieListeCombinaison.pl liste-10000.txt


use strict;
my (%fem,%masc,%epi,%listeF,%listeM,%listeE,%nbEpi);


# Récupération des prénoms de chaque liste et de la fréquence
# d'utilisation de chaque prénom (dans les sources qui ont servi à
# constituer ces listes)
open(E,'<:utf8',"data/sirene/liste-prenoms-fem.csv"); while (my $l=<E>) { my ($nb,$pre,$g,$ori)=split(/\t/,$l); $fem{$pre}=$nb; } close(E);
open(E,'<:utf8',"data/sirene/liste-prenoms-masc.csv"); while (my $l=<E>) { my ($nb,$pre,$g,$ori)=split(/\t/,$l); $masc{$pre}=$nb; } close(E);

# Pour les prénoms épicènes, on calcule un ratio d'utilisation du
# prénom entre femmes et hommes d'après l'information de fréquence
# précédemment récupérée, en vue d'une répartition de ces prénoms en
# fonction de l'usage réel dans la société. Ces prénoms sont exclus
# des listes féminines et masculines et stockés dans une liste épicène
foreach my $pre (sort keys %fem) {
    if (exists $masc{$pre}) {
	my $ratio=$fem{$pre}/($fem{$pre}+$masc{$pre}); $epi{$pre}=$ratio;
	#warn "$pre\t$fem{$pre} F\t$masc{$pre} H\t$ratio\n";
	delete($fem{$pre}); delete($masc{$pre});
    }
}

# Traitement du fichier d'entrée avec répartition des lignes de ce
# fichier dans trois tables de hachage, en fonction de la liste
# (femme, homme, épicène) dans laquelle le prénom de l'identité a été
# trouvé
open(E,'<:utf8',$ARGV[0]);
while (my $l=<E>) {
    chomp $l; my ($prenom,$nom)=split(/\t/,$l);
    if (exists $fem{$prenom}) { $listeF{$l}++; } elsif (exists $masc{$prenom}) { $listeM{$l}++; } else { $listeE{$l}=$epi{$prenom}; $nbEpi{$prenom}++; }
}
close(E);


# Production des fichiers de sortie pour les prénoms assurément
# féminins ou masculins
my $sortie=$ARGV[0]; $sortie=~s/10000/5000/; my $i=0;
my $sortieF=$sortie; $sortieF=~s/(\.[a-z]+)$/-fem$1/g; open(S,'>:utf8',$sortieF); foreach my $l (sort keys %listeF) { print S "$l\n"; $i++; } close(S);
warn "$i identités exclusivement féminines => $sortieF\n"; $i=0;
my $sortieM=$sortie; $sortieM=~s/(\.[a-z]+)$/-masc$1/g; open(S,'>:utf8',$sortieM); foreach my $l (sort keys %listeM) { print S "$l\n"; $i++; } close(S);
warn "$i identités exclusivement masculines => $sortieM\n"; $i=0;
#my $sortieE=$sortie; $sortieE=~s/(\.[a-z]+)$/-epi$1/g; open(S,'>:utf8',$sortieE); foreach my $l (sort keys %listeE) { print S "$l\n"; $i++; } close(S);
#warn "$i identités épicènes => $sortieE\n"; $i=0;


# Pour les prénoms épicènes, répartition des identités entre fichiers
# de sortie féminins ou masculins à hauteur du ratio précédemment
# calculé (0.5=équilibre entre femmes et hommes, >0.5 majoritairement
# féminin, <0.5 majoritairement masculin)
open(F,'>>:utf8',$sortieF);
open(M,'>>:utf8',$sortieM);
my $prec="";
foreach my $l (sort keys %listeE) {
    my ($prenom,$nom)=split(/\t/,$l);  # Récupération du prénom et du nom dans l'identité
    my $ratio=$epi{$prenom};           # Ratio d'usage femme/homme pour ce prénom
    # Nombre d'identités féminines à conserver d'après le nombre total
    # d'identités à base de ce prénom et du ratio précédemment calculé
    my $nbF=sprintf("%.0f",($nbEpi{$prenom}*$ratio))+2; # +2 pour bon équilibre (ad hoc)
    $nbF++ if ($prenom eq "Claude");   # Ajustement manuel pour répartition parfaite 5000
    
    # Si le prénom dans l'identité est différent de celui précédemment
    # traité, réinitialisation du nombre d'identités traitées à base
    # de ce prénom (permet de contrôler la bonne répartition dans les
    # deux fichiers de sortie)
    if ($prenom ne $prec) { $i=0; }
    
    #warn "*** $i $prenom ($nbEpi{$prenom} identités) = $ratio soit $nbF femmes\n";
    
    # Répartition des identités entre femmes et hommes en fonction du
    # nombre d'identités à base de ce prénom déjà traitées, par
    # rapport au ratio femme/homme précédemment calculé
    if ($i<=$nbF) { print F "$l\n"; }
    else { print M "$l\n"; }
    
    $prec=$prenom;  # Précédent prénom traité
    $i++;           # Incrémentation du nombre d'identités avec ce prénom
}
close(F);
close(M);
