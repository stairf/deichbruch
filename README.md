
About Deichbruch
================

Deichbruch is a library for fast, reliable, and portable integer overflow
detection in C. It chooses a suitable overflow-detection strategy at
compile-time, using heuristics based on benchmarking results. The compiler
optimizes each arithmetic operation individually.


Build Deichbruch
----------------

Deichbruch provides a GNU Makefile to create the library. To build it, run
`make`. You can use the `-j` option to speed up the build process:

	make -j<n> benchmarks && make

The build system automatically optimizes the library using benchmark results.
Do not use the `-j` option when running the benchmarks because it influences
performance measurements.


Usage
-----

Deichbruch only consists of a single header file, which includes all required
functions and macros for overflow detection. The following three type-generic
macros are suitable for most occasions:

	#include "overflow.h"

	bool overflow_add(TYPE a, TYPE b, TYPE *r);

	bool overflow_sub(TYPE a, TYPE b, TYPE *r);

	bool overflow_mul(TYPE a, TYPE b, TYPE *r);

Be sure that both `a` and `b` have the same type, and `r` is a pointer to that
type. On overflow, these functions return `true` and the content of `\*r` is
undefined. On success, the return value is `false` and the result of the
arithmetic operation is stored in `\*r`.


Optimization
------------

Deichbruch targets compiler optimization for performance improvement. Do not
compile Deichbruch with optimizations disabled (or at least do not complain
about performance then). The overflow detection macros and functions rely on
basic compiler optimization techniques, such as inlining, constant propagation
and dead code elimination. The following approaches help the compiler to
improve code performance:

 - If available, Deichbruch uses compiler built-in functions that provide
   efficient overflow detection.
 - All macros and functions care about constant values, and therefore allow
   compiler optimizations like constant folding.
 - The compiler statically chooses the overflow detection strategy that
   performed best in the benchmarks, in a similar situation.
 - On success, each macro tells the compiler that the result is equivalent to
   the corresponding integer operation, as long as the compiler supports such
   an information. Thus, further optimization based on dataflow is possible.


Overflow Detection Strategies
-----------------------------

Currently, Deichbruch implements the following overflow detection strategies:

 - *precheck*: Before performing the critical operation, test if the operand are
   in valid ranges. If necessary, the valid ranges are computed at runtime.
   However, Deichbruch tries to reduce runtime costs by pre-calculation at
   compile time, if possible.
 - *largetype*: Use a bigger data type for the critical operation, then check the
   result and cast it back to the original type.
 - *partial*: Split the operands into two parts so that the operation cannot
   overflow, then combine the results.
 - *postcheck*: Perform the operation and check the result afterwards. This is
   only possible for unsigned data types.
 - *default*: Use compile-time heuristics, based on benchmarking results, to
   choose a strategy that is likely to be fast.


Testing
-------

Deichbruch uses a type-generic testsuite to test each overflow detection
strategy for each type. You can find it in the `tests/` folder.

To run the testsuite, run `make check`.

The testsuite uses the GCC compiler flag `-ftrapv` that causes program abortion
on integer overflow. This flag ensures that no undefined behavior occurs in the
tests.


Benchmarking
------------

For each individual operation, Deichbruch tries to find one approach that is
good enough for this particular case. The default strategy examines the
operands to decide which strategy is likely to be fast.

The compile-time heuristics of the default strategy are derived from
benchmarking results. You can find the benchmark source code in the
`benchmarks/` folder.

To run all benchmarks and plot the result, run `make plot`. The result will be
visualized in the file `plots/result.pdf`. Benchmarking *will* take some time.
Do not pass the `-j` option to make because parallel processing can influence
performance measurements.


