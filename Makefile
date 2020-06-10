# ifeq ($(CXX),)
ifndef CXX
  CXX=`which CC`
endif
ifndef CXX
  CXX=`which g++`
endif
ifndef CXX
  CXX=`which clang++`
endif
echo CXX=$(CXX)

all: build_dir./FS_CryptoTest

REAL_BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!

$(REAL_BUILD_DIR):
	mkdir -p $@

build_dir.: ___not_in_Git/build_dir. # TO DO: more DRY
	ln -fs $(REAL_BUILD_DIR) .

SOURCE_FILE=FS_CryptoTest.cpp

build_dir./FS_CryptoTest: build_dir. $(SOURCE_FILE)
	$(CXX) $(CXXFLAGS) $(SOURCE_FILE) -o build_dir./FS_CryptoTest # embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output pathname"



# vim: noet #
