.POSIX:

all: build_dir./FS_CryptoTest

REAL_BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!

$(REAL_BUILD_DIR):
	mkdir -p $@

build_dir.: $(REAL_BUILD_DIR)
	ln -fs $(REAL_BUILD_DIR) .

# ifndef CXX
#   CXX=`which CC`
# endif
# ifndef CXX
#   CXX=`which g++`
# endif
# ifndef CXX
#   CXX=`which clang++`
# endif

CXX_IS_COMPATIBLE_WITH_GCC_FLAGS=`$(CXX) --version | grep -q 'GCC|clang' && echo yes`

# ifndef CXXFLAGS
# endif

BASE_BASENAME=FS_CryptoTest
EXECUTABLE_BASENAME=$(BASE_BASENAME) # For flexibility, e.g. in case this code will -- in the future -- support generating e.g. "FS_CryptoTest.exe"
SOURCE_FILENAME=$(BASE_BASENAME).cpp

build_dir./FS_CryptoTest: build_dir. $(SOURCE_FILENAME)
#	echo INFO: CXX=$(CXX)
#	echo INFO: CXX_IS_COMPATIBLE_WITH_GCC_FLAGS=$(CXX_IS_COMPATIBLE_WITH_GCC_FLAGS)
	# $(CXX) $(CXXFLAGS) $(SOURCE_FILENAME) -o build_dir./$(EXECUTABLE_BASENAME) # embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output pathname"
	./compile.sh $(SOURCE_FILENAME) build_dir./$(EXECUTABLE_BASENAME)



# vim: noet #
