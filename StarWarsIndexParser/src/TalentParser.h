#pragma once

#include "FantasyGroundsLibraryWriter.h"

#include <vector>

struct Talent
{
    std::string name;
    std::string activation;
    bool ranked{false};
    bool forceSensitive{false};
    std::string index;
};

class TalentParser
{
public:
    TalentParser(FantasyGroundsLibraryWriter& writer) : m_writer(writer) {}
    ~TalentParser() = default;

    void Parse();

private:
    void ParseXMLToTalents(const std::string& xml);
    void ExportFantasyGroundsXML();

    xml::xml_node<>* createCharactersLocation(xml::xml_node<>* library);

private:
    FantasyGroundsLibraryWriter& m_writer;
    std::vector<Talent> m_talents;
};
