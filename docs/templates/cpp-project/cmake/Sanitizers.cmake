# Sanitizers and standard library checks. See docs/software-setup.md, "Sanitizers".

# Call this macro before you define targets. It changes the flags of the directory.
macro(starter_prepare_sanitizers)
    if(MSVC AND STARTER_SANITIZERS MATCHES "address")
        # MSVC AddressSanitizer does not work with the run-time checks of /RTC1.
        string(REPLACE "/RTC1" "" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    endif()
    if(MSVC AND STARTER_SANITIZERS MATCHES "undefined|thread")
        message(WARNING "MSVC supports only the address sanitizer. Use clang-cl, WSL2, or Linux for the others.")
    endif()
endmacro()

function(starter_enable_sanitizers target)
    if(STARTER_SANITIZERS STREQUAL "")
        return()
    endif()

    if(MSVC)
        if(STARTER_SANITIZERS MATCHES "address")
            target_compile_options(${target} PRIVATE /fsanitize=address)
            target_link_options(${target} PRIVATE /INCREMENTAL:NO)
        endif()
        return()
    endif()

    list(JOIN STARTER_SANITIZERS "," sanitizer_list)
    target_compile_options(${target} PRIVATE
        -fsanitize=${sanitizer_list}
        -fno-omit-frame-pointer
        -fno-sanitize-recover=all
    )
    target_link_options(${target} PRIVATE -fsanitize=${sanitizer_list})
endfunction()

# Checks of the standard library in debug builds. They find out-of-range access in containers.
add_compile_definitions(
    "$<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:_GLIBCXX_ASSERTIONS>"
)
