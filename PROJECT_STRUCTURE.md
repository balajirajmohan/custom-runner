# 📁 Project Structure

Complete overview of all files and their purposes.

## 🌳 Directory Tree

```
customrunner/
├── .github/
│   └── workflows/
│       ├── ci-docker.yml              # Main CI workflow with Docker containers
│       └── simple-test.yml            # Simple test workflow
│
├── terraform/
│   ├── main.tf                        # Main infrastructure code
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output values
│   ├── user-data.sh                   # EC2 initialization script
│   ├── terraform.tfvars.example       # Example configuration
│   └── .gitignore                     # Terraform-specific ignores
│
├── sample-app/
│   ├── src/
│   │   ├── index.js                   # Main application code
│   │   └── calculator.test.js         # Jest tests
│   ├── package.json                   # Node.js dependencies
│   ├── jest.config.js                 # Jest configuration
│   ├── .gitignore                     # Node.js ignores
│   └── README.md                      # App documentation
│
├── README.md                          # Main project documentation
├── QUICKSTART.md                      # 15-minute setup guide
├── CONCEPTS.md                        # Self-hosted vs container explanation
├── ARCHITECTURE.md                    # Technical architecture details
├── TROUBLESHOOTING.md                 # Problem-solving guide
├── PROJECT_STRUCTURE.md              # This file
└── .gitignore                         # Project-wide ignores
```

---

## 📄 File Descriptions

### Root Level Documentation

#### `README.md`
**Purpose:** Main project documentation  
**Contains:**
- Project overview and architecture diagram
- Complete setup instructions
- Prerequisites checklist
- Step-by-step deployment guide
- Testing procedures
- Troubleshooting basics
- Cost estimation
- Cleanup instructions

**When to use:** Start here for complete project understanding

---

#### `QUICKSTART.md`
**Purpose:** Fast-track setup guide  
**Contains:**
- Streamlined 15-minute setup process
- Prerequisites checklist
- Step-by-step with time estimates
- Quick troubleshooting
- Success checklist

**When to use:** You want to get running ASAP

---

#### `CONCEPTS.md`
**Purpose:** Educational deep dive  
**Contains:**
- What is a self-hosted runner?
- What are container jobs?
- Key differences table
- How they work together
- Visual diagrams
- Use cases
- Benefits and trade-offs
- Decision tree

**When to use:** You want to understand the "why" and "how"

---

#### `ARCHITECTURE.md`
**Purpose:** Technical architecture reference  
**Contains:**
- Network topology
- Component architecture
- Data flow diagrams
- Security architecture
- Storage layout
- Lifecycle management
- Resource allocation
- Monitoring points

**When to use:** You need technical details for production planning

---

#### `TROUBLESHOOTING.md`
**Purpose:** Problem-solving guide  
**Contains:**
- Quick diagnostics script
- Common issues and fixes
- Step-by-step debugging
- Advanced debugging techniques
- Emergency procedures
- Prevention checklist

**When to use:** Something isn't working

---

#### `PROJECT_STRUCTURE.md`
**Purpose:** File organization reference  
**Contains:**
- Complete file tree
- File descriptions
- Usage guidelines
- Customization tips

**When to use:** You want to understand the project layout

---

#### `.gitignore`
**Purpose:** Git ignore rules  
**Contains:**
- Terraform state files
- Node.js dependencies
- Sensitive files (*.pem, *.tfvars)
- IDE files
- OS files

**When to use:** Automatically used by Git

---

### GitHub Workflows (`.github/workflows/`)

#### `ci-docker.yml`
**Purpose:** Main CI/CD workflow demonstrating Docker containers  
**Contains:**
- Job running in Docker container (Node.js 18)
- Matrix testing (Node.js 16, 18, 20)
- Job running directly on runner
- Manual Docker container usage

**Triggers:**
- Push to `main` or `master`
- Pull requests
- Manual dispatch

**Features:**
- Environment information display
- Dependency installation
- Test execution
- Coverage reports
- Multiple Node.js version testing

**When to use:** Main workflow for your Node.js app

---

#### `simple-test.yml`
**Purpose:** Simple verification workflow  
**Contains:**
- Basic runner information
- Docker availability check
- Simple container test

**Triggers:**
- Push to `main` or `master`
- Manual dispatch

**When to use:** Verify runner setup is working

---

### Terraform Infrastructure (`terraform/`)

#### `main.tf`
**Purpose:** Primary infrastructure definition  
**Contains:**
- Provider configuration (AWS)
- VPC and networking resources
- Security groups
- IAM roles and policies
- EC2 instance definition
- Key pair configuration

**Resources Created:**
- 1x VPC
- 1x Internet Gateway
- 1x Public Subnet
- 1x Route Table
- 1x Security Group
- 1x IAM Role + Instance Profile
- 1x Key Pair
- 1x EC2 Instance (t3.medium)

**When to modify:**
- Change instance type
- Add/modify security rules
- Adjust network configuration
- Change region

---

#### `variables.tf`
**Purpose:** Variable definitions  
**Contains:**
- All configurable parameters
- Default values
- Descriptions
- Type constraints
- Sensitive markers

**Key Variables:**
- `aws_region`: AWS region
- `instance_type`: EC2 instance size
- `ssh_public_key`: Your SSH public key
- `github_token`: GitHub PAT (sensitive)
- `github_repo_url`: Your repository URL
- `ssh_allowed_ips`: IP whitelist for SSH

**When to modify:**
- Add new configurable parameters
- Change defaults
- Add validation rules

---

#### `outputs.tf`
**Purpose:** Output values after deployment  
**Contains:**
- VPC ID
- Runner public IP
- Instance ID
- SSH command
- Security group ID

**When to use:**
```bash
terraform output runner_public_ip
terraform output ssh_command
```

---

#### `terraform.tfvars.example`
**Purpose:** Example configuration file  
**Contains:**
- Sample values for all variables
- Comments explaining each setting
- Links to documentation

**How to use:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Never commit** `terraform.tfvars` (contains secrets!)

---

#### `user-data.sh`
**Purpose:** EC2 instance initialization script  
**Contains:**
- System package updates
- Docker installation
- User creation (runner)
- GitHub Actions Runner download
- Runner configuration
- Service installation
- Verification script creation

**Execution:**
- Runs automatically when EC2 instance starts
- Logs to `/var/log/user-data.log`
- Takes 3-5 minutes to complete

**When to modify:**
- Change runner configuration
- Install additional software
- Modify user permissions
- Add custom scripts

---

#### `.gitignore` (Terraform-specific)
**Purpose:** Prevent committing Terraform state  
**Contains:**
- `.terraform/` directory
- `*.tfstate` files
- `*.tfvars` files (contain secrets)
- Lock files

---

### Sample Application (`sample-app/`)

#### `src/index.js`
**Purpose:** Main application code  
**Contains:**
- Express.js server
- Calculator functions
- REST API endpoints
- Error handling

**Endpoints:**
- `GET /`: Welcome message
- `GET /health`: Health check
- `POST /calculate`: Calculator API

**When to modify:**
- Add new features
- Add more endpoints
- Implement your own logic

---

#### `src/calculator.test.js`
**Purpose:** Jest unit tests  
**Contains:**
- Tests for add, subtract, multiply, divide
- Edge cases (zero, negatives)
- Error handling tests

**When to modify:**
- Add tests for new features
- Improve test coverage
- Add integration tests

---

#### `package.json`
**Purpose:** Node.js project configuration  
**Contains:**
- Project metadata
- Dependencies (Express)
- Dev dependencies (Jest)
- NPM scripts

**Scripts:**
- `npm start`: Run the app
- `npm test`: Run tests
- `npm run test:coverage`: Run tests with coverage

**When to modify:**
- Add new dependencies
- Add new scripts
- Update versions

---

#### `jest.config.js`
**Purpose:** Jest testing configuration  
**Contains:**
- Test environment (Node.js)
- Coverage settings
- Test file patterns

**When to modify:**
- Adjust coverage thresholds
- Add test setup files
- Configure test reporters

---

#### `.gitignore` (App-specific)
**Purpose:** Prevent committing Node.js artifacts  
**Contains:**
- `node_modules/`
- Coverage reports
- Log files

---

#### `README.md` (App-specific)
**Purpose:** Application documentation  
**Contains:**
- App features
- Installation instructions
- Running the app
- API documentation
- Example requests

---

## 🎯 Usage Scenarios

### Scenario 1: First-Time Setup

```
1. Read: README.md (overview)
2. Follow: QUICKSTART.md (setup)
3. Configure: terraform/terraform.tfvars
4. Deploy: terraform apply
5. Verify: Check GitHub Settings → Actions → Runners
```

### Scenario 2: Understanding Architecture

```
1. Read: CONCEPTS.md (learn concepts)
2. Read: ARCHITECTURE.md (technical details)
3. Examine: terraform/main.tf (implementation)
```

### Scenario 3: Troubleshooting

```
1. Check: TROUBLESHOOTING.md (common issues)
2. Run: Quick diagnostics script
3. Review: terraform/user-data.sh (setup script)
4. Check: /var/log/user-data.log on runner
```

### Scenario 4: Customizing Workflows

```
1. Review: .github/workflows/ci-docker.yml (examples)
2. Modify: Create your own workflow
3. Test: Push to repository
4. Debug: Use TROUBLESHOOTING.md if needed
```

### Scenario 5: Customizing Infrastructure

```
1. Review: terraform/main.tf (current setup)
2. Modify: Change instance type, add resources
3. Review: ARCHITECTURE.md (understand impact)
4. Apply: terraform plan && terraform apply
```

---

## 🔧 Customization Guide

### Adding a New Language/Runtime

**Option 1: Modify user-data.sh**

```bash
# In terraform/user-data.sh, add:
apt-get install -y python3 python3-pip
```

**Option 2: Use Container with that runtime**

```yaml
# In workflow file:
container:
  image: python:3.11
```

### Adding Multiple Runners

Modify `terraform/main.tf`:

```hcl
resource "aws_instance" "github_runner" {
  count = 3  # Creates 3 runners
  # ... rest of config
  
  user_data = templatefile("${path.module}/user-data.sh", {
    runner_name = "${var.runner_name}-${count.index}"
    # ... other variables
  })
}
```

### Adding Private Subnet

Add to `terraform/main.tf`:

```hcl
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.runner_vpc.id
  cidr_block = "10.0.2.0/24"
  # ... configuration
}
```

### Adding CloudWatch Monitoring

Add to `terraform/main.tf`:

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "runner-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  
  dimensions = {
    InstanceId = aws_instance.github_runner.id
  }
}
```

---

## 📊 File Sizes (Approximate)

```
Total Project Size: ~50 KB (without dependencies)

Documentation:
├── README.md            (~15 KB)
├── QUICKSTART.md        (~8 KB)
├── CONCEPTS.md          (~20 KB)
├── ARCHITECTURE.md      (~15 KB)
├── TROUBLESHOOTING.md   (~12 KB)
└── PROJECT_STRUCTURE.md (~10 KB)

Terraform:
├── main.tf              (~5 KB)
├── variables.tf         (~2 KB)
├── outputs.tf           (~1 KB)
└── user-data.sh         (~3 KB)

Workflows:
├── ci-docker.yml        (~3 KB)
└── simple-test.yml      (~1 KB)

Sample App:
├── src/index.js         (~2 KB)
└── calculator.test.js   (~2 KB)
```

---

## 🔍 Quick Reference

### Most Important Files for Getting Started:
1. `QUICKSTART.md` - Get running fast
2. `terraform/terraform.tfvars.example` - Configuration template
3. `README.md` - Complete guide

### Most Important Files for Learning:
1. `CONCEPTS.md` - Understand the architecture
2. `ARCHITECTURE.md` - Technical deep dive
3. `.github/workflows/ci-docker.yml` - See workflows in action

### Most Important Files for Troubleshooting:
1. `TROUBLESHOOTING.md` - Fix issues
2. `terraform/user-data.sh` - Understand setup
3. `/var/log/user-data.log` - See initialization logs (on runner)

### Most Important Files for Customization:
1. `terraform/main.tf` - Infrastructure
2. `terraform/variables.tf` - Configuration options
3. `.github/workflows/ci-docker.yml` - Workflow examples

---

## ✅ Checklist for New Users

- [ ] Read README.md overview
- [ ] Follow QUICKSTART.md setup
- [ ] Understand CONCEPTS.md (self-hosted vs container)
- [ ] Configure terraform/terraform.tfvars
- [ ] Deploy with terraform apply
- [ ] Verify runner in GitHub
- [ ] Push code and watch workflows run
- [ ] Bookmark TROUBLESHOOTING.md for later

---

## 🎓 Learning Path

**Level 1: Beginner**
- Read: README.md
- Do: QUICKSTART.md setup
- Test: Push code and watch simple-test.yml run

**Level 2: Intermediate**
- Read: CONCEPTS.md
- Understand: Self-hosted runners vs containers
- Customize: Modify ci-docker.yml for your app

**Level 3: Advanced**
- Read: ARCHITECTURE.md
- Understand: Network, security, lifecycle
- Customize: Modify terraform/main.tf
- Scale: Add monitoring, multiple runners

---

**Questions about file structure?** Open an issue!

