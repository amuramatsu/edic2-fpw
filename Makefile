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

SUBDIRS = DISC1 DISC2
ifeq (${HAS_EXTEND_DIC},1)
SUBDIRS += DISC3
endif
FPWMAKE ?= fpwmake
ZIP ?= zip
ARCHIVEEXTRA = ChangeLog README.rst README.PKG

include config.mk

all:

package:
	rm -rf work
	for d in ${SUBDIRS}; do	\
	 (cd $$d && $(FPWMAKE) "FPWMAKE=$(FPWMAKE)" pre-package) \
	done
	cp $(ARCHIVEEXTRA) work
	(cd work && ${ZIP} -9rkq ../${PACKAGE}.zip .)
	rm -rf work

%:
	for d in ${SUBDIRS}; do	\
	 (cd $$d && $(FPWMAKE) "FPWMAKE=$(FPWMAKE)" $@) \
	done
