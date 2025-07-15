# Google Cloud Platform Terraform Configuration

This Terraform configuration creates a secure, production-ready Google Cloud Platform infrastructure for the TopCards application.

## 🏗️ Infrastructure Components

### Core Resources
- **VPC Network** with custom subnet and security groups
- **Compute Instances** with auto-scaling template
- **Cloud Storage** bucket with encryption and versioning
- **Cloud SQL PostgreSQL** database with private networking
- **KMS** encryption keys for data security
- **Secret Manager** for secure credential storage
- **Service Accounts** with least-privilege access
- **Firewall Rules** for controlled network access

### Security Features
- 🔐 **KMS Encryption** for storage and compute disks
- 🗄️ **Private Database** access via VPC peering
- 🔑 **Secret Manager** for database credentials
- 🛡️ **IAM** service accounts with minimal permissions
- 🚫 **Network Security** with custom firewall rules
- 🔒 **Private Google Access** enabled on subnets
- 📝 **Audit Logging** through GCP APIs
- 🔐 **SSL/TLS** required for database connections

## 🚀 Quick Start

### Prerequisites
1. **Google Cloud SDK** installed and configured
2. **Terraform** >= 1.5 installed
3. **GCP Project** with billing enabled
4. **Required APIs** enabled (handled automatically)

### Setup
1. **Clone and navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Copy and configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project details
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan infrastructure**:
   ```bash
   terraform plan
   ```

5. **Apply configuration**:
   ```bash
   terraform apply
   ```

## 📋 Required Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_id` | GCP Project ID | - | ✅ |
| `region` | GCP Region | `us-central1` | ❌ |
| `zone` | GCP Zone | `us-central1-a` | ❌ |
| `environment` | Environment (dev/staging/prod) | `dev` | ❌ |
| `machine_type` | VM machine type | `e2-micro` | ❌ |
| `instance_count` | Number of instances | `1` | ❌ |
| `enable_database` | Create Cloud SQL database | `true` | ❌ |
| `db_version` | PostgreSQL version | `POSTGRES_15` | ❌ |
| `db_tier` | Database machine type | `db-f1-micro` | ❌ |
| `db_disk_size` | Database disk size (GB) | `20` | ❌ |
| `db_name` | Application database name | `topcards_app` | ❌ |
| `db_user` | Database user name | `app_user` | ❌ |

## 🔧 Configuration

### Environment-Specific Configs
```hcl
# Development
environment = "dev"
machine_type = "e2-micro"
instance_count = 1

# Production
environment = "prod"
machine_type = "e2-standard-2"
instance_count = 3
db_tier = "db-n1-standard-2"
db_disk_size = 100
```

### Security Configuration
- All storage buckets use **customer-managed encryption** keys
- Compute instances have **encrypted boot disks**
- Network access controlled via **firewall rules**
- Service accounts follow **least-privilege** principle

## 📊 Outputs

After successful deployment, Terraform outputs:
- **VPC Network** details
- **Compute Instance** IPs and names
- **Storage Bucket** URLs
- **Database Instance** connection details
- **Database Credentials** secret names
- **Service Account** emails
- **Firewall Rules** names

## 🛡️ Security Best Practices

### Applied in this Configuration
- ✅ **Encryption at rest** for all data
- ✅ **Network segmentation** with custom VPC
- ✅ **Minimal IAM permissions**
- ✅ **Firewall rules** for access control
- ✅ **API enablement** automation
- ✅ **Resource labeling** for governance

### Additional Recommendations
- 🔄 Use **Terraform state backend** (Cloud Storage)
- 👥 Implement **workspace separation** per environment
- 🔍 Enable **audit logging** and monitoring
- 🔐 Rotate **service account keys** regularly

## 🗂️ File Structure

```
terraform/
├── main.tf                    # Main infrastructure resources
├── variables.tf               # Input variables and validation
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── startup-script.sh          # VM initialization script
└── README.md                  # This documentation
```

## 🚨 Important Notes

1. **State Management**: Consider using remote state backend for production
2. **Credentials**: Never commit service account keys or credentials
3. **Costs**: Monitor resource usage to avoid unexpected charges
4. **Cleanup**: Run `terraform destroy` to remove all resources

## 🔗 Useful Commands

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Show current state
terraform show

# Import existing resources
terraform import google_compute_instance.example projects/PROJECT/zones/ZONE/instances/INSTANCE

# Destroy infrastructure
terraform destroy
```

## 📞 Support

- **Terraform Google Provider**: [Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- **GCP Documentation**: [Cloud Documentation](https://cloud.google.com/docs)
- **Security Best Practices**: [GCP Security](https://cloud.google.com/security/best-practices)