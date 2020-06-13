#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS=-O2
ENABLE_UTF8_IN_FILENAMES=1
### --- ^^^ --- "tuneables" --- ^^^ --- ###



echo "--- INFO: in ''$0'': ---"
echo "--- INFO:   ''\$@'' :[$@] ---"
echo "--- INFO:   ''\$0'' :''$0'' ---"
echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: source
echo "--- INFO:   ''\$2'' :''$2'' ---" # REQUIRED: destination
echo "--- INFO:   ''\$3'' :''$3'' ---" # REQUIRED: alleged compiler-driver command
echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: non-default flags, if any

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  echo "--- ERROR: not enough arg.s/param.s given to ''$0''. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

echo "--- INFO:   About to list the pre-compilation executable, if it exists ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
echo "--- INFO:     RESULT: OLD EXECUTABLE: `ls -l "$2" 2>&1` ---"



Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX() {
# ls -dl "$1" | sed 's/^.* -> //' # will fail _miserably_ when processing the valid input '.'
  ls -dl "$1" | sed 's/.* //'     # will fail _miserably_ when there`s an ASCII space in the input
  # re the preceding 2 lines of code [incl. 1 commented out]: herein, we seem to be damned if we do and damned if we don`t
}

my_installation_dir="$(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")"

. "$my_installation_dir"/shared_functions.sh

sanitize_filename() {
  filename="$1"
  shift
  while [ $# -ge 2 ]; do
    # echo "DEBUG: “$1” “$2” “$filename”" > /dev/stderr
    filename=`echo "$filename" | sed s="$1"="$2"=g` # instead of using '/' in the "sed" script here, we _must_ use a char. that will _never_ be "sanitized out" -- _or_ used in the replacement string!  oof.  maybe '=' will work well.  :-P
    shift 2
  done
  echo "$filename"
}



# reminder: due to the way I am using "sed" 2 lines from here, don`t _ever_ put an ASCII slash in "COMPILER_INPUT_PREFIX"!
COMPILER_INPUT_PREFIX=--compiler_command=
alleged_compiler_command=
if echo "$3" | grep -q "^$COMPILER_INPUT_PREFIX"; then
  alleged_compiler_command=`echo "$3"| sed s/^$COMPILER_INPUT_PREFIX//`
fi
echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---"

compiler_command=`which "$alleged_compiler_command"`
if test -n "$compiler_command" && is_executable_and_not_a_directory "$compiler_command"; then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  echo "--- INFO:   Using provided compiler command ''$3'', found at ''$compiler_command''. ---"
else
  echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
  old_compiler_command="$compiler_command"
  for alleged_compiler_command in c++ CC g++ clang++; do
    alleged_compiler_fullPath=`which $alleged_compiler_command`
    if is_executable_and_not_a_directory "$alleged_compiler_fullPath"; then
      compiler_command="$alleged_compiler_fullPath"
      break
    fi
  done
  if [ "$compiler_command" != "$old_compiler_command" ]; then
    echo "--- INFO:   Auto-chose ''$compiler_command'' as the compiler command to use. ---"
  fi
fi

# check that by now "$compiler_command" is valid, and "die" if it isn`t
if ! is_executable_and_not_a_directory "$compiler_command"; then
  echo "--- ERROR:  No valid compiler command found at ''$compiler_command''.  Aborting. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

echo "--- INFO:   Using compiler command ''$compiler_command''. ---"

if "$compiler_command" --version 2>&1 >/dev/null; then
  echo '--- INFO:   compiler version report: ---'
  "$compiler_command" --version 2>&1 | grep -v '^$' | sed -e 's/^/--- INFO:     /' -e 's/$/ ---/'
fi

flags="$4"
if test -z "$flags"; then
  echo '--- INFO:   Going to try to autodetect suitable compiler flags. ---'
  if "$compiler_command" --version 2>&1 | grep -q -E '(GCC|clang)'; then
    echo '--- INFO:     Detected a compiler driver that _is_ compatible with GCC compiler flags. ---'
    flags="$FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS"
  else
    echo '--- INFO:     Detected a compiler driver that is _not_ compatible with GCC compiler flags. ---'
  fi
else
  echo "--- INFO:   Using provided compiler flags ''$flags''."
fi
echo   "--- INFO:   Using compiler flags ''$flags''."


real_target_directory="`dirname "$2"`"
target_directory_for_new_files="`dirname "$2"`"/new/
original_target_basename="`basename "$2"`"

mkdir -p "$target_directory_for_new_files" || exit 1

descriptive_basename="`"$my_installation_dir"/compute_C++_target_basename.sh "$original_target_basename"`"

target_with_descriptive_name="$target_directory_for_new_files"/"$descriptive_basename"

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
echo '--- INFO:   About to execute "'"$compiler_command"\" \"$1\" -o \"$target_with_descriptive_name\" ---
"$compiler_command" "$1" -o "$target_with_descriptive_name"
echo "--- INFO:     RESULT: Compiler exit/result code: $? ---"

echo "--- INFO:   About to list the post-compilation executable [definitely new] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
echo "--- INFO:     RESULT: NEW EXECUTABLE: `ls -l "$target_with_descriptive_name" 2>&1` ---"

### overwrite the old executable only if it is different from the new one; compiling in this "careful" way preserves the old timestamp of the old executable if/when the new executable file`s "data fork" is the same as that of the old one ###
cd "$target_directory_for_new_files"
cmp -s "$descriptive_basename" ../"$descriptive_basename" || mv -f "$descriptive_basename" ../
cd - >/dev/null

echo "--- INFO:   About to list the post-compilation executable [possibly ''old'' if the new one was byte-for-byte identical] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
echo "--- INFO:     RESULT: CURRENT EXECUTABLE: `ls -l "$real_target_directory/$descriptive_basename" 2>&1` ---"

### --- add/refresh the symlink --- ###
### using a symbolic link here should be at-least-mostly-OK, since we are forcing symlink regeneration upon recompilation; using a symlink for this but _not_ doing the forcing part might screw up Make`s ability to detect that the program needs to be recompiled: Make might "think" the program should _always_ be recompiled, i.e. even though the source code hasn`t changed, b/c only the "real executable" had gotten an updated timestamp upon the last recompilation [i.e. the symlink had _not_ been updated at that time]
cd "$real_target_directory"
# ln -f -s "`basename "$target_with_descriptive_name"`" "`basename "$2"`" # preserving this line in case its replacement on the next line ever turns out to be wrong
  ln -f -s "$descriptive_basename" "$original_target_basename"
cd - >/dev/null
