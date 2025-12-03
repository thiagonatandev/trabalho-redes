#!/bin/bash

DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"
IP_ADDR="192.168.56.10"

echo "Configurando servidor de email..."

# hostname
hostnamectl set-hostname $HOSTNAME_ONLY
sed -i "/$IP_ADDR/d" /etc/hosts
echo "$IP_ADDR $FQDN $HOSTNAME_ONLY" >> /etc/hosts

# atualizar sistema
echo "Atualizando sistema..."
apt-get update && apt-get upgrade -y
apt-get install -y curl vim net-tools telnet dnsutils

# instalar pacotes de email
echo "Instalando pacotes de email..."
debconf-set-selections <<< "postfix postfix/mailname string ${FQDN}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix dovecot-imapd dovecot-pop3d mailutils ca-certificates openssl

# criar usuarios
echo "Criando usuários..."
for user in aluno1 aluno2; do
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash $user
        echo "$user:123456" | chpasswd
    fi
done

# firewall
echo "Configurando firewall..."
apt-get install -y ufw
ufw allow 22/tcp
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 110/tcp
ufw allow 143/tcp
ufw allow 993/tcp
ufw allow 995/tcp
ufw --force enable

# configurar postfix e dovecot
chmod +x /vagrant/scripts/configure_postfix.sh
/vagrant/scripts/configure_postfix.sh

chmod +x /vagrant/scripts/configure_dovecot.sh
/vagrant/scripts/configure_dovecot.sh

# testes
chmod +x /vagrant/scripts/test_email.sh
/vagrant/scripts/test_email.sh

echo ""
echo "Configuração concluída!"
echo "Usuários: aluno1@${DOMAIN} e aluno2@${DOMAIN} (senha: 123456)"