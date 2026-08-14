#!/bin/sh
# Apply (or check) the project code style.
#
#   ./format.sh           reformat every source file in place
#   ./format.sh --check   exit non-zero if any file is not formatted
#
# clang-format's output is not stable across releases, so the version is
# pinned.  Override with CLANG_FORMAT if you have 19.1.7 on your PATH:
#   CLANG_FORMAT=clang-format-19 ./format.sh
set -eu

CLANG_FORMAT_VERSION=19.1.7
: "${CLANG_FORMAT:=}"

if [ -z "$CLANG_FORMAT" ]; then
    if command -v uv > /dev/null 2>&1; then
        CLANG_FORMAT="uv tool run --from clang-format==${CLANG_FORMAT_VERSION} clang-format"
    elif command -v pipx > /dev/null 2>&1; then
        CLANG_FORMAT="pipx run --spec clang-format==${CLANG_FORMAT_VERSION} clang-format"
    else
        echo "error: need uv or pipx to fetch clang-format ${CLANG_FORMAT_VERSION}," >&2
        echo "       or set CLANG_FORMAT to a ${CLANG_FORMAT_VERSION} binary." >&2
        exit 1
    fi
fi

have=$($CLANG_FORMAT --version | sed 's/.*version //')
case "$have" in
    "$CLANG_FORMAT_VERSION"*) ;;
    *) echo "warning: clang-format $have is not the pinned ${CLANG_FORMAT_VERSION};" >&2
       echo "         output may differ from CI." >&2 ;;
esac

# Files deliberately never reformatted.  See the comments in .clang-format.
#   niftilib/nifti1.h, nifti2/nifti1.h  normative NIfTI-1 specification; the
#                                       two-column comment layout is the
#                                       document.  Byte-identical copies.
#   fsliolib/dbh.h                      ANALYZE 7.5 header, (c) Mayo
#                                       Foundation, included verbatim.
is_excluded() {
    case "$1" in
        ./niftilib/nifti1.h|./nifti2/nifti1.h|./fsliolib/dbh.h) return 0 ;;
        *) return 1 ;;
    esac
}

status=0
count=0
for f in $(find . -path ./.git -prune -o \( -name '*.c' -o -name '*.h' \) -print | sort); do
    is_excluded "$f" && continue
    count=$((count + 1))
    if [ "${1:-}" = "--check" ]; then
        if ! $CLANG_FORMAT --style=file "$f" | diff -q "$f" - > /dev/null; then
            echo "not formatted: $f"
            status=1
        fi
    else
        $CLANG_FORMAT --style=file -i "$f"
    fi
done

if [ "${1:-}" = "--check" ]; then
    [ "$status" -eq 0 ] && echo "all $count files are correctly formatted"
    [ "$status" -ne 0 ] && echo "run ./format.sh to fix" >&2
else
    echo "formatted $count files"
fi
exit $status
