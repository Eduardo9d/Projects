import subprocess
import socket
import csv
import os
import platform

def ping_host(ip):
    ping_command = ['ping', '-n', '2', ip] if platform.system().lower().startswith('windows') else ['ping', '-c', '2', ip]
    try:
        output = subprocess.check_output(ping_command, universal_newlines=True, stderr=subprocess.STDOUT, timeout=10)
        result = "Success"
    except subprocess.CalledProcessError as exc:
        output = exc.output or ""
        result = "Failed"
    except FileNotFoundError:
        output = "ping command not found"
        result = "Error"
    except subprocess.TimeoutExpired as exc:
        output = exc.output or "Ping timed out"
        result = "Timeout"
    return result, output

def scan_ports(ip, ports=None):
    if ports is None:
        # Common ports to scan
        ports = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 3389]
    port_results = []
    for port in ports:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(1)
            result = sock.connect_ex((ip, port))
            status = "OPEN" if result == 0 else "CLOSED"
            port_results.append((port, status))
    return port_results

def resolve_dns(ip):
    try:
        host = socket.gethostbyaddr(ip)
        return host[0]
    except socket.herror:
        return "No DNS record"

def write_to_csv(ip, ping_status, port_results, dns_result, csv_file):
    file_exists = os.path.isfile(csv_file)
    with open(csv_file, mode='a', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        if not file_exists:
            writer.writerow(['IP Address', 'Ping Status', 'Ports (OPEN/CLOSED)', 'DNS Result'])
        ports_str = "; ".join([f"{port}:{status}" for port, status in port_results])
        writer.writerow([ip, ping_status, ports_str, dns_result])

if __name__ == "__main__":
    try:
        target_ip = input("Enter IP address to test: ")
        ping_status, ping_output = ping_host(target_ip)
        port_results = scan_ports(target_ip)
        dns_result = resolve_dns(target_ip)

        # Print results to console
        print(f"Ping: {ping_status}")
        if ping_output:
            print(ping_output)
        for port, status in port_results:
            print(f"Port {port}: {status}")
        print(f"DNS: {dns_result}")

        # Write results to CSV
        csv_file = "network_test_results.csv"
        write_to_csv(target_ip, ping_status, port_results, dns_result, csv_file)
        print(f"Results saved to {csv_file}")
    except KeyboardInterrupt:
        print("\nTest cancelled by user.")
        exit(1)