#include "starter/greeting.hpp"

#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <print>
#include <span>
#include <string_view>

int main(int argc, char* argv[]) {
    const std::span args(argv, static_cast<std::size_t>(argc));
    if (args.size() != 2) {
        std::println(stderr, "usage: starter <name>");
        return EXIT_FAILURE;
    }

    const auto greeting = starter::make_greeting(args[1]);
    if (!greeting) {
        std::println(stderr, "error: {}", starter::describe(greeting.error()));
        return EXIT_FAILURE;
    }

    std::println("{}", *greeting);
    return EXIT_SUCCESS;
}
