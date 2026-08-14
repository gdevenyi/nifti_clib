/* A simple program to test linkage against the niftiio package */

#include <stdlib.h>

#include "nifti1_io.h"

int
main(void)
{
  const char * const name = nifti_datatype_string(DT_FLOAT32);

  return (name != NULL) ? EXIT_SUCCESS : EXIT_FAILURE;
}
