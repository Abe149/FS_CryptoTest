.POSIX:

all: build_dir./FS_CryptoTest

REAL_BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!

$(REAL_BUILD_DIR):
	mkdir -p $@

build_dir.: $(REAL_BUILD_DIR)
	ln -fs $(REAL_BUILD_DIR) .

CXX_IS_COMPATIBLE_WITH_GCC_FLAGS=`$(CXX) --version | grep -q 'GCC|clang' && echo yes`

BASE_BASENAME=FS_CryptoTest
EXECUTABLE_BASENAME=$(BASE_BASENAME) # For flexibility, e.g. in case this code will -- in the future -- support generating e.g. "FS_CryptoTest.exe"
SOURCE_FILENAME=$(BASE_BASENAME).cpp

build_dir./FS_CryptoTest: build_dir. $(SOURCE_FILENAME)
# CXX and CXXFLAGS come _last_ here on _purpose_ in case they are not set
	./compile.sh $(SOURCE_FILENAME) build_dir./$(EXECUTABLE_BASENAME) --compiler_command=$(CXX) $(CXXFLAGS) 



# vim: noet #
