#!/usr/bin/env sh
echo "--- INFO: in ''$0'': ---"
echo "--- INFO:   ''\$@'' :[$@] ---"
echo "--- INFO:   ''\$1'' :''$1'' ---"
echo "--- INFO:   ''\$2'' :''$2'' ---"
echo "--- INFO:   ''\$3'' :''$3'' ---"

compiler=`which "$3"`
if test \( -z "$compiler" \) -o ! \( -x "$compiler" -a ! -d "$compiler" \); then # if the alleged compiler arg. is not provided, or points to something not executable or a directory
  echo '--- INFO:   Going to try to autodetect the C++ compiler command. ---'
else
  echo "--- INFO:   Using provided compiler command ''$3'', found at ''$compiler''. ---"
fi

if test \( -z "$compiler" \) -o ! \( -x "$compiler" -a ! -d "$compiler" \); then
  echo "--- ERROR: No valid compiler command found at ''$compiler''.  Aborting. ---"
  exit 1 # TO DO: add anti-sourcing protection.
fi

# embedded assumption: the compiler`s driver "understands" "-o <...>" to mean "output pathname"
$compiler "$1" -o "$2"
echo "Compiler exit/result code: $?"
