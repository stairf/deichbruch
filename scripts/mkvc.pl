#!/usr/bin/env perl

use warnings;
use strict;

use File::Basename;


my $vcfile = $ARGV[0] or die "usage: $0 <file.vc>";
$vcfile =~ s/\.vc$// or die "usage: $0 <file.vc>";
my $dirname = dirname($vcfile);
my $basename = basename($vcfile);

for my $vc ("cc", "cv", "vc", "vv") {
	my $filename = "$dirname/.$vc-$basename";
	open my $out, ">$filename" or die "failed to open `$filename': $!\n";
	print $out "/*\n * $filename\n * auto-generated VC expansion file\n */\n\n";
	for my $i (0..1) {
		print $out "#define P$i(x) " . ({'v'=>'just'}->{(split //, $vc)[$i]} // '') . "(x)\n";
	}
	print $out "#include \"$vcfile.vc\"\n";
	close $out;
}

