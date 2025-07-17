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
#include <map>
#include <vector>
#include <stack>

// Simple JSON parser for fuzzing
class JSONParser {
public:
    enum JSONType {
        JSON_NULL,
        JSON_BOOL,
        JSON_NUMBER,
        JSON_STRING,
        JSON_ARRAY,
        JSON_OBJECT
    };

    struct JSONValue {
        JSONType type;
        std::string string_value;
        double number_value;
        bool bool_value;
        std::vector<JSONValue> array_value;
        std::map<std::string, JSONValue> object_value;
    };

    JSONValue root;

    bool parseJSON(const std::string& json_content) {
        try {
            size_t pos = 0;
            root = parseValue(json_content, pos);
            validateJSON();
            validatePackageJSON();
            validateSecurityConfig();
            return true;
        } catch (const std::exception& e) {
            // Expected for fuzzing - catch parsing errors
            return false;
        }
    }

private:
    JSONValue parseValue(const std::string& json, size_t& pos) {
        skipWhitespace(json, pos);
        
        if (pos >= json.length()) {
            throw std::runtime_error("Unexpected end of JSON");
        }
        
        char c = json[pos];
        
        switch (c) {
            case '"':
                return parseString(json, pos);
            case '{':
                return parseObject(json, pos);
            case '[':
                return parseArray(json, pos);
            case 't':
            case 'f':
                return parseBool(json, pos);
            case 'n':
                return parseNull(json, pos);
            default:
                if (c == '-' || (c >= '0' && c <= '9')) {
                    return parseNumber(json, pos);
                }
                throw std::runtime_error("Invalid JSON character");
        }
    }

    JSONValue parseString(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_STRING;
        
        if (json[pos] != '"') {
            throw std::runtime_error("Expected '\"'");
        }
        pos++; // Skip opening quote
        
        std::string result;
        while (pos < json.length() && json[pos] != '"') {
            if (json[pos] == '\\') {
                pos++; // Skip escape character
                if (pos >= json.length()) {
                    throw std::runtime_error("Unterminated escape sequence");
                }
                
                char escaped = json[pos];
                switch (escaped) {
                    case '"': result += '"'; break;
                    case '\\': result += '\\'; break;
                    case '/': result += '/'; break;
                    case 'b': result += '\b'; break;
                    case 'f': result += '\f'; break;
                    case 'n': result += '\n'; break;
                    case 'r': result += '\r'; break;
                    case 't': result += '\t'; break;
                    case 'u':
                        // Unicode escape sequence
                        pos++;
                        if (pos + 3 >= json.length()) {
                            throw std::runtime_error("Invalid unicode escape");
                        }
                        // Simplified unicode handling
                        pos += 3;
                        result += '?'; // Placeholder
                        break;
                    default:
                        throw std::runtime_error("Invalid escape character");
                }
            } else {
                result += json[pos];
            }
            pos++;
        }
        
        if (pos >= json.length() || json[pos] != '"') {
            throw std::runtime_error("Unterminated string");
        }
        pos++; // Skip closing quote
        
        value.string_value = result;
        return value;
    }

    JSONValue parseNumber(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_NUMBER;
        
        size_t start = pos;
        
        // Handle negative sign
        if (json[pos] == '-') {
            pos++;
        }
        
        // Parse integer part
        if (pos >= json.length() || !isdigit(json[pos])) {
            throw std::runtime_error("Invalid number format");
        }
        
        if (json[pos] == '0') {
            pos++;
        } else {
            while (pos < json.length() && isdigit(json[pos])) {
                pos++;
            }
        }
        
        // Parse fractional part
        if (pos < json.length() && json[pos] == '.') {
            pos++;
            if (pos >= json.length() || !isdigit(json[pos])) {
                throw std::runtime_error("Invalid number format");
            }
            while (pos < json.length() && isdigit(json[pos])) {
                pos++;
            }
        }
        
        // Parse exponent
        if (pos < json.length() && (json[pos] == 'e' || json[pos] == 'E')) {
            pos++;
            if (pos < json.length() && (json[pos] == '+' || json[pos] == '-')) {
                pos++;
            }
            if (pos >= json.length() || !isdigit(json[pos])) {
                throw std::runtime_error("Invalid number format");
            }
            while (pos < json.length() && isdigit(json[pos])) {
                pos++;
            }
        }
        
        std::string number_str = json.substr(start, pos - start);
        try {
            value.number_value = std::stod(number_str);
        } catch (const std::exception&) {
            throw std::runtime_error("Invalid number value");
        }
        
        return value;
    }

    JSONValue parseBool(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_BOOL;
        
        if (json.substr(pos, 4) == "true") {
            value.bool_value = true;
            pos += 4;
        } else if (json.substr(pos, 5) == "false") {
            value.bool_value = false;
            pos += 5;
        } else {
            throw std::runtime_error("Invalid boolean value");
        }
        
        return value;
    }

    JSONValue parseNull(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_NULL;
        
        if (json.substr(pos, 4) == "null") {
            pos += 4;
        } else {
            throw std::runtime_error("Invalid null value");
        }
        
        return value;
    }

    JSONValue parseArray(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_ARRAY;
        
        if (json[pos] != '[') {
            throw std::runtime_error("Expected '['");
        }
        pos++; // Skip opening bracket
        
        skipWhitespace(json, pos);
        
        // Empty array
        if (pos < json.length() && json[pos] == ']') {
            pos++;
            return value;
        }
        
        while (pos < json.length()) {
            JSONValue element = parseValue(json, pos);
            value.array_value.push_back(element);
            
            skipWhitespace(json, pos);
            
            if (pos >= json.length()) {
                throw std::runtime_error("Unterminated array");
            }
            
            if (json[pos] == ']') {
                pos++;
                break;
            } else if (json[pos] == ',') {
                pos++;
                skipWhitespace(json, pos);
            } else {
                throw std::runtime_error("Expected ',' or ']'");
            }
        }
        
        return value;
    }

    JSONValue parseObject(const std::string& json, size_t& pos) {
        JSONValue value;
        value.type = JSON_OBJECT;
        
        if (json[pos] != '{') {
            throw std::runtime_error("Expected '{'");
        }
        pos++; // Skip opening brace
        
        skipWhitespace(json, pos);
        
        // Empty object
        if (pos < json.length() && json[pos] == '}') {
            pos++;
            return value;
        }
        
        while (pos < json.length()) {
            // Parse key
            skipWhitespace(json, pos);
            if (pos >= json.length() || json[pos] != '"') {
                throw std::runtime_error("Expected string key");
            }
            
            JSONValue key_value = parseString(json, pos);
            std::string key = key_value.string_value;
            
            // Parse colon
            skipWhitespace(json, pos);
            if (pos >= json.length() || json[pos] != ':') {
                throw std::runtime_error("Expected ':'");
            }
            pos++;
            
            // Parse value
            JSONValue obj_value = parseValue(json, pos);
            value.object_value[key] = obj_value;
            
            skipWhitespace(json, pos);
            
            if (pos >= json.length()) {
                throw std::runtime_error("Unterminated object");
            }
            
            if (json[pos] == '}') {
                pos++;
                break;
            } else if (json[pos] == ',') {
                pos++;
                skipWhitespace(json, pos);
            } else {
                throw std::runtime_error("Expected ',' or '}'");
            }
        }
        
        return value;
    }

    void skipWhitespace(const std::string& json, size_t& pos) {
        while (pos < json.length() && 
               (json[pos] == ' ' || json[pos] == '\t' || 
                json[pos] == '\n' || json[pos] == '\r')) {
            pos++;
        }
    }

    void validateJSON() {
        validateValue(root);
    }

    void validateValue(const JSONValue& value) {
        switch (value.type) {
            case JSON_STRING:
                validateString(value.string_value);
                break;
            case JSON_ARRAY:
                for (const auto& element : value.array_value) {
                    validateValue(element);
                }
                break;
            case JSON_OBJECT:
                for (const auto& pair : value.object_value) {
                    validateString(pair.first); // Validate key
                    validateValue(pair.second); // Validate value
                }
                break;
            case JSON_NUMBER:
                validateNumber(value.number_value);
                break;
            default:
                break;
        }
    }

    void validateString(const std::string& str) {
        // Check for potential injection patterns
        if (str.find("javascript:") != std::string::npos ||
            str.find("data:") != std::string::npos ||
            str.find("<script") != std::string::npos) {
            throw std::runtime_error("Potential XSS pattern in string");
        }
        
        // Check for null bytes
        if (str.find('\0') != std::string::npos) {
            throw std::runtime_error("Null byte in string");
        }
        
        // Check string length limits
        if (str.length() > 10000) {
            throw std::runtime_error("String too long");
        }
    }

    void validateNumber(double num) {
        // Check for NaN and infinity
        if (std::isnan(num) || std::isinf(num)) {
            throw std::runtime_error("Invalid number value");
        }
        
        // Check for extremely large numbers
        if (num > 1e100 || num < -1e100) {
            throw std::runtime_error("Number out of range");
        }
    }

    void validatePackageJSON() {
        if (root.type != JSON_OBJECT) return;
        
        // Check if this looks like a package.json
        auto name_it = root.object_value.find("name");
        auto version_it = root.object_value.find("version");
        
        if (name_it != root.object_value.end() && version_it != root.object_value.end()) {
            validatePackageFields();
        }
    }

    void validatePackageFields() {
        // Validate package name
        auto name_it = root.object_value.find("name");
        if (name_it != root.object_value.end() && name_it->second.type == JSON_STRING) {
            validatePackageName(name_it->second.string_value);
        }
        
        // Validate version
        auto version_it = root.object_value.find("version");
        if (version_it != root.object_value.end() && version_it->second.type == JSON_STRING) {
            validateSemanticVersion(version_it->second.string_value);
        }
        
        // Validate scripts
        auto scripts_it = root.object_value.find("scripts");
        if (scripts_it != root.object_value.end() && scripts_it->second.type == JSON_OBJECT) {
            validatePackageScripts(scripts_it->second);
        }
        
        // Validate dependencies
        auto deps_it = root.object_value.find("dependencies");
        if (deps_it != root.object_value.end() && deps_it->second.type == JSON_OBJECT) {
            validateDependencies(deps_it->second);
        }
    }

    void validatePackageName(const std::string& name) {
        // Package name validation rules
        if (name.empty()) {
            throw std::runtime_error("Package name cannot be empty");
        }
        
        if (name.length() > 214) {
            throw std::runtime_error("Package name too long");
        }
        
        if (name[0] == '.' || name[0] == '_') {
            throw std::runtime_error("Package name cannot start with . or _");
        }
        
        // Check for invalid characters
        for (char c : name) {
            if (!isalnum(c) && c != '-' && c != '_' && c != '.' && c != '/') {
                throw std::runtime_error("Invalid character in package name");
            }
        }
    }

    void validateSemanticVersion(const std::string& version) {
        // Basic semantic version validation (simplified)
        size_t dot_count = 0;
        for (char c : version) {
            if (c == '.') dot_count++;
            else if (!isdigit(c) && c != '-' && c != '+' && !isalpha(c)) {
                throw std::runtime_error("Invalid character in version");
            }
        }
        
        if (dot_count < 2) {
            throw std::runtime_error("Invalid semantic version format");
        }
    }

    void validatePackageScripts(const JSONValue& scripts) {
        for (const auto& script : scripts.object_value) {
            if (script.second.type == JSON_STRING) {
                validateScriptCommand(script.second.string_value);
            }
        }
    }

    void validateScriptCommand(const std::string& command) {
        // Check for dangerous script patterns
        std::vector<std::string> dangerous_patterns = {
            "rm -rf", "sudo rm", "del /f", "format c:",
            "curl | sh", "wget | sh", "curl | bash"
        };
        
        for (const auto& pattern : dangerous_patterns) {
            if (command.find(pattern) != std::string::npos) {
                throw std::runtime_error("Dangerous script pattern: " + pattern);
            }
        }
    }

    void validateDependencies(const JSONValue& deps) {
        for (const auto& dep : deps.object_value) {
            if (dep.second.type == JSON_STRING) {
                validateDependencyVersion(dep.first, dep.second.string_value);
            }
        }
    }

    void validateDependencyVersion(const std::string& package, const std::string& version) {
        // Validate dependency version specifiers
        if (version.empty()) {
            throw std::runtime_error("Empty version for dependency: " + package);
        }
        
        // Check for suspicious version patterns
        if (version.find("git+") == 0 || version.find("http://") == 0) {
            // Git or HTTP dependencies might be risky
        }
        
        // Check for extremely permissive ranges
        if (version == "*" || version == "latest") {
            // Very permissive version specifiers
        }
    }

    void validateSecurityConfig() {
        // Check if this looks like a security configuration file
        auto tools_it = root.object_value.find("tools");
        auto policies_it = root.object_value.find("policies");
        
        if (tools_it != root.object_value.end() || policies_it != root.object_value.end()) {
            validateSecurityJSON();
        }
    }

    void validateSecurityJSON() {
        // Validate security-specific JSON configurations
        auto tools_it = root.object_value.find("tools");
        if (tools_it != root.object_value.end() && tools_it->second.type == JSON_OBJECT) {
            validateSecurityTools(tools_it->second);
        }
        
        auto policies_it = root.object_value.find("policies");
        if (policies_it != root.object_value.end() && policies_it->second.type == JSON_OBJECT) {
            validateSecurityPolicies(policies_it->second);
        }
    }

    void validateSecurityTools(const JSONValue& tools) {
        // Validate security tools configuration
        for (const auto& tool_category : tools.object_value) {
            if (tool_category.second.type == JSON_OBJECT) {
                for (const auto& tool : tool_category.second.object_value) {
                    validateSecurityTool(tool.first, tool.second);
                }
            }
        }
    }

    void validateSecurityTool(const std::string& tool_name, const JSONValue& config) {
        if (config.type != JSON_OBJECT) return;
        
        // Check for required configuration fields
        auto enabled_it = config.object_value.find("enabled");
        if (enabled_it != config.object_value.end() && 
            enabled_it->second.type == JSON_BOOL &&
            enabled_it->second.bool_value) {
            
            // Tool is enabled, validate its configuration
            validateEnabledSecurityTool(tool_name, config);
        }
    }

    void validateEnabledSecurityTool(const std::string& tool_name, const JSONValue& config) {
        // Validate specific tool configurations
        if (tool_name == "gitleaks" || tool_name == "trufflehog") {
            validateSecretScanningTool(config);
        } else if (tool_name == "checkov" || tool_name == "tfsec") {
            validateInfrastructureTool(config);
        }
    }

    void validateSecretScanningTool(const JSONValue& config) {
        // Validate secret scanning tool configuration
        auto version_it = config.object_value.find("version");
        if (version_it != config.object_value.end() && version_it->second.type == JSON_STRING) {
            // Validate version format
        }
    }

    void validateInfrastructureTool(const JSONValue& config) {
        // Validate infrastructure scanning tool configuration
        auto format_it = config.object_value.find("output_format");
        if (format_it != config.object_value.end() && format_it->second.type == JSON_STRING) {
            std::string format = format_it->second.string_value;
            if (format != "sarif" && format != "json" && format != "xml") {
                throw std::runtime_error("Invalid output format: " + format);
            }
        }
    }

    void validateSecurityPolicies(const JSONValue& policies) {
        // Validate security policies
        for (const auto& policy : policies.object_value) {
            validateSecurityPolicy(policy.first, policy.second);
        }
    }

    void validateSecurityPolicy(const std::string& policy_name, const JSONValue& policy_config) {
        if (policy_name == "vulnerabilities" && policy_config.type == JSON_OBJECT) {
            validateVulnerabilityPolicy(policy_config);
        }
    }

    void validateVulnerabilityPolicy(const JSONValue& vuln_policy) {
        // Validate vulnerability policy thresholds
        for (const auto& threshold : vuln_policy.object_value) {
            if (threshold.second.type == JSON_NUMBER) {
                if (threshold.second.number_value < 0) {
                    throw std::runtime_error("Negative vulnerability threshold");
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

    std::string json_content(reinterpret_cast<const char*>(Data), Size);
    
    JSONParser parser;
    parser.parseJSON(json_content);
    
    return 0;
}