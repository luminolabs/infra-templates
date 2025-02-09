# #!/bin/bash
# set -e

# # Default Python version if not specified
# PYTHON_VERSION=${PYTHON_VERSION:-"3.11.10"}

# # Check if pyenv is installed
# if ! command -v pyenv &> /dev/null; then
#     echo "Installing pyenv..."
#     curl https://pyenv.run | bash
#     export PATH="$HOME/.pyenv/bin:$PATH"
#     eval "$(pyenv init -)"
#     eval "$(pyenv virtualenv-init -)"
# fi

# # Install specific Python version if not already installed
# if ! pyenv versions | grep -q $PYTHON_VERSION; then
#     echo "Installing Python $PYTHON_VERSION"
#     pyenv install $PYTHON_VERSION
# fi

# # Set local Python version
# pyenv local $PYTHON_VERSION

# # Create and activate virtual environment
# python -m venv venv
# source venv/bin/activate

# # Verify Python version
# python --version

# # Install dependencies
# pip install --upgrade pip setuptools wheel
# pip install -r requirements.txt -r requirements-test.txt

# # Run tests
# PYTHONPATH=$(pwd) pytest $(pwd)/tests -v

# # Deactivate
# deactivate





# #!/bin/bash
# set -e

# # Default Python version if not specified
# PYTHON_VERSION=${PYTHON_VERSION:-"3.11.10"}

# # Function to setup pyenv
# setup_pyenv() {

#     # First check if pyenv exists in common locations
#     if [ -d "$HOME/.pyenv" ]; then
#         echo "Found pyenv in $HOME/.pyenv"
#         export PYENV_ROOT="$HOME/.pyenv"
#         export PATH="$PYENV_ROOT/bin:$PATH"
#         eval "$(pyenv init -)"
#         eval "$(pyenv virtualenv-init -)"
#         return 0
#     fi

#    if ! command -v pyenv &> /dev/null; then
#        echo "Installing pyenv..."
#        # Remove existing pyenv if installation failed previously
#        if [ -d "$HOME/.pyenv" ]; then
#            echo "Removing existing incomplete pyenv installation"
#            rm -rf "$HOME/.pyenv"
#        fi
#        curl https://pyenv.run | bash
#    fi
#    export PATH="$HOME/.pyenv/bin:$PATH"
#    eval "$(pyenv init -)"
#    eval "$(pyenv virtualenv-init -)"
# }

# setup_pyenv

# # Check pyenv cache and install if needed
# if [ "$PYENV_CACHE_HIT" != 'true' ]; then
#    # Install specific version if not in cache
#    if ! [ -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
#        echo "Installing Python $PYTHON_VERSION"
#        pyenv install $PYTHON_VERSION
#    else
#        echo "Python $PYTHON_VERSION already installed"
#    fi
# else
#    echo "Using cached Python $PYTHON_VERSION"
# fi

# # Set local Python version
# pyenv local $PYTHON_VERSION

# # Create version-specific venv directory
# # VENV_DIR="venv-$PYTHON_VERSION"
# VENV_DIR="venv"
# # Remove existing venv if it exists
# if [ -d "$VENV_DIR" ]; then
#    rm -rf "$VENV_DIR"
# fi

# python -m venv $VENV_DIR
# source $VENV_DIR/bin/activate

# # Verify Python version
# python --version

# # Install Main dependencies
# if [ "$MAIN_PIP_CACHE_HIT" != 'true' ]; then
#    echo "Installing main dependencies..."
   
#    # Remove old cache if exists
#    if [ -d "~/.cache/pip/$REPO_NAME/$PR_NUMBER/main" ]; then
#        rm -rf ~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
#    fi
   
#    mkdir -p ~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
#    export PIP_CACHE_DIR=~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
#    pip install --upgrade pip setuptools wheel
#    pip install -r requirements.txt
# else
#    echo "Using cached main dependencies"
# fi

# # Install Test dependencies
# if [ "$TEST_PIP_CACHE_HIT" != 'true' ]; then
#    echo "Installing test dependencies..."
   
#    # Remove old cache if exists
#    if [ -d "~/.cache/pip/$REPO_NAME/$PR_NUMBER/test" ]; then
#        rm -rf ~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
#    fi
   
#    mkdir -p ~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
#    export PIP_CACHE_DIR=~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
#    pip install -r requirements-test.txt
# else
#    echo "Using cached test dependencies"
# fi

# # Run tests
# # PYTHONPATH=$(pwd) pytest $(pwd)/tests -v
# $(pwd)/$VENV_DIR/bin/pytest $(pwd)/tests -v

# # Deactivate
# deactivate





#!/bin/bash
set -e

PYTHON_VERSION=${PYTHON_VERSION:-"3.11.10"}
BASE_VENV_NAME="venv-base-$PYTHON_VERSION"
PR_VENV_NAME="venv-pr-$PYTHON_VERSION"

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
    echo "Setting up base virtualenv"
    # pyenv install -s $PYTHON_VERSION
    pyenv virtualenv -f $PYTHON_VERSION $BASE_VENV_NAME
    # mkdir -p ~/.pyenv/virtualenvs/venv-$REPO_NAME/base
    pyenv activate $BASE_VENV_NAME
    # git checkout origin/main
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt -r requirements-test.txt
    # git checkout -
    pyenv deactivate
fi

# Setup PR virtualenv only if requirements.txt/requirements-test.txt changed
if [ "$REQS_CHANGED" == 'true' ]; then
    if [ "$PR_VENV_CACHE_HIT" != 'true' ]; then
        echo "Dependencies changed, setting up PR virtualenv"
        pyenv virtualenv -f $PYTHON_VERSION $PR_VENV_NAME
        # mkdir -p ~/.pyenv/virtualenvs/venv-$REPO_NAME/pr$PR_NUMBER
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