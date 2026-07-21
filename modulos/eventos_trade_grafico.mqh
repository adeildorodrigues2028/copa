#ifndef COPA_EVENTOS_TRADE_GRAFICO_MQH
#define COPA_EVENTOS_TRADE_GRAFICO_MQH

// ============================================================================
// RESPONSABILIDADE: ENCERRAMENTO, NEGOCIOS E EVENTOS DO GRAFICO
// Funcoes movidas do principal na V43 sem alteracao de regra operacional.
// ============================================================================

void OnDeinit(const int reason)
{
   // V36: checkpoint financeiro antes de encerrar ou reinicializar o EA.
   SalvarControleDiaFIX310(true);
   PersistirProtecaoDiaEscalonadaFIX333();
   GlobalVariablesFlush();
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


#endif // COPA_EVENTOS_TRADE_GRAFICO_MQH
