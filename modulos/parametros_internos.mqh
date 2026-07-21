#ifndef COPA_PARAMETROS_INTERNOS_MQH
#define COPA_PARAMETROS_INTERNOS_MQH

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


#endif // COPA_PARAMETROS_INTERNOS_MQH
