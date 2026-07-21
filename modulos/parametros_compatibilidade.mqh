#ifndef COPA_PARAMETROS_COMPATIBILIDADE_MQH
#define COPA_PARAMETROS_COMPATIBILIDADE_MQH

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


#endif // COPA_PARAMETROS_COMPATIBILIDADE_MQH
