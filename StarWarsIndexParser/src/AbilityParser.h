#pragma once

#include "Parser.h"

#include <rapidxml.hpp>
#include <string>
#include <vector>
namespace xml = rapidxml;

struct Ability
{
    std::string name;
    std::string desc;
    std::string index;
};

class AbilityParser final : public BaseParser
{
public:
    AbilityParser(FantasyGroundsLibraryWriter& writer) : BaseParser(writer) {}
    ~AbilityParser() = default;

    void Parse() override;

private:
    void ParseXMLToAbilities(const std::string& xml);
    void ExportFantasyGroundsXML();
    void ExportAbility(Ability& ability, xml::xml_node<>* abilityEntries);

private:
    std::vector<Ability> m_abilities;
};