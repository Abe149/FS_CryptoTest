#!/usr/bin/env sh

ENABLE_UTF8_IN_FILENAMES=1 # the default; it is _not_ recommended to edit this to turn it off,
                           # since there is only a mechanism in place [a CLI arg.] to DISable Unicode generation,
                           # i.e. a way to override a 1 here with a 0 elsewhere --
                           # there is _no_ mechanism in place to ENable Unicode generation if/when it`s not enabled _here_

DEFAULT_VERBOSITY_LEVEL=1 # do NOT set this to an empty string; do NOT comment this line out or delete it

if [ -z "$VERBOSITY" ]; then VERBOSITY=$DEFAULT_VERBOSITY_LEVEL; fi

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



if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO: in ''$0'': ---"
  stderr_echo "--- INFO:   ''\$@'' :[$@] ---"
  stderr_echo "--- INFO:   ''\$1'' :''$1'' ---" # REQUIRED: base basename [_no_, I did _not_ just now stutter ;-)]
  stderr_echo "--- INFO:   ''\$2'' :''$2'' ---" # REQUIRED: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$3'' :''$3'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$4'' :''$4'' ---" # OPTIONAL: "--name=value"-style arg.
  stderr_echo "--- INFO:   ''\$5'' :''$5'' ---" # OPTIONAL: "--name=value"-style arg.
fi
### "--name=value"-style arg.s supported:
###   * "--compiler[_-]command="<...> : _MANDATORY_,
###     which is why #3 [above] is "REQUIRED":
###       at least one flexible-order arg. must occur [this bullet-point`s such arg.]
###   * "--compiler[_-]flags="<...> [REQUIRED, even if the value is empty] [I made this one required to prevent possible future divergence of replicated fallback_code/fallback_flag_values/both in between this script and "compile.sh"]
###   * "--source[_-]pathname="<...> [for SHA hashing]
###   * "--disable_generation_of_UTF-8_in_computed_basename"
###       only "disable _generation of_ <...>", i.e. not a point-blank "disable <...>",
###       b/c a non-ASCII UTF-8 char. could still appear in the input _base_ basename

if   echo "$1" | grep -q '^-'; then # the first CLI arg. starts with a '-'
  if echo "$1" | grep -Eiq '^(-h|--help)'; then # the first CLI arg. starts with a '-'
    echo 'WIP: help text yet to be written.'
    exit 0 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
  fi

  ### the reason for the next line: it is an error to provide a non-recognized "-<...>" as the first arg. to this program.
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi


if [ -z "$1" -o -z "$2" ]; then
  stderr_echo "--- ERROR: not enough arg.s/param.s given to ''$0'': at least 2 required, 5 supported. ---"
  exit 1 # TO DO: add anti-sourcing protection, if this can be done w/o promoting the minimum shell requirement from "sh" to "bash"
fi

### reminder: due to the way I am using "sed" here,
###           don`t _ever_ put an ASCII slash in _any_ of the values of the "<...>_input_prefix" variables!

alleged_compiler_command=
compiler_input_prefix='--compiler[_-]command='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" | grep -q "^$compiler_input_prefix"; then
    alleged_compiler_command=`echo "$a"| sed s/^$compiler_input_prefix//`
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  alleged_compiler_command=''$alleged_compiler_command'' ---" # reminder: IMPORTANT: in _this_ script, _all_ debug/info/test/whatever output _must_ _not_ go to std. _out_
    fi
  fi
done

flags= # empty by default
flags_have_been_explicitly_set=
flags_input_prefix='--compiler[_-]flags='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" |   grep -q "^$flags_input_prefix"; then
    flags=`echo "$a"| sed s/^$flags_input_prefix//`
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  compiler flags: flags=''$flags'' ---"
    fi
    flags_have_been_explicitly_set=1
  fi
done

pathname= # empty by default
pathname_input_prefix='--source[_-]pathname='
for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" |      grep -q "^$pathname_input_prefix"; then
    pathname=`echo "$a"| sed s/^$pathname_input_prefix//`
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:  source-code pathname: ''$pathname'' ---"
    fi
  fi
done

for a in "$2" "$3" "$4" "$5"; do
  if echo "$a" | grep -q '^--disable_generation_of_UTF-8_in_computed_basename$'; then
    if [ "$VERBOSITY" -gt 2 ]; then
      stderr_echo "--- DEBUG:   disabled UTF-8 [Unicode] generation/conversion ---"
    fi
    ENABLE_UTF8_IN_FILENAMES=0
  fi
done

### [done processing input syntax] ###



if [ -z "$flags_have_been_explicitly_set" ] || [ "$flags_have_been_explicitly_set" -eq 0 ]; then
  stderr_echo "--- ERROR:  this script [$0] _requires_ that its caller give it the compiler flags that are going to be used in compilation, even if that string is a/the empty string."
  exit 1
else
  if [ "$VERBOSITY" -gt 2 ]; then
    stderr_echo "--- INFO:   Using [non-fallback] compiler flags ''$flags''."
  fi
fi
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo   "--- INFO:   Using compiler flags ''$flags''."
fi

compiler_command=$($(dirname "`Q_and_D_readlink_substitute_needed_due_to_lack_of_readlink_in_POSIX "$0"`")/validate_C++_compiler_or_auto-choose_one.sh "$alleged_compiler_command")
if [ "$VERBOSITY" -gt 2 ]; then
  stderr_echo "--- INFO:   Using compiler command ''$compiler_command''. ---"
fi


base_basename="$1"

suffix_to_add=
### note to self: yes, I _know_ the debug-msg. numbers start at 2 ...  "legacy code" ;-)
# stderr_echo "DEBUG 2: suffix_to_add=''$suffix_to_add''"
if "$compiler_command" --version 2>&1 >/dev/null; then # does it "understand" "--version"?  if not, we don`t want an extraneous "___" at the end of the target`s filename
  compiler_version_first_line=`"$compiler_command" --version 2>&1 | head -n 1`
  suffix_to_add="$suffix_to_add   compiler_version=$compiler_version_first_line"
fi
# stderr_echo "DEBUG 3: suffix_to_add=''$suffix_to_add''"
if [ -n "$flags" ]; then
  suffix_to_add="$suffix_to_add   flags_given_to_compiler_driver=$flags" # as opposed to e.g. "implicitly requested by a wrapper script, e.g. a wrapper script that tries to force GCC into ISO-standards-conformance mode"
fi
# stderr_echo "DEBUG 7: suffix_to_add=''$suffix_to_add''"
if is_executable_and_not_a_directory `which sha256sum` && [ -r "$pathname" ]; then
  suffix_to_add="$suffix_to_add   source-code SHA256sum=`sha256sum "$pathname" | cut -f 1 -d ' '`"
fi
# stderr_echo "DEBUG 4: suffix_to_add=''$suffix_to_add''"
suffix_to_add="`sanitize_filename "$suffix_to_add" '\`' ___APOSTROPHE___ '~' ___TILDE___ '!' ___BANG___ '@' ___AT___ '#' ___NUMBER___ '\\$' ___DOLLAR___ % ___PERCENT___ '&' ___AMPERSAND___ '*' ___ASTERISK___ '\[' ___OPEN_BRACKET___ '{' ___OPEN_BRACE___ '\]' ___CLOSE_BRACKET___ '}' ___CLOSE_BRACE___ '\\\' ___BACKSLASH___ '|' ___PIPE___ ';' ___SEMICOLON___ : ___COLON___ "'" ___SINGLE_QUOTE___ '"' ___DOUBLE_QUOTE___ , ___COMMA___ '<' ___LESS_THAN___ '>' ___GREATER_THAN___ / ___SLASH___ '?' ___QUESTION___`" # note: without a backslash preceding it, '$' _does_ match the end of string and does _not_ match '$'  :-P
# stderr_echo "DEBUG 6: suffix_to_add=''$suffix_to_add''"
if [ -n "$ENABLE_UTF8_IN_FILENAMES" ] && [ "$ENABLE_UTF8_IN_FILENAMES" -gt 0 ]; then
  suffix_to_add="`sanitize_filename "$suffix_to_add" '\=' ＝ '(' （ ')' ） ' ' ␠`"
else
  suffix_to_add="`echo "$suffix_to_add" | tr ' ' _`"
fi
# stderr_echo "DEBUG 8: suffix_to_add=''$suffix_to_add''"

echo -n "$base_basename$suffix_to_add"
### <https://en.wikipedia.org/wiki/Uname> ###
if uname -a | grep -Eiq '(Cygwin|MinGW|Interix|UnxUtils|Uwin|winDOwS)'; then
  echo -n .exe
fi
echo
