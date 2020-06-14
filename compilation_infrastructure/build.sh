#!/usr/bin/env sh

real_build_dir=___not_in_Git/build_dir.
if [ ! -e "$real_build_dir" ]; then mkdir -p "$real_build_dir"; fi

build_dir_symlink_name=Build_dir.
if [ ! -e "$build_dir_symlink_name" ]; then ln -s "$real_build_dir" "$build_dir_symlink_name"; fi

if [ -z "$CXX" ]; then CXX=please_autodetect; fi

base_basename=FS_CryptoTest
source_filename="$base_basename".cpp
executable_basename=`./compile_C++.sh "$source_filename" "$base_basename" --compiler_command="$CXX" --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="$CXXFLAGS" --dry-run`

executable_pathname="$build_dir_symlink_name/$executable_basename"

compile_script_basename=compile_C++.sh

do_compile=

DRY_compare_files_datetimestamps() {
  if [ "$1" -nt "$2" ]; then
    echo "''$1'' is newer than ''$2'', so we must try to recompile."
    do_compile=1
  fi
}

if [ ! -e "$executable_pathname" ]; then
  echo "''$executable_pathname'' does not yet exist, so we must compile."
  do_compile=1
else
  DRY_compare_files_datetimestamps "$source_filename"         "$executable_pathname"
  DRY_compare_files_datetimestamps build.sh                   "$executable_pathname"
  DRY_compare_files_datetimestamps "$compile_script_basename" "$executable_pathname"
fi

if [ -n "$do_compile" ] && [ "$do_compile" -gt 0 ]; then

  echo

  ./"$compile_script_basename" "$source_filename" "$executable_pathname" --compiler_command="$CXX" --compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="$CXXFLAGS" --destination_basename_is_already_descriptivized

else

  echo 'No reason to recompile was detected.  Try something like "VERBOSITY=9 ./build.sh" if you want/need to figure out why [not].'

fi

echo
ls -l "$executable_pathname"
