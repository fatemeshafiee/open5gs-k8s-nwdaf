#!/bin/bash
ip route add 12.1.1.0/24 via 192.168.73.201 dev eth0
exec python server.py
