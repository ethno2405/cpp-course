#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

#include "starter/greeting.hpp"

#include <string>

TEST_CASE("greets a person by name") {
    const auto greeting = starter::make_greeting("Ada");

    REQUIRE(greeting.has_value());
    CHECK(*greeting == "Hello, Ada!");
}

TEST_CASE("rejects an empty name") {
    const auto greeting = starter::make_greeting("");

    REQUIRE_FALSE(greeting.has_value());
    CHECK(greeting.error() == starter::GreetingError::empty_name);
}

TEST_CASE("accepts a name with the maximum length") {
    const std::string name(starter::max_name_length, 'a');

    CHECK(starter::make_greeting(name).has_value());
}

TEST_CASE("rejects a name that is one byte too long") {
    const std::string name(starter::max_name_length + 1, 'a');

    const auto greeting = starter::make_greeting(name);

    REQUIRE_FALSE(greeting.has_value());
    CHECK(greeting.error() == starter::GreetingError::name_too_long);
}
