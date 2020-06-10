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

BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!

# all: $(BUILD_DIR)/FS_CryptoTest # no good  :-(
all: ___not_in_Git/build_dir./FS_CryptoTest # TO DO: more DRY

$(BUILD_DIR):
	mkdir -p $@

build_dir.: ___not_in_Git/build_dir. # TO DO: more DRY
	ln -fs $(BUILD_DIR) .

SOURCE_FILE=FS_CryptoTest.cpp

___not_in_Git/build_dir./FS_CryptoTest: build_dir. $(SOURCE_FILE)
	$(CXX) $(CXXFLAGS) $(SOURCE_FILE) -o build_dir./FS_CryptoTest # embedded assumption: the compiler`s driver "undertands" "-o <...>" to mean "output pathname"



# vim: noet #
