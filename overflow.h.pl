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

our $GENERATE_DEFAULT = defined $ENV{NO_DEFAULT_STRATEGY} ? 0 : 1;

my @types = (
	{ ctype => "int",                sfx => "i",   signed => 1, category => "native", size => 1, min => "INT_MIN",   max => "INT_MAX" },
	{ ctype => "unsigned int",       sfx => "u",   signed => 0, category => "native", size => 1, min => 0,           max => "UINT_MAX" },
	{ ctype => "long",               sfx => "li",  signed => 1, category => "native", size => 2, min => "LONG_MIN",  max => "LONG_MAX" },
	{ ctype => "unsigned long",      sfx => "lu",  signed => 0, category => "native", size => 2, min => 0,           max => "ULONG_MAX" },
	{ ctype => "long long",          sfx => "lli", signed => 1, category => "native", size => 3, min => "LLONG_MIN", max => "LLONG_MAX" },
	{ ctype => "unsigned long long", sfx => "llu", signed => 0, category => "native", size => 3, min => 0,           max => "ULLONG_MAX" },
	{ ctype => "int8_t",             sfx => "i8",  signed => 1, category => "fixed",  size => 1, min => "INT8_MIN",  max => "INT8_MAX" },
	{ ctype => "uint8_t",            sfx => "u8",  signed => 0, category => "fixed",  size => 1, min => 0,           max => "UINT8_MAX" },
	{ ctype => "int16_t",            sfx => "i16", signed => 1, category => "fixed",  size => 2, min => "INT16_MIN", max => "INT16_MAX" },
	{ ctype => "uint16_t",           sfx => "u16", signed => 0, category => "fixed",  size => 2, min => 0,           max => "UINT16_MAX" },
	{ ctype => "int32_t",            sfx => "i32", signed => 1, category => "fixed",  size => 3, min => "INT32_MIN", max => "INT32_MAX" },
	{ ctype => "uint32_t",           sfx => "u32", signed => 0, category => "fixed",  size => 3, min => 0,           max => "UINT32_MAX" },
	{ ctype => "int64_t",            sfx => "i64", signed => 1, category => "fixed",  size => 4, min => "INT64_MIN", max => "INT64_MAX" },
	{ ctype => "uint64_t",           sfx => "u64", signed => 0, category => "fixed",  size => 4, min => 0,           max => "UINT64_MAX" },
);

for my $t (@types) {
	$t->{stype} = (grep { $_->{size} == $t->{size} and $_->{category} eq $t->{category} and $_->{signed} } @types)[0] if (!$t->{signed});
	$t->{utype} = (grep { $_->{size} == $t->{size} and $_->{category} eq $t->{category} and !$_->{signed} } @types)[0] if ($t->{signed});
}

my @ops = (
	{ name => "add", operator => "+" },
	{ name => "sub", operator => "-" },
	{ name => "mul", operator => "*", examine => [{ name => "pow2", macro => "is_pow2" }] },
);

my @prefixes = (
	{ name => "",          weights => [30, 3, 3, 10, 1, 1] },
	{ name => "_likely",   weights => [10, 1, 1, 50, 5, 5] },
	{ name => "_unlikely", weights => [50, 5, 5, 10, 1, 1] },
);

my @vc = (
	{ name => "cc", fst => 1, snd => 1 },
	{ name => "cv", fst => 1, snd => 0 },
	{ name => "vc", fst => 0, snd => 1 },
	{ name => "vv", fst => 0, snd => 0 },
);

for my $vc (@vc) {
	$vc->{a} = ($vc->{fst} ? "" : "!") . "a_is_const";
	$vc->{b} = ($vc->{snd} ? "" : "!") . "b_is_const";
}

my @strategies = (
	{ name => "precheck",  impl => [ "sadd", "uadd", "smul", "umul", "ssub", "usub" ] },
	{ name => "largetype", impl => [ "sadd", "uadd", "smul", "umul", "ssub", 0      ] },
	{ name => "postcheck", impl => [ 0,      "uadd", 0,      "umul", 0,      "usub" ] },
	{ name => "partial",   impl => [ 0,      "uadd", 0,      "umul", 0,      0      ] },
);


sub get_larger_types {
	my ($type) = @_;
	return grep { $_->{signed} == $type->{signed} and $_->{category} eq $type->{category} and $_->{size} > $type->{size} } @types;
}


sub print_comment {
	my ($indent, $text) = @_;
	$text =~ s/^[ \t\n]+//;
	$text =~ s/[ \t\n]+$//;
	print "$indent/*\n";
	print "$indent *$_\n" for map { " $_" if $_ } map { s/^[ \t]*//r} map { s/[ \t]*$//r } split /\n/, $text;
	print "$indent */\n";
}

sub print_code {
	my ($indent, $text) = @_;
	$text =~ s/^[ \t\n]+//;
	$text =~ s/[ \t\n]+$//;
	print "$indent$_\n" for map { s/^[ \t]*#?//r} map { s/[ \t]*$//r } split /\n/, $text;
}

sub print_pp {
	my ($indent, $text) = @_;
	$text =~ s/^[ \t\n]+//;
	$text =~ s/[ \t\n]+$//;
	print $_? "#$indent$_\n" : "\n" for map { s/^[ \t]*#?//r} map { s/[ \t]*$//r } split /\n/, $text;
}

sub print_define {
	my ($indent, $name, $text) = @_;
	$text =~ s/^[ \t\n]+//;
	$text =~ s/[ \t\n]+$//;
	print "#" . $indent . "define $name \\\n";
	print $indent . $_ for map { s/^[ \t]*#?//r } map { s/[ \t]*$/ \\\n/r } split /\n/, $text;
	print "\n\n";
}

sub dump_try_builtin {
	my ($indent, $type, $opname) = @_;
	return if $type->{category} ne "native";
	my $asm = ($type->{signed} ? "s" : "u") . $opname . ($type->{sfx} =~ s/[ui]$//r);
	print_pp($indent, qq @
	#ifndef overflow__no_builtins
	#	if defined __clang__
	#		if __has_builtin(__builtin_${asm}_overflow)
	#			define overflow_${opname}_$type->{sfx}(a, b, r) __builtin_${asm}_overflow((a), (b), (r))
	#		endif
	#	elif defined __GNUC__
	#		if __GNUC__ >= 5
	#			define overflow_${opname}_$type->{sfx}(a, b, r) __builtin_${asm}_overflow((a), (b), (r))
	#		endif
	#	endif
	#endif /* overflow__no_builtins */
	@);
	print "\n";
}

sub dump_common_macros {
	my ($indent) = @_;
	print_pp($indent, qq @
	#if defined __clang__
	#	if __has_attribute(__always_inline__) && __has_attribute(__unused__)
	#		define overflow__private static inline __attribute__((__always_inline__,__unused__))
	#	elif __has_attribute(__always_inline__)
	#		define overflow__private static inline __attribute__((__always_inline__))
	#	elif __has_attribute(__unused__)
	#		define overflow__private static inline __attribute__((__unused__))
	#	endif
	#elif defined __GNUC__
	#	if __GNUC__ >= 4 /* TODO */
	#		define overflow__private static inline __attribute__((__always_inline__,__unused__,__artificial__))
	#	elif __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1)
	#		define overflow__private static inline __attribute__((__always_inline__,__unused__))
	#	elif __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 7)
	#		define overflow__private static inline __attribute__((__unused__))
	#	endif
	#endif

	#ifndef overflow__private
	#	define overflow__private static inline
	#endif

	#ifdef __OPTIMIZE__
	#	if defined __clang__
	#		if __has_builtin(__builtin_unreachable)
	#			define overflow__assume(x) do { if (!(x)) __builtin_unreachable(); } while (0)
	#		endif
	#	elif defined __GNUC__
	#		if __GNUC__ > 4 || ( __GNUC__ == 4 && __GNUC_MINOR__ >= 5 )
	#			define overflow__assume(x) do { if (!(x)) __builtin_unreachable(); } while (0)
	#		endif
	#	endif
	#endif

	#ifndef overflow__assume
	#	define overflow__assume(x) ((void)0) /* ignore */
	#endif

	#if defined __clang__
	#	if __has_builtin(__builtin_constant_p)
	#		define overflow__constant(x) __builtin_constant_p(x)
	#	endif
	#elif defined __GNUC__
	#	//
	#	// see also: https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
	#	// this function is completely safe since version 3.0.1
	#	//
	#	if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1)
	#		define overflow__constant(x) __builtin_constant_p(x)
	#	endif
	#endif

	#ifndef overflow__constant
	#	define overflow__constant(x) 0 /* fall-back: this disables some optimizations */
	#endif

	#if defined __clang__
	#	if __has_attribute(__nonnull__)
	#		define overflow__nonnull_arg(idx) __attribute__((__nonnull__(idx)))
	#	endif
	#elif defined __GNUC__
	#	if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3)
	#		define overflow__nonnull_arg(idx) __attribute__((__nonnull__(idx)))
	#	endif
	#endif

	#ifndef overflow__nonnull_arg
	#	define overflow__nonnull_arg(idx) /* ignore */
	#endif

	#if defined __clang__
	#	if __has_attribute(__warn_unused_result__)
	#		define overflow__must_check __attribute__((__warn_unused_result__))
	#	endif
	#elif defined __GNUC__
	#	if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3)
	#		define overflow__must_check __attribute__((__warn_unused_result__))
	#	endif
	#endif

	#ifndef overflow__must_check
	#	define overflow__must_check /* ignore */
	#endif

	#define overflow__is_pow2(x) (!((x) & ((x)-1)))

	#define overflow__is_fast_type(type) (sizeof(type) >= sizeof(int))

	#if defined __clang__
	#	if __has_builtin(__builtin_expect)
	#		define overflow__expect(val, exp) __builtin_expect((val), (exp))
	#	endif
	#elif defined __GNUC__
	#	if __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3)
	#		define overflow__expect(val, exp) __builtin_expect((val), (exp))
	#	endif
	#endif

	#ifndef overflow__expect
	#	define overflow__expect(val, exp) (val)
	#endif

	#define overflow__likely(x)   overflow__expect((x), 1)
	#define overflow__unlikely(x) overflow__expect((x), 0)

	#define overflow__add_suitable_largetype(lmax, max, lmin, min) (lmax-max >= max && lmin-min <= min)
	#define overflow__sub_suitable_largetype(lmax, max, lmin, min) (lmax+min >= max && lmin+max <= min)
	#define overflow__mul_suitable_largetype(lmax, max, lmin, min) (lmax/max >= max && lmin/max <= min && (!min || lmax/min <= min))

	#include <stdint.h>
	#include <limits.h>
	@);
	print "\n";
}

sub dump_custom_add {
	my ($indent, $type) = @_;
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow__add_$type->{sfx}_strategy_precheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	#	(void) b_is_const;
	#	int flag = 0;
	#	if (a_is_const) {
	@);
	if ($type->{signed}) {
		print_code($indent, qq @
		#		if (a >= 0)
		#			flag = $type->{max} - a < b;
		#		else if (a < 0)
		#			flag = $type->{min} - a > b;
		#	} else {
		#		if (b >= 0)
		#			flag = $type->{max} - b < a;
		#		else if (b < 0)
		#			flag = $type->{min} - b > a;
		@);
	} else {
		print_code($indent, qq @
		#		flag = $type->{max} - a < b;
		#	} else {
		#		flag = $type->{max} - b < a;
		@);
	}
	print_code($indent, qq @
	#	}
	#	if (flag) {
	#		return 1;
	#	}
	#	*r = a + b;
	#	return 0;
	#}
	@);
	print "\n";

	for my $largetype (get_larger_types($type)) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__add_$type->{sfx}_strategy_largetype_$largetype->{sfx}(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) b_is_const;
		#	$type->{ctype} r1;
		#	$largetype->{ctype} a2 = ($largetype->{ctype}) a;
		#	$largetype->{ctype} b2 = ($largetype->{ctype}) b;
		#	a2 += b2;
		@);
		if ($type->{signed}) {
			print_code($indent, qq @
			#	if (a2 > $type->{max} || a2 < $type->{min})
			@);
		} else {
			print_code($indent, qq @
			#	if (a2 & ~(($largetype->{ctype}) $type->{max})) /* a2 > $type->{max} */
			@);
		}
		print_code($indent, qq @
		#		return 1;
		#	r1 = ($type->{ctype}) a2;
		#	overflow__assume(r1 == a + b);
		#	*r = r1;
		#	return 0;
		#}
		@);
		print "\n";
	}

	if (!$type->{signed}) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__add_$type->{sfx}_strategy_postcheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) a_is_const;
		#	(void) b_is_const;
		#	$type->{ctype} r1 = a + b;
		#	if (r1 < a)
		#		return 1;
		#	*r = r1;
		#	return 0;
		#}
		@);
		print "\n";

		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__add_$type->{sfx}_strategy_partial(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) a_is_const;
		#	(void) b_is_const;
		#	$type->{ctype} lmask = $type->{max} / 2;
		#	$type->{ctype} hmask = ~lmask;
		#	$type->{ctype} ah = a & hmask;
		#	$type->{ctype} bh = b & hmask;
		#	if (ah & bh)
		#		return 1;
		#	$type->{ctype} al = a & lmask;
		#	$type->{ctype} bl = b & lmask;
		#	$type->{ctype} c = al + bl;
		#	$type->{ctype} ch = c & hmask;
		#	$type->{ctype} oh = ah | bh;
		#	if (oh & ch)
		#		return 1;
		#	c |= oh;
		#	overflow__assume(c == a + b);
		#	*r = c;
		#	return 0;
		#}
		@);
		print "\n";
	}


	for my $prefix (@prefixes) {
		my $op = (grep { $_->{name} eq "add" } @ops)[0];
		generate_largetype($indent, $prefix, $type, $op);
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}

	print_pp($indent, qq @
	#define overflow_add_$type->{sfx}(a, b, r)          overflow__add_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_likely_add_$type->{sfx}(a, b, r)   overflow__likely_add_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_unlikely_add_$type->{sfx}(a, b, r) overflow__unlikely_add_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	@);

	print "\n";
}

sub dump_custom_sub {
	my ($indent, $type) = @_;
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow__sub_$type->{sfx}_strategy_precheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	#	(void) b_is_const;
	#	int flag = 0;
	@);
	if ($type->{signed}) {
		print_code($indent, qq @
		#	if (a_is_const) {
		#		if (a >= 0)
		#			flag = b < a - $type->{max};
		#		else
		#			flag = b > a - $type->{min};
		#	} else {
		#		if (b >= 0)
		#			flag = a < $type->{min} + b;
		#		else
		#			flag = a > $type->{max} + b;
		#	}
		@);
	} else {
		print_code($indent, qq @
		#	(void) a_is_const;
		#	flag = a < b;
		@);
	}
	print_code($indent, qq @
	#	if (flag) {
	#		return 1;
	#	}
	#	*r = a - b;
	#	return 0;
	#}
	@);
	print "\n";

	if (!$type->{signed}) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__sub_$type->{sfx}_strategy_postcheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) a_is_const;
		#	(void) b_is_const;
		#	$type->{ctype} r1 = a - b;
		#	if (r1 > a)
		#		return 1;
		#	*r = r1;
		#	return 0;
		#}
		@);
	}

	if ($type->{signed}) {
		for my $largetype (get_larger_types($type)) {
			print_code($indent, qq @
			#overflow__private overflow__nonnull_arg(3) overflow__must_check
			#int overflow__sub_$type->{sfx}_strategy_largetype_$largetype->{sfx}(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
			#{
			#	(void) a_is_const;
			#	(void) b_is_const;
			#	$largetype->{ctype} a2 = a;
			#	$largetype->{ctype} b2 = b;
			#	a2 -= b2;
			#	if (a2 < $type->{min} || a2 > $type->{max})
			#		return 1;
			#	overflow__assume(a2 == a - b);
			#	*r = ($type->{ctype}) a2;
			#	return 0;
			#}
			@);
			print "\n";
		}
	} else {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__sub_$type->{sfx}_strategy_largetype(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	return overflow__sub_$type->{sfx}_strategy_precheck(a, b, r, a_is_const, b_is_const);
		#}
		@);
		print "\n";
	}

	for my $prefix (@prefixes) {
		my $op = (grep { $_->{name} eq "sub" } @ops)[0];
		generate_largetype($indent, $prefix, $type, $op) if $type->{signed};
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}
	print "\n";

	print_pp($indent, qq @
	#define overflow_sub_$type->{sfx}(a, b, r)          overflow__sub_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_likely_sub_$type->{sfx}(a, b, r)   overflow__likely_sub_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_unlikely_sub_$type->{sfx}(a, b, r) overflow__unlikely_sub_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	@);
	print "\n";
}

sub dump_custom_mul {
	my ($indent, $type) = @_;
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow__mul_$type->{sfx}_strategy_precheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	#	(void) b_is_const;
	#	int flag = 0;
	@);
	if ($type->{signed}) {
		print_code($indent, qq @
		#	if (a_is_const) {
		#		if (a > 0) {
		#			if (b > 0)
		#				flag = b > $type->{max} / a;
		#			else
		#				flag = b < $type->{min} / a;
		#		} else {
		#			if (b > 0)
		#				flag = a < $type->{min} / b;
		#			else
		#				flag = a && b < $type->{max} / a;
		#		}
		#	} else {
		#		if (a > 0) {
		#			if (b > 0)
		#				flag = a > $type->{max} / b;
		#			else
		#				flag = b < $type->{min} / a;
		#		} else {
		#			if (b > 0)
		#				flag = a < $type->{min} / b;
		#			else
		#				flag = b && a < $type->{max} / b;
		#		}
		#	}
		@);
	} else {
		print_code($indent, qq @
		#	if (a_is_const) {
		#		flag = a && b > $type->{max} / a;
		#	} else {
		#		flag = b && a > $type->{max} / b;
		#	}
		@);
	}
	print_code($indent, qq @
	#	if (flag) {
	#		/* TODO: add assumptions */
	#		return 1;
	#	}
	#	*r = a * b;
	#	return 0;
	#}
	@);
	print "\n";

	for my $largetype (get_larger_types($type)) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__mul_$type->{sfx}_strategy_largetype_$largetype->{sfx}(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) a_is_const;
		#	(void) b_is_const;
		#	$largetype->{ctype} a2 = ($largetype->{ctype}) a;
		#	$largetype->{ctype} b2 = ($largetype->{ctype}) b;
		#	$largetype->{ctype} r2 = a2 * b2;
		@);
		if ($type->{signed}) {
			print_code($indent, qq @
			#	if (r2 > $type->{max} || r2 < $type->{min})
			@);
		} else {
			print_code($indent, qq @
			#	if (r2 & ~(($largetype->{ctype}) $type->{max})) /* r2 > $type->{max} */
			@);
		}
		print_code($indent, qq @
		#		return 1;
		#	*r = ($type->{ctype}) r2;
		#	return 0;
		#}
		@);
		print "\n";
	}

	if (!$type->{signed}) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__mul_$type->{sfx}_strategy_partial(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	(void) a_is_const;
		#	(void) b_is_const;
		#	unsigned int shift = (sizeof($type->{ctype}) * CHAR_BIT) / 2;
		#	$type->{ctype} lower_mask = ((($type->{ctype})1)<<shift)-1;
		#	$type->{ctype} a_lo = a & lower_mask;
		#	$type->{ctype} b_lo = b & lower_mask;
		#	$type->{ctype} a_hi = (a >> shift) & lower_mask;
		#	$type->{ctype} b_hi = (b >> shift) & lower_mask;
		#	if(a_hi && b_hi)
		#		return 1;
		#	$type->{ctype} r1 = a_lo * b_lo;
		#	$type->{ctype} r2 = a_lo * b_hi;
		#	$type->{ctype} r3 = a_hi * b_lo;
		#	r2 += r3;
		#	if (r2 & ~lower_mask) {
		#		overflow__assume(a != 0 && b > $type->{max} / a);
		#		overflow__assume(b != 0 && a > $type->{max} / b);
		#		return 1;
		#	}
		#	r2 <<= shift;
		#	if (r2 > $type->{max} - r1) {
		#		overflow__assume(a != 0 && b > $type->{max} / a);
		#		overflow__assume(b != 0 && a > $type->{max} / b);
		#		return 1;
		#	}
		#	r1 += r2;
		#	overflow__assume(r1 == a * b);
		#	*r = r1;
		#	return 0;
		#}
		@);
		print "\n";

		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow__mul_$type->{sfx}_strategy_postcheck(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	if ((a_is_const && !a) || (b_is_const && !b)) {
		#		*r = 0;
		#		return 0;
		#	}
		#	$type->{ctype} r1 = a * b;
		#	if (a_is_const) {
		#		if (a && r1 / a != b)
		#			return 1;
		#	} else {
		#		if (b && r1 / b != a)
		#			return 1;
		#	}
		#	*r = r1;
		#	return 0;
		#}
		@);
		print "\n";
	}

	for my $prefix (@prefixes) {
		my $op = (grep { $_->{name} eq "mul" } @ops)[0];
		generate_largetype($indent, $prefix, $type, $op);
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}
	print "\n";

	print_pp($indent, qq @
	#define overflow_mul_$type->{sfx}(a, b, r)          overflow__mul_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_likely_mul_$type->{sfx}(a, b, r)   overflow__likely_mul_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	#define overflow_unlikely_mul_$type->{sfx}(a, b, r) overflow__unlikely_mul_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
	@);
	print "\n";
}

sub dump_add_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "add");
	print_pp($indent, qq @
	#ifdef overflow_add_$type->{sfx}
	#	define overflow_likely_add_$type->{sfx}(a, b, r)   overflow__expect(overflow_add_$type->{sfx}((a), (b), (r)), 1)
	#	define overflow_unlikely_add_$type->{sfx}(a, b, r) overflow__expect(overflow_add_$type->{sfx}((a), (b), (r)), 0)
	#else
	@);
	dump_custom_add($indent . "\t", $type);
	print_pp($indent, qq @
	#endif /* overflow_add_$type->{sfx} */
	@);
	print "\n";
}

sub dump_sub_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "sub");
	print_pp($indent, qq @
	#ifdef overflow_sub_$type->{sfx}
	#	define overflow_likely_sub_$type->{sfx}(a, b, r)   overflow__expect(overflow_sub_$type->{sfx}((a), (b), (r)), 1)
	#	define overflow_unlikely_sub_$type->{sfx}(a, b, r) overflow__expect(overflow_sub_$type->{sfx}((a), (b), (r)), 0)
	#else
	@);
	dump_custom_sub($indent . "\t", $type);
	print_pp($indent, qq @
	#endif /* overflow_sub_$type->{sfx} */
	@);
	print "\n";
}

sub dump_mul_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "mul");
	print_pp($indent, qq @
	#ifdef overflow_mul_$type->{sfx}
	#	define overflow_likely_mul_$type->{sfx}(a, b, r)   overflow__expect(overflow_mul_$type->{sfx}((a), (b), (r)), 1)
	#	define overflow_unlikely_mul_$type->{sfx}(a, b, r) overflow__expect(overflow_mul_$type->{sfx}((a), (b), (r)), 0)
	#else
	@);
	dump_custom_mul($indent . "\t", $type);
	print_pp($indent, qq @
	#endif /* overflow_mul_$type->{sfx} */
	@);
	print "\n";
}

sub dump_add {
	my ($indent) = @_;
	dump_add_for_type($indent, $_) for (@types)
}

sub dump_sub {
	my ($indent) = @_;
	dump_sub_for_type($indent, $_) for (@types);
}

sub dump_mul {
	my ($indent) = @_;
	dump_mul_for_type($indent, $_) for (@types);
}

sub dump_generic {
	my ($indent, $op) = @_;
	print_pp($indent, qq @
	#ifndef overflow_$op->{name}
	#	if defined __clang__
	#		if !defined overflow__no_builtins && __has_builtin(__builtin_$op->{name}_overflow)
	#			define overflow_$op->{name}(a, b, r)          __builtin_$op->{name}_overflow((a), (b), (r))
	#			define overflow_likely_$op->{name}(a, b, r)   overflow__expect(__builtin_$op->{name}_overflow((a), (b), (r)), 1)
	#			define overflow_unlikely_$op->{name}(a, b, r) overflow__expect(__builtin_$op->{name}_overflow((a), (b), (r)), 0)
	#		elif __has_builtin(__builtin_choose_expr) && __has_builtin(__builtin_types_compatible_p)
	@);
	for my $prefix (@prefixes) {
		print_define($indent . "\t\t\t", "overflow$prefix->{name}_$op->{name}(a, b, r)",
			(join "", map { qq @
			#	__builtin_choose_expr(__builtin_types_compatible_p(__typeof__(*(r)), $_->{ctype}),
			#		overflow$prefix->{name}_$op->{name}_$_->{sfx}((a), (b), ($_->{ctype} *)(r)),
			@ } @types)
			. "#\t((void)0)\n"
			. (")" x scalar @types)
		);
	}

	print_pp($indent, qq @
	#		endif
	#	elif defined __GNUC__
	#		if !defined overflow__no_builtins && __GNUC__ >= 5
	#			define overflow_$op->{name}(a, b, r)          __builtin_$op->{name}_overflow((a), (b), (r))
	#			define overflow_likely_$op->{name}(a, b, r)   overflow__expect(__builtin_$op->{name}_overflow((a), (b), (r)), 1)
	#			define overflow_unlikely_$op->{name}(a, b, r) overflow__expect(__builtin_$op->{name}_overflow((a), (b), (r)), 0)
	#		elif __GNUC__ >= 4 /* TODO  */
	@);
	for my $prefix (@prefixes) {
		print_define($indent . "\t\t\t", "overflow$prefix->{name}_$op->{name}(a, b, r)",
			(join "", map { qq @
			#	__builtin_choose_expr(__builtin_types_compatible_p(__typeof__(*(r)), $_->{ctype}),
			#		overflow$prefix->{name}_$op->{name}_$_->{sfx}((a), (b), ($_->{ctype} *)(r)),
			@ } @types)
			. "#\t((void)0)\n"
			. (")" x scalar @types)
		);
	}
	print_pp($indent, qq @
	#		endif
	#	endif
	#endif
	@);
	print "\n";
}

sub read_eval_data {
	my ($filename) = @_;
	open my $in, "<$filename" or die "failed to open $filename: $!\n";
	my $line = <$in>;
	defined $line or die "failed to read $filename: $!\n";
	my ($avg, $min, $max) = split /[ ]+/, $line;
	close $in;
	return ($avg, $min, $max);
}

sub strategy_implemented {
	my ($type, $op, $strat) = @_;
	my $name = ($type->{signed} ? "s" : "u") . $op->{name};
	return grep { $name eq $_  } @{ $strat->{impl} };
}

sub find_best_strategy {
	my ($prefix, $type, $op, $vc, $examine) = @_;
	my @w = @{ $prefix->{weights} };
	my %data = ();
	my $examinename = defined $examine->{name} ? "-$examine->{name}" : "";
	for my $strat (@strategies) {
		my $s = $strat->{name};
		next if !strategy_implemented($type, $op, $strat);
		my $filename = "benchmarks/...$vc->{name}-$op->{name}${examinename}-$type->{sfx}-$s.data";
		my $ofilename = "benchmarks/...$vc->{name}-$op->{name}-overflow-$type->{sfx}-$s.data";
		my ($avg, $min, $max) = read_eval_data($filename);
		my ($oavg, $omin, $omax) = read_eval_data($ofilename);
		$data{$s} = $avg * $w[0] + $min * $w[1] + $max * $w[2] + $oavg * $w[3] + $omin * $w[4] + $omax * $w[5];
	}
	my $best = (sort { $data{$a} <=> $data{$b} } keys %data)[0];
	return $best;
}

sub generate_default_strategy {
	my ($indent, $prefix, $type, $op) = @_;
	if (!$GENERATE_DEFAULT) {
		print_code($indent, qq @
		#overflow__private overflow__nonnull_arg(3) overflow__must_check
		#int overflow_$prefix->{name}_$op->{name}_$type->{sfx}_strategy_default(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	return overflow__$op->{name}_$type->{sfx}_strategy_precheck(a, b, r, a_is_const, b_is_const);
		#}
		@);
		print "\n";
		return;
	}
	my $expect = $prefix->{name} ? "overflow_$prefix->{name}" : "";
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow_$prefix->{name}_$op->{name}_$type->{sfx}_strategy_default(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	@);
	for my $vc (@vc) {
		for my $examine (@{ $op->{examine} // [] }, ({})) {
				next if defined $examine->{macro} and !$vc->{fst} and !$vc->{snd};
				my $strat = find_best_strategy($prefix, $type, $op, $vc, $examine);
				my $expr = "$vc->{a} && $vc->{b}";
				if (defined $examine->{macro}) {
					$expr .= " && (" . (join " || ", (($vc->{fst} ? "overflow__$examine->{macro}(a)" : ()), ($vc->{snd} ? "overflow__$examine->{macro}(b)" : ()))) . ")";
				}
				print_code($indent, qq @
				#	if ($expr)
				#		return $expect(overflow__$op->{name}_$type->{sfx}_strategy_$strat(a, b, r, a_is_const, b_is_const));
				@);
		}
	}
	print_code($indent, qq @
	#	/* dead code */
	#	overflow__assume(0);
	#	return 1;
	#}
	@);
	print "\n";
}

sub generate_largetype {
	my ($indent, $prefix, $type, $op) = @_;
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow_$prefix->{name}_$op->{name}_$type->{sfx}_strategy_largetype(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	@);
	if (!strategy_implemented($type, $op, (grep { $_->{name} eq "largetype" } @strategies)[0])) {
		print_code($indent, qq @
		#	/* largetype strategy not implemented */
		#	return overflow__$op->{name}_$type->{sfx}_strategy_precheck(a, b, r, a_is_const, b_is_const);
		#}
		@);
		print "\n";
		return;
	}
	for my $largetype (get_larger_types($type)) {
		print_code($indent, qq @
		#	if (overflow__$op->{name}_suitable_largetype($largetype->{max}, $type->{max}, $largetype->{min}, $type->{min}) && overflow__is_fast_type($largetype->{ctype}))
		#		return overflow__$op->{name}_$type->{sfx}_strategy_largetype_$largetype->{sfx}(a, b, r, a_is_const, b_is_const);
		@);
	}
	print_code($indent, qq @
	#	/* precheck is always possible, use that as fallback */
	#	return overflow__$op->{name}_$type->{sfx}_strategy_precheck(a, b, r, a_is_const, b_is_const);
	#}
	@);
	print "\n";
}

sub generate_internal {
	my ($indent, $prefix, $type, $op) = @_;
	print_code($indent, qq @
	#overflow__private overflow__nonnull_arg(3) overflow__must_check
	#int overflow_$prefix->{name}_$op->{name}_$type->{sfx}_internal(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
	#{
	@);
	print_pp($indent, qq @
	#	if 0 /* syntax hack */
	@);
	for my $strat (@strategies) {
		next if !strategy_implemented($type, $op, $strat);
		my $s = $strat->{name};
		print_pp($indent, qq @
		#	elif defined overflow__strategy_$s
		@);
			print_code($indent, qq @
			#		return overflow__$op->{name}_$type->{sfx}_strategy_$s(a, b, r, a_is_const, b_is_const);
			@);
	}
	print_pp($indent, qq @
	#	else
	@);
	print_code($indent, qq @
	#		return overflow_$prefix->{name}_$op->{name}_$type->{sfx}_strategy_default(a, b, r, a_is_const, b_is_const);
	@);
	print_pp($indent, qq @
	#	endif
	@);
	print_code($indent, qq @
	#}
	@);
	print "\n";
}

sub dump_file_header {
	print_comment("", qq @
		overflow.h

		This file contains the Deichbruch integer overflow detection macros and
		functions. It provides fast, reliable, and portable functions/macros
		that perform arithmetic integer operations with overflow detection.

		For performance improvement, Deichbruch implements multiple strategies
		for each operation. Then, the compiler statically chooses an
		implementation that is likely to be fast. These compiler heurisics are
		based on experimental benchmarking results.

		This file has been generated by the Deichbruch build system. Deichbruch
		is free software.
	@);
	print "\n";

}

sub dump_file_body {
	print "#ifndef __OVERFLOW_H_INCLUDED__\n";
	print "#define __OVERFLOW_H_INCLUDED__ 1\n\n";

	my $indent = "";
	dump_common_macros($indent);
	dump_add($indent);
	dump_sub($indent);
	dump_mul($indent);
	dump_generic($indent, $_) for @ops;

	print "\n";
	print "#ifndef OVERFLOW_LAZY_GENERIC\n\n";
	for my $prefix (@prefixes) {
		for my $o (@ops) {
			print "#\tifndef overflow$prefix->{name}_$o->{name}\n";
			print "#\t\terror \"No compiler support for overflow$prefix->{name}_$o->{name} macro\"\n";
			print "#\tendif\n\n"
		}
	}
	print "#endif\n\n";

	print "#endif /* __OVERFLOW_H_INCLUDED__ */\n";
}

### MAIN ###

dump_file_header("");
dump_file_body("");


