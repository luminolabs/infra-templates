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


#!/bin/bash
set -e

# Default Python version if not specified
PYTHON_VERSION=${PYTHON_VERSION:-"3.11.10"}

# Function to setup pyenv
setup_pyenv() {
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

# Check pyenv cache and install if needed
if [ "$PYENV_CACHE_HIT" != 'true' ]; then
   # Install specific version if not in cache
   if ! [ -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
       echo "Installing Python $PYTHON_VERSION"
       pyenv install $PYTHON_VERSION
   else
       echo "Python $PYTHON_VERSION already installed"
   fi
else
   echo "Using cached Python $PYTHON_VERSION"
fi

# Set local Python version
pyenv local $PYTHON_VERSION

# Create version-specific venv directory
VENV_DIR="venv-$PYTHON_VERSION"
# Remove existing venv if it exists
if [ -d "$VENV_DIR" ]; then
   rm -rf "$VENV_DIR"
fi
python -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# Verify Python version
python --version

# Install Main dependencies
if [ "$MAIN_PIP_CACHE_HIT" != 'true' ]; then
   echo "Installing main dependencies..."
   
   # Remove old cache if exists
   if [ -d "~/.cache/pip/$REPO_NAME/$PR_NUMBER/main" ]; then
       rm -rf ~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
   fi
   
   mkdir -p ~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
   export PIP_CACHE_DIR=~/.cache/pip/$REPO_NAME/$PR_NUMBER/main
   pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
else
   echo "Using cached main dependencies"
fi

# Install Test dependencies
if [ "$TEST_PIP_CACHE_HIT" != 'true' ]; then
   echo "Installing test dependencies..."
   
   # Remove old cache if exists
   if [ -d "~/.cache/pip/$REPO_NAME/$PR_NUMBER/test" ]; then
       rm -rf ~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
   fi
   
   mkdir -p ~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
   export PIP_CACHE_DIR=~/.cache/pip/$REPO_NAME/$PR_NUMBER/test
   pip install -r requirements-test.txt
else
   echo "Using cached test dependencies"
fi

# Run tests
PYTHONPATH=$(pwd) pytest $(pwd)/tests -v

# Deactivate
deactivate