import subprocess
import socket
import csv
import os

def ping_host(ip):
    try:
        output = subprocess.check_output(['ping', '-n', '2', ip], universal_newlines=True)
        result = "Success"
    except subprocess.CalledProcessError:
        output = ""
        result = "Failed"
    return result, output

def scan_ports(ip, ports=[22, 80, 443, 3389]):
    port_results = []
    for port in ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex((ip, port))
        status = "OPEN" if result == 0 else "CLOSED"
        port_results.append((port, status))
        sock.close()
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
    target_ip = input("Enter IP address to test: ")
    ping_status, ping_output = ping_host(target_ip)
    port_results = scan_ports(target_ip)
    dns_result = resolve_dns(target_ip)

    # Print results to console
    print(f"Ping: {ping_status}")
    for port, status in port_results:
        print(f"Port {port}: {status}")
    print(f"DNS: {dns_result}")

    # Write results to CSV
    csv_file = "network_test_results.csv"
    write_to_csv(target_ip, ping_status, port_results, dns_result, csv_file)
    print(f"Results saved to {csv_file}")