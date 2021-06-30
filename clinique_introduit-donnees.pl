#!/usr/bin/perl

# A partir de listes de 209310 prénoms, 879422 noms, et 35729 villes,
# récupère les noms de fréquence supérieure à 4 (soit 174207 noms)
# pour éliminer les erreurs, les prénoms de fréquence supérieure à
# 1500 (soit 697 prénoms), normalise ces entrées (mise en minuscules),
# et réintroduit aléatoirement des noms de patients, médecins, et des
# lieux (adresses complètes ou simple ville) en différents endroits du
# corpus de cas cliniques. Ne produit que les sorties qui ont été
# modifiées.

# perl reintroduitDonnesNominatives.pl corpus/DEFT-cas-cliniques/ corpus/cas-cliniques-identifiants/

# Auteur : Cyril Grouin, novembre 2020.


use utf8;
use strict;
binmode STDOUT, ":encoding(utf8)";


my ($in,$out)=@ARGV;
my @fichiers=<$in/*txt>;
my %prenoms=();
my %noms=();
my %villes=();
my @voiries=("impasse","avenue","place","rue","chemin","allée","boulevard","rue","route");
my @hopitaux=("centre","CHU","hôpital","CH","clinique","CHR");
my @pays=("Argentine","Canada","Chine","Espagne","Etats-Unis","Japon","Royaume-Uni","Russie","Sénégal");
my %contenu=();


###
# Configuration

my ($maxNoms,$maxPrenoms,$maxVilles)=&recupereRessources();


###
# Application

foreach my $fichier (@fichiers) {
    my $sortie=$fichier; $sortie=~s/$in/$out/;
    my $nom=int(rand($maxNoms));
    my $prenom=int(rand($maxPrenoms));
    my $ville=int(rand($maxVilles));
    my $transfo=0;
    
    open(E,'<:utf8',$fichier);
    while (my $ligne=<E>) {
	chomp $ligne;

	# Identification de l'âge
	my $age=20;
	if ($ligne!~/(avant|après|depuis|durant|il y a|pendant|un recul de) \d+ ans/i && $ligne!~/\d+ ans de recul/ && $ligne=~/(\d+) ans/) { $age=$1; }
 
	# Au début du cas, on ajoute prénom et nom en gérant le
	# déclencheur (M. Mme Melle) en fonction de l'âge
	my $decl="M.";
	$ligne=~s/Un patient de/$decl $prenoms{$prenom} $noms{$nom}, âgé de/;
	$ligne=~s/Un patient/$decl $prenoms{$prenom} $noms{$nom}/;
	if ($age>18) { $decl="Mme"; } else { $decl="Melle"; }
	$ligne=~s/Une patiente de/$decl $prenoms{$prenom} $noms{$nom}, âgée de/;
	$ligne=~s/Une patiente/$decl $prenoms{$prenom} $noms{$nom}/;

	# - il s'agit d'un(e) patient(e)/nourrisson
	if ($ligne=~/^Il s.agit d.une? (patiente?|nourrisson)/) { $ligne=~s/^Il s.agit d./Cher collègue, $prenoms{$prenom} $noms{$nom} est /; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }

	# 496-3 Madame X,
	if ($ligne=~/^(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\,/) { $ligne=~s/^(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\,/$1 $noms{$nom}\,/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	# 33 Madame C....âgée
	if ($ligne=~/^(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\.+âgée/) { $ligne=~s/^(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\.+/$1 $noms{$nom}\, /; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	# 257 Patient M.B.
	if ($ligne=~/^Patiente? \w\.\w\./) { $ligne=~s/^(Patiente?) \w\.\w\./$1 $noms{$nom}/; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	# 78-2 B. M.C…
	if ($ligne=~/^\w\. \w\.\w…/) { $ligne=~s/^\w\. \w\.\w…/$noms{$nom} $prenoms{$prenom}/; $transfo=&log($fichier,$ligne,"$noms{$nom} $prenoms{$prenom}"); }

	# - introduction au milieu de phrases
	if ($ligne=~/chez une patiente de/) { $ligne=~s/chez une patiente de/chez $prenoms{$prenom} $noms{$nom}, une patiente de/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/chez un patient de/) { $ligne=~s/chez un patient de/chez $prenoms{$prenom} $noms{$nom}, un patient de/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/concerne une (femme|patiente) de/) { $ligne=~s/chez une patiente de/chez $prenoms{$prenom} $noms{$nom}, une patiente de/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/concerne un (homme|patient) de/) { $ligne=~s/chez un patient de/chez $prenoms{$prenom} $noms{$nom}, un patient de/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }

	# - M./Mme X. : initiale remplacée par un nom
	if ($ligne=~/chez (Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./) { $ligne=~s/chez (Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./chez $1 $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	if ($ligne=~/de (Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./) { $ligne=~s/de (Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./de $1 $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	if ($ligne=~/une patiente [A-Z]\.[A-Z]\./) { $ligne=~s/une patiente [A-Z]\.[A-Z]\./une patiente, Mme $prenoms{$prenom} $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/un patient [A-Z]\.[A-Z]\./) { $ligne=~s/un patient [A-Z]\.[A-Z]\./un patient, M. $prenoms{$prenom} $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z][a-z]+ [A-Z]\./) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z][a-z]+ [A-Z]\./$1 $prenoms{$prenom} $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\./$1 $prenoms{$prenom} $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\,/) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\,/$1 $prenoms{$prenom} $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\.?/) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.[A-Z]\.? /$1 $prenoms{$prenom} $noms{$nom} /g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\. [A-Z]\.?\s?…?\,?/) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\. [A-Z]\.?\s?…?(\,?) /$1 $prenoms{$prenom} $noms{$nom}$2 /g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.\s?…?\,?/) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.\s?…?(\,?) /$1 $noms{$nom}$2 /g; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.\,/) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) [A-Z]\.\,/$1 $noms{$nom}\,/g; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	if ($ligne=~/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\./) { $ligne=~s/(Madame|Mademoiselle|Monsieur|M\.|Mr\.|Mr|Mme|Mlle|Melle) \w\.+/$1 $noms{$nom}/g; $transfo=&log($fichier,$ligne,"$noms{$nom}"); }
	# - initiales isolées en début de ligne
	if ($ligne=~/^[A-Z]\.[A-Z]\./) { $ligne=~s/^[A-Z]\.[A-Z]\./$noms{$nom} $prenoms{$prenom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/^[A-Z]\.[A-Z]/) { $ligne=~s/^[A-Z]\.[A-Z]/$noms{$nom} $prenoms{$prenom}/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/^[A-Z]\.\,/) { $ligne=~s/^[A-Z]\.\,/$prenoms{$prenom} $noms{$nom}\,/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/^[A-Z]…\,/) { $ligne=~s/^[A-Z]…\,/$prenoms{$prenom} $noms{$nom}\,/g; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }

	# - sans déclencheur mais avec prénom et nom
	if ($ligne=~/Jeune (garçon|homme) de \d+/) { $ligne=~s/Jeune (garçon|homme) de (\d+)/$prenoms{$prenom} $noms{$nom}, âgé de $2/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/Jeune fille de \d+/) { $ligne=~s/Jeune fille de (\d+)/$prenoms{$prenom} $noms{$nom}, âgée de $1/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/Jeune (garçon|homme)/) { $ligne=~s/Jeune (garçon|homme)/$prenoms{$prenom} $noms{$nom}/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }
	if ($ligne=~/Jeune (fille|femme)/) { $ligne=~s/Jeune (fille|femme)/$prenoms{$prenom} $noms{$nom}/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom} $noms{$nom}"); }

	# - enfants : prénom seulement
	if ($ligne=~/Un jeune (garçon|homme) de (\d+)/) { $ligne=~s/Un jeune (garçon|homme) de (\d+)/$prenoms{$prenom}, âgé de $2/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom}"); }
	if ($ligne=~/Une jeune fille de (\d+)/) { $ligne=~s/Une jeune fille de (\d+)/$prenoms{$prenom}, âgée de $1/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom}"); }
	if ($ligne=~/Un jeune (garçon|homme)/) { $ligne=~s/Un jeune (garçon|homme)/$prenoms{$prenom}/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom}"); }
	if ($ligne=~/Une jeune fille/) { $ligne=~s/Une jeune fille/$prenoms{$prenom}/; $transfo=&log($fichier,$ligne,"$prenoms{$prenom}"); }

	# La première occurrence de "le/la patient(e)" est remplacée par "M./Mme Nom"
	my $decl="M.";
	if ($ligne=~/le patient/) { $ligne=~s/le patient/$decl $noms{$nom}/i; $transfo=&log($fichier,$ligne,"$decl $noms{$nom}"); }
	if ($age>18) { $decl="Mme"; } else { $decl="Melle"; }
	if ($age<=10) { if ($ligne=~/la patiente/) { $ligne=~s/la patiente/$prenoms{$nom}/i; $transfo=&log($fichier,$ligne,"$prenoms{$prenom}"); }}
	else { if ($ligne=~/la patiente/) { $ligne=~s/la patiente/$decl $noms{$nom}/i; $transfo=&log($fichier,$ligne,"$decl $noms{$nom}"); }}

	# - médecin
	if ($ligne=~/intervention\,/) {
	    # Type de titre pour le médecin
	    my $titre=int(rand(2)); if ($titre==1) { $titre="Pr"; } else { $titre="Dr"; }
	    # Présence éventuelle d'un point après le titre
	    my $point=int(rand(2)); if ($point==1) { $point="\."; } else { $point=""; }
	    # Nom du médecin ayant réalisé l'intervention
	    my $nom=int(rand($maxNoms));

	    # Si on adjoint un nom d'hôpital
	    my $hop=int(rand(2));
	    if ($hop==1) {
		# Choix du type d'hôpital (hôpital, CH, CHU, clinique...)
		my $tyho=int(rand($#hopitaux));
		# Choix du nom de l'hôpital
		my $noho=int(rand(3));
		# - nom de personne
		if ($noho==1) { my $n=int(rand($maxNoms)); $noho=$noms{$n}; }
		# - nom de personne et nom de ville
		elsif ($noho==2) {
		    my $n=int(rand($maxVilles)); my ($cp,$vi); if ($villes{$n}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; } 
		    my $n=int(rand($maxNoms));
		    $noho=$noms{$n}."\, $vi \(".substr($cp,0,2)."\)";
		}
		# - nom de ville
		else { my $n=int(rand($maxVilles)); my ($cp,$vi); if ($villes{$n}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; } $noho=$vi; }
		$hop="\, $hopitaux[$tyho] $noho";
	    } else { $hop=""; }
	    $ligne=~s/intervention\,/intervention \($titre$point $noms{$nom}$hop),/; 
	    #print "--- $ligne\n"; 
	    $transfo=&log($fichier,$ligne,"$noms{$nom}");
	}

	
	
	###
	# Villes
	
	# - "à son domicile." : "à son domicile, adresse complète, CP ville."
	if ($ligne=~/à son domicile\./) {
	    my $adresse=&genereAdresse();
	    $ligne=~s/à son domicile\./à son domicile\, $adresse\, $villes{$ville}\./;
	    $transfo=&log($fichier,$ligne,"$adresse\, $villes{$ville}");
	}
	# - "hôpital de jour" : "hôpital de jour de Ville"
	if ($ligne=~/hôpital de jour/) {
	    my ($cp,$vi);
	    if ($villes{$ville}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	    $ligne=~s/hôpital de jour/hôpital de jour de $vi/;
	    $transfo=&log($fichier,$ligne,"$vi");
	}
	# - "de l'hôpital pour" : "de l'hôpital Saint-Prénom à Ville (dpt) pour"
	if ($ligne=~/de l.hôpital pour/) {
	    my $saint=$prenoms{int(rand($maxPrenoms))};
	    my ($cp,$vi);
	    if ($villes{$ville}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	    my $dpt=substr($cp,0,2);
	    $ligne=~s/(de l.hôpital) pour/$1 Saint-$saint à $vi ($dpt) pour/;
	    $transfo=&log($fichier,$ligne,"Saint-$saint");
	}
	# - "maison de soins palliatifs" : "maison de soins palliatifs à Ville (dpt)"
	if ($ligne=~/maison de soins palliatifs/) {
	    my ($cp,$vi);
	    if ($villes{$ville}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	    my $dpt=substr($cp,0,2);
	    $ligne=~s/maison de soins palliatifs/maison de soins palliatifs à $vi ($dpt)/;
	    $transfo=&log($fichier,$ligne,"$vi ($dpt)");
	}
	# - "aux urgences," / "aux urgences pour" : "aux urgences de Ville" / "aux urgences du CHU Prénom Nom
	if ($ligne=~/aux urgences(\,| pour)/) {
	    my $type=int(rand(2));
	    # -- nom de ville
	    if ($type==1) {
		my ($cp,$vi);
		if ($villes{$ville}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
		my $dpt=substr($cp,0,2);
		my $lieu="";
		if ($vi=~/^[AEIOUY]/) { $lieu="d\'".$vi; } elsif ($vi=~/^Les/) { $lieu="d".substr($vi,1); } else { $lieu="de ".$vi; }
		$ligne=~s/aux urgences(\,| pour)/aux urgences $lieu$1/;
		$transfo=&log($fichier,$ligne,"$vi");
		#print "--- $ligne\n";
	    } elsif ($type==0) {
		my $chu=$prenoms{int(rand($maxPrenoms))}."\-".$noms{int(rand($maxNoms))};
		$ligne=~s/aux urgences(\,| pour)/aux urgences du CHU $chu$1/;
		#print "--- $ligne\n";
		$transfo=&log($fichier,$ligne,"$chu");
	    }
	}

	# Pays
	if ($ligne=~/l.étranger/) { my $nopa=$pays[int(rand($#pays))]; $ligne=~s/(l.étranger)/$1 \($nopa\)/; $transfo=&log($fichier,$ligne,"$nopa"); }


	# MAPA juridique
	if ($ligne=~/\[\.\.\.\]/) {
	    my $adresse=&genereAdresse();
	    $ligne=~s/\[\.\.\.\]/$adresse\, $villes{$ville}/;
	    $transfo=&log($fichier,$ligne,"$adresse\, $villes{$ville}");
	}

	$contenu{$sortie}.="$ligne\n";
    }
    close(E);

    # Si aucune modification du contenu n'a été réalisée, ou si le
    # pronom "Vous" est trouvé (contenu pédagogique trop différent),
    # on ne mémorise pas le fichier
    if ($transfo==0 || $contenu{$sortie}=~/Vous/) { $contenu{$sortie}=""; }
}

foreach my $sortie (sort keys %contenu) {
    # On ne produit que les fichiers dont le contenu a été modifié
    if ($contenu{$sortie} ne "") {
	warn "Produit $sortie\n";
	open(S,'>:utf8',$sortie);
	print S $contenu{$sortie};
	close(S);
    }
}



###
# Sous-programmes

sub recupereRessources() {
    # Noms de famille : patronyme,décompte
    my $nbNoms=0;
    open(E,'<:utf8',"data/patronymes.csv");
    while (my $ligne=<E>) {
	$ligne=~s/ D / D\'/;
	chomp $ligne; my @cols=split(/\,/,$ligne);
	if ($cols[1]>4) {
	    my $t="";
	    # Initiale en majuscule, le reste en minuscules, avec
	    # gestion des noms composés (espace ou trait d'union)
	    if ($cols[0]!~/ /) { $t=substr($cols[0],0,1).lc(substr($cols[0],1)); }
	    #elsif ($cols[0]=~/\-/) { my @c=split(/\-/,$cols[0]); foreach my $e (@c) { $t.=substr($e,0,1).lc(substr($e,1))."\-"; } chop $t; }
	    else {
		my @c=split(/ /,$cols[0]);
		foreach my $e (@c) {
		    # Les particules françaises sont en minuscules (de d' du le la)
		    if ($e!~/^(DE|DU|D\'|LE|LA)$/) { $t.=substr($e,0,1).lc(substr($e,1))." "; }
		    else { $t.=lc(substr($e,0))." "; }
		}
		chop $t;
	    }
	    #$t="§§ ".$t;
	    $noms{$nbNoms}=$t; $nbNoms++;
	    #if ($t=~/(^|\s)[a-z]+(\s|$)/) { print "--- $t\n"; }
	}
    }
    close(E);

    # Prénoms : prénom,décompte
    my $nbPrenoms=0;
    open(E,'<:utf8',"data/prenom.csv");
    while (my $ligne=<E>) {
	chomp $ligne; my @cols=split(/\,/,$ligne);
	if ($cols[1]>=1500) {
	    my $t="";
	    if ($cols[0]!~/ /) { $t=substr($cols[0],0,1).lc(substr($cols[0],1));}
	    #elsif ($cols[0]=~/\-/) { my @c=split(/\-/,$cols[0]); foreach my $e (@c) { $t.=substr($e,0,1).lc(substr($e,1))."\-"; } chop $t; }
	    else { my @c=split(/ /,$cols[0]); foreach my $e (@c) { $t.=substr($e,0,1).lc(substr($e,1))." "; } chop $t; }
	    #$t="§§ ".$t;
	    $prenoms{$nbPrenoms}=$t; $nbPrenoms++;
	    #if ($t=~/(^|\s)[a-z]+(\s|$)/) { warn "--- $t\n"; }
	}
    }
    close(E);

    # Villes
    my $nbVilles=0;
    open(E,'<:utf8',"data/codepostaux2019.csv");
    while (my $ligne=<E>) {
	chomp $ligne; my @cols=split(/\,/,$ligne);
	$villes{$nbVilles}="$cols[0] $cols[2]"; $nbVilles++;
    }
    close(E);

    return ($nbNoms,$nbPrenoms,$nbVilles);
}

sub genereAdresse() {
    # Type de voirie (avenue, place, rue, etc.)
    my $voie=$voiries[int(rand($#voiries))];
    # Numérotation maximum en fonction du type de voirie (numéros peu
    # élevés sur des impasses et des places, beaucoup plus hauts sur
    # des avenues)
    my $maximum=60;
    if ($voie eq "boulevard" || $voie eq "avenue") { $maximum=200; }
    elsif ($voie eq "impasse" || $voie eq "place" || $voie eq "chemin") { $maximum=20; }
    my $numero=int(rand($maximum))+1; my $z=int(rand(10)); if ($z==8) { $numero.=" bis"; }
    # Type d'oronyme : nom de lieux ou de personne ou d'événement
    my $typeOro=int(rand(2));
    my $oronyme="";
    if ($typeOro==0) {
	my ($cp,$vi);
	if ($villes{int(rand($maxVilles))}=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	if ($vi=~/^[AEIOUY]/) { $oronyme="d\'".$vi; } elsif ($vi=~/^Les/) { $oronyme="d".substr($vi,1); } else { $oronyme="de ".$vi; }
    }
    elsif ($typeOro==1) { $oronyme=$prenoms{int(rand($maxPrenoms))}." ".$noms{int(rand($maxNoms))}; }
    else { $oronyme="de la République"; }

    # Construction finale
    my $final="$numero $voie $oronyme";
    #warn "--- $final\n";
    return $final;
}

sub log() {
    my ($f,$l,$p)=@_;
    $l=~s/$p/\-\-\[$p\]\-\-/g;
    #print "- $l\n" if ($l=~/domicile/);
    my $modif=1;
    return $modif;
}
