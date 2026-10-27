# OSX-DCC-Monitor
DCC and RS-Bus Monitor software for macOS.
This program is part of a DCC monitoring solution. The description of the hardware can be found on [EasyEda](https://easyeda.com/aikopras/dcc-monitor); a description of the entire system can be found on my [Google Sites pages](https://sites.google.com/site/dcctrains/dcc-rs-bus-monitor).
The executable can be [downloaded directly](/Compiled%20Application/dccmon.zip) or can be compiled from scratch using Xcode (see below).<BR>

## Requirements ##
- macOS 12 (Monterey) or later.
- Universal binary: runs natively on Apple silicon Macs and on Intel Macs.

## Installation ##
1. Download [dccmon.zip](/Compiled%20Application/dccmon.zip), unzip it and move `dccmon.app` to the Applications folder.
2. The application is not notarized by Apple, so macOS blocks it the first time it is opened. To allow it, open System Settings → Privacy & Security (on macOS 12: System Preferences → Security & Privacy → General) and click "Open Anyway".
3. On recent macOS versions the system may ask whether dccmon may access devices on the local network. Allow this; otherwise the TCP connections to the monitor and the Lenz interface fail.

## Main screen ##
After startup the following screen is shown.
![Main](/Screenshots/dccmon.png)

## Preferences ##
![Preferences](/Screenshots/preferences.png)

- IP address and port of the DCC monitor (default: 192.168.24.210, port 5970).
- IP address and port of the Lenz LAN Interface (default: 192.168.24.213, port 5550).
- Default save directory for trace files (default: the Desktop).
- Lenz system (0 = no, 1 = yes): compensates for the non-sequential numbering of accessory (switch) addresses by Lenz (LZV100) command stations.

Press Return after changing a value. New settings are used from the next time START is pressed; there is no need to restart the program.

## Operation ##
The program creates two TCP connections; one to receive DCC (loco and switch) messages, and one to receive RS-Bus messages. By integrating data from both TCP connections, a relation between DCC commands and RS-bus feedback information can be made, which eases the detection of faulty components. The software decodes (nearly) all DCC packets and can optionally save and re-open trace files for later analysis. Trace files are saved in the default save directory, with the date and time as file name (for example `2026-10-27_20_22_05.dcc`).

If the DCC monitor or the Lenz interface does not respond within 3 seconds, the program stops trying and shows this in the status line.

DCC messages should be obtained from a DCC monitor as described on [EasyEda](https://easyeda.com/aikopras/dcc-monitor). RS-bus feedback signals can best be obtained via Lenz's own LAN/USB Interface (serial number: 23151).
Alternatively DCC signals can be obtained using:
- the [old "single-input" monitoring boards by Peter Lebbing](https://digitalbrains.com/2012/dccmon), connected to a serial-to-Ethernet converter, or better
- an ESP32 based system (which needs to be developed, however).

## Building from source ##
Open `Dccmon.xcodeproj` in Xcode 26 or later. The Release configuration (for example via Product → Build For → Profiling, or Product → Archive) produces a universal binary for Apple silicon and Intel.

## Version history ##
**2.2** (October 2026)
- Updated to Xcode 26; universal binary (Apple silicon and Intel); requires macOS 12 or later.
- Connection time-out of 3 seconds if the DCC monitor or the Lenz interface does not respond.
- Improved preference handling: the default save directory is the Desktop, and a message is shown if a trace file cannot be written.

**2.1** (2020)
- Last version for Intel Macs only.
