
#include "FantasyGroundsLibraryWriter.h"

#include "TalentParser.h"
#include "AbilityParser.h"

#include <iostream>
#include <string>

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

    std::cout << "Star Wars index parser: " << kver << std::endl;

    try
    {
        FantasyGroundsLibraryWriter writerDb("db.xml");
        FantasyGroundsLibraryWriter writerCommon("common.xml");

        TalentParser tp(writerCommon);
        tp.Parse();

        AbilityParser ap(writerCommon);
        ap.Parse();

        writerCommon.WriteToDisk();
        writerDb.WriteToDisk();
    }
    catch (std::exception e)
    {
        std::cout << "Did an exception: " << e.what() << std::endl;
    }

    return 0;
}
