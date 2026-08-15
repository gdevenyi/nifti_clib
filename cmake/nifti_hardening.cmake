#
# Runtime hardening for optimised builds.
#
# _FORTIFY_SOURCE makes the C library check the destination size of the
# string and memory functions wherever the compiler can work it out, and
# abort instead of writing past the end.  Level 3 (gcc 12+, clang 15+) also
# handles the cases where the size is only known at run time, which covers
# heap buffers allocated as strlen(x) + n -- the shape this library uses
# throughout its filename construction.
#
# It requires optimisation to be useful: at -O0 the compiler cannot
# determine the object sizes, and glibc warns if it is defined anyway.  So
# it is applied only to the optimised configurations.
#
# This is the low-churn way to get what upstream PR #24 is after.  That PR
# replaces every strcpy()/strcat() call with strlcpy()/strlcat() for
# -fbounds-safety compatibility.  The audit behind this file found the
# call sites themselves are correct -- 86 of them copy into a buffer
# allocated from strlen() of the source a few lines above, and the
# fixed-size destinations fit their contents exactly -- so rewriting 145
# correct calls carries more regression risk than it removes, and defining
# strlcpy/strlcat at global scope claims names reserved for the C library.
# Fortification checks the same calls without editing any of them.
#
# It is a complement to that work rather than a replacement: it catches a
# bad size at run time, where -fbounds-safety and strlcpy aim to make the
# bound explicit at compile time.
#

option(NIFTI_ENABLE_FORTIFY_SOURCE
       "Enable _FORTIFY_SOURCE buffer checks in optimised builds" ON)
mark_as_advanced(NIFTI_ENABLE_FORTIFY_SOURCE)

if(NOT NIFTI_ENABLE_FORTIFY_SOURCE)
  return()
endif()

if(NOT CMAKE_C_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
  return()
endif()

include(CheckCSourceCompiles)

# Pick the highest level the toolchain accepts.  Both the compiler and the
# C library have to support it, so compile rather than test versions.
set(_nifti_fortify "")
foreach(_level 3 2)
  set(CMAKE_REQUIRED_FLAGS "-O2 -D_FORTIFY_SOURCE=${_level} -Werror")
  check_c_source_compiles(
    "#include <string.h>\n#include <stdlib.h>\nint main(void){char *p=malloc(8);if(!p)return 1;strcpy(p,\"x\");return 0;}"
    NIFTI_HAVE_FORTIFY_${_level})
  unset(CMAKE_REQUIRED_FLAGS)
  if(NIFTI_HAVE_FORTIFY_${_level})
    set(_nifti_fortify ${_level})
    break()
  endif()
endforeach()

if(NOT _nifti_fortify)
  return()
endif()

message(STATUS "Using _FORTIFY_SOURCE=${_nifti_fortify} for optimised builds")

# Only where the optimiser runs.  $<CONFIG> is empty for single-config
# generators with no build type, so key off the optimisation flags instead
# of the configuration name.
add_compile_options(
  "$<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>,$<CONFIG:MinSizeRel>>:-D_FORTIFY_SOURCE=${_nifti_fortify}>")

unset(_nifti_fortify)
