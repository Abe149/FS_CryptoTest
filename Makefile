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



all: ___not_in_Git/build_dir./FS_CryptoTest

___not_in_Git/build_dir.:
	mkdir -p $@

build_dir.: ___not_in_Git/build_dir.
	ln -s ___not_in_Git/build_dir. .

SOURCE_FILE=FS_CryptoTest.cpp

___not_in_Git/build_dir./FS_CryptoTest: build_dir. $(SOURCE_FILE)
	$(CXX) $(CXXFLAGS) $(SOURCE_FILE) -o ___not_in_Git/build_dir./FS_CryptoTest # embedded assumption: the compiler`s driver "undertands" "-o <...>" to mean "output pathname"



# vim: noet #
