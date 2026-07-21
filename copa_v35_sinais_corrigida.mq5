// V107 FIX458 - PRESERVA HISTORICO AO TROCAR MAGICS 222050/222051 -> 326050/326051
// V105 FIX456 - MAGICS PADRAO AJUSTADOS: COMPRA 326050 | VENDA 326051
// V104 FIX455 - CORRIGE INDICE DO REARME DE VENDA: remove uso fora de escopo e grava timer no agendamento correto
// V106 FIX457 - RECUPERA HISTORICO APOS REINICIO | MAGICS 326050/326051
// V90 FIX441 - CORRIGE LOG maxContratos; JANELAS A1-A5 SEM LIMITE GLOBAL
// V88 FIX439 - A1 unico a 1000 pontos; stop R$500; MOVEL 25/10 e TRAIL 50/25 reais no motor

// FIX439 - CONFIGURACAO OPERACIONAL APROVADA NO TESTE:
// A0=1C | PERDA=R$500 | MOVEL=25/10 | TRAIL=50/25 CONTINUO.
// A1=1C | DISTANCIA=1000 PONTOS DESDE A0 | TIMER=120S | RSI7 70/30 | AGRESSAO>=60 | FORCA>=60.
// A2/A3/A4=DESLIGADOS. A1 possui protecao individual por ticket e nao pode repetir no mesmo ciclo.
// FIX411: DX adaptativo conectado como filtro separado para A0 e A1-A4.
// Janelas, distancias, trailing e protecoes financeiras preservados.
// COPA / AR100 - FIX384 TIMER OPERACIONAL PERMANENTE
// Base operacional: FIX382. Nenhuma funcao alcancavel por OnInit, OnTick, OnTimer,
// OnTradeTransaction, OnChartEvent ou OnDeinit foi modificada.
// Limpeza aplicada: historico antigo do cabecalho, prototipos sem uso e funcoes
// sem caminho de execucao. Entradas A0, aumentos A1-A4, RSI, timer, linha+candle,
// preco melhor, risco, reentrada, trailing, painel e historico ativo preservados.
// FIX415: MsgBox visual totalmente removida; auditoria de entrada/parcial/trailing permanece somente nos logs Experts.
// FIX416: remove completamente a linha dinamica CHECK/ESC/LOSS do painel; novo Magic continua com historico isolado e zerado.
// FIX394: trailing 20/5 com prioridade total no Timer; fecha antes de parcial, aumento ou gain concorrente.
// IMPORTANTE: validar compilacao no MetaEditor e executar Strategy Tester antes de conta real.

#property strict
#property version   "3.40"
#property description "COPA / AR_100 - operação, histórico e painel"
#include "modulos/texto.mqh"
#include "modulos/identidade_texto.mqh"
#include "modulos/horario.mqh"
// FIX362: recurso visual removido; RSI/agressao continuam somente no calculo interno.
// FIX346: recurso DX externo removido; fallback visual interno ja existente sera utilizado.


// ============================================================================
// FIX426 - DX cirurgico: preserva calibracao FIX425 e adiciona distancia minima,
// candle direcional, rompimento do candle anterior, bloqueio de sinais repetidos e uma seta por regiao.
// FIX425 - DX calibrado: perfil NORMAL, faixa 45/85, amostra 14, liberacao 65,
// tolerancia de 50 pontos na media e confirmacao HILO OU STR em ate 2 candles.
// FIX424 - PARAMETROS DO MOTOR CANAIS ORGANIZADOS APOS OS GRUPOS EXISTENTES; A1-A4 REMOVIDOS DA ABA.
// FIX423 - MOTOR CANAIS independente (Bollinger + Keltner + POC + Fundo/Teto)
// ============================================================================
enum ENUM_OPERACAO_CANAIS
{
   CANAIS_DESATIVADO    = 0, // DESATIVADO
   CANAIS_SOMENTE_COMPRA= 1, // SOMENTE COMPRA
   CANAIS_SOMENTE_VENDA = 2, // SOMENTE VENDA
   CANAIS_AMBOS         = 3  // AMBOS
};

enum ENUM_MODO_DECISAO_CANAIS
{
   CANAIS_TODOS_CONFIRMAM                  = 0,
   CANAIS_MINIMO_CONFIRMACOES              = 1,
   CANAIS_BOLLINGER_KELTNER_OBRIGATORIOS   = 2,
   CANAIS_POC_OBRIGATORIO                  = 3,
   CANAIS_FUNDO_TETO_OBRIGATORIO           = 4
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

// ============================================================================
// PARÂMETROS VISÍVEIS — somente decisões operacionais.
// Aparência, cores, plotagens, geometria do painel, relatórios e desempenho
// permanecem internos para manter esta aba limpa, lógica e segura.
// ============================================================================
// ============================================================================
// ABA PARAMETROS COMPACTA - REGRA CONGELADA FIX373
// Uma linha reune os valores do mesmo assunto. Use CHAVE=VALOR e separe por |.
// Campos NULO/VAZIO nao participam. Os exemplos abaixo sao os valores de teste.
// ============================================================================

input group "00 | TESTE COMPLETO - TICKS REAIS E EXPORTACAO"
input bool InpTesteTicksCompletoFIX433 = true;
input int InpTesteDiasFIX433 = 90;
input bool InpTesteExportarCadaTickFIX433 = true;
input bool InpTesteExportarPosicoesFIX433 = true;
input bool InpTesteExportarNegociosFIX433 = true;
input bool InpTesteExportarSomenteTestadorFIX433 = false;
input int InpTesteFlushSegundosFIX433 = 5;
input double InpTesteAtivaZeroReaisFIX433 = 25.0;
input double InpTesteDefesaPassoReaisFIX433 = 25.0;
input double InpTesteTrailingAtivaReaisFIX433 = 50.0;
input double InpTesteTrailingDistanciaReaisFIX433 = 25.0;
input bool InpTesteExportarMinutoFIX435 = true; // Exporta um registro por candle M1 fechado.
input int InpTestePOCPeriodoFIX435 = 100; // Candles usados no POC aproximado por volume.
input int InpTestePOCFaixaPontosFIX435 = 10; // Tamanho do bin do POC em pontos.
input int InpTesteBollPeriodoFIX435 = 20;
input double InpTesteBollDesvioFIX435 = 2.0;
input int InpTesteKeltEMA_FIX435 = 20;
input int InpTesteKeltATR_FIX435 = 10;
input double InpTesteKeltMultiplicadorFIX435 = 1.5;
input int InpTesteHiloPeriodoFIX435 = 14;
input int InpTesteSTRPeriodoFIX435 = 14;

input group "01 | MAGIC E OPERACAO"
input string InpMatrizMagicsFIX378 = "MAGIC_COMPRA=326050 | MAGIC_VENDA=326051"; // Ex.: compra usa 326050 e venda usa 326051.
input ENUM_OPERACAO_USUARIO_FIX378 InpOperacaoUsuarioFIX378 = COMPRADO; // Escolha no box: COMPRADO, VENDIDO ou AMBOS.
input ENUM_JANELA_USUARIO_FIX378 InpJanelaUsuarioFIX378 = JANELA_A; // Escolha no box: JANELA A ou JANELA B.

input group " "
input group "02 | ENTRADA INICIAL A0"
input string InpMatrizHeadEntradaFIX373 = "ENTRADA=1C | ALVO=50 | PERDA=500 | TRAIL=50/25 | MOVEL=25/10"; // FIX439: A0 ativa MOVEL em +R$25, defende +R$10; TRAIL continuo ativa em +R$50 com distancia de R$25.
input string InpMatrizReentradaFIX373 = "REENT_GANHO=5S | REENT_PREJUIZO=120S"; // Ex.: apos ganho espera 5s; apos prejuizo espera 120s.

input group "  "
input group "03 | CONTROLE FINANCEIRO"
input string InpMatrizFinanceiroFIX373 = "PERDA_DIA=1000 | PERDA_OPERACAO=500 | GANHO_DIA=1000 | GANHO_OPERACAO=50"; // Ex.: bloqueia em -R$1000 no dia, encerra a operacao em -R$500 e busca R$50 por operacao.
input string InpMatrizEscalaHeadFIX373 = "ATIVA=SIM | INICIO=250 | DEFESAS=50/100/150 | RECUOS=75/100/150 | ACIMA600=100/50 | SEM_TETO=SIM"; // 250/300/350 defendem; 400/500/600 usam os recuos; depois segue sem limite

input group "   "
input group "04 | FILTROS DA ENTRADA A0"
input string InpMatrizFiltrosEntradaFIX373 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | CONFIRMA=0 | TEMPO=M5"; // Ex.: tudo NULO deixa a entrada A0 livre.

input group "    "
input group "05 | GERENCIADOR DE AUMENTOS A1-A5"
input string InpMatrizControleAumentosFIX373 = "USAR=SIM | MAX=4 | SEQUENCIA=A1-A2-A3-A4 | TIMER=5S_TESTE | BASE=A0"; // FIX440: o usuario escolhe de 0 a 5 janelas; sem limite global pela soma dos contratos.
input int InpIntervaloMinimoEntreAumentosSegundosFIX434 = 5; // Trava global entre A1 e A2. Minimo recomendado: 120 segundos.
input string InpA1ExecucaoFIX340 = "A1=1C | ESPERA=0M | DIST=25 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // A1: EXECUCAO E PROTECAO DO CONTRATO | ZERO E TRAIL SAO INDIVIDUAIS POR TICKET.
input string InpA2ExecucaoFIX340 = "A2=1C | ESPERA=0M | DIST=50 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // A2: EXECUCAO E PROTECAO DO CONTRATO | ZERO E TRAIL SAO INDIVIDUAIS POR TICKET.
input string InpA3ExecucaoFIX340 = "A3=1C | ESPERA=0M | DIST=75 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // A3: EXECUCAO E PROTECAO DO CONTRATO | ZERO E TRAIL SAO INDIVIDUAIS POR TICKET.
input string InpA4ExecucaoFIX340 = "A4=1C | ESPERA=0M | DIST=100 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // A4 configuravel pelo usuario.
input string InpA5ExecucaoFIX340 = "A5=0C | ESPERA=0M | DIST=0 | MOVEL=0/0 | TRAIL=0/0"; // A5 configuravel pelo usuario.
input int InpRSIPeriodoAumentosFIX399 = 7; // PERIODO DO RSI | USADO SOMENTE QUANDO O USUARIO ESCOLHER RSI EM A1-A5.
input string InpAjudaFiltrosAumentosFIX407 = "EXEMPLOS: RSI + VOLUME + AGRESSAO + FORCA + HILO8 + STR + MEDIA | NULO DESLIGA"; // AJUDA RAPIDA: escolha os filtros desejados em cada aumento.
input string InpFiltroA1CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // A1 FILTROS: escolha RSI, VOLUME, AGRESSAO, FORCA, HILO8, STR, MEDIA ou NULO.
input string InpFiltroA2CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // A2 FILTROS: escolha RSI, VOLUME, AGRESSAO, FORCA, HILO8, STR, MEDIA ou NULO.
input string InpFiltroA3CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // A3 FILTROS: escolha RSI, VOLUME, AGRESSAO, FORCA, HILO8, STR, MEDIA ou NULO.
input string InpFiltroA4CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // A4 FILTROS configuraveis.
input string InpFiltroA5CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // A5 FILTROS configuraveis.
string InpMatrizFiltrosAumentosFIX373 = "F1=RSI | F2=NULO | F3=NULO"; // Compatibilidade interna; cada nivel usa seu filtro proprio FIX375.
input bool InpMostrarCaixasLinhasOperacionaisFIX399 = false; // NÃO: mantém as linhas e remove as caixas de mensagens que piscavam no gráfico.

input group "     "
input group "06 | JANELAS DA ENTRADA A0 - FILTROS PRIORITARIOS"
input string InpMatrizJanela1FIX373 = "HORARIO=09:00-10:00 | F1=NULO | F2=NULO | F3=NULO"; // Se houver filtro, ele prevalece; se todos forem NULO, usa o filtro normal da entrada
input string InpMatrizJanela2FIX373 = "HORARIO=10:00-12:00 | F1=NULO | F2=NULO | F3=NULO"; // Janela 2 da entrada A0
input string InpMatrizJanela3FIX373 = "HORARIO=12:00-15:00 | F1=NULO | F2=NULO | F3=NULO"; // Janela 3 da entrada A0
input string InpMatrizJanela4FIX373 = "HORARIO=15:00-18:00 | F1=NULO | F2=NULO | F3=NULO"; // Janela 4 da entrada A0

input group "      "
input group "07 | FILTRO DX ADAPTATIVO - OPERACIONAL"
input bool InpDXAdaptativoAtivoFIX410 = true; // Liga o filtro DX separado sem alterar as janelas existentes.
input bool InpDXPlotarBandasFIX410 = true; // Media central continua; bandas superior/inferior pontilhadas.
input bool InpDXUsarA0FIX411 = true; // Aplica a confirmacao DX na entrada inicial A0.
input bool InpDXUsarAumentosFIX411 = false; // Aplica a confirmacao DX nos aumentos A1-A4.
input bool InpDXEntradaProximoCandleFIX411 = true; // Confirma no candle fechado e libera na abertura do candle seguinte.
input int InpDXMediaPeriodoFIX411 = 25; // Periodo livre da media usada pelo DX.
input ENUM_MA_METHOD InpDXMediaMetodoFIX411 = MODE_SMA; // Metodo livre: SMA, EMA, SMMA ou LWMA.
input ENUM_APPLIED_PRICE InpDXMediaPrecoFIX411 = PRICE_CLOSE; // Preco aplicado na media.
input int InpDXAmostraCandlesFIX411 = 14; // Candles fechados usados para distancia media e distancia extrema.
input string InpDXAberturaManualFIX411 = "ATE=09:25 | DX=1000P"; // Antes da medicao completa usa distancia manual sem alterar as janelas.
input double InpDXManualAberturaPontosFIX411 = 1000.0; // Distancia manual usada antes do horario de corte.
input string InpDXHorarioInicioAutoFIX411 = "09:25"; // A partir deste horario o DX passa ao calculo automatico.
input double InpDXForcaBloqueioContraFIX411 = 75.0; // Forca contraria igual ou maior bloqueia entrada contra.
input double InpDXForcaLiberacaoFIX411 = 65.0; // So rearma quando a forca contraria cair para este nivel ou menos.
input double InpDXPercentualExtremoMinFIX411 = 45.0; // Forca baixa usa 60% da maior distancia recente.
input double InpDXPercentualExtremoMaxFIX411 = 85.0; // Explosao usa ate 100% da maior distancia recente.
input int InpDXBarrasPlotadasFIX411 = 120; // Reserva visual; bandas atuais sao atualizadas no grafico.
input string InpDXComponentesForcaFIX410 = "HILO + STR + VOL QTD + VOL FIN + RSI + INCLINACAO"; // Seis componentes, cada um participa do medidor 0-100.

input group "08 | TESTE VISUAL ENTRADAS DX + HILO14 + STR14 M5"
input bool InpVisualHilo14STR4AtivoFIX418 = true; // Marca somente onde seria entrada por DX + HILO14 + STR14; nao envia ordens.
input ENUM_TIMEFRAMES InpVisualHilo14STR4TempoFIX418 = PERIOD_M5; // Timeframe fixo sugerido para o teste.
input int InpVisualHiloPeriodoFIX418 = 14; // HILO14: media das maximas e minimas anteriores.
input int InpVisualSTRPeriodoFIX418 = 14; // STR14: compara o fechamento com quatorze candles anteriores.
input int InpVisualHiloSTRBarrasFIX418 = 180; // Reserva/limite minimo de candles para o teste visual.
input int InpVisualDiasHistoricosFIX422 = 5; // Quantidade de dias corridos para tras analisados e marcados no grafico.
input double InpVisualSTRCorpoMinimoFIX418 = 0.35; // Corpo minimo do candle em relacao ao range.
input ENUM_MODO_DX_CALIBRACAO_FIX425 InpDXModoCalibracaoFIX425 = DX_NORMAL_FIX425; // NORMAL aumenta sinais sem liberar entradas aleatorias.
input int InpDXCandlesConfirmacaoFIX425 = 2; // Quantos candles apos o retorno a media podem confirmar HILO/STR.
input double InpDXToleranciaMediaPontosFIX425 = 50.0; // Aceita retorno proximo da media, sem exigir fechamento perfeito alem dela.
input double InpDXDistanciaMinimaArmarFIX426 = 200.0; // Distancia minima entre extremo e media para armar o setup visual.
input bool InpDXExigirRompimentoCandleAnteriorFIX426 = true; // Compra rompe maxima anterior; venda rompe minima anterior.
input bool InpDXExigirCandleDirecionalFIX426 = true; // Compra exige candle comprador; venda exige candle vendedor.
input int InpDXBloqueioMesmoLadoCandlesFIX426 = 3; // Evita setas repetidas do mesmo lado na mesma regiao.
input string InpDXRegraCompactaFIX410 = "NORMAL: EXTREMO >=200P -> RETORNO -> HILO/STR -> CANDLE DIRECIONAL + ROMPIMENTO";
input string InpDXVisualCompactoFIX410 = "DX ATUAL + FORCA COMPRA/VENDA + REGIME + LIBERADO/BLOQUEADO";

input group "08.1 | DX MASTER - MELHORES ENTRADAS"
input bool InpDXMasterAtivoFIX430 = true;
input bool InpDXMasterMostrarSomenteMelhoresFIX430 = true;
input bool InpDXMasterExigirPOCFIX430 = true;
input bool InpDXMasterExigirBollOuKeltFIX430 = true;
input int InpDXMasterMinimoExtrasFIX430 = 2;
input bool InpDXMasterUsarFundoTetoFIX430 = true;
input int InpDXMasterPeriodoPOCFIX430 = 100;
input int InpDXMasterFaixaPOCPontosFIX430 = 10;
input double InpDXMasterDistanciaPOCPontosFIX430 = 50.0;
input int InpDXMasterPeriodoBollFIX430 = 20;
input double InpDXMasterDesvioBollFIX430 = 2.0;
input int InpDXMasterPeriodoEMAFIX430 = 20;
input int InpDXMasterPeriodoATRFIX430 = 10;
input double InpDXMasterMultiplicadorKeltFIX430 = 1.5;
input int InpDXMasterPeriodoFundoTetoFIX430 = 100;
input double InpDXMasterDistanciaTetoFundoPontosFIX430 = 30.0;

input group "       "
input group "08 | SEGURANCA E EXECUCAO"
input string InpMatrizAmbienteFIX373 = "AMBIENTE=DEMO | CONFIRMAR_REAL=NAO | CONTA=0 | SERVIDOR=VAZIO"; // Para conta real, todos os dados devem ser confirmados conscientemente
input string InpMatrizProtecoesFIX373 = "SL=SIM/2000 | SPREAD=4 | TICK=5S | MARGEM=1000/300% | MAX_AB=10 | LIQ=5"; // Protecoes tecnicas reunidas em uma linha
input string InpMatrizCustosFIX373 = "VENCIMENTO=2D | INTERVALO_REAL=2S | COMISSAO=MANUAL/0/SIM | DESVIO_A0=20"; // Vencimento, intervalo, custos e desvio da entrada inicial

input group "        "
input group "09 | ENCERRAMENTO DO DIA"
input string InpMatrizEncerramentoFIX373 = "BLOQUEAR=18:00 | ZERAR=SIM | HORARIO=18:15"; // Bloqueia novas ordens e define a zeragem obrigatoria

input group "         "
input group "10 | TESTE E AUDITORIA"
input string InpMatrizTesteFIX373 = "TESTE=A0+A1-A4 | AUDITORIA=CONFIG_ATUAL"; // A0 usa a linha USAR=NAO; A1-A4 mantem RSI proprio, timer, distancia e gatilho.

input group "11 | MOTOR CANAIS - ATIVACAO E OPERACAO"
input bool InpUsarMotorCanais = true;
input ENUM_OPERACAO_CANAIS InpOperacaoMotorCanais = CANAIS_AMBOS;
input ENUM_TIMEFRAMES InpTimeframeCanais = PERIOD_M1;
input long InpMagicCompraCanais = 888060;
input long InpMagicVendaCanais  = 888061;

input group "12 | MOTOR CANAIS - INDICADORES"
input bool InpCanaisUsarBollinger = true;
input int InpCanaisPeriodoBollinger = 20;
input double InpCanaisDesvioBollinger = 2.0;
input bool InpCanaisUsarKeltner = true;
input int InpCanaisPeriodoEMA = 20;
input int InpCanaisPeriodoATR = 10;
input double InpCanaisMultiplicadorKeltner = 1.5;
input bool InpCanaisUsarPOC = true;
input int InpCanaisPeriodoPOC = 100;
input int InpCanaisFaixaPrecoPOCPontos = 10;
input double InpCanaisDistanciaMinimaPOCPontos = 50;
input bool InpCanaisUsarFundoTeto = true;
input int InpCanaisPeriodoFundoTeto = 100;
input double InpCanaisDistanciaMinimaFundoPontos = 30;
input double InpCanaisDistanciaMinimaTetoPontos = 30;
input bool InpCanaisPermitirRompimentoConfirmado = true;

input group "12.1 | MOTOR CANAIS - VISUAL NO GRAFICO"
input bool InpCanaisMostrarBollingerGrafico = false;
input bool InpCanaisMostrarKeltnerGrafico = false;
input bool InpCanaisMostrarPOCGrafico = true;
input bool InpCanaisMostrarEntradasHistoricasGrafico = true;
input int InpCanaisVisualHistoricoCandles = 600;
input int InpCanaisVisualDistanciaSetaPontos = 25;
input bool InpComparativoDXCanaisAtivo = true;
input int InpComparativoToleranciaCandles = 2;
input bool InpComparativoDestacarConcordancias = true;

input group "13 | MOTOR CANAIS - DECISAO"
input ENUM_MODO_DECISAO_CANAIS InpModoDecisaoCanais = CANAIS_TODOS_CONFIRMAM;
input int InpConfirmacoesMinimasCanais = 3;
input bool InpCanaisConfirmarCandleFechado = true;
input int InpCanaisCandlesConfirmacao = 1;
input int InpCanaisTempoRearmeSegundos = 120;

input group "14 | MOTOR CANAIS - CONTRATO E SAIDAS"
input int InpCanaisContratoA0 = 3; // Quantidade escolhida pelo usuario.
input bool InpCanaisUsarParcial = true; // Realiza parte da posicao e mantem runner.
input int InpCanaisContratosParcial = 1; // Quantidade da primeira parcial.
input double InpCanaisAlvoFinanceiro = 50.0; // Gatilho financeiro da parcial.
input bool InpCanaisFecharTudoNoAlvo = false; // SIM fecha tudo; NAO fecha apenas a parcial.
input double InpCanaisStopFinanceiro = 500.0; // Stop financeiro total do Motor Canais.
input double InpCanaisMovelAtiva = 50.0; // Runner ativa defesa.
input double InpCanaisMovelDefende = 0.0; // Runner defende este valor.
input double InpCanaisTrailingAtiva = 75.0; // Runner ativa trailing continuo.
input double InpCanaisTrailingPasso = 25.0; // Defesa = melhor lucro - distancia.
input bool InpCanaisSairPerdaSinal = true;

// Valores internos alimentados pelas matrizes compactas. Nao aparecem na aba.
ENUM_TIPO_OPERACAO_ROBO InpLadosHabilitadosFIX346 = OPERACAO_AMBOS;
ENUM_JANELA_GRAFICO_AR100 InpJanelaDesteGrafico = JANELA_A_COMPRA;
string InpMagicsCompraVenda = "326050 / 326051";
bool InpAtivarRobo = true;
bool InpPermitirEnvioOrdens = true;
ENUM_COMO_ABRIR_PRIMEIRA_ORDEM InpComoAbrirPrimeiraOrdem = PRIMEIRA_ORDEM_LIVRE_PROTEGIDA;
ENUM_MODO_ENTRADA_A0_FIX310 InpModoEntradaCompra = A0_FIX310_LIVRE;
ENUM_MODO_ENTRADA_A0_FIX310 InpModoEntradaVenda = A0_FIX310_LIVRE;
int InpContratosA0FIX372 = 1;
double InpGanhoPorTicketReaisFIX372 = 50.0;
double InpPerdaPorTicketReaisFIX372 = 100.0;
double InpTrailingAtivarTicketReaisFIX372 = 20.0;
double InpTrailingPassoTicketReaisFIX372 = 5.0;
double InpMovelAtivarTicketReaisFIX395 = 25.0; // FIX439: A0 arma em +R$25.
double InpMovelPassoTicketReaisFIX395 = 10.0;  // FIX439: defesa inicial +R$10 antes do trailing 50/25.
double InpGarantiaPorContratoReaisFIX372 = 100.0;
double InpGarantiaPorLadoReaisFIX372 = 500.0;
bool InpMetaDiaEscalonadaAtiva = true;
double InpProtecaoDiaAtivarReais = 250.0;
double InpProtecaoDiaInicialReais = 50.0;
double InpDefesaEscala300ReaisFIX372 = 100.0;
double InpDefesaEscala350ReaisFIX372 = 150.0;
double InpRecuoEscala400ReaisFIX372 = 75.0;
double InpRecuoEscala500ReaisFIX372 = 100.0;
double InpRecuoEscala600ReaisFIX372 = 150.0;
double InpPassoLucroAcima600ReaisFIX372 = 100.0;
double InpAumentoRecuoAcima600ReaisFIX372 = 50.0;
int InpReentradaLucroSegundosFIX372 = 5;
int InpPausaReentradaSegundos = 120;
string InpFiltroA0_1_FIX372 = "NULO";
string InpFiltroA0_2_FIX372 = "NULO";
string InpFiltroA0_3_FIX372 = "NULO";
ENUM_TF_FILTROS_OPERACIONAIS InpTimeframeFiltrosOperacionais = FILTROS_CANDLE_M5;
int InpDXPeriodo = 2;
int InpDXMediaPeriodo = 2;
double InpDXDistanciaMedia = 0.0;
int InpQuantidadeReforcos = 5;
ENUM_MODO_GATILHO_AUMENTOS InpModoGatilhoAumentos = AUMENTOS_POR_REGRA_ATUAL;
ENUM_BASE_PRECO_AUMENTO InpBasePrecoAumento = BASE_ENTRADA_INICIAL;
string InpFiltroAumento_1_FIX372 = "NULO";
string InpFiltroAumento_2_FIX372 = "NULO";
string InpFiltroAumento_3_FIX372 = "NULO";
string InpJanela1HorarioFIX372 = "09:00-10:00";
string InpJanela1Filtro1FIX372 = "NULO";
string InpJanela1Filtro2FIX372 = "NULO";
string InpJanela1Filtro3FIX372 = "NULO";
string InpJanela2HorarioFIX372 = "10:00-12:00";
string InpJanela2Filtro1FIX372 = "NULO";
string InpJanela2Filtro2FIX372 = "NULO";
string InpJanela2Filtro3FIX372 = "NULO";
string InpJanela3HorarioFIX372 = "12:00-15:00";
string InpJanela3Filtro1FIX372 = "NULO";
string InpJanela3Filtro2FIX372 = "NULO";
string InpJanela3Filtro3FIX372 = "NULO";
string InpJanela4HorarioFIX372 = "15:00-18:00";
string InpJanela4Filtro1FIX372 = "NULO";
string InpJanela4Filtro2FIX372 = "NULO";
string InpJanela4Filtro3FIX372 = "NULO";
ENUM_AMBIENTE_EXECUCAO_FIX342 InpAmbienteExecucaoFIX342 = AMBIENTE_FIX342_DEMO;
bool InpConfirmarContaRealFIX342 = false;
long InpContaRealAutorizadaFIX342 = 0;
string InpServidorRealAutorizadoFIX342 = "";
bool InpStopServidorEmergenciaAtivoFIX342 = true;
double InpStopServidorEmergenciaPontosFIX342 = 2000.0;
double InpSpreadMaximoTicksFIX342 = 4.0;
int InpTickMaximoIdadeSegundosFIX342 = 5;
double InpMargemLivreMinimaReaisFIX342 = 1000.0;
double InpNivelMargemMinimoPercentFIX342 = 300.0;
double InpMaxContratosBrutosABFIX342 = 10.0;
double InpMaxExposicaoLiquidaABFIX342 = 5.0;
int InpBloquearDiasAntesVencimentoFIX342 = 2;
int InpIntervaloMinimoOrdensRealSegFIX342 = 2;
ENUM_MODO_COMISSAO_FIX305 InpModoComissaoAtivoFIX305 = COMISSAO_MANUAL_IDA_VOLTA_FIX305;
double InpComissaoIdaVoltaPorContratoReaisFIX305 = 0.0;
bool InpComissaoAfetaFinanceiroRoboFIX305 = true;
int InpDesvioMaximoPontos = 20;
string InpHorarioBloquearNovasOperacoes = "18:00";
bool InpFechamentoFimDiaAtivo = true;
string InpHorarioFecharTudo = "18:15";
ENUM_MODO_VALIDACAO_EXECUCAO InpModoValidacaoExecucao = VALIDAR_A0_E_AUMENTOS;
ENUM_CENARIO_AUDITORIA_FIX302 InpCenarioAuditoriaFIX302 = AUD302_USAR_CONFIG_ATUAL;

// FIX372: campos tecnicos/legados permanecem internos para reduzir e ordenar a aba Parametros.
string InpHorariosEntradaA0 = "09:00-10:00;10:00-12:00;12:00-15:00;15:00-18:00";
string InpHorariosFiltros = "09:00-10:00;10:00-12:00;12:00-15:00;15:00-18:00";
string InpHorariosAumentos = "00:00-23:59"; // Aumentos nao usam as janelas da A0; somente o bloqueio geral do dia
string InpEntradaA0QuantidadeAlvoFIX340 = "QTD=1C | ALVO=50";
string InpEntradaA0PerdaTrailingFIX340 = "PERDA=500 | TRAIL=50/25"; // FIX442
string InpRiscoAumentosFIX340 = "ALVO=50 | PERDA=500";
string InpA1TrailingFIX340 = "TRAIL=50/25";
string InpA2TrailingFIX340 = "TRAIL=0/0";
string InpA3TrailingFIX340 = "TRAIL=0/0";
string InpA4TrailingFIX340 = "TRAIL=50/25";
string InpA5TrailingFIX340 = "TRAIL=50/25";
double InpMargemExecucaoAlemLinhaPontos = 0.1;
bool   InpAumentoRomperExtremoCandle = false;
double InpAumentoFolgaRompimentoPontos = 0.0;
int    InpAumentoValidadeRompimentoCandles = 3;
string InpTrailingInteligenteLinhasFIX325 = "OFF | ATIVA=75 | PASSO=35 | DIST=75 | REDUZ=OFF | REDUZ_PTS=35 | MIN=10 | APITO=OFF";
string InpFiltrosProjetoFIX324 = "LIVRE";
bool   InpScoreVolumeAumentosAtivo = false;
int    InpScoreVolumeMediaCandles = 20;
bool   InpScoreVolumeAjustarForcaMercado = true;
double InpScoreVolumeMinA1 = 45.0;
double InpScoreVolumeMinA2 = 60.0;
double InpScoreVolumeMinA3 = 75.0;
double InpScoreVolumeMinA4 = 90.0;
bool   InpFiltroRangeAtivoFIX344 = false;
ENUM_REFERENCIA_PRECO_FIX344 InpRangeReferenciaFIX344 = REFERENCIA_FIX344_AJUSTE_ANTERIOR;
double InpRangeMinimoPontosFIX344 = 1000.0;
double InpRangeMaximoPontosFIX344 = 2000.0;
bool   InpGridEntradasAtivoFIX344 = false;
ENUM_REFERENCIA_PRECO_FIX344 InpGridReferenciaFIX344 = REFERENCIA_FIX344_ABERTURA_HOJE;
double InpGridTamanhoPontosFIX344 = 500.0;
double InpGridToleranciaPontosFIX344 = 5.0;
double InpFIX280GainHeadABReais = 100.0; // Calculado automaticamente: ganho por ticket x lados habilitados
double InpFIX280LossHeadABReais = 1000.0; // Calculado automaticamente: garantia por lado x lados habilitados
bool   InpStopDinamicoHeadFIX359 = false; // FIX442: PERDA individual configurada fica efetiva.
double InpProtecaoDiaDegrauReais = 50.0; // Compatibilidade; formula FIX372 usa os niveis explicitos
double InpProtecaoDiaFolgaReais = 200.0; // Compatibilidade
bool   InpCorredorLucroAtivo = false; // FIX379: desativa corredor antigo; usa trailing simples 20/5 da A0.
double InpCorredorAtivarReais = 20.0;
double InpCorredorPisoInicialReais = 5.0;
double InpCorredorDegrauReais = 20.0;
double InpCorredorFolgaForteReais = 5.0;
double InpCorredorFolgaNeutraReais = 5.0;
double InpCorredorFolgaViradaReais = 5.0;
int    InpCorredorConfirmacoesVirada = 2;
bool   InpCorredorAlvoPontaViraMarco = true;
bool   InpCorredorMetaABViraMarco = true;

// Controles internos de painel, plotagem e relatórios. Não aparecem na aba.
ENUM_MODO_PAINEL_VISUAL InpModoPainelVisual = PAINEL_VISUAL_COMPLETO;
ENUM_TEMA_PAINEL InpTemaPainel = TEMA_ESCURO;
bool InpFIX284MostrarBotoesControle = true;
bool InpFIX287UltraLeve = true;
int  InpFIX287PainelIntervaloSegundos = 1;
bool InpMostrarTelaAuditoriaFIX302 = false;
bool InpExportacaoSemanalMeses2FIX306 = true;
int  InpExportacaoMesesFIX306 = 2;

// Configurações internas mantidas fora da aba de parâmetros.
bool InpExigirContaDemo = true;
string InpEntradaOperacao = "QTD=1C | ALVO=100 | PERDA=300 | TRAIL=20/5";
string InpGestaoAumentosFIX324 = "QTD=1C | TIMER=0M | GATILHO=0 | DIST=25 | ALVO=10 | PERDA=500 | TRAIL=50/25"; // FIX442 base interna; janelas A1-A5 prevalecem
double InpContratosPorReforco = 1.0;
int    InpDistanciaEntreReforcosPontos = 100;
int    InpEsperaAntesReforcoMinutos = 0;
double InpFIX280AlvoPorPontaReais = 100.0;
double InpLossEntradaLocalReaisFIX321 = 300.0;
double InpFIX280TrailingAtivarReais = 20.0;
double InpFIX280TrailingPassoReais = 5.0;
double InpLucroAumentoPorContratoReaisFIX207 = 10.0; // FIX439: alvo individual do A1; trailing pode deixar correr antes do fechamento no alvo conforme configuracao.
double InpLossAumentoPorContratoReaisFIX321 = 500.0;
bool   InpAumentoFecharNoAlvoFIX281 = true; // FIX442: R$50 arma trailing; nao fecha no alvo fixo.
double InpTrailingAumentoAtivarReaisFIX281 = 50.0;
double InpTrailingAumentoPassoReaisFIX281 = 25.0;
bool   g_trailInteligenteLinhasAtivoFIX325 = false; // FIX442: prioridade para TRAIL financeiro individual.
double g_trailInteligenteAtivaPontosFIX325 = 75.0;
double g_trailInteligentePassoPontosFIX325 = 35.0;
double g_trailInteligenteDistanciaPontosFIX325 = 75.0;
bool   g_trailInteligenteReduzirFIX325 = true;
double g_trailInteligenteReducaoPontosFIX325 = 35.0;
double g_trailInteligenteDistanciaMinimaPontosFIX325 = 10.0;
bool   g_trailInteligenteApitarFIX325 = true;
string InpAumentos = "ON;DIR=CONTRA;LIVRE_TESTE=ON;LIVRE_TOTAL=ON;IGNORAR_META_DIA=OFF;MAX_AUMENTOS=4;MAX_CONTRATOS=100000;VALIDACAO=OFF"; // FIX357: filtros livres, mas respeita distância e limite
string InpConfirmacaoLinhasAumentos = "FECHAMENTO | M1 | 0P | PRECO MELHOR"; // FIX363 obrigatório: toque -> candle M1 -> filtros -> preço melhor
string InpA1 = "1 | 0M | 0G | D25 | TRAIL=50/25 | ON";
string InpA2 = "1 | 0M | 0G | D50 | TRAIL=50/25 | ON";
string InpA3 = "1 | 0M | 0G | D75 | TRAIL=50/25 | ON";
string InpA4 = "1 | 0M | 0G | D100 | TRAIL=50/25 | ON";
string InpA5 = "0 | 0M | 0G | D0 | TRAIL=0/0 | OFF";
string InpPerfilFiltrosAuditoriaFIX302 = "MIN 6 DE 9 | HILO8 / STR / DX25 / RSI 30/70 / VOLUME QTD+FIN / AGR 50 / FORCA 60 / FIBO 1.272 / WAPBANDS 1.0";
string InpA1Filtros = "LIVRE";
string InpA2Filtros = "LIVRE";
string InpA3Filtros = "LIVRE";
string InpA4Filtros = "LIVRE";
string InpA5Filtros = "LIVRE";
bool   InpFIX280UsarCamposClaros = true; // FIX331: gain/loss visíveis do MESTRE comandam o ciclo
int    InpExportacaoLoteBarrasFIX306 = 250;
int    InpExportacaoLimiteMicrosTimerFIX306 = 25000;
bool   InpExportacaoArquivoComumFIX306 = true;
bool   InpExportacaoCapturarGraficoFIX306 = true;

// Proteções internas. Não aparecem na aba para manter a configuração compacta.
bool InpFIX279EntradaDiretaDemo = false; // FIX318: ativado internamente quando a primeira ordem estiver em LIVRE PROTEGIDA.
bool InpFIX293TesteDX2ZeroAmbosLados = false; // Compatibilidade interna: teste extremo sempre desligado.
const int InpMaxSaidasEmCincoMinutosFIX313 = 8;
const int InpJanelaProtecaoRepeticaoSegundosFIX313 = 300;
const double InpToleranciaFinanceiraPercentualFIX313 = 0.05;
const double InpToleranciaFinanceiraMinimaFIX313 = 0.10;

// ============================================================================
// PARAMETROS INTERNOS CONGELADOS DO FIX288 - NAO APARECEM NA ABA
// NENHUM DEFAULT FOI ALTERADO E NAO EXISTE FUNCAO DE CONVERSAO/MAPEAMENTO.
// ============================================================================
const bool            InpExigirContaHedge        = true; // Regra interna: conta HEDGING obrigatoria
const bool            InpFIX278UmaJanelaAbreDuasPontas = false; // FIX288 interno: DESATIVADO; A=BUY e B=SELL sempre separados
bool                  InpTesteLivreEntradaA0     = false; // Regra interna: a entrada normal precisa de sinal válido
bool                  InpAumentosDistanciaAbsolutaEntrada = true; // FIX357: distâncias iniciais absolutas desde A0
bool InpRearmarA1AposParcialFIX225 = true; // FIX248 interno: rearme dinamico sempre ativo
bool InpRearmarA1SomenteQuandoVoltarBaseFIX225 = false; // FIX248 compatibilidade: regra antiga desativada
bool                  InpValidacaoLiberarFiltrosEntradaAumento = false; // FIX249 interno: filtros nunca são liberados artificialmente
bool                  InpValidacaoIgnorarJanelaHoraria = false; // Regra interna: horários sempre são respeitados
const bool            InpBloquearMesmoSentidoQualquerMagicMesmoAtivo = false; // FIX315: outro Magic não bloqueia o Magic local; duplicidade local continua protegida
bool            InpAuditoriaTesteFIX274 = false; // FIX293: auditoria informativa desligada para nao bloquear o teste de entradas
bool            InpBloquearOrdensSeAuditoriaFalharFIX274 = false; // FIX293: nenhuma ordem de teste e bloqueada por auditoria antiga
int             InpFIX279RepetirTentativaSeg = 2; // Repetir ordem rejeitada a cada N segundos
bool            InpFIX279MostrarDiagnosticoReal = true; // Mostrar permissao de trade, retcode e erro no painel
bool            InpExecutarSomenteNovoCandleEntrada = true; // Regra interna: no máximo uma validação de entrada por candle
string          InpParcialOperacao        = "AUM_ALVO=50R/C | TRAIL=20/5 | FECHA=1C | MODO=POR_TICKET"; // FIX357: parcial por ticket em +R$50
string          InpVolumeCurvaHora        = "ON;HOR=09:15-17:15;SLOT=60m;BASE=ONTEM;AJUSTAR_DIA=ON;FORTE=1.30;EXT=1.80;VOLQ=ON;VOLF=ON"; // Comparar o volume com o mesmo horário do dia anterior
string          InpVolumeCurto            = "ON;J1=5m;J2=15m;FORTE=1.50;EXT=2.00;QTD=ON;FIN=ON"; // Comparar o volume recente de 5 e 15 minutos
bool            InpPlotarCandlesContra             = false; // FIX353: calculo continua; desenho do candle contra fica oculto
bool            InpContraModoCirurgico              = true; // ON: usa setup de exaustão + quebra de estrutura; OFF: mantém score antigo
double          InpContraRSISobrecompra             = 70.0; // Setup de VENDA: RSI chegou a 70 ou mais
double          InpContraRSISobrevenda              = 30.0; // Setup de COMPRA: RSI chegou a 30 ou menos
int             InpContraJanelaSetupBarras          = 15; // Procurar a barra extrema nas últimas 15 barras fechadas
bool            InpContraExigirSetupMesmaBarra      = true; // RSI, HiLo/STR, volume, agressão e distância devem coincidir na mesma barra
bool            InpContraExigirRetornoRSI           = true; // Só confirma depois de o RSI sair da região extrema
double          InpContraRSIRetornoVenda            = 65.0; // Venda: RSI precisa retornar para 65 ou menos
double          InpContraRSIRetornoCompra           = 35.0; // Compra: RSI precisa retornar para 35 ou mais
bool            InpContraExigirCruzamentoRSI        = true; // Exigir cruzamento real do nível de retorno, não apenas permanecer do outro lado
int             InpContraJanelaRetornoRSIBarras     = 3; // Cruzamento do RSI pode ter ocorrido no candle atual ou nos 2 anteriores
bool            InpContraExigirHiLoESTR             = true; // Exigir HiLo8 E STR juntos no impulso extremo
double          InpContraAgressaoMinima             = 60.0; // Agressão mínima do impulso antes da reversão
double          InpContraAgressaoReversaoMinima     = 55.0; // Agressão mínima do lado novo no candle de confirmação
int             InpContraMaxTicksAgressao           = 256; // Amostra leve de negócios; limite interno máximo de 512
int             InpContraVolumeMediaPeriodo         = 20; // Média anterior para Volume Quantidade e Financeiro
double          InpContraVolumeMultiplicador        = 1.10; // Setup exige QTD e FIN pelo menos 15% acima da média
int             InpContraATRPeriodo                 = 14; // Período do ATR usado para medir afastamento do preço
double          InpContraDistanciaMinATR            = 0.70; // Distância mínima simples; Fibo faz a validação principal de exaustão
bool            InpContraUsarFiboExaustao           = true; // Usar níveis Fibonacci para validar esticamento total
bool            InpContraFiboObrigatorio             = true; // Exigir pelo menos Fibo 1.272 no setup extremo
double          InpContraFiboNivelMinimo             = 1.272; // Exaustão normal: extensão mínima 127,2%
double          InpContraFiboNivelForte              = 1.618; // Exaustão forte: extensão 161,8%
int             InpContraFiboLookbackEstrutural      = 21; // Barras anteriores usadas para medir a extensão do range
bool            InpContraUsarPivoFiboFIX269          = true; // Modo principal: entrada por pivô local confirmado + Fibo como decisão
int             InpContraPivoLookbackFIX269          = 7; // Pivô precisa superar as 7 barras anteriores
int             InpContraJanelaConfirmacaoPivoFIX269 = 3; // Confirmar o topo/fundo entre 1 e 3 candles depois
double          InpContraRSIPivoVendaFIX269          = 65.0; // Zona antecipada de venda; RSI 70 continua sendo exaustão forte
double          InpContraRSIPivoCompraFIX269         = 35.0; // Zona antecipada de compra; RSI 30 continua sendo exaustão forte
int             InpContraRSIExtremoRecenteFIX269     = 4; // Procurar RSI 70/30 também nas barras imediatamente anteriores ao pivô
double          InpContraFiboPivoMinimoFIX269        = 0.786; // Fibo mínimo como confirmação de esticamento local
bool            InpContraFiboPivoObrigatorioFIX269   = false; // OFF: Fibo soma pontos; ON: todo sinal exige pelo menos 0.786
double          InpContraPavioMinimoPivoFIX269       = 0.25; // Rejeição mínima pelo pavio do topo/fundo
double          InpContraCorpoMinEntradaPivoFIX269   = 0.22; // Corpo mínimo do candle pintado
double          InpContraDistanciaPivoATR_FIX269     = 0.35; // Distância mínima da média 8 usada como confirmação
double          InpContraVolumePivoMinimoFIX269      = 1.00; // Volume do pivô em relação à média; 1.00 = igual à média
double          InpContraAgressaoPivoMinimaFIX269    = 55.0; // Pressão mínima no movimento que chegou ao extremo
double          InpContraDeltaRSIPivoFIX269          = 2.0; // RSI precisa começar a retornar pelo menos esta quantidade
int             InpContraScoreMinimoPivoFIX269       = 7; // Score mínimo balanceado; faixa recomendada 6 a 9
bool            InpContraUsarCruzamentoFIX270         = true; // FIX270: modo principal, um sinal somente quando a média rápida cruza a lenta
int             InpContraMediaRapidaFIX270            = 5; // Média rápida usada no disparo
int             InpContraMediaLentaFIX270             = 13; // Média lenta usada no disparo
int             InpContraMediaContextoFIX270          = 34; // Média maior usada apenas para medir o contexto
int             InpContraJanelaCruzamentoFIX270       = 3; // Cruzamento pode ocorrer no candle atual ou nos 2 anteriores
int             InpContraJanelaPivoFIX270             = 8; // O topo/fundo deve ter ocorrido até 8 candles antes da entrada
int             InpContraLookbackPivoFIX270           = 8; // Pivô precisa superar as 8 barras anteriores
double          InpContraRSIArmarVendaFIX270          = 65.0; // Topo: RSI mínimo para armar possível venda
double          InpContraRSIArmarCompraFIX270         = 35.0; // Fundo: RSI máximo para armar possível compra
double          InpContraRSIDisparoVendaFIX270        = 62.0; // Venda: RSI precisa retornar até 62 ou menos
double          InpContraRSIDisparoCompraFIX270       = 38.0; // Compra: RSI precisa retornar até 38 ou mais
double          InpContraRetornoRSIMinFIX270          = 4.0; // RSI deve afastar pelo menos 4 pontos do extremo do pivô
double          InpContraCorpoMinEntradaFIX270        = 0.28; // Corpo mínimo do candle de entrada
double          InpContraFechamentoExtremoFIX270      = 0.42; // Venda fecha nos 42% inferiores; compra nos 42% superiores
int             InpContraMicroestruturaFIX270         = 2; // Romper máxima/mínima das 2 barras anteriores
double          InpContraAgressaoEntradaFIX270        = 55.0; // Pressão mínima do lado da reversão no candle pintado
int             InpContraScoreSetupMinFIX270          = 6; // Qualidade mínima do pivô antes de permitir o cruzamento
int             InpContraExtrasEntradaMinFIX270       = 2; // Além do cruzamento, exigir 2 confirmações técnicas
bool            InpContraExigirInclinacaoLentaFIX270  = false; // Opcional: exigir que a média 13 já esteja inclinada para a reversão
bool            InpContraFiboObrigatorioFIX270        = false; // OFF recomendado: Fibo melhora a qualidade, mas não bloqueia todo pivô
double          InpContraFiboMinimoFIX270             = 0.786; // Extensão mínima que soma qualidade ao setup
bool            InpContraEtiquetaSomenteLadoFIX270    = true; // Mostrar apenas C ou V para evitar poluição visual
bool            InpContraUsarOTTFIX271                 = false; // OFF no FIX273: OTT fica disponivel como confirmacao opcional do Darvas
int             InpContraOTTPeriodoFIX271              = 5; // Periodo da media VAR/VIDYA do OTT; M1 recomendado: 4 a 8
double          InpContraOTTPercentualFIX271           = 0.55; // Percentual do OTT; menor reage rapido, maior filtra ruido
int             InpContraOTTDeslocamentoFIX271         = 1; // Deslocamento confirmado usado pelo OTT original
int             InpContraOTTJanelaPivoFIX271           = 16; // Topo/fundo deve ter ocorrido ate 10 candles antes do cruzamento
int             InpContraOTTLookbackPivoFIX271         = 5; // Pivo precisa superar as barras anteriores
double          InpContraOTTRSIArmarVendaFIX271        = 63.0; // Preparar venda quando RSI atingir 65 ou mais
double          InpContraOTTRSIArmarCompraFIX271       = 37.0; // Preparar compra quando RSI atingir 35 ou menos
double          InpContraOTTRSIDisparoVendaFIX271      = 61.0; // Confirmar venda quando RSI retornar para 64 ou menos
double          InpContraOTTRSIDisparoCompraFIX271     = 39.0; // Confirmar compra quando RSI retornar para 36 ou mais
double          InpContraOTTRetornoMinimoFIX271        = 1.5; // RSI deve retornar ao menos 2 pontos desde o extremo
int             InpContraOTTScoreSetupMinFIX271        = 4; // Qualidade minima do topo/fundo antes do cruzamento
int             InpContraOTTExtrasEntradaMinFIX271     = 1; // Confirmacoes adicionais no candle pintado
double          InpContraOTTCorpoMinEntradaFIX271      = 0.14; // Corpo minimo do candle pintado
double          InpContraOTTAgressaoEntradaFIX271      = 52.0; // Agressao minima do lado da reversao
bool            InpContraOTTExigirCruzSuporteFIX271    = false; // Exigir cruzamento da linha de suporte com a OTT
bool            InpContraOTTAceitarCruzPrecoFIX271     = true; // Permitir que cruzamento do preco reforce o sinal
int             InpContraOTTJanelaConfirmacaoFIX272     = 3; // Cruzamento pode ser confirmado no candle atual ou nos 2 seguintes
bool            InpContraOTTAceitarPivoFlexivelFIX272    = true; // Aceitar RSI extremo com rejeicao/Fibo/distancia, sem exigir maxima absoluta
bool            InpContraOTTFiboObrigatorioFIX271      = false; // OFF: Fibo melhora o setup sem eliminar todas as entradas
double          InpContraOTTFiboMinimoFIX271           = 0.786; // Fibo minimo que soma qualidade ao setup
bool            InpContraOTTPlotarLinhasFIX271         = true; // Desenhar suporte e OTT no grafico
int             InpContraOTTBarrasLinhasFIX271         = 400; // Quantidade de barras das linhas visuais
color           InpContraOTTCorSuporteFIX271           = clrAqua; // Cor da linha de suporte VAR/VIDYA
color           InpContraOTTCorLinhaFIX271             = clrMagenta; // Cor da linha OTT
bool            InpContraUsarDarvasFIX273               = true; // Modo principal: falso rompimento da caixa Darvas
int             InpContraDarvasPeriodoFIX273            = 18; // Barras anteriores usadas para formar suporte e resistencia
int             InpContraDarvasJanelaConfirmacaoFIX273  = 3; // Confirmar o retorno para dentro da caixa em ate 3 candles
double          InpContraDarvasRSIVendaFIX273           = 70.0; // Venda: RSI extremo no rompimento do topo
double          InpContraDarvasRSICompraFIX273          = 30.0; // Compra: RSI extremo no rompimento do fundo
double          InpContraDarvasRSIRetornoVendaFIX273    = 66.0; // Venda: RSI precisa retornar para 66 ou menos
double          InpContraDarvasRSIRetornoCompraFIX273   = 34.0; // Compra: RSI precisa retornar para 34 ou mais
double          InpContraDarvasBufferATR_FIX273         = 0.04; // Margem minima alem da borda da caixa em fracao do ATR
double          InpContraDarvasAlturaMinATR_FIX273      = 0.70; // Ignorar caixas estreitas demais
double          InpContraDarvasCorpoMinFIX273           = 0.22; // Corpo minimo do candle de confirmacao
double          InpContraDarvasPavioMinFIX273           = 0.18; // Rejeicao minima no candle que ultrapassa a borda
double          InpContraDarvasVolumeMinFIX273          = 1.00; // Volume QTD e FIN minimo em relacao a media
double          InpContraDarvasAgressaoEntradaFIX273    = 54.0; // Agressao minima do lado da reversao
int             InpContraDarvasExtrasMinFIX273          = 2; // Confirmacoes adicionais: volume/agressao/estrutura/OTT/Fibo/HiLo-STR
int             InpContraDarvasMicroestruturaFIX273     = 2; // Rompimento da microestrutura usado como confirmacao
bool            InpContraDarvasUsarOTTConfirmacaoFIX273 = true; // OTT soma qualidade, mas nao gera entrada sozinho
bool            InpContraDarvasExigirOTT_FIX273         = false; // OFF recomendado para nao eliminar todos os sinais
bool            InpContraDarvasPlotarCaixasFIX273       = false; // FIX280: nao desenhar linhas/caixa; manter somente candles VDB/CDB
int             InpContraDarvasBarrasVisuaisFIX273      = 350; // Quantidade de barras com linhas Darvas
color           InpContraDarvasCorTopoFIX273            = clrOrangeRed; // Resistencia da caixa
color           InpContraDarvasCorFundoFIX273           = clrDeepSkyBlue; // Suporte da caixa
color           InpContraDarvasCorMeioFIX273            = clrSilver; // Linha central opcional
bool            InpContraDarvasPlotarMeioFIX273         = false; // Mostrar metade da caixa
int             InpContraMinExtrasSetup              = 2; // Entre Volume, Agressão e Distância, exigir pelo menos 2 confirmações
int             InpContraMinConfirmacoesSegundo      = 2; // Segundo candle: mínimo de confirmações técnicas adicionais
double          InpContraCorpoMinConfirmacao        = 0.50; // Corpo do candle de confirmação: mínimo de 50% da barra
double          InpContraFechamentoZonaPercent      = 30.0; // Venda fecha nos 30% inferiores; compra nos 30% superiores
bool            InpContraExigirRompimentoAnterior   = true; // Exigir rompimento, engolfo ou rejeição da barra anterior
bool            InpContraExigirQuebraEstrutura      = true; // Venda rompe mínimas anteriores; compra rompe máximas anteriores
int             InpContraEstruturaBarras            = 2; // Quantidade de barras anteriores usadas na microestrutura
bool            InpContraExigirCruzamentoMedia8     = true; // Venda cruza e fecha abaixo da média 8; compra cruza e fecha acima
double          InpContraMargemMediaATR             = 0.05; // Fechamento deve ultrapassar a média por 0,05 ATR
bool            InpContraExigirSegundoCandle        = true; // FIX267: pintar somente após um segundo candle confirmar o gatilho
int             InpContraMediaTendenciaPeriodo      = 21; // Média usada para bloquear entrada contra tendência ainda saudável
bool            InpContraExigirMedia8x21            = true; // Venda: média 8 abaixo da 21; compra: média 8 acima da 21
double          InpContraMargemEntradaATR           = 0.01; // Segundo candle deve romper o gatilho por esta fração do ATR
double          InpContraMargemMedia21ATR           = 0.01; // Fechamento além da média 21 por esta fração do ATR
double          InpContraMaxNovaExtremaATR          = 0.20; // Tolerância para não criar nova máxima/mínima após o gatilho
double          InpContraDeltaRSIMinimo             = 1.0; // RSI do segundo candle precisa avançar ao menos 2 pontos na reversão
double          InpContraRSILimiteEntradaVenda      = 64.0; // Entrada de venda somente com RSI igual ou abaixo deste nível
double          InpContraRSILimiteEntradaCompra     = 36.0; // Entrada de compra somente com RSI igual ou acima deste nível
double          InpContraCorpoMinSegundoCandle      = 0.30; // Corpo mínimo do segundo candle em relação à amplitude
double          InpContraAgressaoEntradaMinima      = 56.0; // Pressão mínima do lado da entrada no segundo candle
int             InpContraCooldownBarras             = 10; // No máximo um sinal do mesmo lado dentro desta distância
int             InpContraManterCandlesNoGrafico     = 2500; // Manter marcações de aproximadamente 1500 barras
bool            InpContraCarregarHistorico          = true; // Analisar barras passadas mesmo sem novo tick
int             InpContraBarrasHistoricas           = 2500; // Barras fechadas analisadas na abertura
int             InpContraMinConfirmacoes            = 3; // Usado somente quando Modo Cirúrgico = OFF
bool            InpContraExigirRSIExtremo           = true; // Usado somente quando Modo Cirúrgico = OFF
bool            InpContraExigirDirecao              = true; // Usado somente quando Modo Cirúrgico = OFF
color           InpContraCorCompra                   = clrDodgerBlue; // Azul: confirmação de COMPRA contra queda
color           InpContraCorVenda                    = clrYellow; // Amarelo: confirmação de VENDA contra alta
bool            InpContraMostrarDiagnostico         = false; // FIX295: aviso visual removido; calculos permanecem ativos
bool            InpContraMostrarSetaConfirmacao     = true; // Mostrar seta no candle confirmado
int             InpContraTamanhoSeta                = 3; // Tamanho da seta: 1 a 5
int             InpContraLarguraVisualBarras        = 2; // Largura do destaque: 1 a 5 candles
bool            InpContraMostrarEtiqueta            = true; // Mostrar C ou V junto da seta
string InpJanela1Filtros = "HILO8 / STR / VOLUME QTD+FIN / DX25 / RSI 30/70 / AGR 50%"; // Regra normal da primeira janela
string InpJanela2Filtros = "HILO8 / STR / VOLUME QTD+FIN / DX25 / RSI 30/70 / AGR 50%"; // Regra normal da segunda janela
string InpJanela3Filtros = "HILO8 / STR / VOLUME QTD+FIN / DX25 / RSI 30/70 / AGR 50%"; // Regra normal da terceira janela
string InpJanela4Filtros = "HILO8 / STR / VOLUME QTD+FIN / DX25 / RSI 30/70 / AGR 50%"; // Regra normal da quarta janela
bool            InpBloquearAumentosAposParcial   = false; // Depois de uma parcial, não adicionar mais contratos neste ciclo
string InpAumentosSomenteScore = "HILO8=ON;STR=ON;VOLQ=ON;VOLF=ON;PESO_HILO8=25;PESO_STR=25;PESO_VOLQ=25;PESO_VOLF=25;MIN_A1=50;MIN_A2=75;MIN_A3=100;MIN_A4=100;MIN_A5=100;EXIGIR_DIRECAO=ON"; // Score dos aumentos: itens, pesos e mínimo de cada nível
string InpScoreHistorico = "ON | ONTEM POR HORA | DIA ATUAL"; // Score adaptativo: compara o pregão anterior no mesmo horário e ajusta pelo ritmo acumulado de hoje; remova DIA ATUAL ou use OFF
bool            InpTravarContaDemoAutorizada = false; // Permitir somente uma conta demonstrativa específica
long            InpContaDemoAutorizada    = 0; // Número da conta permitida (0 = aceitar qualquer conta demo)
bool            InpBloquearSePosicaoInicial = false; // Não iniciar se já existir posição aberta no ativo
bool            InpUsarSTFTAntiReentrada  = true; // Esperar antes de abrir uma nova operação após uma saída
bool            InpReentradaTambemAposLucro      = true; // FIX372: lucro usa pausa configurada de 5 segundos
int             InpFimDiaIntervaloTentativaSegundos = 2; // Intervalo entre tentativas de zerar tudo (ex.: 2 segundos)
bool            InpStopOperacaoCestaABAtivo = true; // FIX320: MESTRE supervisiona LOSS HEAD A+B
double          InpStopOperacaoCestaABReais = 1000.0; // FIX372: fallback alinhado ao LOSS HEAD automatico
bool            InpGainGlobalCestaAtivo     = false; // FIX372: sem gain fixo; saida global ocorre pela defesa escalonada
double          InpGainGlobalCestaReais     = 250.0; // Marco inicial da escala; nao fecha por meta
bool            InpGainGlobalCestaZerarCiclo = true; // Após atingir a meta, encerrar o ciclo e permitir outro limpo
string          InpEscalonamentoGanhos     = "ON;NAO_PERDER_DIA=ON"; // Compatibilidade interna; valores vêm das etapas visíveis
bool            InpModoSimplesFIX195            = true; // Usar o modo simples de realização e proteção
double          InpMetaMestreABReais            = 250.0; // FIX372: marco da escala; nao e teto
bool            InpEntradaOperacaoComandaHeadAB = true; // FIX320: somente limites financeiros do MESTRE A+B
bool            InpEntradaOperacaoSomarDuasPontasHeadAB = true; // Somar os dois lados ao calcular ganho e perda do conjunto
double          InpEntradaOperacaoPontasHeadAB = 2.0; // Quantidade de lados considerada no conjunto (ex.: 2)
double          InpRealizacaoPrimeiraReais      = 20.0; // Primeiro valor para realizar lucro: R$20
double          InpRealizacaoPassoReais         = 20.0; // Próxima realização avança mais R$20
double          InpRealizacaoContratos          = 1.0; // Quantidade de contratos fechados por realização (ex.: 1)
bool            InpRealizarAumentosPorTicketFIX207 = true; // Realizar separadamente os contratos dos aumentos
double          InpParcial50PercentualMeta     = 0.0; // Percentual da meta para liberar a parcial (0 = usar valor em reais)
bool            InpParcialArmarProtecao        = true; // Depois da parcial, proteger imediatamente o lucro restante
bool            InpParcialFinalFecharTudo      = false; // Na última parcial, fechar toda a posição restante
bool            InpParcialExecutarAoTocarLinhaGrafico = true; // Executar a parcial assim que o preço tocar sua linha
bool            InpParcialLinhaGraficoUsarGrupoHeadAB = false; // FIX320: parcial calculada por lado/Magic
int             InpParcialLinhaCooldownSegundos = 2; // Evitar duas parciais iguais em sequência (ex.: 2 segundos)
bool            InpParcialForcarTotalAntesDoGain = true; // Manter a linha parcial antes da meta final
double          InpParcialRecuoMinimoPontos = 1.0; // Distância mínima da linha parcial para a entrada (ex.: 1 ponto)
bool            InpProtecaoLucroAtiva          = true; // Ligar a proteção curta de lucro
double          InpProtecaoCurtaDefesaMaxReais = 50.0; // Limite máximo defendido pela proteção curta
bool            InpProtecaoMaiorCestaABAtiva  = false; // FIX320: protecao financeira independente por lado
double          InpProtecaoMaiorAtivarEmReais = 400.0; // Ganho que liga a proteção maior (ex.: R$400)
double          InpProtecaoMaiorFolgaReais    = 300.0; // Espaço permitido para o lucro oscilar (ex.: R$300)
double          InpProtecaoMaiorPassoReais    = 50.0; // Passo da proteção maior (ex.: R$50)
bool            InpProtecaoFecharAoRetrair     = true; // Fechar quando o resultado voltar até a proteção
bool            InpHedgeRealizarLucroPontaGanhadora = true; // Realizar lucro do lado positivo mesmo com o conjunto negativo
double          InpHedgeLucroPontaPassoReais = 5.0; // Passo entre realizações do lado positivo (ex.: R$5)
double          InpHedgeLucroPontaPercentualVolume = 50.0; // Percentual do lado positivo fechado (ex.: 50%)
int             InpHedgeLucroPontaCooldownSegundos = 2; // Espera entre realizações dos dois lados (ex.: 2 segundos)
bool            InpPermitirHedgeRecuperacao      = false; // Permitir abrir o lado oposto para recuperação
bool            InpOperacaoLongaUsar           = false; // Permitir transformar uma operação vencedora em operação longa
double          InpOperacaoLongaAtivarEmReais  = 120.0; // Ganho mínimo para virar operação longa (ex.: R$120)
double          InpOperacaoLongaScoreSaida     = 40.0; // Score mínimo para continuar segurando a operação longa
bool            InpOperacaoLongaUsarHiLo        = true; // Usar HiLo para manter a operação longa
bool            InpOperacaoLongaUsarSTR         = true; // Usar STR para manter a operação longa
bool            InpOperacaoLongaUsarVolumeQtd   = true; // Usar volume em quantidade na operação longa
bool            InpOperacaoLongaUsarVolumeFin   = true; // Usar volume financeiro na operação longa
bool            InpUmaPontaPorTimeframe         = false; // Permitir somente um lado por período do gráfico
bool            InpBloquearA0OutraPontaAutomatica = false; // Após a entrada inicial, bloquear a abertura automática do outro lado
int             InpBloqueioA0AposEntradaSegundos = 0; // Espera após a entrada para a corretora atualizar a posição
int             InpIntervaloMinimoOrdensSeg     = 0; // Tempo mínimo entre duas ordens (0 = sem espera)
ENUM_ORDER_TYPE_FILLING InpTipoPreenchimentoOrdem = ORDER_FILLING_RETURN; // Forma usada pela corretora para preencher a ordem
string          InpComentarioOrdens             = "AR100_ORDEM"; // Texto curto gravado nas ordens do robô
bool            InpPermitirAssumirPosicaoInicial = true; // Permitir que o robô gerencie uma posição já aberta
ENUM_PAINEL_CARD_LOCAL InpPainelCardLocal = PAINEL_CARD_AUTO; // Escolher onde o painel será mostrado: automático, lado A ou B
int  InpPainelCardX               = 12; // Distância do painel em relação à esquerda (ex.: 12)
int  InpPainelCardY               = 28; // Distância do painel em relação ao topo (ex.: 28)
int  InpPainelCardLargura         = 1480; // Largura do painel em pixels (ex.: 1480)
int  InpPainelCardAltura          = 960; // Altura do painel em pixels (ex.: 960)
int  InpPainelFonteTitulo         = 10; // Tamanho da letra dos títulos (ex.: 10)
int  InpPainelFonteTexto          = 8; // Tamanho da letra dos textos (ex.: 8)
bool            InpFIX280PlotarBandaDXPreco = false; // FIX353: calculo DX continua; bandas visuais ficam ocultas
double          InpFIX280DistanciaBandaDXPontos = 100.0; // Ex.: 100 = media +/- 100 pontos, acompanhando os candles
int             InpFIX280BarrasBandaDX = 600; // Quantidade de barras desenhadas
bool            InpFIX280RemoverLinhasDarvas = true; // Remover linhas Darvas; nao remove os candles/sinais de entrada
bool            InpFIX283ModoLeve = true; // Reduz trabalho repetido sem alterar as regras de entrada, meta, stop ou trailing
bool            InpFIX283DesligarLogsContinuos = true; // Mantem logs de eventos importantes e desliga fotografias repetidas a cada segundo
int             InpFIX283HistoricoIntervaloSegundos = 1; // FIX353: DIA/realizado reconfirmados a cada segundo
int             InpFIX283TimerGerenciarSomenteSemTickMs = 1500; // Timer so executa o motor de ordens se o mercado estiver sem ticks por este tempo
int             InpFIX284IntervaloFechamentoMs = 1000; // Intervalo minimo entre tentativas de fechar somente o Magic local
int             InpFIX287MercadoIntervaloMinimoMs = 100; // Indicadores/filtros no maximo 10 vezes por segundo; trailing financeiro nao depende deste limite
bool            InpFIX287DesligarBandaDXObjetos = true; // Evita apagar/criar ate 1800 segmentos a cada candle
bool            InpFIX287IgnorarLogsDegrauTrail = true; // Nao grava CSV pesado quando a defesa sobe de R$5 em R$5
int             InpFIX287ReverHistoricoContraSegundos = 30; // Depois de carregado, confere os candles coloridos somente neste intervalo


// ==================================================================
// CONFIGURAÇÕES FIXAS INTERNAS — não aparecem na tela de parâmetros
// Janelas: sempre ligadas, A0 permitido e ambos os lados.
// Gráfico, histórico e registros: padrões protegidos contra alteração acidental.
// ==================================================================

ENUM_TIPO_OPERACAO_ROBO InpTipoOperacao   = OPERACAO_COMPRA; // FIX255: definido automaticamente pela janela deste gráfico
int             InpMagicA = 147025; // FIX255 interno: preenchido pela linha MAGICS COMPRA/VENDA
int             InpMagicB = 147026; // FIX255 interno: preenchido pela linha MAGICS COMPRA/VENDA
bool            InpPermitirOutraPontaSeDirecionalFavor = true; // Regra interna: permitir o segundo lado quando aprovado
bool            InpUsarCandleFiltroFechado = true; // Confirmar os filtros somente depois que o candle fechar
bool            InpDXBandasApenasLeitura   = true; // Usar as bandas de força apenas como informação
bool            InpPlotarMedia25NoGrafico  = true; // FIX385: media 25 visivel no grafico para leitura rapida das entradas
bool            InpMediaGraficoSeguirDXMedia = false; // FIX390: mantido por compatibilidade; nao trava a media
int             InpMedia25PeriodoGrafico   = 25; // FIX390: periodo LIVRE da media visual (1 a 1000)
ENUM_MA_METHOD  InpMedia25MetodoGrafico    = MODE_EMA; // Tipo de cálculo da média do gráfico
ENUM_APPLIED_PRICE InpMedia25PrecoGrafico  = PRICE_CLOSE; // Preço usado para calcular a média do gráfico
bool            InpPlotarBandasMedia25NoGrafico = false; // FIX385: somente a media 25 fica visivel por padrao
double          InpMedia25DistanciaPontos  = 100.0; // Distância das faixas em relação à média (ex.: 100 pontos)
int             InpMedia25BandasBarras     = 600; // Quantidade de candles desenhados nas faixas (ex.: 600)
bool            InpPlotarEntradasHistoricasNoGrafico = true; // FIX385: desenhar as entradas ja executadas no proprio grafico
int             InpEntradasHistoricasDias = 5; // Quantos dias para tras mostrar as setas das entradas
int             InpEntradasHistoricasMaxSetas = 120; // Limite de setas historicas para manter o grafico leve
int             InpEntradasHistoricasDeslocamentoPontos = 20; // Pequeno afastamento vertical para a seta nao cobrir o candle
int             InpEntradasHistoricasLarguraSeta = 1; // Tamanho pequeno da seta historica
bool            InpTesteHardPermitirContraM25 = true; // Em teste, permitir entrada contra a média principal
string          InpJanelasPerfilPadrao    = "HARD"; // Nível de exigência usado nos quatro horários
bool InpMostrarHistorico          = true; // Mostrar os resultados anteriores no painel
int  InpHistoricoAtualizarSegundos = 1; // Intervalo para atualizar o resultado de hoje (ex.: 1 segundo)
bool InpMostrarCardAumentosVisual = true; // Mostrar no painel a situação de A1, A2 e A3
bool InpPlotarLinhasOperacionais  = true; // Mostrar no gráfico as linhas da operação
bool InpPlotarLinhasAumentos       = true; // Mostrar as linhas de A1, A2 e A3
bool InpPlotarLinhasParciais       = true; // Mostrar as linhas das realizações parciais
int  InpPlotarLinhasParciaisQtd    = 3; // Quantidade de linhas de parcial mostradas (ex.: 3)
bool InpPlotarLinhaEntrada         = true; // Mostrar a linha do preço de entrada
bool InpParcialSubstituiLinhaEntradaAposEntrada = true; // Depois da entrada, trocar sua linha pela próxima parcial
bool InpLinhaParcialRealizadaMudaCor = true; // Mudar a cor da linha depois que a parcial for realizada
int  InpPlotLinhasLargura          = 1; // Espessura das linhas do gráfico (ex.: 1)
int  InpMsgBoxVisualSegundos       = 5; // Tempo que o aviso de entrada fica no painel
bool            InpTotalABSincronizarEntreJanelas = true; // Mostrar o mesmo total financeiro nas duas janelas
int             InpTotalABSnapshotSegundos = 1; // Tempo de validade do total compartilhado (ex.: 1 segundo)
bool            InpBaseHistoricaGerarNoInit       = false; // Ao iniciar, criar um arquivo com o histórico de preços
int             InpBaseHistoricaDias              = 62; // Quantidade de dias exportados (ex.: 62)
ENUM_TIMEFRAMES InpBaseHistoricaTFPrincipal       = PERIOD_M1; // Período principal do histórico exportado (ex.: M1)
bool            InpBaseHistoricaGerarM5           = true; // Exportar também os dados de 5 minutos
bool            InpBaseHistoricaGerarM15          = false; // Exportar também os dados de 15 minutos
int             InpBaseHistoricaMaxBarrasPorArquivo = 200000; // Máximo de candles em cada arquivo (ex.: 200.000)
string          InpBaseHistoricaPrefixoArquivo    = "AR100_BASE"; // Nome inicial dos arquivos de histórico
bool            InpBaseHistoricaArquivoComum      = true; // Salvar em uma pasta compartilhada pelos terminais
bool            InpBaseHistoricaSomenteExportar   = false; // Somente exportar dados, sem permitir ordens
bool            InpLogValidacaoCSVAtivo          = true; // Gravar um arquivo com os acontecimentos da operação
bool            InpLogValidacaoCSVCommon         = false; // Salvar o registro na pasta compartilhada dos terminais
string          InpLogValidacaoCSVPrefixo        = "AR100_EA_VALIDACAO"; // Nome inicial dos arquivos de registro
bool            InpLogValidacaoSomenteRelevantes = true; // Gravar somente entradas, saídas, parciais e proteções
bool            InpLogValidacaoFlushImediato     = false; // Salvar cada acontecimento imediatamente no disco
bool            InpLogCestaABDetalhado           = true; // Gravar detalhes financeiros dos dois lados
int             InpLogCestaABIntervaloSegundos   = 30; // Intervalo do registro detalhado (ex.: 2 segundos)
bool            InpLogCestaABNoExperts           = false; // Mostrar o resumo também na aba de mensagens do robô
bool            InpSaidaCestaABFecharGrupoInteiro = true; // Ao encerrar, fechar todas as posições do conjunto
bool            InpSaidaCestaABIgnorarInstanciaAoFecharGrupo = true; // Ao fechar o conjunto, incluir posições de outra janela
bool            InpSaidaCestaABBloquearSaidaIsoladaQuandoDuasPontas = true; // Com dois lados abertos, impedir fechamento isolado acidental
bool            InpLogHedgeCompletoAtivo        = true; // Gravar detalhes completos quando os dois lados estiverem abertos
int             InpLogHedgeCompletoIntervaloSegundos = 30; // Intervalo do registro completo (ex.: 1 segundo)
bool            InpLogHedgeCompletoListarTickets = true; // Incluir no registro os números das posições abertas
bool            InpLogStopFullHedgeAtivo        = true; // Gravar como o limite de perda do conjunto está mudando
int             InpLogStopFullHedgeIntervaloSegundos = 5; // FIX359: auditoria do stop móvel a cada 5 segundos
bool            InpLogStopPerdaHeadColunasCSV = true; // Criar colunas separadas para ganho e perda do conjunto
bool            InpLogEntradaFiltrosAtivo = true; // Gravar por que cada entrada ou aumento foi aceito ou bloqueado
bool            InpLogEntradaFiltrosColunasCSV = true; // Colocar cada confirmação em uma coluna separada
bool            InpLogEntradaFiltrosNoExperts = false; // Mostrar um resumo das confirmações na aba de mensagens

// Valores internos de compatibilidade. As escolhas visíveis vêm das linhas compactas acima.
bool                  InpParcial50Ativa = true;
double                InpParcialGatilhoReais = 15.0;
bool                  InpParcialGatilhoPorContrato = false;
double                InpParcial50PercentualVolume = 50.0;
bool                  InpParcialRecuoAumentoAtivo = true;
double                InpProtecaoAtivarEmReais = 20.0;
double                InpProtecaoTrailPassoReais = 5.0;
bool                  InpAumentoConfirmarFechamentoCandle = true;
ENUM_TIMEFRAMES       InpAumentoTimeframeConfirmacao = PERIOD_M1;
double                InpAumentoMargemFechamentoPontos = 0.0;

bool                  g_parcialOperacaoAtivaEfetiva = true;
double                g_entradaTrailingAtivarReaisEfetivo = 20.0; // FIX280: ativa em R$20
double                g_entradaTrailingPassoReaisEfetivo = 5.0;  // FIX206: passo do trailing
double                g_parcialGatilhoReaisEfetivo = 25.0;
bool                  g_parcialPorContratoEfetivo = false;
double                g_parcialPassoReaisEfetivo = 5.0;
double                g_parcialPercentualVolumeEfetivo = 50.0;
bool                  g_parcialRecuoAumentoAtivoEfetivo = true;     // FIX172: vem da aba Parametros: MODO=RECUO_AUMENTO ou MODO=TOTAL
bool                  g_parcialValorEmPontosEfetivo = true;        // FIX172: 25P/PASSO=5P sao pontos; nao financeiro escondido no codigo
string                g_assinaturaParametrosEfetivos = "";
ulong                 g_ultimoTickRecebidoMsFIX283 = 0; // FIX283: impede o timer de repetir o motor durante fluxo normal de ticks
// FIX287: limitadores de frequencia para retirar tarefas nao criticas do caminho de cada tick.
ulong                 g_ultimaAtualizacaoMercadoMsFIX287 = 0;
ulong                 g_ultimaAtualizacaoParABMsFIX287 = 0;
ulong                 g_ultimaCargaHistoricoContraMsFIX287 = 0;
ulong                 g_ultimaAtualizacaoEstadosMsFIX287 = 0;
int                   g_ultimaQtdPosicoesEstadosFIX287 = -1;
bool                  g_bandasObjetosLimpasFIX287 = false;
// FIX285: controle operacional leve, persistente e independente por Magic.
ENUM_CONTROLE_OPERACAO_FIX284 g_controleOperacaoFIX284 = CONTROLE_OPERACAO_ATIVO_FIX284;
ulong                 g_ultimaSincronizacaoControleMsFIX284 = 0;
ulong                 g_ultimaTentativaEncerrarMsFIX284 = 0;
bool                  g_fechamentoManualEmAndamentoFIX284 = false;
string                g_statusControleOperacaoFIX284 = "ATIVO";
double                InpEntradaContratos        = 1.0;                                // FIX161 interno: vem da linha compacta InpEntradaOperacao
double                InpEntradaGanhoAlvoReais   = 50.0;                                 // Valor interno lido da configuracao da entrada; nao aparece na tela.
double                InpEntradaPerdaMaximaReais = 500.0;                                // Valor interno lido da configuracao da entrada; nao aparece na tela.
int                   InpMaxAumentos = 4;
int                   InpMaxContratosTotal = 5;
ENUM_MODO_AUMENTO_EXECUCAO InpModoAumentoExecucao = AUMENTO_SEQUENCIAL;
double                InpScorePularParaA2 = 70.0;
double                InpScorePularParaA3 = 85.0;
bool                  InpPermitirAumentosNaValidacao = true;
bool                  InpValidacaoAumentoIgnorarScoreExtremo = true;
bool                  InpAumentosLivreTeste = false;     // FIX249: padrão seguro; somente LIVRE_TESTE=ON libera explicitamente
bool                  InpAumentosLivreIgnorarTimerPreco = false; // FIX133: modo seguro; respeita timer/preço dos aumentos
bool                  InpAumentosLivreIgnorarMetaDia = false; // FIX251 interno: meta diária sempre respeitada no modo operacional
bool                  InpAumentosContraPosicao = true;    // FIX113: BUY aumenta abaixo; SELL aumenta acima, modelo de recuperação/cesta
bool                  InpValidarRiscoProjetadoAumentoFIX331 = false; // FIX360: não prever perda; STOP MOVEL A+B controla o risco real
bool                  InpA1Ativo = true;
double                InpA1Contratos = 1.0;
int                   InpA1TempoMinutos = 1;
double                InpA1GatilhoReais = 25.0;
int                   InpA1DistanciaPontos = 1000;
double                InpA1ProtecaoPercent = 0.0; // FIX282 legado: substituido por TRAIL=20/5
bool                  InpA2Ativo = false;
double                InpA2Contratos = 0.0;
int                   InpA2TempoMinutos = 2;
double                InpA2GatilhoReais = 25.0;
int                   InpA2DistanciaPontos = 75;
double                InpA2ProtecaoPercent = 0.0; // FIX282 legado: substituido por TRAIL=20/5
bool                  InpA3Ativo = true;
double                InpA3Contratos = 1.0;
int                   InpA3TempoMinutos = 3;
double                InpA3GatilhoReais = 25.0;
int                   InpA3DistanciaPontos = 100;
double                InpA3ProtecaoPercent = 0.0; // FIX282 legado: substituido por TRAIL=20/5
bool                  InpAumentosUsarFiltrosHumanizados = true;
string                InpAumentosModoFiltro = "TODOS";
int                   InpAumentosMinOkFiltro = 0; // FIX135: precisa de 3 confirmações entre HiLo/STR/DX/Volume/Agressão
bool                  InpForcarPainelUsarMagicAB = true;
bool                  InpIsolarInstanciaPorParMagic = true;
string                InpIDInstanciaRobo = "";
bool                  InpAceitarPosicaoSemIDInstancia = false;
bool                  InpPainelFinanceiroPorMagic = true;
bool                  InpPainelSomarTodasInstanciasDoMagic = false; // FIX304: nunca liberar historico/posicao apenas pelo Magic
ENUM_FONTE_MAGIC_PAINEL InpPainelFonteMagic = PAINEL_MAGIC_MOTOR_ATUAL;
int                   InpMagicPainelA = 0;
int                   InpMagicPainelB = 0;
bool                  InpHistoricoSomenteSessaoAtual = false;   // FIX79: operacao atual usa sessao do robo para nao misturar ciclo antigo
bool                  InpHistoricoPeriodosPreservarAoRecolocar = true; // FIX176: DIA/7D/15D/30D/TUDO preservam lucro ja feito no dia ao recolocar no grafico
bool                  InpPainelFinanceiroSomenteOperacaoAtual = true;
bool                  InpRiscoUsarFinanceiroOperacaoAtual = true;
const bool            InpBloquearMesmoSentidoOutroMagicMesmoTF = true;
double                InpPainelExposicaoMaximaReais = 300.0;
double                InpPainelExposicaoPorContratoReais = 40.0;
bool                  InpAdicionarDXNoGrafico = false;
bool                  InpPlotarDXBandasNoGrafico = false;
bool                  InpFIX353GraficoLimpoSemIndicadores = true; // Oculta somente desenhos; filtros internos continuam funcionando
bool                  InpPainelAtualizarSemTick = true; // FIX279: painel mostra retcode/erro em tempo real mesmo sem novo tick
int                   InpPainelTimerSegundos = 1;
bool                  InpMagicPiscandoPainel = false; // FIX315: leitura estável, sem piscar
bool                  InpFocoUnicoLadoAtual = false;
bool                  InpFocoCompactoPainel = false;
bool                  InpLinhasOperacionaisAtrasDoPainel = true;
bool                  InpPainelSepararRealizadoAberto = true;
bool                  InpGraficoDesligarGrade = true;
double                InpProtecaoDefenderPercent = 50.0;
double                InpProtecaoDefesaMinimaReais = 1.0;
bool                  InpLucroAbertoUsarCalculoManual = true;
double                InpOperacaoLongaSomenteSeGanhoMaiorQue = 0.0;
bool                  InpGerenciadorOrdensExperts = true;   // FIX94: log ligado para diagnosticar A0 no Experts
bool                  InpLogBloqueiosExperts = true;        // FIX94: mostrar motivo real de bloqueio
bool                  InpLogTentativaOrdemExperts = true;   // FIX94: mostrar tentativa e retcode da ordem
int                   InpIntervaloLogRepetidoSeg = 60;
bool                  InpLogAumentosAguardandoExperts = false; // FIX95: evita spam de AUMENTO aguardando a cada tick; ORDER/A0 continuam logando
bool                  InpHistoricoSomenteMagicAtual = true;
bool                  InpHistoricoSomenteDealsSaida = true;
bool                  InpHistoricoRoboUsarGrupoTotalAB = true; // historico do robo/DIA/7D usa o mesmo grupo A+B em todas as janelas
bool                  InpHistoricoTotalHeadIgualSaldoAB = true; // no rodape, Total HEAD deve espelhar o Saldo A+B exibido
bool                  InpHistoricoIncluirAbertoNosCards = false;
bool                  InpHistoricoSeguroSemTravamento = true;
bool                  InpHistoricoAceitarDealsSemTagInstancia = false;
bool                  InpHistoricoUnificarVencimentosFIX347 = true; // ONTEM/7D/15D/30D/TUDO aceitam WIN/WDO de outro vencimento, mantendo Magics A/B
int                   InpHistoricoLongoAtualizarSegundos = 60; // FIX80: periodos longos só recalculam de minuto em minuto
bool                  InpHistoricoCliqueRecalcularAgora = true; // FIX349: clique recalcula imediatamente o periodo selecionado
bool                  InpHistoricoCliqueVisualUltraLeve = true; // FIX80: clique redesenha só abas + card histórico, não o painel inteiro
bool                  InpPainelVisualDesligarComment = true;      // FIX81: visual premium não monta Comment pesado em paralelo
bool                  InpPainelRedrawManualSomenteClique = true;  // FIX353: clique continua imediato; redraw financeiro e garantido 1x/s
bool                  InpPainelRodapeAtualizacaoRapida = true;    // FIX81: leitura/evento/histórico atualizam separado do painel pesado
int                   InpPainelRodapeAtualizarSegundos = 1;       // FIX81: intervalo do rodapé rápido
bool                  InpPainelReencaixeAutomaticoInicial = true;  // FIX83: recalcula o FULL nos primeiros segundos para não abrir cortado
int                   InpPainelReencaixeInicialCiclos = 3;         // FIX83: quantidade de reencaixes leves na abertura
bool                  InpGestaoCadaMagicVidaPropria = true;
double                InpHedgeDispararPrejuizoReais = 100.0;
double                InpHedgeMetaResolucaoReais = 100.0;
double                InpHedgeProtecaoReais = 50.0;
double                InpHedgeProtecaoPercent = 50.0;
bool                  InpHedgeIgnorarUmaPontaPorTF = true;
bool                  InpHedgeExigirFiltroEntrada = false;
int                   InpHedgeIntervaloTentativaSegundos = 0;
bool                  InpUsarRoboHeadExterno = false;
int                   InpMagicHeadCompra = 100100;
int                   InpMagicHeadVenda = 100101;
ENUM_SELECAO_HEAD_OPERACAO InpHeadSelecaoOperacao = HEAD_OPERAR_AUTOMATICO;
bool                  InpHeadUsarConfirmacaoLadoOposto = false;
bool                  InpHeadForcarEntradaOpostaGrupo = false; // FIX332: nenhuma ponta força ou trava automaticamente a outra
bool                  InpHeadCiclosIndependentesFIX275 = true; // FIX275: cada ponta rearma sem esperar o grupo A+B ficar flat
bool                  InpHeadOpostoIgnoraTipoOperacao = true; // permite a ponta oposta mesmo que Tipo Operacao local esteja diferente
bool                  InpHeadOpostoIgnoraFiltrosA0FIX257 = false; // FIX332: cada ponta conserva sua própria validação
bool                  InpHeadOpostoIgnoraSTFTFIX257 = false; // FIX275: nova ponta respeita pausa tecnica apos encerramento
bool                  InpHeadMostrarInfoNoPainel = false;
bool                  InpAumentosConfirmarFechamento = true;
int                   InpAumentosCandlesConfirmacao = 1;
bool                  InpAumentosFiltroHiLo = false;
bool                  InpAumentosFiltroSTR = false;
bool                  InpAumentosFiltroDX = true;
double                InpAumentosDXMin = 50.0;
bool                  InpAumentosFiltroRSI = false; // FIX135: aumento usa principalmente HiLo/STR/DX/Volume/Agressão
double                InpAumentosRSICompraMin = 55.0;
double                InpAumentosRSIVendaMax = 45.0;
bool                  InpAumentosFiltroVolumeQtd = false;
double                InpAumentosVolumeQtdMin = 1000.0;
bool                  InpAumentosFiltroVolumeFin = false; // FIX135: evita travar por volume financeiro em teste inicial
double                InpAumentosVolumeFinMin = 1000000.0;
bool                  InpAumentosFiltroAgressao = false;
double                InpAumentosAgressaoMin = 60.0;
string InpGerenciadorAumentos = "ON;MODO=SEQUENCIAL;MAX_AUMENTOS=4;MAX_CONTRATOS=5;EXIGIR_RESFRIAMENTO=OFF;USAR_AX=OFF"; // legado interno; gatilho real vem de InpModoGatilhoAumentos
string InpRiscoOperacao = "ON;META_OP=50;STOP_OP=300;MODO=CESTA;PROTECAO=ON;PROT_INICIAL=50%;VALOR_PROT=15;ZERAR_50=OFF;BUSCAR_100=ON;ALVO_FINAL=50;ESCALONAR=ON;GATILHO=50G;SINCRONIZAR_FINANCEIRO=ON";
string InpProtecaoLucro = "ON;ATIVA_EM=20R;NAO_VIRAR_PREJUIZO=ON;DEFESA_MIN=1;PROT_PERCENT=50%;TRAIL_ATIVA=20R;TRAIL_PASSO=5R;BASE=FINANCEIRO_CESTA"; // FIX280: trailing financeiro 20/5
string InpOperacaoLonga = "OFF;ATIVA_LUCRO=120R;MODO=DINAMICO;ALVO_NORMAL=100;ALVO_LONGO=DINAMICO;SAIDA=HILO8|STR|SCORE_VOL;SCORE_VOL_MIN=60;SCORE_VOL_SAIR=40;DEFENDER_50=ON;ZERAR_50=OFF;BUSCAR_MAXIMO=ON";
string InpRiscoDiario = "ON;META_DIA=0;STOP_DIA=300;BLOQ_META=OFF;BLOQ_STOP=OFF;NOVO_CICLO=FLAT"; // FIX360: histórico diário não bloqueia; stop operacional é da cesta A+B
string InpParciais = "ON;MODO=BASQUETE;PVALOR=15R_TOTAL;VOLUME=50%;P100=OFF;POS_PARCIAL=PROTEGER_RESTANTE;ULTIMO_CONTRATO=TRAILING"; // Parcial padrão R$15 TOTAL da ponta, proteção do restante
string InpTrailing = "ON;ATIVACAO=20R;PASSO=5R;ULTIMO_CONTRATO=ON;BASE=FINANCEIRO_CESTA"; // FIX280: ativa R$20 e corre R$5
string InpSaidaTecnica = "ON;HILO8=ON;STR=ON;SCORE_VOL=ON;MODO=QUALQUER;CONF=FECHAMENTO;CANDLES=1";
bool InpMostrarPainel = false;
bool InpMostrarAmbiente = true;
bool InpMostrarPontaCompra = true;
bool InpMostrarPontaVenda = true;
bool InpMostrarMestre = true;
bool InpMostrarMatrizJanelas = true;
bool InpMostrarMatrizAumentos = true;
bool InpMostrarMatrizRisco = true;
bool InpMostrarScoreFluxo = true;
bool InpMostrarGerenciadorAumento = true;
bool InpMostrarLog = false;
int  InpPainelAtualizarSegundos = 1; // FIX227: painel financeiro responde em ate 1 segundo
bool InpModoLeveSistema = true;
bool InpPainelModoReduzido = false;
bool InpPainelModoSlimDia = false;
int  InpPainelSlimLargura = 1180;
int  InpPainelSlimAltura = 248;
bool InpPlotarVolumeNoPainel = false;
int  InpPlotarVolumeBarras = 24;
bool InpMostrarExposicaoCardsLaterais = true;
bool InpMostrarHistoricoVisual = false;
bool InpHistoricoCliqueImediato = true;

enum ENUM_LADO_ROBO
{
   LADO_COMPRA = 0,
   LADO_VENDA  = 1,
   LADO_AMBOS  = 2,
   LADO_NENHUM = 3
};

#include "modulos/lado.mqh"
#include "modulos/formatacao.mqh"

enum ENUM_STATUS_MERCADO
{
   MERCADO_FRACO    = 0,
   MERCADO_NORMAL   = 1,
   MERCADO_FORTE    = 2,
   MERCADO_EXTREMO  = 3
};

struct MercadoAtual
{
   double dx;
   double dxMedia;
   double dxBandaBaixa;
   double dxBandaAlta;
   int    dxStatus; // 0=ABAIXO, 1=DENTRO, 2=ACIMA
   double rsi;
   double volq;
   double volf;
   int    volSlot;
   double volqBaseHora;
   double volfBaseHora;
   double volqAtualHora;
   double volfAtualHora;
   double volqProjetadoHora;
   double volfProjetadoHora;
   double volqRatioHora;
   double volfRatioHora;
   double volqMinDinamico;
   double volfMinDinamico;
   bool   volqCurvaOK;
   bool   volfCurvaOK;
   bool   volumeCurvaOK;
   double volqFatorDia;
   double volfFatorDia;
   double volqBaseAjustadaHora;
   double volfBaseAjustadaHora;
   double volqRatioAjustadoHora;
   double volfRatioAjustadoHora;
   double volqRatio5m;
   double volfRatio5m;
   double volqRatio15m;
   double volfRatio15m;
   datetime volCandleTempo;
   double volqCandleFechado;
   double volfCandleFechado;
   double volqMediaCandles;
   double volfMediaCandles;
   double volqRatioCandle;
   double volfRatioCandle;
   double volRatioDecisao;
   int    volFarol; // 0=BAIXO, 1=NORMAL, 2=FORTE, 3=EXTREMO, 4=CIRURGICO
   double agr;
   double scoreFluxo;
   bool   hiloCompra;
   bool   hiloVenda;
   bool   strCompra;
   bool   strVenda;
   ENUM_STATUS_MERCADO status;
};

struct RegraFiltros
{
   bool configuracaoInvalida; // FIX251: texto nao reconhecido bloqueia em vez de liberar silenciosamente
   string erroConfiguracao;
   bool usarHilo8;
   bool usarSTR;
   bool usarDX;
   bool usarRSI;
   bool usarVOLQ;
   bool usarVOLF;
   bool volumeCombinado; // FIX249: VOLUME QTD+FIN conta como uma opção e exige as duas leituras
   bool usarAGR;
   string dxOp;
   double dxMin;
   string rsiCompraOp;
   double rsiCompraMin;
   string rsiVendaOp;
   double rsiVendaMax;
   string volqOp;
   double volqMin;
   string volfOp;
   double volfMin;
   string agrOp;
   double agrMin;
   bool confirmarFechamento;
   int  candlesConfirmacao;
   string modo;
   int    minOk;
   bool   usarScore;
   double scoreMin;
   double scoreExtremo;
   bool   usarMedia25Direcional;
   bool   usarForca;
   double forcaMin;
   bool   usarFibo;
   double fiboMin;
   bool   usarWapBands;
   double wapBandDesvios;
};

struct RegraJanela
{
   bool ativa;
   string horario;
   int minutoInicio;
   int minutoFim;
   ENUM_LADO_ROBO lado;
   bool entradaAtiva;
   double qtd;
   string perfil;
   RegraFiltros filtros;
};

struct RegraAumento
{
   bool ativa;
   double qtd;
   int tempoMinutos;
   int distanciaPontos;
   double gatilhoReais;
   double protecaoPercent; // legado
   double movelAtivarReais;     // FIX442: MOVEL=X/Y, X ativa e Y e a defesa fixa inicial
   double movelDefenderReais;   // FIX442: 0/0 desliga o movel da janela
   double trailingAtivarReais;  // FIX442: TRAIL=X/Y, X ativa
   double trailingPassoReais;   // FIX442: Y e a distancia continua desde o melhor lucro
   ENUM_LADO_ROBO lado;
   RegraFiltros filtros;
};

struct GerenciadorAumentos
{
   bool ativo;
   string modo;
   int maxAumentos;
   int maxContratos;
   double scoreNormalMax;
   double scoreForteMax;
   double scoreExtremo;
   string acaoExtremo;
   bool exigirPausa;
   bool usarAX;
};

struct ScoreAumentosConfig
{
   bool ativo;
   bool usarHilo8;
   bool usarSTR;
   bool usarVOLQ;
   bool usarVOLF;
   bool exigirDirecao;
   bool adaptarHistoricoHora;
   bool ajustarPeloDiaAtual;
   double pesoHilo8;
   double pesoSTR;
   double pesoVOLQ;
   double pesoVOLF;
   double minimoA1;
   double minimoA2;
   double minimoA3;
   double minimoA4;
   double minimoA5;
};

struct RiscoConfig
{
   bool ativo;
   double metaOperacao;
   double stopOperacao;
   double valorProtecao;
   double protecaoPercent;
   bool zerar50;
   bool buscar100;
   bool escalonar;
   bool sincronizarFinanceiro;
   double metaDia;
   double stopDia;
   double defesaAtivaEm;
   double defesaMinima;
   bool naoVirarPrejuizo;
   double trailPasso;
   double ativaLongaEm;
   bool operacaoLongaAtiva;
   double operacaoLongaSomenteSeGanhoMaiorQue;
   double operacaoLongaScoreSaida;
};

struct EstadoLado
{
   ENUM_LADO_ROBO lado;
   string nome;
   long magic;
   long tipoPosicaoAtual;
   double contratosCompra;
   double contratosVenda;
   bool posicaoAberta;
   double contratos;
   double precoMedio;
   double precoEntradaInicial; // FIX212: ancora fixa da A0; A1/A2/A3 nao deslocam quando o preco medio muda.
   double resultadoAberto;
   double resultadoAbertoServidor;
   double resultadoAbertoManual;
   double resultadoFechado;
   double resultadoDia;
   double melhorResultadoAberto;
   int aumentosExecutados;
   bool lucroProtegido;
   double valorDefendido;
   bool modoLongo;
   bool parcial50Executada;
   bool parcialFinalExecutada;
   datetime horarioEntrada;
   datetime horarioUltimoAumento;
   datetime bloqueioReentradaAte;
   datetime ultimaTentativaOrdem;
   bool reentradaImediataAposLucro; // FIX361: próxima A0 ignora apenas esperas temporais após ciclo positivo
   int ultimoNivelAumentoUsado;
   bool bloqueado;
   string motivoBloqueioAumento;
   string ultimaMensagem;
};

struct EstadoMestre
{
   double resultadoAbertoTotal;
   double resultadoFechadoTotal;
   double resultadoDiaTotal;
   double melhorResultadoDiaTotal;
   double defesaDiaTotal;
   bool diaLucroProtegido;
   bool diaProtecaoDisparada;
   datetime diaProtecaoRef;
   bool bloqueadoPorMeta;
   bool bloqueadoPorStop;
   string mensagemAmbiente;
   string mensagemGeral;
};

struct HistoricoPeriodo
{
   ENUM_PERIODO_HISTORICO_PAINEL periodoId;
   datetime janelaInicio;
   datetime janelaFim;
   datetime calculadoEm;
   bool incluiAberto;
   long chaveDiaServidor;
   string nome;
   int compras;
   int vendas;
   int tradesLucroCompra;
   int tradesPrejuCompra;
   int tradesLucroVenda;
   int tradesPrejuVenda;
   // FIX368: detalhamento das parciais para o card historico sem dupla contagem.
   int parciaisLucroQtdCompra;
   int parciaisPrejuQtdCompra;
   int parciaisLucroQtdVenda;
   int parciaisPrejuQtdVenda;
   double qtdCompra;
   double qtdVenda;
   double qtdTotal;
   double financeiro;
   double financeiroCompra;
   double financeiroVenda;
   double financeiroLucroCompra;
   double financeiroPrejuCompra;
   double financeiroLucroVenda;
   double financeiroPrejuVenda;
   double percentual;
   double parcial;
   double parcialCompra;
   double parcialVenda;
   double financeiroParcialLucroCompra;
   double financeiroParcialPrejuCompra;
   double financeiroParcialLucroVenda;
   double financeiroParcialPrejuVenda;
   double lucroTotal;
};

struct ResumoFinanceiroPainel
{
   long magic;
   string nomeSlot;
   string posTexto;
   double realizado;
   double aberto;
   double saldo;
   double lucro;
   double prejuizo;
   double parcialPositiva;
   double expPrejuizo;
   double expAtual;
   double contratos;
   int totalTrades;
   int tradesLucro;
   int tradesPrejuizo;
   int qtdParciais;
   int aumentosFeitos;
};

struct FotoCestaAB
{
   datetime inicio;
   datetime fim;
   string grupoMagics;
   double qtdCompra;
   double qtdVenda;
   double qtdTotal;
   double qtdLiquida;
   double abertoCompra;
   double abertoVenda;
   double abertoTotal;
   double realizadoCompra;
   double realizadoVenda;
   double realizadoTotal;
   double saldoCompra;
   double saldoVenda;
   double saldoTotal;
   double lucroRealizado;
   double prejuRealizado;
   double parcialCompra;
   double parcialVenda;
   double parcialTotal;
   int tradesLucro;
   int tradesPreju;
   int tradesTotal;
   int dealsSaidaUsados;
};

// FIX362: uma unica fotografia alimenta painel, HEAD, stop movel e auditoria.
struct FotoFinanceiraPainelFIX362
{
   datetime calculadaEm;
   double qtdCompra;
   double qtdVenda;
   double qtdTotal;
   double abertoCompra;
   double abertoVenda;
   double abertoHead;
   double realizadoCompra;
   double realizadoVenda;
   double realizadoDia;
   double gainHead;
   double lossHead;
   double restanteHead;
};

// FIX362: quantidade encerrada com resultado positivo e respectivo valor liquido.
struct GanhoQuantidadeFinanceiroFIX362
{
   double qtdCompra;
   double reaisCompra;
   double qtdVenda;
   double reaisVenda;
   double qtdHead;
   double reaisHead;
};
FotoCestaAB g_cacheRealizadoCestaFIX283;
bool         g_cacheRealizadoCestaValidoFIX283=false;
datetime     g_cacheRealizadoCestaInicioFIX283=0;
ulong        g_cacheRealizadoCestaMsFIX283=0;
MercadoAtual g_mercado;
GerenciadorAumentos g_gerAumentos;
ScoreAumentosConfig g_scoreAumentos;
RiscoConfig g_risco;
RegraJanela  g_janelas[5];
RegraAumento g_aumentos[5];
EstadoLado g_compra;
EstadoLado g_venda;
EstadoLado g_painelA;
EstadoLado g_painelB;
EstadoMestre g_mestre;

struct EstadoTrailAumentoFIX281
{
   ulong ticket;
   ulong identificador;
   double melhorLucro;
   double defesaAtual;
   bool protecaoArmada;
   bool movelArmadoFIX397;
   double defesaMovelFIX397;
   double melhorPrecoFIX325;
   double stopPrecoFIX325;
   double distanciaAtualPontosFIX325;
   int degrauAtualFIX325;
   bool alertaToqueEmitidoFIX325;
};

struct EstadoPontaSimplesFIX195
{
   double melhorLucro;
   double defesaAtual;
   double proximaRealizacao;
   bool protecaoArmada;
   bool movelArmadoFIX395;
   double defesaMovelFIX395;
   bool parcialPendente;
   ulong ticketParcialPendente;       // FIX207: ticket real que recebeu a ordem de realizacao.
   ulong identificadorParcialPendente;// FIX207: POSITION_IDENTIFIER para confirmar mesmo sem comentario.
   int nivelAumentoPendente;          // FIX207: A1/A2/A3... em validacao.
   double valorNominalParcialPendente;// FIX214: valor configurado da parcial, separado do liquido apos custos.
   datetime horaParcialPendente;       // FIX251: permite recuperar ordem aceita sem deal confirmado.
   datetime ultimaParcialConfirmada;
   ENUM_REGIME_CORREDOR_FIX338 regimeCorredor;
   int confirmacoesViradaCorredor;
   datetime ultimoCandleCorredor;
   bool alvoMarcoCorredorRegistrado;
};
EstadoPontaSimplesFIX195 g_simplesBuy;
EstadoPontaSimplesFIX195 g_simplesSell;
EstadoTrailAumentoFIX281 g_trailAumentoBuy[5];
EstadoTrailAumentoFIX281 g_trailAumentoSell[5];
double g_alvoLinhaAumentoBuy[5];
double g_alvoLinhaAumentoSell[5];
double g_precoRealizadoAumentoBuy[5];
double g_precoRealizadoAumentoSell[5];
double g_precoEntradaAumentoBuy[5];   // FIX220: preco real de entrada de A1-A5, preservado apos parcial.
double g_precoEntradaAumentoSell[5];
// FIX358: memoria exclusivamente visual. Nao participa de gatilho, ordem, parcial, trailing ou rearme.
double g_audPrecoProgramadoAumentoBuyFIX358[5];
double g_audPrecoProgramadoAumentoSellFIX358[5];
double g_audPrecoExecutadoAumentoBuyFIX358[5];
double g_audPrecoExecutadoAumentoSellFIX358[5];
bool   g_aumentoRealizadoBuy[5];
bool   g_aumentoRealizadoSell[5];
bool   g_precosAumentosRestauradosBuy=false;
bool   g_precosAumentosRestauradosSell=false;
datetime g_candleToqueAumentoBuyFIX224[5];
datetime g_candleToqueAumentoSellFIX224[5];
double   g_linhaCandleAumentoBuyFIX224[5];
double   g_linhaCandleAumentoSellFIX224[5];
bool     g_candleAumentoConfirmadoBuyFIX224[5];
bool     g_candleAumentoConfirmadoSellFIX224[5];
double   g_gatilhoRompimentoAumentoBuyFIX337[5];
double   g_gatilhoRompimentoAumentoSellFIX337[5];
datetime g_horaGatilhoRompimentoBuyFIX337[5];
datetime g_horaGatilhoRompimentoSellFIX337[5];
double   g_ancoraRearmeA1BuyFIX225=0.0;
double   g_ancoraRearmeA1SellFIX225=0.0;
int      g_cicloRearmeA1BuyFIX225=0;
int      g_cicloRearmeA1SellFIX225=0;
int      g_nivelInicioRearmeBuyFIX248=0;
int      g_nivelInicioRearmeSellFIX248=0;
bool     g_rearmeParcialPendenteBuyFIX248=false;
bool     g_rearmeParcialPendenteSellFIX248=false;
int      g_nivelParcialPendenteBuyFIX248=0;
int      g_nivelParcialPendenteSellFIX248=0;
double   g_volumeParcialPendenteBuyFIX248=0.0;
double   g_volumeParcialPendenteSellFIX248=0.0;
datetime g_horaParcialPendenteBuyFIX248=0;
datetime g_horaParcialPendenteSellFIX248=0;
double   g_rearmeSnapshotVolumeBuyFIX251=-1.0;
double   g_rearmeSnapshotVolumeSellFIX251=-1.0;
double   g_rearmeSnapshotMediaBuyFIX251=0.0;
double   g_rearmeSnapshotMediaSellFIX251=0.0;
datetime g_rearmeSnapshotHoraBuyFIX251=0;
datetime g_rearmeSnapshotHoraSellFIX251=0;
bool     g_aguardaRetornoLinhaBuyFIX248[5];
datetime g_horaRearmeNivelBuyFIX453[5];
datetime g_horaRearmeNivelSellFIX453[5];
bool     g_aguardaRetornoLinhaSellFIX248[5];
bool g_cicloMestreSimplesAtivo=false;
datetime g_cicloMestreSimplesInicio=0;
double g_parciaisCicloBuy=0.0;
double g_parciaisCicloSell=0.0;
int    g_qtdParciaisCicloBuy=0;  // FIX214: quantidade de parciais BUY confirmadas pelo servidor no ciclo.
int    g_qtdParciaisCicloSell=0; // FIX214: quantidade de parciais SELL confirmadas pelo servidor no ciclo.
double g_parciaisNominaisCicloBuy=0.0;  // Ex.: duas parciais configuradas em R$10 = R$20.
double g_parciaisNominaisCicloSell=0.0;
double g_realizadoAumentosCicloBuy=0.0;   // FIX281: financeiro liquido confirmado apenas de A1/A2/...
double g_realizadoAumentosCicloSell=0.0;
double g_volumeRealizadoAumentosCicloBuy=0.0; // FIX281: contratos/volume efetivamente realizados
double g_volumeRealizadoAumentosCicloSell=0.0;
int    g_qtdRealizacoesAumentosCicloBuy=0; // FIX281: quantidade de eventos de realizacao de aumentos
int    g_qtdRealizacoesAumentosCicloSell=0;
double g_realizadoAumentosNivelBuyFIX324[5];
double g_realizadoAumentosNivelSellFIX324[5];
double g_volumeRealizadoNivelBuyFIX324[5];
double g_volumeRealizadoNivelSellFIX324[5];
int    g_qtdRealizacoesNivelBuyFIX324[5];
int    g_qtdRealizacoesNivelSellFIX324[5];
datetime g_ultimaSincronizacaoRealizacoesAumentosFIX296=0; // Recontagem leve do ciclo para manter painel e eventos alinhados.
datetime g_ultimoEnvioAumentoBuyFIX434=0;
datetime g_ultimoEnvioAumentoSellFIX434=0;
double g_totalCicloMestreSimples=0.0;
bool g_fechamentoMestreSimplesPendente=false;
datetime g_fimDiaDataReferenciaFIX215=0;
datetime g_fimDiaUltimaTentativaFIX215=0;
bool g_fimDiaEncerradoFIX215=false;
bool g_fimDiaAvisoBloqueioFIX215=false;
datetime g_ultimaTentativaStopDiaMestreFIX320=0;
double g_cestaMelhorSaldoLiquido = 0.0;
double g_cestaStopMovelAbertoPermitido = 0.0;
double g_cestaEspacoStopRestante = 0.0;
bool   g_cestaStopDisparado = false;
bool   g_cestaGainDisparado = false;          // FIX99: evita repetir ordem de fechamento da cesta no mesmo ciclo
bool   g_cestaResetarCicloDepoisFlat = false; // FIX99: após fechar A+B, zera o ciclo quando ficar sem posição
datetime g_cestaUltimoFechamentoGlobal = 0;   // FIX99: log/controle do último gain global
double g_cestaDefesaMaiorAB = 0.0;          // FIX135: piso financeiro A+B após bater referência maior
bool   g_cestaProtecaoMaiorDisparada = false; // FIX135: evita repetição de fechamento por proteção maior
double g_cestaDefesaCurtaAB = 0.0;
bool   g_cestaParcialCurtaExecutada = false;
bool   g_cestaProtecaoCurtaDisparada = false;
bool   g_cestaMetaMarcoCorredorFIX338 = false;
bool   g_auditoriaTesteFIX274OK = true;
string g_auditoriaTesteFIX274Status = "NAO EXECUTADA";
int    g_logValidacaoHandle = INVALID_HANDLE;
string g_logValidacaoArquivo = "";

// ============================================================================
// FIX302 - AUDITORIA LEVE EM MEMORIA, ARQUIVOS POR MAGIC E PERFORMANCE LOCAL
// ============================================================================
#define AUD302_FILA_MAX 384
string g_aud302FilaCSV[AUD302_FILA_MAX];
string g_aud302FilaLOG[AUD302_FILA_MAX];
int    g_aud302FilaDestino[AUD302_FILA_MAX]; // 0=eventos, 1=resumo, 2=deals brutos
bool   g_aud302FilaCritica[AUD302_FILA_MAX];
int    g_aud302FilaInicio=0;
int    g_aud302FilaQtd=0;
int    g_aud302FilaDescartada=0;
int    g_aud302EventosGravados=0;
int    g_aud302FalhasArquivo=0;
bool   g_aud302FlushUrgente=false;
datetime g_aud302UltimoFlush=0;
datetime g_aud302UltimoFileFlush=0;
datetime g_aud302SuspensoAte=0;
int    g_aud302LogHandle=INVALID_HANDLE;
int    g_aud302ResumoHandle=INVALID_HANDLE;
int    g_aud305DealsHandle=INVALID_HANDLE;
string g_aud305ArquivoDeals="";
string g_aud302ArquivoLOG="";
string g_aud302ArquivoResumo="";
string g_aud302Sessao="";
string g_aud302Ciclo="SEM_CICLO";
bool   g_aud302CicloAtivo=false;
// FIX304 - identidade forte compartilhada pelas janelas A/B e ciclo local por Magic.
string g_identidadeGrupoFIX304="";
string g_identidadeGeracaoFIX304="";
string g_identidadeCicloLocalFIX304="";
string g_identidadeChaveBaseFIX304="";
string g_identidadeChaveGeracaoFIX304="";
string g_identidadeChaveHeartbeatAFIX304="";
string g_identidadeChaveHeartbeatBFIX304="";
bool   g_identidadeInicializadaFIX304=false;
const int g_identidadeHeartbeatValidoSegFIX304=120;
bool   g_aud302PosAnterior=false;
bool   g_aud302Inicializada=false;
bool   g_aud302TelaAtiva=false;
bool   g_aud302ValidarGraficoPendente=false;
string g_aud302UltimoEvento="INICIALIZANDO";
string g_aud302StatusGeral="PENDENTE";
int    g_aud302ChecksOK=0;
int    g_aud302ChecksFalha=0;
int    g_aud302ChecksPendente=0;
string g_aud302FiltroNivel[6];
string g_aud302EntradaNivel[6];
string g_aud302TrailNivel[6];
string g_aud302ParcialNivel[6];
string g_aud302GraficoNivel[6];
string g_aud302FinanceiroNivel[6];
double g_aud302PrecoEsperado[6];
double g_aud302PrecoEntrada[6];
double g_aud302PrecoSaida[6];
double g_aud302ResultadoNivel[6];
ulong  g_aud302TicketNivel[6];
ulong  g_aud302DealNivel[6];
ulong  g_aud302Ticks=0;
ulong  g_aud302TickUsTotal=0;
ulong  g_aud302TickUsMax=0;
ulong  g_aud302Timers=0;
ulong  g_aud302TimerUsTotal=0;
ulong  g_aud302TimerUsMax=0;
ulong  g_aud302Trades=0;
ulong  g_aud302TradeUsTotal=0;
ulong  g_aud302TradeUsMax=0;
ulong  g_aud302LotesEscrita=0;
ulong  g_aud302EscritaUsTotal=0;
ulong  g_aud302EscritaUsMax=0;

// ============================================================================
// FIX306 - EXPORTACAO SEMANAL DOS ULTIMOS MESES, M1 A M5, FORA DO ONTICK
// ============================================================================
enum ENUM_EXP306_FASE
{
   EXP306_PARADO=0,
   EXP306_BARRAS=1,
   EXP306_DEALS=2,
   EXP306_POSICOES=3,
   EXP306_OBJETOS=4,
   EXP306_FECHAR_SEMANA=5,
   EXP306_CONCLUIDO=6,
   EXP306_ERRO=7
};
bool g_exp306Ativa=false;
ENUM_EXP306_FASE g_exp306Fase=EXP306_PARADO;
string g_exp306Status="PARADA";
string g_exp306RunId="";
string g_exp306ExportId="";
string g_exp306Prefixo="EXPORTACAO_SEMANAL_MESES_2";
string g_exp306PrefixoArquivo="ESM2"; // FIX309: somente para nomes fisicos compactos
datetime g_exp306RangeStart=0;
datetime g_exp306RangeEnd=0;
datetime g_exp306WeekStart=0;
datetime g_exp306WeekDataStart=0;
datetime g_exp306WeekDataEnd=0;
int g_exp306SemanaAtual=0;
int g_exp306SemanasTotal=0;
ENUM_TIMEFRAMES g_exp306TFs[5]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5};
int g_exp306TfIndex=0;
bool g_exp306TfCarregado=false;
int g_exp306TfTentativas=0;
MqlRates g_exp306Rates[];
int g_exp306RateCursor=0;
int g_exp306RateTotal=0;
int g_exp306BarIndexTF=0;
long g_exp306VwapDia=0;
double g_exp306VwapPV=0.0;
double g_exp306VwapVol=0.0;
ulong g_exp306Deals[];
int g_exp306DealCursor=0;
int g_exp306PosCursor=0;
int g_exp306ObjCursor=0;
int g_exp306BarsHandle=INVALID_HANDLE;
int g_exp306AuditHandle=INVALID_HANDLE;
int g_exp306ManifestHandle=INVALID_HANDLE;
string g_exp306BarsArquivo="";
string g_exp306AuditArquivo="";
string g_exp306ManifestArquivo="";
string g_exp306ScreenshotArquivo="";
long g_exp306TotalBarras=0;
long g_exp306TotalDeals=0;
long g_exp306TotalPosicoes=0;
long g_exp306TotalObjetos=0;
long g_exp306BarrasSemana=0;
long g_exp306DealsSemana=0;
long g_exp306PosicoesSemana=0;
long g_exp306ObjetosSemana=0;
int g_exp306Falhas=0;
datetime g_exp306Inicio=0;

string g_aud302UltimaAssinatura="";
datetime g_aud302UltimaAssinaturaHora=0;
datetime g_ultimoLogCestaABDetalhado = 0; // FIX155: anti-spam do log financeiro A+B detalhado.
datetime g_ultimoLogHedgeCompleto = 0;     // FIX157: anti-spam do log completo HEDGE A+B.
datetime g_ultimoLogStopFullHedgeAB = 0;   // FIX158: anti-spam do log da linha oficial STOP FULL HEDGE A+B.
string g_logFiltroTipoEntrada = "";
string g_logFiltroDecisao = "";
string g_logFiltroMotivo = "";
string g_logFiltroM25Status = "";
string g_logFiltroScoreStatus = "";
string g_logFiltroResumo = "";
string g_logFiltroDetalhe = "";
int    g_logFiltroTotal = 0;
int    g_logFiltroOk = 0;
double g_logFiltroScoreLado = 0.0;
double g_logFiltroDX = 0.0;
double g_logFiltroRSI = 0.0;
double g_logFiltroVolQ = 0.0;
double g_logFiltroVolF = 0.0;
double g_logFiltroAgr = 0.0;
string g_logFiltroHiloOK = "";
string g_logFiltroSTROK = "";
string g_logFiltroDXOK = "";
string g_logFiltroRSIOK = "";
string g_logFiltroVOLQOK = "";
string g_logFiltroVOLFOK = "";
string g_logFiltroAGROK = "";
HistoricoPeriodo g_histDia;
HistoricoPeriodo g_histOntem;
HistoricoPeriodo g_hist7Dias;
HistoricoPeriodo g_hist15Dias;
HistoricoPeriodo g_hist30Dias;
HistoricoPeriodo g_histTudo;
datetime g_historicoMarcoZero = 0;
string   g_historicoMarcoZeroChave = "";
ulong    g_historicoTicketZero = 0;
string   g_historicoTicketZeroChave = "";
ENUM_PERIODO_HISTORICO_PAINEL g_periodoHistoricoAtivo = HIST_PAINEL_DIA;
datetime g_ultimoCliqueHistorico = 0;
ENUM_MODO_PAINEL_VISUAL g_modoPainelVisualAtivo = PAINEL_VISUAL_COMPLETO; // modo clicavel em tempo real.
// FIX319: transformação visual aplicada apenas aos objetos COPA_AR100_CARD_.
bool   g_painelAutoFitFIX319 = false;
double g_painelEscalaXFIX319 = 1.0;
double g_painelEscalaYFIX319 = 1.0;
int    g_painelBaseXFIX319 = 0;
int    g_painelBaseYFIX319 = 0;
int    g_painelRealXFIX319 = 0;
int    g_painelRealYFIX319 = 0;
int    g_painelBaseWFIX319 = 0;
int    g_painelBaseHFIX319 = 0;
int    g_painelLayoutResponsivoFIX320 = -1;
bool   g_painelCompactoAutomaticoFIX320 = false;
double   g_totalHeadSaldoABExibido = 0.0;
bool     g_totalHeadSaldoABExibidoValido = false;
datetime g_totalHeadSaldoABExibidoHora = 0;
double   g_totalHeadResultadoABExibido = 0.0;      // FIX183: aberto/resultado A+B exibido no card Total A+B
bool     g_totalHeadResultadoABExibidoValido = false;
datetime g_totalHeadResultadoABExibidoHora = 0;
datetime g_ultimaAtualizacaoHistorico = 0;
datetime g_ultimaAtualizacaoHistoricoLongo = 0;
datetime g_historicoRefreshRapidoAteFIX227 = 0; // reconfirma realizado logo apos DEAL_ADD
datetime g_ultimaTentativaHistoricoRapidoFIX227 = 0;
datetime g_diaHistoricoAtivo = 0;
int      g_historicoPassoLongo = 0;
datetime g_ultimaAtualizacaoPainelVisual = 0;
datetime g_ultimaAtualizacaoRodapeVisual = 0; // FIX81: atualiza leitura/evento/histórico sem redesenhar painel inteiro
ulong    g_ultimoRedrawPainelFIX353 = 0; // redraw visual financeiro limitado a uma vez por segundo
ulong    g_ultimaAtualizacaoCamposFIX354 = 0; // atualizacao leve dos valores financeiros, sem redesenhar o painel inteiro
// FIX362: valores efetivos sao copiados somente dos campos visiveis do usuario.
double   g_gainHeadEfetivoFIX362 = 200.0;
double   g_lossHeadEfetivoFIX362 = 300.0;
// FIX372: fotografia consolidada do ciclo e origem real dos filtros.
double   g_resultadoHeadCicloFIX372 = 0.0;
double   g_melhorHeadCicloFIX372 = 0.0;
double   g_defesaHeadCicloFIX372 = 0.0;
bool     g_escalaHeadAtivaFIX372 = false;
string   g_perfilA0PadraoFIX372 = "LIVRE";
string   g_perfilAumentosFIX372 = "LIVRE";
string   g_origemFiltroJanelaFIX372[4];
string   g_perfilFiltroJanelaFIX372[4];
string   g_assinaturaParametrosUsuarioFIX362 = "";
FotoFinanceiraPainelFIX362 g_fotoFinanceiraPainelFIX362;
GanhoQuantidadeFinanceiroFIX362 g_ganhoQtdReaisFIX362;
ulong    g_ultimaFotoFinanceiraMsFIX362 = 0;
ulong    g_ultimaAtualizacaoGanhoQtdMsFIX362 = 0;
datetime g_ultimaAuditoriaCamposFIX354 = 0;
int      g_auditoriaCamposOkFIX354 = 0;
int      g_auditoriaCamposTotalFIX354 = 0;
string   g_auditoriaCamposStatusFIX354 = "AGUARDANDO";
int      g_painelReencaixeInicialRestante = 0; // FIX83: força alguns redraws leves após o MT5 estabilizar o tamanho do gráfico
bool     g_timerCriadoSomenteParaPainelInicial = false;
datetime g_horarioInicioRobo = 0;
ulong    g_historicoMarcoDealInicial = 0;       // FIX90: maior ticket/deal existente antes do robo iniciar
datetime g_historicoMarcoHoraInicial = 0;       // FIX90: maior horario de deal existente antes do robo iniciar
bool     g_historicoTeveSaidaSessao = false; // FIX80: evita HistorySelect em todo tick quando a sessão ainda não fechou nenhum deal
bool     g_historicoPrimeiraCargaFeita = false; // FIX80: evita carga pesada no OnInit quando histórico por sessão deve nascer zerado
datetime g_cicloInicioCompra = 0; // inicio do ciclo/operacao atual do Magic A.
datetime g_cicloInicioVenda  = 0; // inicio do ciclo/operacao atual do Magic B.
bool g_contaDemo = false;
bool g_contaHedge = false;
bool g_ambienteLiberado = false;
bool g_baseHistoricaSomenteExportarAtivo = false; // FIX137: quando a base historica esta sendo gerada, nao executa ordens
long   g_loginContaAtual = 0;
string g_servidorContaAtual = "";
string g_empresaContaAtual = "";
bool   g_bloqueioValidacaoInicial = false;
bool   g_posicaoInicialAssumida = false;
datetime g_ultimoCandle = 0;
bool g_novoCandle = false;
string   g_ordemUltimoEvento      = "";
string   g_ordemUltimoContexto    = "";
string   g_ordemUltimoRetcode     = "";
string   g_ordemUltimoErro        = "";
string   g_ordemUltimoTicket      = "";
datetime g_ordemUltimaHora        = 0;
double   g_ordemUltimoVolume      = 0.0;
double   g_ordemUltimoPreco       = 0.0;
long     g_ordemUltimoMagic       = 0;
int      g_ordemTentativas        = 0;
int      g_ordemEnviadas          = 0;
int      g_ordemRejeitadas        = 0;
int      g_ordemBloqueadas        = 0;
// FIX279: diagnostico real da entrada direta em conta demo.
string   g_fix279StatusGeral       = "AGUARDANDO PRIMEIRA TENTATIVA";
string   g_fix279StatusCompra      = "C: AGUARDANDO";
string   g_fix279StatusVenda       = "V: AGUARDANDO";
uint     g_fix279RetcodeCompra     = 0;
uint     g_fix279RetcodeVenda      = 0;
int      g_fix279ErroCompra        = 0;
int      g_fix279ErroVenda         = 0;
datetime g_fix279UltimaTentativaCompra = 0;
datetime g_fix279UltimaTentativaVenda  = 0;
datetime g_ultimoCandleA0DiretoCompraFIX313 = 0;
datetime g_ultimoCandleA0DiretoVendaFIX313  = 0;
bool     g_fix279CompraSolicitada = false;
bool     g_fix279VendaSolicitada  = false;
// FIX226: MsgBox realmente temporaria. Nao ocupa a faixa quando nao existe evento relevante.
datetime g_msgBoxVisualHoraFIX226 = 0;
string   g_msgBoxVisualTituloFIX226 = "";
string   g_msgBoxVisualLinha1FIX226 = "";
string   g_msgBoxVisualLinha2FIX226 = "";
datetime g_ultimaEntradaA0OkHora = 0;       // FIX103
int      g_ultimoLadoEntradaA0Ok = -1;       // FIX103
string   g_ultimoLogAssinatura    = "";
datetime g_ultimoLogHora          = 0;
int g_handleADX = INVALID_HANDLE; // Usado somente para calcular DX operacional/painel.
int g_handleMedia25Grafico = INVALID_HANDLE; // handle visual da media grafica dinamica no grafico principal.
bool g_media25AdicionadaNoGrafico = false;
// FIX398: impede tentativa e log infinito quando o MT5 recusa ChartIndicatorAdd (erro 4114).
bool g_media25TentativaBloqueadaFIX398 = false;
int  g_media25UltimoErroFIX398 = 0;
bool g_mediaGraficaNativaLegadoRemovida = false; // FIX148: remove a media nativa antiga que podia ficar presa em 25.
bool g_adxVisualLegadoRemovido = false; // evita ChartIndicatorDelete repetido no timer, que podia fechar a janela de parametros.
datetime g_ultimaBarraBandasMedia25 = 0; // evita redesenho pesado das bandas sem candle novo.
int g_handleRSI = INVALID_HANDLE;
int g_handleOscVisualFIX343 = INVALID_HANDLE;
int g_janelaOscVisualFIX343 = -1;
bool g_oscVisualAdicionadoFIX343 = false;
string g_nomeOscVisualFIX343 = "";
int g_handleDXVisualFIX345 = INVALID_HANDLE;
bool g_dxVisualAdicionadoFIX345 = false;
bool g_dxVisualFechadoUsuarioFIX345 = false;
bool g_objetosDXLegadoRemovidosFIX345 = false;
string g_nomeDXVisualFIX345 = "";
datetime g_ultimaAtualizacaoAgressao = 0; // FIX249: limita leitura pesada de ticks a uma vez por segundo
datetime g_ultimoCandleContraProcessadoFIX258 = 0; // FIX258: impede redesenho repetido do mesmo candle fechado
// FIX310: ultimo sinal contra confirmado, usado pelo seletor visivel de entrada A0.
datetime       g_ultimoSinalContraHoraFIX310 = 0;
ENUM_LADO_ROBO g_ultimoSinalContraLadoFIX310 = LADO_NENHUM;

// FIX310: controle financeiro diario independente do ciclo operacional.
datetime g_diaFinanceiroRefFIX310 = 0;
double   g_abertoBaseDiaCompraFIX310 = 0.0;
double   g_abertoBaseDiaVendaFIX310 = 0.0;
double   g_saldoOntemCompraFIX310 = 0.0;
double   g_saldoOntemVendaFIX310 = 0.0;
double   g_ultimoAbertoCompraFIX310 = 0.0;
double   g_ultimoAbertoVendaFIX310 = 0.0;
datetime g_ultimaFotoAbertoFIX310 = 0;
datetime g_ultimaPersistenciaDiaFIX310 = 0;
bool     g_controleDiaProntoFIX310 = false;
string   g_statusViradaDiaFIX310 = "AGUARDANDO";
// FIX342: homologação e proteções de produção. DEMO continua sendo o padrão.
bool     g_auditoriaProducaoOKFIX342 = false;
string   g_auditoriaProducaoStatusFIX342 = "NAO EXECUTADA";
datetime g_ultimaAuditoriaStopServidorFIX342 = 0;
bool     g_ultimoEnvioAguardandoDealFIX342 = false;
ulong    g_ultimaOrdemPendenteFIX342 = 0;
uint     g_ultimoRetcodeExternoFIX342 = 0;
datetime g_bloqueioTecnicoEntradasAteFIX342 = 0;
string   g_bloqueioTecnicoMotivoFIX342 = "";
string   g_statusRangeGridFIX344 = "RANGE OFF | GRID OFF";
datetime g_ultimaPlotagemRangeGridFIX344 = 0;
string   g_assinaturaPlotagemRangeGridFIX344 = "";
// FIX411: estado independente do filtro DX para A0 e aumentos.
double g_dxMediaAtualFIX411=0.0;
double g_dxDistanciaAtualPtsFIX411=0.0;
double g_dxBandaSuperiorFIX411=0.0;
double g_dxBandaInferiorFIX411=0.0;
double g_dxForcaCompraFIX411=0.0;
double g_dxForcaVendaFIX411=0.0;
string g_dxRegimeFIX411="AGUARDANDO";
bool g_dxDadosProntosFIX411=false;
datetime g_dxUltimoCalculoBarraFIX411=0;
bool g_dxToqueCompraA0FIX411=false;
bool g_dxToqueVendaA0FIX411=false;
bool g_dxToqueCompraAumFIX417[4];
bool g_dxToqueVendaAumFIX417[4];
datetime g_dxBarraToqueCompraA0FIX411=0;
datetime g_dxBarraToqueVendaA0FIX411=0;
datetime g_dxBarraToqueCompraAumFIX417[4];
datetime g_dxBarraToqueVendaAumFIX417[4];
datetime g_dxLiberadoCompraA0FIX411=0;
datetime g_dxLiberadoVendaA0FIX411=0;
datetime g_dxLiberadoCompraAumFIX417[4];
datetime g_dxLiberadoVendaAumFIX417[4];

// FIX311: auditoria continua do historico/data/Magics. Nao bloqueia entradas; registra qualquer divergencia.
datetime g_ultimaAuditoriaHistMagicFIX311 = 0;
int      g_auditoriaHistPassFIX311 = 0;
int      g_auditoriaHistFailFIX311 = 0;
string   g_auditoriaHistStatusFIX311 = "AGUARDANDO";
string   g_auditoriaHistFalhasFIX311 = "";
// Diagnóstico financeiro e proteção contra repetição anormal.
int      g_financeiroDealsReconstruidosFIX313 = 0;
int      g_financeiroDealsSemBaseFIX313 = 0;
ulong    g_ultimoDealFinanceiroReconstruidoFIX313 = 0;
double   g_ultimoProfitBrutoFIX313 = 0.0;
double   g_ultimoProfitSeguroFIX313 = 0.0;
bool     g_fatorFinanceiroDetectadoFIX313 = false;
double   g_fatorFinanceiroServidorFIX313 = 1.0;
int      g_amostrasFatorFinanceiroFIX313 = 0;
ulong    g_cacheDealTicketFIX313[];
double   g_cacheDealResultadoFIX313[];
datetime g_ultimaProtecaoRepeticaoLogFIX313 = 0;
string   g_statusFinanceiroFIX313 = "AGUARDANDO";
bool     g_financeiroHistoricoValidoFIX314 = true;
int      g_financeiroHistoricoErrosFIX314 = 0;
ulong    g_financeiroHistoricoUltimoDealErroFIX314 = 0;
bool g_painelProntoFIX259 = false; // FIX259: bloqueia rotinas visuais pesadas antes do painel terminar o OnInit
bool g_historicoCandlesContraCarregadoFIX261 = false; // FIX261/FIX263: controle de carga e repintura do historico
int  g_totalCandlesContraPintadosFIX261 = 0; // FIX261/FIX263: diagnostico da quantidade pintada
datetime g_ultimaVarreduraCandlesContraFIX262 = 0; // evita varrer as barras a cada segundo quando não há sinal
int      g_tentativasCargaContraFIX263 = 0; // quantidade de tentativas até a série histórica ficar pronta
int      g_sinaisCompraContraFIX263 = 0; // diagnóstico visual: barras azuis
int      g_sinaisVendaContraFIX263 = 0; // diagnóstico visual: barras amarelas
string   g_statusCargaContraFIX263 = "AGUARDANDO HISTORICO";
double   g_ultimoFiboNivelSinalFIX269 = 0.0; // nível Fibo associado ao sinal atual
int      g_sinaisFibo127FIX269 = 0; // sinais autorizados por exaustão 1.272
int      g_sinaisFibo161FIX269 = 0; // sinais autorizados por exaustão 1.618 ou superior
int      g_sinaisFibo078FIX269 = 0; // sinais de pivô com extensão Fibo entre 0.786 e 1.272
// FIX271: cache historico do OTT. Os arrays usam o mesmo indice shift das series do MT5.
double   g_ottSuporteFIX271[];
double   g_ottLinhaRawFIX271[];
double   g_ottLongStopFIX271[];
double   g_ottShortStopFIX271[];
int      g_ottDirecaoFIX271[];
int      g_ottCacheMaxShiftFIX271 = -1;
datetime g_ottCacheBarraAtualFIX271 = 0;
ENUM_TIMEFRAMES g_ottCacheTFFIX271 = PERIOD_CURRENT;
string   g_textoEtiquetaContraFIX271 = "";
double   g_ultimoOTTSuporteSinalFIX271 = 0.0;
double   g_ultimoOTTLinhaSinalFIX271 = 0.0;
int      g_ottCruzCompraFIX272 = 0;
int      g_ottCruzVendaFIX272 = 0;
int      g_ottSetupCompraFIX272 = 0;
int      g_ottSetupVendaFIX272 = 0;
// FIX273: diagnostico e ultimo contexto da caixa Darvas.
int      g_darvasFalsoCompraFIX273 = 0;
int      g_darvasFalsoVendaFIX273 = 0;
int      g_darvasSetupCompraFIX273 = 0;
int      g_darvasSetupVendaFIX273 = 0;
double   g_ultimoDarvasTopoFIX273 = 0.0;
double   g_ultimoDarvasFundoFIX273 = 0.0;
long g_magicCompraSincronizado = -1;
long g_magicVendaSincronizado  = -1;
// FIX256: coordenacao obrigatoria entre as duas instancias do mesmo ativo/conta.
bool     g_coordenacaoMagicsOK_FIX256 = false;
string   g_statusCoordenacaoMagics_FIX256 = "NAO INICIALIZADA";
datetime g_ultimoHeartbeatMagics_FIX256 = 0;
const int g_timeoutHeartbeatMagics_FIX256 = 15;
bool ValidarAmbienteConta();
void InicializarEstados();
bool InicializarIndicadores();
void LiberarIndicadores();
void SincronizarMagicParametros(bool forcar=false);
long MagicCompraAtual();
long MagicVendaAtual();
long MagicPainelAAtual();
long MagicPainelBAtual();
bool ValidarMagicsConfiguradosFIX252(string &motivo);
string MarcadorComentarioOperacionalFIX252(string comentarioBase);
string IDInstanciaAtual();
string Base36FIX304(long valor,int largura);
long HashTextoFIX304(string texto);
void InicializarIdentidadeUnicaFIX304();
void AtualizarHeartbeatIdentidadeFIX304();
void EncerrarHeartbeatIdentidadeFIX304();
string ExtrairGeracaoComentarioFIX304(string comentario);
string ExtrairCicloComentarioFIX304(string comentario);
bool ComentarioTemIdentidadeAtualFIX304(string comentario,long magic);
string CicloAtualMagicFIX304(long magic,bool criarSeNecessario);
void EncerrarCicloIdentidadeLocalFIX304();
string ComentarioComIdentidadeMagicFIX304(string comentarioBase,long magic);
int ContarPosicoesMagicFIX304(long magic,double &contratos);
bool DealEhDoRoboHistorico(ulong deal);
void AtualizarHistoricoLongoEmRodizio(datetime agora, datetime inicioHoje, datetime inicioOntem, datetime inicio7, datetime inicio15, datetime inicio30, datetime inicioTudo, datetime corteSessao);
void AtualizarHistoricoSelecionadoAgora();
void CarregarTodasMatrizes();
void CarregarMatrizJanelas();
void CarregarMatrizAumentos();
void CarregarMatrizSaida();
string MontarLinhaJanelaClara(string configuracao, string filtros);
string FaixaHorarioCompacta(string lista, int indice);
bool HorarioCompactoPermitidoAgora(string lista);
void InvalidarSnapshotTotalABFIX292();
void ValidarJanelasClaras();
bool MinutoDentroJanelaValor(int minuto, RegraJanela &j);
RegraJanela ParseJanela(string linha);
RegraAumento ParseAumento(string linha);
void ParseTrailAumentoFIX282(string campo, double &ativar, double &passo);
void ParseGerenciadorAumentos(string linha);
void ParseScoreAumentos(string linha);
bool ModoAumentoSomenteScore();
double MinimoScoreAumentoNivel(int indiceZero);
double QualidadeVolumeScoreAdaptativo(bool quantidade, bool &aprovado, string &detalhe);
double CalcularScoreAumentoDedicado(ENUM_LADO_ROBO lado, string &detalhe);
bool ScoreAumentoAutoriza(EstadoLado &estado, int indiceZero, string &detalhe);
string TextoScoreAumentoNivel(EstadoLado &estado, int indiceZero);
double MinimoScoreVolumeAumentoFIX334(int indiceZero);
void AtualizarScoreVolumeCandleFIX335();
double CalcularScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, string &detalhe);
bool ScoreVolumeAumentoAutorizaFIX334(ENUM_LADO_ROBO lado, int indiceZero, string &detalhe);
string TextoScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, int indiceZero);
void AtualizarHiLo8ESTR();
void AtualizarVisualHilo14STR4FIX418(bool forcar=false);
void LimparVisualHilo14STR4FIX418();
void AtualizarDXAdaptativoFIX411(bool forcar=false);
bool DXAdaptativoAutorizaFIX411(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento,string &detalhe);
void ConsumirSinalDXAposOrdemFIX417(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento);
void AtualizarPlotagemDXAdaptativoFIX411();
void LimparPlotagemDXAdaptativoFIX411();
string RegimeDXFIX411(double forcaMax);

double CalcularAgressaoCompradoraTicks(int quantidadeTicks);
double AgressaoDirecionalPercentual(ENUM_LADO_ROBO lado);
double CalcularAgressaoCompradoraCandleFIX258(datetime inicio, datetime fim);
double VolumeQuantidadeBarraContraFIX261(int shift);
double VolumeFinanceiroBarraContraFIX261(int shift);
bool VolumeQtdFinHistoricoContraFIX261(int shift, double &ratioQtd, double &ratioFin);
double RSICalculadoManualContraFIX262(int shift, int periodo=14);
double RSIHistoricoContraFIX261(int shift);
bool HiLoSTRHistoricoContraFIX261(int shift, bool &hiloCompra, bool &hiloVenda, bool &strCompra, bool &strVenda);
double AgressaoCompradoraEstimadaContraFIX261(int shift);
double MediaFechamentoAnteriorContraFIX265(int shift, int periodo);
double ATRManualContraFIX265(int shift, int periodo);
bool CandleReversaoBasicoContraFIX265(int shift, ENUM_LADO_ROBO ladoContra);
double MediaFechamentoIncluindoAtualContraFIX266(int shift, int periodo);
bool RetornoRSIConfirmadoContraFIX266(int shift, ENUM_LADO_ROBO ladoContra, double rsiAtual);
bool QuebraEstruturaContraFIX266(int shift, ENUM_LADO_ROBO ladoContra);
bool CruzamentoMedia8ContraFIX266(int shift, ENUM_LADO_ROBO ladoContra);
bool CalcularFiboExaustaoContraFIX269(int shiftSetup, ENUM_LADO_ROBO ladoContra, double &nivelFibo, double &extensaoATR, double &extensaoEstrutural);
bool ConfirmacaoSegundoCandleContraFIX267(int shift, ENUM_LADO_ROBO ladoContra, int shiftGatilho, double extremaSetup, double nivelFiboSetup);
bool ExisteSinalRecenteContraFIX265(int shift, ENUM_LADO_ROBO ladoContra);
bool PrepararCacheOTTFIX271(int maxShift);
double ValorSuporteOTTFIX271(int shift);
double ValorLinhaOTTFIX271(int shift);
void PlotarLinhasOTTFIX271();
void LimparLinhasOTTFIX271();
bool AvaliarCandleContraOTTFIX271(int shift, ENUM_LADO_ROBO &ladoContra, double &rsi, double &agrCompra, double &ratioQtd, double &ratioFin, int &confirmacoes);
bool AvaliarCandleContraCruzamentoFIX270(int shift, ENUM_LADO_ROBO &ladoContra, double &rsi, double &agrCompra, double &ratioQtd, double &ratioFin, int &confirmacoes);
bool AvaliarCandleContraCirurgicoFIX265(int shift, ENUM_LADO_ROBO &ladoContra, double &rsi, double &agrCompra, double &ratioQtd, double &ratioFin, int &confirmacoes);
bool AvaliarCandleContraFIX261(int shift, bool usarAgressaoAtual, ENUM_LADO_ROBO &ladoContra, double &rsi, double &agrCompra, double &ratioQtd, double &ratioFin, int &confirmacoes);
int ContarObjetosCandlesContraFIX262();
void AtualizarDiagnosticoCandlesContraFIX263();
void CarregarHistoricoCandlesContraFIX261();
void PlotarCandleContraFIX258(datetime tempoBarra, ENUM_LADO_ROBO entradaContra, double precoAbertura, double maxima, double minima, double fechamento);
void LimitarCandlesContraFIX258();
void LimparCandlesContraFIX258();
void AtualizarCandlesContraFIX258(bool forcar=false);
string CombinarLinhaFiltro(string linhaBase, string linhaFiltros);
string NormalizarFiltrosHumanizados(string linha);
void AplicarConfirmacaoLinhasAumentos();
bool ExtrairPrimeiroNumeroAPartir(string texto, int inicio, double &valor, int &fimNumero);
double NumeroDepoisDoMarcador(string texto, string marcador, double padrao);
bool DoisNumerosDepoisDoMarcador(string texto, string marcador, double &primeiro, double &segundo);
int CandlesNoFormatoCurto(string texto, int padrao);
void AplicarParametrosCompactos();
void AplicarAumentoCompactoNosInputs(int nivel, string linha);
void ParseRiscoOperacao(string linha);
void ParseRiscoDiario(string linha);
void ParseProtecaoLucro(string linha);
void ParseOperacaoLonga(string linha);
void AplicarParametrosHumanizados();
void AplicarAumentoHumanizado(int idx, bool ativo, double qtd, int tempoMinutos, double gatilhoReais, int distanciaPontos, double protecaoPercent, string filtrosLinha);
void AplicarFiltrosHumanizadosAoAumento(int idx);

RegraFiltros ParseFiltrosDaLinha(string linha)
{
   RegraFiltros f;
   ZeroMemory(f);
   f.configuracaoInvalida = IsOn(GetCampo(linha, "INVALIDO", "OFF"));
   f.erroConfiguracao = GetCampo(linha, "ERRO", "");
   f.confirmarFechamento = (Upper(GetCampo(linha, "CONF", "FECHAMENTO")) == "FECHAMENTO");
   f.candlesConfirmacao = ExtrairInteiro(GetCampo(linha, "CANDLES", "1"));
   f.modo = Upper(GetCampo(linha, "MODO", "TODOS"));
   f.minOk = ExtrairInteiro(GetCampo(linha, "MIN_OK", "0"));
   string filtros = GetCampo(linha, "FILTROS", "");
   string tokens[];
   int total = StringSplit(filtros, '|', tokens);
   for(int i = 0; i < total; i++)
      AplicarFiltroToken(f, tokens[i]);
   string v;
   v = GetCampo(linha, "HILO", GetCampo(linha, "HILO8", ""));
   if(v != "")
      f.usarHilo8 = IsOn(v);
   v = GetCampo(linha, "STR", "");
   if(v != "")
      f.usarSTR = IsOn(v);
   v = GetCampo(linha, "DX25", GetCampo(linha, "DX", ""));
   if(v != "")
   {
      f.usarDX = IsOn(v);
      f.dxOp = ">=";
      f.dxMin = ExtrairNumero(GetCampo(linha, "DXMIN", GetCampo(linha, "DX_MIN", "25")));
   }
   v = GetCampo(linha, "RSI", "");
   if(v != "")
   {
      f.usarRSI = IsOn(v);
      f.rsiCompraOp = GetCampo(linha, "RSIC_OP", GetCampo(linha, "RSI_C_OP", ">="));
      f.rsiCompraMin = ExtrairNumero(GetCampo(linha, "RSIC", GetCampo(linha, "RSI_C", "55")));
      f.rsiVendaOp = GetCampo(linha, "RSIV_OP", GetCampo(linha, "RSI_V_OP", "<="));
      f.rsiVendaMax = ExtrairNumero(GetCampo(linha, "RSIV", GetCampo(linha, "RSI_V", "45")));
   }
   v = GetCampo(linha, "VOLQ", "");
   if(v != "")
   {
      f.usarVOLQ = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.volqOp = ">=";
      if(IsOn(v))
         f.volqMin = ExtrairNumero(GetCampo(linha, "VOLQMIN", GetCampo(linha, "VOLQ_MIN", "1000")));
      else
         f.volqMin = ExtrairNumero(v);
   }
   v = GetCampo(linha, "VOLF", "");
   if(v != "")
   {
      f.usarVOLF = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.volfOp = ">=";
      if(IsOn(v))
         f.volfMin = ExtrairNumero(GetCampo(linha, "VOLFMIN", GetCampo(linha, "VOLF_MIN", "1000000")));
      else
         f.volfMin = ExtrairNumero(v);
   }
   f.volumeCombinado = IsOn(GetCampo(linha, "VOLCOMB", "OFF"));
   v = GetCampo(linha, "AGF", GetCampo(linha, "AGR", ""));
   if(v != "")
   {
      f.usarAGR = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.agrOp = ">=";
      if(IsOn(v))
         f.agrMin = ExtrairNumero(GetCampo(linha, "AGFMIN", GetCampo(linha, "AGRMIN", "50")));
      else
         f.agrMin = ExtrairNumero(v);
   }
   v = GetCampo(linha, "SCORE", GetCampo(linha, "SCORE_MIN", ""));
   if(v != "")
   {
      f.usarScore = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.scoreMin = ExtrairNumero(v);
      if(f.scoreMin <= 0.0)
         f.scoreMin = 60.0;
      f.scoreExtremo = ExtrairNumero(GetCampo(linha, "EXT", GetCampo(linha, "EXTREMO", "85")));
   }
   v = GetCampo(linha, "M25", GetCampo(linha, "MEDIA25", GetCampo(linha, "DIR", "")));
   if(v != "")
      f.usarMedia25Direcional = IsOn(v);
   v = GetCampo(linha,"FORCA",GetCampo(linha,"STRENGTH",""));
   if(v!="")
   {
      f.usarForca=IsOn(v) || ExtrairNumero(v)>0.0;
      f.forcaMin=IsOn(v) ? ExtrairNumero(GetCampo(linha,"FORCAMIN","60")) : ExtrairNumero(v);
      if(f.forcaMin<=0.0) f.forcaMin=60.0;
   }
   v = GetCampo(linha,"FIBO","");
   if(v!="")
   {
      f.usarFibo=IsOn(v) || ExtrairNumero(v)>0.0;
      f.fiboMin=IsOn(v) ? ExtrairNumero(GetCampo(linha,"FIBOMIN","1.272")) : ExtrairNumero(v);
      if(f.fiboMin<=0.0) f.fiboMin=1.272;
   }
   v = GetCampo(linha,"WAPBANDS",GetCampo(linha,"VWAPBANDS",GetCampo(linha,"WAP","")));
   if(v!="")
   {
      f.usarWapBands=IsOn(v) || ExtrairNumero(v)>0.0;
      f.wapBandDesvios=IsOn(v) ? ExtrairNumero(GetCampo(linha,"WAPDESVIO","1.0")) : ExtrairNumero(v);
      if(f.wapBandDesvios<=0.0) f.wapBandDesvios=1.0;
   }
   if(f.usarScore && !f.usarMedia25Direcional)
      f.usarMedia25Direcional = true;
   return f;
}
void AplicarFiltroToken(RegraFiltros &f, string token);
string Trim(string s);
string Upper(string s);
bool IsOn(string s);
double ExtrairNumero(string s);
int ExtrairInteiro(string s);
string GetCampo(string linha, string chave, string padrao="");
string NormalizarLinhaAumentoHumanizada(string linha);
string GetArg(string args, string chave, string padrao="");
int HorarioParaMinutos(string hhmm);
bool ParseHorario(string horario, int &ini, int &fim);
ENUM_LADO_ROBO ParseLado(string s);
string NomeLado(ENUM_LADO_ROBO lado);
void AtualizarNovoCandle();
void AtualizarMercado();
void AtualizarEstadosDePosicao();
void AtualizarEstadosPainelFinanceiro();
void PrepararSlotPainel(EstadoLado &slot, string nome, long magic, ENUM_LADO_ROBO slotHistorico);
void AtualizarEstadoLado(EstadoLado &estado);
void ResetarDadosCicloSemPosicao(EstadoLado &estado);
void SincronizarResultadoFechadoDiaComHistorico();
double LucroAbertoPosicaoSelecionada(long tipo);
double LucroAbertoPosicaoSelecionadaFIX354(long tipo);
void AtualizarCamposFinanceirosCriticosFIX354(bool forcarRedraw=false);
double GainHeadEfetivoFIX362();
double LossHeadEfetivoFIX362();
string AssinaturaParametrosUsuarioFIX362();
bool SincronizarParametrosUsuarioFIX362(bool forcar=false, string origem="AUTO");
void MontarFotoFinanceiraPainelFIX362(FotoFinanceiraPainelFIX362 &foto, bool forcar=false);
void AtualizarGanhoQtdReaisFIX362(bool forcar=false);
string TextoGanhoQtdReaisFIX362(ENUM_LADO_ROBO lado, bool head=false);
bool AtualizarObjetoValorFIX354(string nome,string texto,color cor,int &ok,int &total);
void RegistrarAuditoriaCamposPainelFIX354(int objOk,int objTotal,int formulaOk,int formulaTotal,string movimento,double bid,double ask,double abertoC,double abertoV,double realizadoC,double realizadoV,double saldoC,double saldoV);
ENUM_LADO_ROBO LadoDaPosicaoAtual(EstadoLado &estado);
void AtualizarRiscoMestre();
void AtualizarHistoricoObrigatorio();
int IntervaloHistoricoEfetivo();
int IntervaloPainelEfetivo();
void ArmarAtualizacaoHistoricoRapidaFIX227(string motivo);
void ProcessarAtualizacaoHistoricoRapidaFIX227();
void ForcarAtualizacaoHistoricoPainel(string motivo);
void AtualizarVisualHistoricoRapido();
void RedesenharAbasHistoricoRapidas(string pfx, int tx, int ty, int fonte);
bool PainelCliqueHistorico(string objeto);
bool PainelCliqueModoVisual(string objeto);
void DesenharBotoesModoPainel(string pfx, int x, int y, int fonte);
void PnlBotaoModo(string nome, string texto, int x, int y, int largura, int altura, bool ativo, int fonte);
bool PainelObjetoAutoFitFIX319(string nome);
void PainelDesativarAutoFitFIX319();
void PainelPrepararCompletoAutoFitFIX319(int &x,int &y,int &largura,int &altura);
void PainelConfigurarAutoFitFIX319(int baseX,int baseY,int baseW,int baseH,int &x,int &y,int &largura,int &altura);
int PainelAutoXFIX319(string nome,int x);
int PainelAutoYFIX319(string nome,int y);
int PainelAutoWFIX319(string nome,int largura);
int PainelAutoHFIX319(string nome,int altura);
int PainelAutoFonteFIX319(string nome,int fonte);
string ChaveControleMagicFIX285(long magic);
string ChaveControleOperacaoFIX284();
long MagicControleLocalFIX285();
string NomeLadoControleMagicFIX285(long magic);
ENUM_CONTROLE_OPERACAO_FIX284 EstadoControleMagicFIX285(long magic);
bool ControleBloqueiaMagicFIX285(long magic);
string TextoControleMagicFIX285(long magic);
bool ExistePosicaoAbertaControleLocalFIX285();
bool FecharPosicoesControleLocalFIX285(string motivo);
void InicializarControleOperacaoFIX284();
void SincronizarControleOperacaoFIX284(bool forcar=false);
void DefinirControleOperacaoFIX284(ENUM_CONTROLE_OPERACAO_FIX284 novoEstado, string motivo);
string TextoControleOperacaoFIX284();
bool ProcessarEncerramentoManualFIX284(bool forcar);
bool PainelCliqueControleOperacaoFIX284(string objeto);
void DesenharBotoesControleOperacaoFIX284(string pfx, int x, int y, int fonte);
void PnlBotaoControleFIX284(string nome, string texto, int x, int y, int largura, int altura, color fundo, color textoCor, color borda, int fonte);
void ObterHistoricoSelecionado(HistoricoPeriodo &h);
void ObterHistoricoPainelPrincipal(HistoricoPeriodo &h);
void CalcularHistoricoOperacaoAtual(HistoricoPeriodo &h);
void ObterHistoricoMagicLocalPainel(EstadoLado &e, HistoricoPeriodo &h);
void CalcularHistoricoPeriodoHeadGrupo(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto);
void MarcarInicioCicloOperacional(EstadoLado &estado);
string NomePeriodoHistoricoPainel(ENUM_PERIODO_HISTORICO_PAINEL periodo);
void CalcularHistoricoPeriodo(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto);
void InicializarMarcoHistoricoZero();
bool AplicarMarcoHistoricoZero(datetime &inicio, datetime fim, HistoricoPeriodo &h, string nome);
ulong CapturarMaiorTicketHistoricoExistente();
bool DealEhDepoisDoMarcoHistoricoZero(ulong deal);
void ZerarHistoricoPeriodo(HistoricoPeriodo &h, string nome);
ENUM_PERIODO_HISTORICO_PAINEL PeriodoIdPorNome(string nome);
void DefinirJanelaHistorico(HistoricoPeriodo &h, datetime inicio, datetime fim, bool incluirAberto);
bool HistoricoPeriodoCompativel(HistoricoPeriodo &h, ENUM_PERIODO_HISTORICO_PAINEL esperado);
void VerificarViradaDiaHistorico(datetime agora);
// FIX310: virada civil, painel diario e seletor FAVOR/CONTRA.
string ChaveControleDiaFIX310(string sufixo);
double AbertoAtualLadoFIX310(ENUM_LADO_ROBO lado);
void SalvarControleDiaFIX310(bool forcar);
void InicializarControleDiaFIX310();
void ProcessarViradaFinanceiraFIX310(datetime agora, bool forcar=false);
void AuditoriaViradaDiaFIX310(datetime agora);
double RealizadoHojeLadoFIX310(ENUM_LADO_ROBO lado);
double VariacaoAbertaHojeLadoFIX310(ENUM_LADO_ROBO lado);
double SaldoHojeLadoFIX310(ENUM_LADO_ROBO lado);
bool ExisteSinalContraValidoFIX310(ENUM_LADO_ROBO lado, string &detalhe);
bool ModoEntradaA0PermiteFIX310(EstadoLado &estado, string &motivo);
string TextoModoEntradaA0FIX310();
bool PrimeiraOrdemLivreProtegidaFIX314();
bool PrimeiraOrdemDesligadaFIX314();
string TextoComoAbrirPrimeiraOrdemFIX314();
// FIX311: fonte unica e auditoria de historico/Magics.
string FamiliaContratoHistoricoFIX347(string simbolo);
bool SimboloAceitoHistoricoFIX347(string simbolo);
datetime InicioOntemCivilFIX311(datetime referencia);
bool PosicaoTemIdentidadeAR100FIX311(long magic);
bool MagicHistoricoCompraFIX458(long magic);
bool MagicHistoricoVendaFIX458(long magic);
bool MagicPertenceHistoricoFinanceiroFIX458(long magic);
long TipoLadoHistoricoMagicFIX458(long magic);
long TipoPosicaoEsperadoMagicPainelFIX316(long magic);
bool PosicaoSelecionadaPertencePainelFIX316(long magic);
bool PosicaoSelecionadaPertenceEstadoFIX317(EstadoLado &estado);
bool DealPertenceHistoricoPainelFIX316(ulong deal);
void ObterEntradasAbertasPainelFIX316(double &qtdCompra, double &qtdVenda, int &entradasCompra, int &entradasVenda);
void AplicarFallbackEntradasAbertasHistoricoFIX316(HistoricoPeriodo &h);
void CalcularHistoricoPeriodoCoreFIX311(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto, long magicFiltro);
double AbertoPeriodoLadoFIX311(HistoricoPeriodo &h, ENUM_LADO_ROBO lado);
double SaldoPeriodoLadoFIX311(HistoricoPeriodo &h, ENUM_LADO_ROBO lado);
void AuditoriaHistoricoMagicFIX311(bool forcar);
void InicializarHistoricoPainelZerado();
void CapturarMarcoHistoricoInicial();
bool DealEhDepoisDoMarcoHistoricoSessao(ulong deal);
datetime AgoraServidorHistorico();
datetime InicioDoDia(datetime ref);
datetime InicioDiasAtras(int quantidadeDias);
double ResultadoDealHistorico(ulong deal);
bool CalcularLucroEsperadoDealReaisFIX313(ulong dealSaida, double &lucroEsperado, double &precoMedio, double &volumeSaida);
double ResultadoDealSeguroReaisFIX313(ulong deal);
bool ObterResultadoDealCacheFIX313(ulong deal, double &resultado);
void SalvarResultadoDealCacheFIX313(ulong deal, double resultado);
bool AuditarUnidadeFinanceiraHojeFIX313(int &corrigidos, int &semBase, double &somaBruta, double &somaSegura);
int ContarSaidasRecentesFIX313(int janelaSegundos);
bool ProtecaoRepeticaoPermiteNovaOrdemFIX313(EstadoLado &estado, string contexto);
bool DealEhParcialHistoricaReal(ulong deal);
bool DealEhDoRoboHistorico(ulong deal);
bool DealEhDoRobo(ulong deal);
bool DealEhSaidaParcial(long entry);
double ParcialHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado);
int TradesLucroHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado);
int TradesPrejuHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado);
string LinhaHistoricoPeriodo(HistoricoPeriodo &h);
double CalcularScoreFluxo();
void AtualizarCurvaVolumeHoraHora(int shiftFiltro);
datetime InicioDia(datetime t);
datetime MontarHorarioNoDia(datetime dia, string horaMinuto);
datetime DiaAnteriorComBarras(datetime diaAtual);
double SomarVolumePeriodo(datetime inicio, datetime fim, bool financeiro);
int SlotHoraHora(datetime t, datetime inicio, int slotMinutos, int maxSlots);
double LimiteVolumeQtdDinamico(RegraFiltros &f);
double LimiteVolumeFinDinamico(RegraFiltros &f);
ENUM_STATUS_MERCADO ClassificarMercado(double score);
string NomeStatusMercado(ENUM_STATUS_MERCADO status);
string TextoDXStatus();
color CorMagicPiscando(color corBase);
ENUM_LADO_ROBO LadoCardLocalPainelAtual();
void ObterEstadoMotorPainelLocal(EstadoLado &destino);
void ObterEstadoResumoPainelLocal(EstadoLado &destino);
string TituloResumoLocalPainel(EstadoLado &e);
bool CardFinanceiroEhFoco(EstadoLado &e);
void CalcularResumoFinanceiroSlotPainel(EstadoLado &e, HistoricoPeriodo &h, ResumoFinanceiroPainel &r);
void CalcularResumoFinanceiroTotalAB(ResumoFinanceiroPainel &a, ResumoFinanceiroPainel &b, ResumoFinanceiroPainel &t);
string TextoFormulaSaldoCard3(ResumoFinanceiroPainel &a, ResumoFinanceiroPainel &b, ResumoFinanceiroPainel &t);
void ZerarFotoCestaAB(FotoCestaAB &f);
datetime InicioHistoricoCestaABOficial();
void CalcularFotoCestaABOficial(FotoCestaAB &f, bool usarSnapshotAberto=false);
string TextoLogFotoCestaAB(FotoCestaAB &f);
void LogCestaABDetalhado(string contexto, bool forcar=false);
void LogDealSaidaCestaAB(ulong deal);
string NomeTipoPosicaoHedge(long type);
string NomeTipoDealHedge(long type);
string NomeEntryDealHedge(long entry);
int ContarPosicoesAbertasGrupoAB();
string TextoPosicoesAbertasGrupoAB();
string TextoHedgeStatusAB(FotoCestaAB &f);
void LogHedgeCompleto(string contexto, string etapa, string motivo, ulong ticket, ulong deal, long magic, uint retcode, int erro, double volume, double preco, bool forcar);
double LinhaStopFullAtualHedgeAB();
string MotivoLinhaStopFullHedgeAB();
void LogStopFullHedgeAB(string contexto, bool forcar=false);
bool ExistePosicaoAbertaGrupoTotalAB();
bool CestaABTemDuasPontasAbertasGrupo();
bool FecharCestaABOficial(string motivo);
void AtualizarEstadoFimDiaFIX215();
bool BloquearNovasOperacoesFimDiaFIX215();
bool HorarioFechamentoObrigatorioFIX215();
bool ProcessarFechamentoFimDiaFIX215();
bool GerenciarStopDiaMestreFIX320();
string TextoStatusFimDiaFIX215();
void DispararMsgBoxVisualFIX226(string titulo, string linha1, string linha2);
bool MsgBoxVisualAtivaFIX226();
void LimparMsgBoxVisualFIX226(string pfx);
void AvaliarEventoMsgBoxFIX226(string contexto, string mensagem, bool importante);
bool MagicPertencePainelTotalAB(long magic);
bool GrupoHeadTemPosicaoTipo(long tipo);
bool LadoObrigatorioOpostoGrupoHead(ENUM_LADO_ROBO lado);
bool LadoBloqueadoPorOpostoGrupoHead(ENUM_LADO_ROBO lado);
string ChaveParABCompletadoFIX274();
bool ParABJaCompletadoFIX274();
void AtualizarEstadoParABFIX274();
bool ExecutarAuditoriaTesteFIX274();
string TextoGrupoMagicsTotalAB();
void CalcularAbertoTotalABGrupoDiretoBase(double &qtdCompra, double &qtdVenda, double &totalBruto, double &abertoCompra, double &abertoVenda, double &abertoTotal);
void CalcularAbertoTotalABGrupoDireto(double &qtdCompra, double &qtdVenda, double &totalBruto, double &abertoCompra, double &abertoVenda, double &abertoTotal);
string TextoFocoUnico(EstadoLado &e);
string TextoMagicTopoPiscando();
double ContratosPlanejadosTotal();
void LimparPlotagemDX();
void AtualizarPlotagemDX();
void GarantirDXIndicadorNoGrafico();
bool FiltroVisualSelecionadoFIX343(string filtro);
bool GarantirOsciladoresSelecionadosFIX343();
void RemoverOsciladoresSelecionadosFIX343();
bool LocalizarIndicadorPorPrefixoFIX345(string prefixo,int &janela,string &nome);
bool GarantirDXVisualEditavelFIX345();
void RemoverDXVisualEditavelFIX345();
void DetectarFechamentoVisualUsuarioFIX345();
int PeriodoMediaGraficoEfetivo();
void GarantirMedia25NoGrafico();
void AtualizarBandasMedia25Grafico(bool forcar=false);
void LimparBandasMedia25Grafico();
void AplicarGraficoLimpoFIX353();
void AtualizarPainelFinanceiroImediatoFIX353(bool forcarHistorico=false);
bool CriarSegmentoMedia25(string nome, datetime t1, double p1, datetime t2, double p2, color cor, ENUM_LINE_STYLE estilo, int largura);
void LimparEntradasHistoricasGraficoFIX385();
void AtualizarEntradasHistoricasGraficoFIX385(bool forcar=false);
void PlotarEntradaHistoricaNoGraficoFIX385(ulong deal);
void PlotarPosicoesAbertasProvisoriasFIX390();
bool DealEhEntradaPlotavelGraficoFIX385(ulong deal);
void RemoverADXVisualLegado();
void ConfigurarObjetoAtrasPainel(string nome);
string TextoDXConfigPainel();
string NomeModoPainelVisual(ENUM_MODO_PAINEL_VISUAL modo);
string TextoCortarPainel(string texto, int larguraPx, int fonte);
string PnlMoedaBRL(double valor);
string TextoMoedaPainelCurto(double valor);
void PainelTextoCortado(string nome, string texto, int x, int y, color cor, int fonte, string fontName, int larguraPx);
void GerenciarLado(ENUM_LADO_ROBO lado);
void GerenciarEstadoLado(EstadoLado &estado);
bool TipoOperacaoPermiteLado(ENUM_LADO_ROBO lado);
string TextoTipoOperacaoParametro();
bool GerenciarProtecaoLado(EstadoLado &estado);
bool GerenciarParciaisLado(EstadoLado &estado);
double ResultadoProtecaoOperacaoLado(EstadoLado &estado);
double CalcularDefesaCurtaPorDegrau(double melhorLucro);
string NomeRegimeCorredorFIX338(ENUM_REGIME_CORREDOR_FIX338 regime);
ENUM_REGIME_CORREDOR_FIX338 AvaliarRegimeCorredorFIX338(long tipo, int &favoraveis, int &contrarios, string &leitura);
double CalcularPisoCorredorFIX338(double melhorLucro, double ativacao, double pisoInicial, double degrau, double folga);
bool CorredorAlvoPontaViraMarcoFIX338();
bool CorredorMetaABViraMarcoFIX338();
double CalcularDefesaMaiorCestaAB(double melhorLucro);
bool GerenciarProtecaoMaiorCestaAB();
bool CestaABTemDuasPontasAbertas();
bool GerenciarParcialProtecaoCurtaCestaAB();
bool GerenciarLucroPontaGanhadoraHedgeAB();
bool CestaABTemAlgumaPosicaoFIX195();
void ResetarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &e);
void PrepararNovoCicloPontaFIX275(EstadoLado &estado);
void AtualizarCicloMestreSimplesFIX195();
void ResetarCicloMestreSimplesFIX195SeFlat();
bool ProcessarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, double lucroPonta, double volumePonta);
bool ProcessarPontaSimplesFIX195(long tipo,double lucroPonta,double volumePonta);
bool ProcessarGerenciamentoSimplesInstanciaFIX255();
bool AplicarMagicsCompactosFIX255(string &motivo);
bool JanelaAtualEhA_FIX255();
bool JanelaAtualEhB_FIX255();
ENUM_LADO_ROBO LadoOperacionalInstanciaFIX255();
long MagicOperacionalInstanciaFIX255();
bool InstanciaGerenciaLadoFIX255(ENUM_LADO_ROBO lado);
bool LadoHabilitadoUsuarioFIX346(ENUM_LADO_ROBO lado);
string TextoLadosHabilitadosFIX346();
bool InstanciaMestreGrupoFIX255();
string NomeJanelaInstanciaFIX255();
ENUM_TIMEFRAMES TimeframeFiltroAtualFIX255();
ENUM_TIMEFRAMES TimeframeEntradaAtualFIX255();
string PrefixoCoordenacaoMagicsFIX256();
string ChaveCoordenacaoMagicsFIX256(string campo);
datetime AgoraCoordenacaoMagicsFIX256();
bool RegistroJanelaAtivoFIX256(bool janelaA, long &chartId, datetime &heartbeat);
bool AdquirirLockCoordenacaoMagicsFIX256();
void LiberarLockCoordenacaoMagicsFIX256();
bool RegistrarCoordenacaoMagicsFIX256(string &motivo);
void AtualizarCoordenacaoMagicsFIX256(bool forcar=false);
void DesregistrarCoordenacaoMagicsFIX256();
bool CoordenacaoPermiteNovaOrdemFIX256(EstadoLado &estado, string contexto);
int NivelAumentoComentarioFIX207(string comentario);
int NivelAumentoDealRobustoFIX296(ulong deal);
void ReconstruirMarcacaoAumentosRealizadosFIX296(EstadoLado &estado, datetime inicio);
void SincronizarRealizacoesAumentosFIX296(bool forcar);

int NivelAumentoPosicaoFIX212(EstadoLado &estado, ulong ticket, string comentario);
bool ObterPosicaoAumentoNivelFIX212(EstadoLado &estado, int nivel, ulong &ticket, double &precoEntrada, double &volume, long &tipo);
double PrecoRealizacaoAumentoFIX212(long tipo, double precoEntrada, double volume, double alvoReais);
double PrecoLossAumentoFIX321(long tipo, double precoEntrada, double volume, double lossReais);
void SalvarAlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel, double precoAlvo);
double AlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel);
void MarcarAumentoRealizadoFIX212(EstadoLado &estado, int nivel, double precoRealizado);
bool AumentoRealizadoFIX212(EstadoLado &estado, int nivel, double &precoRealizado);
void ResetarRastreamentoAumentosFIX212(EstadoLado &estado);
string NomeBasePrecoAumentoFIX220();
string ChavePrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel);
void SalvarPrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel, double preco);
double PrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel);
void RegistrarAuditoriaVisualAumentoFIX358(EstadoLado &estado,int nivel,double programado,double executado);
double PrecoProgramadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel);
double PrecoExecutadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel);
void RestaurarPrecosEntradaAumentosFIX220(EstadoLado &estado);
double PassoAumentoPontosFIX220(int indiceZero);
double UltimoPrecoAumentoAntesFIX220(EstadoLado &estado, int indiceZero, int &nivelEncontrado);
string ChaveAncoraRearmeA1FIX225(EstadoLado &estado);
string ChaveCicloRearmeA1FIX225(EstadoLado &estado);
double AncoraRearmeA1FIX225(EstadoLado &estado);
int CicloRearmeA1FIX225(EstadoLado &estado);
void SalvarAncoraRearmeA1FIX225(EstadoLado &estado, double preco);
string ChaveNivelInicioRearmeFIX248(EstadoLado &estado);
int NivelInicioRearmeFIX248(EstadoLado &estado);
void SalvarContextoRearmeFIX248(EstadoLado &estado, double precoMedio, int nivelInicio);
void LimparContextoRearmeFIX248(EstadoLado &estado);
string ChaveRearmePendenteFIX251(EstadoLado &estado, string campo);
void PersistirRearmePendenteFIX251(EstadoLado &estado);
void RestaurarRearmePendenteFIX251(EstadoLado &estado);
void LimparRearmePendenteFIX251(EstadoLado &estado);
bool RearmeParcialPendenteFIX248(EstadoLado &estado);
void AgendarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido);
bool ProcessarRearmeDinamicoPendenteFIX248(EstadoLado &estado);
bool RecuperarRearmeSemEventoFIX452(EstadoLado &estado);
int PrimeiroNivelRearmavelFIX248(EstadoLado &estado, int nivelRealizado);
void LimparMemoriaNiveisAPartirFIX248(EstadoLado &estado, int nivelInicial);
bool AplicarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido);
bool PrecoNoLadoGatilhoAumentoFIX248(EstadoLado &estado, double linha);
double PrecoExecutavelAumentoFIX363(EstadoLado &estado);
bool PrecoAumentoNaLinhaOuMelhorFIX363(EstadoLado &estado,double linha,string &status);
bool ValidarAumentoFinalAntesEnvioFIX363(EstadoLado &estado,int indiceZero,double linhaProgramada,string &status);
void PrepararNovoCruzamentoNivelFIX248(EstadoLado &estado, int nivel);
bool NovoCruzamentoLiberadoFIX248(EstadoLado &estado, int nivel, double linha, string &status);
bool EscadaA1RearmadaFIX225(EstadoLado &estado);
int ProximoIndiceAumentoSequencialFIX218(EstadoLado &estado);
double CalcularDefesaDegrauFIX281(double melhorLucro, double ativacao, double passo);
void ResetarTrailAumentoFIX281(EstadoTrailAumentoFIX281 &trail);
bool ProcessarTicketAumentoFIX281(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, ulong ticket, int nivel, double volume, double lucroTicket, EstadoTrailAumentoFIX281 &trail);
void CalcularAumentosAbertosLadoFIX281(EstadoLado &estado, double &volumeAberto, double &financeiroAberto, int &ticketsAbertos);
void ReconstruirRealizacoesAumentosCicloFIX281(long magic, long tipoPosicao, datetime inicio, double &financeiro, double &volume, int &quantidade);
bool FecharTicketAumentoFIX207(EstadoLado &estado, ulong ticket, double volumeDesejado, int nivel, double lucroTicket, string motivoFIX281);
bool GerenciarRealizacaoAumentosPorTicketFIX207(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo);
double ResultadoCicloPontaFIX207(long tipo, double lucroAberto);
bool FecharParcialGrupoPorTipo(long tipo, double volumeDesejado, string motivo);
void LimparLocksLucroPontaHedgeAB();
int HashTextoCurtoAB(string texto);
string ChaveGlobalCurtaAB();
string ChaveCicloGrupoTipoAB(long tipo);
void LimparLocksParciaisHedgeABPorPrefixo();
void ArmarProtecaoFinanceiraLado(EstadoLado &estado, string contexto, bool importante);
double NormalizarVolumeParaFechamento(double volume);
double CalcularVolumeParcialSeguro(double volumeAtual, double percentualVolume);
bool FecharParcialPosicoesLado(EstadoLado &estado, double volumeDesejado, string motivo);
bool GerenciarGainGlobalCestaAB();
bool GerenciarStopMovelCestaAB();
void ResetarCicloCestaABQuandoFlat();
bool RiscoOperacaoModoCesta();
double StopBaseCestaAB();
double GainGlobalCestaAB();
double ResultadoRealizadoCestaABAtual();
double ResultadoAbertoCestaABAtual();

double SaldoLiquidoCestaABAtual();
double StopMovelAbertoPermitidoCestaAB();
double EspacoStopRestanteCestaAB();
string TextoGainStopCestaPainel();
double CalcularDefesaTrailingLado(EstadoLado &estado);
bool DeveAtivarModoLongo(EstadoLado &estado);
bool SaidaTecnicaLonga(EstadoLado &estado, string &motivo);
bool GerenciadorAutorizaAumento(EstadoLado &estado, RegraAumento &aum);
bool PodeExecutarAumento(EstadoLado &estado, RegraAumento &aum, int indiceZero);
bool ExistePosicaoMagicQualquerInstancia(long magic);
string PrefixoLockCicloMagic(long magic);
string ChaveLockA0(EstadoLado &estado);
bool ExisteOrdemPendenteA0FIX257(EstadoLado &estado);
string ChaveLockAumento(EstadoLado &estado, int idx);
string ChaveLockAumentoConfirmadoFIX208(EstadoLado &estado, int idx);
bool ExisteOrdemPendenteAumentoFIX208(EstadoLado &estado, int idx);
double VolumePlanejadoAteAumentoFIX208(int idx);
void MarcarLockAumentoConfirmadoFIX208(EstadoLado &estado, int idx);
bool RegistrarLockCiclo(string chave);
void LiberarLockCiclo(string chave);
bool RegistrarLockA0(EstadoLado &estado);
bool RegistrarLockAumento(EstadoLado &estado, int idx);
bool LockAumentoJaRegistrado(EstadoLado &estado, int idx);
int AumentosExecutadosPlanejadosPorContratos(double contratos);
void LimparLocksCicloMagic(long magic);
bool ValidarTravasDeValidacaoInicial();
bool ExistePosicaoAR100Aberta();
bool PermitirEntradaA0PeloModoValidacao(EstadoLado &estado);
bool PermitirAumentoPeloModoValidacao(EstadoLado &estado, int idxAlvo);
string TextoModoValidacaoExecucao();
string NomeTimeframeCurto(ENUM_TIMEFRAMES tf);
bool PermiteEnvioOrdem(EstadoLado &estado, string contexto);
bool PermiteEnvioAumentoDiretoFIX211(EstadoLado &estado, string contexto);
bool ReentradaTimerAtivo();
bool STFTPermiteNovaEntrada(EstadoLado &estado);
void RegistrarSTFTFechamento(EstadoLado &estado, double resultado);
bool ExistePontaContrariaAberta(ENUM_LADO_ROBO lado);
bool BloquearA0OutraPontaAutomatica(EstadoLado &estado);
bool ExisteMesmoSentidoOutroMagicMesmoTF(EstadoLado &estado);
double ResultadoPontaContraria(ENUM_LADO_ROBO lado);
bool PontaContrariaNegativaParaHedge(ENUM_LADO_ROBO lado);
bool PermitirEntradaHedgeRecuperacao(EstadoLado &estado, string &motivo);
int  EscolherIndiceAumentoInteligente(EstadoLado &estado);
int  PrimeiroIndiceAumentoAtivoApartir(int inicio);
bool TimerAumentoLiberado(EstadoLado &estado, RegraAumento &aum, int indiceZero=-1);
bool PrecoChegouNivelAumentoNivel(EstadoLado &estado, RegraAumento &aum, int indiceZero);
void LimparConfirmacaoCandleAumentoFIX224(EstadoLado &estado, int indiceZero);
bool CandleAumentoConfirmadoFIX224(EstadoLado &estado, int indiceZero);
datetime CandleToqueAumentoFIX224(EstadoLado &estado, int indiceZero);
bool ConfirmarFechamentoCandleAumentoFIX224(EstadoLado &estado, int indiceZero, double linha, string &status);
string StatusCandleAumentoFIX224(EstadoLado &estado, int indiceZero);
bool ExecutarEntradaA0(EstadoLado &estado, RegraJanela &janela);
double VolumeAtualMagicServidor(EstadoLado &estado);
bool ExecutarAumento(EstadoLado &estado, RegraAumento &aum, int idx);
bool EnviarOrdemMercado(EstadoLado &estado, double volume, string comentario, string contextoEnvio);
void AplicarAmbienteExecucaoFIX342();
bool ExecutarAuditoriaProducaoFIX342(string &detalhes);
bool ValidarPreflightEntradaFIX342(EstadoLado &estado,MqlTradeRequest &req,string &motivo,MqlTradeCheckResult &check);
void ProcessarRetcodeEntradaFIX342(EstadoLado &estado,uint retcode,uint retcodeExterno,string contexto);
double CalcularStopServidorEntradaFIX342(ENUM_LADO_ROBO lado,double precoEntrada);
void GarantirStopsServidorFIX342(bool forcar=false);
bool ConfiguracaoParABCompativelFIX342(string &motivo);
double PrecoReferenciaFIX344(ENUM_REFERENCIA_PRECO_FIX344 referencia,string &origem);
bool ValidarRangeGridEntradaFIX344(EstadoLado &estado,double preco,string &motivo);
void AtualizarRangeGridGraficoFIX344(bool forcar=false);
void LimparRangeGridGraficoFIX344();
bool PermissoesTradingFIX279(ENUM_LADO_ROBO lado, string &motivo);
bool EnviarA0DiretoFIX279(EstadoLado &estado);
bool ProcessarEntradaDiretaFIX279();
bool FecharPosicoesLado(EstadoLado &estado, string motivo);
ENUM_ORDER_TYPE_FILLING TipoPreenchimentoSeguro();
double NormalizarVolume(double volume);
void RegistrarGerenciadorOrdens(EstadoLado &estado, string contexto, string mensagem, uint retcode, int erro, double volume, double preco, bool importante);
void FecharLogValidacaoCSV();
bool ContextoLogValidacaoRelevante(string contexto, string mensagem, bool importante);
string SanitizarCampoCSV(string texto);
void RegistrarLogValidacaoCSV(EstadoLado &estado, string contexto, string mensagem, uint retcode, int erro, double volume, double preco, bool importante);
void RegistrarLogValidacaoSistema(string contexto, string mensagem);
// FIX302 auditoria
void AplicarCenarioAuditoriaFIX302();
bool EntradaDiretaDemoEfetivaFIX302();
bool ModoContinuidadeTesteFIX352();
string FiltroEfetivoAuditoriaFIX302(string configurado);
void AuditoriaInicializarFIX302();
void AuditoriaResetarNiveisFIX302();
void AuditoriaAtualizarCicloFIX302();
void AuditoriaRegistrarEventoFIX302(EstadoLado &estado,string contexto,string mensagem,uint retcode,int erro,double volume,double preco,bool importante);
void AuditoriaRegistrarDealEntradaFIX302(ulong deal,int nivel);
void AuditoriaRegistrarDealSaidaFIX302(ulong deal,int nivel,double resultado);
void AuditoriaRegistrarDealBrutoFIX305(ulong deal,int nivel);
string AuditoriaCabecalhoDealsFIX305();
double ResultadoDealServidorFIX305(ulong deal);
double ComissaoManualDealFIX305(ulong deal);
double ComissaoAplicadaDealFIX305(ulong deal);
double ResultadoDealLiquidoAuditadoFIX305(ulong deal);
string NomeModoComissaoFIX305();
void AuditoriaFlushFIX302(bool forcar);
void AuditoriaFecharFIX302();
void AuditoriaRegistrarTempoTickFIX302(ulong micros);
void AuditoriaRegistrarTempoTimerFIX302(ulong micros);
void AuditoriaRegistrarTempoTradeFIX302(ulong micros);
void AuditoriaValidarGraficoFIX302(bool forcar);
void AuditoriaAtualizarTelaFIX302(bool forcar);
bool PainelCliqueAuditoriaFIX302(string objeto);
// FIX306 exportacao semanal externa
bool ExportacaoIniciarFIX306();
void ExportacaoProcessarTimerFIX306();
void ExportacaoFecharFIX306();
string ExportacaoStatusCurtoFIX306();
void ProcessarOnTickMotorFIX302();
void ProcessarOnTimerMotorFIX302();
void ProcessarOnTradeTransactionMotorFIX302(const MqlTradeTransaction& trans,const MqlTradeRequest& request,const MqlTradeResult& result);
void LimparSnapshotEntradaFiltros();
string TextoLadoOrdem(ENUM_LADO_ROBO lado);
string ValorBoolSN(bool v);
bool MontarDiagnosticoFiltros(RegraFiltros &f, ENUM_LADO_ROBO lado, string &resumo, string &detalhe, int &total, int &ok, string &m25Status, string &scoreStatus, double &scoreLado, string &hiloOK, string &strOK, string &dxOK, string &rsiOK, string &volqOK, string &volfOK, string &agrOK);
void RegistrarLogEntradaFiltros(EstadoLado &estado, string contexto, string tipoEntrada, RegraFiltros &f, bool decisaoLiberada, string motivo, bool importante);
void RegistrarDecisaoOperacional(EstadoLado &estado, string contexto, string mensagem);
void LogExpertsGerenciador(string assinatura, string contexto, EstadoLado &estado, string mensagem, bool importante);
string ResumoGerenciadorOrdens();
bool ExisteJanelaAtivaParaLado(ENUM_LADO_ROBO lado, RegraJanela &janelaOut);
bool EstaDentroJanela(RegraJanela &j);
int MinutoAtualDoDia();
bool ValidarFiltros(RegraFiltros &f, ENUM_LADO_ROBO lado);
bool ValidarComparacao(double valor, string op, double limite);
double Media25FiltroValor(int shift);
ENUM_LADO_ROBO DirecaoMedia25Operacional();
bool Media25PermiteLado(ENUM_LADO_ROBO lado, string &motivo);
double ScoreDirecionalDoLado(ENUM_LADO_ROBO lado);
string TextoDirecaoMedia25();
void AtualizarPainelMestre();
void AtualizarPainelGrafico();
void AtualizarRodapePainelRapido();
void PainelChartRedrawLeve(bool clique=false);
void ReencaixarPainelInicialSeNecessario();
void LimparPainelGrafico();
void LimparTodosObjetosCOPA();
void LimparSomentePainelVisual();
void DesenharCardAumentos(EstadoLado &estado, int x, int y, int largura, int altura);
void DesenharCardHistorico(int x, int y, int largura, int altura);
bool ExistePosicaoMagicTipo(long magic, long tipo);
string TextoSelecaoHead();
string TextoHeadExterno();
bool SinalSaidaOperacaoLonga(EstadoLado &estado);
bool EscalonamentoGanhosAtivo();
double DefesaMetaDiaEscalonadaFIX331(double melhorLucro, double &etapaAtingida);
bool ValidarParametrosOperacionaisFIX331(string &erro);
double NivelEscalonamentoAtual(double melhorLucro);
double CalcularDefesaEscalonadaPorGanho(double melhorLucro);
string TextoEscalonamentoGanhosPainel(double melhorLucro);
void AtualizarProtecaoResultadoDia();
string TextoPosicaoCard(EstadoLado &estado);
string TextoLadoCurto(ENUM_LADO_ROBO lado);
double ExposicaoMaximaLado(EstadoLado &estado);
double ExposicaoNegativaLado(EstadoLado &estado);
double ExposicaoNegativaTotalPainel();
double ResultadoAbertoTotalPainel();
double DistanciaPrecoPorFinanceiro(double valorReais, double volume);
double GatilhoParcialEfetivoPorVolume(double valorBaseReais, double volume);
double GatilhoParcialEfetivoLado(EstadoLado &estado, double valorBaseReais);
double GatilhoParcialEfetivoCestaAB(double valorBaseReais);
void AplicarParcialOperacaoCompacta();
void AplicarAumentosDiretoDasLinhasParametros();
bool ParcialOperacaoAtivaEfetiva();
double ParcialGatilhoBaseReaisEfetivo();
double ParcialPassoBaseReaisEfetivo();
double ParcialPercentualVolumeEfetivo();
bool ParcialPorContratoEfetivo();
bool ParcialRecuoAumentoAtivoEfetivo();
long TipoPosicaoPeloLadoEstado(EstadoLado &estado);
void ReaplicarParametrosAntesDoGrafico(string origem);
bool CalcularInfoGrupoTipoAB(long tipo, double &volume, double &precoMedio, double &lucroAberto, double &precoFechamento);
double LucroEstimadoGrupoTipoPorPreco(long tipo, double volume, double precoMedio, double precoFechamento);
double PrecoNivelParcialGraficoLado(EstadoLado &estado, double valorBaseNivel, double &valorNivelEfetivo, double &volumeReferencia);
double DistanciaAumentoPontosIndice(int indiceZero);
bool PrecoEntradaReferenciaGrupoTipoAB(long tipo, double &precoEntradaRef, double &volume, double &precoFechamento);
int AumentosExecutadosEfetivosLado(EstadoLado &estado, long tipo);
double PrecoNivelParcialRecuoAumento(EstadoLado &estado, long tipo, double recuoPontos, double &distAumentoPontos, double &distLinhaPontos, double &precoEntradaRef);
bool GerenciarParcialPorLinhaGraficoHeadAB();
double PrecoNivelAumentoValorIndice(EstadoLado &estado, int indiceZero);
string PrecoNivelAumentoTextoIndice(EstadoLado &estado, int indiceZero);
void LimparPlotagemOperacional();
void LimparPlotagemPrefixo(string prefixo);
void AtualizarPlotagemOperacional();
void PlotarLinhasOperacionaisLado(string prefixo, EstadoLado &estado);
void PlotarLinhaPrecoBox(string nomeBase, double preco, color corLinha, ENUM_LINE_STYLE estilo, int larguraLinha, string legenda, color corTexto, color corFundo, int yAjuste);
double ExposicaoMaximaTotal();
string FormatarMoeda(double valor);
color CorFinanceiro(double valor);
color CorStatusTexto(string status);
color CorLadoTexto(ENUM_LADO_ROBO lado);

#include "modulos/base_historica.mqh"


#include "modulos/motor_canais.mqh"

#include "modulos/auditoria_ticks.mqh"

int OnInit()
{
   Print("[COPA_AR100][FIX454][ARQUIVO_ATIVO] V103 | COMPILACAO_CORRIGIDA | REARME_POR_NIVEL=ON | TIMER_INDIVIDUAL=ON | FILTROS_SOMENTE_SE_CONFIGURADOS=ON | ACUM=ON");
   FIX433AbrirArquivos();
   Print("[COPA_AR100][FIX438][ARQUIVO_ATIVO] V87 | COLETA_MQL5_FILES_STATUS_TICKS_MINUTOS | COLETA_120D | TICKS+MINUTOS+POSICOES+DEALS | POC+RSI7+AGR+FORCA+BOLL+KELT+HILO+STR");
   Print("[COPA_AR100][FIX417][BASE] DX_A1_A4_INDEPENDENTE=ON | CONSUMO_SOMENTE_APOS_ORDEM=ON | SINAL_PERSISTENTE=ON");
   PrepararParametrosMestreFIX372();
   AplicarAmbienteExecucaoFIX342();
   AplicarGraficoLimpoFIX353();
   string erroParametrosFIX331="";
   if(!ValidarParametrosOperacionaisFIX331(erroParametrosFIX331))
   {
      Print("[COPA_AR100][FIX331][PARAMETROS_INVALIDOS] ",erroParametrosFIX331);
      return INIT_PARAMETERS_INCORRECT;
   }
   // FIX283: configuracao leve aplicada antes de abrir logs, historico e timer.
   if(InpFIX283ModoLeve)
   {
      int intervaloHistFIX283=InpFIX283HistoricoIntervaloSegundos;
      if(intervaloHistFIX283<1) intervaloHistFIX283=1;
      InpHistoricoAtualizarSegundos=intervaloHistFIX283;
      InpLogValidacaoFlushImediato=false;
      if(InpFIX283DesligarLogsContinuos)
      {
         InpLogCestaABDetalhado=false;
         InpLogHedgeCompletoAtivo=false;
         InpLogStopFullHedgeAtivo=false;
         InpLogCestaABNoExperts=false;
         InpLogEntradaFiltrosNoExperts=false;
      }
   }
   // FIX288: papel fixo por janela. Nunca permitir OPERACAO_AMBOS nesta instancia.
   InpTipoOperacao = JanelaAtualEhA_FIX255() ? OPERACAO_COMPRA : OPERACAO_VENDA;
   string erroMagicFIX252 = "";
   if(!AplicarMagicsCompactosFIX255(erroMagicFIX252) || !ValidarMagicsConfiguradosFIX252(erroMagicFIX252))
   {
      Print("[COPA_AR100][FIX257][MAGIC_INVALIDO] ", erroMagicFIX252);
      return INIT_PARAMETERS_INCORRECT;
   }
   bool registroCoordenacaoFIX260=RegistrarCoordenacaoMagicsFIX256(erroMagicFIX252);
   if(!registroCoordenacaoFIX260)
   {
      // FIX260: nunca fechar o EA apenas porque a outra janela ainda usa o Magic antigo.
      // O painel abre normalmente e o envio de novas ordens fica bloqueado ate a sincronizacao.
      g_coordenacaoMagicsOK_FIX256=false;
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: "+erroMagicFIX252;
      Print("[COPA_AR100][FIX260][SINCRONIZACAO_MAGIC_PENDENTE] ",erroMagicFIX252,
            " | O painel sera aberto; novas ordens permanecem bloqueadas.");
   }
   InicializarIdentidadeUnicaFIX304();
   InicializarMarcoHistoricoZero();
   LimparCandlesContraFIX258(); // FIX263: remove restos da versão anterior somente na inicialização
   LimparTodosObjetosCOPA();
   InicializarEstados();
   InicializarHistoricoPainelZerado();
   SincronizarMagicParametros(true);
   InicializarControleOperacaoFIX284();
   if(InpFIX293TesteDX2ZeroAmbosLados)
   {
      // Mesmo no teste extremo, não apagamos o relógio de reentrada nem a coordenação entre janelas.
      g_controleOperacaoFIX284 = CONTROLE_OPERACAO_ATIVO_FIX284;
      GlobalVariableSet(ChaveControleOperacaoFIX284(), (double)CONTROLE_OPERACAO_ATIVO_FIX284);
      g_statusControleOperacaoFIX284 = "TESTE EXTREMO ATIVO | PROTECOES DE REPETICAO MANTIDAS";
   }
   g_horarioInicioRobo = TimeCurrent();
   CapturarMarcoHistoricoInicial();
   GerarBaseHistoricaValidacao();
   bool ambienteContaOKFIX342=ValidarAmbienteConta();
   if(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL && !ambienteContaOKFIX342)
   {
      Print("[COPA_AR100][FIX342][REAL_BLOQUEADO] ",g_mestre.mensagemAmbiente);
      return INIT_PARAMETERS_INCORRECT;
   }
   AplicarCenarioAuditoriaFIX302();
   CarregarTodasMatrizes();
   PrintFormat("[COPA_AR100][FIX377][CENARIO] A0_LIVRE=%s | COMPRA=%d | VENDA=%d | REENT=%ds/%ds | A1-A4 RSI RECUPERACAO 55/45 | TIMER 1S",
               EntradaDiretaDemoEfetivaFIX302()?"SIM":"NAO",(int)MagicCompraAtual(),(int)MagicVendaAtual(),
               InpReentradaLucroSegundosFIX372,InpPausaReentradaSegundos);
   PrintFormat("[COPA_AR100][FIX380][TRAIL_A0_DIRETO] LEGADO_DUPLO=OFF | CORREDOR=OFF | ATIVA=R$ %.2f | PASSO=R$ %.2f | DEFESA_INICIAL=R$ %.2f | LINHA=BRANCA | BASE=SOMENTE_LUCRO_ABERTO",
               MathAbs(g_entradaTrailingAtivarReaisEfetivo),
               MathAbs(g_entradaTrailingPassoReaisEfetivo),
               MathMax(0.0,MathAbs(g_entradaTrailingAtivarReaisEfetivo)-MathAbs(g_entradaTrailingPassoReaisEfetivo)));
   Print("[COPA_AR100][FIX394][TRAIL_PRIORIDADE] TIMER=1S | ATIVA=20 | DEFESA=15 | PASSO=5 | PRIORIDADE=ANTES_DE_PARCIAIS_AUMENTOS_GAIN | RETRY=ON");
   Print("[COPA_AR100][FIX394][ARQUIVO_ATIVO] V43 | MAGICS=999050/999051 | TRAILING_FINANCEIRO=PRIORIDADE_TOTAL");
   Print("[COPA_AR100][FIX395][MOVEL] ATIVA=R$10 | ZERO=SIM | PASSO=R$5 | TRAIL20_5=CONGELADO | NENHUMA_OUTRA_REGRA_ALTERADA");
   Print("[COPA_AR100][FIX395][ARQUIVO_ATIVO] V44 | MAGICS=999050/999051 | MOVEL=10/5 | TRAIL=20/5");
   Print("[COPA_AR100][FIX396][SALDO_OPERACIONAL] FORMULA=REALIZADO_SEPARADO+ABERTO | TRAIL20_5=CONGELADO | MOVEL10_5=CONGELADO");
   Print("[COPA_AR100][FIX399][AUMENTOS_PROTEGIDOS] A1-A4=SEPARADOS | MOVEL=10/5 | TRAIL=25/5 | FECHA_SOMENTE_O_TICKET | A0_CONGELADO");
   Print("[COPA_AR100][FIX405][PARAMETROS_A1_A4] MOVEL=10/5 | TRAIL=25/5 | SINAL_IGUAL_CORRIGIDO | PARSER_LENDO_25_5");
   Print("[COPA_AR100][FIX405][ARQUIVO_ATIVO] V54 | MAGICS=999050/999051 | A1-A4_TRAIL25_5_VALIDADO");
   Print("[COPA_AR100][FIX397][ARQUIVO_ATIVO] V46 | MAGICS=999050/999051 | AUMENTOS_MOVEL_TRAIL_INDEPENDENTES");
   Print("[COPA_AR100][FIX398][MEDIA] ERRO_4114_SEM_REPETICAO | UMA_TENTATIVA_POR_INSTANCIA | A1-A4_FIX397_PRESERVADOS");
   Print("[COPA_AR100][FIX398][ARQUIVO_ATIVO] V47 | MAGICS=999050/999051 | AUMENTOS_SEPARADOS=ON | MEDIA_RETRY_TIMER=OFF");
   Print("[COPA_AR100][FIX403][ARQUIVO_ATIVO] V52 | MAGICS_FORCADOS=999050/999051 | ZERO=POR_TICKET | REARME=INDIVIDUAL | A0_PRESERVADO");
   Print("[COPA_AR100][FIX403][REGRA] A1-A4: LUCRO_DO_PROPRIO_TICKET -> MOVEL10/5 -> TRAIL25/5 -> FECHA_SO_TICKET -> CONFIRMA_DEAL -> REARMA_SO_NIVEL");
   Print("[COPA_AR100][FIX399][ARQUIVO_ATIVO] V48 | RSI_PERIODO=",IntegerToString(InpRSIPeriodoAumentosFIX399)," | DISTANCIAS=50/75/100/125 | AUMENTOS=MOVEL10/5+TRAIL25/5 | BOX_LINHAS=OFF | A0_CONGELADO");
   Print("[COPA_AR100][FIX400][PARAMETROS_RSI] PERIODO_EDITAVEL=",IntegerToString(InpRSIPeriodoAumentosFIX399)," | LINHAS_A1_A4=RSI 55/45 | SEM_RSI14_FIXO");
   Print("[COPA_AR100][FIX401][DESCRICAO_FILTROS] A1-A4=MATRIZ_CONFIGURAVEL | RSI=APENAS_UM_DOS_FILTROS | EXEMPLO=6_DE_7 | REGRA_OPERACIONAL_PRESERVADA");
   Print("[COPA_AR100][FIX401][ARQUIVO_ATIVO] V50 | MAGICS=999050/999051 | SOMENTE_DESCRICAO_PARAMETROS");
   Print("[COPA_AR100][FIX407][ARQUIVO_ATIVO] V56 | EXEMPLOS_FILTROS_COMPACTOS=ON | CONFIRMA_VISUAL=REMOVIDO | LOGICA_OPERACIONAL=PRESERVADA");
   Print("[COPA_AR100][FIX408][ARQUIVO_ATIVO] V57 | MSG_PISCANDO=OFF | CAIXAS_EVENTOS=OFF | LINHAS_GRAFICO=ON | LOGS_EXPERTS=ON");
   Print("[COPA_AR100][FIX406][DESCRICAO_A1_A4] EXECUCAO_PROTECAO_SEPARADA_DOS_FILTROS | RSI_NAO_E_FILTRO_UNICO | ZERO_TRAIL_POR_TICKET");
   Print("[COPA_AR100][FIX447][GESTAO_A1_A4] ALVO_FIXO=R$10_POR_TICKET | FECHA_SO_TICKET=ON | CONFIRMA_DEAL=ON | REARME_SO_NIVEL=ON | MOVEL_TRAIL=RESERVA");
   Print("[COPA_AR100][FIX411][ARQUIVO_ATIVO] V60 | DX_ADAPTATIVO=OPERACIONAL | A0=",(InpDXUsarA0FIX411?"ON":"OFF")," | A1-A4=",(InpDXUsarAumentosFIX411?"ON":"OFF"));
   Print("[COPA_AR100][FIX412][ARQUIVO_ATIVO] V61 | MAGIC_USUARIO=ON | HISTORICO_POR_MAGIC=ISOLADO | DX_FIX411_PRESERVADO");
   Print("[COPA_AR100][FIX413][ARQUIVO_ATIVO] V62 | BORDA_SUPERIOR_HISTORICO=OFF | MSG_AMARELA_PISCANDO=OFF | LOGICA_PRESERVADA");
   Print("[COPA_AR100][FIX415][ARQUIVO_ATIVO] V64 | MSGBOX_VISUAL=OFF | AMARELO_PISCANDO=OFF | AUDITORIA=SOMENTE_EXPERTS");
   Print("[COPA_AR100][FIX417][ARQUIVO_ATIVO] V66 | LINHA_CHECK_ESC_LOSS=OFF | MAGIC_USUARIO=ON | HISTORICO_NOVO_MAGIC=ZERADO");
   Print("[COPA_AR100][FIX411][REGRA] FORCA=HILO+STR+VOLQ+VOLF+RSI+INCLINACAO | BLOQUEIO=",DoubleToString(InpDXForcaBloqueioContraFIX411,0)," | LIBERA=",DoubleToString(InpDXForcaLiberacaoFIX411,0)," | TOQUE_DX->MEDIA->PROXIMO_CANDLE");
   Print("[COPA_AR100][FIX396][ARQUIVO_ATIVO] V45 | MAGICS=999050/999051 | SOMENTE_CORRECAO_VISUAL_SALDO");
   Print("[COPA_AR100][FIX382][AUMENTOS] SEQUENCIA=TIMER->LINHA->CANDLE->RSI->PRECO->RISCO->ORDEM | RSI_M5 RECUPERACAO: COMPRA<=45 VENDA>=55 | FILTRO_MANTIDO");
   ExecutarAuditoriaTesteFIX274();
   string detalhesProducaoFIX342="";
   bool auditoriaProducaoFIX342=ExecutarAuditoriaProducaoFIX342(detalhesProducaoFIX342);
   if(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL && !auditoriaProducaoFIX342)
   {
      Print("[COPA_AR100][FIX342][AUDITORIA_REAL_FALHOU] ",detalhesProducaoFIX342);
      return INIT_PARAMETERS_INCORRECT;
   }
   if(!CanaisInicializar()) return INIT_PARAMETERS_INCORRECT;
   CanaisAtualizarVisualGrafico(true);
   InicializarIndicadores();
   RemoverOsciladoresSelecionadosFIX343();
   AtualizarMercado();
   GarantirDXIndicadorNoGrafico();
   AtualizarBandasMedia25Grafico(true);
   AtualizarRangeGridGraficoFIX344(true);
   g_modoPainelVisualAtivo = InpModoPainelVisual;
   // FIX384: o timer agora e parte do motor operacional, nao apenas do painel.
   // Aumentos A1-A4, recuperacao por RSI, virada do dia, coordenacao de Magics e
   // atualizacoes sem tick precisam continuar funcionando mesmo com o painel leve.
   // Antes, o timer podia ser encerrado apos o reencaixe inicial e o aumento ficava
   // aguardando indefinidamente ate chegar outro tick/candle.
   EventSetTimer(1);
   g_timerCriadoSomenteParaPainelInicial = false;
   Print("[COPA_AR100][FIX384][TIMER_OPERACIONAL] ATIVO=SIM | INTERVALO=1S | AUMENTOS/RSI/REENTRADA/PAINEL INDEPENDENTES DE NOVO TICK");
   Print("[COPA_AR100][FIX385][GRAFICO] HISTORICO=SEM_PERCENTUAL | MEDIA25=ON | BANDAS=OFF | SETAS_ENTRADA=ON");
   Print("[COPA_AR100][FIX386][HISTORICO_CORRIGIDO] HOJE=CIVIL_COMPLETO | QTD=SOMENTE_ENTRADAS | SAIDAS_NAO_DUPLICAM_QTD | FINANCEIRO=DEALS_DO_MAGIC");
   Print("[COPA_AR100][FIX387][PLOTAGEM_FORCADA] MAGICS=999050/999051 | MEDIA25=SEMPRE_VISIVEL | SETAS_HISTORICAS=SEMPRE_ATUALIZADAS | GRAFICO_LIMPO_PRESERVA_M25_SETAS");
   Print("[COPA_AR100][FIX388][PLOTAGEM_CORRIGIDA] OPERACAO=999050/999051 | SETAS=PERSISTENTES | VISUAL_HIST=888050/888051+999050/999051 | MEDIA25=LARGURA_2");
   Print("[COPA_AR100][FIX392] MEDIA=SIMPLES_VISIVEL | PERIODO_LIVRE | NAO_DESLIGA_NO_GRAFICO_LIMPO | MAGICS=999050/999051");
   Print("[COPA_AR100][FIX390] MEDIA=LIVRE_PERIODO_METODO_PRECO | SETA=PEQUENA_241_242_LARGURA_1 | MAGICS=999050/999051");
   if(InpPainelReencaixeAutomaticoInicial)
   {
      g_painelReencaixeInicialRestante = InpPainelReencaixeInicialCiclos;
      if(g_painelReencaixeInicialRestante < 1)
         g_painelReencaixeInicialRestante = 1;
      if(g_painelReencaixeInicialRestante > 5)
         g_painelReencaixeInicialRestante = 5;
   }
   AtualizarEstadosDePosicao();
   // FIX342: ao reiniciar com posicao aberta, recuperar o estado e garantir
   // imediatamente a protecao catastrofica registrada no servidor.
   GarantirStopsServidorFIX342(true);
   InicializarControleDiaFIX310();
   AuditoriaViradaDiaFIX310(AgoraServidorHistorico());
   AtualizarEstadoParABFIX274();
   if(!ExistePosicaoAbertaGrupoTotalAB())
      LimparLocksParciaisHedgeABPorPrefixo();
   ValidarTravasDeValidacaoInicial();
   AtualizarHistoricoObrigatorio();
   g_historicoPrimeiraCargaFeita=true;
   AuditoriaHistoricoMagicFIX311(true);
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AuditoriaInicializarFIX302();
   if(InpGraficoDesligarGrade)
      ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartSetInteger(0, CHART_FOREGROUND, false);
   g_mestre.mensagemGeral = StringFormat("AR100 SEGURO A=BUY B=SELL | A0 %s | VIRADA %s | HIST %s | CONTROLE LOCAL %s | AUM100+TRAIL+HEAD: %s | Magic local %d | TF %s | %s | AUDITORIA %s | PRODUCAO %s.",
                                          TextoModoEntradaA0FIX310(),
                                          g_statusViradaDiaFIX310,
                                          g_auditoriaHistStatusFIX311,
                                          TextoControleOperacaoFIX284(),
                                          NomeJanelaInstanciaFIX255(),
                                          (int)MagicOperacionalInstanciaFIX255(),
                                          NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                                          g_statusCoordenacaoMagics_FIX256,
                                           g_auditoriaTesteFIX274Status,
                                           g_auditoriaProducaoStatusFIX342);
   g_ordemUltimoEvento = "INIT: gerenciador de ordens carregado";
   g_ordemUltimoContexto = "INIT";
   g_ordemUltimaHora = TimeCurrent();
   RegistrarLogValidacaoSistema("INIT", StringFormat("FIX319: %s | MagicLocal=%d | TF=%s | %s | DIRECAO FIXA; LIVRE PROTEGIDA=ENTRADA IMEDIATA DEMO; A0/A1-A4 alvo50, perda100, trail20-5; garantia100/contrato; LOSS HEAD auto; escala250 sem teto.",
                                                       NomeJanelaInstanciaFIX255(),
                                                       (int)MagicOperacionalInstanciaFIX255(),
                                                       NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                                                       g_statusCoordenacaoMagics_FIX256));
   Print("[COPA_AR100][FIX362][AUDITORIA_FINAL] PARAM_SYNC=OK | GAIN_HEAD=",PnlMoedaBRL(GainHeadEfetivoFIX362()),
         " | LOSS_HEAD=",PnlMoedaBRL(LossHeadEfetivoFIX362()),
         " | STOP_FONTE=ABERTO_C+ABERTO_V | HISTORICO_SEPARADO=SIM | OSC_VISUAL=OFF | GANHO_QTD_RS=ON | AUMENTO_CANDLE_M1=ON | PRECO_MELHOR=ON");
   if(InpGerenciadorOrdensExperts)
   {
      Print("[COPA_AR100][INIT] Commit 02 FIX137 carregado | Symbol=", _Symbol,
            " | Login=", IntegerToString((int)g_loginContaAtual),
            " | Server=", g_servidorContaAtual,
            " | Janela=", NomeJanelaInstanciaFIX255(),
            " | MagicLocal=", IntegerToString((int)MagicOperacionalInstanciaFIX255()),
            " | TF_Filtro=", EnumToString(TimeframeFiltroAtualFIX255()),
            " | TF_Entrada=", EnumToString(TimeframeEntradaAtualFIX255()),
            " | Lados=", TextoLadosHabilitadosFIX346(),
            " | ModoValidacao=", TextoModoValidacaoExecucao(),
            " | CandleFiltroFechado=", (InpUsarCandleFiltroFechado ? "SIM" : "NAO"),
            " | MotorNovoCandleEntrada=", (InpExecutarSomenteNovoCandleEntrada ? "SIM" : "NAO"),
            " | Ordens=", (InpPermitirEnvioOrdens ? "ON" : "OFF"),
            " | DemoOK=", (g_contaDemo ? "SIM" : "NAO"),
            " | HedgeOK=", (g_contaHedge ? "SIM" : "NAO"),
            " | Ambiente=", (g_ambienteLiberado ? "LIBERADO" : "BLOQUEADO"),
            " | PosInicialAssumida=", (g_posicaoInicialAssumida ? "SIM" : "NAO"));
   }
   ReaplicarParametrosAntesDoGrafico("INIT_FIX280");
   if(InpFIX280RemoverLinhasDarvas)
      LimparCaixasDarvasFIX273();
   AtualizarBandasMedia25Grafico(true);
   AtualizarPainelMestre();
   AtualizarCamposFinanceirosCriticosFIX354(true);
   PainelChartRedrawLeve(true);
   g_painelProntoFIX259 = true;
   CarregarHistoricoCandlesContraFIX261();
   AtualizarCandlesContraFIX258(true);
   AtualizarEntradasHistoricasGraficoFIX385(true);
   AtualizarVisualHilo14STR4FIX418(true);
   PainelChartRedrawLeve(true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   FIX433FecharArquivos();
   ExportacaoFecharFIX306();
   EncerrarHeartbeatIdentidadeFIX304();
   g_painelProntoFIX259 = false;
   g_historicoCandlesContraCarregadoFIX261 = false;
   g_ultimaVarreduraCandlesContraFIX262 = 0;
   RegistrarLogValidacaoSistema("DEINIT", StringFormat("Encerrando EA. Reason=%d", reason));
   DesregistrarCoordenacaoMagicsFIX256();
   FecharLogValidacaoCSV();
   EventKillTimer();
   CanaisLiberar();
   LimparDXMasterFIX430();
   LiberarIndicadores();
   LimparCandlesContraFIX258(); // FIX263: limpeza explícita ao retirar o EA do gráfico
   LimparEntradasHistoricasGraficoFIX385();
   LimparVisualHilo14STR4FIX418();
   LimparComparativoDXCanaisFIX429();
   LimparTodosObjetosCOPA();
   Comment("");
}

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   FIX433RegistrarDeal(trans);
   ulong inicioFIX302=GetMicrosecondCount();
   CanaisProcessarTradeTransaction(trans);
   ProcessarOnTradeTransactionMotorFIX302(trans,request,result);
   // Nao reenvia SLTP a partir do proprio TRADE_TRANSACTION_REQUEST: uma
   // rejeicao de stop poderia alimentar um ciclo de retentativas. O timer
   // mantem a nova tentativa limitada e DEAL/POSITION confirmam mudanca real.
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD || trans.type==TRADE_TRANSACTION_POSITION)
   {
      GarantirStopsServidorFIX342(true);
      AtualizarPainelFinanceiroImediatoFIX353(trans.type==TRADE_TRANSACTION_DEAL_ADD);
      if(trans.type==TRADE_TRANSACTION_DEAL_ADD)
         AtualizarEntradasHistoricasGraficoFIX385();
   }
   ulong fimFIX302=GetMicrosecondCount();
   AuditoriaRegistrarTempoTradeFIX302(fimFIX302>=inicioFIX302 ? fimFIX302-inicioFIX302 : 0);
   AuditoriaAtualizarCicloFIX302();
}

void ProcessarOnTradeTransactionMotorFIX302(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // FIX283/FIX287: qualquer alteracao de negocio invalida imediatamente os caches.
   g_cacheRealizadoCestaValidoFIX283=false;
   g_ultimaFotoFinanceiraMsFIX362=0;
   g_ultimaAtualizacaoGanhoQtdMsFIX362=0;
   g_ultimaAtualizacaoEstadosMsFIX287=0;
   g_ultimaQtdPosicoesEstadosFIX287=-1;
   InvalidarSnapshotTotalABFIX292();
   SincronizarMagicParametros(false);
   if(trans.type==TRADE_TRANSACTION_REQUEST)
   {
      g_ultimoRetcodeExternoFIX342=result.retcode_external;
      bool aceito=(result.retcode==TRADE_RETCODE_DONE ||
                   result.retcode==TRADE_RETCODE_DONE_PARTIAL ||
                   result.retcode==TRADE_RETCODE_PLACED);
      string msg=StringFormat("RESPOSTA SERVIDOR | RC%u EXT%u | ordem %I64u deal %I64u | %s",
                              result.retcode,result.retcode_external,result.order,result.deal,result.comment);
      if(!aceito)
      {
         g_ultimoEnvioAguardandoDealFIX342=false;
         g_ultimaOrdemPendenteFIX342=0;
      }
      long magicReq=(long)request.magic;
      if(magicReq==MagicCompraAtual())
      {
         if(!aceito && request.action==TRADE_ACTION_DEAL && request.position==0)
            ProcessarRetcodeEntradaFIX342(g_compra,result.retcode,result.retcode_external,"RESPOSTA SERVIDOR BUY");
         RegistrarGerenciadorOrdens(g_compra,aceito ? "FIX342_REQUEST_OK" : "FIX342_REQUEST_REJECT",msg,result.retcode,GetLastError(),request.volume,request.price,true);
      }
      else if(magicReq==MagicVendaAtual())
      {
         if(!aceito && request.action==TRADE_ACTION_DEAL && request.position==0)
            ProcessarRetcodeEntradaFIX342(g_venda,result.retcode,result.retcode_external,"RESPOSTA SERVIDOR SELL");
         RegistrarGerenciadorOrdens(g_venda,aceito ? "FIX342_REQUEST_OK" : "FIX342_REQUEST_REJECT",msg,result.retcode,GetLastError(),request.volume,request.price,true);
      }
      else
         RegistrarLogValidacaoSistema(aceito ? "FIX342_REQUEST_OK" : "FIX342_REQUEST_REJECT",msg);
      return;
   }
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   ulong deal = trans.deal;
   if(deal == 0)
      return;
   if(!HistoryDealSelect(deal))
      return;
   long magicDealFIX342=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(magicDealFIX342==MagicOperacionalInstanciaFIX255())
   {
      g_ultimoEnvioAguardandoDealFIX342=false;
      g_ultimaOrdemPendenteFIX342=0;
   }
   if(!DealEhDepoisDoMarcoHistoricoZero(deal))
      return;
   int nivelAumentoDealFIX296=NivelAumentoDealRobustoFIX296(deal);
   AuditoriaRegistrarDealBrutoFIX305(deal,nivelAumentoDealFIX296);
   if(!DealEhDoRobo(deal) && nivelAumentoDealFIX296<=0)
      return;
   if(!DealEhDepoisDoMarcoHistoricoSessao(deal))
      return;
   long magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
   long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
   long tipoDealFIX195 = HistoryDealGetInteger(deal, DEAL_TYPE);
   string comentarioDealFIX204 = HistoryDealGetString(deal, DEAL_COMMENT);
   if(entry==DEAL_ENTRY_IN)
   {
      int nivelEntradaFIX220=(nivelAumentoDealFIX296>0 ? nivelAumentoDealFIX296 : NivelAumentoComentarioFIX207(comentarioDealFIX204));
      double precoEntradaFIX220=HistoryDealGetDouble(deal,DEAL_PRICE);
      if(nivelEntradaFIX220>0 && precoEntradaFIX220>0.0)
      {
         if(magic==MagicCompraAtual() && tipoDealFIX195==DEAL_TYPE_BUY)
            SalvarPrecoEntradaAumentoFIX220(g_compra,nivelEntradaFIX220,precoEntradaFIX220);
         else if(magic==MagicVendaAtual() && tipoDealFIX195==DEAL_TYPE_SELL)
            SalvarPrecoEntradaAumentoFIX220(g_venda,nivelEntradaFIX220,precoEntradaFIX220);
         RegistrarLogValidacaoSistema("FIX220_PRECO_AUMENTO_SALVO",StringFormat("A%d preco real %.0f salvo como base do proximo aumento.",nivelEntradaFIX220,precoEntradaFIX220));
      }
      AuditoriaRegistrarDealEntradaFIX302(deal,nivelEntradaFIX220);
   }
   if(!DealEhSaidaParcial(entry))
      return;
   double resultadoDeal = ResultadoDealHistorico(deal);
   bool comentarioParcialSimplesFIX204 = (StringFind(comentarioDealFIX204, "PARCIAL_SIMPLES") >= 0);
   bool comentarioProtecaoSimplesFIX204 = (StringFind(comentarioDealFIX204, "PROTECAO_SIMPLES") >= 0);
   ulong identificadorDealFIX207 = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   bool confirmaBuyFIX207 = comentarioParcialSimplesFIX204 ||
      (g_simplesBuy.identificadorParcialPendente > 0 && identificadorDealFIX207 == g_simplesBuy.identificadorParcialPendente);
   bool confirmaSellFIX207 = comentarioParcialSimplesFIX204 ||
      (g_simplesSell.identificadorParcialPendente > 0 && identificadorDealFIX207 == g_simplesSell.identificadorParcialPendente);
   bool resultadoDealJaSomadoFIX209=false;
   bool parcialContadaFIX214=false;
   bool aumentoContadoFIX281=false;
   bool rearmeAgendadoFIX248=false;
   if(g_simplesBuy.parcialPendente && magic == MagicCompraAtual() &&
      tipoDealFIX195 == DEAL_TYPE_SELL && confirmaBuyFIX207)
   {
      g_parciaisCicloBuy += resultadoDeal;
      double nominalBuyFIX214=g_simplesBuy.valorNominalParcialPendente;
      if(nominalBuyFIX214<=0.0)
         nominalBuyFIX214=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
      g_parciaisNominaisCicloBuy+=nominalBuyFIX214;
      g_qtdParciaisCicloBuy++;
      parcialContadaFIX214=true;
      resultadoDealJaSomadoFIX209=true;
      int nivelBuyFIX218=g_simplesBuy.nivelAumentoPendente;
      if(nivelBuyFIX218<=0) nivelBuyFIX218=nivelAumentoDealFIX296;
      if(nivelBuyFIX218>0)
      {
         g_realizadoAumentosCicloBuy+=resultadoDeal;
         g_volumeRealizadoAumentosCicloBuy+=HistoryDealGetDouble(deal,DEAL_VOLUME);
         g_qtdRealizacoesAumentosCicloBuy++;
         aumentoContadoFIX281=true;
      }
      MarcarAumentoRealizadoFIX212(g_compra,nivelBuyFIX218,HistoryDealGetDouble(deal,DEAL_PRICE));
      AgendarRearmeDinamicoAposParcialFIX248(g_compra,nivelBuyFIX218,HistoryDealGetDouble(deal,DEAL_VOLUME));
      rearmeAgendadoFIX248=true;
      g_simplesBuy.parcialPendente = false;
      g_simplesBuy.ticketParcialPendente = 0;
      g_simplesBuy.identificadorParcialPendente = 0;
      g_simplesBuy.nivelAumentoPendente = 0;
      g_simplesBuy.valorNominalParcialPendente = 0.0;
      g_simplesBuy.horaParcialPendente = 0;
      g_simplesBuy.ultimaParcialConfirmada = TimeCurrent();
      RegistrarLogValidacaoSistema("FIX281_AUMENTO_BUY_REALIZADO",
         StringFormat("A%d BUY confirmado %s | AUM QTD %d | VOL %.2f | FIN %s | REAL CICLO %s.",
                      nivelBuyFIX218,PnlMoedaBRL(resultadoDeal),g_qtdRealizacoesAumentosCicloBuy,
                      g_volumeRealizadoAumentosCicloBuy,PnlMoedaBRL(g_realizadoAumentosCicloBuy),PnlMoedaBRL(g_parciaisCicloBuy)));
   }
   else if(g_simplesSell.parcialPendente && magic == MagicVendaAtual() &&
           tipoDealFIX195 == DEAL_TYPE_BUY && confirmaSellFIX207)
   {
      g_parciaisCicloSell += resultadoDeal;
      double nominalSellFIX214=g_simplesSell.valorNominalParcialPendente;
      if(nominalSellFIX214<=0.0)
         nominalSellFIX214=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
      g_parciaisNominaisCicloSell+=nominalSellFIX214;
      g_qtdParciaisCicloSell++;
      parcialContadaFIX214=true;
      resultadoDealJaSomadoFIX209=true;
      int nivelSellFIX218=g_simplesSell.nivelAumentoPendente;
      if(nivelSellFIX218<=0) nivelSellFIX218=nivelAumentoDealFIX296;
      if(nivelSellFIX218>0)
      {
         g_realizadoAumentosCicloSell+=resultadoDeal;
         g_volumeRealizadoAumentosCicloSell+=HistoryDealGetDouble(deal,DEAL_VOLUME);
         g_qtdRealizacoesAumentosCicloSell++;
         aumentoContadoFIX281=true;
      }
      MarcarAumentoRealizadoFIX212(g_venda,nivelSellFIX218,HistoryDealGetDouble(deal,DEAL_PRICE));
      AgendarRearmeDinamicoAposParcialFIX248(g_venda,nivelSellFIX218,HistoryDealGetDouble(deal,DEAL_VOLUME));
      rearmeAgendadoFIX248=true;
      g_simplesSell.parcialPendente = false;
      g_simplesSell.ticketParcialPendente = 0;
      g_simplesSell.identificadorParcialPendente = 0;
      g_simplesSell.nivelAumentoPendente = 0;
      g_simplesSell.valorNominalParcialPendente = 0.0;
      g_simplesSell.horaParcialPendente = 0;
      g_simplesSell.ultimaParcialConfirmada = TimeCurrent();
      RegistrarLogValidacaoSistema("FIX281_AUMENTO_SELL_REALIZADO",
         StringFormat("A%d SELL confirmado %s | AUM QTD %d | VOL %.2f | FIN %s | REAL CICLO %s.",
                      nivelSellFIX218,PnlMoedaBRL(resultadoDeal),g_qtdRealizacoesAumentosCicloSell,
                      g_volumeRealizadoAumentosCicloSell,PnlMoedaBRL(g_realizadoAumentosCicloSell),PnlMoedaBRL(g_parciaisCicloSell)));
   }
   // FIX248: qualquer saida identificada como PARCIAL rearma a escada, mesmo fora da parcial por ticket.
   if(!rearmeAgendadoFIX248 && DealEhParcialHistoricaReal(deal))
   {
      int nivelGenericoFIX248=nivelAumentoDealFIX296;
      if(magic==MagicCompraAtual())
      {
         if(nivelGenericoFIX248<=0) nivelGenericoFIX248=MathMax(1,g_compra.ultimoNivelAumentoUsado);
         AgendarRearmeDinamicoAposParcialFIX248(g_compra,nivelGenericoFIX248,HistoryDealGetDouble(deal,DEAL_VOLUME));
         rearmeAgendadoFIX248=true;
      }
      else if(magic==MagicVendaAtual())
      {
         if(nivelGenericoFIX248<=0) nivelGenericoFIX248=MathMax(1,g_venda.ultimoNivelAumentoUsado);
         AgendarRearmeDinamicoAposParcialFIX248(g_venda,nivelGenericoFIX248,HistoryDealGetDouble(deal,DEAL_VOLUME));
         rearmeAgendadoFIX248=true;
      }
   }
   if(InpModoSimplesFIX195 && !resultadoDealJaSomadoFIX209)
   {
      if(magic == MagicCompraAtual())
      {
         g_parciaisCicloBuy += resultadoDeal;
         int nivelDealAumentoFIX281=nivelAumentoDealFIX296;
         if(!aumentoContadoFIX281 && nivelDealAumentoFIX281>0)
         {
            g_realizadoAumentosCicloBuy+=resultadoDeal;
            g_volumeRealizadoAumentosCicloBuy+=HistoryDealGetDouble(deal,DEAL_VOLUME);
            g_qtdRealizacoesAumentosCicloBuy++;
            aumentoContadoFIX281=true;
         }
         if(!parcialContadaFIX214 && DealEhParcialHistoricaReal(deal))
         {
            g_qtdParciaisCicloBuy++;
            g_parciaisNominaisCicloBuy+=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
            parcialContadaFIX214=true;
         }
         resultadoDealJaSomadoFIX209=true;
         RegistrarLogValidacaoSistema("FIX209_REALIZADO_BUY",
            StringFormat("Saida BUY %s somada ao realizado do ciclo: %s.",
                         PnlMoedaBRL(resultadoDeal),PnlMoedaBRL(g_parciaisCicloBuy)));
      }
      else if(magic == MagicVendaAtual())
      {
         g_parciaisCicloSell += resultadoDeal;
         int nivelDealAumentoFIX281=nivelAumentoDealFIX296;
         if(!aumentoContadoFIX281 && nivelDealAumentoFIX281>0)
         {
            g_realizadoAumentosCicloSell+=resultadoDeal;
            g_volumeRealizadoAumentosCicloSell+=HistoryDealGetDouble(deal,DEAL_VOLUME);
            g_qtdRealizacoesAumentosCicloSell++;
            aumentoContadoFIX281=true;
         }
         if(!parcialContadaFIX214 && DealEhParcialHistoricaReal(deal))
         {
            g_qtdParciaisCicloSell++;
            g_parciaisNominaisCicloSell+=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
            parcialContadaFIX214=true;
         }
         resultadoDealJaSomadoFIX209=true;
         RegistrarLogValidacaoSistema("FIX209_REALIZADO_SELL",
            StringFormat("Saida SELL %s somada ao realizado do ciclo: %s.",
                         PnlMoedaBRL(resultadoDeal),PnlMoedaBRL(g_parciaisCicloSell)));
      }
   }
   // FIX414: somente após o DEAL confirmado e depois de atualizar os acumuladores.
   // Assim a caixa sempre mostra o valor real do evento e o total da operação.
   double totalOperacaoFIX414=0.0;
   string ladoFIX414="";
   if(magic==MagicCompraAtual())
   {
      totalOperacaoFIX414=g_parciaisCicloBuy;
      ladoFIX414="COMPRA";
   }
   else if(magic==MagicVendaAtual())
   {
      totalOperacaoFIX414=g_parciaisCicloSell;
      ladoFIX414="VENDA";
   }
   string comentarioUpperFIX414=Upper(comentarioDealFIX204);
   string tituloFIX414="SAIDA REALIZADA";
   if(StringFind(comentarioUpperFIX414,"TRAIL")>=0 || StringFind(comentarioUpperFIX414,"PROTECAO")>=0)
      tituloFIX414="TRAILING REALIZADO";
   else if(StringFind(comentarioUpperFIX414,"PARCIAL")>=0 || nivelAumentoDealFIX296>0)
      tituloFIX414="PARCIAL REALIZADA";
   DispararMsgBoxVisualFIX226(
      tituloFIX414+" | "+ladoFIX414,
      "RESULTADO DESTA SAIDA: "+PnlMoedaBRL(resultadoDeal),
      "TOTAL REALIZADO DA OPERACAO: "+PnlMoedaBRL(totalOperacaoFIX414));
   RegistrarLogValidacaoSistema("FIX414_MSGBOX_TOTAL",
      StringFormat("%s | evento %s | total operacao %s",tituloFIX414,PnlMoedaBRL(resultadoDeal),PnlMoedaBRL(totalOperacaoFIX414)));

   LogDealSaidaCestaAB(deal);
   LogHedgeCompleto("TRADE_TRANSACTION_DEAL", "DEAL_CONFIRMADO_SERVIDOR", "saída/parcial confirmada pelo servidor", trans.position, deal, magic, result.retcode, GetLastError(), HistoryDealGetDouble(deal, DEAL_VOLUME), HistoryDealGetDouble(deal, DEAL_PRICE), true);
   LogCestaABDetalhado("DEAL_SAIDA_AB", true);
   if(magic == MagicCompraAtual())
   {
      RegistrarGerenciadorOrdens(g_compra, "DEAL_SAIDA",
                                 "Saida confirmada pelo servidor. Resultado " + FormatarMoeda(resultadoDeal),
                                 0, 0, 0.0, 0.0, true);
      RegistrarSTFTFechamento(g_compra, resultadoDeal);
   }
   else if(magic == MagicVendaAtual())
   {
      RegistrarGerenciadorOrdens(g_venda, "DEAL_SAIDA",
                                 "Saida confirmada pelo servidor. Resultado " + FormatarMoeda(resultadoDeal),
                                 0, 0, 0.0, 0.0, true);
      RegistrarSTFTFechamento(g_venda, resultadoDeal);
   }
   g_historicoTeveSaidaSessao = true;
   AuditoriaRegistrarDealSaidaFIX302(deal,nivelAumentoDealFIX296,resultadoDeal);
   SincronizarRealizacoesAumentosFIX296(true);
   // FIX227: mostra o realizado imediatamente e reconfirma nos 3 segundos seguintes.
   ArmarAtualizacaoHistoricoRapidaFIX227(StringFormat("Deal %I64u confirmado | realizado %s",deal,PnlMoedaBRL(resultadoDeal)));
   ProcessarAtualizacaoHistoricoRapidaFIX227();
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      g_ultimaAtualizacaoPainelVisual = 0;
      ReaplicarParametrosAntesDoGrafico("CHARTEVENT_CHART_CHANGE");
      DetectarFechamentoVisualUsuarioFIX345();
      GarantirDXIndicadorNoGrafico();
      AtualizarBandasMedia25Grafico(true);
      AtualizarEstadosDePosicao();
      AtualizarRiscoMestre();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(true);
      return;
   }
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   if(PainelCliqueControleOperacaoFIX284(sparam))
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      g_ultimaAtualizacaoPainelVisual = 0;
      AtualizarEstadosDePosicao();
      AtualizarRiscoMestre();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(true);
      return;
   }
   if(PainelCliqueModoVisual(sparam))
   {
      g_ultimaAtualizacaoPainelVisual = 0;
      AtualizarEstadosDePosicao();
      AtualizarRiscoMestre();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(true);
      if(InpGerenciadorOrdensExperts)
         Print("[COPA_AR100][PAINEL] Modo visual alterado por clique: ", NomeModoPainelVisual(g_modoPainelVisualAtivo), " | Objeto=", sparam);
      return;
   }
   if(PainelCliqueAuditoriaFIX302(sparam))
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      AuditoriaAtualizarTelaFIX302(true);
      PainelChartRedrawLeve(true);
      return;
   }
   if(PainelCliqueHistorico(sparam))
   {
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ForcarAtualizacaoHistoricoPainel("clique " + NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo));
      if(InpHistoricoCliqueVisualUltraLeve)
         AtualizarVisualHistoricoRapido();
      else
      {
         AtualizarPainelMestre();
         PainelChartRedrawLeve(true);
      }
      if(InpGerenciadorOrdensExperts)
      {
         Print("[COPA_AR100][PAINEL] Historico selecionado por clique leve | Periodo=",
               NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo));
      }
   }
}

void OnTimer()
{
   CanaisSincronizarTimer();
   // FIX390: reserva visual independente de tick e do modo ultra-leve.
   // A cada 2 segundos reconfirma MEDIA 25 e setas historicas/provisorias.
   static datetime ultimaPlotagemFIX390=0;
   datetime agoraPlotagemFIX390=TimeCurrent();
   if(ultimaPlotagemFIX390==0 || agoraPlotagemFIX390-ultimaPlotagemFIX390>=2)
   {
      ultimaPlotagemFIX390=agoraPlotagemFIX390;
      AtualizarBandasMedia25Grafico(true);
      AtualizarEntradasHistoricasGraficoFIX385(false);
      AtualizarVisualHilo14STR4FIX418(false);
   }
   ulong inicioFIX302=GetMicrosecondCount();
   ProcessarOnTimerMotorFIX302();
   ulong fimFIX302=GetMicrosecondCount();
   AuditoriaRegistrarTempoTimerFIX302(fimFIX302>=inicioFIX302 ? fimFIX302-inicioFIX302 : 0);
   AuditoriaAtualizarCicloFIX302();
   AuditoriaValidarGraficoFIX302(false);
   AuditoriaFlushFIX302(false);
   ExportacaoProcessarTimerFIX306();
   AuditoriaAtualizarTelaFIX302(false);
}

void ProcessarOnTimerMotorFIX302()
{
   AtualizarHeartbeatIdentidadeFIX304();
   ReaplicarParametrosAntesDoGrafico("TIMER_FIX283");
   AtualizarCoordenacaoMagicsFIX256(false);

   // FIX341: a virada civil nao pode depender de chegar um novo tick.
   // No primeiro pulso do timer depois de 00:00 do servidor, consolida HOJE em
   // ONTEM, cria o novo HOJE zerado e recalcula imediatamente os dois periodos.
   datetime agoraViradaFIX341=AgoraServidorHistorico();
   datetime diaFinanceiroAntesFIX341=g_diaFinanceiroRefFIX310;
   datetime diaHistoricoAntesFIX341=g_diaHistoricoAtivo;
   AuditoriaViradaDiaFIX310(agoraViradaFIX341);
   VerificarViradaDiaHistorico(agoraViradaFIX341);
   bool virouDiaFIX341=(diaFinanceiroAntesFIX341!=g_diaFinanceiroRefFIX310 ||
                        diaHistoricoAntesFIX341!=g_diaHistoricoAtivo);
   if(virouDiaFIX341)
   {
      g_ultimaAtualizacaoHistorico=0;
      g_ultimaAtualizacaoHistoricoLongo=0;
      AtualizarHistoricoObrigatorio();
      SincronizarResultadoFechadoDiaComHistorico();
      AtualizarRiscoMestre();
      g_ultimaAtualizacaoPainelVisual=0;
      RegistrarLogValidacaoSistema("FIX341_VIRADA_MEIA_NOITE",
         StringFormat("00:00 servidor confirmado | HOJE zerado | ONTEM C %s V %s | ref %s",
                      PnlMoedaBRL(g_saldoOntemCompraFIX310),
                      PnlMoedaBRL(g_saldoOntemVendaFIX310),
                      TimeToString(g_diaFinanceiroRefFIX310,TIME_DATE|TIME_SECONDS)));
   }
   // FIX287: contar todos os objetos do grafico em cada segundo causava congeladas.
   // Enquanto ainda nao carregou, tenta a cada 3s; depois apenas confere no intervalo configurado.
   ulong agoraCargaContraMsFIX287=GetTickCount64();
   int intervaloCargaContraFIX287=g_historicoCandlesContraCarregadoFIX261 ? InpFIX287ReverHistoricoContraSegundos*1000 : 3000;
   if(intervaloCargaContraFIX287<3000) intervaloCargaContraFIX287=3000;
   if(!InpFIX287UltraLeve || g_ultimaCargaHistoricoContraMsFIX287==0 ||
      agoraCargaContraMsFIX287<g_ultimaCargaHistoricoContraMsFIX287 ||
      (agoraCargaContraMsFIX287-g_ultimaCargaHistoricoContraMsFIX287)>=(ulong)intervaloCargaContraFIX287)
   {
      g_ultimaCargaHistoricoContraMsFIX287=agoraCargaContraMsFIX287;
      CarregarHistoricoCandlesContraFIX261();
   }
   if(InpFechamentoFimDiaAtivo && InstanciaMestreGrupoFIX255())
   {
      SincronizarMagicParametros(false);
      AtualizarEstadosDePosicao();
      ProcessarFechamentoFimDiaFIX215();
      if(MsgBoxVisualAtivaFIX226())
      {
         AtualizarPainelMestre();
         PainelChartRedrawLeve(true);
      }
   }
   // FIX227: mesmo com painel sem atualização por timer, reconfirma saídas por 3s.
   ProcessarAtualizacaoHistoricoRapidaFIX227();

   SincronizarControleOperacaoFIX284(false);
   AtualizarEstadosDePosicao();
   GarantirStopsServidorFIX342(false);
   bool encerramentoManualAtivoFIX284 = ProcessarEncerramentoManualFIX284(false);

   // FIX283: o timer funciona como reserva quando o mercado esta sem ticks.
   // Com ticks normais, somente OnTick executa o motor de ordens, evitando trabalho e envios duplicados.
   int esperaSemTickFIX283=InpFIX283TimerGerenciarSomenteSemTickMs;
   if(esperaSemTickFIX283<500) esperaSemTickFIX283=500;
   ulong agoraMsFIX283=GetTickCount64();
   bool semTickRecenteFIX283=(g_ultimoTickRecebidoMsFIX283==0 ||
                              agoraMsFIX283<g_ultimoTickRecebidoMsFIX283 ||
                              (agoraMsFIX283-g_ultimoTickRecebidoMsFIX283)>=(ulong)esperaSemTickFIX283);
   if(semTickRecenteFIX283 && !encerramentoManualAtivoFIX284 &&
      InpAtivarRobo && g_ambienteLiberado && !BloquearNovasOperacoesFimDiaFIX215())
   {
      // FIX288: reserva sem tick gerencia somente o lado local desta janela.
      AtualizarMercado();
      AtualizarDXAdaptativoFIX411(false);
      AtualizarEstadosDePosicao();
      if(EntradaDiretaDemoEfetivaFIX302())
         ProcessarEntradaDiretaFIX279();
      AtualizarEstadosDePosicao();
      if(JanelaAtualEhA_FIX255())
      {
         if(g_compra.posicaoAberta)
            GerenciarEstadoLado(g_compra);
      }
      else
      {
         if(g_venda.posicaoAberta)
            GerenciarEstadoLado(g_venda);
      }
   }

   // FIX287: com ticks recentes, o OnTick ja atualiza gestao e painel.
   // Retornar aqui impede o Timer de repetir HistorySelect, CopyBuffer, varredura de posicoes
   // e centenas de ObjectSet no mesmo segundo.
   if(InpFIX287UltraLeve && !semTickRecenteFIX283)
   {
      AtualizarCamposFinanceirosCriticosFIX354(true);
      ReencaixarPainelInicialSeNecessario();
      return;
   }

   if(!InpPainelAtualizarSemTick)
   {
      ReencaixarPainelInicialSeNecessario();
      AtualizarDiagnosticoCandlesContraFIX263();
      return;
   }
   ReencaixarPainelInicialSeNecessario();
   SincronizarMagicParametros(false);
   AtualizarMercado();
   AtualizarCandlesContraFIX258(false);
   AtualizarBandasMedia25Grafico(false);
   AtualizarEstadosDePosicao();
   if(JanelaAtualEhA_FIX255())
   {
      RecuperarRearmeSemEventoFIX452(g_compra);
      ProcessarRearmeDinamicoPendenteFIX248(g_compra);
   }
   else
   {
      RecuperarRearmeSemEventoFIX452(g_venda);
      ProcessarRearmeDinamicoPendenteFIX248(g_venda);
   }
   ResetarCicloCestaABQuandoFlat();
   AtualizarHistoricoObrigatorio();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   LogCestaABDetalhado("TIMER_FINANCEIRO_AB", false);
   LogStopFullHedgeAB("TIMER_STOP_FULL_HEDGE_AB", false);
   AtualizarEstadosDePosicao();
   AtualizarRodapePainelRapido();
   AtualizarPainelMestre();
   AtualizarCamposFinanceirosCriticosFIX354(true);
   PainelChartRedrawLeve(false);
}

bool CestaABTemAlgumaPosicaoFIX195()
{
   double qC=0.0,qV=0.0,qT=0.0,aC=0.0,aV=0.0,aT=0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qC,qV,qT,aC,aV,aT);
   return (qT>0.0001);
}

void ResetarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &e)
{
   e.melhorLucro=0.0;
   e.defesaAtual=0.0;
   e.proximaRealizacao=MathAbs(InpRealizacaoPrimeiraReais);
   if(e.proximaRealizacao<=0.0) e.proximaRealizacao=10.0;
   e.protecaoArmada=false;
   e.movelArmadoFIX395=false;
   e.defesaMovelFIX395=0.0;
   e.parcialPendente=false;
   e.ticketParcialPendente=0;
   e.identificadorParcialPendente=0;
   e.nivelAumentoPendente=0;
   e.valorNominalParcialPendente=0.0;
   e.horaParcialPendente=0;
   e.ultimaParcialConfirmada=0;
   e.regimeCorredor=CORREDOR_FIX338_AGUARDA;
   e.confirmacoesViradaCorredor=0;
   e.ultimoCandleCorredor=0;
   e.alvoMarcoCorredorRegistrado=false;
}

void PrepararNovoCicloPontaFIX275(EstadoLado &estado)
{
   if(!InpHeadCiclosIndependentesFIX275 || estado.posicaoAberta)
      return;

   if(estado.lado == LADO_COMPRA)
   {
      g_parciaisCicloBuy = 0.0;
      g_parciaisNominaisCicloBuy = 0.0;
      g_qtdParciaisCicloBuy = 0;
      g_realizadoAumentosCicloBuy = 0.0;
      g_volumeRealizadoAumentosCicloBuy = 0.0;
      g_qtdRealizacoesAumentosCicloBuy = 0;
      for(int iFIX281=0;iFIX281<5;iFIX281++) ResetarTrailAumentoFIX281(g_trailAumentoBuy[iFIX281]);
      g_cicloInicioCompra = 0;
      ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
   }
   else if(estado.lado == LADO_VENDA)
   {
      g_parciaisCicloSell = 0.0;
      g_parciaisNominaisCicloSell = 0.0;
      g_qtdParciaisCicloSell = 0;
      g_realizadoAumentosCicloSell = 0.0;
      g_volumeRealizadoAumentosCicloSell = 0.0;
      g_qtdRealizacoesAumentosCicloSell = 0;
      for(int iFIX281=0;iFIX281<5;iFIX281++) ResetarTrailAumentoFIX281(g_trailAumentoSell[iFIX281]);
      g_cicloInicioVenda = 0;
      ResetarEstadoPontaSimplesFIX195(g_simplesSell);
   }
   else
      return;

   g_totalCicloMestreSimples = g_parciaisCicloBuy + g_parciaisCicloSell;
   estado.resultadoFechado = 0.0;
   estado.resultadoDia = estado.resultadoAberto;
   estado.parcial50Executada = false;
   estado.parcialFinalExecutada = false;
   estado.melhorResultadoAberto = 0.0;
   estado.valorDefendido = 0.0;
   estado.lucroProtegido = false;
   estado.modoLongo = false;

   RegistrarLogValidacaoSistema("FIX275_NOVO_CICLO_PONTA",
      StringFormat("%s iniciou novo ciclo independente: realizado local zerado; alvo R$100; ponta oposta permanece intacta.",
                   estado.lado == LADO_COMPRA ? "BUY" : "SELL"));
}

void ReconstruirParciaisCicloLadoFIX214(long magic, long tipoPosicao, datetime inicio, double &valorLiquido, double &valorNominal, int &quantidade)
{
   valorLiquido=0.0;
   valorNominal=0.0;
   quantidade=0;
   if(magic<=0 || inicio<=0)
      return;
   datetime fim=TimeCurrent();
   if(fim<=inicio || !HistorySelect(inicio,fim))
      return;
   ulong ordensContadas[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0)
         continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      datetime horario=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(horario<inicio || horario>fim)
         continue;
      valorLiquido+=ResultadoDealHistorico(deal);
      valorNominal+=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0)
         ordem=deal;
      bool jaContada=false;
      int n=ArraySize(ordensContadas);
      for(int j=0;j<n;j++)
      {
         if(ordensContadas[j]==ordem)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         ArrayResize(ordensContadas,n+1);
         ordensContadas[n]=ordem;
         quantidade++;
      }
   }
   valorLiquido=NormalizeDouble(valorLiquido,2);
   valorNominal=NormalizeDouble(valorNominal,2);
}

void ReconstruirRealizacoesAumentosCicloFIX281(long magic, long tipoPosicao, datetime inicio, double &financeiro, double &volume, int &quantidade)
{
   financeiro=0.0;
   volume=0.0;
   quantidade=0;
   if(magic<=0 || inicio<=0)
      return;
   datetime fim=TimeCurrent();
   if(fim<=inicio || !HistorySelect(inicio,fim))
      return;
   ulong ordensContadas[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      datetime horario=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(horario<inicio || horario>fim)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<=0)
         continue; // Saida de A0 ou deal externo: nao entra no contador de aumentos realizados.
      financeiro+=ResultadoDealHistorico(deal);
      volume+=HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0) ordem=deal;
      bool jaContada=false;
      for(int j=0;j<ArraySize(ordensContadas);j++)
      {
         if(ordensContadas[j]==ordem)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         int n=ArraySize(ordensContadas);
         ArrayResize(ordensContadas,n+1);
         ordensContadas[n]=ordem;
         quantidade++;
      }
   }
   financeiro=NormalizeDouble(financeiro,2);
   volume=NormalizeDouble(volume,2);
}

void ReconstruirRealizacoesAumentosPorNivelFIX324(long magic,
                                                   long tipoPosicao,
                                                   datetime inicio,
                                                   double &financeiroNivel[],
                                                   double &volumeNivel[],
                                                   int &quantidadeNivel[])
{
   for(int nivelZero=0;nivelZero<5;nivelZero++)
   {
      financeiroNivel[nivelZero]=0.0;
      volumeNivel[nivelZero]=0.0;
      quantidadeNivel[nivelZero]=0;
   }
   if(magic<=0 || inicio<=0 || !HistorySelect(inicio,TimeCurrent()+60))
      return;

   ulong ordensContadas[];
   int niveisContados[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<1 || nivel>5)
         continue;

      int idx=nivel-1;
      financeiroNivel[idx]+=ResultadoDealHistorico(deal);
      volumeNivel[idx]+=HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0) ordem=deal;
      bool jaContada=false;
      for(int j=0;j<ArraySize(ordensContadas);j++)
      {
         if(ordensContadas[j]==ordem && niveisContados[j]==nivel)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         int n=ArraySize(ordensContadas);
         ArrayResize(ordensContadas,n+1);
         ArrayResize(niveisContados,n+1);
         ordensContadas[n]=ordem;
         niveisContados[n]=nivel;
         quantidadeNivel[idx]++;
      }
   }
   for(int idx=0;idx<5;idx++)
   {
      financeiroNivel[idx]=NormalizeDouble(financeiroNivel[idx],2);
      volumeNivel[idx]=NormalizeDouble(volumeNivel[idx],2);
   }
}

void ReconstruirMarcacaoAumentosRealizadosFIX296(EstadoLado &estado, datetime inicio)
{
   if(inicio<=0 || !HistorySelect(inicio,TimeCurrent()+60))
      return;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=estado.magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(estado.lado==LADO_COMPRA && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(estado.lado==LADO_VENDA && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<=0)
         continue;
      MarcarAumentoRealizadoFIX212(estado,nivel,HistoryDealGetDouble(deal,DEAL_PRICE));
   }
}

void SincronizarRealizacoesAumentosFIX296(bool forcar)
{
   datetime agora=TimeCurrent();
   if(!forcar && g_ultimaSincronizacaoRealizacoesAumentosFIX296>0 &&
      (agora-g_ultimaSincronizacaoRealizacoesAumentosFIX296)<1)
      return;
   g_ultimaSincronizacaoRealizacoesAumentosFIX296=agora;

   for(int idx=0;idx<5;idx++)
   {
      g_realizadoAumentosNivelBuyFIX324[idx]=0.0;
      g_realizadoAumentosNivelSellFIX324[idx]=0.0;
      g_volumeRealizadoNivelBuyFIX324[idx]=0.0;
      g_volumeRealizadoNivelSellFIX324[idx]=0.0;
      g_qtdRealizacoesNivelBuyFIX324[idx]=0;
      g_qtdRealizacoesNivelSellFIX324[idx]=0;
   }

   if(g_cicloInicioCompra>0)
   {
      double fin=0.0,vol=0.0; int qtd=0;
      ReconstruirRealizacoesAumentosCicloFIX281(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,fin,vol,qtd);
      g_realizadoAumentosCicloBuy=fin;
      g_volumeRealizadoAumentosCicloBuy=vol;
      g_qtdRealizacoesAumentosCicloBuy=qtd;
      ReconstruirRealizacoesAumentosPorNivelFIX324(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                                    g_realizadoAumentosNivelBuyFIX324,g_volumeRealizadoNivelBuyFIX324,g_qtdRealizacoesNivelBuyFIX324);
      ReconstruirMarcacaoAumentosRealizadosFIX296(g_compra,g_cicloInicioCompra);
   }
   if(g_cicloInicioVenda>0)
   {
      double fin=0.0,vol=0.0; int qtd=0;
      ReconstruirRealizacoesAumentosCicloFIX281(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,fin,vol,qtd);
      g_realizadoAumentosCicloSell=fin;
      g_volumeRealizadoAumentosCicloSell=vol;
      g_qtdRealizacoesAumentosCicloSell=qtd;
      ReconstruirRealizacoesAumentosPorNivelFIX324(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                                    g_realizadoAumentosNivelSellFIX324,g_volumeRealizadoNivelSellFIX324,g_qtdRealizacoesNivelSellFIX324);
      ReconstruirMarcacaoAumentosRealizadosFIX296(g_venda,g_cicloInicioVenda);
   }
}

void RestaurarParciaisCicloAbertoFIX214()
{
   if(g_compra.posicaoAberta)
   {
      ReconstruirParciaisCicloLadoFIX214(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                         g_parciaisCicloBuy,g_parciaisNominaisCicloBuy,g_qtdParciaisCicloBuy);
      ReconstruirRealizacoesAumentosCicloFIX281(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                                g_realizadoAumentosCicloBuy,g_volumeRealizadoAumentosCicloBuy,g_qtdRealizacoesAumentosCicloBuy);
   }
   if(g_venda.posicaoAberta)
   {
      ReconstruirParciaisCicloLadoFIX214(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                         g_parciaisCicloSell,g_parciaisNominaisCicloSell,g_qtdParciaisCicloSell);
      ReconstruirRealizacoesAumentosCicloFIX281(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                                g_realizadoAumentosCicloSell,g_volumeRealizadoAumentosCicloSell,g_qtdRealizacoesAumentosCicloSell);
   }
   g_totalCicloMestreSimples=g_parciaisCicloBuy+g_parciaisCicloSell;
   RegistrarLogValidacaoSistema("FIX214_PARCIAIS_RESTAURADAS",
      StringFormat("BUY liq %s / nom %s / %d | SELL liq %s / nom %s / %d | TOTAL LIQ %s",
                   PnlMoedaBRL(g_parciaisCicloBuy),PnlMoedaBRL(g_parciaisNominaisCicloBuy),g_qtdParciaisCicloBuy,
                   PnlMoedaBRL(g_parciaisCicloSell),PnlMoedaBRL(g_parciaisNominaisCicloSell),g_qtdParciaisCicloSell,
                   PnlMoedaBRL(g_totalCicloMestreSimples)));
   RegistrarLogValidacaoSistema("FIX281_AUMENTOS_RESTAURADOS",
      StringFormat("BUY QTD %d VOL %.2f FIN %s | SELL QTD %d VOL %.2f FIN %s",
                   g_qtdRealizacoesAumentosCicloBuy,g_volumeRealizadoAumentosCicloBuy,PnlMoedaBRL(g_realizadoAumentosCicloBuy),
                   g_qtdRealizacoesAumentosCicloSell,g_volumeRealizadoAumentosCicloSell,PnlMoedaBRL(g_realizadoAumentosCicloSell)));
}

void AtualizarCicloMestreSimplesFIX195()
{
   if(!g_cicloMestreSimplesAtivo && CestaABTemAlgumaPosicaoFIX195())
   {
      g_cicloMestreSimplesAtivo=true;

      // FIX457: ao reiniciar o computador/MT5 com posição ainda aberta,
      // não iniciar o ciclo em TimeCurrent(). Isso apagava da reconstrução
      // todas as parciais realizadas antes do reinício. Recupera o horário
      // real mais antigo das posições abertas dos Magics 326050/326051.
      datetime inicioRealFIX457=0;
      for(int posFIX457=0; posFIX457<PositionsTotal(); posFIX457++)
      {
         ulong ticketFIX457=PositionGetTicket(posFIX457);
         if(ticketFIX457==0 || !PositionSelectByTicket(ticketFIX457))
            continue;
         if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
            continue;
         long magicFIX457=(long)PositionGetInteger(POSITION_MAGIC);
         if(magicFIX457!=MagicCompraAtual() && magicFIX457!=MagicVendaAtual())
            continue;
         datetime horaFIX457=(datetime)PositionGetInteger(POSITION_TIME);
         if(horaFIX457>0 && (inicioRealFIX457==0 || horaFIX457<inicioRealFIX457))
            inicioRealFIX457=horaFIX457;
         if(magicFIX457==MagicCompraAtual() && (g_cicloInicioCompra<=0 || horaFIX457<g_cicloInicioCompra))
            g_cicloInicioCompra=horaFIX457;
         if(magicFIX457==MagicVendaAtual() && (g_cicloInicioVenda<=0 || horaFIX457<g_cicloInicioVenda))
            g_cicloInicioVenda=horaFIX457;
      }
      if(inicioRealFIX457<=0)
         inicioRealFIX457=TimeCurrent();
      g_cicloMestreSimplesInicio=inicioRealFIX457;

      g_parciaisCicloBuy=0.0;
      g_parciaisCicloSell=0.0;
      g_qtdParciaisCicloBuy=0;
      g_qtdParciaisCicloSell=0;
      g_parciaisNominaisCicloBuy=0.0;
      g_parciaisNominaisCicloSell=0.0;
      g_realizadoAumentosCicloBuy=0.0;
      g_realizadoAumentosCicloSell=0.0;
      g_volumeRealizadoAumentosCicloBuy=0.0;
      g_volumeRealizadoAumentosCicloSell=0.0;
      g_qtdRealizacoesAumentosCicloBuy=0;
      g_qtdRealizacoesAumentosCicloSell=0;
      for(int iFIX281=0;iFIX281<5;iFIX281++)
      {
         ResetarTrailAumentoFIX281(g_trailAumentoBuy[iFIX281]);
         ResetarTrailAumentoFIX281(g_trailAumentoSell[iFIX281]);
      }
      g_totalCicloMestreSimples=0.0;
      RestaurarParciaisCicloAbertoFIX214(); // recupera parciais do ciclo se o EA foi recompilado/recolocado com posicao aberta.
      g_fechamentoMestreSimplesPendente=false;
      ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
      ResetarEstadoPontaSimplesFIX195(g_simplesSell);
      RegistrarLogValidacaoSistema("FIX195_CICLO_INICIO","Novo ciclo simples iniciado.");
   }
}

void ResetarCicloMestreSimplesFIX195SeFlat()
{
   if(!g_cicloMestreSimplesAtivo) return;
   if(CestaABTemAlgumaPosicaoFIX195()) return;
   if(g_simplesBuy.parcialPendente || g_simplesSell.parcialPendente) return;
   RegistrarLogValidacaoSistema("FIX214_CICLO_FIM",StringFormat("Real BUY %s (%d parc) | Real SELL %s (%d parc) | Total %s. Valores preservados nos cards ate a proxima A0.",PnlMoedaBRL(g_parciaisCicloBuy),g_qtdParciaisCicloBuy,PnlMoedaBRL(g_parciaisCicloSell),g_qtdParciaisCicloSell,PnlMoedaBRL(g_totalCicloMestreSimples)));
   g_cicloMestreSimplesAtivo=false;
   g_cicloMestreSimplesInicio=0;
   g_totalCicloMestreSimples=g_parciaisCicloBuy+g_parciaisCicloSell;
   g_fechamentoMestreSimplesPendente=false;
   ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
   ResetarEstadoPontaSimplesFIX195(g_simplesSell);
}

int NivelAumentoComentarioFIX207(string comentario)
{
   string c=" "+Upper(comentario)+" ";
   StringReplace(c,"_"," ");
   StringReplace(c,"-"," ");
   StringReplace(c,"|"," ");
   StringReplace(c,";"," ");
   for(int nivel=1; nivel<=5; nivel++)
   {
      string marca=" A"+IntegerToString(nivel)+" ";
      if(StringFind(c,marca)>=0)
         return nivel;
   }
   return 0;
}

int NivelAumentoDealRobustoFIX296(ulong deal)
{
   if(deal==0)
      return 0;
   string simbolo=HistoryDealGetString(deal,DEAL_SYMBOL);
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(simbolo!=_Symbol || (magic!=MagicCompraAtual() && magic!=MagicVendaAtual() &&
                           magic!=MagicPainelAAtual() && magic!=MagicPainelBAtual()))
      return 0;

   int nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(deal,DEAL_COMMENT));
   if(nivel>0)
      return nivel;

   ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
   if(ordem>0)
   {
      string comentarioOrdem=HistoryOrderGetString(ordem,ORDER_COMMENT);
      nivel=NivelAumentoComentarioFIX207(comentarioOrdem);
      if(nivel>0)
         return nivel;
   }

   ulong identificador=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
   if(identificador==0)
      return 0;

   // Primeiro usa a selecao historica atual. Isso evita destruir a lista enquanto
   // ReconstruirRealizacoesAumentosCicloFIX281 percorre os deals do ciclo.
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong d=HistoryDealGetTicket(i);
      if(d==0 || d==deal)
         continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=simbolo)
         continue;
      if((long)HistoryDealGetInteger(d,DEAL_MAGIC)!=magic)
         continue;
      if((ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID)!=identificador)
         continue;
      long entrada=HistoryDealGetInteger(d,DEAL_ENTRY);
      if(entrada!=DEAL_ENTRY_IN && entrada!=DEAL_ENTRY_INOUT)
         continue;
      nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(d,DEAL_COMMENT));
      if(nivel<=0)
      {
         ulong ordemEntrada=(ulong)HistoryDealGetInteger(d,DEAL_ORDER);
         if(ordemEntrada>0)
            nivel=NivelAumentoComentarioFIX207(HistoryOrderGetString(ordemEntrada,ORDER_COMMENT));
      }
      if(nivel>0)
         return nivel;
   }

   // OnTradeTransaction pode ter somente o deal atual selecionado. Nesse caso,
   // abre uma janela curta e procura o deal de entrada pelo POSITION_IDENTIFIER.
   datetime horaDeal=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
   datetime inicio=horaDeal-(datetime)(7*86400);
   if(inicio<0) inicio=0;
   datetime fim=TimeCurrent()+60;
   if(fim<horaDeal) fim=horaDeal+60;
   if(!HistorySelect(inicio,fim))
      return 0;
   total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong d=HistoryDealGetTicket(i);
      if(d==0)
         continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=simbolo)
         continue;
      if((long)HistoryDealGetInteger(d,DEAL_MAGIC)!=magic)
         continue;
      if((ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID)!=identificador)
         continue;
      long entrada=HistoryDealGetInteger(d,DEAL_ENTRY);
      if(entrada!=DEAL_ENTRY_IN && entrada!=DEAL_ENTRY_INOUT)
         continue;
      nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(d,DEAL_COMMENT));
      if(nivel<=0)
      {
         ulong ordemEntrada=(ulong)HistoryDealGetInteger(d,DEAL_ORDER);
         if(ordemEntrada>0)
            nivel=NivelAumentoComentarioFIX207(HistoryOrderGetString(ordemEntrada,ORDER_COMMENT));
      }
      if(nivel>0)
         return nivel;
   }
   return 0;
}

int NivelAumentoPosicaoFIX212(EstadoLado &estado, ulong ticket, string comentario)
{
   int nivel=NivelAumentoComentarioFIX207(comentario);
   if(nivel>0)
      return nivel;
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return 0;
   long tipoAtual=PositionGetInteger(POSITION_TYPE);
   datetime horaAtual=(datetime)PositionGetInteger(POSITION_TIME);
   double precoAtual=PositionGetDouble(POSITION_PRICE_OPEN);
   int anteriores=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong outro=PositionGetTicket(i);
      if(outro==0 || outro==ticket || !PositionSelectByTicket(outro))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=tipoAtual)
         continue;
      datetime horaOutro=(datetime)PositionGetInteger(POSITION_TIME);
      if(horaOutro<horaAtual || (horaOutro==horaAtual && outro<ticket))
         anteriores++;
   }
   if(anteriores<=0)
      return 0;
   int melhorNivel=0;
   double melhorDiferenca=1.0e100;
   for(int n=1; n<=5 && (n-1)<ArraySize(g_aumentos); n++)
   {
      if(!g_aumentos[n-1].ativa)
         continue;
      double esperado=PrecoNivelAumentoValorIndice(estado,n-1);
      if(esperado<=0.0)
         continue;
      double diferenca=MathAbs(precoAtual-esperado);
      if(diferenca<melhorDiferenca)
      {
         melhorDiferenca=diferenca;
         melhorNivel=n;
      }
   }
   if(melhorNivel>0)
      return melhorNivel;
   if(anteriores>=1 && anteriores<=5)
      return anteriores;
   return 0;
}

bool ObterPosicaoAumentoNivelFIX212(EstadoLado &estado, int nivel, ulong &ticket, double &precoEntrada, double &volume, long &tipo)
{
   ticket=0;
   precoEntrada=0.0;
   volume=0.0;
   tipo=-1;
   if(nivel<1 || nivel>5)
      return false;
   datetime melhorHora=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong t=PositionGetTicket(i);
      if(t==0 || !PositionSelectByTicket(t))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      long tp=PositionGetInteger(POSITION_TYPE);
      if(estado.lado==LADO_COMPRA && tp!=POSITION_TYPE_BUY)
         continue;
      if(estado.lado==LADO_VENDA && tp!=POSITION_TYPE_SELL)
         continue;
      string comentario=PositionGetString(POSITION_COMMENT);
      int n=NivelAumentoPosicaoFIX212(estado,t,comentario);
      if(n!=nivel)
         continue;
      if(!PositionSelectByTicket(t))
         continue;
      tp=PositionGetInteger(POSITION_TYPE);
      datetime h=(datetime)PositionGetInteger(POSITION_TIME);
      if(ticket==0 || h>=melhorHora)
      {
         ticket=t;
         melhorHora=h;
         precoEntrada=PositionGetDouble(POSITION_PRICE_OPEN);
         volume=PositionGetDouble(POSITION_VOLUME);
         tipo=tp;
      }
   }
   return (ticket>0 && precoEntrada>0.0 && volume>0.0);
}

double PrecoRealizacaoAumentoFIX212(long tipo, double precoEntrada, double volume, double alvoReais)
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(precoEntrada<=0.0 || volume<=0.0 || alvoReais<=0.0 || tickSize<=0.0 || tickValue<=0.0)
      return 0.0;
   double distancia=(MathAbs(alvoReais)/(tickValue*volume))*tickSize;
   if(tipo==POSITION_TYPE_BUY)
      return NormalizeDouble(precoEntrada+distancia,_Digits);
   if(tipo==POSITION_TYPE_SELL)
      return NormalizeDouble(precoEntrada-distancia,_Digits);
   return 0.0;
}

double PrecoLossAumentoFIX321(long tipo, double precoEntrada, double volume, double lossReais)
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(precoEntrada<=0.0 || volume<=0.0 || lossReais<=0.0 || tickSize<=0.0 || tickValue<=0.0)
      return 0.0;
   double distancia=(MathAbs(lossReais)/(tickValue*volume))*tickSize;
   if(tipo==POSITION_TYPE_BUY)
      return NormalizeDouble(precoEntrada-distancia,_Digits);
   if(tipo==POSITION_TYPE_SELL)
      return NormalizeDouble(precoEntrada+distancia,_Digits);
   return 0.0;
}

void SalvarAlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel, double precoAlvo)
{
   int i=nivel-1;
   if(i<0 || i>=5 || precoAlvo<=0.0)
      return;
   if(estado.lado==LADO_COMPRA)
      g_alvoLinhaAumentoBuy[i]=precoAlvo;
   else if(estado.lado==LADO_VENDA)
      g_alvoLinhaAumentoSell[i]=precoAlvo;
}

double AlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return 0.0;
   if(estado.lado==LADO_COMPRA)
      return g_alvoLinhaAumentoBuy[i];
   if(estado.lado==LADO_VENDA)
      return g_alvoLinhaAumentoSell[i];
   return 0.0;
}

void MarcarAumentoRealizadoFIX212(EstadoLado &estado, int nivel, double precoRealizado)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return;
   if(estado.lado==LADO_COMPRA)
   {
      g_aumentoRealizadoBuy[i]=true;
      if(precoRealizado>0.0)
         g_precoRealizadoAumentoBuy[i]=precoRealizado;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_aumentoRealizadoSell[i]=true;
      if(precoRealizado>0.0)
         g_precoRealizadoAumentoSell[i]=precoRealizado;
   }
}

bool AumentoRealizadoFIX212(EstadoLado &estado, int nivel, double &precoRealizado)
{
   precoRealizado=0.0;
   int i=nivel-1;
   if(i<0 || i>=5)
      return false;
   if(estado.lado==LADO_COMPRA)
   {
      precoRealizado=g_precoRealizadoAumentoBuy[i];
      return g_aumentoRealizadoBuy[i];
   }
   if(estado.lado==LADO_VENDA)
   {
      precoRealizado=g_precoRealizadoAumentoSell[i];
      return g_aumentoRealizadoSell[i];
   }
   return false;
}

void ResetarRastreamentoAumentosFIX212(EstadoLado &estado)
{
   if(estado.nome!="MOTOR_COMPRA" && estado.nome!="MOTOR_VENDA")
      return;
   for(int i=0; i<5; i++)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_precosAumentosRestauradosBuy=false;
         g_alvoLinhaAumentoBuy[i]=0.0;
         g_precoRealizadoAumentoBuy[i]=0.0;
         g_precoEntradaAumentoBuy[i]=0.0;
         g_audPrecoProgramadoAumentoBuyFIX358[i]=0.0;
         g_audPrecoExecutadoAumentoBuyFIX358[i]=0.0;
         g_aumentoRealizadoBuy[i]=false;
         g_candleToqueAumentoBuyFIX224[i]=0;
         g_linhaCandleAumentoBuyFIX224[i]=0.0;
         g_candleAumentoConfirmadoBuyFIX224[i]=false;
         g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
         g_horaGatilhoRompimentoBuyFIX337[i]=0;
         ResetarTrailAumentoFIX281(g_trailAumentoBuy[i]);
      }
      else if(estado.lado==LADO_VENDA)
      {
         g_precosAumentosRestauradosSell=false;
         g_alvoLinhaAumentoSell[i]=0.0;
         g_precoRealizadoAumentoSell[i]=0.0;
         g_precoEntradaAumentoSell[i]=0.0;
         g_audPrecoProgramadoAumentoSellFIX358[i]=0.0;
         g_audPrecoExecutadoAumentoSellFIX358[i]=0.0;
         g_aumentoRealizadoSell[i]=false;
         g_candleToqueAumentoSellFIX224[i]=0;
         g_linhaCandleAumentoSellFIX224[i]=0.0;
         g_candleAumentoConfirmadoSellFIX224[i]=false;
         g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
         g_horaGatilhoRompimentoSellFIX337[i]=0;
         ResetarTrailAumentoFIX281(g_trailAumentoSell[i]);
      }
   }
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=0.0;
      g_cicloRearmeA1BuyFIX225=0;
      g_nivelInicioRearmeBuyFIX248=0;
      g_rearmeParcialPendenteBuyFIX248=false;
      g_nivelParcialPendenteBuyFIX248=0;
      g_volumeParcialPendenteBuyFIX248=0.0;
      g_horaParcialPendenteBuyFIX248=0;
      for(int r=0;r<5;r++) g_aguardaRetornoLinhaBuyFIX248[r]=false;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=0.0;
      g_cicloRearmeA1SellFIX225=0;
      g_nivelInicioRearmeSellFIX248=0;
      g_rearmeParcialPendenteSellFIX248=false;
      g_nivelParcialPendenteSellFIX248=0;
      g_volumeParcialPendenteSellFIX248=0.0;
      g_horaParcialPendenteSellFIX248=0;
      for(int r=0;r<5;r++) g_aguardaRetornoLinhaSellFIX248[r]=false;
   }
   string chaveAncora=ChaveAncoraRearmeA1FIX225(estado);
   string chaveCiclo=ChaveCicloRearmeA1FIX225(estado);
   string chaveNivel=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chaveAncora)) GlobalVariableDel(chaveAncora);
   if(GlobalVariableCheck(chaveCiclo)) GlobalVariableDel(chaveCiclo);
   if(GlobalVariableCheck(chaveNivel)) GlobalVariableDel(chaveNivel);
   LimparRearmePendenteFIX251(estado);
}

string NomeBasePrecoAumentoFIX220()
{
   if(InpBasePrecoAumento==BASE_ULTIMO_AUMENTO)
      return "0 ULTIMO AUMENTO";
   if(InpBasePrecoAumento==BASE_ENTRADA_INICIAL)
      return "1 ENTRADA A0";
   return "2 PRECO MEDIO PROTEGIDO";
}

string ChaveAncoraRearmeA1FIX225(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX225_ANCORA_REARME_A1";
}

string ChaveCicloRearmeA1FIX225(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX225_CICLO_REARME_A1";
}

double AncoraRearmeA1FIX225(EstadoLado &estado)
{
   double preco=(estado.lado==LADO_COMPRA ? g_ancoraRearmeA1BuyFIX225 : g_ancoraRearmeA1SellFIX225);
   if(preco>0.0)
      return preco;
   string chave=ChaveAncoraRearmeA1FIX225(estado);
   if(GlobalVariableCheck(chave))
   {
      preco=GlobalVariableGet(chave);
      if(preco>0.0)
      {
         if(estado.lado==LADO_COMPRA) g_ancoraRearmeA1BuyFIX225=preco;
         else if(estado.lado==LADO_VENDA) g_ancoraRearmeA1SellFIX225=preco;
      }
   }
   return preco;
}

int CicloRearmeA1FIX225(EstadoLado &estado)
{
   int ciclo=(estado.lado==LADO_COMPRA ? g_cicloRearmeA1BuyFIX225 : g_cicloRearmeA1SellFIX225);
   if(ciclo>0)
      return ciclo;
   string chave=ChaveCicloRearmeA1FIX225(estado);
   if(GlobalVariableCheck(chave))
   {
      ciclo=(int)GlobalVariableGet(chave);
      if(estado.lado==LADO_COMPRA) g_cicloRearmeA1BuyFIX225=ciclo;
      else if(estado.lado==LADO_VENDA) g_cicloRearmeA1SellFIX225=ciclo;
   }
   return ciclo;
}

string ChaveNivelInicioRearmeFIX248(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX248_NIVEL_INICIO_REARME";
}

int NivelInicioRearmeFIX248(EstadoLado &estado)
{
   int nivel=(estado.lado==LADO_COMPRA ? g_nivelInicioRearmeBuyFIX248 : g_nivelInicioRearmeSellFIX248);
   if(nivel>0)
      return nivel;
   string chave=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chave))
   {
      nivel=(int)GlobalVariableGet(chave);
      if(estado.lado==LADO_COMPRA) g_nivelInicioRearmeBuyFIX248=nivel;
      else if(estado.lado==LADO_VENDA) g_nivelInicioRearmeSellFIX248=nivel;
   }
   return nivel;
}

void SalvarContextoRearmeFIX248(EstadoLado &estado, double precoMedio, int nivelInicio)
{
   if(precoMedio<=0.0 || nivelInicio<1 || nivelInicio>5)
      return;
   SalvarAncoraRearmeA1FIX225(estado,precoMedio);
   if(estado.lado==LADO_COMPRA) g_nivelInicioRearmeBuyFIX248=nivelInicio;
   else if(estado.lado==LADO_VENDA) g_nivelInicioRearmeSellFIX248=nivelInicio;
   GlobalVariableSet(ChaveNivelInicioRearmeFIX248(estado),(double)nivelInicio);
}

void LimparContextoRearmeFIX248(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=0.0;
      g_nivelInicioRearmeBuyFIX248=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=0.0;
      g_nivelInicioRearmeSellFIX248=0;
   }
   string chaveAncora=ChaveAncoraRearmeA1FIX225(estado);
   string chaveNivel=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chaveAncora)) GlobalVariableDel(chaveAncora);
   if(GlobalVariableCheck(chaveNivel)) GlobalVariableDel(chaveNivel);
}

string ChaveRearmePendenteFIX251(EstadoLado &estado, string campo)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX251_REARME_PEND_"+campo;
}

void PersistirRearmePendenteFIX251(EstadoLado &estado)
{
   bool pendente=(estado.lado==LADO_COMPRA ? g_rearmeParcialPendenteBuyFIX248 : g_rearmeParcialPendenteSellFIX248);
   int nivel=(estado.lado==LADO_COMPRA ? g_nivelParcialPendenteBuyFIX248 : g_nivelParcialPendenteSellFIX248);
   double volume=(estado.lado==LADO_COMPRA ? g_volumeParcialPendenteBuyFIX248 : g_volumeParcialPendenteSellFIX248);
   datetime hora=(estado.lado==LADO_COMPRA ? g_horaParcialPendenteBuyFIX248 : g_horaParcialPendenteSellFIX248);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"PEND"),pendente ? 1.0 : 0.0);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"NIVEL"),(double)nivel);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"VOL"),volume);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"HORA"),(double)hora);
}

void RestaurarRearmePendenteFIX251(EstadoLado &estado)
{
   string chavePend=ChaveRearmePendenteFIX251(estado,"PEND");
   if(!GlobalVariableCheck(chavePend) || GlobalVariableGet(chavePend)<=0.0)
      return;
   int nivel=(int)GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"NIVEL"));
   double volume=GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"VOL"));
   datetime hora=(datetime)GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"HORA"));
   if(nivel<1) nivel=1;
   if(hora<=0) hora=TimeCurrent();
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeParcialPendenteBuyFIX248=true;
      g_nivelParcialPendenteBuyFIX248=nivel;
      g_volumeParcialPendenteBuyFIX248=MathAbs(volume);
      g_horaParcialPendenteBuyFIX248=hora;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeParcialPendenteSellFIX248=true;
      g_nivelParcialPendenteSellFIX248=nivel;
      g_volumeParcialPendenteSellFIX248=MathAbs(volume);
      g_horaParcialPendenteSellFIX248=hora;
   }
}

void LimparRearmePendenteFIX251(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeParcialPendenteBuyFIX248=false;
      g_nivelParcialPendenteBuyFIX248=0;
      g_volumeParcialPendenteBuyFIX248=0.0;
      g_horaParcialPendenteBuyFIX248=0;
      g_rearmeSnapshotVolumeBuyFIX251=-1.0;
      g_rearmeSnapshotMediaBuyFIX251=0.0;
      g_rearmeSnapshotHoraBuyFIX251=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeParcialPendenteSellFIX248=false;
      g_nivelParcialPendenteSellFIX248=0;
      g_volumeParcialPendenteSellFIX248=0.0;
      g_horaParcialPendenteSellFIX248=0;
      g_rearmeSnapshotVolumeSellFIX251=-1.0;
      g_rearmeSnapshotMediaSellFIX251=0.0;
      g_rearmeSnapshotHoraSellFIX251=0;
   }
   string campos[4]={"PEND","NIVEL","VOL","HORA"};
   for(int i=0;i<4;i++)
   {
      string chave=ChaveRearmePendenteFIX251(estado,campos[i]);
      if(GlobalVariableCheck(chave)) GlobalVariableDel(chave);
   }
}

bool RearmeParcialPendenteFIX248(EstadoLado &estado)
{
   RestaurarRearmePendenteFIX251(estado);
   if(estado.lado==LADO_COMPRA) return g_rearmeParcialPendenteBuyFIX248;
   if(estado.lado==LADO_VENDA) return g_rearmeParcialPendenteSellFIX248;
   return false;
}

void AgendarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido)
{
   if(nivelRealizado<1) nivelRealizado=1;
   if(nivelRealizado>5) nivelRealizado=5;
   int indiceNivelFIX453=nivelRealizado-1;
   if(estado.lado==LADO_COMPRA)
   {
      g_horaRearmeNivelBuyFIX453[indiceNivelFIX453]=TimeCurrent();
      g_rearmeParcialPendenteBuyFIX248=true;
      g_nivelParcialPendenteBuyFIX248=MathMax(g_nivelParcialPendenteBuyFIX248,nivelRealizado);
      g_volumeParcialPendenteBuyFIX248+=MathAbs(volumeRemovido);
      g_horaParcialPendenteBuyFIX248=TimeCurrent();
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_horaRearmeNivelSellFIX453[indiceNivelFIX453]=TimeCurrent();
      g_rearmeParcialPendenteSellFIX248=true;
      g_nivelParcialPendenteSellFIX248=MathMax(g_nivelParcialPendenteSellFIX248,nivelRealizado);
      g_volumeParcialPendenteSellFIX248+=MathAbs(volumeRemovido);
      g_horaParcialPendenteSellFIX248=TimeCurrent();
   }
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeSnapshotVolumeBuyFIX251=-1.0;
      g_rearmeSnapshotMediaBuyFIX251=0.0;
      g_rearmeSnapshotHoraBuyFIX251=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeSnapshotVolumeSellFIX251=-1.0;
      g_rearmeSnapshotMediaSellFIX251=0.0;
      g_rearmeSnapshotHoraSellFIX251=0;
   }
   PersistirRearmePendenteFIX251(estado);
   estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL CONFIRMADA | aguarda duas leituras estaveis de volume e preco medio para rearmar.",nivelRealizado);
   estado.ultimaMensagem=estado.motivoBloqueioAumento;
   RegistrarLogValidacaoSistema("FIX251_REARME_AGENDADO_SEGURO",estado.motivoBloqueioAumento);
}

int PrimeiroNivelRearmavelFIX248(EstadoLado &estado, int nivelRealizado)
{
   // FIX450: rearme verdadeiramente individual. O mesmo nível que realizou
   // volta a ficar disponível, independentemente de níveis superiores abertos.
   if(nivelRealizado<1 || nivelRealizado>g_gerAumentos.maxAumentos || nivelRealizado>ArraySize(g_aumentos))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d fora do limite configurado para rearme.",nivelRealizado);
      return 0;
   }
   if(!g_aumentos[nivelRealizado-1].ativa)
   {
      estado.motivoBloqueioAumento=StringFormat("A%d está desativado; sem rearme.",nivelRealizado);
      return 0;
   }

   ulong ticket=0;
   double preco=0.0,volume=0.0;
   long tipo=-1;
   if(ObterPosicaoAumentoNivelFIX212(estado,nivelRealizado,ticket,preco,volume,tipo))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d ainda possui ticket %I64u com %.2f contrato(s); rearme aguarda fechamento integral.",
                                                nivelRealizado,ticket,volume);
      return 0;
   }
   return nivelRealizado;
}

void LimparMemoriaNiveisAPartirFIX248(EstadoLado &estado, int nivelInicial)
{
   if(nivelInicial<1) nivelInicial=1;
   if(nivelInicial>5) return;
   for(int nivel=nivelInicial;nivel<=5;nivel++)
   {
      int i=nivel-1;
      LiberarLockCiclo(ChaveLockAumento(estado,nivel));
      LiberarLockCiclo(ChaveLockAumentoConfirmadoFIX208(estado,nivel));
      string chavePreco=ChavePrecoEntradaAumentoFIX220(estado,nivel);
      if(GlobalVariableCheck(chavePreco)) GlobalVariableDel(chavePreco);
      if(estado.lado==LADO_COMPRA)
      {
         g_alvoLinhaAumentoBuy[i]=0.0;
         g_precoRealizadoAumentoBuy[i]=0.0;
         g_precoEntradaAumentoBuy[i]=0.0;
         g_aumentoRealizadoBuy[i]=false;
         g_candleToqueAumentoBuyFIX224[i]=0;
         g_linhaCandleAumentoBuyFIX224[i]=0.0;
         g_candleAumentoConfirmadoBuyFIX224[i]=false;
         g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
         g_horaGatilhoRompimentoBuyFIX337[i]=0;
         g_aguardaRetornoLinhaBuyFIX248[i]=false;
      }
      else if(estado.lado==LADO_VENDA)
      {
         g_alvoLinhaAumentoSell[i]=0.0;
         g_precoRealizadoAumentoSell[i]=0.0;
         g_precoEntradaAumentoSell[i]=0.0;
         g_aumentoRealizadoSell[i]=false;
         g_candleToqueAumentoSellFIX224[i]=0;
         g_linhaCandleAumentoSellFIX224[i]=0.0;
         g_candleAumentoConfirmadoSellFIX224[i]=false;
         g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
         g_horaGatilhoRompimentoSellFIX337[i]=0;
         g_aguardaRetornoLinhaSellFIX248[i]=false;
      }
   }
   if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
   else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
   estado.ultimoNivelAumentoUsado=nivelInicial-1;
   estado.aumentosExecutados=nivelInicial-1;
}

void LimparMemoriaSomenteNivelFIX450(EstadoLado &estado,int nivel)
{
   if(nivel<1 || nivel>5) return;
   int i=nivel-1;
   LiberarLockCiclo(ChaveLockAumento(estado,nivel));
   LiberarLockCiclo(ChaveLockAumentoConfirmadoFIX208(estado,nivel));
   string chavePreco=ChavePrecoEntradaAumentoFIX220(estado,nivel);
   if(GlobalVariableCheck(chavePreco)) GlobalVariableDel(chavePreco);

   if(estado.lado==LADO_COMPRA)
   {
      g_alvoLinhaAumentoBuy[i]=0.0;
      g_precoRealizadoAumentoBuy[i]=0.0;
      g_precoEntradaAumentoBuy[i]=0.0;
      g_aumentoRealizadoBuy[i]=false;
      g_candleToqueAumentoBuyFIX224[i]=0;
      g_linhaCandleAumentoBuyFIX224[i]=0.0;
      g_candleAumentoConfirmadoBuyFIX224[i]=false;
      g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
      g_horaGatilhoRompimentoBuyFIX337[i]=0;
      g_aguardaRetornoLinhaBuyFIX248[i]=false;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_alvoLinhaAumentoSell[i]=0.0;
      g_precoRealizadoAumentoSell[i]=0.0;
      g_precoEntradaAumentoSell[i]=0.0;
      g_aumentoRealizadoSell[i]=false;
      g_candleToqueAumentoSellFIX224[i]=0;
      g_linhaCandleAumentoSellFIX224[i]=0.0;
      g_candleAumentoConfirmadoSellFIX224[i]=false;
      g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
      g_horaGatilhoRompimentoSellFIX337[i]=0;
      g_aguardaRetornoLinhaSellFIX248[i]=false;
   }

   // Faz o sequenciador apontar novamente para o mesmo nível, sem limpar os demais.
   estado.ultimoNivelAumentoUsado=nivel-1;
   estado.aumentosExecutados=nivel-1;
}

bool PrecoNoLadoGatilhoAumentoFIX248(EstadoLado &estado, double linha)
{
   if(linha<=0.0) return false;
   double precoExecucao=(estado.lado==LADO_COMPRA) ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(precoExecucao<=0.0) return false;
   if(estado.lado==LADO_COMPRA)
      return InpAumentosContraPosicao ? (precoExecucao<=linha) : (precoExecucao>=linha);
   if(estado.lado==LADO_VENDA)
      return InpAumentosContraPosicao ? (precoExecucao>=linha) : (precoExecucao<=linha);
   return false;
}

double PrecoExecutavelAumentoFIX363(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
      return SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(estado.lado==LADO_VENDA)
      return SymbolInfoDouble(_Symbol,SYMBOL_BID);
   return 0.0;
}

bool PrecoAumentoNaLinhaOuMelhorFIX363(EstadoLado &estado,double linha,string &status)
{
   status="";
   if(linha<=0.0)
   {
      status="LINHA PROGRAMADA INVALIDA";
      return false;
   }
   double preco=PrecoExecutavelAumentoFIX363(estado);
   if(preco<=0.0)
   {
      status="SEM PRECO EXECUTAVEL";
      return false;
   }

   bool correto=false;
   if(estado.lado==LADO_COMPRA)
      correto=InpAumentosContraPosicao ? (preco<=linha) : (preco>=linha);
   else if(estado.lado==LADO_VENDA)
      correto=InpAumentosContraPosicao ? (preco>=linha) : (preco<=linha);

   if(!correto)
   {
      status=StringFormat("PRECO PIOR QUE A LINHA | PROG %.0f | EXEC %.0f | AGUARDA NOVO TOQUE+CANDLE",linha,preco);
      return false;
   }
   status=StringFormat("PRECO MELHOR OK | PROG %.0f | EXEC %.0f",linha,preco);
   return true;
}

bool ValidarAumentoFinalAntesEnvioFIX363(EstadoLado &estado,int indiceZero,double linhaProgramada,string &status)
{
   status="";
   if(indiceZero<0 || indiceZero>=ArraySize(g_aumentos))
   {
      status="NIVEL INVALIDO";
      return false;
   }
   if(!InpAumentoConfirmarFechamentoCandle || !CandleAumentoConfirmadoFIX224(estado,indiceZero))
   {
      status=StringFormat("A%d SEM CANDLE M1 CONFIRMADO",indiceZero+1);
      return false;
   }

   double linhaAtual=PrecoNivelAumentoValorIndice(estado,indiceZero);
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0.0) tickSize=_Point;
   if(linhaAtual<=0.0 || MathAbs(linhaAtual-linhaProgramada)>tickSize*0.5)
   {
      status=StringFormat("A%d LINHA MUDOU | ARMADA %.0f | ATUAL %.0f | NOVA CONFIRMACAO",indiceZero+1,linhaProgramada,linhaAtual);
      LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
      return false;
   }

   if(!PrecoAumentoNaLinhaOuMelhorFIX363(estado,linhaProgramada,status))
   {
      LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
      return false;
   }
   return true;
}

void PrepararNovoCruzamentoNivelFIX248(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5 || i>=ArraySize(g_aumentos) || !g_aumentos[i].ativa)
      return;
   double linha=PrecoNivelAumentoValorIndice(estado,i);
   bool aguarda=(linha>0.0 && PrecoNoLadoGatilhoAumentoFIX248(estado,linha));
   if(estado.lado==LADO_COMPRA) g_aguardaRetornoLinhaBuyFIX248[i]=aguarda;
   else if(estado.lado==LADO_VENDA) g_aguardaRetornoLinhaSellFIX248[i]=aguarda;
   LimparConfirmacaoCandleAumentoFIX224(estado,i);
}

bool NovoCruzamentoLiberadoFIX248(EstadoLado &estado, int nivel, double linha, string &status)
{
   status="";
   int i=nivel-1;
   if(i<0 || i>=5) return false;
   bool aguarda=(estado.lado==LADO_COMPRA ? g_aguardaRetornoLinhaBuyFIX248[i] : g_aguardaRetornoLinhaSellFIX248[i]);
   if(!aguarda) return true;
   if(PrecoNoLadoGatilhoAumentoFIX248(estado,linha))
   {
      status=StringFormat("A%d NOVA LINHA %.0f | aguarda preco voltar e cruzar novamente",nivel,linha);
      return false;
   }
   if(estado.lado==LADO_COMPRA) g_aguardaRetornoLinhaBuyFIX248[i]=false;
   else if(estado.lado==LADO_VENDA) g_aguardaRetornoLinhaSellFIX248[i]=false;
   LimparConfirmacaoCandleAumentoFIX224(estado,i);
   status=StringFormat("A%d RETORNO CONFIRMADO | novo cruzamento liberado",nivel);
   RegistrarLogValidacaoSistema("FIX248_NOVO_CRUZAMENTO_ARMADO",status);
   return false;
}

bool AplicarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido)
{
   AtualizarEstadoLado(estado);
   if(!estado.posicaoAberta || estado.precoMedio<=0.0)
   {
      LimparContextoRearmeFIX248(estado);
      estado.motivoBloqueioAumento="Parcial confirmou encerramento da ponta; sem rearme.";
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      return false;
   }
   int nivelInicio=PrimeiroNivelRearmavelFIX248(estado,nivelRealizado);
   if(nivelInicio<=0)
   {
      if(estado.motivoBloqueioAumento=="")
         estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL OK | %.2f contratos | nenhum nivel integral livre dentro do limite.",nivelRealizado,estado.contratos);
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      RegistrarLogValidacaoSistema("FIX248_SEM_NIVEL_REARMAVEL",estado.motivoBloqueioAumento);
      return false;
   }
   double novaMedia=estado.precoMedio;
   RestaurarPrecosEntradaAumentosFIX220(estado);
   int nivelAncora=0;
   double ancoraUltimoAumento=UltimoPrecoAumentoAntesFIX220(estado,5,nivelAncora);
   if(ancoraUltimoAumento<=0.0)
      ancoraUltimoAumento=novaMedia;
   // A média atual serve para gain/loss e painel. A distância do novo aumento
   // parte do último aumento realmente executado deste mesmo Magic/lado.
   SalvarContextoRearmeFIX248(estado,ancoraUltimoAumento,nivelInicio);
   // FIX450: limpa somente o nível realizado; tickets e memórias dos outros níveis permanecem.
   LimparMemoriaSomenteNivelFIX450(estado,nivelInicio);
   estado.horarioUltimoAumento=TimeCurrent();
   double novaLinha=PrecoNivelAumentoValorIndice(estado,nivelInicio-1);
   PrepararNovoCruzamentoNivelFIX248(estado,nivelInicio);
   int minutos=MathMax(0,g_aumentos[nivelInicio-1].tempoMinutos);
   int ciclo=CicloRearmeA1FIX225(estado);
   estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL OK %.2f CT | REARME MESMO NIVEL A%d | MEDIA %.0f | ANCORA A%d %.0f | CICLO #%d | LINHA %.0f | TIMER %dM | OUTROS NIVEIS PRESERVADOS.",
                                             nivelRealizado,MathAbs(volumeRemovido),nivelInicio,novaMedia,nivelAncora,ancoraUltimoAumento,ciclo,novaLinha,minutos);
   estado.ultimaMensagem=estado.motivoBloqueioAumento;
   RegistrarLogValidacaoSistema("FIX248_REARME_DINAMICO_OK",estado.motivoBloqueioAumento);
   g_ultimaAtualizacaoPainelVisual=0;
   return true;
}

bool RecuperarRearmeSemEventoFIX452(EstadoLado &estado)
{
   // Recupera parcial/rearme quando o EA foi recompilado ou recolocado depois
   // do deal. A marcação e o acumulado são reconstruídos do histórico do ciclo.
   AtualizarEstadoLado(estado);
   if(!estado.posicaoAberta)
      return false;
   if(RearmeParcialPendenteFIX248(estado) || NivelInicioRearmeFIX248(estado)>0)
      return false;

   for(int nivel=1;nivel<=g_gerAumentos.maxAumentos && nivel<=ArraySize(g_aumentos);nivel++)
   {
      if(!g_aumentos[nivel-1].ativa)
         continue;

      ulong ticket=0;
      double preco=0.0,volumeAberto=0.0;
      long tipo=-1;
      if(ObterPosicaoAumentoNivelFIX212(estado,nivel,ticket,preco,volumeAberto,tipo))
         continue;

      double precoRealizado=0.0;
      if(!AumentoRealizadoFIX212(estado,nivel,precoRealizado))
         continue;

      double acumulado=(estado.lado==LADO_COMPRA
                        ? g_realizadoAumentosNivelBuyFIX324[nivel-1]
                        : g_realizadoAumentosNivelSellFIX324[nivel-1]);
      int qtdReal=(estado.lado==LADO_COMPRA
                   ? g_qtdRealizacoesNivelBuyFIX324[nivel-1]
                   : g_qtdRealizacoesNivelSellFIX324[nivel-1]);
      if(qtdReal<=0 && MathAbs(acumulado)<0.005)
         continue;

      double volumeReal=(estado.lado==LADO_COMPRA
                         ? g_volumeRealizadoNivelBuyFIX324[nivel-1]
                         : g_volumeRealizadoNivelSellFIX324[nivel-1]);
      if(volumeReal<=0.0)
         volumeReal=MathMax(1.0,g_aumentos[nivel-1].qtd);

      AgendarRearmeDinamicoAposParcialFIX248(estado,nivel,volumeReal);
      RegistrarLogValidacaoSistema(
         "FIX452_REARME_RECUPERADO_APOS_REINICIO",
         StringFormat("A%d sem ticket | acumulado %s | %d realizacao(oes) | rearme recuperado.",
                      nivel,PnlMoedaBRL(acumulado),qtdReal));
      return true; // Um contexto por vez; os demais serão recuperados depois.
   }
   return false;
}

bool ProcessarRearmeDinamicoPendenteFIX248(EstadoLado &estado)
{
   if(!RearmeParcialPendenteFIX248(estado))
      return false;

   AtualizarEstadoLado(estado);
   datetime agora=TimeCurrent();
   datetime horaPendente=(estado.lado==LADO_COMPRA ? g_horaParcialPendenteBuyFIX248 : g_horaParcialPendenteSellFIX248);
   if(horaPendente>0 && (agora-horaPendente)<2)
   {
      estado.motivoBloqueioAumento="Parcial confirmada: aguardando estabilizacao inicial do servidor.";
      return false;
   }

   double volumeAtual=(estado.posicaoAberta ? MathAbs(estado.contratos) : 0.0);
   double mediaAtual=(estado.posicaoAberta ? estado.precoMedio : 0.0);
   double snapshotVolume=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotVolumeBuyFIX251 : g_rearmeSnapshotVolumeSellFIX251);
   double snapshotMedia=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotMediaBuyFIX251 : g_rearmeSnapshotMediaSellFIX251);
   datetime snapshotHora=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotHoraBuyFIX251 : g_rearmeSnapshotHoraSellFIX251);

   if(snapshotHora<=0)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_rearmeSnapshotVolumeBuyFIX251=volumeAtual;
         g_rearmeSnapshotMediaBuyFIX251=mediaAtual;
         g_rearmeSnapshotHoraBuyFIX251=agora;
      }
      else
      {
         g_rearmeSnapshotVolumeSellFIX251=volumeAtual;
         g_rearmeSnapshotMediaSellFIX251=mediaAtual;
         g_rearmeSnapshotHoraSellFIX251=agora;
      }
      estado.motivoBloqueioAumento=StringFormat("Parcial confirmada: primeira leitura servidor %.2f CT | MEDIA %.0f; aguardando confirmacao.",volumeAtual,mediaAtual);
      return false;
   }
   if((agora-snapshotHora)<1)
      return false;

   bool volumeEstavel=(MathAbs(volumeAtual-snapshotVolume)<=0.0001);
   double toleranciaMedia=MathMax(_Point,0.0000001);
   bool mediaEstavel=(MathAbs(mediaAtual-snapshotMedia)<=toleranciaMedia);
   if(!volumeEstavel || !mediaEstavel)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_rearmeSnapshotVolumeBuyFIX251=volumeAtual;
         g_rearmeSnapshotMediaBuyFIX251=mediaAtual;
         g_rearmeSnapshotHoraBuyFIX251=agora;
      }
      else
      {
         g_rearmeSnapshotVolumeSellFIX251=volumeAtual;
         g_rearmeSnapshotMediaSellFIX251=mediaAtual;
         g_rearmeSnapshotHoraSellFIX251=agora;
      }
      estado.motivoBloqueioAumento=StringFormat("Servidor ainda atualizando: %.2f CT | MEDIA %.0f; nova verificacao antes do rearme.",volumeAtual,mediaAtual);
      RegistrarLogValidacaoSistema("FIX251_REARME_AGUARDA_ESTABILIDADE",estado.motivoBloqueioAumento);
      return false;
   }

   int nivel=(estado.lado==LADO_COMPRA ? g_nivelParcialPendenteBuyFIX248 : g_nivelParcialPendenteSellFIX248);
   double volume=(estado.lado==LADO_COMPRA ? g_volumeParcialPendenteBuyFIX248 : g_volumeParcialPendenteSellFIX248);
   bool aplicado=AplicarRearmeDinamicoAposParcialFIX248(estado,nivel,volume);
   LimparRearmePendenteFIX251(estado);
   return aplicado;
}

void SalvarAncoraRearmeA1FIX225(EstadoLado &estado, double preco)
{
   if(preco<=0.0)
      return;
   preco=NormalizeDouble(preco,_Digits);
   int ciclo=CicloRearmeA1FIX225(estado)+1;
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=preco;
      g_cicloRearmeA1BuyFIX225=ciclo;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=preco;
      g_cicloRearmeA1SellFIX225=ciclo;
   }
   GlobalVariableSet(ChaveAncoraRearmeA1FIX225(estado),preco);
   GlobalVariableSet(ChaveCicloRearmeA1FIX225(estado),(double)ciclo);
}

bool EscadaA1RearmadaFIX225(EstadoLado &estado)
{
   return (InpRearmarA1AposParcialFIX225 && AncoraRearmeA1FIX225(estado)>0.0 && NivelInicioRearmeFIX248(estado)>0);
}



string ChavePrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel)
{
   return PrefixoLockCicloMagic(estado.magic)+"PENT_A"+IntegerToString(nivel);
}

void SalvarPrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel, double preco)
{
   int i=nivel-1;
   if(i<0 || i>=5 || preco<=0.0)
      return;
   preco=NormalizeDouble(preco,_Digits);
   if(estado.lado==LADO_COMPRA)
      g_precoEntradaAumentoBuy[i]=preco;
   else if(estado.lado==LADO_VENDA)
      g_precoEntradaAumentoSell[i]=preco;
   GlobalVariableSet(ChavePrecoEntradaAumentoFIX220(estado,nivel),preco);
}

double PrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return 0.0;
   double preco=(estado.lado==LADO_COMPRA ? g_precoEntradaAumentoBuy[i] : g_precoEntradaAumentoSell[i]);
   if(preco>0.0)
      return preco;
   string chave=ChavePrecoEntradaAumentoFIX220(estado,nivel);
   if(GlobalVariableCheck(chave))
   {
      preco=GlobalVariableGet(chave);
      if(preco>0.0)
      {
         if(estado.lado==LADO_COMPRA)
            g_precoEntradaAumentoBuy[i]=preco;
         else if(estado.lado==LADO_VENDA)
            g_precoEntradaAumentoSell[i]=preco;
      }
   }
   return preco;
}

void RegistrarAuditoriaVisualAumentoFIX358(EstadoLado &estado,int nivel,double programado,double executado)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return;
   if(programado>0.0) programado=NormalizeDouble(programado,_Digits);
   if(executado>0.0) executado=NormalizeDouble(executado,_Digits);
   if(estado.lado==LADO_COMPRA)
   {
      if(programado>0.0) g_audPrecoProgramadoAumentoBuyFIX358[i]=programado;
      if(executado>0.0) g_audPrecoExecutadoAumentoBuyFIX358[i]=executado;
   }
   else if(estado.lado==LADO_VENDA)
   {
      if(programado>0.0) g_audPrecoProgramadoAumentoSellFIX358[i]=programado;
      if(executado>0.0) g_audPrecoExecutadoAumentoSellFIX358[i]=executado;
   }
}

double PrecoProgramadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5) return 0.0;
   return (estado.lado==LADO_COMPRA ? g_audPrecoProgramadoAumentoBuyFIX358[i] : g_audPrecoProgramadoAumentoSellFIX358[i]);
}

double PrecoExecutadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5) return 0.0;
   return (estado.lado==LADO_COMPRA ? g_audPrecoExecutadoAumentoBuyFIX358[i] : g_audPrecoExecutadoAumentoSellFIX358[i]);
}

void RestaurarPrecosEntradaAumentosFIX220(EstadoLado &estado)
{
   for(int nivel=1;nivel<=5;nivel++)
      PrecoEntradaAumentoFIX220(estado,nivel);
   bool jaRestaurado=(estado.lado==LADO_COMPRA ? g_precosAumentosRestauradosBuy : g_precosAumentosRestauradosSell);
   if(jaRestaurado)
      return;

   // Recupera uma unica vez de posicoes abertas quando o EA foi colocado no meio do ciclo.
   for(int p=PositionsTotal()-1;p>=0;p--)
   {
      ulong ticket=PositionGetTicket(p);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(estado.lado==LADO_COMPRA && tipo!=POSITION_TYPE_BUY)
         continue;
      if(estado.lado==LADO_VENDA && tipo!=POSITION_TYPE_SELL)
         continue;
      int nivel=NivelAumentoComentarioFIX207(PositionGetString(POSITION_COMMENT));
      if(nivel>0 && PrecoEntradaAumentoFIX220(estado,nivel)<=0.0)
         SalvarPrecoEntradaAumentoFIX220(estado,nivel,PositionGetDouble(POSITION_PRICE_OPEN));
   }

   // FIX225: com escada rearmada, os niveis antigos fechados pertencem ao ciclo anterior.
   // Posicoes ainda abertas ja foram recuperadas acima; nao repopular A1/A2 antigos pelo historico.
   if(EscadaA1RearmadaFIX225(estado))
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }

   // Recupera aumentos ja realizados pelo historico do ciclo atual.
   datetime inicio=estado.horarioEntrada;
   if(inicio<=0)
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }
   if(!HistorySelect(inicio,TimeCurrent()))
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }
   for(int d=0;d<HistoryDealsTotal();d++)
   {
      ulong deal=HistoryDealGetTicket(d);
      if(deal==0)
         continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=estado.magic)
         continue;
      if(HistoryDealGetInteger(deal,DEAL_ENTRY)!=DEAL_ENTRY_IN)
         continue;
      int nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(deal,DEAL_COMMENT));
      if(nivel<=0 || PrecoEntradaAumentoFIX220(estado,nivel)>0.0)
         continue;
      SalvarPrecoEntradaAumentoFIX220(estado,nivel,HistoryDealGetDouble(deal,DEAL_PRICE));
   }
   if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
   else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
}

double PassoAumentoPontosFIX220(int indiceZero)
{
   if(indiceZero<0 || indiceZero>=ArraySize(g_aumentos))
      return 0.0;
   double atual=MathAbs((double)g_aumentos[indiceZero].distanciaPontos);
   if(atual<=0.0)
      return 0.0;
   if(!InpAumentosDistanciaAbsolutaEntrada || indiceZero==0)
      return atual;
   for(int i=indiceZero-1;i>=0;i--)
   {
      if(!g_aumentos[i].ativa)
         continue;
      double anterior=MathAbs((double)g_aumentos[i].distanciaPontos);
      double passo=atual-anterior;
      if(passo>0.0)
         return passo;
      break;
   }
   return atual;
}

double UltimoPrecoAumentoAntesFIX220(EstadoLado &estado, int indiceZero, int &nivelEncontrado)
{
   nivelEncontrado=0;
   for(int i=(int)MathMin(indiceZero-1,4);i>=0;i--)
   {
      double preco=PrecoEntradaAumentoFIX220(estado,i+1);
      if(preco>0.0)
      {
         nivelEncontrado=i+1;
         return preco;
      }
   }
   return 0.0;
}

int ProximoIndiceAumentoSequencialFIX218(EstadoLado &estado)
{
   // FIX451: um nível confirmado como rearmado tem prioridade sobre o maior
   // nível histórico usado. Sem isso, A3/A4 permaneciam como FEITO para sempre.
   int nivelRearme=NivelInicioRearmeFIX248(estado);
   if(nivelRearme>=1 && nivelRearme<=g_gerAumentos.maxAumentos &&
      nivelRearme<=ArraySize(g_aumentos) && g_aumentos[nivelRearme-1].ativa)
   {
      ulong ticketRearme=0;
      double precoRearme=0.0,volumeRearme=0.0;
      long tipoRearme=-1;
      if(!ObterPosicaoAumentoNivelFIX212(estado,nivelRearme,ticketRearme,precoRearme,volumeRearme,tipoRearme))
         return nivelRearme-1;
   }

   int idx=estado.ultimoNivelAumentoUsado;
   if(estado.aumentosExecutados>idx)
      idx=estado.aumentosExecutados;
   if(idx<0)
      idx=0;
   while(idx<ArraySize(g_aumentos))
   {
      if(!g_aumentos[idx].ativa)
      {
         idx++;
         continue;
      }
      int nivel=idx+1;
      string chaveOK=ChaveLockAumentoConfirmadoFIX208(estado,nivel);
      if(GlobalVariableCheck(chaveOK) && GlobalVariableGet(chaveOK)>0.0)
      {
         if(estado.ultimoNivelAumentoUsado<nivel)
            estado.ultimoNivelAumentoUsado=nivel;
         if(estado.aumentosExecutados<nivel)
            estado.aumentosExecutados=nivel;
         idx++;
         continue;
      }
      // Lock ainda pendente nao libera o proximo nivel. ExecutarAumento trata confirmacao/recuperacao sem duplicar ordem.
      break;
   }
   return idx;
}


double ResultadoCicloPontaFIX207(long tipo, double lucroAberto)
{
   if(tipo==POSITION_TYPE_BUY)
      return lucroAberto+g_parciaisCicloBuy;
   if(tipo==POSITION_TYPE_SELL)
      return lucroAberto+g_parciaisCicloSell;
   return lucroAberto;
}

bool FecharTicketAumentoFIX207(EstadoLado &estado, ulong ticket, double volumeDesejado, int nivel, double lucroTicket, string motivoFIX281)
{
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return false;
   if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
      return false;
   long tipoPosicao=PositionGetInteger(POSITION_TYPE);
   double volumePosicao=PositionGetDouble(POSITION_VOLUME);
   if(volumePosicao<=0.0)
      return false;
   double volumeFechar=MathMin(volumePosicao,MathAbs(volumeDesejado));
   volumeFechar=NormalizarVolumeParaFechamento(volumeFechar);
   if(volumeFechar<=0.0)
      return false;
   if(!PermiteEnvioOrdem(estado,"Saida aumento alvo/trailing FIX281"))
      return false;
   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action=TRADE_ACTION_DEAL;
   req.position=ticket;
   req.symbol=_Symbol;
   req.volume=volumeFechar;
   req.magic=(ulong)estado.magic;
   req.deviation=InpDesvioMaximoPontos;
   req.type_time=ORDER_TIME_GTC;
   req.type_filling=TipoPreenchimentoSeguro();
   req.comment=ComentarioComIdentidadeMagicFIX304(StringFormat("%s PARCIAL_AUMENTO_FIX281 A%d %s",InpComentarioOrdens,nivel,motivoFIX281),req.magic);
   if(tipoPosicao==POSITION_TYPE_BUY)
   {
      req.type=ORDER_TYPE_SELL;
      req.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   }
   else if(tipoPosicao==POSITION_TYPE_SELL)
   {
      req.type=ORDER_TYPE_BUY;
      req.price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   }
   else
      return false;
   estado.ultimaTentativaOrdem=TimeCurrent();
   ResetLastError();
   bool ok=OrderSend(req,res);
   bool aceito=(ok && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED || res.retcode==TRADE_RETCODE_DONE_PARTIAL));
   if(aceito)
   {
      RegistrarGerenciadorOrdens(estado,"AUMENTO_SAIDA_OK",
         StringFormat("FIX282 A%d %s | ticket %s | lucro %s | fecha %.2f contrato",
                      nivel,motivoFIX281,IntegerToString((long)ticket),PnlMoedaBRL(lucroTicket),volumeFechar),
         res.retcode,0,volumeFechar,req.price,true);
      return true;
   }
   RegistrarGerenciadorOrdens(estado,"AUMENTO_SAIDA_REJECT",
      StringFormat("FIX282 A%d %s ticket %s rejeitado | retcode %d | erro %d",
                   nivel,motivoFIX281,IntegerToString((long)ticket),(int)res.retcode,GetLastError()),
      res.retcode,GetLastError(),volumeFechar,req.price,true);
   return false;
}

double CalcularDefesaDegrauFIX281(double melhorLucro, double ativacao, double passo)
{
   ativacao=MathAbs(ativacao);
   passo=MathAbs(passo);
   if(ativacao<=0.0 || passo<=0.0 || melhorLucro<ativacao)
      return 0.0;
   double degraus=MathFloor(((melhorLucro-ativacao)+0.0000001)/passo);
   return MathMax(0.0,(ativacao-passo)+(degraus*passo));
}

void ResetarTrailAumentoFIX281(EstadoTrailAumentoFIX281 &trail)
{
   trail.ticket=0;
   trail.identificador=0;
   trail.melhorLucro=0.0;
   trail.defesaAtual=0.0;
   trail.protecaoArmada=false;
   trail.movelArmadoFIX397=false;
   trail.defesaMovelFIX397=0.0;
   trail.melhorPrecoFIX325=0.0;
   trail.stopPrecoFIX325=0.0;
   trail.distanciaAtualPontosFIX325=0.0;
   trail.degrauAtualFIX325=-1;
   trail.alertaToqueEmitidoFIX325=false;
}

double NormalizarPrecoTrailInteligenteFIX325(double preco, long tipo)
{
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   if(tick<=0.0) return NormalizeDouble(preco,_Digits);
   double unidades=preco/tick;
   if(tipo==POSITION_TYPE_BUY)
      unidades=MathFloor(unidades+0.0000001);
   else
      unidades=MathCeil(unidades-0.0000001);
   return NormalizeDouble(unidades*tick,_Digits);
}

bool AtualizarTrailInteligenteAumentoFIX325(EstadoLado &estado,
                                             long tipo,
                                             ulong ticket,
                                             int nivel,
                                             double volume,
                                             EstadoTrailAumentoFIX281 &trail,
                                             bool &armouAgora,
                                             bool &moveuAgora)
{
   armouAgora=false;
   moveuAgora=false;
   if(!g_trailInteligenteLinhasAtivoFIX325 || ticket==0 || volume<=0.0 || !PositionSelectByTicket(ticket))
      return false;
   double entrada=PositionGetDouble(POSITION_PRICE_OPEN);
   double atual=(tipo==POSITION_TYPE_BUY ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK));
   if(entrada<=0.0 || atual<=0.0 || _Point<=0.0)
      return false;
   if(trail.melhorPrecoFIX325<=0.0)
      trail.melhorPrecoFIX325=entrada;
   if(tipo==POSITION_TYPE_BUY && atual>trail.melhorPrecoFIX325)
      trail.melhorPrecoFIX325=atual;
   else if(tipo==POSITION_TYPE_SELL && (trail.melhorPrecoFIX325<=0.0 || atual<trail.melhorPrecoFIX325))
      trail.melhorPrecoFIX325=atual;

   double favorPontos=(tipo==POSITION_TYPE_BUY
                       ? (trail.melhorPrecoFIX325-entrada)/_Point
                       : (entrada-trail.melhorPrecoFIX325)/_Point);
   if(favorPontos+0.0001<g_trailInteligenteAtivaPontosFIX325)
      return false;
   int degrau=(int)MathFloor((favorPontos-g_trailInteligenteAtivaPontosFIX325+0.0001)/g_trailInteligentePassoPontosFIX325);
   if(degrau<0) degrau=0;
   bool precisaMover=(!trail.protecaoArmada || degrau>trail.degrauAtualFIX325);
   if(precisaMover)
   {
      double distancia=g_trailInteligenteDistanciaPontosFIX325;
      if(g_trailInteligenteReduzirFIX325)
         distancia-=((double)degrau*g_trailInteligenteReducaoPontosFIX325);
      if(distancia<g_trailInteligenteDistanciaMinimaPontosFIX325)
         distancia=g_trailInteligenteDistanciaMinimaPontosFIX325;
      double candidato=(tipo==POSITION_TYPE_BUY
                        ? trail.melhorPrecoFIX325-(distancia*_Point)
                        : trail.melhorPrecoFIX325+(distancia*_Point));
      // O primeiro stop nunca fica pior que o preco de entrada.
      if(tipo==POSITION_TYPE_BUY && candidato<entrada) candidato=entrada;
      if(tipo==POSITION_TYPE_SELL && candidato>entrada) candidato=entrada;
      candidato=NormalizarPrecoTrailInteligenteFIX325(candidato,tipo);
      bool melhorou=(!trail.protecaoArmada || trail.stopPrecoFIX325<=0.0 ||
                     (tipo==POSITION_TYPE_BUY && candidato>trail.stopPrecoFIX325) ||
                     (tipo==POSITION_TYPE_SELL && candidato<trail.stopPrecoFIX325));
      if(melhorou)
      {
         armouAgora=!trail.protecaoArmada;
         moveuAgora=trail.protecaoArmada;
         trail.protecaoArmada=true;
         trail.stopPrecoFIX325=candidato;
         trail.distanciaAtualPontosFIX325=distancia;
         trail.degrauAtualFIX325=degrau;
         double protegidoPontos=(tipo==POSITION_TYPE_BUY ? (candidato-entrada)/_Point : (entrada-candidato)/_Point);
         double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
         trail.defesaAtual=(tickSize>0.0 && tickValue>0.0)
                            ? MathMax(0.0,protegidoPontos*_Point/tickSize*tickValue*volume)
                            : MathMax(0.0,protegidoPontos);
         trail.alertaToqueEmitidoFIX325=false;
         RegistrarLogValidacaoSistema(armouAgora ? "FIX325_TRAIL_INT_ARMADO" : "FIX325_TRAIL_INT_MOVEU",
            StringFormat("%s A%d | favor %.0f pts | degrau %d | stop %.0f | distancia %.0f pts | protegido %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,favorPontos,degrau,
                         trail.stopPrecoFIX325,distancia,PnlMoedaBRL(trail.defesaAtual)));
         if(g_trailInteligenteApitarFIX325)
            PlaySound("alert.wav");
      }
   }
   if(!trail.protecaoArmada || armouAgora || moveuAgora || trail.stopPrecoFIX325<=0.0)
      return false;
   bool tocou=(tipo==POSITION_TYPE_BUY
               ? atual<=trail.stopPrecoFIX325+(_Point*0.1)
               : atual>=trail.stopPrecoFIX325-(_Point*0.1));
   if(tocou && !trail.alertaToqueEmitidoFIX325)
   {
      trail.alertaToqueEmitidoFIX325=true;
      if(g_trailInteligenteApitarFIX325)
         PlaySound("alert.wav");
   }
   return tocou;
}

bool ProcessarTicketAumentoFIX281(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, ulong ticket, int nivel, double volume, double lucroTicket, EstadoTrailAumentoFIX281 &trail)
{
   if(ticket==0 || nivel<1 || nivel>5 || volume<=0.0)
      return false;
   if(!PositionSelectByTicket(ticket))
      return false;
   ulong identificador=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   if(trail.ticket!=ticket || trail.identificador!=identificador)
   {
      ResetarTrailAumentoFIX281(trail);
      trail.ticket=ticket;
      trail.identificador=identificador;
   }
   if(lucroTicket>trail.melhorLucro)
      trail.melhorLucro=lucroTicket;

   double alvo=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*volume;
   double lossIndividual=InpStopDinamicoHeadFIX359 ? 0.0 : MathAbs(InpLossAumentoPorContratoReaisFIX321)*volume;
   int idxRegra=nivel-1;
   double ativacaoUnitaria=MathAbs(InpTrailingAumentoAtivarReaisFIX281);
   double passoUnitario=MathAbs(InpTrailingAumentoPassoReaisFIX281);
   if(idxRegra>=0 && idxRegra<5)
   {
      if(g_aumentos[idxRegra].trailingAtivarReais>0.0) ativacaoUnitaria=g_aumentos[idxRegra].trailingAtivarReais;
      if(g_aumentos[idxRegra].trailingPassoReais>0.0) passoUnitario=g_aumentos[idxRegra].trailingPassoReais;
   }
   double ativacao=ativacaoUnitaria*volume;
   double passo=passoUnitario*volume;
   if(alvo<=0.0) alvo=100.0*volume;
   if(ativacao<=0.0) ativacao=20.0*volume;
   if(passo<=0.0) passo=5.0*volume;

   // FIX442: MOVEL e TRAIL sao individuais e lidos da janela A1-A5.
   // MOVEL=X/Y: ao atingir X por contrato, fixa defesa em Y por contrato.
   // TRAIL=X/Y: ao atingir X, defesa continua = melhor lucro - Y.
   double movelAtivarUnit=0.0;
   double movelDefenderUnit=0.0;
   if(idxRegra>=0 && idxRegra<5)
   {
      movelAtivarUnit=MathAbs(g_aumentos[idxRegra].movelAtivarReais);
      movelDefenderUnit=MathAbs(g_aumentos[idxRegra].movelDefenderReais);
   }
   double movelAtivar=movelAtivarUnit*volume;
   double movelDefender=movelDefenderUnit*volume;
   bool movelHabilitado=(movelAtivarUnit>0.0);
   bool armouMovelAgoraFIX397=false;
   if(movelHabilitado && !trail.movelArmadoFIX397 && trail.melhorLucro+0.0001>=movelAtivar)
   {
      trail.movelArmadoFIX397=true;
      trail.defesaMovelFIX397=movelDefender;
      armouMovelAgoraFIX397=true;
      RegistrarLogValidacaoSistema("FIX442_TICKET_MOVEL_ARMADO",
         StringFormat("%s A%d ticket %s | melhor %s | MOVEL %.2f/%.2f | defesa %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,IntegerToString((long)ticket),
                      PnlMoedaBRL(trail.melhorLucro),movelAtivarUnit,movelDefenderUnit,
                      PnlMoedaBRL(trail.defesaMovelFIX397)));
   }

   bool armouAgora=false;
   bool moveuAgora=false;
   bool tocouTrailInteligente=false;
   if(g_trailInteligenteLinhasAtivoFIX325)
      tocouTrailInteligente=AtualizarTrailInteligenteAumentoFIX325(estado,tipo,ticket,nivel,volume,trail,armouAgora,moveuAgora);
   else if(ativacaoUnitaria>0.0 && passoUnitario>0.0 && !trail.protecaoArmada && trail.melhorLucro+0.0001>=ativacao)
   {
      trail.protecaoArmada=true;
      trail.defesaAtual=NormalizeDouble(MathMax(0.0,trail.melhorLucro-passo),2);
      armouAgora=true;
      RegistrarLogValidacaoSistema("FIX442_TICKET_TRAIL_ARMADO",
         StringFormat("%s A%d ticket %s | melhor %s | TRAIL %.2f/%.2f continuo | defesa %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,IntegerToString((long)ticket),
                      PnlMoedaBRL(trail.melhorLucro),ativacaoUnitaria,passoUnitario,PnlMoedaBRL(trail.defesaAtual)));
   }
   if(!g_trailInteligenteLinhasAtivoFIX325 && trail.protecaoArmada)
   {
      double novaDefesa=NormalizeDouble(MathMax(0.0,trail.melhorLucro-passo),2);
      if(novaDefesa>trail.defesaAtual+0.0001)
      {
         trail.defesaAtual=novaDefesa;
         RegistrarLogValidacaoSistema("FIX442_TICKET_TRAIL_SUBIU",
            StringFormat("%s A%d melhor %s | defesa continua %s | distancia %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,
                         PnlMoedaBRL(trail.melhorLucro),PnlMoedaBRL(trail.defesaAtual),PnlMoedaBRL(passo)));
      }
   }

   string motivo="";
   if(lossIndividual>0.0 && lucroTicket<=-lossIndividual+0.0001)
      motivo="LOSS_INDIVIDUAL";
   else if(InpAumentoFecharNoAlvoFIX281 && lucroTicket+0.0001>=alvo)
      motivo="ALVO_FIXO";
   else if(trail.movelArmadoFIX397 && !trail.protecaoArmada && !armouMovelAgoraFIX397 &&
           lucroTicket<=trail.defesaMovelFIX397+0.0001)
      motivo="MOVEL_INDIVIDUAL_FIX442";
   else if(g_trailInteligenteLinhasAtivoFIX325 && tocouTrailInteligente)
      motivo="TRAIL_INTELIGENTE_LINHA";
   else if(!g_trailInteligenteLinhasAtivoFIX325 && trail.protecaoArmada && !armouAgora && lucroTicket<=trail.defesaAtual+0.0001)
      motivo="TRAIL_CONTINUO_INDIVIDUAL_FIX442";
   if(motivo=="")
      return false;

   // FIX296: registrar a pendencia ANTES do OrderSend. Assim um deal confirmado muito rapido
   // ja encontra POSITION_IDENTIFIER, nivel e ticket preparados no OnTradeTransaction.
   p.parcialPendente=true;
   p.ticketParcialPendente=ticket;
   p.identificadorParcialPendente=identificador;
   p.nivelAumentoPendente=nivel;
   p.valorNominalParcialPendente=NormalizeDouble(MathMax(0.0,lucroTicket),2);
   p.horaParcialPendente=TimeCurrent();
   if(FecharTicketAumentoFIX207(estado,ticket,volume,nivel,lucroTicket,motivo))
   {
      RegistrarLogValidacaoSistema("FIX296_AUMENTO_SAIDA_ENVIADA",
         StringFormat("%s A%d %s | atual %s | melhor %s | defesa %s | alvo %s | loss -%s | volume %.2f | aguardando confirmacao do servidor.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,motivo,PnlMoedaBRL(lucroTicket),
                      PnlMoedaBRL(trail.melhorLucro),
                      PnlMoedaBRL(trail.protecaoArmada ? trail.defesaAtual : trail.defesaMovelFIX397),
                      PnlMoedaBRL(alvo),PnlMoedaBRL(lossIndividual),volume));
      return true;
   }
   p.parcialPendente=false;
   p.ticketParcialPendente=0;
   p.identificadorParcialPendente=0;
   p.nivelAumentoPendente=0;
   p.valorNominalParcialPendente=0.0;
   p.horaParcialPendente=0;
   return false;
}

void CalcularAumentosAbertosLadoFIX281(EstadoLado &estado, double &volumeAberto, double &financeiroAberto, int &ticketsAbertos)
{
   volumeAberto=0.0;
   financeiroAberto=0.0;
   ticketsAbertos=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(estado.lado==LADO_COMPRA && tipo!=POSITION_TYPE_BUY)
         continue;
      if(estado.lado==LADO_VENDA && tipo!=POSITION_TYPE_SELL)
         continue;
      int nivel=NivelAumentoPosicaoFIX212(estado,ticket,PositionGetString(POSITION_COMMENT));
      if(nivel<=0)
         continue;
      double lucroServidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double lucroManual=LucroAbertoPosicaoSelecionada(tipo);
      financeiroAberto+=(InpLucroAbertoUsarCalculoManual?lucroManual:lucroServidor);
      volumeAberto+=PositionGetDouble(POSITION_VOLUME);
      ticketsAbertos++;
   }
   financeiroAberto=NormalizeDouble(financeiroAberto,2);
   volumeAberto=NormalizeDouble(volumeAberto,2);
}


bool GerenciarRealizacaoAumentosPorTicketFIX207(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo)
{
   if(!InpRealizarAumentosPorTicketFIX207)
      return false;
   if(p.parcialPendente)
   {
      int timeoutParcial=30;
      if(p.horaParcialPendente>0 && (TimeCurrent()-p.horaParcialPendente)>=timeoutParcial)
      {
         RegistrarLogValidacaoSistema("FIX251_PARCIAL_TIMEOUT_RECUPERADA",
            StringFormat("%s parcial pendente por %d s sem deal confirmado; liberando nova verificacao. Deal tardio ainda sera reconhecido pela tag PARCIAL.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",timeoutParcial));
         p.parcialPendente=false;
         p.ticketParcialPendente=0;
         p.identificadorParcialPendente=0;
         p.nivelAumentoPendente=0;
         p.valorNominalParcialPendente=0.0;
         p.horaParcialPendente=0;
      }
      else
         return false;
   }
   if(!estado.posicaoAberta)
      return false;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=tipo)
         continue;
      string comentario=PositionGetString(POSITION_COMMENT);
      int nivel=NivelAumentoPosicaoFIX212(estado,ticket,comentario);
      if(nivel<=0 || nivel>5)
         continue; // A0 continua com alvo/trailing da ponta; A1-A5 usam gestao individual FIX281.
      if(!PositionSelectByTicket(ticket))
         continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(volume<=0.0)
         continue;
      double lucroServidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double lucroManual=LucroAbertoPosicaoSelecionada(tipo);
      double lucroTicket=InpLucroAbertoUsarCalculoManual ? lucroManual : lucroServidor;
      int idx=nivel-1;
      bool saiu=false;
      if(tipo==POSITION_TYPE_BUY)
         saiu=ProcessarTicketAumentoFIX281(p,estado,tipo,ticket,nivel,volume,lucroTicket,g_trailAumentoBuy[idx]);
      else
         saiu=ProcessarTicketAumentoFIX281(p,estado,tipo,ticket,nivel,volume,lucroTicket,g_trailAumentoSell[idx]);
      if(saiu)
         return true; // uma saida por tick; espera confirmacao real do servidor.
   }
   return false;
}

string NomeRegimeCorredorFIX338(ENUM_REGIME_CORREDOR_FIX338 regime)
{
   if(regime==CORREDOR_FIX338_FORTE)  return "FORTE";
   if(regime==CORREDOR_FIX338_NEUTRO) return "NEUTRO";
   if(regime==CORREDOR_FIX338_VIRADA) return "VIRADA";
   return "AGUARDA";
}

bool CorredorAlvoPontaViraMarcoFIX338()
{
   return (InpCorredorLucroAtivo && InpCorredorAlvoPontaViraMarco);
}

bool CorredorMetaABViraMarcoFIX338()
{
   return (InpCorredorLucroAtivo && InpCorredorMetaABViraMarco);
}

ENUM_REGIME_CORREDOR_FIX338 AvaliarRegimeCorredorFIX338(long tipo,
                                                        int &favoraveis,
                                                        int &contrarios,
                                                        string &leitura)
{
   favoraveis=0;
   contrarios=0;
   bool compra=(tipo==POSITION_TYPE_BUY);
   bool hiloFavor=(compra ? g_mercado.hiloCompra : g_mercado.hiloVenda);
   bool hiloContra=(compra ? g_mercado.hiloVenda : g_mercado.hiloCompra);
   bool strFavor=(compra ? g_mercado.strCompra : g_mercado.strVenda);
   bool strContra=(compra ? g_mercado.strVenda : g_mercado.strCompra);
   // QTD+FIN formam um unico pilar: ambos precisam confirmar para ser forte;
   // ambos precisam falhar, com farol baixo, para contar como virada.
   bool volumeFavor=(g_mercado.volqCurvaOK && g_mercado.volfCurvaOK && g_mercado.volFarol>=1);
   bool volumeContra=(!g_mercado.volqCurvaOK && !g_mercado.volfCurvaOK && g_mercado.volFarol<=1);
   if(hiloFavor) favoraveis++;
   if(strFavor) favoraveis++;
   if(volumeFavor) favoraveis++;
   if(hiloContra) contrarios++;
   if(strContra) contrarios++;
   if(volumeContra) contrarios++;
   ENUM_REGIME_CORREDOR_FIX338 regime=CORREDOR_FIX338_NEUTRO;
   if(contrarios>=2)
      regime=CORREDOR_FIX338_VIRADA;
   else if(favoraveis>=3)
      regime=CORREDOR_FIX338_FORTE;
   leitura=StringFormat("TF %s | HiLo %s | STR %s | VOL Q+F %s | fav %d/3 | contra %d/3",
                        NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                        hiloFavor ? "FAVOR" : (hiloContra ? "CONTRA" : "NEUTRO"),
                        strFavor ? "FAVOR" : (strContra ? "CONTRA" : "NEUTRO"),
                        volumeFavor ? "FORTE" : (volumeContra ? "FRACO" : "NEUTRO"),
                        favoraveis,contrarios);
   return regime;
}

double CalcularPisoCorredorFIX338(double melhorLucro,
                                  double ativacao,
                                  double pisoInicial,
                                  double degrau,
                                  double folga)
{
   ativacao=MathAbs(ativacao);
   pisoInicial=MathMax(0.0,MathAbs(pisoInicial));
   degrau=MathAbs(degrau);
   folga=MathAbs(folga);
   if(ativacao<=0.0 || melhorLucro<ativacao)
      return 0.0;
   if(degrau<=0.0)
      degrau=20.0;
   if(folga<=0.0)
      folga=degrau;
   double quantidade=MathFloor(((melhorLucro-ativacao)+0.0000001)/degrau);
   if(quantidade<0.0)
      quantidade=0.0;
   double marco=ativacao+(quantidade*degrau);
   double piso=MathMax(pisoInicial,marco-folga);
   if(piso>melhorLucro)
      piso=melhorLucro;
   return NormalizeDouble(MathMax(0.0,piso),2);
}

bool ProcessarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, double lucroPonta, double volumePonta)
{
   if(volumePonta<=0.0001)
   {
      if(!p.parcialPendente)
      {
         ResetarEstadoPontaSimplesFIX195(p);
         estado.lucroProtegido=false;
         estado.valorDefendido=0.0;
         estado.melhorResultadoAberto=0.0;
         estado.modoLongo=false;
      }
      return false;
   }
   // FIX380: separa o resultado total do ciclo do lucro aberto usado pelo trailing.
   // O alvo pode considerar o ciclo, mas o TRAIL 20/5 usa exclusivamente a operacao aberta atual.
   double resultadoCiclo=ResultadoCicloPontaFIX207(tipo,lucroPonta);
   double resultadoTrail=lucroPonta;
   if(resultadoTrail>p.melhorLucro)
      p.melhorLucro=resultadoTrail;

   // FIX439: MOVEL 25/10, camada anterior ao TRAIL continuo 50/25.
   // +R$25 => defesa inicial em +R$10. A cada novo bloco de R$10, a defesa sobe R$10.
   // Ao chegar em +R$50, o trailing assume com distancia financeira de R$25.
   double movelInicioFIX395=MathAbs(InpMovelAtivarTicketReaisFIX395);
   double movelPassoFIX395=MathAbs(InpMovelPassoTicketReaisFIX395);
   if(movelInicioFIX395<=0.0) movelInicioFIX395=25.0;
   if(movelPassoFIX395<=0.0) movelPassoFIX395=10.0;
   bool armouMovelAgoraFIX395=false;
   if(!p.movelArmadoFIX395 && p.melhorLucro>=movelInicioFIX395)
   {
      p.movelArmadoFIX395=true;
      p.defesaMovelFIX395=10.0;
      armouMovelAgoraFIX395=true;
      RegistrarLogValidacaoSistema("FIX439_MOVEL_ARMADO",
         StringFormat("%s melhor %s atingiu MOVEL %s; defesa posicionada em +R$10. Passo %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                      PnlMoedaBRL(movelInicioFIX395),PnlMoedaBRL(movelPassoFIX395)));
   }
   if(p.movelArmadoFIX395)
   {
      double degrausMovelFIX395=MathFloor(((p.melhorLucro-movelInicioFIX395)+0.0000001)/movelPassoFIX395);
      if(degrausMovelFIX395<0.0) degrausMovelFIX395=0.0;
      double novaDefesaMovelFIX395=NormalizeDouble(10.0+(degrausMovelFIX395*movelPassoFIX395),2);
      if(novaDefesaMovelFIX395>p.defesaMovelFIX395)
      {
         p.defesaMovelFIX395=novaDefesaMovelFIX395;
         RegistrarLogValidacaoSistema("FIX395_MOVEL_SUBIU",
            StringFormat("%s melhor %s; defesa movel subiu para %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                         PnlMoedaBRL(p.defesaMovelFIX395)));
      }
   }
   bool usarCorredor=InpCorredorLucroAtivo;
   double inicio=usarCorredor ? MathAbs(InpCorredorAtivarReais) : MathAbs(g_entradaTrailingAtivarReaisEfetivo);
   double passo=usarCorredor ? MathAbs(InpCorredorDegrauReais) : MathAbs(g_entradaTrailingPassoReaisEfetivo);
   if(inicio<=0.0) inicio=15.0;
   if(passo<=0.0) passo=5.0;
   bool armouProtecaoAgora=false;
   if(!p.protecaoArmada && p.melhorLucro>=inicio)
   {
      p.protecaoArmada=true;
      p.defesaAtual=usarCorredor
                     ? MathMax(0.0,MathAbs(InpCorredorPisoInicialReais))
                     : MathMax(0.0,inicio-passo);
      armouProtecaoAgora=true;
      RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_ARMADO" : "FIX211_TRAIL_ARMADO",
         StringFormat("%s lucro aberto atingiu %s; %s armado em %s; defesa inicial %s. Parciais e rearme permanecem ativos.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                      usarCorredor ? "corredor inteligente" : "trailing por degrau",
                      PnlMoedaBRL(inicio),PnlMoedaBRL(p.defesaAtual)));
   }
   bool saidaTecnicaCorredor=false;
   string leituraCorredor="";
   if(p.protecaoArmada)
   {
      double novaDefesa=0.0;
      if(usarCorredor)
      {
         int favoraveis=0,contrarios=0;
         ENUM_REGIME_CORREDOR_FIX338 regimeAnterior=p.regimeCorredor;
         ENUM_REGIME_CORREDOR_FIX338 regime=AvaliarRegimeCorredorFIX338(tipo,favoraveis,contrarios,leituraCorredor);
         p.regimeCorredor=regime;
         datetime candleFechado=iTime(_Symbol,TimeframeFiltroAtualFIX255(),1);
         if(candleFechado>0 && candleFechado!=p.ultimoCandleCorredor)
         {
            p.ultimoCandleCorredor=candleFechado;
            if(regime==CORREDOR_FIX338_VIRADA)
               p.confirmacoesViradaCorredor++;
            else
               p.confirmacoesViradaCorredor=0;
         }
         double pisoInicial=MathAbs(InpCorredorPisoInicialReais);
         double folgaForte=MathAbs(InpCorredorFolgaForteReais);
         novaDefesa=CalcularPisoCorredorFIX338(p.melhorLucro,inicio,pisoInicial,passo,folgaForte);
         if(regime==CORREDOR_FIX338_NEUTRO)
            novaDefesa=MathMax(novaDefesa,p.melhorLucro-MathAbs(InpCorredorFolgaNeutraReais));
         else if(regime==CORREDOR_FIX338_VIRADA)
            novaDefesa=MathMax(novaDefesa,p.melhorLucro-MathAbs(InpCorredorFolgaViradaReais));
         novaDefesa=NormalizeDouble(MathMax(0.0,MathMin(p.melhorLucro,novaDefesa)),2);
         int confirmacoesNecessarias=MathMax(1,InpCorredorConfirmacoesVirada);
         saidaTecnicaCorredor=(regime==CORREDOR_FIX338_VIRADA &&
                               p.confirmacoesViradaCorredor>=confirmacoesNecessarias);
         if(regime!=regimeAnterior)
         {
            RegistrarLogValidacaoSistema("FIX338_CORREDOR_REGIME",
               StringFormat("%s corredor %s -> %s | %s | defesa atual %s.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",
                            NomeRegimeCorredorFIX338(regimeAnterior),
                            NomeRegimeCorredorFIX338(regime),
                            leituraCorredor,PnlMoedaBRL(p.defesaAtual)));
         }
      }
      else
         novaDefesa=CalcularDefesaDegrauFIX281(p.melhorLucro,inicio,passo);
      if(novaDefesa>p.defesaAtual)
      {
         p.defesaAtual=novaDefesa;
         RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_SUBIU" : "FIX211_TRAIL_SUBIU",
            StringFormat("%s melhor %s; nova defesa %s%s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),
                         usarCorredor ? " | "+NomeRegimeCorredorFIX338(p.regimeCorredor)+" | "+leituraCorredor : ""));
      }
   }
   estado.lucroProtegido=p.protecaoArmada;
   estado.valorDefendido=p.defesaAtual;
   estado.melhorResultadoAberto=p.melhorLucro;
   estado.modoLongo=(usarCorredor && p.protecaoArmada);
   if(usarCorredor && p.protecaoArmada)
      estado.ultimaMensagem=StringFormat("CORREDOR %s | total %s | melhor %s | piso %s | virada %d/%d | %s",
                                         NomeRegimeCorredorFIX338(p.regimeCorredor),
                                         PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),
                                         p.confirmacoesViradaCorredor,MathMax(1,InpCorredorConfirmacoesVirada),
                                         NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));

   // FIX403: NAO usa o zero agregado da cesta.
   // Cada aumento A1-A4 e acompanhado pelo lucro do proprio ticket em ProcessarTicketAumentoFIX281.
   // Ao devolver ate sua defesa individual, fecha somente aquele ticket; o deal confirma a parcial
   // e o fluxo FIX248 rearma somente o nivel realizado para permitir nova entrada pelos filtros.

   // FIX439: antes de o TRAIL 50/25 armar, o MOVEL 25/10 preserva pelo menos +R$10.
   if(p.movelArmadoFIX395 && !p.protecaoArmada && !armouMovelAgoraFIX395 &&
      resultadoTrail<=p.defesaMovelFIX395+0.01)
   {
      string motivoMovelFIX395=(tipo==POSITION_TYPE_BUY?"MOVEL25_10_BUY_FIX439":"MOVEL25_10_SELL_FIX439");
      bool okMovelFIX395=FecharPosicoesLado(estado,motivoMovelFIX395);
      if(okMovelFIX395)
      {
         RegistrarLogValidacaoSistema("FIX395_MOVEL_DISPARADO",
            StringFormat("%s atual %s <= defesa movel %s | melhor %s | fechamento enviado. TRAIL 50/25 permanece independente.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaMovelFIX395),PnlMoedaBRL(p.melhorLucro)));
         return true;
      }
      RegistrarLogValidacaoSistema("FIX395_MOVEL_RETRY",
         StringFormat("%s tocou defesa movel %s com atual %s; envio falhou e sera repetido no proximo Timer.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.defesaMovelFIX395),PnlMoedaBRL(resultadoTrail)));
   }

   // FIX394: o trailing financeiro tem prioridade absoluta.
   // Assim, quando o lucro volta ao piso protegido, nenhuma parcial, aumento ou gain concorrente
   // consegue atrasar o fechamento. Esta rotina roda pelo Timer de 1 segundo.
   if(p.protecaoArmada && !armouProtecaoAgora && resultadoTrail<=p.defesaAtual+0.01)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX394_TRAIL_PRIORIDADE",
            "Trailing sobrepos parcial pendente; fechamento local tem prioridade absoluta.");
      string motivoTrailFIX394=(usarCorredor
                                ? (tipo==POSITION_TYPE_BUY?"CORREDOR_PISO_BUY_FIX394":"CORREDOR_PISO_SELL_FIX394")
                                : (tipo==POSITION_TYPE_BUY?"TRAIL20_5_BUY_FIX394":"TRAIL20_5_SELL_FIX394"));
      bool okTrailFIX394=FecharPosicoesLado(estado,motivoTrailFIX394);
      if(okTrailFIX394)
      {
         RegistrarLogValidacaoSistema("FIX394_TRAIL_DISPARADO",
            StringFormat("%s | atual %s <= defesa %s | melhor %s | ativa %s | passo %s | fechamento enviado pelo Timer.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(p.melhorLucro),
                         PnlMoedaBRL(inicio),PnlMoedaBRL(passo)));
         return true;
      }
      RegistrarLogValidacaoSistema("FIX394_TRAIL_RETRY",
         StringFormat("%s tocou defesa %s com atual %s, mas envio falhou; nova tentativa no proximo Timer.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(resultadoTrail)));
   }

   if(GerenciarRealizacaoAumentosPorTicketFIX207(p,estado,tipo))
      return true;
   double lossLocal=InpStopDinamicoHeadFIX359 ? 0.0 : MathAbs(InpLossEntradaLocalReaisFIX321);
   if(lossLocal>0.0 && resultadoCiclo<=-lossLocal)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Loss local sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"LOSS_LOCAL_BUY_FIX321":"LOSS_LOCAL_SELL_FIX321");
      if(ok)
      {
         RegistrarLogValidacaoSistema("FIX321_LOSS_ENTRADA_LOCAL",
            StringFormat("%s local %s atingiu LOSS -%s; fechando somente o Magic local, sem usar o lado oposto.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(lossLocal)));
         return true;
      }
   }
   double metaFinal=MathAbs(InpEntradaGanhoAlvoReais);
   if(metaFinal>0.0 && resultadoCiclo>=metaFinal)
   {
      if(CorredorAlvoPontaViraMarcoFIX338() && p.protecaoArmada)
      {
         if(!p.alvoMarcoCorredorRegistrado)
         {
            p.alvoMarcoCorredorRegistrado=true;
            RegistrarLogValidacaoSistema("FIX338_ALVO_VIROU_MARCO",
               StringFormat("%s atingiu o alvo %s; nao fecha: corredor continua sem teto | melhor %s | piso %s.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(metaFinal),
                            PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual)));
         }
      }
      else
      {
         bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"GAIN_PONTA_BUY_FIX207":"GAIN_PONTA_SELL_FIX207");
         if(ok)
         {
            RegistrarLogValidacaoSistema("FIX207_GAIN_PONTA",
               StringFormat("%s ciclo %s atingiu gain %s; fechando somente o Magic local.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(metaFinal)));
            return true;
         }
      }
   }
   if(!InpRealizarAumentosPorTicketFIX207)
   {
      if(p.proximaRealizacao<=0.0)
         p.proximaRealizacao=(InpRealizacaoPrimeiraReais>0.0?InpRealizacaoPrimeiraReais:10.0);
      if(!p.parcialPendente && resultadoCiclo>=p.proximaRealizacao && volumePonta>1.0001)
      {
         double qtd=MathAbs(InpRealizacaoContratos);
         if(qtd<=0.0) qtd=1.0;
         bool ok=FecharParcialPosicoesLado(estado,qtd,tipo==POSITION_TYPE_BUY?"PARCIAL_SIMPLES_BUY_FIX207":"PARCIAL_SIMPLES_SELL_FIX207");
         if(ok)
         {
            p.parcialPendente=true;
            p.horaParcialPendente=TimeCurrent();
            double passoFallback=MathAbs(InpRealizacaoPassoReais);
            if(passoFallback<=0.0) passoFallback=10.0;
            p.proximaRealizacao+=passoFallback;
            return true;
         }
      }
   }
   if(usarCorredor && p.protecaoArmada && !armouProtecaoAgora && saidaTecnicaCorredor)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Virada do corredor sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"CORREDOR_VIRADA_BUY_FIX338":"CORREDOR_VIRADA_SELL_FIX338");
      if(ok)
      {
         RegistrarLogValidacaoSistema("FIX338_CORREDOR_SAIDA_TECNICA",
            StringFormat("%s encerrou por virada confirmada %d/%d candles | total %s | melhor %s | piso %s | %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",p.confirmacoesViradaCorredor,
                         MathMax(1,InpCorredorConfirmacoesVirada),PnlMoedaBRL(resultadoCiclo),
                         PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),leituraCorredor));
         return true;
      }
   }
   // FIX394: bloco legado mantido apenas como referencia; a execucao ocorre antes das parciais.
   if(false && p.protecaoArmada && !armouProtecaoAgora && resultadoTrail<=p.defesaAtual)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Piso financeiro sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,
                                usarCorredor
                                ? (tipo==POSITION_TYPE_BUY?"CORREDOR_PISO_BUY_FIX338":"CORREDOR_PISO_SELL_FIX338")
                                : (tipo==POSITION_TYPE_BUY?"PROTECAO_SIMPLES_BUY_FIX207":"PROTECAO_SIMPLES_SELL_FIX207"));
      if(ok)
      {
         RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_PISO" : "FIX211_TRAIL_DISPARADO",
            StringFormat("%s lucro aberto voltou para %s; defesa %s; melhor aberto %s; fechando somente a ponta local.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(p.melhorLucro)));
         return true;
      }
   }
   return false;
}

bool ProcessarPontaSimplesFIX195(long tipo,double lucroPonta,double volumePonta)
{
   if(tipo==POSITION_TYPE_BUY) return ProcessarEstadoPontaSimplesFIX195(g_simplesBuy, g_compra, tipo, lucroPonta, volumePonta);
   if(tipo==POSITION_TYPE_SELL) return ProcessarEstadoPontaSimplesFIX195(g_simplesSell, g_venda, tipo, lucroPonta, volumePonta);
   return false;
}


bool ProcessarGerenciamentoSimplesInstanciaFIX255()
{
   AtualizarCicloMestreSimplesFIX195();
   ResetarCicloMestreSimplesFIX195SeFlat();
   if(!g_cicloMestreSimplesAtivo)
      return false;

   double qBuy=0.0,qSell=0.0,qTotal=0.0,aBuy=0.0,aSell=0.0,aTotal=0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qBuy,qSell,qTotal,aBuy,aSell,aTotal);

   bool saiuLocal=false;
   if(JanelaAtualEhA_FIX255())
      saiuLocal=ProcessarPontaSimplesFIX195(POSITION_TYPE_BUY,g_compra.resultadoAberto,g_compra.contratos);
   else
      saiuLocal=ProcessarPontaSimplesFIX195(POSITION_TYPE_SELL,g_venda.resultadoAberto,g_venda.contratos);
   if(saiuLocal)
      return true;

   // FIX320: no modo LADO, esta instancia encerra aqui. Resultado, meta,
   // stop e reentrada do Magic oposto nao participam de nenhuma decisao.
   if(!RiscoOperacaoModoCesta())
   {
      g_mestre.mensagemGeral=StringFormat("%s INDEPENDENTE | Magic %d | aberto %s",
                                          NomeJanelaInstanciaFIX255(),
                                          (int)MagicOperacionalInstanciaFIX255(),
                                          PnlMoedaBRL(JanelaAtualEhA_FIX255() ? g_compra.resultadoAberto : g_venda.resultadoAberto));
      return false;
   }

   g_totalCicloMestreSimples=aBuy+aSell+g_parciaisCicloBuy+g_parciaisCicloSell;
   if(CorredorMetaABViraMarcoFIX338() && g_cestaMetaMarcoCorredorFIX338)
      g_mestre.mensagemGeral=StringFormat("FIX338 %s | CORREDOR A+B %s | MELHOR %s | PISO %s | SEM TETO",
                                          NomeJanelaInstanciaFIX255(),PnlMoedaBRL(g_totalCicloMestreSimples),
                                          PnlMoedaBRL(g_cestaMelhorSaldoLiquido),PnlMoedaBRL(g_cestaDefesaCurtaAB));
   else
      g_mestre.mensagemGeral=StringFormat("FIX256 %s | TOTAL A+B %s / META %s",
                                          NomeJanelaInstanciaFIX255(),
                                          PnlMoedaBRL(g_totalCicloMestreSimples),
                                          PnlMoedaBRL(InpMetaMestreABReais));

   // Somente a Janela A envia o fechamento global; a B apenas acompanha o total no painel.
   if(!InstanciaMestreGrupoFIX255())
      return false;

   double meta=MathAbs(InpMetaMestreABReais);
   if(!CorredorMetaABViraMarcoFIX338() && meta>0.0 && !g_fechamentoMestreSimplesPendente && g_totalCicloMestreSimples>=meta)
   {
      g_fechamentoMestreSimplesPendente=true;
      RegistrarLogValidacaoSistema("FIX256_META_MESTRE",
         StringFormat("Janela A coordenadora: total %s >= meta %s.",
                      PnlMoedaBRL(g_totalCicloMestreSimples),PnlMoedaBRL(meta)));
      bool ok=FecharCestaABOficial("META_MESTRE_FIX255_JANELA_A");
      if(!ok)
         g_fechamentoMestreSimplesPendente=false;
      return ok;
   }
   return false;
}


void DispararMsgBoxVisualFIX226(string titulo, string linha1, string linha2)
{
   // FIX415: nenhuma caixa visual. Mantém auditoria somente nos logs Experts.
   if(titulo!="" || linha1!="" || linha2!="")
      Print("[COPA_AR100][FIX415][AUDITORIA_SEM_MSGBOX] ",titulo," | ",linha1," | ",linha2);
   g_msgBoxVisualHoraFIX226=0;
   g_msgBoxVisualTituloFIX226="";
   g_msgBoxVisualLinha1FIX226="";
   g_msgBoxVisualLinha2FIX226="";
}

bool MsgBoxVisualAtivaFIX226()
{
   // FIX415: desligada de forma definitiva para impedir amarelo/pisca no painel.
   return false;
}

void LimparMsgBoxVisualFIX226(string pfx)
{
   ObjectDelete(0,pfx+"_BG");
   ObjectDelete(0,pfx+"_TIT");
   ObjectDelete(0,pfx+"_MSG");
   ObjectDelete(0,pfx+"_SCORE");
}

void AvaliarEventoMsgBoxFIX226(string contexto, string mensagem, bool importante)
{
   // FIX408: nenhuma entrada, aumento, parcial, saída, stop ou proteção gera
   // caixa visual temporária. O processamento e os logs permanecem ativos.
   return;
}

void AtualizarEstadoFimDiaFIX215()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   dt.hour=0;
   dt.min=0;
   dt.sec=0;
   datetime inicioDia=StructToTime(dt);
   if(g_fimDiaDataReferenciaFIX215==inicioDia)
      return;
   g_fimDiaDataReferenciaFIX215=inicioDia;
   g_fimDiaUltimaTentativaFIX215=0;
   g_fimDiaEncerradoFIX215=false;
   g_fimDiaAvisoBloqueioFIX215=false;
   g_msgBoxVisualHoraFIX226=0;
   g_msgBoxVisualTituloFIX226="";
   g_msgBoxVisualLinha1FIX226="";
   g_msgBoxVisualLinha2FIX226="";
}

bool BloquearNovasOperacoesFimDiaFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!InpFechamentoFimDiaAtivo)
      return false;
   int minutoBloqueio=HorarioParaMinutos(InpHorarioBloquearNovasOperacoes);
   int minutoAgora=MinutoAtualDoDia();
   return (minutoAgora>=minutoBloqueio);
}

bool HorarioFechamentoObrigatorioFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!InpFechamentoFimDiaAtivo)
      return false;
   int minutoFechamento=HorarioParaMinutos(InpHorarioFecharTudo);
   int minutoAgora=MinutoAtualDoDia();
   return (minutoAgora>=minutoFechamento);
}

string TextoStatusFimDiaFIX215()
{
   if(!InpFechamentoFimDiaAtivo)
      return "FIM DIA OFF";
   if(HorarioFechamentoObrigatorioFIX215())
      return g_fimDiaEncerradoFIX215 ? "DIA ENCERRADO | ZERADO" : "FECHANDO TUDO AGORA";
   if(BloquearNovasOperacoesFimDiaFIX215())
      return StringFormat("NOVAS ORDENS BLOQUEADAS | FECHA %s",InpHorarioFecharTudo);
   return StringFormat("OPERA ATE %s | FECHA %s",InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
}

string ChaveControleMagicFIX285(long magic)
{
   return StringFormat("AR5CTL_%I64d_%s_%I64d",
                       AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       magic);
}

long MagicControleLocalFIX285()
{
   return MagicOperacionalInstanciaFIX255();
}

string ChaveControleOperacaoFIX284()
{
   return ChaveControleMagicFIX285(MagicControleLocalFIX285());
}

string NomeLadoControleMagicFIX285(long magic)
{
   if(magic == MagicCompraAtual())
      return "COMPRA";
   if(magic == MagicVendaAtual())
      return "VENDA";
   return "MAGIC " + IntegerToString((int)magic);
}

ENUM_CONTROLE_OPERACAO_FIX284 EstadoControleMagicFIX285(long magic)
{
   if(magic == MagicControleLocalFIX285())
   {
      SincronizarControleOperacaoFIX284(false);
      return g_controleOperacaoFIX284;
   }

   string chave = ChaveControleMagicFIX285(magic);
   if(!GlobalVariableCheck(chave))
   {
      GlobalVariableSet(chave, (double)CONTROLE_OPERACAO_ATIVO_FIX284);
      return CONTROLE_OPERACAO_ATIVO_FIX284;
   }

   int valor = (int)MathRound(GlobalVariableGet(chave));
   if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
      valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
   return (ENUM_CONTROLE_OPERACAO_FIX284)valor;
}

bool ControleBloqueiaMagicFIX285(long magic)
{
   return (EstadoControleMagicFIX285(magic) != CONTROLE_OPERACAO_ATIVO_FIX284);
}

string TextoControleMagicFIX285(long magic)
{
   ENUM_CONTROLE_OPERACAO_FIX284 estado = EstadoControleMagicFIX285(magic);
   string lado = NomeLadoControleMagicFIX285(magic);
   if(estado == CONTROLE_OPERACAO_PAUSADO_FIX284)
      return lado + " PAUSADA";
   if(estado == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return lado + " ENCERRADA";
   return lado + " ATIVA";
}

string TextoControleOperacaoFIX284()
{
   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_PAUSADO_FIX284)
      return lado + " PAUSADA";
   if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return lado + " ENCERRADA";
   return lado + " ATIVA";
}

bool ExistePosicaoAbertaControleLocalFIX285()
{
   long magicLocal = MagicControleLocalFIX285();
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) == magicLocal)
         return true;
   }
   return false;
}

bool FecharPosicoesControleLocalFIX285(string motivo)
{
   AtualizarEstadosDePosicao();
   long magicLocal = MagicControleLocalFIX285();
   EstadoLado estadoLocal;
   if(JanelaAtualEhA_FIX255())
      estadoLocal = g_compra;
   else
      estadoLocal = g_venda;

   // Botao de encerramento e uma saida de seguranca: tenta fechar mesmo se entradas estiverem travadas.
   // Se o terminal/servidor nao permitir negociacao, o proprio OrderSend retorna o erro no log.
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estadoLocal))
         continue;

      long tipo = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         continue;

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action = TRADE_ACTION_DEAL;
      req.position = ticket;
      req.symbol = _Symbol;
      req.volume = NormalizarVolume(volume);
      req.magic = (ulong)magicLocal;
      req.deviation = InpDesvioMaximoPontos;
      req.type_time = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " ENCERRAR LOCAL " + motivo,req.magic);

      if(tipo == POSITION_TYPE_BUY)
      {
         req.type = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(tipo == POSITION_TYPE_SELL)
      {
         req.type = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;

      encontrou = true;
      ResetLastError();
      bool enviado = OrderSend(req, res);
      if(enviado && (res.retcode == TRADE_RETCODE_DONE ||
                     res.retcode == TRADE_RETCODE_PLACED ||
                     res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         RegistrarGerenciadorOrdens(estadoLocal, "FIX285_ENCERRAR_LOCAL_OK",
                                    StringFormat("Magic %d | Ticket %I64u | Volume %.2f | %s",
                                                 (int)magicLocal, ticket, req.volume, motivo),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int erro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estadoLocal, "FIX285_ENCERRAR_LOCAL_ERRO",
                                    StringFormat("Magic %d | Ticket %I64u | Retcode %d | Erro %d",
                                                 (int)magicLocal, ticket, (int)res.retcode, erro),
                                    res.retcode, erro, req.volume, req.price, true);
      }
   }
   return (!encontrou || tudoOk);
}

void InicializarControleOperacaoFIX284()
{
   string chave = ChaveControleOperacaoFIX284();
   if(GlobalVariableCheck(chave))
   {
      int valor = (int)MathRound(GlobalVariableGet(chave));
      if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
         valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
      g_controleOperacaoFIX284 = (ENUM_CONTROLE_OPERACAO_FIX284)valor;
   }
   else
   {
      g_controleOperacaoFIX284 = CONTROLE_OPERACAO_ATIVO_FIX284;
      GlobalVariableSet(chave, (double)g_controleOperacaoFIX284);
   }
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
   g_ultimaSincronizacaoControleMsFIX284 = GetTickCount64();
}

void SincronizarControleOperacaoFIX284(bool forcar)
{
   ulong agoraMs = GetTickCount64();
   if(!forcar && g_ultimaSincronizacaoControleMsFIX284 > 0 &&
      agoraMs >= g_ultimaSincronizacaoControleMsFIX284 &&
      (agoraMs - g_ultimaSincronizacaoControleMsFIX284) < 250)
      return;

   g_ultimaSincronizacaoControleMsFIX284 = agoraMs;
   string chave = ChaveControleOperacaoFIX284();
   if(!GlobalVariableCheck(chave))
   {
      GlobalVariableSet(chave, (double)g_controleOperacaoFIX284);
      return;
   }
   int valor = (int)MathRound(GlobalVariableGet(chave));
   if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
      valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
   g_controleOperacaoFIX284 = (ENUM_CONTROLE_OPERACAO_FIX284)valor;
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
}

void DefinirControleOperacaoFIX284(ENUM_CONTROLE_OPERACAO_FIX284 novoEstado, string motivo)
{
   g_controleOperacaoFIX284 = novoEstado;
   GlobalVariableSet(ChaveControleOperacaoFIX284(), (double)novoEstado);
   g_ultimaSincronizacaoControleMsFIX284 = GetTickCount64();
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
   g_ultimaAtualizacaoPainelVisual = 0;

   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   string mensagem = StringFormat("FIX285 CONTROLE %s | Magic %d | %s",
                                  g_statusControleOperacaoFIX284,
                                  (int)MagicControleLocalFIX285(),
                                  motivo);
   g_mestre.mensagemGeral = mensagem;
   RegistrarLogValidacaoSistema("FIX285_CONTROLE_LOCAL", mensagem);

   if(novoEstado == CONTROLE_OPERACAO_PAUSADO_FIX284)
      DispararMsgBoxVisualFIX226(lado + " PAUSADA", "NOVAS ENTRADAS E AUMENTOS DESTE LADO BLOQUEADOS", "TRAILING, ALVO, STOP E PARCIAIS CONTINUAM");
   else if(novoEstado == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      DispararMsgBoxVisualFIX226("ENCERRAR " + lado, "FECHANDO SOMENTE O MAGIC " + IntegerToString((int)MagicControleLocalFIX285()), "O OUTRO LADO CONTINUA NORMALMENTE");
   else
      DispararMsgBoxVisualFIX226(lado + " ATIVA", "NOVAS ENTRADAS E AUMENTOS DESTE LADO LIBERADOS", "O OUTRO LADO NAO FOI ALTERADO");
}



bool ProcessarEncerramentoManualFIX284(bool forcar)
{
   SincronizarControleOperacaoFIX284(false);
   if(g_controleOperacaoFIX284 != CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return false;

   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   if(!ExistePosicaoAbertaControleLocalFIX285())
   {
      g_statusControleOperacaoFIX284 = lado + " ENCERRADA | ZERADA";
      return false;
   }

   int intervalo = InpFIX284IntervaloFechamentoMs;
   if(intervalo < 500)
      intervalo = 500;
   ulong agoraMs = GetTickCount64();
   if(!forcar && g_ultimaTentativaEncerrarMsFIX284 > 0 &&
      agoraMs >= g_ultimaTentativaEncerrarMsFIX284 &&
      (agoraMs - g_ultimaTentativaEncerrarMsFIX284) < (ulong)intervalo)
      return true;

   g_ultimaTentativaEncerrarMsFIX284 = agoraMs;
   g_fechamentoManualEmAndamentoFIX284 = true;
   bool ok = FecharPosicoesControleLocalFIX285("BOTAO_ENCERRAR_LOCAL_FIX285");
   g_fechamentoManualEmAndamentoFIX284 = false;

   if(ok)
      g_mestre.mensagemGeral = StringFormat("FIX285: encerramento da %s enviado para o Magic %d; aguardando servidor.", lado, (int)MagicControleLocalFIX285());
   else
      g_mestre.mensagemGeral = StringFormat("FIX285: fechamento da %s ainda pendente; nova tentativa sera somente neste Magic.", lado);
   return true;
}

bool PainelCliqueControleOperacaoFIX284(string objeto)
{
   if(StringFind(objeto, "CTRL_PAUSA_FIX284") >= 0)
   {
      SincronizarControleOperacaoFIX284(true);
      if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ATIVO_FIX284)
      {
         DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_PAUSADO_FIX284, "clique no botao PAUSAR LOCAL");
      }
      else if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_PAUSADO_FIX284)
      {
         DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ATIVO_FIX284, "clique no botao RETOMAR LOCAL");
      }
      else
      {
         AtualizarEstadosDePosicao();
         if(ExistePosicaoAbertaControleLocalFIX285())
         {
            string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
            g_mestre.mensagemGeral = "FIX285: aguarde somente a " + lado + " ficar zerada antes de reativar.";
            DispararMsgBoxVisualFIX226("REATIVACAO LOCAL BLOQUEADA", "AINDA EXISTE POSICAO DESTE MAGIC", "O OUTRO LADO NAO INTERFERE NESTA REATIVACAO");
         }
         else
         {
            DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ATIVO_FIX284, "clique no botao REATIVAR LOCAL");
         }
      }
      return true;
   }

   if(StringFind(objeto, "CTRL_ENCERRAR_FIX284") >= 0)
   {
      DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ENCERRADO_FIX284, "clique no botao ENCERRAR LOCAL");
      AtualizarEstadosDePosicao();
      ProcessarEncerramentoManualFIX284(true);
      return true;
   }
   return false;
}

bool ProcessarFechamentoFimDiaFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!HorarioFechamentoObrigatorioFIX215())
      return false;

   if(!ExistePosicaoAbertaGrupoTotalAB())
   {
      if(!g_fimDiaEncerradoFIX215)
      {
         g_fimDiaEncerradoFIX215=true;
         g_mestre.mensagemGeral="FIX226 FIM DO DIA: todas as posicoes foram encerradas e o grupo esta zerado.";
         RegistrarLogValidacaoSistema("FIX226_FIM_DIA_ZERADO",g_mestre.mensagemGeral);
         DispararMsgBoxVisualFIX226(
            StringFormat("FIM DO DIA %s",InpHorarioFecharTudo),
            "POSICOES ENCERRADAS | GRUPO ZERADO",
            "DIA FINALIZADO | NOVAS ORDENS SO NO PROXIMO DIA");
      }
      return true;
   }

   int intervalo=InpFimDiaIntervaloTentativaSegundos;
   if(intervalo<1)
      intervalo=1;
   datetime agora=TimeCurrent();
   if(g_fimDiaUltimaTentativaFIX215>0 && (agora-g_fimDiaUltimaTentativaFIX215)<intervalo)
      return true;

   g_fimDiaUltimaTentativaFIX215=agora;
   g_mestre.mensagemGeral=StringFormat("FIX226 FIM DO DIA: fechando todos os tickets. Limite %s.",InpHorarioFecharTudo);
   RegistrarLogValidacaoSistema("FIX226_FIM_DIA_FECHAR_TUDO",g_mestre.mensagemGeral);
   FecharCestaABOficial("FIM_DIA_FIX215_1815");
   return true;
}


string RegimeDXFIX411(double forcaMax)
{
   if(forcaMax>=86.0) return "EXPLOSAO";
   if(forcaMax>=71.0) return "MUITO FORTE";
   if(forcaMax>=51.0) return "FORTE";
   if(forcaMax>=31.0) return "NORMAL";
   return "FRACO";
}

int MinutoHorarioTextoFIX411(string hhmm)
{
   string p[];
   if(StringSplit(hhmm,':',p)<2) return 565;
   return (int)StringToInteger(p[0])*60+(int)StringToInteger(p[1]);
}

void LimparPlotagemDXAdaptativoFIX411()
{
   ObjectDelete(0,"COPA_FIX411_DX_SUP");
   ObjectDelete(0,"COPA_FIX411_DX_INF");
   ObjectDelete(0,"COPA_FIX411_DX_MEDIA");
   ObjectDelete(0,"COPA_FIX411_DX_STATUS");
}

void CriarLinhaDXFIX411(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura)
{
   if(preco<=0.0) return;
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_HLINE,0,0,preco);
   ObjectSetDouble(0,nome,OBJPROP_PRICE,preco);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,estilo);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,nome,OBJPROP_BACK,true);
}

void AtualizarPlotagemDXAdaptativoFIX411()
{
   if(!InpDXAdaptativoAtivoFIX410 || !InpDXPlotarBandasFIX410 || g_dxMediaAtualFIX411<=0.0)
   {
      LimparPlotagemDXAdaptativoFIX411();
      return;
   }
   CriarLinhaDXFIX411("COPA_FIX411_DX_MEDIA",g_dxMediaAtualFIX411,clrWhite,STYLE_SOLID,2);
   CriarLinhaDXFIX411("COPA_FIX411_DX_SUP",g_dxBandaSuperiorFIX411,clrGold,STYLE_DOT,1);
   CriarLinhaDXFIX411("COPA_FIX411_DX_INF",g_dxBandaInferiorFIX411,clrDeepSkyBlue,STYLE_DOT,1);
   string txt=StringFormat("DX %.0fP | FC %.0f | FV %.0f | %s",g_dxDistanciaAtualPtsFIX411,g_dxForcaCompraFIX411,g_dxForcaVendaFIX411,g_dxRegimeFIX411);
   if(ObjectFind(0,"COPA_FIX411_DX_STATUS")<0)
      ObjectCreate(0,"COPA_FIX411_DX_STATUS",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_XDISTANCE,20);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_YDISTANCE,75);
   ObjectSetString(0,"COPA_FIX411_DX_STATUS",OBJPROP_TEXT,txt);
   ObjectSetString(0,"COPA_FIX411_DX_STATUS",OBJPROP_FONT,"Consolas");
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_SELECTABLE,false);
}

void AtualizarDXAdaptativoFIX411(bool forcar)
{
   if(!InpDXAdaptativoAtivoFIX410)
   {
      g_dxDadosProntosFIX411=false;
      LimparPlotagemDXAdaptativoFIX411();
      return;
   }
   ENUM_TIMEFRAMES tf=PERIOD_M1;
   datetime barra=iTime(_Symbol,tf,0);
   if(!forcar && barra>0 && barra==g_dxUltimoCalculoBarraFIX411)
   {
      AtualizarPlotagemDXAdaptativoFIX411();
      return;
   }
   int periodo=MathMax(2,InpDXMediaPeriodoFIX411);
   int amostra=MathMax(5,InpDXAmostraCandlesFIX411);
   int necessario=periodo+amostra+5;
   if(Bars(_Symbol,tf)<necessario)
   {
      g_dxDadosProntosFIX411=false;
      g_dxRegimeFIX411="CALCULANDO";
      AtualizarPlotagemDXAdaptativoFIX411();
      return;
   }
   int h=iMA(_Symbol,tf,periodo,0,InpDXMediaMetodoFIX411,InpDXMediaPrecoFIX411);
   if(h==INVALID_HANDLE) return;
   double ma[];
   ArraySetAsSeries(ma,true);
   int cop=CopyBuffer(h,0,0,amostra+3,ma);
   IndicatorRelease(h);
   if(cop<amostra+2) return;
   double soma=0.0,maxDist=0.0;
   int usados=0;
   for(int i=1;i<=amostra;i++)
   {
      double c=iClose(_Symbol,tf,i);
      if(c<=0.0 || ma[i]<=0.0) continue;
      double d=MathAbs(c-ma[i])/_Point;
      soma+=d;
      if(d>maxDist) maxDist=d;
      usados++;
   }
   if(usados<MathMin(amostra,10)) return;
   double mediaDist=soma/(double)usados;
   g_dxMediaAtualFIX411=ma[0];

   double peso=100.0/6.0;
   double fc=0.0,fv=0.0;
   if(g_mercado.hiloCompra) fc+=peso;
   if(g_mercado.hiloVenda) fv+=peso;
   if(g_mercado.strCompra) fc+=peso;
   if(g_mercado.strVenda) fv+=peso;
   double o1=iOpen(_Symbol,tf,1),c1=iClose(_Symbol,tf,1);
   bool alta=(c1>o1),baixa=(c1<o1);
   if(g_mercado.volqRatioCandle>=1.0 || g_mercado.volqCurvaOK)
   {
      if(alta) fc+=peso; else if(baixa) fv+=peso;
   }
   if(g_mercado.volfRatioCandle>=1.0 || g_mercado.volfCurvaOK)
   {
      if(alta) fc+=peso; else if(baixa) fv+=peso;
   }
   if(g_mercado.rsi>=70.0) fc+=peso;
   if(g_mercado.rsi<=30.0) fv+=peso;
   int shiftInclinacao=MathMin(amostra,3);
   double inclinacao=(ma[1]-ma[shiftInclinacao])/_Point;
   if(inclinacao>0.0) fc+=peso;
   if(inclinacao<0.0) fv+=peso;
   g_dxForcaCompraFIX411=MathMin(100.0,fc);
   g_dxForcaVendaFIX411=MathMin(100.0,fv);
   double forcaMax=MathMax(fc,fv);
   g_dxRegimeFIX411=RegimeDXFIX411(forcaMax);

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   int minuto=dt.hour*60+dt.min;
   int corte=MinutoHorarioTextoFIX411(InpDXHorarioInicioAutoFIX411);
   if(minuto<corte)
      g_dxDistanciaAtualPtsFIX411=MathMax(1.0,InpDXManualAberturaPontosFIX411);
   else
   {
      double pctMin=MathMax(0.0,MathMin(100.0,InpDXPercentualExtremoMinFIX411));
      double pctMax=MathMax(pctMin,MathMin(150.0,InpDXPercentualExtremoMaxFIX411));
      double pct=pctMin+(pctMax-pctMin)*(forcaMax/100.0);
      double extremo=maxDist*(pct/100.0);
      g_dxDistanciaAtualPtsFIX411=MathMax(mediaDist,extremo);
   }
   g_dxBandaSuperiorFIX411=g_dxMediaAtualFIX411+g_dxDistanciaAtualPtsFIX411*_Point;
   g_dxBandaInferiorFIX411=g_dxMediaAtualFIX411-g_dxDistanciaAtualPtsFIX411*_Point;
   // O toque e memorizado continuamente, mesmo antes de A0/A1-A4 chegarem ao ultimo filtro.
   double bidFIX411=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double askFIX411=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(bidFIX411>0.0 && bidFIX411<=g_dxBandaInferiorFIX411)
   {
      g_dxToqueCompraA0FIX411=true;
      g_dxBarraToqueCompraA0FIX411=barra;
      for(int nivelFIX417=0;nivelFIX417<4;nivelFIX417++)
      {
         g_dxToqueCompraAumFIX417[nivelFIX417]=true;
         g_dxBarraToqueCompraAumFIX417[nivelFIX417]=barra;
      }
   }
   if(askFIX411>0.0 && askFIX411>=g_dxBandaSuperiorFIX411)
   {
      g_dxToqueVendaA0FIX411=true;
      g_dxBarraToqueVendaA0FIX411=barra;
      for(int nivelFIX417=0;nivelFIX417<4;nivelFIX417++)
      {
         g_dxToqueVendaAumFIX417[nivelFIX417]=true;
         g_dxBarraToqueVendaAumFIX417[nivelFIX417]=barra;
      }
   }
   g_dxDadosProntosFIX411=true;
   g_dxUltimoCalculoBarraFIX411=barra;
   AtualizarPlotagemDXAdaptativoFIX411();
   PrintFormat("[COPA_AR100][FIX411][DX_CALC] MEDIA=%.0f | MEDIA_DIST=%.0fP | MAX_DIST=%.0fP | DX=%.0fP | FC=%.0f | FV=%.0f | REGIME=%s",
               g_dxMediaAtualFIX411,mediaDist,maxDist,g_dxDistanciaAtualPtsFIX411,fc,fv,g_dxRegimeFIX411);
}

bool DXAdaptativoAutorizaFIX411(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento,string &detalhe)
{
   detalhe="";
   int idxDXFIX417=nivelAumento;
   if(aumento && (idxDXFIX417<0 || idxDXFIX417>=4))
   {
      detalhe="DX AUMENTO: NIVEL INVALIDO";
      return false;
   }
   if(!InpDXAdaptativoAtivoFIX410)
   {
      detalhe="DX OFF";
      return true;
   }
   AtualizarDXAdaptativoFIX411(false);
   if(!g_dxDadosProntosFIX411)
   {
      detalhe="DX CALCULANDO; USA MANUAL/AGUARDA DADOS";
      return false;
   }
   bool compra=(lado==LADO_COMPRA);
   double forcaContra=compra ? g_dxForcaVendaFIX411 : g_dxForcaCompraFIX411;
   if(forcaContra>=InpDXForcaBloqueioContraFIX411)
   {
      detalhe=StringFormat("REGIME %s | FORCA CONTRARIA %.0f >= %.0f | CONTRA BLOQUEADA",g_dxRegimeFIX411,forcaContra,InpDXForcaBloqueioContraFIX411);
      return false;
   }
   double preco=compra ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   datetime barra0=iTime(_Symbol,PERIOD_M1,0);
   bool tocou=false;
   datetime toque=0,liberado=0;
   if(!aumento && compra){ tocou=g_dxToqueCompraA0FIX411; toque=g_dxBarraToqueCompraA0FIX411; liberado=g_dxLiberadoCompraA0FIX411; }
   if(!aumento && !compra){ tocou=g_dxToqueVendaA0FIX411; toque=g_dxBarraToqueVendaA0FIX411; liberado=g_dxLiberadoVendaA0FIX411; }
   if(aumento && compra){ tocou=g_dxToqueCompraAumFIX417[idxDXFIX417]; toque=g_dxBarraToqueCompraAumFIX417[idxDXFIX417]; liberado=g_dxLiberadoCompraAumFIX417[idxDXFIX417]; }
   if(aumento && !compra){ tocou=g_dxToqueVendaAumFIX417[idxDXFIX417]; toque=g_dxBarraToqueVendaAumFIX417[idxDXFIX417]; liberado=g_dxLiberadoVendaAumFIX417[idxDXFIX417]; }

   if(!tocou)
   {
      bool atingiu=compra ? (preco<=g_dxBandaInferiorFIX411) : (preco>=g_dxBandaSuperiorFIX411);
      if(atingiu)
      {
         tocou=true; toque=barra0;
         if(!aumento && compra){g_dxToqueCompraA0FIX411=true;g_dxBarraToqueCompraA0FIX411=barra0;}
         if(!aumento && !compra){g_dxToqueVendaA0FIX411=true;g_dxBarraToqueVendaA0FIX411=barra0;}
         if(aumento && compra){g_dxToqueCompraAumFIX417[idxDXFIX417]=true;g_dxBarraToqueCompraAumFIX417[idxDXFIX417]=barra0;}
         if(aumento && !compra){g_dxToqueVendaAumFIX417[idxDXFIX417]=true;g_dxBarraToqueVendaAumFIX417[idxDXFIX417]=barra0;}
         PrintFormat("[COPA_AR100][FIX411][DX_TOQUE] TIPO=%s | LADO=%s | PRECO=%.0f | BANDA=%.0f | DX=%.0fP",
                     aumento?StringFormat("A%d",idxDXFIX417+1):"A0",compra?"COMPRA":"VENDA",preco,compra?g_dxBandaInferiorFIX411:g_dxBandaSuperiorFIX411,g_dxDistanciaAtualPtsFIX411);
      }
      detalhe=StringFormat("AGUARDA TOQUE DX %s %.0f | PRECO %.0f",compra?"INF":"SUP",compra?g_dxBandaInferiorFIX411:g_dxBandaSuperiorFIX411,preco);
      return false;
   }

   if(forcaContra>InpDXForcaLiberacaoFIX411)
   {
      detalhe=StringFormat("DX TOCADO | AGUARDA PERDA FORCA %.0f <= %.0f",forcaContra,InpDXForcaLiberacaoFIX411);
      return false;
   }
   datetime barraFechada=iTime(_Symbol,PERIOD_M1,1);
   double ma1=g_dxMediaAtualFIX411;
   int h=iMA(_Symbol,PERIOD_M1,MathMax(2,InpDXMediaPeriodoFIX411),0,InpDXMediaMetodoFIX411,InpDXMediaPrecoFIX411);
   if(h!=INVALID_HANDLE)
   {
      double m[]; ArraySetAsSeries(m,true);
      if(CopyBuffer(h,0,1,1,m)>0) ma1=m[0];
      IndicatorRelease(h);
   }
   double high1=iHigh(_Symbol,PERIOD_M1,1),low1=iLow(_Symbol,PERIOD_M1,1),close1=iClose(_Symbol,PERIOD_M1,1);
   bool retorno=compra ? (high1>=ma1 && close1>ma1) : (low1<=ma1 && close1<ma1);
   bool tempoConfirmado=InpDXEntradaProximoCandleFIX411 ? (barraFechada>toque) : (barraFechada>=toque);
   if(retorno && tempoConfirmado)
   {
      if(!aumento && compra) g_dxLiberadoCompraA0FIX411=barra0;
      if(!aumento && !compra) g_dxLiberadoVendaA0FIX411=barra0;
      if(aumento && compra) g_dxLiberadoCompraAumFIX417[idxDXFIX417]=barra0;
      if(aumento && !compra) g_dxLiberadoVendaAumFIX417[idxDXFIX417]=barra0;
      liberado=barra0;
      PrintFormat("[COPA_AR100][FIX411][DX_RETORNO_MEDIA] TIPO=%s | LADO=%s | CLOSE=%.0f | MEDIA=%.0f | PROXIMO_CANDLE_LIBERADO",
                  aumento?StringFormat("A%d",idxDXFIX417+1):"A0",compra?"COMPRA":"VENDA",close1,ma1);
   }
   bool autorizado=(liberado>0); // FIX417: permanece autorizado ate a ordem ser aceita e o sinal ser consumido
   if(autorizado)
   {
      detalhe=StringFormat("DX OK | %s | FORCA CONTRA %.0f | DX %.0fP | ENTRADA PROXIMO CANDLE",g_dxRegimeFIX411,forcaContra,g_dxDistanciaAtualPtsFIX411);
      // FIX417: nao consumir aqui. O sinal permanece valido se RSI, volume, risco, preco ou envio bloquearem.
      // O consumo ocorre somente depois que a ordem for aceita pelo servidor.
      return true;
   }
   detalhe=StringFormat("DX TOCADO | FORCA %.0f | AGUARDA RETORNO/FECHAMENTO NA MEDIA %.0f",forcaContra,ma1);
   return false;
}

void ConsumirSinalDXAposOrdemFIX417(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento)
{
   bool compra=(lado==LADO_COMPRA);
   if(!aumento)
   {
      if(compra){ g_dxToqueCompraA0FIX411=false; g_dxLiberadoCompraA0FIX411=0; g_dxBarraToqueCompraA0FIX411=0; }
      else      { g_dxToqueVendaA0FIX411=false;  g_dxLiberadoVendaA0FIX411=0;  g_dxBarraToqueVendaA0FIX411=0; }
      PrintFormat("[COPA_AR100][FIX417][DX_CONSUMIDO] TIPO=A0 | LADO=%s | MOTIVO=ORDEM_ACEITA",compra?"COMPRA":"VENDA");
      return;
   }
   if(nivelAumento<0 || nivelAumento>=4) return;
   if(compra)
   {
      g_dxToqueCompraAumFIX417[nivelAumento]=false;
      g_dxLiberadoCompraAumFIX417[nivelAumento]=0;
      g_dxBarraToqueCompraAumFIX417[nivelAumento]=0;
   }
   else
   {
      g_dxToqueVendaAumFIX417[nivelAumento]=false;
      g_dxLiberadoVendaAumFIX417[nivelAumento]=0;
      g_dxBarraToqueVendaAumFIX417[nivelAumento]=0;
   }
   PrintFormat("[COPA_AR100][FIX417][DX_CONSUMIDO] TIPO=A%d | LADO=%s | MOTIVO=ORDEM_ACEITA",nivelAumento+1,compra?"COMPRA":"VENDA");
}

void OnTick()
{
   FIX433RegistrarTick();
   CanaisProcessarTick();
   ulong inicioFIX302=GetMicrosecondCount();
   ProcessarOnTickMotorFIX302();
   ulong fimFIX302=GetMicrosecondCount();
   AuditoriaRegistrarTempoTickFIX302(fimFIX302>=inicioFIX302 ? fimFIX302-inicioFIX302 : 0);
   AuditoriaAtualizarCicloFIX302();
}

void ProcessarOnTickMotorFIX302()
{
   g_ultimoTickRecebidoMsFIX283=GetTickCount64();
   ReaplicarParametrosAntesDoGrafico("TICK_FIX283");
   AtualizarCoordenacaoMagicsFIX256(false);
   SincronizarMagicParametros(false);
   AtualizarNovoCandle();
   // FIX287: indicadores/filtros nao precisam ser recalculados centenas de vezes por segundo.
   // A gestao financeira de alvo, stop e trailing continua executando abaixo em TODO tick.
   ulong agoraMercadoMsFIX287=GetTickCount64();
   int intervaloMercadoMsFIX287=InpFIX287MercadoIntervaloMinimoMs;
   if(intervaloMercadoMsFIX287<20) intervaloMercadoMsFIX287=20;
   if(!InpFIX287UltraLeve || g_novoCandle || g_ultimaAtualizacaoMercadoMsFIX287==0 ||
      agoraMercadoMsFIX287<g_ultimaAtualizacaoMercadoMsFIX287 ||
      (agoraMercadoMsFIX287-g_ultimaAtualizacaoMercadoMsFIX287)>=(ulong)intervaloMercadoMsFIX287)
   {
      g_ultimaAtualizacaoMercadoMsFIX287=agoraMercadoMsFIX287;
      AtualizarMercado();
      AtualizarDXAdaptativoFIX411(g_novoCandle);
   }
   // A carga historica dos candles coloridos fica somente no Timer; no OnTick ela varria ObjectsTotal.
   AtualizarCandlesContraFIX258(false);
   AtualizarEstadosDePosicao();
   GarantirStopsServidorFIX342(false);
   int intervaloParABMsFIX287=500;
   if(!InpFIX287UltraLeve || g_ultimaAtualizacaoParABMsFIX287==0 ||
      agoraMercadoMsFIX287<g_ultimaAtualizacaoParABMsFIX287 ||
      (agoraMercadoMsFIX287-g_ultimaAtualizacaoParABMsFIX287)>=(ulong)intervaloParABMsFIX287)
   {
      g_ultimaAtualizacaoParABMsFIX287=agoraMercadoMsFIX287;
      AtualizarEstadoParABFIX274();
   }
   if(JanelaAtualEhA_FIX255())
   {
      RecuperarRearmeSemEventoFIX452(g_compra);
      ProcessarRearmeDinamicoPendenteFIX248(g_compra);
   }
   else
   {
      RecuperarRearmeSemEventoFIX452(g_venda);
      ProcessarRearmeDinamicoPendenteFIX248(g_venda);
   }
   ResetarCicloCestaABQuandoFlat();
   AtualizarHistoricoObrigatorio();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AtualizarCamposFinanceirosCriticosFIX354(false);
   if(GerenciarStopDiaMestreFIX320())
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual=TimeCurrent();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(false);
      return;
   }
   ProcessarAtualizacaoHistoricoRapidaFIX227();
   LogCestaABDetalhado("TICK_FINANCEIRO_AB", false);
   LogHedgeCompleto("TICK_HEDGE_AB", "SNAPSHOT", "fotografia completa do grupo A+B", 0, 0, 0, 0, 0, 0.0, 0.0, false);
   LogStopFullHedgeAB("TICK_STOP_FULL_HEDGE_AB", false);
   if(ProcessarEncerramentoManualFIX284(false))
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      int intervaloPainelFIX284 = IntervaloPainelEfetivo();
      if(g_ultimaAtualizacaoPainelVisual == 0 ||
         (TimeCurrent() - g_ultimaAtualizacaoPainelVisual) >= intervaloPainelFIX284)
      {
         g_ultimaAtualizacaoPainelVisual = TimeCurrent();
         AtualizarPainelMestre();
      }
      return;
   }
   if(InstanciaMestreGrupoFIX255() && ProcessarFechamentoFimDiaFIX215())
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual=TimeCurrent();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(false);
      return;
   }
   if(BloquearNovasOperacoesFimDiaFIX215() && !g_fimDiaAvisoBloqueioFIX215)
   {
      g_fimDiaAvisoBloqueioFIX215=true;
      g_mestre.mensagemGeral=StringFormat("FIX215: novas entradas e aumentos bloqueados as %s. Operacao atual segue com os mesmos valores ate zerar; fechamento obrigatorio as %s.",InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
      RegistrarLogValidacaoSistema("FIX215_FIM_DIA_BLOQUEIO",g_mestre.mensagemGeral);
   }
   if(g_baseHistoricaSomenteExportarAtivo)
   {
      AtualizarRodapePainelRapido();
      return;
   }
   bool saidaCesta = false;
   bool saidaProtecaoCompra = false;
   bool saidaProtecaoVenda  = false;
   if(g_ambienteLiberado)
   {
      if(InpModoSimplesFIX195)
      {
         // FIX257: o modo simples tambem deve respeitar o STOP e o GAIN financeiros do grupo A+B.
         // Somente a Janela A coordena o fechamento global; a Janela B continua cuidando apenas do seu Magic.
         if(InstanciaMestreGrupoFIX255())
         {
            saidaCesta = GerenciarStopMovelCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarGainGlobalCestaAB();
         }
         if(!saidaCesta)
            saidaCesta = ProcessarGerenciamentoSimplesInstanciaFIX255();
      }
      else
      {
         // Funções que podem fechar o grupo A+B são coordenadas somente pela Janela A.
         if(InstanciaMestreGrupoFIX255())
         {
            saidaCesta = GerenciarProtecaoMaiorCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarParcialPorLinhaGraficoHeadAB();
            if(!saidaCesta)
               saidaCesta = GerenciarParcialProtecaoCurtaCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarLucroPontaGanhadoraHedgeAB();
            if(!saidaCesta)
               saidaCesta = GerenciarGainGlobalCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarStopMovelCestaAB();
         }
         if(!saidaCesta)
         {
            if(!(InpSaidaCestaABBloquearSaidaIsoladaQuandoDuasPontas && CestaABTemDuasPontasAbertasGrupo()))
            {
               if(JanelaAtualEhA_FIX255())
                  saidaProtecaoCompra = GerenciarProtecaoLado(g_compra);
               else
                  saidaProtecaoVenda = GerenciarProtecaoLado(g_venda);
            }
            else if(InstanciaMestreGrupoFIX255())
            {
               LogCestaABDetalhado("BLOQ_SAIDA_ISOLADA_DUAS_PONTAS", false);
               LogHedgeCompleto("BLOQ_SAIDA_ISOLADA_DUAS_PONTAS", "BLOQUEIO", "grupo tem compra e venda abertas; saída isolada por lado bloqueada", 0, 0, 0, 0, 0, 0.0, 0.0, false);
            }
         }
      }
   }
   if(!(saidaCesta || saidaProtecaoCompra || saidaProtecaoVenda) && !BloquearNovasOperacoesFimDiaFIX215())
   {
      if(InpAtivarRobo && g_ambienteLiberado)
      {
         // FIX361/FIX362: depois de ciclo lucrativo, a A0 desse lado pode ser
         // revalidada no proximo tick mesmo que o candle ainda seja o mesmo.
         ENUM_LADO_ROBO ladoLocalFIX255 = LadoOperacionalInstanciaFIX255();
         bool reentradaLucroLocalFIX362=(ladoLocalFIX255==LADO_VENDA
                                         ? g_venda.reentradaImediataAposLucro
                                         : g_compra.reentradaImediataAposLucro);
         bool liberarA0NesteTick = (!InpExecutarSomenteNovoCandleEntrada || g_novoCandle || reentradaLucroLocalFIX362);

         // FIX288: cada grafico envia e gerencia somente seu proprio lado.
         bool posicaoLocalAbertaFIX255 = JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
         bool ladoHabilitadoUsuarioFIX346=LadoHabilitadoUsuarioFIX346(ladoLocalFIX255);

         // FIX318: no modo LIVRE PROTEGIDA, a primeira A0 e tentada imediatamente no primeiro tick.
         // A protecao interna ainda impede duplicidade e nova A0 no mesmo candle depois de uma saida.
         if(EntradaDiretaDemoEfetivaFIX302() && !posicaoLocalAbertaFIX255 && ladoHabilitadoUsuarioFIX346)
         {
            ProcessarEntradaDiretaFIX279();
            AtualizarEstadosDePosicao();
            posicaoLocalAbertaFIX255 = JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
         }

         bool gerenciarLocalFIX255 = posicaoLocalAbertaFIX255 ||
                                     (!EntradaDiretaDemoEfetivaFIX302() && liberarA0NesteTick &&
                                      ladoHabilitadoUsuarioFIX346 &&
                                      TipoOperacaoPermiteLado(ladoLocalFIX255) &&
                                      LadoPermitidoPelaSelecaoHead(ladoLocalFIX255));
         if(gerenciarLocalFIX255)
            GerenciarLado(ladoLocalFIX255);
      }
   }
   int intervaloPainel = IntervaloPainelEfetivo();
   if(g_ultimaAtualizacaoPainelVisual == 0 ||
      (TimeCurrent() - g_ultimaAtualizacaoPainelVisual) >= intervaloPainel)
   {
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual = TimeCurrent();
      AtualizarPainelMestre();
   }
   else
   {
      AtualizarRodapePainelRapido();
   }
}

void AplicarAmbienteExecucaoFIX342()
{
   bool real=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   InpExigirContaDemo=!real;
   if(real)
   {
      // Em produção a auditoria antiga deixa de ser apenas informativa.
      InpAuditoriaTesteFIX274=true;
      InpBloquearOrdensSeAuditoriaFalharFIX274=true;
      int intervalo=InpIntervaloMinimoOrdensRealSegFIX342;
      if(intervalo<1) intervalo=1;
      if(InpIntervaloMinimoOrdensSeg<intervalo)
         InpIntervaloMinimoOrdensSeg=intervalo;
   }
}

bool ExecutarAuditoriaProducaoFIX342(string &detalhes)
{
   detalhes="";
   g_auditoriaProducaoOKFIX342=false;
   bool real=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   if(!real)
   {
      g_auditoriaProducaoOKFIX342=true;
      g_auditoriaProducaoStatusFIX342="DEMO | PRODUCAO NAO ARMADA";
      detalhes=g_auditoriaProducaoStatusFIX342;
      RegistrarLogValidacaoSistema("FIX342_AUDITORIA_DEMO",detalhes);
      return true;
   }

   int falhas=0;
   if(!InpConfirmarContaRealFIX342) { falhas++; detalhes+="CONFIRMACAO_REAL_OFF | "; }
   if(InpContaRealAutorizadaFIX342<=0) { falhas++; detalhes+="LOGIN_REAL_NAO_INFORMADO | "; }
   if(Trim(InpServidorRealAutorizadoFIX342)=="") { falhas++; detalhes+="SERVIDOR_REAL_NAO_INFORMADO | "; }
   if(InpComoAbrirPrimeiraOrdem!=PRIMEIRA_ORDEM_NORMAL) { falhas++; detalhes+="A0_NAO_E_NORMAL_COM_SINAIS | "; }
   if(InpCenarioAuditoriaFIX302!=AUD302_USAR_CONFIG_ATUAL) { falhas++; detalhes+="CENARIO_DE_TESTE_ATIVO | "; }
   if(EntradaDiretaDemoEfetivaFIX302() || InpTesteLivreEntradaA0) { falhas++; detalhes+="BYPASS_A0_ATIVO | "; }
   if(InpAumentosLivreTeste || InpAumentosLivreIgnorarTimerPreco) { falhas++; detalhes+="BYPASS_AUMENTOS_ATIVO | "; }
   if(!InpAuditoriaTesteFIX274 || !InpBloquearOrdensSeAuditoriaFalharFIX274 || !g_auditoriaTesteFIX274OK)
      { falhas++; detalhes+="AUDITORIA_BLOQUEANTE_NAO_APROVADA | "; }
   if(!InpStopServidorEmergenciaAtivoFIX342 || InpStopServidorEmergenciaPontosFIX342<=0.0)
      { falhas++; detalhes+="STOP_SERVIDOR_INVALIDO | "; }
   if(InpSpreadMaximoTicksFIX342<=0.0 || InpTickMaximoIdadeSegundosFIX342<1)
      { falhas++; detalhes+="QUALIDADE_COTACAO_INVALIDA | "; }
   if(InpMargemLivreMinimaReaisFIX342<0.0 || InpNivelMargemMinimoPercentFIX342<=0.0)
      { falhas++; detalhes+="LIMITE_MARGEM_INVALIDO | "; }
   if(InpMaxContratosBrutosABFIX342<=0.0)
      { falhas++; detalhes+="EXPOSICAO_AB_INVALIDA | "; }
   if(InpMaxExposicaoLiquidaABFIX342<=0.0 || InpMaxExposicaoLiquidaABFIX342>InpMaxContratosBrutosABFIX342)
      { falhas++; detalhes+="EXPOSICAO_LIQUIDA_INVALIDA | "; }
   if(InpFiltroRangeAtivoFIX344 &&
      (InpRangeMinimoPontosFIX344<0.0 || InpRangeMaximoPontosFIX344<=0.0 ||
       InpRangeMinimoPontosFIX344>InpRangeMaximoPontosFIX344))
      { falhas++; detalhes+="FILTRO_RANGE_INVALIDO | "; }
   if(InpGridEntradasAtivoFIX344 &&
      (InpGridTamanhoPontosFIX344<=0.0 || InpGridToleranciaPontosFIX344<0.0 ||
       InpGridToleranciaPontosFIX344>InpGridTamanhoPontosFIX344*0.5))
      { falhas++; detalhes+="GRID_ENTRADAS_INVALIDO | "; }
   if(!InpFechamentoFimDiaAtivo)
      { falhas++; detalhes+="FECHAMENTO_FIM_DIA_OFF | "; }

   g_auditoriaProducaoOKFIX342=(falhas==0);
   g_auditoriaProducaoStatusFIX342=g_auditoriaProducaoOKFIX342
      ? "REAL APROVADO PELA AUDITORIA"
      : StringFormat("REAL BLOQUEADO | %d FALHA(S) | %s",falhas,detalhes);
   detalhes=g_auditoriaProducaoStatusFIX342;
   RegistrarLogValidacaoSistema(g_auditoriaProducaoOKFIX342 ? "FIX342_AUDITORIA_REAL_OK" : "FIX342_AUDITORIA_REAL_FALHOU",detalhes);
   return g_auditoriaProducaoOKFIX342;
}

bool ValidarAmbienteConta()
{
   long tradeMode  = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   long marginMode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   g_loginContaAtual    = AccountInfoInteger(ACCOUNT_LOGIN);
   g_servidorContaAtual = AccountInfoString(ACCOUNT_SERVER);
   g_empresaContaAtual  = AccountInfoString(ACCOUNT_COMPANY);
   g_contaDemo  = (tradeMode == ACCOUNT_TRADE_MODE_DEMO);
   g_contaHedge = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   bool ambienteReal=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   if(!ambienteReal && !g_contaDemo)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = "BLOQUEADO: ambiente DEMO exige conta demonstrativa.";
      return false;
   }
   if(ambienteReal)
   {
      if(tradeMode!=ACCOUNT_TRADE_MODE_REAL)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: ambiente REAL exige conta real.";
         return false;
      }
      if(!InpConfirmarContaRealFIX342 || InpContaRealAutorizadaFIX342<=0 ||
         g_loginContaAtual!=InpContaRealAutorizadaFIX342)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente=StringFormat("BLOQUEADO: login REAL %I64d nao autorizado.",g_loginContaAtual);
         return false;
      }
      string servidorEsperado=Upper(Trim(InpServidorRealAutorizadoFIX342));
      if(servidorEsperado=="" || Upper(Trim(g_servidorContaAtual))!=servidorEsperado)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: servidor REAL diferente do autorizado.";
         return false;
      }
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: terminal sem conexao com o servidor real.";
         return false;
      }
   }
   if(!ambienteReal && InpTravarContaDemoAutorizada && InpContaDemoAutorizada > 0 && g_loginContaAtual != InpContaDemoAutorizada)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = StringFormat("BLOQUEADO: login %s diferente da conta demo autorizada %s.",
                                               IntegerToString((int)g_loginContaAtual),
                                               IntegerToString((int)InpContaDemoAutorizada));
      return false;
   }
   if(InpExigirContaHedge && !g_contaHedge)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = "BLOQUEADO: conta nao e HEDGE.";
      return false;
   }
   g_ambienteLiberado = true;
   g_mestre.mensagemAmbiente = StringFormat("AMBIENTE %s OK: %s | TF %s | HEDGING.",
                                             ambienteReal ? "REAL" : "DEMO",
                                             NomeJanelaInstanciaFIX255(),
                                             NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));
   return true;
}

bool ValidarTravasDeValidacaoInicial()
{
   g_bloqueioValidacaoInicial = false;
   g_posicaoInicialAssumida = false;
   if(!g_ambienteLiberado)
      return false;
   if(ExistePosicaoAR100Aberta())
   {
      if(InpBloquearSePosicaoInicial)
      {
         g_bloqueioValidacaoInicial = true;
         g_ambienteLiberado = false;
         g_mestre.mensagemAmbiente = "BLOQUEADO VALIDACAO: existe posicao AR_100 aberta. Para testar A0 puro, iniciar zerado.";
         if(InpGerenciadorOrdensExperts)
            Print("[COPA_AR100][VALIDACAO] BLOQUEADO: posicao inicial existente. Feche a posicao ou deixe InpBloquearSePosicaoInicial=false.");
         return false;
      }
      if(InpPermitirAssumirPosicaoInicial)
      {
         g_posicaoInicialAssumida = true;
         g_mestre.mensagemAmbiente = "VALIDACAO: posicao inicial AR_100 assumida. A0 nao duplica; aumentos seguem travados pelo modo de validacao.";
         if(InpGerenciadorOrdensExperts)
            Print("[COPA_AR100][VALIDACAO] POSICAO INICIAL ASSUMIDA | Compra=", DoubleToString(g_compra.contratos, 2),
                  " | B=", DoubleToString(g_venda.contratos, 2),
                  " | Modo=", TextoModoValidacaoExecucao(),
                  " | AumentosValidacao=", (InpPermitirAumentosNaValidacao ? "ON" : "OFF"));
      }
   }
   return true;
}

bool ExistePosicaoAR100Aberta()
{
   return (g_compra.posicaoAberta || g_venda.posicaoAberta);
}

bool PermitirEntradaA0PeloModoValidacao(EstadoLado &estado)
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS ||
      InpModoValidacaoExecucao == VALIDAR_A0_E_AUMENTOS ||
      InpModoValidacaoExecucao == OPERAR_COMPLETO)
      return true;
   RegistrarGerenciadorOrdens(estado, "VALIDACAO", "Entrada A0 bloqueada: modo de validacao invalido.", 0, 0, 0.0, 0.0, true);
   return false;
}

bool PermitirAumentoPeloModoValidacao(EstadoLado &estado, int idxAlvo)
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS)
   {
      RegistrarGerenciadorOrdens(estado, "VALIDACAO",
                                 StringFormat("Aumento A%d bloqueado: modo VALIDAR_A0_APENAS. Primeiro validar entrada A0 com 1 contrato.", idxAlvo + 1),
                                 0, 0, 0.0, 0.0, false);
      return false;
   }
   if(!InpPermitirAumentosNaValidacao && InpModoValidacaoExecucao != OPERAR_COMPLETO)
   {
      RegistrarGerenciadorOrdens(estado, "VALIDACAO",
                                 StringFormat("Aumento A%d bloqueado: InpPermitirAumentosNaValidacao=false.", idxAlvo + 1),
                                 0, 0, 0.0, 0.0, false);
      return false;
   }
   return true;
}

string TextoModoValidacaoExecucao()
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS)
      return "VALIDAR_A0_APENAS";
   if(InpModoValidacaoExecucao == VALIDAR_A0_E_AUMENTOS)
      return "VALIDAR_A0_E_AUMENTOS";
   if(InpModoValidacaoExecucao == OPERAR_COMPLETO)
      return "OPERAR_COMPLETO";
   return "MODO_INVALIDO";
}

string NomeTimeframeCurto(ENUM_TIMEFRAMES tf)
{
   string s = EnumToString(tf);
   StringReplace(s, "PERIOD_", "");
   return s;
}

void InicializarEstados()
{
   ZeroMemory(g_mercado);
   ZeroMemory(g_gerAumentos);
   ZeroMemory(g_scoreAumentos);
   ZeroMemory(g_risco);
   ZeroMemory(g_mestre);
   ZeroMemory(g_compra);
   ZeroMemory(g_venda);
   ZeroMemory(g_painelA);
   ZeroMemory(g_painelB);
   ZeroMemory(g_alvoLinhaAumentoBuy);
   ZeroMemory(g_alvoLinhaAumentoSell);
   ZeroMemory(g_precoRealizadoAumentoBuy);
   ZeroMemory(g_precoRealizadoAumentoSell);
   ZeroMemory(g_precoEntradaAumentoBuy);
   ZeroMemory(g_precoEntradaAumentoSell);
   g_precosAumentosRestauradosBuy=false;
   g_precosAumentosRestauradosSell=false;
   ZeroMemory(g_aumentoRealizadoBuy);
   ZeroMemory(g_aumentoRealizadoSell);
   g_compra.lado = LADO_COMPRA;
   g_compra.nome = "MOTOR_COMPRA";
   g_compra.magic = MagicCompraAtual();
   g_compra.tipoPosicaoAtual = -1;
   g_venda.lado = LADO_VENDA;
   g_venda.nome = "MOTOR_VENDA";
   g_venda.magic = MagicVendaAtual();
   g_venda.tipoPosicaoAtual = -1;
   PrepararSlotPainel(g_painelA, "A", MagicPainelAAtual(), LADO_COMPRA);
   PrepararSlotPainel(g_painelB, "B", MagicPainelBAtual(), LADO_VENDA);
}

bool AplicarMagicsCompactosFIX255(string &motivo)
{
   motivo = "";
   double valorA=0.0, valorB=0.0, valorExtra=0.0;
   int fimA=0, fimB=0, fimExtra=0;

   // FIX260: pode informar somente um Magic base.
   // Exemplo: 200100 gera automaticamente Compra=200100 e Venda=200101.
   if(!ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,0,valorA,fimA))
   {
      motivo = "Informe um Magic base (ex.: 147025) ou o par Compra/Venda (ex.: 147025 / 147026).";
      return false;
   }

   bool temMagicB=ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,fimA,valorB,fimB);
   if(temMagicB && ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,fimB,valorExtra,fimExtra))
   {
      motivo = "Foram encontrados mais de dois numeros na linha de Magics.";
      return false;
   }

   long magicA=(long)MathRound(valorA);
   if(MathAbs(valorA-(double)magicA)>0.000001)
   {
      motivo = "O Magic precisa ser um numero inteiro.";
      return false;
   }

   long magicB=0;
   if(temMagicB)
   {
      magicB=(long)MathRound(valorB);
      if(MathAbs(valorB-(double)magicB)>0.000001)
      {
         motivo = "Os Magics precisam ser numeros inteiros.";
         return false;
      }
   }
   else
   {
      if(magicA>=2147483647)
      {
         motivo = "O Magic base e muito alto para gerar automaticamente o Magic de venda.";
         return false;
      }
      magicB=magicA+1;
   }

   if(magicA<=0 || magicB<=0 || magicA>2147483647 || magicB>2147483647)
   {
      motivo = "Os Magics precisam ser inteiros positivos validos.";
      return false;
   }
   if(magicA==magicB)
   {
      motivo = "Compra e venda precisam usar numeros Magic diferentes.";
      return false;
   }

   // FIX412: respeita o Magic informado pelo usuario.
   // Um novo par de Magics possui historico, painel, posicoes e resultado isolados.
   InpMagicA=(int)magicA;
   InpMagicB=(int)magicB;
   Print("[COPA_AR100][FIX412][MAGIC_USUARIO] Compra=",IntegerToString(InpMagicA),
         " | Venda=",IntegerToString(InpMagicB),
         " | HISTORICO_ISOLADO=SIM");
   if(!temMagicB)
      Print("[COPA_AR100][FIX260][MAGIC_BASE] Base=",IntegerToString((int)magicA),
            " | Compra=",IntegerToString((int)magicA),
            " | Venda=",IntegerToString((int)magicB));
   return true;
}

long MagicCompraAtual()
{
   return (long)InpMagicA;
}

long MagicVendaAtual()
{
   return (long)InpMagicB;
}

long MagicPainelAAtual()
{
   return MagicCompraAtual();
}

long MagicPainelBAtual()
{
   return MagicVendaAtual();
}


bool JanelaAtualEhA_FIX255()
{
   return (InpJanelaDesteGrafico == JANELA_A_COMPRA);
}

bool JanelaAtualEhB_FIX255()
{
   return (InpJanelaDesteGrafico == JANELA_B_VENDA);
}

ENUM_LADO_ROBO LadoOperacionalInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? LADO_COMPRA : LADO_VENDA;
}

long MagicOperacionalInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? MagicCompraAtual() : MagicVendaAtual();
}

bool InstanciaGerenciaLadoFIX255(ENUM_LADO_ROBO lado)
{
   // FIX288: papel imutavel por janela.
   // JANELA A gerencia somente COMPRA; JANELA B gerencia somente VENDA.
   return (lado == LadoOperacionalInstanciaFIX255());
}

bool LadoHabilitadoUsuarioFIX346(ENUM_LADO_ROBO lado)
{
   if(InpLadosHabilitadosFIX346==OPERACAO_AMBOS)
      return (lado==LADO_COMPRA || lado==LADO_VENDA);
   if(InpLadosHabilitadosFIX346==OPERACAO_COMPRA)
      return (lado==LADO_COMPRA);
   if(InpLadosHabilitadosFIX346==OPERACAO_VENDA)
      return (lado==LADO_VENDA);
   return false;
}

string TextoLadosHabilitadosFIX346()
{
   if(InpLadosHabilitadosFIX346==OPERACAO_COMPRA) return "SOMENTE COMPRA";
   if(InpLadosHabilitadosFIX346==OPERACAO_VENDA)  return "SOMENTE VENDA";
   return "COMPRA + VENDA";
}

bool InstanciaMestreGrupoFIX255()
{
   // FIX342: A continua mestre preferencial. Se o heartbeat de A desaparecer,
   // B assume imediatamente a supervisão A+B e o fechamento de emergência.
   if(JanelaAtualEhA_FIX255())
      return true;
   long chartA=0;
   datetime heartbeatA=0;
   return !RegistroJanelaAtivoFIX256(true,chartA,heartbeatA);
}

string NomeJanelaInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? "JANELA A | SOMENTE COMPRA" : "JANELA B | SOMENTE VENDA";
}

ENUM_TIMEFRAMES TimeframeFiltroAtualFIX255()
{
   int tf=(int)InpTimeframeFiltrosOperacionais;
   if(tf!=(int)PERIOD_M5 && tf!=(int)PERIOD_M10)
      tf=(int)PERIOD_M5;
   return (ENUM_TIMEFRAMES)tf;
}

ENUM_TIMEFRAMES TimeframeEntradaAtualFIX255()
{
   return (ENUM_TIMEFRAMES)_Period;
}

string PrefixoCoordenacaoMagicsFIX256()
{
   string simbolo=_Symbol;
   StringReplace(simbolo,".","_");
   StringReplace(simbolo,"#","_");
   StringReplace(simbolo," ","_");
   StringReplace(simbolo,"/","_");
   StringReplace(simbolo,"\\","_");
   if(StringLen(simbolo)>14)
      simbolo=StringSubstr(simbolo,0,14);
   long login=AccountInfoInteger(ACCOUNT_LOGIN);
   // FIX320: versoes antigas abertas em outras abas nao podem conservar o
   // registro A/B desta versao e impedir o teste. Instancias FIX320 ainda
   // compartilham este prefixo, portanto somente uma COMPRA e uma VENDA
   // permanecem autorizadas por conta e ativo.
   return "AR320_"+IntegerToString(login)+"_"+simbolo+"_";
}

string ChaveCoordenacaoMagicsFIX256(string campo)
{
   return PrefixoCoordenacaoMagicsFIX256()+campo;
}

long AssinaturaConfiguracaoProducaoFIX342()
{
   string cfg=StringFormat("AMB=%d|SIDE=%d|A0=%d|MC=%d|MV=%d|TF=%d|Q=%d|MG=%d|MB=%d",
                           (int)InpAmbienteExecucaoFIX342,(int)InpLadosHabilitadosFIX346,(int)InpComoAbrirPrimeiraOrdem,
                           (int)InpModoEntradaCompra,(int)InpModoEntradaVenda,
                           (int)InpTimeframeFiltrosOperacionais,InpQuantidadeReforcos,
                           (int)MagicCompraAtual(),(int)MagicVendaAtual());
   cfg+="|A0E="+InpEntradaA0QuantidadeAlvoFIX340+"|A0R="+InpEntradaA0PerdaTrailingFIX340;
   cfg+="|AR="+InpRiscoAumentosFIX340+"|A1="+InpA1ExecucaoFIX340+InpA1TrailingFIX340;
   cfg+="|A2="+InpA2ExecucaoFIX340+InpA2TrailingFIX340+"|A3="+InpA3ExecucaoFIX340+InpA3TrailingFIX340;
   cfg+="|A4="+InpA4ExecucaoFIX340+InpA4TrailingFIX340+"|F="+InpFiltrosProjetoFIX324;
   cfg+=StringFormat("|GH=%.2f|LH=%.2f|SL=%.1f|MAX=%.2f|NET=%.2f|H=%s/%s",
                     GainHeadEfetivoFIX362(),LossHeadEfetivoFIX362(),
                     InpStopServidorEmergenciaPontosFIX342,InpMaxContratosBrutosABFIX342,InpMaxExposicaoLiquidaABFIX342,
                     InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
   cfg+=StringFormat("|R=%d/%d/%.1f/%.1f|G=%d/%d/%.1f/%.1f",
                     InpFiltroRangeAtivoFIX344 ? 1 : 0,(int)InpRangeReferenciaFIX344,
                     InpRangeMinimoPontosFIX344,InpRangeMaximoPontosFIX344,
                     InpGridEntradasAtivoFIX344 ? 1 : 0,(int)InpGridReferenciaFIX344,
                     InpGridTamanhoPontosFIX344,InpGridToleranciaPontosFIX344);
   return HashTextoFIX304(cfg);
}

bool ConfiguracaoParABCompativelFIX342(string &motivo)
{
   motivo="";
   string sufixoLocal=JanelaAtualEhA_FIX255() ? "A" : "B";
   string sufixoOutro=JanelaAtualEhA_FIX255() ? "B" : "A";
   long hashLocal=AssinaturaConfiguracaoProducaoFIX342();
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixoLocal+"CFG"),(double)hashLocal);

   long chartOutro=0;
   datetime hbOutro=0;
   bool outroAtivo=RegistroJanelaAtivoFIX256(!JanelaAtualEhA_FIX255(),chartOutro,hbOutro);
   if(!outroAtivo)
      return true;
   string chaveOutro=ChaveCoordenacaoMagicsFIX256(sufixoOutro+"CFG");
   if(!GlobalVariableCheck(chaveOutro))
   {
      motivo="outra janela ativa ainda nao publicou sua configuracao";
      return false;
   }
   long hashOutro=(long)GlobalVariableGet(chaveOutro);
   if(hashOutro!=hashLocal)
   {
      motivo=StringFormat("parametros A/B diferentes | local %I64d outro %I64d",hashLocal,hashOutro);
      return false;
   }
   return true;
}

datetime AgoraCoordenacaoMagicsFIX256()
{
   datetime agora=TimeLocal();
   if(agora<=0)
      agora=TimeCurrent();
   return agora;
}

bool RegistroJanelaAtivoFIX256(bool janelaA, long &chartId, datetime &heartbeat)
{
   chartId=0;
   heartbeat=0;
   string sufixo=janelaA ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   if(!GlobalVariableCheck(chaveChart) || !GlobalVariableCheck(chaveHB))
      return false;
   chartId=(long)GlobalVariableGet(chaveChart);
   heartbeat=(datetime)GlobalVariableGet(chaveHB);
   datetime agora=AgoraCoordenacaoMagicsFIX256();
   if(chartId<=0 || heartbeat<=0 || agora<heartbeat || (agora-heartbeat)>g_timeoutHeartbeatMagics_FIX256)
      return false;
   return true;
}

bool AdquirirLockCoordenacaoMagicsFIX256()
{
   string chaveLock=ChaveCoordenacaoMagicsFIX256("LOCK");
   string chaveHora=ChaveCoordenacaoMagicsFIX256("LTS");
   if(!GlobalVariableCheck(chaveLock))
      GlobalVariableSet(chaveLock,0.0);

   double token=(double)ChartID();
   datetime agora=AgoraCoordenacaoMagicsFIX256();

   // FIX283: recupera trava abandonada, mas nunca bloqueia a thread do EA com Sleep.
   if(GlobalVariableCheck(chaveHora))
   {
      datetime horaLock=(datetime)GlobalVariableGet(chaveHora);
      if(horaLock>0 && agora>=horaLock && (agora-horaLock)>5)
         GlobalVariableSet(chaveLock,0.0);
   }

   if(!GlobalVariableSetOnCondition(chaveLock,token,0.0))
      return false;

   GlobalVariableSet(chaveHora,(double)agora);
   return true;
}

void LiberarLockCoordenacaoMagicsFIX256()
{
   string chaveLock=ChaveCoordenacaoMagicsFIX256("LOCK");
   string chaveHora=ChaveCoordenacaoMagicsFIX256("LTS");
   double token=(double)ChartID();
   if(GlobalVariableCheck(chaveLock) && GlobalVariableGet(chaveLock)==token)
      GlobalVariableSet(chaveLock,0.0);
   GlobalVariableSet(chaveHora,0.0);
}

bool RegistrarCoordenacaoMagicsFIX256(string &motivo)
{
   motivo="";
   if(!AdquirirLockCoordenacaoMagicsFIX256())
   {
      motivo="Nao foi possivel obter a trava de sincronizacao dos Magics.";
      return false;
   }

   bool janelaA=JanelaAtualEhA_FIX255();
   long chartAtual=ChartID();
   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);

   if(janelaA && ativoA && chartA!=chartAtual)
   {
      motivo="Ja existe outra JANELA A/COMPRA ativa neste ativo e conta.";
      LiberarLockCoordenacaoMagicsFIX256();
      return false;
   }
   if(!janelaA && ativoB && chartB!=chartAtual)
   {
      motivo="Ja existe outra JANELA B/VENDA ativa neste ativo e conta.";
      LiberarLockCoordenacaoMagicsFIX256();
      return false;
   }

   string sufixo=janelaA ? "A" : "B";
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"CH"),(double)chartAtual);
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"HB"),(double)AgoraCoordenacaoMagicsFIX256());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"MA"),(double)MagicCompraAtual());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"MB"),(double)MagicVendaAtual());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"CFG"),(double)AssinaturaConfiguracaoProducaoFIX342());

   if(janelaA ||
      !GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("MA")) ||
      !GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("MB")))
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)MagicCompraAtual());
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)MagicVendaAtual());
   }

   LiberarLockCoordenacaoMagicsFIX256();
   AtualizarCoordenacaoMagicsFIX256(true);
   return true;
}

void AtualizarCoordenacaoMagicsFIX256(bool forcar)
{
   datetime agora=AgoraCoordenacaoMagicsFIX256();
   if(!forcar && g_ultimoHeartbeatMagics_FIX256>0 && (agora-g_ultimoHeartbeatMagics_FIX256)<1)
      return;
   g_ultimoHeartbeatMagics_FIX256=agora;

   bool janelaA=JanelaAtualEhA_FIX255();
   string sufixo=janelaA ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   string chaveMA=ChaveCoordenacaoMagicsFIX256(sufixo+"MA");
   string chaveMB=ChaveCoordenacaoMagicsFIX256(sufixo+"MB");
   string chaveCFG=ChaveCoordenacaoMagicsFIX256(sufixo+"CFG");

   bool donoRegistro=(GlobalVariableCheck(chaveChart) &&
                      (long)GlobalVariableGet(chaveChart)==ChartID());
   if(donoRegistro)
   {
      GlobalVariableSet(chaveHB,(double)agora);
      GlobalVariableSet(chaveMA,(double)MagicCompraAtual());
      GlobalVariableSet(chaveMB,(double)MagicVendaAtual());
      GlobalVariableSet(chaveCFG,(double)AssinaturaConfiguracaoProducaoFIX342());
   }

   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);

   bool parAExiste=(GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("AMA")) &&
                    GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("AMB")));
   bool parBExiste=(GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("BMA")) &&
                    GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("BMB")));
   long magicAA=parAExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("AMA")) : 0;
   long magicAB=parAExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("AMB")) : 0;
   long magicBA=parBExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("BMA")) : 0;
   long magicBB=parBExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("BMB")) : 0;

   if(ativoA && parAExiste)
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)magicAA);
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)magicAB);
   }
   else if(ativoB && parBExiste)
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)magicBA);
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)magicBB);
   }

   bool registroLocal=(janelaA ? (ativoA && chartA==ChartID()) : (ativoB && chartB==ChartID()));
   bool publicacaoLocalOK=(janelaA ?
                           (parAExiste && magicAA==MagicCompraAtual() && magicAB==MagicVendaAtual()) :
                           (parBExiste && magicBA==MagicCompraAtual() && magicBB==MagicVendaAtual()));
   bool paresIguais=(parAExiste && parBExiste && magicAA==magicBA && magicAB==magicBB);

   // FIX320: cada lado tem vida propria. A autorizacao local depende somente
   // do registro e dos Magics desta janela; o lado oposto nunca bloqueia.
   bool outraJanelaAtiva = janelaA ? ativoB : ativoA;
   bool parOutraExiste   = janelaA ? parBExiste : parAExiste;
   bool compatibilidadeOutra = true;
   g_coordenacaoMagicsOK_FIX256=(registroLocal && publicacaoLocalOK);

   if(g_coordenacaoMagicsOK_FIX256)
   {
      if(ativoA && ativoB)
         g_statusCoordenacaoMagics_FIX256=StringFormat("LADOS INDEPENDENTES | A=BUY M%d | B=SELL M%d",(int)MagicCompraAtual(),(int)MagicVendaAtual());
      else
         g_statusCoordenacaoMagics_FIX256=StringFormat("LOCAL OK | %s | outro lado opcional",NomeJanelaInstanciaFIX255());
   }
   else if(!registroLocal)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: ja existe outra janela com o mesmo papel A/B";
   else if(!publicacaoLocalOK)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: atualizando o novo Magic desta janela";
   else if(outraJanelaAtiva && !parOutraExiste)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: publicacao da outra janela incompleta";
   else if(outraJanelaAtiva && !paresIguais)
      g_statusCoordenacaoMagics_FIX256=StringFormat("BLOQUEADO: Magics diferentes | Janela A %d/%d | Janela B %d/%d",
                                                   (int)magicAA,(int)magicAB,(int)magicBA,(int)magicBB);
   else
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: sincronizacao local incompleta";
}

void DesregistrarCoordenacaoMagicsFIX256()
{
   if(!AdquirirLockCoordenacaoMagicsFIX256())
      return;

   string sufixo=JanelaAtualEhA_FIX255() ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   string chaveMA=ChaveCoordenacaoMagicsFIX256(sufixo+"MA");
   string chaveMB=ChaveCoordenacaoMagicsFIX256(sufixo+"MB");
   string chaveCFG=ChaveCoordenacaoMagicsFIX256(sufixo+"CFG");

   if(GlobalVariableCheck(chaveChart) && (long)GlobalVariableGet(chaveChart)==ChartID())
   {
      GlobalVariableDel(chaveChart);
      if(GlobalVariableCheck(chaveHB)) GlobalVariableDel(chaveHB);
      if(GlobalVariableCheck(chaveMA)) GlobalVariableDel(chaveMA);
      if(GlobalVariableCheck(chaveMB)) GlobalVariableDel(chaveMB);
      if(GlobalVariableCheck(chaveCFG)) GlobalVariableDel(chaveCFG);
   }

   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);
   if(!ativoA && !ativoB)
   {
      string chaves[6]={ChaveCoordenacaoMagicsFIX256("MA"),
                        ChaveCoordenacaoMagicsFIX256("MB"),
                        ChaveCoordenacaoMagicsFIX256("AMA"),
                        ChaveCoordenacaoMagicsFIX256("AMB"),
                        ChaveCoordenacaoMagicsFIX256("BMA"),
                        ChaveCoordenacaoMagicsFIX256("BMB")};
      for(int i=0;i<6;i++)
         if(GlobalVariableCheck(chaves[i])) GlobalVariableDel(chaves[i]);
   }

   LiberarLockCoordenacaoMagicsFIX256();
   g_coordenacaoMagicsOK_FIX256=false;
}

bool CoordenacaoPermiteNovaOrdemFIX256(EstadoLado &estado, string contexto)
{
   string motivoMagic="";
   if(!ValidarMagicsConfiguradosFIX252(motivoMagic))
   {
      RegistrarGerenciadorOrdens(estado,contexto,contexto+" bloqueado: "+motivoMagic,0,0,0.0,0.0,true);
      return false;
   }

   // FIX350: A0 LIVRE PROTEGIDA em DEMO nao depende do registro visual A/B.
   // Duas abas podem chegar aqui ao mesmo tempo, mas somente uma consegue adquirir
   // o lock global A0 por conta/simbolo/Magic antes do OrderSend.
   bool contextoA0DiretoFIX350=(StringFind(contexto,"A0 DIRETO")>=0);
   bool livreProtegidaDemoFIX350=(g_contaDemo && PrimeiraOrdemLivreProtegidaFIX314() &&
                                  EntradaDiretaDemoEfetivaFIX302() && contextoA0DiretoFIX350);
   if(livreProtegidaDemoFIX350)
      return true;

   AtualizarCoordenacaoMagicsFIX256(false);

   // FIX288: nunca ignorar a coordenacao no modo direto normal/real.
   // Uma unica janela local e permitida; duas janelas do mesmo papel ou pares diferentes sao bloqueados.
   if(g_coordenacaoMagicsOK_FIX256)
      return true;

   // No teste direto, uma aba proprietaria antiga nao pode parar o projeto.
   // A0 avanca protegida pelo lock global do Magic. A1-A5 chegam aqui apenas
   // depois de adquirir o lock global especifico do nivel/ciclo; portanto a
   // liberacao da suplente nao duplica contratos.
   bool contextoA0DiretoFIX322=(StringFind(contexto,"A0 DIRETO")>=0);
   bool contextoAumentoComLockFIX322=(StringFind(contexto,"Aumento A")>=0);
   bool mesmoPapelSuplenteFIX322=(StringFind(g_statusCoordenacaoMagics_FIX256,
                                             "mesmo papel A/B")>=0);
   // FIX322: A1-A5 ja chegam aqui com lock global do nivel/ciclo adquirido.
   // Liberar a janela que possui a posicao nao ignora timer, linha, candle ou filtros:
   // todas essas regras foram validadas antes de ExecutarAumento. O lock impede duplicidade.
   bool testeSuplenteProtegidoFIX320=(mesmoPapelSuplenteFIX322 &&
                                      ((EntradaDiretaDemoEfetivaFIX302() && contextoA0DiretoFIX322) ||
                                       contextoAumentoComLockFIX322));
   if(testeSuplenteProtegidoFIX320)
      return true;

   RegistrarGerenciadorOrdens(estado,contexto,
      contexto+" bloqueado: "+g_statusCoordenacaoMagics_FIX256,
      0,0,0.0,0.0,true);
   return false;
}

bool ValidarMagicsConfiguradosFIX252(string &motivo)
{
   long magicA = MagicCompraAtual();
   long magicB = MagicVendaAtual();
   motivo = "";
   if(magicA <= 0 || magicB <= 0)
   {
      motivo = StringFormat("Magic invalido: A=%d B=%d. Ambos precisam ser maiores que zero.", (int)magicA, (int)magicB);
      return false;
   }
   if(magicA == magicB)
   {
      motivo = StringFormat("Magic duplicado: A e B usam %d. Compra e venda precisam de identificadores diferentes.", (int)magicA);
      return false;
   }
   return true;
}


string ChaveIdentidadeBaseFIX304()
{
   string servidor=AccountInfoString(ACCOUNT_SERVER);
   string bruto=IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN))+"|"+servidor+"|"+_Symbol+"|"+
                IntegerToString((int)MagicCompraAtual())+"|"+IntegerToString((int)MagicVendaAtual());
   return "AR304_"+Base36FIX304(HashTextoFIX304(bruto),8);
}

string RecuperarGeracaoHistoricoFIX311()
{
   datetime fim=AgoraServidorHistorico()+86400;
   if(!HistorySelect(0,fim))
      return "";
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) continue;
      long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
      if(magic!=MagicCompraAtual() && magic!=MagicVendaAtual()) continue;
      string geracao=ExtrairGeracaoComentarioFIX304(HistoryDealGetString(deal,DEAL_COMMENT));
      if(geracao!="") return geracao;
   }
   return "";
}

string RecuperarGeracaoPosicoesFIX304()
{
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic!=MagicCompraAtual() && magic!=MagicVendaAtual() && magic!=MagicPainelAAtual() && magic!=MagicPainelBAtual()) continue;
      string g=ExtrairGeracaoComentarioFIX304(PositionGetString(POSITION_COMMENT));
      if(g!="") return g;
   }
   return "";
}

void InicializarIdentidadeUnicaFIX304()
{
   if(g_identidadeInicializadaFIX304) return;
   g_identidadeChaveBaseFIX304=ChaveIdentidadeBaseFIX304();
   g_identidadeChaveGeracaoFIX304=g_identidadeChaveBaseFIX304+"_GEN";
   g_identidadeChaveHeartbeatAFIX304=g_identidadeChaveBaseFIX304+"_HBA";
   g_identidadeChaveHeartbeatBFIX304=g_identidadeChaveBaseFIX304+"_HBB";
   g_identidadeGrupoFIX304="H"+Base36FIX304(HashTextoFIX304(g_identidadeChaveBaseFIX304),6);

   string manual=InpIDInstanciaRobo;
   StringTrimLeft(manual); StringTrimRight(manual);
   string recuperadaPosicao=RecuperarGeracaoPosicoesFIX304();
   long numeroPersistido=GlobalVariableCheck(g_identidadeChaveGeracaoFIX304)
                         ? (long)GlobalVariableGet(g_identidadeChaveGeracaoFIX304) : 0;

   if(manual!="")
   {
      numeroPersistido=HashTextoFIX304(manual+"|"+g_identidadeChaveBaseFIX304);
      g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
      GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }
   else if(numeroPersistido>0)
   {
      // FIX311: a geracao persistida e reutilizada mesmo quando as duas janelas e o MT5 foram fechados.
      g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
   }
   else if(recuperadaPosicao!="")
   {
      g_identidadeGeracaoFIX304=recuperadaPosicao;
      numeroPersistido=Base36ParaLongFIX311(recuperadaPosicao);
      if(numeroPersistido>0)
         GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }
   else
   {
      string recuperadaHistorico=RecuperarGeracaoHistoricoFIX311();
      if(recuperadaHistorico!="")
      {
         g_identidadeGeracaoFIX304=recuperadaHistorico;
         numeroPersistido=Base36ParaLongFIX311(recuperadaHistorico);
      }
      if(numeroPersistido<=0)
      {
         // Deterministico: mesma conta/servidor/simbolo/par de Magics recebe sempre a mesma identidade.
         numeroPersistido=HashTextoFIX304(g_identidadeChaveBaseFIX304+"|FIX311_ESTAVEL");
         g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
      }
      GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }

   g_identidadeInicializadaFIX304=true;
   AtualizarHeartbeatIdentidadeFIX304();
   g_identidadeCicloLocalFIX304=CicloAtualMagicFIX304(MagicOperacionalInstanciaFIX255(),false);
   Print("[AR100][FIX311][IDENTIDADE_ESTAVEL] grupo=",g_identidadeGrupoFIX304,
         " | geracao=",g_identidadeGeracaoFIX304,
         " | A=",IntegerToString((int)MagicCompraAtual()),
         " | B=",IntegerToString((int)MagicVendaAtual()),
         " | janela=",NomeJanelaInstanciaFIX255());
}

void AtualizarHeartbeatIdentidadeFIX304()
{
   if(!g_identidadeInicializadaFIX304) return;
   string chave=JanelaAtualEhA_FIX255() ? g_identidadeChaveHeartbeatAFIX304 : g_identidadeChaveHeartbeatBFIX304;
   if(chave!="") GlobalVariableSet(chave,(double)TimeLocal());
}

void EncerrarHeartbeatIdentidadeFIX304()
{
   if(!g_identidadeInicializadaFIX304) return;
   string chave=JanelaAtualEhA_FIX255() ? g_identidadeChaveHeartbeatAFIX304 : g_identidadeChaveHeartbeatBFIX304;
   if(chave!="") GlobalVariableSet(chave,0.0);
}

string NovoCicloMagicFIX304(long magic)
{
   string chave=g_identidadeChaveBaseFIX304+"_"+g_identidadeGeracaoFIX304+"_M"+IntegerToString((int)magic)+"_SEQ";
   long seq=GlobalVariableCheck(chave) ? (long)GlobalVariableGet(chave) : 0;
   seq++;
   if(seq>46655) seq=1;
   GlobalVariableSet(chave,(double)seq);
   return "C"+Base36FIX304(seq,3);
}

string CicloAtualMagicFIX304(long magic,bool criarSeNecessario)
{
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      string cmt=PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt,"#I"+g_identidadeGeracaoFIX304)<0) continue;
      string ciclo=ExtrairCicloComentarioFIX304(cmt);
      if(ciclo!="")
      {
         if(magic==MagicOperacionalInstanciaFIX255()) g_identidadeCicloLocalFIX304=ciclo;
         return ciclo;
      }
   }
   if(magic==MagicOperacionalInstanciaFIX255() && g_identidadeCicloLocalFIX304!="")
      return g_identidadeCicloLocalFIX304;
   if(!criarSeNecessario) return "";
   string novo=NovoCicloMagicFIX304(magic);
   if(magic==MagicOperacionalInstanciaFIX255()) g_identidadeCicloLocalFIX304=novo;
   return novo;
}

void EncerrarCicloIdentidadeLocalFIX304()
{
   g_identidadeCicloLocalFIX304="";
}

bool ComentarioTemIdentidadeAtualFIX304(string comentario,long magic)
{
   if(g_identidadeGeracaoFIX304=="") return false;
   if(StringFind(comentario,"#I"+g_identidadeGeracaoFIX304)<0) return false;
   if(StringFind(comentario,"|M"+IntegerToString((int)magic))<0) return false;
   if(ExtrairCicloComentarioFIX304(comentario)=="") return false;
   return true;
}

string ComentarioComIdentidadeMagicFIX304(string comentarioBase,long magic)
{
   if(!g_identidadeInicializadaFIX304) InicializarIdentidadeUnicaFIX304();
   string marcador=MarcadorComentarioOperacionalFIX252(comentarioBase);
   bool precisaCiclo=(StringFind(marcador,"|A")>=0 || StringFind(marcador,"|PC")>=0 || StringFind(marcador,"|PR")>=0 || StringFind(marcador,"|OUT")>=0);
   string ciclo=CicloAtualMagicFIX304(magic,precisaCiclo);
   if(ciclo=="") ciclo="C000";
   string c="#I"+g_identidadeGeracaoFIX304+"|M"+IntegerToString((int)magic)+"|"+ciclo+marcador;
   if(StringLen(c)>31) c=StringSubstr(c,0,31);
   return c;
}

int ContarPosicoesMagicFIX304(long magic,double &contratos)
{
   contratos=0.0;
   int qtd=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if(!PosicaoSelecionadaPertencePainelFIX316(magic)) continue;
      qtd++;
      contratos+=PositionGetDouble(POSITION_VOLUME);
   }
   return qtd;
}

string IDInstanciaAtual()
{
   if(!g_identidadeInicializadaFIX304) InicializarIdentidadeUnicaFIX304();
   return g_identidadeGeracaoFIX304;
}


string MarcadorComentarioOperacionalFIX252(string comentarioBase)
{
   string c = Upper(comentarioBase);
   int nivel = NivelAumentoComentarioFIX207(c);
   bool parcial = (StringFind(c, "PARCIAL") >= 0 || StringFind(c, "PARC_") >= 0);
   bool protecao = (StringFind(c, "PROTECAO") >= 0);
   bool saida = (StringFind(c, "SAIDA") >= 0);
   string marcador = "";
   if(nivel > 0)
      marcador = "|A" + IntegerToString(nivel);
   else if(StringFind(" " + c + " ", " A0 ") >= 0)
      marcador = "|A0";
   if(parcial)
      marcador += "|PC";
   else if(protecao)
      marcador += "|PR";
   else if(saida)
      marcador += "|OUT";
   else if(marcador == "")
      marcador = "|OP";
   return marcador;
}



void SincronizarMagicParametros(bool forcar)
{
   long novoMagicCompra = MagicCompraAtual();
   long novoMagicVenda  = MagicVendaAtual();
   long novoMagicPainelA = MagicPainelAAtual();
   long novoMagicPainelB = MagicPainelBAtual();
   bool mudou = (forcar ||
                 g_magicCompraSincronizado != novoMagicCompra ||
                 g_magicVendaSincronizado  != novoMagicVenda  ||
                 g_compra.magic != novoMagicCompra ||
                 g_venda.magic  != novoMagicVenda ||
                 g_painelA.magic != novoMagicPainelA ||
                 g_painelB.magic != novoMagicPainelB);
   g_compra.magic = novoMagicCompra;
   g_venda.magic  = novoMagicVenda;
   PrepararSlotPainel(g_painelA, "A", novoMagicPainelA, LADO_COMPRA);
   PrepararSlotPainel(g_painelB, "B", novoMagicPainelB, LADO_VENDA);
   if(!mudou)
      return;
   LimparTodosObjetosCOPA();
   g_magicCompraSincronizado = novoMagicCompra;
   g_magicVendaSincronizado  = novoMagicVenda;
   g_ultimaAtualizacaoHistorico = 0;
   g_ultimaAtualizacaoPainelVisual = 0;
   g_cicloInicioCompra = 0;
   g_cicloInicioVenda  = 0;
   g_ordemUltimoMagic = 0;
   g_ordemUltimoEvento = "MAGIC ALTERADO PELOS PARAMETROS";
   g_ordemUltimoContexto = "MAGIC_SYNC";
   g_ordemUltimaHora = TimeCurrent();
   g_mestre.mensagemGeral = StringFormat("Magic aplicado: A %s | B %s | Painel A %s | Painel B %s | ID %s",
                                         IntegerToString(novoMagicCompra),
                                         IntegerToString(novoMagicVenda),
                                         IntegerToString(novoMagicPainelA),
                                         IntegerToString(novoMagicPainelB),
                                         IDInstanciaAtual());
   if(InpGerenciadorOrdensExperts)
   {
      Print("[COPA_AR100][MAGIC_SYNC] MagicA=", IntegerToString(novoMagicCompra),
            " | MagicB=", IntegerToString(novoMagicVenda),
            " | PainelA=", IntegerToString(novoMagicPainelA),
            " | PainelB=", IntegerToString(novoMagicPainelB),
            " | Janela=", NomeJanelaInstanciaFIX255(),
            " | TF=", NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
            " | Fonte=InpMagicsCompraVenda | FIX260");
   }
}

bool InicializarIndicadores()
{
   int periodoDX = InpDXPeriodo;
   if(periodoDX <= 0)
      periodoDX = 2;
   int periodoMediaGrafico = PeriodoMediaGraficoEfetivo();
   g_handleADX = iADX(_Symbol, TimeframeFiltroAtualFIX255(), periodoDX);
   g_handleMedia25Grafico = iMA(_Symbol,
                                (ENUM_TIMEFRAMES)_Period,
                                periodoMediaGrafico,
                                0,
                                InpMedia25MetodoGrafico,
                                InpMedia25PrecoGrafico);
   int periodoRSIAumentosFIX399=InpRSIPeriodoAumentosFIX399;
   if(periodoRSIAumentosFIX399<2) periodoRSIAumentosFIX399=14;
   g_handleRSI = iRSI(_Symbol, TimeframeFiltroAtualFIX255(), periodoRSIAumentosFIX399, PRICE_CLOSE);
   if(g_handleADX == INVALID_HANDLE || g_handleRSI == INVALID_HANDLE)
   {
      g_mestre.mensagemGeral = "Aviso: DX/RSI interno nao inicializou corretamente.";
      return false;
   }
   if(g_handleMedia25Grafico == INVALID_HANDLE && InpGerenciadorOrdensExperts)
      Print("[COPA_AR100][MEDIA_GRAFICA] Aviso: media grafica do grafico nao inicializou.");
   GarantirDXIndicadorNoGrafico();
   GarantirOsciladoresSelecionadosFIX343();
   return true;
}

void LiberarIndicadores()
{
   RemoverOsciladoresSelecionadosFIX343();
   RemoverDXVisualEditavelFIX345();
   if(g_handleADX != INVALID_HANDLE)
      IndicatorRelease(g_handleADX);
   if(g_handleMedia25Grafico != INVALID_HANDLE)
      IndicatorRelease(g_handleMedia25Grafico);
   if(g_handleRSI != INVALID_HANDLE)
      IndicatorRelease(g_handleRSI);
}

void AplicarTrailingInteligenteLinhasFIX325()
{
   string linha=InpTrailingInteligenteLinhasFIX325;
   StringReplace(linha,"|",";");
   g_trailInteligenteLinhasAtivoFIX325=IsOn(GetCampo(linha,"","ON"));
   g_trailInteligenteAtivaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"ATIVA","75")));
   g_trailInteligentePassoPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"PASSO","35")));
   g_trailInteligenteDistanciaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"DIST","75")));
   g_trailInteligenteReduzirFIX325=IsOn(GetCampo(linha,"REDUZ","ON"));
   g_trailInteligenteReducaoPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"REDUZ_PTS","35")));
   g_trailInteligenteDistanciaMinimaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"MIN","10")));
   g_trailInteligenteApitarFIX325=IsOn(GetCampo(linha,"APITO","ON"));
   if(g_trailInteligenteAtivaPontosFIX325<=0.0) g_trailInteligenteAtivaPontosFIX325=75.0;
   if(g_trailInteligentePassoPontosFIX325<=0.0) g_trailInteligentePassoPontosFIX325=35.0;
   if(g_trailInteligenteDistanciaPontosFIX325<=0.0) g_trailInteligenteDistanciaPontosFIX325=75.0;
   if(g_trailInteligenteReducaoPontosFIX325<=0.0) g_trailInteligenteReducaoPontosFIX325=35.0;
   if(g_trailInteligenteDistanciaMinimaPontosFIX325<=0.0) g_trailInteligenteDistanciaMinimaPontosFIX325=10.0;
   // Distancia minima maior que a inicial impediria a reducao; limita ao valor inicial.
   if(g_trailInteligenteDistanciaMinimaPontosFIX325>g_trailInteligenteDistanciaPontosFIX325)
      g_trailInteligenteDistanciaMinimaPontosFIX325=g_trailInteligenteDistanciaPontosFIX325;
}

void AplicarGestaoAumentosCompactaFIX324()
{
   AplicarTrailingInteligenteLinhasFIX325();
   string linha=InpGestaoAumentosFIX324;
   StringReplace(linha,"|",";");

   double contratos=ExtrairNumero(GetCampo(linha,"QTD",GetCampo(linha,"CONTRATOS","1")));
   int espera=ExtrairInteiro(GetCampo(linha,"TIMER",GetCampo(linha,"TEMPO","0")));
   double gatilho=MathAbs(ExtrairNumero(GetCampo(linha,"GATILHO",GetCampo(linha,"G","20"))));
   int distancia=(int)MathRound(MathAbs(ExtrairNumero(GetCampo(linha,"DIST",GetCampo(linha,"DISTANCIA","100")))));
   double alvo=MathAbs(ExtrairNumero(GetCampo(linha,"ALVO",GetCampo(linha,"GAIN",GetCampo(linha,"GANHO","100")))));
   double perda=MathAbs(ExtrairNumero(GetCampo(linha,"PERDA",GetCampo(linha,"LOSS",GetCampo(linha,"STOP","100")))));
   string trail=GetCampo(linha,"TRAIL",GetCampo(linha,"TRAILING","20/5"));
   double proteger=20.0;
   double passo=5.0;
   ParseTrailAumentoFIX282(trail,proteger,passo);

   if(contratos<=0.0) contratos=1.0;
   if(espera<0) espera=0;
   if(gatilho<0.0) gatilho=0.0;
   if(distancia<1) distancia=1;
   if(alvo<=0.0) alvo=100.0;
   if(perda<=0.0) perda=100.0;

   InpContratosPorReforco=contratos;
   InpEsperaAntesReforcoMinutos=espera;
   InpDistanciaEntreReforcosPontos=distancia;
   InpLucroAumentoPorContratoReaisFIX207=alvo;
   InpLossAumentoPorContratoReaisFIX321=perda;
   InpTrailingAumentoAtivarReaisFIX281=proteger;
   InpTrailingAumentoPassoReaisFIX281=passo;
   InpLucroAumentoPorContratoReaisFIX207=10.0; // FIX447: alvo de teste por ticket.
   InpAumentoFecharNoAlvoFIX281=true; // FIX447: fecha somente o ticket do nivel em +R$10.

   string perfilA0=Trim(g_perfilA0PadraoFIX372);
   if(perfilA0=="") perfilA0="LIVRE";
   string perfilAumento=Trim(g_perfilAumentosFIX372);
   if(perfilAumento=="") perfilAumento="LIVRE";
   InpPerfilFiltrosAuditoriaFIX302=perfilA0;
   // FIX377: cada aumento usa sua propria linha visivel de filtros.
   InpA1Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA1CompactoFIX375);
   InpA2Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA2CompactoFIX375);
   InpA3Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA3CompactoFIX375);
   InpA4Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA4CompactoFIX375);
   InpA5Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA5CompactoFIX375);
   InpA5Filtros="LIVRE";

   string j1=MontarPerfilTresFiltrosFIX372(InpJanela1Filtro1FIX372,InpJanela1Filtro2FIX372,InpJanela1Filtro3FIX372);
   string j2=MontarPerfilTresFiltrosFIX372(InpJanela2Filtro1FIX372,InpJanela2Filtro2FIX372,InpJanela2Filtro3FIX372);
   string j3=MontarPerfilTresFiltrosFIX372(InpJanela3Filtro1FIX372,InpJanela3Filtro2FIX372,InpJanela3Filtro3FIX372);
   string j4=MontarPerfilTresFiltrosFIX372(InpJanela4Filtro1FIX372,InpJanela4Filtro2FIX372,InpJanela4Filtro3FIX372);
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
   {
      InpJanela1Filtros="LIVRE"; InpJanela2Filtros="LIVRE";
      InpJanela3Filtros="LIVRE"; InpJanela4Filtros="LIVRE";
      InpA1Filtros="LIVRE"; InpA2Filtros="LIVRE"; InpA3Filtros="LIVRE"; InpA4Filtros="LIVRE"; InpA5Filtros="LIVRE";
   }
   else
   {
      InpJanela1Filtros=PerfilJanelaOuPadraoFIX372(0,j1,perfilA0);
      InpJanela2Filtros=PerfilJanelaOuPadraoFIX372(1,j2,perfilA0);
      InpJanela3Filtros=PerfilJanelaOuPadraoFIX372(2,j3,perfilA0);
      InpJanela4Filtros=PerfilJanelaOuPadraoFIX372(3,j4,perfilA0);
   }
}

string MontarLinhaAumentoVisivelFIX340(string execucao, string trailing, bool ativo)
{
   string linha=Trim(execucao)+";"+Trim(trailing);
   StringReplace(linha,"|",";");
   string qtd=Trim(GetCampo(linha,"QTD",GetCampo(linha,"CONTRATOS",GetCampo(linha,"A1",GetCampo(linha,"A2",GetCampo(linha,"A3",GetCampo(linha,"A4",GetCampo(linha,"A5","1C"))))))));
   string timer=Trim(GetCampo(linha,"TIMER",GetCampo(linha,"TEMPO","2M")));
   string gatilho=Trim(GetCampo(linha,"GATILHO",GetCampo(linha,"G","20")));
   string distancia=Trim(GetCampo(linha,"DIST",GetCampo(linha,"DISTANCIA","100")));
   string trail=Trim(GetCampo(linha,"TRAIL",GetCampo(linha,"TRAILING","20/5")));
   return StringFormat("%s;QTD=%s;TEMPO=%s;GATILHO=%s;DIST=%s;TRAIL=%s",
                       ativo ? "ON" : "OFF",qtd,timer,gatilho,distancia,trail);
}

void MontarReforcosDaTelaFIX312()
{
   int quantidade=InpQuantidadeReforcos;
   if(quantidade<0) quantidade=0;
   if(quantidade>5) quantidade=5;

   // FIX340: a tela fica humana e curta; estas linhas remontam exatamente as
   // strings técnicas já usadas pelo motor, sem alterar a estratégia.
   InpEntradaOperacao=Trim(InpEntradaA0QuantidadeAlvoFIX340)+" | "+Trim(InpEntradaA0PerdaTrailingFIX340);
   InpA1=MontarLinhaAumentoVisivelFIX340(InpA1ExecucaoFIX340,InpA1TrailingFIX340,quantidade>=1);
   InpA2=MontarLinhaAumentoVisivelFIX340(InpA2ExecucaoFIX340,InpA2TrailingFIX340,quantidade>=2);
   InpA3=MontarLinhaAumentoVisivelFIX340(InpA3ExecucaoFIX340,InpA3TrailingFIX340,quantidade>=3);
   InpA4=MontarLinhaAumentoVisivelFIX340(InpA4ExecucaoFIX340,InpA4TrailingFIX340,quantidade>=4);
   InpA5=MontarLinhaAumentoVisivelFIX340(InpA5ExecucaoFIX340,InpA5TrailingFIX340,quantidade>=5);

   string risco=Trim(InpRiscoAumentosFIX340);
   StringReplace(risco,"|",";");
   // Os valores de alvo/perda dos aumentos permanecem comuns por contrato,
   // como no motor existente. A1 fornece apenas os defaults operacionais.
   InpGestaoAumentosFIX324=InpA1+";"+risco;
   AplicarGestaoAumentosCompactaFIX324();

   // FIX440: cada janela A1-A5 define sua propria quantidade.
   // Nao existe bloqueio global pela soma dos contratos configurados.
   InpAumentos=StringFormat("ON;DIR=CONTRA;LIVRE_TESTE=OFF;LIVRE_TOTAL=OFF;IGNORAR_META_DIA=OFF;MAX_AUMENTOS=%d;MAX_CONTRATOS=100000;VALIDACAO=ON",
                            quantidade);
}

void CarregarTodasMatrizes()
{
   SincronizarParametrosUsuarioFIX362(true,"INIT_MATRIZES");
}

void CarregarMatrizJanelas()
{
   // FIX302: uma linha compacta controla as quatro faixas de A0.
   g_janelas[0] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,0), InpJanela1Filtros));
   g_janelas[1] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,1), InpJanela2Filtros));
   g_janelas[2] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,2), InpJanela3Filtros));
   g_janelas[3] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,3), InpJanela4Filtros));
   g_janelas[4] = ParseJanela("OFF;HOR=18:00-18:15;LADO=AMBOS;A0=OFF;QTD=1;PERFIL=FIM_DIA");
   ValidarJanelasClaras();
}

string MontarLinhaJanelaClara(string configuracao, string filtros)
{
   string raw = Trim(configuracao);
   string horarioCompleto = raw;

   // Compatibilidade com arquivos antigos: aceita ON | HH:MM - HH:MM | A0=ON
   // e também ON;HOR=HH:MM-HH:MM;..., mas ignora ON/OFF, A0 e LADO.
   if(StringFind(raw, "|") >= 0)
   {
      string partesConfig[];
      int totalConfig = StringSplit(raw, '|', partesConfig);
      horarioCompleto = "";
      for(int i = 0; i < totalConfig; i++)
      {
         string parte = Trim(partesConfig[i]);
         if(StringFind(parte, ":") >= 0 && StringFind(parte, "-") >= 0)
         {
            horarioCompleto = parte;
            break;
         }
      }
   }
   else if(StringFind(Upper(raw), "HOR=") >= 0)
      horarioCompleto = GetCampo(raw, "HOR", "00:00-00:00");

   string horario = Trim(horarioCompleto);
   string partesHorario[];
   int quantidadePartes = StringSplit(horario, '-', partesHorario);
   bool formatoValido = (quantidadePartes >= 2 &&
                         StringFind(Trim(partesHorario[0]), ":") >= 0 &&
                         StringFind(Trim(partesHorario[1]), ":") >= 0);
   if(formatoValido)
      horario = Trim(partesHorario[0]) + "-" + Trim(partesHorario[1]);
   else
   {
      horario = "00:00-00:00";
      PrintFormat("[COPA_AR100][HORARIOS] Formato invalido; janela bloqueada: '%s'. Use HH:MM - HH:MM.", configuracao);
   }

   // Regras fixas protegidas: janela ligada, entrada A0 permitida e ambos os lados.
   string base = StringFormat("%s;HOR=%s;LADO=AMBOS;A0=ON;QTD=1;PERFIL=HARD",
                              formatoValido ? "ON" : "OFF",
                              horario);
   return CombinarLinhaFiltro(base, NormalizarFiltrosHumanizados(filtros));
}

bool MinutoDentroJanelaValor(int minuto, RegraJanela &j)
{
   if(!j.ativa || j.minutoInicio == j.minutoFim)
      return false;
   if(j.minutoInicio < j.minutoFim)
      return (minuto >= j.minutoInicio && minuto < j.minutoFim);
   return (minuto >= j.minutoInicio || minuto < j.minutoFim);
}

void ValidarJanelasClaras()
{
   for(int i = 0; i < 4; i++)
   {
      if(!g_janelas[i].ativa)
         continue;
      if(g_janelas[i].minutoInicio == g_janelas[i].minutoFim)
      {
         PrintFormat("[COPA_AR100][JANELAS] J%d desativada na pratica: inicio e fim iguais (%s).", i + 1, g_janelas[i].horario);
         continue;
      }
      for(int k = i + 1; k < 4; k++)
      {
         if(!g_janelas[k].ativa)
            continue;
         bool sobrepoe = false;
         for(int minuto = 0; minuto < 1440 && !sobrepoe; minuto++)
            sobrepoe = (MinutoDentroJanelaValor(minuto, g_janelas[i]) && MinutoDentroJanelaValor(minuto, g_janelas[k]));
         if(sobrepoe)
            PrintFormat("[COPA_AR100][JANELAS] ATENCAO: J%d (%s) sobrepoe J%d (%s).", i + 1, g_janelas[i].horario, k + 1, g_janelas[k].horario);
      }
   }
}

void CarregarMatrizAumentos()
{
   ParseGerenciadorAumentos(InpAumentos);
   ParseScoreAumentos(InpAumentosSomenteScore);
   g_aumentos[0] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA1), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA1Filtros))));
   g_aumentos[1] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA2), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA2Filtros))));
   g_aumentos[2] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA3), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA3Filtros))));
   g_aumentos[3] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA4), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA4Filtros))));
   g_aumentos[4] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA5), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA5Filtros))));
}

bool ExtrairPrimeiroNumeroAPartir(string texto, int inicio, double &valor, int &fimNumero)
{
   valor = 0.0;
   fimNumero = inicio;
   int total = StringLen(texto);
   string numero = "";
   bool iniciou = false;
   int inicioSeguro = (inicio < 0 ? 0 : inicio);
   for(int i = inicioSeguro; i < total; i++)
   {
      ushort ch = StringGetCharacter(texto, i);
      bool digito = (ch >= '0' && ch <= '9');
      bool separadorDecimal = (ch == '.' || ch == ',');
      bool sinal = (ch == '-' && !iniciou);
      if(digito || (separadorDecimal && iniciou) || sinal)
      {
         if(ch == ',')
            numero += ".";
         else
            numero += ShortToString(ch);
         iniciou = true;
         fimNumero = i + 1;
         continue;
      }
      if(iniciou)
         break;
   }
   if(numero == "" || numero == "-")
      return false;
   valor = StringToDouble(numero);
   return true;
}

double NumeroDepoisDoMarcador(string texto, string marcador, double padrao)
{
   string superior = Upper(texto);
   string chave = Upper(marcador);
   int pos = StringFind(superior, chave);
   if(pos < 0)
      return padrao;
   double valor = 0.0;
   int fim = pos + StringLen(chave);
   if(!ExtrairPrimeiroNumeroAPartir(superior, fim, valor, fim))
      return padrao;
   return valor;
}

bool DoisNumerosDepoisDoMarcador(string texto, string marcador, double &primeiro, double &segundo)
{
   primeiro = 0.0;
   segundo = 0.0;
   string superior = Upper(texto);
   string chave = Upper(marcador);
   int pos = StringFind(superior, chave);
   if(pos < 0)
      return false;
   int fimPrimeiro = pos + StringLen(chave);
   if(!ExtrairPrimeiroNumeroAPartir(superior, fimPrimeiro, primeiro, fimPrimeiro))
      return false;
   int fimSegundo = fimPrimeiro;
   if(!ExtrairPrimeiroNumeroAPartir(superior, fimPrimeiro, segundo, fimSegundo))
      return false;
   return true;
}

int CandlesNoFormatoCurto(string texto, int padrao)
{
   string superior = Upper(texto);
   int total = StringLen(superior);
   for(int i = 0; i < total; i++)
   {
      ushort ch = StringGetCharacter(superior, i);
      if(ch < '0' || ch > '9')
         continue;
      double valor = 0.0;
      int fim = i;
      if(!ExtrairPrimeiroNumeroAPartir(superior, i, valor, fim))
         continue;
      int j = fim;
      while(j < total && StringGetCharacter(superior, j) == ' ')
         j++;
      if(j < total && StringGetCharacter(superior, j) == 'C')
      {
         int candles = (int)MathRound(valor);
         if(candles < 1)
            candles = 1;
         return candles;
      }
      i = MathMax(i, fim - 1);
   }
   return padrao;
}

string NormalizarFiltrosHumanizados(string linha)
{
   string raw = Trim(linha);
   string superior = Upper(raw);
   if(raw == "" || superior == "LIVRE" || superior == "SEM FILTRO" ||
      superior == "SEM FILTROS" || superior == "OFF")
      return "MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";

   // Compatibilidade com configurações técnicas antigas em CHAVE=VALOR.
   if(StringFind(raw, "=") >= 0 || StringFind(raw, ";") >= 0)
      return raw;

   // FIX326: matriz humana com volume combinado, forca, Fibo e WAP Bands reais.
   if(StringFind(superior,"MACD")>=0 || StringFind(superior,"ATR")>=0 ||
      StringFind(superior,"SCORE")>=0)
      return "INVALIDO=ON;ERRO=FILTRO_NAO_SUPORTADO_NESTA_MATRIZ;MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";
   int minimoOk=0;
   bool modoMinimo=(StringFind(superior,"MIN ")>=0 || StringFind(superior,"MINIMO")>=0);
   if(modoMinimo)
   {
      minimoOk=(int)MathRound(MathAbs(NumeroDepoisDoMarcador(superior,"MIN",6.0)));
      if(minimoOk<1) minimoOk=1;
      if(minimoOk>10) minimoOk=10;
   }
   string normalizada = (modoMinimo ? StringFormat("MODO=MINIMO;MIN_OK=%d",minimoOk) : "MODO=TODOS;MIN_OK=0");
   int usados = 0;

   if(StringFind(superior, "HILO8") >= 0 || StringFind(superior, "HILO") >= 0)
   {
      normalizada += ";HILO=ON";
      usados++;
   }
   if(StringFind(superior, "STR") >= 0)
   {
      normalizada += ";STR=ON";
      usados++;
   }

   bool volumeCombinado = (StringFind(superior, "VOLUME QTD+FIN") >= 0 ||
                           StringFind(superior, "VOLUME QTD + FIN") >= 0 ||
                           StringFind(superior, "VOLQ+VOLF") >= 0 ||
                           StringFind(superior, "VOLQ + VOLF") >= 0);
   int posVOLQ = StringFind(superior, "VOLQ");
   if(posVOLQ < 0)
      posVOLQ = StringFind(superior, "VOLUME QTD");
   int posVOLF = StringFind(superior, "VOLF");
   if(posVOLF < 0)
      posVOLF = StringFind(superior, "VOLUME FIN");
   if(volumeCombinado)
   {
      normalizada += ";VOLCOMB=ON;VOLQ=ON;VOLQMIN=1000.00;VOLF=ON;VOLFMIN=1000000.00";
      usados++;
   }
   else
   {
      // Compatibilidade: VOLQ ou VOLF separados continuam aceitos, sem criar novas opções visuais.
      if(posVOLQ >= 0)
      {
         string marcadorQ = (StringFind(superior, "VOLQ") >= 0 ? "VOLQ" : "VOLUME QTD");
         double minimoVOLQ = MathAbs(NumeroDepoisDoMarcador(superior, marcadorQ, 1000.0));
         normalizada += StringFormat(";VOLQ=ON;VOLQMIN=%.2f", minimoVOLQ);
         usados++;
      }
      if(posVOLF >= 0)
      {
         string marcadorF = (StringFind(superior, "VOLF") >= 0 ? "VOLF" : "VOLUME FIN");
         double minimoVOLF = MathAbs(NumeroDepoisDoMarcador(superior, marcadorF, 1000000.0));
         normalizada += StringFormat(";VOLF=ON;VOLFMIN=%.2f", minimoVOLF);
         usados++;
      }
   }

   if(StringFind(superior, "DX") >= 0)
   {
      double minimoDX = MathAbs(NumeroDepoisDoMarcador(superior, "DX", 25.0));
      normalizada += StringFormat(";DX25=ON;DXMIN=%.2f", minimoDX);
      usados++;
   }

   if(StringFind(superior, "RSI") >= 0)
   {
      double faixaBaixa = 30.0;
      double faixaAlta = 70.0;
      double numero1 = 0.0;
      double numero2 = 0.0;
      if(DoisNumerosDepoisDoMarcador(superior, "RSI", numero1, numero2))
      {
         faixaBaixa = MathMin(numero1, numero2);
         faixaAlta = MathMax(numero1, numero2);
      }
      // FIX274: RSI 30/70 deve significar COMPRA em sobrevenda (<=30)
      // e VENDA em sobrecompra (>=70). O mapeamento antigo estava invertido.
      normalizada += StringFormat(";RSI=ON;RSIC=%.2f;RSIV=%.2f;RSIC_OP=<=;RSIV_OP=>=",
                                  faixaBaixa, faixaAlta);
      usados++;
   }

   int posAGR = StringFind(superior, "AGR");
   if(posAGR < 0)
      posAGR = StringFind(superior, "AGF");
   if(posAGR >= 0)
   {
      string marcador = (StringFind(superior, "AGR") >= 0 ? "AGR" : "AGF");
      double minimoAGR = MathAbs(NumeroDepoisDoMarcador(superior, marcador, 50.0));
      normalizada += StringFormat(";AGF=ON;AGFMIN=%.2f", minimoAGR);
      usados++;
   }

   if(StringFind(superior,"M25")>=0 || StringFind(superior,"MEDIA25")>=0)
   {
      normalizada += ";M25=ON";
      usados++;
   }

   int posForca=StringFind(superior,"FORCA");
   if(posForca<0) posForca=StringFind(superior,"FORÇA");
   if(posForca>=0)
   {
      string marcadorForca=(StringFind(superior,"FORCA")>=0 ? "FORCA" : "FORÇA");
      double minimoForca=MathAbs(NumeroDepoisDoMarcador(superior,marcadorForca,60.0));
      normalizada+=StringFormat(";FORCA=ON;FORCAMIN=%.2f",minimoForca);
      usados++;
   }

   if(StringFind(superior,"FIBO")>=0)
   {
      double minimoFibo=MathAbs(NumeroDepoisDoMarcador(superior,"FIBO",1.272));
      normalizada+=StringFormat(";FIBO=ON;FIBOMIN=%.3f",minimoFibo);
      usados++;
   }

   int posWap=StringFind(superior,"WAPBANDS");
   string marcadorWap="WAPBANDS";
   if(posWap<0)
   {
      posWap=StringFind(superior,"WAP BANDS");
      marcadorWap="WAP BANDS";
   }
   if(posWap<0)
   {
      posWap=StringFind(superior,"VWAP");
      marcadorWap="VWAP";
   }
   if(posWap>=0)
   {
      double desvios=MathAbs(NumeroDepoisDoMarcador(superior,marcadorWap,1.0));
      normalizada+=StringFormat(";WAPBANDS=ON;WAPDESVIO=%.2f",desvios);
      usados++;
   }

   int candles = CandlesNoFormatoCurto(superior, 1);
   normalizada += StringFormat(";CONF=FECHAMENTO;CANDLES=%d", candles);

   if(usados == 0)
      return "INVALIDO=ON;ERRO=FILTRO_NAO_RECONHECIDO;MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";
   return normalizada;
}


void AplicarConfirmacaoLinhasAumentos()
{
   // FIX363: regra obrigatória e não sobrescrita por modo de teste.
   // A linha apenas arma. A ordem só pode sair depois do candle M1 fechado,
   // filtros aprovados e preço executável ainda na linha ou em posição melhor.
   InpConfirmacaoLinhasAumentos="FECHAMENTO | M1 | 0P | PRECO MELHOR";
   InpAumentoConfirmarFechamentoCandle=true;
   InpAumentoTimeframeConfirmacao=PERIOD_M1;
   InpAumentoMargemFechamentoPontos=0.0;
}

string CombinarLinhaFiltro(string linhaBase, string linhaFiltros)
{
   linhaBase = Trim(linhaBase);
   linhaFiltros = Trim(linhaFiltros);
   if(linhaBase == "")
      return linhaFiltros;
   if(linhaFiltros == "")
      return linhaBase;
   return linhaBase + ";" + linhaFiltros;
}

void CarregarMatrizSaida()
{
   ParseRiscoOperacao(InpRiscoOperacao);
   ParseRiscoDiario(InpRiscoDiario);
   ParseProtecaoLucro(InpProtecaoLucro);
   ParseOperacaoLonga(InpOperacaoLonga);
}

RegraJanela ParseJanela(string linha)
{
   RegraJanela j;
   ZeroMemory(j);
   j.ativa = IsOn(GetCampo(linha, "", "ON"));
   j.horario = GetCampo(linha, "HOR", "00:00-23:59");
   ParseHorario(j.horario, j.minutoInicio, j.minutoFim);
   j.lado = ParseLado(GetCampo(linha, "LADO", "AMBOS"));
   j.entradaAtiva = IsOn(GetCampo(linha, "A0", GetCampo(linha, "ENT", "ON")));
   j.qtd = ExtrairNumero(GetCampo(linha, "QTD", "1"));
   j.perfil = Upper(GetCampo(linha, "PERFIL", "DINAMICO"));
   j.filtros = ParseFiltrosDaLinha(linha);
   return j;
}

void ParseTrailAumentoFIX282(string campo, double &ativar, double &passo)
{
   ativar = MathAbs(InpTrailingAumentoAtivarReaisFIX281);
   passo = MathAbs(InpTrailingAumentoPassoReaisFIX281);
   string valor = Trim(campo);
   int eq = StringFind(valor,"=");
   if(eq >= 0)
      valor = Trim(StringSubstr(valor,eq+1));
   string partes[];
   int total = StringSplit(valor,'/',partes);
   if(total >= 1 && Trim(partes[0]) != "")
      ativar = MathAbs(ExtrairNumero(partes[0]));
   if(total >= 2 && Trim(partes[1]) != "")
      passo = MathAbs(ExtrairNumero(partes[1]));
   if(ativar <= 0.0) ativar = 20.0;
   if(passo <= 0.0) passo = 5.0;
}

void ParseMovelAumentoFIX442(string campo, double &ativar, double &defender)
{
   ativar=0.0;
   defender=0.0;
   string valor=Trim(campo);
   int eq=StringFind(valor,"=");
   if(eq>=0) valor=Trim(StringSubstr(valor,eq+1));
   string partes[];
   int total=StringSplit(valor,'/',partes);
   if(total>=1 && Trim(partes[0])!="") ativar=MathAbs(ExtrairNumero(partes[0]));
   if(total>=2 && Trim(partes[1])!="") defender=MathAbs(ExtrairNumero(partes[1]));
   if(ativar<=0.0)
   {
      ativar=0.0;
      defender=0.0;
   }
   if(defender>ativar) defender=ativar;
}

RegraAumento ParseAumento(string linha)
{
   RegraAumento a;
   ZeroMemory(a);
   linha = NormalizarLinhaAumentoHumanizada(linha);
   a.ativa = IsOn(GetCampo(linha, "", "ON"));
   a.qtd = ExtrairNumero(GetCampo(linha, "QTD", "1"));
   a.tempoMinutos = ExtrairInteiro(GetCampo(linha, "TEMPO", "0m"));
   a.distanciaPontos = ExtrairInteiro(GetCampo(linha, "DIST", "0pts"));
   a.gatilhoReais = ExtrairNumero(GetCampo(linha, "GATILHO", "0G"));
   a.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT", "0%"));
   ParseMovelAumentoFIX442(GetCampo(linha, "MOVEL", "0/0"), a.movelAtivarReais, a.movelDefenderReais);
   ParseTrailAumentoFIX282(GetCampo(linha, "TRAIL", "0/0"), a.trailingAtivarReais, a.trailingPassoReais);
   a.lado = ParseLado(GetCampo(linha, "LADO", "AMBOS"));
   a.filtros = ParseFiltrosDaLinha(linha);
   return a;
}

void ParseGerenciadorAumentos(string linha)
{
   ZeroMemory(g_gerAumentos);
   g_gerAumentos.ativo = IsOn(GetCampo(linha, "", "ON"));
   g_gerAumentos.modo = Upper(GetCampo(linha, "MODO", "DINAMICO"));
   g_gerAumentos.maxAumentos = ExtrairInteiro(GetCampo(linha, "MAX_AUMENTOS", GetCampo(linha, "MAX_AUM", "5")));
   g_gerAumentos.maxContratos = ExtrairInteiro(GetCampo(linha, "MAX_CONTRATOS", GetCampo(linha, "MAX_CONTR", "100000")));
   g_gerAumentos.scoreNormalMax = ExtrairNumero(GetCampo(linha, "SCORE_NORMAL_MAX", "79"));
   g_gerAumentos.scoreForteMax = ExtrairNumero(GetCampo(linha, "SCORE_FORTE_MAX", "84"));
   g_gerAumentos.scoreExtremo = ExtrairNumero(GetCampo(linha, "SCORE_EXTREMO", "85"));
   g_gerAumentos.acaoExtremo = Upper(GetCampo(linha, "ACAO_EXTREMO", "BLOQUEAR_AUMENTOS"));
   g_gerAumentos.exigirPausa = IsOn(GetCampo(linha, "EXIGIR_RESFRIAMENTO", "ON"));
   g_gerAumentos.usarAX = IsOn(GetCampo(linha, "USAR_AX", "OFF"));
}

void ParseScoreAumentos(string linha)
{
   ZeroMemory(g_scoreAumentos);
   g_scoreAumentos.ativo = (InpModoGatilhoAumentos == AUMENTOS_SOMENTE_POR_SCORE);
   g_scoreAumentos.usarHilo8 = IsOn(GetCampo(linha, "HILO8", GetCampo(linha, "HILO", "ON")));
   g_scoreAumentos.usarSTR = IsOn(GetCampo(linha, "STR", "ON"));
   g_scoreAumentos.usarVOLQ = IsOn(GetCampo(linha, "VOLQ", "ON"));
   g_scoreAumentos.usarVOLF = IsOn(GetCampo(linha, "VOLF", "ON"));
   g_scoreAumentos.exigirDirecao = IsOn(GetCampo(linha, "EXIGIR_DIRECAO", "ON"));
   string cfgHistorico = Upper(InpScoreHistorico);
   g_scoreAumentos.adaptarHistoricoHora = (StringFind(cfgHistorico, "OFF") < 0 && StringFind(cfgHistorico, "ONTEM") >= 0);
   g_scoreAumentos.ajustarPeloDiaAtual = (g_scoreAumentos.adaptarHistoricoHora && StringFind(cfgHistorico, "DIA ATUAL") >= 0);
   g_scoreAumentos.pesoHilo8 = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_HILO8", GetCampo(linha, "PESO_HILO", "25"))));
   g_scoreAumentos.pesoSTR = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_STR", "25")));
   g_scoreAumentos.pesoVOLQ = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_VOLQ", "25")));
   g_scoreAumentos.pesoVOLF = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_VOLF", "25")));
   g_scoreAumentos.minimoA1 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A1", "50")));
   g_scoreAumentos.minimoA2 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A2", "75")));
   g_scoreAumentos.minimoA3 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A3", "100")));
   g_scoreAumentos.minimoA4 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A4", "100")));
   g_scoreAumentos.minimoA5 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A5", "100")));
}

bool ModoAumentoSomenteScore()
{
   return (InpModoGatilhoAumentos == AUMENTOS_SOMENTE_POR_SCORE);
}

double MinimoScoreAumentoNivel(int indiceZero)
{
   if(indiceZero <= 0)
      return g_scoreAumentos.minimoA1;
   if(indiceZero == 1)
      return g_scoreAumentos.minimoA2;
   if(indiceZero == 2)
      return g_scoreAumentos.minimoA3;
   if(indiceZero == 3)
      return g_scoreAumentos.minimoA4;
   return g_scoreAumentos.minimoA5;
}

double QualidadeVolumeScoreAdaptativo(bool quantidade, bool &aprovado, string &detalhe)
{
   double ratioHoraBruto = quantidade ? g_mercado.volqRatioHora : g_mercado.volfRatioHora;
   double ratioHoraAjustado = quantidade ? g_mercado.volqRatioAjustadoHora : g_mercado.volfRatioAjustadoHora;
   double ratio5 = quantidade ? g_mercado.volqRatio5m : g_mercado.volfRatio5m;
   double ratio15 = quantidade ? g_mercado.volqRatio15m : g_mercado.volfRatio15m;
   double fatorDia = quantidade ? g_mercado.volqFatorDia : g_mercado.volfFatorDia;
   double baseHora = quantidade ? g_mercado.volqBaseHora : g_mercado.volfBaseHora;
   bool curvaOk = quantidade ? g_mercado.volqCurvaOK : g_mercado.volfCurvaOK;

   bool historicoDisponivel = (baseHora > 0.0 && ratioHoraBruto > 0.0);
   if(!g_scoreAumentos.adaptarHistoricoHora)
   {
      aprovado = (curvaOk || g_mercado.volFarol >= 2 || ratio5 >= 1.0 || ratio15 >= 1.0);
      detalhe = aprovado ? "FIXO_OK" : "FIXO_NAO";
      return aprovado ? 1.0 : 0.0;
   }
   if(!historicoDisponivel)
   {
      double ratioAtualSemBase = MathMax(ratio15 * 0.85, ratio5 * 0.70);
      double qualidadeSemBase = MathMax(0.0, MathMin(1.0, ratioAtualSemBase));
      aprovado = (ratioAtualSemBase >= 1.0);
      detalhe = StringFormat("SEM_BASE_ONTEM | ATUAL %.2f", ratioAtualSemBase);
      return qualidadeSemBase;
   }

   double ratioUsado = g_scoreAumentos.ajustarPeloDiaAtual ? ratioHoraAjustado : ratioHoraBruto;
   if(g_scoreAumentos.ajustarPeloDiaAtual)
      ratioUsado = MathMax(ratioUsado, MathMax(ratio15 * 0.85, ratio5 * 0.70));
   if(g_mercado.volFarol >= 2)
      ratioUsado = MathMax(ratioUsado, 1.0);

   double qualidade = MathMax(0.0, MathMin(1.0, ratioUsado));
   aprovado = (ratioUsado >= 1.0);
   detalhe = StringFormat("ADAPT %.2f | ONTEM_HORA | DIA %.2f", ratioUsado, fatorDia);
   return qualidade;
}

double CalcularScoreAumentoDedicado(ENUM_LADO_ROBO lado, string &detalhe)
{
   detalhe = "SCORE_AUMENTO_OFF";
   if(!g_scoreAumentos.ativo)
      return 100.0;

   double pontos = 0.0;
   double totalPesos = 0.0;
   bool hiloOk = false;
   bool strOk = false;
   bool volqOk = false;
   bool volfOk = false;
   string detalheVolQ = "OFF";
   string detalheVolF = "OFF";

   if(g_scoreAumentos.usarHilo8)
   {
      totalPesos += g_scoreAumentos.pesoHilo8;
      hiloOk = ((lado == LADO_COMPRA && g_mercado.hiloCompra) || (lado == LADO_VENDA && g_mercado.hiloVenda));
      if(hiloOk)
         pontos += g_scoreAumentos.pesoHilo8;
   }
   if(g_scoreAumentos.usarSTR)
   {
      totalPesos += g_scoreAumentos.pesoSTR;
      strOk = ((lado == LADO_COMPRA && g_mercado.strCompra) || (lado == LADO_VENDA && g_mercado.strVenda));
      if(strOk)
         pontos += g_scoreAumentos.pesoSTR;
   }
   if(g_scoreAumentos.usarVOLQ)
   {
      totalPesos += g_scoreAumentos.pesoVOLQ;
      double qualidadeVolQ = QualidadeVolumeScoreAdaptativo(true, volqOk, detalheVolQ);
      pontos += g_scoreAumentos.pesoVOLQ * qualidadeVolQ;
   }
   if(g_scoreAumentos.usarVOLF)
   {
      totalPesos += g_scoreAumentos.pesoVOLF;
      double qualidadeVolF = QualidadeVolumeScoreAdaptativo(false, volfOk, detalheVolF);
      pontos += g_scoreAumentos.pesoVOLF * qualidadeVolF;
   }

   double score = 0.0;
   if(totalPesos > 0.0)
      score = (pontos / totalPesos) * 100.0;
   bool direcaoOk = (!g_scoreAumentos.exigirDirecao || hiloOk || strOk);
   if(!direcaoOk)
      score = 0.0;
   if(score < 0.0)
      score = 0.0;
   if(score > 100.0)
      score = 100.0;

   string modoHistorico = g_scoreAumentos.adaptarHistoricoHora
                          ? (g_scoreAumentos.ajustarPeloDiaAtual ? "ONTEM_HORA+DIA_ATUAL" : "ONTEM_HORA")
                          : "FIXO";
   detalhe = StringFormat("SCORE=%.1f | HILO8=%s | STR=%s | VOLQ=%s[%s] | VOLF=%s[%s] | DIR=%s | BASE=%s",
                          score,
                          hiloOk ? "OK" : "NAO",
                          strOk ? "OK" : "NAO",
                          volqOk ? "OK" : "PARCIAL",
                          detalheVolQ,
                          volfOk ? "OK" : "PARCIAL",
                          detalheVolF,
                          direcaoOk ? "OK" : "NAO",
                          modoHistorico);
   return score;
}

bool ScoreAumentoAutoriza(EstadoLado &estado, int indiceZero, string &detalhe)
{
   if(!g_scoreAumentos.ativo)
   {
      detalhe = "Score de aumentos desligado.";
      return true;
   }
   ENUM_LADO_ROBO lado = LadoDaPosicaoAtual(estado);
   double score = CalcularScoreAumentoDedicado(lado, detalhe);
   double minimo = MinimoScoreAumentoNivel(indiceZero);
   if(score + 0.000001 < minimo)
   {
      detalhe = StringFormat("A%d bloqueado: %.1f < minimo %.1f | %s", indiceZero + 1, score, minimo, detalhe);
      return false;
   }
   detalhe = StringFormat("A%d liberado: %.1f >= minimo %.1f | %s", indiceZero + 1, score, minimo, detalhe);
   return true;
}

string TextoScoreAumentoNivel(EstadoLado &estado, int indiceZero)
{
   if(!g_scoreAumentos.ativo)
      return "SCORE OFF";
   string detalhe = "";
   double score = CalcularScoreAumentoDedicado(LadoDaPosicaoAtual(estado), detalhe);
   return StringFormat("SCORE %.0f/%.0f", score, MinimoScoreAumentoNivel(indiceZero));
}

double MinimoScoreVolumeAumentoFIX334(int indiceZero)
{
   if(indiceZero<=0)
      return MathAbs(InpScoreVolumeMinA1);
   if(indiceZero==1)
      return MathAbs(InpScoreVolumeMinA2);
   if(indiceZero==2)
      return MathAbs(InpScoreVolumeMinA3);
   return MathAbs(InpScoreVolumeMinA4);
}

double CalcularScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, string &detalhe)
{
   detalhe="VOL SCORE OFF";
   if(!InpScoreVolumeAumentosAtivo)
      return 100.0;

   bool qtdOk=false;
   bool finOk=false;
   string detalheQtd="";
   string detalheFin="";
   double qualidadeHoraQtd=QualidadeVolumeScoreAdaptativo(true,qtdOk,detalheQtd);
   double qualidadeHoraFin=QualidadeVolumeScoreAdaptativo(false,finOk,detalheFin);
   qualidadeHoraQtd=MathMax(0.0,MathMin(1.0,qualidadeHoraQtd));
   qualidadeHoraFin=MathMax(0.0,MathMin(1.0,qualidadeHoraFin));

   bool candleDisponivel=(g_mercado.volCandleTempo>0 &&
                          g_mercado.volqMediaCandles>0.0 &&
                          g_mercado.volfMediaCandles>0.0);
   double qualidadeCandleQtd=candleDisponivel ? MathMax(0.0,MathMin(1.0,g_mercado.volqRatioCandle)) : qualidadeHoraQtd;
   double qualidadeCandleFin=candleDisponivel ? MathMax(0.0,MathMin(1.0,g_mercado.volfRatioCandle)) : qualidadeHoraFin;
   // Candle fechado comanda 70%; contexto historico por horario preserva 30%.
   double qualidadeQtd=candleDisponivel ? (qualidadeCandleQtd*0.70+qualidadeHoraQtd*0.30) : qualidadeHoraQtd;
   double qualidadeFin=candleDisponivel ? (qualidadeCandleFin*0.70+qualidadeHoraFin*0.30) : qualidadeHoraFin;

   // O componente mais fraco comanda. Volume financeiro alto sem participacao,
   // ou muita quantidade sem dinheiro real, nao libera aumento arriscado.
   double scoreQtd=qualidadeQtd*100.0;
   double scoreFin=qualidadeFin*100.0;
   double scoreBase=MathMin(scoreQtd,scoreFin);
   double score=scoreBase;
   double forcaLado=ScoreDirecionalDoLado(lado);
   double fatorForca=1.0;
   ENUM_LADO_ROBO direcao=DirecaoMedia25Operacional();
   bool direcaoContra=(direcao!=LADO_NENHUM && direcao!=LADO_AMBOS && direcao!=lado);
   if(InpScoreVolumeAjustarForcaMercado && g_mercado.status>=MERCADO_FORTE)
   {
      fatorForca=0.65+0.35*(MathMax(0.0,MathMin(100.0,forcaLado))/100.0);
      if(direcaoContra)
         fatorForca*=(g_mercado.status==MERCADO_EXTREMO ? 0.55 : 0.75);
      else if(direcao==LADO_NENHUM || direcao==LADO_AMBOS)
         fatorForca*=(g_mercado.status==MERCADO_EXTREMO ? 0.80 : 0.90);
      score=scoreBase*fatorForca;
   }
   score=MathMax(0.0,MathMin(100.0,score));
   string regime=(g_mercado.status==MERCADO_EXTREMO ? "EXTREMO" :
                  (g_mercado.status==MERCADO_FORTE ? "FORTE" :
                   (g_mercado.status==MERCADO_NORMAL ? "NORMAL" : "FRACO")));
   string dirTexto=(direcao==LADO_COMPRA ? "COMPRA" : (direcao==LADO_VENDA ? "VENDA" : "NEUTRA"));
   detalhe=StringFormat("VOL=%.1f BASE=%.1f | CND Qx%.2f Fx%.2f | QTD=%.1f FIN=%.1f | FORCA=%.1f FATOR=%.2f %s/%s",
                        score,scoreBase,g_mercado.volqRatioCandle,g_mercado.volfRatioCandle,
                        scoreQtd,scoreFin,forcaLado,fatorForca,regime,dirTexto);
   return score;
}

bool ScoreVolumeAumentoAutorizaFIX334(ENUM_LADO_ROBO lado, int indiceZero, string &detalhe)
{
   if(!InpScoreVolumeAumentosAtivo)
   {
      detalhe="Score VOL QTD+FIN desligado.";
      return true;
   }
   string leitura="";
   double score=CalcularScoreVolumeAumentoFIX334(lado,leitura);
   double minimo=MinimoScoreVolumeAumentoFIX334(indiceZero);
   if(score+0.000001<minimo)
   {
      detalhe=StringFormat("A%d bloqueado por volume: %.1f < %.1f | %s",
                           indiceZero+1,score,minimo,leitura);
      return false;
   }
   detalhe=StringFormat("A%d volume aprovado: %.1f >= %.1f | %s",
                        indiceZero+1,score,minimo,leitura);
   return true;
}

string TextoScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, int indiceZero)
{
   if(!InpScoreVolumeAumentosAtivo)
      return "VOL OFF";
   string detalhe="";
   double score=CalcularScoreVolumeAumentoFIX334(lado,detalhe);
   return StringFormat("VOL %.0f/%.0f",score,MinimoScoreVolumeAumentoFIX334(indiceZero));
}

void ParseRiscoOperacao(string linha)
{
   g_risco.ativo = IsOn(GetCampo(linha, "", "ON"));
   g_risco.metaOperacao = ExtrairNumero(GetCampo(linha, "META_OP", "150"));
   g_risco.stopOperacao = ExtrairNumero(GetCampo(linha, "STOP_OP", "450"));
   g_risco.valorProtecao = ExtrairNumero(GetCampo(linha, "VALOR_PROT", "75"));
   g_risco.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT_INICIAL", "50%"));
   g_risco.zerar50 = IsOn(GetCampo(linha, "ZERAR_50", "OFF"));
   g_risco.buscar100 = IsOn(GetCampo(linha, "BUSCAR_100", "ON"));
   g_risco.escalonar = IsOn(GetCampo(linha, "ESCALONAR", "ON"));
   g_risco.sincronizarFinanceiro = IsOn(GetCampo(linha, "SINCRONIZAR_FINANCEIRO", "ON"));
}

void ParseRiscoDiario(string linha)
{
   // FIX362: histórico diário nunca bloqueia entrada. O limite operacional
   // vem exclusivamente do campo visível LOSS HEAD.
   g_risco.metaDia = 0.0;
   g_risco.stopDia = LossHeadEfetivoFIX362();
}

void ParseProtecaoLucro(string linha)
{
   g_risco.defesaAtivaEm = ExtrairNumero(GetCampo(linha, "ATIVA_EM", "10R"));
   g_risco.naoVirarPrejuizo = IsOn(GetCampo(linha, "NAO_VIRAR_PREJUIZO", "ON"));
   g_risco.defesaMinima = ExtrairNumero(GetCampo(linha, "DEFESA_MIN", "1"));
   g_risco.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT_PERCENT", "50%"));
   g_risco.trailPasso = ExtrairNumero(GetCampo(linha, "TRAIL_PASSO", "2.5"));
}

void ParseOperacaoLonga(string linha)
{
   g_risco.operacaoLongaAtiva = IsOn(GetCampo(linha, "", "ON"));
   g_risco.ativaLongaEm = ExtrairNumero(GetCampo(linha, "ATIVA_LUCRO", "20R"));
   g_risco.operacaoLongaScoreSaida = ExtrairNumero(GetCampo(linha, "SCORE_VOL_SAIR", "40"));
   g_risco.operacaoLongaSomenteSeGanhoMaiorQue = 50.0;
}

void AplicarParametrosCompactos()
{
   AplicarConfirmacaoLinhasAumentos();
   InpMaxAumentos = ExtrairInteiro(GetCampo(InpAumentos, "MAX_AUMENTOS", GetCampo(InpAumentos, "MAX_AUM", "5")));
   InpMaxContratosTotal = ExtrairInteiro(GetCampo(InpAumentos, "MAX_CONTRATOS", GetCampo(InpAumentos, "MAX_CONTR", "100000")));
   // FIX237: a regra antiga nunca usa score para escolher ou pular niveis.
   // O modo SOMENTE SCORE continua sequencial: A1, depois A2, depois A3.
   InpModoAumentoExecucao = AUMENTO_SEQUENCIAL;
   InpPermitirAumentosNaValidacao = IsOn(GetCampo(InpAumentos, "VALIDACAO", "ON"));
   InpValidacaoAumentoIgnorarScoreExtremo = true; // FIX237: score geral removido da regra antiga.
   InpAumentosLivreTeste = (InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS) ? true :
                              ((InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS) ? false : IsOn(GetCampo(InpAumentos, "LIVRE_TESTE", "OFF")));
   // FIX363: LIVRE pode retirar filtros, mas nunca pode retirar LINHA, CANDLE e PREÇO MELHOR.
   InpAumentosLivreIgnorarTimerPreco = false;
   InpAumentosLivreIgnorarMetaDia = IsOn(GetCampo(InpAumentos, "IGNORAR_META_DIA", "OFF"));
   string dirAum = Upper(GetCampo(InpAumentos, "DIR", "CONTRA"));
   InpAumentosContraPosicao = (dirAum == "CONTRA" || dirAum == "RECUPERACAO" || dirAum == "RECOVERY" || dirAum == "LOSS");
   AplicarAumentoCompactoNosInputs(1, InpA1);
   AplicarAumentoCompactoNosInputs(2, InpA2);
   AplicarAumentoCompactoNosInputs(3, InpA3);
   string filtroA1Normalizado = NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA1Filtros));
   InpAumentosModoFiltro = Upper(GetCampo(filtroA1Normalizado, "MODO", "TODOS"));
   InpAumentosMinOkFiltro = ExtrairInteiro(GetCampo(filtroA1Normalizado, "MIN_OK", "0"));
   InpAumentosConfirmarFechamento = (Upper(GetCampo(filtroA1Normalizado, "CONF", "FECHAMENTO")) == "FECHAMENTO");
   InpAumentosCandlesConfirmacao = ExtrairInteiro(GetCampo(filtroA1Normalizado, "CANDLES", "1"));
   InpAumentosDXMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "DXMIN", "25"));
   InpAumentosRSICompraMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "RSIC", "70"));
   InpAumentosRSIVendaMax = ExtrairNumero(GetCampo(filtroA1Normalizado, "RSIV", "30"));
   InpAumentosVolumeQtdMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "VOLQMIN", "1000"));
   InpAumentosVolumeFinMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "VOLFMIN", "1000000"));
   InpAumentosAgressaoMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "AGFMIN", "50"));
}

void AplicarAumentoCompactoNosInputs(int nivel, string linha)
{
   linha = NormalizarLinhaAumentoHumanizada(linha);
   bool ativo = IsOn(GetCampo(linha, "", "ON"));
   double qtd = ExtrairNumero(GetCampo(linha, "QTD", GetCampo(linha, "A1", GetCampo(linha, "A2", GetCampo(linha, "A3", GetCampo(linha, "A4", "1"))))));
   int tempo = ExtrairInteiro(GetCampo(linha, "TEMPO", GetCampo(linha, "ESPERA", GetCampo(linha, "TIMER", "1m"))));
   double gatilho = ExtrairNumero(GetCampo(linha, "GATILHO", "20G"));
   int distancia = ExtrairInteiro(GetCampo(linha, "DIST", GetCampo(linha, "DISTANCIA", "200p")));
   double protecao = ExtrairNumero(GetCampo(linha, "PROT", "0%")); // FIX282: 50%P removido; TRAIL e lido por nivel em ParseAumento
   if(nivel == 1)
   {
      InpA1Ativo = ativo;
      InpA1Contratos = qtd;
      InpA1TempoMinutos = tempo;
      InpA1GatilhoReais = gatilho;
      InpA1DistanciaPontos = distancia;
      InpA1ProtecaoPercent = protecao;
   }
   else if(nivel == 2)
   {
      InpA2Ativo = ativo;
      InpA2Contratos = qtd;
      InpA2TempoMinutos = tempo;
      InpA2GatilhoReais = gatilho;
      InpA2DistanciaPontos = distancia;
      InpA2ProtecaoPercent = protecao;
   }
   else if(nivel == 3)
   {
      InpA3Ativo = ativo;
      InpA3Contratos = qtd;
      InpA3TempoMinutos = tempo;
      InpA3GatilhoReais = gatilho;
      InpA3DistanciaPontos = distancia;
      InpA3ProtecaoPercent = protecao;
   }
}

void AplicarParcialOperacaoCompacta()
{
   g_parcialOperacaoAtivaEfetiva = InpParcial50Ativa;
   g_parcialGatilhoReaisEfetivo = MathAbs(InpParcialGatilhoReais);
   g_parcialPorContratoEfetivo = InpParcialGatilhoPorContrato;
   g_parcialPassoReaisEfetivo = MathAbs(InpHedgeLucroPontaPassoReais);
   if(g_parcialPassoReaisEfetivo <= 0.0)
      g_parcialPassoReaisEfetivo = MathAbs(InpProtecaoTrailPassoReais);
   if(g_parcialPassoReaisEfetivo <= 0.0)
      g_parcialPassoReaisEfetivo = 5.0;
   g_parcialPercentualVolumeEfetivo = MathAbs(InpParcial50PercentualVolume);
   g_parcialRecuoAumentoAtivoEfetivo = InpParcialRecuoAumentoAtivo;
   g_parcialValorEmPontosEfetivo = false;
   if(g_parcialPercentualVolumeEfetivo <= 0.0)
      g_parcialPercentualVolumeEfetivo = 50.0;
   if(g_parcialPercentualVolumeEfetivo > 100.0)
      g_parcialPercentualVolumeEfetivo = 100.0;
   string linhaRaw = Trim(InpParcialOperacao);
   if(linhaRaw == "")
      return;
   string linha = Upper(linhaRaw);
   string linhaCampo = linha;
   StringReplace(linhaCampo, "|", ";");
   string primeiro = Upper(Trim(GetCampo(linhaCampo, "", "ON")));
   if(primeiro == "OFF" || primeiro == "NAO" || primeiro == "NÃO" || primeiro == "0")
      g_parcialOperacaoAtivaEfetiva = false;
   else if(primeiro == "ON" || primeiro == "SIM" || primeiro == "1")
      g_parcialOperacaoAtivaEfetiva = true;
   string valorCampo = GetCampo(linhaCampo, "PVALOR", GetCampo(linhaCampo, "VALOR", GetCampo(linhaCampo, "PARCIAL", "")));
   string passoCampo = GetCampo(linhaCampo, "PASSO", GetCampo(linhaCampo, "STEP", ""));
   string volumeCampo = GetCampo(linhaCampo, "VOLUME", GetCampo(linhaCampo, "VOL", ""));
   string modoCampo = Upper(GetCampo(linhaCampo, "MODO", ""));
   string partes[];
   int total = StringSplit(linha, '|', partes);
   if(total <= 1)
      total = StringSplit(linha, ';', partes);
   for(int i = 0; i < total; i++)
   {
      string parte = Upper(Trim(partes[i]));
      if(parte == "")
         continue;
      if(StringFind(parte, "OFF") >= 0)
         g_parcialOperacaoAtivaEfetiva = false;
      if(StringFind(parte, "ON") >= 0)
         g_parcialOperacaoAtivaEfetiva = true;
      if(StringFind(parte, "/C") >= 0 || StringFind(parte, "CONTRATO") >= 0)
         g_parcialPorContratoEfetivo = true;
      if(StringFind(parte, "TOTAL") >= 0 || StringFind(parte, "CESTA") >= 0)
         g_parcialPorContratoEfetivo = false;
      if(StringFind(parte, "RECUO") >= 0 || StringFind(parte, "PONT") >= 0 || StringFind(parte, "25P") >= 0 || StringFind(parte, "P;") >= 0)
         g_parcialRecuoAumentoAtivoEfetivo = true;
      if(StringFind(parte, "TOTAL") >= 0 || StringFind(parte, "FINANCEIRO") >= 0 || StringFind(parte, "REAIS") >= 0 || StringFind(parte, " R") >= 0)
         g_parcialRecuoAumentoAtivoEfetivo = false;
      if(StringFind(parte, "P") >= 0 && StringFind(parte, "%") < 0)
         g_parcialValorEmPontosEfetivo = true;
      if(StringFind(parte, "PASSO") >= 0 || StringFind(parte, "STEP") >= 0)
      {
         double vPasso = MathAbs(ExtrairNumero(parte));
         if(vPasso > 0.0)
            g_parcialPassoReaisEfetivo = vPasso;
         continue;
      }
      if(StringFind(parte, "VOL") >= 0 || StringFind(parte, "VOLUME") >= 0)
      {
         double vVol = MathAbs(ExtrairNumero(parte));
         if(vVol > 0.0)
            g_parcialPercentualVolumeEfetivo = MathMin(100.0, vVol);
         continue;
      }
      if(i > 0 && valorCampo == "")
      {
         double vParc = MathAbs(ExtrairNumero(parte));
         if(vParc > 0.0)
         {
            g_parcialGatilhoReaisEfetivo = vParc;
            valorCampo = parte;
         }
      }
   }
   if(valorCampo != "")
   {
      double v = MathAbs(ExtrairNumero(valorCampo));
      if(v > 0.0)
         g_parcialGatilhoReaisEfetivo = v;
      string valorUpper = Upper(valorCampo);
      if(StringFind(valorUpper, "/C") >= 0 || StringFind(valorUpper, "CONTRATO") >= 0)
         g_parcialPorContratoEfetivo = true;
      if(StringFind(valorUpper, "TOTAL") >= 0 || StringFind(valorUpper, "CESTA") >= 0)
         g_parcialPorContratoEfetivo = false;
   }
   if(passoCampo != "")
   {
      double v = MathAbs(ExtrairNumero(passoCampo));
      if(v > 0.0)
         g_parcialPassoReaisEfetivo = v;
   }
   if(volumeCampo != "")
   {
      double v = MathAbs(ExtrairNumero(volumeCampo));
      if(v > 0.0)
         g_parcialPercentualVolumeEfetivo = MathMin(100.0, v);
   }
   if(modoCampo == "TOTAL" || modoCampo == "CESTA")
   {
      g_parcialPorContratoEfetivo = false;
      g_parcialRecuoAumentoAtivoEfetivo = false;
   }
   if(modoCampo == "FINANCEIRO" || modoCampo == "REAIS")
      g_parcialRecuoAumentoAtivoEfetivo = false;
   if(modoCampo == "RECUO" || modoCampo == "RECUO_AUMENTO" || modoCampo == "PONTOS")
   {
      g_parcialRecuoAumentoAtivoEfetivo = true;
      g_parcialValorEmPontosEfetivo = true;
   }
   if(modoCampo == "CONTRATO" || modoCampo == "POR_CONTRATO" || modoCampo == "R/C")
      g_parcialPorContratoEfetivo = true;
}

bool ParcialOperacaoAtivaEfetiva()
{
   return g_parcialOperacaoAtivaEfetiva;
}

double ParcialGatilhoBaseReaisEfetivo()
{
   double v = MathAbs(g_parcialGatilhoReaisEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpParcialGatilhoReais);
   return v;
}

double ParcialPassoBaseReaisEfetivo()
{
   double v = MathAbs(g_parcialPassoReaisEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpHedgeLucroPontaPassoReais);
   if(v <= 0.0)
      v = MathAbs(InpProtecaoTrailPassoReais);
   if(v <= 0.0)
      v = 5.0;
   return v;
}

double ParcialPercentualVolumeEfetivo()
{
   double v = MathAbs(g_parcialPercentualVolumeEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpParcial50PercentualVolume);
   if(v <= 0.0)
      v = 50.0;
   if(v > 100.0)
      v = 100.0;
   return v;
}

bool ParcialPorContratoEfetivo()
{
   return g_parcialPorContratoEfetivo;
}

bool ParcialRecuoAumentoAtivoEfetivo()
{
   return g_parcialRecuoAumentoAtivoEfetivo;
}

long TipoPosicaoPeloLadoEstado(EstadoLado &estado)
{
   if(estado.lado == LADO_COMPRA)
      return POSITION_TYPE_BUY;
   if(estado.lado == LADO_VENDA)
      return POSITION_TYPE_SELL;
   if(estado.tipoPosicaoAtual == POSITION_TYPE_BUY || estado.tipoPosicaoAtual == POSITION_TYPE_SELL)
      return estado.tipoPosicaoAtual;
   return -1;
}

string ValorMatrizCompactaFIX373(string matriz,string chave,string padrao="")
{
   string partes[];
   int total=StringSplit(matriz,'|',partes);
   string alvo=Upper(Trim(chave));
   for(int i=0;i<total;i++)
   {
      string item=Trim(partes[i]);
      int pos=StringFind(item,"=");
      if(pos<1) continue;
      string nome=Upper(Trim(StringSubstr(item,0,pos)));
      if(nome!=alvo) continue;
      return Trim(StringSubstr(item,pos+1));
   }
   return padrao;
}

bool SimCompactoFIX373(string valor,bool padrao=false)
{
   string t=Upper(Trim(valor));
   if(t=="") return padrao;
   if(t=="SIM" || t=="S" || t=="ON" || t=="TRUE" || t=="1" || t=="ATIVO" || t=="ATIVADO") return true;
   if(t=="NAO" || t=="N" || t=="OFF" || t=="FALSE" || t=="0" || t=="INATIVO" || t=="DESATIVADO") return false;
   return padrao;
}

double NumeroCompactoFIX373(string valor,double padrao=0.0)
{
   string t=Upper(Trim(valor));
   if(t=="" || t=="NULO" || t=="VAZIO") return padrao;
   StringReplace(t,",",".");
   StringReplace(t,"R$","");
   StringReplace(t,"%","");
   StringReplace(t," ","");
   int n=StringLen(t);
   while(n>0)
   {
      ushort c=StringGetCharacter(t,n-1);
      if((c>='0' && c<='9') || c=='.') break;
      t=StringSubstr(t,0,n-1);
      n=StringLen(t);
   }
   if(t=="" || t=="-" || t=="+") return padrao;
   return StringToDouble(t);
}

void SepararValoresCompactosFIX373(string valor,string &a,string &b,string &c)
{
   a=""; b=""; c="";
   string p[];
   int n=StringSplit(valor,'/',p);
   if(n>0) a=Trim(p[0]);
   if(n>1) b=Trim(p[1]);
   if(n>2) c=Trim(p[2]);
}

ENUM_MODO_ENTRADA_A0_FIX310 ModoEntradaCompactoFIX373(string valor)
{
   string t=Upper(Trim(valor));
   if(StringFind(t,"FAVOR_E_CONTRA")>=0 || StringFind(t,"AMBOS")>=0) return A0_FIX310_FAVOR_E_CONTRA;
   if(StringFind(t,"CONTRA")>=0) return A0_FIX310_CONTRA;
   if(StringFind(t,"FAVOR")>=0) return A0_FIX310_FAVOR;
   return A0_FIX310_LIVRE;
}

void LerJanelaCompactaFIX373(string matriz,string horarioPadrao,string &horario,string &f1,string &f2,string &f3)
{
   horario=ValorMatrizCompactaFIX373(matriz,"HORARIO",horarioPadrao);
   f1=ValorMatrizCompactaFIX373(matriz,"F1","NULO");
   f2=ValorMatrizCompactaFIX373(matriz,"F2","NULO");
   f3=ValorMatrizCompactaFIX373(matriz,"F3","NULO");
}

bool EntradaA0SemFiltrosCompactaFIX377()
{
   bool usar=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"USAR","SIM"),true);
   string f1=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"1o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F1","NULO"));
   string f2=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"2o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F2","NULO"));
   string f3=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"3o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F3","NULO"));
   string n1=Upper(Trim(f1)),n2=Upper(Trim(f2)),n3=Upper(Trim(f3));
   bool z1=(n1=="" || n1=="0" || n1=="NULL" || n1=="NULO" || n1=="NENHUM" || n1=="OFF" || n1=="LIVRE");
   bool z2=(n2=="" || n2=="0" || n2=="NULL" || n2=="NULO" || n2=="NENHUM" || n2=="OFF" || n2=="LIVRE");
   bool z3=(n3=="" || n3=="0" || n3=="NULL" || n3=="NULO" || n3=="NENHUM" || n3=="OFF" || n3=="LIVRE");
   return (!usar || (z1 && z2 && z3));
}

string FiltroAumentoCompactoInternoFIX377(string linha)
{
   bool usar=SimCompactoFIX373(ValorMatrizCompactaFIX373(linha,"USAR","SIM"),true);
   if(!usar)
      return "LIVRE";
   string f1=Upper(ValorMatrizCompactaFIX373(linha,"1o",ValorMatrizCompactaFIX373(linha,"F1","NULO")));
   string f2=Upper(ValorMatrizCompactaFIX373(linha,"2o",ValorMatrizCompactaFIX373(linha,"F2","NULO")));
   string f3=Upper(ValorMatrizCompactaFIX373(linha,"3o",ValorMatrizCompactaFIX373(linha,"F3","NULO")));
   string todos=f1+" | "+f2+" | "+f3;
   if(StringFind(todos,"RSI")>=0)
   {
      // FIX382: na escrita RSI55/45, 55 e a faixa alta e 45 e a faixa baixa.
      // Como os aumentos sao CONTRA a posicao (recuperacao), compra reforca em sobrevenda
      // e venda reforca em sobrecompra. O filtro continua ativo; apenas a direcao foi corrigida.
      double faixaAlta=55.0,faixaBaixa=45.0;
      double n1=0.0,n2=0.0;
      if(DoisNumerosDepoisDoMarcador(todos,"RSI",n1,n2))
      {
         faixaAlta=MathMax(n1,n2);
         faixaBaixa=MathMin(n1,n2);
      }
      return StringFormat("RSI=ON;RSIC=%.2f;RSIV=%.2f;RSIC_OP=<=;RSIV_OP=>=;MODO=TODOS;MIN_OK=1;CONF=ATUAL;CANDLES=1",faixaBaixa,faixaAlta);
   }
   return "LIVRE";
}

void AplicarMatrizesCompactasFIX373()
{
   // 01 - Magic, lados e janela. FIX378: operacao e janela vem de caixas de escolha reais.
   if(InpOperacaoUsuarioFIX378==VENDIDO)
      InpLadosHabilitadosFIX346=OPERACAO_VENDA;
   else if(InpOperacaoUsuarioFIX378==AMBOS)
      InpLadosHabilitadosFIX346=OPERACAO_AMBOS;
   else
      InpLadosHabilitadosFIX346=OPERACAO_COMPRA;

   InpJanelaDesteGrafico=(InpJanelaUsuarioFIX378==JANELA_B ? JANELA_B_VENDA : JANELA_A_COMPRA);

   string magicCompra=ValorMatrizCompactaFIX373(InpMatrizMagicsFIX378,"MAGIC_COMPRA","326050");
   string magicVenda=ValorMatrizCompactaFIX373(InpMatrizMagicsFIX378,"MAGIC_VENDA","326051");
   InpMagicsCompraVenda=magicCompra+" / "+magicVenda;

   // 02 - HEAD e A0.
   InpAtivarRobo=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ROBO","SIM"),true);
   InpPermitirEnvioOrdens=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ORDENS","SIM"),true);
   InpContratosA0FIX372=(int)MathMax(1.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ENTRADA",ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"A0","1C")),1.0));
   string abertura=Upper(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ABERTURA","LIVRE_PROTEGIDA"));
   if(StringFind(abertura,"DESLIG")>=0) InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_DESLIGADA;
   else if(StringFind(abertura,"NORMAL")>=0) InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_NORMAL;
   else InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_LIVRE_PROTEGIDA;
   InpModoEntradaCompra=ModoEntradaCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"COMPRA","LIVRE"));
   InpModoEntradaVenda=ModoEntradaCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"VENDA","LIVRE"));

   // 03 - Financeiro, escala e reentrada.
   InpGanhoPorTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ALVO",ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GANHO_OPERACAO","50")),50.0));
   InpPerdaPorTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"PERDA",ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"PERDA_OPERACAO","500")),500.0));
   string tA,tB,tC;
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"TRAIL","20/5"),tA,tB,tC);
   InpTrailingAtivarTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,20.0));
   InpTrailingPassoTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,5.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"MOVEL","10/5"),tA,tB,tC);
   InpMovelAtivarTicketReaisFIX395=MathAbs(NumeroCompactoFIX373(tA,10.0));
   InpMovelPassoTicketReaisFIX395=MathAbs(NumeroCompactoFIX373(tB,5.0));
   InpGarantiaPorContratoReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GAR_CTT","100"),100.0));
   InpGarantiaPorLadoReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GAR_LADO","500"),500.0));

   InpMetaDiaEscalonadaAtiva=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"ATIVA","SIM"),true);
   InpProtecaoDiaAtivarReais=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"INICIO","250"),250.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"DEFESAS","50/100/150"),tA,tB,tC);
   InpProtecaoDiaInicialReais=MathAbs(NumeroCompactoFIX373(tA,50.0));
   InpDefesaEscala300ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,100.0));
   InpDefesaEscala350ReaisFIX372=MathAbs(NumeroCompactoFIX373(tC,150.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"RECUOS","75/100/150"),tA,tB,tC);
   InpRecuoEscala400ReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,75.0));
   InpRecuoEscala500ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,100.0));
   InpRecuoEscala600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tC,150.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"ACIMA600","100/50"),tA,tB,tC);
   InpPassoLucroAcima600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,100.0));
   InpAumentoRecuoAcima600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,50.0));
   InpGainGlobalCestaAtivo=false; // SEM_TETO e regra congelada.
   InpReentradaLucroSegundosFIX372=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"REENT_GANHO",ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"GANHO",ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"LUCRO","5S"))),5.0));
   InpPausaReentradaSegundos=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"REENT_PREJUIZO",ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"PREJUIZO",ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"PERDA","120S"))),120.0));

   // 04 - Filtros normais da A0.
   InpFiltroA0_1_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"1o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F1","NULO"));
   InpFiltroA0_2_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"2o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F2","NULO"));
   InpFiltroA0_3_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"3o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F3","NULO"));
   string tf=Upper(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"TEMPO",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"TF","M5")));
   InpTimeframeFiltrosOperacionais=(StringFind(tf,"10")>=0 ? FILTROS_CANDLE_M10 : FILTROS_CANDLE_M5);
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"DX","2/2/0"),tA,tB,tC);
   InpDXPeriodo=(int)MathMax(1.0,NumeroCompactoFIX373(tA,2.0));
   InpDXMediaPeriodo=(int)MathMax(1.0,NumeroCompactoFIX373(tB,2.0));
   InpDXDistanciaMedia=MathMax(0.0,NumeroCompactoFIX373(tC,0.0));

   // 05 - Aumentos e filtros exclusivos do gerenciador.
   InpQuantidadeReforcos=(int)MathMax(0.0,MathMin(5.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"MAX","5"),5.0)));
   string regra=Upper(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"REGRA","LINHA+TIMER+CANDLE+FILTROS"));
   InpModoGatilhoAumentos=(StringFind(regra,"SCORE")>=0 ? AUMENTOS_SOMENTE_POR_SCORE : AUMENTOS_POR_REGRA_ATUAL);
   string base=Upper(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"BASE","A0"));
   if(StringFind(base,"MEDIO")>=0 || StringFind(base,"PROTEG")>=0) InpBasePrecoAumento=BASE_PRECO_MEDIO_PROTEGIDO;
   else if(StringFind(base,"ULTIMO")>=0) InpBasePrecoAumento=BASE_ULTIMO_AUMENTO;
   else InpBasePrecoAumento=BASE_ENTRADA_INICIAL;
   InpFiltroAumento_1_FIX372="RSI";
   InpFiltroAumento_2_FIX372="NULO";
   InpFiltroAumento_3_FIX372="NULO";
   InpA1Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA1CompactoFIX375);
   InpA2Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA2CompactoFIX375);
   InpA3Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA3CompactoFIX375);
   InpA4Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA4CompactoFIX375);
   InpA5Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA5CompactoFIX375);

   // 06 - Janelas sincronizadas somente com a entrada A0.
   LerJanelaCompactaFIX373(InpMatrizJanela1FIX373,"09:00-10:00",InpJanela1HorarioFIX372,InpJanela1Filtro1FIX372,InpJanela1Filtro2FIX372,InpJanela1Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela2FIX373,"10:00-12:00",InpJanela2HorarioFIX372,InpJanela2Filtro1FIX372,InpJanela2Filtro2FIX372,InpJanela2Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela3FIX373,"12:00-15:00",InpJanela3HorarioFIX372,InpJanela3Filtro1FIX372,InpJanela3Filtro2FIX372,InpJanela3Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela4FIX373,"15:00-18:00",InpJanela4HorarioFIX372,InpJanela4Filtro1FIX372,InpJanela4Filtro2FIX372,InpJanela4Filtro3FIX372);

   // 07 - Seguranca e execucao.
   string ambiente=Upper(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"AMBIENTE","DEMO"));
   InpAmbienteExecucaoFIX342=(StringFind(ambiente,"REAL")>=0 ? AMBIENTE_FIX342_REAL : AMBIENTE_FIX342_DEMO);
   InpConfirmarContaRealFIX342=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"CONFIRMAR_REAL","NAO"),false);
   InpContaRealAutorizadaFIX342=(long)NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"CONTA","0"),0.0);
   InpServidorRealAutorizadoFIX342=ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"SERVIDOR","");
   if(Upper(InpServidorRealAutorizadoFIX342)=="VAZIO" || Upper(InpServidorRealAutorizadoFIX342)=="NULO") InpServidorRealAutorizadoFIX342="";
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"SL","SIM/2000"),tA,tB,tC);
   InpStopServidorEmergenciaAtivoFIX342=SimCompactoFIX373(tA,true);
   InpStopServidorEmergenciaPontosFIX342=MathAbs(NumeroCompactoFIX373(tB,2000.0));
   InpSpreadMaximoTicksFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"SPREAD","4"),4.0));
   InpTickMaximoIdadeSegundosFIX342=(int)MathMax(1.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"TICK","5S"),5.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"MARGEM","1000/300%"),tA,tB,tC);
   InpMargemLivreMinimaReaisFIX342=MathAbs(NumeroCompactoFIX373(tA,1000.0));
   InpNivelMargemMinimoPercentFIX342=MathAbs(NumeroCompactoFIX373(tB,300.0));
   InpMaxContratosBrutosABFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"MAX_AB","10"),10.0));
   InpMaxExposicaoLiquidaABFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"LIQ","5"),5.0));
   InpBloquearDiasAntesVencimentoFIX342=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"VENCIMENTO","2D"),2.0));
   InpIntervaloMinimoOrdensRealSegFIX342=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"INTERVALO_REAL","2S"),2.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"COMISSAO","MANUAL/0/SIM"),tA,tB,tC);
   string modoComissao=Upper(tA);
   if(StringFind(modoComissao,"AUTO")>=0) InpModoComissaoAtivoFIX305=COMISSAO_AUTO_FIX305;
   else if(StringFind(modoComissao,"CORRET")>=0 || StringFind(modoComissao,"SERVIDOR")>=0) InpModoComissaoAtivoFIX305=COMISSAO_SERVIDOR_FIX305;
   else InpModoComissaoAtivoFIX305=COMISSAO_MANUAL_IDA_VOLTA_FIX305;
   InpComissaoIdaVoltaPorContratoReaisFIX305=MathAbs(NumeroCompactoFIX373(tB,0.0));
   InpComissaoAfetaFinanceiroRoboFIX305=SimCompactoFIX373(tC,true);
   InpDesvioMaximoPontos=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"DESVIO_A0","20"),20.0));

   // 08 - Encerramento.
   InpHorarioBloquearNovasOperacoes=ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"BLOQUEAR","18:00");
   InpFechamentoFimDiaAtivo=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"ZERAR","SIM"),true);
   InpHorarioFecharTudo=ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"HORARIO","18:15");

   // 09 - Teste e auditoria.
   string teste=Upper(ValorMatrizCompactaFIX373(InpMatrizTesteFIX373,"TESTE","A0+A1-A4"));
   if(teste=="A0" || StringFind(teste,"SOMENTE A0")>=0) InpModoValidacaoExecucao=VALIDAR_A0_APENAS;
   else if(StringFind(teste,"NORMAL")>=0 || StringFind(teste,"COMPLETO")>=0) InpModoValidacaoExecucao=OPERAR_COMPLETO;
   else InpModoValidacaoExecucao=VALIDAR_A0_E_AUMENTOS;
   string auditoria=Upper(ValorMatrizCompactaFIX373(InpMatrizTesteFIX373,"AUDITORIA","CONFIG_ATUAL"));
   if(StringFind(auditoria,"SEM_FILTRO")>=0 || StringFind(auditoria,"LIVRE")>=0) InpCenarioAuditoriaFIX302=AUD302_TESTE_SEM_FILTROS;
   else if(StringFind(auditoria,"COM_FILTRO")>=0) InpCenarioAuditoriaFIX302=AUD302_TESTE_COM_FILTROS;
   else InpCenarioAuditoriaFIX302=AUD302_USAR_CONFIG_ATUAL;
}

#include "modulos/historico_core.mqh"
#include "modulos/cesta_ab_diagnostico.mqh"
bool FecharCestaABOficial(string motivo)
{
   if(!InpSaidaCestaABFecharGrupoInteiro)
   {
      bool okLocal = true;
      bool enviouLocal = false;
      if(g_painelA.posicaoAberta)
      {
         enviouLocal = true;
         if(!FecharPosicoesLado(g_painelA, motivo)) okLocal = false;
      }
      if(g_painelB.posicaoAberta)
      {
         enviouLocal = true;
         if(!FecharPosicoesLado(g_painelB, motivo)) okLocal = false;
      }
      return (enviouLocal && okLocal);
   }
   if(!ExistePosicaoAbertaGrupoTotalAB())
      return false;
   if(!PermiteEnvioOrdem(g_painelA, "Saida financeira A+B"))
      return false;
   FotoCestaAB fotoAntes;
   CalcularFotoCestaABOficial(fotoAntes, false);
   string msgInicio = "SAIDA OFICIAL A+B " + motivo + " | antes: " + TextoLogFotoCestaAB(fotoAntes) +
                      " | regra: fecha todos os Magics do grupo porque a decisão foi pelo saldo_total A+B";
   LogHedgeCompleto("SAIDA_AB_PRE", "ANTES_FECHAR_GRUPO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_OFICIAL", msgInicio, 0, 0, 0.0, 0.0, true);
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][FIX156][SAIDA_AB_OFICIAL] ", msgInicio);
   RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_OFICIAL", msgInicio, 0, 0, 0.0, 0.0, true);
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      string symbol = PositionGetString(POSITION_SYMBOL);
      if(symbol != _Symbol)
         continue;
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      // FIX317: o grupo A+B fecha somente a direção oficial de cada Magic.
      // Comentário antigo não pode deixar uma posição real presa.
      if(!PosicaoSelecionadaPertencePainelFIX316(magic))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         continue;
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = _Symbol;
      req.volume       = NormalizarVolume(volume);
      req.magic        = (ulong)magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " GRUPOAB",req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;
      encontrou = true;
      g_painelA.ultimaTentativaOrdem = TimeCurrent();
      g_painelB.ultimaTentativaOrdem = TimeCurrent();
      string lado = (type == POSITION_TYPE_BUY ? "COMPRA" : "VENDA");
      LogHedgeCompleto("SAIDA_AB_ENVIO", "ENVIO_ORDEM_FECHAMENTO", motivo + " | lado " + lado, ticket, 0, magic, 0, 0, req.volume, req.price, true);
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         string msgOk = StringFormat("SAIDA GRUPO A+B OK %s | Magic %d | Ticket %s | Lado %s | Volume %.2f | Preco %.0f",
                                     motivo,
                                     (int)magic,
                                     IntegerToString((long)ticket),
                                     lado,
                                     req.volume,
                                     req.price);
         RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         LogHedgeCompleto("SAIDA_AB_RESULT", "RESULTADO_ORDEM_FECHAMENTO_OK", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         string msgErro = StringFormat("SAIDA GRUPO A+B REJEITADA %s | Magic %d | Ticket %s | Lado %s | Retcode %s | Erro %s",
                                       motivo,
                                       (int)magic,
                                       IntegerToString((long)ticket),
                                       lado,
                                       IntegerToString((int)res.retcode),
                                       IntegerToString(ultimoErro));
         RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         LogHedgeCompleto("SAIDA_AB_RESULT", "RESULTADO_ORDEM_FECHAMENTO_REJECT", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!encontrou)
   {
      string msgBlock = "SAIDA OFICIAL A+B solicitada, mas nenhuma posição do grupo de Magics foi encontrada.";
      RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_BLOCK", msgBlock, 0, 0, 0.0, 0.0, true);
      RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_BLOCK", msgBlock, 0, 0, 0.0, 0.0, true);
      LogHedgeCompleto("SAIDA_AB_BLOCK", "FECHAMENTO_NAO_ENCONTROU_POSICAO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   }
   LogHedgeCompleto("SAIDA_AB_POS", "DEPOIS_TENTATIVA_FECHAR_GRUPO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   return (encontrou && tudoOk);
}
#include "modulos/resumo_financeiro.mqh"
#include "modulos/filtros_operacionais.mqh"
#include "modulos/protecao_dia.mqh"
#include "modulos/parcial_niveis.mqh"
#include "modulos/parciais_head.mqh"
bool GerenciarParciaisLado(EstadoLado &estado)
{
   if(CestaABTemDuasPontasAbertas())
      return false;
   if(!estado.posicaoAberta)
      return false;
   string cfg = Upper(GetCampo(InpParciais, "", "ON"));
   if(cfg == "OFF" || cfg == "0" || cfg == "FALSE")
      return false;
   double resultadoProtecao = ResultadoProtecaoOperacaoLado(estado);
   double alvo = MathAbs(InpEntradaGanhoAlvoReais);
   double gatilhoParcial = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   if(gatilhoParcial <= 0.0)
   {
      double percMeta = MathAbs(InpParcial50PercentualMeta);
      if(percMeta <= 0.0)
         percMeta = 50.0;
      if(percMeta > 100.0)
         percMeta = 100.0;
      if(alvo > 0.0)
         gatilhoParcial = alvo * (percMeta / 100.0);
   }
   double gatilhoParcialEfetivo = GatilhoParcialEfetivoLado(estado, gatilhoParcial);
   if(ParcialOperacaoAtivaEfetiva() && !estado.parcial50Executada && gatilhoParcialEfetivo > 0.0 && resultadoProtecao >= gatilhoParcialEfetivo)
   {
      double volumeParcial = CalcularVolumeParcialSeguro(estado.contratos, ParcialPercentualVolumeEfetivo());
      if(volumeParcial <= 0.0)
      {
         RegistrarGerenciadorOrdens(estado,
                                    "PARCIAL_BLOCK",
                                    StringFormat("Parcial livre aguardando volume: total %s | gatilho %s | atual %.2f contrato(s). Com 1 contrato não existe meia parcial segura; precisa de aumento ou volume maior.",
                                                 PnlMoedaBRL(resultadoProtecao),
                                                 PnlMoedaBRL(gatilhoParcialEfetivo),
                                                 estado.contratos),
                                    0, 0, 0.0, 0.0, false);
         return false;
      }
      estado.parcial50Executada = true;
      if(InpParcialArmarProtecao)
      {
         if(resultadoProtecao > estado.melhorResultadoAberto)
            estado.melhorResultadoAberto = resultadoProtecao;
         estado.lucroProtegido = true;
         ArmarProtecaoFinanceiraLado(estado, "PARCIAL_PROTECAO", true);
      }
      bool ok = FecharParcialPosicoesLado(estado, volumeParcial, "PARCIAL_LIVRE_REAIS");
      if(!ok)
         estado.parcial50Executada = false;
      return ok;
   }
   if(InpParcialFinalFecharTudo && !estado.parcialFinalExecutada && alvo > 0.0 && resultadoProtecao >= alvo)
   {
      estado.parcialFinalExecutada = true;
      bool ok = FecharPosicoesLado(estado, "PARCIAL_FINAL_100");
      if(!ok)
         estado.parcialFinalExecutada = false;
      return ok;
   }
   return false;
}

double NormalizarVolumeParaFechamento(double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   double vol = MathFloor(volume / step) * step;
   if(vol < minVol)
      return 0.0;
   if(maxVol > 0.0 && vol > maxVol)
      vol = maxVol;
   return NormalizeDouble(vol, 2);
}

double CalcularVolumeParcialSeguro(double volumeAtual, double percentualVolume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   if(volumeAtual <= minVol + 0.0001)
      return 0.0;
   double perc = MathAbs(percentualVolume);
   if(perc <= 0.0)
      perc = 50.0;
   if(perc > 100.0)
      perc = 100.0;
   double desejado = volumeAtual * (perc / 100.0);
   double vol = NormalizarVolumeParaFechamento(desejado);
   if(vol <= 0.0)
      return 0.0;
   if((volumeAtual - vol) > 0.0001 && (volumeAtual - vol) < minVol)
      vol = NormalizarVolumeParaFechamento(volumeAtual - minVol);
   if(vol <= 0.0)
      return 0.0;
   if(vol >= volumeAtual - 0.0001)
      return 0.0;
   return vol;
}

bool FecharParcialPosicoesLado(EstadoLado &estado, double volumeDesejado, string motivo)
{
   if(!estado.posicaoAberta)
      return false;
   if(!PermiteEnvioOrdem(estado, "Saida parcial"))
      return false;
   double restante = NormalizarVolumeParaFechamento(volumeDesejado);
   if(restante <= 0.0)
   {
      RegistrarGerenciadorOrdens(estado, "PARCIAL_BLOCK", "Parcial bloqueada: volume desejado abaixo do mínimo do ativo.", 0, 0, volumeDesejado, 0.0, true);
      return false;
   }
   bool enviouAlgo = false;
   bool tudoOk = true;
   double volumeEnviado = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0 && restante > 0.0001; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double volumePosicao = PositionGetDouble(POSITION_VOLUME);
      if(volumePosicao <= 0.0)
         continue;
      double volFechar = MathMin(volumePosicao, restante);
      volFechar = NormalizarVolumeParaFechamento(volFechar);
      if(volFechar <= 0.0)
         continue;
      double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if((volumePosicao - volFechar) > 0.0001 && (volumePosicao - volFechar) < minVol)
      {
         volFechar = NormalizarVolumeParaFechamento(volumePosicao - minVol);
         if(volFechar <= 0.0)
            continue;
      }
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = _Symbol;
      req.volume       = volFechar;
      req.magic        = (ulong)estado.magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " " + estado.nome,req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;
      estado.ultimaTentativaOrdem = TimeCurrent();
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         enviouAlgo = true;
         volumeEnviado += req.volume;
         restante -= req.volume;
         RegistrarGerenciadorOrdens(estado, "PARCIAL_OK",
                                    StringFormat("PARCIAL ENVIADA %s | Ticket %s | Volume %.2f | Aberto %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 req.volume,
                                                 PnlMoedaBRL(estado.resultadoAberto)),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estado, "PARCIAL_REJECT",
                                    StringFormat("PARCIAL REJEITADA %s | Ticket %s | Retcode %s | Erro %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 IntegerToString((int)res.retcode),
                                                 IntegerToString(ultimoErro)),
                                    res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!enviouAlgo)
      RegistrarGerenciadorOrdens(estado, "PARCIAL_BLOCK", "Parcial solicitada, mas nenhuma posição válida do Magic/instância foi encontrada.", 0, 0, volumeDesejado, 0.0, true);
   return (enviouAlgo && tudoOk);
}

bool SinalSaidaOperacaoLonga(EstadoLado &estado)
{
   if(!estado.modoLongo)
      return false;
   bool fluxoFraco = (g_mercado.scoreFluxo <= MathAbs(InpOperacaoLongaScoreSaida));
   bool volumeQtdFraco = false;
   if(InpOperacaoLongaUsarVolumeQtd)
      volumeQtdFraco = (!g_mercado.volqCurvaOK && g_mercado.volFarol <= 1);
   bool volumeFinFraco = false;
   if(InpOperacaoLongaUsarVolumeFin)
      volumeFinFraco = (!g_mercado.volfCurvaOK && g_mercado.volFarol <= 1);
   ENUM_LADO_ROBO ladoAtual = LadoDaPosicaoAtual(estado);
   bool hiloContra = false;
   if(InpOperacaoLongaUsarHiLo)
   {
      if(ladoAtual == LADO_COMPRA)
         hiloContra = g_mercado.hiloVenda;
      else if(ladoAtual == LADO_VENDA)
         hiloContra = g_mercado.hiloCompra;
   }
   bool strContra = false;
   if(InpOperacaoLongaUsarSTR)
   {
      if(ladoAtual == LADO_COMPRA)
         strContra = g_mercado.strVenda;
      else if(ladoAtual == LADO_VENDA)
         strContra = g_mercado.strCompra;
   }
   return (fluxoFraco || volumeQtdFraco || volumeFinFraco || hiloContra || strContra);
}

#include "modulos/validacoes_entrada_aumento.mqh"
#include "modulos/preflight_stops_ordens.mqh"
#include "modulos/envio_ordem_mercado.mqh"
#include "modulos/entrada_direta.mqh"
bool FecharPosicoesLado(EstadoLado &estado, string motivo)
{
   if(!estado.posicaoAberta)
      return false;
   if(!PermiteEnvioOrdem(estado, "Saida financeira"))
      return false;
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         continue;
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = _Symbol;
      req.volume       = NormalizarVolume(volume);
      req.magic        = (ulong)estado.magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " " + estado.nome,req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;
      encontrou = true;
      estado.ultimaTentativaOrdem = TimeCurrent();
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         RegistrarGerenciadorOrdens(estado, "SAIDA_OK",
                                    StringFormat("SAIDA ENVIADA %s | Ticket %s | Volume %.2f | Aberto %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 req.volume,
                                                 PnlMoedaBRL(estado.resultadoAberto)),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estado, "SAIDA_REJECT",
                                    StringFormat("SAIDA REJEITADA %s | Ticket %s | Retcode %s | Erro %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 IntegerToString((int)res.retcode),
                                                 IntegerToString(ultimoErro)),
                                    res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!encontrou)
      RegistrarGerenciadorOrdens(estado, "SAIDA_BLOCK", "Saida solicitada, mas nenhuma posicao do Magic/lado foi encontrada.", 0, 0, 0.0, 0.0, true);
   return (encontrou && tudoOk);
}

#include "modulos/logs_auditoria.mqh"
#include "modulos/locks_ordens.mqh"

#include "modulos/painel.mqh"
#include "modulos/auditoria_core.mqh"

#include "modulos/exportacao_semanal.mqh"

#include "modulos/auditoria_visual.mqh"
