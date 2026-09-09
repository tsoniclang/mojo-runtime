#include <charconv>
#include <cstdlib>
#include <system_error>

extern "C" int tsonic_source_number_digits(double value, char *output) noexcept {
    const auto result = std::to_chars(output, output + 32, value,
                                      std::chars_format::general);
    if (result.ec != std::errc{}) std::abort();
    return static_cast<int>(result.ptr - output);
}
