#pragma once

#include <cstddef>
#include <expected>
#include <string>
#include <string_view>

namespace starter {

// The reasons why make_greeting can fail.
enum class GreetingError {
    empty_name,
    name_too_long,
};

// The maximum length of a name, in bytes.
inline constexpr std::size_t max_name_length = 40;

// Returns "Hello, <name>!".
// Fails if the name is empty or longer than max_name_length bytes.
[[nodiscard]] std::expected<std::string, GreetingError> make_greeting(std::string_view name);

// Returns a message for the user that describes the error.
[[nodiscard]] std::string_view describe(GreetingError error);

} // namespace starter
