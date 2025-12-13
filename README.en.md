# VPS Speed Tester

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](https://github.com/anrulev/vps-speed-test)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Maintenance](https://img.shields.io/badge/maintained-yes-brightgreen)](https://github.com/anrulev/vps-speed-test/commits/main)

**Languages:** [🇷🇺 Русский](README.md) | **🇬🇧 English**

A tool for testing speed and connection quality to VPS servers.

## Project Structure

```
test_vps/
├── test_vps_speed.sh    # Main testing script
├── view_reports.sh      # Script for viewing and managing reports
├── servers.conf         # Server configuration
├── reports/             # Directory for test reports
│   ├── report_2025-12-13_17-30-45.txt
│   └── report_2025-12-13_18-15-22.txt
└── README.md           # Documentation
```

## Installation

1. Ensure you have the necessary utilities installed:
   - `curl` - for geolocation
   - `ping` - for latency testing
   - `traceroute` - for route determination
   - `bc` - for mathematical calculations

2. (Optional) Install `jq` for improved JSON parsing:
   ```bash
   brew install jq  # macOS
   apt install jq   # Ubuntu/Debian
   ```

## Configuration

Edit the `servers.conf` file to add/remove servers:

```
# Format: Server Name|IP Address
New York|192.3.81.8
Chicago, IL|198.23.228.15
My Custom Server|203.0.113.42
```

**Rules:**
- Lines starting with `#` are ignored (comments)
- Empty lines are ignored
- Format: `Name|IP` (pipe separator)
- IP address must be a valid IPv4 address

## Usage

Run the script from any directory:

```bash
cd ~/test_vps
./test_vps_speed.sh
```

or with full path:

```bash
~/test_vps/test_vps_speed.sh
```

## Testing Parameters

The script checks the following parameters for each server:

1. **Ping** - response latency (min/avg/max/stddev)
2. **Packet Loss** - percentage of lost packets
3. **Jitter** - connection stability (latency variation)
4. **Hops** - number of intermediate nodes (traceroute)
5. **TCP Connection Time** - TCP connection establishment speed

## Scoring Formula

```
Total Score = Ping + (Packet Loss × 10) + (Jitter × 2)
```

Lower score = better connection quality.

## Results Interpretation

### Connection Quality:
- ★★★ **Excellent**: ping < 50ms and packet loss < 1%
- ★★☆ **Good**: ping < 100ms and packet loss < 2%
- ★☆☆ **Satisfactory**: other cases

### Medals:
- 🥇 - Best server
- 🥈 - Second place
- 🥉 - Third place

## Example Output

```
========================================
  VPS Speed Test
========================================

Getting your location information...
Your IP: 198.45.195.56
Your location: Moscow, Moscow, RU

Loaded servers: 9

[Testing each server...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                FINAL RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#   Location       IP            Ping(ms) Loss% Jitter Hops TCP(ms) Score
---------------------------------------------------------------------------
🥇 Amsterdam       23.94.101.88    60.96   0.0   3.52   11  64.72   68.00
🥈 Dublin          23.95.225.2     79.58   0.0   7.93   11  82.14   95.44
🥉 Chicago         198.23.228.15  143.86   0.0   3.25   11 156.62  150.36

🏆 RECOMMENDATION: Amsterdam
   Average ping: 60.96 ms | Packet loss: 0.0% | Total score: 68.00
```

## Execution Time

Testing takes approximately **30-60 seconds per server** depending on:
- Number of servers in configuration
- Your internet connection speed
- Server availability

For 9 servers: ~5-10 minutes

## Report Storage

Each test run is **automatically saved** to a separate file with date and time:

```
reports/report_2025-12-13_17-30-45.txt
```

**File name format:** `report_YYYY-MM-DD_HH-MM-SS.txt`

**Report contents:**
- Test date and time
- System information
- Your location and IP
- Detailed results for each server
- Summary table with rankings
- Best server recommendation

**Viewing reports:**

Use the interactive script for report management:
```bash
cd ~/test_vps
./view_reports.sh
```

Features:
- View list of all reports
- View latest report
- Select and view specific report
- Delete old reports (>30 days)
- Delete all reports

Or manually via command line:
```bash
# View latest report
cat ~/test_vps/reports/report_*.txt | tail -100

# List all reports
ls -lht ~/test_vps/reports/

# View specific report
cat ~/test_vps/reports/report_2025-12-13_17-30-45.txt
```

**Comparing reports:**
You can compare reports from different times to track connection quality changes throughout the day/week.

## Troubleshooting

### Script can't find servers.conf

Ensure the `servers.conf` file is in the same directory as the script.

### Traceroute doesn't work

On macOS, traceroute may require sudo. The script will continue with "unavailable" mark for hops.

### Location not detected

Check your internet connection. The script uses ipinfo.io API for geolocation.

## License

Free to use.
