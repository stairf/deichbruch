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
	print "$_\n" for map { $_ =~ m,^\s*//, ? "$indent$_" : $_ ? "#$indent$_" : "" } map { s/^[ \t]*#?//r} map { s/[ \t]*$//r } split /\n/, $text;
}

sub print_define {
	my ($indent, $name, $text) = @_;
	$text =~ s/^[ \t\n]+//;
	$text =~ s/[ \t\n]+$//;
	print "#" . $indent . "define $name \\\n";
	print $indent . "\t" . $_ for map { s/^[ \t]*#?//r } map { s/[ \t]*$/ \\\n/r } split /\n/, $text;
	print "\n\n";
}

sub dump_try_builtin {
	my ($indent, $type, $opname) = @_;
	if ($type->{category} ne "native") {
		print_pp($indent, qq @
		#if 1
		#	// no compiler built-in available for overflow_${opname}_$type->{sfx}
		@);
		return;
	}
	my $asm = ($type->{signed} ? "s" : "u") . $opname . ($type->{sfx} =~ s/[ui]$//r);
	print_pp($indent, qq @
	#if !defined overflow__no_builtins && defined overflow__have_builtin_${asm}_overflow
	#	define overflow_${opname}_$type->{sfx}(a, b, r) __builtin_${asm}_overflow((a), (b), (r))
	@);
	dump_prefixed_builtins($indent, $type, $opname);
	print_pp($indent, qq @
	#else
	@);
	print "\n";
}

sub dump_common_macros {
	my ($indent) = @_;
	print_pp($indent, qq @
	#if defined __clang__
	#	if __clang_major__ < 3 || (__clang_major__ == 3 && __clang_minor__ < 3)
	#
	#	// Old clang versions have a bug where __has_feature and similar CPP
	#	// functions cause syntax errors. In consequence, using these macros
	#	// makes no sense, because feature detection must not lead to
	#	// compilation errors.
	#	//
	#	// The most reliable solution is to manually disable all compiler features
	#	// to ensure the code compiles. In consequence, the code will probably be
	#	// a lot slower. If this matters to you, simply upgrade to clang version
	#	// 3.3 or newer.
	#	//
	#	// According to the clang documentation, the version number should not be
	#	// used for feature checking. However, this appears to be the most
	#	// reliable way.
	#	//
	#	// This problem appears to be fixed in the commit
	#	// 3f03b586351779be6947466f530f22c491b1b70f
	#	//
	#	// At that commit, docs/ReleaseNotes.html contains version number 3.2.
	#	// Therefore, version 3.3 should be safe.
	#
	#	else
	#
	#		define overflow__have_typeof 1
	#
	#		if __has_builtin(__builtin_unreachable)
	#			define overflow__have_builtin_unreachable 1
	#		endif
	#
	#		if __has_builtin(__builtin_constant_p)
	#			define overflow__have_builtin_constant_p 1
	#		endif
	#
	#		if __has_builtin(__builtin_expect)
	#			define overflow__have_builtin_expect 1
	#		endif
	#
	#		if __has_builtin(__builtin_choose_expr)
	#			define overflow__have_builtin_choose_expr 1
	#		endif
	#
	#		if __has_builtin(__builtin_types_compatible_p)
	#			define overflow__have_builtin_types_compatible_p 1
	#		endif
	#
	#		if __has_builtin(__builtin_assume)
	#			define overflow__have_builtin_assume 1
	#		endif
	#
	#		if __has_attribute(__always_inline__) || __has_attribute(always_inline)
	#			define overflow__have_attribute_always_inline 1
	#		endif
	#
	#		if __has_attribute(__unused__) || __has_attribute(unused)
	#			define overflow__have_attribute_unused 1
	#		endif
	#
	#		if __has_attribute(__artificial__) || __has_attribute(artificial)
	#			define overflow__have_attribute_artificial 1
	#		endif
	#
	#		if __has_attribute(__nonnull__) || __has_attribute(nonnull)
	#			define overflow__have_attribute_nonnull 1
	#		endif
	#
	#		if __has_builtin(__builtin_add_overflow)
	#			define overflow__have_builtin_add_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_sadd_overflow)
	#			define overflow__have_builtin_sadd_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_saddl_overflow)
	#			define overflow__have_builtin_saddl_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_saddll_overflow)
	#			define overflow__have_builtin_saddll_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_uadd_overflow)
	#			define overflow__have_builtin_uadd_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_uaddl_overflow)
	#			define overflow__have_builtin_uaddl_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_uaddll_overflow)
	#			define overflow__have_builtin_uaddll_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_sub_overflow)
	#			define overflow__have_builtin_sub_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_ssub_overflow)
	#			define overflow__have_builtin_ssub_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_ssubl_overflow)
	#			define overflow__have_builtin_ssubl_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_ssubll_overflow)
	#			define overflow__have_builtin_ssubll_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_usub_overflow)
	#			define overflow__have_builtin_usub_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_usubl_overflow)
	#			define overflow__have_builtin_usubl_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_usubll_overflow)
	#			define overflow__have_builtin_usubll_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_mul_overflow)
	#			define overflow__have_builtin_mul_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_smul_overflow)
	#			define overflow__have_builtin_smul_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_smull_overflow)
	#			define overflow__have_builtin_smull_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_smulll_overflow)
	#			define overflow__have_builtin_smulll_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_umul_overflow)
	#			define overflow__have_builtin_umul_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_umull_overflow)
	#			define overflow__have_builtin_umull_overflow 1
	#		endif
	#
	#		if __has_builtin(__builtin_umulll_overflow)
	#			define overflow__have_builtin_umulll_overflow 1
	#		endif
	#
	#	endif
	#
	#elif defined __GNUC__
	#
	#	define overflow__have_typeof 1
	#
	#	if __GNUC__ > 5 || (__GNUC__ == 5 && __GNUC_MINOR__ >= 1)
	#		define overflow__have_builtin_add_overflow 1
	#		define overflow__have_builtin_sadd_overflow 1
	#		define overflow__have_builtin_saddl_overflow 1
	#		define overflow__have_builtin_saddll_overflow 1
	#		define overflow__have_builtin_uadd_overflow 1
	#		define overflow__have_builtin_uaddl_overflow 1
	#		define overflow__have_builtin_uaddll_overflow 1
	#		define overflow__have_builtin_sub_overflow 1
	#		define overflow__have_builtin_ssub_overflow 1
	#		define overflow__have_builtin_ssubl_overflow 1
	#		define overflow__have_builtin_ssubll_overflow 1
	#		define overflow__have_builtin_usub_overflow 1
	#		define overflow__have_builtin_usubl_overflow 1
	#		define overflow__have_builtin_usubll_overflow 1
	#		define overflow__have_builtin_mul_overflow 1
	#		define overflow__have_builtin_smul_overflow 1
	#		define overflow__have_builtin_smull_overflow 1
	#		define overflow__have_builtin_smulll_overflow 1
	#		define overflow__have_builtin_umul_overflow 1
	#		define overflow__have_builtin_umull_overflow 1
	#		define overflow__have_builtin_umulll_overflow 1
	#	endif
	#
	#	if __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 5)
	#		define overflow__have_builtin_unreachable 1
	#	endif
	#
	#	if __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3)
	#		define overflow__have_builtin_expect 1
	#		define overflow__have_attribute_artificial 1
	#	endif
	#
	#	if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3)
	#		define overflow__have_attribute_nonnull 1
	#		define overflow__have_attribute_warn_unused_result 1
	#	endif
	#
	#	if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1)
	#		define overflow__have_attribute_always_inline 1
	#		define overflow__have_builtin_types_compatible_p 1
	#		define overflow__have_builtin_choose_expr 1
	#		//
	#		// see also: https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
	#		// this function is completely safe since version 3.0.1
	#		//
	#		define overflow__have_builtin_constant_p 1
	#	endif
	#
	#	if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 7)
	#		define overflow__have_attribute_unused 1
	#	endif
	#
	#endif

	#ifdef overflow__have_attribute_always_inline
	#	define overflow__attribute_always_inline __attribute__((__always_inline__))
	#else
	#	define overflow__attribute_always_inline /* empty */
	#endif

	#ifdef overflow__have_attribute_unused
	#	define overflow__attribute_unused __attribute__((__unused__))
	#else
	#	define overflow__attribute_unused /* empty */
	#endif

	#ifdef overflow__have_attribute_artificial
	#	define overflow__attribute_artificial __attribute__((__artificial__))
	#else
	#	define overflow__attribute_artificial /* empty */
	#endif

	#define overflow__function static inline overflow__attribute_always_inline overflow__attribute_unused overflow__attribute_artificial

	#if defined overflow__have_builtin_assume
	#	define overflow__assume(x) __builtin_assume(x)
	#elif defined overflow__have_builtin_unreachable && defined __OPTIMIZE__
	#	define overflow__assume(x) do { if (!(x)) __builtin_unreachable(); } while (0)
	#else
	#	define overflow__assume(x) ((void)0) /* ignore */
	#endif

	#ifdef overflow__have_builtin_constant_p
	#	define overflow__constant(x) __builtin_constant_p(x)
	#else
	#	// fall-back: nothing can be proven to be constant
	#	define overflow__constant(x) 0
	#endif

	#ifdef overflow__have_attribute_nonnull
	#	define overflow__nonnull_arg(idx) __attribute__((__nonnull__(idx)))
	#else
	#	define overflow__nonnull_arg(idx) /* ignore */
	#endif

	#ifdef overflow__have_attribute_warn_unused_result
	#	define overflow__must_check __attribute__((__warn_unused_result__))
	#else
	#	define overflow__must_check /* ignore */
	#endif

	#ifdef overflow__have_builtin_expect
	#	define overflow__expect(val, exp) __builtin_expect((val), (exp))
	#else
	#	define overflow__expect(val, exp) (val)
	#endif

	#define overflow__likely(x)   overflow__expect((x), 1)
	#define overflow__unlikely(x) overflow__expect((x), 0)

	#define overflow__is_pow2(x) (!((x) & ((x)-1)))

	#define overflow__is_fast_type(type) (sizeof(type) >= sizeof(int))

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
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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


	my $op = (grep { $_->{name} eq "add" } @ops)[0];
	generate_largetype($indent, $type, $op);
	for my $prefix (@prefixes) {
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}

	for my $p (@prefixes) {
		print_pp($indent, qq @
		#define overflow$p->{name}_add_$type->{sfx}(a, b, r) overflow_$p->{name}_add_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
		@);
	}

	print "\n";
}

sub dump_custom_sub {
	my ($indent, $type) = @_;
	print_code($indent, qq @
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
			#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
		#int overflow__sub_$type->{sfx}_strategy_largetype(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
		#{
		#	return overflow__sub_$type->{sfx}_strategy_precheck(a, b, r, a_is_const, b_is_const);
		#}
		@);
		print "\n";
	}

	my $op = (grep { $_->{name} eq "sub" } @ops)[0];
	generate_largetype($indent, $type, $op) if $type->{signed};
	for my $prefix (@prefixes) {
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}
	print "\n";

	for my $p (@prefixes) {
		print_pp($indent, qq @
		#define overflow$p->{name}_sub_$type->{sfx}(a, b, r) overflow_$p->{name}_sub_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
		@);
	}
	print "\n";
}

sub dump_custom_mul {
	my ($indent, $type) = @_;
	print_code($indent, qq @
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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

	my $op = (grep { $_->{name} eq "mul" } @ops)[0];
	generate_largetype($indent, $type, $op);
	for my $prefix (@prefixes) {
		generate_default_strategy($indent, $prefix, $type, $op);
		generate_internal($indent, $prefix, $type, $op);
	}
	print "\n";

	for my $p (@prefixes) {
		print_pp($indent, qq @
		#define overflow$p->{name}_mul_$type->{sfx}(a, b, r) overflow_$p->{name}_mul_$type->{sfx}_internal((a), (b), (r), overflow__constant(a), overflow__constant(b))
		@);
	}
	print "\n";
}

sub dump_prefixed_builtins {
	my ($indent, $type, $op) = @_;
	for my $p (grep { $_->{name} } @prefixes) {
		print_pp($indent, qq @
		#	define overflow$p->{name}_${op}_$type->{sfx}(a, b, r) overflow_$p->{name}(overflow_${op}_$type->{sfx}((a), (b), (r)))

		@);
	}
}

sub dump_add_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "add");
	dump_custom_add($indent . "\t", $type);
	print_pp($indent, qq @
	#endif /* overflow_add_$type->{sfx} */
	@);
	print "\n";
}

sub dump_sub_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "sub");
	dump_custom_sub($indent . "\t", $type);
	print_pp($indent, qq @
	#endif /* overflow_sub_$type->{sfx} */
	@);
	print "\n";
}

sub dump_mul_for_type {
	my ($indent, $type) = @_;
	dump_try_builtin($indent, $type, "mul");
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
	#if !defined overflow__no_builtins && defined overflow__have_builtin_$op->{name}_overflow
	@);
	for my $prefix (@prefixes) {
		my $expect = $prefix->{name} ? "overflow_$prefix->{name}" : "";
		print_define($indent . "\t", "overflow$prefix->{name}_$op->{name}(a, b, r)", "$expect(__builtin_$op->{name}_overflow(a, b, r))");
	}
	print_pp($indent, qq @
	#elif defined overflow__have_builtin_choose_expr && defined overflow__have_builtin_types_compatible_p && defined overflow__have_typeof
	@);
	for my $prefix (@prefixes) {
		print_define($indent . "\t\t\t", "overflow$prefix->{name}_$op->{name}(a, b, r)",
			(join "", map { qq @
			#__builtin_choose_expr(__builtin_types_compatible_p(__typeof__(*(r)), $_->{ctype}),
			#	overflow$prefix->{name}_$op->{name}_$_->{sfx}((a), (b), ($_->{ctype} *)(r)),
			@ } @types)
			. "#\t((void)0)\n"
			. (")" x scalar @types)
		);
	}
	print_pp($indent, qq @
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
		#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
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
	my ($indent, $type, $op) = @_;
	print_code($indent, qq @
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
	#int overflow__$op->{name}_$type->{sfx}_strategy_largetype(const $type->{ctype} a, const $type->{ctype} b, $type->{ctype} *const restrict r, const int a_is_const, const int b_is_const)
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
	#overflow__function overflow__nonnull_arg(3) overflow__must_check
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


