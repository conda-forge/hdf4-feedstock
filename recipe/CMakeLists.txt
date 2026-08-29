cmake_minimum_required(VERSION 3.15)
project(hdf4_consumer LANGUAGES C)

find_package(HDF4 CONFIG REQUIRED COMPONENTS C shared)

add_executable(hdf4_consumer test_sd.c)
target_link_libraries(hdf4_consumer PRIVATE ${HDF4_C_SHARED_LIBRARY})
