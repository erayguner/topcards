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

FROM gcr.io/oss-fuzz-base/base-builder

# Install dependencies for building and testing
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    wget \
    unzip \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    yamllint \
    && rm -rf /var/lib/apt/lists/*

# Install additional tools for infrastructure testing
RUN pip3 install \
    pyyaml \
    jsonschema \
    terraform-compliance \
    checkov

# Install Terraform for configuration validation
RUN wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip && \
    unzip terraform_1.7.0_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_1.7.0_linux_amd64.zip

# Clone the project repository
RUN git clone https://github.com/erayguner/topcards $SRC/topcards

# Set working directory
WORKDIR $SRC/topcards

# Copy build script
COPY build.sh $SRC/build.sh
COPY fuzz_targets/ $SRC/fuzz_targets/

# Make build script executable
RUN chmod +x $SRC/build.sh