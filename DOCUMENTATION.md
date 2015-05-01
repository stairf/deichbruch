Deichbruch Documentation
========================

About Deichbruch
----------------

Deichbruch provides functions and macros for reliable, portable and fast
integer overflow detection in C.


Usage
-----

	#include <overflow.h>

	bool overflow_add(TYPE a, TYPE b, TYPE *r);

	bool overflow_likely_add(TYPE a, TYPE b, TYPE *r);

	bool overflow_unlikely_add(TYPE a, TYPE b, TYPE *r);

	bool overflow_sub(TYPE a, TYPE b, TYPE *r);

	bool overflow_likely_sub(TYPE a, TYPE b, TYPE *r);

	bool overflow_unlikely_sub(TYPE a, TYPE b, TYPE *r);

	bool overflow_mul(TYPE a, TYPE b, TYPE *r);

	bool overflow_likely_mul(TYPE a, TYPE b, TYPE *r);

	bool overflow_unlikely_mul(TYPE a, TYPE b, TYPE *r);

	bool overflow_add_i(int a, int b, int *r);

	bool overflow_add_li(long a, long b, long *r);

	bool overflow_add_lli(long long a, long long b, long long *r);

	bool overflow_add_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_add_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_add_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_add_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_add_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_add_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_add_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_add_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_add_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_add_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_add_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_likely_add_i(int a, int b, int *r);

	bool overflow_likely_add_li(long a, long b, long *r);

	bool overflow_likely_add_lli(long long a, long long b, long long *r);

	bool overflow_likely_add_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_likely_add_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_likely_add_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_likely_add_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_likely_add_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_likely_add_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_likely_add_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_likely_add_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_likely_add_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_likely_add_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_likely_add_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_unlikely_add_i(int a, int b, int *r);

	bool overflow_unlikely_add_li(long a, long b, long *r);

	bool overflow_unlikely_add_lli(long long a, long long b, long long *r);

	bool overflow_unlikely_add_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_unlikely_add_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_unlikely_add_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_unlikely_add_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_unlikely_add_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_unlikely_add_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_unlikely_add_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_unlikely_add_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_unlikely_add_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_unlikely_add_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_unlikely_add_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_sub_i(int a, int b, int *r);

	bool overflow_sub_li(long a, long b, long *r);

	bool overflow_sub_lli(long long a, long long b, long long *r);

	bool overflow_sub_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_sub_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_sub_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_sub_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_sub_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_sub_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_sub_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_sub_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_sub_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_sub_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_sub_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_likely_sub_i(int a, int b, int *r);

	bool overflow_likely_sub_li(long a, long b, long *r);

	bool overflow_likely_sub_lli(long long a, long long b, long long *r);

	bool overflow_likely_sub_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_likely_sub_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_likely_sub_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_likely_sub_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_likely_sub_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_likely_sub_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_likely_sub_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_likely_sub_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_likely_sub_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_likely_sub_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_likely_sub_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_unlikely_sub_i(int a, int b, int *r);

	bool overflow_unlikely_sub_li(long a, long b, long *r);

	bool overflow_unlikely_sub_lli(long long a, long long b, long long *r);

	bool overflow_unlikely_sub_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_unlikely_sub_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_unlikely_sub_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_unlikely_sub_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_unlikely_sub_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_unlikely_sub_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_unlikely_sub_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_unlikely_sub_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_unlikely_sub_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_unlikely_sub_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_unlikely_sub_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_mul_i(int a, int b, int *r);

	bool overflow_mul_li(long a, long b, long *r);

	bool overflow_mul_lli(long long a, long long b, long long *r);

	bool overflow_mul_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_mul_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_mul_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_mul_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_mul_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_mul_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_mul_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_mul_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_mul_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_mul_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_mul_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_likely_mul_i(int a, int b, int *r);

	bool overflow_likely_mul_li(long a, long b, long *r);

	bool overflow_likely_mul_lli(long long a, long long b, long long *r);

	bool overflow_likely_mul_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_likely_mul_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_likely_mul_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_likely_mul_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_likely_mul_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_likely_mul_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_likely_mul_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_likely_mul_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_likely_mul_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_likely_mul_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_likely_mul_u64(uint64_t a, uint64_t b, uint64_t *r);

	bool overflow_unlikely_mul_i(int a, int b, int *r);

	bool overflow_unlikely_mul_li(long a, long b, long *r);

	bool overflow_unlikely_mul_lli(long long a, long long b, long long *r);

	bool overflow_unlikely_mul_u(unsigned int a, unsigned int b, unsigned int *r);

	bool overflow_unlikely_mul_lu(unsigned long a, unsigned long b, unsigned long *r);

	bool overflow_unlikely_mul_llu(unsigned long long a, unsigned long long b, unsigned long long *r);

	bool overflow_unlikely_mul_i8(int8_t a, int8_t b, int8_t *r);

	bool overflow_unlikely_mul_u8(uint8_t a, uint8_t b, uint8_t *r);

	bool overflow_unlikely_mul_i16(int16_t a, int16_t b, int16_t *r);

	bool overflow_unlikely_mul_u16(uint16_t a, uint16_t b, uint16_t *r);

	bool overflow_unlikely_mul_i32(int32_t a, int32_t b, int32_t *r);

	bool overflow_unlikely_mul_u32(uint32_t a, uint32_t b, uint32_t *r);

	bool overflow_unlikely_mul_i64(int64_t a, int64_t b, int64_t *r);

	bool overflow_unlikely_mul_u64(uint64_t a, uint64_t b, uint64_t *r);


Description
-----------

All `overflow_*` functions and macros provide integer arithmetic operations
with overflow detection. Note that both operands must have the same type, and
the result must be a pointer to that type. Conceptually, each function performs
an arithmetic operation with infinite precision, and then truncates that result
to the result type. All function return zero on success, and the result of the
operation is stored in `*r`. When the truncated result is not equal to the
infinite-precision result, then all functions return a non-zero value, and the
contents of `*r` are undefined.

The `overflow_likely_*` and the `overflow_unlikely_*` functions are equivalent
to the corresponding `overflow_*` functions, but they are optimized for the
case of overflow, or no overflow, respectively.

Technically, all functions are implemented as preprocessor macros. Do not use
function pointers.


Return Value
------------

All overflow detection functions return zero when the result of its integer
arithmetic operation can be represented by the actual data type. Otherwise,
they return a non-zero value.


Configuration
-------------

Deichbruch allows a minimal configuration using preprocessor macros.

	* `OVERFLOW_LAZY_GENERIC`

		Do not raise a compiler warning when type-generic macros are not
		supported. Then, it is possible that the Deichbruch header file does
		not define the following macros:

		 - overflow_add
		 - overflow_sub
		 - overflow_mul
		 - overflow_likely_add
		 - overflow_likely_sub
		 - overflow_likely_mul
		 - overflow_unlikely_add
		 - overflow_unlikely_sub
		 - overflow_unlikely_mul


		See above for a detailled description of the macros. You can still use
		the non-generic macros with type suffix.

Future versions might support more configuration variables.


Namespaces
----------

Deichbruch uses the following namespaces:

	- `overflow_*` for all public functions and function-like macros
	- `OVERFLOW_*` for externally visible macros
	- `overflow__*` for everything internal

Do not rely on any of the internal `overflow__*` macros because they might
change in future versions without any warning.

