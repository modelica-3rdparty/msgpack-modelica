# Builds the msgpack-c library the MessagePack Modelica package needs, and
# installs it where a Modelica tool asked for it:
#
#   cmake -DCMAKE_INSTALL_PREFIX=<dir> -DCMAKE_INSTALL_LIBDIR=. .
#   cmake --build . --target install
#
# BUILD_SHARED_LIBS decides the form. OpenModelica turns it on together with its
# wasm32-wasip1 toolchain file, because a wasm target loads the library as a
# module instead of linking it.
#
# msgpack-c's own CMake project is not used: its declared minimum is older than
# CMake 4 accepts. Files.cmake is its source list, so this stays in step with it.
cmake_minimum_required(VERSION 3.11...3.31)
project(msgpack-modelica VERSION 0.1.1 LANGUAGES C)

set(MSGPACK_C_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../C-Sources/msgpack-c")
include("${MSGPACK_C_DIR}/Files.cmake")

set(msgpackc_ABS_SOURCES "")
foreach(src IN LISTS msgpackc_SOURCES)
  list(APPEND msgpackc_ABS_SOURCES "${MSGPACK_C_DIR}/${src}")
endforeach()

add_library(msgpackc ${msgpackc_ABS_SOURCES})
target_include_directories(msgpackc PUBLIC "${MSGPACK_C_DIR}/include")
# The archive is linked into shared objects, so its members have to be PIC.
set_target_properties(msgpackc PROPERTIES POSITION_INDEPENDENT_CODE ON)

include(GNUInstallDirs)
install(TARGETS msgpackc
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
