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

// Shell script parser and validator for fuzzing
class ShellScriptParser {
public:
    struct Command {
        std::string command;
        std::vector<std::string> arguments;
        std::string redirection;
        bool is_pipe_target = false;
        bool is_background = false;
    };

    struct Function {
        std::string name;
        std::vector<std::string> body;
    };

    std::vector<Command> commands;
    std::vector<Function> functions;
    std::map<std::string, std::string> variables;

    bool parseScript(const std::string& script) {
        try {
            validateShebang(script);
            parseCommands(script);
            parseFunctions(script);
            parseVariables(script);
            validateSecurity(script);
            validateSyntax(script);
            return true;
        } catch (const std::exception& e) {
            // Expected for fuzzing - catch parsing errors
            return false;
        }
    }

private:
    void validateShebang(const std::string& script) {
        if (script.empty()) return;
        
        if (script.substr(0, 2) == "#!") {
            size_t newline = script.find('\n');
            std::string shebang = script.substr(0, newline);
            
            // Validate common shebangs
            if (shebang.find("/bin/bash") == std::string::npos &&
                shebang.find("/bin/sh") == std::string::npos &&
                shebang.find("/usr/bin/env") == std::string::npos) {
                throw std::runtime_error("Unusual shebang detected");
            }
        }
    }

    void parseCommands(const std::string& script) {
        std::istringstream stream(script);
        std::string line;
        
        while (std::getline(stream, line)) {
            line = trim(line);
            
            // Skip empty lines and comments
            if (line.empty() || line[0] == '#') {
                continue;
            }
            
            // Skip function definitions, variable assignments, control structures
            if (isControlStructure(line) || isFunctionDefinition(line) || isVariableAssignment(line)) {
                continue;
            }
            
            parseCommandLine(line);
        }
    }

    void parseCommandLine(const std::string& line) {
        Command cmd;
        
        // Handle background processes
        if (line.back() == '&') {
            cmd.is_background = true;
        }
        
        // Split by pipes
        std::vector<std::string> pipe_parts = splitByPipe(line);
        
        for (size_t i = 0; i < pipe_parts.size(); ++i) {
            Command pipe_cmd = parseSimpleCommand(pipe_parts[i]);
            if (i > 0) {
                pipe_cmd.is_pipe_target = true;
            }
            commands.push_back(pipe_cmd);
        }
    }

    Command parseSimpleCommand(const std::string& cmd_str) {
        Command cmd;
        std::istringstream stream(cmd_str);
        std::string token;
        
        bool first_token = true;
        while (stream >> token) {
            if (first_token) {
                cmd.command = token;
                first_token = false;
            } else if (token[0] == '>' || token[0] == '<') {
                cmd.redirection = token;
            } else {
                cmd.arguments.push_back(token);
            }
        }
        
        return cmd;
    }

    std::vector<std::string> splitByPipe(const std::string& line) {
        std::vector<std::string> parts;
        std::stringstream ss(line);
        std::string part;
        
        while (std::getline(ss, part, '|')) {
            parts.push_back(trim(part));
        }
        
        return parts;
    }

    bool isControlStructure(const std::string& line) {
        std::vector<std::string> control_keywords = {
            "if", "then", "else", "elif", "fi",
            "for", "while", "until", "do", "done",
            "case", "esac", "select"
        };
        
        for (const auto& keyword : control_keywords) {
            if (line.find(keyword) == 0) {
                return true;
            }
        }
        
        return false;
    }

    bool isFunctionDefinition(const std::string& line) {
        return line.find("function ") == 0 || 
               line.find("()") != std::string::npos;
    }

    bool isVariableAssignment(const std::string& line) {
        size_t equals = line.find('=');
        return equals != std::string::npos && 
               equals > 0 && 
               line[equals-1] != '!' && 
               line[equals-1] != '=' &&
               line[equals+1] != '=';
    }

    void parseFunctions(const std::string& script) {
        std::regex func_regex(R"(function\s+(\w+)\s*\(\s*\)|(\w+)\s*\(\s*\))");
        std::smatch matches;
        
        std::string::const_iterator searchStart(script.cbegin());
        while (std::regex_search(searchStart, script.cend(), matches, func_regex)) {
            Function func;
            func.name = matches[1].matched ? matches[1] : matches[2];
            
            // Parse function body (simplified)
            size_t start_pos = matches.suffix().first - script.cbegin();
            size_t brace_start = script.find('{', start_pos);
            if (brace_start != std::string::npos) {
                size_t brace_end = findMatchingBrace(script, brace_start);
                if (brace_end != std::string::npos) {
                    std::string body = script.substr(brace_start + 1, brace_end - brace_start - 1);
                    parseFunctionBody(body, func);
                }
            }
            
            functions.push_back(func);
            searchStart = matches.suffix().first;
        }
    }

    size_t findMatchingBrace(const std::string& script, size_t start) {
        int brace_count = 1;
        for (size_t i = start + 1; i < script.length(); ++i) {
            if (script[i] == '{') brace_count++;
            else if (script[i] == '}') brace_count--;
            
            if (brace_count == 0) {
                return i;
            }
        }
        return std::string::npos;
    }

    void parseFunctionBody(const std::string& body, Function& func) {
        std::istringstream stream(body);
        std::string line;
        
        while (std::getline(stream, line)) {
            line = trim(line);
            if (!line.empty() && line[0] != '#') {
                func.body.push_back(line);
            }
        }
    }

    void parseVariables(const std::string& script) {
        std::regex var_regex(R"((\w+)=([^;\n\r]+))");
        std::smatch matches;
        
        std::string::const_iterator searchStart(script.cbegin());
        while (std::regex_search(searchStart, script.cend(), matches, var_regex)) {
            std::string var_name = matches[1];
            std::string var_value = matches[2];
            
            variables[var_name] = trim(var_value);
            searchStart = matches.suffix().first;
        }
    }

    void validateSecurity(const std::string& script) {
        // Check for dangerous commands
        std::vector<std::string> dangerous_commands = {
            "rm -rf /", "dd if=", "mkfs", "fdisk", 
            "chmod 777", "chown root", "su root"
        };
        
        for (const auto& dangerous : dangerous_commands) {
            if (script.find(dangerous) != std::string::npos) {
                throw std::runtime_error("Dangerous command detected: " + dangerous);
            }
        }
        
        // Check for potential injection patterns
        validateInjectionPatterns(script);
        
        // Check for insecure downloads
        validateDownloadSecurity(script);
        
        // Check for credential exposure
        validateCredentialSecurity(script);
    }

    void validateInjectionPatterns(const std::string& script) {
        // Command injection patterns
        std::vector<std::string> injection_patterns = {
            "; rm ", "&& rm ", "| rm ", "$(rm", "`rm",
            "; wget ", "&& wget ", "| wget ", "$(wget", "`wget",
            "; curl ", "&& curl ", "| curl ", "$(curl", "`curl"
        };
        
        for (const auto& pattern : injection_patterns) {
            if (script.find(pattern) != std::string::npos) {
                throw std::runtime_error("Potential injection pattern: " + pattern);
            }
        }
        
        // Check for eval usage
        if (script.find("eval ") != std::string::npos) {
            throw std::runtime_error("Use of eval detected");
        }
    }

    void validateDownloadSecurity(const std::string& script) {
        // Check for curl/wget piped to shell
        std::regex dangerous_download(R"((curl|wget)[^|]*\|\s*(bash|sh))");
        if (std::regex_search(script, dangerous_download)) {
            throw std::runtime_error("Dangerous download pattern detected");
        }
        
        // Check for insecure downloads (HTTP)
        if (script.find("http://") != std::string::npos &&
            (script.find("curl") != std::string::npos || script.find("wget") != std::string::npos)) {
            // HTTP downloads might be insecure
        }
    }

    void validateCredentialSecurity(const std::string& script) {
        // Check for hardcoded credentials
        std::vector<std::string> credential_patterns = {
            "password=", "passwd=", "pwd=", "secret=", 
            "token=", "key=", "api_key=", "apikey="
        };
        
        for (const auto& pattern : credential_patterns) {
            size_t pos = script.find(pattern);
            if (pos != std::string::npos) {
                // Check if it's not reading from environment or file
                std::string context = script.substr(pos, 50);
                if (context.find("$") == std::string::npos &&
                    context.find("$(") == std::string::npos &&
                    context.find("`") == std::string::npos) {
                    throw std::runtime_error("Potential hardcoded credential");
                }
            }
        }
    }

    void validateSyntax(const std::string& script) {
        // Check for balanced quotes
        validateQuoteBalance(script);
        
        // Check for balanced parentheses/brackets
        validateBracketBalance(script);
        
        // Check for proper command termination
        validateCommandTermination(script);
    }

    void validateQuoteBalance(const std::string& script) {
        int single_quotes = 0;
        int double_quotes = 0;
        bool in_single = false;
        bool in_double = false;
        
        for (size_t i = 0; i < script.length(); ++i) {
            char c = script[i];
            
            if (c == '\'' && !in_double) {
                if (!in_single) {
                    in_single = true;
                    single_quotes++;
                } else {
                    in_single = false;
                }
            } else if (c == '"' && !in_single) {
                if (i == 0 || script[i-1] != '\\') {
                    if (!in_double) {
                        in_double = true;
                        double_quotes++;
                    } else {
                        in_double = false;
                    }
                }
            }
        }
        
        if (single_quotes % 2 != 0) {
            throw std::runtime_error("Unbalanced single quotes");
        }
        
        if (double_quotes % 2 != 0) {
            throw std::runtime_error("Unbalanced double quotes");
        }
    }

    void validateBracketBalance(const std::string& script) {
        int parens = 0;
        int brackets = 0;
        int braces = 0;
        
        for (char c : script) {
            switch (c) {
                case '(': parens++; break;
                case ')': parens--; break;
                case '[': brackets++; break;
                case ']': brackets--; break;
                case '{': braces++; break;
                case '}': braces--; break;
            }
            
            if (parens < 0 || brackets < 0 || braces < 0) {
                throw std::runtime_error("Unbalanced brackets");
            }
        }
        
        if (parens != 0 || brackets != 0 || braces != 0) {
            throw std::runtime_error("Unbalanced brackets");
        }
    }

    void validateCommandTermination(const std::string& script) {
        // Check for unterminated command substitutions
        if (script.find("$(") != std::string::npos) {
            size_t pos = 0;
            while ((pos = script.find("$(", pos)) != std::string::npos) {
                size_t close_pos = script.find(")", pos);
                if (close_pos == std::string::npos) {
                    throw std::runtime_error("Unterminated command substitution");
                }
                pos = close_pos;
            }
        }
        
        // Check for unterminated backticks
        int backtick_count = 0;
        for (char c : script) {
            if (c == '`') backtick_count++;
        }
        
        if (backtick_count % 2 != 0) {
            throw std::runtime_error("Unmatched backticks");
        }
    }

    std::string trim(const std::string& str) {
        size_t start = str.find_first_not_of(" \t\r\n");
        if (start == std::string::npos) return "";
        
        size_t end = str.find_last_not_of(" \t\r\n");
        return str.substr(start, end - start + 1);
    }
};

// Fuzzing entry point
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    if (Size == 0 || Size > 32768) {
        return 0;
    }

    std::string shell_script(reinterpret_cast<const char*>(Data), Size);
    
    ShellScriptParser parser;
    parser.parseScript(shell_script);
    
    return 0;
}