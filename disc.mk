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

include ../config.mk

FPWMAKE ?= fpwmake
PACKAGE = edic2-fpw
SUBDIRS = $(wildcard EDIC2D*)
SRCDIR2 = ../${SRCDIR}
PACKAGEEXTRA = ../README.PKG
PACKAGEDEPS = 
ARCHIVEEXTRA = ../ChangeLog ../README.rst ../README.PKG
CLEANEXTRA =
PACKAGEEXTRA = 

FPWPARSER = ../edic2-fpw.pl
FPWPARSERFLAGS = ${DICNO} ${SRCDIR2}

.SUFFIXES:
.PHONY: build

include fpwutils.mk

build: all catalogs

SUB_CATALOGS := $(addsuffix /catalogs.txt,${SUBDIRS})
$(SUB_CATALOGS): ${FPWPARSER}
	(cd "$(dir $@)" && ${FPWMAKE} catalogs.txt)

catalogs.txt: ${SUB_CATALOGS}
	rm -f $@
	echo "[Catalog]" > $@
	echo "FileName	= catalogs" >> $@
	echo "Type	= EPWING5" >> $@
	${PERL} -e 'printf "Books\t\t= %d\n", scalar(@ARGV)' ${SUBDIRS} >> $@
	for subdir in ${SUBDIRS} ; do \
	   echo "[Book]" >> $@ ; \
	   ${PERL} -n -e 'print if /^Title\s*=/'    $$subdir/$@ >> $@ ; \
	   ${PERL} -n -e 'print if /^BookType\s*=/' $$subdir/$@ >> $@ ; \
	   ${PERL} -n -e 'print if /^HanGaiji\s*=/' $$subdir/$@ >> $@ ; \
	   ${PERL} -n -e 'print if /^ZenGaiji\s*=/' $$subdir/$@ >> $@ ; \
	   echo "Directory	= \"$$subdir\"" >> $@ ; \
	done

pre-package:
	rm -rf ${DIR}
	${FPWMAKE} INSTALLDIR="../work" DIR="${DIR}" install
	chmod 777 ../work/${DIR}
ifneq ($(strip ${SUBDIRS}),)
	for subdir in ${SUBDIRS} ; do \
	  chmod 777 ../work/${DIR}/$${subdir}/data ; \
	done
else
	chmod 777 ../work/${DIR}/${DIR}/data
endif
