#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS=-O2
### --- ^^^ --- "tuneables" --- ^^^ --- ###



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



stderr_echo "--- INFO: in ''$0'': ---"
stderr_echo "--- INFO:   ''\$@'' :[$@] ---"
stderr_echo "--- INFO:   ''\$0'' :''$0'' ---"
stderr_echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: source
stderr_echo "--- INFO:   ''\$2'' :''$2'' ---" # REQUIRED: destination
stderr_echo "--- INFO:   ''\$3'' :''$3'' ---" # REQUIRED: alleged compiler-driver command
stderr_echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: "--name=value"-style arg.
stderr_echo "--- INFO:   ''\$5'' :''$5'' ---" # OPTIONAL: "--name=value"-style arg.
stderr_echo "--- INFO:   ''\$6'' :''$6'' ---" # OPTIONAL: "--name=value"-style arg.
### "--name=value"-style arg.s supported:
###   * "--compiler[_-]flags="<...>
###   * "--dry[_-]run"
###   * "--destination_basename[_-]is[_-]already[_-]descriptivized"

flags= # empty by default
flags_have_been_explicitly_set=
flags_input_prefix='--compiler[_-]flags='
for a in "$4" "$5" "$6"; do
  if echo "$a" |   grep -q "^$flags_input_prefix"; then
    flags=`echo "$a"| sed s/^$flags_input_prefix//`
    stderr_echo "--- DEBUG:  compiler flags: flags=''$flags'' ---"
    flags_have_been_explicitly_set=1
  fi
done

in_dryRun_mode=
dryRun_arg='--dry[_-]run'
for a in "$4" "$5" "$6"; do
  if echo "$a" |   grep -q "^$dryRun_arg\$"; then # the "\$" at the end of the regex: to prevent inputs like "--dry-run=no" from triggering dry-run mode
    stderr_echo "--- DEBUG:  dry-run mode activated [going to figure out flags first, then compute a nice basename for the executable] ---"
    in_dryRun_mode=1
  fi
done

### this next "feature" [bug? ;-)] only makes sense in _non_-dryRun mode ["wet-run mode?"], but I see no need to issue an error and/or exit early if/when they both appear in the inputs in the same execution
destination_basename_is_already_descriptivized=
already_pretty_arg='--destination_basename[_-]is[_-]already[_-]descriptivized'
for a in "$4" "$5" "$6"; do
  if echo "$a" |   grep -q "^$already_pretty_arg\$"; then # the "\$" at the end of the regex: to prevent inputs like "--destination_basename_is_already_descriptivized=no" from "working" in an unwanted way [and breaking "everything" as a result ;-)]
    stderr_echo "--- DEBUG:  caller [Make?] claims that the target basename has already been descriptivized ---"
    destination_basename_is_already_descriptivized=1
  fi
done



### TO DO: enable the disabling [?!? ;-)] of Unicode in the target basename
# ENABLE_UTF8_IN_FILENAMES=1

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  stderr_echo "--- ERROR: not enough arg.s/param.s given to ''$0''. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

stderr_echo "--- INFO:   About to list the pre-compilation executable, if it exists ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
stderr_echo "--- INFO:     RESULT: OLD EXECUTABLE: `ls -l "$2" 2>&1` ---"



# reminder: due to the way I am using "sed" 2 lines from here, don`t _ever_ put an ASCII slash in "COMPILER_INPUT_PREFIX"!
COMPILER_INPUT_PREFIX=--compiler_command=
alleged_compiler_command=
if echo "$3" | grep -q "^$COMPILER_INPUT_PREFIX"; then
  alleged_compiler_command=`echo "$3"| sed s/^$COMPILER_INPUT_PREFIX//`
fi
stderr_echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---"

compiler_command=`which "$alleged_compiler_command"`
if test -n "$compiler_command" && is_executable_and_not_a_directory "$compiler_command"; then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  stderr_echo "--- INFO:   Using provided compiler command ''$3'', found at ''$compiler_command''. ---"
else
  stderr_echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
  old_compiler_command="$compiler_command"
  for alleged_compiler_command in c++ CC g++ clang++; do
    alleged_compiler_fullPath=`which $alleged_compiler_command`
    if is_executable_and_not_a_directory "$alleged_compiler_fullPath"; then
      compiler_command="$alleged_compiler_fullPath"
      break
    fi
  done
  if [ "$compiler_command" != "$old_compiler_command" ]; then
    stderr_echo "--- INFO:   Auto-chose ''$compiler_command'' as the compiler command to use. ---"
  fi
fi

# check that by now "$compiler_command" is valid, and "die" if it isn`t
if ! is_executable_and_not_a_directory "$compiler_command"; then
  stderr_echo "--- ERROR:  No valid compiler command found at ''$compiler_command''.  Aborting. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

stderr_echo "--- INFO:   Using compiler command ''$compiler_command''. ---"

### commented out -- at least for now...  maybe move it down to after dry-run detection, where the output to stdout would be safe? -- so as to enable the "--dry-run" flags [for Make to use when it wants to get a target pathname from this script]
# if "$compiler_command" --version 2>&1 >/dev/null; then
#   echo '--- INFO:   compiler version report: ---'
#   "$compiler_command" --version 2>&1 | grep -v '^$' | sed -e 's/^/--- INFO:     /' -e 's/$/ ---/'
# fi

if [ -n "$flags_have_been_explicitly_set" -a "$flags_have_been_explicitly_set" -gt 0 ]; then
  stderr_echo "--- INFO:   Using provided compiler flags ''$flags''."
else
  stderr_echo '--- INFO:   Going to try to autodetect suitable compiler flags. ---'
  if "$compiler_command" --version 2>&1 | grep -q -E '(GCC|clang)'; then
    stderr_echo '--- INFO:     Detected a compiler driver that _is_ compatible with GCC compiler flags. ---'
    flags="$FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS"
  else
    stderr_echo '--- INFO:     Detected a compiler driver that is _not_ compatible with GCC compiler flags. ---'
  fi
fi
stderr_echo   "--- INFO:   Using compiler flags ''$flags''."


real_target_directory="`dirname "$2"`"
target_directory_for_new_files="`dirname "$2"`"/new/
original_target_basename="`basename "$2"`"

descriptive_basename="`"$my_installation_dir"/compute_C++_target_basename.sh "$original_target_basename" --compiler_command="$compiler_command" --compiler_flags="$flags" --source_pathname="$1"`"



if [ -n "$in_dryRun_mode" ] && [ "$in_dryRun_mode" -gt 0 ]; then
  stderr_echo '--- INFO:     In dry-run mode, so about to output computed destination/target pathname with "prettified" basename, then exit. ---'
  echo "$real_target_directory/$descriptive_basename"
  exit 0
fi



mkdir -p "$target_directory_for_new_files" || exit 1

target_with_descriptive_name="$target_directory_for_new_files"/"$descriptive_basename"

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
stderr_echo '--- INFO:   About to execute "'"$compiler_command"\" \"$1\" -o \"$target_with_descriptive_name\" \"$flags\" ---
"$compiler_command" "$1" -o "$target_with_descriptive_name" "$flags"
compiler_command_result=$? # we need/want to keep this one "safe" so we can use it in a not-immediately-thereafter context
stderr_echo "--- INFO:     RESULT: Compiler exit/result code: $compiler_command_result ---"

if [ $compiler_command_result -ne 0 ]; then
  stderr_echo "--- ERROR: compiler exit/result code: $compiler_command_result ---"
  exit $compiler_command_result
fi

stderr_echo "--- INFO:   About to list the post-compilation executable [definitely new] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
stderr_echo "--- INFO:     RESULT: NEW EXECUTABLE: `ls -l "$target_with_descriptive_name" 2>&1` ---"

### overwrite the old executable only if it is different from the new one; compiling in this "careful" way preserves the old timestamp of the old executable if/when the new executable file`s "data fork" is the same as that of the old one ###
cd "$target_directory_for_new_files"
if cmp -s "$descriptive_basename" ../"$descriptive_basename"; then
  stderr_echo '--- NOTICE:    _intentionally_ not updating the build target, so as to preserve its file timestamp, since recompilation produced an identical executable; this may cause unexpected behavior in the following case: the source code file`s timestamp has been updated -- but that file`s _content_ has not changed -- since the last recompilation with that source-code content, and/or the Makefile has a newer timetamp than that of the relevant executable file; in that case, repeated invocations of "make" will recompile the code, since the newer-but-identical-content executable file will _not_ be used to replace the older-and-identical-content executable file. ---'
else
  mv -f "$descriptive_basename" ../
fi
cd - >/dev/null

stderr_echo "--- INFO:   About to list the post-compilation executable [possibly ''old'' if the new one was byte-for-byte identical] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
stderr_echo "--- INFO:     RESULT: CURRENT EXECUTABLE: `ls -l "$real_target_directory/$descriptive_basename" 2>&1` ---"

### --- add/refresh the symlink --- ###
### using a symbolic link here should be at-least-mostly-OK, since we are forcing symlink regeneration upon recompilation; using a symlink for this but _not_ doing the forcing part might screw up Make`s ability to detect that the program needs to be recompiled: Make might "think" the program should _always_ be recompiled, i.e. even though the source code hasn`t changed, b/c only the "real executable" had gotten an updated timestamp upon the last recompilation [i.e. the symlink had _not_ been updated at that time]
cd "$real_target_directory"
# ln -f -s "`basename "$target_with_descriptive_name"`" "`basename "$2"`" # preserving this line in case its replacement on the next line ever turns out to be wrong
rm -f                            "$original_target_basename" # this should solve the problem of occassional failures to overwrite an old symlink
ln -f -s "$descriptive_basename" "$original_target_basename"
cd - >/dev/null
