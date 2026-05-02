# LocalServices

Infraestrutura local compartilhada. Sobe uma única vez e serve a todos os projetos.

## Serviços

| Serviço       | Porta |
|---------------|-------|
| PostgreSQL 15 | 5432  |
| Redis 7       | 6379  |
| Temporal      | 7233  |
| Temporal UI   | 8081  |
| MySQL 8       | 3306  |

## Quick Start

```bash
# 1. Gera os envs a partir dos .example (edite antes de subir)
./scripts/setup-env.sh

# 2. Suba a infra
docker compose up -d
```

Para subir serviços específicos:
```bash
docker compose up -d postgresql redis
```

## Configuração

Cada serviço tem seu próprio arquivo em `envs/`. Edite apenas o que precisar:

| Arquivo                  | O que configura              |
|--------------------------|------------------------------|
| `envs/postgresql.env`    | Admin, bancos, serviços      |
| `envs/redis.env`         | Senha                        |
| `envs/temporal.env`      | Namespaces, retenção         |
| `envs/mysql.env`         | Admin, bancos, serviços      |

Após qualquer edição, regenere o `.env` raiz:
```bash
./scripts/setup-env.sh
```

## Adicionando um novo serviço

### PostgreSQL (banco isolado)

Edite `envs/postgresql.env` e adicione ao `PG_APP_SERVICES`:
```
PG_APP_SERVICES=appexistente||senha||banco;novoapp||senha||novobanco
```
Aplique sem reiniciar o container:
```bash
./scripts/setup-env.sh
docker compose exec postgresql /scripts/pg-setup.sh
```

### MySQL (banco isolado)

Edite `envs/mysql.env` e adicione ao `MYSQL_APP_SERVICES`:
```
MYSQL_APP_SERVICES=appexistente||senha||banco;novoapp||senha||novobanco
```
Aplique sem reiniciar o container:
```bash
./scripts/setup-env.sh
docker compose exec mysql /scripts/mysql-setup.sh
```

### Temporal (namespace)

Edite `envs/temporal.env`:
```
TEMPORAL_NAMESPACES=namespace-existente,novo-namespace
```
Aplique:
```bash
./scripts/setup-env.sh
docker compose restart temporal-init
```

## Formato de serviços

```
user||password||database
```

| Campo    | Separador | Obrigatório |
|----------|-----------|-------------|
| user     | `\|\|`    | sim         |
| password | `\|\|`    | sim         |
| database | —         | não (padrão: nome do usuário) |

Múltiplos serviços: separados por `;`

## Isolamento

**PostgreSQL** — banco separado por serviço. Cada usuário é dono do seu banco e não tem acesso aos demais.

**MySQL** — banco separado por serviço. Cada usuário tem `GRANT` apenas no seu banco.

**Redis** — senha única compartilhada (sem isolamento por usuário).

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para diretrizes de contribuição.

## Segurança

Leia [SECURITY.md](SECURITY.md) antes de reportar vulnerabilidades.

## Changelog

Veja [CHANGELOG.md](CHANGELOG.md) para o histórico de mudanças.

## Licença

[MIT](LICENSE)

## Conectando uma aplicação

```env
# PostgreSQL
DATABASE_URL=postgresql://<user>:<password>@localhost:5432/<database>

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<REDIS_PASSWORD>

# Temporal
TEMPORAL_HOST=localhost:7233
```
