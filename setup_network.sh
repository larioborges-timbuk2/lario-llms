#!/usr/bin/env bash

# Exit on error
set -e

# Static IP parameters
WIRED_IP="192.168.10.222/24"
WIFI_IP="192.168.10.223/24"
GATEWAY="192.168.10.1"
UPSTREAM_DNS="1.1.1.1,8.8.8.8"

echo "=================================================================="
echo "  Local Network Static IP & DNS Resolver Setup Script"
echo "  Target Hostname/Domain: strixly.nuclear.cooking"
echo "=================================================================="

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo privileges."
  echo "Usage: sudo ./setup_network.sh"
  exit 1
fi

# Detect active connections
echo "[-] Detecting active NetworkManager connection profiles..."
WIRED_CONN=$(nmcli -t -f NAME,TYPE connection show --active | grep ethernet | head -n1 | cut -d: -f1)
WIFI_CONN=$(nmcli -t -f NAME,TYPE connection show --active | grep wireless | head -n1 | cut -d: -f1)

WIRED_CONFIGURED=false
WIFI_CONFIGURED=false

# Configure Wired Ethernet
if [ -n "$WIRED_CONN" ]; then
  echo "[+] Found active Ethernet connection: '$WIRED_CONN'"
  read -p "    Configure static IP $WIRED_IP on '$WIRED_CONN'? (y/N): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    nmcli connection modify "$WIRED_CONN" \
      ipv4.addresses "$WIRED_IP" \
      ipv4.gateway "$GATEWAY" \
      ipv4.dns "$UPSTREAM_DNS" \
      ipv4.method "manual"
    echo "    [✓] Ethernet static IP configured."
    WIRED_CONFIGURED=true
  else
    echo "    [!] Skipping Ethernet static IP configuration."
  fi
else
  echo "[!] No active Ethernet connection profile detected."
fi

# Configure Wi-Fi
if [ -n "$WIFI_CONN" ]; then
  echo "[+] Found active Wi-Fi connection: '$WIFI_CONN'"
  read -p "    Configure static IP $WIFI_IP on '$WIFI_CONN'? (y/N): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    nmcli connection modify "$WIFI_CONN" \
      ipv4.addresses "$WIFI_IP" \
      ipv4.gateway "$GATEWAY" \
      ipv4.dns "$UPSTREAM_DNS" \
      ipv4.method "manual"
    echo "    [✓] Wi-Fi static IP configured."
    WIFI_CONFIGURED=true
  else
    echo "    [!] Skipping Wi-Fi static IP configuration."
  fi
else
  echo "[!] No active Wi-Fi connection profile detected."
fi


echo "=================================================================="
echo "  Configuration Finished!"
echo "=================================================================="
echo "To apply your static IP configurations, restart your connections:"
if [ "$WIRED_CONFIGURED" = true ]; then
  echo "  sudo nmcli connection up \"$WIRED_CONN\""
fi
if [ "$WIFI_CONFIGURED" = true ]; then
  echo "  sudo nmcli connection up \"$WIFI_CONN\""
fi
echo ""
echo "=================================================================="
