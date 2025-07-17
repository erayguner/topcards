# 🐛 OSS-Fuzz Integration for TopCards

## Overview

This repository includes comprehensive OSS-Fuzz integration for continuous fuzzing of infrastructure configuration parsing, shell script security analysis, and GitHub Actions workflow validation. The integration provides automated discovery of parsing edge cases, injection vulnerabilities, and input validation issues.

## 🎯 What is OSS-Fuzz?

OSS-Fuzz is Google's continuous fuzzing platform for open source software. It:
- Combines modern fuzzing techniques with scalable, distributed execution
- Has discovered over 13,000 vulnerabilities and 50,000 bugs across 1,000+ projects
- Supports multiple programming languages and fuzzing engines (libFuzzer, AFL++, Honggfuzz)
- Provides automated bug reporting and tracking

## 🔧 Fuzz Targets

Our OSS-Fuzz integration includes 5 specialized fuzz targets:

### 1. Terraform Configuration Fuzzer (`terraform_config_fuzzer.cpp`)
**Purpose**: Tests Terraform configuration parsing and validation
**Coverage**:
- Resource and provider block parsing
- Variable and output validation
- Syntax and structure verification
- GCP-specific attribute validation
- Interpolation and heredoc handling

### 2. YAML Configuration Fuzzer (`yaml_config_fuzzer.cpp`)
**Purpose**: Tests YAML configuration file parsing and GitHub Actions validation
**Coverage**:
- YAML document structure parsing
- GitHub Actions workflow validation
- Security configuration analysis
- YAML injection pattern detection
- Key-value pair validation

### 3. Shell Script Fuzzer (`shell_script_fuzzer.cpp`)
**Purpose**: Tests shell script security analysis and command validation
**Coverage**:
- Shell script syntax parsing
- Command injection detection
- Dangerous command pattern identification
- Quote and bracket balance validation
- Credential exposure prevention

### 4. JSON Configuration Fuzzer (`json_config_fuzzer.cpp`)
**Purpose**: Tests JSON configuration parsing and package.json validation
**Coverage**:
- JSON syntax and structure parsing
- Package.json semantic validation
- Security configuration analysis
- Dependency version validation
- XSS and injection pattern detection

### 5. GitHub Actions Workflow Fuzzer (`github_actions_fuzzer.cpp`)
**Purpose**: Tests GitHub Actions workflow parsing and security validation
**Coverage**:
- Workflow structure and job validation
- Action usage and security analysis
- Permission and secret validation
- Command injection prevention
- Best practices enforcement

## 📁 Project Structure

```
oss-fuzz/
├── project.yaml              # OSS-Fuzz project configuration
├── Dockerfile                # Build environment setup
├── build.sh                  # Build script for fuzz targets
└── fuzz_targets/             # C++ fuzz target implementations
    ├── terraform_config_fuzzer.cpp
    ├── yaml_config_fuzzer.cpp
    ├── shell_script_fuzzer.cpp
    ├── json_config_fuzzer.cpp
    └── github_actions_fuzzer.cpp
```

## 🚀 Local Testing

### Prerequisites
- Docker
- C++ compiler (clang recommended)
- OSS-Fuzz helper tools (optional)

### Quick Start

1. **Build fuzz targets locally**:
   ```bash
   # Set up build environment
   export CC=clang
   export CXX=clang++
   export CFLAGS="-fsanitize=address,fuzzer-no-link"
   export CXXFLAGS="-fsanitize=address,fuzzer-no-link -std=c++17"
   export LIB_FUZZING_ENGINE="-fsanitize=fuzzer"
   export OUT="$(pwd)/fuzz_build"
   mkdir -p $OUT
   
   # Build all targets
   chmod +x oss-fuzz/build.sh
   ./oss-fuzz/build.sh
   ```

2. **Run individual fuzz targets**:
   ```bash
   # Test Terraform configuration fuzzer
   ./fuzz_build/terraform_config_fuzzer -max_total_time=60
   
   # Test YAML configuration fuzzer
   ./fuzz_build/yaml_config_fuzzer -max_total_time=60
   
   # Test shell script fuzzer
   ./fuzz_build/shell_script_fuzzer -max_total_time=60
   ```

3. **Use seed corpus**:
   ```bash
   # Create seed directory
   mkdir seeds
   cp terraform/*.tf seeds/
   cp .github/workflows/*.yml seeds/
   cp *.json seeds/
   
   # Run with seeds
   ./fuzz_build/terraform_config_fuzzer seeds/
   ```

### GitHub Actions Integration

The repository includes automated OSS-Fuzz testing via GitHub Actions:

```bash
# Trigger local fuzzing workflow
gh workflow run oss-fuzz-integration.yml -f fuzz_duration=300
```

**Workflow Features**:
- ✅ Validates OSS-Fuzz configuration
- ✅ Builds all fuzz targets
- ✅ Runs local fuzzing tests
- ✅ Analyzes results and generates reports
- ✅ Uploads artifacts for investigation

## 📊 Coverage Areas

### Infrastructure Security
- **Terraform Configuration**: Resource validation, provider security, variable handling
- **Shell Scripts**: Command injection, credential exposure, dangerous commands
- **Startup Scripts**: GCP instance configuration, security hardening

### Configuration Validation
- **YAML Files**: GitHub Actions workflows, security tool configurations
- **JSON Files**: Package.json, dependency validation, security policies
- **Workflow Files**: Permission validation, action security, best practices

### Security Focus Areas
- **Injection Prevention**: Command, code, and configuration injection
- **Input Validation**: Syntax checking, format validation, type safety
- **Credential Security**: Secret detection, hardcoded credential prevention
- **Permission Analysis**: Access control validation, privilege escalation prevention

## 🔍 Expected Findings

### Common Issues Discovered by Fuzzing
- **Parser Edge Cases**: Malformed input handling, boundary conditions
- **Injection Vulnerabilities**: Command injection, code execution
- **Buffer Overflows**: String handling, memory safety issues
- **Logic Errors**: Validation bypass, incorrect state handling
- **Resource Exhaustion**: Infinite loops, memory consumption

### Security Improvements
- **Robust Input Validation**: Better error handling and input sanitization
- **Injection Prevention**: Improved command and configuration parsing
- **Memory Safety**: Buffer overflow and use-after-free prevention
- **Configuration Security**: Better validation of security-sensitive settings

## 🏗️ OSS-Fuzz Submission

### Prerequisites for Submission
- [x] Open source project with security impact
- [x] Fuzz targets implemented and tested
- [x] Build system configured and validated
- [x] Documentation and contact information provided

### Submission Process

1. **Fork OSS-Fuzz repository**:
   ```bash
   git clone https://github.com/google/oss-fuzz.git
   cd oss-fuzz
   git checkout -b add-topcards
   ```

2. **Create project directory**:
   ```bash
   mkdir projects/topcards
   cp -r /path/to/topcards/oss-fuzz/* projects/topcards/
   ```

3. **Test integration**:
   ```bash
   python infra/helper.py build_image topcards
   python infra/helper.py build_fuzzers topcards
   python infra/helper.py check_build topcards
   python infra/helper.py run_fuzzer topcards terraform_config_fuzzer
   ```

4. **Submit pull request** to OSS-Fuzz repository

### Post-Submission
- **Monitor ClusterFuzz dashboard** for bug reports
- **Respond to security issues** within SLA timeframes
- **Maintain fuzz targets** and update as needed
- **Collaborate with OSS-Fuzz team** on improvements

## 📈 Benefits

### Security Improvements
- **Continuous Security Testing**: 24/7 automated fuzzing
- **Early Vulnerability Detection**: Issues found before release
- **Comprehensive Coverage**: Multiple attack vectors tested
- **Industry Recognition**: OSS-Fuzz participation demonstrates security commitment

### Development Benefits
- **Improved Code Quality**: Better input validation and error handling
- **Edge Case Discovery**: Unusual input combinations tested
- **Regression Prevention**: Continuous testing prevents security regressions
- **Community Contribution**: Enhanced security for the broader ecosystem

### Infrastructure Benefits
- **Configuration Validation**: Terraform and YAML parsing improvements
- **Script Security**: Shell script injection prevention
- **Workflow Security**: GitHub Actions security validation
- **Automation Safety**: CI/CD pipeline security enhancement

## 🔧 Customization

### Adding New Fuzz Targets

1. **Create new fuzzer file**:
   ```cpp
   // oss-fuzz/fuzz_targets/my_fuzzer.cpp
   extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
       // Your fuzzing logic here
       return 0;
   }
   ```

2. **Update build script**:
   ```bash
   # Add to oss-fuzz/build.sh
   $CXX $CXXFLAGS -std=c++17 \
       -I$SRC/fuzz_targets \
       $SRC/fuzz_targets/my_fuzzer.cpp \
       -o $OUT/my_fuzzer \
       $LIB_FUZZING_ENGINE
   ```

3. **Update project configuration**:
   ```yaml
   # Add to oss-fuzz/project.yaml
   testing_focus:
     - New functionality description
   ```

### Modifying Existing Targets

- **Expand parser coverage**: Add new configuration formats
- **Enhance validation**: Implement additional security checks
- **Improve performance**: Optimize parsing algorithms
- **Add dictionaries**: Create fuzzing dictionaries for better coverage

## 🚨 Security Considerations

### Fuzzing Safety
- **Isolated Environment**: All fuzzing runs in sandboxed containers
- **No Network Access**: Fuzzers cannot make external connections
- **Limited Resources**: CPU and memory limits prevent resource exhaustion
- **Safe Input Handling**: No execution of fuzzing input as code

### Vulnerability Handling
- **Private Reporting**: Security issues reported privately first
- **Coordinated Disclosure**: 90-day disclosure timeline
- **Patch Development**: Fixes developed before public disclosure
- **Community Notification**: Security advisories published after fixes

## 📞 Support and Contact

### OSS-Fuzz Integration
- **Primary Contact**: erayguner@gmail.com
- **Repository**: https://github.com/erayguner/topcards
- **Security Policy**: See [SECURITY.md](SECURITY.md)

### Documentation
- **OSS-Fuzz Docs**: https://google.github.io/oss-fuzz/
- **libFuzzer Tutorial**: https://llvm.org/docs/LibFuzzer.html
- **Fuzzing Best Practices**: https://google.github.io/oss-fuzz/reference/ideal-integration/

### Contributing
1. **Review existing fuzz targets** and their coverage
2. **Test changes locally** before submitting
3. **Update documentation** for any modifications
4. **Follow security guidelines** for vulnerability reporting

---

## 📊 Integration Summary

| Component | Status | Coverage |
|-----------|--------|----------|
| **Terraform Configuration Fuzzing** | ✅ Ready | Resource parsing, provider validation, syntax checking |
| **YAML Configuration Fuzzing** | ✅ Ready | GitHub Actions, security configs, structure validation |
| **Shell Script Fuzzing** | ✅ Ready | Security analysis, injection prevention, syntax validation |
| **JSON Configuration Fuzzing** | ✅ Ready | Package.json, security policies, format validation |
| **GitHub Actions Fuzzing** | ✅ Ready | Workflow security, permission validation, best practices |
| **Local Testing** | ✅ Active | GitHub Actions workflow with automated testing |
| **OSS-Fuzz Submission** | 🔄 Ready | Complete configuration and documentation |

**Total Fuzz Targets**: 5 specialized targets covering infrastructure, configuration, and security validation

**Expected Impact**: Enhanced security posture through continuous fuzzing of critical parsing and validation logic

---

*OSS-Fuzz Integration for TopCards - Comprehensive Fuzzing for Infrastructure Security*