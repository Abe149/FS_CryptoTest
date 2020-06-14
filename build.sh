#!/usr/bin/env sh

real_build_dir=___not_in_Git/build_dir.
if [ ! -e "$real_build_dir" ]; then mkdir -p "$real_build_dir"; fi

if [ ! -e build_dir. ]; then ln -s "$real_build_dir" build_dir. # restating the target name instead of using '.' just in case the basename of "$real_build_dir" will evey be different from what is needed in the current dir.


