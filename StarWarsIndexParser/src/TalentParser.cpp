#include "TalentParser.h"

#include <iostream>
#include <memory>
#include <string>

#include <boost/filesystem.hpp>

#include <rapidxml.hpp>
#include <rapidxml_iterators.hpp>
#include <rapidxml_print.hpp>
#include <rapidxml_utils.hpp>

namespace fs = boost::filesystem;
namespace xml = rapidxml;

struct Talent
{
    std::string name;
    std::string activation;
    bool ranked{false};
    bool forceSensitive{false};
    std::string index;
};

void TalentParser::Parse(char* outputFile)
{
    const char* fileToLoad = "./data/character_talents.xml";

    std::unique_ptr<char*> talentsRaw;

    std::string characterTalentsStdString;
    fs::path p(fileToLoad);
    if (fs::exists(p))
    {
        if (fs::is_regular_file(p))
        {
            auto size = fs::file_size(p);
            //if (size)
            //{
            //    talentsRaw = std::make_unique<char*>(new char[size + 1]);
            //}
            //fs::load_string_file(p, *talentsRaw.get());
        }
    }

    //if (characterTalentsStdString.empty())
    //{
    //    std::cout << "No source file found at " << fileToLoad << std::endl;
    //    return;
    //}

    //auto talentsRaw = std::make_unique<char*>(new char[characterTalentsStdString.size() + 1]);
    //if (talentsRaw != nullptr)
    //{
    //    strcpy(*talentsRaw.get(), characterTalentsStdString.c_str());
    //    {
    //        xml::xml_document<> doc;
    //        doc.parse<0>(*talentsRaw.get());
    //    }
    //}
}