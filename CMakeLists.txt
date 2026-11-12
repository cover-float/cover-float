cmake_minimum_required(VERSION 3.15)

project(${SKBUILD_PROJECT_NAME} LANGUAGES C CXX)

# Release wheels turn this off, so that new compiler warnings do not break the build.
option(COVER_FLOAT_WERROR "Treat compiler warnings as errors" ON)
if(COVER_FLOAT_WERROR)
    set(cover_float_werror -Werror)
endif()

set(PYBIND11_FINDPYTHON ON)
find_package(pybind11 CONFIG REQUIRED)

add_subdirectory(src)
