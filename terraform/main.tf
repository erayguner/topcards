# TopCards Infrastructure Configuration
# 
# This is the main entry point for the Terraform configuration.
# Resources are organized into separate files by type for better maintainability:
#
# - providers.tf    : Terraform and provider configuration
# - apis.tf         : Google Cloud API enablement
# - networking.tf   : VPC, subnets, firewall rules, NAT
# - storage.tf      : Cloud Storage buckets
# - security.tf     : KMS, IAM, service accounts, secrets
# - compute.tf      : Compute instances and templates
# - database.tf     : Cloud SQL PostgreSQL configuration
# - bigquery.tf     : BigQuery dataset and external tables
# - variables.tf    : Input variables
# - outputs.tf      : Output values

# This file intentionally kept minimal to serve as documentation
# All resources are defined in their respective specialized files