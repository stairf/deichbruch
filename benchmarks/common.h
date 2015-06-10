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

#include "overflow.x"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sched.h>

#define N_RUN 10000

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

/*
 * HACK: we can use overflow__function here although it should be private
 */
overflow__function uint64_t now()
{
	uint32_t low;
	uint32_t high;
	__asm__ volatile ("rdtsc" : "=a" (low), "=d" (high));
	uint64_t result = high;
	result <<= 32;
	result |= low;
	return result;
}

static inline void cpu_pin(void)
{
	cpu_set_t *set;

	long nproc = sysconf(_SC_NPROCESSORS_CONF);
	int cpu = sched_getcpu();
	size_t size = CPU_ALLOC_SIZE(nproc+1);
	if (cpu < 0)
		die("sched_getcpu");

	set = CPU_ALLOC(nproc+1);
	if (!set)
		die("CPU_ALLOC");

	CPU_ZERO_S(size, set);
	CPU_SET_S(cpu, size, set);

	if (sched_setaffinity(getpid(), size, set))
		die("sched_setaffinity");

	CPU_FREE(set);
}

static inline void cpu_relax(void)
{
	sched_yield();
}

static uint64_t time;
static uint64_t total_time;

#define start() do{ \
		uint64_t _start__now = now(); \
		time = _start__now; \
	} while (0)

#define end() do {\
		uint64_t _end__now = now(); \
		uint64_t _end__delta = _end__now - time; \
		total_time += _end__delta; \
	} while (0)

extern void ignore(int x);
extern int nothing(void);

#define effect(x) (ignore((int)(x)))
#define just(x) ((x)^nothing())


static void step(void);

int main(int argc, char **argv)
{
	cpu_pin();
	for (int i = 0; i < N_RUN; ++i) {
		step();
		cpu_relax();
	}
	printf("%llu\n", (unsigned long long) total_time);

	return 0;
}



#endif /* __COMMON_H__ */
