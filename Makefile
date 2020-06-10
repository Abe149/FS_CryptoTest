.POSIX:

all: build_dir./FS_CryptoTest

REAL_BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!

$(REAL_BUILD_DIR):
	mkdir -p $@

build_dir.: $(REAL_BUILD_DIR)
	ln -f -s $(REAL_BUILD_DIR) .

CXX_IS_COMPATIBLE_WITH_GCC_FLAGS=`$(CXX) --version | grep -q 'GCC|clang' && echo yes`

BASE_BASENAME=FS_CryptoTest
EXECUTABLE_BASENAME=$(BASE_BASENAME) # For flexibility, e.g. in case this code will -- in the future -- support generating e.g. "FS_CryptoTest.exe"
SOURCE_FILENAME=$(BASE_BASENAME).cpp

# build_dir./$(EXECUTABLE_BASENAME): build_dir. $(SOURCE_FILENAME)
build_dir./$(EXECUTABLE_BASENAME): Makefile compile.sh $(SOURCE_FILENAME) # removed "build_dir." from the list of prereq.s due to an apparent bug in GNU Make 3.81 [more documentation in a long comment, below]
#
# CXX and CXXFLAGS come _last_ here on _purpose_ in case they are not set
#
# the next 2 lines: intentionally repeating myself, to work around what seems to be a bug/error in GNU Make 3.81: in re target prereq.s: even when a symlink-to-a-dir. is _older_ than the target, and only the symlink [i.e. _not_ also its _target_] is specified as a prereq., if the pointed-to directory is _newer_ than the target, a rebuild is triggered; "pmake" seems to handle it correctly
	mkdir -p $(REAL_BUILD_DIR)
	ln -f -s $(REAL_BUILD_DIR) .
#
	./compile.sh $(SOURCE_FILENAME) build_dir./$(EXECUTABLE_BASENAME) --compiler_command=$(CXX) $(CXXFLAGS) 



# vim: noet #
