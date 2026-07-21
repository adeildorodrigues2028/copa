#ifndef COPA_CICLO_INICIALIZACAO_MQH
#define COPA_CICLO_INICIALIZACAO_MQH

// ============================================================================
// RESPONSABILIDADE: INICIALIZACAO DO EXPERT ADVISOR
// Funcoes movidas do principal na V43 sem alteracao de regra operacional.
// ============================================================================

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
   string motivoLadosV36="";
   g_ladosOpostosOKV36=AuditarLadosOpostosV36(motivoLadosV36);
   g_ladosOpostosStatusV36=(g_ladosOpostosOKV36 ? "APROVADO: A=BUY E B=SELL" : "BLOQUEADO: "+motivoLadosV36);
   Print("[COPA_AR100][V36][AUDITORIA_LADOS] ",g_ladosOpostosStatusV36,
         " | MagicA=",IntegerToString((int)MagicCompraAtual()),
         " | MagicB=",IntegerToString((int)MagicVendaAtual()),
         " | Selecao=",TextoLadosHabilitadosFIX346(),
         " | Entrada=",TextoModoEntradaA0FIX310());
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


#endif // COPA_CICLO_INICIALIZACAO_MQH
