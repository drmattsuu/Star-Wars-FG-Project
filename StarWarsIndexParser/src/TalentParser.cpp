#include "TalentParser.h"

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
using namespace rapidxml;

void TalentParser::ParseXMLToTalents(const std::string& xml)
{
    // We're not allowed to use std::string directly because rapidXML does strange things.
    std::vector<char> xmlCopy(xml.begin(), xml.end());
    xmlCopy.push_back('\0');  // Wack a null on the end to make sure the string terminates

    xml_document<> doc;
    doc.parse<0>(&xmlCopy[0]);
    auto table = doc.first_node("table");

    auto tableItem = table->first_node();
    while (tableItem != nullptr)
    {
        auto trClass = tableItem->first_attribute("class");
        // in our spec, table entries without a class are talent entries.
        if (!trClass)
        {
            Talent newTalent;
            auto entry = tableItem->first_node();
            if (entry)
            {
                auto talentName = entry->first_node();
                if (!talentName)
                {
                    throw std::exception("Badly formed Talent");
                }
                newTalent.name = talentName->value();

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Talent");
                }

                newTalent.activation = entry->value();

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Talent");
                }

                std::string ranked = entry->value();
                if (ranked == "True")
                {
                    newTalent.ranked = true;
                }

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Talent");
                }

                std::string fs = entry->value();
                if (fs == "True")
                {
                    newTalent.forceSensitive = true;
                }

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Talent");
                }

                newTalent.index = entry->value();
            }

            m_talents.push_back(newTalent);
        }

        tableItem = tableItem->next_sibling();
    }
}

void TalentParser::ExportFantasyGroundsXML()
{
    auto library = m_writer.GetLibraryNode();

    if (library)
    {
        // root.library.characters
        auto characters = library->first_node("characters");
        if (!characters)
        {
            characters = createCharactersLocation(library);
        }

        auto entries = characters->first_node("entries");
        if (!entries)
        {
            // todo: error
            return;
        }

        auto talents = m_writer.AllocateNode(node_element, "talents");
        entries->append_node(talents);

        auto name = m_writer.AllocateNode(node_element, "name", "Talents");
        name->append_attribute(m_writer.AllocateAttr("type", "string"));
        talents->append_node(name);

        auto talentEntries = m_writer.AllocateNode(node_element, "entries");
        talents->append_node(talentEntries);

        for (auto talent : m_talents)
        {
            std::string id = talent.name;
            id.erase(std::remove_if(id.begin(), id.end(), [](char c) { return !std::isalpha(c); }), id.end());
            std::transform(id.begin(), id.end(), id.begin(), [](unsigned char c) { return std::toupper(c); });

            auto entryNode = m_writer.AllocateNode(node_element, m_writer.AllocateString(id.c_str()));
            talentEntries->append_node(entryNode);

            auto classname = m_writer.AllocateNode(node_element, "classname", "talent");
            classname->append_attribute(m_writer.AllocateAttr("type", "string"));
            entryNode->append_node(classname);

            auto entryName = m_writer.AllocateNode(node_element, "name", m_writer.AllocateString(talent.name.c_str()));
            entryName->append_attribute(m_writer.AllocateAttr("type", "string"));
            entryNode->append_node(entryName);

            std::string desc = talent.forceSensitive ? "<i>Force Talent.</i>" : "";
            desc += "<p>" + talent.index + "</p>";
            auto entryDescription =
                m_writer.AllocateNode(node_element, "description", m_writer.AllocateString(desc.c_str()));
            entryDescription->append_attribute(m_writer.AllocateAttr("type", "formattedtext"));
            entryNode->append_node(entryDescription);

            if (talent.ranked)
            {
                auto entryRanked = m_writer.AllocateNode(node_element, "activation", "ranked");
                entryRanked->append_attribute(m_writer.AllocateAttr("type", "string"));
                entryNode->append_node(entryRanked);
            }

            auto entryActiviation =
                m_writer.AllocateNode(node_element, "activation", m_writer.AllocateString(talent.activation.c_str()));
            entryActiviation->append_attribute(m_writer.AllocateAttr("type", "string"));
            entryNode->append_node(entryActiviation);
        }
    }
}

xml_node<char>* TalentParser::createCharactersLocation(xml_node<>* library)
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

void TalentParser::Parse()
{
    const char* fileToLoad = "./data/character_talents.xml";

    std::string characterTalents;

    fs::path p(fileToLoad);
    if (fs::exists(p))
    {
        if (fs::is_regular_file(p))
        {
            fs::load_string_file(p, characterTalents);
        }
    }

    ParseXMLToTalents(characterTalents);

    if (m_talents.size())
    {
        ExportFantasyGroundsXML();
    }
}