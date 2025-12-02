#!/bin/bash

# Configurações Iniciais
# ---------------------
DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"
IP_ADDR="192.168.56.10"

echo "=== Iniciando Provisionamento do Servidor: ${FQDN} ==="

# 1. Definição do Hostname
# ------------------------
echo "--- Configurando Hostname ---"
hostnamectl set-hostname $HOSTNAME_ONLY
# Garante que o hostname completo esteja resolvendo para o IP fixo
# Remove entrada antiga se existir para evitar duplicidade
sed -i "/$IP_ADDR/d" /etc/hosts
echo "$IP_ADDR $FQDN $HOSTNAME_ONLY" >> /etc/hosts

echo "Hostname definido para: $(hostname -f)"

# 2. Atualização do Sistema e Instalação de Pacotes Base
# ------------------------------------------------------
echo "--- Atualizando repositórios e sistema ---"
apt-get update && apt-get upgrade -y
apt-get install -y curl vim net-tools telnet dnsutils

# 3. Instalação dos Pacotes de E-mail (Postfix, Dovecot, etc)
# -----------------------------------------------------------
echo "--- Instalando Pacotes de E-mail ---"

# Configuração prévia para o Postfix não abrir telas interativas (debconf)
debconf-set-selections <<< "postfix postfix/mailname string ${FQDN}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# Instalação dos pacotes solicitados
apt-get install -y postfix dovecot-imapd dovecot-pop3d mailutils ca-certificates openssl

# 4. Criação de Usuários de Teste
# -------------------------------
echo "--- Criando usuários para teste de e-mail ---"
# Criamos o usuário e definimos a senha como '123456' para facilitar os testes
for user in aluno1 aluno2; do
    if id "$user" &>/dev/null; then
        echo "Usuário $user já existe."
    else
        useradd -m -s /bin/bash $user
        echo "$user:123456" | chpasswd
        echo "Usuário $user criado."
    fi
done

# 5. Firewall Básico (UFW)
# ------------------------
echo "--- Configurando Firewall (UFW) ---"
# Instala o UFW
apt-get install -y ufw

# Regras
ufw allow 22/tcp        # SSH (Importante para o Vagrant conectar)
ufw allow 80/tcp        # HTTP (Opcional, bom deixar)
ufw allow 25/tcp        # SMTP (Postfix)
ufw allow 587/tcp       # SMTP Submission
ufw allow 110/tcp       # POP3 (Dovecot)
ufw allow 143/tcp       # IMAP (Dovecot)
ufw allow 993/tcp       # IMAPS
ufw allow 995/tcp       # POP3S

# Habilita o firewall
ufw --force enable
ufw status verbose

echo "=== Provisionamento Concluído com Sucesso! ==="