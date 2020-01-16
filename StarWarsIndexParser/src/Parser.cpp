#include "Parser.h"

#include <iostream>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>

#include <rapidxml.hpp>
#include <rapidxml_iterators.hpp>
#include <rapidxml_print.hpp>
#include <rapidxml_utils.hpp>

namespace fs = boost::filesystem;
using namespace xml;

xml::xml_node<>* BaseParser::CreateCharactersLocation(xml::xml_node<>* library)
{
    auto characters = m_writer.AllocateNode(node_element, "characters");
    library->append_node(characters);

    auto categoryName = m_writer.AllocateNode(node_element, "categoryname");
    categoryName->append_attribute(m_writer.AllocateAttr("type", "string"));
    categoryName->value("Player Library");
    characters->append_node(categoryName);

    auto name = m_writer.AllocateNode(node_element, "name");
    name->append_attribute(m_writer.AllocateAttr("type", "string"));
    name->value("Characters");
    characters->append_node(name);

    auto entries = m_writer.AllocateNode(node_element, "entries");
    characters->append_node(entries);
    return characters;
}

std::string BaseParser::ReadFileToString(const char* fileToLoad)
{
    std::string rawCharData;

    fs::path p(fileToLoad);
    if (fs::exists(p))
    {
        if (fs::is_regular_file(p))
        {
            fs::load_string_file(p, rawCharData);
        }
    }

    return std::move(rawCharData);
}

std::string BaseParser::GenerateId(const std::string& name)
{
    std::string id = name;
    id.erase(std::remove_if(id.begin(), id.end(), [](char c) { return !std::isalpha(c); }), id.end());
    std::transform(id.begin(), id.end(), id.begin(), [](unsigned char c) { return std::toupper(c); });

    return std::move(id);
}

xml::xml_node<>* BaseParser::AddEntryToNode(xml::xml_node<>* entries, const std::string& name,
                                            const std::string& className)
{
    std::string id = GenerateId(name);
    auto entryNode = m_writer.AllocateNode(node_element, m_writer.AllocateString(id.c_str()));
    entries->append_node(entryNode);

    auto cn = m_writer.AllocateNode(node_element, "classname", m_writer.AllocateString(className.c_str()));
    cn->append_attribute(m_writer.AllocateAttr("type", "string"));
    entryNode->append_node(cn);

    auto entryName = m_writer.AllocateNode(node_element, "name", m_writer.AllocateString(name.c_str()));
    entryName->append_attribute(m_writer.AllocateAttr("type", "string"));
    entryNode->append_node(entryName);

    return entryNode;
}
