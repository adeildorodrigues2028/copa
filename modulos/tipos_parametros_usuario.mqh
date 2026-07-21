#ifndef COPA_TIPOS_PARAMETROS_USUARIO_MQH
#define COPA_TIPOS_PARAMETROS_USUARIO_MQH

enum ENUM_OPERACAO_CANAIS
{
   CANAIS_DESATIVADO    = 0, // DESATIVADO
   CANAIS_SOMENTE_COMPRA= 1, // SOMENTE COMPRA
   CANAIS_SOMENTE_VENDA = 2, // SOMENTE VENDA
   CANAIS_AMBOS         = 3  // AMBOS
};

enum ENUM_MODO_DECISAO_CANAIS
{
   CANAIS_TODOS_CONFIRMAM                  = 0, // TODOS DEVEM CONFIRMAR
   CANAIS_MINIMO_CONFIRMACOES              = 1, // USAR QUANTIDADE MINIMA
   CANAIS_BOLLINGER_KELTNER_OBRIGATORIOS   = 2, // BOLLINGER E KELTNER OBRIGATORIOS
   CANAIS_POC_OBRIGATORIO                  = 3, // REGIAO DE MAIOR VOLUME OBRIGATORIA
   CANAIS_FUNDO_TETO_OBRIGATORIO           = 4  // FUNDO OU TETO OBRIGATORIO
};

enum ENUM_MODO_DX_CALIBRACAO_FIX425
{
   DX_RIGIDO_FIX425    = 0, // HILO E STR no mesmo candle
   DX_NORMAL_FIX425    = 1, // HILO OU STR em ate N candles; recomendado
   DX_AGRESSIVO_FIX425 = 2  // candle direcional, HILO ou STR; mais sinais
};

enum ENUM_TEMA_PAINEL
{
   TEMA_ESCURO = 0, // ESCURO — fundo preto
   TEMA_CLARO  = 1  // CLARO — fundo branco
};

enum ENUM_MODO_PAINEL_VISUAL
{
   PAINEL_VISUAL_SLIM      = 0, // PEQUENO — mostra somente o essencial
   PAINEL_VISUAL_COMPLETO  = 1, // COMPLETO — mostra todas as informações
   PAINEL_VISUAL_REDUZIDO  = 2, // REDUZIDO — ocupa menos espaço
   PAINEL_VISUAL_OFF       = 3  // ESCONDIDO — não desenha o painel
};

// FIX285: cada Magic possui estado operacional independente.
enum ENUM_CONTROLE_OPERACAO_FIX284
{
   CONTROLE_OPERACAO_ATIVO_FIX284     = 0,
   CONTROLE_OPERACAO_PAUSADO_FIX284   = 1,
   CONTROLE_OPERACAO_ENCERRADO_FIX284 = 2
};

enum ENUM_MODO_AUMENTO_EXECUCAO
{
   AUMENTO_SEQUENCIAL         = 0,
   AUMENTO_INTELIGENTE_SCORE  = 1,
   AUMENTO_SCORE_RISCO        = 2
};

enum ENUM_MODO_GATILHO_AUMENTOS
{
   AUMENTOS_POR_REGRA_ATUAL       = 0, // DISTÂNCIA — reforça ao alcançar a próxima distância
   AUMENTOS_SOMENTE_POR_SCORE     = 1  // CONFIRMAÇÕES — reforça somente com sinais fortes
};

enum ENUM_BASE_PRECO_AUMENTO
{
   BASE_ULTIMO_AUMENTO       = 0, // ÚLTIMO REFORÇO — começa a contar novamente
   BASE_ENTRADA_INICIAL      = 1, // PRIMEIRA ENTRADA — sempre conta desde o começo
   BASE_PRECO_MEDIO_PROTEGIDO= 2  // PREÇO MÉDIO — conta a partir do preço médio protegido
};

enum ENUM_TF_FILTROS_OPERACIONAIS
{
   FILTROS_CANDLE_M5  = 5,  // M5 — resposta mais rápida
   FILTROS_CANDLE_M10 = 10  // M10 — contexto mais filtrado
};

enum ENUM_MODO_VALIDACAO_EXECUCAO
{
   VALIDAR_A0_APENAS      = 0, // SOMENTE ENTRADA — não testa reforços
   VALIDAR_A0_E_AUMENTOS  = 1, // ENTRADA E REFORÇOS — teste completo das ordens
   OPERAR_COMPLETO        = 2  // OPERAÇÃO NORMAL — usa todas as regras
};

// FIX302: o mesmo MQ5 testa o fluxo livre ou o fluxo completo com filtros.
enum ENUM_CENARIO_AUDITORIA_FIX302
{
   AUD302_USAR_CONFIG_ATUAL = 0, // USAR ESTA TELA — respeita as escolhas atuais
   AUD302_TESTE_SEM_FILTROS = 1, // TESTE LIVRE — entra sem filtros de confirmação
   AUD302_TESTE_COM_FILTROS = 2  // TESTE COM FILTROS — exige todas as confirmações
};

// FIX305: modo de custo financeiro do ativo.
// MANUAL usa o custo TOTAL ida+volta por contrato somente quando o volume e encerrado.
enum ENUM_MODO_COMISSAO_FIX305
{
   COMISSAO_MANUAL_IDA_VOLTA_FIX305 = 0, // VALOR INFORMADO — usa o custo digitado abaixo
   COMISSAO_SERVIDOR_FIX305 = 1,         // CORRETORA — usa o custo enviado pela corretora
   COMISSAO_AUTO_FIX305 = 2              // AUTOMÁTICO — corretora; se faltar, usa o valor informado
};

enum ENUM_SELECAO_HEAD_OPERACAO
{
   HEAD_OPERAR_AUTOMATICO       = 0,
   HEAD_OPERAR_SOMENTE_COMPRA   = 1,
   HEAD_OPERAR_SOMENTE_VENDA    = 2,
   HEAD_OPERAR_CONFIRMAR_OPOSTO = 3
};

enum ENUM_PERIODO_HISTORICO_PAINEL
{
   HIST_PAINEL_INVALIDO  = -1, // fotografia ainda nao calculada
   HIST_PAINEL_DIA       = 0,  // somente hoje, 00:00 ate agora
   HIST_PAINEL_ONTEM     = 1,  // somente ontem, 00:00 ate 23:59:59
   HIST_PAINEL_7D        = 2,  // janela exclusiva de 7 dias
   HIST_PAINEL_15D       = 3,  // janela exclusiva de 15 dias
   HIST_PAINEL_30D       = 4,  // janela exclusiva de 30 dias
   HIST_PAINEL_TUDO      = 5,  // todo o historico disponivel
   HIST_PAINEL_OPERACAO  = 100 // ciclo operacional atual; nunca reutiliza cache de periodo
};

enum ENUM_FONTE_MAGIC_PAINEL
{
   PAINEL_MAGIC_MOTOR_ATUAL = 0,
   PAINEL_MAGIC_FIXO_AB     = 1
};

enum ENUM_PAINEL_CARD_LOCAL
{
   PAINEL_CARD_AUTO = 0, // Escolher automaticamente
   PAINEL_CARD_A    = 1, // Mostrar no lado A
   PAINEL_CARD_B    = 2  // Mostrar no lado B
};

enum ENUM_TIPO_OPERACAO_ROBO
{
   OPERACAO_COMPRA = 0,   // Somente compra / BUY
   OPERACAO_VENDA  = 1,   // Somente venda / SELL
   OPERACAO_AMBOS  = 2    // Compra e venda
};

// FIX378: escolhas visiveis e humanizadas na aba Parametros.
enum ENUM_OPERACAO_USUARIO_FIX378
{
   COMPRADO = 0, // COMPRADO — permite somente ordens de compra
   VENDIDO  = 1, // VENDIDO — permite somente ordens de venda
   AMBOS    = 2  // AMBOS — permite compra e venda
};

enum ENUM_JANELA_USUARIO_FIX378
{
   JANELA_A = 0, // JANELA A — instancia principal de compra
   JANELA_B = 1  // JANELA B — instancia reservada para venda
};

enum ENUM_MODO_ENTRADA_A0_FIX310
{
   A0_FIX310_LIVRE          = 0, // LIVRE — entra normalmente para teste
   A0_FIX310_FAVOR          = 1, // A FAVOR — acompanha o movimento principal
   A0_FIX310_CONTRA         = 2, // CONTRA — espera sinal confirmado de possível virada
   A0_FIX310_FAVOR_E_CONTRA = 3  // AMBOS — aceita a favor ou contra confirmado
};

enum ENUM_JANELA_GRAFICO_AR100
{
   JANELA_A_COMPRA = 0, // COMPRA — use no gráfico reservado para compras
   JANELA_B_VENDA  = 1  // VENDA — use no gráfico reservado para vendas
};

enum ENUM_COMO_ABRIR_PRIMEIRA_ORDEM
{
   PRIMEIRA_ORDEM_DESLIGADA       = 0, // DESLIGADA — não abre uma nova operação
   PRIMEIRA_ORDEM_NORMAL          = 1, // NORMAL COM SINAIS — respeita todos os filtros
   PRIMEIRA_ORDEM_LIVRE_PROTEGIDA = 2  // LIVRE COM PROTEÇÕES — testa entradas sem filtros e sem repetição
};

enum ENUM_REGIME_CORREDOR_FIX338
{
   CORREDOR_FIX338_AGUARDA = 0,
   CORREDOR_FIX338_FORTE   = 1,
   CORREDOR_FIX338_NEUTRO  = 2,
   CORREDOR_FIX338_VIRADA  = 3
};

enum ENUM_AMBIENTE_EXECUCAO_FIX342
{
   AMBIENTE_FIX342_DEMO = 0, // DEMO — padrão seguro para testes e homologação
   AMBIENTE_FIX342_REAL = 1  // REAL — exige conta, servidor, confirmação e auditoria aprovados
};

enum ENUM_REFERENCIA_PRECO_FIX344
{
   REFERENCIA_FIX344_ABERTURA_HOJE = 0,   // Abertura da sessao atual / candle D1
   REFERENCIA_FIX344_AJUSTE_ATUAL = 1,    // Ajuste da sessao informado pela corretora
   REFERENCIA_FIX344_AJUSTE_ANTERIOR = 2, // Fechamento do candle D1 anterior
   REFERENCIA_FIX344_MEDIA_AJUSTES = 3    // Media entre ajuste anterior e atual
};


#endif // COPA_TIPOS_PARAMETROS_USUARIO_MQH
