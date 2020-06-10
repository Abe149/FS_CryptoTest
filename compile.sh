#!/usr/bin/env sh

### --- vvv --- "tuneables" --- vvv --- ###
FLAGS_TO_USE_WHEN_COMPILER_SEEMS_COMPATIBLE_WITH_GCC_FLAGS=-O2
### --- ^^^ --- "tuneables" --- ^^^ --- ###



echo "--- INFO: in ''$0'': ---"
echo "--- INFO:   ''\$@'' :[$@] ---"
echo "--- INFO:   ''\$1'' :''$1'' ---" # source
echo "--- INFO:   ''\$2'' :''$2'' ---" # destination
echo "--- INFO:   ''\$3'' :''$3'' ---" # alleged compiler-driver command
echo "--- INFO:   ''\$4'' :''$4'' ---" # non-default flags, if any

if [ -z "$1" -o -z "$2" ]; then
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

echo "--- INFO:   About to list the pre-compilation executable, if it exists ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
echo "--- INFO:     RESULT: OLD EXECUTABLE: `ls -l "$2" 2>&1` ---"



### --- vvv --- functions --- vvv --- ###

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


target_directory="`dirname "$2"`"
original_target_basename="`basename "$2"`"

descriptive_basename="$original_target_basename"___compiler_driver_basename=`basename "$compiler_command"`
# echo "DEBUG 2: descriptive_basename=''$descriptive_basename''"
if "$compiler_command" --version 2>&1 >/dev/null; then # does it "understand" "--version"?  if not, we don`t want an extraneous "___" at the end of the target`s filename
  compiler_version_first_line=`"$compiler_command" --version 2>&1 | head -n 1`
  descriptive_basename="$descriptive_basename"___compiler_version="$compiler_version_first_line"
fi
echo "DEBUG 3: descriptive_basename=''$descriptive_basename''"
descriptive_basename="$descriptive_basename"___explicit_compiler_flags="$flags" # "explicit" as opposed to e.g. "implicitly requested by a wrapper script, e.g. a wrapper script that tries to force GCC into ISO-standards-conformance mode"
echo "DEBUG 4: descriptive_basename=''$descriptive_basename''"
descriptive_basename=`sanitize_filename "$descriptive_basename" ' ' _ '\`' ___APOSTROPHE___ '~' ___TILDE___ '!' ___BANG___ '@' ___AT___ '#' ___NUMBER___ '\\$' ___DOLLAR___ % ___PERCENT___ '&' ___AMPERSAND___ '*' ___ASTERISK___ '\[' ___OPEN_BRACKET___ '{' ___OPEN_BRACE___ '\]' ___CLOSE_BRACKET___ '}' ___CLOSE_BRACE___ '\\\' ___BACKSLASH___ '|' ___PIPE___ ';' ___SEMICOLON___ : ___COLON___ "'" ___SINGLE_QUOTE___ '"' ___DOUBLE_QUOTE___ , ___COMMA___ '<' ___LESS_THAN___ '>' ___GREATER_THAN___ / ___SLASH___ '?' ___QUESTION___` # note: without a backslash preceding it, '$' _does_ match the end of string and does _not_ match '$'  :-P
echo "DEBUG 5: descriptive_basename=''$descriptive_basename''"
caller=`ps -o comm "$PPID" | tail -n 1`
descriptive_basename="$descriptive_basename"___caller_of_compile.sh="$caller"
echo "DEBUG 6: descriptive_basename=''$descriptive_basename''"

target_with_descriptive_name="$target_directory"/"$descriptive_basename"

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output to this pathname"
echo '--- INFO:   About to execute "'"$compiler_command"\" \"$1\" -o \"$2\" ---
"$compiler_command" "$1" -o "$target_with_descriptive_name"
echo "--- INFO:     RESULT: Compiler exit/result code: $? ---"

echo "--- INFO:   About to list the post-compilation executable ---" # changed verbiage from "new executable" in case of unlikely situations like {executable already existed at start, but was read-only and/or locked, so not overwritten}
echo "--- INFO:     RESULT: NEW EXECUTABLE: `ls -l "$target_with_descriptive_name" 2>&1` ---"
# using a symbolic link here should be at-least-mostly-OK, since we are forcing symlink regeneration upon recompilation; using a symlink for this but _not_ doing the forcing part might screw up Make`s ability to detect that the program needs to be recompiled: Make might "think" the program should _always_ be recompiled, i.e. even though the source code hasn`t changed, b/c only the "real executable" had gotten an updated timestamp upon the last recompilation [i.e. the symlink had _not_ been updated at that time]
cd `dirname "$2"`
# ln -f -s "`basename "$target_with_descriptive_name"`" "`basename "$2"`" # preserving this line in case its replacement on the next line ever turns out to be wrong
  ln -f -s "$descriptive_basename" "$original_target_basename"
cd - >/dev/null
