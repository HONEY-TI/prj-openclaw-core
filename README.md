# 🛠️ Manutenção dos Remotes Git

Esta seção reúne comandos úteis para reconfigurar os remotes caso seja necessário migrar repositórios, corrigir URLs ou recuperar configurações.

---

# 🔍 Verificar a configuração atual

Exibe todas as URLs configuradas para cada remote.

```bash
git remote -v
```

Exibe informações detalhadas do remote `origin`.

```bash
git remote show origin
```

---

# 🔎 Listar apenas as URLs

```bash
git config --get remote.origin.url
git config --get remote.origin.pushurl
```

Caso `pushurl` não exista, significa que o Git utiliza a mesma URL para `fetch` e `push`.

---

# ♻️ Reconfigurar completamente o remote `origin`

Quando houver incompatibilidade ou dúvida sobre a configuração atual.

## 1. Remover o remote

```bash
git remote remove origin
```

## 2. Adicionar novamente

```bash
git remote add origin git@gitlab.com:alexfariakof/prj-openclaw-core.git
```

## 3. Configurar o Push

```bash
git remote set-url --push origin git@github.com:alexribeirofaria/prj-openclaw-core.git
```

---

# 🔄 Alterar somente a URL de Fetch

```bash
git remote set-url origin git@gitlab.com:alexfariakof/prj-openclaw-core.git
```

---

# 🚀 Alterar somente a URL de Push

```bash
git remote set-url --push origin git@github.com:alexribeirofaria/prj-openclaw-core.git
```

---

# ❌ Remover a URL exclusiva de Push

Caso deseje utilizar a mesma URL para `fetch` e `push`.

```bash
git remote set-url --delete --push origin git@github.com:alexribeirofaria/prj-openclaw-core.git
```

ou

```bash
git config --unset-all remote.origin.pushurl
```

Após isso, o Git utilizará automaticamente a URL configurada em `remote.origin.url`.

---

# ➕ Adicionar múltiplos destinos de Push

É possível enviar para mais de um repositório com um único `git push`.

```bash
git remote set-url --add --push origin git@github.com:alexribeirofaria/prj-openclaw-core.git

git remote set-url --add --push origin git@gitlab.com:alexfariakof/prj-openclaw-core.git
```

Resultado:

```text
origin (fetch) -> GitLab

git push
 ├── GitHub
 └── GitLab
```

---

# 🗑️ Remover uma URL específica de Push

```bash
git remote set-url --delete --push origin git@gitlab.com:alexfariakof/prj-openclaw-core.git
```

---

# ➕ Criar um novo remote

Caso seja necessário manter um segundo servidor.

```bash
git remote add backup git@github.com:alexribeirofaria/prj-openclaw-core.git
```

Verificar:

```bash
git remote -v
```

---

# ❌ Remover um remote

```bash
git remote remove backup
```

---

# 🔁 Renomear um remote

```bash
git remote rename origin gitlab

git remote rename gitlab origin
```

---

# 🔐 Validar acesso SSH

Verifica se a autenticação SSH está funcionando.

GitHub:

```bash
ssh -T git@github.com
```

GitLab:

```bash
ssh -T git@gitlab.com
```

---

# 🔑 Verificar qual chave SSH está sendo utilizada

```bash
ssh-add -l
```

Caso não exista nenhuma chave carregada:

```bash
ssh-add ~/.ssh/id_ed25519
```

---

# 🌐 Migrar de HTTPS para SSH

Visualizar a URL atual.

```bash
git remote -v
```

Alterar.

```bash
git remote set-url origin git@gitlab.com:alexfariakof/prj-openclaw-core.git
```

---

# 🧹 Remover referências obsoletas

Após exclusão de branches remotas.

```bash
git remote prune origin
```

ou

```bash
git fetch --prune
```

---

# 📦 Buscar todas as alterações

```bash
git fetch --all
```

---

# 🔄 Atualizar todas as referências

```bash
git fetch --all --prune
```

---

# 🧪 Diagnóstico completo

```bash
git remote -v

git remote show origin

git branch -vv

git status

git config --list | grep remote
```

---

# 🚨 Problemas comuns

## ❌ Remote já existe

```text
error: remote origin already exists
```

Solução:

```bash
git remote remove origin
```

ou

```bash
git remote set-url origin <nova-url>
```

---

## ❌ Permissão negada (SSH)

```text
Permission denied (publickey)
```

Verificar:

```bash
ssh -T git@github.com

ssh -T git@gitlab.com
```

---

## ❌ Repositório não encontrado

```text
Repository not found
```

Verifique:

* Nome do repositório.
* Organização ou usuário.
* Permissões de acesso.
* URL configurada no remote.

---

## ❌ Push rejeitado

```text
Updates were rejected
```

Atualize a branch local antes de enviar.

```bash
git fetch

git pull --rebase

git push
```

---

# ✅ Estado final recomendado

```text
origin
├── Fetch → git@gitlab.com:alexfariakof/prj-openclaw-core.git
└── Push  → git@github.com:alexribeirofaria/prj-openclaw-core.git
```

Esse modelo facilita migrações entre plataformas, reduz a necessidade de múltiplos remotes e simplifica a manutenção do projeto.
