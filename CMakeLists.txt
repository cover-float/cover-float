cmake_minimum_required(VERSION 3.15)
project(${SKBUILD_PROJECT_NAME} LANGUAGES CXX C)

set(RAW_COVER_FLOAT_FLAGS "${CMAKE_C_FLAGS} -Wextra -Wall -Wno-format -Werror")
separate_arguments(COVER_FLOAT_FLAGS NATIVE_COMMAND "${RAW_COVER_FLOAT_FLAGS}")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra -Wall -Wno-format -Werror")

set(PYBIND11_FINDPYTHON ON)
find_package(pybind11 CONFIG REQUIRED)

add_subdirectory(src/submodules)


# Reference library with rounding result tracking modifications

add_library(coverfloat STATIC src/c/coverfloat.cpp)
target_link_libraries(coverfloat PRIVATE softfloat)
set_target_properties(coverfloat PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)
target_compile_options(coverfloat PRIVATE ${COVER_FLOAT_FLAGS})
target_compile_definitions(coverfloat PRIVATE BOOST_MP_STANDALONE)

target_include_directories(coverfloat PUBLIC src/c)
target_include_directories(coverfloat PUBLIC src/submodules/spike/)
target_include_directories(coverfloat PUBLIC src/submodules/boost_multiprecision/include)


# Softfloat taken directly from spike, without any modifications

add_library(unmodified_coverfloat STATIC src/c/coverfloat.cpp)
target_link_libraries(unmodified_coverfloat PRIVATE unmodified_softfloat)
set_target_properties(unmodified_coverfloat PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)
target_compile_options(unmodified_coverfloat PRIVATE ${COVER_FLOAT_FLAGS})
target_compile_options(unmodified_coverfloat PRIVATE -DUNMODIFIED_SOFTFLOAT)
target_compile_definitions(unmodified_coverfloat PRIVATE BOOST_MP_STANDALONE)

target_include_directories(unmodified_coverfloat PUBLIC src/c)
target_include_directories(unmodified_coverfloat PUBLIC src/submodules/unmodified_spike/)
target_include_directories(unmodified_coverfloat PUBLIC src/submodules/boost_multiprecision/include)
target_include_directories(unmodified_coverfloat PUBLIC src/submodules/config_fix)


# Python Modules

pybind11_add_module(_reference MODULE src/c/reference.cpp)
target_link_libraries(_reference PRIVATE coverfloat)
target_compile_options(_reference PRIVATE ${COVER_FLOAT_FLAGS})

target_include_directories(_reference PRIVATE src/c)

pybind11_add_module(_unmodified_reference MODULE src/c/unmodified_reference.cpp)
target_link_libraries(_unmodified_reference PRIVATE unmodified_coverfloat)
target_compile_options(_unmodified_reference PRIVATE ${COVER_FLOAT_FLAGS})
target_compile_options(_unmodified_reference PRIVATE -DUNMODIFIED_SOFTFLOAT)

install(TARGETS _reference _unmodified_reference DESTINATION ${SKBUILD_PROJECT_NAME})
