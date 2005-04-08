
SHELL		=	csh

## Projects
NIFTI		=	niftilib
ZNZ		=	znzlib
FSLIO		=	fsliolib
EXAMPLES	=	examples
UTILS		=	utils
UTILS_PROGS	=	nifti_stats nifti_tool nifti1_test
THIS_DIR	=	`basename ${PWD}`

## Note the TARFILE_NAME embeds the release version number
TARFILE_NAME	=	nifticlib-0.1


## Compiler  defines
cc		=	gcc
CC		=	gcc
AR		=	ar
DEPENDFLAGS	=	-MM
GNU_ANSI_FLAGS	= 	-Wall -ansi -pedantic
ANSI_FLAGS	= 	${GNU_ANSI_FLAGS}
CFLAGS		=	$(ANSI_FLAGS)

## Command defines
MAKE 		=	gmake
RM		=	rm
MV		=	mv
CP		=	cp
TAR		=	tar


## Installation
INSTALL_BIN_DIR	=	bin
INSTALL_LIB_DIR	=	lib
INSTALL_INC_DIR	=	include


## Zlib defines
ZLIB_INC	=	-I/usr/include
ZLIB_PATH	=	-L/usr/lib
ZLIB_LIBS 	= 	$(ZLIB_PATH) -lm -lz 



## Platform specific redefines

## SGI 32bit
ZLIB_INC	=	-I/usr/freeware/include
ZLIB_PATH	=	-L/usr/freeware/lib32


## RedHat Fedora Linux
## ZLIB_INC	=	-I/usr/include
## ZLIB_PATH	=	-L/usr/lib





#################################################################

## ZNZ defines
ZNZ_INC		=	-I../$(ZNZ)
ZNZ_PATH	=	-L../$(ZNZ)
ZNZ_LIBS	=	$(ZNZ_PATH)  -lznz
USEZLIB         =       -DHAVE_ZLIB

## NIFTI defines
NIFTI_INC	=	-I../$(NIFTI)
NIFTI_PATH	=	-L../$(NIFTI)
NIFTI_LIBS	=	$(NIFTI_PATH) -lniftiio

## FSLIO defines
FSLIO_INC	=	-I../$(FSLIO)
FSLIO_PATH	=	-L../$(FSLIO)
FSLIO_LIBS	=	$(FSLIO_PATH) -lfslio



## Rules

.SUFFIXES: .c .o

.c.o:
	$(CC) -c $(CFLAGS) $(INCFLAGS) $<



## Targets

all:	   znz nifti fslio install

install:   znz_install nifti_install fslio_install utils_install

clean:	   znz_clean nifti_clean fslio_clean examples_clean utils_clean

clean_all: clean install_clean doc_clean


znz:
	(cd $(ZNZ); $(MAKE) depend; $(MAKE) lib;)
	@echo " ----------- $(ZNZ) build completed."

nifti:	znz
	(cd $(NIFTI); $(MAKE) depend; $(MAKE) lib;)
	@echo " ----------- $(NIFTI) build completed."

fslio:	nifti
	(cd $(FSLIO); $(MAKE) depend; $(MAKE) lib;)
	@echo " ----------  $(FSLIO) build completed."

example:nifti
	(cd $(EXAMPLES); $(MAKE) all;)
	@echo Example programs built.

utils:  nifti
	(cd $(UTILS); $(MAKE) all;)
	@echo Utility programs built.

doc:
	(cd docs; doxygen Doxy_nifti.txt;)
	@echo "doxygen doc rebuilt, run netscape doc/html/index.html to view."

znz_install:
	($(CP) $(ZNZ)/*.a $(INSTALL_LIB_DIR); $(CP) $(ZNZ)/*.h $(INSTALL_INC_DIR);)
	@echo " $(ZNZ) installed."

nifti_install:
	($(CP) $(NIFTI)/*.a $(INSTALL_LIB_DIR); $(CP) $(NIFTI)/*.h $(INSTALL_INC_DIR);)
	@echo " $(NIFTI) installed."

fslio_install:
	($(CP) $(FSLIO)/*.a $(INSTALL_LIB_DIR); $(CP) $(FSLIO)/*.h $(INSTALL_INC_DIR);)
	@echo " $(FSLIO) installed."

utils_install: utils
	(cd $(UTILS); $(CP) $(UTILS_PROGS) ../$(INSTALL_BIN_DIR);)
	@echo " $(UTILS) installed."

install_clean:
	($(RM) -f $(INSTALL_INC_DIR)/* $(INSTALL_LIB_DIR)/* $(INSTALL_BIN_DIR)/*;)

znz_clean:
	(cd $(ZNZ); $(RM) -f *.o *.a core; $(RM) -f depend.mk;)

nifti_clean:
	(cd $(NIFTI); $(RM) -f *.o *.a core; $(RM) -f depend.mk;)

fslio_clean:
	(cd $(FSLIO); $(RM) -f *.o *.a core; $(RM) -f depend.mk;)

examples_clean:
	(cd $(EXAMPLES); $(MAKE) clean;)

utils_clean:
	(cd $(UTILS); $(MAKE) clean;)

doc_clean:
	($(RM) -fr docs/html;)

tar:
	(cd .. ; ln -s $(THIS_DIR) ${TARFILE_NAME} ; \
	tar --exclude=CVS -cf ${TARFILE_NAME}.tar ${TARFILE_NAME}/*; \
	rm -f ${TARFILE_NAME});
	@echo ''
	@echo 'tar file ../${TARFILE_NAME}.tar has been created.'
	@echo ''


help:
	@echo ""
	@echo "all:           build and install znz, nifti1 and fslio"
	@echo "               libraries, and the utils programs"
	@echo "install:       install znz, nifti1, and fslio libraries"
	@echo "doc:           build the doxygen docs for this project."
	@echo "               (Need doxygen installed, see"
	@echo "               http://www.stack.nl/~dimitri/doxygen/index.html"
	@echo "tar:           make a tar file of all nifti_io code, put in .."
	@echo ""
	@echo "clean:         remove .o .a etc. files from source directories,"
	@echo "               and remove examples and utils programs"
	@echo "clean_all:     make clean and delete all installed files in bin,"
	@echo "               include and lib, and remove any autogenerated"
	@echo "               docs (docs/html)"
	@echo ""
	@echo "znz:           build the znz library"
	@echo "znz_install:   install the znz library"
	@echo "nifti:         build the nifti1 library"
	@echo "nifti_install: install the nifti1 library"
	@echo "fslio:         build the fslio library"
	@echo "fslio_install: install the fslio library"
	@echo "example:       make the example program(s)"
	@echo "utils:         make the utils programs"
	@echo "utils_install: install the utils programs"
	@echo ""