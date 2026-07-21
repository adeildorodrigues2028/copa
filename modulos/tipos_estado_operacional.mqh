#ifndef COPA_TIPOS_ESTADO_OPERACIONAL_MQH
#define COPA_TIPOS_ESTADO_OPERACIONAL_MQH

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

#endif // COPA_TIPOS_ESTADO_OPERACIONAL_MQH
