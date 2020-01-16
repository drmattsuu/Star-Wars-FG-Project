#pragma once

#include "FantasyGroundsLibraryWriter.h"

#include <rapidxml.hpp>
#include <string>
namespace xml = rapidxml;

class BaseParser
{
public:
    BaseParser(FantasyGroundsLibraryWriter& writer) : m_writer(writer){};
    virtual ~BaseParser() = default;

    virtual void Parse() = 0;

protected:
    xml::xml_node<>* CreateCharactersLocation(xml::xml_node<>* library);
    std::string ReadFileToString(const char* fileToLoad);
    std::string GenerateId(const std::string& name);
	xml::xml_node<>* AddEntryToNode(xml::xml_node<>* entries, const std::string& name, const std::string& className);

protected:
    FantasyGroundsLibraryWriter& m_writer;

};