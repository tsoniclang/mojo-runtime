#include <gmp.h>
#include <cstdlib>
#include <cstdint>
#include <limits>

struct TsonicBigInt {
    mpz_t value;
    TsonicBigInt() { mpz_init(value); }
    ~TsonicBigInt() { mpz_clear(value); }
    TsonicBigInt(const TsonicBigInt &) = delete;
    TsonicBigInt &operator=(const TsonicBigInt &) = delete;
};

extern "C" TsonicBigInt *tsonic_bigint_parse(const char *digits) noexcept {
    auto *result = new TsonicBigInt();
    if (mpz_set_str(result->value, digits, 10) != 0) {
        delete result;
        return nullptr;
    }
    return result;
}

extern "C" void tsonic_bigint_destroy(TsonicBigInt *value) noexcept {
    delete value;
}

extern "C" char *tsonic_bigint_digits(const TsonicBigInt *value) noexcept {
    const auto size = mpz_sizeinbase(value->value, 10);
    if (size > std::numeric_limits<std::size_t>::max() - 2) std::abort();
    auto *digits = static_cast<char *>(std::malloc(size + 2));
    if (digits == nullptr) std::abort();
    mpz_get_str(digits, 10, value->value);
    return digits;
}

extern "C" void tsonic_bigint_free_digits(char *digits) noexcept {
    std::free(digits);
}

extern "C" int tsonic_bigint_compare(const TsonicBigInt *left,
                                    const TsonicBigInt *right) noexcept {
    return mpz_cmp(left->value, right->value);
}

extern "C" int tsonic_bigint_sign(const TsonicBigInt *value) noexcept {
    return mpz_sgn(value->value);
}

extern "C" int tsonic_bigint_export(const TsonicBigInt *value, int bits,
                                   int is_signed, std::uint64_t *lower,
                                   std::uint64_t *upper) noexcept {
    if (bits != 8 && bits != 16 && bits != 32 && bits != 64 && bits != 128) return 0;
    TsonicBigInt limit;
    mpz_set_ui(limit.value, 1);
    mpz_mul_2exp(limit.value, limit.value, bits - (is_signed != 0));
    if (mpz_sgn(value->value) >= 0) {
        if (mpz_cmp(value->value, limit.value) >= 0) return 0;
    } else {
        if (is_signed == 0) return 0;
        mpz_neg(limit.value, limit.value);
        if (mpz_cmp(value->value, limit.value) < 0) return 0;
    }
    TsonicBigInt packed;
    mpz_fdiv_r_2exp(packed.value, value->value, bits);
    std::uint64_t words[2] = {0, 0};
    mpz_export(words, nullptr, -1, sizeof(std::uint64_t), 0, 0, packed.value);
    *lower = words[0];
    *upper = words[1];
    return 1;
}

template <void (*Operation)(mpz_ptr, mpz_srcptr, mpz_srcptr)>
static TsonicBigInt *binary(const TsonicBigInt *left, const TsonicBigInt *right) {
    auto *result = new TsonicBigInt();
    Operation(result->value, left->value, right->value);
    return result;
}

extern "C" TsonicBigInt *tsonic_bigint_add(const TsonicBigInt *left,
                                         const TsonicBigInt *right) noexcept {
    return binary<mpz_add>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_subtract(const TsonicBigInt *left,
                                              const TsonicBigInt *right) noexcept {
    return binary<mpz_sub>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_multiply(const TsonicBigInt *left,
                                              const TsonicBigInt *right) noexcept {
    return binary<mpz_mul>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_divide(const TsonicBigInt *left,
                                            const TsonicBigInt *right) noexcept {
    return mpz_sgn(right->value) == 0 ? nullptr : binary<mpz_tdiv_q>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_remainder(const TsonicBigInt *left,
                                               const TsonicBigInt *right) noexcept {
    return mpz_sgn(right->value) == 0 ? nullptr : binary<mpz_tdiv_r>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_and(const TsonicBigInt *left,
                                         const TsonicBigInt *right) noexcept {
    return binary<mpz_and>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_or(const TsonicBigInt *left,
                                        const TsonicBigInt *right) noexcept {
    return binary<mpz_ior>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_xor(const TsonicBigInt *left,
                                         const TsonicBigInt *right) noexcept {
    return binary<mpz_xor>(left, right);
}

extern "C" TsonicBigInt *tsonic_bigint_negate(const TsonicBigInt *value) noexcept {
    auto *result = new TsonicBigInt();
    mpz_neg(result->value, value->value);
    return result;
}

extern "C" TsonicBigInt *tsonic_bigint_invert(const TsonicBigInt *value) noexcept {
    auto *result = new TsonicBigInt();
    mpz_com(result->value, value->value);
    return result;
}

extern "C" TsonicBigInt *tsonic_bigint_power(const TsonicBigInt *base,
                                           const TsonicBigInt *exponent) noexcept {
    if (mpz_sgn(exponent->value) < 0) return nullptr;
    auto *result = new TsonicBigInt();
    if (mpz_sgn(exponent->value) == 0) mpz_set_ui(result->value, 1);
    else if (mpz_sgn(base->value) == 0) mpz_set_ui(result->value, 0);
    else if (mpz_cmpabs_ui(base->value, 1) == 0) {
        mpz_set_si(result->value,
                   mpz_sgn(base->value) < 0 && mpz_odd_p(exponent->value) ? -1 : 1);
    } else if (mpz_fits_ulong_p(exponent->value) != 0) {
        const auto count = mpz_get_ui(exponent->value);
        const auto maximum_bits = static_cast<mp_bitcnt_t>(std::numeric_limits<int>::max()) * GMP_NUMB_BITS;
        const auto base_bits = mpz_sizeinbase(base->value, 2);
        if (count > (maximum_bits - 1) / (base_bits - 1)) {
            delete result;
            return nullptr;
        }
        mpz_pow_ui(result->value, base->value, count);
    } else {
        delete result;
        return nullptr;
    }
    return result;
}

static TsonicBigInt *shift(const TsonicBigInt *value,
                           const TsonicBigInt *count, bool left) {
    TsonicBigInt magnitude;
    mpz_abs(magnitude.value, count->value);
    if (mpz_sgn(count->value) < 0) left = !left;
    auto *result = new TsonicBigInt();
    if (mpz_sgn(value->value) == 0) return result;
    if (mpz_fits_ulong_p(magnitude.value) != 0) {
        const auto bits = mpz_get_ui(magnitude.value);
        const auto maximum_bits = static_cast<mp_bitcnt_t>(std::numeric_limits<int>::max()) * GMP_NUMB_BITS;
        if (left && bits > maximum_bits - mpz_sizeinbase(value->value, 2)) {
            delete result;
            return nullptr;
        }
        if (left) mpz_mul_2exp(result->value, value->value, bits);
        else mpz_fdiv_q_2exp(result->value, value->value, bits);
    } else if (!left) {
        mpz_set_si(result->value, mpz_sgn(value->value) < 0 ? -1 : 0);
    } else {
        delete result;
        return nullptr;
    }
    return result;
}

extern "C" TsonicBigInt *tsonic_bigint_shift_left(const TsonicBigInt *value,
                                                const TsonicBigInt *count) noexcept {
    return shift(value, count, true);
}

extern "C" TsonicBigInt *tsonic_bigint_shift_right(const TsonicBigInt *value,
                                                 const TsonicBigInt *count) noexcept {
    return shift(value, count, false);
}
