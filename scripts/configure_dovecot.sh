#!/bin/bash

set -e

DOMAIN="email.local"
HOSTNAME_ONLY="servidor-email"
FQDN="${HOSTNAME_ONLY}.${DOMAIN}"

echo "Configurando Dovecot..."

# certificado ssl
echo "Criando certificado SSL..."

CERT_DIR="/etc/dovecot/ssl"
mkdir -p $CERT_DIR

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout $CERT_DIR/dovecot.key \
    -out $CERT_DIR/dovecot.crt \
    -subj "/C=BR/ST=Estado/L=Cidade/O=Organizacao/CN=${FQDN}/emailAddress=admin@${DOMAIN}"

chmod 600 $CERT_DIR/dovecot.key
chmod 644 $CERT_DIR/dovecot.crt
chown root:root $CERT_DIR/dovecot.key $CERT_DIR/dovecot.crt

# configurar protocols
echo "Configurando protocols..."

cat > /etc/dovecot/conf.d/10-protocols.conf <<EOF
protocols = imap pop3 lmtp
EOF

cat > /etc/dovecot/conf.d/10-logging.conf <<EOF
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log
debug_log_path = /var/log/dovecot-debug.log
EOF

# autenticação
echo "Configurando autenticação..."

cat > /etc/dovecot/conf.d/10-auth.conf <<EOF
disable_plaintext_auth = no
auth_mechanisms = plain login

passdb {
    driver = pam
}

userdb {
    driver = passwd
}
EOF

# maildir
echo "Configurando Maildir..."

cat > /etc/dovecot/conf.d/10-mail.conf <<EOF
mail_location = maildir:~/Maildir

namespace inbox {
    inbox = yes
    location = 
    mailbox Drafts {
        special_use = \Drafts
    }
    mailbox Sent {
        special_use = \Sent
    }
    mailbox "Sent Messages" {
        special_use = \Sent
    }
    mailbox Trash {
        special_use = \Trash
    }
    mailbox Junk {
        special_use = \Junk
    }
}
EOF

# ssl
echo "Configurando SSL..."

cat > /etc/dovecot/conf.d/10-ssl.conf <<EOF
ssl = required
ssl_cert = <$CERT_DIR/dovecot.crt
ssl_key = <$CERT_DIR/dovecot.key
ssl_protocols = !SSLv2 !SSLv3 TLSv1.2 TLSv1.3
ssl_cipher_list = HIGH:!aNULL:!MD5
ssl_prefer_server_ciphers = yes
EOF

# sasl para postfix
echo "Configurando SASL para Postfix..."
if [ ! -f /etc/dovecot/conf.d/10-master.conf.orig ]; then
    cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
fi

mkdir -p /var/spool/postfix/private
chown root:postfix /var/spool/postfix/private
chmod 750 /var/spool/postfix/private

cat > /etc/dovecot/conf.d/10-master.conf <<EOF
service imap-login {
    inet_listener imap {
        port = 143
    }
    inet_listener imaps {
        port = 993
        ssl = yes
    }
}

service pop3-login {
    inet_listener pop3 {
        port = 110
    }
    inet_listener pop3s {
        port = 995
        ssl = yes
    }
}

service lmtp {
    unix_listener /var/spool/postfix/private/dovecot-lmtp {
        mode = 0600
        user = postfix
        group = postfix
    }
}

service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0666
        user = postfix
        group = postfix
    }
    user = dovecot
}

service auth-worker {
    user = root
}
EOF

# criar maildir para usuarios
echo "Criando Maildir para usuários..."

for user in aluno1 aluno2; do
    if id "$user" &>/dev/null; then
        USER_HOME=$(eval echo ~$user)
        MAILDIR="$USER_HOME/Maildir"
        if [ ! -d "$MAILDIR" ]; then
            mkdir -p "$MAILDIR"/{cur,new,tmp}
            chown -R $user:$user "$MAILDIR"
            chmod -R 700 "$MAILDIR"
        fi
    fi
done

dovecot -n
systemctl restart dovecot
systemctl enable dovecot

if systemctl is-active --quiet dovecot; then
    echo "Dovecot rodando"
else
    echo "Erro ao iniciar Dovecot"
    systemctl status dovecot
    exit 1
fi

echo "Portas IMAP/POP3:"
netstat -tlnp | grep -E ':(110|143|993|995)' || ss -tlnp | grep -E ':(110|143|993|995)'

