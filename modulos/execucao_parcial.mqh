#ifndef COPA_EXECUCAO_PARCIAL_MQH
#define COPA_EXECUCAO_PARCIAL_MQH

// ============================================================================
// RESPONSABILIDADE: EXECUCAO DAS ORDENS DE SAIDA PARCIAL
// Funcoes movidas do principal na V45 sem alteracao de regra operacional.
// ============================================================================

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


#endif // COPA_EXECUCAO_PARCIAL_MQH
