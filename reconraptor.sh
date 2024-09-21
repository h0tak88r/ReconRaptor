#!/bin/bash

# ReconRaptor Logo
printf "==============================\n"
printf "  
┳┓       ┳┓         
┣┫┏┓┏┏┓┏┓┣┫┏┓┏┓╋┏┓┏┓
┛┗┗ ┗┗┛┛┗┛┗┗┻┣┛┗┗┛┛ 
             ┛      
==============================\n"

# Constants
RESULTS_DIR="results"
WORDLIST_DIR="Wordlists"
FUZZ_WORDLIST="$WORDLIST_DIR/h0tak88r_fuzz.txt"
TARGET="$1"
SINGLE_SUBDOMAIN=""
LOG_FILE="reconraptor.log"
DISCORD_WEBHOOK="" # Here add your Discord Webhook

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
    printf "%s\n" "$message"
    printf "%s\n" "$message" >> "$LOG_FILE"
    send_to_discord "$message"
}

# Function to send messages to Discord
send_to_discord() {
    local content="$1"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$content\"}" \
         "$DISCORD_WEBHOOK" > /dev/null 2>&1
}

# Function to send files to Discord
send_file_to_discord() {
    local file="$1"
    local description="$2"
    if [[ -f "$file" ]]; then
        curl -F "file=@$file" \
             -F "payload_json={\"content\": \"$description\"}" \
             "$DISCORD_WEBHOOK" > /dev/null 2>&1
    else
        log "Error: File $file does not exist."
    fi
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

# Function to check enabled PUT Method
put_scan() {
    log "[+] Checking for PUT method"
    while IFS= read -r host; do
        curl -s -o /dev/null -w "URL: %{url_effective} - Response: %{response_code}\n" -X PUT -d "hello world" "${host}/evil.txt" | tee -a "$RESULTS_DIR/put-scan.txt"
    done < "$RESULTS_DIR/live.txt"
    send_file_to_discord "$RESULTS_DIR/put-scan.txt" "PUT Scan results"
}

# Function to run subdomain enumeration
subEnum() {
    log "[+] Subdomain Enumeration using SubFinder and free API Sources"
    #--------------------------------------------------------------------------------------------------------------------
    curl --silent "https://api.hackertarget.com/hostsearch/?q=$1" | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl --silent "https://crt.sh/?q=%.$1" | grep -oP "\<TD\>\K.*\.$1" | sed -e 's/\<BR\>/\n/g' | grep -oP "\K.*\.$1" | sed -e 's/[\<|\>]//g' | grep -o -E "[a-zA-Z0-9._-]+\.$1"  >> tmp.txt
    curl --silent "https://crt.sh/?q=%.%.$1" | grep -oP "\<TD\>\K.*\.$1" | sed -e 's/\<BR\>/\n/g' | sed -e 's/[\<|\>]//g' | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl --silent "https://crt.sh/?q=%.%.%.$1" | grep "$1" | cut -d '>' -f2 | cut -d '<' -f1 | grep -v " " | grep -o -E "[a-zA-Z0-9._-]+\.$1" | sort -u >> tmp.txt
    curl --silent "https://crt.sh/?q=%.%.%.%.$1" | grep "$1" | cut -d '>' -f2 | cut -d '<' -f1 | grep -v " " | grep -o -E "[a-zA-Z0-9._-]+\.$1" |  sort -u >> tmp.txt
    curl --silent "https://spyse.2com/target/domain/$1" | grep -E -o "button.*>.*\.$1\/button>" |  grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl 'https://tls.bufferover.run/dns?q=.google.com' -H 'x-api-key: lx6FXQo1sd54gAIBWnwlWa8WR4rgzCyR87LBlV6l' -X POST | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl --silent "https://urlscan.io/api/v1/search/?q=$1" | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl --silent -X POST "https://synapsint.com/report.php" -d "name=http%3A%2F%2F$1" | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    curl --silent "https://jldc.me/anubis/subdomains/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" >> tmp.txt
    curl --silent "https://otx.alienvault.com/api/v1/indicators/domain/$1/passive_dns" | grep -o -E "[a-zA-Z0-9._-]+\.$1" >> tmp.txt
    #--------------------------------------------------------------------------------------------------------------------
    sed -e "s/\*\.$1//g" -e "s/^\..*//g" tmp.txt | grep -o -E "[a-zA-Z0-9._-]+\.$1" | sort -u > "$RESULTS_DIR/apis-subs.txt"
    rm tmp.txt 
    subfinder -d "$TARGET" --all -silent -o "$RESULTS_DIR/subfinder-subs.txt"
    sort -u "$RESULTS_DIR/subfinder-subs.txt" "$RESULTS_DIR/apis-subs.txt" | grep -v "*" | sort -u > "$RESULTS_DIR/subs.txt"
    log "Subdomain Enumeration completed. Results saved in $RESULTS_DIR/subs.txt"
    send_file_to_discord "$RESULTS_DIR/subs.txt" "Subdomain Enumeration completed"
}

# Function to fetch URLs
fetch_urls() {
    log "[+] Fetching URLs"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        waymore -i "$SINGLE_SUBDOMAIN" -oU "$RESULTS_DIR/urls.txt" -mode U
    else
        waymore -i "$TARGET" -oU "$RESULTS_DIR/urls.txt" -mode U
    fi
    send_file_to_discord "$RESULTS_DIR/urls.txt" "Fetched URLs"
}

# Function to run subdomain takeover scanning
subdomain_takeover_scan() {
    log "[+] Subdomain Takeover Scanning"
    subov88r -f "$RESULTS_DIR/subs.txt" | grep -E 'cloudapp.net|azurewebsites.net|cloudapp.azure.com' > "$RESULTS_DIR/azureSDT.txt"
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei-templates/http/takeovers/
    nuclei -l "$RESULTS_DIR/subs.txt" -t nuclei_templates/takeover/detect-all-takeover.yaml
    send_file_to_discord "$RESULTS_DIR/azureSDT.txt" "Subdomain Takeover Scan Results"
}

# Function to scan for JS exposures
scan_js_exposures() {
    log "[+] JS Exposures"
    grep ".js" "$RESULTS_DIR/urls.txt" | nuclei -l - -t nuclei_templates/js/ | tee "$RESULTS_DIR/js-exposures.txt"
    send_file_to_discord "$RESULTS_DIR/js-exposures.txt" "JS Exposures Scan Results"
}

# Function to filter live hosts
filter_live_hosts() {
    log "[+] Filtering Live hosts"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        printf "%s\n" "$SINGLE_SUBDOMAIN" | httpx --silent | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    else
        httpx --silent -l "$RESULTS_DIR/subs.txt" | awk '{print $1}' > "$RESULTS_DIR/live.txt"
    fi
    send_file_to_discord "$RESULTS_DIR/live.txt" "Live Hosts Results"
}

# Function to run port scanning
run_port_scan() {
    log "[+] Port Scanning"
    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        naabu -host "$SINGLE_SUBDOMAIN" -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    else
        naabu -list "$RESULTS_DIR/subs.txt" -top-ports 1000 -o "$RESULTS_DIR/naabu-results.txt"
    fi
    send_file_to_discord "$RESULTS_DIR/naabu-results.txt" "Port Scan Results"
}

# Function to scan for exposed panels
scan_exposed_panels() {
    log "[+] Exposed Panels Scanning"
    nuclei -t nuclei_templates/panels -l "$RESULTS_DIR/live.txt" | tee "$RESULTS_DIR/exposed-panels.txt"
    nuclei -t nuclei_templates/panels -l "$RESULTS_DIR/urls.txt" | tee "$RESULTS_DIR/exposed-panels.txt"
    send_file_to_discord "$RESULTS_DIR/exposed-panels.txt" "Exposed Panels Scan Results"
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
    send_file_to_discord "$RESULTS_DIR/nuclei_templates-results.txt" "Nuclei Scans Results"
}

# Function to run reflection scanning
run_reflection_scan() {
    log "[+] Reflection Scanning"
    kxss < "$RESULTS_DIR/urls.txt" | tee "$RESULTS_DIR/kxss-results.txt"
    send_file_to_discord "$RESULTS_DIR/kxss-results.txt" "Reflection Scan Results"
}

# Function to run GF pattern scans
run_gf_scans() {
    log "[+] GF Patterns"
    local gf_patterns=("xss" "ssrf" "ssti" "redirect" "lfi" "sqli")
    for pattern in "${gf_patterns[@]}"; do
        urldedupe < "$RESULTS_DIR/urls.txt" | gf "$pattern" | qsreplace FUZZ > "$RESULTS_DIR/gf-$pattern.txt"
        send_file_to_discord "$RESULTS_DIR/gf-$pattern.txt" "GF $pattern Scan Results"
    done
}

# Function to run Dalfox scans
run_dalfox_scan() {
    log "[+] Dalfox Scanning"
    dalfox file "$RESULTS_DIR/gf-xss.txt" --no-spinner --only-poc r --ignore-return 302,404,403 --skip-bav -b "XSS Server here" -w 50 -o "$RESULTS_DIR/dalfox-results.txt"
    send_file_to_discord "$RESULTS_DIR/dalfox-results.txt" "Dalfox XSS Scan Results"
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
    send_file_to_discord "$RESULTS_DIR/ffufGet.txt" "ffuf GET Fuzz Results"
    send_file_to_discord "$RESULTS_DIR/ffufPost.txt" "ffuf POST Fuzz Results"
}

# Function to make ffuf results unique
make_ffuf_results_unique() {
    log "[+] Making ffuf results unique"
    declare -A seen_sizes
    for file in "$RESULTS_DIR/ffufGet.txt" "$RESULTS_DIR/ffufPost.txt"; do
        while IFS= read -r line; do
            size=$(printf "%s\n" "$line" | grep -oP 'Words: \K\d+')
            if [[ -n "$size" && -z "${seen_sizes[$size]}" ]]; then
                printf "%s\n" "$line" >> "${file%.txt}-unique.txt"
                seen_sizes[$size]=1
            fi
        done < "$file"
        send_file_to_discord "${file%.txt}-unique.txt" "Unique ffuf results"
    done
}

# Function to run SQL injection scanning with sqlmap
run_sql_injection_scan() {
    log "[+] SQL Injection Scanning with sqlmap"
    interlace -tL "$RESULTS_DIR/gf-sqli.txt" -threads 5 -c "sqlmap -u _target_ --batch --dbs --random-agent >> '$RESULTS_DIR/sqlmap-sqli.txt'"
    send_file_to_discord "$RESULTS_DIR/sqlmap-sqli.txt" "SQL Injection Scan Results"
}

# Main function
main() {
    check_and_clone "nuclei_templates" "https://github.com/h0tak88r/nuclei_templates.git"
    check_and_clone "nuclei-templates" "https://github.com/projectdiscovery/nuclei-templates.git"
    check_and_clone "$WORDLIST_DIR" "https://github.com/h0tak88r/Wordlists.git"

    if [[ ! -d "$HOME/.gf" ]]; then
        log "Error: Patterns (~/.gf) directory not found."
        exit 1
    fi

    check_tools
    setup_results_dir

    if [[ -n "$SINGLE_SUBDOMAIN" ]]; then
        log "[+] Working with single subdomain: $SINGLE_SUBDOMAIN"
        fetch_urls
        scan_js_exposures
        filter_live_hosts
        put_scan
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
        subEnum
        fetch_urls
        subdomain_takeover_scan
        scan_js_exposures
        filter_live_hosts
        put_scan
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
