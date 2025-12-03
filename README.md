# Servidor de Email Interno

Servidor de email completo configurado com Debian, Postfix, Dovecot, Thunderbird e OpenSSL.

## Tecnologias

- **Debian** - Sistema operacional
- **Postfix** - Servidor SMTP
- **Dovecot** - Servidor IMAP/POP3
- **Thunderbird** - Cliente de email
- **OpenSSL** - Certificados SSL/TLS

## Ferramentas Necessárias

- VirtualBox
- Vagrant

## Configuração Rápida

### 1. Subir o ambiente

```bash
vagrant up
```

Este comando irá:
- Criar a VM Debian
- Instalar todos os pacotes necessários
- Configurar Postfix com TLS
- Configurar Dovecot com Maildir, SASL, IMAP/POP3
- Executar testes iniciais

### 2. Acessar a VM

```bash
vagrant ssh
```

### 3. Executar testes

Dentro da VM:

```bash
/vagrant/scripts/test_email.sh
```

## Usuários de Teste

- **aluno1@email.local** (senha: 123456)
- **aluno2@email.local** (senha: 123456)

## Configurações Implementadas

### Postfix
- ✅ Instalação e configuração
- ✅ Certificado SSL autoassinado
- ✅ TLS habilitado (portas 25 e 587)
- ✅ Autenticação SASL via Dovecot
- ✅ Envio de emails funcional

### Dovecot
- ✅ Instalação e configuração
- ✅ Maildir habilitado
- ✅ SASL para Postfix
- ✅ IMAP/POP3 com TLS
- ✅ Certificado SSL autoassinado

### Testes
- ✅ Envio de email via CLI
- ✅ Teste SMTP/TLS via openssl s_client
- ✅ Teste IMAP/POP3 via openssl
- ✅ Verificação de Maildir

## Documentação Completa

Para documentação detalhada sobre configuração, testes manuais e troubleshooting, consulte [CONFIGURACAO.md](CONFIGURACAO.md).

## Estrutura do Projeto

```
trabalho-redes/
├── Vagrantfile                  # Configuração da VM
├── README.md                    # Este arquivo
├── CONFIGURACAO.md              # Documentação detalhada
└── scripts/
    ├── setup.sh                 # Script principal de provisionamento
    ├── configure_postfix.sh     # Configuração do Postfix
    ├── configure_dovecot.sh     # Configuração do Dovecot
    └── test_email.sh            # Script de testes
```

## Portas Configuradas

- **25**: SMTP (com STARTTLS)
- **587**: SMTP Submission (TLS obrigatório)
- **110**: POP3 (com STARTTLS)
- **143**: IMAP (com STARTTLS)
- **993**: IMAPS (IMAP sobre SSL)
- **995**: POP3S (POP3 sobre SSL)

## Configurar Thunderbird

1. Abra o Thunderbird
2. Adicione uma nova conta:
   - **Email**: aluno1@email.local
   - **Senha**: 123456
3. O Thunderbird deve detectar automaticamente as configurações
4. Se necessário, configure manualmente:
   - **IMAP**: 192.168.56.10:993 (SSL/TLS)
   - **SMTP**: 192.168.56.10:587 (STARTTLS)

## Verificar Status

```bash
# Status dos serviços
systemctl status postfix
systemctl status dovecot

# Verificar portas
netstat -tlnp | grep -E ':(25|587|110|143|993|995)'

# Verificar logs
tail -f /var/log/mail.log
tail -f /var/log/dovecot.log
```