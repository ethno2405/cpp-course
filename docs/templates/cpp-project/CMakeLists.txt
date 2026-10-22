cmake_minimum_required(VERSION 3.28)

project(starter
    VERSION 0.1.0
    DESCRIPTION "Starter project of the C++ course"
    LANGUAGES CXX
)

# Course rules: C++23, no compiler extensions.
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# clangd and clang-tidy read this file. Only the Ninja and Makefile generators write it.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(STARTER_BUILD_TESTS "Build the tests" ON)
option(STARTER_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)
set(STARTER_SANITIZERS "" CACHE STRING "Sanitizers: empty, 'address;undefined', or 'thread'")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(CompilerWarnings)
include(Sanitizers)
starter_prepare_sanitizers()

# The library holds the logic. The executable and the tests use it.
add_library(starter_core
    src/greeting.cpp
)
target_include_directories(starter_core PUBLIC "${PROJECT_SOURCE_DIR}/include")
starter_set_warnings(starter_core)
starter_enable_sanitizers(starter_core)

add_executable(starter app/main.cpp)
target_link_libraries(starter PRIVATE starter_core)
starter_set_warnings(starter)
starter_enable_sanitizers(starter)

if(STARTER_BUILD_TESTS)
    enable_testing()

    # doctest is vendored: one header, pinned in third_party/README.md.
    set(DOCTEST_HEADER "${PROJECT_SOURCE_DIR}/third_party/doctest/doctest/doctest.h")
    if(NOT EXISTS "${DOCTEST_HEADER}")
        message(FATAL_ERROR
            "doctest is missing: ${DOCTEST_HEADER}\n"
            "Follow third_party/README.md to add it, or configure with -DSTARTER_BUILD_TESTS=OFF.")
    endif()
    add_library(doctest INTERFACE)
    add_library(doctest::doctest ALIAS doctest)
    # SYSTEM: warnings in third-party headers do not stop our build.
    target_include_directories(doctest SYSTEM INTERFACE "${PROJECT_SOURCE_DIR}/third_party/doctest")

    add_executable(starter_tests tests/greeting_tests.cpp)
    target_link_libraries(starter_tests PRIVATE starter_core doctest::doctest)
    starter_set_warnings(starter_tests)
    starter_enable_sanitizers(starter_tests)
    add_test(NAME starter_tests COMMAND starter_tests)
endif()
