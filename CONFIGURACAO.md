# Configuração do Servidor de Email

Este documento descreve a configuração completa do servidor de email interno usando Debian, Postfix, Dovecot, Thunderbird e OpenSSL.

## Visão Geral

O servidor de email foi configurado com as seguintes características:

- **Sistema Operacional**: Debian Bookworm
- **Servidor SMTP**: Postfix
- **Servidor IMAP/POP3**: Dovecot
- **Cliente de Email**: Thunderbird
- **Certificados**: SSL/TLS autoassinados
- **Formato de Mailbox**: Maildir

## Estrutura do Projeto

```
trabalho-redes/
├── Vagrantfile              # Configuração da VM
├── scripts/
│   ├── setup.sh             # Script principal de provisionamento
│   ├── configure_postfix.sh # Configuração do Postfix
│   ├── configure_dovecot.sh # Configuração do Dovecot
│   └── test_email.sh        # Script de testes
└── CONFIGURACAO.md          # Esta documentação
```

## Configurações Implementadas

### 1. Postfix (SMTP)

#### Instalação e Configuração Básica
- **Hostname**: `servidor-email.email.local`
- **Domínio**: `email.local`
- **IP**: `192.168.56.10`

#### Certificado SSL
- Certificado autoassinado criado em `/etc/postfix/ssl/`
- Válido por 10 anos
- Chave RSA 2048 bits

#### TLS/SSL
- TLS habilitado na porta 25 (SMTP)
- TLS obrigatório na porta 587 (SMTP Submission)
- Protocolos suportados: TLSv1.2, TLSv1.3
- Cifras de alta segurança

#### Autenticação SASL
- Integração com Dovecot para autenticação
- Socket em `/var/spool/postfix/private/auth`
- Autenticação obrigatória na porta 587

#### Portas
- **25**: SMTP (com suporte a STARTTLS)
- **587**: SMTP Submission (TLS obrigatório, autenticação obrigatória)

#### Configurações de Segurança
- Restrições de HELO
- Restrições de cliente (RBL)
- Restrições de remetente e destinatário
- Rejeição de domínios não-FQDN

### 2. Dovecot (IMAP/POP3)

#### Instalação e Configuração Básica
- Protocolos habilitados: IMAP, POP3, LMTP
- Formato de mailbox: Maildir (`~/Maildir`)

#### Certificado SSL
- Certificado autoassinado criado em `/etc/dovecot/ssl/`
- Válido por 10 anos
- Chave RSA 2048 bits

#### TLS/SSL
- TLS obrigatório para todas as conexões
- Protocolos suportados: TLSv1.2, TLSv1.3
- Cifras de alta segurança

#### Autenticação
- Mecanismos: PLAIN, LOGIN
- Integração com PAM
- Autenticação via sistema de usuários do Linux

#### SASL para Postfix
- Socket em `/var/spool/postfix/private/auth`
- Permite autenticação SMTP via Dovecot

#### Portas
- **110**: POP3 (com suporte a STARTTLS)
- **143**: IMAP (com suporte a STARTTLS)
- **993**: IMAPS (IMAP sobre SSL)
- **995**: POP3S (POP3 sobre SSL)

#### Maildir
- Estrutura criada automaticamente para novos usuários
- Pastas padrão: Inbox, Sent, Drafts, Trash, Junk

### 3. Usuários de Teste

Dois usuários foram criados para testes:

- **aluno1@email.local** (senha: 123456)
- **aluno2@email.local** (senha: 123456)

## Como Usar

### 1. Provisionar a VM

```bash
vagrant up
```

Este comando irá:
1. Criar a VM Debian
2. Instalar todos os pacotes necessários
3. Configurar Postfix
4. Configurar Dovecot
5. Executar testes iniciais

### 2. Acessar a VM

```bash
vagrant ssh
```

### 3. Executar Testes

Dentro da VM, execute:

```bash
/vagrant/scripts/test_email.sh
```

## Testes Manuais

### 1. Testar Envio de Email via CLI

```bash
echo "Teste de email" | mail -s "Assunto do teste" aluno1@email.local
```

Verificar se o email chegou:

```bash
ls -la /home/aluno1/Maildir/new/
```

### 2. Testar SMTP/TLS na porta 25

```bash
openssl s_client -connect 192.168.56.10:25 -starttls smtp
```

Comandos para testar:
```
EHLO servidor-email.email.local
MAIL FROM: aluno1@email.local
RCPT TO: aluno2@email.local
DATA
Assunto: Teste SMTP
Este é um teste de envio via SMTP.
.
QUIT
```

### 3. Testar SMTP Submission/TLS na porta 587

```bash
openssl s_client -connect 192.168.56.10:587 -starttls smtp
```

Comandos para testar (com autenticação):
```
EHLO servidor-email.email.local
AUTH PLAIN <base64(username:password)>
MAIL FROM: aluno1@email.local
RCPT TO: aluno2@email.local
DATA
Assunto: Teste SMTP Submission
Este é um teste de envio via SMTP Submission.
.
QUIT
```

Para gerar o base64 do usuário e senha:
```bash
echo -ne '\000aluno1\000123456' | base64
```

### 4. Testar IMAP/TLS na porta 143

```bash
openssl s_client -connect 192.168.56.10:143 -starttls imap
```

Comandos para testar:
```
a1 LOGIN aluno1 123456
a2 LIST "" "*"
a3 SELECT INBOX
a4 FETCH 1 BODY[]
a5 LOGOUT
```

### 5. Testar IMAPS na porta 993

```bash
openssl s_client -connect 192.168.56.10:993
```

Comandos para testar:
```
a1 LOGIN aluno1 123456
a2 LIST "" "*"
a3 SELECT INBOX
a4 FETCH 1 BODY[]
a5 LOGOUT
```

### 6. Testar POP3/TLS na porta 110

```bash
openssl s_client -connect 192.168.56.10:110 -starttls pop3
```

Comandos para testar:
```
USER aluno1
PASS 123456
STAT
LIST
RETR 1
QUIT
```

### 7. Testar POP3S na porta 995

```bash
openssl s_client -connect 192.168.56.10:995
```

Comandos para testar:
```
USER aluno1
PASS 123456
STAT
LIST
RETR 1
QUIT
```

## Configurar Thunderbird

### 1. Adicionar Conta

1. Abra o Thunderbird
2. Menu: `Editar` → `Configurações da Conta`
3. Clique em `Adicionar Conta de Email`
4. Preencha:
   - **Nome**: Aluno 1
   - **Email**: aluno1@email.local
   - **Senha**: 123456

### 2. Configuração Manual (se necessário)

Se a configuração automática não funcionar:

#### Servidor de Entrada (IMAP)
- **Tipo**: IMAP
- **Servidor**: 192.168.56.10
- **Porta**: 993
- **SSL/TLS**: SSL/TLS
- **Autenticação**: Senha normal

#### Servidor de Saída (SMTP)
- **Servidor**: 192.168.56.10
- **Porta**: 587
- **SSL/TLS**: STARTTLS
- **Autenticação**: Senha normal
- **Usuário**: aluno1@email.local

### 3. Aceitar Certificado Autoassinado

Quando o Thunderbird avisar sobre o certificado autoassinado:
1. Clique em `Examinar Certificado`
2. Clique em `Confirmar Exceção de Segurança`
3. Marque `Confiar neste CA para identificar este site`
4. Clique em `Confirmar Exceção de Segurança`

## Verificar Logs

### Logs do Postfix

```bash
tail -f /var/log/mail.log
```

### Logs do Dovecot

```bash
tail -f /var/log/dovecot.log
```

### Logs detalhados do Dovecot

```bash
tail -f /var/log/dovecot-info.log
tail -f /var/log/dovecot-debug.log
```

## Verificar Status dos Serviços

### Postfix

```bash
systemctl status postfix
systemctl restart postfix
```

### Dovecot

```bash
systemctl status dovecot
systemctl restart dovecot
```

## Verificar Portas

```bash
netstat -tlnp | grep -E ':(25|587|110|143|993|995)'
# ou
ss -tlnp | grep -E ':(25|587|110|143|993|995)'
```

## Estrutura do Maildir

Cada usuário tem a seguinte estrutura:

```
~/Maildir/
├── cur/          # Emails lidos
├── new/          # Novos emails
└── tmp/          # Emails temporários
```

## Troubleshooting

### Postfix não inicia

1. Verificar configuração:
   ```bash
   postfix check
   ```

2. Verificar logs:
   ```bash
   tail -n 50 /var/log/mail.log
   ```

3. Verificar permissões do certificado:
   ```bash
   ls -la /etc/postfix/ssl/
   ```

### Dovecot não inicia

1. Verificar configuração:
   ```bash
   dovecot -n
   ```

2. Verificar logs:
   ```bash
   tail -n 50 /var/log/dovecot.log
   ```

3. Verificar permissões do certificado:
   ```bash
   ls -la /etc/dovecot/ssl/
   ```

### Emails não chegam

1. Verificar se o Maildir existe:
   ```bash
   ls -la /home/aluno1/Maildir/
   ```

2. Verificar logs do Postfix:
   ```bash
   grep "aluno1" /var/log/mail.log
   ```

3. Verificar se o Dovecot está recebendo via LMTP:
   ```bash
   grep "lmtp" /var/log/mail.log
   ```

### Autenticação não funciona

1. Verificar socket do SASL:
   ```bash
   ls -la /var/spool/postfix/private/auth
   ```

2. Verificar permissões:
   ```bash
   ls -la /var/spool/postfix/private/
   ```

3. Testar autenticação manualmente:
   ```bash
   telnet localhost 25
   EHLO localhost
   AUTH PLAIN <base64>
   ```

## Segurança

### Certificados Autoassinados

Os certificados são autoassinados, o que significa que:
- São válidos para testes e ambientes internos
- Navegadores e clientes de email mostrarão avisos de segurança
- Para produção, use certificados assinados por uma CA confiável (Let's Encrypt, etc.)

### Firewall

O UFW está configurado para permitir apenas as portas necessárias:
- 22 (SSH)
- 25 (SMTP)
- 587 (SMTP Submission)
- 110 (POP3)
- 143 (IMAP)
- 993 (IMAPS)
- 995 (POP3S)

### Senhas

As senhas dos usuários de teste são fracas (123456). Em produção:
- Use senhas fortes
- Considere usar autenticação de dois fatores
- Implemente políticas de senha

## Próximos Passos

Para um ambiente de produção, considere:

1. **Certificados SSL**: Use Let's Encrypt ou outra CA confiável
2. **SPF/DKIM/DMARC**: Configure registros DNS para autenticação de email
3. **Antispam**: Instale e configure SpamAssassin ou similar
4. **Antivírus**: Instale e configure ClamAV
5. **Webmail**: Instale Roundcube ou similar para acesso web
6. **Backup**: Configure backup regular dos Maildirs
7. **Monitoramento**: Configure monitoramento dos serviços

## Referências

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Dovecot Documentation](https://doc.dovecot.org/)
- [Thunderbird Documentation](https://support.mozilla.org/thunderbird)

