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
- Send Results file and logs to your discord server using discord webhook url you can yours  to web webhook at `DISCORD_WEBHOOK="" # Here Add your webhook`


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

## Setup 
```sh
bash setup.sh
```

## Clone the repository
```sh
git clone https://github.com/h0tak88r/ReconRaptor.git
cd ReconRaptor
```

### Setup GF Patterns
```sh
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

## License
This project is licensed under the MIT License.

## Contributions
Contributions are welcome! Please fork the repository and create a pull request.
