#!/usr/bin/env perl

#
# Copyright (c) 2015, Stefan Reif
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

use warnings;
use strict;

my $what = shift;
my $other = (grep { $_ ne $what }("strat", "type"))[0];
my $outfile = shift;

my $IMAGEH = 20;

my @data;

my %lang = (
	'strat' => "strategies",
	'type' => "types",
	'i' => "int",
	'li' => "long",
	'lli' => "long long",
	'u' => "unsigned int",
	'lu' => "unsigned long",
	'llu' => "unsigned long long",
);


while (defined (my $filename = shift)) {
	#my $filename = $_;
	if ($filename =~ m,benchmarks/\.\.\.(\w+)-([a-zA-Z0-9_-]+)-(\w+)-(\w+)\.data,) {
		#print STDERR "OK: $filename\n";
		my $vc = $1;
		my $tc = $2;
		my $type = $3;
		my $strat = $4;
		my $plain = `cat $filename`;
		my ($val, $min, $max) = split /[ \n\t]+/, $plain;
		push @data, { vc => $vc, tc => $tc, type => $type, strat => $strat, val => $val, min => $min, max => $max};
		#print $out "$i $val \"$vc\" \"$strat\"\n";
	} else {
		print STDERR "bad file name format: $filename\n";
		exit 1;
	}
}

my %seen;
my @vc = sort grep { !$seen{$_}++ } map { $_->{vc} } @data;
%seen = ();
$what =~ s/^--//;
my @strat = sort grep { !$seen{$_}++ } map { $_->{$what} } @data;

my $max = (reverse sort {$a<=>$b} map {$_->{max}} @data)[0];
my $pow = int(log($max)/log(10));
my $scale = "1" . ("0" x $pow);
my $ratio = $max/$scale;
# print STDERR "MAX:   $max\n";
# print STDERR "SCALE: $scale\n";
# print STDERR "RATIO: $ratio\n";
$pow-- if ($ratio < 2);
$scale = "1" . ("0" x $pow);
my $steps = int($max/$scale)+1;
$max = $scale*$steps;
# print STDERR "TOTAL $steps steps of range $scale\n";

$steps /=2 if ($steps>10);

$_->{val} /= ($max/$IMAGEH) for @data;
$_->{min} /= ($max/$IMAGEH) for @data;
$_->{max} /= ($max/$IMAGEH) for @data;

open my $out, ">$outfile" or die "$outfile: $!\n";
#print STDERR "WRITE TO: $outfile\n";

my $any = $data[0];
#for my $d (@data) {
#	print $out qq @
#	\\documentclass[tikz,border=1cm]{standalone}
#	\\usepackage{color}
#	\\usepackage{tikz}
#	\\usetikzlibrary{calc,arrows,decorations}
#	\\begin{document}
#	\\begin{tikzpicture}
#		\\tikzset{axis/.style={ultra thick,black}};
#		\\tikzset{bar/.style={draw=black}};
#		\\tikzset{brace/.style={thick,decorate,decoration={brace,amplitude=5pt}}};
#	@;
	print $out qq @
	\\section{Comparison of different \\textit{ $lang{$what} } in the \\texttt{ $any->{tc} } benchmark of type \\texttt{ $lang{$any->{type}} } }
	\\begin{tikzpicture}[scale=0.5]
		\\tikzset{axis/.style={ultra thick,black}};
		\\tikzset{bar/.style={draw=black}};
		\\tikzset{error/.style={draw=black}};
		\\tikzset{ytic/.style={draw=black}};
		\\tikzset{yline/.style={draw=black!15}};
		\\tikzset{brace/.style={thick,decorate,decoration={brace,amplitude=5pt}}};
	@;
	for my $k (1..$steps) {
		my $y = $k*$IMAGEH/$steps;
		my $realpow = $pow - 4; # N_RUN is 10000
		my $imagew = 5 + scalar @data;
		print $out qq @
		\\draw[ytic] (0.2,$y) -- (-0.2,$y) node[anchor=east] { \\texttt{${k}E${realpow}} };
		\\draw[yline] (0.2,$y) -- ($imagew,$y);
		@
	};
	my $x = 1;
	for my $vc (@vc) {
		my $blockno = 0;
		my $blockstart = $x;
		my $shadow=0;
		for my $strat (@strat) {
			$blockno++;
			my $item = (grep { $_->{vc} eq $vc and $_->{$what} eq $strat } @data)[0];
			#next unless $item;
			print $out qq @
				\\draw[bar,fill=black!$shadow] ($x,0) rectangle ++(1,$item->{val});
				\\draw[error] (\$($x,$item->{min})+(0.1,0)\$) -- ++(0.8,0);
				\\draw[error] (\$($x,$item->{max})+(0.1,0)\$) -- ++(0.8,0);
				\\draw[error] (\$($x,$item->{min})+(0.5,0)\$) -- (\$($x,$item->{max})+(0.5,0)\$);
			@;
			$x++;
			$shadow += 10;
		}
		print $out qq @
			\\draw[thick] ($blockstart,0) -- ($x,0) node[midway,below] { \\textbf{$vc} };
		@;
		$x++;
	}
	my $y = 1 + $IMAGEH + scalar @strat;
	my $shadow=0;
	for my $strat (@strat) {
		print $out qq @
			\\draw[fill=black!$shadow] ($x,$y) rectangle ++(-1,1);
			\\node[anchor=east] at (\$($x,$y)+(-1.5,0.5)\$) { \\textbf{$strat} };
		@;
		$y--;
		$shadow += 10;
	}
#	print $out qq @
#		\\draw[axis] (0,0) -- ($x,0);
#		\\draw[axis,->] (0,0) -- (0,11) node[above] { \\huge \\textbf{time} };
#	\\end{tikzpicture}
#	\\end{document}
#	@;
	print $out qq @
		\\draw[axis,->] ($x,0) -- (0,0) -- (\$(0,1)+(0,$IMAGEH)\$) node[above] { \\textbf{time/cycles} };
	\\end{tikzpicture}
	@;
#}


close $out;

