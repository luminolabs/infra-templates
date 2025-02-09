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

# Setup base virtualenv if no cache
if [ "$BASE_VENV_CACHE_HIT" != 'true' ]; then

    # Check if Python version exists before installing
    if ! pyenv versions | grep -q $PYTHON_VERSION; then
        pyenv install $PYTHON_VERSION
    else
        echo "Python $PYTHON_VERSION already installed"
    fi

    echo "Setting up base virtualenv"
    pyenv virtualenv -f $PYTHON_VERSION $BASE_VENV_NAME
    pyenv activate $BASE_VENV_NAME
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt -r requirements-test.txt
    pyenv deactivate
fi

# Setup PR virtualenv only if requirements.txt/requirements-test.txt changed
if [ "$REQS_CHANGED" == 'true' ]; then
    if [ "$PR_VENV_CACHE_HIT" != 'true' ]; then
        echo "Dependencies changed, setting up PR virtualenv"
        pyenv virtualenv -f $PYTHON_VERSION $PR_VENV_NAME
        pyenv activate $PR_VENV_NAME
        pip install --upgrade pip setuptools wheel
        pip install -r requirements.txt -r requirements-test.txt
        pyenv deactivate
    fi
    VENV_TO_USE=$PR_VENV_NAME
else
    echo "Using base virtualenv"
    VENV_TO_USE=$BASE_VENV_NAME
fi

# Run tests using appropriate virtualenv
pyenv activate $VENV_TO_USE
PYTHONPATH=$(pwd) python -m pytest tests/ -v
pyenv deactivate
