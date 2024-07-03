# ReconRaptor

ReconRaptor is an automated reconnaissance tool designed for security assessments. It performs various tasks such as subdomain enumeration, URL fetching, subdomain takeover scanning, JS exposure scanning, live host filtering, port scanning, exposed panels scanning, nuclei scans, reflection scanning, fuzzing, and SQL injection scanning.

## Features

- Subdomain Enumeration
- URL Fetching
- Subdomain Takeover Scanning
- JS Exposures Scanning
- Live Hosts Filtering
- Port Scanning
- Exposed Panels Scanning
- Nuclei Scanning
- Reflection Scanning
- GF Patterns Scanning
- Dalfox Scanning
- Fuzzing with ffuf
- SQL Injection Scanning with sqlmap

## Prerequisites

Make sure you have the following tools installed:

- subfinder
- httpx
- waymore
- subov88r
- nuclei
- naabu
- kxss
- qsreplace
- gf
- dalfox
- ffuf
- interlace
- urldedupe

## Installation

Clone the required repositories:

```bash
git clone https://github.com/h0tak88r/nuclei_templates.git
git clone https://github.com/projectdiscovery/nuclei-templates.git
git clone https://github.com/h0tak88r/Wordlists.git
```

If you don't have GF Patterns installed, follow these steps:

```bash
git clone https://github.com/1ndianl33t/Gf-Patterns
mkdir -p ~/.gf
cp Gf-Patterns/*.json ~/.gf
echo 'source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc
source ~/.bashrc
```

## Usage

To run ReconRaptor, use the following command:

```bash
./reconraptor.sh <target_domain> [-s single_subdomain]
```

- `<target_domain>`: The target domain for reconnaissance.
- `-s single_subdomain`: (Optional) Specify a single subdomain to work with.

## Functions Overview

- `log`: Logs messages to both the console and a log file.
- `check_and_clone`: Checks and clones repositories if they do not exist.
- `check_tools`: Checks if required tools are installed.
- `setup_results_dir`: Sets up the results directory.
- `run_subfinder`: Runs subdomain enumeration.
- `fetch_urls`: Fetches URLs using waymore.
- `subdomain_takeover_scan`: Scans for subdomain takeover vulnerabilities.
- `scan_js_exposures`: Scans for JS exposures using nuclei.
- `filter_live_hosts`: Filters live hosts using httpx.
- `run_port_scan`: Runs port scanning using naabu.
- `scan_exposed_panels`: Scans for exposed panels using nuclei.
- `run_nuclei_scans`: Runs nuclei scans.
- `run_reflection_scan`: Runs reflection scanning using kxss.
- `run_gf_scans`: Runs GF pattern scans.
- `run_dalfox_scan`: Runs Dalfox scans.
- `run_ffuf`: Runs fuzzing with ffuf.
- `make_ffuf_results_unique`: Makes ffuf results unique.
- `run_sql_injection_scan`: Runs SQL injection scanning with sqlmap.

## Logs

Logs are stored in `reconraptor.log`.

## Results

Results are stored in the `results` directory, created in the current working directory.

## License

This project is licensed under the MIT License.
