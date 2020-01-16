#pragma once

#include <rapidxml.hpp>
#include <string>

namespace xml = rapidxml;

class FantasyGroundsLibraryWriter
{
public:
    FantasyGroundsLibraryWriter(const std::string& outputFile);
    ~FantasyGroundsLibraryWriter() = default;

    void GenerateDeclaration();

    void WriteToDisk();

    xml::xml_node<>* GetRootNode();
    xml::xml_node<>* GetLibraryNode();

    xml::xml_node<>* AllocateNode(xml::node_type type, const char* name = 0, const char* value = 0,
                                  std::size_t name_size = 0, std::size_t value_size = 0);
    xml::xml_attribute<>* AllocateAttr(const char* name = 0, const char* value = 0, std::size_t name_size = 0,
                                       std::size_t value_size = 0);
    char* AllocateString(const char* source, std::size_t size = 0);

private:
    xml::xml_document<> m_xmlDocument;
    xml::xml_node<>* m_rootNode{nullptr};
    std::string m_outputFilePathRelative;
};