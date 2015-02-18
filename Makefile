# *** MAKEFILE ***

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


#
# This is the Deichbruch Makefile. It supports the following targets:
#  all        -- create the Deichbruch header file
#  clean      -- delete everything, except for the benchmark plots
#  tests      -- compile the testsuite
#  check      -- run the testsuite
#  benchmarks -- compile all benchmarks
#  plot       -- run and plot benchmark results
#
# You will probably need GNU make to run make. If you do not have a GNU
# implementation of make, or you do not want to generate dependencies (this
# takes some time), run:
# 	perl overflow.h.pl > overflow.h
#
# File name suffix conventions
#  .vc [hint:variable-constant]
#     Expand to four source files, which have the macros P0(x) and P1(x)
#     defined. These macros do hide the parameter value from the compiler. The
#     four result files contain the four varations of constant/variable
#     parameters.
#  .tg [hint:type-generic]
#     Expand to six source files, where each use a different type.
#  .d
#     Dependency file for make
#
#
TARGET = overflow.h

TDIR = ./tests
BDIR = ./benchmarks
CDIR = .
PDIR = ./plots

CC       = gcc
LD       = gcc
CFLAGS   = -std=c99 -I.
CFLAGS_B = -D_GNU_SOURCE
CFLAGS_T = -ftrapv
OPTIMIZE = -O3 -mtune=native -march=native
WARN     = -Wall -Wno-overflow
LDFLAGS  = $(CFLAGS)
LIBS     =
PERL     = perl
SH      ?= sh
RM       = rm -rf
MKDIR    = mkdir -p
DEPGEN   = -MM -MF $@ -MT "$(@:%.d=%.o) $@" -MP -MG $<
LATEX    = pdflatex </dev/null -interaction=nonstopmode

CFLAGS  += $(OPTIMIZE) $(WARN)

TGSFX = i u li lu lli llu i8 u8 i16 u16 i32 u32 i64 u64
STRAT = default precheck postcheck largetype partial likely unlikely
VC    = cc cv vc vv

ifneq "$(strip $(wildcard safe_iop.h))" ""
	STRAT += lib
endif

TSRC := $(notdir $(wildcard $(TDIR:%=%/*.c)))
BSRC := $(notdir $(wildcard $(BDIR:%=%/*.c)))
CSRC := $(notdir $(wildcard ./*.c))

TGPL := $(notdir $(wildcard $(TDIR:%=%/*.[ch].pl)))
BGPL := $(notdir $(wildcard $(BDIR:%=%/*.[ch].pl)))
CGPL := $(notdir $(wildcard ./*.[ch].pl))

TGEN := $(TGPL:%.pl=%)
BGEN := $(BGPL:%.pl=%)
CGEN := $(CGPL:%.pl=%)

TSRC += $(filter %.c, $(TGEN))
BSRC += $(filter %.c, $(BGEN))
CSRC += $(filter %.c, $(CGEN))

TVCS := $(notdir $(wildcard $(TDIR:%=%/*.vc)))
BVCS := $(notdir $(wildcard $(BDIR:%=%/*.vc)))

TVCG := $(foreach V, $(VC), $(TVCS:%.vc=$(TDIR:%=%)/.$(V:%=%)-%))
BVCG := $(foreach V, $(VC), $(BVCS:%.vc=$(BDIR:%=%)/.$(V:%=%)-%))

TTG  := $(notdir $(wildcard $(TDIR:%=%/*.tg))) $(notdir $(TVCG))
BTG  := $(notdir $(wildcard $(BDIR:%=%/*.tg))) $(notdir $(BVCG))

TTGC := $(foreach S, $(TGSFX), $(TTG:%.tg=$(TDIR:%=%)/.%-$(S:%=%).c))
BTGC := $(foreach S, $(TGSFX), $(BTG:%.tg=$(BDIR:%=%)/.%-$(S:%=%).c))

TSRC += $(notdir $(TTGC))
BSRC += $(notdir $(BTGC))

TSRC := $(sort $(TSRC))
BSRC := $(sort $(BSRC))

TOBJ  =
BOBJ  =
COBJ  =

TBIN  =
BBIN  =

TDEP  =
BDEP  =
CDEP  =

OBJS  =
DEPS  =
GEN   = $(TGEN) $(BGEN) $(CGEN) $(BVCG) $(TVCG)
TGC   = $(TTGC) $(BTGC)

TESTS      = $(TSRC:%.c=%)
BENCHMARKS = $(BVCS:%.tg.vc=%)


# by default, only build the target header. Everything else is optional, so we
# can speed up the build time. When someone does not want to run the
# testcases/benchmarks, then building them is not required.
.PHONY: all
all: $(TARGET)

ifeq "${VERBOSE}" ""
Q=@
LATEX += >/dev/null
else
Q=
endif


# usage $(eval $(call STRATEGY_TEMPLATE, strategy_name))
define STRATEGY_TEMPLATE
$(1:%=TOBJ_%) = $$(TSRC:%.c=$$(TDIR:%=%)/.%-$(1:%=%).o)
$(1:%=BOBJ_%) = $$(BSRC:%.c=$$(BDIR:%=%)/.%-$(1:%=%).o)
$(1:%=COBJ_%) = $$(CSRC:%.c=$$(CDIR:%=%)/.%-$(1:%=%).o)

$(1:%=TBIN_%) = $$(TSRC:%.c=$$(TDIR:%=%)/.%-$(1:%=%)-bin)
$(1:%=BBIN_%) = $$(BSRC:%.c=$$(BDIR:%=%)/.%-$(1:%=%)-bin)

##$(1:%=TRUN_%) = $$($(1:%=TBIN_%):%-bin=%-run)

TBIN += $$($(1:%=TBIN_%))
BBIN += $$($(1:%=BBIN_%))

##TRUN += $$($(1:%=TRUN_%))

$(1:%=TDEP_%) = $$(TSRC:%.c=$$(TDIR:%=%)/.%-$(1:%=%).d)
$(1:%=BDEP_%) = $$(BSRC:%.c=$$(BDIR:%=%)/.%-$(1:%=%).d)
$(1:%=CDEP_%) = $$(CSRC:%.c=$$(CDIR:%=%)/.%-$(1:%=%).d)

OBJS += $$($(1:%=TOBJ_%)) $$($(1:%=BOBJ_%)) $$($(1:%=COBJ_%))
DEPS += $$($(1:%=TDEP_%)) $$($(1:%=BDEP_%)) $$($(1:%=CDEP_%))

.PHONY: $(1:%=info-%)
$(1:%=info-%):
	@echo "== Strategy: $(1:%=%) =="
	@echo "  T OBJ: $$($(1:%=TOBJ_%))"
	@echo "  T DEP: $$($(1:%=TDEP_%))"
	@echo "  T BIN: $$($(1:%=TBIN_%))"
	@echo "  B OBJ: $$($(1:%=BOBJ_%))"
	@echo "  B DEP: $$($(1:%=BDEP_%))"
	@echo "  B BIN: $$($(1:%=BBIN_%))"
	@echo "  C OBJ: $$($(1:%=COBJ_%))"
	@echo "  C DEP: $$($(1:%=CDEP_%))"

$(1:%=CFLAGS_%) = $$(CFLAGS) $(1:%=-Doverflow__strategy_%)

$$(TDIR)/.%-$(1:%=%).o: $$(TDIR)/%.c
	@echo "CC   [T]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) $$(CFLAGS_T) -c -o $$@ $$<

$$(BDIR)/.%-$(1:%=%).o: $$(BDIR)/%.c
	@echo "CC   [B]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) $$(CFLAGS_B) -c -o $$@ $$<

$$(CDIR)/.%-$(1:%=%).o: $$(CDIR)/%.c
	@echo "CC   [C]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) -c -o $$@ $$<

$$(TDIR)/.%-$(1:%=%).d: $$(TDIR)/%.c
	@echo "DEP  [T]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) $$(CFLAGS_T) $$(DEPGEN) $$<

$$(BDIR)/.%-$(1:%=%).d: $$(BDIR)/%.c
	@echo "DEP  [B]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) $$(CFLAGS_B) $$(DEPGEN) $$<

$$(CDIR)/.%-$(1:%=%).d: $$(CDIR)/%.c
	@echo "DEP  [C]  $$< -> $1"
	$$Q $$(CC) $$($(1:%=CFLAGS_%)) $$(DEPGEN) $$<

$$($(1:%=TBIN_%)): $$(TDIR:%=%)/%-bin: $$(TDIR:%=%)/%.o $$($(1:%=COBJ_%))
	@echo "LD   [T]  $$@"
	$$Q $$(LD) $$(LDFLAGS) -o $$@ $$^ $$(LIBS)

$$($(1:%=BBIN_%)): $$(BDIR:%=%)/%-bin: $$(BDIR:%=%)/%.o $$($(1:%=COBJ_%))
	@echo "LD   [B]  $$@"
	$$Q $$(LD) $$(LDFLAGS) -o $$@ $$^ $$(LIBS)

endef

$(foreach S, $(STRAT), $(eval $(call STRATEGY_TEMPLATE, $S)))

#PLOT =
TEX =
# usage: $(eval $(call PLOT_TEMPLATE_STRAT, benchmark, type)
define PLOT_TEMPLATE_STRAT
$$(PDIR)/$(1:%=%)-$(2:%=%).tex: $$(foreach V, $$(VC), $$(foreach S, $$(STRAT), $$(BDIR:%=%)/...$$(V:%=%)-$(1:%=%)-$(2:%=%)-$$(S:%=%).data)) | $$(PDIR)
	@echo "PLOT      $$(@:%=%)"
	$$Q $$(PERL) scripts/plot.pl --strat $$@ $$^

TEX += $(PDIR)/$(1:%=%)-$(2:%=%).tex
endef

# usage: $(eval $(call PLOT_TEMPLATE_TYPES, benchmark, strat)
define PLOT_TEMPLATE_TYPES
$$(PDIR)/$(1:%=%)-$(2:%=%).tex: $$(foreach V, $$(VC), $$(foreach T, $$(TGSFX), $$(BDIR:%=%)/...$$(V:%=%)-$(1:%=%)-$$(T:%=%)-$(2:%=%).data)) | $$(PDIR)
	@echo "PLOT      $$(@:%=%)"
	$$Q $$(PERL) scripts/plot.pl --type $$@ $$^

TEX += $(PDIR)/$(1:%=%)-$(2:%=%).tex
endef

# usage: $(eval $(call PLOT_TEMPLATE_BENCH, type, strat)
define PLOT_TEMPLATE_BENCH
$$(PDIR)/$(1:%=%)-$(2:%=%).tex: $$(foreach V, $$(VC), $$(foreach B, $$(BENCHMARKS), $$(BDIR:%=%)/...$$(V:%=%)-$$(B:%=%)-$(1:%=%)-$(2:%=%).data)) | $$(PDIR)
	@echo "PLOT      $$(@:%=%)"
	$$Q $$(PERL) scripts/plot.pl --bench $$@ $$^

TEX += $(PDIR)/$(1:%=%)-$(2:%=%).tex
endef

$(foreach B, $(BENCHMARKS), $(foreach T, $(TGSFX), $(eval $(call PLOT_TEMPLATE_STRAT, $B, $T))))
$(foreach B, $(BENCHMARKS), $(foreach S, $(STRAT), $(eval $(call PLOT_TEMPLATE_TYPES, $B, $S))))
$(foreach T, $(TGSFX), $(foreach S, $(STRAT), $(eval $(call PLOT_TEMPLATE_BENCH, $T, $S))))

$(PDIR:%=%)/result.tex: $(TEX)
	@echo "COMB      $@"
	$Q $(SH) scripts/combine.sh scripts/header.tex $^ scripts/footer.tex > $@

$(PDIR:%=%)/result.pdf: $(PDIR:%=%)/result.tex
	@echo "LATEX     $@"
	$Q $(LATEX) -output-directory $(PDIR) $<
	$Q $(LATEX) -output-directory $(PDIR) $<

PLOT = $(PDIR:%=%)/result.pdf

.PHONY: tests benchmarks objs deps gen tg plot tex check
tests: $(TBIN)
benchmarks: $(BBIN)
objs: $(OBJS)
deps: $(DEPS)
gen: $(GEN)
tg: $(TGC)
plot: $(PLOT)
tex: $(TEX)

TRUN = $(TBIN:%-bin=%-run)
check: $(TRUN)
.PHONY: $(TRUN)
$(TRUN): %-run: %-bin
	@echo "CHK       $<"
	$Q $<

DATA = $(BBIN:%-bin=%.data)
data: $(DATA)
$(DATA): %.data: %-bin
	@echo "EVAL      $<"
	$Q ./scripts/eval.sh $< > $@


$(foreach S, $(TGSFX), $(TDIR)/.%-$(S:%=%).c): $(TDIR)/%.tg
	@echo "GEN  [T]  $(*:%=%).tg"
	$Q $(PERL) scripts/mktg.pl $<

$(foreach S, $(TGSFX), $(BDIR)/.%-$(S:%=%).c): $(BDIR)/%.tg
	@echo "GEN  [B]  $(*:%=%).tg"
	$Q $(PERL) scripts/mktg.pl $<

$(foreach V, $(VC), $(BDIR)/.$(V:%=%)-%): $(BDIR)/%.vc
	@echo "GEN  [B]  $(*:%=%).vc"
	$Q $(PERL) scripts/mkvc.pl $<

$(foreach V, $(VC), $(TDIR)/.$(V:%=%)-%): $(TDIR)/%.vc
	@echo "GEN  [T]  $(*:%=%).vc"
	$Q $(PERL) scripts/mkvc.pl $<

$(filter %.h, $(GEN)): %.h: %.h.pl
	@echo "GEN  [PL] $(*:%=%).h"
	$Q $(PERL) $< > $@

$(filter %.c, $(GEN)): %.c: %.c.pl
	@echo "GEN  [PL] $@"
	$Q $(PERL) $< > $@

$(PDIR):
	@echo "MKDIR     $@"
	$Q $(MKDIR) $@

cleangoals = $(filter clean%, $(MAKECMDGOALS))
buildgoals = $(filter-out clean%, $(MAKECMDGOALS))

# include dependency files only if required
ifeq "$(strip $(cleangoals))" ""
  -include $(DEPS)
else
  ifneq "$(strip $(buildgoals))" ""
    $(error "error: build and clean targets specified together")
  endif
endif

.PHONY: clean clean-dep clean-obj clean-gen clean-tg clean-test clean-benchmark clean-all clean-data clean-plot

clean: clean-dep clean-obj clean-gen clean-tg clean-test clean-benchmark
clean-all: clean clean-data clean-plot

clean-dep:
	@echo "CLEAN    dep"
	$Q $(RM) $(DEPS)

clean-obj:
	@echo "CLEAN    obj"
	$Q $(RM) $(OBJS)

clean-gen:
	@echo "CLEAN    gen"
	$Q $(RM) $(GEN)

clean-tg:
	@echo "CLEAN    tg"
	$Q $(RM) $(TGC)

clean-test:
	@echo "CLEAN    test"
	$Q $(RM) $(TBIN)

clean-benchmark:
	@echo "CLEAN    benchmark"
	$Q $(RM) $(BBIN)

clean-data:
	@echo "CLEAN    data"
	$Q $(RM) $(DATA)

clean-plot:
	@echo "CLEAN    plot"
	$Q $(RM) $(PDIR)

.PHONY: info
info:
	@echo "TYPES : $(TGSFX)"
	@echo "TSRC  : $(TSRC)"
	@echo "TOBJ  : $(TOBJ)"
	@echo "TDEP  : $(TDEP)"
	@echo "TGPL  : $(TGPL)"
	@echo "TGEN  : $(TGEN)"
	@echo "BSRC  : $(BSRC)"
	@echo "BOBJ  : $(BOBJ)"
	@echo "BDEP  : $(BDEP)"
	@echo "BGPL  : $(BGPL)"
	@echo "BGEN  : $(BGEN)"
	@echo "BTG   : $(BTG)"
	@echo "BTGC  : $(BTGC)"
	@echo "CSRC  : $(CSRC)"
	@echo "COBJ  : $(COBJ)"
	@echo "CDEP  : $(CDEP)"
	@echo "CGPL  : $(CGPL)"
	@echo "CGEN  : $(CGEN)"
	@echo "PLOT  : $(PLOT)"
	@$(MAKE) --no-print-directory $(foreach S, $(STRAT), $(S:%=info-%))
	@echo "TRUN  : $(TRUN)"
	@echo "DATA  : $(DATA)"
	@echo "BVCG  : $(BVCG)"
	@echo "BM    : $(BENCHMARKS)"


