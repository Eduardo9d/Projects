#!/bin/bash


# Whitelist A — Máxima segurança
ALLOWED_PORTS=(53 631 5353)

# FUNÇÕES 

is_allowed() {
    local port=$1
    for allowed in "${ALLOWED_PORTS[@]}"; do
        if [[ "$allowed" == "$port" ]]; then
            return 0
        fi
    done
    return 1
}

# EXECUÇÃO 

echo "A definir política padrão UFW, bloqueando todas as portas de entrada e permitindo todas as saídas"

sudo ufw default deny incoming
sudo ufw default allow outgoing

# Verificar se UFW está ativo, caso contrário ativar
echo " A verificar estado do UFW..."
sudo ufw status | grep -q inactive
if [[ $? -eq 0 ]]; then
    echo "UFW está desligado — a ativar"
    sudo ufw --force enable
else
    echo "UFW já está ativo"
fi


echo "A recolher portas abertas no sistema"
OPEN_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | sed 's/.*://')
OPEN_PORTS=$(echo "$OPEN_PORTS" | sort -n | uniq)


echo "A aplicar whitelist (53, 631, 5353)..."
for port in "${ALLOWED_PORTS[@]}"; do
    sudo ufw status numbered | grep -q "$port"
    if [[ $? -ne 0 ]]; then
        echo "A permitir porta: $port"
        sudo ufw allow "$port"
    else
        echo "Porta $port já está permitida"
    fi
done


echo "A bloquear portas não permitidas."
for port in $OPEN_PORTS; do
    if is_allowed "$port"; then
        echo "Porta $port é permitida"
    else
        echo "Porta $port NÃO permitida — a bloquear"
        sudo ufw deny "$port"
    fi
done


echo "Estado final da firewall:"
sudo ufw status verbose


echo "Script concluído"
