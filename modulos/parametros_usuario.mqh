#ifndef COPA_PARAMETROS_USUARIO_MQH
#define COPA_PARAMETROS_USUARIO_MQH

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

input group "01 | COMECE AQUI - MAGIC E OPERACAO"
input string InpMatrizMagicsFIX378 = "MAGIC_COMPRA=326050 | MAGIC_VENDA=326051"; // Identificacao exclusiva: exemplo COMPRA=326050 e VENDA=326051.
input ENUM_OPERACAO_USUARIO_FIX378 InpOperacaoUsuarioFIX378 = COMPRADO; // Qual lado deseja operar?
input ENUM_JANELA_USUARIO_FIX378 InpJanelaUsuarioFIX378 = JANELA_A; // Esta instancia sera a janela de compra ou de venda?

input group " "
input group "02 | JANELAS DE HORARIO E SEUS FILTROS"
input string InpMatrizJanela1FIX373 = "HORARIO=09:00-10:00 | F1=NULO | F2=NULO | F3=NULO"; // O timer controla o horario; NULO deixa somente o filtro desta janela livre.
input string InpMatrizJanela2FIX373 = "HORARIO=10:00-12:00 | F1=NULO | F2=NULO | F3=NULO"; // Segunda janela com filtros proprios e independentes.
input string InpMatrizJanela3FIX373 = "HORARIO=12:00-15:00 | F1=NULO | F2=NULO | F3=NULO"; // Terceira janela com filtros proprios e independentes.
input string InpMatrizJanela4FIX373 = "HORARIO=15:00-18:00 | F1=NULO | F2=NULO | F3=NULO"; // Quarta janela com filtros proprios e independentes.

input group "  "
input group "03 | PRIMEIRA ENTRADA E REENTRADA"
input string InpMatrizHeadEntradaFIX373 = "CONTRATOS=1C | ALVO=50 | PERDA=500 | PROTEGE=25/10 | ACOMPANHA=50/25"; // Ex.: 1 contrato; alvo R$50; perda R$500; protege 10 ao chegar em 25.
input string InpMatrizReentradaFIX373 = "APOS_GANHO=5S | APOS_PERDA=120S"; // Ex.: espera 5s apos ganho e 120s apos perda.

input group "   "
input group "04 | FILTROS DA PRIMEIRA ENTRADA A0"
input string InpMatrizFiltrosEntradaFIX373 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | CONFIRMA=0 | TEMPO=M5"; // Ex.: USAR=NAO deixa livre; filtros aceitos: RSI, VOLUME, FORCA, HILO, STR ou MEDIA.

input group "    "
input group "05 | ENTRADAS ADICIONAIS"
input string InpMatrizControleAumentosFIX373 = "USAR=SIM | MAX=4 | SEQUENCIA=A1-A2-A3-A4 | TIMER=5S_TESTE | BASE=A0"; // Ex.: permite quatro entradas adicionais em sequencia.
input int InpIntervaloMinimoEntreAumentosSegundosFIX434 = 5; // Espera minima entre duas entradas adicionais; recomendado 120s em operacao normal.
input string InpA1ExecucaoFIX340 = "A1=1C | ESPERA=0M | DIST=25 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // Primeira adicional: contratos, espera, distancia e protecao individual.
input string InpA2ExecucaoFIX340 = "A2=1C | ESPERA=0M | DIST=50 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // Segunda adicional: exemplo a 50 pontos da referencia.
input string InpA3ExecucaoFIX340 = "A3=1C | ESPERA=0M | DIST=75 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // Terceira adicional: exemplo a 75 pontos da referencia.
input string InpA4ExecucaoFIX340 = "A4=1C | ESPERA=0M | DIST=100 | ALVO=10 | MOVEL=25/10 [25->10] | TRAIL=50/25 [50->25;CONTINUO]"; // Quarta adicional: exemplo a 100 pontos da referencia.
input string InpA5ExecucaoFIX340 = "A5=0C | ESPERA=0M | DIST=0 | MOVEL=0/0 | TRAIL=0/0"; // Quinta adicional: 0C mantem esta entrada desligada.
input int InpRSIPeriodoAumentosFIX399 = 7; // Periodo do RSI usado somente quando escolhido nos filtros adicionais.
input string InpAjudaFiltrosAumentosFIX407 = "EXEMPLOS: RSI + VOLUME + AGRESSAO + FORCA + HILO8 + STR + MEDIA | NULO DESLIGA"; // Ajuda: NULO significa sem filtro.
input string InpFiltroA1CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // Filtros da primeira adicional.
input string InpFiltroA2CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // Filtros da segunda adicional.
input string InpFiltroA3CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // Filtros da terceira adicional.
input string InpFiltroA4CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // Filtros da quarta adicional.
input string InpFiltroA5CompactoFIX375 = "USAR=NAO | 1o=NULO | 2o=NULO | 3o=NULO | TEMPO=M1"; // Filtros da quinta adicional.
string InpMatrizFiltrosAumentosFIX373 = "F1=RSI | F2=NULO | F3=NULO"; // Compatibilidade interna; cada nivel usa seu filtro proprio FIX375.
input bool InpMostrarCaixasLinhasOperacionaisFIX399 = false; // Mostrar mensagens das entradas adicionais no grafico?

input group "     "
input group "06 | PROTECAO E GARANTIA FINANCEIRA"
input string InpMatrizFinanceiroFIX373 = "GARANTIA_CONTRATO=100 | GARANTIA_LADO=500"; // Ex.: reserva R$100 por contrato e limita cada lado a R$500 de garantia.
input string InpMatrizEscalaHeadFIX373 = "ATIVA=SIM | INICIO=250 | DEFESAS=50/100/150 | RECUOS=75/100/150 | ACIMA600=100/50 | SEM_TETO=SIM"; // Ex.: inicia em R$250 e aumenta a protecao conforme o melhor ganho.

input group "      "
input group "07 | SEGURANCA DA CONTA E DAS ORDENS"
input string InpMatrizAmbienteFIX373 = "AMBIENTE=DEMO | CONFIRMAR_REAL=NAO | CONTA=0 | SERVIDOR=VAZIO"; // Ex.: conta real exige confirmacao, numero da conta e servidor corretos.
input string InpMatrizProtecoesFIX373 = "SL=SIM/2000 | SPREAD=4 | TICK=5S | MARGEM=1000/300% | MAX_AB=10 | LIQ=5"; // Ex.: stop no servidor, spread maximo, cotacao valida, margem e exposicao.
input string InpMatrizCustosFIX373 = "VENCIMENTO=2D | INTERVALO_REAL=2S | COMISSAO=MANUAL/0/SIM | DESVIO_A0=20"; // Ex.: bloqueia perto do vencimento e controla custos e intervalo entre ordens.

input group "       "
input group "08 | ENCERRAMENTO DO DIA"
input string InpMatrizEncerramentoFIX373 = "BLOQUEAR=18:00 | ZERAR=SIM | HORARIO=18:15"; // Ex.: para novas entradas as 18:00 e fecha posicoes as 18:15.

input group "        "
input group "09 | FILTRO DE DISTANCIA E FORCA"
input bool InpDXAdaptativoAtivoFIX410 = true; // Usar protecao por distancia e forca do movimento?
input bool InpDXPlotarBandasFIX410 = true; // Mostrar os limites calculados no grafico?
input bool InpDXUsarA0FIX411 = true; // Aplicar na primeira entrada?
input bool InpDXUsarAumentosFIX411 = false; // Aplicar tambem nas entradas adicionais?
input bool InpDXEntradaProximoCandleFIX411 = true; // Confirmar no fechamento e entrar no candle seguinte?
input int InpDXMediaPeriodoFIX411 = 25; // Periodo da media de referencia; exemplo 25.
input ENUM_MA_METHOD InpDXMediaMetodoFIX411 = MODE_SMA; // Tipo da media de referencia.
input ENUM_APPLIED_PRICE InpDXMediaPrecoFIX411 = PRICE_CLOSE; // Preco usado no calculo da media.
input int InpDXAmostraCandlesFIX411 = 14; // Quantidade de candles analisados; exemplo 14.
input string InpDXAberturaManualFIX411 = "ATE=09:25 | DX=1000P"; // Regra antes do historico estar completo; exemplo ate 09:25 usa 1000 pontos.
input double InpDXManualAberturaPontosFIX411 = 1000.0; // Distancia provisoria na abertura, em pontos.
input string InpDXHorarioInicioAutoFIX411 = "09:25"; // Horario em que o calculo automatico comeca.
input double InpDXForcaBloqueioContraFIX411 = 75.0; // Forca contraria que bloqueia uma entrada.
input double InpDXForcaLiberacaoFIX411 = 65.0; // Forca necessaria para liberar novamente.
input double InpDXPercentualExtremoMinFIX411 = 45.0; // Percentual minimo da distancia extrema.
input double InpDXPercentualExtremoMaxFIX411 = 85.0; // Percentual maximo da distancia extrema.
input int InpDXBarrasPlotadasFIX411 = 120; // Quantidade de candles mostrados no grafico.
input string InpDXComponentesForcaFIX410 = "HILO + STR + VOL QTD + VOL FIN + RSI + INCLINACAO"; // Componentes usados para medir a forca de 0 a 100.

input group "10 | MARCACOES DE ENTRADAS NO GRAFICO"
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
input string InpDXRegraCompactaFIX410 = "NORMAL: EXTREMO >=200P -> RETORNO -> HILO/STR -> CANDLE DIRECIONAL + ROMPIMENTO"; // Resumo da regra usada para marcar uma entrada.
input string InpDXVisualCompactoFIX410 = "DX ATUAL + FORCA COMPRA/VENDA + REGIME + LIBERADO/BLOQUEADO"; // Informacoes exibidas no resumo visual.

input group "10.1 | SELECIONAR SOMENTE OS MELHORES SINAIS"
input bool InpDXMasterAtivoFIX430 = true; // Ativar selecao dos melhores sinais?
input bool InpDXMasterMostrarSomenteMelhoresFIX430 = true; // Mostrar somente sinais aprovados?
input bool InpDXMasterExigirPOCFIX430 = true; // Exigir confirmacao da regiao de maior volume?
input bool InpDXMasterExigirBollOuKeltFIX430 = true; // Exigir confirmacao de Bollinger ou Keltner?
input int InpDXMasterMinimoExtrasFIX430 = 2; // Quantidade minima de confirmacoes adicionais.
input bool InpDXMasterUsarFundoTetoFIX430 = true; // Considerar regioes de fundo e teto?
input int InpDXMasterPeriodoPOCFIX430 = 100; // Candles usados na regiao de maior volume.
input int InpDXMasterFaixaPOCPontosFIX430 = 10; // Tamanho de cada faixa de preco, em pontos.
input double InpDXMasterDistanciaPOCPontosFIX430 = 50.0; // Distancia permitida da regiao de maior volume.
input int InpDXMasterPeriodoBollFIX430 = 20; // Periodo das bandas de Bollinger.
input double InpDXMasterDesvioBollFIX430 = 2.0; // Desvio das bandas de Bollinger.
input int InpDXMasterPeriodoEMAFIX430 = 20; // Periodo da media do canal Keltner.
input int InpDXMasterPeriodoATRFIX430 = 10; // Periodo da volatilidade do canal Keltner.
input double InpDXMasterMultiplicadorKeltFIX430 = 1.5; // Largura do canal Keltner.
input int InpDXMasterPeriodoFundoTetoFIX430 = 100; // Candles usados para localizar fundo e teto.
input double InpDXMasterDistanciaTetoFundoPontosFIX430 = 30.0; // Distancia permitida do fundo ou teto.

input group "           "
input group "11 | TESTE E AUDITORIA"
input string InpMatrizTesteFIX373 = "TESTE=A0+A1-A4 | AUDITORIA=CONFIG_ATUAL"; // A0 usa a linha USAR=NAO; A1-A4 mantem RSI proprio, timer, distancia e gatilho.

input group "12 | MOTOR DE CANAIS - OPERACAO"
input bool InpUsarMotorCanais = true; // Usar o motor de canais?
input ENUM_OPERACAO_CANAIS InpOperacaoMotorCanais = CANAIS_AMBOS; // Quais lados o motor de canais pode operar?
input ENUM_TIMEFRAMES InpTimeframeCanais = PERIOD_M1; // Tempo grafico usado pelo motor de canais.
input long InpMagicCompraCanais = 888060; // Identificacao exclusiva das compras dos canais.
input long InpMagicVendaCanais  = 888061; // Identificacao exclusiva das vendas dos canais; deve ser diferente.

input group "13 | MOTOR DE CANAIS - CONFIRMACOES"
input bool InpCanaisUsarBollinger = true; // Usar bandas de Bollinger?
input int InpCanaisPeriodoBollinger = 20; // Periodo de Bollinger; exemplo 20.
input double InpCanaisDesvioBollinger = 2.0; // Largura das bandas; exemplo 2.0.
input bool InpCanaisUsarKeltner = true; // Usar canal Keltner?
input int InpCanaisPeriodoEMA = 20; // Periodo da media do Keltner.
input int InpCanaisPeriodoATR = 10; // Periodo da volatilidade do Keltner.
input double InpCanaisMultiplicadorKeltner = 1.5; // Largura do Keltner; exemplo 1.5.
input bool InpCanaisUsarPOC = true; // Usar regiao de maior volume?
input int InpCanaisPeriodoPOC = 100; // Candles analisados para maior volume.
input int InpCanaisFaixaPrecoPOCPontos = 10; // Tamanho da faixa de preco, em pontos.
input double InpCanaisDistanciaMinimaPOCPontos = 50; // Distancia minima da regiao de maior volume.
input bool InpCanaisUsarFundoTeto = true; // Usar regioes de fundo e teto?
input int InpCanaisPeriodoFundoTeto = 100; // Candles analisados para fundo e teto.
input double InpCanaisDistanciaMinimaFundoPontos = 30; // Distancia minima do fundo, em pontos.
input double InpCanaisDistanciaMinimaTetoPontos = 30; // Distancia minima do teto, em pontos.
input bool InpCanaisPermitirRompimentoConfirmado = true; // Permitir entrada depois de rompimento confirmado?

input group "13.1 | MOTOR DE CANAIS - APARENCIA"
input bool InpCanaisMostrarBollingerGrafico = false; // Mostrar Bollinger no grafico?
input bool InpCanaisMostrarKeltnerGrafico = false; // Mostrar Keltner no grafico?
input bool InpCanaisMostrarPOCGrafico = true; // Mostrar regiao de maior volume?
input bool InpCanaisMostrarEntradasHistoricasGrafico = true; // Mostrar entradas encontradas no historico?
input int InpCanaisVisualHistoricoCandles = 600; // Quantidade de candles desenhados.
input int InpCanaisVisualDistanciaSetaPontos = 25; // Distancia das setas em relacao ao candle.
input bool InpComparativoDXCanaisAtivo = true; // Comparar sinais de distancia com sinais dos canais?
input int InpComparativoToleranciaCandles = 2; // Diferenca maxima de candles para considerar concordancia.
input bool InpComparativoDestacarConcordancias = true; // Destacar sinais em que os dois motores concordam?

input group "14 | MOTOR DE CANAIS - DECISAO"
input ENUM_MODO_DECISAO_CANAIS InpModoDecisaoCanais = CANAIS_TODOS_CONFIRMAM; // Como as confirmacoes devem liberar a entrada?
input int InpConfirmacoesMinimasCanais = 3; // Quantidade minima quando o modo permitir contagem.
input bool InpCanaisConfirmarCandleFechado = true; // Esperar o candle fechar antes de confirmar?
input int InpCanaisCandlesConfirmacao = 1; // Quantos candles devem confirmar?
input int InpCanaisTempoRearmeSegundos = 120; // Espera depois de uma saida antes de nova entrada.

input group "15 | MOTOR DE CANAIS - CONTRATOS E SAIDAS"
input int InpCanaisContratoA0 = 3; // Quantidade de contratos da primeira entrada.
input bool InpCanaisUsarParcial = true; // Realizar uma parte e manter o restante aberto?
input int InpCanaisContratosParcial = 1; // Contratos encerrados na primeira realizacao.
input double InpCanaisAlvoFinanceiro = 50.0; // Ganho que ativa a primeira realizacao, em reais.
input bool InpCanaisFecharTudoNoAlvo = false; // Fechar tudo ao atingir o ganho?
input double InpCanaisStopFinanceiro = 500.0; // Limite de perda do motor de canais, em reais.
input double InpCanaisMovelAtiva = 50.0; // Ganho que ativa a primeira protecao.
input double InpCanaisMovelDefende = 0.0; // Valor minimo protegido depois da ativacao.
input double InpCanaisTrailingAtiva = 75.0; // Ganho que inicia o acompanhamento continuo.
input double InpCanaisTrailingPasso = 25.0; // Distancia mantida do melhor resultado.
input bool InpCanaisSairPerdaSinal = true; // Encerrar quando os canais perderem a confirmacao?

input group "                "
input group "16 | AVANCADO - COLETA E EXPORTACAO"
input bool InpTesteTicksCompletoFIX433 = true; // Ativar coleta detalhada para auditoria?
input int InpTesteDiasFIX433 = 90; // Quantidade de dias da auditoria; exemplo 90.
input bool InpTesteExportarCadaTickFIX433 = true; // Exportar cada mudanca de preco?
input bool InpTesteExportarPosicoesFIX433 = true; // Exportar fotografias das posicoes?
input bool InpTesteExportarNegociosFIX433 = true; // Exportar negocios executados?
input bool InpTesteExportarSomenteTestadorFIX433 = false; // Exportar somente durante simulacao?
input int InpTesteFlushSegundosFIX433 = 5; // Intervalo para gravar dados no disco.
input double InpTesteAtivaZeroReaisFIX433 = 25.0; // Ganho que ativa protecao no teste.
input double InpTesteDefesaPassoReaisFIX433 = 25.0; // Valor protegido no teste.
input double InpTesteTrailingAtivaReaisFIX433 = 50.0; // Ganho que inicia acompanhamento no teste.
input double InpTesteTrailingDistanciaReaisFIX433 = 25.0; // Distancia do melhor ganho no teste.
input bool InpTesteExportarMinutoFIX435 = true; // Exportar um registro por minuto fechado?
input int InpTestePOCPeriodoFIX435 = 100; // Candles usados na regiao de maior volume.
input int InpTestePOCFaixaPontosFIX435 = 10; // Tamanho da faixa de preco em pontos.
input int InpTesteBollPeriodoFIX435 = 20; // Periodo de Bollinger usado na exportacao.
input double InpTesteBollDesvioFIX435 = 2.0; // Desvio de Bollinger usado na exportacao.
input int InpTesteKeltEMA_FIX435 = 20; // Periodo da media Keltner usada na exportacao.
input int InpTesteKeltATR_FIX435 = 10; // Periodo da volatilidade Keltner.
input double InpTesteKeltMultiplicadorFIX435 = 1.5; // Largura do Keltner na exportacao.
input int InpTesteHiloPeriodoFIX435 = 14; // Periodo Hilo usado na exportacao.
input int InpTesteSTRPeriodoFIX435 = 14; // Periodo de tendencia usado na exportacao.

#endif // COPA_PARAMETROS_USUARIO_MQH
