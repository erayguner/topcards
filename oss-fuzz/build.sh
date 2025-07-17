#!/bin/bash -eu
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build script for TopCards OSS-Fuzz integration

# Build the fuzz targets
cd $SRC/topcards

# Create output directory for fuzz targets
mkdir -p $OUT/seeds

# Build infrastructure configuration fuzzer
$CXX $CXXFLAGS -std=c++17 \
    -I$SRC/fuzz_targets \
    $SRC/fuzz_targets/terraform_config_fuzzer.cpp \
    -o $OUT/terraform_config_fuzzer \
    $LIB_FUZZING_ENGINE

# Build shell script fuzzer
$CXX $CXXFLAGS -std=c++17 \
    -I$SRC/fuzz_targets \
    $SRC/fuzz_targets/shell_script_fuzzer.cpp \
    -o $OUT/shell_script_fuzzer \
    $LIB_FUZZING_ENGINE

# Build YAML configuration fuzzer
$CXX $CXXFLAGS -std=c++17 \
    -I$SRC/fuzz_targets \
    $SRC/fuzz_targets/yaml_config_fuzzer.cpp \
    -o $OUT/yaml_config_fuzzer \
    $LIB_FUZZING_ENGINE

# Build JSON configuration fuzzer
$CXX $CXXFLAGS -std=c++17 \
    -I$SRC/fuzz_targets \
    $SRC/fuzz_targets/json_config_fuzzer.cpp \
    -o $OUT/json_config_fuzzer \
    $LIB_FUZZING_ENGINE

# Build GitHub Actions workflow fuzzer
$CXX $CXXFLAGS -std=c++17 \
    -I$SRC/fuzz_targets \
    $SRC/fuzz_targets/github_actions_fuzzer.cpp \
    -o $OUT/github_actions_fuzzer \
    $LIB_FUZZING_ENGINE

# Create seed corpus for Terraform configurations
find terraform -name "*.tf" -exec cp {} $OUT/seeds/ \;

# Create seed corpus for shell scripts
find . -name "*.sh" -exec cp {} $OUT/seeds/ \;

# Create seed corpus for YAML files
find .github -name "*.yml" -exec cp {} $OUT/seeds/ \;
find .github -name "*.yaml" -exec cp {} $OUT/seeds/ \;

# Create seed corpus for JSON files
find . -name "*.json" -exec cp {} $OUT/seeds/ \;

# Create fuzz target options files
echo "[libfuzzer]" > $OUT/terraform_config_fuzzer.options
echo "max_len = 65536" >> $OUT/terraform_config_fuzzer.options
echo "timeout = 10" >> $OUT/terraform_config_fuzzer.options

echo "[libfuzzer]" > $OUT/shell_script_fuzzer.options
echo "max_len = 32768" >> $OUT/shell_script_fuzzer.options
echo "timeout = 10" >> $OUT/shell_script_fuzzer.options

echo "[libfuzzer]" > $OUT/yaml_config_fuzzer.options
echo "max_len = 65536" >> $OUT/yaml_config_fuzzer.options
echo "timeout = 10" >> $OUT/yaml_config_fuzzer.options

echo "[libfuzzer]" > $OUT/json_config_fuzzer.options
echo "max_len = 65536" >> $OUT/json_config_fuzzer.options
echo "timeout = 10" >> $OUT/json_config_fuzzer.options

echo "[libfuzzer]" > $OUT/github_actions_fuzzer.options
echo "max_len = 65536" >> $OUT/github_actions_fuzzer.options
echo "timeout = 10" >> $OUT/github_actions_fuzzer.options

# Create dictionaries for better fuzzing coverage
cat > $OUT/terraform.dict << EOF
# Terraform keywords
"resource"
"provider"
"variable"
"output"
"data"
"module"
"locals"
"terraform"
"count"
"for_each"
"depends_on"
"lifecycle"
"google_compute_instance"
"google_storage_bucket"
"google_project"
"google_service_account"
"google_kms_key_ring"
"google_kms_crypto_key"
"google_secret_manager_secret"
"google_compute_network"
"google_compute_subnetwork"
"google_compute_firewall"
"google_sql_database_instance"
"google_bigquery_dataset"
"google_bigquery_table"
EOF

cat > $OUT/yaml.dict << EOF
# YAML keywords
"name:"
"on:"
"jobs:"
"steps:"
"uses:"
"run:"
"with:"
"env:"
"if:"
"needs:"
"strategy:"
"matrix:"
"permissions:"
"secrets:"
"workflow_dispatch:"
"push:"
"pull_request:"
"schedule:"
"branches:"
"paths:"
"actions/checkout"
"actions/setup-node"
"actions/upload-artifact"
"ubuntu-latest"
"windows-latest"
"macos-latest"
EOF

cat > $OUT/shell.dict << EOF
# Shell script keywords
"#!/bin/bash"
"#!/bin/sh"
"apt-get"
"curl"
"wget"
"git"
"docker"
"systemctl"
"ufw"
"fail2ban"
"mkdir"
"chmod"
"chown"
"echo"
"export"
"source"
"if"
"then"
"else"
"fi"
"for"
"while"
"do"
"done"
"case"
"esac"
"function"
"return"
"exit"
EOF

echo "Build completed successfully!"
echo "Fuzz targets created:"
echo "  - terraform_config_fuzzer"
echo "  - shell_script_fuzzer" 
echo "  - yaml_config_fuzzer"
echo "  - json_config_fuzzer"
echo "  - github_actions_fuzzer"