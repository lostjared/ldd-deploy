/* 
    mingw-deploy
    written by Jared Bruni
    https://lostsidedead.biz

    Copy DLL from Mingw compiled EXE in MSYS2 to current directory
    
*/

#include<iostream>
#include<sstream>
#include<string>
#include<cstdio>
#include<cstdlib>
#include<algorithm>
#include<optional>
#include"argz.hpp"


std::optional<std::string> extractFilename(const std::string &path) {
    auto pos = path.find("=>");
    if(pos != std::string::npos) {
        std::string rightof = path.substr(pos+2);
        auto pos2 = rightof.rfind("(");
        if(pos2 != std::string::npos) {
            std::string leftof = rightof.substr(0, pos2);
            return leftof;
        }
    }
    return std::nullopt;
}

int main(int argc, char **argv) {
    Argz<std::string> argz(argc, argv);
    argz.addOptionSingleValue('i', "input filename")
    .addOptionSingle('h', "print out help")
    .addOptionSingleValue('o', "output directory ")
    .addOptionDoubleValue('I', "input", "input filename")
    .addOptionDoubleValue('O', "output", "output directory");
    int value = 0;
    Argument<std::string> arg;
    std::string input_exe;
    std::string output_dir = ".";
    try {
        while((value = argz.proc(arg)) != -1) {
            switch(value) {
            case 'h':
                argz.help(std::cout);
                break;
            case 'i':
            case 'I':
                input_exe = arg.arg_value;
                break;
            case 'o':
            case 'O':
                output_dir = arg.arg_value;
                break;
            }
        }
     } catch(const ArgException<std::string> &e) {
        std::cerr << "Syntax Error: " << e.text() << "\n";
    }
    if(input_exe.empty()) {
        std::cerr << "Error requires input EXE path with -i.\n";
        argz.help(std::cout);
        std::cerr.flush();
        exit(EXIT_FAILURE);
    }
    std::ostringstream stream;
    stream << "ldd " << input_exe << " | grep -vi windows ";
#ifdef _WIN32
    FILE *fptr = _popen(stream.str().c_str(), "r");
#else
    FILE *fptr = popen(stream.str().c_str(), "r");
#endif
    if(!fptr) {
        std::cerr << "An Error has occoured..\n";
        std::cerr.flush();
        exit(EXIT_FAILURE);
    }
    std::string output;
    while(!feof(fptr)) {
        char buf[1024];
        std::size_t bytes = fread(buf, 1, 1024, fptr);
        buf[bytes] = 0;
        output += buf;
    }
#ifdef _WIN32
    _pclose(fptr);
#else
    pclose(fptr);
#endif
    std::istringstream istream(output);
    while(!istream.eof()) {
        std::string line;
        std::getline(istream, line);
        if(istream) {
            auto filename = extractFilename(line);
            if(filename.has_value()) {
                std::ostringstream stream;
                stream << "cp " << filename.value() << " " << output_dir;
                system(stream.str().c_str());
                std::cout << stream.str() << "\n";
            }
        }
    }
    return 0;
}