# Plano de melhoria do esquema e do domínio financeiro

## 1. Objetivo e critério de proporcionalidade

O objetivo principal é eliminar a reconstrução da posição atual ativo por ativo e o consequente problema de N+1 consultas, preservando correção financeira, auditabilidade e a possibilidade de reconstruir os dados derivados.

O desenho considera uma aplicação pessoal ou familiar, com poucos usuários e volume moderado. A solução continuará sendo um monólito Rails com PostgreSQL e terá somente as projeções que resolvem necessidades concretas.

Decisões gerais:

- substituir o esquema legado por um novo baseline, sem migração de dados antigos;
- manter PostgreSQL 18, Rails, ERB, Turbo/Stimulus, Devise, Pundit e Solid Queue;
- manter nomes de domínio, serviços, mensagens e testes em português; nomes de infraestrutura de bibliotecas podem permanecer em inglês;
- usar tabelas tipadas de domínio, e não um livro-razão contábil genérico;
- manter um cabeçalho financeiro mínimo para autoria, idempotência, confirmação e reversão;
- materializar somente `posicoes_atuais` na primeira entrega;
- calcular saldos de caixa com uma consulta agregada sobre o livro-razão de caixa;
- reconstruir a carteira inteira quando houver evento retroativo ou reversão, em vez de manter um grafo de dependências por ativo;
- fazer leituras históricas por replay em lote; resumos diários serão uma etapa funcional posterior para suportar TWR;
- usar `decimal`, nunca `float`, para quantidades, preços, valores, taxas e percentuais;
- arquivar cadastros referenciados com `arquivado_em`, sem apagá-los.

Ficam deliberadamente fora do desenho inicial:

- microsserviços, CQRS distribuído, barramento de eventos e tabela de saída transacional;
- particionamento, fragmentação, réplicas de leitura e RLS;
- gatilhos de banco para regras de domínio;
- tabela própria para acompanhar reconstruções;
- reconstrução incremental por sequência de ativo;
- projeção de saldo de caixa;
- armazenamento de várias cotações brutas e outra tabela para selecionar uma cotação oficial;
- infraestrutura genérica de conversão entre quaisquer pares de moedas.

## 2. Princípios de integridade

- IDs usam `bigint`; competência, negociação, liquidação e fechamento usam `date`; auditoria usa timestamps.
- Quantidades usam `numeric(30,10)`, preços e valores `numeric(30,12)`, taxas `numeric(24,12)` e percentuais `numeric(9,6)`.
- Cadastros e fatos financeiros recebem FKs, `NOT NULL`, índices únicos e `CHECK` coerentes com os sinais permitidos.
- Toda alteração financeira confirmada é atômica: cabeçalho, detalhe, lançamentos de caixa e posição são gravados na mesma transação.
- A consulta nunca pode observar uma projeção parcialmente atualizada ou reconstruída.
- Registros confirmados são imutáveis. Uma correção cria outro registro confirmado que reverte o anterior; o original não muda.
- Reprocessamentos usam chaves de idempotência e podem ser repetidos sem duplicar eventos ou lançamentos.
- A moeda e as taxas efetivamente usadas por um fato financeiro são persistidas no próprio detalhe para que seu replay seja determinístico.

## 3. Esquema alvo

### 3.1. Cadastros e propriedade

- `users`: mantida para Devise.
- `investidores`: `user_id` único, nome e `moeda_fiscal_id`, inicialmente BRL.
- `moedas`: código ISO ou código de criptoativo, nome, tipo, casas decimais e `arquivado_em`; código único em maiúsculas.
- `carteiras`: investidor, nome, `moeda_base_id` com padrão BRL e `arquivado_em`; unicidade `(investidor_id, nome)`.
- `corretoras`: nome, país e `arquivado_em`.
- `contas_investimento`: carteira, corretora, nome, identificador externo e `arquivado_em`; unicidade `(carteira_id, nome)` e, quando preenchido, do identificador externo por corretora.
- `contas_caixa`: conta de investimento e moeda; unicidade `(conta_investimento_id, moeda_id)`.
- `ativos`: código, mercado, descrição, tipo, moeda de negociação, moeda de exposição, CNPJ normalizado e `arquivado_em`; unicidade `(codigo, mercado)`.

O CNPJ será indexado, mas só terá unicidade parcial nos tipos de ativo para os quais essa regra seja comprovadamente válida. Operações e proventos apontam para a conta de investimento; carteira e corretora são derivadas por essa associação e não são repetidas.

### 3.2. Cabeçalho financeiro e detalhes tipados

`eventos_financeiros` é um cabeçalho pequeno e comum:

- tipo e origem (`manual`, `importacao`, `sistema`);
- data de competência e sequência determinística na data;
- estado persistido (`rascunho` ou `confirmado`);
- usuário responsável;
- chave de idempotência;
- `evento_revertido_id`, quando este evento for uma reversão;
- observação e timestamps.

Regras:

- a chave de idempotência é única por carteira quando preenchida;
- `evento_revertido_id` tem índice único parcial, impedindo mais de uma reversão do mesmo evento;
- “revertido” é um estado derivado da existência de uma reversão e nunca uma mutação do evento original;
- somente rascunhos podem ser alterados ou excluídos;
- a reversão usa a competência econômica correta para desfazer os efeitos, preservando o timestamp real de registro;
- os serviços validam que todas as contas envolvidas pertencem à mesma carteira;
- a imutabilidade é protegida pelos serviços, models, policies e ausência de rotas de edição; o banco protege a estrutura com FKs, checks e unicidades, sem gatilhos de domínio.

Detalhes 1:1 ligados ao cabeçalho:

- `operacoes`: conta, ativo, natureza (`compra` ou `venda`), quantidade positiva, preço unitário positivo, moeda, data de negociação, data de liquidação, custos separados em colunas e taxas de conversão efetivamente usadas;
- `proventos`: conta, ativo, tipo (`dividendo`, `jcp`, `rendimento`), quantidade de referência, valores bruto, tributos e líquido, moeda, data-base, data de pagamento e taxas usadas;
- `movimentacoes_caixa`: conta-caixa, natureza (`aporte`, `resgate`, `ajuste`), valor positivo e data efetiva;
- `transferencias_caixa`: contas-caixa de origem e destino, valor positivo e data efetiva;
- `transferencias_custodia`: contas de origem e destino, ativo e quantidade positiva;
- `eventos_corporativos`: tipo (`desdobramento`, `grupamento`, `incorporacao`), conta, ativo de origem, ativo de destino opcional, fator ou quantidade final, valor de fração opcional e regra explícita de alocação do custo.

Os custos fixos de uma operação serão colunas `taxa`, `emolumentos`, `corretagem`, `iss_iof`, `irrf` e `outros`, com padrão zero e checks não negativos. Isso evita uma tabela e vários joins para um conjunto pequeno e estável de campos.

Uma venda não é cadastrada como “venda descoberta”. O projetor determina se ela reduz, zera ou inverte uma posição. Da mesma forma, uma compra pode cobrir uma posição vendida e eventualmente abrir uma posição comprada.

### 3.3. Livro-razão de caixa

`lancamentos_caixa` é a única fonte de verdade para o saldo:

- evento financeiro, conta-caixa, data efetiva, natureza e valor assinado;
- operações afetam a posição na negociação e o caixa apenas na liquidação;
- compras, vendas, proventos e movimentações geram seus lançamentos na confirmação;
- transferências geram lançamentos opostos cujo total na mesma moeda é zero;
- uma consulta `SUM(valor)`, agrupada por conta e filtrada por `data_efetiva <= data_consulta`, calcula todos os saldos;
- um saldo informado em extrato serve somente para conciliação e não constitui outro saldo acumulado.

Não haverá `saldos_caixa_atuais` inicialmente. Essa projeção só será criada se uma medição real mostrar que a agregação ficou cara.

### 3.4. Importação e conciliação

- `importacoes_extrato`: conta-caixa, corretora, nome original, `checksum_sha256`, formato, estado, contadores e erro resumido.
- `itens_extrato_importado`: importação, ordem, datas, descrição, valor, moeda, saldo informado opcional, identificador externo, chave de deduplicação, dados normalizados em `jsonb`, classificação e estado da conciliação.
- Um item resolvido aponta, de maneira mutuamente exclusiva, para o evento que gerou ou para o lançamento de caixa existente com que foi conciliado. Não haverá FKs circulares de volta ao item.
- O arquivo é lido e normalizado durante a requisição; apenas metadados e itens normalizados são persistidos. O arquivo original não é guardado.
- A classificação e a conciliação podem continuar em `ProcessarItensImportacaoJob` depois que as linhas já estiverem no banco. Para arquivos pequenos, o mesmo serviço pode ser executado em linha.
- `UNIQUE (conta_caixa_id, checksum_sha256)` impede a reimportação do mesmo arquivo.
- `UNIQUE (importacao_extrato_id, ordem)` identifica cada linha do arquivo.
- A chave de deduplicação é indexada, mas não é única: duas movimentações legítimas podem ter a mesma data, descrição e valor.
- Quando a corretora fornece identificador externo estável, ele compõe a chave de idempotência do evento.

Fluxo de conciliação:

1. procurar primeiro um lançamento esperado ainda não conciliado, usando conta, moeda, valor, datas e identificador externo;
2. quando houver correspondência inequívoca, vincular o item ao lançamento sem criar novo efeito financeiro;
3. quando o item representar um evento externo novo e for inequívoco, criar o evento e seus lançamentos;
4. quando houver ambiguidade ou possível duplicidade, deixar o item pendente para revisão;
5. registrar a decisão e o usuário responsável para auditoria.

### 3.5. Posição atual e resultados realizados

- `posicoes_atuais`: conta, ativo, quantidade assinada, custo total na moeda de negociação, custo total na moeda-base, resultado econômico realizado acumulado, último evento aplicado e versão; unicidade `(conta_investimento_id, ativo_id)`.
- `resultados_operacoes`: operação de encerramento, quantidade encerrada, custo alocado, valor de alienação, custos alocados e resultado realizado. Essa tabela só será mantida se os relatórios existentes realmente precisarem do detalhe; caso contrário, o resultado permanece agregado em `posicoes_atuais` e pode ser derivado por replay.

Regras do projetor:

- compra em posição comprada aumenta quantidade e custo;
- venda parcial reduz o custo pelo custo médio anterior e reconhece resultado;
- zeragem leva quantidade e custo exatamente a zero;
- posição vendida mantém quantidade e custo assinados negativos;
- cobertura parcial reconhece a diferença entre preço médio de abertura e preço de recompra;
- cruzamento de zero divide internamente a operação em encerramento e abertura;
- custos são rateados proporcionalmente entre as parcelas encerrada e aberta;
- transferência de custódia move quantidade e custo proporcional sem realizar resultado;
- desdobramento e grupamento alteram quantidade e preservam custo total;
- incorporação usa a quantidade final informada ou calculada e trata explicitamente eventual fração em dinheiro e sua alocação de custo.

Uma confirmação comum bloqueia a linha da carteira, grava todos os efeitos e atualiza a projeção na mesma transação. O bloqueio por carteira é simples e suficiente para o pequeno número de usuários.

Evento retroativo ou reversão reconstrói todas as posições da carteira, ordenadas por `(data_competencia, sequencia_na_data, id)`. A reconstrução calcula o novo conjunto antes da substituição e troca as linhas dentro de uma única transação, sem expor estado parcial. Ela permanecerá síncrona enquanto medições reais indicarem tempo aceitável.

### 3.6. Cotações e câmbio

Manter apenas uma cotação canônica por ativo ou par de moedas e data:

- `fontes_cotacao`: nome, prioridade, tipos atendidos e `arquivado_em`;
- `cotacoes_ativos`: ativo, data, preço positivo, moeda, fonte e indicador de inserção manual; unicidade `(ativo_id, data)`;
- `cotacoes_cambio`: moedas de origem e destino, data, taxa positiva, fonte e indicador manual; unicidade `(moeda_origem_id, moeda_destino_id, data)`.

O buscador tenta as fontes ativas em ordem de prioridade e persiste apenas o valor escolhido. Uma correção manual atualiza a cotação canônica com auditoria, sem manter tabelas separadas de valores brutos e oficiais.

Leituras nunca chamam serviços externos. Na ausência de fechamento exato, usam a última cotação anterior e informam sua data e a condição defasada; sem cotação, a valorização fica incompleta. A taxa histórica persistida num evento nunca é substituída durante um replay.

### 3.7. Referências e alocação

Como a comparação histórica de metas foi definida como funcionalidade desejada, manter versionamento, mas sem criar um cadastro separado de categorias:

- `referencias`: nome único e descrição;
- `versoes_referencia`: referência, vigência inicial e estado (`rascunho`, `publicada`, `encerrada`);
- `alocacoes_referencia`: versão, ativo, categoria textual e percentual; unicidade `(versao_referencia_id, ativo_id)`.

A publicação valida em uma transação que existe ao menos uma alocação, que nenhum percentual é negativo e que a soma é exatamente 100%. Versões publicadas são imutáveis; alterações criam nova versão.

### 3.8. Resumos diários e TWR

TWR diário é uma funcionalidade desejada, mas não participa da correção da posição atual. Será implementado depois que o livro-razão e a projeção atual estiverem validados.

- `resumos_diarios_carteira`: data, patrimônio inicial, patrimônio final, ativos, caixa, fluxo externo líquido, resultado diário, TWR diário, data das cotações usadas e estado de completude;
- a geração lê eventos, posições reconstruídas para o dia, caixa agregado e cotações canônicas;
- um evento retroativo invalida e recalcula os resumos da carteira a partir da data afetada;
- não são necessárias inicialmente tabelas `posicoes_diarias` ou `saldos_caixa_diarios`;
- a posição histórica detalhada é obtida com uma única consulta dos eventos até a data e replay em memória.

Fórmula adotada, tratando fluxos externos como ocorridos no fim do dia:

```text
retorno_diario = (patrimonio_final - fluxo_externo_liquido) / patrimonio_inicial - 1
```

O retorno do período é o produto dos fatores diários menos um. Dias sem patrimônio inicial ou com valorização incompleta não produzem retorno e são apresentados como pendentes.

### 3.9. Índices e constraints principais

- eventos por `(carteira_id, data_competencia, sequencia_na_data, id)`;
- unicidades parciais para chave de idempotência e `evento_revertido_id`;
- operações por `(conta_investimento_id, ativo_id)`;
- lançamentos por `(conta_caixa_id, data_efetiva, evento_financeiro_id)`;
- posições atuais por `(conta_investimento_id, ativo_id)`;
- importações por conta, checksum e estado;
- itens por importação/ordem, identificador externo e chave de deduplicação;
- cotações por ativo ou par e data;
- versões de referência por referência e vigência;
- resumos por `(carteira_id, data)`.

Usar `ON DELETE RESTRICT` em fatos financeiros e cadastros já referenciados. Projeções e resumos podem ser substituídos apenas pelos serviços explícitos de reconstrução. Enums relevantes recebem `CHECK`; valores financeiros recebem checks de sinal.

## 4. Organização do código

### 4.1. Serviços de domínio

Serviços públicos em português:

- `RegistrarOperacao`
- `RegistrarProvento`
- `RegistrarMovimentacaoCaixa`
- `RegistrarTransferenciaCaixa`
- `RegistrarTransferenciaCustodia`
- `RegistrarEventoCorporativo`
- `ConfirmarEventoFinanceiro`
- `ReverterEventoFinanceiro`
- `ProjetarEventoFinanceiro`
- `ReconstruirPosicoesCarteira`
- `ConciliarItemExtrato`
- `SelecionarCotacao`
- `PublicarVersaoReferencia`
- `RecalcularResumosDiarios`

O projetor será uma classe pura que recebe estado e evento e devolve novo estado. Transações, bloqueio da carteira e persistência pertencem aos serviços de aplicação. Não usar callbacks de model para criar efeitos financeiros ocultos.

### 4.2. Consultas

- `ConsultarPosicaoCarteira`: lê `posicoes_atuais`, cotações canônicas e associações necessárias em quantidade constante de consultas;
- `ConsultarPosicaoHistorica`: carrega em lote os eventos da carteira até a data e executa um único replay em memória;
- `ConsultarPosicaoAtivo`: posição, valorização e cadeia de eventos, sem consulta por linha;
- `ConsultarSaldosCaixa`: uma agregação sobre `lancamentos_caixa`;
- `ConsultarRentabilidade`: lê `resumos_diarios_carteira` quando essa etapa estiver pronta;
- `ConsultarComparacaoReferencia`: usa a versão vigente na data.

Controllers entregam DTOs completamente carregados. Views não chamam SQL, serviços externos nem métodos que carreguem associações implicitamente.

### 4.3. Resultado econômico e relatórios tributários

Separar resultado econômico de apuração tributária:

- o projetor calcula custo médio e resultado realizado por encerramento;
- custos de compra compõem a base e custos de venda reduzem o resultado da alienação, com rateio explícito;
- relatórios atuais recebem testes de caracterização antes da reescrita;
- a primeira entrega preserva categorias e relatórios existentes, mas não declara a saída como apuração tributária completa ou juridicamente atualizada;
- operações e regimes não suportados, como regras específicas de day trade ou compensações ainda não modeladas, devem ser identificados explicitamente em vez de produzir resultado silenciosamente incorreto;
- revisão de legislação tributária permanece fora deste trabalho.

### 4.4. Jobs

Usar poucos jobs, apenas onde há benefício concreto:

- `ProcessarItensImportacaoJob`, depois que o arquivo já foi normalizado;
- `BuscarCotacoesFechamentoJob`, sem transação aberta durante chamadas externas;
- `RecalcularResumosDiariosJob`, somente na etapa de TWR.

O estado do Solid Queue e campos simples na entidade afetada bastam para diagnóstico. Não criar `processamentos_projecao`. Reconstrução da posição atual permanece síncrona até que um benchmark real justifique movê-la para job.

### 4.5. Interface

Manter Rails server-rendered e organizar:

- carteira: painel atual, posição histórica, rentabilidade, relatórios e referência;
- contas: cadastro, caixa e custódia;
- eventos financeiros: linha do tempo, detalhe e reversão;
- formulários tipados para operações, proventos, movimentações, transferências e eventos corporativos;
- importações: envio, itens conciliados, possíveis duplicatas e pendências;
- referências: versões, alocação e publicação;
- cotações: cobertura, fontes e correção manual.

Eventos confirmados não terão editar ou excluir, apenas reverter. Rotas, rótulos e mensagens de domínio permanecem em português. Pundit garante propriedade por investidor e carteira.

## 5. Etapas de implementação

### Etapa 1 — núcleo correto e consulta barata

1. Remover migrations legadas e criar uma migration baseline com cadastros, contas, eventos tipados, livro-razão de caixa e `posicoes_atuais`.
2. Regenerar `db/schema.rb`, seeds e fixtures mínimos para BRL, USD, fontes e usuário administrativo.
3. Configurar inflexões em português e usar `self.table_name` somente quando necessário.
4. Implementar models finos, constraints, serviços de registro, confirmação, reversão e projeção.
5. Implementar reconstrução integral da carteira e tarefa `carteiras:reconstruir_posicoes`.
6. Reescrever consultas de posição atual, posição histórica e caixa, eliminando N+1.
7. Reescrever as telas principais e remover edição direta de fatos confirmados.
8. Remover `PosicaoAtivo`, reconstruções por ativo e callbacks que geram extratos a partir de descrições.

### Etapa 2 — importação conciliável e cotações

1. Implementar normalização síncrona dos arquivos XP, Vitreo e Avenue sem armazenar o original.
2. Implementar classificação idempotente, conciliação explícita e revisão de ambiguidade.
3. Persistir cotações canônicas e prioridade simples de fontes.
4. Garantir que todas as valorizações sejam feitas somente com dados persistidos.

### Etapa 3 — referências e rentabilidade

1. Implementar versões de referência e publicação transacional.
2. Implementar `resumos_diarios_carteira` e o cálculo de TWR.
3. Recalcular resumos afetados por eventos retroativos ou novas cotações.
4. Entregar telas de rentabilidade e comparação histórica.

Cada etapa deve terminar utilizável e testada. Etapas 2 e 3 não devem ampliar a infraestrutura da etapa 1 além das necessidades descritas.

## 6. Testes e critérios de aceitação

### Integridade e consistência

- cobrir FKs, `NOT NULL`, unicidades, checks, arquivamento e propriedade entre contas;
- provar que um evento confirmado não é editado e só recebe uma reversão;
- testar rollback conjunto de evento, detalhe, caixa e posição em qualquer falha;
- testar que a consulta não observa reconstrução parcial;
- provar que replay completo gera exatamente as mesmas posições atuais;
- testar duas confirmações concorrentes na mesma carteira sem perda de atualização.

### Regras financeiras

- cobrir compra, venda parcial, zeragem, posição vendida, cobertura parcial e cruzamento de zero;
- cobrir rateio de custos, câmbio persistido, transferência de custódia, desdobramento, grupamento, incorporação e fração em dinheiro;
- testar separadamente data de negociação e data de liquidação;
- caracterizar os relatórios tributários existentes e sinalizar casos não suportados.

### Importação

- testar arquivo repetido, linha semelhante legítima, identificador externo, nova tentativa e item ambíguo;
- provar que conciliar um item com lançamento esperado não duplica o saldo;
- testar que o arquivo não é necessário depois da normalização e não fica armazenado;
- garantir que saldo informado no extrato não seja contabilizado como lançamento.

### Cotações, histórico e retorno

- testar prioridade de fontes, correção manual, cotação defasada e ausência de preço;
- provar que replay usa a taxa gravada no evento;
- testar versão de referência vigente e imutabilidade da versão publicada;
- na etapa 3, testar TWR diário, encadeamento do período, fluxo externo e valorização incompleta.

### Performance e qualidade

- `ConsultarPosicaoCarteira` deve executar um número constante de consultas de domínio, com meta de no máximo cinco;
- um teste compara carteiras com 2 e 50 ativos e garante que a quantidade de consultas não cresce;
- caixa de todas as contas é obtido em uma consulta agregada;
- nenhuma view dispara consulta por elemento e nenhuma leitura chama API externa;
- o número de eventos históricos não altera o número de consultas da posição atual;
- executar `bin/rails zeitwerk:check`, testes unitários, integração, jobs, policies e system tests;
- todo model, serviço, controller, rota, mensagem e teste novo de domínio usa português.

## 7. Evoluções condicionadas a medições reais

Somente considerar estas mudanças depois de medir um problema concreto:

- `saldos_caixa_atuais`, se a soma agregada ficar lenta;
- snapshots mensais ou diários de posições, se o replay histórico ficar lento;
- reconstrução assíncrona, se a reconstrução integral da carteira exceder o tempo aceitável;
- armazenamento temporário do arquivo e importação totalmente assíncrona, se a normalização bloquear requisições;
- múltiplas cotações brutas e seleção oficial, se houver conflitos recorrentes entre fontes;
- particionamento ou outra infraestrutura de escala, apenas se o volume deixar de ser pessoal/familiar.

## 8. Premissas fixadas

- não há dados antigos a migrar;
- o corte será Big Bang com novo baseline;
- PostgreSQL continuará sendo o único banco;
- a moeda fiscal inicial é BRL e a moeda-base da carteira é configurável;
- custo médio é o método econômico principal;
- posições vendidas, eventos corporativos, múltiplas moedas e importadores atuais permanecem suportados;
- o código de domínio continuará em português;
- a interface continuará no monólito Rails;
- Pundit continuará sendo a barreira de autorização;
- a aplicação é destinada a poucos usuários e otimiza primeiro simplicidade, correção e facilidade de manutenção.
