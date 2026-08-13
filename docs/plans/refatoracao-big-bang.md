# Refatoração BIG BANG do domínio financeiro

**Status:** especificação fechada para implementação. Quem executar este plano deve tratar as decisões abaixo como requisitos, não reabrir o desenho durante a implementação e registrar qualquer impedimento real antes de ampliar o escopo.

## 1. Resumo e linguagem de domínio

Substituir integralmente o schema e a implementação atuais por um novo baseline, sem migração de dados, compatibilidade temporária, dual-write ou feature flags. Manter Rails, PostgreSQL, Devise, Pundit, Solid Queue e o monólito.

O núcleo funcional incluirá:

- múltiplos espaços e usuários;
- múltiplos investidores, carteiras e contas;
- compras e vendas long-only;
- notas de negociação com várias operações;
- proventos;
- aportes, resgates, transferências e câmbio;
- múltiplas moedas;
- posições atuais e históricas;
- resultados econômicos realizados;
- cotações canônicas;
- rentabilidade TWR.

Adotar no `CONTEXT.md`:

- **Espaço:** contêiner de acesso e isolamento de dados.
- **Usuário:** identidade autenticável.
- **Membro:** vínculo entre usuário e espaço.
- **Investidor:** titular econômico das contas.
- **Carteira:** agrupamento exclusivo de contas para acompanhamento e rentabilidade.
- **Conta de investimento:** conta de custódia mantida em uma instituição.
- **Conta de caixa:** saldo de uma moeda dentro da conta de investimento.
- **Ativo:** item global negociável ou investível.
- **Transação financeira:** fato financeiro que começa como rascunho e se torna imutável após confirmação.
- **Lançamento de caixa:** efeito monetário assinado de uma transação.
- **Posição:** estado reconstruível de quantidade e custo de um ativo em uma conta.
- **Projeção:** dado derivado que pode ser integralmente reconstruído.

Remover dos textos, código e interface os termos `família`, `familiar` e `family`, substituindo-os por “espaço”, “compartilhado” ou “uso pessoal”, conforme o contexto.

## 2. Novo modelo de dados

### Convenções do baseline

O banco primário terminará com **20 tabelas funcionais da aplicação**, além de `schema_migrations` e `ar_internal_metadata`, que são metadados do Rails. As tabelas internas do Solid Queue permanecem no banco de fila e não entram nessa contagem. A lista abaixo é definitiva; não criar tabelas auxiliares, de auditoria, cache ou junção que não estejam nela.

- Todas as tabelas usam `id:bigint`, `created_at` e `updated_at`; esses campos são omitidos do inventário abaixo.
- Todo campo listado é `NOT NULL`, exceto quando marcado como opcional. Strings obrigatórias são normalizadas com `strip`; strings opcionais vazias viram `NULL`.
- Enums de domínio são strings protegidas por `CHECK`, não enums nativos do PostgreSQL nem inteiros do Rails.
- Quantidades usam `numeric(30,10)`, valores e preços `numeric(30,12)` e taxas `numeric(24,12)`. Entradas HTTP chegam como strings decimais e são convertidas para `BigDecimal`; `Float` é rejeitado nas interfaces financeiras.
- Datas econômicas usam `date`; auditoria usa `timestamp`. Armazenar timestamps em UTC e apresentá-los no fuso configurado pela aplicação.
- FKs usam `ON DELETE RESTRICT`. Excluir um rascunho significa apagar seus itens e detalhe tipado explicitamente, dentro de uma transação, e só então apagar a transação. Linhas confirmadas, cadastros referenciados e lançamentos nunca são apagados.
- `dependent: :destroy` fica restrito a detalhes de rascunhos. Não usar `dependent: :destroy` em fatos confirmados, catálogos, espaços, investidores, carteiras ou contas.
- Checks do banco cobrem enumerações, positividade, pares de campos e estados estruturais. Regras que atravessam tabelas ficam no módulo financeiro e em testes; não criar triggers.

### Inventário definitivo das 20 tabelas

| # | Tabela | Colunas de domínio |
|---|---|---|
| 1 | `users` | `email:string` default `""`, `encrypted_password:string` default `""`, `reset_password_token:string?`, `reset_password_sent_at:datetime?`, `remember_created_at:datetime?`, `sign_in_count:integer` default `0`, `current_sign_in_at:datetime?`, `last_sign_in_at:datetime?`, `current_sign_in_ip:string?`, `last_sign_in_ip:string?`, `failed_attempts:integer` default `0`, `unlock_token:string?`, `locked_at:datetime?`, `administrador_sistema:boolean` default `false`. |
| 2 | `espacos` | `nome:string`, `arquivado_em:datetime?`. |
| 3 | `membros_espaco` | `espaco_id`, `user_id`, `papel:string`. |
| 4 | `investidores` | `espaco_id`, `nome:string`, `arquivado_em:datetime?`. |
| 5 | `carteiras` | `investidor_id`, `nome:string`, `moeda_base_id`, `arquivado_em:datetime?`. |
| 6 | `contas_investimento` | `carteira_id`, `instituicao_id`, `nome:string`, `identificador_externo:string?`, `arquivado_em:datetime?`. |
| 7 | `contas_caixa` | `conta_investimento_id`, `moeda_id`, `arquivado_em:datetime?`. |
| 8 | `moedas` | `codigo:string(3)`, `nome:string`, `casas_decimais:integer` com default `2`, `arquivado_em:datetime?`. |
| 9 | `instituicoes` | `nome:string`, `arquivado_em:datetime?`. |
| 10 | `ativos` | `codigo:string`, `mercado:string`, `descricao:string?`, `tipo:string`, `moeda_negociacao_id`, `simbolo_yahoo:string?`, `cnpj:string?`, `arquivado_em:datetime?`. |
| 11 | `fontes_cotacao` | `codigo:string`, `nome:string`, `arquivado_em:datetime?`. |
| 12 | `transacoes_financeiras` | `investidor_id`, `tipo:string`, `origem:string`, `data_competencia:date`, `ordem_na_data:integer?`, `estado:string` com default `rascunho`, `criado_por_id`, `confirmado_por_id?`, `observacao:text?`, `confirmada_em:datetime?`, `chave_idempotencia:string?`, `transacao_revertida_id?`. |
| 13 | `notas_negociacao` | `transacao_financeira_id`, `conta_caixa_id`, `data_negociacao:date`, `data_liquidacao:date`, `custo_operacional_total:numeric(30,12)` com default `0`, `taxa_conversao_base:numeric(24,12)` com default `1`. |
| 14 | `negociacoes` | `nota_negociacao_id`, `ordem:integer`, `ativo_id`, `natureza:string`, `quantidade:numeric(30,10)`, `preco_unitario:numeric(30,12)`, `custo_alocado:numeric(30,12)`. |
| 15 | `proventos` | `transacao_financeira_id`, `conta_caixa_id`, `ativo_id`, `tipo:string`, `data_base:date`, `data_pagamento:date`, `quantidade_referencia:numeric(30,10)`, `valor_bruto:numeric(30,12)`, `retencoes:numeric(30,12)` com default `0`, `valor_liquido:numeric(30,12)`, `taxa_conversao_base:numeric(24,12)` com default `1`. |
| 16 | `movimentacoes_caixa` | `transacao_financeira_id`, `tipo:string`, `conta_caixa_origem_id?`, `conta_caixa_destino_id?`, `valor_origem:numeric(30,12)?`, `valor_destino:numeric(30,12)?`, `data_efetiva:date`. |
| 17 | `lancamentos_caixa` | `transacao_financeira_id`, `ordem:integer`, `conta_caixa_id`, `data_efetiva:date`, `natureza:string`, `valor:numeric(30,12)`, `lancamento_original_id?`. |
| 18 | `posicoes_atuais` | `conta_investimento_id`, `ativo_id`, `quantidade:numeric(30,10)`, `custo_total_local:numeric(30,12)`, `custo_total_base:numeric(30,12)`, `ultima_transacao_id`. |
| 19 | `cotacoes_ativos` | `ativo_id`, `data:date`, `preco:numeric(30,12)`, `fonte_cotacao_id`, `manual:boolean` com default `false`, `autor_id?`. |
| 20 | `cotacoes_cambio` | `moeda_origem_id`, `moeda_destino_id`, `data:date`, `taxa:numeric(24,12)`, `fonte_cotacao_id`, `autor_id`. |

Enums definitivos:

- `membros_espaco.papel`: `administrador|editor|leitor`;
- `ativos.tipo`: `acao|fii|fundo|etf|renda_fixa|criptoativo|outro`;
- `transacoes_financeiras.tipo`: `nota_negociacao|provento|movimentacao_caixa|reversao`;
- `transacoes_financeiras.origem`: `manual|sistema`;
- `transacoes_financeiras.estado`: `rascunho|confirmada`;
- `negociacoes.natureza`: `compra|venda`;
- `proventos.tipo`: `dividendo|jcp|rendimento|juros|outro`;
- `movimentacoes_caixa.tipo`: `aporte|resgate|transferencia|cambio`;
- `lancamentos_caixa.natureza`: `liquidacao_nota|provento|aporte|resgate|transferencia_saida|transferencia_entrada|cambio_saida|cambio_entrada`.

Índices e unicidades obrigatórios:

- `users.email`, `users.reset_password_token` e `users.unlock_token` únicos conforme Devise;
- `membros_espaco (espaco_id, user_id)`; `investidores (espaco_id, lower(nome))`; `carteiras (investidor_id, lower(nome))`; `contas_investimento (carteira_id, lower(nome))`; `contas_caixa (conta_investimento_id, moeda_id)`;
- `moedas.codigo`, `instituicoes lower(nome)`, `ativos (codigo, mercado)` e `fontes_cotacao.codigo` únicos; indexar `contas_investimento.identificador_externo`, `ativos.simbolo_yahoo` e `ativos.cnpj` sem exigir unicidade;
- `transacoes_financeiras (investidor_id, chave_idempotencia)` único quando a chave estiver preenchida, `transacao_revertida_id` único quando preenchido e `(investidor_id, data_competencia, ordem_na_data, id)` para replay;
- detalhe tipado único por `transacao_financeira_id`; `negociacoes (nota_negociacao_id, ordem)`; `lancamentos_caixa (transacao_financeira_id, ordem)`; `lancamentos_caixa.lancamento_original_id` único quando preenchido;
- `lancamentos_caixa (conta_caixa_id, data_efetiva, transacao_financeira_id)`; `posicoes_atuais (conta_investimento_id, ativo_id)` único;
- `cotacoes_ativos (ativo_id, data)` e `cotacoes_cambio (moeda_origem_id, moeda_destino_id, data)` únicos.

Normalizações e checks adicionais:

- `moedas.codigo`, `ativos.codigo` e `fontes_cotacao.codigo` são armazenados em maiúsculas; `moedas.codigo` tem exatamente três letras e `casas_decimais` fica entre `0` e `10`.
- `cnpj`, quando informado, armazena somente 14 dígitos. Ele é metadado e não altera regras financeiras.
- Nomes únicos ignoram caixa conforme os índices `lower(nome)`; código e mercado do ativo são normalizados para maiúsculas.
- `posicoes_atuais` contém apenas quantidades estritamente positivas; uma zeragem remove a linha da projeção.
- `fontes_cotacao` recebe nos seeds os códigos estáveis `MANUAL` e `YAHOO`. Não armazenar prioridade ou lista de tipos atendidos.
- Depois da primeira referência, `moedas.codigo` e `fontes_cotacao.codigo` tornam-se imutáveis; nomes continuam editáveis. A instituição pode ser renomeada porque sua identidade é o ID e o nome não participa de cálculos.

### Acesso e propriedade

- `users`: manter campos Devise; substituir `role` por `administrador_sistema:boolean`.
- `espacos`: nome, timestamps e `arquivado_em`.
- `membros_espaco`: espaço, usuário e papel `administrador|editor|leitor`; unicidade por espaço/usuário. Fixar o model como `MembroEspaco` com `self.table_name = "membros_espaco"`, sem depender da inflexão automática.
- `investidores`: espaço, nome e `arquivado_em`; sem `user_id` e sem moeda fiscal.
- `carteiras`: investidor, nome, moeda-base e `arquivado_em`; nome único por investidor.
- `contas_investimento`: carteira, instituição global, nome, identificador externo informativo/indexado e `arquivado_em`; nome único por carteira, sem unicidade global do identificador externo.
- `contas_caixa`: conta de investimento, moeda e arquivamento; unicidade por conta/moeda.
- Cada conta pertence a exatamente uma carteira. Após possuir transação confirmada, sua carteira não pode ser alterada.

Qualquer usuário autenticado poderá criar um espaço e se tornará seu primeiro administrador. Administradores adicionam usuários já cadastrados por e-mail. Não haverá convite, token ou envio de e-mail nesta versão.

Arquivamento terá semântica uniforme: registros arquivados continuam disponíveis em históricos, somem das opções padrão e não aceitam novos filhos ou fatos. Um espaço arquivado fica somente leitura e pode ser restaurado por seu administrador ou pelo administrador do sistema.

### Catálogos globais

- `moedas`: catálogo global, inicialmente BRL e USD.
- `instituicoes`: instituições financeiras globais.
- `ativos`: catálogo global com código, mercado, descrição, tipo, moeda de negociação, `simbolo_yahoo` opcional, CNPJ opcional e arquivamento.
- `fontes_cotacao`: fontes globais, inicialmente Manual e Yahoo Finance.

Não separar ativo de listagem. A unicidade do ativo será `(codigo, mercado)`. Somente o administrador do sistema altera catálogos globais. Todos os ativos globais não arquivados ficam disponíveis para qualquer espaço por pesquisa, sem seleção, apelido ou arquivamento local.

Após referência por uma transação ou cotação, código, mercado e moeda de negociação do ativo tornam-se imutáveis. Descrição e símbolo de busca continuam editáveis. Da mesma forma, a moeda-base da carteira torna-se imutável após o primeiro fato confirmado; essas restrições evitam reinterpretar históricos.

### Transações financeiras

Criar `transacoes_financeiras` com:

- investidor, derivando o espaço por essa associação; não armazenar `espaco_id` redundante;
- tipo `nota_negociacao|provento|movimentacao_caixa|reversao`;
- origem `manual|sistema`;
- `data_competencia` e `ordem_na_data`;
- estado `rascunho|confirmada`;
- usuário criador, usuário confirmador, observação e `confirmada_em`;
- chave de idempotência opcional, única por investidor;
- `transacao_revertida_id`, única quando preenchida.

O sistema adotará regime de caixa/liquidação, sem contas a pagar ou receber:

- nota: `data_competencia = data_liquidacao`; `data_negociacao` é informativa;
- provento: `data_competencia = data_pagamento`; `data_base` é informativa;
- movimentação de caixa: `data_competencia = data_efetiva`;
- posição, resultado, caixa e TWR reconhecem o fato nessa competência.

Essa escolha evita patrimônio fictício entre negociação e liquidação e evita criar um subsistema de accrual. Histórico e rentabilidade serão explicitamente apresentados como baseados em liquidação/pagamento.

Detalhes tipados:

- `notas_negociacao`: uma por transação, com `conta_caixa_id`, negociação, liquidação, custo operacional total e taxa de conversão para a moeda-base; conta de investimento e moeda são derivadas da conta de caixa.
- `negociacoes`: várias por nota, com ordem, ativo, natureza `compra|venda`, quantidade, preço unitário e custo alocado.
- `proventos`: exatamente um por transação, com `conta_caixa_id`, ativo, tipo, data-base, pagamento, quantidade de referência, bruto, retenções, líquido e taxa para a moeda-base.
- `movimentacoes_caixa`: uma por transação, com tipo `aporte|resgate|transferencia|cambio`, `conta_caixa_origem_id`, `conta_caixa_destino_id`, `valor_origem`, `valor_destino` e data efetiva.
- `lancamentos_caixa`: efeitos assinados gerados na confirmação, com ordem única por transação, conta, data efetiva, natureza, valor não zero e `lancamento_original_id` único quando preenchido para reversões; serão a única fonte do saldo.

#### Contrato dos atributos de entrada

Todos os hashes usam chaves simbólicas, IDs inteiros e valores decimais em string. A camada HTTP faz apenas a tradução de parâmetros; validações e derivações pertencem ao módulo. Atributo desconhecido, campo derivado enviado pelo cliente ou ID fora do escopo produz erro, em vez de ser silenciosamente ignorado.

Campos comuns a todo rascunho: `observacao` opcional e `ordem_na_data` opcional. `investidor`, `tipo`, `origem`, criador e chave de idempotência chegam como argumentos da interface, não dentro de `atributos`. O módulo deriva `data_competencia`; reversão não pode ser criada como rascunho.

| Tipo | `atributos` completo aceito |
|---|---|
| Nota | `{ conta_caixa_id:, data_negociacao:, data_liquidacao:, custo_operacional_total:, taxa_conversao_base:, negociacoes: [{ ativo_id:, natureza:, quantidade:, preco_unitario: }, ...], observacao:?, ordem_na_data:? }` |
| Provento | `{ conta_caixa_id:, ativo_id:, tipo_provento:, data_base:, data_pagamento:, quantidade_referencia:, valor_bruto:, retencoes:, taxa_conversao_base:, observacao:?, ordem_na_data:? }` |
| Aporte | `{ tipo_movimentacao: "aporte", conta_caixa_destino_id:, valor:, data_efetiva:, observacao:?, ordem_na_data:? }` |
| Resgate | `{ tipo_movimentacao: "resgate", conta_caixa_origem_id:, valor:, data_efetiva:, observacao:?, ordem_na_data:? }` |
| Transferência | `{ tipo_movimentacao: "transferencia", conta_caixa_origem_id:, conta_caixa_destino_id:, valor:, data_efetiva:, observacao:?, ordem_na_data:? }` |
| Câmbio | `{ tipo_movimentacao: "cambio", conta_caixa_origem_id:, conta_caixa_destino_id:, valor_origem:, valor_destino:, data_efetiva:, observacao:?, ordem_na_data:? }` |

Na nota, a ordem do array gera `negociacoes.ordem` de `1..N`; o cliente não envia ordem nem custo alocado. No provento, `valor_liquido` é derivado. Na transferência, `valor` preenche origem e destino. Em aporte e resgate, apenas a perna indicada é preenchida. `atualizar_rascunho` e a substituta de `corrigir` recebem o payload completo, substituem o detalhe anterior e não fazem merge parcial.

Regras:

- Cada transação não-reversão possui exatamente um detalhe compatível com seu tipo; reversões não possuem detalhe próprio. O módulo valida essa cardinalidade antes da confirmação.
- Todos os detalhes chegam, por suas contas, ao mesmo investidor e espaço da transação.
- Uma nota opera em uma única conta e moeda, contém ao menos uma negociação e exige `data_negociacao <= data_liquidacao`.
- Conta de caixa da nota pertence à conta de investimento; todo ativo usa a moeda dessa conta; quantidade e preço são positivos; custo total é não negativo.
- O custo total da nota é rateado pelo valor bruto das negociações; arredondar para 12 casas e atribuir o resíduo ao último item em ordem estável. `custo_alocado` é derivado, nunca aceito do usuário, e sua soma deve ser exatamente o custo total.
- A prévia, a confirmação e o replay usam a mesma implementação BigDecimal e a mesma quantização.
- Compra adiciona `bruto + custo_alocado` ao custo médio local e o equivalente convertido ao custo-base.
- Venda encerra apenas posição existente; rejeitar qualquer venda que torne a quantidade negativa. O resultado-base usa o custo-base médio histórico e converte alienação e custo da venda pela taxa persistida na nota, nunca multiplicando o custo local histórico pela taxa atual.
- O lançamento da nota na liquidação será `vendas − compras − custos`.
- A taxa-base significa “unidades da moeda-base da carteira por uma unidade da moeda da nota”; deve ser `1` quando as moedas coincidem e positiva nos demais casos.
- Provento exige `liquido = bruto - retencoes`, valores não negativos, moeda do ativo igual à conta de caixa e a mesma convenção de taxa-base; data-base é apenas informativa e todo efeito é reconhecido no pagamento.
- Aporte usa apenas destino/valor-destino; resgate apenas origem/valor-origem; transferência usa ambos, mesma moeda e valores iguais; câmbio usa ambos, moedas distintas e valores positivos independentes, com spread/custo implícito na relação entre valores.
- Câmbio é restrito a contas da mesma carteira. Transferências podem usar contas de carteiras diferentes do mesmo investidor.
- Transferências podem cruzar carteiras do mesmo investidor. São internas quando as contas pertencem à mesma carteira e fluxos externos opostos para o TWR quando cruzam carteiras.
- Transações entre investidores diferentes são proibidas.
- Saldo de caixa negativo é permitido para suportar históricos incompletos e diferenças de liquidação.
- Rascunhos podem ser editados ou excluídos. Confirmadas e seus detalhes são imutáveis pela interface do módulo, models, policies e ausência de rotas de edição.
- `ordem_na_data` é um inteiro escopado por investidor/data e recebe por padrão `máximo + 1` sob lock do investidor; o usuário pode informá-la no rascunho, inclusive para inserir um fato antes dos já existentes. Replay ordena por `(data_competencia, ordem_na_data, id)`. A ordem não é única no banco para permitir que uma correção reutilize a posição econômica da original; o `id` é o desempate determinístico.
- `negociacoes.ordem` é positiva, única por nota e define a aplicação interna, inclusive quando a mesma nota compra e vende o mesmo ativo.
- Uma confirmada pode ser revertida uma única vez; não se reverte uma reversão. No replay, reversão funciona como tombstone: original e reversão não afetam posições ou resultados, enquanto o caixa recebe linhas opostas exatas ligadas por `lancamento_original_id`.
- A reversão reutiliza competência e ordem da original; seus lançamentos opostos reutilizam as datas efetivas das pernas originais. Alvo, reversão e eventual substituta pertencem sempre ao mesmo investidor.
- Antes de confirmar reversão, correção ou fato retroativo, simular o replay completo das carteiras afetadas e rejeitar atomicamente se o histórico long-only ficar inválido.
- Correção é uma operação atômica que cria reversão e substituta, reutiliza data/ordem da original e valida apenas o estado final. Não persistir uma reversão intermediária que deixe vendas posteriores sem lastro.
- Não haverá visão bitemporal “como conhecido naquela data”.

O ciclo de vida é fechado:

```text
criar rascunho -> atualizar zero ou mais vezes -> excluir OU confirmar
confirmada -> permanecer imutável OU reverter uma vez OU corrigir uma vez
corrigir -> cria, na mesma transação do banco, uma reversão confirmada e uma substituta confirmada
```

`confirmar`, `reverter` e `corrigir` exigem uma confirmada elegível no estado esperado e falham quando repetidos; não tentam adivinhar a intenção. A substituta de uma correção conserva o tipo da original. Para trocar o tipo, o usuário deve reverter a original e criar outra transação explicitamente. Nem reversão nem substituta herdam a chave de idempotência da original.

A idempotência opcional vale apenas para `criar_rascunho`: repetir a mesma chave para o mesmo investidor e tipo devolve o rascunho ou a confirmada já existente sem reaplicar atributos; reutilizá-la com outro tipo produz `ConflitoIdempotencia`. As demais mutações usam estado e locks para impedir duplicação.

Constraints estruturais:

- IDs usam `bigint`; quantidades `numeric(30,10)`; preços e valores `numeric(30,12)`; taxas `numeric(24,12)`.
- FKs de fatos e cadastros referenciados usam `ON DELETE RESTRICT`; checks protegem enums, sinais e coerência de campos opcionais.
- Uma transação confirmada exige `confirmada_em` e ordem; rascunho não produz lançamento, posição ou qualquer outro dado derivado.
- Uma transação confirmada exige também `confirmado_por_id`; um rascunho exige ambos nulos. `ordem_na_data`, quando preenchida, é positiva.
- Reversão aponta para transação confirmada, não revertida, não-reversão e do mesmo investidor; um índice parcial único em `transacao_revertida_id` impede segunda reversão.
- Valores de `movimentacoes_caixa` são positivos quando preenchidos; valores de `lancamentos_caixa` são assinados e não zero.
- A geração de lançamentos é integralmente derivada e idempotente; consultas históricas filtram `data_efetiva <= data_consulta`.

### Projeções econômicas

- `posicoes_atuais`: conta, ativo, quantidade, custo total na moeda do ativo, custo na moeda-base e última transação.
- Caixa atual e histórico continuará sendo `SUM(lancamentos_caixa.valor)`; não criar projeção de saldo.

Somente `posicoes_atuais` será uma projeção persistida. Resultados realizados, posição histórica e rentabilidade serão calculados por replay em lote e retornados como DTOs, sem tabelas próprias, cache ou jobs de invalidação. O projetor puro produz tanto o estado quanto os resultados das vendas; a reconstrução persiste apenas o estado atual.

Para manter uma única implementação correta, toda confirmação, reversão ou correção faz replay completo das transações confirmadas do investidor e substitui todas as suas linhas em `posicoes_atuais` dentro da mesma transação do banco. Não implementar caminho incremental. O volume esperado de uso pessoal torna esse custo aceitável; otimização futura exige medição.

`resultado_realizado` não pertence à posição. Remover moeda fiscal, taxa fiscal e qualquer campo ou mensagem que sugira apuração tributária.

### Cotações canônicas

- `cotacoes_ativos`: ativo, data, preço positivo, fonte, `manual`, autor opcional e timestamps; moeda derivada do ativo; unicidade `(ativo_id, data)`.
- `cotacoes_cambio`: moedas de origem/destino distintas, data, taxa positiva, fonte, autor e timestamps; unicidade `(moeda_origem_id, moeda_destino_id, data)`.

Uma busca automática de preço de ativo cria ou atualiza a linha canônica somente quando ela não estiver marcada como manual. Correção manual atualiza a mesma linha, registra fonte, autor e `manual = true`; substituir esse valor por automação exige ação explícita do administrador do sistema. Não manter revisões, observações rejeitadas ou tabelas de seleção.

Uma cotação de ativo com `manual = true` exige fonte `MANUAL` e autor; uma automática exige fonte `YAHOO` e autor nulo. Ativos sem `simbolo_yahoo` não entram na busca automática. Yahoo fornecerá apenas preços de ativos neste escopo; cotações de câmbio serão sempre manuais, com fonte `MANUAL` e autor.

Leituras usam a cotação exata ou a última anterior e informam data e dias de defasagem. A convenção cambial é `destino = origem * taxa`: procurar primeiro o par direto e, se ausente, aceitar o par inverso usando `1/taxa`; nunca triangular por terceira moeda. A taxa persistida numa nota ou provento é parte do fato e não muda quando a cotação canônica é corrigida.

Como posição histórica, resultados e TWR são calculados sob demanda, uma correção de cotação aparece automaticamente na consulta seguinte e não dispara invalidação ou recálculo.

## 3. Módulos, interfaces e aplicação

### Interfaces externas

Controllers, jobs e testes funcionais atravessam somente três interfaces: `TransacoesFinanceiras`, `ConsultasFinanceiras` e `Mercado`. Projetor, alocador de custos, gerador de lançamentos, replay e cliente Yahoo são implementação interna; não criar classes públicas que apenas repassem argumentos.

#### `TransacoesFinanceiras`

```ruby
TransacoesFinanceiras.prever(tipo:, investidor:, usuario:, atributos:)
TransacoesFinanceiras.criar_rascunho(tipo:, investidor:, usuario:, atributos:, chave_idempotencia: nil)
TransacoesFinanceiras.atualizar_rascunho(transacao:, usuario:, atributos:)
TransacoesFinanceiras.excluir_rascunho(transacao:, usuario:)
TransacoesFinanceiras.confirmar(transacao:, usuario:)
TransacoesFinanceiras.reverter(transacao:, usuario:)
TransacoesFinanceiras.corrigir(transacao:, usuario:, atributos:)
```

`prever` executa normalização, derivações, rateio, geração de lançamentos e simulação long-only sem gravar. Devolve `PreviaTransacao` imutável com `tipo`, `data_competencia`, `ordem_na_data`, `detalhe_normalizado`, `lancamentos`, `liquidacao_liquida` e `posicoes_resultantes`. Confirmação usa a mesma implementação da prévia.

Criação, atualização, confirmação e reversão devolvem a `TransacaoFinanceira` resultante; exclusão devolve `true`; correção devolve `ResultadoCorrecao` imutável com `original`, `reversao` e `substituta`. O módulo:

- autoriza o usuário novamente, mesmo quando a chamada veio de controller protegido;
- bloqueia o investidor e depois todas as suas carteiras em ordem crescente de ID;
- carrega todos os fatos confirmados do investidor em ordem de replay, inclui a alteração candidata em memória, valida todo o histórico e só então persiste;
- gera lançamentos e substitui todas as posições atuais do investidor na mesma transação do banco;
- reverte tudo em qualquer falha; nenhuma interface devolve sucesso parcial.

Rascunhos criados pelo usuário têm origem `manual`. Reversões têm origem `sistema`. A substituta de uma correção copia a origem da original e registra o usuário da correção como criador e confirmador.

#### `ConsultasFinanceiras`

```ruby
ConsultasFinanceiras.posicao_atual(carteira:, usuario:)
ConsultasFinanceiras.posicao_historica(carteira:, data:, usuario:)
ConsultasFinanceiras.saldos_caixa(carteira:, data:, usuario:)
ConsultasFinanceiras.resultados_realizados(carteira:, inicio:, fim:, usuario:)
ConsultasFinanceiras.rentabilidade(carteira:, inicio:, fim:, usuario:)
```

Períodos são inclusivos e exigem `inicio <= fim`. A consulta autoriza o usuário e devolve DTOs imutáveis, sem relações Active Record lazy. Campos mínimos:

- `PosicaoDTO`: `carteira_id`, `data`, `itens`, `valor_total_base`, `completo`; cada item traz conta, ativo, quantidade, custos local/base, preço e data usados, valor de mercado local/base, câmbio e defasagens;
- `SaldosCaixaDTO`: `carteira_id`, `data`, `itens`, `valor_total_base`, `completo`; cada item traz conta de caixa, moeda, saldo, taxa/data de câmbio, valor-base e defasagem;
- `ResultadosDTO`: `carteira_id`, período, `itens`, totais localizados por moeda e total-base; cada venda traz transação, data, conta, ativo, quantidade, alienação, custo removido, custo da venda e resultado, em moeda local e base;
- `RentabilidadeDTO`: `carteira_id`, período, `pontos`, `twr_acumulado`, `completo`, `motivos_incompletude`; cada ponto traz data, patrimônio inicial/final, fluxo externo líquido, TWR diário, TWR acumulado até o dia, estado e maior defasagem usada.

`posicao_atual` lê `posicoes_atuais`; as demais consultas fazem replay. Resultados incluem vendas cuja `data_competencia` esteja no período. Todas carregam fatos e cotações em lotes, fazem processamento linear em memória e não escrevem no banco.

#### `Mercado`

```ruby
Mercado.registrar_cotacao_ativo(ativo:, data:, preco:, fonte:, manual:, usuario: nil)
Mercado.registrar_cotacao_cambio(moeda_origem:, moeda_destino:, data:, taxa:, usuario:)
Mercado.liberar_automacao(cotacao_ativo:, usuario:)
Mercado.buscar_e_registrar_yahoo(data:)
```

Registros manuais exigem administrador do sistema e `usuario`; gravações automáticas de ativo exigem fonte `YAHOO` e autor nulo. Os métodos de registro devolvem `ResultadoCotacao` com `cotacao` e estado `criada|atualizada|ignorada_manual`; o último estado só se aplica a ativo. `liberar_automacao` apenas muda `manual` para `false` numa cotação de ativo; a próxima busca poderá substituí-la. Uma busca que falha ou não encontra preço preserva o valor existente e registra a falha no log do job, sem criar outra tabela.

Haverá somente um buscador automático, Yahoo. Implementá-lo privadamente com dependência HTTP injetável para teste; não criar registro genérico de adapters ou framework de provedores antes de existir uma segunda fonte automática real. Timeout, resposta inválida e indisponibilidade de rede são falhas recuperáveis do job e usam o retry padrão do Solid Queue, limitado a três tentativas.

### Erros das interfaces

Definir sob o namespace financeiro:

- `NaoAutorizado`: papel insuficiente;
- `EscopoInvalido`: recurso não pertence ao espaço/investidor esperado;
- `AtributosInvalidos`: payload, enum, valor, data ou cardinalidade inválidos;
- `EstadoInvalido`: operação incompatível com rascunho, confirmada ou reversão;
- `HistoricoInvalido`: replay violaria long-only ou outra invariante histórica;
- `RegistroArquivado`: tentativa de criar filho ou fato usando cadastro arquivado;
- `ConflitoIdempotencia`: mesma chave usada com tipo incompatível.

Cada erro inclui `codigo` estável e `detalhes` estruturados para o formulário, sem texto HTML. Controllers traduzem `NaoAutorizado` em `403`, `EscopoInvalido` em `404`, conflitos de estado/idempotência em `409` e erros corrigíveis de entrada/histórico/arquivamento em `422`. Erros inesperados continuam `500` e não são convertidos em validação.

### Convenções completas da rentabilidade

Rentabilidade e resultados são síncronos. Solid Queue permanece apenas para busca agendada de cotações e manutenção; não participa do cálculo financeiro. Cache ou materialização só serão considerados depois de medição.

O TWR produz um ponto para cada **dia civil** do período inclusivo. Para o dia `D`, o patrimônio inicial é o estado no fechamento de `D-1`, antes dos fatos de `D`, avaliado com cotações exatas ou anteriores a `D-1`; o patrimônio final é o estado depois de todos os fatos de `D`, avaliado com cotações exatas ou anteriores a `D`. A consulta reconstrói todo o histórico anterior a `inicio`, portanto o primeiro ponto não é tratado como caso especial.

Patrimônio é a soma, na moeda-base da carteira, de `quantidade * preço` de todas as posições mais todos os saldos de caixa, inclusive negativos. Custos médios e resultados realizados não entram na avaliação patrimonial. Um item já denominado na moeda-base usa taxa `1`; demais itens usam câmbio canônico direto ou inverso conforme a convenção definida.

TWR diário adota fluxo externo no fim do dia:

```text
(patrimonio_final - fluxo_externo_liquido) / patrimonio_inicial - 1
```

A classificação é derivada da transação e da carteira consultada:

- aporte é entrada externa e resgate é saída externa;
- transferência entre contas da mesma carteira é interna;
- transferência entre carteiras é saída externa na origem e entrada externa no destino;
- compra, venda, provento e câmbio são internos;
- reversão copia a classificação da original com sinal oposto.

Fluxos em moeda diferente da moeda-base usam o câmbio canônico exato ou anterior na data do fluxo. Só são necessárias cotações para ativos e saldos não zerados naquele ponto. Ausência de qualquer preço ou câmbio necessário deixa o dia `incompleto` e seus valores de patrimônio/TWR ficam `nil`.

Com dados completos, TWR diário só é calculado quando `patrimonio_inicial > 0`; caso contrário, o ponto fica `sem_patrimonio_inicial_valido`. Carteira vazia também cai nesse estado, não em retorno zero. Fins de semana e feriados reutilizam a última cotação anterior e normalmente produzem retorno zero se nada mudou.

O acumulado de cada ponto é `produto(1 + twr_diario) - 1` desde `inicio`. A partir do primeiro dia incompleto ou incalculável, o acumulado daquele ponto e dos seguintes fica `nil`; consequentemente, `RentabilidadeDTO.twr_acumulado` só existe quando todos os dias são calculáveis. Defasagem é metadado e, sozinha, não torna um dia incompleto; reportar a maior defasagem entre preços e câmbios utilizados.

### Autorização

- `administrador_sistema`: acesso total a todos os espaços e catálogos.
- `administrador`: gerencia espaço, membros, investidores, carteiras, contas e transações.
- `editor`: gerencia investidores, carteiras, contas e transações, sem alterar membros ou espaço.
- `leitor`: somente consultas e relatórios.
- Impedir remoção ou rebaixamento do último administrador de um espaço.
- Não haverá permissão específica por investidor dentro do espaço.
- Substituir policies que percorrem `user.investidor` por escopos baseados em associação ao espaço, com curto-circuito para administrador do sistema.
- Controllers carregam o espaço com `policy_scope(Espaco).find(params[:espaco_id])` e todos os recursos aninhados pelas associações desse espaço; não usar `Model.find` global para recurso escopado.
- Alteração de membros bloqueia o espaço para impedir duas remoções concorrentes do último administrador.

### Rotas e interface

- Área global `/admin` para ativos, instituições, moedas, fontes e cotações.
- `/espacos` para criação e seleção.
- Recursos financeiros sob `/espacos/:espaco_id`, incluindo membros, investidores, carteiras, contas, transações e relatórios.
- Uma transação terá criação/edição/exclusão de rascunho, confirmação, visualização, reversão e correção atômica; não haverá edição de confirmada.
- O formulário de nota permitirá adicionar/remover várias negociações e exibirá a prévia do rateio e da liquidação.
- O painel da carteira exibirá posição, caixa por moeda, valor convertido, cotação defasada, resultados e rentabilidade.

Manter o stack visual atual de ERB, Turbo, Stimulus e Bootstrap; este plano não inclui redesign visual nem frontend separado. O conjunto mínimo de telas é:

- seleção/criação/restauração de espaço e gestão de membros;
- CRUD com arquivamento/restauração de investidores, carteiras e contas;
- lista de transações com filtros por investidor, carteira, tipo, estado e período;
- um fluxo de rascunho por tipo, com campos exatamente correspondentes aos contratos de atributos; nota usa linhas dinâmicas e todos exibem prévia antes de confirmar;
- visualização de confirmada com lançamentos derivados, ação de reversão e formulário de correção previamente preenchido;
- painel de carteira com data/período selecionáveis e seções de posição, caixa, resultados e TWR;
- CRUD administrativo dos quatro catálogos globais e das duas cotações canônicas.

Confirmação, reversão, correção, arquivamento e restauração usam `POST/PATCH`, nunca `GET`. Falhas `422` preservam o payload e exibem erros junto aos campos; `409` informa que o estado mudou e recarrega o registro; `403/404` não revelam recursos de outro espaço. Nenhuma tela oferece exclusão física de cadastro ou fato confirmado.

## 4. Remoções e corte BIG BANG

Remover integralmente:

- `EventoFinanceiro` e os registradores públicos atuais;
- importações e conciliações de extrato;
- referências, versões e metas de alocação;
- eventos corporativos;
- transferências de custódia;
- posições vendidas e cobertura;
- colunas e relatórios fiscais;
- `resultados_operacoes`, `resumos_diarios_carteira`, jobs e infraestrutura de invalidação/recálculo financeiro;
- enums, rotas, controllers, views, jobs e testes dessas capacidades;
- o plano de schema anterior, substituindo-o por um ADR único do redesenho.

Não criar `espacos_ativos`, tabelas de seleção/revisão de cotações, cache de rentabilidade ou outra projeção além de `posicoes_atuais`. `lancamentos_caixa` permanece como livro canônico derivado das transações, não como cache.

Criar `CONTEXT.md` e um ADR registrando: corte sem migração, espaço como limite de acesso, catálogo global, transações imutáveis tipadas, posição atual reconstruível, cálculos históricos sob demanda e escopo long-only.

### Ordem de implementação

A entrega continua sendo um único Big Bang. As etapas abaixo organizam o trabalho e os commits; nenhuma etapa intermediária precisa ser compatível com o schema antigo.

1. **Documentação e baseline:** criar `CONTEXT.md` e ADR; substituir a migration primária pelo inventário exato das 20 tabelas; atualizar schema e seeds. Concluída quando os bancos vazios são preparados duas vezes e os testes de constraints do novo schema passam.
2. **Acesso e catálogos:** implementar models, policies, scopes e telas de espaços, membros, investidores, carteiras, contas e catálogos. Concluída com matriz de autorização, arquivamento e proteção do último administrador passando.
3. **Núcleo financeiro:** implementar `TransacoesFinanceiras`, projetor puro, replay, lançamentos e posição atual, começando por movimentação, depois provento e por fim nota multilinha. Concluída quando prévia/confirmação/replay são idênticos e cenários long-only, retroativos, reversão, correção e concorrência passam.
4. **Mercado e consultas:** implementar cotações canônicas, busca Yahoo, DTOs, posição histórica, caixa, resultados e TWR. Concluída com testes de ausência/defasagem de cotação, câmbio direto/inverso e períodos de 30/365 dias.
5. **Fluxos HTTP:** implementar rotas, controllers e telas mínimas sobre as interfaces já testadas. Concluída com system tests dos fluxos principais e verificação de N+1.
6. **Remoção e corte:** apagar implementação, testes, rotas e dependências das capacidades removidas; revisar textos; executar o checklist destrutivo e toda a validação. Concluída somente quando não restam constantes/tabelas/rotas legadas e toda a suíte passa.

Rollout:

1. Implementar tudo em uma única linha de mudança, sem camada de compatibilidade.
2. Substituir apenas as migrations do domínio primário por um baseline consolidado e regenerar `db/schema.rb`; preservar o schema/migrations próprios do Solid Queue.
3. Parar aplicação e workers no corte e confirmar explicitamente os bancos primário e Solid Queue que serão descartados.
4. Recriar ambos os bancos vazios; `db:prepare` não será usado como mecanismo de limpeza de schema legado.
5. Em desenvolvimento/teste, executar a recriação e os comandos Rails dentro do Dev Container. Em produção, recriar os bancos externamente antes de rodar `db:prepare` e `db:seed`.
6. Seeds idempotentes criam moedas e fontes. `ADMIN_EMAIL` e `ADMIN_PASSWORD` devem estar ambos presentes ou ambos ausentes; quando presentes, criam/atualizam o administrador do sistema sem criar investidor automaticamente. Em produção ambos são obrigatórios no primeiro preparo; em desenvolvimento/teste podem estar ausentes.
7. Validar que nenhuma tabela legada existe nos bancos primário e de fila antes de iniciar processos.
8. Subir aplicação e workers somente após validação completa.
9. Não criar scripts de migração, importação legado ou rollback de dados.

Checklist operacional para desenvolvimento e teste, executado a partir da raiz do repositório. Antes dos comandos de `drop`, o executor deve conferir que o Compose é `.devcontainer/docker-compose.yml` e que os nomes resolvidos são exclusivamente `carteiras_development`, `carteiras_development_queue`, `carteiras_test` e `carteiras_test_queue`:

```sh
docker compose -f .devcontainer/docker-compose.yml up -d --build
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails db:drop:all
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails db:create
docker compose -f .devcontainer/docker-compose.yml exec -T app bin/rails db:prepare db:seed
docker compose -f .devcontainer/docker-compose.yml exec -T app env RAILS_ENV=test bin/rails db:drop:all
docker compose -f .devcontainer/docker-compose.yml exec -T app env RAILS_ENV=test bin/rails db:create
docker compose -f .devcontainer/docker-compose.yml exec -T app env RAILS_ENV=test bin/rails db:prepare
```

Em produção, não copiar esses comandos. Parar processos, resolver e registrar os dois nomes de banco a partir da configuração do ambiente, obter confirmação humana desses nomes, recriá-los pelo provedor, configurar as credenciais de administrador, executar `bin/rails db:prepare db:seed`, comparar o schema primário com as 20 tabelas deste plano e verificar as tabelas do Solid Queue antes de voltar a subir processos. O rollback é restaurar backup integral anterior ao corte; não existe rollback lógico da aplicação.

## 5. Testes e critérios de aceitação

- Espaços: criação, associação por e-mail, três papéis, último administrador e acesso total do administrador do sistema.
- Baseline: exatamente as 20 tabelas funcionais inventariadas, com tipos, defaults, nulabilidade, FKs, checks e índices especificados; nenhuma tabela funcional extra.
- Isolamento: usuários comuns nunca acessam dados de espaços sem associação.
- Catálogo: todo espaço encontra ativos globais não arquivados; ativo arquivado não entra em novo rascunho, mas permanece válido no histórico.
- Negociação multilinha: compras e vendas mistas, ordem interna, liquidação líquida, rateio proporcional, resíduo determinístico e identidade entre prévia, confirmação e replay.
- Regime de liquidação: compra em D e liquidação em D+2 não cria posição, caixa ou salto patrimonial em D/D+1.
- Long-only: venda parcial, zeragem, venda retroativa válida, rejeição de venda excedente e reversão recusada quando removeria o lastro de venda posterior.
- Correção: reversão e substituta são atômicas e podem corrigir uma compra que sustenta venda posterior sem expor histórico intermediário inválido.
- Caixa: aporte, resgate, transferência interna, transferência entre carteiras, câmbio restrito à mesma carteira, saldo negativo permitido e lançamento de reversão ligado à perna original.
- Proventos: bruto, retenção, líquido, caixa e conversão para moeda-base.
- Contratos: rejeitar atributos desconhecidos, `Float`, campos derivados enviados, payload parcial de atualização/correção, tipo diferente na substituta e reutilização conflitante da chave de idempotência.
- Imutabilidade: confirmadas não são editadas/excluídas; reversão única; rollback atômico em qualquer falha.
- Replay: posição atual deve ser idêntica à reconstrução integral após inclusão retroativa ou reversão; resultados realizados derivados devem ser idênticos entre consultas repetidas e nunca gerar gravação.
- Concorrência: confirmações simultâneas para o mesmo investidor/data não perdem atualizações nem geram deadlock; duas remoções simultâneas não removem o último administrador.
- Cotações: criação/atualização canônica, correção manual, proteção de valor manual contra automação, preço defasado, câmbio direto/inverso e ausência de cotação.
- TWR: primeiro dia do intervalo, dias civis sem movimento, aporte revertido, fluxo em moeda não-base, transferência entre carteiras com moedas-base iguais/diferentes, encadeamento, patrimônio inicial zero/negativo, carteira vazia e valorização incompleta; cálculo não escreve no banco e reflete uma correção de cotação na consulta seguinte.
- Interfaces: testar retornos e todos os erros públicos pelas três interfaces externas; testes de implementação pura podem chamar diretamente o projetor interno, mas controllers e jobs não.
- Performance: posição atual em número constante de consultas; caixa agregado em uma consulta; views sem N+1. Os testes comparam conjuntos pequenos e grandes e falham se a quantidade de consultas crescer com contas, ativos, transações ou dias, sem fixar um teto arbitrário.
- Rentabilidade sob demanda: comparar períodos de 30 e 365 dias e garantir quantidade constante de consultas, processamento linear no número de dias/eventos e nenhuma criação/alteração de registros.
- Autorização: matriz completa para administrador do sistema, administrador, editor, leitor e usuário sem vínculo; adulteração de IDs de espaço, investidor, conta e ativo nunca atravessa o escopo autorizado.
- System tests: criar espaço, cadastrar estrutura, registrar nota multilinha, confirmar, consultar posição, corrigir e reverter.
- Verificar inexistência de tabelas, rotas e constantes das funcionalidades removidas.
- Preparar duas vezes bancos vazios, executar seeds repetidamente e verificar ausência de tabelas legadas nos bancos primário e de fila.
- Buscar por `família|familiar|family` em `app/`, `config/locales/`, `README.md` e `CONTEXT.md`; planos e ADRs históricos ficam fora desse critério.

Executar no Dev Container:

```sh
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
bin/rails zeitwerk:check
bin/rails test
bin/rails test:system
```

### Definição de pronto do handoff

A implementação estará concluída somente quando:

- as 20 tabelas funcionais correspondem ao inventário e o banco de fila continua isolado;
- todas as mutações financeiras atravessam `TransacoesFinanceiras`, todas as leituras agregadas atravessam `ConsultasFinanceiras` e toda escrita de cotação atravessa `Mercado`;
- uma reconstrução integral reproduz `posicoes_atuais`, e consultas históricas/resultados/TWR não gravam registros;
- matriz de autorização, invariantes financeiras, concorrência, fluxos HTTP e busca de cotação passam;
- as capacidades removidas e a terminologia proibida não aparecem nas áreas verificadas;
- todos os comandos obrigatórios terminam com sucesso em bancos recriados do zero.

Se uma decisão necessária à implementação não estiver descrita, escolher primeiro a opção mais simples que preserve as invariantes e as três interfaces. Não acrescentar tabela, job, adapter, cache, novo estado ou nova capacidade sem atualizar este plano e obter aprovação.

## 6. Premissas fixadas

- Todos os dados atuais serão descartados.
- PostgreSQL continuará sendo o único banco.
- IDs permanecem `bigint`; valores financeiros usam `numeric`, nunca `float`.
- A moeda-base pertence à carteira.
- Custo médio é o único método econômico.
- Todos os ativos globais não arquivados ficam disponíveis em todos os espaços; não haverá seleção ou apelido local.
- Cotações são canônicas e corrigíveis, sem histórico de revisões.
- Somente `posicoes_atuais` é projeção persistida; posição histórica, resultados realizados e TWR são calculados sob demanda e não possuem cache.
- Não haverá tributação real, importadores, metas, eventos corporativos, posições vendidas ou transferência de custódia.
- Não haverá RLS, microsserviços, event sourcing genérico, razão contábil universal, particionamento, UUIDs, convites por e-mail ou grafo genérico de conversão cambial.
- Não criar triggers de domínio; integridade estrutural ficará em FKs, `NOT NULL`, unicidades e checks, e a imutabilidade comportamental no módulo de transações e nas policies.
- Cadastros e fatos referenciados não serão apagados; serão arquivados. Apenas rascunhos e projeções reconstruíveis podem ser excluídos fisicamente.
