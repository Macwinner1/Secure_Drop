# GitHub Action Setup for GHCR

This guide explains how to set up GitHub Actions to automatically build and push Docker images to GitHub Container Registry (GHCR).

## 🎯 What This Does

Every time you push to `main` or `develop` branch:
1. ✅ Runs tests and linting
2. ✅ Scans for security vulnerabilities
3. ✅ Builds Docker image
4. ✅ Pushes to `ghcr.io/YOUR_USERNAME/secure-drop`
5. ✅ (Optional) Deploys to EC2

## 🔧 Setup Steps

### 1. Enable GitHub Actions Permissions

Go to your repository → **Settings** → **Actions** → **General**

Under "Workflow permissions":
- ✅ Select **Read and write permissions**
- ✅ Check **Allow GitHub Actions to create and approve pull requests**
- Click **Save**

### 2. Make Package Public (Recommended)

After first successful build:

1. Go to your GitHub profile → **Packages**
2. Find `secure-drop` package
3. Click **Package settings**
4. Scroll to **Danger Zone**
5. Click **Change visibility** → **Public**

This allows pulling the image without authentication.

### 3. Add GitHub Secrets (For Deployment)

Only needed if you want automatic deployment to EC2:

Go to repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

| Secret | Value | Required |
|--------|-------|----------|
| `VPS_HOST` | Your EC2 IP address | For deployment |
| `VPS_USERNAME` | SSH username (usually `ubuntu`) | For deployment |
| `VPS_SSH_KEY` | Your EC2 private key | For deployment |

## 📦 Image Tags

The workflow creates multiple tags:

```bash
# Latest from main branch
ghcr.io/YOUR_USERNAME/secure-drop:latest

# Main branch with commit SHA
ghcr.io/YOUR_USERNAME/secure-drop:main-abc1234

# Develop branch
ghcr.io/YOUR_USERNAME/secure-drop:develop

# Develop branch with commit SHA
ghcr.io/YOUR_USERNAME/secure-drop:develop-abc1234
```

## 🚀 Trigger the Workflow

### Option 1: Push to GitHub
```bash
git add .
git commit -m "Trigger build"
git push origin main
```

### Option 2: Manual Trigger
1. Go to **Actions** tab
2. Select **CI/CD Pipeline**
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow**

## 📊 Monitor Build

1. Go to **Actions** tab in your repository
2. Click on the latest workflow run
3. Watch the progress:
   - ✅ Lint & Test
   - ✅ Security Scan
   - ✅ Build & Push
   - ✅ Deploy (if configured)

## 🔍 View Your Images

### On GitHub
Visit: `https://github.com/YOUR_USERNAME?tab=packages`

### Pull Image
```bash
# Public image (no auth needed)
docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest

# Private image (needs authentication)
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest
```

## 🔐 Authentication (For Private Images)

### Create Personal Access Token (PAT)

1. Go to GitHub **Settings** → **Developer settings**
2. Click **Personal access tokens** → **Tokens (classic)**
3. Click **Generate new token (classic)**
4. Give it a name: "GHCR Access"
5. Select scopes:
   - ✅ `read:packages`
   - ✅ `write:packages`
6. Click **Generate token**
7. **Copy the token** (you won't see it again!)

### Login to GHCR
```bash
echo YOUR_PAT_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

### Save Credentials (Optional)
```bash
# On your EC2 or local machine
docker login ghcr.io -u YOUR_USERNAME
# Enter PAT when prompted
# Credentials saved to ~/.docker/config.json
```

## 🛠️ Using the Image on EC2

### Update docker-compose.prod.yml

```yaml
services:
  app:
    image: ghcr.io/YOUR_USERNAME/secure-drop:latest
    # ... rest of config
```

### Pull and Run
```bash
# Login (if private)
echo YOUR_PAT | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull latest
docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest

# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🔄 Workflow File Explained

```yaml
# .github/workflows/ci-cd.yml

# Triggers on push to main/develop or PR to main
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

# Registry configuration
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/secure-drop

# Jobs:
jobs:
  lint-and-test:      # Run tests
  security-scan:      # Scan for vulnerabilities
  build-and-push:     # Build and push to GHCR
  deploy:             # Deploy to EC2 (optional)
```

## 🐛 Troubleshooting

### Build Fails

**Error: "Permission denied"**
- ✅ Check workflow permissions in Settings → Actions
- ✅ Enable "Read and write permissions"

**Error: "Authentication required"**
- ✅ Workflow uses `GITHUB_TOKEN` automatically
- ✅ No manual token needed for building

### Can't Pull Image

**Error: "unauthorized"**
- ✅ Make package public, OR
- ✅ Login with PAT: `docker login ghcr.io`

**Error: "not found"**
- ✅ Check image name matches: `ghcr.io/USERNAME/secure-drop`
- ✅ Verify build completed successfully
- ✅ Check package exists in GitHub Packages

### Deployment Fails

**Error: "Host key verification failed"**
- ✅ Add EC2 to known_hosts, OR
- ✅ Use `StrictHostKeyChecking=no` (less secure)

**Error: "Permission denied (publickey)"**
- ✅ Verify `VPS_SSH_KEY` secret is correct
- ✅ Include full key with BEGIN/END lines
- ✅ Check EC2 security group allows port 22

## 📋 Checklist

Before pushing:
- ✅ Workflow permissions enabled
- ✅ Tests passing locally
- ✅ Dockerfile builds successfully
- ✅ .env.example is up to date

After first build:
- ✅ Check Actions tab for success
- ✅ Verify image in Packages
- ✅ Make package public (optional)
- ✅ Test pulling image

For deployment:
- ✅ Add GitHub secrets
- ✅ EC2 has Docker installed
- ✅ EC2 security groups configured
- ✅ SSH key is correct

## 🎓 Best Practices

1. **Tag Strategy**: Use semantic versioning for releases
2. **Security**: Keep packages private if needed
3. **Caching**: Workflow uses layer caching for faster builds
4. **Testing**: Always run tests before building
5. **Monitoring**: Check Actions tab regularly

## 📚 Additional Resources

- [GitHub Container Registry Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

---

**Need Help?** Check the [DEPLOYMENT.md](../DEPLOYMENT.md) for full deployment guide.
