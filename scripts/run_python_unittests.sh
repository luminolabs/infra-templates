#!/bin/bash
set -e

PYTHON_VERSION=${PYTHON_VERSION:-"3.11.10"}
BASE_VENV_NAME="venv-$REPO_NAME-base-$PYTHON_VERSION"
PR_VENV_NAME="venv-$REPO_NAME-pr$PR_NUMBER-$PYTHON_VERSION"

# Function to setup pyenv
setup_pyenv() {

    # First check if pyenv exists in common locations
    if [ -d "$HOME/.pyenv" ]; then
        echo "Found pyenv in $HOME/.pyenv"
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
        return 0
    fi

    if ! command -v pyenv &> /dev/null; then
        echo "Installing pyenv..."
        # Remove existing pyenv if installation failed previously
        if [ -d "$HOME/.pyenv" ]; then
            echo "Removing existing incomplete pyenv installation"
            rm -rf "$HOME/.pyenv"
        fi
        curl https://pyenv.run | bash
    fi

    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
}

setup_pyenv

# # Handle Python version check without pipe
# pyenv versions > /tmp/pyenv_versions
# if ! grep -q $PYTHON_VERSION /tmp/pyenv_versions; then
#     pyenv install $PYTHON_VERSION
# else
#     echo "Python $PYTHON_VERSION already installed"
# fi

# Create a temporary file with unique name and ensure cleanup
TEMP_FILE=$(mktemp)
trap 'rm -f $TEMP_FILE' EXIT  # Will delete temp file when script exits

# Handle Python version check without pipe using temp file
pyenv versions > "$TEMP_FILE"
if ! grep -q $PYTHON_VERSION "$TEMP_FILE"; then
    pyenv install $PYTHON_VERSION
else
    echo "Python $PYTHON_VERSION already installed"
fi

# Determine which virtualenv to use/create
if [ "$REQS_CHANGED" == 'true' ]; then
    echo "Requirements changed, using PR virtualenv"
    VENV_NAME=$PR_VENV_NAME
    CACHE_HIT=$PR_VENV_CACHE_HIT
else
    echo "Using base virtualenv"
    VENV_NAME=$BASE_VENV_NAME
    CACHE_HIT=$BASE_VENV_CACHE_HIT
fi

# Setup virtualenv if needed (if cache miss)
if [ "$CACHE_HIT" != 'true' ]; then
    echo "Setting up virtualenv: $VENV_NAME"
    pyenv virtualenv -f $PYTHON_VERSION $VENV_NAME
    pyenv activate $VENV_NAME
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt -r requirements-test.txt
    pyenv deactivate
else
    echo "Using cached virtualenv: $VENV_NAME"
fi

# Run tests
pyenv activate $VENV_NAME
PYTHONPATH=$(pwd) python -m pytest tests/ -v
pyenv deactivate
