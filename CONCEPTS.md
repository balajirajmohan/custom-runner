# Self-Hosted Runners vs Container Jobs: A Deep Dive

This document explains the key concepts of GitHub self-hosted runners and container jobs, how they differ, and how they work together.

## 📚 Table of Contents

1. [What is a Self-Hosted Runner?](#what-is-a-self-hosted-runner)
2. [What are Container Jobs?](#what-are-container-jobs)
3. [Key Differences](#key-differences)
4. [How They Work Together](#how-they-work-together)
5. [Practical Examples](#practical-examples)
6. [Use Cases](#use-cases)
7. [Benefits and Trade-offs](#benefits-and-trade-offs)

---

## 🖥️ What is a Self-Hosted Runner?

### Definition

A **self-hosted runner** is a machine (physical or virtual) that you own and manage, which executes GitHub Actions workflows.

### Characteristics

- **Infrastructure**: YOU provide and maintain the machine
- **Operating System**: Can be Linux, Windows, or macOS
- **Location**: Can be anywhere - AWS, Azure, GCP, on-premises, or even your laptop
- **Persistence**: The runner machine stays running (or can be started on-demand)
- **Environment**: The runner has a persistent file system and installed tools

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                     GitHub.com                          │
│                                                         │
│  When workflow triggered:                              │
│  1. Finds available runner with matching labels        │
│  2. Sends job to runner                                │
│  3. Runner executes job steps                          │
│  4. Reports results back to GitHub                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ HTTPS polling
                     │ (Runner asks: "Any jobs for me?")
                     │
┌────────────────────▼────────────────────────────────────┐
│              Your Self-Hosted Runner                    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │  GitHub Actions Runner Agent (Service)            │ │
│  │  - Polls GitHub for jobs                          │ │
│  │  - Downloads workflow and code                    │ │
│  │  - Executes steps directly on the machine        │ │
│  │  - Cleans up after job completes                 │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
│  Installed Tools:                                      │
│  - Node.js, Python, Docker, etc.                      │
│  - Whatever you pre-install                           │
└─────────────────────────────────────────────────────────┘
```

### Specifying in Workflow

```yaml
jobs:
  my-job:
    runs-on: self-hosted  # Uses your self-hosted runner
```

### Who Manages What?

| Aspect | Managed By |
|--------|------------|
| Hardware/VM | You |
| Operating System | You |
| Runner Software | GitHub (you install/update) |
| Installed Tools | You |
| Security | You |
| Networking | You |
| Scaling | You |

---

## 🐳 What are Container Jobs?

### Definition

**Container jobs** are workflow jobs that execute inside a Docker container, regardless of where the runner is located.

### Characteristics

- **Isolation**: Each job runs in a fresh, isolated container
- **Consistency**: Same environment every time
- **Image-based**: Uses Docker images from Docker Hub, GitHub Container Registry, etc.
- **Ephemeral**: Container is destroyed after the job completes
- **Portable**: Works on any runner with Docker installed

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│              Self-Hosted Runner Machine                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  GitHub Actions Runner Agent                        │ │
│  │  1. Receives job from GitHub                        │ │
│  │  2. Sees "container: node:18" in workflow          │ │
│  │  3. Asks Docker Engine to create container         │ │
│  └──────────────┬─────────────────────────────────────┘ │
│                 │                                        │
│                 ▼                                        │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Docker Engine                                      │ │
│  │  - Pulls image if not cached                       │ │
│  │  - Creates container from image                    │ │
│  │  - Mounts workspace                                │ │
│  └──────────────┬─────────────────────────────────────┘ │
│                 │                                        │
│                 ▼                                        │
│  ┌────────────────────────────────────────────────────┐ │
│  │  🐳 Docker Container (node:18)                     │ │
│  │                                                     │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │  Job Steps Execute Here:                     │ │ │
│  │  │  - checkout code                              │ │ │
│  │  │  - npm install                                │ │ │
│  │  │  - npm test                                   │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  │                                                     │ │
│  │  Isolated filesystem, network, processes          │ │
│  └────────────────────────────────────────────────────┘ │
│                 │                                        │
│                 ▼ (container destroyed after job)       │
└─────────────────────────────────────────────────────────┘
```

### Specifying in Workflow

```yaml
jobs:
  my-job:
    runs-on: self-hosted
    container:
      image: node:18-alpine  # Runs inside this container
      options: --user root
```

---

## 🔄 Key Differences

| Aspect | Self-Hosted Runner | Container Job |
|--------|-------------------|---------------|
| **What is it?** | A machine that executes workflows | An execution environment within a runner |
| **Lifecycle** | Long-lived (persistent) | Short-lived (per-job) |
| **Environment** | Same machine state between jobs | Fresh environment every job |
| **Isolation** | Shared machine state | Isolated per job |
| **Setup Time** | One-time setup | Container startup per job (~seconds) |
| **Tool Installation** | Manual, persistent | Baked into Docker image |
| **Cleanup** | Manual or scripted | Automatic (container destroyed) |
| **Resource Usage** | Entire machine available | Limited by Docker container settings |
| **Flexibility** | Full control over machine | Limited to what's in the image |

### Visual Comparison

**Job on Self-Hosted Runner (No Container):**
```
┌─────────────────────────────────────────┐
│    Self-Hosted Runner Machine           │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Job Steps Execute Here:           │ │
│  │  - Uses tools installed on machine │ │
│  │  - Accesses host filesystem        │ │
│  │  - Shares state with other jobs    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Persistent tools: Node, Docker, etc.   │
└─────────────────────────────────────────┘
```

**Job on Self-Hosted Runner (WITH Container):**
```
┌──────────────────────────────────────────────┐
│    Self-Hosted Runner Machine                │
│                                               │
│  ┌──────────────────────────────────────┐   │
│  │  🐳 Docker Container                  │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │  Job Steps Execute Here:       │  │   │
│  │  │  - Isolated environment        │  │   │
│  │  │  - Tools from container image  │  │   │
│  │  │  - Fresh state every time      │  │   │
│  │  └────────────────────────────────┘  │   │
│  └──────────────────────────────────────┘   │
│                                               │
│  Docker Engine (runs containers)             │
└──────────────────────────────────────────────┘
```

---

## 🔗 How They Work Together

Self-hosted runners and container jobs are **complementary** technologies that work together:

### The Relationship

```
Self-Hosted Runner = WHERE the job runs (the infrastructure)
Container Job      = HOW the job runs (the execution environment)
```

### Layer Model

```
┌─────────────────────────────────────────────────────────┐
│  Layer 4: Job Steps                                     │
│  (Your actual workflow commands)                        │
│  └─ npm install, npm test, etc.                        │
└─────────────────────────────────────────────────────────┘
                     ▲
                     │ Runs inside
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Execution Environment (OPTIONAL)              │
│  └─ Docker Container (node:18-alpine)                  │
│     OR                                                  │
│  └─ Directly on runner machine                         │
└─────────────────────────────────────────────────────────┘
                     ▲
                     │ Managed by
┌─────────────────────────────────────────────────────────┐
│  Layer 2: GitHub Actions Runner Agent                   │
│  └─ Polls GitHub, downloads code, executes jobs        │
└─────────────────────────────────────────────────────────┘
                     ▲
                     │ Runs on
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Infrastructure                                │
│  └─ Your AWS EC2 instance (self-hosted runner)         │
└─────────────────────────────────────────────────────────┘
```

### Why Use Both?

1. **Self-Hosted Runner** gives you:
   - Control over hardware (cost, performance)
   - Access to internal resources (databases, networks)
   - Custom security policies
   - Persistent state if needed

2. **Container Jobs** add:
   - Consistent, reproducible environments
   - Isolation between jobs
   - Easy version management (image tags)
   - Automatic cleanup

### Real-World Scenario

**Problem**: You need to test a Node.js app that connects to an internal database.

**Solution**:
```yaml
jobs:
  test:
    runs-on: self-hosted  # ← Runner in your VPC with database access
    container:
      image: node:18      # ← Consistent Node.js environment
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm test      # ← Can reach database via runner's network
```

**Benefits**:
- ✅ Runner has network access to database (via VPC)
- ✅ Container provides consistent Node.js version
- ✅ Container is isolated and clean for each run
- ✅ You control the infrastructure cost

---

## 💡 Practical Examples

### Example 1: Direct Execution (No Container)

```yaml
jobs:
  test:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - run: node --version     # Uses Node.js installed on runner
      - run: npm install
      - run: npm test
```

**Execution**:
- Steps run directly on the runner machine
- Uses pre-installed Node.js version
- Shares filesystem with other jobs
- Fastest execution (no container overhead)

### Example 2: Container Execution

```yaml
jobs:
  test:
    runs-on: self-hosted
    container: node:18-alpine
    steps:
      - uses: actions/checkout@v4
      - run: node --version     # Uses Node.js 18 from container
      - run: npm install
      - run: npm test
```

**Execution**:
- Steps run inside Docker container
- Uses Node.js 18 specifically
- Fresh environment every time
- Slightly slower (container startup ~2-5 seconds)

### Example 3: Matrix Testing (Multiple Versions)

```yaml
jobs:
  test:
    runs-on: self-hosted
    strategy:
      matrix:
        node-version: [16, 18, 20]
    container: node:${{ matrix.node-version }}
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm test
```

**Execution**:
- Creates 3 jobs (Node 16, 18, 20)
- All run on the same self-hosted runner
- Each in isolated container
- Tests compatibility across versions

### Example 4: Custom Docker Commands

```yaml
jobs:
  test:
    runs-on: self-hosted
    # No container specified - runs on host
    steps:
      - uses: actions/checkout@v4
      - name: Build custom image
        run: docker build -t my-app .
      - name: Run tests in custom container
        run: docker run --rm my-app npm test
      - name: Cleanup
        run: docker rmi my-app
```

**Execution**:
- Job runs directly on runner
- Manually manages Docker containers
- Maximum flexibility
- Requires Docker knowledge

---

## 🎯 Use Cases

### When to Use Self-Hosted Runners

✅ **Use self-hosted when**:
- You need specific hardware (GPU, high memory, fast storage)
- You need access to internal resources (databases, APIs)
- You want to control costs (GitHub-hosted can be expensive for large teams)
- You need to comply with security policies
- You want persistent caching between jobs
- You need custom tools that take time to install

❌ **Don't use self-hosted when**:
- You're just starting out (GitHub-hosted is easier)
- You don't want to manage infrastructure
- You don't need special hardware or network access
- You want zero maintenance

### When to Use Container Jobs

✅ **Use containers when**:
- You need consistent environments across runs
- You want to test multiple versions (Node 16, 18, 20)
- You need isolation between jobs
- You want automatic cleanup
- You use common tools available in Docker images
- You want reproducible builds

❌ **Don't use containers when**:
- You need maximum performance (container adds overhead)
- You need tools not available in images
- You need access to host resources (GPU, USB devices)
- Container startup time is problematic

### Best Practices: Use Both

🎯 **Ideal Setup**:
```yaml
jobs:
  test:
    runs-on: self-hosted      # Your infrastructure
    container: node:18-alpine  # Consistent environment
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
```

**Why this is great**:
- ✅ Control over infrastructure (self-hosted)
- ✅ Consistent environment (container)
- ✅ Isolation and cleanup (container)
- ✅ Access to internal resources (runner's network)
- ✅ Predictable costs (self-hosted)

---

## ⚖️ Benefits and Trade-offs

### Self-Hosted Runner

**Benefits**:
- 💰 Cost control (pay for VM, not per-minute)
- 🔒 Security control (your network, your rules)
- 🚀 Performance (choose your hardware)
- 🔌 Internal access (databases, APIs)
- 💾 Persistent caching (faster builds)

**Trade-offs**:
- 🛠️ You manage updates and maintenance
- 🔐 You're responsible for security
- 📊 You need to monitor and scale
- 💸 You pay even when idle (unless using spot/scheduled instances)

### Container Jobs

**Benefits**:
- 🎯 Consistent environments
- 🧹 Automatic cleanup
- 🔄 Easy version switching
- 🏗️ Reproducible builds
- 🔒 Job isolation

**Trade-offs**:
- ⏱️ Container startup time (2-10 seconds)
- 📦 Image pull time (if not cached)
- 🐳 Requires Docker on runner
- 💻 Limited to container capabilities
- 📚 Requires Docker knowledge

---

## 🎓 Summary

### The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│  Self-Hosted Runner = Your Infrastructure Layer             │
│  - WHERE jobs run                                            │
│  - The physical/virtual machine                             │
│  - Long-lived, persistent                                   │
│  - You manage it                                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Provides platform for
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Container Jobs = Your Execution Environment Layer          │
│  - HOW jobs run                                             │
│  - Docker containers                                        │
│  - Short-lived, ephemeral                                   │
│  - GitHub Actions + Docker manage it                        │
└─────────────────────────────────────────────────────────────┘
```

### Key Takeaways

1. **Self-hosted runners** are machines you manage that execute GitHub Actions
2. **Container jobs** are an optional feature that runs jobs inside Docker containers
3. They work **together**: runner provides infrastructure, container provides isolation
4. You can use:
   - Self-hosted runner WITHOUT containers (direct execution)
   - Self-hosted runner WITH containers (recommended)
   - GitHub-hosted runners WITH containers (also works)
5. Best practice: **Self-hosted + containers** = control + consistency

### Decision Tree

```
Do you need specific hardware or internal network access?
  │
  ├─ NO → Use GitHub-hosted runners
  │        (Easiest, no maintenance)
  │
  └─ YES → Use self-hosted runners
           │
           ├─ Do you need consistent environments?
           │  │
           │  ├─ YES → Use containers on self-hosted
           │  │        (Best of both worlds)
           │  │
           │  └─ NO → Use self-hosted without containers
           │           (Maximum performance)
```

---

## 🔬 Advanced Topics

### Container Options

You can configure containers with additional options:

```yaml
container:
  image: node:18
  env:
    NODE_ENV: test
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  options: --cpus 2 --memory 4g
```

### Service Containers

Run supporting services (databases, Redis, etc.):

```yaml
jobs:
  test:
    runs-on: self-hosted
    container: node:18
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
```

### Docker-in-Docker

Run Docker commands inside container jobs:

```yaml
container:
  image: docker:latest
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

---

## 📚 Further Reading

- [GitHub: About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [GitHub: Running jobs in containers](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container)
- [Docker: Best practices](https://docs.docker.com/develop/dev-best-practices/)
- [Terraform: AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Questions or feedback?** Open an issue in this repository!

