#!/bin/bash

echo "AUTO OPTIMIZE — Laptop Edition"
echo

# ============================================
# 1. Ajustar swappiness (melhor para SSD)
# ============================================

echo "A ajustar swappiness para 10..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null

# ============================================
# 2. Ativar TRIM (SSD)
# ============================================

echo "A ativar TRIM semanal..."
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# ============================================
# 3. Limpar caches de RAM
# ============================================

echo "A limpar caches de RAM..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

# ============================================
# 4. Desativar serviços inúteis
# ============================================

SERVICES=(
    bluetooth
    cups-browsed
    avahi-daemon
)

echo " A desativar serviços desnecessários..."
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo " A parar $svc"
        sudo systemctl stop "$svc"
        sudo systemctl disable "$svc"
    else
        echo " $svc já está desativado"
    fi
done

# ============================================
# 5. Otimizar boot (systemd-analyze)
# ============================================

echo " A verificar serviços lentos no boot..."
systemd-analyze blame | head -n 10

# ============================================
# 6. Ajustar governor da CPU
# ============================================

echo " A definir governor para 'ondemand'..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo ondemand | sudo tee "$cpu" >/dev/null
done

# ============================================
# 7. Verificar temperaturas
# ============================================

echo "Temperaturas atuais:"
sensors | grep -E "Core|temp"

# ============================================
# 8. Relatório final
# ============================================

echo
echo "Otimização concluída!"
echo "O teu laptop está mais rápido, frio e eficiente."
