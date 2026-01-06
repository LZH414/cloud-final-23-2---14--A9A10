# 环境安装指南

本文档介绍如何安装运行此项目所需的所有工具。

## 必需工具

### 1. Node.js 和 npm

#### macOS (使用 Homebrew)
```bash
brew install node
```

#### Linux (Ubuntu/Debian)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### Windows
下载并安装：https://nodejs.org/

#### 验证安装
```bash
node --version  # 应该显示 v18.x.x
npm --version   # 应该显示 9.x.x 或更高
```

### 2. Docker

#### macOS
下载并安装 Docker Desktop：https://www.docker.com/products/docker-desktop/

#### Linux (Ubuntu/Debian)
```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y ca-certificates curl gnupg

# 添加 Docker 官方 GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 设置仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker
```

#### Windows
下载并安装 Docker Desktop：https://www.docker.com/products/docker-desktop/

#### 验证安装
```bash
docker --version
docker ps
```

### 3. Docker Compose

Docker Compose 现在作为 Docker 插件包含在 Docker Desktop 中。

#### 验证安装
```bash
docker compose version
```

### 4. kubectl (可选，用于 Kubernetes 部署)

#### macOS
```bash
brew install kubectl
```

#### Linux
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Windows
下载并安装：https://kubernetes.io/docs/tasks/tools/

#### 验证安装
```bash
kubectl version --client
```

### 5. Trivy (可选，用于安全扫描)

#### macOS
```bash
brew install trivy
```

#### Linux
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

#### 验证安装
```bash
trivy --version
```

### 6. jq (可选，用于 JSON 处理)

#### macOS
```bash
brew install jq
```

#### Linux
```bash
sudo apt-get install jq
```

#### 验证安装
```bash
jq --version
```

## 本地 Kubernetes 集群（可选）

### Kind (Kubernetes in Docker)

#### 安装
```bash
# macOS/Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### 创建集群
```bash
kind create cluster --name cloud-native-demo
```

### Minikube

#### 安装
```bash
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### 启动集群
```bash
minikube start
```

## 快速启动指南

### 1. 安装所有必需工具
按照上述说明安装 Node.js、Docker 和 Docker Compose。

### 2. 克隆或进入项目目录
```bash
cd /path/to/cloud-native-demo
```

### 3. 安装项目依赖
```bash
npm install
```

### 4. 运行测试
```bash
npm test
```

### 5. 使用 Docker Compose 启动
```bash
docker-compose up -d
```

### 6. 访问应用
打开浏览器访问：http://localhost:3000

### 7. 查看日志
```bash
docker-compose logs -f
```

### 8. 停止服务
```bash
docker-compose down
```

## 故障排查

### Node.js 版本问题
确保使用 Node.js 18 或更高版本：
```bash
nvm install 18
nvm use 18
```

### Docker 权限问题
如果遇到 Docker 权限错误：
```bash
sudo usermod -aG docker $USER
# 重新登录或运行
newgrp docker
```

### 端口已被占用
如果 3000 端口已被占用，修改 docker-compose.yml 中的端口映射：
```yaml
ports:
  - "3001:3000"  # 使用 3001 端口
```

### 内存不足
如果 Docker 内存不足，增加 Docker Desktop 的内存分配：
- Docker Desktop > Settings > Resources > Memory
- 建议至少 4GB

## 下一步

安装完成后，请参考 [README.md](README.md) 了解如何使用项目的完整功能。
