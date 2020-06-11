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
stderr_echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: base basename [_no_, I did _not_ just now stutter ;-)]
stderr_echo "--- INFO:   ''\$2'' :''$2'' ---" # OPTIONAL: "--name=value"-style arg.
stderr_echo "--- INFO:   ''\$3'' :''$3'' ---" # OPTIONAL: "--name=value"-style arg.
stderr_echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: "--name=value"-style arg.
stderr_echo "--- INFO:   ''\$5'' :''$5'' ---" # OPTIONAL: "--name=value"-style arg.
### "--name=value"-style arg.s supported:
###   * "--compiler[_-]command="<...> : _MANDATORY_,
###     which is why #3 [above] is "REQUIRED":
###       at least one flexible-order arg. must occur [this bullet-point`s such arg.]
###   * "--compiler[_-]flags="<...>
###   * "--source[_-]pathname="<...> [for SHA512 hashing]
###   * "--fallback_GCC-compatible_flags="<...>

if [ -z "$1" ]; then
  stderr_echo "--- ERROR: not enough arg.s/param.s given to ''$0'': at least 1 required, 5 supported. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

### reminder: due to the way I am using "sed" here,
###           don`t _ever_ put an ASCII slash in _any_ of the values of the "<...>_INPUT_PREFIX" variables!

alleged_compiler_command=
compiler_input_prefix='--compiler[_-]command='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" | grep -q "^$compiler_input_prefix"; then
    alleged_compiler_command=`echo "$a"| sed s/^$compiler_input_prefix//`
    stderr_echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---" # reminder: IMPORTANT: in _this_ script, _all_ debug/info/test/whatever output _must_ _not_ go to std. _out_
  fi
done

flags= # empty by default
flags_have_been_explicitly_set=
flags_input_prefix='--compiler[_-]flags='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" |   grep -q "^$flags_input_prefix"; then
    flags=`echo "$a"| sed s/^$flags_input_prefix//`
    stderr_echo "--- DEBUG:  requested compiler flags: flags=''$flags'' ---"
    flags_have_been_explicitly_set=1
  fi
done

pathname= # empty by default
pathname_input_prefix='--source[_-]pathname='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" |      grep -q "^$pathname_input_prefix"; then
    pathname=`echo "$a"| sed s/^$pathname_input_prefix//`
    stderr_echo "--- DEBUG:  source-code pathname: ''$pathname'' ---"
  fi
done

fallback_GCCcompatible_flags= # empty by default
fallback_GCCcompatible_flags_input_prefix='--fallback_GCC-compatible_flags' # _intentionally_ no {'_' vs. '-'} flexibility on _this_ one
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" |      grep -q "^$fallback_GCCcompatible_flags_input_prefix"; then
    fallback_GCCcompatible_flags=`echo "$a"| sed s/^$fallback_GCCcompatible_flags_input_prefix//`
    stderr_echo "--- DEBUG:   fallback_GCCcompatible_flags=''$fallback_GCCcompatible_flags'' ---"
  fi
done

### [done processing input syntax] ###



compiler_command=$($(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/validate_C++_compiler_or_auto-choose_one.sh "$alleged_compiler_command")
stderr_echo "--- INFO:   Using compiler command ''$compiler_command''. ---"

if [ -z "$flags_have_been_explicitly_set" ] || [ "$flags_have_been_explicitly_set" -eq 0 ]; then
  stderr_echo '--- INFO:   Going to try to autodetect suitable compiler flags. ---'
  if "$compiler_command" --version 2>&1 | grep -q -E '(GCC|clang)'; then
    stderr_echo '--- INFO:     Detected a compiler driver that _is_ compatible with GCC compiler flags. ---'
    flags="$fallback_GCCcompatible_flags"
  else
    stderr_echo '--- INFO:     Detected a compiler driver that is _not_ compatible with GCC compiler flags. ---'
  fi
else
  stderr_echo "--- INFO:   Using provided compiler flags ''$flags''."
fi
stderr_echo   "--- INFO:   Using compiler flags ''$flags''."


base_basename="$1"

descriptive_basename="$base_basename"
# note to self: yes, I _know_ the debug-msg. numbers start at 2 ...  "legacy code" ;-)
stderr_echo "DEBUG 2: descriptive_basename=''$descriptive_basename''"
if "$compiler_command" --version 2>&1 >/dev/null; then # does it "understand" "--version"?  if not, we don`t want an extraneous "___" at the end of the target`s filename
  compiler_version_first_line=`"$compiler_command" --version 2>&1 | head -n 1`
  descriptive_basename="$descriptive_basename"___compiler_version="$compiler_version_first_line"
fi
stderr_echo "DEBUG 3: descriptive_basename=''$descriptive_basename''"
if [ -n "$flags" ]; then
  descriptive_basename="$descriptive_basename"___flags_given_to_compiler_driver_command="$flags" # as opposed to e.g. "implicitly requested by a wrapper script, e.g. a wrapper script that tries to force GCC into ISO-standards-conformance mode"
fi
stderr_echo "DEBUG 4: descriptive_basename=''$descriptive_basename''"
descriptive_basename="`sanitize_filename "$descriptive_basename" ' ' _ '\`' ___APOSTROPHE___ '~' ___TILDE___ '!' ___BANG___ '@' ___AT___ '#' ___NUMBER___ '\\$' ___DOLLAR___ % ___PERCENT___ '&' ___AMPERSAND___ '*' ___ASTERISK___ '\[' ___OPEN_BRACKET___ '{' ___OPEN_BRACE___ '\]' ___CLOSE_BRACKET___ '}' ___CLOSE_BRACE___ '\\\' ___BACKSLASH___ '|' ___PIPE___ ';' ___SEMICOLON___ : ___COLON___ "'" ___SINGLE_QUOTE___ '"' ___DOUBLE_QUOTE___ , ___COMMA___ '<' ___LESS_THAN___ '>' ___GREATER_THAN___ / ___SLASH___ '?' ___QUESTION___`" # note: without a backslash preceding it, '$' _does_ match the end of string and does _not_ match '$'  :-P
stderr_echo "DEBUG 5: descriptive_basename=''$descriptive_basename''"
### re the next 2 lines of code: this works well with GNU Make on Debian 7 ["<...>___caller_of_compile.sh=make"], but _badly_ with "pmake" [also on Debian 7]: "<...>___caller_of_compile.sh=sh"
# caller=`ps -o comm "$PPID" | tail -n 1`
# descriptive_basename="$descriptive_basename"___caller_of_compile.sh="$caller"
stderr_echo "DEBUG 6: descriptive_basename=''$descriptive_basename''"
if is_executable_and_not_a_directory `which sha512sum` && [ -r "$pathname" ]; then
  descriptive_basename="$descriptive_basename"___source_code_SHA512sum="`sha512sum "$pathname" | cut -f 1 -d ' '`"
fi
stderr_echo "DEBUG 7: descriptive_basename=''$descriptive_basename''"
if [ -n "$ENABLE_UTF8_IN_FILENAMES" ] && [ "$ENABLE_UTF8_IN_FILENAMES" -gt 0 ]; then
descriptive_basename="`sanitize_filename "$descriptive_basename" '\=' ＝ '(' （ ')' ）`"
fi
stderr_echo "DEBUG 8: descriptive_basename=''$descriptive_basename''"

echo "$descriptive_basename"
