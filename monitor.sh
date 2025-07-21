#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"
BOLD="\e[1m"

# ========== BANNER ==========
banner() {
    clear
    echo -e "${MAGENTA}"
    echo ' ███████╗██╗     ██╗ █████╗ ███████╗███████╗███████╗'
    echo ' ██╔════╝██║     ██║██╔══██╗██╔════╝██╔════╝██╔════╝'
    echo ' █████╗  ██║     ██║███████║███████╗█████╗  ███████╗'
    echo ' ██╔══╝  ██║     ██║██╔══██║╚════██║██╔══╝  ╚════██║'
    echo ' ███████╗███████╗██║██║  ██║███████║███████╗███████║'
    echo ' ╚══════╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝'
    echo -e "${BOLD}            Realtime Defender Monitor by Eliassz${RESET}\n"
}

# ========== MONITOR FUNCTIONS ==========
monitor_logins() {
    echo -e "${CYAN}[+] Users Logged In:${RESET}"
    who | awk '{printf " - %s on %s (%s)\n", $1, $2, $3}'
    echo
}

monitor_logouts() {
    echo -e "${CYAN}[+] Recent User Logouts:${RESET}"
    last -x | grep "logged out" | head -n 5
    echo
}

monitor_commands() {
    echo -e "${YELLOW}[+] Recently Executed Commands (via bash history):${RESET}"
    for user in $(getent passwd {1000..65534} | cut -d: -f1); do
        histfile=$(eval echo ~$user/.bash_history)
        if [[ -f $histfile ]]; then
            echo -e "${GREEN}User: $user${RESET}"
            tail -n 3 "$histfile" 2>/dev/null | sed 's/^/  > /'
        fi
    done
    echo
}

monitor_processes() {
    echo -e "${YELLOW}[+] Active User Processes:${RESET}"
    for user in $(getent passwd {1000..65534} | cut -d: -f1); do
        procs=$(ps -u "$user" -o pid,cmd --sort=start_time 2>/dev/null | tail -n +2)
        if [[ -n "$procs" ]]; then
            echo -e "${GREEN}[User: $user]${RESET}"
            echo "$procs" | awk '{printf "  - PID: %s | CMD: %s\n", $1, substr($0,index($0,$2))}'
        fi
    done
    echo
}

monitor_transfers() {
    echo -e "${CYAN}[+] Recent Network Transfers (open ports):${RESET}"
    ss -tuna | grep -E 'ESTAB|LISTEN' | awk '{print " - " $5 " <---> " $6 " (" $1 ")"}' | head -n 10
    echo
}

defense_monitor_menu() {
    clear
    banner
    echo -e "${CYAN}[5] Realtime Port Attack Monitoring & Defense${RESET}"
    echo -e "${YELLOW}Detecting scanning, intrusion attempts, and port exploitation...${RESET}"
    echo ""

    echo -e "${MAGENTA}Monitoring logs for suspicious activity (nmap scan, masscan, etc)...${RESET}"
    echo -e "Press CTRL+C to stop.\n"

    sudo tail -Fn0 /var/log/syslog | while read line; do
        if echo "$line" | grep -E "nmap|masscan|NULL scan|XMAS scan|FIN scan|NMAP scan|portscan|invalid user|Failed password"; then
            echo -e "${RED}[!] Suspicious activity detected:${RESET} $line"
            attacker_ip=$(echo "$line" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            if [ -n "$attacker_ip" ]; then
                echo -e "\n${YELLOW}Attacker IP detected: ${attacker_ip}${RESET}"
                echo -e "${CYAN}Options:${RESET}"
                echo "1) Block IP using iptables"
                echo "2) Ignore"
                echo "0) Back"
                read -p "Choose: " act
                if [[ $act == 1 ]]; then
                    sudo iptables -A INPUT -s "$attacker_ip" -j DROP
                    echo -e "${GREEN}[+] IP $attacker_ip has been blocked.${RESET}"
                elif [[ $act == 0 ]]; then
                    break
                fi
            fi
        fi
    done
}

vuln_port_check_menu() {
    clear
    banner
    echo -e "${CYAN}[6] Vulnerable Ports & Weak Services Check${RESET}"
    echo ""

    echo -e "${YELLOW}Scanning for known risky ports...${RESET}"

    sudo netstat -tuln | grep -E ':(21|22|23|25|110|139|143|445|3306|3389)' | while read line; do
        port=$(echo "$line" | awk '{print $4}' | awk -F':' '{print $NF}')
        case $port in
            21) echo -e "${RED}[!] FTP (21) open — consider using SFTP instead.${RESET}" ;;
            23) echo -e "${RED}[!] Telnet (23) open — insecure protocol, disable if unused.${RESET}" ;;
            25) echo -e "${YELLOW}[!] SMTP (25) open — ensure secure configuration.${RESET}" ;;
            139|445) echo -e "${RED}[!] SMB Ports ($port) open — commonly exploited, restrict access.${RESET}" ;;
            3306) echo -e "${YELLOW}[!] MySQL (3306) open — check for passwordless or root access.${RESET}" ;;
            3389) echo -e "${RED}[!] RDP (3389) open — if exposed to internet, use VPN.${RESET}" ;;
            *) echo -e "[*] Port $port open — review manually." ;;
        esac
    done

    echo -e "\n${CYAN}Suggested Tools:${RESET}"
    echo -e "- nmap: \`sudo apt install nmap\`"
    echo -e "- lynis: \`sudo apt install lynis\` then run \`sudo lynis audit system\`"
    echo -e "- chkrootkit: \`sudo apt install chkrootkit\`"

    echo -e "\n${MAGENTA}0) Back${RESET}"
    read -p "Press 0 to return: " back
}


# ========== MENU ==========
show_menu() {
    echo -e "${BOLD}${YELLOW}Choose Monitoring Mode:${RESET}"
    echo -e "${GREEN}[1]${RESET} Realtime Login Monitor"
    echo -e "${GREEN}[2]${RESET} Realtime Command Monitor"
    echo -e "${GREEN}[3]${RESET} View Process/Transfer Summary"
    echo -e "${GREEN}[4]${RESET} View All Activity Summary"
    echo -e "${GREEN}[5]${RESET} Monitor Attack & Block IP"
    echo -e "${GREEN}[6]${RESET} Scan for Weak/Open Ports"
    echo -e "${GREEN}[0]${RESET} Exit"
}

# ========== LOOP ==========
main_loop() {
    while true; do
        clear
        banner
        show_menu

        read -rp "$(echo -e "${RED}Select Option: ${RESET}")" opt
        case $opt in
            1)
                clear && banner
                echo -e "${CYAN}[Realtime Login Monitoring]${RESET} - Press CTRL+C to stop"
                last_login_hash=""
                while true; do
                    current_hash=$(who | md5sum)
                    if [[ "$current_hash" != "$last_login_hash" ]]; then
                        clear && banner
                        monitor_logins
                        last_login_hash="$current_hash"
                    fi
                    inotifywait -qq -e modify /var/log/wtmp
                done
                ;;
            2)
                clear && banner
                echo -e "${CYAN}[Realtime Command Monitor]${RESET} - Press CTRL+C to stop"
                while true; do
                    clear && banner
                    monitor_commands
                    inotifywait -qq -e modify $(getent passwd {1000..65534} | cut -d: -f6 | awk '{print $0"/.bash_history"}' | xargs -d '\n')
                done
                ;;
            3)
                clear && banner
                monitor_processes
                monitor_transfers
                echo -e "\n${CYAN}Press Enter to go back.${RESET}"
                read
                ;;
            4)
                clear && banner
                monitor_logins
                monitor_logouts
                monitor_commands
                monitor_processes
                monitor_transfers
                echo -e "\n${CYAN}Press Enter to go back.${RESET}"
                read
                ;;
            5)
                clear
                defense_monitor_menu
                ;;
            6)
                clear
                vuln_port_check_menu
                ;;
            0)
                echo -e "${YELLOW}Exiting...${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ========== EXECUTE ==========
main_loop
