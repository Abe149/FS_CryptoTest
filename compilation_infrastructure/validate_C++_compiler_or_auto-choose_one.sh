#!/usr/bin/env sh

### --- vvv --- functions --- vvv --- ###

## --- load shared functions --- ##
Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX() {
  ls -dl "$1" | sed 's/.* //' # will fail _miserably_ when there`s an ASCII space in the input  :-(
}
. $(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/shared_functions.sh



test_alleged_Cxx_compiler() {
  ### <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/date.html>
  ### the next line`s finely-tuned monstrosity is due to the lack of a suitable "make temporary file" shell API in POSIX version 2008 and later, and is carefully designed to avoid ASCII {spaces and colons}
  prefix=/tmp/compiler-validation_test_files
  mkdir -p $prefix || exit 1 # TO DO: add anti-sourcing protection
  test_file_base_pathname=$prefix/C++_compiler_validation_test_started_at___`date '+%a_%A_%b_%B_%C_%d_%H_%I_%j_%m_%M_%p_%S_%u_%U_%V_%w_%W_%y_%Y_%Z'`
  sleep 1 # unfortunately, POSIX "date" doesn`t seem to provide a {milli/micro/nano}seconds percent-prefixed character API, so we need to make sure that subsequent calls to this function in the same execution don`t execute within the same second

  source_extension=.cpp
  executable_extension=.exe # should work fine on Unix, even though not required "there"

  if [ -e "$test_file_base_pathname""$source_extension" -o -e "$test_file_base_pathname""$executable_extension" ]; then
    echo "FATAL ERROR: either ''$test_file_base_pathname""$source_extension'' or ''$test_file_base_pathname""$executable_extension'' or both already existed."
    exit 1 # TO DO: add anti-sourcing protection
  fi

  cat << THE_END > "$test_file_base_pathname""$source_extension"
#include <iostream>
int main(){std::cout<<"Hello world [from a C++-_only_ -- i.e. _not_ also valid C -- program].\n";}
THE_END

  # EMBEDDED ASSUMPTION on the next line: "-o" _always_ means "output to the following pathname"
  "$1" "$test_file_base_pathname""$source_extension" -o "$test_file_base_pathname""$executable_extension" >&2
  #                ensure any stdout output from the compiler doesn`t pollute this script`s stdout output ^^^

  # EMBEDDED ASSUMPTIONS on the next line: [1] the "file" utility can identify the executable format; [2] the "file" utility`s output for the executable format in use includes the word "executable"
  if file "$test_file_base_pathname""$executable_extension" | grep -iq executable; then
    return 0 # reminder: 0 means "OK" in the context of Unix shell scripting
  else
    return 9
  fi

  # possible TO DO: should we remove the temporary file[s], assuming we successfully created it/them?
}

### --- ^^^ --- functions --- ^^^ --- ###



compiler_command=`which "$1"` # NOTE: simple "$1": no prefix, no nothing
if test -n "$compiler_command" && is_executable_and_not_a_directory "$compiler_command" && test_alleged_Cxx_compiler "$compiler_command"; then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  stderr_echo "--- INFO:   Using provided compiler command ''$1'', found at ''$compiler_command''. ---"
else
  stderr_echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
  old_compiler_command="$compiler_command"

# for alleged_compiler_command in INTENTIONALLY-INVALID_COMMAND_NAME ls c++ CC g++ clang++; do # torture-testing version of the "for" loop header
  for alleged_compiler_command in                                       c++ CC g++ clang++; do
    alleged_compiler_fullPath=`which $alleged_compiler_command`
    if is_executable_and_not_a_directory "$alleged_compiler_fullPath" && test_alleged_Cxx_compiler "$alleged_compiler_fullPath"; then
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
