#!/bin/bash

# Check if TARGET is provided
if [[ -z "$1" ]]; then
    printf "Usage: %s <target_domain|subdomain_list> [-s single_subdomain]\n" "$0" >&2
    exit 1
fi

# Constants
RESULTS_DIR="results"
WORDLIST_DIR="Wordlists"
FUZZ_WORDLIST="$WORDLIST_DIR/h0tak88r_fuzz.txt"
TARGET="$1"
SINGLE_SUBDOMAIN=""
SQLMAP=="python3 /home/aooooom/sallam/sqlmap-dev/sqlmap.py"

# Parse options
while getopts "s:" opt; do
    case "$opt" in
        s) SINGLE_SUBDOMAIN=$OPTARG ;;
        *) printf "Usage: %s <target_domain|subdomain_list> [-s single_subdomain]\n" "$0" >&2; exit 1 ;;
    esac
done

# Function to check and clone repositories if they do not exist
check_and_clone() {
    local dir="$1"
    local repo_url="$2"
    if [[ ! -d "$dir" ]]; then
        printf "Error: %s directory not found.\n" "$dir" >&2
        printf "To clone %s, run:\n" "$dir" >&2
        printf "git clone %s\n" "$repo_url" >&2
        exit 1
    fi
}

# Function to check if required tools are installed
check_tools() {
    local tools=("subfinder" "httpx" "gau" "subov88r" "nuclei" "naabu" "kxss" "qsreplace" "gf" "dalfox" "ffuf" "interlace" "urldedupe")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            printf "Error: %s is not installed.\n" "$tool" >&2
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
    printf "[+] Subdomain Enumeration using SubFinder\n"
    if ! subfinder -d "$TARGET" --all -silent -o "$RESULTS_DIR/subs.txt"; then
        printf "SubFinder failed.\n" >&2
        return 1
    fi
}

# Function to fetch URLs
fetch_urls() {
    printf "[+] Fetching URLs\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | gau | sort -u > "$RESULTS_DIR/urls.txt"
    else
        cat "$RESULTS_DIR/subs.txt" | gau | sort -u > "$RESULTS_DIR/urls.txt"
    fi
}

# Function to run subdomain takeover scanning
subdomain_takeover_scan() {
    printf "[+] Subdomain Takeover Scanning\n"
    subov88r -f "$RESULTS_DIR/subs.txt" | grep -E 'cloudapp.net|azurewebsites.net|cloudapp.azure.com' > "$RESULTS_DIR/azureSDT.txt"
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei-templates/http/takeovers/
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei_templates/takeover/detect-all-takeover.yaml
}

# Function to scan for JS exposures
scan_js_exposures() {
    printf "[+] JS Exposures\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | gau | grep ".js" > "$RESULTS_DIR/JS.txt"
    else
        cat "$RESULTS_DIR/subs.txt" | gau | grep ".js" > "$RESULTS_DIR/JS.txt"
    fi
    nuclei -l "$RESULTS_DIR/JS.txt" -t nuclei_templates/js/ | tee "$RESULTS_DIR/js-exposures.txt"
}

# Function to filter live hosts
filter_live_hosts() {
    printf "[+] Filtering Live hosts\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | httpx --silent | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    else
        cat "$RESULTS_DIR/subs.txt" | httpx --silent | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    fi
}

# Function to run port scanning
run_port_scan() {
    printf "[+] Port Scanning\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        naabu -host $SINGLE_SUBDOMAIN -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    else
        aabu -list "$RESULTS_DIR/subs.txt" -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    fi
}

# Function to scan for exposed panels
scan_exposed_panels() {
    printf "[+] Exposed Panels Scanning\n"
    cat "$RESULTS_DIR/live.txt" | nuclei -t nuclei_templates/panels | tee "$RESULTS_DIR/exposed-panels.txt"
}

# Function to run nuclei scans
run_nuclei_scans() {
    printf "[+] Nuclei Scanning\n"
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
    printf "[+] Reflection Scanning\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | gau | kxss | tee "$RESULTS_DIR/kxss-results.txt"
    else
        cat "$RESULTS_DIR/subs.txt" | gau | kxss | tee "$RESULTS_DIR/kxss-results.txt"
    fi
}

# Function to run GF pattern scans
run_gf_scans() {
    printf "[+] GF Patterns\n"
    local gf_patterns=("xss" "ssrf" "ssti" "redirect" "lfi" "sqli")
    for pattern in "${gf_patterns[@]}"; do
        if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
            echo "$SINGLE_SUBDOMAIN" | gau | gf "$pattern" | qsreplace FUZZ > "$RESULTS_DIR/gf-$pattern.txt"
        else
            cat "$RESULTS_DIR/urls.txt" | gf "$pattern" | qsreplace FUZZ > "$RESULTS_DIR/gf-$pattern.txt"
        fi
    done
}

# Function to run Dalfox scans
run_dalfox_scan() {
    printf "[+] Dalfox Scanning\n"
    if ! dalfox file "$RESULTS_DIR/kxss-results.txt" --no-spinner --only-poc r --ignore-return 302,404,403 --skip-bav -b "XSS Server here" -w 50 -o "$RESULTS_DIR/dalfox-results.txt"; then
        printf "Dalfox scanning failed.\n" >&2
        return 1
    fi
}

# Function to run fuzzing with ffuf
run_ffuf() {
    printf "[+] Fuzzing with ffuf\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        ffuf -u "https://$SINGLE_SUBDOMAIN/FUZZ" -w "$FUZZ_WORDLIST"| tee "$RESULTS_DIR/ffufGet.txt"
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
    printf "[+] Making ffuf results unique\n"
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
    printf "[+] SQL Injection Scanning with sqlmap\n"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        echo "$SINGLE_SUBDOMAIN" | gau | urldedupe | gf sqli > "$RESULTS_DIR/sql.txt"
    else
        if ! cat "$RESULTS_DIR/subs.txt" | gau | urldedupe | gf sqli > "$RESULTS_DIR/sql.txt"; then
            printf "Failed to prepare SQL injection scan input.\n" >&2
            return 1
        fi
    fi

    if ! $SQLMAP -m "$RESULTS_DIR/sql.txt" --batch --dbs --risk 2 --level 5 --random-agent | tee -a "$RESULTS_DIR/sqli.txt"; then
        printf "SQL injection scanning failed.\n" >&2
        return 1
    fi
}

# Main function
main() {
    check_and_clone "nuclei_templates" "https://github.com/h0tak88r/nuclei_templates.git"
    check_and_clone "nuclei-templates" "https://github.com/projectdiscovery/nuclei-templates.git"
    check_and_clone "$WORDLIST_DIR" "https://github.com/h0tak88r/Wordlists.git"

    if [[ ! -d "$HOME/.gf" ]]; then
        printf "Error: Patterns (~/.gf) directory not found.\n" >&2
        printf "To clone Patterns, run:\n" >&2
        printf "git clone https://github.com/1ndianl33t/Gf-Patterns\n" >&2
        printf "mkdir -p ~/.gf\n" >&2
        printf "cp Gf-Patterns/*.json ~/.gf\n" >&2
        printf "echo 'source \$GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc\n" >&2
        printf "source ~/.bashrc\n" >&2
        exit 1
    fi

    check_tools
    setup_results_dir

    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        printf "[+] Working with single subdomain: %s\n" "$SINGLE_SUBDOMAIN"
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
        printf "[+] Working with domain or list of subdomains: %s\n" "$TARGET"
        if [[ -f "$TARGET" ]]; then
            cp "$TARGET" "$RESULTS_DIR/subs.txt"
        else
            run_subfinder
        fi
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

    printf "[+] Done\n"
}

main
