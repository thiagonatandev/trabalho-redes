#!/bin/bash

set -e

DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"
IP_ADDR="192.168.56.10"

echo "Testando servidor de email..."
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# verificar serviços
echo "Verificando serviços..."
if systemctl is-active --quiet postfix; then
    echo -e "${GREEN}OK${NC} Postfix rodando"
else
    echo -e "${RED}ERRO${NC} Postfix não está rodando"
fi

if systemctl is-active --quiet dovecot; then
    echo -e "${GREEN}OK${NC} Dovecot rodando"
else
    echo -e "${RED}ERRO${NC} Dovecot não está rodando"
fi
echo ""

# verificar portas
echo "Verificando portas..."
for port in 25 587 110 143 993 995; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}OK${NC} Porta $port aberta"
    else
        echo -e "${RED}ERRO${NC} Porta $port fechada"
    fi
done
echo ""

# testar envio de email
echo "Testando envio de email..."
if echo "teste" | mail -s "teste" aluno1@${DOMAIN} 2>/dev/null; then
    echo -e "${GREEN}OK${NC} Email enviado"
    sleep 2
    if [ -d "/home/aluno1/Maildir/new" ] && [ "$(ls -A /home/aluno1/Maildir/new 2>/dev/null)" ]; then
        echo -e "${GREEN}OK${NC} Email recebido no Maildir"
    else
        echo -e "${YELLOW}AVISO${NC} Email pode não ter chegado ainda"
    fi
else
    echo -e "${RED}ERRO${NC} Falha ao enviar email"
fi
echo ""

# testar conexões tls
echo "Testando conexões TLS..."
(echo "EHLO ${FQDN}"; echo "QUIT") | timeout 3 openssl s_client -connect ${IP_ADDR}:25 -starttls smtp -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} SMTP/TLS porta 25" || echo -e "${YELLOW}AVISO${NC} SMTP/TLS porta 25 (teste manual)"

(echo "EHLO ${FQDN}"; echo "QUIT") | timeout 3 openssl s_client -connect ${IP_ADDR}:587 -starttls smtp -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} SMTP Submission/TLS porta 587" || echo -e "${YELLOW}AVISO${NC} SMTP Submission/TLS porta 587 (teste manual)"

(echo "a1 LOGIN aluno1 123456"; echo "a2 LOGOUT") | timeout 3 openssl s_client -connect ${IP_ADDR}:143 -starttls imap -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} IMAP/TLS porta 143" || echo -e "${YELLOW}AVISO${NC} IMAP/TLS porta 143 (teste manual)"

(echo "a1 LOGIN aluno1 123456"; echo "a2 LOGOUT") | timeout 3 openssl s_client -connect ${IP_ADDR}:993 -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} IMAPS porta 993" || echo -e "${YELLOW}AVISO${NC} IMAPS porta 993 (teste manual)"

(echo "USER aluno1"; echo "PASS 123456"; echo "QUIT") | timeout 3 openssl s_client -connect ${IP_ADDR}:110 -starttls pop3 -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} POP3/TLS porta 110" || echo -e "${YELLOW}AVISO${NC} POP3/TLS porta 110 (teste manual)"

(echo "USER aluno1"; echo "PASS 123456"; echo "QUIT") | timeout 3 openssl s_client -connect ${IP_ADDR}:995 -quiet 2>/dev/null && \
    echo -e "${GREEN}OK${NC} POP3S porta 995" || echo -e "${YELLOW}AVISO${NC} POP3S porta 995 (teste manual)"
echo ""

# verificar maildir
echo "Verificando Maildir..."
for user in aluno1 aluno2; do
    if [ -d "/home/$user/Maildir" ]; then
        EMAIL_COUNT=$(ls -1 /home/$user/Maildir/new 2>/dev/null | wc -l)
        echo "$user: $EMAIL_COUNT emails novos"
    else
        echo -e "${RED}ERRO${NC} Maildir não existe para $user"
    fi
done
echo ""

echo "Logs recentes:"
tail -n 3 /var/log/mail.log 2>/dev/null | head -n 3
tail -n 3 /var/log/dovecot.log 2>/dev/null | head -n 3

