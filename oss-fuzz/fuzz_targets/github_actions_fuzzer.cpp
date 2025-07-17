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
#include <set>

// GitHub Actions workflow parser and validator for fuzzing
class GitHubActionsParser {
public:
    struct Step {
        std::string name;
        std::string uses;
        std::string run;
        std::map<std::string, std::string> with;
        std::map<std::string, std::string> env;
        std::string if_condition;
    };

    struct Job {
        std::string name;
        std::string runs_on;
        std::vector<std::string> needs;
        std::map<std::string, std::string> permissions;
        std::vector<Step> steps;
        std::map<std::string, std::string> env;
        std::string if_condition;
        int timeout_minutes = 360; // Default timeout
    };

    struct Workflow {
        std::string name;
        std::map<std::string, std::string> on_events;
        std::map<std::string, std::string> permissions;
        std::map<std::string, Job> jobs;
        std::map<std::string, std::string> env;
    };

    Workflow workflow;

    bool parseWorkflow(const std::string& yaml_content) {
        try {
            parseBasicStructure(yaml_content);
            validateWorkflowStructure();
            validateSecurity();
            validatePerformance();
            validateBestPractices();
            return true;
        } catch (const std::exception& e) {
            // Expected for fuzzing - catch parsing errors
            return false;
        }
    }

private:
    void parseBasicStructure(const std::string& content) {
        // Simplified YAML parsing for GitHub Actions
        std::istringstream stream(content);
        std::string line;
        std::string current_section;
        std::string current_job;
        
        while (std::getline(stream, line)) {
            line = trim(line);
            
            if (line.empty() || line[0] == '#') {
                continue;
            }
            
            if (line.find("name:") == 0) {
                workflow.name = extractValue(line);
            } else if (line.find("on:") == 0) {
                current_section = "on";
                parseOnSection(stream);
            } else if (line.find("permissions:") == 0) {
                current_section = "permissions";
                parsePermissionsSection(stream, workflow.permissions);
            } else if (line.find("jobs:") == 0) {
                current_section = "jobs";
                parseJobsSection(stream);
            } else if (line.find("env:") == 0) {
                current_section = "env";
                parseEnvSection(stream, workflow.env);
            }
        }
    }

    void parseOnSection(std::istringstream& stream) {
        std::string line;
        while (std::getline(stream, line)) {
            line = trim(line);
            if (line.empty() || line[0] == '#') continue;
            
            // If we hit another top-level section, put the line back
            if (isTopLevelSection(line)) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find(':') != std::string::npos) {
                std::string key = extractKey(line);
                std::string value = extractValue(line);
                workflow.on_events[key] = value;
            }
        }
    }

    void parsePermissionsSection(std::istringstream& stream, std::map<std::string, std::string>& permissions) {
        std::string line;
        while (std::getline(stream, line)) {
            line = trim(line);
            if (line.empty() || line[0] == '#') continue;
            
            if (isTopLevelSection(line)) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find(':') != std::string::npos) {
                std::string key = extractKey(line);
                std::string value = extractValue(line);
                permissions[key] = value;
            }
        }
    }

    void parseJobsSection(std::istringstream& stream) {
        std::string line;
        std::string current_job;
        
        while (std::getline(stream, line)) {
            line = trim(line);
            if (line.empty() || line[0] == '#') continue;
            
            if (isTopLevelSection(line)) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            // Job definition (at base indentation under jobs:)
            if (line.find(':') != std::string::npos && getIndentLevel(line) == 2) {
                current_job = extractKey(line);
                workflow.jobs[current_job] = Job();
                parseJob(stream, workflow.jobs[current_job]);
            }
        }
    }

    void parseJob(std::istringstream& stream, Job& job) {
        std::string line;
        
        while (std::getline(stream, line)) {
            if (line.empty() || line[0] == '#') continue;
            
            int indent = getIndentLevel(line);
            line = trim(line);
            
            // If we're back to job level or higher, put line back
            if (indent <= 2) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find("name:") == 0) {
                job.name = extractValue(line);
            } else if (line.find("runs-on:") == 0) {
                job.runs_on = extractValue(line);
            } else if (line.find("timeout-minutes:") == 0) {
                job.timeout_minutes = std::stoi(extractValue(line));
            } else if (line.find("if:") == 0) {
                job.if_condition = extractValue(line);
            } else if (line.find("needs:") == 0) {
                parseNeedsSection(stream, job.needs);
            } else if (line.find("permissions:") == 0) {
                parsePermissionsSection(stream, job.permissions);
            } else if (line.find("env:") == 0) {
                parseEnvSection(stream, job.env);
            } else if (line.find("steps:") == 0) {
                parseStepsSection(stream, job.steps);
            }
        }
    }

    void parseNeedsSection(std::istringstream& stream, std::vector<std::string>& needs) {
        // Simplified parsing - could be array or single value
        std::string line;
        if (std::getline(stream, line)) {
            line = trim(line);
            if (line.find('-') == 0) {
                // Array format
                needs.push_back(trim(line.substr(1)));
                
                while (std::getline(stream, line)) {
                    line = trim(line);
                    if (line.find('-') == 0) {
                        needs.push_back(trim(line.substr(1)));
                    } else {
                        stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                        break;
                    }
                }
            } else {
                // Single value on same line
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
            }
        }
    }

    void parseEnvSection(std::istringstream& stream, std::map<std::string, std::string>& env) {
        std::string line;
        while (std::getline(stream, line)) {
            line = trim(line);
            if (line.empty() || line[0] == '#') continue;
            
            int indent = getIndentLevel(line);
            if (indent <= 4) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find(':') != std::string::npos) {
                std::string key = extractKey(line);
                std::string value = extractValue(line);
                env[key] = value;
            }
        }
    }

    void parseStepsSection(std::istringstream& stream, std::vector<Step>& steps) {
        std::string line;
        
        while (std::getline(stream, line)) {
            if (line.empty() || line[0] == '#') continue;
            
            int indent = getIndentLevel(line);
            line = trim(line);
            
            // If we're back to job level, put line back
            if (indent <= 4) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            // New step
            if (line.find('-') == 0) {
                Step step;
                parseStep(stream, step, line);
                steps.push_back(step);
            }
        }
    }

    void parseStep(std::istringstream& stream, Step& step, const std::string& first_line) {
        // Parse the first line after the dash
        std::string content = trim(first_line.substr(1)); // Remove dash
        if (!content.empty() && content.find(':') != std::string::npos) {
            std::string key = extractKey(content);
            std::string value = extractValue(content);
            
            if (key == "name") step.name = value;
            else if (key == "uses") step.uses = value;
            else if (key == "run") step.run = value;
            else if (key == "if") step.if_condition = value;
        }
        
        // Parse subsequent lines
        std::string line;
        while (std::getline(stream, line)) {
            if (line.empty() || line[0] == '#') continue;
            
            int indent = getIndentLevel(line);
            line = trim(line);
            
            // If we hit another step or back to job level
            if (indent <= 6 || line.find('-') == 0) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find(':') != std::string::npos) {
                std::string key = extractKey(line);
                std::string value = extractValue(line);
                
                if (key == "name") step.name = value;
                else if (key == "uses") step.uses = value;
                else if (key == "run") step.run = value;
                else if (key == "if") step.if_condition = value;
                else if (key == "with") {
                    parseWithSection(stream, step.with);
                } else if (key == "env") {
                    parseStepEnvSection(stream, step.env);
                }
            }
        }
    }

    void parseWithSection(std::istringstream& stream, std::map<std::string, std::string>& with) {
        std::string line;
        while (std::getline(stream, line)) {
            line = trim(line);
            if (line.empty() || line[0] == '#') continue;
            
            int indent = getIndentLevel(line);
            if (indent <= 8) {
                stream.seekg(-static_cast<int>(line.length() + 1), std::ios::cur);
                break;
            }
            
            if (line.find(':') != std::string::npos) {
                std::string key = extractKey(line);
                std::string value = extractValue(line);
                with[key] = value;
            }
        }
    }

    void parseStepEnvSection(std::istringstream& stream, std::map<std::string, std::string>& env) {
        parseWithSection(stream, env); // Same parsing logic
    }

    bool isTopLevelSection(const std::string& line) {
        return line.find("name:") == 0 ||
               line.find("on:") == 0 ||
               line.find("permissions:") == 0 ||
               line.find("jobs:") == 0 ||
               line.find("env:") == 0;
    }

    int getIndentLevel(const std::string& line) {
        int indent = 0;
        for (char c : line) {
            if (c == ' ') indent++;
            else if (c == '\t') indent += 2;
            else break;
        }
        return indent;
    }

    std::string extractKey(const std::string& line) {
        size_t colon = line.find(':');
        if (colon != std::string::npos) {
            return trim(line.substr(0, colon));
        }
        return "";
    }

    std::string extractValue(const std::string& line) {
        size_t colon = line.find(':');
        if (colon != std::string::npos && colon + 1 < line.length()) {
            std::string value = trim(line.substr(colon + 1));
            // Remove quotes if present
            if (value.length() >= 2 && 
                ((value[0] == '"' && value.back() == '"') ||
                 (value[0] == '\'' && value.back() == '\''))) {
                value = value.substr(1, value.length() - 2);
            }
            return value;
        }
        return "";
    }

    std::string trim(const std::string& str) {
        size_t start = str.find_first_not_of(" \t\r\n");
        if (start == std::string::npos) return "";
        
        size_t end = str.find_last_not_of(" \t\r\n");
        return str.substr(start, end - start + 1);
    }

    void validateWorkflowStructure() {
        // Validate required fields
        if (workflow.name.empty()) {
            throw std::runtime_error("Workflow missing name");
        }
        
        if (workflow.on_events.empty()) {
            throw std::runtime_error("Workflow missing trigger events");
        }
        
        if (workflow.jobs.empty()) {
            throw std::runtime_error("Workflow missing jobs");
        }
        
        // Validate job structure
        for (const auto& job_pair : workflow.jobs) {
            validateJob(job_pair.second);
        }
        
        // Validate job dependencies
        validateJobDependencies();
    }

    void validateJob(const Job& job) {
        if (job.runs_on.empty()) {
            throw std::runtime_error("Job missing runs-on");
        }
        
        // Validate runner types
        std::set<std::string> valid_runners = {
            "ubuntu-latest", "ubuntu-20.04", "ubuntu-18.04",
            "windows-latest", "windows-2019", "windows-2016",
            "macos-latest", "macos-11", "macos-10.15",
            "self-hosted"
        };
        
        bool valid_runner = false;
        for (const auto& runner : valid_runners) {
            if (job.runs_on.find(runner) != std::string::npos) {
                valid_runner = true;
                break;
            }
        }
        
        if (!valid_runner) {
            throw std::runtime_error("Invalid runner type: " + job.runs_on);
        }
        
        // Validate timeout
        if (job.timeout_minutes <= 0 || job.timeout_minutes > 600) {
            throw std::runtime_error("Invalid timeout minutes");
        }
        
        // Validate steps
        if (job.steps.empty()) {
            throw std::runtime_error("Job has no steps");
        }
        
        for (const auto& step : job.steps) {
            validateStep(step);
        }
    }

    void validateStep(const Step& step) {
        // Step must have either 'uses' or 'run'
        if (step.uses.empty() && step.run.empty()) {
            throw std::runtime_error("Step missing both uses and run");
        }
        
        if (!step.uses.empty() && !step.run.empty()) {
            throw std::runtime_error("Step cannot have both uses and run");
        }
        
        if (!step.uses.empty()) {
            validateAction(step.uses);
        }
        
        if (!step.run.empty()) {
            validateRunCommand(step.run);
        }
    }

    void validateAction(const std::string& uses) {
        // Validate action format
        if (uses.empty()) {
            throw std::runtime_error("Empty uses field");
        }
        
        // Check for suspicious patterns
        if (uses.find("..") != std::string::npos) {
            throw std::runtime_error("Suspicious path traversal in action");
        }
        
        // Validate action reference format
        if (uses.find('/') == std::string::npos && uses.find("docker://") != 0 && uses.find("./") != 0) {
            throw std::runtime_error("Invalid action reference format");
        }
        
        // Check for pinned versions
        if (uses.find('@') == std::string::npos && uses.find("docker://") != 0 && uses.find("./") != 0) {
            // Action not pinned to specific version
        }
    }

    void validateRunCommand(const std::string& run) {
        // Check for dangerous commands
        std::vector<std::string> dangerous_patterns = {
            "rm -rf /", "sudo rm -rf", "del /s /q",
            "format c:", "mkfs", "dd if=/dev/zero"
        };
        
        for (const auto& pattern : dangerous_patterns) {
            if (run.find(pattern) != std::string::npos) {
                throw std::runtime_error("Dangerous command pattern: " + pattern);
            }
        }
        
        // Check for curl | bash patterns
        if (run.find("curl") != std::string::npos && run.find("bash") != std::string::npos) {
            if (run.find("|") != std::string::npos) {
                throw std::runtime_error("Dangerous curl | bash pattern");
            }
        }
    }

    void validateJobDependencies() {
        // Check for circular dependencies
        std::set<std::string> job_names;
        for (const auto& job_pair : workflow.jobs) {
            job_names.insert(job_pair.first);
        }
        
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            for (const auto& need : job.needs) {
                if (job_names.find(need) == job_names.end()) {
                    throw std::runtime_error("Job depends on non-existent job: " + need);
                }
                
                // Simple circular dependency check
                if (need == job_pair.first) {
                    throw std::runtime_error("Job cannot depend on itself");
                }
            }
        }
    }

    void validateSecurity() {
        // Check permissions
        validatePermissions();
        
        // Check for secret usage
        validateSecretUsage();
        
        // Check for injection vulnerabilities
        validateInjectionSafety();
    }

    void validatePermissions() {
        // Validate workflow-level permissions
        for (const auto& perm : workflow.permissions) {
            validatePermission(perm.first, perm.second);
        }
        
        // Validate job-level permissions
        for (const auto& job_pair : workflow.jobs) {
            for (const auto& perm : job_pair.second.permissions) {
                validatePermission(perm.first, perm.second);
            }
        }
    }

    void validatePermission(const std::string& permission, const std::string& value) {
        std::set<std::string> valid_permissions = {
            "actions", "checks", "contents", "deployments", "issues",
            "packages", "pages", "pull-requests", "repository-projects",
            "security-events", "statuses"
        };
        
        if (valid_permissions.find(permission) == valid_permissions.end()) {
            throw std::runtime_error("Invalid permission: " + permission);
        }
        
        std::set<std::string> valid_values = {"read", "write", "none"};
        if (valid_values.find(value) == valid_values.end()) {
            throw std::runtime_error("Invalid permission value: " + value);
        }
    }

    void validateSecretUsage() {
        // Check for hardcoded secrets
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            // Check job environment variables
            for (const auto& env_var : job.env) {
                if (looksLikeSecret(env_var.first, env_var.second)) {
                    throw std::runtime_error("Potential hardcoded secret in job env");
                }
            }
            
            // Check step environment variables and run commands
            for (const auto& step : job.steps) {
                for (const auto& env_var : step.env) {
                    if (looksLikeSecret(env_var.first, env_var.second)) {
                        throw std::runtime_error("Potential hardcoded secret in step env");
                    }
                }
                
                if (containsHardcodedSecret(step.run)) {
                    throw std::runtime_error("Potential hardcoded secret in run command");
                }
            }
        }
    }

    bool looksLikeSecret(const std::string& key, const std::string& value) {
        // Check if key suggests it's a secret
        std::vector<std::string> secret_keywords = {
            "password", "passwd", "pwd", "secret", "token", 
            "key", "api_key", "apikey", "auth", "credential"
        };
        
        std::string lower_key = key;
        std::transform(lower_key.begin(), lower_key.end(), lower_key.begin(), ::tolower);
        
        for (const auto& keyword : secret_keywords) {
            if (lower_key.find(keyword) != std::string::npos) {
                // Check if value is hardcoded (not a reference)
                if (!value.empty() && 
                    value.find("${{") == std::string::npos &&
                    value.find("secrets.") == std::string::npos) {
                    return true;
                }
            }
        }
        
        return false;
    }

    bool containsHardcodedSecret(const std::string& command) {
        // Look for patterns that might contain hardcoded secrets
        std::regex secret_pattern(R"((password|token|key|secret)=['\"]?[a-zA-Z0-9+/=]{10,}['\"]?)");
        return std::regex_search(command, secret_pattern);
    }

    void validateInjectionSafety() {
        // Check for potential injection vulnerabilities
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            for (const auto& step : job.steps) {
                if (!step.run.empty()) {
                    validateCommandInjection(step.run);
                }
            }
        }
    }

    void validateCommandInjection(const std::string& command) {
        // Check for user input that might lead to injection
        if (command.find("${{ github.event") != std::string::npos ||
            command.find("${{ github.head_ref") != std::string::npos) {
            
            // Check if user input is properly quoted/escaped
            if (command.find("\"${{") == std::string::npos &&
                command.find("'${{") == std::string::npos) {
                throw std::runtime_error("Potential command injection vulnerability");
            }
        }
    }

    void validatePerformance() {
        // Check for performance issues
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            // Check timeout settings
            if (job.timeout_minutes > 360) { // 6 hours
                throw std::runtime_error("Job timeout too long");
            }
            
            // Check for excessive parallelism
            if (job.steps.size() > 50) {
                throw std::runtime_error("Too many steps in job");
            }
        }
        
        // Check total number of jobs
        if (workflow.jobs.size() > 20) {
            throw std::runtime_error("Too many jobs in workflow");
        }
    }

    void validateBestPractices() {
        // Check for GitHub Actions best practices
        validateActionVersionPinning();
        validateCaching();
        validateArtifacts();
    }

    void validateActionVersionPinning() {
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            for (const auto& step : job.steps) {
                if (!step.uses.empty() && step.uses.find("./") != 0) {
                    // Check if action is pinned to specific version
                    if (step.uses.find('@') == std::string::npos) {
                        // Action not pinned - potential security risk
                    } else {
                        // Check if pinned to a branch (less secure than tag/SHA)
                        std::string version = step.uses.substr(step.uses.find('@') + 1);
                        if (version == "main" || version == "master" || version == "develop") {
                            // Pinned to branch instead of tag/SHA
                        }
                    }
                }
            }
        }
    }

    void validateCaching() {
        // Check if workflow uses caching appropriately
        bool has_cache_action = false;
        
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            for (const auto& step : job.steps) {
                if (step.uses.find("actions/cache") != std::string::npos) {
                    has_cache_action = true;
                    break;
                }
            }
        }
        
        // If workflow has build/test steps but no caching, it might be inefficient
    }

    void validateArtifacts() {
        // Check artifact usage
        for (const auto& job_pair : workflow.jobs) {
            const Job& job = job_pair.second;
            
            for (const auto& step : job.steps) {
                if (step.uses.find("actions/upload-artifact") != std::string::npos) {
                    // Check artifact configuration
                    auto retention_it = step.with.find("retention-days");
                    if (retention_it != step.with.end()) {
                        int retention = std::stoi(retention_it->second);
                        if (retention > 90) {
                            throw std::runtime_error("Artifact retention too long");
                        }
                    }
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

    std::string workflow_content(reinterpret_cast<const char*>(Data), Size);
    
    GitHubActionsParser parser;
    parser.parseWorkflow(workflow_content);
    
    return 0;
}