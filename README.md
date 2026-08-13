# Carteiras

Aplicação Rails de uso pessoal ou compartilhado para acompanhar investidores, carteiras e contas em múltiplas moedas. O domínio suporta compras e vendas long-only, notas com várias negociações, saldos iniciais documentados, transferências de custódia, eventos corporativos, proventos, caixa, posições históricas, resultados econômicos e rentabilidade TWR. Notas e extratos XP/Avenue podem ser analisados sem armazenar os arquivos e sempre geram rascunhos para revisão.

Consulte [CONTEXT.md](CONTEXT.md) para a linguagem e as interfaces do domínio e [ADR 001](docs/adr/001-redesenho-big-bang.md) para as decisões do redesenho.

## Dev Container

O Dev Container é o ambiente canônico. Ele inclui Ruby 4.0.5, Rails 8.1, PostgreSQL 18.4, Chromium/Chromedriver e `pdftotext` (Poppler). PostgreSQL roda exclusivamente no serviço Compose `db`.

```sh
docker compose -f .devcontainer/docker-compose.yml up -d --build
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails db:prepare
docker compose -f .devcontainer/docker-compose.yml exec -T app env RAILS_ENV=test bin/rails db:prepare
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails zeitwerk:check
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails test
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails test:system
```

A aplicação fica disponível em `http://localhost:3001` quando o servidor Rails é iniciado no container.

## Cotações automáticas

As cotações dos ativos B3 são obtidas pela brapi.dev no plano gratuito, uma vez por dia útil às 21h no fuso de Brasília. O ticker enviado é o próprio `codigo` do ativo.

Configure o token no backend pela variável `BRAPI_API_TOKEN` ou pela credencial Rails `brapi.api_token`. O token nunca deve ser enviado ao navegador ou incluído no repositório.
