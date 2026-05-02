# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.2] - 2026-05-01

### Corrigido

- PostgreSQL: tabelas criadas pelo usuário admin (ex: via DBVear) agora ficam acessíveis ao app user do serviço — adicionados `GRANT ALL PRIVILEGES ON ALL TABLES/SEQUENCES` e `ALTER DEFAULT PRIVILEGES` no `pg-setup.sh`
- `ALTER DEFAULT PRIVILEGES FOR ROLE <admin>` garante que objetos criados pelo admin no futuro também sejam automaticamente acessíveis ao app user, sem necessidade de re-execução manual do script

## [1.0.1] - 2026-05-01

### Alterado

- PostgreSQL: isolamento migrado de schema (banco único `localservices`) para banco de dados separado por serviço — alinha com o modelo já adotado pelo MySQL
- `PG_APP_SERVICES`: terceiro campo renomeado de `schema` para `database`; semântica mantida (padrão = nome do usuário quando omitido)
- Removida a variável `PG_APP_DB` do `docker-compose.yml` e dos arquivos de env

### Removido

- Schema `public` compartilhado implícito — cada serviço passa a ter seu próprio banco isolado

## [1.0.0] - 2026-05-01

### Adicionado

- PostgreSQL 15 com isolamento por schema
- Redis 7 com autenticação por senha
- MySQL 8 com isolamento por banco de dados
- Temporal 1.24.2 com suporte a múltiplos namespaces
- Temporal UI 2.30.3 na porta 8081
- Scripts idempotentes de inicialização para PostgreSQL e MySQL
- Script `setup-env.sh` para geração do `.env` raiz a partir de `envs/`
- Arquivos `.env.example` como templates de configuração
- Suporte a múltiplos serviços por banco via variáveis de ambiente
- Rede Docker compartilhada `local-services-network` para integração entre projetos

[1.0.2]: https://github.com/DevCodeServices/LocalServices/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/DevCodeServices/LocalServices/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/DevCodeServices/LocalServices/releases/tag/v1.0.0
