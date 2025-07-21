import os
import shutil
import subprocess

required_tools = [
    "auditctl", "inotifywait", "iptables", "lsof",
    "netstat", "nmap", "tcpdump", "whois"
]

optional_tools = ["fail2ban", "pstree"]

def check_and_install(tool):
    if shutil.which(tool) is None:
        print(f"[+] Installing missing tool: {tool}")
        subprocess.run(["sudo", "apt-get", "install", "-y", tool], check=False)
    else:
        print(f"[✓] {tool} is already installed.")

print("=== Eliassz Defender Python Installer ===")
print("[*] Checking required tools...\n")

for tool in required_tools:
    check_and_install(tool)

print("\n[*] Checking optional tools...\n")
for tool in optional_tools:
    check_and_install(tool)

print("\n[✓] All tools checked.")
