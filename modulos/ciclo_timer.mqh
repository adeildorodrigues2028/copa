#ifndef COPA_CICLO_TIMER_MQH
#define COPA_CICLO_TIMER_MQH

// ============================================================================
// RESPONSABILIDADE: ORQUESTRACAO DO TIMER
// Funcoes movidas do principal na V43 sem alteracao de regra operacional.
// ============================================================================

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


#endif // COPA_CICLO_TIMER_MQH
