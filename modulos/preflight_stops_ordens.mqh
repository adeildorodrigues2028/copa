#ifndef COPA_PREFLIGHT_STOPS_ORDENS_MQH
#define COPA_PREFLIGHT_STOPS_ORDENS_MQH

bool ExistePosicaoDirecaoErradaMagicFIX288(long magic, ENUM_LADO_ROBO ladoEsperado, string &detalhe)
{
   detalhe="";
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic)
         continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      bool errado=(ladoEsperado==LADO_COMPRA && tipo==POSITION_TYPE_SELL) ||
                   (ladoEsperado==LADO_VENDA  && tipo==POSITION_TYPE_BUY);
      if(!errado)
         continue;
      detalhe=StringFormat("Magic %d possui ticket %s no sentido %s; esperado %s",
                           (int)magic,
                           IntegerToString((long)ticket),
                           tipo==POSITION_TYPE_BUY ? "BUY" : "SELL",
                           ladoEsperado==LADO_COMPRA ? "BUY" : "SELL");
      return true;
   }
   return false;
}

bool ValidarDirecaoFixaOrdemFIX288(EstadoLado &estado, string &motivo)
{
   motivo="";
   long magicEsperado=(estado.lado==LADO_COMPRA ? MagicCompraAtual() : MagicVendaAtual());
   ENUM_LADO_ROBO ladoLocal=LadoOperacionalInstanciaFIX255();
   long magicLocal=MagicOperacionalInstanciaFIX255();

   if(estado.lado!=LADO_COMPRA && estado.lado!=LADO_VENDA)
   {
      motivo="lado operacional invalido";
      return false;
   }
   if(!LadoHabilitadoUsuarioFIX346(estado.lado))
   {
      motivo=StringFormat("lado %s desabilitado pelo usuario | modo %s",
                          estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",
                          TextoLadosHabilitadosFIX346());
      return false;
   }
   if(estado.magic!=magicEsperado)
   {
      motivo=StringFormat("mapeamento invalido: lado %s recebeu Magic %d; esperado Magic %d",
                          estado.lado==LADO_COMPRA ? "BUY" : "SELL",
                          (int)estado.magic,(int)magicEsperado);
      return false;
   }
   if(estado.lado!=ladoLocal || estado.magic!=magicLocal)
   {
      motivo=StringFormat("esta %s nao pode enviar %s/Magic %d",
                          NomeJanelaInstanciaFIX255(),
                          estado.lado==LADO_COMPRA ? "BUY" : "SELL",
                          (int)estado.magic);
      return false;
   }
   string detalheErrado="";
   if(ExistePosicaoDirecaoErradaMagicFIX288(estado.magic,estado.lado,detalheErrado))
   {
      motivo="posicao de sentido errado detectada: "+detalheErrado+". Zere este Magic antes de reativar.";
      return false;
   }
   return true;
}

double PrecoReferenciaFIX344(ENUM_REFERENCIA_PRECO_FIX344 referencia,string &origem)
{
   origem="";
   double abertura=SymbolInfoDouble(_Symbol,SYMBOL_SESSION_OPEN);
   if(abertura<=0.0)
      abertura=iOpen(_Symbol,PERIOD_D1,0);
   double ajusteAtual=SymbolInfoDouble(_Symbol,SYMBOL_SESSION_PRICE_SETTLEMENT);
   if(ajusteAtual<=0.0)
      ajusteAtual=abertura;
   double ajusteAnterior=iClose(_Symbol,PERIOD_D1,1);

   if(referencia==REFERENCIA_FIX344_ABERTURA_HOJE)
   {
      origem="ABERTURA HOJE";
      return abertura;
   }
   if(referencia==REFERENCIA_FIX344_AJUSTE_ATUAL)
   {
      origem="AJUSTE ATUAL";
      return ajusteAtual;
   }
   if(referencia==REFERENCIA_FIX344_AJUSTE_ANTERIOR)
   {
      origem="AJUSTE D1 ANTERIOR";
      return ajusteAnterior;
   }
   origem="MEDIA AJUSTE ANT/ATUAL";
   if(ajusteAnterior<=0.0 || ajusteAtual<=0.0)
      return 0.0;
   return (ajusteAnterior+ajusteAtual)*0.5;
}

bool ValidarRangeGridEntradaFIX344(EstadoLado &estado,double preco,string &motivo)
{
   motivo="";
   if(!InpFiltroRangeAtivoFIX344 && !InpGridEntradasAtivoFIX344)
   {
      g_statusRangeGridFIX344="RANGE OFF | GRID OFF";
      return true;
   }
   if(preco<=0.0 || _Point<=0.0)
   {
      motivo="RANGE/GRID SEM PRECO VALIDO";
      g_statusRangeGridFIX344="RG BLOQUEADO | PRECO INVALIDO";
      return false;
   }

   string status="RG "+estado.nome;
   if(InpFiltroRangeAtivoFIX344)
   {
      string origemRange="";
      double referenciaRange=PrecoReferenciaFIX344(InpRangeReferenciaFIX344,origemRange);
      if(referenciaRange<=0.0)
      {
         motivo="RANGE SEM REFERENCIA: "+origemRange;
         g_statusRangeGridFIX344="RANGE BLOQUEADO | SEM REFERENCIA";
         return false;
      }
      double distancia=MathAbs(preco-referenciaRange)/_Point;
      if(distancia+0.0001<InpRangeMinimoPontosFIX344)
      {
         motivo=StringFormat("RANGE BLOQUEOU | %s %.0f | DIST %.0f < MIN %.0f",
                             origemRange,referenciaRange,distancia,InpRangeMinimoPontosFIX344);
         g_statusRangeGridFIX344=StringFormat("RANGE BLOQ %.0f<%.0f",distancia,InpRangeMinimoPontosFIX344);
         return false;
      }
      if(distancia>InpRangeMaximoPontosFIX344+0.0001)
      {
         motivo=StringFormat("RANGE BLOQUEOU | %s %.0f | DIST %.0f > MAX %.0f",
                             origemRange,referenciaRange,distancia,InpRangeMaximoPontosFIX344);
         g_statusRangeGridFIX344=StringFormat("RANGE BLOQ %.0f>%.0f",distancia,InpRangeMaximoPontosFIX344);
         return false;
      }
      status+=StringFormat(" | R %.0f OK",distancia);
   }
   else
      status+=" | R OFF";

   if(InpGridEntradasAtivoFIX344)
   {
      string origemGrid="";
      double base=PrecoReferenciaFIX344(InpGridReferenciaFIX344,origemGrid);
      double passo=InpGridTamanhoPontosFIX344*_Point;
      if(base<=0.0 || passo<=0.0)
      {
         motivo="GRID SEM REFERENCIA/PASSO VALIDO: "+origemGrid;
         g_statusRangeGridFIX344="GRID BLOQUEADO | SEM BASE";
         return false;
      }
      double nivel=MathRound((preco-base)/passo);
      double linha=base+(nivel*passo);
      double distanciaLinha=MathAbs(preco-linha)/_Point;
      if(distanciaLinha>InpGridToleranciaPontosFIX344+0.0001)
      {
         motivo=StringFormat("GRID BLOQUEOU | %s %.0f | LINHA %.0f | DIST %.1f > TOL %.1f",
                             origemGrid,base,linha,distanciaLinha,InpGridToleranciaPontosFIX344);
         g_statusRangeGridFIX344=StringFormat("GRID BLOQ D%.1f/%.1f",distanciaLinha,InpGridToleranciaPontosFIX344);
         return false;
      }
      status+=StringFormat(" | G %.0f D%.1f OK",linha,distanciaLinha);
   }
   else
      status+=" | G OFF";
   g_statusRangeGridFIX344=status;
   return true;
}

double NormalizarPrecoStopFIX342(double preco,bool arredondarParaCima)
{
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   if(tick<=0.0 || preco<=0.0) return 0.0;
   double passos=preco/tick;
   double normal=arredondarParaCima ? MathCeil(passos)*tick : MathFloor(passos)*tick;
   return NormalizeDouble(normal,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
}

double CalcularStopServidorEntradaFIX342(ENUM_LADO_ROBO lado,double precoEntrada)
{
   if(!InpStopServidorEmergenciaAtivoFIX342 || precoEntrada<=0.0)
      return 0.0;
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   double distancia=MathAbs(InpStopServidorEmergenciaPontosFIX342)*_Point;
   double minima=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+tick;
   if(distancia<minima) distancia=minima;
   if(lado==LADO_COMPRA)
      return NormalizarPrecoStopFIX342(precoEntrada-distancia,false);
   if(lado==LADO_VENDA)
      return NormalizarPrecoStopFIX342(precoEntrada+distancia,true);
   return 0.0;
}

double ContratosBrutosABServidorFIX342()
{
   double total=0.0;
   long magicC=MagicCompraAtual(),magicV=MagicVendaAtual();
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic!=magicC && magic!=magicV) continue;
      total+=MathAbs(PositionGetDouble(POSITION_VOLUME));
   }
   return total;
}

double ExposicaoLiquidaABServidorFIX342()
{
   double liquida=0.0;
   long magicC=MagicCompraAtual(),magicV=MagicVendaAtual();
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic!=magicC && magic!=magicV) continue;
      double volume=MathAbs(PositionGetDouble(POSITION_VOLUME));
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(tipo==POSITION_TYPE_BUY) liquida+=volume;
      else if(tipo==POSITION_TYPE_SELL) liquida-=volume;
   }
   return liquida;
}

bool GarantiaInternaAutorizaOrdemFIX372(EstadoLado &estado,double novoVolume,string contexto,string &detalhe)
{
   detalhe="";
   double atual=VolumeAtualMagicServidor(estado);
   double novo=MathAbs(novoVolume);
   double projetado=atual+novo;
   double porContrato=MathAbs(InpGarantiaPorContratoReaisFIX372);
   double disponivel=MathAbs(InpGarantiaPorLadoReaisFIX372);
   if(porContrato<=0.0) porContrato=100.0;
   if(disponivel<=0.0) disponivel=500.0;
   double necessario=projetado*porContrato;
   detalhe=StringFormat("%s | ATUAL %.0fC | NOVO %.0fC | PROJETADO %.0fC | EXIGE %.0f | DISP %.0f",
                        contexto,atual,novo,projetado,necessario,disponivel);
   if(necessario>disponivel+0.01)
   {
      detalhe="GARANTIA INSUFICIENTE | "+detalhe+" | ORDEM NAO ENVIADA";
      estado.motivoBloqueioAumento=detalhe;
      estado.ultimaMensagem=detalhe;
      RegistrarGerenciadorOrdens(estado,"FIX372_GARANTIA_BLOQUEIO",detalhe,0,0,novo,0.0,true);
      return false;
   }
   RegistrarGerenciadorOrdens(estado,"FIX372_GARANTIA_OK",detalhe,0,0,novo,0.0,false);
   return true;
}

bool ValidarPreflightEntradaFIX342(EstadoLado &estado,MqlTradeRequest &req,string &motivo,MqlTradeCheckResult &check)
{
   motivo="";
   ZeroMemory(check);
   bool livreProtegidaDemoFIX350=(g_contaDemo && PrimeiraOrdemLivreProtegidaFIX314() && EntradaDiretaDemoEfetivaFIX302());
   // FIX346: bloqueio central cobre A0 normal, A0 livre de teste e A1-A4.
   // Saidas e protecoes nao passam por este preflight e permanecem autorizadas.
   if(!LadoHabilitadoUsuarioFIX346(estado.lado))
   {
      motivo=StringFormat("LADO %s DESABILITADO | MODO %s",
                          estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",
                          TextoLadosHabilitadosFIX346());
      return false;
   }
   if(g_bloqueioTecnicoEntradasAteFIX342>TimeCurrent())
   {
      motivo=StringFormat("PAUSA TECNICA %ds | %s",
                          (int)(g_bloqueioTecnicoEntradasAteFIX342-TimeCurrent()),
                          g_bloqueioTecnicoMotivoFIX342);
      return false;
   }
   if(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL && !g_auditoriaProducaoOKFIX342)
   {
      motivo="AUDITORIA DE PRODUCAO NAO APROVADA";
      return false;
   }
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
   {
      motivo="TERMINAL SEM CONEXAO COM O SERVIDOR";
      return false;
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      motivo="NEGOCIACAO NAO AUTORIZADA NO TERMINAL/EA/CONTA";
      return false;
   }
   long tradeMode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(tradeMode==SYMBOL_TRADE_MODE_DISABLED || tradeMode==SYMBOL_TRADE_MODE_CLOSEONLY ||
      (estado.lado==LADO_COMPRA && tradeMode==SYMBOL_TRADE_MODE_SHORTONLY) ||
      (estado.lado==LADO_VENDA && tradeMode==SYMBOL_TRADE_MODE_LONGONLY))
   {
      motivo=StringFormat("ATIVO NAO AUTORIZA ESTE LADO | TRADE_MODE=%d",(int)tradeMode);
      return false;
   }

   MqlTick tickAtual;
   if(!SymbolInfoTick(_Symbol,tickAtual) || tickAtual.bid<=0.0 || tickAtual.ask<=0.0 || tickAtual.time<=0)
   {
      motivo="BID/ASK INVALIDO";
      return false;
   }
   double precoEntradaRG=(estado.lado==LADO_COMPRA ? tickAtual.ask : tickAtual.bid);
   datetime agora=TimeTradeServer();
   if(agora<=0) agora=TimeCurrent();

   // FIX351: LIVRE PROTEGIDA em DEMO é um teste técnico de envio.
   // Filtros estratégicos e limites internos não podem impedir que a ordem chegue ao servidor.
   // Em operação normal/REAL, todas as validações antigas continuam exatamente ativas.
   if(!livreProtegidaDemoFIX350)
   {
      string motivoRangeGrid="";
      if(!ValidarRangeGridEntradaFIX344(estado,precoEntradaRG,motivoRangeGrid))
      {
         motivo=motivoRangeGrid;
         return false;
      }
      int idade=(agora>=tickAtual.time ? (int)(agora-tickAtual.time) : 0);
      if(idade>InpTickMaximoIdadeSegundosFIX342)
      {
         motivo=StringFormat("COTACAO ATRASADA %ds > %ds",idade,InpTickMaximoIdadeSegundosFIX342);
         return false;
      }
      double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tickSize<=0.0) tickSize=_Point;
      double spreadTicks=(tickSize>0.0 ? (tickAtual.ask-tickAtual.bid)/tickSize : 999999.0);
      if(spreadTicks>InpSpreadMaximoTicksFIX342+0.000001)
      {
         motivo=StringFormat("SPREAD %.1f TICKS > LIMITE %.1f",spreadTicks,InpSpreadMaximoTicksFIX342);
         return false;
      }

      datetime vencimento=(datetime)SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_TIME);
      if(vencimento>0 && InpBloquearDiasAntesVencimentoFIX342>0)
      {
         datetime limite=vencimento-(datetime)(InpBloquearDiasAntesVencimentoFIX342*86400);
         if(agora>=limite)
         {
            motivo=StringFormat("CONTRATO PERTO DO VENCIMENTO %s",TimeToString(vencimento,TIME_DATE|TIME_MINUTES));
            return false;
         }
      }
   }
   else
   {
      g_statusRangeGridFIX344="FIX351 A0 DEMO | PREFLIGHT MINIMO";
   }

   string detalheGarantiaFIX372="";
   if(!GarantiaInternaAutorizaOrdemFIX372(estado,req.volume,"PRE-FLIGHT",detalheGarantiaFIX372))
   {
      motivo=detalheGarantiaFIX372;
      return false;
   }

   double brutoProjetado=ContratosBrutosABServidorFIX342()+MathAbs(req.volume);
   if(brutoProjetado>InpMaxContratosBrutosABFIX342+0.0001)
   {
      motivo=StringFormat("EXPOSICAO A+B %.2f > LIMITE %.2f",brutoProjetado,InpMaxContratosBrutosABFIX342);
      return false;
   }
   double sinalLado=(estado.lado==LADO_COMPRA ? 1.0 : -1.0);
   double liquidaProjetada=ExposicaoLiquidaABServidorFIX342()+sinalLado*MathAbs(req.volume);
   if(MathAbs(liquidaProjetada)>InpMaxExposicaoLiquidaABFIX342+0.0001)
   {
      motivo=StringFormat("EXPOSICAO LIQUIDA A+B %.2f > LIMITE %.2f",MathAbs(liquidaProjetada),InpMaxExposicaoLiquidaABFIX342);
      return false;
   }

   ResetLastError();
   bool checkOK=OrderCheck(req,check);
   int erroCheck=GetLastError();

   // FIX350: algumas contas DEMO da bolsa recusam o SL junto com a ordem a mercado,
   // mesmo aceitando o mesmo SL logo depois na posicao. Somente na LIVRE PROTEGIDA
   // DEMO, refaz o OrderCheck sem SL e o gerenciador recoloca a protecao no servidor.
   if(!checkOK && livreProtegidaDemoFIX350 && req.sl>0.0)
   {
      string comentarioCheck=Upper(check.comment);
      bool rejeicaoStop=(check.retcode==TRADE_RETCODE_INVALID_STOPS ||
                         StringFind(comentarioCheck,"STOP")>=0 ||
                         StringFind(comentarioCheck,"SL")>=0);
      if(rejeicaoStop)
      {
         double slOriginalFIX350=req.sl;
         req.sl=0.0;
         ZeroMemory(check);
         ResetLastError();
         checkOK=OrderCheck(req,check);
         erroCheck=GetLastError();
         if(checkOK)
         {
            RegistrarLogValidacaoSistema("FIX350_PREFLIGHT_SEM_SL",
               StringFormat("A0 DEMO aprovada sem SL inicial; SL %.0f sera recolocado apos abrir a posicao.",slOriginalFIX350));
         }
      }
   }
   if(!checkOK)
   {
      motivo=StringFormat("ORDERCHECK RC=%u E=%d %s",check.retcode,erroCheck,check.comment);

      // FIX351: no teste DEMO, OrderCheck vira diagnóstico.
      // Somente falhas realmente críticas impedem o OrderSend. As demais seguem ao servidor,
      // que devolve o retcode definitivo e elimina o falso PREFLIGHT_BLOCK.
      bool falhaCriticaFIX351=(check.retcode==TRADE_RETCODE_NO_MONEY ||
                               check.retcode==TRADE_RETCODE_TRADE_DISABLED ||
                               check.retcode==TRADE_RETCODE_MARKET_CLOSED ||
                               check.retcode==TRADE_RETCODE_INVALID_VOLUME ||
                               check.retcode==TRADE_RETCODE_LIMIT_VOLUME);
      if(!livreProtegidaDemoFIX350 || falhaCriticaFIX351)
         return false;

      PrintFormat("[COPA_AR100][FIX351][ORDERCHECK_AVISO] %s | %s | Magic %I64d | preço %.0f | volume %.2f | ENVIANDO AO SERVIDOR",
                  motivo,estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",estado.magic,req.price,req.volume);
      motivo="";
   }
   if(!livreProtegidaDemoFIX350 && InpMargemLivreMinimaReaisFIX342>0.0 && check.margin_free<InpMargemLivreMinimaReaisFIX342)
   {
      motivo=StringFormat("MARGEM LIVRE PROJETADA %.2f < %.2f",check.margin_free,InpMargemLivreMinimaReaisFIX342);
      return false;
   }
   if(!livreProtegidaDemoFIX350 && InpNivelMargemMinimoPercentFIX342>0.0 && check.margin_level>0.0 &&
      check.margin_level<InpNivelMargemMinimoPercentFIX342)
   {
      motivo=StringFormat("NIVEL DE MARGEM PROJETADO %.1f%% < %.1f%%",check.margin_level,InpNivelMargemMinimoPercentFIX342);
      return false;
   }
   return true;
}

void ProcessarRetcodeEntradaFIX342(EstadoLado &estado,uint retcode,uint retcodeExterno,string contexto)
{
   if(retcode==TRADE_RETCODE_DONE || retcode==TRADE_RETCODE_DONE_PARTIAL || retcode==TRADE_RETCODE_PLACED)
      return;
   int pausa=0;
   bool critico=false;
   if(retcode==TRADE_RETCODE_REQUOTE || retcode==TRADE_RETCODE_PRICE_CHANGED ||
      retcode==TRADE_RETCODE_PRICE_OFF || retcode==TRADE_RETCODE_TIMEOUT ||
      retcode==TRADE_RETCODE_CONNECTION || retcode==TRADE_RETCODE_TOO_MANY_REQUESTS ||
      retcode==TRADE_RETCODE_LOCKED)
      pausa=5;
   else if(retcode==TRADE_RETCODE_MARKET_CLOSED || retcode==TRADE_RETCODE_TRADE_DISABLED)
      pausa=60;
   else if(retcode==TRADE_RETCODE_NO_MONEY || retcode==TRADE_RETCODE_INVALID ||
           retcode==TRADE_RETCODE_INVALID_VOLUME || retcode==TRADE_RETCODE_INVALID_PRICE ||
           retcode==TRADE_RETCODE_INVALID_STOPS || retcode==TRADE_RETCODE_INVALID_FILL ||
           retcode==TRADE_RETCODE_LIMIT_VOLUME || retcode==TRADE_RETCODE_LIMIT_ORDERS)
      critico=true;
   else
      pausa=2;

   g_bloqueioTecnicoMotivoFIX342=StringFormat("%s RC%u EXT%u",contexto,retcode,retcodeExterno);
   if(pausa>0)
      g_bloqueioTecnicoEntradasAteFIX342=TimeCurrent()+pausa;
   if(critico && InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL)
   {
      g_auditoriaProducaoOKFIX342=false;
      g_auditoriaProducaoStatusFIX342="REAL PAUSADO POR FALHA CRITICA | "+g_bloqueioTecnicoMotivoFIX342;
      g_bloqueioTecnicoEntradasAteFIX342=TimeCurrent()+86400;
      RegistrarGerenciadorOrdens(estado,"FIX342_FALHA_CRITICA",g_auditoriaProducaoStatusFIX342,
                                 retcode,0,0.0,0.0,true);
   }
}

void GarantirStopsServidorFIX342(bool forcar)
{
   if(!InpStopServidorEmergenciaAtivoFIX342 || InpStopServidorEmergenciaPontosFIX342<=0.0)
      return;
   datetime agora=TimeCurrent();
   if(!forcar && g_ultimaAuditoriaStopServidorFIX342>0 &&
      (agora-g_ultimaAuditoriaStopServidorFIX342)<2)
      return;
   g_ultimaAuditoriaStopServidorFIX342=agora;
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
      return;

   long magicLocal=MagicOperacionalInstanciaFIX255();
   MqlTick tickAtual;
   if(!SymbolInfoTick(_Symbol,tickAtual) || tickAtual.bid<=0.0 || tickAtual.ask<=0.0)
      return;
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0.0) tickSize=_Point;
   double distanciaMinima=(double)MathMax(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),
                                          SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL))*_Point+tickSize;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magicLocal) continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(tipo!=POSITION_TYPE_BUY && tipo!=POSITION_TYPE_SELL) continue;

      double abertura=PositionGetDouble(POSITION_PRICE_OPEN);
      double slAtual=PositionGetDouble(POSITION_SL);
      double tpAtual=PositionGetDouble(POSITION_TP);
      ENUM_LADO_ROBO lado=(tipo==POSITION_TYPE_BUY ? LADO_COMPRA : LADO_VENDA);
      double desejado=CalcularStopServidorEntradaFIX342(lado,abertura);
      if(tipo==POSITION_TYPE_BUY)
      {
         double maximoValido=NormalizarPrecoStopFIX342(tickAtual.bid-distanciaMinima,false);
         if(desejado<=0.0 || desejado>maximoValido) desejado=maximoValido;
         if(slAtual>0.0 && slAtual>=desejado-tickSize*0.5) continue;
      }
      else
      {
         double minimoValido=NormalizarPrecoStopFIX342(tickAtual.ask+distanciaMinima,true);
         if(desejado<=0.0 || desejado<minimoValido) desejado=minimoValido;
         if(slAtual>0.0 && slAtual<=desejado+tickSize*0.5) continue;
      }
      if(desejado<=0.0) continue;

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req); ZeroMemory(res);
      req.action=TRADE_ACTION_SLTP;
      req.position=ticket;
      req.symbol=_Symbol;
      req.magic=(ulong)magicLocal;
      req.sl=desejado;
      req.tp=tpAtual;
      ResetLastError();
      bool ok=OrderSend(req,res);
      int erro=GetLastError();
      bool aceito=(ok && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED));
      string msg=StringFormat("SL SERVIDOR %s | ticket %I64u | %.0f -> %.0f | RC%u E%d",
                              aceito ? "OK" : "REJEITADO",ticket,slAtual,desejado,res.retcode,erro);
      if(tipo==POSITION_TYPE_BUY)
         RegistrarGerenciadorOrdens(g_compra,aceito ? "FIX342_SL_SERVER_OK" : "FIX342_SL_SERVER_REJECT",msg,res.retcode,erro,PositionGetDouble(POSITION_VOLUME),desejado,true);
      else
         RegistrarGerenciadorOrdens(g_venda,aceito ? "FIX342_SL_SERVER_OK" : "FIX342_SL_SERVER_REJECT",msg,res.retcode,erro,PositionGetDouble(POSITION_VOLUME),desejado,true);
   }
}


#endif // COPA_PREFLIGHT_STOPS_ORDENS_MQH
