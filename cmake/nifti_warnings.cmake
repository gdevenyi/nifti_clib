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
#   -Wsign-conversion    219 hits, and not a warning this codebase can be
#                        made clean under by casting.  108 of them are in
#                        allocation, copy-length or seek positions --
#                        malloc(nbricks * sizeof ...), memcpy(..., len),
#                        znzseek(..., slbytes * slice) -- where the whole
#                        point of the diagnostic is that a negative value
#                        becomes an enormous unsigned one.  Adding a cast
#                        at each site removes the diagnostic and leaves
#                        the defect, which is worse than not enabling it.
#                        Making it clean means auditing all 219 and adding
#                        range validation, which changes error-return
#                        behaviour and so belongs in its own piece of work.
#                        Enable NIFTI_ENABLE_SIGN_CONVERSION_WARNINGS to
#                        do that audit.
#
# Warnings are NOT errors by default; set NIFTI_WARNINGS_AS_ERRORS=ON to
# make CI fail on them.
#

option(NIFTI_ENABLE_WARNINGS "Enable the project's compiler warning set" ON)
option(NIFTI_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
option(NIFTI_ENABLE_SIGN_CONVERSION_WARNINGS
       "Also warn on implicit signed/unsigned conversions (219 known hits)" OFF)
mark_as_advanced(NIFTI_ENABLE_WARNINGS NIFTI_WARNINGS_AS_ERRORS
                 NIFTI_ENABLE_SIGN_CONVERSION_WARNINGS)

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

if(NIFTI_ENABLE_SIGN_CONVERSION_WARNINGS AND NOT MSVC)
  list(APPEND _nifti_warnings -Wsign-conversion)
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
