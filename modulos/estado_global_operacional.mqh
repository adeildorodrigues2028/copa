#ifndef COPA_ESTADO_GLOBAL_OPERACIONAL_MQH
#define COPA_ESTADO_GLOBAL_OPERACIONAL_MQH

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

#endif // COPA_ESTADO_GLOBAL_OPERACIONAL_MQH
