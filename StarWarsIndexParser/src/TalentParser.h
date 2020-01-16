#pragma once

#include "Parser.h"

#include <rapidxml.hpp>
#include <string>
#include <vector>
namespace xml = rapidxml;

struct Talent
{
    std::string name;
    std::string activation;
    bool ranked{false};
    bool forceSensitive{false};
    std::string index;
};

class TalentParser final : public BaseParser
{
public:
    TalentParser(FantasyGroundsLibraryWriter& writer) : BaseParser(writer) {}
    ~TalentParser() = default;

    void Parse() override;

private:
    void ParseXMLToTalents(const std::string& xml);
    void ExportFantasyGroundsXML();
    void ExportTalent(Talent& talent, xml::xml_node<>* talentEntries);

private:
    std::vector<Talent> m_talents;
};
