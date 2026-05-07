project(softfloat LANGUAGES C)

include_directories(spike/softfloat)
file(GLOB SOFTFLOAT_SRC spike/softfloat/*.c)

add_library(softfloat STATIC ${SOFTFLOAT_SRC})
set_target_properties(softfloat PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)
target_compile_options(softfloat PRIVATE -Wall -Wextra -Werror -Wno-sign-compare -Wno-implicit-fallthrough)

file(GLOB UNMODIFIED_SOFTFLOAT_SRC unmodified_spike/softfloat/*.c)
add_library(unmodified_softfloat STATIC ${UNMODIFIED_SOFTFLOAT_SRC})
target_include_directories(unmodified_softfloat PRIVATE config_fix)
set_target_properties(unmodified_softfloat PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)
target_compile_options(unmodified_softfloat PRIVATE -Wall -Wextra -Werror -Wno-sign-compare -Wno-implicit-fallthrough -Wno-unused-parameter)
