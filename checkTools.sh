#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Array of tools to check
tools=(
    "go"
    "subfinder"
    "httpx"
    "nuclei"
    "naabu"
    "kxss"
    "qsreplace"
    "gf"
    "dalfox"
    "ffuf"
    "urldedupe"
    "waymore"
    "subov88r"
    "interlace"
)

echo -e "${BLUE}Checking for installed tools...${NC}"

uninstalled_tools=()

for tool in "${tools[@]}"
do
    if command_exists "$tool"; then
        echo -e "${GREEN}$tool is installed${NC}"
    else
        echo -e "${RED}$tool is not installed${NC}"
        uninstalled_tools+=("$tool")
    fi
done

echo -e "\n${YELLOW}Summary of uninstalled tools:${NC}"
if [ ${#uninstalled_tools[@]} -eq 0 ]; then
    echo -e "${GREEN}All tools are installed!${NC}"
else
    for tool in "${uninstalled_tools[@]}"
    do
        echo -e "${RED}- $tool${NC}"
    done
    echo -e "\n${YELLOW}You may want to try installing these tools manually.${NC}"
fi