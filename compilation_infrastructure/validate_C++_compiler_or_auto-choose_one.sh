#!/usr/bin/env sh

### --- vvv --- functions --- vvv --- ###

## --- load shared functions --- ##
Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX() {
  ls -dl "$1" | sed 's/.* //' # will fail _miserably_ when there`s an ASCII space in the input  :-(
}
. $(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/shared_functions.sh

### --- ^^^ --- functions --- ^^^ --- ###



compiler_command=`which "$1"` # NOTE: simple "$1": no prefix, no nothing
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

stderr_echo "--- INFO:   Recommending compiler command ''$compiler_command''. ---"

echo "$compiler_command" # the "real" output


