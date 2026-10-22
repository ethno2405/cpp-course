# The warning set of the course. See docs/software-setup.md, "Warnings".

function(starter_set_warnings target)
    set(msvc_warnings
        /W4
        /permissive-
        /w14062 # a switch does not handle an enumerator
        /w14263 # a member function does not override a base class virtual function
        /w14265 # a class has virtual functions, but its destructor is not virtual
        /w15262 # implicit fall-through in a switch
        /utf-8
        /Zc:__cplusplus
    )

    set(common_warnings
        -Wall
        -Wextra
        -Wpedantic
        -Wshadow
        -Wconversion
        -Wsign-conversion
        -Wnon-virtual-dtor
        -Woverloaded-virtual
        -Wold-style-cast
        -Wimplicit-fallthrough
    )

    set(gcc_warnings
        ${common_warnings}
        -Wduplicated-cond
        -Wduplicated-branches
        -Wlogical-op
    )

    if(STARTER_WARNINGS_AS_ERRORS)
        list(APPEND msvc_warnings /WX)
        list(APPEND common_warnings -Werror)
        list(APPEND gcc_warnings -Werror)
    endif()

    if(MSVC)
        # MSVC and clang-cl both accept the MSVC options.
        target_compile_options(${target} PRIVATE ${msvc_warnings})
        # MSVC marks portable standard C functions (std::fopen, std::getenv) as deprecated
        # (warning C4996). The course code is portable, so it keeps the standard functions.
        target_compile_definitions(${target} PRIVATE _CRT_SECURE_NO_WARNINGS)
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        target_compile_options(${target} PRIVATE ${common_warnings})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${target} PRIVATE ${gcc_warnings})
    else()
        message(WARNING "No warning set for the compiler ${CMAKE_CXX_COMPILER_ID}")
    endif()
endfunction()
