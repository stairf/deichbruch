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
 * common.h
 */
#ifndef __COMMON_H__
#define __COMMON_H__

#include "overflow.h"

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

#define dieX(file,line,func,...) do { \
		fprintf(stderr, "%s:%u:%s(): error: ", file, line, func); \
		fprintf(stderr, __VA_ARGS__); \
		fprintf(stderr, ": %s\n", strerror(errno)); \
		exit(EXIT_FAILURE); \
	} while (0)

#define termX(file,line,func,...) do { \
		fprintf(stderr, "%s:%u:%s(): error: ", file, line, func); \
		fprintf(stderr, __VA_ARGS__); \
		fprintf(stderr, "\n"); \
		exit(EXIT_FAILURE); \
	} while (0)

#define AT const char *_file, unsigned _line, const char *_func
#define die(...) dieX(__FILE__,__LINE__,__func__,__VA_ARGS__)
#define term(...) termX(__FILE__,__LINE__,__func__,__VA_ARGS__)
#define dieAt(...) dieX(_file, _line, _func, __VA_ARGS__)
#define termAt(...) termX(_file, _line, _func, __VA_ARGS__)

extern void ignore(int x);
extern int nothing(void);

#define effect(x) (ignore((int)(x)))
#define just(x) ((x)^nothing())


#endif /* __COMMON_H__ */
