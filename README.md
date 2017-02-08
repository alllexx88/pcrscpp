
# PCRSCPP: C++ Perl Compatible Regular Substitution

The PCRSCPP library is a supplement to the PCRE library that implements
regular expression based substitution, similar to the one provided by
Perl's 's' operator. Originally inspired by PCRS C library (see [PCRS (3)]),
it does not suffer from PCRS subpatterns capturing number limit, provides
some additional features (see below), as well as support for 16- and
32-bit character strings. The latter currently requires C\+\+11
features (u16string, u32string and UTF8<->UTF16, UTF8<->UTF32 conversion),
hence libpcrscpp16 and libpcrscpp32 need a C\+\+11 capable compiler, while
libpcrscpp (8-bit) can be built with a C\+\+98 compiler.

## PCRSCPP API

PCRSCPP declarations can be found in <pcrscpp.h> header. Regular expression
based substitution jobs creation and execution classes are:

  * `pcrscpp::replace`
  * `pcrscpp16::replace`
  * `pcrscpp32::replace`

These classes instantiate common template class:
  * `pcrscpp_templates::replace<typename pchar, class pstring, class replace_impl>`

More specifically,

```
namespace pcrscpp {
typedef char pchar;
typedef std::basic_string<pchar> pstring;
class replace_impl;
typedef pcrscpp_templates::replace<pchar, pstring, replace_impl> replace;
}

namespace pcrscpp16 {
typedef PCRE_UCHAR16 pchar;
typedef std::basic_string<pchar> pstring;
class replace_impl;
typedef pcrscpp_templates::replace<pchar, pstring, replace_impl> replace;
}

namespace pcrscpp32 {
typedef PCRE_UCHAR32 pchar;
typedef std::basic_string<pchar> pstring;
class replace_impl;
typedef pcrscpp_templates::replace<pchar, pstring, replace_impl> replace;
}
```

Note that <pcrscpp.h> defines `PCRE_UCHAR16` and `PCRE_UCHAR32` as `char16_t`
and `char32_t`, respectively, before including <pcre.h>, unless they are already
defined, which means that `pcrscpp16::pchar` and `pcrscpp32::pchar` definitions
can be overridden. If they are overridden during libpcrscpp16/libpcrscpp32
compilation, make sure that client code shares the same overridden defines.

### Creating and removing replace jobs

Several overloaded `add_job` methods can be used to create replacement jobs:

```
    pcrscpp_error_codes::error_code add_job
        (const pstring& command);
    pcrscpp_error_codes::error_code add_job
        (const pchar* command);
    pcrscpp_error_codes::error_code add_job
        (const pstring& pattern,
         const pstring& substitute,
         const pstring& options);
    pcrscpp_error_codes::error_code add_job
        (const pchar* pattern,
         const pchar* substitute,
         const pchar* options);
```

These methods return zero error code (`pcrscpp_error_codes::no_error`) on success,
a negative code if there was a warning(s) (but job still created), and a positive
code on a fatal error. In case of an error/warning, a descriptive error message can
be retrieved using `std::string last_error_message()` method. `replace` class can
be initialized with a job too, but it should be noted that in case of an error/warning
it throws an `pcrscpp_error_codes::error_code` exception.
Expected `command`, `pattern`, `substitute` and `options` strings syntax is described
in respective sections below.

Jobs can be chained as many times as resources permit. Use `jobs_n()` method to
get the number of currently added jobs.

Removing jobs is done using `pop_job*` methods:

```
    // remove last job:
    // returns false if no job to pop
    bool pop_job_back();
    // remove first job
    bool pop_job_front();
    // remove job number n
    // (numbers start from 0):
    // returns false if no such job
    bool pop_job(size_t n);
```

Or to remove all jobs at once:

```
    // remove all present (if any) jobs
    void remove_jobs();
```

### Executing replacement on a string

`pcrscpp*::replace` classes give several options to execute replacement on a string:

```
    void replace_inplace (pstring& subject);
    void replace_store (const pstring& subject);
    void replace_store (const pchar* subject);
    pstring replace_copy (const pstring& subject);
    pstring replace_copy (const pchar* subject);
```

* `replace_inplace`: store replacement result in the passed string self
* `replace_store`: replacement result is stored in public `std::string replace_result` field
* `replace_copy`: resutrn replacement result as a copy

Use `std::vector<size_t> last_replace_count()` method to get vector of numbers of replaced
pattern matches for each respective job.

### Command string syntax

Command syntax follows Perl `s/pattern/substitute/[options]` convention. Any character
(except the backslash `\`) can be used as a delimiter, not just `/`, but make sure that
delimiter is escaped with a backslash (`\`) if used in `pattern`, `substitute` or `options`
substrings, e.g.:

- `s/\\/\//g` to replace all backslashes with forward ones

Remember to double backslashes in C\+\+ code, unless using raw string literal
(see [string literal]):

```
pcrscpp::replace rx("s/\\\\/\\//g");
```

### Pattern string syntax

Pattern string is passed directly to `pcre*_exec`, and thus has to follow PCRE syntax as
described in [PCRE documentation].

### Substitute string syntax

Substitute string backreferencing syntax is similar to Perl's:

  * `$1` ... `$n`: nth capturing subpattern matched.
  * `$&` and `$0`: the whole match
  * `$+{label}`  : labled subpattern matched. `label` is up to 32 alphanumerical +
                   underscore characters (`'A'-'Z'`,`'a'-'z'`,`'0'-'9'`,`'_'`),
                   first character must be alphabetical
  * ``$` `` and `$'` (backtick and tick) refer to the areas of the subject before
                     and after the match, respectively. As in Perl, the unmodified
                     subject is used, even if a global substitution previously matched.

Also, following escape sequences get recognized:

  * `\n`: newline
  * `\r`: carriage return
  * `\t`: horizontal tab
  * `\f`: form feed
  * `\b`: backspace
  * `\a`: alarm, bell
  * `\e`: escape
  * `\0`: binary zero

Any other escape sequence `\<char>`, is interpreted as `<char>`, meaning that you
have to escape backslashes too

### Options string syntax

In Perl-like manner, options string is a sequence of allowed modifier letters.
PCRSCPP recognizes following modifiers:

1. Perl-compatible flags
  * `g`: global replace, not just the first match
  * `i`: case insensitive match  
       (PCRE_CASELESS)
  * `m`: multi-line mode: `^` and `$` additionally match positions
         after and before newlines, respectively  
         (PCRE_MULTILINE)
  * `s`: let the scope of the `.` metacharacter include newlines
         (treat newlines as ordinary characters)  
         (PCRE_DOTALL)
  * `x`: allow extended regular expression syntax,
         enabling whitespace and comments in complex patterns  
         (PCRE_EXTENDED)
2. PHP-compatible flags
  * `A`: "anchor" pattern: look only for "anchored" matches: ones that
         start with zero offset. In single-line mode is identical to
         prefixing all pattern alternative branches with `^`  
         (PCRE_ANCHORED)
  * `D`: treat dollar `$` as subject end assertion only, overriding the default:
         end, or immediately before a newline at the end.
         Ignored in multi-line mode  
         (PCRE_DOLLAR_ENDONLY)
  * `U`: invert `*` and `+` greediness logic: make ungreedy by default,
         `?` switches back to greedy. `(?U)` and `(?-U)` in-pattern switches
         remain unaffected  
         (PCRE_UNGREEDY)
  * `u`: Unicode mode. Treat pattern and subject as UTF8/UTF16/UTF32 string.
         Unlike in PHP, also affects newlines, `\R`, `\d`, `\w`, etc. matching  
         ((PCRE_UTF8/PCRE_UTF16/PCRE_UTF32) | PCRE_NEWLINE_ANY
          | PCRE_BSR_UNICODE | PCRE_UCP)
3. PCRSCPP own flags:
  * `N`: skip empty matches  
         (PCRE_NOTEMPTY)
  * `T`: treat substitute as a trivial string, i.e., make no backreference
         and escape sequences interpretation
  * `n`: discard non-matching portions of the string to replace  
         Note: PCRSCPP does _not_ automatically add newlines,
         the replacement result is plain concatenation of matches,
         be specifically aware of this in multiline mode

## Usage example

Simple usage example that executes replacement jobs series, taken from args,
on a file (the last arg), and have result printed to `stdout`:

```
#include <pcrscpp.h>
#include <string>
#include <iostream>
#include <fstream>

int main (int argc, char *argv[]) {
    pcrscpp::replace rx;
    if (argc < 3) {
        std::cerr << "Error: need at lease 2 args: <command> [<command2> <command3> ...] <file>" << std::endl;
        return 1;
    }
        
    std::string cmd;
    pcrscpp_error_codes::error_code error;
    for (int i = 1; i < argc - 1; i++) {
        cmd = argv[i];
    error = rx.add_job (cmd); // add replace job

    if (error < 0)
        std::cerr << "There was a warning when compiling command " << cmd << ": " << rx.last_error_message() << std::endl;
    } else if (error > 0) {
        std::cerr << "Fatal error when compiling command " << cmd << ": " << rx.last_error_message() << std::endl;
        return 3;
    }

    std::ifstream file (argv[argc - 1]);
    if (!file.is_open ()) {
        std::cerr << "Unable to open file " << argv[2] << std::endl;
        return 2;
    }
    std::string buffer;
    {
        file.seekg(0, std::ios::end);
        size_t size = file.tellg();
        file.seekg(0);
        if (size > 0) {
            buffer.resize(size);
            file.read(&buffer[0], size);
            buffer.resize(size - 1); // strip '\0'
        }
    }
    if (buffer.size() > 0) {
        rx.replace_inplace(buffer); // run replace
        std::cout << buffer << std::endl;
    }

    file.close();

    return 0;
}
```

## Building PCRSCPP

PCRSCPP sources come shipped with a simple Makefile that should build 8, 16 and 32 bit
libraries in any Unix environment, as long as standard build tools are available, and
PCRE development files are installed. With minor modifications, the same Makefile can
be used in Windows too, using MSYS MinGW

```
~/pcrscpp$ make
rm -f obj/pcrscpp.o
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -UPCRSCPP16 -UPCRSCPP32 -c src/pcrscpp.cpp -o obj/pcrscpp.o
rm -f libpcrscpp.so.0.0.1
g++ -shared -Wl,-soname,libpcrscpp.so.0 -o libpcrscpp.so.0.0.1  obj/pcrscpp.o -lpcre 
rm -f obj/pcrscpp16.o
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -DPCRSCPP16 -UPCRSCPP32 -c src/pcrscpp.cpp -o obj/pcrscpp16.o
rm -f libpcrscpp16.so.0.0.1
g++ -shared -Wl,-soname,libpcrscpp16.so.0 -o libpcrscpp16.so.0.0.1  obj/pcrscpp16.o -lpcre16 
rm -f obj/pcrscpp32.o
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -UPCRSCPP16 -DPCRSCPP32 -c src/pcrscpp.cpp -o obj/pcrscpp32.o
rm -f libpcrscpp32.so.0.0.1
g++ -shared -Wl,-soname,libpcrscpp32.so.0 -o libpcrscpp32.so.0.0.1  obj/pcrscpp32.o -lpcre32 
rm -f libpcrscpp.a
ar rcs libpcrscpp.a obj/pcrscpp.o
rm -f libpcrscpp16.a
ar rcs libpcrscpp16.a obj/pcrscpp16.o
rm -f libpcrscpp32.a
ar rcs libpcrscpp32.a obj/pcrscpp32.o
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -c src/test.cpp -o obj/test.o
g++ obj/test.o libpcrscpp.a -lpcre  -o test
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -c src/test16.cpp -o obj/test16.o
g++ obj/test16.o libpcrscpp16.a -lpcre16  -o test16
g++ -Iinclude  -fPIC -std=c++11  -O3  -g  -Wall  -Werror  -c src/test32.cpp -o obj/test32.o
g++ obj/test32.o libpcrscpp32.a -lpcre32  -o test32
All done
```

Note that library versioning (`PCRSCPP_VERSION` in the Makefile) and SO naming policy (`PCRSCPP_SO_VERSION`) should not
be treated as final


   [PCRS (3)]: <https://www.gsp.com/cgi-bin/man.cgi?section=3&topic=pcrs>
   [string literal]: <http://en.cppreference.com/w/cpp/language/string_literal>
   [PCRE documentation]: <http://pcre.org/pcre.txt>
