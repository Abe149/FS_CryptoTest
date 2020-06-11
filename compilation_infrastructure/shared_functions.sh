### note: this file is _intentionally_ not executable, so no shebang line here ###

stderr_echo() { # so I`ll be able to see easily -- esp. in a syntax-highlit view -- which "kind"/"flavor" of output each line uses
  echo "$@" >&2
}

is_executable_and_not_a_directory() {
  test -x "$1" -a ! -d "$1"
  return $?
}
