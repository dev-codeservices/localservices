# Contribuindo

Obrigado por querer contribuir com o LocalServices!

## Como contribuir

1. Faça um fork do repositório
2. Crie um branch descritivo: `git checkout -b feat/novo-servico` ou `fix/corrige-setup-mysql`
3. Commit com mensagens claras (veja a convenção abaixo)
4. Abra um Pull Request descrevendo o que foi feito e por quê

## Convenção de commits

Use o formato [Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```
feat: adiciona suporte ao MongoDB
fix: corrige criação de schema no PostgreSQL quando nome tem hífen
docs: atualiza exemplos de conexão no README
chore: atualiza versão do Temporal para 1.25.0
```

## Adicionando um novo serviço Docker

- Adicione o serviço em `docker-compose.yml`
- Crie os arquivos `envs/<servico>.env.example` e `envs/<servico>.env.example`
- Se precisar de inicialização, adicione em `init-<servico>/` e um script em `scripts/`
- Os scripts devem ser **idempotentes** — podem rodar múltiplas vezes sem efeitos colaterais
- Atualize o README com a porta, configuração e como conectar

## Padrões de código (shell)

- Scripts Bash devem começar com `#!/usr/bin/env bash`
- Use `set -euo pipefail` no início de cada script
- Prefira variáveis com nomes em `UPPER_SNAKE_CASE`
- Valide variáveis de ambiente obrigatórias antes de usá-las
- Scripts de inicialização devem logar o que estão fazendo (`echo "[serviço] mensagem"`)

## Reportando bugs

Use o template de issue disponível em `.github/ISSUE_TEMPLATE/bug_report.md`.

## Atualizando o CHANGELOG

Ao abrir um PR, adicione uma linha na seção `[Unreleased]` do `CHANGELOG.md` descrevendo a mudança.
