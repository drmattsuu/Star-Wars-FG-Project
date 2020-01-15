set (_src_root_path "${CMAKE_SOURCE_DIR}/src")
file( GLOB_RECURSE _src_swip
    LIST_DIRECTORIES true
    "${_src_root_path}/*.c*"
    "${_src_root_path}/*.h*"
)

add_executable(StarWarsIndexParser
${_src_swip}
)

target_link_libraries(StarWarsIndexParser
    PUBLIC Boost::filesystem
    PUBLIC Boost::boost
    PUBLIC ${ALL_LIBS}
)

target_include_directories(StarWarsIndexParser
    PRIVATE
    SYSTEM PUBLIC
    ${CMAKE_SOURCE_DIR}/thirdparty/rapidxml-1.13
)

