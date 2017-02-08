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

	    if (error < 0) {
		    std::cerr << "There was a warning when compiling command " << cmd << ": " << rx.last_error_message() << std::endl;
	    } else if (error > 0) {
		    std::cerr << "Fatal error when compiling command " << cmd << ": " << rx.last_error_message() << std::endl;
		    return 3;
	    }
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
