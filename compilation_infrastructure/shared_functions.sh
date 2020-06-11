### note: this file is _intentionally_ not executable, so no shebang line here ###

is_executable_and_not_a_directory() {
  test -x "$1" -a ! -d "$1"
  return $?
}
