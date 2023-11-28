#!/usr/bin/python3

import sys
from scapy.all import *
import time
from scapy.all import sendp , ARP , Ether
import scapy.all as scapy
from scapy.data import ETH_P_ALL

EthBroadcastAddress= "ff:ff:ff:ff:ff:ff"
ArpRequestCode= 1
ArpResonseCode= 2

def getMac( _interfaceName, _protocolDst):
  broadcastFrame= scapy.Ether( dst= EthBroadcastAddress)
  arpRequest= scapy.ARP( pdst= _protocolDst)
  arpFrame= broadcastFrame/ arpRequest
  answerList= scapy.srp( arpFrame, iface= _interfaceName, timeout= 5, verbose= False)[0]
  return answerList[ 0][ 1].hwsrc

def forwardFrame( _interfaceName, _dstMacAddress, _payloadType, _payload):
  frame= scapy.Ether( dst= _dstMacAddress, type= _payloadType)
  fullFrame= frame/ _payload
  answerList= scapy.srp( fullFrame, iface= _interfaceName, timeout= 5, verbose= False)[0]

  print( "\n\nsent frame:")
  print( fullFrame.summary)

  return answerList[ 0][ 1].hwsrc

def FrameHandler( _interfaceName, _interfaceMac, _sideAIp, _sideAMac, _sideBIp, _sideBMac):
    def frameHandler( _frame):
        if _frame.type!= 0x806 and _frame.dst== _interfaceMac:
            try:
                print( "\n\nreceived frame:")
                print( _frame.summary)

                ipPacket= _frame.payload
                ipDst= ipPacket.getfieldval( "dst")
                print( ipDst)

                if ipDst== _sideAIp:
                    _frame.dst= _sideAMac
                    #scapy.sendp( _frame, iface= _interfaceName, verbose= False )
                    forwardFrame( _interfaceName, _sideAMac, _frame.type, ipPacket )

                elif ipDst== _sideBIp:
                    _frame.dst= _sideBMac
                    forwardFrame( _interfaceName, _sideBMac, _frame.type, ipPacket )
                    #scapy.sendp( _frame, iface= _interfaceName, verbose= False )

#                print( "\n\nsent frame:")
#                print( _frame.summary)

            except Exception as e:
                print( e)

    print( _interfaceMac)
    sniff( iface= _interfaceName, prn= frameHandler, count= 100)  

if len( sys.argv)< 4:
  print( sys.argv[0 ]+ ": <interface name> <side A IP address> <side B IP address>")
  sys.exit( 1)

interfaceName= sys.argv[ 1]
sideAIp= sys.argv[ 2]
sideBIp= sys.argv[ 3]

interfaceMac= get_if_hwaddr( interfaceName)
sideAMac= getMac( interfaceName, sideAIp)
sideBMac= getMac( interfaceName, sideBIp)
FrameHandler( interfaceName, interfaceMac, sideAIp, sideAMac, sideBIp, sideBMac)
