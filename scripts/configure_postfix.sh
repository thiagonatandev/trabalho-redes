#!/bin/bash

set -e

DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"
IP_ADDR="192.168.56.10"

echo "Configurando Postfix..."

# backup do main.cf
if [ ! -f /etc/postfix/main.cf.orig ]; then
    cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
fi

# criar certificado ssl
echo "Criando certificado SSL..."

CERT_DIR="/etc/postfix/ssl"
mkdir -p $CERT_DIR

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout $CERT_DIR/postfix.key \
    -out $CERT_DIR/postfix.crt \
    -subj "/C=BR/ST=Estado/L=Cidade/O=Organizacao/CN=${FQDN}/emailAddress=admin@${DOMAIN}"

chmod 600 $CERT_DIR/postfix.key
chmod 644 $CERT_DIR/postfix.crt
chown root:root $CERT_DIR/postfix.key $CERT_DIR/postfix.crt

echo "Configurando main.cf..."

cat > /etc/postfix/main.cf <<EOF
myhostname = ${FQDN}
mydomain = ${DOMAIN}
myorigin = \$mydomain
inet_interfaces = all
inet_protocols = ipv4

mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mynetworks = 127.0.0.0/8, [::ffff:127.0.0.0]/104, [::1]/128, 192.168.56.0/24

home_mailbox = Maildir/
mailbox_command = 

smtpd_tls_cert_file = /etc/postfix/ssl/postfix.crt
smtpd_tls_key_file = /etc/postfix/ssl/postfix.key
smtpd_use_tls = yes
smtpd_tls_auth_only = yes
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3, TLSv1.2, TLSv1.3
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, TLSv1.2, TLSv1.3
smtpd_tls_ciphers = high
smtpd_tls_mandatory_ciphers = high
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtpd_tls_session_cache_timeout = 3600s

smtp_tls_security_level = may
smtp_tls_protocols = !SSLv2, !SSLv3, TLSv1.2, TLSv1.3
smtp_tls_ciphers = high
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = \$myhostname

smtpd_helo_required = yes
smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname, warn_if_reject reject_unknown_helo_hostname, permit

smtpd_client_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_rbl_client zen.spamhaus.org, permit

smtpd_sender_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_sender, reject_unknown_sender_domain, permit

smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_recipient, reject_unknown_recipient_domain, permit_mail_access, reject_unauth_destination, permit

maillog_file = /var/log/mail.log
EOF

# configurar submission na porta 587
echo "Configurando porta 587..."
if ! grep -q "^submission" /etc/postfix/master.cf; then
    if [ ! -f /etc/postfix/master.cf.orig ]; then
        cp /etc/postfix/master.cf /etc/postfix/master.cf.orig
    fi
    sed -i 's/^submission/#submission/' /etc/postfix/master.cf
    cat >> /etc/postfix/master.cf <<EOF

submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix-submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_helo_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=permit_mynetworks,permit_sasl_authenticated
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
EOF
fi

postfix check
systemctl restart postfix
systemctl enable postfix

if systemctl is-active --quiet postfix; then
    echo "Postfix rodando"
else
    echo "Erro ao iniciar Postfix"
    systemctl status postfix
    exit 1
fi

echo "Portas SMTP:"
netstat -tlnp | grep -E ':(25|587)' || ss -tlnp | grep -E ':(25|587)'

