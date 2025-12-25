# Setup Instructions

## Quick Setup

### 1. Install Python Virtual Environment Support (One-time)

On Ubuntu/Debian/WSL:
```bash
sudo apt update
sudo apt install python3-venv
```

On other systems, `venv` is usually included with Python.

### 2. Run Setup Script

```bash
cd /home/jim/projects/cursor-test
./setup.sh
```

The script will:
- Check Python version
- Create virtual environment in `venv/`
- Install all dependencies from `requirements.txt`

### 3. Configure Environment Variables

```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

Add your GitHub Personal Access Token to the `.env` file.

### 4. Verify Setup

```bash
source venv/bin/activate
python -c "from scripts.utils.github_api import GitHubAPI; api = GitHubAPI(); print('✓ Setup successful!')"
```

---

## Manual Setup (Alternative)

If you prefer to set up manually:

```bash
# 1. Create virtual environment
python3 -m venv venv

# 2. Activate virtual environment
source venv/bin/activate

# 3. Upgrade pip
pip install --upgrade pip

# 4. Install dependencies
pip install -r requirements.txt

# 5. Configure environment
cp .env.example .env
# Edit .env with your GitHub token

# 6. Verify
python -c "from scripts.utils.github_api import GitHubAPI; api = GitHubAPI(); print('✓ Ready!')"
```

---

## Daily Workflow

Before working on the project each day:

```bash
cd /home/jim/projects/cursor-test
source venv/bin/activate
```

Your terminal prompt will show `(venv)` when the virtual environment is active.

To deactivate when done:
```bash
deactivate
```

---

## Troubleshooting

### "python3-venv not found"
**Solution**: Install it first:
```bash
sudo apt install python3-venv
```

### "GITHUB_API_KEY not found"
**Solution**: Make sure `.env` file exists and contains your token:
```bash
cp .env.example .env
# Edit .env and add your token
```

### "Module not found" errors
**Solution**: Make sure virtual environment is activated and dependencies installed:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Scripts not executable
**Solution**: Make them executable:
```bash
chmod +x setup.sh
chmod +x scripts/github/*.py
```

