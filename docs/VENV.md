# Virtual Environment Quick Reference

## For Users

Always activate before working:
```bash
cd /home/jim/projects/cursor-test
source venv/bin/activate
```

Your prompt will show `(venv)` when active.

To deactivate:
```bash
deactivate
```

## For AI Agents

**CRITICAL**: Always activate venv in terminal commands!

### Correct Pattern:
```bash
cd /home/jim/projects/cursor-test && source venv/bin/activate && python script.py
```

### Examples:

**Run Python script:**
```bash
source venv/bin/activate && python scripts/github/create_tickets.py plan.md
```

**Run tests:**
```bash
source venv/bin/activate && pytest
```

**Install package:**
```bash
source venv/bin/activate && pip install package-name
```

**Run Python one-liner:**
```bash
source venv/bin/activate && python -c "import sys; print(sys.version)"
```

### Never Do:
❌ `python script.py`  # Wrong - venv not activated
❌ `pip install package`  # Wrong - venv not activated

### Always Do:
✅ `source venv/bin/activate && python script.py`
✅ `source venv/bin/activate && pip install package`

## Verification

Test that venv is activated properly:
```bash
source venv/bin/activate && which python
# Should show: /home/jim/projects/cursor-test/venv/bin/python
```

---

**This ensures all Python dependencies are isolated and consistent!**

