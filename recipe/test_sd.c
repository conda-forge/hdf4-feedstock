#include <string.h>

#include <mfhdf.h>

int main(void) {
  int32 dimensions[1] = {4};
  int32 start[1] = {0};
  int32 edges[1] = {4};
  int32 expected[4] = {3, 1, 4, 1};
  int32 actual[4] = {0, 0, 0, 0};
  int32 file_id;
  int32 dataset_id;

  file_id = SDstart("hdf4-consumer.hdf", DFACC_CREATE);
  if (file_id == FAIL) {
    return 1;
  }

  dataset_id = SDcreate(file_id, "values", DFNT_INT32, 1, dimensions);
  if (dataset_id == FAIL
      || SDwritedata(dataset_id, start, NULL, edges, expected) == FAIL
      || SDendaccess(dataset_id) == FAIL
      || SDend(file_id) == FAIL) {
    return 1;
  }

  file_id = SDstart("hdf4-consumer.hdf", DFACC_READ);
  if (file_id == FAIL) {
    return 1;
  }

  dataset_id = SDselect(file_id, 0);
  if (dataset_id == FAIL
      || SDreaddata(dataset_id, start, NULL, edges, actual) == FAIL
      || SDendaccess(dataset_id) == FAIL
      || SDend(file_id) == FAIL) {
    return 1;
  }

  return memcmp(actual, expected, sizeof(expected)) == 0 ? 0 : 1;
}
