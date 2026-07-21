#ifndef COPA_ENVIO_ORDEM_MERCADO_MQH
#define COPA_ENVIO_ORDEM_MERCADO_MQH

bool EnviarOrdemMercado(EstadoLado &estado, double volume, string comentario, string contextoEnvio)
{
   // FIX288: trava final antes de qualquer A0 ou aumento.
   string motivoDirecaoFIX288="";
   if(!ValidarDirecaoFixaOrdemFIX288(estado,motivoDirecaoFIX288))
   {
      g_mestre.mensagemGeral="FIX288 BLOQUEIO DE DIRECAO: "+motivoDirecaoFIX288;
      RegistrarGerenciadorOrdens(estado,"FIX288_DIRECAO_BLOCK",g_mestre.mensagemGeral,
                                 0,0,volume,0.0,true);
      return false;
   }
   if(!CoordenacaoPermiteNovaOrdemFIX256(estado,contextoEnvio))
      return false;
   double vol = NormalizarVolume(volume);
   if(vol <= 0.0)
   {
      RegistrarGerenciadorOrdens(estado, "ORDER_BLOCK", "Ordem bloqueada: volume invalido.", 0, 0, volume, 0.0, true);
      return false;
   }
   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = vol;
   req.magic        = (ulong)estado.magic;
   bool envioAumentoFIX363=(StringFind(Upper(contextoEnvio),"AUMENTO")>=0);
   req.deviation    = envioAumentoFIX363 ? 0 : InpDesvioMaximoPontos;
   req.type_time    = ORDER_TIME_GTC;
   req.type_filling = TipoPreenchimentoSeguro();
   req.comment      = ComentarioComIdentidadeMagicFIX304(comentario,req.magic);
   if(estado.lado == LADO_COMPRA)
   {
      req.type  = ORDER_TYPE_BUY;
      req.price = ask;
      req.sl    = CalcularStopServidorEntradaFIX342(LADO_COMPRA,ask);
   }
   else if(estado.lado == LADO_VENDA)
   {
      req.type  = ORDER_TYPE_SELL;
      req.price = bid;
      req.sl    = CalcularStopServidorEntradaFIX342(LADO_VENDA,bid);
   }
   else
   {
      RegistrarGerenciadorOrdens(estado, "ORDER_BLOCK", "Ordem bloqueada: lado invalido.", 0, 0, vol, 0.0, true);
      return false;
   }
   MqlTradeCheckResult checkFIX342;
   string motivoPreflightFIX342="";
   if(!ValidarPreflightEntradaFIX342(estado,req,motivoPreflightFIX342,checkFIX342))
   {
      RegistrarGerenciadorOrdens(estado,"FIX342_PREFLIGHT_BLOCK",
                                 contextoEnvio+" bloqueado: "+motivoPreflightFIX342,
                                 checkFIX342.retcode,GetLastError(),vol,req.price,true);
      return false;
   }
   estado.ultimaTentativaOrdem = TimeCurrent();
   if(InpLogTentativaOrdemExperts)
   {
      RegistrarGerenciadorOrdens(estado, "ORDER_SEND",
                                 StringFormat("Enviando ordem | Tipo %s | Volume %.2f | Preco %.2f | Fill %d | Desvio %d",
                                              estado.lado == LADO_COMPRA ? "BUY" : "SELL",
                                              vol, req.price, (int)req.type_filling, (int)req.deviation),
                                 0, 0, vol, req.price, true);
   }
   ResetLastError();
   g_ultimoEnvioAguardandoDealFIX342=false;
   g_ultimaOrdemPendenteFIX342=0;
   bool ok = OrderSend(req, res);
   g_ultimoRetcodeExternoFIX342=res.retcode_external;
   ProcessarRetcodeEntradaFIX342(estado,res.retcode,res.retcode_external,contextoEnvio);
   if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
   {
      RegistrarGerenciadorOrdens(estado, "ORDER_OK",
                                 StringFormat("ORDEM EXECUTADA: %s %.2f contrato(s) | Ticket %s | Deal %s | Retcode %s | %s",
                                              estado.nome,
                                              vol,
                                              IntegerToString((long)res.order),
                                              IntegerToString((long)res.deal),
                                              IntegerToString((int)res.retcode),
                                              comentario),
                                 res.retcode, 0, vol, res.price, true);
      // FIX414: entrada confirmada com total já realizado no ciclo para auditoria.
      double totalEntradaFIX414=(estado.lado==LADO_COMPRA ? g_parciaisCicloBuy : g_parciaisCicloSell);
      DispararMsgBoxVisualFIX226(
         "ENTRADA EXECUTADA | "+estado.nome,
         StringFormat("VOLUME: %.2f | PRECO: %.0f",vol,res.price),
         "TOTAL REALIZADO DA OPERACAO: "+PnlMoedaBRL(totalEntradaFIX414));
      RegistrarLogValidacaoSistema("FIX414_MSGBOX_ENTRADA",
         StringFormat("%s | volume %.2f | preco %.0f | total realizado %s",estado.nome,vol,res.price,PnlMoedaBRL(totalEntradaFIX414)));
      if(envioAumentoFIX363)
      {
         int nivelFIX363=0;
         int posA=StringFind(Upper(contextoEnvio),"AUMENTO A");
         if(posA>=0) nivelFIX363=(int)StringToInteger(StringSubstr(contextoEnvio,posA+9));
         if(nivelFIX363>=1 && nivelFIX363<=ArraySize(g_aumentos))
         {
            double linhaFillFIX363=(estado.lado==LADO_COMPRA
                                      ? g_linhaCandleAumentoBuyFIX224[nivelFIX363-1]
                                      : g_linhaCandleAumentoSellFIX224[nivelFIX363-1]);
            if(linhaFillFIX363<=0.0)
               linhaFillFIX363=PrecoNivelAumentoValorIndice(estado,nivelFIX363-1);
            string stFillFIX363="";
            bool fillOkFIX363=true;
            if(res.price>0.0)
            {
               if(estado.lado==LADO_COMPRA)
                  fillOkFIX363=InpAumentosContraPosicao ? (res.price<=linhaFillFIX363) : (res.price>=linhaFillFIX363);
               else
                  fillOkFIX363=InpAumentosContraPosicao ? (res.price>=linhaFillFIX363) : (res.price<=linhaFillFIX363);
            }
            stFillFIX363=StringFormat("A%d FILL %s | PROG %.0f | EXEC %.0f | DESVIO 0",nivelFIX363,fillOkFIX363?"OK":"FORA DA LINHA",linhaFillFIX363,res.price);
            RegistrarGerenciadorOrdens(estado,fillOkFIX363?"FIX363_FILL_OK":"FIX363_FILL_FORA_LINHA",stFillFIX363,res.retcode,0,vol,res.price,true);
         }
      }
      return true;
   }
   if(ok && res.retcode == TRADE_RETCODE_PLACED)
   {
      g_ultimoEnvioAguardandoDealFIX342=true;
      g_ultimaOrdemPendenteFIX342=res.order;
      RegistrarGerenciadorOrdens(estado, "ORDER_PLACED_AGUARDA_DEAL",
                                 StringFormat("ORDEM COLOCADA E AGUARDANDO DEAL | Ticket %s | Deal %s | Retcode %s | %s",
                                              IntegerToString((long)res.order),
                                              IntegerToString((long)res.deal),
                                              IntegerToString((int)res.retcode),
                                              comentario),
                                 res.retcode, 0, vol, req.price, true);
      return true;
   }
   int ultimoErro = GetLastError();
   string erro = StringFormat("ORDEM REJEITADA: OrderSend=%s | retcode=%s | erro=%s | comentario=%s",
                              (ok ? "true" : "false"),
                              IntegerToString((int)res.retcode),
                              IntegerToString(ultimoErro),
                              comentario);
   RegistrarGerenciadorOrdens(estado, "ORDER_REJECT", erro, res.retcode, ultimoErro, vol, req.price, true);
   return false;
}


#endif // COPA_ENVIO_ORDEM_MERCADO_MQH
