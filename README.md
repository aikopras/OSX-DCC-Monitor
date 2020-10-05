# OSX-DCC-Monitor

DCC and RS-Bus Monitor software for MAC OSX

This program is part of a DCC monitoring solution. The description of the hardware can be found on https://easyeda.com/aikopras/dcc-monitor; a description of the entire system can be found on https://sites.google.com/site/dcctrains/dcc-rs-bus-monitor.

The program creates two TCP connections; one to receive DCC (loco and switch) messages, and one to receive RS-Bus messages. By integrating data from both TCP connections, a relation between DCC commands and RS-bus feedback information can be made, which eases the detection of faulty components. The software decodes (nearly) all DCC packets and can optionaly save and re-open trace files for later analysis.

DCC messages should be obtained from a DCC monitoring as described on EasyEda. RS-bus feedback signals can best be obtained via Lenz's own LAN/USB Interface (serial number: 23151). Although it expects input via the Ethernet interface, the software can still be used together with the old "single-input" monitoring boards, provided a serial-to-Ethernet converter is being used.
