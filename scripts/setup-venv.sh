#!/bin/bash
set -e

echo "=== Setting up Python virtual environment ==="

# Находим python3
PYTHON_CMD=$(command -v python3)
echo "Found Python version: $($PYTHON_CMD --version)"

# Очищаем старое окружение, если оно осталось с ошибками
if [ -d "venv" ]; then
    echo "Removing old venv..."
    rm -rf venv
fi

# Создаем виртуальное окружение
echo "Creating virtual environment in venv..."
$PYTHON_CMD -m venv venv

echo "✓ Virtual environment created."
echo "Activating virtual environment..."
source venv/bin/activate

# ==============================================================================
# КРИТИЧЕСКИ ВАЖНО: Настраиваем pip на использование зеркала и таймаутов
# Эти переменные применятся ко ВСЕМ последующим командам pip в этом скрипте
# ==============================================================================
export PIP_DEFAULT_TIMEOUT=100
export PIP_RETRIES=5
export PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
export PIP_TRUSTED_HOST="pypi.tuna.tsinghua.edu.cn"

echo "Upgrading pip (using mirror)..."
pip install --upgrade pip

echo "Installing Python dependencies from requirements.txt (using mirror)..."
pip install -r requirements.txt

echo "=== Python virtual environment setup complete! ==="
echo "To activate manually, run: source venv/bin/activate"