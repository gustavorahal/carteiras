# Contexto do domínio

Carteiras é um monólito Rails para acompanhamento financeiro long-only, com múltiplos espaços, investidores, carteiras, contas e moedas. O reconhecimento econômico segue liquidação e pagamento.

## Linguagem

- **Espaço:** contêiner de acesso e isolamento de dados.
- **Usuário:** identidade autenticável.
- **Membro:** vínculo entre usuário e espaço.
- **Investidor:** titular econômico das contas.
- **Carteira:** agrupamento exclusivo de contas para acompanhamento e rentabilidade.
- **Conta de investimento:** conta de custódia mantida em uma instituição.
- **Conta de caixa:** saldo de uma moeda dentro da conta de investimento.
- **Ativo:** item global negociável ou investível.
- **Transação financeira:** fato que começa como rascunho e se torna imutável após confirmação.
- **Lançamento de caixa:** efeito monetário assinado de uma transação.
- **Posição:** estado reconstruível de quantidade e custo de um ativo em uma conta.
- **Projeção:** dado derivado que pode ser integralmente reconstruído.

## Interfaces do domínio

Mutações financeiras atravessam `TransacoesFinanceiras`, leituras agregadas atravessam `ConsultasFinanceiras` e escritas de cotação atravessam `Mercado`. Controllers e jobs não chamam projetores ou mecanismos internos. `posicoes_atuais` é a única projeção persistida; caixa vem do livro de lançamentos e histórico, resultados e TWR são calculados sob demanda.

Espaço é o limite de autorização. Catálogos de moedas, instituições, ativos e fontes são globais e administrados pelo administrador do sistema. Fatos confirmados e seus detalhes são imutáveis; correções produzem reversão e substituta atômicas.

Rascunhos podem registrar uma competência futura, mas só são confirmados quando essa competência chega. Assim, `posicoes_atuais` permanece uma projeção puramente derivada de fatos já reconhecidos, e consultas nunca precisam escrever no banco nem depender de um job adicional para a virada da data.
