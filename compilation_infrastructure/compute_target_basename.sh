#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
ENABLE_UTF8_IN_FILENAMES=1
### --- ^^^ --- "tuneables" --- ^^^ --- ###



### --- vvv --- functions --- vvv --- ###

## --- load shared functions --- ##
Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX() {
  ls -dl "$1" | sed 's/.* //' # will fail _miserably_ when there`s an ASCII space in the input  :-(
}
. $(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/shared_functions.sh

## --- non-shared functions --- #

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

compiler_command=$($(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/validate_C++_compiler_or_auto-choose_one.sh "$alleged_compiler_command")
stderr_echo "--- INFO:   Using compiler command ''$compiler_command''. ---"
