#!/usr/bin/env sh
echo "--- INFO: in ''$0'': ---"
echo "--- INFO:   ''\$@'' :[$@] ---"
echo "--- INFO:   ''\$1'' :''$1'' ---" # source
echo "--- INFO:   ''\$2'' :''$2'' ---" # destination
echo "--- INFO:   ''\$3'' :''$3'' ---" # alleged compiler-driver command
echo "--- INFO:   ''\$4'' :''$4'' ---" # non-default flags, if any

if [ -z "$1" -o -z "$2" ]; then
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

echo "--- INFO: about to list the old executable, if it exists ---"
ls -l "$2"

is_executable_and_not_a_directory() { # for DRY
  test -x "$1" -a ! -d "$1"
  return $?
}

compiler=`which "$3"`
if test -n "$compiler" && is_executable_and_not_a_directory "$compiler"; then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  echo "--- INFO:   Using provided compiler command ''$3'', found at ''$compiler''. ---"
else
  echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
  old_compiler_command="$compiler"
  for alleged_compiler in c++ CC g++ clang++; do
    alleged_compiler_fullPath=`which $alleged_compiler`
    if is_executable_and_not_a_directory "$alleged_compiler_fullPath"; then
      compiler="$alleged_compiler_fullPath"
      break
    fi
  done
  if [ "$compiler" != "$old_compiler_command" ]; then
    echo "--- INFO:   Auto-chose ''$compiler'' as the compiler command to use. ---"
  fi
fi

# check that by now "$compiler" is valid, and "die" if it isn`t
if ! is_executable_and_not_a_directory "$compiler"; then
  echo "--- ERROR:  No valid compiler command found at ''$compiler''.  Aborting. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

echo "--- INFO:   Using compiler command ''$compiler''. ---"



# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
$compiler "$1" -o "$2"
echo "Compiler exit/result code: $?"

echo "--- INFO: about to list the new executable ---"
ls -l "$2"
