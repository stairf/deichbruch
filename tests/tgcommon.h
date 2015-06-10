/*****
 * Copyright (c) 2015, Stefan Reif
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****/

/*
 * tgcommon.h
 */
#ifndef __TGCOMMON_H__
#define __TGCOMMON_H__

#include "common.h"

#define check_add(a,b) check_add_at(a,b,__FILE__,__LINE__,__func__)
#define check_sub(a,b) check_sub_at(a,b,__FILE__,__LINE__,__func__)
#define check_mul(a,b) check_mul_at(a,b,__FILE__,__LINE__,__func__)
#define fail_add(a,b) fail_add_at(a,b,__FILE__,__LINE__,__func__)
#define fail_sub(a,b) fail_sub_at(a,b,__FILE__,__LINE__,__func__)
#define fail_mul(a,b) fail_mul_at(a,b,__FILE__,__LINE__,__func__)


overflow__function void check_add_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_add(a, b, &r)) {
		termAt(FMT " + " FMT " should not overflow", a, b);
	}
	if (r != a + b)
		termAt(FMT " + " FMT " = " FMT ", should be " FMT, a, b, r, a+b);
}

overflow__function void check_sub_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_sub(a, b, &r)) {
		termAt(FMT " - " FMT " should not overflow", a, b);
	}
	if (r != a - b)
		termAt(FMT " - " FMT " = " FMT ", should be " FMT, a, b, r, a-b);
}

overflow__function void check_mul_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_mul(a, b, &r)) {
		termAt(FMT " * " FMT " should not overflow", a, b);
	}
	if (r != a * b)
		termAt(FMT " * " FMT " = " FMT ", should be " FMT, a, b, r, a*b);
}

overflow__function void fail_add_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_add(a, b, &r))
		return;
	termAt(FMT " + " FMT " = " FMT ", should overflow", a, b, r);
}

overflow__function void fail_sub_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_sub(a, b, &r))
		return;
	termAt(FMT " - " FMT " = " FMT ", should overflow", a, b, r);
}

overflow__function void fail_mul_at(TYPE a, TYPE b, AT)
{
	TYPE r;
	if (overflow_mul(a, b, &r))
		return;
	termAt(FMT " * " FMT " = " FMT ", should overflow", a, b, r);
}


#endif /* __TGCOMMON_H__ */
