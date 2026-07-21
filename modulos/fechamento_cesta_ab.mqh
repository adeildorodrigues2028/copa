#ifndef COPA_FECHAMENTO_CESTA_AB_MQH
#define COPA_FECHAMENTO_CESTA_AB_MQH

// ============================================================================
// RESPONSABILIDADE: FECHAMENTO OFICIAL DA CESTA A+B
// Funcoes movidas do principal na V44 sem alteracao de regra operacional.
// ============================================================================

bool FecharCestaABOficial(string motivo)
{
   if(!InpSaidaCestaABFecharGrupoInteiro)
   {
      bool okLocal = true;
      bool enviouLocal = false;
      if(g_painelA.posicaoAberta)
      {
         enviouLocal = true;
         if(!FecharPosicoesLado(g_painelA, motivo)) okLocal = false;
      }
      if(g_painelB.posicaoAberta)
      {
         enviouLocal = true;
         if(!FecharPosicoesLado(g_painelB, motivo)) okLocal = false;
      }
      return (enviouLocal && okLocal);
   }
   if(!ExistePosicaoAbertaGrupoTotalAB())
      return false;
   if(!PermiteEnvioOrdem(g_painelA, "Saida financeira A+B"))
      return false;
   FotoCestaAB fotoAntes;
   CalcularFotoCestaABOficial(fotoAntes, false);
   string msgInicio = "SAIDA OFICIAL A+B " + motivo + " | antes: " + TextoLogFotoCestaAB(fotoAntes) +
                      " | regra: fecha todos os Magics do grupo porque a decisão foi pelo saldo_total A+B";
   LogHedgeCompleto("SAIDA_AB_PRE", "ANTES_FECHAR_GRUPO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_OFICIAL", msgInicio, 0, 0, 0.0, 0.0, true);
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][FIX156][SAIDA_AB_OFICIAL] ", msgInicio);
   RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_OFICIAL", msgInicio, 0, 0, 0.0, 0.0, true);
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      string symbol = PositionGetString(POSITION_SYMBOL);
      if(symbol != _Symbol)
         continue;
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      // FIX317: o grupo A+B fecha somente a direção oficial de cada Magic.
      // Comentário antigo não pode deixar uma posição real presa.
      if(!PosicaoSelecionadaPertencePainelFIX316(magic))
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
      req.magic        = (ulong)magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " GRUPOAB",req.magic);
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
      g_painelA.ultimaTentativaOrdem = TimeCurrent();
      g_painelB.ultimaTentativaOrdem = TimeCurrent();
      string lado = (type == POSITION_TYPE_BUY ? "COMPRA" : "VENDA");
      LogHedgeCompleto("SAIDA_AB_ENVIO", "ENVIO_ORDEM_FECHAMENTO", motivo + " | lado " + lado, ticket, 0, magic, 0, 0, req.volume, req.price, true);
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         string msgOk = StringFormat("SAIDA GRUPO A+B OK %s | Magic %d | Ticket %s | Lado %s | Volume %.2f | Preco %.0f",
                                     motivo,
                                     (int)magic,
                                     IntegerToString((long)ticket),
                                     lado,
                                     req.volume,
                                     req.price);
         RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         LogHedgeCompleto("SAIDA_AB_RESULT", "RESULTADO_ORDEM_FECHAMENTO_OK", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         string msgErro = StringFormat("SAIDA GRUPO A+B REJEITADA %s | Magic %d | Ticket %s | Lado %s | Retcode %s | Erro %s",
                                       motivo,
                                       (int)magic,
                                       IntegerToString((long)ticket),
                                       lado,
                                       IntegerToString((int)res.retcode),
                                       IntegerToString(ultimoErro));
         RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         LogHedgeCompleto("SAIDA_AB_RESULT", "RESULTADO_ORDEM_FECHAMENTO_REJECT", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!encontrou)
   {
      string msgBlock = "SAIDA OFICIAL A+B solicitada, mas nenhuma posição do grupo de Magics foi encontrada.";
      RegistrarGerenciadorOrdens(g_painelA, "SAIDA_AB_BLOCK", msgBlock, 0, 0, 0.0, 0.0, true);
      RegistrarLogValidacaoCSV(g_painelA, "SAIDA_AB_BLOCK", msgBlock, 0, 0, 0.0, 0.0, true);
      LogHedgeCompleto("SAIDA_AB_BLOCK", "FECHAMENTO_NAO_ENCONTROU_POSICAO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   }
   LogHedgeCompleto("SAIDA_AB_POS", "DEPOIS_TENTATIVA_FECHAR_GRUPO", motivo, 0, 0, 0, 0, 0, 0.0, 0.0, true);
   return (encontrou && tudoOk);
}

#endif // COPA_FECHAMENTO_CESTA_AB_MQH
