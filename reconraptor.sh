#!/bin/bash

# ReconRaptor Logo
echo "=============================="
echo "  
┳┓       ┳┓         
┣┫┏┓┏┏┓┏┓┣┫┏┓┏┓╋┏┓┏┓
┛┗┗ ┗┗┛┛┗┛┗┗┻┣┛┗┗┛┛ 
             ┛      
=============================="

# Check if TARGET is provided
if [[ -z "$1" ]]; then
    printf "Usage: %s <target_domain> [-s single_subdomain]\n" "$0" >&2
    exit 1
fi

# Constants
RESULTS_DIR="results"
WORDLIST_DIR="Wordlists"
FUZZ_WORDLIST="$WORDLIST_DIR/h0tak88r_fuzz.txt"
TARGET="$1"
SINGLE_SUBDOMAIN=""
LOG_FILE="reconraptor.log"

# Parse options
while getopts "s:" opt; do
    case "$opt" in
        s) SINGLE_SUBDOMAIN=$OPTARG ;;
        *) printf "Usage: %s <target_domain> [-s single_subdomain]\n" "$0" >&2; exit 1 ;;
    esac
done

# Function to log messages
log() {
    local message="$1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Function to check and clone repositories if they do not exist
check_and_clone() {
    local dir="$1"
    local repo_url="$2"
    if [[ ! -d "$dir" ]]; then
        log "Error: $dir directory not found."
        log "To clone $dir, run:"
        log "git clone $repo_url"
        exit 1
    fi
}

# Function to check if required tools are installed
check_tools() {
    local tools=("subfinder" "httpx" "waymore" "subov88r" "nuclei" "naabu" "kxss" "qsreplace" "gf" "dalfox" "ffuf" "interlace" "urldedupe")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "Error: $tool is not installed."
            exit 1
        fi
    done
}

# Function to remove and create results directory
setup_results_dir() {
    if [[ -d "$RESULTS_DIR" ]]; then
        rm -rf "$RESULTS_DIR"
    fi
    mkdir -p "$RESULTS_DIR"
}

# Function to run subdomain enumeration
run_subfinder() {
    log "[+] Subdomain Enumeration using SubFinder"
    if ! subfinder -d "$TARGET" --all -silent -o "$RESULTS_DIR/subs.txt"; then
        log "SubFinder failed."
        return 1
    fi
}

# Function to fetch URLs
fetch_urls() {
    log "[+] Fetching URLs"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        waymore -i "$SINGLE_SUBDOMAIN" -oU "$RESULTS_DIR/urls.txt" -mode U
    else
        waymore -i "$TARGET" -oU "$RESULTS_DIR/urls.txt" -mode U
    fi
}

# Function to run subdomain takeover scanning
subdomain_takeover_scan() {
    log "[+] Subdomain Takeover Scanning"
    subov88r -f "$RESULTS_DIR/subs.txt" | grep -E 'cloudapp.net|azurewebsites.net|cloudapp.azure.com' > "$RESULTS_DIR/azureSDT.txt"
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei-templates/http/takeovers/
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei_templates/takeover/detect-all-takeover.yaml
}

# Function to scan for JS exposures
scan_js_exposures() {
    log "[+] JS Exposures"
    grep ".js" "$RESULTS_DIR/urls.txt" | nuclei -l - -t nuclei_templates/js/ | tee "$RESULTS_DIR/js-exposures.txt"
}

# Function to filter live hosts
filter_live_hosts() {
    log "[+] Filtering Live hosts"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | httpx --silent | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    else
        cat "$RESULTS_DIR/subs.txt" | httpx --silent | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    fi
}

# Function to run port scanning
run_port_scan() {
    log "[+] Port Scanning"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        naabu -host $SINGLE_SUBDOMAIN -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    else
        naabu -list "$RESULTS_DIR/subs.txt" -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    fi
}

# Function to scan for exposed panels
scan_exposed_panels() {
    log "[+] Exposed Panels Scanning"
    cat "$RESULTS_DIR/live.txt" | nuclei -t nuclei_templates/panels | tee "$RESULTS_DIR/exposed-panels.txt"
}

# Function to run nuclei scans
run_nuclei_scans() {
    log "[+] Nuclei Scanning"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        nuclei -u "https://$SINGLE_SUBDOMAIN" -t nuclei_templates/Others -o "$RESULTS_DIR/nuclei_templates-results.txt"
        nuclei -u "https://$SINGLE_SUBDOMAIN" -t nuclei-templates/http -o "$RESULTS_DIR/nuclei-templates-results.txt"
    else
        nuclei -l "$RESULTS_DIR/live.txt" -t nuclei_templates/Others -o "$RESULTS_DIR/nuclei_templates-results.txt"
        nuclei -l "$RESULTS_DIR/live.txt" -t nuclei-templates/http -o "$RESULTS_DIR/nuclei-templates-results.txt"
    fi
}

# Function to run reflection scanning
run_reflection_scan() {
    log "[+] Reflection Scanning"
    cat "$RESULTS_DIR/urls.txt" | kxss | tee "$RESULTS_DIR/kxss-results.txt"
}

# Function to run GF pattern scans
run_gf_scans() {
    log "[+] GF Patterns"
    local gf_patterns=("xss" "ssrf" "ssti" "redirect" "lfi" "sqli")
    for pattern in "${gf_patterns[@]}"; do
        cat "$RESULTS_DIR/urls.txt" | urldedupe | gf "$pattern" | qsreplace FUZZ > "$RESULTS_DIR/gf-$pattern.txt"
    done
}

# Function to run Dalfox scans
run_dalfox_scan() {
    log "[+] Dalfox Scanning"
    if ! dalfox file "$RESULTS_DIR/kxss-results.txt" --no-spinner --only-poc r --ignore-return 302,404,403 --skip-bav -b "XSS Server here" -w 50 -o "$RESULTS_DIR/dalfox-results.txt"; then
        log "Dalfox scanning failed."
        return 1
    fi
}

# Function to run fuzzing with ffuf
run_ffuf() {
    log "[+] Fuzzing with ffuf"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        ffuf -u "https://$SINGLE_SUBDOMAIN/FUZZ" -w "$FUZZ_WORDLIST" | tee "$RESULTS_DIR/ffufGet.txt"
        ffuf -u "https://$SINGLE_SUBDOMAIN/FUZZ" -w "$FUZZ_WORDLIST" -X POST | tee "$RESULTS_DIR/ffufPost.txt"
    else
        while IFS= read -r url; do
            ffuf -u "$url/FUZZ" -w "$FUZZ_WORDLIST" | tee "$RESULTS_DIR/ffufGet.txt"
            ffuf -u "$url/FUZZ" -w "$FUZZ_WORDLIST" -X POST | tee "$RESULTS_DIR/ffufPost.txt"
        done < "$RESULTS_DIR/live.txt"
    fi
}

# Function to make ffuf results unique
make_ffuf_results_unique() {
    log "[+] Making ffuf results unique"
    declare -A seen_sizes
    for file in "$RESULTS_DIR/ffufGet.txt" "$RESULTS_DIR/ffufPost.txt"; do
        while IFS= read -r line; do
            size=$(echo "$line" | grep -oP 'Words: \K\d+')
            if [[ -n "$size" && -z "${seen_sizes[$size]}" ]]; then
                echo "$line" >> "${file%.txt}-unique.txt"
                seen_sizes[$size]=1
            fi
        done < "$file"
    done
}

# Function to run SQL injection scanning with sqlmap
run_sql_injection_scan() {
    log "[+] SQL Injection Scanning with sqlmap"
    interlace -tL "$RESULTS_DIR/gf-sqli.txt" -threads 5 -c "sqlmap -u _target_ --batch --dbs --random-agent >> '$RESULTS_DIR/sqlmap-sqli.txt'"
}

# Main function
main() {
    check_and_clone "nuclei_templates" "https://github.com/h0tak88r/nuclei_templates.git"
    check_and_clone "nuclei-templates" "https://github.com/projectdiscovery/nuclei-templates.git"
    check_and_clone "$WORDLIST_DIR" "https://github.com/h0tak88r/Wordlists.git"

    if [[ ! -d "$HOME/.gf" ]]; then
        log "Error: Patterns (~/.gf) directory not found."
        log "To clone Patterns, run:"
        log "git clone https://github.com/1ndianl33t/Gf-Patterns"
        log "mkdir -p ~/.gf"
        log "cp Gf-Patterns/*.json ~/.gf"
        log "echo 'source \$GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc"
        log "source ~/.bashrc"
        exit 1
    fi

    check_tools
    setup_results_dir

    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        log "[+] Working with single subdomain: $SINGLE_SUBDOMAIN"
        fetch_urls
        scan_js_exposures
        filter_live_hosts
        run_port_scan
        scan_exposed_panels
        run_nuclei_scans
        run_reflection_scan
        run_gf_scans
        run_dalfox_scan
        run_ffuf
        make_ffuf_results_unique
        run_sql_injection_scan
    else
        log "[+] Working with domain: $TARGET"
        run_subfinder
        fetch_urls
        subdomain_takeover_scan
        scan_js_exposures
        filter_live_hosts
        run_port_scan
        scan_exposed_panels
        run_nuclei_scans
        run_reflection_scan
        run_gf_scans
        run_dalfox_scan
        run_ffuf
        make_ffuf_results_unique
        run_sql_injection_scan
    fi

    log "[+] Done"
}

main
