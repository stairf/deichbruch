#!/bin/sh

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

die() {
	echo "$@" >&2
	exit 1
}

[ "$1" ] || die "usage: $0 <program>"

BIN="$1"

EXPR="scale=10;(0"
VALUES=""
NRUN=20
i=0

while [ $i -lt $NRUN ]; do
	printf "%d\r" $i >&2
	OUT=$( $BIN )
	EXPR="$EXPR+$OUT"
	VALUES="$VALUES $OUT"
	i=$((i+1))
done

EXPR="$EXPR)/$NRUN"
AVG="$(echo $EXPR | bc)"

EXPR="scale=10;(0"
MIN=""
MAX="0"
for V in $VALUES; do
	V=$(echo "scale=10; if ( $V>3*$AVG ) 0 else $V" | bc)
	if [ "$V" -eq 0 ]; then
		NRUN=$((NRUN-1))
	else
		if [ "$V" -gt "$MAX" ]; then
			MAX="$V"
		elif [ -z "$MIN" -o "0$V" -lt "0$MIN" ]; then
			MIN="$V"
		fi
		EXPR="$EXPR+$V"
	fi
done

EXPR="$EXPR)/$NRUN"
#echo >&2 "$EXPR"
AVG=$(echo $EXPR | bc)


printf "%s %s %s\n" "$AVG" "$MIN" "$MAX"


