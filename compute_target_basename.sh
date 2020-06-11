#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
ENABLE_UTF8_IN_FILENAMES=1
### --- ^^^ --- "tuneables" --- ^^^ --- ###



### --- vvv --- functions --- vvv --- ###

stderr_echo() { # so I`ll be able to see easily -- esp. in a syntax-highlit view -- which "kind"/"flavor" of output each line uses
  echo "$@" >&2
}

is_executable_and_not_a_directory() { # for DRY
  test -x "$1" -a ! -d "$1"
  return $?
}

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

### --- ^^^ --- functions --- ^^^ --- ###



stderr_echo "--- INFO: in ''$0'': ---"
stderr_echo "--- INFO:   ''\$@'' :[$@] ---"
stderr_echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: flags to use when compiler seems compatible with GCC flags [in this position in the {list of args} so as to keep the others at [2, 3, 4] for backwards compatibility with how this code was originally written
stderr_echo "--- INFO:   ''\$2'' :''$2'' ---" # REQUIRED: base basename [_no_, I did _not_ just now stutter ;-)]
stderr_echo "--- INFO:   ''\$3'' :''$3'' ---" # REQUIRED: alleged compiler-driver command
stderr_echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: non-default flags, if any

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  stderr_echo "--- ERROR: not enough arg.s/param.s given to ''$0''. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

flags_to_use_when_compiler_seems_compatible_with_GCC_flags="$1"






# reminder: due to the way I am using "sed" 2 lines from here, don`t _ever_ put an ASCII slash in "COMPILER_INPUT_PREFIX"!
COMPILER_INPUT_PREFIX=--compiler_command=
alleged_compiler_command=
if echo "$3" | grep -q "^$COMPILER_INPUT_PREFIX"; then
  alleged_compiler_command=`echo "$3"| sed s/^$COMPILER_INPUT_PREFIX//`
fi
stderr_echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---" # reminder 1: ">&2" is a "/dev/"-free way to say "redirect to standard _error_"; reminder 2: IMPORTANT: in _this_ script, _all_ debug/info/test/whatever output _must_ not go to std. _out_

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

