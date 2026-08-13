# ADR 001 — Redesenho Big Bang do domínio financeiro

## Status

Aceito em 2026-08-13.

## Decisão

Substituir o domínio anterior sem migração ou compatibilidade de dados. Espaço é o limite de acesso, os catálogos são globais, transações confirmadas são fatos tipados imutáveis e o escopo é long-only com custo médio.

O banco primário possui 24 tabelas funcionais. Às 20 tabelas do redesenho foram acrescentadas as tabelas tipadas `saldos_iniciais`, `transferencias_custodia` e `eventos_corporativos`, além do registro operacional `importacoes_financeiras`. `posicoes_atuais` é reconstruível e a única projeção persistida. Posição histórica, resultados realizados e TWR são calculados sob demanda. Lançamentos de caixa constituem o livro canônico derivado das transações.

Os novos fatos de posição continuam sob a interface única `TransacoesFinanceiras`; importadores nunca escrevem fatos ou projeções diretamente. `ImportacoesFinanceiras` é o seam persistente para adapters de documentos externos, preservando idempotência e revisão humana sem armazenar os arquivos de origem.

As três interfaces externas são `TransacoesFinanceiras`, `ConsultasFinanceiras` e `Mercado`. A brapi.dev é a única integração automática de preço, atende ativos B3 pelo código canônico e fica atrás de uma dependência HTTP interna testável.

Competências futuras podem permanecer em rascunho, mas a confirmação só ocorre na data econômica. A escolha evita antecipar posição e caixa e mantém as consultas sem efeitos colaterais, sem introduzir outra projeção ou um job de virada de competência.

## Consequências

Os dados anteriores são descartados no corte. Não existem importadores do legado, dual-write, flags, cache de rentabilidade, tributação real, metas de alocação, eventos corporativos, posições vendidas ou transferências de custódia. O rollback operacional é restaurar o backup integral anterior ao corte.
