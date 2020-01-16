#include "AbilityParser.h"

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include <rapidxml.hpp>
#include <rapidxml_iterators.hpp>
#include <rapidxml_print.hpp>
#include <rapidxml_utils.hpp>

using namespace xml;

void AbilityParser::Parse()
{
    const char* fileToLoad = "./data/character_abilities.xml";
    std::string characterAbilities = ReadFileToString(fileToLoad);

    ParseXMLToAbilities(characterAbilities);

    if (m_abilities.size())
    {
        ExportFantasyGroundsXML();
    }
}

void AbilityParser::ParseXMLToAbilities(const std::string& xml)
{  // We're not allowed to use std::string directly because rapidXML does strange things.
    std::vector<char> xmlCopy(xml.begin(), xml.end());
    xmlCopy.push_back('\0');  // Wack a null on the end to make sure the string terminates

    xml_document<> doc;
    doc.parse<0>(&xmlCopy[0]);
    auto table = doc.first_node("table");

    auto tableItem = table->first_node();
    while (tableItem != nullptr)
    {
        auto trClass = tableItem->first_attribute("class");
        // in our spec, table entries without a class are ability entries.
        if (!trClass)
        {
            auto entry = tableItem->first_node();
            if (entry)
            {
                Ability newAbility;
                auto abilityName = entry->first_node();
                if (!abilityName)
                {
                    throw std::exception("Badly formed Ability");
                }
                newAbility.name = abilityName->value();

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Ability");
                }

                newAbility.desc = entry->value();

                entry = entry->next_sibling();
                if (!entry)
                {
                    throw std::exception("Badly formed Ability");
                }

                newAbility.index = entry->value();

                m_abilities.push_back(newAbility);
            }
        }

        tableItem = tableItem->next_sibling();
    }
}

void AbilityParser::ExportFantasyGroundsXML()
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

        auto abilities = m_writer.AllocateNode(node_element, "abilities");
        entries->append_node(abilities);

        auto name = m_writer.AllocateNode(node_element, "name", "Abilities");
        name->append_attribute(m_writer.AllocateAttr("type", "string"));
        abilities->append_node(name);

        auto abilityEntries = m_writer.AllocateNode(node_element, "entries");
        abilities->append_node(abilityEntries);

        for (auto ability : m_abilities)
        {
            ExportAbility(ability, abilityEntries);
        }
    }
}

void AbilityParser::ExportAbility(Ability& ability, xml::xml_node<>* abilityEntries)
{
    auto entryNode = AddEntryToNode(abilityEntries, ability.name, "ability");

    auto entryDescription = m_writer.AllocateNode(node_element, "description");
    entryDescription->append_attribute(m_writer.AllocateAttr("type", "formattedtext"));

    auto index = m_writer.AllocateNode(node_element, "p", m_writer.AllocateString(ability.index.c_str()));
    entryDescription->append_node(index);
    auto desc = m_writer.AllocateNode(node_element, "p", m_writer.AllocateString(ability.desc.c_str()));
    entryDescription->append_node(desc);

    entryNode->append_node(entryDescription);
}
