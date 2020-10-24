# -*- mode: makefile -*-
#
# Copyright (C) 2020  MURAMATSU Atsushi
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

include ../../config.mk

DICNO = $(notdir $(shell pwd))
SRCDIR3 = ../../${SRCDIR}
SOURCES = $(wildcard "${SRCDIR3}/*.csv")
FPWPARSER = ../../edic2-fpw.pl
FPWPARSERFLAGS = ${DICNO} ${SRCDIR3}

.SUFFIXES:

include fpwutils.mk

catalogs.txt: ${FPWPARSER}
	${PERL} ${FPWPARSER} --catalogs ${DICNO}
