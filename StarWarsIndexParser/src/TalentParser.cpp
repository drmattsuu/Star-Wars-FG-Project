#include "TalentParser.h"

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include <rapidxml.hpp>
#include <rapidxml_iterators.hpp>
#include <rapidxml_print.hpp>
#include <rapidxml_utils.hpp>

using namespace xml;

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
            auto entry = tableItem->first_node();
            if (entry)
            {
                Talent newTalent;
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

                m_talents.push_back(newTalent);
            }
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
            characters = CreateCharactersLocation(library);
        }

        auto entries = characters->first_node("entries");
        if (!entries)
        {
            throw std::exception("No entries node found under library.characters");
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
            ExportTalent(talent, talentEntries);
        }
    }
}

void TalentParser::Parse()
{
    const char* fileToLoad = "./data/character_talents.xml";

    std::string characterTalents = ReadFileToString(fileToLoad);

    ParseXMLToTalents(characterTalents);

    if (m_talents.size())
    {
        ExportFantasyGroundsXML();
    }
}

void TalentParser::ExportTalent(Talent& talent, xml_node<>* talentEntries)
{
    auto entryNode = AddEntryToNode(talentEntries, talent.name, "talent");

    auto entryDescription = m_writer.AllocateNode(node_element, "description");
    entryDescription->append_attribute(m_writer.AllocateAttr("type", "formattedtext"));

    if (talent.forceSensitive)
    {
        auto index = m_writer.AllocateNode(node_element, "i", "Force Talent.");
        entryDescription->append_node(index);
    }

    auto desc = m_writer.AllocateNode(node_element, "p", m_writer.AllocateString(talent.index.c_str()));
    entryDescription->append_node(desc);

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
