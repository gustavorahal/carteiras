# Contexto do domínio

Carteiras é um monólito Rails para acompanhamento financeiro long-only, com múltiplos espaços, investidores, carteiras, contas e moedas. O reconhecimento econômico segue liquidação e pagamento.

## Linguagem

- **Espaço:** contêiner de acesso e isolamento de dados.
- **Usuário:** identidade autenticável.
- **Membro:** vínculo entre usuário e espaço.
- **Investidor:** titular econômico das contas.
- **Carteira:** agrupamento exclusivo de contas para acompanhamento e rentabilidade.
- **Conta de investimento:** conta de custódia mantida em uma instituição.
- **Conta de caixa:** livro e saldo de uma moeda dentro da conta de investimento.
- **Ativo:** item global negociável ou investível.
- **Categoria de alocação:** classificação editável do papel de um ativo em uma carteira, independente de seu tipo e da conta onde está custodiado.
- **Transação financeira:** fato que começa como rascunho e se torna imutável após confirmação.
- **Lançamento de caixa:** efeito monetário assinado de uma transação.
- **Posição:** estado reconstruível da quantidade de um ativo em uma conta; seu custo pode ser conhecido ou desconhecido.
- **Custo desconhecido:** ausência documentada do custo de aquisição; não equivale a custo zero e impede apenas métricas que dependem do custo.
- **Variação da cotação:** mudança do preço de mercado entre duas datas, sem considerar quantidade, custo, negociações ou proventos; não é a rentabilidade do investidor.
- **Saldo inicial de posição:** fato de implantação que inaugura uma posição documentada, sem gerar caixa.
- **Saldo inicial de caixa:** fato de implantação que estabelece o valor documentado de uma conta de caixa sem representar aporte.
- **Saldo da conta de investimento:** visão derivada das posições e dos saldos de suas contas de caixa; nunca é um fato armazenado.
- **Transferência de custódia:** deslocamento de quantidade e custo proporcional entre contas do mesmo investidor.
- **Evento corporativo:** transformação manual de quantidade ou de ativo que preserva o custo econômico.
- **Importação financeira:** análise auditável de uma nota ou extrato externo; nunca é o próprio fato financeiro.
- **Projeção:** dado derivado que pode ser integralmente reconstruído.

## Interfaces do domínio

Mutações financeiras atravessam `TransacoesFinanceiras`, importações atravessam `ImportacoesFinanceiras`, leituras agregadas atravessam `ConsultasFinanceiras` e escritas de cotação atravessam `Mercado`. Adapters de corretoras criam somente rascunhos por meio da interface financeira; controllers não chamam projetores ou persistem fatos diretamente. `posicoes_atuais` é a única projeção persistida; caixa vem do livro de lançamentos e histórico, resultados e TWR são calculados sob demanda.

Arquivos importados são processados sincronicamente e não são armazenados. O registro persistente conserva checksum, parser, dados extraídos, pendências e vínculos com os rascunhos. Notas XP/Avenue e extratos XP/Avenue compartilham essa fronteira; divergências de caixa ou quantidade nunca geram ajuste automático.

Espaço é o limite de autorização. Catálogos de moedas, instituições, ativos e fontes são globais e administrados pelo administrador do sistema. Fatos confirmados e seus detalhes são imutáveis; correções produzem reversão e substituta atômicas.

Rascunhos podem registrar uma competência futura, mas só são confirmados quando essa competência chega. Assim, `posicoes_atuais` permanece uma projeção puramente derivada de fatos já reconhecidos, e consultas nunca precisam escrever no banco nem depender de um job adicional para a virada da data.
