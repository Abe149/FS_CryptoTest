#!/usr/bin/env sh

real_build_dir=___not_in_Git/build_dir.
if [ ! -e "$real_build_dir" ]; then mkdir -p "$real_build_dir"; fi

build_dir_symlink_name=build_dir.
if [ ! -e "$build_dir_symlink_name" ]; then ln -s "$real_build_dir" "$build_dir_symlink_name"; fi # restating the target name instead of using '.' just in case the basename of "$real_build_dir" will evey be different from what is needed in the current dir.

if [ -z "$CXX" ]; then CXX=please_autodetect; fi

base_basename=FS_CryptoTest
source_filename="$base_basename".cpp
executable_basename=`./compile_C++.sh "$source_filename" "$base_basename" --compiler_command="$CXX" --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="$CXXFLAGS" --dry-run`

executable_pathname="$build_dir_symlink_name/$executable_basename"

compile_script_basename=compile_C++.sh

do_compile=

if [ ! -e "$executable_pathname" ]; then
  echo "''$executable_pathname'' does not yet exist, so we must compile."
  do_compile=1
else
  if [ "$source_filename" -nt "$executable_pathname" ]; then
    echo "''$source_filename'' is newer than ''$executable_pathname'', so we must compile."
    do_compile=1
  fi
  if [ "$source_filename" -nt build.sh ]; then
    echo "''$source_filename'' is newer than ''build.sh'',"   "so we must compile."
    do_compile=1
  fi
  if [ "$source_filename" -nt "$compile_script_basename" ]; then
    echo "''$source_filename'' is newer than ''$compile_script_basename'',"" so we must compile."
    do_compile=1
  fi
fi

if [ -n "$do_compile" ] && [ "$do_compile" -gt 0 ]; then

  ./"$compile_script_basename" "$source_filename" "$executable_pathname" --compiler_command="$CXX" --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="$CXXFLAGS" --destination_basename_is_already_descriptivized

else

  echo 'No reason to recompile was detected.'

fi
