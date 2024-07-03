#!/bin/bash

# Function to install Go tools
install_go_tools() {
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/notify/cmd/notify@latest
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    go install github.com/d3mondev/puredns/v2@latest
    go install github.com/glebarez/cero@latest
    go install github.com/Emoe/kxss@latest
    go install github.com/lc/gau/v2/cmd/gau@latest
    go install github.com/ffuf/ffuf/v2@latest
}

# Function to install urldedupe
install_urldedupe() {
    git clone https://github.com/ameenmaali/urldedupe.git
    cd urldedupe
    cmake CMakeLists.txt
    make
    sudo mv urldedupe /bin/
    cd ..
}

# Function to install naabu
install_naabu() {
    sudo apt-get install -y libpcap-dev
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
}

# Function to install massdns
install_massdns() {
    git clone https://github.com/blechschmidt/massdns.git
    cd massdns
    make
    sudo make install
    cd ..
}

# Function to install nuclei templates
install_nuclei_templates() {
    git clone https://github.com/h0tak88r/nuclei_templates.git
}

# Function to install aquatone
install_aquatone() {
    wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
    unzip aquatone_linux_amd64_1.7.0.zip
    chmod +x aquatone
    sudo mv aquatone /usr/local/bin/
}

# Function to check and install required tools
install_required_tools() {
    REQUIRED_TOOLS=("subfinder" "httpx" "gau" "subov88r" "nuclei" "naabu" "kxss" "qsreplace" "gf" "dalfox" "ffuf" "interlace" "ghauri")
    for TOOL in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$TOOL" &> /dev/null; then
            echo "Error: $TOOL is not installed."
            echo "To install $TOOL, run the appropriate command:"
            case "$TOOL" in
                subfinder) echo "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" ;;
                httpx) echo "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest" ;;
                gau) echo "go install github.com/lc/gau/v2/cmd/gau@latest" ;;
                subov88r) echo "go install github.com/h0tak88r/subov88r@latest" ;;
                nuclei) echo "go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest" ;;
                naabu) echo "sudo apt install -y libpcap-dev && go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" ;;
                kxss) echo "go install -v github.com/tomnomnom/hacks/kxss@latest" ;;
                qsreplace) echo "go install -v github.com/tomnomnom/qsreplace@latest" ;;
                gf) echo "go install -v github.com/tomnomnom/gf@latest" ;;
                dalfox) echo "go install -v github.com/hahwul/dalfox/v2@latest" ;;
                ffuf) echo "go install -v github.com/ffuf/ffuf@latest" ;;
                interlace) echo "git clone https://github.com/codingo/Interlace.git && cd Interlace/ && python3 setup.py install" ;;
                ghauri) echo "git clone https://github.com/r0oth3x49/ghauri.git ; cd ghauri/ ; python3 -m pip install --upgrade -r requirements.txt && python3 setup.py install" ;;
                *) echo "Please install $TOOL manually." ;;
            esac
            exit 1
        fi
    done
}

# Main setup function
setup() {
    install_go_tools
    install_urldedupe
    install_naabu
    install_massdns
    install_nuclei_templates
    install_aquatone
    install_required_tools
}

# Run the setup
setup

echo "Setup complete."
