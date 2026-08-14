#
# Compiler warning flags shared by every nifti_clib target.
#
# The set is deliberately chosen to be one the project can hold at zero, so
# that a new warning means a new defect rather than more noise.  Adding a
# flag here is a commitment to keep the tree clean under it.
#
# Deliberately NOT enabled, with reasons:
#
#   -Wdouble-promotion   ~240 hits.  Silencing them means calling sqrtf()
#                        and friends instead of sqrt(), which changes the
#                        numerical results of the quaternion and matrix
#                        code.  Not a formatting-era decision to take.
#   -Wfloat-equal        ~150 hits.  Most are deliberate tests against an
#                        exact 0.0 or a sentinel, which is correct here.
#   -Wconversion         Largely subsumed by -Wsign-conversion, and the
#                        remainder overlaps -Wdouble-promotion above.
#   -Wunsafe-buffer-usage clang-only, and aimed at C++ span/array types
#                        that do not exist in this codebase.
#
# Warnings are NOT errors by default; set NIFTI_WARNINGS_AS_ERRORS=ON to
# make CI fail on them.
#

option(NIFTI_ENABLE_WARNINGS "Enable the project's compiler warning set" ON)
option(NIFTI_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
mark_as_advanced(NIFTI_ENABLE_WARNINGS NIFTI_WARNINGS_AS_ERRORS)

if(NOT NIFTI_ENABLE_WARNINGS)
  return()
endif()

set(_nifti_warnings "")

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
  list(APPEND _nifti_warnings
    -Wall
    -Wextra
    -Wpedantic
    -Wcast-qual           # casting away const or volatile
    -Wformat=2            # printf/scanf format checking, including nonliteral
    -Wmissing-declarations
    -Wmissing-prototypes  # an exported function with no visible prototype
    -Wnull-dereference
    -Wpointer-arith       # arithmetic on void * or function pointers
    -Wredundant-decls
    -Wshadow
    -Wsign-conversion
    -Wstrict-prototypes
    -Wswitch-enum
    -Wundef               # #if on an undefined identifier
    -Wvla                 # variable length arrays
    -Wwrite-strings       # string literals are const
  )
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  list(APPEND _nifti_warnings
    -Wcast-align=strict   # clang spells this -Wcast-align
    -Wduplicated-branches
    -Wduplicated-cond
    -Wjump-misses-init
    -Wlogical-op
    -Wold-style-definition
  )
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang")
  list(APPEND _nifti_warnings
    -Wcast-align
    -Wcomma
    -Wconditional-uninitialized   # used on some path without being set
    -Wextra-semi-stmt
    -Wmissing-variable-declarations
    -Wnewline-eof
    -Wshorten-64-to-32
  )
elseif(MSVC)
  list(APPEND _nifti_warnings /W3)
endif()

if(NIFTI_WARNINGS_AS_ERRORS)
  if(MSVC)
    list(APPEND _nifti_warnings /WX)
  else()
    list(APPEND _nifti_warnings -Werror)
  endif()
endif()

add_compile_options(${_nifti_warnings})
unset(_nifti_warnings)
