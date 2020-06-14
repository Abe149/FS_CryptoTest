.POSIX:

Make_is_beyond_redemption___let_us_say_a_prayer_for_it,_then_lay_it_to_rest: # please don`t create a file/dir. in this dir. with this name
	./build.sh




#   BASE_BASENAME:=FS_CryptoTest
#   SOURCE_FILENAME:=$(BASE_BASENAME).cpp
#   
#   EXECUTABLE_BASENAME:=$(./compile_C++.sh "$(SOURCE_FILENAME)" "$(BASE_BASENAME)" --compiler_command="$(CXX)" --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="$(CXXFLAGS)" --dry-run)
#   
#   all: build_dir./$(EXECUTABLE_BASENAME)
#   
#   REAL_BUILD_DIR=___not_in_Git/build_dir. # important: do _NOT_ add a trailing slash here!
#   
#   $(REAL_BUILD_DIR):
#   	mkdir -p $@
#   
#   build_dir.: $(REAL_BUILD_DIR)
#   	ln -f -s $(REAL_BUILD_DIR) .
#   
#   # CXX_IS_COMPATIBLE_WITH_GCC_FLAGS=`$(CXX) --version | grep -q 'GCC|clang' && echo yes`
#   
#   # build_dir./$(EXECUTABLE_BASENAME): build_dir. $(SOURCE_FILENAME)
#   build_dir./$(EXECUTABLE_BASENAME): Makefile compile_C++.sh $(SOURCE_FILENAME) # removed "build_dir." from the list of prereq.s due to an apparent bug in GNU Make 3.81 [more documentation in a long comment, below]
#   #
#   # the next 2 lines: intentionally repeating myself, to work around what seems to be a bug/error in GNU Make 3.81: in re target prereq.s: even when a symlink-to-a-dir. is _older_ than the target, and only the symlink [i.e. _not_ also its _target_] is specified as a prereq., if the pointed-to directory is _newer_ than the target, a rebuild is triggered; "pmake" seems to handle it correctly
#   	mkdir -p $(REAL_BUILD_DIR)
#   	ln -f -s $(REAL_BUILD_DIR) .
#   #
#   	./compile_C++.sh $(SOURCE_FILENAME) build_dir./$(EXECUTABLE_BASENAME) --compiler_command=$(CXX) --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags=$(CXXFLAGS) --destination_basename_is_already_descriptivized
#   


# vim: noet #
