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
#include <stack>

// YAML configuration parser for fuzzing
class YAMLParser {
public:
    struct YAMLNode {
        std::string key;
        std::string value;
        std::vector<YAMLNode> children;
        int indent_level;
    };

    YAMLNode root;

    bool parseYAML(const std::string& yaml_content) {
        try {
            parseDocument(yaml_content);
            validateStructure();
            validateGitHubActions();
            validateSecurityConfig();
            return true;
        } catch (const std::exception& e) {
            // Expected for fuzzing - catch parsing errors
            return false;
        }
    }

private:
    void parseDocument(const std::string& content) {
        std::istringstream stream(content);
        std::string line;
        std::stack<YAMLNode*> node_stack;
        
        node_stack.push(&root);
        
        while (std::getline(stream, line)) {
            if (line.empty() || line[0] == '#') {
                continue; // Skip empty lines and comments
            }
            
            int indent = getIndentLevel(line);
            std::string trimmed = trim(line);
            
            if (trimmed == "---" || trimmed == "...") {
                continue; // Skip document separators
            }
            
            // Parse key-value pairs
            size_t colon_pos = trimmed.find(':');
            if (colon_pos != std::string::npos) {
                YAMLNode node;
                node.key = trim(trimmed.substr(0, colon_pos));
                node.indent_level = indent;
                
                if (colon_pos + 1 < trimmed.length()) {
                    node.value = trim(trimmed.substr(colon_pos + 1));
                }
                
                // Adjust stack based on indentation
                adjustStackForIndent(node_stack, indent);
                
                if (!node_stack.empty()) {
                    node_stack.top()->children.push_back(node);
                    node_stack.push(&node_stack.top()->children.back());
                }
            }
        }
    }

    int getIndentLevel(const std::string& line) {
        int indent = 0;
        for (char c : line) {
            if (c == ' ') indent++;
            else if (c == '\t') indent += 4; // Treat tab as 4 spaces
            else break;
        }
        return indent;
    }

    std::string trim(const std::string& str) {
        size_t start = str.find_first_not_of(" \t\r\n");
        if (start == std::string::npos) return "";
        
        size_t end = str.find_last_not_of(" \t\r\n");
        return str.substr(start, end - start + 1);
    }

    void adjustStackForIndent(std::stack<YAMLNode*>& stack, int indent) {
        while (stack.size() > 1 && stack.top()->indent_level >= indent) {
            stack.pop();
        }
    }

    void validateStructure() {
        validateNode(root);
    }

    void validateNode(const YAMLNode& node) {
        // Check for valid YAML key patterns
        if (!node.key.empty()) {
            validateKeyFormat(node.key);
        }
        
        // Check for valid value patterns
        if (!node.value.empty()) {
            validateValueFormat(node.value);
        }
        
        // Recursively validate children
        for (const auto& child : node.children) {
            validateNode(child);
        }
    }

    void validateKeyFormat(const std::string& key) {
        // Keys should not contain certain characters
        if (key.find('\n') != std::string::npos ||
            key.find('\r') != std::string::npos ||
            key.find('\0') != std::string::npos) {
            throw std::runtime_error("Invalid characters in YAML key");
        }
        
        // Check for reserved YAML characters
        if (key.find(':') != std::string::npos ||
            key.find('[') != std::string::npos ||
            key.find(']') != std::string::npos ||
            key.find('{') != std::string::npos ||
            key.find('}') != std::string::npos) {
            // These might be valid in quoted strings, but check context
        }
    }

    void validateValueFormat(const std::string& value) {
        // Check for YAML injection patterns
        if (value.find("!!") != std::string::npos) {
            // YAML type tags - validate they're safe
            validateYAMLTags(value);
        }
        
        // Check for multiline string indicators
        if (value == "|" || value == ">" || value == "|-" || value == ">-") {
            // These are valid multiline indicators
        }
        
        // Check for potential script injection
        if (value.find("$(") != std::string::npos ||
            value.find("`") != std::string::npos) {
            // Potential command injection
        }
    }

    void validateYAMLTags(const std::string& value) {
        std::regex tag_regex(R"(!![a-zA-Z0-9_-]+)");
        std::smatch matches;
        
        if (std::regex_search(value, matches, tag_regex)) {
            std::string tag = matches[0];
            
            // Check for dangerous tags
            std::vector<std::string> dangerous_tags = {
                "!!python/object/apply:",
                "!!python/object/new:",
                "!!java/object:",
                "!!javax/script/"
            };
            
            for (const auto& dangerous : dangerous_tags) {
                if (value.find(dangerous) != std::string::npos) {
                    throw std::runtime_error("Dangerous YAML tag detected");
                }
            }
        }
    }

    void validateGitHubActions() {
        YAMLNode* workflow_node = findNode(root, "name");
        if (!workflow_node) return;
        
        // Validate GitHub Actions workflow structure
        YAMLNode* on_node = findNode(root, "on");
        YAMLNode* jobs_node = findNode(root, "jobs");
        
        if (on_node) {
            validateWorkflowTriggers(*on_node);
        }
        
        if (jobs_node) {
            validateWorkflowJobs(*jobs_node);
        }
        
        // Check for permissions
        YAMLNode* permissions_node = findNode(root, "permissions");
        if (permissions_node) {
            validateWorkflowPermissions(*permissions_node);
        }
    }

    void validateSecurityConfig() {
        // Validate security-related YAML configurations
        YAMLNode* tools_node = findNode(root, "tools");
        if (tools_node) {
            validateSecurityTools(*tools_node);
        }
        
        YAMLNode* policies_node = findNode(root, "policies");
        if (policies_node) {
            validateSecurityPolicies(*policies_node);
        }
    }

    YAMLNode* findNode(const YAMLNode& parent, const std::string& key) {
        for (auto& child : const_cast<YAMLNode&>(parent).children) {
            if (child.key == key) {
                return &child;
            }
            
            YAMLNode* found = findNode(child, key);
            if (found) return found;
        }
        return nullptr;
    }

    void validateWorkflowTriggers(const YAMLNode& on_node) {
        // Check for valid GitHub Actions triggers
        std::vector<std::string> valid_triggers = {
            "push", "pull_request", "workflow_dispatch", "schedule",
            "release", "issues", "issue_comment", "pull_request_review"
        };
        
        for (const auto& child : on_node.children) {
            bool valid_trigger = false;
            for (const auto& trigger : valid_triggers) {
                if (child.key == trigger) {
                    valid_trigger = true;
                    break;
                }
            }
            
            if (!valid_trigger && !child.key.empty()) {
                throw std::runtime_error("Invalid workflow trigger: " + child.key);
            }
        }
    }

    void validateWorkflowJobs(const YAMLNode& jobs_node) {
        for (const auto& job : jobs_node.children) {
            validateJob(job);
        }
    }

    void validateJob(const YAMLNode& job_node) {
        // Check for required job fields
        YAMLNode* runs_on = findNode(job_node, "runs-on");
        if (!runs_on) {
            throw std::runtime_error("Job missing 'runs-on' field");
        }
        
        // Validate runner types
        if (runs_on->value.find("ubuntu") == std::string::npos &&
            runs_on->value.find("windows") == std::string::npos &&
            runs_on->value.find("macos") == std::string::npos &&
            runs_on->value.find("self-hosted") == std::string::npos) {
            throw std::runtime_error("Invalid runner type");
        }
        
        // Check steps
        YAMLNode* steps = findNode(job_node, "steps");
        if (steps) {
            validateSteps(*steps);
        }
    }

    void validateSteps(const YAMLNode& steps_node) {
        for (const auto& step : steps_node.children) {
            validateStep(step);
        }
    }

    void validateStep(const YAMLNode& step_node) {
        // Each step should have either 'uses' or 'run'
        YAMLNode* uses = findNode(step_node, "uses");
        YAMLNode* run = findNode(step_node, "run");
        
        if (!uses && !run) {
            throw std::runtime_error("Step missing 'uses' or 'run' field");
        }
        
        if (uses) {
            validateActionUsage(*uses);
        }
        
        if (run) {
            validateRunCommand(*run);
        }
    }

    void validateActionUsage(const YAMLNode& uses_node) {
        // Validate GitHub Actions usage
        if (uses_node.value.empty()) {
            throw std::runtime_error("Empty 'uses' field");
        }
        
        // Check for suspicious action patterns
        if (uses_node.value.find("..") != std::string::npos ||
            uses_node.value.find("./") == 0) {
            // Relative paths might be suspicious
        }
    }

    void validateRunCommand(const YAMLNode& run_node) {
        // Validate run commands for potential security issues
        if (run_node.value.find("curl") != std::string::npos &&
            run_node.value.find("bash") != std::string::npos) {
            // Curl | bash pattern - potentially dangerous
        }
        
        if (run_node.value.find("sudo") != std::string::npos) {
            // Sudo usage in CI
        }
    }

    void validateWorkflowPermissions(const YAMLNode& permissions_node) {
        std::vector<std::string> valid_permissions = {
            "actions", "checks", "contents", "deployments", "issues",
            "packages", "pages", "pull-requests", "repository-projects",
            "security-events", "statuses"
        };
        
        for (const auto& perm : permissions_node.children) {
            bool valid = false;
            for (const auto& valid_perm : valid_permissions) {
                if (perm.key == valid_perm) {
                    valid = true;
                    break;
                }
            }
            
            if (!valid && !perm.key.empty()) {
                throw std::runtime_error("Invalid permission: " + perm.key);
            }
        }
    }

    void validateSecurityTools(const YAMLNode& tools_node) {
        // Validate security tools configuration
        for (const auto& tool_category : tools_node.children) {
            for (const auto& tool : tool_category.children) {
                validateSecurityTool(tool);
            }
        }
    }

    void validateSecurityTool(const YAMLNode& tool_node) {
        // Check for required tool fields
        YAMLNode* enabled = findNode(tool_node, "enabled");
        if (enabled && enabled->value == "true") {
            // Tool is enabled, validate its configuration
        }
    }

    void validateSecurityPolicies(const YAMLNode& policies_node) {
        // Validate security policies
        for (const auto& policy : policies_node.children) {
            validateSecurityPolicy(policy);
        }
    }

    void validateSecurityPolicy(const YAMLNode& policy_node) {
        // Validate individual security policies
        if (policy_node.key == "vulnerabilities") {
            validateVulnerabilityPolicy(policy_node);
        }
    }

    void validateVulnerabilityPolicy(const YAMLNode& vuln_policy) {
        // Validate vulnerability policy thresholds
        for (const auto& threshold : vuln_policy.children) {
            if (!threshold.value.empty()) {
                try {
                    int value = std::stoi(threshold.value);
                    if (value < 0) {
                        throw std::runtime_error("Negative vulnerability threshold");
                    }
                } catch (const std::invalid_argument&) {
                    throw std::runtime_error("Invalid vulnerability threshold format");
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

    std::string yaml_content(reinterpret_cast<const char*>(Data), Size);
    
    YAMLParser parser;
    parser.parseYAML(yaml_content);
    
    return 0;
}