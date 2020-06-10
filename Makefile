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

all: FS_CryptoTest
