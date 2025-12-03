#!/bin/bash

# Script para Gerar Relatório do Servidor de Email
# =================================================

DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"
IP_ADDR="192.168.56.10"
REPORT_FILE="/tmp/relatorio_servidor_email_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Gerando Relatório do Servidor de Email ==="
echo ""

{
    echo "=========================================="
    echo "RELATÓRIO DO SERVIDOR DE EMAIL"
    echo "=========================================="
    echo "Data: $(date)"
    echo "Hostname: $(hostname -f)"
    echo "IP: ${IP_ADDR}"
    echo ""
    
    echo "----------------------------------------"
    echo "1. INFORMAÇÕES DO SISTEMA"
    echo "----------------------------------------"
    echo "Sistema Operacional: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    echo "----------------------------------------"
    echo "2. STATUS DOS SERVIÇOS"
    echo "----------------------------------------"
    echo "Postfix:"
    systemctl is-active postfix && echo "  Status: ATIVO" || echo "  Status: INATIVO"
    systemctl is-enabled postfix && echo "  Habilitado: SIM" || echo "  Habilitado: NÃO"
    echo ""
    
    echo "Dovecot:"
    systemctl is-active dovecot && echo "  Status: ATIVO" || echo "  Status: INATIVO"
    systemctl is-enabled dovecot && echo "  Habilitado: SIM" || echo "  Habilitado: NÃO"
    echo ""
    
    echo "----------------------------------------"
    echo "3. PORTAS ABERTAS"
    echo "----------------------------------------"
    echo "Portas de Email:"
    for port in 25 587 110 143 993 995; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo "  Porta $port: ABERTA"
        else
            echo "  Porta $port: FECHADA"
        fi
    done
    echo ""
    
    echo "----------------------------------------"
    echo "4. CERTIFICADOS SSL"
    echo "----------------------------------------"
    echo "Postfix:"
    if [ -f /etc/postfix/ssl/postfix.crt ]; then
        echo "  Certificado: EXISTE"
        echo "  Válido até: $(openssl x509 -in /etc/postfix/ssl/postfix.crt -noout -enddate 2>/dev/null | cut -d= -f2)"
    else
        echo "  Certificado: NÃO ENCONTRADO"
    fi
    echo ""
    
    echo "Dovecot:"
    if [ -f /etc/dovecot/ssl/dovecot.crt ]; then
        echo "  Certificado: EXISTE"
        echo "  Válido até: $(openssl x509 -in /etc/dovecot/ssl/dovecot.crt -noout -enddate 2>/dev/null | cut -d= -f2)"
    else
        echo "  Certificado: NÃO ENCONTRADO"
    fi
    echo ""
    
    echo "----------------------------------------"
    echo "5. USUÁRIOS DE EMAIL"
    echo "----------------------------------------"
    for user in aluno1 aluno2; do
        if id "$user" &>/dev/null; then
            echo "Usuário: $user"
            echo "  Email: ${user}@${DOMAIN}"
            if [ -d "/home/$user/Maildir" ]; then
                EMAIL_COUNT=$(find /home/$user/Maildir/new -type f 2>/dev/null | wc -l)
                echo "  Maildir: EXISTE"
                echo "  Emails novos: $EMAIL_COUNT"
            else
                echo "  Maildir: NÃO EXISTE"
            fi
            echo ""
        fi
    done
    
    echo "----------------------------------------"
    echo "6. CONFIGURAÇÕES PRINCIPAIS"
    echo "----------------------------------------"
    echo "Postfix:"
    echo "  Domínio: ${DOMAIN}"
    echo "  Hostname: ${FQDN}"
    echo "  Mailbox: Maildir"
    echo "  TLS: Habilitado"
    echo "  SASL: Habilitado (Dovecot)"
    echo ""
    
    echo "Dovecot:"
    echo "  Protocolos: IMAP, POP3, LMTP"
    echo "  Mailbox: Maildir"
    echo "  TLS: Obrigatório"
    echo "  SASL para Postfix: Habilitado"
    echo ""
    
    echo "----------------------------------------"
    echo "7. ÚLTIMAS LINHAS DOS LOGS"
    echo "----------------------------------------"
    echo "Postfix (últimas 10 linhas):"
    tail -n 10 /var/log/mail.log 2>/dev/null || echo "  Log não encontrado"
    echo ""
    
    echo "Dovecot (últimas 10 linhas):"
    tail -n 10 /var/log/dovecot.log 2>/dev/null || echo "  Log não encontrado"
    echo ""
    
    echo "----------------------------------------"
    echo "8. TESTES DE CONECTIVIDADE"
    echo "----------------------------------------"
    echo "Testando conexões locais:"
    
    # Teste SMTP
    if timeout 2 bash -c "echo > /dev/tcp/localhost/25" 2>/dev/null; then
        echo "  SMTP (25): OK"
    else
        echo "  SMTP (25): FALHOU"
    fi
    
    # Teste SMTP Submission
    if timeout 2 bash -c "echo > /dev/tcp/localhost/587" 2>/dev/null; then
        echo "  SMTP Submission (587): OK"
    else
        echo "  SMTP Submission (587): FALHOU"
    fi
    
    # Teste IMAP
    if timeout 2 bash -c "echo > /dev/tcp/localhost/143" 2>/dev/null; then
        echo "  IMAP (143): OK"
    else
        echo "  IMAP (143): FALHOU"
    fi
    
    # Teste IMAPS
    if timeout 2 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null; then
        echo "  IMAPS (993): OK"
    else
        echo "  IMAPS (993): FALHOU"
    fi
    
    # Teste POP3
    if timeout 2 bash -c "echo > /dev/tcp/localhost/110" 2>/dev/null; then
        echo "  POP3 (110): OK"
    else
        echo "  POP3 (110): FALHOU"
    fi
    
    # Teste POP3S
    if timeout 2 bash -c "echo > /dev/tcp/localhost/995" 2>/dev/null; then
        echo "  POP3S (995): OK"
    else
        echo "  POP3S (995): FALHOU"
    fi
    echo ""
    
    echo "=========================================="
    echo "FIM DO RELATÓRIO"
    echo "=========================================="
    
} | tee "$REPORT_FILE"

echo ""
echo "Relatório salvo em: $REPORT_FILE"
echo ""
echo "Para visualizar o relatório:"
echo "  cat $REPORT_FILE"

