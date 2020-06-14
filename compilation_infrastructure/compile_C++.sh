#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS=-O2
DEFAULT_VERBOSITY_LEVEL=1 # do NOT set this to an empty string; do NOT comment this line out or delete it
### --- ^^^ --- "tuneables" --- ^^^ --- ###



if [ -z "$VERBOSITY" ]; then VERBOSITY=$DEFAULT_VERBOSITY_LEVEL; fi

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



if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO: in ''$0'': ---"
  stderr_echo "--- INFO:   ''\$@'' :[$@] ---"
  stderr_echo "--- INFO:   ''\$0'' :''$0'' ---"
  stderr_echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: source
  stderr_echo "--- INFO:   ''\$2'' :''$2'' ---" # REQUIRED: destination
  stderr_echo "--- INFO:   ''\$3'' :''$3'' ---" # REQUIRED: alleged compiler-driver command
  stderr_echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$5'' :''$5'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$6'' :''$6'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$7'' :''$7'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$8'' :''$8'' ---" # OPTIONAL: "--name=value"-style arg.
fi
### "--name=value"-style arg.s supported:
###   * "--compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags="<...>
###   * "--dry[_-]run"
###   * "--destination_basename[_-]is[_-]already[_-]descriptivized"
###   * "--force_replacement_of_old_executable"
###   - "--force[_-]recompilation"

flags= # empty by default
# flags_have_been_explicitly_set= # a remnant of "happier days" from before I realized that Make was sabotaging me yet _again_ :-(
flags_input_prefix='--compiler_flags_to_use_if_nonempty___if_empty_then_try_to_guess_good_flags='
for a in "$4" "$5" "$6" "$7" "$8"; do
  if echo "$a" |   grep -q "^$flags_input_prefix"; then
    flags=`echo "$a"| sed s/^$flags_input_prefix//`
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  compiler flags: flags=''$flags'' ---"
    fi
    # flags_have_been_explicitly_set=1 # a remnant of "happier days" from before I realized that Make was sabotaging me yet _again_ :-(
  fi
done

in_dryRun_mode=
dryRun_arg='--dry[_-]run'
for a in "$4" "$5" "$6" "$7" "$8"; do
  if echo "$a" |   grep -q "^$dryRun_arg\$"; then # the "\$" at the end of the regex: to prevent inputs like "--dry-run=no" from triggering dry-run mode
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  dry-run mode activated [going to figure out flags first, then compute a nice basename for the executable] ---"
    fi
    in_dryRun_mode=1
  fi
done

### this next "feature" [bug? ;-)] only makes sense in _non_-dryRun mode ["wet-run mode?"], but I see no need to issue an error and/or exit early if/when they both appear in the inputs in the same execution
destination_basename_is_already_descriptivized=
already_pretty_arg='--destination_basename[_-]is[_-]already[_-]descriptivized'
for a in "$4" "$5" "$6" "$7" "$8"; do
  if echo "$a" |   grep -q "^$already_pretty_arg\$"; then # the "\$" at the end of the regex: to prevent inputs like "--destination_basename_is_already_descriptivized=no" from "working" in an unwanted way [and breaking "everything" as a result ;-)]
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  caller [Make?] claims that the target basename has already been descriptivized ---"
    fi
    destination_basename_is_already_descriptivized=1
  fi
done

force_replacement_of_old_executable=
force_arg='--force_replacement_of_old_executable'
for a in "$4" "$5" "$6" "$7" "$8"; do
  if echo "$a" |   grep -q "^$force_arg\$"; then # the "\$" at the end of the regex: to prevent inputs ending in something like "=no" from triggering this code
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  force-replacement-of-old-executable mode enabled. ---"
    fi
    force_replacement_of_old_executable=1
  fi
done

force_recompilation=
force_arg='--force[_-]recompilation'
for a in "$4" "$5" "$6" "$7" "$8"; do
  if echo "$a" |   grep -q "^$force_arg\$"; then # the "\$" at the end of the regex: to prevent inputs ending in something like "=no" from triggering this code
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  force-reompilation mode enabled. ---"
    fi
    force_reompilation=1
  fi
done



### TO DO: enable the disabling [?!? ;-)] of Unicode in the target basename
# ENABLE_UTF8_IN_FILENAMES=1

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  stderr_echo "--- ERROR: not enough arg.s/param.s given to ''$0''. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:   About to list the pre-compilation executable, if it exists ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
  stderr_echo "--- INFO:     RESULT: OLD EXECUTABLE: `ls -l "$2" 2>&1` ---"
fi



# reminder: due to the way I am using "sed" 2 lines from here, don`t _ever_ put an ASCII slash in "COMPILER_INPUT_PREFIX"!
COMPILER_INPUT_PREFIX=--compiler_command=
alleged_compiler_command=
if echo "$3" | grep -q "^$COMPILER_INPUT_PREFIX"; then
  alleged_compiler_command=`echo "$3"| sed s/^$COMPILER_INPUT_PREFIX//`
fi
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---"
fi

compiler_command=`which "$alleged_compiler_command"`
if test -n "$compiler_command" && is_executable_and_not_a_directory "$compiler_command"; then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  if [ "$VERBOSITY" -gt 2 ]; then
    stderr_echo "--- INFO:   Using provided compiler command ''$3'', found at ''$compiler_command''. ---"
  fi
else
  if [ "$VERBOSITY" -gt 2 ]; then
    stderr_echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
  fi
  old_compiler_command="$compiler_command"
  for alleged_compiler_command in c++ CC g++ clang++; do
    alleged_compiler_fullPath=`which $alleged_compiler_command`
    if is_executable_and_not_a_directory "$alleged_compiler_fullPath"; then
      compiler_command="$alleged_compiler_fullPath"
      break
    fi
  done
  if [ "$VERBOSITY" -gt 2 ] && [ "$compiler_command" != "$old_compiler_command" ]; then
    stderr_echo "--- INFO:   Auto-chose ''$compiler_command'' as the compiler command to use. ---"
  fi
fi

# check that by now "$compiler_command" is valid, and "die" if it isn`t
if ! is_executable_and_not_a_directory "$compiler_command"; then
  stderr_echo "--- ERROR:  No valid compiler command found at ''$compiler_command''.  Aborting. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:   Using compiler command ''$compiler_command''. ---"
fi

### commented out -- at least for now...  maybe move it down to after dry-run detection, where the output to stdout would be safe? -- so as to enable the "--dry-run" flags [for Make to use when it wants to get a target pathname from this script]
# if "$compiler_command" --version 2>&1 >/dev/null; then
#   echo '--- INFO:   compiler version report: ---'
#   "$compiler_command" --version 2>&1 | grep -v '^$' | sed -e 's/^/--- INFO:     /' -e 's/$/ ---/'
# fi

# if [ -n "$flags_have_been_explicitly_set" -a "$flags_have_been_explicitly_set" -gt 0 ]; then
if [ -n "$flags" ]; then
  if [ "$VERBOSITY" -gt 2 ]; then
    stderr_echo "--- INFO:   Using provided compiler flags ''$flags''."
  fi
else
  if [ "$VERBOSITY" -gt 2 ]; then
    stderr_echo '--- INFO:   Going to try to autodetect suitable compiler flags. ---'
  fi
  if "$compiler_command" --version 2>&1 | grep -q -E '(GCC|clang)'; then
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo '--- INFO:     Detected a compiler driver that _is_ compatible with GCC compiler flags. ---'
    fi
    flags="$FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS"
  else
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo '--- INFO:     Detected a compiler driver that is _not_ compatible with GCC compiler flags. ---'
    fi
  fi
fi
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo   "--- INFO:   Using compiler flags ''$flags''."
fi


real_target_directory="`dirname "$2"`"
target_directory_for_new_files="`dirname "$2"`"/new/
original_target_basename="`basename "$2"`"

if [ -n "$destination_basename_is_already_descriptivized" ] && [ "$destination_basename_is_already_descriptivized" -gt 0 ]; then
  descriptive_basename="$original_target_basename" # in this context, "original" is relative to the current execution of this script
else
  descriptive_basename="`"$my_installation_dir"/compute_C++_target_basename.sh "$original_target_basename" --compiler_command="$compiler_command" --compiler_flags="$flags" --source_pathname="$1"`"
fi
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- DEBUG:  descriptive_basename=''$descriptive_basename''."
fi

if [ -n "$in_dryRun_mode" ] && [ "$in_dryRun_mode" -gt 0 ]; then
  if [ "$VERBOSITY" -gt 1 ]; then
    stderr_echo '--- INFO:     In dry-run mode, so about to output computed destination/target pathname with "prettified" basename, then exit. ---'
  fi
  echo "$real_target_directory/$descriptive_basename"
  exit 0 # WIP: anti-sourcing protection
fi


pathname_of_kludge_dir_to_prevent_excessive_recompilation_attempts="$real_target_directory"/canary_files_for___tracking_last_successful_recompilations___and_for___preventing_excessive_recompilations_due_to_changes_in_the_build-and-compile_scripts

if [ -z "$force_recompilation" ] || [ "$force_recompilation" -lt 1 ]; then
  canary_pathname="$pathname_of_kludge_dir_to_prevent_excessive_recompilation_attempts/$descriptive_basename"
  if [ -e "$canary_pathname" ] && cmp -s "$canary_pathname" "$real_target_directory/$descriptive_basename"; then
    stderr_echo "Found a canary file at ''"$canary_pathname"'' which seems to have the same data-fork content as the target at ''"$real_target_directory/$descriptive_basename"'', so suppressing recompilation."
    stderr_echo
    stderr_echo 'If you want to suppress this suppression, then either:'
    stderr_echo '  * delete/rename/move/mutilate the canary file,'
    stderr_echo '  * use the "--force-recompilation" flag,'
    stderr_echo '  * or, if you are _really_ sadistic, do _both_ of the preceding.'
    stderr_echo
    ls -l "$canary_pathname"
    exit 0 # WIP: anti-sourcing protection
  fi
fi


mkdir -p "$target_directory_for_new_files" || exit 1

target_with_descriptive_name="$target_directory_for_new_files"/"$descriptive_basename"

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo '--- INFO:   About to execute "'"$compiler_command"\" \"$1\" -o \"$target_with_descriptive_name\" \"$flags\" ---
fi
"$compiler_command" "$1" -o "$target_with_descriptive_name" "$flags"
compiler_command_result=$? # we need/want to keep this one "safe" so we can use it in a not-immediately-thereafter context
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:     RESULT: Compiler exit/result code: $compiler_command_result ---"
fi

if [ $compiler_command_result -ne 0 ]; then
  stderr_echo "--- ERROR: compiler exit/result code: $compiler_command_result ---"
  exit $compiler_command_result
fi

pathname_of_new_canary_file="$pathname_of_kludge_dir_to_prevent_excessive_recompilation_attempts/$descriptive_basename"
mkdir -p "$pathname_of_kludge_dir_to_prevent_excessive_recompilation_attempts" && \
ln -v "$target_with_descriptive_name" "$pathname_of_new_canary_file" || \
# if hard-linking doesn`t work, _then_ try copying
cp -f "$target_with_descriptive_name" "$pathname_of_new_canary_file"

if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:   About to list the post-compilation executable [definitely new] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
  stderr_echo "--- INFO:     RESULT: NEW EXECUTABLE: `ls -l "$target_with_descriptive_name" 2>&1` ---"
fi

### overwrite the old executable only if it is different from the new one; compiling in this "careful" way preserves the old timestamp of the old executable if/when the new executable file`s "data fork" is the same as that of the old one ###
cd "$target_directory_for_new_files"
if [ -n "$force_replacement_of_old_executable" ] && [ "$force_replacement_of_old_executable" -gt 0 ]; then
  mv -f "$descriptive_basename" ../
else
  if cmp -s "$descriptive_basename" ../"$descriptive_basename"; then
    stderr_echo '--- NOTICE:    _intentionally_ not updating the build target, so as to preserve its file timestamp, since recompilation produced an identical executable.'
  else
    mv -f "$descriptive_basename" ../
  fi
fi
cd - >/dev/null

if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:   About to list the post-compilation executable [possibly ''old'' if the new one was byte-for-byte identical] ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
  stderr_echo "--- INFO:     RESULT: CURRENT EXECUTABLE: `ls -l "$real_target_directory/$descriptive_basename" 2>&1` ---"
fi

### --- add/refresh the symlink --- ###
### using a symbolic link here should be at-least-mostly-OK, since we are forcing symlink regeneration upon recompilation; using a symlink for this but _not_ doing the forcing part might screw up Make`s ability to detect that the program needs to be recompiled: Make might "think" the program should _always_ be recompiled, i.e. even though the source code hasn`t changed, b/c only the "real executable" had gotten an updated timestamp upon the last recompilation [i.e. the symlink had _not_ been updated at that time]
cd "$real_target_directory"
# ln -f -s "`basename "$target_with_descriptive_name"`" "`basename "$2"`" # preserving this line in case its replacement on the next line ever turns out to be wrong
symlink_name=symlink_to_potentially-old-timestamped_executable_with_same_basename_and_content_as_most-recent_successful_build
rm -f                            "$symlink_name" # this should solve the problem of occassional failures to overwrite an old symlink
ln -f -s "$descriptive_basename" "$symlink_name"
if [ "$VERBOSITY" -gt 0 ]; then
  ls -l "$symlink_name"
fi
cd - >/dev/null
