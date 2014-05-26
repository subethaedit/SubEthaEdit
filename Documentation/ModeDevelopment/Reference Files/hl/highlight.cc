/*
 * A block comment w/ alerts:
 * NOTE some note
 * WARNING some warning
 * ATTENTION attention text
 * TODO todo text
 * TBD to be defined
 * FIXME to be fixed later
 */

#include <boost/mpl/eval_if.hpp>
#include <boost/mpl/bool.hpp>

// Use predefined standard macros
#define MY_THROW(Ex) throw Ex << exception::location_info(__FILE__, __LINE__)
// GCC specific predefined macros
#if defined(__GNUC__) && defined(__linux__)
# define MY_OS "Linux"
#endif

namespace mpl {
/**
 * \brief True variadic analog of \c boost::mpl::or_
 *
 * \attention Generic template isn't defined
 */
template <typename...>
struct v_or;

/**
 * \brief True variadic analog of \c boost::mpl::or_
 *
 * \note Specialization to accept at least two parameters
 * \todo Assert that all given types are \e mpl booleans
 */
template <typename T1, typename T2, typename... Tail>
struct v_or<T1, T2, Tail...>
  : boost::mpl::eval_if<
      T1
    , boost::mpl::true_
    , v_or<T2, Tail...>
    >::type
{
    static_assert(sizeof...(Tail) != 0, "Impossible!");
};

/**
 * \brief True variadic analog of \c boost::mpl::or_
 *
 * \note Single parameter specialization
 */
template <typename T>
struct v_or<T> : boost::mpl::bool_<T::type::value>
{
};

}                                                           // namespace mpl

namespace sample { namespace details {
constexpr std::size_t pow_bytes(const std::size_t what, const unsigned d)
{
    return d ? 1'024 * pow_bytes(what, d - 1) : what;
}
}                                                           // namespace details

/// User defined literal: bytes
constexpr std::size_t operator"" _bytes(const unsigned long long size)
{
    return size;
}
/// User defined literal: kibibytes (2^10)
constexpr std::size_t operator"" _KiB(const unsigned long long size)
{
    return zencxx::details::pow_bytes(size, 1);
}
/// User defined literal: mebibytes (2^20)
constexpr std::size_t operator"" _MiB(const unsigned long long size)
{
    return zencxx::details::pow_bytes(size, 2);
}
/// \warning Invalid user defined literal: missed leading underscore
constexpr std::size_t operator"" GiB(const unsigned long long size)
{
    return zencxx::details::pow_bytes(size, 2);
}

constexpr std::size_t BUFFER_SIZE = 10_Mib;                 // user defined literal (const)
constexpr std::size_t MESSAGE_SIZE = 100_Kib;
constexpr std::size_t MAX_PKT_LENGTH = 100'500_bytes;       // user defined literal w/ delimiters
extern thread_local std::string s_thread_name;              // prefixed static variable
extern std::string g_app_name;                              // prefixed global variable
// names w/ leading underscore are reserved by C++ Standard
std::string _reserved;
}                                                           // namespace sample

namespace chars {
const char a = 'a';
const char hex_esc = '\x1b';
const char oct_esc = '\033';
const char cr = '\n';
const char lf = '\r';
const char lf = '\z';                                       // not a valid esc char
const char tab = '\t';
const int multi = 'abcd';
const wchar_t b = L'b';
const wchar_t b_multi = L'abcdefgh';
const char16_t c = u'c';
const char16_t c = u'\u0bac';
const char16_t c_multi = u'abcd';                           // unicode multichars are not allowed
const char32_t d = U'd';
const char32_t d = U'\U12345678';
const char32_t d_multi = U'ab';                             // unicode multichars are not allowed
}                                                           // namespace strings

namespace strings {
const char* a = "Hello\n";
const wchar_t* b = L"Hello\x0d";
const char16_t* c = u"Hello\015";
const char32_t* d = U"Hello\13";
const char* e = u8"Hello UTF-8";
const char* f = R"-(
    Raw string literal
    (no \t esc sequences here \x21)
  )-";
const wchar_t* g = LR"**(Hello %-03s %d %4i %%)**";         // printf-like format string
const char16_t* h = uR"!(Hello)!";
const char32_t* i = UR"@@@(Hello)@@@";
const std::string j = u8R"++(Hello)++";
const std::string h = u8"привет"_RU;                        // user defined literal
}                                                           // namespace strings


namespace numbers {
constexpr int a = 123;                                      // decimal
constexpr int a1 = -123'456;                                // decimal w/ delimiters
constexpr int au = 123u;                                    // unsigned decimal
constexpr long al = 123l;                                   // long decimal
constexpr long al = 123l;                                   // long decimal
constexpr long long all = 123ll;                            // long long decimal
constexpr unsigned long long aull = +123ull;                // unsigned long long decimal
constexpr auto a_invalid = 123uull;
constexpr int b = 0123;                                     // octal
constexpr int b1 = -0'123'456;                              // octal w/ delimiters
constexpr int octal_invalid = -0678;
constexpr auto c = 0x123;                                   // hex
constexpr auto c = 0x1234'5678'9abc;                        // hex w/ delimiters
constexpr auto z = 0b1010110001110;                         // binary w/ delimiters
constexpr auto z1 = 0b1'0101'1000'1110;                     // binary w/ delimiters
constexpr auto binary_invalid = 0b012;


const auto d = 10.;
const auto e = 10.01;
const auto f = .01f;

const auto g = 10E10f;
const auto h = +10E10;
const auto i = -10E10;

const auto j = 10E+10;
const auto k = +10E+10f;
const auto l = -10E+10;

const auto m = 10e-10;
const auto o = +10e-10;
const auto p = -10e-10f;

const auto q = 10.01E10;
const auto s = 10.01E+10;
const auto t = 10.01E-10l;

const auto u = 10f;                                         // user defined literals must have a leading underscore
}                                                           // namespace numbers

extern void foo() __attribute__((weak));                    // GCC specific attributes

class base
{
public:
    virtual ~base() {}
    virtual void foo() const volatile = 0;
};

class derived : public base
{
    virtual void foo() const volatile override final
    {
        std::cout << __PRETTY_FUNCTION__ << ": " << __DATE__<< std::endl;
    }
    // C++11 attributes
    void exit() [[noreturn, deprecated("Use exit(int) instead")]]
    {
        exit(other_);
    }
    void exit(int a) [[noreturn, gcc::visibility("default")]]
    {
        /// GCC builtins
        if (__builtin_expect(a == 0, 1))
        {
            // ...
        }
    }
    alignas(long) int other_;                               // google code style compatible member name
    int m_member;                                           // prefixed data member
};

// Commented by preprocessor
#if 0
boost::optional<std::string> m_commented;
#else
int not_commended;
#endif

#if true
char also_not_commented;
# if 0
std::string comment = "comment";
# endif
#else
char other_commented;
#endif

// Modelines: switch to C++ mode
// kate: hl C++;
// kate: indent-width 4;
