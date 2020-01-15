#include <iostream>
#include <string>

#include "TalentParser.h"

#include <boost/filesystem.hpp>

#ifndef APP_VERSION
#define APP_VERSION = "VERSION_MISSING"
#endif

constexpr auto kver = APP_VERSION;

int main(int argc, char* argv[])
{
#if defined(PARSER_WORKING_DIR)
    // set debug working directory to the project root, we do this so we don't have to mess about copying resources when
    // developing.
    boost::filesystem::current_path(PARSER_WORKING_DIR);
#endif

    std::cout << "Hello app! " << kver << std::endl;

    TalentParser tp;
    tp.Parse("testOut.xml");

    return 0;
}
