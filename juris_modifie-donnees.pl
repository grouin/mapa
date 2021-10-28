#!/usr/bin/perl

# A partir de listes de 209310 prénoms, 879422 noms, et 35729 villes,
# récupère les noms de fréquence supérieure à 4 (soit 174207 noms)
# pour éliminer les erreurs, les prénoms de fréquence supérieure à
# 1500 (soit 697 prénoms), normalise ces entrées (mise en minuscules),
# et réintroduit aléatoirement des noms de personnes, et des lieux
# (adresses complètes ou simple ville) en différents endroits du
# corpus de jurisprudence. Ne produit que les sorties qui ont été
# modifiées.

# Auteur : Cyril Grouin, avril 2021.

# perl modifieFichiersJuris.pl corpus/mapa/ corpus/mapa2/
# perl modifieFichiersJuris.pl corpus/CIVILE/ corpus/CIVILE2/


use utf8;
use strict;
binmode STDOUT, ":encoding(utf8)";


my ($in,$out)=@ARGV;
my @fichiers=<$in/*xml>;
my %prenoms=();
my %prenomsFem=();
my %prenomsMasc=();
my %noms=();
my %villes=();
my %prenomsOrdre=();
my @voiries=("impasse","avenue","place","rue","chemin","allée","boulevard","rue","route");
my @pays=("Argentine","Canada","Chine","Espagne","Etats-Unis","Japon","Royaume-Uni","Russie","Sénégal");
my %contenu=();
my @alphabet=("A"..."Z");
my @consonnes=("b","c","d","f","g","l","m","n","p","r","s","t","v","x","cc","mm","nn","ss");
my @voyelles=("a","e","i","o","y");


###
# Configuration

my $maxVilles=&recupereRessources();


###
# Application

foreach my $fichier (@fichiers) {
    my $sortie=$fichier; $sortie=~s/$in/$out/;
    my $ville=int(rand($maxVilles));
    my $transfo=0;

    # Pour chaque fichier, on reproduit le même nom, prénom, ville, à
    # l'identique dès lors que l'initiale présente dans le texte est
    # la même
    my %listeNomsMasculins=();
    my %listeNomsFeminins=();
    my %listeNomsAvocats=();
    my %listePrenomsMasculins=();
    my %listePrenomsFeminins=();
    my %listeVilles=();
    my %listeSocietes=();
    
    open(E,'<:utf8',$fichier);
    while (my $ligne=<E>) {
	chomp $ligne;

	# NOM PRENOM MASCULIN : en la personne de M. Q... B...,
	my $z=0;
	while ($ligne=~/M\. (\w)\.\.\. (\w)\.\.\./) {
	    # On récupère l'initiale indiquée ; s'il s'agit du X
	    # (lettre d'anonymat par défaut), on la remplace
	    # aléatoirement par une lettre de l'alphabet
	    my ($initialeNom,$initialePrenom)=($1,$2);
	    if ($initialeNom eq "X") { $initialeNom=$alphabet[int(rand($#alphabet+1))]; }
	    if ($initialePrenom eq "X") { $initialePrenom=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit=""; my $prenomProduit="";
	    # Si des nom et prénom pour ces initiales ont déjà été
	    # générés, on les reprend, sinon, on en génère et on les
	    # mémorise pour les prochaines mentions
	    if (exists $listeNomsMasculins{$initialeNom}) { $nomProduit=$listeNomsMasculins{$initialeNom}; }
	    else {
		my @nomsIni=split(/§/,$noms{$initialeNom}); my $alea=int(rand($#nomsIni+1));
		$nomProduit=$nomsIni[$alea]; $listeNomsMasculins{$initialeNom}=$nomsIni[$alea];
	    }
	    if (exists $listePrenomsMasculins{$initialePrenom}) { $prenomProduit=$listePrenomsMasculins{$initialePrenom}; }
	    else {
		my @prenomsIni=split(/§/,$prenomsMasc{$initialePrenom}); my $alea=int(rand($#prenomsIni+1));
		$prenomProduit=$prenomsIni[$alea]; $listePrenomsMasculins{$initialePrenom}=$prenomsIni[$alea];
	    }
	    
	    $ligne=~s/M\. \w\.\.\. \w\.\.\./M. $nomProduit $prenomProduit/; $transfo=&log($fichier,$ligne,"$nomProduit $prenomProduit");
	    $z++;
	}
	
	
	while ($ligne=~/Monsieur (\w)\.\.?\.? (\w)\.\.\./) {
	    my ($initialeNom,$initialePrenom)=($1,$2);
	    if ($initialeNom eq "X") { $initialeNom=$alphabet[int(rand($#alphabet+1))]; }
	    if ($initialePrenom eq "X") { $initialePrenom=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit=""; my $prenomProduit="";
	    if (exists $listeNomsMasculins{$initialeNom}) { $nomProduit=$listeNomsMasculins{$initialeNom}; }
	    else {
		my @nomsIni=split(/§/,$noms{$initialeNom}); my $alea=int(rand($#nomsIni+1));
		$nomProduit=$nomsIni[$alea]; $listeNomsMasculins{$initialeNom}=$nomsIni[$alea];
	    }
	    if (exists $listePrenomsMasculins{$initialePrenom}) { $prenomProduit=$listePrenomsMasculins{$initialePrenom}; }
	    else {
		my @prenomsIni=split(/§/,$prenomsMasc{$initialePrenom}); my $alea=int(rand($#prenomsIni+1));
		$prenomProduit=$prenomsIni[$alea]; $listePrenomsMasculins{$initialePrenom}=$prenomsIni[$alea];
	    }
	    
	    $ligne=~s/Monsieur \w\.\.?\.? \w\.\.\./Monsieur $nomProduit $prenomProduit/; $transfo=&log($fichier,$ligne,"$nomProduit $prenomProduit");
	    $z++;
	}
	
	
	# NOM PRENOM FEMININ : en la personne de Mme E... O...,
	while ($ligne=~/Mme (\w)\.\.\. (\w)\.\.\./) {
	    my ($initialeNom,$initialePrenom)=($1,$2);
	    if ($initialeNom eq "X") { $initialeNom=$alphabet[int(rand($#alphabet+1))]; }
	    if ($initialePrenom eq "X") { $initialePrenom=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit=""; my $prenomProduit="";
	    if (exists $listeNomsFeminins{$initialeNom}) { $nomProduit=$listeNomsFeminins{$initialeNom}; }
	    else {
		my @nomsIni=split(/§/,$noms{$initialeNom}); my $alea=int(rand($#nomsIni+1));
		$nomProduit=$nomsIni[$alea]; $listeNomsFeminins{$initialeNom}=$nomsIni[$alea];
	    }
	    if (exists $listePrenomsFeminins{$initialePrenom}) { $prenomProduit=$listePrenomsFeminins{$initialePrenom}; }
	    else {
		my @prenomsIni=split(/§/,$prenomsFem{$initialePrenom}); my $alea=int(rand($#prenomsIni+1));
		$prenomProduit=$prenomsIni[$alea]; $listePrenomsFeminins{$initialePrenom}=$prenomsIni[$alea];
	    }
	    
	    $ligne=~s/Mme \w\.\.\. \w\.\.\./Mme $nomProduit $prenomProduit/; $transfo=&log($fichier,$ligne,"$nomProduit $prenomProduit");
	}

	while ($ligne=~/Madame (\w)\.\.\. (\w)\.\.\./) {
	    my ($initialeNom,$initialePrenom)=($1,$2);
	    if ($initialeNom eq "X") { $initialeNom=$alphabet[int(rand($#alphabet+1))]; }
	    if ($initialePrenom eq "X") { $initialePrenom=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit=""; my $prenomProduit="";
	    if (exists $listeNomsFeminins{$initialeNom}) { $nomProduit=$listeNomsFeminins{$initialeNom}; }
	    else {
		my @nomsIni=split(/§/,$noms{$initialeNom}); my $alea=int(rand($#nomsIni+1));
		$nomProduit=$nomsIni[$alea]; $listeNomsFeminins{$initialeNom}=$nomsIni[$alea];
	    }
	    if (exists $listePrenomsFeminins{$initialePrenom}) { $prenomProduit=$listePrenomsFeminins{$initialePrenom}; }
	    else {
		my @prenomsIni=split(/§/,$prenomsFem{$initialePrenom}); my $alea=int(rand($#prenomsIni+1));
		$prenomProduit=$prenomsIni[$alea]; $listePrenomsFeminins{$initialePrenom}=$prenomsIni[$alea];
	    }
	    
	    $ligne=~s/Madame \w\.\.\. \w\.\.\./Madame $nomProduit $prenomProduit/; $transfo=&log($fichier,$ligne,"$nomProduit $prenomProduit");
	}


	# NOM MASCULIN : Condamne M. X...,
	while ($ligne=~/M\. (\w)\.\.\./) {
	    # On récupère l'initiale indiquée ; s'il s'agit du X
	    # (lettre d'anonymat par défaut), on la remplace
	    # aléatoirement par une lettre de l'alphabet
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    # Si un nom de cette initiale a déjà été généré, on le
	    # reprend
	    if (exists $listeNomsMasculins{$ini}) { $ligne=~s/M\. \w\.\.\./M. $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}"); }
	    # Sinon, on en génère un et on le mémorise pour les
	    # prochaines mentions avec cette initiale
	    else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/M\. \w\.\.\./M. $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/Monsieur (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsMasculins{$ini}) { $ligne=~s/Monsieur \w\.\.\./M. $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}"); }
	    else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Monsieur \w\.\.\./Monsieur $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}

	# NOM FEMININ : en la personne de Mme O...,
	while ($ligne=~/Mme (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsFeminins{$ini}) {
		$ligne=~s/Mme \w\.\.\./Mme $listeNomsFeminins{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsFeminins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Mme \w\.\.\./Mme $nomsIni[$alea]/; $listeNomsFeminins{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/Madame (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsFeminins{$ini}) {
		$ligne=~s/Madame \w\.\.\./Madame $listeNomsFeminins{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsFeminins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Madame \w\.\.\./Madame $nomsIni[$alea]/; $listeNomsFeminins{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/Mme (\w+) (\w)\.\.\.?/) {
	    my ($pre,$ini)=($1,$2); if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsFeminins{$ini}) {
		$ligne=~s/Mme $pre \w\.\.\.?/Mme $pre $listeNomsFeminins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsFeminins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Mme $pre \w\.\.\.?/Mme $pre $nomsIni[$alea]/; $listeNomsFeminins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }	    
	}
	while ($ligne=~/Madame (\w+) (\w)\.\.\.?/) {
	    my ($pre,$ini)=($1,$2); if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsFeminins{$ini}) {
		$ligne=~s/Madame $pre \w\.\.\.?/Madame $pre $listeNomsFeminins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsFeminins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Madame $pre \w\.\.\.?/Madame $pre $nomsIni[$alea]/; $listeNomsFeminins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }	    
	}
	while ($ligne=~/épouse (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsAvocats{$ini}) {
		$ligne=~s/épouse \w\.\.\./épouse $listeNomsAvocats{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsAvocats{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/épouse \w\.\.\./épouse $nomsIni[$alea]/; $listeNomsAvocats{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/née (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsAvocats{$ini}) {
		$ligne=~s/née \w\.\.\./née $listeNomsAvocats{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsAvocats{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/née \w\.\.\./née $nomsIni[$alea]/; $listeNomsAvocats{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	# AVOCAT : d'avoir condamné Me X...
	while ($ligne=~/Me (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsAvocats{$ini}) {
		$ligne=~s/Me \w\.\.\./Me $listeNomsAvocats{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsAvocats{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Me \w\.\.\./Me $nomsIni[$alea]/; $listeNomsAvocats{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/époux (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsAvocats{$ini}) {
		$ligne=~s/époux \w\.\.\./époux $listeNomsAvocats{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsAvocats{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/époux \w\.\.\./époux $nomsIni[$alea]/; $listeNomsAvocats{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	while ($ligne=~/courtier (\w)\.\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsAvocats{$ini}) {
		$ligne=~s/courtier \w\.\.\./courtier $listeNomsAvocats{$ini}/;
		$transfo=&log($fichier,$ligne,"$listeNomsAvocats{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/courtier \w\.\.\./courtier $nomsIni[$alea]/; $listeNomsAvocats{$ini}=$nomsIni[$alea]; 
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}
	
	# NOM MASCULIN : que M. X.. et la SCP
	while ($ligne=~/M\. (\w)\.\./) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsMasculins{$ini}) {
		$ligne=~s/M\. \w\.\./M. $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/M\. \w\.\./M. $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}

	
	# condamné M. François A..., pris en sa qualité d'héritier de M. Henri A...,
	# condamner Maître François A...,

	while ($ligne=~/M\. (\w+) (\w)\.\.\.?/) {
	    my ($pre,$ini)=($1,$2); if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsMasculins{$ini}) {
		$ligne=~s/M\. $pre \w\.\.\.?/M. $pre $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/M\. $pre \w\.\.\.?/M. $pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }	    
	}
	while ($ligne=~/Monsieur (\w+) (\w)\.\.\.?/) {
	    my ($pre,$ini)=($1,$2); if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsMasculins{$ini}) {
		$ligne=~s/Monsieur $pre \w\.\.\.?/Monsieur $pre $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/Monsieur $pre \w\.\.\.?/Monsieur $pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }	    
	}
	while ($ligne=~/(Me|Maître) (\w+) (\w)\.\.\.?/) {
	    my ($type,$pre,$ini)=($1,$2,$3); if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    if (exists $listeNomsMasculins{$ini}) {
		$ligne=~s/$type $pre \w\.\.\.?/$type $pre $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/$type $pre \w\.\.\.?/$type $pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }	    
	}

	# acte reçu par Henri A...,
	# successeur d'Henri A...,

	# while ($ligne=~/(par |de |d\'|que |à )([A-Z]\w+) (\w)\.\.\.?/) {
	#     my ($prep,$pre,$ini)=($1,$2,$3);
	#     if (exists $prenomsOrdre{$pre}) {
	# 	if (exists $listeNomsMasculins{$ini}) {
	# 	    $ligne=~s/$prep$pre \w\.\.\.?/$prep$pre $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
	# 	} else {
	# 	    my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
	# 	    $ligne=~s/$prep$pre \w\.\.\.?/$prep$pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
	# 	    $transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	# 	}	    
	#     } else {
	# 	my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
	# 	$ligne=~s/$prep$pre \w\.\.\.?/$prep$pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
	# 	$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	#     }	    
	# }
	
	while ($ligne=~/([A-Z]\w+) (\w)\.\.\.?/) {
	    my ($pre,$ini)=($1,$2);
	    if (exists $prenomsOrdre{$pre}) {
		if (exists $listeNomsMasculins{$ini}) {
		    $ligne=~s/$pre \w\.\.\.?/$pre $listeNomsMasculins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini}");
		} elsif (exists $listeNomsFeminins{$ini}) {
		    $ligne=~s/$pre \w\.\.\.?/$pre $listeNomsFeminins{$ini}/; $transfo=&log($fichier,$ligne,"$listeNomsFeminins{$ini}");
		} else {
		    my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		    $ligne=~s/$pre \w\.\.\.?/$pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		    $transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
		}
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/$pre \w\.\.\.?/$pre $nomsIni[$alea]/; $listeNomsMasculins{$ini}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}

	###
	# Villes
	
	# un appartement situé [...] , 4ème étage,
	# cinquième sous-sol du parking [...] ;

	# mise en garde ; [...] qu'au
	# au sein du "M... I..." ; [...] que la pièce
	while ($ligne=~/[^\;] \[\.\.\.\]/) {
	    my $adresse=&genereAdresse();
	    my ($cp,$vi);
	    my $initialeVille=$alphabet[int(rand($#alphabet+1))];
	    my @villesIni=split(/§/,$villes{$initialeVille}); my $alea=int(rand($#villesIni+1)); my $villeProduite=$villesIni[$alea];
	    if ($villeProduite=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	    $ligne=~s/([^\;]) \[\.\.\.\]/$1 $adresse, $cp $vi/; $ligne=~s/$vi \,/$vi\,/;
	    $transfo=&log($fichier,$ligne,"$adresse, $cp $vi");
	}
	# les adresses ne sont pas mémorisées : des adresses
	# différentes seront générées dans le document alors qu'il
	# peut s'agir d'un même endroit décrit à plusieurs reprises ;
	# nécessité de tenir compte du contexte pour repérer les mêmes
	# sites (parking, 4ème étage, etc.)
	

	# # Pays
	# if ($ligne=~/l.étranger/) { my $nopa=$pays[int(rand($#pays))]; $ligne=~s/(l.étranger)/$1 \($nopa\)/; $transfo=&log($fichier,$ligne,"$nopa"); }


	###
	# Sociétés

	# la société I...-O...,
	# la société I... O...,
	
	while ($ligne=~/(groupe|société|entreprise) (\w)\.\.\.?( |\-)(\w)\.\.\.?/) {
	    my ($type,$ini1,$sep,$ini2)=($1,$2,$3,$4);
	    if (exists $listeSocietes{"$ini1$ini2"}) {
		my $societe=$listeSocietes{"$ini1$ini2"};
		chomp $societe; $societe=~s/ /$sep/;
		$ligne=~s/$type (\w)\.\.\.?( |\-)(\w)\.\.\.?/$type $societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    } else {
		my $societe=&genereSociete($ini1,$ini2); $listeSocietes{"$ini1$ini2"}=$societe;
		chomp $societe; $societe=~s/ /$sep/;
		$ligne=~s/$type (\w)\.\.\.?( |\-)(\w)\.\.\.?/$type $societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    }
	}

	while ($ligne=~/(groupe|société|entreprise) (\w)\.\.\.?/) {
	    my ($type,$ini1)=($1,$2);
	    if (exists $listeSocietes{"$ini1"}) {
		my $societe=$listeSocietes{"$ini1"};
		chomp $societe;
		$ligne=~s/$type (\w)\.\.\.?/$type $societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    } else {
		my $societe=&genereSociete($ini1); $listeSocietes{"$ini1"}=$societe;
		chomp $societe;
		$ligne=~s/$type (\w)\.\.\.?/$type $societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    }
	}

	# et I...-O..., ès qualités,

	while ($ligne=~/(groupe|sociétés|entreprises) [^\.]+ et (\w)\.\.\.( |\-)(\w)\.\.\./) {
	    my ($type,$ini1,$sep,$ini2)=($1,$2,$3,$4);
	    if (exists $listeSocietes{"$ini1$ini2"}) {
		my $societe=$listeSocietes{"$ini1$ini2"};
		chomp $societe; $societe=~s/ /$sep/;
		$ligne=~s/(\w)\.\.\.( |\-)(\w)\.\.\./$societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    } else {
		my $societe=&genereSociete($ini1,$ini2); $listeSocietes{"$ini1$ini2"}=$societe;
		chomp $societe; $societe=~s/ /$sep/;
		$ligne=~s/(\w)\.\.\.( |\-)(\w)\.\.\./$societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    }
	}
	
	    
	# la SCP X...Y...Z... à payer
	while ($ligne=~/X\.\.\.?Y\.\.\.?Z\.\.\.?/) {
	    my $ini1=uc($voyelles[int(rand($#voyelles+1))]);
	    my $ini2=uc($voyelles[int(rand($#voyelles+1))]);
	    if (exists $listeSocietes{"XYZ"}) {
		my $societe=$listeSocietes{"XYZ"};
		chomp $societe;
		$ligne=~s/X\.\.\.?Y\.\.\.?Z\.\.\.?/$societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    } else {
		my $societe=&genereSociete($ini1,$ini2); $listeSocietes{"XYZ"}=$societe;
		chomp $societe;
		$ligne=~s/X\.\.\.?Y\.\.\.?Z\.\.\.?/$societe/; $ligne=~s/$societe\s+\,/$societe\,/;
		$transfo=&log($fichier,$ligne,"$societe");
	    }
	}

	# et la SCP X...et associés...
	# par la SCP X... et associés
	# la SCP X... et Me X... consécutivement
	
	while ($ligne=~/SCP (\w)\.\.\.( |\-)(\w)\.\.\./) {
	    my ($ini1,$sep,$ini2)=($1,$2,$3);
	    if ($ini1 eq "X") { $ini1=$alphabet[int(rand($#alphabet+1))]; }
	    if ($ini2 eq "X") { $ini2=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit1=""; my $nomProduit2="";
	    if (exists $listeNomsMasculins{$ini1}) { $nomProduit1=$listeNomsMasculins{$ini1}; }
	    else {
		my @nomsIni=split(/§/,$noms{$ini1}); my $alea=int(rand($#nomsIni+1));
		$nomProduit1=$nomsIni[$alea]; $listeNomsMasculins{$ini1}=$nomsIni[$alea];
	    }
	    if (exists $listeNomsMasculins{$ini2}) { $nomProduit2=$listeNomsMasculins{$ini2}; }
	    else {
		my @nomsIni=split(/§/,$noms{$ini2}); my $alea=int(rand($#nomsIni+1));
		$nomProduit2=$nomsIni[$alea]; $listeNomsMasculins{$ini2}=$nomsIni[$alea];
	    }
	    
	    $ligne=~s/SCP \w\.\.\.$sep\w\.\.\./SCP $nomProduit1$sep$nomProduit2/; $transfo=&log($fichier,$ligne,"$nomProduit1$sep$nomProduit2");
	}
	
	while ($ligne=~/SCP (\w)\.\.\.?/) {
	    my $ini=$1; my $ini2=$ini; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; $ini2="X"; }
	    if (exists $listeNomsMasculins{$ini2}) {
		$ligne=~s/SCP \w\.\.\.?/SCP $listeNomsMasculins{$ini2} /; $ligne=~s/($listeNomsMasculins{$ini2})\s+/$1 /g;
		$transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini2}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/SCP \w\.\.\.?/SCP $nomsIni[$alea] /; $ligne=~s/($listeNomsMasculins{$ini2})\s+/$1 /g;
		$listeNomsMasculins{$ini2}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	    # my $ini=$1; my $ini2=$ini; if ($ini eq "X") { $ini=uc($voyelles[int(rand($#voyelles+1))]); $ini2="X"; }
	    # if (exists $listeSocietes{$ini2}) {
	    # 	my $societe=$listeSocietes{$ini2};
	    # 	chomp $societe;
	    # 	$ligne=~s/SCP \w\.\.\.?/SCP $societe/; $ligne=~s/$societe \,/$societe\,/;
	    # 	$transfo=&log($fichier,$ligne,"$societe");
	    # } else {
	    # 	my $societe=&genereSociete($ini); $listeSocietes{$ini2}=$societe;
	    # 	chomp $societe;
	    # 	$ligne=~s/SCP \w\.\.\.?/SCP $societe/; $ligne=~s/$societe \,/$societe\,/;
	    # 	$transfo=&log($fichier,$ligne,"$societe");
	    # 	warn "-- SCP $societe --\n";
	    # }
	}

	# consorts X... Y...
	while ($ligne=~/consorts (\w)\.\.\.( |\-)(\w)\.\.\./) {
	    my ($ini1,$sep,$ini2)=($1,$2,$3);
	    if ($ini1 eq "X") { $ini1=$alphabet[int(rand($#alphabet+1))]; }
	    if ($ini2 eq "Y") { $ini2=$alphabet[int(rand($#alphabet+1))]; }
	    my $nomProduit1=""; my $nomProduit2="";
	    if (exists $listeNomsMasculins{$ini1}) { $nomProduit1=$listeNomsMasculins{$ini1}; }
	    else {
		my @nomsIni=split(/§/,$noms{$ini1}); my $alea=int(rand($#nomsIni+1));
		$nomProduit1=$nomsIni[$alea]; $listeNomsMasculins{$ini1}=$nomsIni[$alea];
	    }
	    if (exists $listeNomsFeminins{$ini2}) { $nomProduit2=$listeNomsFeminins{$ini2}; }
	    else {
		my @nomsIni=split(/§/,$noms{$ini2}); my $alea=int(rand($#nomsIni+1));
		$nomProduit2=$nomsIni[$alea]; $listeNomsFeminins{$ini2}=$nomsIni[$alea];
	    }
	    
	    $ligne=~s/consorts \w\.\.\.$sep\w\.\.\./consorts $nomProduit1$sep$nomProduit2/; $transfo=&log($fichier,$ligne,"$nomProduit1$sep$nomProduit2");
	}
	
	while ($ligne=~/consorts (\w)\.\.\.?/) {
	    my $ini=$1; my $ini2=$ini; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; $ini2="X"; }
	    if (exists $listeNomsMasculins{$ini2}) {
		$ligne=~s/consorts \w\.\.\.?/SCP $listeNomsMasculins{$ini2} /; $ligne=~s/($listeNomsMasculins{$ini2})\s+/$1 /g;
		$transfo=&log($fichier,$ligne,"$listeNomsMasculins{$ini2}");
	    } else {
		my @nomsIni=split(/§/,$noms{$ini}); my $alea=int(rand($#nomsIni+1));
		$ligne=~s/consorts \w\.\.\.?/SCP $nomsIni[$alea] /; $ligne=~s/($listeNomsMasculins{$ini2})\s+/$1 /g;
		$listeNomsMasculins{$ini2}=$nomsIni[$alea];
		$transfo=&log($fichier,$ligne,"$nomsIni[$alea]");
	    }
	}


	###
	# Initiale(s) isolée(s) (boucle potentiellement dangereuse) :
	# - le conseiller apparaît comme étant "K..."
	# - je pense que D... contrairement aux autres intermédiaires
	# - le prêt Helvet Immo à D...
	# - avait pour nom commercial "M... O..."
	# - a pour nom commercial "N... Capital''
	# - anciennement dénommée I...
	# - au sein du "M... I..."
	
	while ($ligne=~/(\w)\.\.\.?/) {
	    my $ini=$1; if ($ini eq "X") { $ini=$alphabet[int(rand($#alphabet+1))]; }
	    my @listeLoc=split(/§/,$prenoms{$ini}); my $alea=int(rand($#listeLoc+1));
	    $ligne=~s/\w\.\.\.?/$listeLoc[$alea]/; $listeNomsMasculins{$ini}=$listeLoc[$alea];
	    $transfo=&log($fichier,$ligne,"$listeLoc[$alea]");
	}
	
	

	# Nettoyage
	$ligne=~s/associés\.\.\./associés/g;
	$ligne=~s/([^\s])et associé/$1 et associé/g;


	
	$contenu{$sortie}.="$ligne\n";
    }
    close(E);

    # Si aucune modification du contenu n'a été réalisée, on ne
    # mémorise pas le fichier
    if ($transfo==0) { $contenu{$sortie}=""; }
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
    # # Noms de famille : patronyme,décompte
    # open(E,'<:utf8',"data/patronymes.csv");
    # while (my $ligne=<E>) {
    # 	$ligne=~s/ D / D\'/;
    # 	chomp $ligne; my @cols=split(/\,/,$ligne);
    # 	if ($cols[1]>4) {
    # 	    my $t="";
    # 	    # Initiale en majuscule, le reste en minuscules, avec
    # 	    # gestion des noms composés (espace ou trait d'union)
    # 	    if ($cols[0]!~/ /) { $t=substr($cols[0],0,1).lc(substr($cols[0],1)); }
    # 	    else {
    # 		my @c=split(/ /,$cols[0]);
    # 		foreach my $e (@c) {
    # 		    # Les particules françaises sont en minuscules (de d' du le la)
    # 		    if ($e!~/^(DE|DU|D\'|LE|LA)$/) { $t.=substr($e,0,1).lc(substr($e,1))." "; }
    # 		    else { $t.=lc(substr($e,0))." "; }
    # 		}
    # 		chop $t;
    # 	    }
    # 	    my $initiale=substr($t,0,1);
    # 	    # Nettoyage
    # 	    $t=~s/iere/ière/;
    # 	    $noms{$initiale}.="$t§";
    # 	}
    # }
    # close(E);

    # # Prénoms : prénom,décompte
    # open(E,'<:utf8',"data/prenom-fr.csv");
    # while (my $ligne=<E>) {
    # 	# chomp $ligne; my @cols=split(/\,/,$ligne);
    # 	# if ($cols[1]>=1500) {
    # 	#     my $t="";
    # 	#     if ($cols[0]!~/ /) { $t=substr($cols[0],0,1).lc(substr($cols[0],1));}
    # 	#     else { my @c=split(/ /,$cols[0]); foreach my $e (@c) { $t.=substr($e,0,1).lc(substr($e,1))." "; } chop $t; }
    # 	#     my $initiale=substr($t,0,1);
    # 	#     $prenoms{$initiale}.="$t§";
    # 	#     $prenomsOrdre{$t}++;
    # 	# }
    # 	chomp $ligne; my @cols=split(/\t/,$ligne);
    # 	my $t=$cols[1];
    # 	my $initiale=substr($t,0,1);
    # 	$prenoms{$initiale}.="$t§";
    # 	$prenomsFem{$initiale}.="$t§" if ($cols[2]=~/F/);
    # 	$prenomsMasc{$initiale}.="$t§" if ($cols[2]=~/M/);
    # 	$prenomsOrdre{$t}++;
    # }
    # close(E);

    open(E,'<:utf8',"data/sirene/liste-noms.csv");
    while (my $ligne=<E>) {
	$ligne=~s/ D / D\'/;
	chomp $ligne; my @cols=split(/\t/,$ligne);
	my $initiale=substr($cols[1],0,1);
	$noms{$initiale}.="$cols[1]§";
    }
    close(E);

    open(E,'<:utf8',"data/sirene/liste-prenoms-fem.csv");
    while (my $ligne=<E>) {
	chomp $ligne; my @cols=split(/\t/,$ligne);
	my $t=$cols[1];
	my $initiale=substr($cols[1],0,1);
	$prenoms{$initiale}.="$t§";
	$prenomsFem{$initiale}.="$t§";
	$prenomsOrdre{$t}++;
    }
    close(E);

    open(E,'<:utf8',"data/sirene/liste-prenoms-masc.csv");
    while (my $ligne=<E>) {
	chomp $ligne; my @cols=split(/\t/,$ligne);
	my $t=$cols[1];
	my $initiale=substr($cols[1],0,1);
	$prenoms{$initiale}.="$t§";
	$prenomsMasc{$initiale}.="$t§";
	$prenomsOrdre{$t}++;
    }
    close(E);

    # Villes
    my $nbVilles=0;
    open(E,'<:utf8',"data/codepostaux2019.csv");
    while (my $ligne=<E>) {
	chomp $ligne; my @cols=split(/\,/,$ligne);
	my $initiale=substr($cols[2],0,1);
	$villes{$initiale}.="$cols[0] $cols[2]§"; $nbVilles++;
    }
    close(E);

    return $nbVilles;
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
	my $initialeVille=$alphabet[int(rand($#alphabet+1))];
	my @villesIni=split(/§/,$villes{$initialeVille}); my $alea=int(rand($#villesIni+1)); my $villeProduite=$villesIni[$alea];
	if ($villeProduite=~/^(\d+) (.*)$/) { $cp=$1; $vi=$2; }
	if ($vi=~/^[AEIOUY]/) { $oronyme="d\'".$vi; } elsif ($vi=~/^Les/) { $oronyme="d".substr($vi,1); } else { $oronyme="de ".$vi; }
    }
    elsif ($typeOro==1) {
	my $initialeNom=$alphabet[int(rand($#alphabet+1))];
	my @nomsIni=split(/§/,$noms{$initialeNom}); my $alea=int(rand($#nomsIni+1)); my $nomProduit=$nomsIni[$alea];
	my $initialePrenom=$alphabet[int(rand($#alphabet+1))];
	my @prenomsIni=split(/§/,$prenoms{$initialePrenom}); my $alea=int(rand($#prenomsIni+1)); my $prenomProduit=$prenomsIni[$alea];
	$oronyme=$prenomProduit." ".$nomProduit;
    }
    else { $oronyme="de la République"; }

    # Construction finale
    my $final="$numero $voie $oronyme";
    #warn "--- $final\n";
    return $final;
}

sub log() {
    my ($f,$l,$p)=@_;
    $l=~s/$p/\-\-\[$p\]\-\-/g;
    my $ii=index($l,$p);
    my $portion=substr($l,$ii-20,length($p)+40);
    #print "- $f\t$portion\n";
    my $modif=1;
    return $modif;
}

sub genereSociete() {
    my @lettres=@_;
    my $n="";
    foreach my $lettre (@lettres) {
	$n.=$lettre;
	my $nbCar=int(rand(2))+1;
	for (my $i=0;$i<$nbCar;$i++) {
	    my $cons=$consonnes[int(rand($#consonnes+1))];
	    my $voy=$voyelles[int(rand($#voyelles+1))];
	    # Pas de voyelles après une plosives
	    if (($cons eq "p" || $cons eq "b") && $i!=$nbCar-1) { $n.="$cons"; }
	    else { $n.="$cons$voy"; }
	}
	$n.=" ";
    }
    # Francisation, Latinisation
    $n=~s/e $/erre/;
    $n=~s/i $/ium/;
    #$n=~s/a $/ane/;
    #$n=~s/o $/\'One/;
    return $n;
}
