#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}





# Detect the shell and update the appropriate config file
update_shell_config() {
    if [ "$SHELL" = "/bin/zsh" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ "$SHELL" = "/bin/bash" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    else
        echo -e "${YELLOW}Unsupported shell. Please manually add the following to your shell configuration:${NC}"
        echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin:~/tools"
        return 1
    fi

    echo -e "${BLUE}Updating ${SHELL_CONFIG}...${NC}"
    echo 'export PATH=$PATH:/usr/local/go/bin:~/go/bin:~/tools' >> "$SHELL_CONFIG"
    echo -e "${GREEN}Shell configuration updated. Please open a new terminal session to apply the changes.${NC}"
}






# Update package list
echo -e "${BLUE}Updating package list...${NC}"
sudo apt update

# Install prerequisites
echo -e "${BLUE}Installing prerequisite tools...${NC}"
sudo apt install -y curl git python3 wget python3-pip libpcap-dev

# Install Go if not already installed
if ! command_exists go; then
    echo -e "${YELLOW}Installing Go...${NC}"
    wget https://go.dev/dl/go1.17.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
    rm go1.17.linux-amd64.tar.gz
else
    echo -e "${GREEN}Go is already installed${NC}"
fi




# Create tools directory
echo -e "${BLUE}Creating tools directory...${NC}"
mkdir -p ~/tools
cd ~/tools


# Ensure proper permissions for Go directories
sudo mkdir -p /usr/local/go
sudo chown -R $USER:$USER /usr/local/go
mkdir -p ~/go
sudo chown -R $USER:$USER ~/go

# Function to install Go tools
install_go_tool() {
    if ! command_exists $1; then
        echo -e "${YELLOW}Installing $1...${NC}"
        GO111MODULE=on go install $2@latest
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$1 installed successfully!${NC}"
        else
            echo -e "${RED}Failed to install $1${NC}"
        fi
    else
        echo -e "${GREEN}$1 is already installed${NC}"
    fi
}


# Install Go-based tools
#######################
declare -a tools=(
    "subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "httpx github.com/projectdiscovery/httpx/cmd/httpx"
    "nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "naabu github.com/projectdiscovery/naabu/v2/cmd/naabu"
    "kxss github.com/Emoe/kxss"
    "qsreplace github.com/tomnomnom/qsreplace"
    "gf github.com/tomnomnom/gf"
    "dalfox github.com/hahwul/dalfox/v2"
    "ffuf github.com/ffuf/ffuf/v2"
    "subov88r github.com/h0tak88r/subov88r"
)

# loop through the array and install each tool
for tool in "${tools[@]}"; do
    name=$(echo "$tool" | awk '{print $1}')
    repo=$(echo "$tool" | awk '{print $2}')
    install_go_tool "$name" "$repo"
done


# Install Python-based tools
if ! command_exists waymore; then
    echo -e "${YELLOW}Installing waymore...${NC}"
    git clone https://github.com/xnl-h4ck3r/waymore.git
    cd waymore
    sudo python3 setup.py install
    cd ..
    echo -e "${GREEN}waymore installed successfully!${NC}"
else
    echo -e "${GREEN}waymore is already installed${NC}"
fi


if [ ! -d "Interlace" ]; then
    echo -e "${YELLOW}Installing interlace...${NC}"
    git clone https://github.com/codingo/Interlace.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clone Interlace repository${NC}"
        exit 1
    fi
    cd Interlace
    echo -e "${BLUE}Installing Interlace dependencies...${NC}"
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Interlace dependencies${NC}"
        exit 1
    fi
    echo -e "${BLUE}Running Interlace setup...${NC}"
    sudo python3 setup.py install
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to run Interlace setup${NC}"
        exit 1
    fi
    cd ..
    echo -e "${GREEN}interlace installed successfully!${NC}"
else
    echo -e "${GREEN}interlace is already installed${NC}"
fi


# installing urldedupe

if [ ! -d "urldedupe" ]; then
    echo -e "${YELLOW}Installing urldedupe...${NC}"
    git clone https://github.com/ameenmaali/urldedupe.git
    cd urldedupe || { echo "Failed to enter directory urldedupe"; exit 1; }
    
    if ! command_exists cmake;then 
        echo -e "${YELLOW}CMake not found. Installing cmake...${NC}"
        sudo apt install -y cmake
    fi

    echo -e "${BLUE}Running cmake CMakeLists.txt...${NC}"
    cmake CMakeLists.txt
    
    echo -e "${BLUE}Building urldedupe with make...${NC}"
    make
else
    echo -e "${BLUE}urldedupe is already installed.${NC}"
fi




# Update shell configuration
update_shell_config

#permissions for installed binaries
sudo chown -R $USER:$USER ~/go/bin


echo -e "${GREEN}All tools installed successfully!${NC}"
echo -e "${YELLOW}Please restart your terminal or run 'source ${SHELL_CONFIG}' to apply changes.${NC}"