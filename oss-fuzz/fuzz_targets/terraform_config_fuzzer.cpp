// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <cstdint>
#include <cstring>
#include <string>
#include <iostream>
#include <sstream>
#include <regex>
#include <vector>
#include <map>

// Terraform configuration parser for fuzzing
class TerraformParser {
public:
    struct Resource {
        std::string type;
        std::string name;
        std::map<std::string, std::string> attributes;
    };

    struct Variable {
        std::string name;
        std::string type;
        std::string description;
        std::string default_value;
    };

    std::vector<Resource> resources;
    std::vector<Variable> variables;

    bool parseConfig(const std::string& config) {
        try {
            parseResources(config);
            parseVariables(config);
            parseProviders(config);
            parseOutputs(config);
            validateSyntax(config);
            return true;
        } catch (const std::exception& e) {
            // Expected for fuzzing - catch parsing errors
            return false;
        }
    }

private:
    void parseResources(const std::string& config) {
        std::regex resource_regex(R"(resource\s+"([^"]+)"\s+"([^"]+)"\s*\{([^}]*)\})");
        std::smatch matches;
        
        std::string::const_iterator searchStart(config.cbegin());
        while (std::regex_search(searchStart, config.cend(), matches, resource_regex)) {
            Resource resource;
            resource.type = matches[1];
            resource.name = matches[2];
            
            // Parse attributes within the resource block
            std::string attributes = matches[3];
            parseAttributes(attributes, resource.attributes);
            
            resources.push_back(resource);
            searchStart = matches.suffix().first;
        }
    }

    void parseVariables(const std::string& config) {
        std::regex var_regex(R"(variable\s+"([^"]+)"\s*\{([^}]*)\})");
        std::smatch matches;
        
        std::string::const_iterator searchStart(config.cbegin());
        while (std::regex_search(searchStart, config.cend(), matches, var_regex)) {
            Variable variable;
            variable.name = matches[1];
            
            std::string var_block = matches[2];
            parseVariableAttributes(var_block, variable);
            
            variables.push_back(variable);
            searchStart = matches.suffix().first;
        }
    }

    void parseProviders(const std::string& config) {
        std::regex provider_regex(R"(provider\s+"([^"]+)"\s*\{([^}]*)\})");
        std::smatch matches;
        
        std::string::const_iterator searchStart(config.cbegin());
        while (std::regex_search(searchStart, config.cend(), matches, provider_regex)) {
            // Validate provider configuration
            std::string provider_name = matches[1];
            std::string provider_config = matches[2];
            
            // Check for common GCP provider attributes
            if (provider_name == "google" || provider_name == "google-beta") {
                validateGCPProvider(provider_config);
            }
            
            searchStart = matches.suffix().first;
        }
    }

    void parseOutputs(const std::string& config) {
        std::regex output_regex(R"(output\s+"([^"]+)"\s*\{([^}]*)\})");
        std::smatch matches;
        
        std::string::const_iterator searchStart(config.cbegin());
        while (std::regex_search(searchStart, config.cend(), matches, output_regex)) {
            std::string output_name = matches[1];
            std::string output_config = matches[2];
            
            // Validate output configuration
            if (output_config.find("value") == std::string::npos) {
                throw std::runtime_error("Output missing required 'value' attribute");
            }
            
            searchStart = matches.suffix().first;
        }
    }

    void parseAttributes(const std::string& attributes, std::map<std::string, std::string>& attr_map) {
        std::regex attr_regex(R"((\w+)\s*=\s*"([^"]*)")");
        std::smatch matches;
        
        std::string::const_iterator searchStart(attributes.cbegin());
        while (std::regex_search(searchStart, attributes.cend(), matches, attr_regex)) {
            attr_map[matches[1]] = matches[2];
            searchStart = matches.suffix().first;
        }
    }

    void parseVariableAttributes(const std::string& var_block, Variable& variable) {
        if (var_block.find("type") != std::string::npos) {
            std::regex type_regex(R"(type\s*=\s*(\w+))");
            std::smatch type_match;
            if (std::regex_search(var_block, type_match, type_regex)) {
                variable.type = type_match[1];
            }
        }
        
        if (var_block.find("description") != std::string::npos) {
            std::regex desc_regex(R"(description\s*=\s*"([^"]*)")");
            std::smatch desc_match;
            if (std::regex_search(var_block, desc_match, desc_regex)) {
                variable.description = desc_match[1];
            }
        }
    }

    void validateGCPProvider(const std::string& provider_config) {
        // Check for required GCP provider configurations
        std::vector<std::string> gcp_attrs = {"project", "region", "zone"};
        for (const auto& attr : gcp_attrs) {
            if (provider_config.find(attr) != std::string::npos) {
                // Validate attribute format
                validateGCPAttribute(attr, provider_config);
            }
        }
    }

    void validateGCPAttribute(const std::string& attr, const std::string& config) {
        if (attr == "project") {
            std::regex project_regex(R"(project\s*=\s*"([a-z0-9-]+)")");
            if (!std::regex_search(config, project_regex)) {
                throw std::runtime_error("Invalid GCP project format");
            }
        } else if (attr == "region") {
            std::regex region_regex(R"(region\s*=\s*"([a-z0-9-]+)")");
            if (!std::regex_search(config, region_regex)) {
                throw std::runtime_error("Invalid GCP region format");
            }
        }
    }

    void validateSyntax(const std::string& config) {
        // Check for balanced braces
        int brace_count = 0;
        for (char c : config) {
            if (c == '{') brace_count++;
            else if (c == '}') brace_count--;
            
            if (brace_count < 0) {
                throw std::runtime_error("Unbalanced braces");
            }
        }
        
        if (brace_count != 0) {
            throw std::runtime_error("Unbalanced braces");
        }
        
        // Check for valid Terraform syntax patterns
        validateTerraformKeywords(config);
    }

    void validateTerraformKeywords(const std::string& config) {
        std::vector<std::string> keywords = {
            "resource", "provider", "variable", "output", "data", 
            "module", "locals", "terraform"
        };
        
        for (const auto& keyword : keywords) {
            if (config.find(keyword) != std::string::npos) {
                // Validate keyword usage context
                std::regex keyword_regex(keyword + R"(\s+[^{]*\{)");
                if (keyword != "locals" && keyword != "terraform" && 
                    !std::regex_search(config, keyword_regex)) {
                    throw std::runtime_error("Invalid keyword usage: " + keyword);
                }
            }
        }
    }
};

// Fuzzing entry point
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    if (Size == 0 || Size > 65536) {
        return 0;
    }

    std::string terraform_config(reinterpret_cast<const char*>(Data), Size);
    
    TerraformParser parser;
    parser.parseConfig(terraform_config);
    
    // Additional validation checks that might find edge cases
    if (!terraform_config.empty()) {
        // Test various parsing scenarios
        try {
            // Check for potential injection patterns
            if (terraform_config.find("$(") != std::string::npos ||
                terraform_config.find("${") != std::string::npos) {
                // Handle interpolation syntax
            }
            
            // Check for heredoc syntax
            if (terraform_config.find("<<") != std::string::npos) {
                // Handle heredoc blocks
            }
            
            // Validate string escaping
            if (terraform_config.find("\\") != std::string::npos) {
                // Handle escaped characters
            }
            
        } catch (...) {
            // Catch any exceptions during additional validation
        }
    }
    
    return 0;
}