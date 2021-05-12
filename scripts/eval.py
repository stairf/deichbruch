#!/usr/bin/env python
# coding: utf-8

#
# Copyright (c) 2021, Stefan Reif
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

import numpy as np
import subprocess
import sys

def die(msg):
    print(msg)
    sys.exit(1)

def remove_outliers(values, dist=3):
    avg = np.average(values)
    return [v for v in values if v < dist * avg]

self = sys.argv[0]

if len(sys.argv) != 2:
    die("usage: "+self+" <target>")

target = sys.argv[1]

proc = subprocess.Popen([ target ], stdout=subprocess.PIPE)
raw_values = [float(l.rstrip()) for l in proc.stdout]
proc.wait()
if proc.returncode < 0:
    print("#exit signal "+str(-proc.returncode))
    sys.exit(0)
elif proc.returncode > 0:
    print("#exit code "+str(proc.returncode))
    sys.exit(0)

values = remove_outliers(raw_values)

print("%f %f %f"%(np.average(values), np.percentile(values, 5), np.percentile(values, 95)))


