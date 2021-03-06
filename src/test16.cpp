#include <pcrscpp.h>
#include <string>
#include <iostream>
#include <fstream>
#if __cplusplus >= 201103L
#include <locale>
#include <codecvt>
#else
#warning "Without C++11: not internal UTF16 support: test16 only linked to test for undefined references in the static libpcrscpp16"
#endif

int main (int argc, char *argv[]) {
	pcrscpp16::replace rx;
#if __cplusplus >= 201103L
	if (argc < 3) {
		std::cerr << "Error: need at lease 2 args: <command> [<command2> <command3> ...] <file>" << std::endl;
		return 1;
	}

	std::wstring_convert<std::codecvt_utf8<char16_t>,char16_t> cv;
		
	std::u16string cmd;
        pcrscpp_error_codes::error_code error;
        for (int i = 1; i < argc - 1; i++) {
        cmd = cv.from_bytes(std::string(argv[i]));
	    error = rx.add_job (cmd); // add replace job

	    if (error < 0) {
		    std::cerr << "There was a warning when compiling command " << argv[i] << ": " << rx.last_error_message() << std::endl;
	    } else if (error > 0) {
		    std::cerr << "Fatal error when compiling command " << argv[i] << ": " << rx.last_error_message() << std::endl;
		    return 3;
	    }
        }

	std::ifstream file (argv[argc - 1]);
	if (!file.is_open ()) {
		std::cerr << "Unable to open file " << argv[2] << std::endl;
		return 2;
	}
	std::u16string str;
	{
		file.seekg(0, std::ios::end);
		size_t size = file.tellg();
		file.seekg(0);
                std::string buffer;
		if (size > 0) {
			buffer.resize(size);
			file.read(&buffer[0], size);
			buffer.resize(size - 1); // strip '\0'
                        str = cv.from_bytes(buffer);
		}
	}
	if (str.size() > 0) {
		rx.replace_inplace(str); // run replace
		std::cout << cv.to_bytes(str) << std::endl;
	}

	file.close();
#else
	std::cerr << "No internal UTF16 support: doing nothing..." << std::endl;
#endif

	return 0;
}
