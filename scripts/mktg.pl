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

use File::Basename;

my @types = (
	{ ctype => "int",                sfx => "i",   signed => 1, category => "native", fmt => '"i"',    size => 1, min => "INT_MIN",   max => "INT_MAX" },
	{ ctype => "unsigned int",       sfx => "u",   signed => 0, category => "native", fmt => '"u"',    size => 1, min => 0,           max => "UINT_MAX" },
	{ ctype => "long",               sfx => "li",  signed => 1, category => "native", fmt => '"li"',   size => 2, min => "LONG_MIN",  max => "LONG_MAX" },
	{ ctype => "unsigned long",      sfx => "lu",  signed => 0, category => "native", fmt => '"lu"',   size => 2, min => 0,           max => "ULONG_MAX" },
	{ ctype => "long long",          sfx => "lli", signed => 1, category => "native", fmt => '"lli"',  size => 3, min => "LLONG_MIN", max => "LLONG_MAX" },
	{ ctype => "unsigned long long", sfx => "llu", signed => 0, category => "native", fmt => '"llu"',  size => 3, min => 0,           max => "ULLONG_MAX" },
	{ ctype => "int8_t",             sfx => "i8",  signed => 1, category => "fixed",  fmt => 'PRId8',  size => 1, min => "INT8_MIN",  max => "INT8_MAX" },
	{ ctype => "uint8_t",            sfx => "u8",  signed => 0, category => "fixed",  fmt => 'PRIu8',  size => 1, min => 0,           max => "UINT8_MAX" },
	{ ctype => "int16_t",            sfx => "i16", signed => 1, category => "fixed",  fmt => 'PRId16', size => 2, min => "INT16_MIN", max => "INT16_MAX" },
	{ ctype => "uint16_t",           sfx => "u16", signed => 0, category => "fixed",  fmt => 'PRIu16', size => 2, min => 0,           max => "UINT16_MAX" },
	{ ctype => "int32_t",            sfx => "i32", signed => 1, category => "fixed",  fmt => 'PRId32', size => 3, min => "INT32_MIN", max => "INT32_MAX" },
	{ ctype => "uint32_t",           sfx => "u32", signed => 0, category => "fixed",  fmt => 'PRIu32', size => 3, min => 0,           max => "UINT32_MAX" },
	{ ctype => "int64_t",            sfx => "i64", signed => 1, category => "fixed",  fmt => 'PRId64', size => 4, min => "INT64_MIN", max => "INT64_MAX" },
	{ ctype => "uint64_t",           sfx => "u64", signed => 0, category => "fixed",  fmt => 'PRIu64', size => 5, min => 0,           max => "UINT64_MAX" },
);

for my $t (@types) {
	$t->{stype} = (grep { $_->{size} == $t->{size} && $_->{signed} } @types)[0] if (!$t->{signed});
	$t->{utype} = (grep { $_->{size} == $t->{size} && !$_->{signed} } @types)[0] if ($t->{signed});
}

my @ops = (
	{ name => "add", operator => "+" },
	{ name => "sub", operator => "-" },
	{ name => "mul", operator => "*" },
);

my $tgfile = $ARGV[0] or die "usage: $0 <file.tg>";
$tgfile =~ s/\.tg//;
my $dirname = dirname($tgfile);
my $basename = basename($tgfile);

for my $t (@types) {
	my $filename = "$dirname/.$basename-$t->{sfx}.c";
	open my $out, ">$filename" or die "failed to open `$filename': $!\n";
	print $out "/*\n * $filename\n *\n * auto-generated type-generic C file\n */\n\n";
	print $out "#include <stdint.h>\n";
	print $out "#include <inttypes.h>\n";
	print $out "#define TYPE $t->{ctype}\n";
	print $out "#define MAX $t->{max}\n";
	print $out "#define MIN $t->{min}\n";
	print $out "#define FMT \"%\" $t->{fmt}\n";
	for my $op (@ops) {
		print $out "#define o_$op->{name}(a, b, r) overflow_$op->{name}_$t->{sfx}(a, b, r)\n";
	}
	if ($t->{signed}) {
		print $out "#define SIGNED 1\n";
		print $out "#define IS_2_COMPLEMENT (-MAX == MIN + 1)\n"
	} else {
		print $out "#define UNSIGNED 1\n";
		print $out "#define IS_2_COMPLEMENT 0\n"
	}
	print $out "#include \"$tgfile.tg\"\n";
	print $out "\n";
	close $out;
}


