# ReconRaptor

ReconRaptor is a comprehensive reconnaissance tool designed to perform extensive scanning and enumeration of domains and subdomains. It integrates various open-source tools and APIs to provide detailed information about the target.

## Features

- Subdomain enumeration using multiple APIs and SubFinder
- URL fetching using Waymore
- Subdomain takeover detection
- JavaScript exposure scanning
- Live host filtering
- Port scanning using Naabu
- Exposed panel detection
- Reflection scanning
- GF pattern-based scanning
- XSS scanning using Dalfox
- Fuzzing with ffuf
- SQL injection scanning with sqlmap

## Installation

### Prerequisites

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

Or You can Install them using :

```sh
chmod +x Install_tools.sh
./Install_tools
```

Make sure if the tools installed correctly by :

```sh
chmod +x checkTools
./checkTools
```

if any of those tools didn't install correctly try installing it manually install them

### Clone the repository

```sh
git clone https://github.com/h0tak88r/ReconRaptor.git
cd ReconRaptor
```

### Download required repositories

```sh
git clone https://github.com/h0tak88r/nuclei_templates.git
git clone https://github.com/projectdiscovery/nuclei-templates.git
git clone https://github.com/h0tak88r/Wordlists.git
git clone https://github.com/1ndianl33t/Gf-Patterns
mkdir -p ~/.gf
cp Gf-Patterns/*.json ~/.gf
echo 'source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc
source ~/.bashrc
```

## Usage

```sh
./reconraptor.sh <target_domain> [-s single_subdomain]
```

### Options

- `<target_domain>`: The main domain to be scanned.
- `-s single_subdomain`: (Optional) Specify a single subdomain to scan.

### Examples

- Scan a domain:

  ```sh
  ./reconraptor.sh example.com
  ```

- Scan a single subdomain:
  ```sh
  ./reconraptor.sh example.com -s sub.example.com
  ```

## Output

Results are saved in the `results` directory, which is recreated for each run.

## Logging

All log messages are saved to `reconraptor.log`.

## Modules

### Subdomain Enumeration

Uses multiple APIs and SubFinder to find subdomains.

### URL Fetching

Fetches URLs using Waymore.

### Subdomain Takeover Detection

Detects potential subdomain takeovers.

### JavaScript Exposure Scanning

Scans for exposed JavaScript files.

### Live Host Filtering

Filters live hosts using httpx.

### Port Scanning

Scans top 1000 ports using Naabu.

### Exposed Panel Detection

Detects exposed panels using nuclei templates.

### Reflection Scanning

Scans for reflection vulnerabilities using kxss.

### GF Pattern Scanning

Uses GF patterns to detect vulnerabilities such as XSS, SSRF, SSTI, and more.

### XSS Scanning

Scans for XSS vulnerabilities using Dalfox.

### Fuzzing

Performs fuzzing using ffuf.

### SQL Injection Scanning

Scans for SQL injection vulnerabilities using sqlmap.

## License

This project is licensed under the MIT License.

## Contributions

Contributions are welcome! Please fork the repository and create a pull request.
