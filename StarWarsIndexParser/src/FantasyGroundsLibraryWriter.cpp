#include "FantasyGroundsLibraryWriter.h"

#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <rapidxml.hpp>
#include <rapidxml_iterators.hpp>
#include <rapidxml_print.hpp>
#include <rapidxml_utils.hpp>

namespace fs = boost::filesystem;
using namespace rapidxml;

FantasyGroundsLibraryWriter::FantasyGroundsLibraryWriter(const std::string& outputFile)
    : m_outputFilePathRelative(outputFile)
{
    GenerateDeclaration();
}

void FantasyGroundsLibraryWriter::GenerateDeclaration()
{
    // xml declaration
    xml_node<>* decl = AllocateNode(node_declaration);
    decl->append_attribute(AllocateAttr("version", "1.0"));
    decl->append_attribute(AllocateAttr("encoding", "ISO-8859-1"));
    m_xmlDocument.append_node(decl);

    // root node
    m_rootNode = AllocateNode(node_element, "root");
    m_rootNode->append_attribute(AllocateAttr("version", "2.0"));
    m_xmlDocument.append_node(m_rootNode);

    // root.library
    xml_node<>* library = AllocateNode(node_element, "library");
    library->append_attribute(AllocateAttr("static", "true"));
    m_rootNode->append_node(library);
}

void FantasyGroundsLibraryWriter::WriteToDisk()
{
    std::string xmlAsString;
    print(std::back_inserter(xmlAsString), m_xmlDocument);

    if (!xmlAsString.empty())
    {
        fs::path outP(m_outputFilePathRelative);
        fs::ofstream ofs{outP};
        ofs << xmlAsString;
    }
}

xml_node<>* FantasyGroundsLibraryWriter::GetRootNode() { return m_rootNode; }

xml_node<>* FantasyGroundsLibraryWriter::GetLibraryNode()
{
    if (!m_rootNode) return nullptr;
    return m_rootNode->first_node("library");
}

xml::xml_node<>* FantasyGroundsLibraryWriter::AllocateNode(xml::node_type type, const char* name /*= 0*/,
                                                           const char* value /*= 0*/, std::size_t name_size /*= 0*/,
                                                           std::size_t value_size /*= 0*/)
{
    return m_xmlDocument.allocate_node(type, name, value, name_size, value_size);
}

xml::xml_attribute<>* FantasyGroundsLibraryWriter::AllocateAttr(const char* name /*= 0*/, const char* value /*= 0*/,
                                                                std::size_t name_size /*= 0*/,
                                                                std::size_t value_size /*= 0*/)
{
    return m_xmlDocument.allocate_attribute(name, value, name_size, value_size);
}

char* FantasyGroundsLibraryWriter::AllocateString(const char* source, std::size_t size /*= 0*/)
{
    return m_xmlDocument.allocate_string(source, size);
}
