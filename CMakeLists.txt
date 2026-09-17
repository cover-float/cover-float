cmake_minimum_required(VERSION 3.15)

project(${SKBUILD_PROJECT_NAME} LANGUAGES C CXX)

set(PYBIND11_FINDPYTHON ON)
find_package(pybind11 CONFIG REQUIRED)

add_subdirectory(src)
