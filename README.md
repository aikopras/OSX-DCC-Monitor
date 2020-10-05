# OSX-DCC-Monitor
DCC and RS-Bus Monitor software for MAC OSX
This program is part of a DCC monitoring solution. The description of the hardware can be found on [EasyEda](https://easyeda.com/aikopras/dcc-monitor); a description of the entire system can be found on my [Google Sites pages](https://sites.google.com/site/dcctrains/dcc-rs-bus-monitor).
The program is written for MAC OSX; the executable can be [dowloaded directly](/Compiled%20Application/dccmon.dmg) or can be compiled from scratch using Xcode.<BR>

## Main screen ## 
After startup the following screen is shown.
![Main](/Screenshots/dccmon.png)


## Operation ##
The program creates two TCP connections; one to receive DCC (loco and switch) messages, and one to receive RS-Bus messages. By integrating data from both TCP connections, a relation between DCC commands and RS-bus feedback information can be made, which eases the detection of faulty components. The software decodes (nearly) all DCC packets and can optionaly save and re-open trace files for later analysis.

DCC messages should be obtained from a DCC monitoring as described on [EasyEda](https://easyeda.com/aikopras/dcc-monitor). RS-bus feedback signals can best be obtained via Lenz's own LAN/USB Interface (serial number: 23151). 
Alternatively DCC signals can be obtained using:
- the [old "single-input" monitoring boards by Peter Lebbing](https://digitalbrains.com/2012/dccmon), connected to a serial-to-Ethernet converter, or better 
- an ESP32 based system (which needs to be eveloped, however).
