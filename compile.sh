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

echo "--- INFO:   About to list the old executable, if it exists ---"
echo "--- INFO:     RESULT: OLD EXECUTABLE: `ls -l "$2" 2>&1` ---"

is_executable_and_not_a_directory() { # for DRY
  test -x "$1" -a ! -d "$1"
  return $?
}

# reminder: due to the way I am using "sed" 2 lines from here, don`t _ever_ put an ASCII slash in "COMPILER_INPUT_PREFIX"!
COMPILER_INPUT_PREFIX=--compiler_command=
alleged_compiler_command=
if echo "$3" | grep -q "^$COMPILER_INPUT_PREFIX"; then
  alleged_compiler_command=`echo "$3"| sed s/^$COMPILER_INPUT_PREFIX//`
fi
echo "--- DEBUG:    alleged_compiler_command=''$alleged_compiler_command'' ---"

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
  if "$compiler_command" --version 2>&1 | grep -q 'GCC|clang'; then
    echo WIP1
  else
    echo WIP2
  fi
fi

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
echo '--- INFO:   About to execute "'"$compiler_command"\" \"$1\" -o \"$2\" ---
"$compiler_command" "$1" -o "$2"
echo "--- INFO:     RESULT: Compiler exit/result code: $? ---"

echo "--- INFO:   About to list the new executable ---"
echo "--- INFO:     RESULT: NEW EXECUTABLE: `ls -l "$2" 2>&1` ---"
