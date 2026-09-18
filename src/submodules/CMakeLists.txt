add_subdirectory(boost_multiprecision EXCLUDE_FROM_ALL)

file(GLOB SOFTFLOAT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/spike/softfloat/*.c")

add_library(softfloat STATIC ${SOFTFLOAT_SOURCES})
target_compile_options(softfloat PRIVATE
    -Wall
    -Wextra
    -Werror
    -Wno-sign-compare
    -Wno-implicit-fallthrough
)
target_include_directories(softfloat PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/spike")
set_target_properties(softfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)

file(GLOB UNMODIFIED_SOFTFLOAT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/unmodified_spike/softfloat/*.c")

add_library(unmodified_softfloat STATIC ${UNMODIFIED_SOFTFLOAT_SOURCES})
target_compile_options(unmodified_softfloat PRIVATE
    -Wall
    -Wextra
    -Werror
    -Wno-sign-compare
    -Wno-implicit-fallthrough
    -Wno-unused-parameter
)
target_include_directories(unmodified_softfloat
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/unmodified_spike"
        "${CMAKE_CURRENT_SOURCE_DIR}/config_fix"
)
set_target_properties(unmodified_softfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)
