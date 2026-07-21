#ifndef COPA_FECHAMENTO_POSICOES_MQH
#define COPA_FECHAMENTO_POSICOES_MQH

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

ENUM_ORDER_TYPE_FILLING TipoPreenchimentoSeguro()
{
   // FIX317: RETURN não é permitido em Market Execution.
   // Primeiro respeita a preferência configurada quando ela é aceita;
   // depois escolhe automaticamente uma alternativa suportada pelo ativo.
   long filling=(long)SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   long execucao=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE);
   bool suportaFOK=((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK);
   bool suportaIOC=((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC);
   bool marketExecution=(execucao==SYMBOL_TRADE_EXECUTION_MARKET);

   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_FOK && suportaFOK)
      return ORDER_FILLING_FOK;
   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_IOC && suportaIOC)
      return ORDER_FILLING_IOC;
   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_RETURN && !marketExecution)
      return ORDER_FILLING_RETURN;

   if(suportaIOC)
      return ORDER_FILLING_IOC;
   if(suportaFOK)
      return ORDER_FILLING_FOK;

   // Em execução Request/Instant/Exchange, RETURN é a alternativa mais segura.
   if(!marketExecution)
      return ORDER_FILLING_RETURN;

   // Proteção final para Market Execution com flags incompletas do servidor.
   // FOK evita enviar RETURN, que seria rejeitado nesse modo de execução.
   return ORDER_FILLING_FOK;
}


#endif // COPA_FECHAMENTO_POSICOES_MQH
