// COPA V07 - Etapa 07: Motor Canais isolado.
#ifndef COPA_V07_MODULOS_MOTOR_CANAIS_MQH
#define COPA_V07_MODULOS_MOTOR_CANAIS_MQH

// ============================================================================
// FIX423 - IMPLEMENTACAO ISOLADA DO MOTOR CANAIS
// ============================================================================
int g_canaisHandleBands=INVALID_HANDLE;
int g_canaisHandleEMA=INVALID_HANDLE;
int g_canaisHandleATR=INVALID_HANDLE;
datetime g_canaisUltimoCandleProcessado=0;
datetime g_canaisUltimaEntradaCompraCandle=0;
datetime g_canaisUltimaEntradaVendaCandle=0;
datetime g_canaisUltimaSaidaCompra=0;
datetime g_canaisUltimaSaidaVenda=0;
datetime g_canaisUltimoLog=0;
string g_canaisUltimoLogTexto="";
double g_canaisPOC=0.0;
double g_canaisTeto=0.0;
double g_canaisFundo=0.0;
double g_canaisMelhorLucroCompra=0.0;
double g_canaisMelhorLucroVenda=0.0;
bool g_canaisParcialCompraRealizada=false;
bool g_canaisParcialVendaRealizada=false;
datetime g_canaisUltimoCandleVisual=0;
string g_canaisStatusPainel="CANAIS | DESATIVADO";
int g_comparativoDXCompra=0;
int g_comparativoDXVenda=0;
int g_comparativoCanaisCompra=0;
int g_comparativoCanaisVenda=0;
int g_comparativoConcordaCompra=0;
int g_comparativoConcordaVenda=0;

bool CanaisMotorAtivo()
{
   return (InpUsarMotorCanais && InpOperacaoMotorCanais!=CANAIS_DESATIVADO);
}

bool CanaisVisualAtivo()
{
   return (InpCanaisMostrarBollingerGrafico || InpCanaisMostrarKeltnerGrafico || InpCanaisMostrarPOCGrafico || InpCanaisMostrarEntradasHistoricasGrafico);
}

bool CanaisMagicValido(const long magic)
{
   return (magic==InpMagicCompraCanais || magic==InpMagicVendaCanais);
}

void CanaisLog(const string categoria,const string texto,const bool forcar=false)
{
   datetime agora=TimeCurrent();
   string completo="[CANAIS]["+categoria+"] "+texto;
   if(!forcar && completo==g_canaisUltimoLogTexto && agora-g_canaisUltimoLog<5)
      return;
   g_canaisUltimoLog=agora;
   g_canaisUltimoLogTexto=completo;
   Print(completo);
}

bool CanaisValidarParametros(string &erro)
{
   erro="";
   bool motorAtivo=CanaisMotorAtivo();
   bool visualAtivo=CanaisVisualAtivo();
   if(!motorAtivo && !visualAtivo) return true;
   if(motorAtivo)
   {
      if(InpMagicCompraCanais<=0 || InpMagicVendaCanais<=0 || InpMagicCompraCanais==InpMagicVendaCanais)
         erro="Magics do Motor Canais invalidos ou iguais.";
      else if(InpMagicCompraCanais==MagicCompraAtual() || InpMagicCompraCanais==MagicVendaAtual() ||
              InpMagicVendaCanais==MagicCompraAtual() || InpMagicVendaCanais==MagicVendaAtual())
         erro="Magic do Motor Canais conflita com Magic atual do DX/HEAD.";
      else if(InpCanaisContratoA0<1)
         erro="Motor Canais exige A0 com pelo menos 1 contrato.";
      else if(InpCanaisUsarParcial && InpCanaisContratosParcial<1)
         erro="Quantidade da parcial deve ser pelo menos 1 contrato.";
      else if(InpCanaisUsarParcial && InpCanaisContratosParcial>=InpCanaisContratoA0 && !InpCanaisFecharTudoNoAlvo)
         erro="Parcial deve ser menor que A0 para manter contrato runner.";
      else if(InpConfirmacoesMinimasCanais<1 || InpCanaisCandlesConfirmacao<1)
         erro="Confirmacoes do Motor Canais invalidas.";
   }
   if(erro=="" && (InpCanaisPeriodoBollinger<2 || InpCanaisPeriodoEMA<2 || InpCanaisPeriodoATR<1))
      erro="Periodos Bollinger/Keltner invalidos.";
   else if(erro=="" && (InpCanaisPeriodoPOC<2 || InpCanaisFaixaPrecoPOCPontos<1 || InpCanaisPeriodoFundoTeto<2))
      erro="Parametros POC/Fundo/Teto invalidos.";
   else if(erro=="" && InpCanaisVisualHistoricoCandles<50)
      erro="Visual do Motor Canais exige ao menos 50 candles no historico do grafico.";
   else if(erro=="" && InpCanaisVisualDistanciaSetaPontos<1)
      erro="Distancia visual das setas do Motor Canais invalida.";
   else if(erro=="" && InpComparativoToleranciaCandles<0)
      erro="Tolerancia do comparativo DX x Canais invalida.";
   return (erro=="");
}

bool CanaisInicializar()
{
   bool motorAtivo=CanaisMotorAtivo();
   bool visualAtivo=CanaisVisualAtivo();
   if(!motorAtivo && !visualAtivo)
   {
      g_canaisStatusPainel="CANAIS | DESATIVADO";
      return true;
   }
   string erro="";
   if(!CanaisValidarParametros(erro))
   {
      CanaisLog("BLOQUEIO",erro,true);
      return false;
   }
   g_canaisHandleBands=iBands(_Symbol,InpTimeframeCanais,InpCanaisPeriodoBollinger,0,InpCanaisDesvioBollinger,PRICE_CLOSE);
   g_canaisHandleEMA=iMA(_Symbol,InpTimeframeCanais,InpCanaisPeriodoEMA,0,MODE_EMA,PRICE_CLOSE);
   g_canaisHandleATR=iATR(_Symbol,InpTimeframeCanais,InpCanaisPeriodoATR);
   if(g_canaisHandleBands==INVALID_HANDLE || g_canaisHandleEMA==INVALID_HANDLE || g_canaisHandleATR==INVALID_HANDLE)
   {
      CanaisLog("BLOQUEIO",StringFormat("Falha ao criar handles | BOLL=%d EMA=%d ATR=%d ERRO=%d",g_canaisHandleBands,g_canaisHandleEMA,g_canaisHandleATR,GetLastError()),true);
      return false;
   }
   if(motorAtivo)
      CanaisLog("SINAL",StringFormat("Motor operacional | A0=%dC | PARCIAL=%s/%dC em R$%.2f | FECHA_TUDO=%s | MOVEL=%.2f/%.2f | TRAIL=%.2f/%.2f | STOP=R$%.2f | MAGICS=%I64d/%I64d",InpCanaisContratoA0,InpCanaisUsarParcial?"SIM":"NAO",InpCanaisContratosParcial,InpCanaisAlvoFinanceiro,InpCanaisFecharTudoNoAlvo?"SIM":"NAO",InpCanaisMovelAtiva,InpCanaisMovelDefende,InpCanaisTrailingAtiva,InpCanaisTrailingPasso,InpCanaisStopFinanceiro,InpMagicCompraCanais,InpMagicVendaCanais),true);
   else if(visualAtivo)
      CanaisLog("SINAL","Visual de Bollinger/Keltner/POC inicializado no grafico",true);
   return true;
}

void CanaisLimparObjetosVisuais()
{
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string nome=ObjectName(0,i);
      if(StringFind(nome,"COPA_CANAIS_VIS_FIX427_")==0)
         ObjectDelete(0,nome);
   }
}

void CanaisLiberar()
{
   if(g_canaisHandleBands!=INVALID_HANDLE){ IndicatorRelease(g_canaisHandleBands); g_canaisHandleBands=INVALID_HANDLE; }
   if(g_canaisHandleEMA!=INVALID_HANDLE){ IndicatorRelease(g_canaisHandleEMA); g_canaisHandleEMA=INVALID_HANDLE; }
   if(g_canaisHandleATR!=INVALID_HANDLE){ IndicatorRelease(g_canaisHandleATR); g_canaisHandleATR=INVALID_HANDLE; }
   ObjectDelete(0,"COPA_CANAIS_LINHA_FIX423");
   CanaisLimparObjetosVisuais();
}

bool CanaisCopiarValor(const int handle,const int buffer,const int shift,double &valor)
{
   if(handle==INVALID_HANDLE) return false;
   double dados[]; ArraySetAsSeries(dados,true);
   if(CopyBuffer(handle,buffer,shift,1,dados)!=1) return false;
   valor=dados[0];
   return (valor!=EMPTY_VALUE && MathIsValidNumber(valor));
}

void CanaisDesenharSegmento(const string nome,const datetime t1,const double p1,const datetime t2,const double p2,const color cor,const ENUM_LINE_STYLE estilo,const int largura)
{
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_TREND,0,t1,p1,t2,p2);
   else
   {
      ObjectMove(0,nome,0,t1,p1);
      ObjectMove(0,nome,1,t2,p2);
   }
   ObjectSetInteger(0,nome,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,nome,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,estilo);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,nome,OBJPROP_BACK,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
}

void CanaisDesenharSerieSegmentada(const string prefix,datetime &tempos[],double &valores[],const int total,const color cor,const ENUM_LINE_STYLE estilo,const int largura)
{
   if(total<2) return;
   for(int i=total-1;i>0;i--)
   {
      string nome=prefix+"_"+IntegerToString(i);
      CanaisDesenharSegmento(nome,tempos[i],valores[i],tempos[i-1],valores[i-1],cor,estilo,largura);
   }
}

void CanaisAtualizarVisualGrafico(const bool forcar=false)
{
   if(!CanaisVisualAtivo())
   {
      CanaisLimparObjetosVisuais();
      return;
   }
   datetime candleAtual=iTime(_Symbol,InpTimeframeCanais,0);
   if(!forcar && candleAtual>0 && candleAtual==g_canaisUltimoCandleVisual)
      return;
   if(candleAtual>0)
      g_canaisUltimoCandleVisual=candleAtual;

   int total=MathMax(10,InpCanaisVisualHistoricoCandles);
   datetime tempos[]; ArraySetAsSeries(tempos,true);
   if(CopyTime(_Symbol,InpTimeframeCanais,0,total,tempos)<2)
      return;

   CanaisLimparObjetosVisuais();

   if(InpCanaisMostrarBollingerGrafico)
   {
      double bollSup[],bollMid[],bollInf[];
      ArraySetAsSeries(bollSup,true); ArraySetAsSeries(bollMid,true); ArraySetAsSeries(bollInf,true);
      int c1=CopyBuffer(g_canaisHandleBands,1,0,total,bollSup);
      int c2=CopyBuffer(g_canaisHandleBands,0,0,total,bollMid);
      int c3=CopyBuffer(g_canaisHandleBands,2,0,total,bollInf);
      int n=MathMin(ArraySize(tempos),MathMin(c1,MathMin(c2,c3)));
      if(n>=2)
      {
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_BOLL_SUP",tempos,bollSup,n,clrDodgerBlue,STYLE_SOLID,1);
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_BOLL_MED",tempos,bollMid,n,clrDodgerBlue,STYLE_DOT,1);
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_BOLL_INF",tempos,bollInf,n,clrDodgerBlue,STYLE_SOLID,1);
      }
   }

   if(InpCanaisMostrarKeltnerGrafico)
   {
      double ema[],atr[];
      ArraySetAsSeries(ema,true); ArraySetAsSeries(atr,true);
      int c1=CopyBuffer(g_canaisHandleEMA,0,0,total,ema);
      int c2=CopyBuffer(g_canaisHandleATR,0,0,total,atr);
      int n=MathMin(ArraySize(tempos),MathMin(c1,c2));
      if(n>=2)
      {
         double sup[],med[],inf[];
         ArrayResize(sup,n); ArrayResize(med,n); ArrayResize(inf,n);
         ArraySetAsSeries(sup,true); ArraySetAsSeries(med,true); ArraySetAsSeries(inf,true);
         for(int i=0;i<n;i++)
         {
            med[i]=ema[i];
            sup[i]=ema[i]+atr[i]*InpCanaisMultiplicadorKeltner;
            inf[i]=ema[i]-atr[i]*InpCanaisMultiplicadorKeltner;
         }
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_KELT_SUP",tempos,sup,n,clrOrange,STYLE_DASH,1);
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_KELT_MED",tempos,med,n,clrOrange,STYLE_DOT,1);
         CanaisDesenharSerieSegmentada("COPA_CANAIS_VIS_FIX427_KELT_INF",tempos,inf,n,clrOrange,STYLE_DASH,1);
      }
   }

   if(InpCanaisMostrarPOCGrafico && CanaisCalcularPOCFundoTeto())
   {
      string linha="COPA_CANAIS_VIS_FIX427_POC";
      if(ObjectFind(0,linha)<0)
         ObjectCreate(0,linha,OBJ_HLINE,0,0,g_canaisPOC);
      ObjectSetDouble(0,linha,OBJPROP_PRICE,g_canaisPOC);
      ObjectSetInteger(0,linha,OBJPROP_COLOR,clrGold);
      ObjectSetInteger(0,linha,OBJPROP_STYLE,STYLE_DASHDOTDOT);
      ObjectSetInteger(0,linha,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,linha,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,linha,OBJPROP_HIDDEN,true);

      string label="COPA_CANAIS_VIS_FIX427_POC_TXT";
      datetime tempoTexto=(ArraySize(tempos)>0?tempos[0]:TimeCurrent());
      if(ObjectFind(0,label)<0)
         ObjectCreate(0,label,OBJ_TEXT,0,tempoTexto,g_canaisPOC);
      else
         ObjectMove(0,label,0,tempoTexto,g_canaisPOC);
      ObjectSetString(0,label,OBJPROP_TEXT,"POC " + DoubleToString(g_canaisPOC,_Digits));
      ObjectSetInteger(0,label,OBJPROP_COLOR,clrGold);
      ObjectSetInteger(0,label,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,label,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,label,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   }

   if(InpCanaisMostrarEntradasHistoricasGrafico)
   {
      MqlRates ratesVis[]; ArraySetAsSeries(ratesVis,true);
      int copiadosRates=CopyRates(_Symbol,InpTimeframeCanais,0,total,ratesVis);
      int limite=MathMin(ArraySize(tempos),copiadosRates);
      double offset=InpCanaisVisualDistanciaSetaPontos*_Point;
      for(int shift=limite-2; shift>=1; shift--)
      {
         bool bc,bv,kc,kv,pc,pv,fc,fv; string d;
         if(!CanaisLerSinaisPorShift(shift,bc,bv,kc,kv,pc,pv,fc,fv,d))
            continue;
         bool sinalC=CanaisDecisao(true,bc,kc,pc,fc);
         bool sinalV=CanaisDecisao(false,bv,kv,pv,fv);
         datetime quando=ratesVis[shift].time;
         if(sinalC && (InpOperacaoMotorCanais==CANAIS_SOMENTE_COMPRA || InpOperacaoMotorCanais==CANAIS_AMBOS || InpOperacaoMotorCanais==CANAIS_DESATIVADO))
            CanaisDesenharSetaHistorica("COPA_CANAIS_VIS_FIX427_BUY_"+IntegerToString((int)quando),quando,ratesVis[shift].low-offset,true);
         if(sinalV && (InpOperacaoMotorCanais==CANAIS_SOMENTE_VENDA || InpOperacaoMotorCanais==CANAIS_AMBOS || InpOperacaoMotorCanais==CANAIS_DESATIVADO))
            CanaisDesenharSetaHistorica("COPA_CANAIS_VIS_FIX427_SELL_"+IntegerToString((int)quando),quando,ratesVis[shift].high+offset,false);
      }
   }
}

bool CanaisCalcularPOCFundoTeto()
{
   int barras=MathMax(InpCanaisPeriodoPOC,InpCanaisPeriodoFundoTeto)+2;
   MqlRates rates[]; ArraySetAsSeries(rates,true);
   int copiados=CopyRates(_Symbol,InpTimeframeCanais,1,barras,rates);
   if(copiados<MathMax(InpCanaisPeriodoPOC,InpCanaisPeriodoFundoTeto))
      return false;
   int passoPts=MathMax(1,InpCanaisFaixaPrecoPOCPontos);
   double passo=passoPts*_Point;
   double menor=rates[0].low;
   for(int i=1;i<InpCanaisPeriodoPOC && i<copiados;i++) menor=MathMin(menor,rates[i].low);
   int bins=1;
   double maior=rates[0].high;
   for(int i=1;i<InpCanaisPeriodoPOC && i<copiados;i++) maior=MathMax(maior,rates[i].high);
   bins=(int)MathFloor((maior-menor)/passo)+1;
   if(bins<1) bins=1;
   if(bins>5000) bins=5000;
   double volumes[]; ArrayResize(volumes,bins); ArrayInitialize(volumes,0.0);
   for(int i=0;i<InpCanaisPeriodoPOC && i<copiados;i++)
   {
      double precoTipico=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      int idx=(int)MathFloor((precoTipico-menor)/passo);
      if(idx<0) idx=0; if(idx>=bins) idx=bins-1;
      double vol=(rates[i].real_volume>0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      volumes[idx]+=vol;
   }
   int melhor=0;
   for(int i=1;i<bins;i++) if(volumes[i]>volumes[melhor]) melhor=i;
   g_canaisPOC=NormalizeDouble(menor+(melhor+0.5)*passo,_Digits);
   // Exclui o candle-sinal (shift 1). O teto/fundo anterior usa shifts 2..N+1.
   g_canaisTeto=rates[1].high;
   g_canaisFundo=rates[1].low;
   for(int i=1;i<InpCanaisPeriodoFundoTeto && (i+1)<copiados;i++)
   {
      g_canaisTeto=MathMax(g_canaisTeto,rates[i+1].high);
      g_canaisFundo=MathMin(g_canaisFundo,rates[i+1].low);
   }
   return true;
}

bool CanaisEncontrarPosicao(const long magic,const ENUM_POSITION_TYPE tipo,ulong &ticket,double &volume,double &lucro)
{
   ticket=0; volume=0.0; lucro=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t=PositionGetTicket(i);
      if(t==0 || !PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=tipo) continue;
      ticket=t;
      volume=PositionGetDouble(POSITION_VOLUME);
      lucro+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      return true;
   }
   return false;
}

bool CanaisExisteQualquerPosicao()
{
   ulong t; double v,p;
   return CanaisEncontrarPosicao(InpMagicCompraCanais,POSITION_TYPE_BUY,t,v,p) ||
          CanaisEncontrarPosicao(InpMagicVendaCanais,POSITION_TYPE_SELL,t,v,p);
}

bool CanaisEnviarEntrada(const bool compra,const datetime candle)
{
   long magic=compra?InpMagicCompraCanais:InpMagicVendaCanais;
   if((compra && g_canaisUltimaEntradaCompraCandle==candle) || (!compra && g_canaisUltimaEntradaVendaCandle==candle))
      return false;
   ulong t; double v,p;
   if(CanaisEncontrarPosicao(magic,compra?POSITION_TYPE_BUY:POSITION_TYPE_SELL,t,v,p)) return false;
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return false;
   MqlTradeRequest req={}; MqlTradeResult res={};
   req.action=TRADE_ACTION_DEAL; req.symbol=_Symbol; req.magic=(ulong)magic;
   req.volume=(double)InpCanaisContratoA0;
   req.type=compra?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   req.price=compra?tick.ask:tick.bid;
   req.deviation=20; req.type_filling=TipoPreenchimentoSeguro(); req.comment="CANAIS_A0";
   ResetLastError();
   bool enviado=OrderSend(req,res);
   bool aceito=enviado && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_DONE_PARTIAL || res.retcode==TRADE_RETCODE_PLACED);
   if(aceito)
   {
      if(compra){ g_canaisUltimaEntradaCompraCandle=candle; g_canaisParcialCompraRealizada=false; g_canaisMelhorLucroCompra=0.0; }
      else { g_canaisUltimaEntradaVendaCandle=candle; g_canaisParcialVendaRealizada=false; g_canaisMelhorLucroVenda=0.0; }
      CanaisLog("ENTRADA",StringFormat("%s | MAGIC=%I64d | A0=%dC | CANDLE=%s | ORDEM=%I64u",compra?"COMPRA":"VENDA",magic,InpCanaisContratoA0,TimeToString(candle,TIME_DATE|TIME_MINUTES),res.order),true);
      return true;
   }
   CanaisLog("BLOQUEIO",StringFormat("ORDEM %s REJEITADA | MAGIC=%I64d | RC=%u | ERRO=%d | %s",compra?"COMPRA":"VENDA",magic,res.retcode,GetLastError(),res.comment),true);
   return false;
}

bool CanaisFecharPosicao(const bool compra,const string motivo)
{
   long magic=compra?InpMagicCompraCanais:InpMagicVendaCanais;
   ulong ticket; double volume,lucro;
   if(!CanaisEncontrarPosicao(magic,compra?POSITION_TYPE_BUY:POSITION_TYPE_SELL,ticket,volume,lucro)) return false;
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return false;
   MqlTradeRequest req={}; MqlTradeResult res={};
   req.action=TRADE_ACTION_DEAL; req.symbol=_Symbol; req.magic=(ulong)magic; req.position=ticket;
   req.volume=volume; req.type=compra?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
   req.price=compra?tick.bid:tick.ask; req.deviation=20; req.type_filling=TipoPreenchimentoSeguro();
   req.comment="CANAIS_SAIDA_"+motivo;
   bool enviado=OrderSend(req,res);
   bool aceito=enviado && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_DONE_PARTIAL || res.retcode==TRADE_RETCODE_PLACED);
   if(aceito)
   {
      if(compra) g_canaisUltimaSaidaCompra=TimeCurrent(); else g_canaisUltimaSaidaVenda=TimeCurrent();
      CanaisLog("SAIDA",StringFormat("%s | MAGIC=%I64d | MOTIVO=%s | RESULTADO_ABERTO=R$ %.2f",compra?"COMPRA":"VENDA",magic,motivo,lucro),true);
      return true;
   }
   CanaisLog("BLOQUEIO",StringFormat("FALHA SAIDA %s | MAGIC=%I64d | RC=%u | ERRO=%d",compra?"COMPRA":"VENDA",magic,res.retcode,GetLastError()),true);
   return false;
}


bool CanaisFecharVolume(const bool compra,const double volumeFechar,const string motivo)
{
   long magic=compra?InpMagicCompraCanais:InpMagicVendaCanais;
   ulong ticket; double volume,lucro;
   if(!CanaisEncontrarPosicao(magic,compra?POSITION_TYPE_BUY:POSITION_TYPE_SELL,ticket,volume,lucro)) return false;
   double minVol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=1.0;
   double qtd=MathMin(volume,volumeFechar);
   qtd=MathFloor(qtd/step+1e-9)*step;
   if(qtd<minVol) return false;
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return false;
   MqlTradeRequest req={}; MqlTradeResult res={};
   req.action=TRADE_ACTION_DEAL; req.symbol=_Symbol; req.magic=(ulong)magic; req.position=ticket;
   req.volume=qtd; req.type=compra?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
   req.price=compra?tick.bid:tick.ask; req.deviation=20; req.type_filling=TipoPreenchimentoSeguro();
   req.comment="CANAIS_PARCIAL_"+motivo;
   bool enviado=OrderSend(req,res);
   bool aceito=enviado && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_DONE_PARTIAL || res.retcode==TRADE_RETCODE_PLACED);
   if(aceito)
   {
      CanaisLog("PARCIAL",StringFormat("%s | MAGIC=%I64d | FECHOU=%.2f | ANTES=%.2f | RESTANTE_EST=%.2f | RESULTADO_ABERTO=R$ %.2f | MOTIVO=%s",compra?"COMPRA":"VENDA",magic,qtd,volume,MathMax(0.0,volume-qtd),lucro,motivo),true);
      return true;
   }
   CanaisLog("BLOQUEIO",StringFormat("FALHA PARCIAL %s | MAGIC=%I64d | QTD=%.2f | RC=%u | ERRO=%d",compra?"COMPRA":"VENDA",magic,qtd,res.retcode,GetLastError()),true);
   return false;
}

bool CanaisCalcularPOCFundoTetoPorShift(const int shift,double &poc,double &teto,double &fundo)
{
   int barras=MathMax(InpCanaisPeriodoPOC,InpCanaisPeriodoFundoTeto)+2;
   MqlRates rates[]; ArraySetAsSeries(rates,true);
   int copiados=CopyRates(_Symbol,InpTimeframeCanais,shift,barras,rates);
   if(copiados<MathMax(InpCanaisPeriodoPOC,InpCanaisPeriodoFundoTeto))
      return false;
   int passoPts=MathMax(1,InpCanaisFaixaPrecoPOCPontos);
   double passo=passoPts*_Point;
   double menor=rates[0].low;
   for(int i=1;i<InpCanaisPeriodoPOC && i<copiados;i++) menor=MathMin(menor,rates[i].low);
   double maior=rates[0].high;
   for(int i=1;i<InpCanaisPeriodoPOC && i<copiados;i++) maior=MathMax(maior,rates[i].high);
   int bins=(int)MathFloor((maior-menor)/passo)+1;
   if(bins<1) bins=1;
   if(bins>5000) bins=5000;
   double volumes[]; ArrayResize(volumes,bins); ArrayInitialize(volumes,0.0);
   for(int i=0;i<InpCanaisPeriodoPOC && i<copiados;i++)
   {
      double precoTipico=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      int idx=(int)MathFloor((precoTipico-menor)/passo);
      if(idx<0) idx=0; if(idx>=bins) idx=bins-1;
      double vol=(rates[i].real_volume>0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      volumes[idx]+=vol;
   }
   int melhor=0;
   for(int i=1;i<bins;i++) if(volumes[i]>volumes[melhor]) melhor=i;
   poc=NormalizeDouble(menor+(melhor+0.5)*passo,_Digits);
   teto=rates[1].high;
   fundo=rates[1].low;
   for(int i=1;i<InpCanaisPeriodoFundoTeto && (i+1)<copiados;i++)
   {
      teto=MathMax(teto,rates[i+1].high);
      fundo=MathMin(fundo,rates[i+1].low);
   }
   return true;
}

bool CanaisLerSinaisPorShift(const int shift,bool &bollC,bool &bollV,bool &keltC,bool &keltV,bool &pocC,bool &pocV,bool &ftC,bool &ftV,string &detalhe)
{
   double poc,teto,fundo;
   if(!CanaisCalcularPOCFundoTetoPorShift(shift,poc,teto,fundo)) return false;
   double sup,meio,inf,ema,atr;
   if(!CanaisCopiarValor(g_canaisHandleBands,1,shift,sup) || !CanaisCopiarValor(g_canaisHandleBands,0,shift,meio) ||
      !CanaisCopiarValor(g_canaisHandleBands,2,shift,inf) || !CanaisCopiarValor(g_canaisHandleEMA,0,shift,ema) ||
      !CanaisCopiarValor(g_canaisHandleATR,0,shift,atr)) return false;
   double close=iClose(_Symbol,InpTimeframeCanais,shift);
   if(close<=0.0) return false;
   double ks=ema+atr*InpCanaisMultiplicadorKeltner, ki=ema-atr*InpCanaisMultiplicadorKeltner;
   bollC=!InpCanaisUsarBollinger || close>sup; bollV=!InpCanaisUsarBollinger || close<inf;
   keltC=!InpCanaisUsarKeltner || close>ks; keltV=!InpCanaisUsarKeltner || close<ki;
   pocC=!InpCanaisUsarPOC || close>poc+InpCanaisDistanciaMinimaPOCPontos*_Point; pocV=!InpCanaisUsarPOC || close<poc-InpCanaisDistanciaMinimaPOCPontos*_Point;
   double distTeto=(teto-close)/_Point, distFundo=(close-fundo)/_Point;
   bool rompeTeto=InpCanaisPermitirRompimentoConfirmado && close>teto;
   bool rompeFundo=InpCanaisPermitirRompimentoConfirmado && close<fundo;
   ftC=!InpCanaisUsarFundoTeto || distTeto>=InpCanaisDistanciaMinimaTetoPontos || rompeTeto;
   ftV=!InpCanaisUsarFundoTeto || distFundo>=InpCanaisDistanciaMinimaFundoPontos || rompeFundo;
   detalhe=StringFormat("BOLL=%s | KELT=%s | POC=%s | F/T=%s",(bollC||bollV)?"OK":"NAO",(keltC||keltV)?"OK":"NAO",(pocC||pocV)?"OK":"NAO",(ftC||ftV)?"LIVRE":"BLOQ");
   return true;
}

void CanaisDesenharSetaHistorica(const string nome,const datetime quando,const double preco,const bool compra)
{
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_ARROW,0,quando,preco);
   else
      ObjectMove(0,nome,0,quando,preco);
   ObjectSetInteger(0,nome,OBJPROP_ARROWCODE,compra?241:242);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,compra?clrAqua:clrOrangeRed);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
}

bool CanaisLerSinais(const int shift,bool &bollC,bool &bollV,bool &keltC,bool &keltV,bool &pocC,bool &pocV,bool &ftC,bool &ftV,string &detalhe)
{
   double sup,meio,inf,ema,atr;
   if(!CanaisCopiarValor(g_canaisHandleBands,1,shift,sup) || !CanaisCopiarValor(g_canaisHandleBands,0,shift,meio) ||
      !CanaisCopiarValor(g_canaisHandleBands,2,shift,inf) || !CanaisCopiarValor(g_canaisHandleEMA,0,shift,ema) ||
      !CanaisCopiarValor(g_canaisHandleATR,0,shift,atr)) return false;
   double close=iClose(_Symbol,InpTimeframeCanais,shift);
   if(close<=0.0) return false;
   double ks=ema+atr*InpCanaisMultiplicadorKeltner, ki=ema-atr*InpCanaisMultiplicadorKeltner;
   bollC=!InpCanaisUsarBollinger || close>sup; bollV=!InpCanaisUsarBollinger || close<inf;
   keltC=!InpCanaisUsarKeltner || close>ks; keltV=!InpCanaisUsarKeltner || close<ki;
   pocC=!InpCanaisUsarPOC || close>g_canaisPOC+InpCanaisDistanciaMinimaPOCPontos*_Point; pocV=!InpCanaisUsarPOC || close<g_canaisPOC-InpCanaisDistanciaMinimaPOCPontos*_Point;
   double distTeto=(g_canaisTeto-close)/_Point, distFundo=(close-g_canaisFundo)/_Point;
   bool rompeTeto=InpCanaisPermitirRompimentoConfirmado && close>g_canaisTeto;
   bool rompeFundo=InpCanaisPermitirRompimentoConfirmado && close<g_canaisFundo;
   ftC=!InpCanaisUsarFundoTeto || distTeto>=InpCanaisDistanciaMinimaTetoPontos || rompeTeto;
   ftV=!InpCanaisUsarFundoTeto || distFundo>=InpCanaisDistanciaMinimaFundoPontos || rompeFundo;
   detalhe=StringFormat("BOLL=%s | KELT=%s | POC=%s | F/T=%s",(bollC||bollV)?"OK":"NAO",(keltC||keltV)?"OK":"NAO",(pocC||pocV)?"OK":"NAO",(ftC||ftV)?"LIVRE":"BLOQ");
   return true;
}

bool CanaisDecisao(const bool compra,const bool boll,const bool kelt,const bool poc,const bool ft)
{
   int ativos=0,ok=0;
   if(InpCanaisUsarBollinger){ativos++; if(boll)ok++;}
   if(InpCanaisUsarKeltner){ativos++; if(kelt)ok++;}
   if(InpCanaisUsarPOC){ativos++; if(poc)ok++;}
   if(InpCanaisUsarFundoTeto){ativos++; if(ft)ok++;}
   if(ativos==0) return false;
   switch(InpModoDecisaoCanais)
   {
      case CANAIS_TODOS_CONFIRMAM: return ok==ativos;
      case CANAIS_MINIMO_CONFIRMACOES: return ok>=MathMin(ativos,MathMax(1,InpConfirmacoesMinimasCanais));
      case CANAIS_BOLLINGER_KELTNER_OBRIGATORIOS: return boll && kelt && ok>=MathMin(ativos,MathMax(1,InpConfirmacoesMinimasCanais));
      case CANAIS_POC_OBRIGATORIO: return poc && ok>=MathMin(ativos,MathMax(1,InpConfirmacoesMinimasCanais));
      case CANAIS_FUNDO_TETO_OBRIGATORIO: return ft && ok>=MathMin(ativos,MathMax(1,InpConfirmacoesMinimasCanais));
   }
   return false;
}

bool CanaisConfirmarSequencia(const bool compra)
{
   int n=MathMax(1,InpCanaisCandlesConfirmacao);
   for(int shift=1;shift<=n;shift++)
   {
      bool bc,bv,kc,kv,pc,pv,fc,fv; string d;
      if(!CanaisLerSinais(shift,bc,bv,kc,kv,pc,pv,fc,fv,d)) return false;
      if(!CanaisDecisao(compra,compra?bc:bv,compra?kc:kv,compra?pc:pv,compra?fc:fv)) return false;
   }
   return true;
}

void CanaisGerenciarSaidas()
{
   ulong ticket; double volume,lucro;
   if(CanaisEncontrarPosicao(InpMagicCompraCanais,POSITION_TYPE_BUY,ticket,volume,lucro))
   {
      g_canaisMelhorLucroCompra=MathMax(g_canaisMelhorLucroCompra,lucro);
      if(lucro<=-MathAbs(InpCanaisStopFinanceiro)){ CanaisFecharPosicao(true,"STOP"); return; }
      if(!g_canaisParcialCompraRealizada && lucro>=InpCanaisAlvoFinanceiro)
      {
         if(InpCanaisFecharTudoNoAlvo || !InpCanaisUsarParcial || volume<=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
         { CanaisFecharPosicao(true,"ALVO_TOTAL"); return; }
         if(CanaisFecharVolume(true,(double)InpCanaisContratosParcial,"ALVO_1"))
         { g_canaisParcialCompraRealizada=true; g_canaisMelhorLucroCompra=lucro; return; }
      }
      if(g_canaisParcialCompraRealizada || !InpCanaisUsarParcial)
      {
         if(g_canaisMelhorLucroCompra>=InpCanaisTrailingAtiva)
         {
            double defesa=g_canaisMelhorLucroCompra-InpCanaisTrailingPasso;
            if(lucro<=defesa){ CanaisLog("TRAILING",StringFormat("COMPRA | MELHOR=R$ %.2f | DEFESA=R$ %.2f | ATUAL=R$ %.2f",g_canaisMelhorLucroCompra,defesa,lucro),true); CanaisFecharPosicao(true,"TRAILING"); return; }
         }
         else if(g_canaisMelhorLucroCompra>=InpCanaisMovelAtiva && lucro<=InpCanaisMovelDefende)
         { CanaisLog("MOVEL",StringFormat("COMPRA | ATIVA=R$ %.2f | DEFENDE=R$ %.2f | ATUAL=R$ %.2f",InpCanaisMovelAtiva,InpCanaisMovelDefende,lucro),true); CanaisFecharPosicao(true,"MOVEL"); return; }
      }
   }
   else { g_canaisMelhorLucroCompra=0.0; g_canaisParcialCompraRealizada=false; }

   if(CanaisEncontrarPosicao(InpMagicVendaCanais,POSITION_TYPE_SELL,ticket,volume,lucro))
   {
      g_canaisMelhorLucroVenda=MathMax(g_canaisMelhorLucroVenda,lucro);
      if(lucro<=-MathAbs(InpCanaisStopFinanceiro)){ CanaisFecharPosicao(false,"STOP"); return; }
      if(!g_canaisParcialVendaRealizada && lucro>=InpCanaisAlvoFinanceiro)
      {
         if(InpCanaisFecharTudoNoAlvo || !InpCanaisUsarParcial || volume<=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
         { CanaisFecharPosicao(false,"ALVO_TOTAL"); return; }
         if(CanaisFecharVolume(false,(double)InpCanaisContratosParcial,"ALVO_1"))
         { g_canaisParcialVendaRealizada=true; g_canaisMelhorLucroVenda=lucro; return; }
      }
      if(g_canaisParcialVendaRealizada || !InpCanaisUsarParcial)
      {
         if(g_canaisMelhorLucroVenda>=InpCanaisTrailingAtiva)
         {
            double defesa=g_canaisMelhorLucroVenda-InpCanaisTrailingPasso;
            if(lucro<=defesa){ CanaisLog("TRAILING",StringFormat("VENDA | MELHOR=R$ %.2f | DEFESA=R$ %.2f | ATUAL=R$ %.2f",g_canaisMelhorLucroVenda,defesa,lucro),true); CanaisFecharPosicao(false,"TRAILING"); return; }
         }
         else if(g_canaisMelhorLucroVenda>=InpCanaisMovelAtiva && lucro<=InpCanaisMovelDefende)
         { CanaisLog("MOVEL",StringFormat("VENDA | ATIVA=R$ %.2f | DEFENDE=R$ %.2f | ATUAL=R$ %.2f",InpCanaisMovelAtiva,InpCanaisMovelDefende,lucro),true); CanaisFecharPosicao(false,"MOVEL"); return; }
      }
   }
   else { g_canaisMelhorLucroVenda=0.0; g_canaisParcialVendaRealizada=false; }
}

void CanaisProcessarNovoCandle()
{
   if(!CanaisMotorAtivo()) return;
   datetime candle=iTime(_Symbol,InpTimeframeCanais,1);
   if(candle<=0 || candle==g_canaisUltimoCandleProcessado) return;
   g_canaisUltimoCandleProcessado=candle;
   if(!CanaisCalcularPOCFundoTeto()){ CanaisLog("BLOQUEIO","Dados insuficientes para POC/Fundo/Teto"); return; }
   CanaisAtualizarVisualGrafico(true);
   bool bc,bv,kc,kv,pc,pv,fc,fv; string detalhe;
   if(!CanaisLerSinais(1,bc,bv,kc,kv,pc,pv,fc,fv,detalhe)){ CanaisLog("BLOQUEIO","Falha ao ler indicadores"); return; }
   // Saída por perda de sinal sempre no candle fechado e somente nos Magics do motor.
   if(InpCanaisSairPerdaSinal)
   {
      ulong t; double v,l;
      double close=iClose(_Symbol,InpTimeframeCanais,1), bs,bm,bi,ema,atr;
      if(CanaisCopiarValor(g_canaisHandleBands,1,1,bs) && CanaisCopiarValor(g_canaisHandleBands,0,1,bm) && CanaisCopiarValor(g_canaisHandleBands,2,1,bi) && CanaisCopiarValor(g_canaisHandleEMA,0,1,ema) && CanaisCopiarValor(g_canaisHandleATR,0,1,atr))
      {
         double ks=ema+atr*InpCanaisMultiplicadorKeltner,ki=ema-atr*InpCanaisMultiplicadorKeltner;
         if(CanaisEncontrarPosicao(InpMagicCompraCanais,POSITION_TYPE_BUY,t,v,l) && ((close<bs && close<ks) || close<g_canaisPOC))
         { CanaisLog("PERDA_SINAL","COMPRA perdeu canais/POC",true); CanaisFecharPosicao(true,"PERDA_SINAL"); }
         if(CanaisEncontrarPosicao(InpMagicVendaCanais,POSITION_TYPE_SELL,t,v,l) && ((close>bi && close>ki) || close>g_canaisPOC))
         { CanaisLog("PERDA_SINAL","VENDA perdeu canais/POC",true); CanaisFecharPosicao(false,"PERDA_SINAL"); }
      }
   }
   bool sinalC=CanaisConfirmarSequencia(true), sinalV=CanaisConfirmarSequencia(false);
   g_canaisStatusPainel=StringFormat("CANAIS | BOLL=%s | KELT=%s | POC=%s | F/T=%s | SINAL=%s",bc?"OK":"NAO",kc?"OK":"NAO",pc?"COMPRA":(pv?"VENDA":"NAO"),fc?"LIVRE":"BLOQ",sinalC?"COMPRA":(sinalV?"VENDA":"AGUARDA"));
   if(CanaisExisteQualquerPosicao()) return;
   datetime agora=TimeCurrent();
   if(agora-g_canaisUltimaSaidaCompra<InpCanaisTempoRearmeSegundos || agora-g_canaisUltimaSaidaVenda<InpCanaisTempoRearmeSegundos)
   { CanaisLog("BLOQUEIO","REARME ATIVO"); return; }
   if(!InpAtivarRobo || !g_ambienteLiberado || BloquearNovasOperacoesFimDiaFIX215()) return;
   if(sinalC && (InpOperacaoMotorCanais==CANAIS_SOMENTE_COMPRA || InpOperacaoMotorCanais==CANAIS_AMBOS))
      CanaisEnviarEntrada(true,candle);
   else if(sinalV && (InpOperacaoMotorCanais==CANAIS_SOMENTE_VENDA || InpOperacaoMotorCanais==CANAIS_AMBOS))
      CanaisEnviarEntrada(false,candle);
   else if((bc&&kc&&pc&&!fc) || (bv&&kv&&pv&&!fv))
      CanaisLog("BLOQUEIO",StringFormat("%s | %s",sinalC?"COMPRA":"VENDA",detalhe));
   else CanaisLog("SINAL",g_canaisStatusPainel);
}

void CanaisAtualizarPainel()
{
   string nome="COPA_CANAIS_LINHA_FIX423";
   if(!CanaisMotorAtivo()){ ObjectDelete(0,nome); return; }
   ulong t; double v,l;
   if(CanaisEncontrarPosicao(InpMagicCompraCanais,POSITION_TYPE_BUY,t,v,l))
      g_canaisStatusPainel=StringFormat("CANAIS COMPRA | MAGIC=%I64d | A0=%dC | PARCIAL=%dC@R$%.0f | STOP=R$%.0f",InpMagicCompraCanais,InpCanaisContratoA0,InpCanaisContratosParcial,InpCanaisAlvoFinanceiro,InpCanaisStopFinanceiro);
   else if(CanaisEncontrarPosicao(InpMagicVendaCanais,POSITION_TYPE_SELL,t,v,l))
      g_canaisStatusPainel=StringFormat("CANAIS VENDA | MAGIC=%I64d | A0=%dC | PARCIAL=%dC@R$%.0f | STOP=R$%.0f",InpMagicVendaCanais,InpCanaisContratoA0,InpCanaisContratosParcial,InpCanaisAlvoFinanceiro,InpCanaisStopFinanceiro);
   if(ObjectFind(0,nome)<0)
   {
      ObjectCreate(0,nome,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,nome,OBJPROP_CORNER,CORNER_LEFT_LOWER);
      ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,10);
      ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,12);
      ObjectSetInteger(0,nome,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
   }
   ObjectSetString(0,nome,OBJPROP_TEXT,g_canaisStatusPainel);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,clrSilver);
}

void CanaisProcessarTick()
{
   if(!CanaisMotorAtivo()) return;
   CanaisGerenciarSaidas();
   CanaisProcessarNovoCandle();
}

void CanaisSincronizarTimer()
{
   if(CanaisVisualAtivo())
      CanaisAtualizarVisualGrafico();
   if(!CanaisMotorAtivo()) return;
   CanaisGerenciarSaidas(); // recuperação/saída financeira; entrada permanece exclusiva do novo candle.
   CanaisAtualizarPainel();
}

void CanaisProcessarTradeTransaction(const MqlTradeTransaction &trans)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || trans.deal==0 || !HistoryDealSelect(trans.deal)) return;
   long magic=(long)HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(!CanaisMagicValido(magic)) return;
   string simbolo=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
   if(simbolo!=_Symbol) return;
   long entry=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   double resultado=HistoryDealGetDouble(trans.deal,DEAL_PROFIT)+HistoryDealGetDouble(trans.deal,DEAL_SWAP)+HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   CanaisLog(entry==DEAL_ENTRY_IN?"ENTRADA":"SAIDA",StringFormat("DEAL=%I64u | MAGIC=%I64d | RESULTADO=R$ %.2f",trans.deal,magic,resultado),true);
   if(entry!=DEAL_ENTRY_IN)
   {
      if(magic==InpMagicCompraCanais) g_canaisUltimaSaidaCompra=TimeCurrent();
      if(magic==InpMagicVendaCanais) g_canaisUltimaSaidaVenda=TimeCurrent();
   }
}


// ============================================================================
// RESPONSABILIDADE: CANDLES CONTRA E DIAGNOSTICO
// ============================================================================

int ContarObjetosCandlesContraFIX262()
{
   int encontrados = 0;
   string prefixo = PrefixoCandleContraFIX258();
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, prefixo) == 0)
         encontrados++;
   }
   return encontrados;
}

void AtualizarDiagnosticoCandlesContraFIX263()
{
   // FIX294: remove somente o aviso flutuante de carregamento/diagnostico.
   // O historico, os sinais e os calculos continuam funcionando normalmente.
   string nomes[] = {
      "AR100_CONTRA_STATUS_FIX273",
      "AR100_CONTRA_STATUS_FIX272",
      "AR100_CONTRA_STATUS_FIX271",
      "AR100_CONTRA_STATUS_FIX270",
      "AR100_CONTRA_STATUS_FIX269",
      "AR100_CONTRA_STATUS_FIX268",
      "AR100_CONTRA_STATUS_FIX267",
      "AR100_CONTRA_STATUS_FIX266",
      "AR100_CONTRA_STATUS_FIX265",
      "AR100_CONTRA_STATUS_FIX264",
      "AR100_CONTRA_STATUS_FIX263"
   };
   for(int i=0;i<ArraySize(nomes);i++)
      ObjectDelete(0,nomes[i]);
}

void CarregarHistoricoCandlesContraFIX261()
{
   if(!g_painelProntoFIX259 || !InpPlotarCandlesContra || !InpContraCarregarHistorico)
      return;

   AtualizarDiagnosticoCandlesContraFIX263();

   // FIX263: o painel e a troca de Magic não podem mais apagar os candles.
   int objetosAtuais = ContarObjetosCandlesContraFIX262();
   if(g_historicoCandlesContraCarregadoFIX261 && objetosAtuais > 0)
   {
      g_statusCargaContraFIX263 = "HISTORICO OK";
      AtualizarDiagnosticoCandlesContraFIX263();
      return;
   }
   datetime agoraVarredura = TimeLocal();
   if(agoraVarredura <= 0)
      agoraVarredura = TimeCurrent();
   if(g_historicoCandlesContraCarregadoFIX261 && objetosAtuais == 0 &&
      g_ultimaVarreduraCandlesContraFIX262 > 0 &&
      (agoraVarredura - g_ultimaVarreduraCandlesContraFIX262) < 30)
      return;
   g_ultimaVarreduraCandlesContraFIX262 = agoraVarredura;
   g_tentativasCargaContraFIX263++;

   ENUM_TIMEFRAMES tfContraFIX263 = TimeframeFiltroAtualFIX255();
   long serieSincronizadaFIX263 = 0;
   bool serieOKFIX263 = SeriesInfoInteger(_Symbol, tfContraFIX263, SERIES_SYNCHRONIZED, serieSincronizadaFIX263);
   int barrasDisponiveis = Bars(_Symbol, tfContraFIX263);
   if(!serieOKFIX263 || serieSincronizadaFIX263 == 0 || barrasDisponiveis < 60)
   {
      g_historicoCandlesContraCarregadoFIX261 = false;
      g_statusCargaContraFIX263 = StringFormat("CARREGANDO HISTORICO TENTATIVA %d", g_tentativasCargaContraFIX263);
      AtualizarDiagnosticoCandlesContraFIX263();
      if((g_tentativasCargaContraFIX263 % 10) == 1)
         Print("[COPA_AR100][FIX273][CONTRA] Aguardando série histórica sincronizar | TF=",
               EnumToString(tfContraFIX263), " | barras=", barrasDisponiveis,
               " | sincronizada=", serieSincronizadaFIX263,
               " | tentativa=", g_tentativasCargaContraFIX263);
      return;
   }
   int quantidade = InpContraBarrasHistoricas;
   if(quantidade < 20)
      quantidade = 20;
   if(quantidade > 5000)
      quantidade = 5000;
   int margemBase = (int)MathMax(InpContraVolumeMediaPeriodo + 15, InpContraJanelaSetupBarras + InpContraJanelaRetornoRSIBarras + InpContraEstruturaBarras + 20);
   int margem = (int)MathMax(60, margemBase);
   quantidade = (int)MathMin(quantidade, barrasDisponiveis - margem);
   if(quantidade < 1)
      return;
   // FIX263: somente confirma a carga depois de validar OHLC suficiente.
   g_historicoCandlesContraCarregadoFIX261 = false;
   g_totalCandlesContraPintadosFIX261 = 0;
   g_sinaisCompraContraFIX263 = 0;
   g_sinaisVendaContraFIX263 = 0;
   g_ottCruzCompraFIX272 = 0;
   g_ottCruzVendaFIX272 = 0;
   g_ottSetupCompraFIX272 = 0;
   g_ottSetupVendaFIX272 = 0;
   g_darvasFalsoCompraFIX273 = 0;
   g_darvasFalsoVendaFIX273 = 0;
   g_darvasSetupCompraFIX273 = 0;
   g_darvasSetupVendaFIX273 = 0;
   g_sinaisFibo078FIX269 = 0;
   g_sinaisFibo127FIX269 = 0;
   g_sinaisFibo161FIX269 = 0;
   int candidatosRSI = 0;
   int melhorScore = 0;
   int barrasComOHLCFIX263 = 0;
   if(!InpContraUsarDarvasFIX273 && InpContraUsarOTTFIX271 && !PrepararCacheOTTFIX271(quantidade + 80))
   {
      g_statusCargaContraFIX263 = "OTT CARREGANDO";
      AtualizarDiagnosticoCandlesContraFIX263();
      return;
   }
   for(int shift = quantidade; shift >= 1; shift--)
   {
      double testeOpenFIX263 = iOpen(_Symbol, tfContraFIX263, shift);
      double testeHighFIX263 = iHigh(_Symbol, tfContraFIX263, shift);
      double testeLowFIX263 = iLow(_Symbol, tfContraFIX263, shift);
      double testeCloseFIX263 = iClose(_Symbol, tfContraFIX263, shift);
      if(testeOpenFIX263 <= 0.0 || testeHighFIX263 <= 0.0 || testeLowFIX263 <= 0.0 || testeCloseFIX263 <= 0.0)
         continue;
      barrasComOHLCFIX263++;

      ENUM_LADO_ROBO lado = LADO_NENHUM;
      double rsi = -1.0;
      double agrCompra = -1.0;
      double ratioQtd = 0.0;
      double ratioFin = 0.0;
      int confirmacoes = 0;
      bool sinalContra = AvaliarCandleContraFIX261(shift, false, lado, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);
      if(confirmacoes > melhorScore)
         melhorScore = confirmacoes;
      if(rsi >= InpContraRSISobrecompra || rsi <= InpContraRSISobrevenda)
         candidatosRSI++;
      if(!sinalContra)
         continue;

      datetime tempo = iTime(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double abertura = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double maxima = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double minima = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double fechamento = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      PlotarCandleContraFIX258(tempo, lado, abertura, maxima, minima, fechamento);
      if(tempo > g_ultimoSinalContraHoraFIX310)
      {
         g_ultimoSinalContraHoraFIX310 = tempo;
         g_ultimoSinalContraLadoFIX310 = lado;
      }
      double nivelForteContagem = MathMax(MathAbs(InpContraFiboNivelMinimo), MathAbs(InpContraFiboNivelForte));
      if(g_ultimoFiboNivelSinalFIX269 >= nivelForteContagem - 0.0001)
         g_sinaisFibo161FIX269++;
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboNivelMinimo) - 0.0001)
         g_sinaisFibo127FIX269++;
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboPivoMinimoFIX269) - 0.0001)
         g_sinaisFibo078FIX269++;
      g_totalCandlesContraPintadosFIX261++;
      if(lado == LADO_COMPRA)
         g_sinaisCompraContraFIX263++;
      else if(lado == LADO_VENDA)
         g_sinaisVendaContraFIX263++;
   }

   if(barrasComOHLCFIX263 < MathMin(20, quantidade))
   {
      g_historicoCandlesContraCarregadoFIX261 = false;
      g_statusCargaContraFIX263 = StringFormat("OHLC INCOMPLETO %d/%d", barrasComOHLCFIX263, quantidade);
      AtualizarDiagnosticoCandlesContraFIX263();
      return;
   }

   g_historicoCandlesContraCarregadoFIX261 = true;
   g_statusCargaContraFIX263 = StringFormat("HISTORICO OK %d BARRAS", barrasComOHLCFIX263);
   g_ultimoCandleContraProcessadoFIX258 = iTime(_Symbol, TimeframeFiltroAtualFIX255(), 1);
   LimitarCandlesContraFIX258();
   if(InpContraUsarDarvasFIX273)
      PlotarCaixasDarvasFIX273();
   else
      PlotarLinhasOTTFIX271();
   AtualizarDiagnosticoCandlesContraFIX263();
   ChartSetInteger(0, CHART_FOREGROUND, false);
   ChartRedraw(0);
   Print("[COPA_AR100][FIX273][CONTRA] Historico analisado: ", quantidade,
         " | OHLC validas: ", barrasComOHLCFIX263,
         " barras | RSI extremos: ", candidatosRSI,
         " | melhor confirmacao: ", melhorScore, (InpContraUsarDarvasFIX273 ? "/18" : (InpContraUsarOTTFIX271 ? "/20" : (InpContraUsarCruzamentoFIX270 ? "/18" : (InpContraUsarPivoFiboFIX269 ? "/14" : (InpContraModoCirurgico ? "/11" : "/5"))))),
         " | modo: ", (InpContraUsarDarvasFIX273 ? "SINAL_CONTRA" : (InpContraUsarOTTFIX271 ? "OTT" : (InpContraUsarCruzamentoFIX270 ? "CRUZAMENTO_5X13" : (InpContraUsarPivoFiboFIX269 ? "PIVO_FIBO" : (InpContraModoCirurgico ? "FIBO_BALANCEADO" : "SCORE"))))),
         " | sinais pintados: ", g_totalCandlesContraPintadosFIX261,
         " | objetos visiveis: ", ContarObjetosCandlesContraFIX262(),
         " | azul=compra contra | amarelo=venda contra.");
}

string PrefixoCandleContraFIX258()
{
   return "COPA_AR100_CONTRA_FIX258_";
}

void ConfigurarRetanguloCandleContraFIX258(string nome, datetime tempo1, double preco1, datetime tempo2, double preco2, color cor)
{
   if(ObjectFind(0, nome) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, nome, OBJ_RECTANGLE, 0, tempo1, preco1, tempo2, preco2))
      {
         Print("[COPA_AR100][FIX273][ERRO_PINTURA] Falha ao criar ", nome, " | erro=", GetLastError());
         return;
      }
   }
   else
   {
      ObjectMove(0, nome, 0, tempo1, preco1);
      ObjectMove(0, nome, 1, tempo2, preco2);
   }
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, nome, OBJPROP_FILL, true);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 100);
}

void ConfigurarSetaCandleContraFIX264(string nome,
                                      bool compraContra,
                                      datetime tempo,
                                      double preco,
                                      color cor)
{
   ENUM_OBJECT tipo = (compraContra ? OBJ_ARROW_UP : OBJ_ARROW_DOWN);
   if(ObjectFind(0, nome) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, nome, tipo, 0, tempo, preco))
      {
         Print("[COPA_AR100][FIX273][ERRO_SETA] Falha ao criar ", nome, " | erro=", GetLastError());
         return;
      }
   }
   else
      ObjectMove(0, nome, 0, tempo, preco);

   int tamanho = InpContraTamanhoSeta;
   if(tamanho < 1) tamanho = 1;
   if(tamanho > 5) tamanho = 5;
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, tamanho);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 300);
}

void ConfigurarEtiquetaCandleContraFIX264(string nome,
                                          bool compraContra,
                                          datetime tempo,
                                          double preco,
                                          color cor)
{
   if(ObjectFind(0, nome) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, nome, OBJ_TEXT, 0, tempo, preco))
      {
         Print("[COPA_AR100][FIX273][ERRO_TEXTO] Falha ao criar ", nome, " | erro=", GetLastError());
         return;
      }
   }
   else
      ObjectMove(0, nome, 0, tempo, preco);

   string textoFibo = (g_textoEtiquetaContraFIX271 != "" ? g_textoEtiquetaContraFIX271 : (compraContra ? "C" : "V"));
   if(g_textoEtiquetaContraFIX271 == "" && !InpContraEtiquetaSomenteLadoFIX270)
   {
      double nivelForteEtiqueta = MathMax(MathAbs(InpContraFiboNivelMinimo), MathAbs(InpContraFiboNivelForte));
      if(g_ultimoFiboNivelSinalFIX269 >= nivelForteEtiqueta - 0.0001)
         textoFibo += "161";
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboNivelMinimo) - 0.0001)
         textoFibo += "127";
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboPivoMinimoFIX269) - 0.0001)
         textoFibo += "78";
      else
         textoFibo += "P";
   }
   ObjectSetString(0, nome, OBJPROP_TEXT, textoFibo);
   ObjectSetString(0, nome, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_ANCHOR, (compraContra ? ANCHOR_UPPER : ANCHOR_LOWER));
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 301);
}

void PlotarCandleContraFIX258(datetime tempoBarra,
                              ENUM_LADO_ROBO entradaContra,
                              double precoAbertura,
                              double maxima,
                              double minima,
                              double fechamento)
{
   if(tempoBarra <= 0 || maxima <= 0.0 || minima <= 0.0)
      return;

   int segundosTF = PeriodSeconds(TimeframeFiltroAtualFIX255());
   if(segundosTF <= 0)
      segundosTF = 60;
   int larguraBarras = InpContraLarguraVisualBarras;
   if(larguraBarras < 1) larguraBarras = 1;
   if(larguraBarras > 5) larguraBarras = 5;
   // FIX264: no M1 afastado um candle pode ocupar menos de 1 pixel.
   // O destaque usa de 1 a 5 barras de largura, mas a seta marca o candle exato.
   int meiaLarguraCorpo = (int)MathMax(3.0, (double)segundosTF * 0.48 * (double)larguraBarras);
   int meiaLarguraPavio = (int)MathMax(2.0, (double)segundosTF * 0.07 * (double)larguraBarras);
   datetime centro = tempoBarra + segundosTF / 2;

   ChartSetInteger(0, CHART_FOREGROUND, false); // FIX263: objetos coloridos ficam sobre os candles normais
   color cor = (entradaContra == LADO_COMPRA ? InpContraCorCompra : InpContraCorVenda);
   string ladoNome = (entradaContra == LADO_COMPRA ? "AZUL_COMPRA_" : "AMARELO_VENDA_");
   string base = PrefixoCandleContraFIX258() + ladoNome + IntegerToString((int)tempoBarra);

   double corpoTopo = MathMax(precoAbertura, fechamento);
   double corpoFundo = MathMin(precoAbertura, fechamento);
   double alturaMinima = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(alturaMinima <= 0.0)
      alturaMinima = _Point;
   if(alturaMinima <= 0.0)
      alturaMinima = 0.01;
   if(corpoTopo - corpoFundo < alturaMinima)
   {
      double meio = (corpoTopo + corpoFundo) / 2.0;
      corpoTopo = meio + alturaMinima / 2.0;
      corpoFundo = meio - alturaMinima / 2.0;
   }

   ConfigurarRetanguloCandleContraFIX258(base + "_PAVIO",
                                         centro - meiaLarguraPavio,
                                         maxima,
                                         centro + meiaLarguraPavio,
                                         minima,
                                         cor);
   ConfigurarRetanguloCandleContraFIX258(base + "_CORPO",
                                         centro - meiaLarguraCorpo,
                                         corpoTopo,
                                         centro + meiaLarguraCorpo,
                                         corpoFundo,
                                         cor);

   bool compraContra = (entradaContra == LADO_COMPRA);
   double range = maxima - minima;
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0) tick = _Point;
   if(tick <= 0.0) tick = 1.0;
   double afastamento = MathMax(range * 0.30, tick * 20.0);
   double precoSeta = (compraContra ? minima - afastamento : maxima + afastamento);

   if(InpContraMostrarSetaConfirmacao)
      ConfigurarSetaCandleContraFIX264(base + "_SETA", compraContra, centro, precoSeta, cor);

   if(InpContraMostrarEtiqueta)
   {
      double precoTexto = (compraContra ? precoSeta - afastamento * 0.35 : precoSeta + afastamento * 0.35);
      ConfigurarEtiquetaCandleContraFIX264(base + "_LETRA", compraContra, centro, precoTexto, cor);
   }
}

void LimparCandlesContraFIX258()
{
   string prefixo = PrefixoCandleContraFIX258();
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, prefixo) == 0)
         ObjectDelete(0, nome);
   }
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX272");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX273");
   LimparCaixasDarvasFIX273();
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX271");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX270");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX269");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX268");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX267");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX266");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX265");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX264");
   ObjectDelete(0, "AR100_CONTRA_STATUS_FIX263");
   g_ultimoCandleContraProcessadoFIX258 = 0;
   g_sinaisCompraContraFIX263 = 0;
   g_sinaisVendaContraFIX263 = 0;
   g_ottCruzCompraFIX272 = 0;
   g_ottCruzVendaFIX272 = 0;
   g_ottSetupCompraFIX272 = 0;
   g_ottSetupVendaFIX272 = 0;
   g_darvasFalsoCompraFIX273 = 0;
   g_darvasFalsoVendaFIX273 = 0;
   g_darvasSetupCompraFIX273 = 0;
   g_darvasSetupVendaFIX273 = 0;
   LimparLinhasOTTFIX271();
   ArrayFree(g_ottSuporteFIX271);
   ArrayFree(g_ottLinhaRawFIX271);
   ArrayFree(g_ottLongStopFIX271);
   ArrayFree(g_ottShortStopFIX271);
   ArrayFree(g_ottDirecaoFIX271);
   g_ottCacheMaxShiftFIX271 = -1;
   g_ottCacheBarraAtualFIX271 = 0;
}

void LimitarCandlesContraFIX258()
{
   int manter = InpContraManterCandlesNoGrafico;
   if(manter < 20)
      manter = 20;
   if(manter > 5000)
      manter = 5000;
   datetime corte = iTime(_Symbol, TimeframeFiltroAtualFIX255(), manter);
   if(corte <= 0)
      return;

   string prefixo = PrefixoCandleContraFIX258();
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, prefixo) != 0)
         continue;
      datetime tempoObjeto = (datetime)ObjectGetInteger(0, nome, OBJPROP_TIME, 0);
      if(tempoObjeto > 0 && tempoObjeto < corte)
         ObjectDelete(0, nome);
   }
}

// FIX266: somente o candle que confirma RSI + estrutura + média recebe a cor.
// A barra fechada e avaliada com os valores da propria barra; a funcao nao envia ordens.
void AtualizarCandlesContraFIX258(bool forcar)
{
   if(!g_painelProntoFIX259)
      return;

   if(!InpPlotarCandlesContra)
   {
      if(g_ultimoCandleContraProcessadoFIX258 != 0)
         LimparCandlesContraFIX258();
      return;
   }

   const int shift = 1;
   datetime tempoBarra = iTime(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   if(tempoBarra <= 0)
      return;
   if(!forcar && tempoBarra == g_ultimoCandleContraProcessadoFIX258)
      return;
   g_ultimoCandleContraProcessadoFIX258 = tempoBarra;

   if(InpContraUsarDarvasFIX273)
   {
      if(InpContraDarvasUsarOTTConfirmacaoFIX273)
         PrepararCacheOTTFIX271(MathMax(InpContraDarvasBarrasVisuaisFIX273 + 60, 250));
      PlotarCaixasDarvasFIX273();
   }
   else if(InpContraUsarOTTFIX271)
   {
      PrepararCacheOTTFIX271(MathMax(InpContraOTTBarrasLinhasFIX271 + 40, 200));
      PlotarLinhasOTTFIX271();
   }

   ENUM_LADO_ROBO ladoContra = LADO_NENHUM;
   double rsi = -1.0;
   double agressaoCompra = -1.0;
   double ratioQtd = 0.0;
   double ratioFin = 0.0;
   int confirmacoes = 0;
   bool sinal = AvaliarCandleContraFIX261(shift, true, ladoContra, rsi, agressaoCompra, ratioQtd, ratioFin, confirmacoes);

   if(sinal)
   {
      double precoAbertura = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double maxima = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double minima = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      double fechamento = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      PlotarCandleContraFIX258(tempoBarra, ladoContra, precoAbertura, maxima, minima, fechamento);
      g_ultimoSinalContraHoraFIX310 = tempoBarra;
      g_ultimoSinalContraLadoFIX310 = ladoContra;
      double nivelForteTempoReal = MathMax(MathAbs(InpContraFiboNivelMinimo), MathAbs(InpContraFiboNivelForte));
      if(g_ultimoFiboNivelSinalFIX269 >= nivelForteTempoReal - 0.0001)
         g_sinaisFibo161FIX269++;
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboNivelMinimo) - 0.0001)
         g_sinaisFibo127FIX269++;
      else if(g_ultimoFiboNivelSinalFIX269 >= MathAbs(InpContraFiboPivoMinimoFIX269) - 0.0001)
         g_sinaisFibo078FIX269++;
      if(ladoContra == LADO_COMPRA)
         g_sinaisCompraContraFIX263++;
      else if(ladoContra == LADO_VENDA)
         g_sinaisVendaContraFIX263++;
      g_statusCargaContraFIX263 = "ATUALIZADO EM TEMPO REAL";
      AtualizarDiagnosticoCandlesContraFIX263();
      ChartRedraw(0);

      if(InpGerenciadorOrdensExperts)
      {
         Print("[COPA_AR100][FIX273][CONTRA] ",
               (ladoContra == LADO_COMPRA ? "AZUL | POSSIVEL COMPRA CONTRA" : "AMARELO | POSSIVEL VENDA CONTRA"),
               " | Candle=", TimeToString(tempoBarra, TIME_DATE|TIME_MINUTES),
               " | RSI=", DoubleToString(rsi, 2),
               " | AGR_COMPRA=", DoubleToString(agressaoCompra, 1), "%",
               " | AGR_VENDA=", DoubleToString(100.0 - agressaoCompra, 1), "%",
               " | VOLQx=", DoubleToString(ratioQtd, 2),
               " | VOLFx=", DoubleToString(ratioFin, 2),
               " | CONF=", IntegerToString(confirmacoes), (InpContraUsarDarvasFIX273 ? "/18" : (InpContraUsarOTTFIX271 ? "/20" : (InpContraUsarCruzamentoFIX270 ? "/18" : (InpContraUsarPivoFiboFIX269 ? "/14" : (InpContraModoCirurgico ? "/11" : "/5"))))),
               " | FIBO=", DoubleToString(g_ultimoFiboNivelSinalFIX269, 3),
               " | OTT_SUP=", DoubleToString(g_ultimoOTTSuporteSinalFIX271, _Digits),
               " | DB_TOP=", DoubleToString(g_ultimoDarvasTopoFIX273, _Digits),
               " | DB_BOT=", DoubleToString(g_ultimoDarvasFundoFIX273, _Digits),
               " | OTT_LIN=", DoubleToString(g_ultimoOTTLinhaSinalFIX271, _Digits), " | MODO=", (InpContraUsarDarvasFIX273 ? "SINAL_CONTRA" : (InpContraUsarOTTFIX271 ? "OTT" : (InpContraUsarCruzamentoFIX270 ? "CRUZAMENTO_5X13" : (InpContraUsarPivoFiboFIX269 ? "PIVO_FIBO" : (InpContraModoCirurgico ? "FIBO_BALANCEADO" : "SCORE"))))));
      }
   }
   LimitarCandlesContraFIX258();
}


// ============================================================================
// RESPONSABILIDADE: MERCADO SCORE E CURVA DE VOLUME
// ============================================================================

void AtualizarScoreVolumeCandleFIX335()
{
   int periodo=InpScoreVolumeMediaCandles;
   if(periodo<3)
      periodo=3;
   if(periodo>200)
      periodo=200;
   ENUM_TIMEFRAMES tf=TimeframeFiltroAtualFIX255();
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copiados=CopyRates(_Symbol,tf,0,periodo+2,rates);
   if(copiados<4)
      return;
   datetime candleFechado=rates[1].time;
   if(candleFechado<=0)
      return;
   if(g_mercado.volCandleTempo==candleFechado &&
      g_mercado.volqMediaCandles>0.0 && g_mercado.volfMediaCandles>0.0)
      return;

   double qtdAtual=(rates[1].real_volume>0 ? (double)rates[1].real_volume : (double)rates[1].tick_volume);
   double precoAtual=(rates[1].high+rates[1].low+rates[1].close)/3.0;
   double finAtual=qtdAtual*precoAtual;
   double somaQtd=0.0;
   double somaFin=0.0;
   int usados=0;
   for(int i=2;i<copiados && usados<periodo;i++)
   {
      double qtd=(rates[i].real_volume>0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      if(qtd<=0.0)
         continue;
      double preco=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      somaQtd+=qtd;
      somaFin+=qtd*preco;
      usados++;
   }
   if(usados<3 || somaQtd<=0.0 || somaFin<=0.0)
      return;

   g_mercado.volCandleTempo=candleFechado;
   g_mercado.volqCandleFechado=qtdAtual;
   g_mercado.volfCandleFechado=finAtual;
   g_mercado.volqMediaCandles=somaQtd/(double)usados;
   g_mercado.volfMediaCandles=somaFin/(double)usados;
   g_mercado.volqRatioCandle=RatioSeguro(qtdAtual,g_mercado.volqMediaCandles);
   g_mercado.volfRatioCandle=RatioSeguro(finAtual,g_mercado.volfMediaCandles);
}

void AtualizarMercado()
{
   double adxBuffer[];
   double rsiBuffer[];
   ArraySetAsSeries(adxBuffer, true);
   ArraySetAsSeries(rsiBuffer, true);
   int shiftFiltro = InpUsarCandleFiltroFechado ? 1 : 0;
   if(g_handleADX != INVALID_HANDLE && CopyBuffer(g_handleADX, 0, shiftFiltro, 1, adxBuffer) > 0)
      g_mercado.dx = adxBuffer[0];
   int periodoMediaDX = InpDXMediaPeriodo;
   if(periodoMediaDX < 1)
      periodoMediaDX = InpDXPeriodo;
   if(periodoMediaDX < 1)
      periodoMediaDX = 2;
   double dxMediaBuffer[];
   ArraySetAsSeries(dxMediaBuffer, true);
   double somaDX = 0.0;
   int lidosDX = 0;
   if(g_handleADX != INVALID_HANDLE && CopyBuffer(g_handleADX, 0, shiftFiltro, periodoMediaDX, dxMediaBuffer) > 0)
   {
      int totalDX = ArraySize(dxMediaBuffer);
      for(int iDX = 0; iDX < totalDX; iDX++)
      {
         somaDX += dxMediaBuffer[iDX];
         lidosDX++;
      }
   }
   if(lidosDX > 0)
      g_mercado.dxMedia = somaDX / (double)lidosDX;
   else
      g_mercado.dxMedia = g_mercado.dx;
   double distDX = MathAbs(InpDXDistanciaMedia);
   g_mercado.dxBandaBaixa = g_mercado.dxMedia - distDX;
   g_mercado.dxBandaAlta  = g_mercado.dxMedia + distDX;
   if(g_mercado.dx > g_mercado.dxBandaAlta)
      g_mercado.dxStatus = 2;
   else if(g_mercado.dx < g_mercado.dxBandaBaixa)
      g_mercado.dxStatus = 0;
   else
      g_mercado.dxStatus = 1;
   if(g_handleRSI != INVALID_HANDLE && CopyBuffer(g_handleRSI, 0, shiftFiltro, 1, rsiBuffer) > 0)
      g_mercado.rsi = rsiBuffer[0];
   long tickVol = iVolume(_Symbol, TimeframeFiltroAtualFIX255(), shiftFiltro);
   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shiftFiltro);
   g_mercado.volq = (double)tickVol;
   g_mercado.volf = close0 * (double)tickVol;
   AtualizarCurvaVolumeHoraHora(shiftFiltro);
   datetime agoraAgressao = TimeCurrent();
   if(g_ultimaAtualizacaoAgressao != agoraAgressao)
   {
      g_mercado.agr = CalcularAgressaoCompradoraTicks(256); // -1 bloqueia AGR quando o servidor não entrega negócios direcionais
      g_ultimaAtualizacaoAgressao = agoraAgressao;
   }
   AtualizarHiLo8ESTR();
   g_mercado.scoreFluxo = CalcularScoreFluxo();
   g_mercado.status = ClassificarMercado(g_mercado.scoreFluxo);
   AtualizarScoreVolumeCandleFIX335();
}

datetime InicioDia(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   return StructToTime(dt);
}

datetime MontarHorarioNoDia(datetime dia, string horaMinuto)
{
   string partes[];
   int qtd = StringSplit(horaMinuto, ':', partes);
   MqlDateTime dt;
   TimeToStruct(dia, dt);
   if(qtd >= 2)
   {
      dt.hour = (int)StringToInteger(partes[0]);
      dt.min  = (int)StringToInteger(partes[1]);
   }
   else
   {
      dt.hour = 9;
      dt.min  = 15;
   }
   dt.sec = 0;
   return StructToTime(dt);
}

datetime DiaAnteriorComBarras(datetime diaAtual)
{
   datetime anterior = 0;
   int total = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   int limite = MathMin(total, 20000);
   for(int i = 1; i < limite; i++)
   {
      datetime t = iTime(_Symbol, TimeframeFiltroAtualFIX255(), i);
      if(t <= 0)
         break;
      datetime d = InicioDia(t);
      if(d < diaAtual)
      {
         anterior = d;
         break;
      }
   }
   if(anterior > 0)
      return anterior;
   return (diaAtual - 86400);
}



int SlotHoraHora(datetime t, datetime inicio, int slotMinutos, int maxSlots)
{
   if(slotMinutos <= 0)
      slotMinutos = 60;
   int deltaMin = (int)((t - inicio) / 60);
   if(deltaMin < 0)
      return 0;
   int slot = deltaMin / slotMinutos;
   if(slot < 0)
      slot = 0;
   if(slot >= maxSlots)
      slot = maxSlots - 1;
   return slot;
}

double SomarVolumePeriodo(datetime inicio, datetime fim, bool financeiro)
{
   if(fim <= inicio)
      return 0.0;
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int lidos = CopyRates(_Symbol, TimeframeFiltroAtualFIX255(), inicio, fim, rates);
   if(lidos <= 0)
      return 0.0;
   double soma = 0.0;
   for(int i = 0; i < lidos; i++)
   {
      double vol = (rates[i].real_volume > 0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      if(financeiro)
         soma += vol * rates[i].close;
      else
         soma += vol;
   }
   return soma;
}

double RatioSeguro(double atual, double base)
{
   if(base <= 0.0)
      return 0.0;
   return atual / base;
}

double ExtrairMinutosCampo(string cfg, string chave, string padrao)
{
   int m = ExtrairInteiro(GetCampo(cfg, chave, padrao));
   if(m <= 0)
      m = ExtrairInteiro(padrao);
   if(m <= 0)
      m = 5;
   return (double)m;
}

int ClassificarFarolVolume(double ratioHora, double ratio15, double ratio5, double forteHora, double extHora, double forteCurto, double extCurto)
{
   if(ratioHora >= extHora && (ratio5 >= extCurto || ratio15 >= extCurto))
      return 4;
   if(ratioHora >= extHora || ratio5 >= extCurto || ratio15 >= extCurto)
      return 3;
   if(ratioHora >= forteHora || ratio15 >= forteCurto || ratio5 >= forteCurto)
      return 2;
   if(ratioHora >= 0.90)
      return 1;
   return 0;
}

void ZerarVolumeCurvaComoAprovado()
{
   g_mercado.volSlot = -1;
   g_mercado.volqBaseHora = 0.0;
   g_mercado.volfBaseHora = 0.0;
   g_mercado.volqAtualHora = g_mercado.volq;
   g_mercado.volfAtualHora = g_mercado.volf;
   g_mercado.volqProjetadoHora = g_mercado.volq;
   g_mercado.volfProjetadoHora = g_mercado.volf;
   g_mercado.volqRatioHora = 0.0;
   g_mercado.volfRatioHora = 0.0;
   g_mercado.volqMinDinamico = 0.0;
   g_mercado.volfMinDinamico = 0.0;
   g_mercado.volqFatorDia = 1.0;
   g_mercado.volfFatorDia = 1.0;
   g_mercado.volqBaseAjustadaHora = 0.0;
   g_mercado.volfBaseAjustadaHora = 0.0;
   g_mercado.volqRatioAjustadoHora = 0.0;
   g_mercado.volfRatioAjustadoHora = 0.0;
   g_mercado.volqRatio5m = 0.0;
   g_mercado.volfRatio5m = 0.0;
   g_mercado.volqRatio15m = 0.0;
   g_mercado.volfRatio15m = 0.0;
   g_mercado.volRatioDecisao = 0.0;
   g_mercado.volFarol = 1;
   g_mercado.volqCurvaOK = true;
   g_mercado.volfCurvaOK = true;
   g_mercado.volumeCurvaOK = true;
}

void AtualizarCurvaVolumeHoraHora(int shiftFiltro)
{
   string cfg = InpVolumeCurvaHora;
   string cfgCurto = InpVolumeCurto;
   if(!IsOn(GetCampo(cfg, "", "ON")) || !IsOn(GetCampo(cfg, "ATIVO", "ON")))
   {
      ZerarVolumeCurvaComoAprovado();
      return;
   }
   string faixa = GetCampo(cfg, "HOR", "09:15-17:15");
   string p[];
   StringSplit(faixa, '-', p);
   string hIni = (ArraySize(p) >= 1 ? p[0] : "09:15");
   string hFim = (ArraySize(p) >= 2 ? p[1] : "17:15");
   int slotMin = ExtrairInteiro(GetCampo(cfg, "SLOT", "60"));
   if(slotMin <= 0)
      slotMin = 60;
   bool ajustarDia = IsOn(GetCampo(cfg, "AJUSTAR_DIA", "ON"));
   bool usarQ = IsOn(GetCampo(cfg, "VOLQ", GetCampo(cfg, "QTD", "ON")));
   bool usarF = IsOn(GetCampo(cfg, "VOLF", GetCampo(cfg, "FIN", "ON")));
   double multForteHora = ExtrairNumero(GetCampo(cfg, "FORTE", GetCampo(cfg, "MULT_FORTE", "1.30")));
   double multExtHora   = ExtrairNumero(GetCampo(cfg, "EXT", GetCampo(cfg, "MULT_EXT", "1.80")));
   if(multForteHora <= 0.0) multForteHora = 1.30;
   if(multExtHora <= multForteHora) multExtHora = MathMax(1.80, multForteHora + 0.30);
   double multForteCurto = ExtrairNumero(GetCampo(cfgCurto, "FORTE", "1.50"));
   double multExtCurto   = ExtrairNumero(GetCampo(cfgCurto, "EXT", "2.00"));
   if(multForteCurto <= 0.0) multForteCurto = 1.50;
   if(multExtCurto <= multForteCurto) multExtCurto = MathMax(2.00, multForteCurto + 0.30);
   int curto1 = (int)ExtrairMinutosCampo(cfgCurto, "J1", "5m");
   int curto2 = (int)ExtrairMinutosCampo(cfgCurto, "J2", "15m");
   if(curto1 <= 0) curto1 = 5;
   if(curto2 <= 0) curto2 = 15;
   datetime tempoBarra = iTime(_Symbol, TimeframeFiltroAtualFIX255(), shiftFiltro);
   if(tempoBarra <= 0)
      tempoBarra = TimeCurrent();
   int segTF = PeriodSeconds(TimeframeFiltroAtualFIX255());
   if(segTF <= 0)
      segTF = 60;
   datetime diaAtual = InicioDia(tempoBarra);
   datetime inicioAtual = MontarHorarioNoDia(diaAtual, hIni);
   datetime fimAtual = MontarHorarioNoDia(diaAtual, hFim);
   if(fimAtual <= inicioAtual)
      fimAtual = inicioAtual + (8 * 60 * 60);
   int maxSlots = (int)MathCeil((double)(fimAtual - inicioAtual) / (double)(slotMin * 60));
   if(maxSlots <= 0)
      maxSlots = 1;
   int slot = SlotHoraHora(tempoBarra, inicioAtual, slotMin, maxSlots);
   datetime slotIniAtual = inicioAtual + (slot * slotMin * 60);
   datetime slotFimAtual = slotIniAtual + (slotMin * 60);
   if(slotFimAtual > fimAtual)
      slotFimAtual = fimAtual;
   datetime fimParcialAtual = tempoBarra + segTF;
   if(fimParcialAtual > slotFimAtual)
      fimParcialAtual = slotFimAtual;
   if(fimParcialAtual <= slotIniAtual)
      fimParcialAtual = slotIniAtual + segTF;
   datetime diaBase = DiaAnteriorComBarras(diaAtual);
   datetime inicioBase = MontarHorarioNoDia(diaBase, hIni);
   datetime slotIniBase = inicioBase + (slot * slotMin * 60);
   datetime slotFimBase = slotIniBase + (slotMin * 60);
   double baseQ = SomarVolumePeriodo(slotIniBase, slotFimBase, false);
   double baseF = SomarVolumePeriodo(slotIniBase, slotFimBase, true);
   double atualQ = SomarVolumePeriodo(slotIniAtual, fimParcialAtual, false);
   double atualF = SomarVolumePeriodo(slotIniAtual, fimParcialAtual, true);
   double minutosPassados = (double)(fimParcialAtual - slotIniAtual) / 60.0;
   if(minutosPassados < 1.0) minutosPassados = 1.0;
   if(minutosPassados > (double)slotMin) minutosPassados = (double)slotMin;
   double fatorProjecao = (double)slotMin / minutosPassados;
   double projQ = atualQ * fatorProjecao;
   double projF = atualF * fatorProjecao;
   datetime fimAcumAtual = fimParcialAtual;
   datetime fimAcumBase = inicioBase + (fimAcumAtual - inicioAtual);
   if(fimAcumBase < inicioBase) fimAcumBase = inicioBase;
   double acumHojeQ = SomarVolumePeriodo(inicioAtual, fimAcumAtual, false);
   double acumHojeF = SomarVolumePeriodo(inicioAtual, fimAcumAtual, true);
   double acumBaseQ = SomarVolumePeriodo(inicioBase, fimAcumBase, false);
   double acumBaseF = SomarVolumePeriodo(inicioBase, fimAcumBase, true);
   double fatorDiaQ = (ajustarDia && acumBaseQ > 0.0 ? acumHojeQ / acumBaseQ : 1.0);
   double fatorDiaF = (ajustarDia && acumBaseF > 0.0 ? acumHojeF / acumBaseF : 1.0);
   if(fatorDiaQ < 0.50) fatorDiaQ = 0.50;
   if(fatorDiaQ > 2.50) fatorDiaQ = 2.50;
   if(fatorDiaF < 0.50) fatorDiaF = 0.50;
   if(fatorDiaF > 2.50) fatorDiaF = 2.50;
   double baseAjustadaQ = baseQ * fatorDiaQ;
   double baseAjustadaF = baseF * fatorDiaF;
   double ratioHoraQ = RatioSeguro(projQ, baseAjustadaQ);
   double ratioHoraF = RatioSeguro(projF, baseAjustadaF);
   datetime fimCurtoAtual = fimParcialAtual;
   datetime ini5Atual  = fimCurtoAtual - (curto1 * 60);
   datetime ini15Atual = fimCurtoAtual - (curto2 * 60);
   if(ini5Atual < inicioAtual) ini5Atual = inicioAtual;
   if(ini15Atual < inicioAtual) ini15Atual = inicioAtual;
   datetime fimCurtoBase = inicioBase + (fimCurtoAtual - inicioAtual);
   datetime ini5Base  = fimCurtoBase - (curto1 * 60);
   datetime ini15Base = fimCurtoBase - (curto2 * 60);
   if(ini5Base < inicioBase) ini5Base = inicioBase;
   if(ini15Base < inicioBase) ini15Base = inicioBase;
   double q5Atual  = SomarVolumePeriodo(ini5Atual, fimCurtoAtual, false);
   double f5Atual  = SomarVolumePeriodo(ini5Atual, fimCurtoAtual, true);
   double q15Atual = SomarVolumePeriodo(ini15Atual, fimCurtoAtual, false);
   double f15Atual = SomarVolumePeriodo(ini15Atual, fimCurtoAtual, true);
   double q5Base  = SomarVolumePeriodo(ini5Base, fimCurtoBase, false) * fatorDiaQ;
   double f5Base  = SomarVolumePeriodo(ini5Base, fimCurtoBase, true) * fatorDiaF;
   double q15Base = SomarVolumePeriodo(ini15Base, fimCurtoBase, false) * fatorDiaQ;
   double f15Base = SomarVolumePeriodo(ini15Base, fimCurtoBase, true) * fatorDiaF;
   double ratio5Q  = RatioSeguro(q5Atual, q5Base);
   double ratio5F  = RatioSeguro(f5Atual, f5Base);
   double ratio15Q = RatioSeguro(q15Atual, q15Base);
   double ratio15F = RatioSeguro(f15Atual, f15Base);
   double ratioHoraDecisao = 0.0;
   if(usarQ && usarF)
      ratioHoraDecisao = MathMin(ratioHoraQ, ratioHoraF);
   else if(usarQ)
      ratioHoraDecisao = ratioHoraQ;
   else if(usarF)
      ratioHoraDecisao = ratioHoraF;
   else
      ratioHoraDecisao = MathMin(ratioHoraQ, ratioHoraF);
   double ratio5Decisao = MathMin(ratio5Q, ratio5F);
   double ratio15Decisao = MathMin(ratio15Q, ratio15F);
   int farol = ClassificarFarolVolume(ratioHoraDecisao, ratio15Decisao, ratio5Decisao,
                                      multForteHora, multExtHora, multForteCurto, multExtCurto);
   g_mercado.volSlot = slot;
   g_mercado.volqBaseHora = baseQ;
   g_mercado.volfBaseHora = baseF;
   g_mercado.volqAtualHora = atualQ;
   g_mercado.volfAtualHora = atualF;
   g_mercado.volqProjetadoHora = (projQ > 0.0 ? projQ : g_mercado.volq);
   g_mercado.volfProjetadoHora = (projF > 0.0 ? projF : g_mercado.volf);
   g_mercado.volqFatorDia = fatorDiaQ;
   g_mercado.volfFatorDia = fatorDiaF;
   g_mercado.volqBaseAjustadaHora = baseAjustadaQ;
   g_mercado.volfBaseAjustadaHora = baseAjustadaF;
   g_mercado.volqRatioHora = (baseQ > 0.0 ? g_mercado.volqProjetadoHora / baseQ : 0.0);
   g_mercado.volfRatioHora = (baseF > 0.0 ? g_mercado.volfProjetadoHora / baseF : 0.0);
   g_mercado.volqRatioAjustadoHora = ratioHoraQ;
   g_mercado.volfRatioAjustadoHora = ratioHoraF;
   g_mercado.volqRatio5m = ratio5Q;
   g_mercado.volfRatio5m = ratio5F;
   g_mercado.volqRatio15m = ratio15Q;
   g_mercado.volfRatio15m = ratio15F;
   g_mercado.volRatioDecisao = ratioHoraDecisao;
   g_mercado.volFarol = farol;
   g_mercado.volqMinDinamico = (usarQ ? baseAjustadaQ * multForteHora : 0.0);
   g_mercado.volfMinDinamico = (usarF ? baseAjustadaF * multForteHora : 0.0);
   g_mercado.volqCurvaOK = (!usarQ || baseAjustadaQ <= 0.0 || g_mercado.volqProjetadoHora >= g_mercado.volqMinDinamico);
   g_mercado.volfCurvaOK = (!usarF || baseAjustadaF <= 0.0 || g_mercado.volfProjetadoHora >= g_mercado.volfMinDinamico);
   g_mercado.volumeCurvaOK = (g_mercado.volqCurvaOK && g_mercado.volfCurvaOK);
}

double LimiteVolumeQtdDinamico(RegraFiltros &f)
{
   if(g_mercado.volqMinDinamico > 0.0)
      return MathMax(MathAbs(f.volqMin), g_mercado.volqMinDinamico);
   return MathAbs(f.volqMin);
}

double LimiteVolumeFinDinamico(RegraFiltros &f)
{
   if(g_mercado.volfMinDinamico > 0.0)
      return MathMax(MathAbs(f.volfMin), g_mercado.volfMinDinamico);
   return MathAbs(f.volfMin);
}


// ============================================================================
// RESPONSABILIDADE: DX HILO STR E COMPARATIVOS VISUAIS
// ============================================================================

void LimparVisualHilo14STR4FIX418()
{
   const string prefixo="COPA_FIX418_HILO_STR_";
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string nome=ObjectName(0,i);
      if(StringFind(nome,prefixo)==0)
         ObjectDelete(0,nome);
   }
}

void CriarSegmentoHiloFIX418(string nome,datetime t1,double p1,datetime t2,double p2,color cor)
{
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_TREND,0,t1,p1,t2,p2);
   else
   {
      ObjectMove(0,nome,0,t1,p1);
      ObjectMove(0,nome,1,t2,p2);
   }
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,nome,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,nome,OBJPROP_BACK,true);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
}

void CriarSetaSTRFIX418(string nome,datetime tempo,double preco,bool compra)
{
   ENUM_OBJECT tipo=(compra ? OBJ_ARROW_UP : OBJ_ARROW_DOWN);
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,tipo,0,tempo,preco);
   else
      ObjectMove(0,nome,0,tempo,preco);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,compra ? clrDeepSkyBlue : clrTomato);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,5);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,nome,OBJPROP_BACK,false);
}

// ============================================================================
// FIX430 - DX MASTER SUPER CONFIRMADO (VISUAL)
// ============================================================================
int g_dxMasterCompraFIX430=0;
int g_dxMasterVendaFIX430=0;

bool CalcularPOCGenericoFIX430(const ENUM_TIMEFRAMES tf,const int shift,const int periodo,const int faixaPts,double &poc)
{
   int n=MathMax(10,periodo);
   MqlRates rates[]; ArraySetAsSeries(rates,true);
   int cop=CopyRates(_Symbol,tf,shift,n,rates);
   if(cop<n) return false;
   double passo=MathMax(1,faixaPts)*_Point;
   double menor=rates[0].low,maior=rates[0].high;
   for(int i=1;i<n;i++){ menor=MathMin(menor,rates[i].low); maior=MathMax(maior,rates[i].high); }
   int bins=(int)MathFloor((maior-menor)/passo)+1;
   bins=MathMax(1,MathMin(5000,bins));
   double vols[]; ArrayResize(vols,bins); ArrayInitialize(vols,0.0);
   for(int i=0;i<n;i++)
   {
      double preco=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      int idx=(int)MathFloor((preco-menor)/passo);
      idx=MathMax(0,MathMin(bins-1,idx));
      double v=(rates[i].real_volume>0?(double)rates[i].real_volume:(double)rates[i].tick_volume);
      vols[idx]+=v;
   }
   int melhor=0;
   for(int i=1;i<bins;i++) if(vols[i]>vols[melhor]) melhor=i;
   poc=NormalizeDouble(menor+(melhor+0.5)*passo,_Digits);
   return true;
}

bool FundoTetoLiberadoFIX430(const ENUM_TIMEFRAMES tf,const int shift,const bool compra,const double close)
{
   if(!InpDXMasterUsarFundoTetoFIX430) return true;
   int n=MathMax(10,InpDXMasterPeriodoFundoTetoFIX430);
   MqlRates r[]; ArraySetAsSeries(r,true);
   int cop=CopyRates(_Symbol,tf,shift+1,n,r);
   if(cop<n) return false;
   double teto=r[0].high,fundo=r[0].low;
   for(int i=1;i<n;i++){ teto=MathMax(teto,r[i].high); fundo=MathMin(fundo,r[i].low); }
   double minPts=MathMax(0.0,InpDXMasterDistanciaTetoFundoPontosFIX430);
   if(compra) return (close>teto || (teto-close)/_Point>=minPts);
   return (close<fundo || (close-fundo)/_Point>=minPts);
}

void CriarSetaDXMasterFIX430(const string nome,const datetime tempo,const double preco,const bool compra,const int extras,const double poc)
{
   if(ObjectFind(0,nome)<0) ObjectCreate(0,nome,OBJ_ARROW,0,tempo,preco);
   else ObjectMove(0,nome,0,tempo,preco);
   ObjectSetInteger(0,nome,OBJPROP_ARROWCODE,compra?241:242);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,4);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
   ObjectSetString(0,nome,OBJPROP_TOOLTIP,StringFormat("DX MASTER %s | EXTRAS=%d | POC=%.2f",compra?"COMPRA":"VENDA",extras,poc));
}

void LimparDXMasterFIX430()
{
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string n=ObjectName(0,i);
      if(StringFind(n,"COPA_DX_MASTER_FIX430_")==0) ObjectDelete(0,n);
   }
}

void AtualizarPainelDXMasterFIX430()
{
   string n="COPA_DX_MASTER_FIX430_PAINEL";
   if(!InpDXMasterAtivoFIX430){ ObjectDelete(0,n); return; }
   if(ObjectFind(0,n)<0)
   {
      ObjectCreate(0,n,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,15);
      ObjectSetInteger(0,n,OBJPROP_YDISTANCE,55);
      ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   }
   ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("DX MASTER | MELHORES=%d | C=%d | V=%d | POC+CANAL | EXTRAS=%d",g_dxMasterCompraFIX430+g_dxMasterVendaFIX430,g_dxMasterCompraFIX430,g_dxMasterVendaFIX430,InpDXMasterMinimoExtrasFIX430));
   ObjectSetInteger(0,n,OBJPROP_COLOR,clrYellow);
}

void LimparComparativoDXCanaisFIX429()
{
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string nome=ObjectName(0,i);
      if(StringFind(nome,"COPA_COMP_FIX429_")==0)
         ObjectDelete(0,nome);
   }
}

void CriarMarcadorConcordanciaFIX429(const string nome,const datetime tempo,const double preco,const bool compra)
{
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_ARROW,0,tempo,preco);
   else
      ObjectMove(0,nome,0,tempo,preco);
   ObjectSetInteger(0,nome,OBJPROP_ARROWCODE,159);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,3);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
   ObjectSetString(0,nome,OBJPROP_TOOLTIP,compra?"DX + CANAIS = COMPRA":"DX + CANAIS = VENDA");
}

void AtualizarComparativoDXCanaisFIX429()
{
   string painel="COPA_COMP_FIX429_PAINEL";
   if(!InpComparativoDXCanaisAtivo)
   {
      LimparComparativoDXCanaisFIX429();
      return;
   }

   LimparComparativoDXCanaisFIX429();
   datetime dxBuy[],dxSell[],canBuy[],canSell[];
   ArrayResize(dxBuy,0); ArrayResize(dxSell,0); ArrayResize(canBuy,0); ArrayResize(canSell,0);

   int totalObj=ObjectsTotal(0);
   for(int i=0;i<totalObj;i++)
   {
      string nome=ObjectName(0,i);
      datetime t=(datetime)ObjectGetInteger(0,nome,OBJPROP_TIME,0);
      if(t<=0) continue;
      if(StringFind(nome,"COPA_FIX426_DX_CIRURGICO_")==0)
      {
         if(StringFind(nome,"DX_BUY")>0){int n=ArraySize(dxBuy);ArrayResize(dxBuy,n+1);dxBuy[n]=t;}
         else if(StringFind(nome,"DX_SELL")>0){int n=ArraySize(dxSell);ArrayResize(dxSell,n+1);dxSell[n]=t;}
      }
      else if(StringFind(nome,"COPA_CANAIS_VIS_FIX427_BUY_")==0)
      {int n=ArraySize(canBuy);ArrayResize(canBuy,n+1);canBuy[n]=t;}
      else if(StringFind(nome,"COPA_CANAIS_VIS_FIX427_SELL_")==0)
      {int n=ArraySize(canSell);ArrayResize(canSell,n+1);canSell[n]=t;}
   }

   g_comparativoDXCompra=ArraySize(dxBuy);
   g_comparativoDXVenda=ArraySize(dxSell);
   g_comparativoCanaisCompra=ArraySize(canBuy);
   g_comparativoCanaisVenda=ArraySize(canSell);
   g_comparativoConcordaCompra=0;
   g_comparativoConcordaVenda=0;

   int segundosTF=PeriodSeconds(InpTimeframeCanais);
   if(segundosTF<=0) segundosTF=60;
   int tolerancia=MathMax(0,InpComparativoToleranciaCandles)*segundosTF;

   for(int i=0;i<ArraySize(dxBuy);i++)
   {
      bool encontrou=false;
      for(int j=0;j<ArraySize(canBuy);j++)
         if((int)MathAbs((double)(dxBuy[i]-canBuy[j]))<=tolerancia){encontrou=true;break;}
      if(encontrou)
      {
         g_comparativoConcordaCompra++;
         if(InpComparativoDestacarConcordancias)
         {
            int sh=iBarShift(_Symbol,InpTimeframeCanais,dxBuy[i],false);
            double p=iLow(_Symbol,InpTimeframeCanais,sh)-InpCanaisVisualDistanciaSetaPontos*2*_Point;
            CriarMarcadorConcordanciaFIX429("COPA_COMP_FIX429_BUY_"+IntegerToString((int)dxBuy[i]),dxBuy[i],p,true);
         }
      }
   }
   for(int i=0;i<ArraySize(dxSell);i++)
   {
      bool encontrou=false;
      for(int j=0;j<ArraySize(canSell);j++)
         if((int)MathAbs((double)(dxSell[i]-canSell[j]))<=tolerancia){encontrou=true;break;}
      if(encontrou)
      {
         g_comparativoConcordaVenda++;
         if(InpComparativoDestacarConcordancias)
         {
            int sh=iBarShift(_Symbol,InpTimeframeCanais,dxSell[i],false);
            double p=iHigh(_Symbol,InpTimeframeCanais,sh)+InpCanaisVisualDistanciaSetaPontos*2*_Point;
            CriarMarcadorConcordanciaFIX429("COPA_COMP_FIX429_SELL_"+IntegerToString((int)dxSell[i]),dxSell[i],p,false);
         }
      }
   }

   int dxTotal=g_comparativoDXCompra+g_comparativoDXVenda;
   int canTotal=g_comparativoCanaisCompra+g_comparativoCanaisVenda;
   int confTotal=g_comparativoConcordaCompra+g_comparativoConcordaVenda;
   double pct=(dxTotal>0 ? 100.0*confTotal/dxTotal : 0.0);
   string texto=StringFormat("COMPARATIVO | DX=%d (C%d/V%d) | CANAIS=%d (C%d/V%d) | JUNTOS=%d | %.0f%% DO DX",
                            dxTotal,g_comparativoDXCompra,g_comparativoDXVenda,
                            canTotal,g_comparativoCanaisCompra,g_comparativoCanaisVenda,
                            confTotal,pct);
   if(ObjectFind(0,painel)<0)
   {
      ObjectCreate(0,painel,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,painel,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,painel,OBJPROP_XDISTANCE,15);
      ObjectSetInteger(0,painel,OBJPROP_YDISTANCE,35);
      ObjectSetInteger(0,painel,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,painel,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,painel,OBJPROP_HIDDEN,true);
   }
   ObjectSetString(0,painel,OBJPROP_TEXT,texto);
   ObjectSetInteger(0,painel,OBJPROP_COLOR,clrYellow);
   Print("[COPA_AR100][FIX429][COMPARATIVO] ",texto);
}

void AtualizarVisualHilo14STR4FIX418(bool forcar=false)
{
   static datetime ultimaBarra=0;
   if(!InpVisualHilo14STR4AtivoFIX418)
   {
      LimparVisualHilo14STR4FIX418();
      return;
   }

   ENUM_TIMEFRAMES tf=InpVisualHilo14STR4TempoFIX418;
   datetime barraAtual=iTime(_Symbol,tf,0);
   if(!forcar && barraAtual>0 && barraAtual==ultimaBarra)
      return;
   ultimaBarra=barraAtual;

   int periodoHilo=MathMax(2,InpVisualHiloPeriodoFIX418);
   int periodoSTR=MathMax(2,InpVisualSTRPeriodoFIX418);
   int periodoMA=MathMax(2,InpDXMediaPeriodoFIX411);
   int amostraDX=MathMax(5,InpDXAmostraCandlesFIX411);
   int diasHistoricos=MathMax(1,MathMin(30,InpVisualDiasHistoricosFIX422));
   datetime inicioHistorico=TimeCurrent()-(datetime)(diasHistoricos*86400);
   int shiftInicio=iBarShift(_Symbol,tf,inicioHistorico,false);
   int qtd=(shiftInicio>0 ? shiftInicio : InpVisualHiloSTRBarrasFIX418);
   qtd=MathMax(20,MathMin(5000,qtd));
   int margemDados=periodoMA+amostraDX+periodoHilo+periodoSTR+20;
   int barras=Bars(_Symbol,tf);
   int maxDisponivel=MathMax(20,barras-margemDados-2);
   if(qtd>maxDisponivel) qtd=maxDisponivel;
   int necessario=qtd+margemDados;
   if(barras<necessario)
   {
      PrintFormat("[COPA_AR100][FIX422][VISUAL_AGUARDA] TF=%s | BARRAS=%d | NECESSARIO=%d",EnumToString(tf),barras,necessario);
      return;
   }

   int hMA=iMA(_Symbol,tf,periodoMA,0,InpDXMediaMetodoFIX411,InpDXMediaPrecoFIX411);
   int hRSI=iRSI(_Symbol,tf,14,PRICE_CLOSE);
   int hBoll=iBands(_Symbol,tf,MathMax(2,InpDXMasterPeriodoBollFIX430),0,InpDXMasterDesvioBollFIX430,PRICE_CLOSE);
   int hKeltEMA=iMA(_Symbol,tf,MathMax(2,InpDXMasterPeriodoEMAFIX430),0,MODE_EMA,PRICE_CLOSE);
   int hKeltATR=iATR(_Symbol,tf,MathMax(1,InpDXMasterPeriodoATRFIX430));
   if(hMA==INVALID_HANDLE || hRSI==INVALID_HANDLE || hBoll==INVALID_HANDLE || hKeltEMA==INVALID_HANDLE || hKeltATR==INVALID_HANDLE)
   {
      if(hMA!=INVALID_HANDLE) IndicatorRelease(hMA);
      if(hRSI!=INVALID_HANDLE) IndicatorRelease(hRSI);
      if(hBoll!=INVALID_HANDLE) IndicatorRelease(hBoll);
      if(hKeltEMA!=INVALID_HANDLE) IndicatorRelease(hKeltEMA);
      if(hKeltATR!=INVALID_HANDLE) IndicatorRelease(hKeltATR);
      Print("[COPA_AR100][FIX430][VISUAL_ERRO] Falha ao criar indicadores do DX Master");
      return;
   }

   int copiar=qtd+margemDados+5;
   double ma[],rsi[],bollSup[],bollInf[],keltEMA[],keltATR[];
   ArraySetAsSeries(ma,true); ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(bollSup,true); ArraySetAsSeries(bollInf,true);
   ArraySetAsSeries(keltEMA,true); ArraySetAsSeries(keltATR,true);
   int copMA=CopyBuffer(hMA,0,0,copiar,ma);
   int copRSI=CopyBuffer(hRSI,0,0,copiar,rsi);
   int copBS=CopyBuffer(hBoll,1,0,copiar,bollSup);
   int copBI=CopyBuffer(hBoll,2,0,copiar,bollInf);
   int copKE=CopyBuffer(hKeltEMA,0,0,copiar,keltEMA);
   int copKA=CopyBuffer(hKeltATR,0,0,copiar,keltATR);
   IndicatorRelease(hMA); IndicatorRelease(hRSI); IndicatorRelease(hBoll); IndicatorRelease(hKeltEMA); IndicatorRelease(hKeltATR);
   if(copMA<necessario || copRSI<necessario || copBS<necessario || copBI<necessario || copKE<necessario || copKA<necessario)
   {
      PrintFormat("[COPA_AR100][FIX430][VISUAL_ERRO] Dados insuficientes MA=%d RSI=%d BS=%d BI=%d KE=%d KA=%d NEC=%d",copMA,copRSI,copBS,copBI,copKE,copKA,necessario);
      return;
   }

   LimparVisualHilo14STR4FIX418();
   LimparDXMasterFIX430();
   g_dxMasterCompraFIX430=0;
   g_dxMasterVendaFIX430=0;

   bool toqueCompra=false,toqueVenda=false;
   bool retornoCompraAtivo=false,retornoVendaAtivo=false;
   datetime horaToqueCompra=0,horaToqueVenda=0;
   int candlesConfCompra=0,candlesConfVenda=0;
   int totalCompra=0,totalVenda=0;
   int candlesDesdeCompra=100000,candlesDesdeVenda=100000;

   // Percorre do candle mais antigo para o mais recente e reproduz a sequencia:
   // toque DX -> perda da forca contraria -> retorno a media -> HILO14+STR14 -> seta.
   for(int shift=qtd;shift>=1;shift--)
   {
      candlesDesdeCompra++;
      candlesDesdeVenda++;
      double somaDist=0.0,maxDist=0.0;
      int usados=0;
      for(int k=1;k<=amostraDX;k++)
      {
         int sh=shift+k;
         double closeHist=iClose(_Symbol,tf,sh);
         if(closeHist<=0.0 || ma[sh]<=0.0) continue;
         double dist=MathAbs(closeHist-ma[sh])/_Point;
         somaDist+=dist;
         if(dist>maxDist) maxDist=dist;
         usados++;
      }
      if(usados<MathMin(amostraDX,10)) continue;
      double mediaDist=somaDist/(double)usados;

      double somaHigh=0.0,somaLow=0.0;
      for(int j=1;j<=periodoHilo;j++)
      {
         somaHigh+=iHigh(_Symbol,tf,shift+j);
         somaLow +=iLow(_Symbol,tf,shift+j);
      }
      double hiloHigh=somaHigh/(double)periodoHilo;
      double hiloLow =somaLow /(double)periodoHilo;

      double o=iOpen(_Symbol,tf,shift);
      double h=iHigh(_Symbol,tf,shift);
      double l=iLow(_Symbol,tf,shift);
      double c=iClose(_Symbol,tf,shift);
      double cRef=iClose(_Symbol,tf,shift+periodoSTR);
      double range=h-l;
      double corpo=MathAbs(c-o);
      double proporcao=(range>0.0 ? corpo/range : 0.0);
      bool forte=(proporcao>=MathMax(0.05,MathMin(1.0,InpVisualSTRCorpoMinimoFIX418)));
      bool hiloCompra=(c>hiloHigh);
      bool hiloVenda =(c<hiloLow);
      bool strCompra =(forte && c>o && c>cRef);
      bool strVenda  =(forte && c<o && c<cRef);

      // Forca historica aproximando os mesmos 6 componentes do DX operacional.
      double peso=100.0/6.0;
      double fc=0.0,fv=0.0;
      if(hiloCompra) fc+=peso;
      if(hiloVenda) fv+=peso;
      if(strCompra) fc+=peso;
      if(strVenda) fv+=peso;

      long volAtual=(long)iVolume(_Symbol,tf,shift);
      double somaVol=0.0;
      for(int v=1;v<=amostraDX;v++) somaVol+=(double)iVolume(_Symbol,tf,shift+v);
      double mediaVol=(amostraDX>0 ? somaVol/(double)amostraDX : 0.0);
      bool volumeForte=(mediaVol>0.0 && (double)volAtual>=mediaVol);
      if(volumeForte)
      {
         if(c>o){fc+=peso;fc+=peso;} // quantidade + financeiro no mesmo sentido
         else if(c<o){fv+=peso;fv+=peso;}
      }
      if(rsi[shift]>=70.0) fc+=peso;
      if(rsi[shift]<=30.0) fv+=peso;
      int shIncl=shift+MathMin(amostraDX,3);
      double inclinacao=(ma[shift]-ma[shIncl])/_Point;
      if(inclinacao>0.0) fc+=peso;
      if(inclinacao<0.0) fv+=peso;
      fc=MathMin(100.0,fc);
      fv=MathMin(100.0,fv);
      double forcaMax=MathMax(fc,fv);

      double pctMin=MathMax(0.0,MathMin(100.0,InpDXPercentualExtremoMinFIX411));
      double pctMax=MathMax(pctMin,MathMin(150.0,InpDXPercentualExtremoMaxFIX411));
      double pct=pctMin+(pctMax-pctMin)*(forcaMax/100.0);
      double distanciaDX=MathMax(mediaDist,maxDist*(pct/100.0));
      double bandaSup=ma[shift]+distanciaDX*_Point;
      double bandaInf=ma[shift]-distanciaDX*_Point;
      datetime tempo=iTime(_Symbol,tf,shift);

      double distanciaExtremoCompra=(ma[shift]-l)/_Point;
      double distanciaExtremoVenda =(h-ma[shift])/_Point;
      double distanciaMinimaArmar=MathMax(0.0,InpDXDistanciaMinimaArmarFIX426);
      if(l<=bandaInf && distanciaExtremoCompra>=distanciaMinimaArmar)
      {
         toqueCompra=true;
         horaToqueCompra=tempo;
         retornoCompraAtivo=false;
         candlesConfCompra=0;
      }
      if(h>=bandaSup && distanciaExtremoVenda>=distanciaMinimaArmar)
      {
         toqueVenda=true;
         horaToqueVenda=tempo;
         retornoVendaAtivo=false;
         candlesConfVenda=0;
      }

      bool candleDepoisCompra=(toqueCompra && tempo>horaToqueCompra);
      bool candleDepoisVenda=(toqueVenda && tempo>horaToqueVenda);
      double toleranciaMedia=MathMax(0.0,InpDXToleranciaMediaPontosFIX425)*_Point;
      bool retornoCompra=(h>=ma[shift]-toleranciaMedia && c>=ma[shift]-toleranciaMedia);
      bool retornoVenda =(l<=ma[shift]+toleranciaMedia && c<=ma[shift]+toleranciaMedia);

      int limiteConfirmacao=MathMax(1,MathMin(10,InpDXCandlesConfirmacaoFIX425));
      if(candleDepoisCompra && fv<=InpDXForcaLiberacaoFIX411 && retornoCompra && !retornoCompraAtivo)
      {
         retornoCompraAtivo=true;
         candlesConfCompra=0;
      }
      if(candleDepoisVenda && fc<=InpDXForcaLiberacaoFIX411 && retornoVenda && !retornoVendaAtivo)
      {
         retornoVendaAtivo=true;
         candlesConfVenda=0;
      }

      bool candleDirecionalCompra=(forte && c>o);
      bool candleDirecionalVenda =(forte && c<o);
      bool confirmaCompra=false;
      bool confirmaVenda=false;
      if(InpDXModoCalibracaoFIX425==DX_RIGIDO_FIX425)
      {
         confirmaCompra=(hiloCompra && strCompra);
         confirmaVenda =(hiloVenda && strVenda);
      }
      else if(InpDXModoCalibracaoFIX425==DX_AGRESSIVO_FIX425)
      {
         confirmaCompra=(hiloCompra || strCompra || candleDirecionalCompra);
         confirmaVenda =(hiloVenda || strVenda || candleDirecionalVenda);
      }
      else
      {
         confirmaCompra=(hiloCompra || strCompra);
         confirmaVenda =(hiloVenda || strVenda);
      }

      double maximaAnterior=iHigh(_Symbol,tf,shift+1);
      double minimaAnterior=iLow(_Symbol,tf,shift+1);
      bool rompeAnteriorCompra=(!InpDXExigirRompimentoCandleAnteriorFIX426 || c>maximaAnterior);
      bool rompeAnteriorVenda =(!InpDXExigirRompimentoCandleAnteriorFIX426 || c<minimaAnterior);
      bool direcionalCompra=(!InpDXExigirCandleDirecionalFIX426 || c>o);
      bool direcionalVenda =(!InpDXExigirCandleDirecionalFIX426 || c<o);
      int bloqueioMesmoLado=MathMax(0,InpDXBloqueioMesmoLadoCandlesFIX426);
      bool liberadoRepeticaoCompra=(candlesDesdeCompra>=bloqueioMesmoLado);
      bool liberadoRepeticaoVenda =(candlesDesdeVenda>=bloqueioMesmoLado);

      bool janelaCompra=(retornoCompraAtivo && candlesConfCompra<limiteConfirmacao);
      bool janelaVenda =(retornoVendaAtivo && candlesConfVenda<limiteConfirmacao);
      double margem=MathMax(_Point*80.0,range*0.45);
      string base="COPA_FIX426_DX_CIRURGICO_"+IntegerToString((int)tempo)+"_";

      if(janelaCompra && confirmaCompra && rompeAnteriorCompra && direcionalCompra && liberadoRepeticaoCompra)
      {
         double poc=0.0;
         bool pocCalc=CalcularPOCGenericoFIX430(tf,shift,InpDXMasterPeriodoPOCFIX430,InpDXMasterFaixaPOCPontosFIX430,poc);
         bool pocOK=(!InpDXMasterExigirPOCFIX430 || (pocCalc && c>poc+InpDXMasterDistanciaPOCPontosFIX430*_Point));
         double kSup=keltEMA[shift]+keltATR[shift]*InpDXMasterMultiplicadorKeltFIX430;
         bool bollOK=(c>bollSup[shift]);
         bool keltOK=(c>kSup);
         bool canalOK=(!InpDXMasterExigirBollOuKeltFIX430 || bollOK || keltOK);
         bool ftOK=FundoTetoLiberadoFIX430(tf,shift,true,c);
         int extras=(hiloCompra?1:0)+(strCompra?1:0)+(bollOK?1:0)+(keltOK?1:0)+(ftOK?1:0);
         bool masterOK=(!InpDXMasterAtivoFIX430 || (pocOK && canalOK && ftOK && extras>=MathMax(1,InpDXMasterMinimoExtrasFIX430)));
         if(!InpDXMasterMostrarSomenteMelhoresFIX430 || !InpDXMasterAtivoFIX430) CriarSetaSTRFIX418(base+"DX_BUY",tempo,l-margem,true);
         if(InpDXMasterAtivoFIX430 && masterOK)
         {
            CriarSetaDXMasterFIX430("COPA_DX_MASTER_FIX430_BUY_"+IntegerToString((int)tempo),tempo,l-margem*1.55,true,extras,poc);
            g_dxMasterCompraFIX430++;
         }
         totalCompra++;
         PrintFormat("[COPA_AR100][FIX430][ENTRADA_VISUAL] COMPRA | MASTER=%s | EXTRAS=%d | POC=%s | BOLL=%s | KELT=%s | FT=%s | HORA=%s",(masterOK?"OK":"BLOQ"),extras,(pocOK?"OK":"NAO"),(bollOK?"OK":"NAO"),(keltOK?"OK":"NAO"),(ftOK?"OK":"NAO"),TimeToString(tempo,TIME_DATE|TIME_MINUTES));
         candlesDesdeCompra=0;
         toqueCompra=false;
         horaToqueCompra=0;
         retornoCompraAtivo=false;
         candlesConfCompra=0;
         // invalida o setup oposto antigo para evitar duas setas sobre o mesmo movimento
         toqueVenda=false;
         horaToqueVenda=0;
         retornoVendaAtivo=false;
         candlesConfVenda=0;
      }
      else if(janelaVenda && confirmaVenda && rompeAnteriorVenda && direcionalVenda && liberadoRepeticaoVenda)
      {
         double poc=0.0;
         bool pocCalc=CalcularPOCGenericoFIX430(tf,shift,InpDXMasterPeriodoPOCFIX430,InpDXMasterFaixaPOCPontosFIX430,poc);
         bool pocOK=(!InpDXMasterExigirPOCFIX430 || (pocCalc && c<poc-InpDXMasterDistanciaPOCPontosFIX430*_Point));
         double kInf=keltEMA[shift]-keltATR[shift]*InpDXMasterMultiplicadorKeltFIX430;
         bool bollOK=(c<bollInf[shift]);
         bool keltOK=(c<kInf);
         bool canalOK=(!InpDXMasterExigirBollOuKeltFIX430 || bollOK || keltOK);
         bool ftOK=FundoTetoLiberadoFIX430(tf,shift,false,c);
         int extras=(hiloVenda?1:0)+(strVenda?1:0)+(bollOK?1:0)+(keltOK?1:0)+(ftOK?1:0);
         bool masterOK=(!InpDXMasterAtivoFIX430 || (pocOK && canalOK && ftOK && extras>=MathMax(1,InpDXMasterMinimoExtrasFIX430)));
         if(!InpDXMasterMostrarSomenteMelhoresFIX430 || !InpDXMasterAtivoFIX430) CriarSetaSTRFIX418(base+"DX_SELL",tempo,h+margem,false);
         if(InpDXMasterAtivoFIX430 && masterOK)
         {
            CriarSetaDXMasterFIX430("COPA_DX_MASTER_FIX430_SELL_"+IntegerToString((int)tempo),tempo,h+margem*1.55,false,extras,poc);
            g_dxMasterVendaFIX430++;
         }
         totalVenda++;
         PrintFormat("[COPA_AR100][FIX430][ENTRADA_VISUAL] VENDA | MASTER=%s | EXTRAS=%d | POC=%s | BOLL=%s | KELT=%s | FT=%s | HORA=%s",(masterOK?"OK":"BLOQ"),extras,(pocOK?"OK":"NAO"),(bollOK?"OK":"NAO"),(keltOK?"OK":"NAO"),(ftOK?"OK":"NAO"),TimeToString(tempo,TIME_DATE|TIME_MINUTES));
         candlesDesdeVenda=0;
         toqueVenda=false;
         horaToqueVenda=0;
         retornoVendaAtivo=false;
         candlesConfVenda=0;
         toqueCompra=false;
         horaToqueCompra=0;
         retornoCompraAtivo=false;
         candlesConfCompra=0;
      }
      else
      {
         if(retornoCompraAtivo)
         {
            candlesConfCompra++;
            if(candlesConfCompra>=limiteConfirmacao)
            {
               retornoCompraAtivo=false;
               toqueCompra=false;
               horaToqueCompra=0;
            }
         }
         if(retornoVendaAtivo)
         {
            candlesConfVenda++;
            if(candlesConfVenda>=limiteConfirmacao)
            {
               retornoVendaAtivo=false;
               toqueVenda=false;
               horaToqueVenda=0;
            }
         }
      }
   }

   AtualizarPainelDXMasterFIX430();
   ChartRedraw(0);
   PrintFormat("[COPA_AR100][FIX430][VISUAL_OK] DX_MASTER | TF=%s | DIAS=%d | BASE_C=%d/V=%d | MASTER_C=%d/V=%d | SEM_ORDENS=SIM",EnumToString(tf),diasHistoricos,totalCompra,totalVenda,g_dxMasterCompraFIX430,g_dxMasterVendaFIX430);
   AtualizarComparativoDXCanaisFIX429();
}


// ============================================================================
// RESPONSABILIDADE: HILO SCORE STATUS E SLOTS DO PAINEL
// ============================================================================

void AtualizarHiLo8ESTR()
{
   g_mercado.hiloCompra = false;
   g_mercado.hiloVenda = false;
   g_mercado.strCompra = false;
   g_mercado.strVenda = false;

   int shift = InpUsarCandleFiltroFechado ? 1 : 0;
   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(barras < shift + 12)
      return;

   double somaLow = 0.0;
   double somaHigh = 0.0;
   int periodo = 8;
   for(int i = shift + 1; i <= shift + periodo; i++)
   {
      somaLow += iLow(_Symbol, TimeframeFiltroAtualFIX255(), i);
      somaHigh += iHigh(_Symbol, TimeframeFiltroAtualFIX255(), i);
   }
   double hiloLow = somaLow / (double)periodo;
   double hiloHigh = somaHigh / (double)periodo;
   double open0 = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double high0 = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double low0 = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close1 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   double close3 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 3);
   if(close0 <= 0.0 || close1 <= 0.0 || close3 <= 0.0)
      return;

   g_mercado.hiloCompra = (close0 > hiloHigh);
   g_mercado.hiloVenda = (close0 < hiloLow);

   double range = high0 - low0;
   double corpo = MathAbs(close0 - open0);
   double proporcaoCorpo = (range > 0.0 ? corpo / range : 0.0);
   bool candleForte = (proporcaoCorpo >= 0.35);
   g_mercado.strCompra = (candleForte && close0 > open0 && close0 > close3);
   g_mercado.strVenda = (candleForte && close0 < open0 && close0 < close3);
}

double CalcularScoreFluxo()
{
   double scoreDX = MathMin(100.0, MathMax(0.0, g_mercado.dx * 2.0));
   double scoreRSI = 100.0 - MathAbs(50.0 - g_mercado.rsi) * 2.0;
   double ratioHora = MathMin(g_mercado.volqRatioAjustadoHora, g_mercado.volfRatioAjustadoHora);
   double ratio15   = MathMin(g_mercado.volqRatio15m, g_mercado.volfRatio15m);
   double ratio5    = MathMin(g_mercado.volqRatio5m, g_mercado.volfRatio5m);
   double ratioVol  = MathMax(ratioHora, MathMax(ratio15 * 0.85, ratio5 * 0.70));
   if(ratioVol <= 0.0)
      ratioVol = g_mercado.volq / 20.0 / 100.0;
   double scoreVOL = MathMin(100.0, MathMax(0.0, ratioVol * 45.0));
   if(g_mercado.volFarol == 4)
      scoreVOL = MathMax(scoreVOL, 95.0);
   else if(g_mercado.volFarol == 3)
      scoreVOL = MathMax(scoreVOL, 85.0);
   else if(g_mercado.volFarol == 2)
      scoreVOL = MathMax(scoreVOL, 70.0);
   double scoreAGR = 50.0;
   if(g_mercado.agr >= 0.0)
      scoreAGR = MathMax(g_mercado.agr, 100.0 - g_mercado.agr); // força da agressão dominante
   double score = (scoreDX * 0.30) + (scoreRSI * 0.15) + (scoreVOL * 0.30) + (scoreAGR * 0.25);
   if(score < 0.0)
      score = 0.0;
   if(score > 100.0)
      score = 100.0;
   return score;
}

ENUM_STATUS_MERCADO ClassificarMercado(double score)
{
   if(score >= g_gerAumentos.scoreExtremo)
      return MERCADO_EXTREMO;
   if(score > g_gerAumentos.scoreForteMax)
      return MERCADO_FORTE;
   if(score < 40.0)
      return MERCADO_FRACO;
   return MERCADO_NORMAL;
}

string NomeStatusMercado(ENUM_STATUS_MERCADO status)
{
   if(status == MERCADO_FRACO)
      return "FRACO";
   if(status == MERCADO_NORMAL)
      return "NORMAL";
   if(status == MERCADO_FORTE)
      return "FORTE";
   if(status == MERCADO_EXTREMO)
      return "EXTREMO";
   return "N/D";
}

string TextoDXStatus()
{
   if(g_mercado.dxStatus == 2)
      return "ACIMA";
   if(g_mercado.dxStatus == 0)
      return "ABAIXO";
   return "DENTRO";
}


// ============================================================================
// RESPONSABILIDADE: AGRESSAO VOLUME RSI E CONFIRMACOES
// ============================================================================

void AtualizarNovoCandle()
{
   datetime t = iTime(_Symbol, TimeframeEntradaAtualFIX255(), 0);
   g_novoCandle = false;
   if(t != 0 && t != g_ultimoCandle)
   {
      g_ultimoCandle = t;
      g_novoCandle = true;
   }
}

double CalcularAgressaoCompradoraTicks(int quantidadeTicks)
{
   if(quantidadeTicks < 32)
      quantidadeTicks = 32;
   if(quantidadeTicks > 2000)
      quantidadeTicks = 2000;

   MqlTick ticks[];
   int copiados = CopyTicks(_Symbol, ticks, COPY_TICKS_TRADE, 0, (uint)quantidadeTicks);
   if(copiados <= 1)
      return -1.0;

   double volumeCompra = 0.0;
   double volumeVenda = 0.0;
   double ultimoLast = 0.0;
   for(int i = 0; i < copiados; i++)
   {
      double peso = ticks[i].volume_real;
      if(peso <= 0.0)
         peso = (double)ticks[i].volume;
      if(peso <= 0.0)
         peso = 1.0;

      bool agressaoCompra = ((ticks[i].flags & TICK_FLAG_BUY) != 0);
      bool agressaoVenda = ((ticks[i].flags & TICK_FLAG_SELL) != 0);
      double lastAtual = ticks[i].last;

      // Alguns servidores não entregam BUY/SELL. Nesse caso, usa a direção do último negócio.
      if(!agressaoCompra && !agressaoVenda && lastAtual > 0.0 && ultimoLast > 0.0)
      {
         if(lastAtual > ultimoLast)
            agressaoCompra = true;
         else if(lastAtual < ultimoLast)
            agressaoVenda = true;
      }

      if(agressaoCompra && !agressaoVenda)
         volumeCompra += peso;
      else if(agressaoVenda && !agressaoCompra)
         volumeVenda += peso;

      if(lastAtual > 0.0)
         ultimoLast = lastAtual;
   }

   double totalDirecional = volumeCompra + volumeVenda;
   if(totalDirecional <= 0.0)
      return -1.0;
   double percentual = 100.0 * volumeCompra / totalDirecional;
   return MathMax(0.0, MathMin(100.0, percentual));
}

double AgressaoDirecionalPercentual(ENUM_LADO_ROBO lado)
{
   if(g_mercado.agr < 0.0)
      return -1.0;
   double compra = MathMax(0.0, MathMin(100.0, g_mercado.agr));
   if(lado == LADO_VENDA)
      return 100.0 - compra;
   return compra;
}

// FIX259: versao leve. Nao busca milhares de negocios historicos no OnInit/nova barra.
// Usa a agressao que AtualizarMercado() ja calculou; somente faz uma pequena leitura de reserva.
double CalcularAgressaoCompradoraCandleFIX258(datetime inicio, datetime fim)
{
   if(!g_painelProntoFIX259 || inicio <= 0 || fim <= inicio)
      return -1.0;

   if(g_mercado.agr >= 0.0)
      return MathMax(0.0, MathMin(100.0, g_mercado.agr));

   int amostraLeve = InpContraMaxTicksAgressao;
   if(amostraLeve < 32)
      amostraLeve = 32;
   if(amostraLeve > 512)
      amostraLeve = 512;
   return CalcularAgressaoCompradoraTicks(amostraLeve);
}

// FIX258: QTD e FIN precisam aprovar juntas e o farol precisa estar FORTE ou superior.


// FIX261: volume da propria barra. Usa volume real quando a corretora fornece;
// caso contrario usa tick volume. O comparativo por razao continua valido.
double VolumeQuantidadeBarraContraFIX261(int shift)
{
   if(shift < 0)
      return 0.0;
   long realVolume = iRealVolume(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   if(realVolume > 0)
      return (double)realVolume;
   long tickVolume = iVolume(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   return (tickVolume > 0 ? (double)tickVolume : 0.0);
}

double VolumeFinanceiroBarraContraFIX261(int shift)
{
   double qtd = VolumeQuantidadeBarraContraFIX261(shift);
   if(qtd <= 0.0)
      return 0.0;
   double high = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double low = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   if(high <= 0.0 || low <= 0.0 || close <= 0.0)
      return 0.0;
   double precoTipico = (high + low + close) / 3.0;
   return qtd * precoTipico;
}

// FIX261: para o historico, QTD e FIN sao comparados com as barras anteriores.
// Isso evita usar o volume "de agora" para decidir uma barra antiga.
bool VolumeQtdFinHistoricoContraFIX261(int shift, double &ratioQtd, double &ratioFin)
{
   ratioQtd = 0.0;
   ratioFin = 0.0;
   int periodo = InpContraVolumeMediaPeriodo;
   if(periodo < 5)
      periodo = 5;
   if(periodo > 100)
      periodo = 100;

   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(shift < 1 || barras <= shift + periodo + 1)
      return false;

   double qtdAtual = VolumeQuantidadeBarraContraFIX261(shift);
   double finAtual = VolumeFinanceiroBarraContraFIX261(shift);
   if(qtdAtual <= 0.0 || finAtual <= 0.0)
      return false;

   double somaQtd = 0.0;
   double somaFin = 0.0;
   int validas = 0;
   for(int i = shift + 1; i <= shift + periodo; i++)
   {
      double qtd = VolumeQuantidadeBarraContraFIX261(i);
      double fin = VolumeFinanceiroBarraContraFIX261(i);
      if(qtd <= 0.0 || fin <= 0.0)
         continue;
      somaQtd += qtd;
      somaFin += fin;
      validas++;
   }
   if(validas < MathMax(3, periodo / 2))
      return false;

   double mediaQtd = somaQtd / (double)validas;
   double mediaFin = somaFin / (double)validas;
   if(mediaQtd <= 0.0 || mediaFin <= 0.0)
      return false;

   ratioQtd = qtdAtual / mediaQtd;
   ratioFin = finAtual / mediaFin;
   double multiplicador = MathMax(0.10, MathMin(5.0, MathAbs(InpContraVolumeMultiplicador)));
   return (ratioQtd >= multiplicador && ratioFin >= multiplicador);
}

// FIX263: RSI manual de reserva. Assim a pintura histórica não depende do handle terminar de carregar.
double RSICalculadoManualContraFIX262(int shift, int periodo)
{
   if(shift < 0)
      return -1.0;
   if(periodo < 2)
      periodo = 14;
   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(barras <= shift + periodo + 2)
      return -1.0;

   double ganhos = 0.0;
   double perdas = 0.0;
   for(int i = shift; i < shift + periodo; i++)
   {
      double atual = iClose(_Symbol, TimeframeFiltroAtualFIX255(), i);
      double anterior = iClose(_Symbol, TimeframeFiltroAtualFIX255(), i + 1);
      if(atual <= 0.0 || anterior <= 0.0)
         return -1.0;
      double variacao = atual - anterior;
      if(variacao > 0.0)
         ganhos += variacao;
      else
         perdas += -variacao;
   }
   if(perdas <= 0.0)
      return (ganhos > 0.0 ? 100.0 : 50.0);
   double mediaGanhos = ganhos / (double)periodo;
   double mediaPerdas = perdas / (double)periodo;
   if(mediaPerdas <= 0.0)
      return 100.0;
   double rs = mediaGanhos / mediaPerdas;
   return 100.0 - (100.0 / (1.0 + rs));
}

double RSIHistoricoContraFIX261(int shift)
{
   if(shift < 0)
      return -1.0;
   if(g_handleRSI != INVALID_HANDLE)
   {
      double buffer[];
      ArrayResize(buffer, 1);
      if(CopyBuffer(g_handleRSI, 0, shift, 1, buffer) == 1 && buffer[0] >= 0.0 && buffer[0] <= 100.0)
         return buffer[0];
   }
   return RSICalculadoManualContraFIX262(shift, 14);
}

bool HiLoSTRHistoricoContraFIX261(int shift,
                                  bool &hiloCompra,
                                  bool &hiloVenda,
                                  bool &strCompra,
                                  bool &strVenda)
{
   hiloCompra = false;
   hiloVenda = false;
   strCompra = false;
   strVenda = false;
   if(shift < 1)
      return false;

   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   const int periodo = 8;
   if(barras <= shift + periodo + 3)
      return false;

   double somaLow = 0.0;
   double somaHigh = 0.0;
   for(int i = shift + 1; i <= shift + periodo; i++)
   {
      somaLow += iLow(_Symbol, TimeframeFiltroAtualFIX255(), i);
      somaHigh += iHigh(_Symbol, TimeframeFiltroAtualFIX255(), i);
   }

   double hiloLow = somaLow / (double)periodo;
   double hiloHigh = somaHigh / (double)periodo;
   double open0 = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double high0 = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double low0 = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close3 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 3);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 || close3 <= 0.0)
      return false;

   hiloCompra = (close0 > hiloHigh);
   hiloVenda = (close0 < hiloLow);

   double range = high0 - low0;
   double corpo = MathAbs(close0 - open0);
   double proporcaoCorpo = (range > 0.0 ? corpo / range : 0.0);
   bool candleForte = (proporcaoCorpo >= 0.35);
   strCompra = (candleForte && close0 > open0 && close0 > close3);
   strVenda = (candleForte && close0 < open0 && close0 < close3);
   return true;
}

// FIX261: barras antigas normalmente nao possuem BUY/SELL por negocio disponivel no terminal.
// A estimativa usa onde o fechamento ficou dentro da maxima/minima da propria barra:
// perto da maxima = agressao compradora; perto da minima = agressao vendedora.
double AgressaoCompradoraEstimadaContraFIX261(int shift)
{
   double high = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double low = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double range = high - low;
   if(high <= 0.0 || low <= 0.0 || close <= 0.0 || range <= 0.0)
      return 50.0;
   double percentual = 100.0 * (close - low) / range;
   return MathMax(0.0, MathMin(100.0, percentual));
}

double MediaFechamentoAnteriorContraFIX265(int shift, int periodo)
{
   if(periodo < 2)
      periodo = 8;
   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(shift < 1 || barras <= shift + periodo + 2)
      return 0.0;
   double soma = 0.0;
   int validas = 0;
   for(int i = shift + 1; i <= shift + periodo; i++)
   {
      double close = iClose(_Symbol, TimeframeFiltroAtualFIX255(), i);
      if(close <= 0.0)
         continue;
      soma += close;
      validas++;
   }
   return (validas > 0 ? soma / (double)validas : 0.0);
}

double ATRManualContraFIX265(int shift, int periodo)
{
   if(periodo < 2)
      periodo = 14;
   if(periodo > 100)
      periodo = 100;
   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(shift < 1 || barras <= shift + periodo + 3)
      return 0.0;
   double soma = 0.0;
   int validas = 0;
   for(int i = shift + 1; i <= shift + periodo; i++)
   {
      double high = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), i);
      double low = iLow(_Symbol, TimeframeFiltroAtualFIX255(), i);
      double closeAnterior = iClose(_Symbol, TimeframeFiltroAtualFIX255(), i + 1);
      if(high <= 0.0 || low <= 0.0 || closeAnterior <= 0.0 || high < low)
         continue;
      double tr = MathMax(high - low, MathMax(MathAbs(high - closeAnterior), MathAbs(low - closeAnterior)));
      soma += tr;
      validas++;
   }
   return (validas > 0 ? soma / (double)validas : 0.0);
}

// O candle pintado e o gatilho, nao o candle que apenas chegou ao RSI extremo.
bool CandleReversaoBasicoContraFIX265(int shift, ENUM_LADO_ROBO ladoContra)
{
   if(shift < 1)
      return false;
   double open0 = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double high0 = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double low0 = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double open1 = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   double high1 = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   double low1 = iLow(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   double close1 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 ||
      open1 <= 0.0 || high1 <= 0.0 || low1 <= 0.0 || close1 <= 0.0)
      return false;

   double range = high0 - low0;
   if(range <= 0.0)
      return false;
   double corpo = MathAbs(close0 - open0);
   double proporcaoCorpo = corpo / range;
   double corpoMinimo = MathMax(0.10, MathMin(0.90, MathAbs(InpContraCorpoMinConfirmacao)));
   if(proporcaoCorpo < corpoMinimo)
      return false;

   double zona = MathMax(10.0, MathMin(49.0, MathAbs(InpContraFechamentoZonaPercent))) / 100.0;
   double posicaoFechamento = (close0 - low0) / range;
   double meioAnterior = (high1 + low1) / 2.0;

   if(ladoContra == LADO_VENDA)
   {
      bool candleDirecional = (close0 < open0 && close0 < close1 && posicaoFechamento <= zona);
      bool rompe = (close0 < low1);
      bool engolfo = (open0 >= close1 && close0 <= open1);
      bool rejeicao = (high0 >= high1 && close0 < meioAnterior);
      return (candleDirecional && (!InpContraExigirRompimentoAnterior || rompe || engolfo || rejeicao));
   }
   if(ladoContra == LADO_COMPRA)
   {
      bool candleDirecional = (close0 > open0 && close0 > close1 && posicaoFechamento >= (1.0 - zona));
      bool rompe = (close0 > high1);
      bool engolfo = (open0 <= close1 && close0 >= open1);
      bool rejeicao = (low0 <= low1 && close0 > meioAnterior);
      return (candleDirecional && (!InpContraExigirRompimentoAnterior || rompe || engolfo || rejeicao));
   }
   return false;
}


double MediaFechamentoIncluindoAtualContraFIX266(int shift, int periodo)
{
   if(periodo < 2)
      periodo = 8;
   if(periodo > 100)
      periodo = 100;
   int barras = Bars(_Symbol, TimeframeFiltroAtualFIX255());
   if(shift < 1 || barras <= shift + periodo + 2)
      return 0.0;

   double soma = 0.0;
   int validas = 0;
   for(int i = shift; i < shift + periodo; i++)
   {
      double close = iClose(_Symbol, TimeframeFiltroAtualFIX255(), i);
      if(close <= 0.0)
         continue;
      soma += close;
      validas++;
   }
   return (validas > 0 ? soma / (double)validas : 0.0);
}

// FIX266: o retorno do RSI deve ser uma saída real do extremo.
// A janela curta permite que a quebra de estrutura ocorra até poucos candles depois do cruzamento.
bool RetornoRSIConfirmadoContraFIX266(int shift, ENUM_LADO_ROBO ladoContra, double rsiAtual)
{
   if(!InpContraExigirRetornoRSI)
      return true;

   double nivelVenda = MathMax(50.0, MathMin(99.0, MathAbs(InpContraRSIRetornoVenda)));
   double nivelCompra = MathMax(1.0, MathMin(50.0, MathAbs(InpContraRSIRetornoCompra)));

   if(!InpContraExigirCruzamentoRSI)
   {
      if(ladoContra == LADO_VENDA)
         return (rsiAtual <= nivelVenda);
      if(ladoContra == LADO_COMPRA)
         return (rsiAtual >= nivelCompra);
      return false;
   }

   int janela = InpContraJanelaRetornoRSIBarras;
   if(janela < 1) janela = 1;
   if(janela > 8) janela = 8;

   for(int s = shift; s < shift + janela; s++)
   {
      double rsiNovo = RSIHistoricoContraFIX261(s);
      double rsiVelho = RSIHistoricoContraFIX261(s + 1);
      if(rsiNovo < 0.0 || rsiVelho < 0.0)
         continue;

      if(ladoContra == LADO_VENDA && rsiVelho > nivelVenda && rsiNovo <= nivelVenda)
         return true;
      if(ladoContra == LADO_COMPRA && rsiVelho < nivelCompra && rsiNovo >= nivelCompra)
         return true;
   }
   return false;
}

// FIX266: confirma mudança da microestrutura, evitando vender apenas porque o RSI está alto
// ou comprar apenas porque o RSI está baixo.
bool QuebraEstruturaContraFIX266(int shift, ENUM_LADO_ROBO ladoContra)
{
   if(!InpContraExigirQuebraEstrutura)
      return true;
   if(shift < 1)
      return false;

   int barrasEstrutura = InpContraEstruturaBarras;
   if(barrasEstrutura < 2) barrasEstrutura = 2;
   if(barrasEstrutura > 8) barrasEstrutura = 8;

   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   if(close0 <= 0.0)
      return false;

   if(ladoContra == LADO_VENDA)
   {
      double menorLow = 1.0e100;
      for(int i = shift + 1; i <= shift + barrasEstrutura; i++)
      {
         double low = iLow(_Symbol, TimeframeFiltroAtualFIX255(), i);
         if(low > 0.0 && low < menorLow)
            menorLow = low;
      }
      return (menorLow < 1.0e99 && close0 < menorLow);
   }

   if(ladoContra == LADO_COMPRA)
   {
      double maiorHigh = -1.0e100;
      for(int i = shift + 1; i <= shift + barrasEstrutura; i++)
      {
         double high = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), i);
         if(high > maiorHigh)
            maiorHigh = high;
      }
      return (maiorHigh > -1.0e99 && close0 > maiorHigh);
   }
   return false;
}

// FIX266: a média 8 funciona como linha de sustentação/resistência da tendência curta.
// O sinal contra só aparece depois de o candle cruzar e fechar do outro lado.
bool CruzamentoMedia8ContraFIX266(int shift, ENUM_LADO_ROBO ladoContra)
{
   if(!InpContraExigirCruzamentoMedia8)
      return true;
   if(shift < 1)
      return false;

   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close1 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   double media0 = MediaFechamentoIncluindoAtualContraFIX266(shift, 8);
   double media1 = MediaFechamentoIncluindoAtualContraFIX266(shift + 1, 8);
   double atr = ATRManualContraFIX265(shift, InpContraATRPeriodo);
   if(close0 <= 0.0 || close1 <= 0.0 || media0 <= 0.0 || media1 <= 0.0 || atr <= 0.0)
      return false;

   double margemATR = MathMax(0.0, MathMin(1.0, MathAbs(InpContraMargemMediaATR)));
   double margem = atr * margemATR;

   if(ladoContra == LADO_VENDA)
      return (close1 >= media1 && close0 < (media0 - margem));
   if(ladoContra == LADO_COMPRA)
      return (close1 <= media1 && close0 > (media0 + margem));
   return false;
}

// FIX269: mede a exaustao por duas referencias sem olhar candles futuros:
// 1) distancia do extremo ate a media 8 em multiplos de ATR;
// 2) extensao acima/abaixo do range estrutural anterior.
// Se qualquer uma atingir 1.272, existe zona Fibo. Em 1.618 a exaustao e forte.

// ============================================================================
// RESPONSABILIDADE: SINAIS OTT E ESTRUTURA
// ============================================================================

bool CalcularFiboExaustaoContraFIX269(int shiftSetup,
                                      ENUM_LADO_ROBO ladoContra,
                                      double &nivelFibo,
                                      double &extensaoATR,
                                      double &extensaoEstrutural)
{
   nivelFibo = 0.0;
   extensaoATR = 0.0;
   extensaoEstrutural = 0.0;
   if(!InpContraUsarFiboExaustao)
      return true;
   if(shiftSetup < 1)
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double highSetup = iHigh(_Symbol, tf, shiftSetup);
   double lowSetup = iLow(_Symbol, tf, shiftSetup);
   double media8 = MediaFechamentoAnteriorContraFIX265(shiftSetup, 8);
   double atr = ATRManualContraFIX265(shiftSetup, InpContraATRPeriodo);
   if(highSetup <= 0.0 || lowSetup <= 0.0 || media8 <= 0.0 || atr <= 0.0)
      return false;

   if(ladoContra == LADO_VENDA)
      extensaoATR = MathMax(0.0, (highSetup - media8) / atr);
   else if(ladoContra == LADO_COMPRA)
      extensaoATR = MathMax(0.0, (media8 - lowSetup) / atr);
   else
      return false;

   int lookback = InpContraFiboLookbackEstrutural;
   if(lookback < 8) lookback = 8;
   if(lookback > 80) lookback = 80;
   double highAnterior = -1.0e100;
   double lowAnterior = 1.0e100;
   for(int i = shiftSetup + 1; i <= shiftSetup + lookback; i++)
   {
      double h = iHigh(_Symbol, tf, i);
      double l = iLow(_Symbol, tf, i);
      if(h > highAnterior) highAnterior = h;
      if(l > 0.0 && l < lowAnterior) lowAnterior = l;
   }
   double rangeAnterior = highAnterior - lowAnterior;
   if(highAnterior > -1.0e99 && lowAnterior < 1.0e99 && rangeAnterior > 0.0)
   {
      if(ladoContra == LADO_VENDA && highSetup > highAnterior)
         extensaoEstrutural = 1.0 + (highSetup - highAnterior) / rangeAnterior;
      else if(ladoContra == LADO_COMPRA && lowSetup < lowAnterior)
         extensaoEstrutural = 1.0 + (lowAnterior - lowSetup) / rangeAnterior;
   }

   double minimo = MathMax(1.0, MathMin(3.0, MathAbs(InpContraFiboNivelMinimo)));
   double forte = MathMax(minimo, MathMin(4.0, MathAbs(InpContraFiboNivelForte)));
   double maiorExtensao = MathMax(extensaoATR, extensaoEstrutural);
   if(maiorExtensao >= forte)
      nivelFibo = forte;
   else if(maiorExtensao >= minimo)
      nivelFibo = minimo;

   return (nivelFibo >= minimo || !InpContraFiboObrigatorio);
}

// FIX267: o candle em shift+1 e apenas o gatilho. O candle em shift deve provar
// que a reversao continuou. Isso evita marcar cada pequeno recuo contra uma tendencia forte.
bool ConfirmacaoSegundoCandleContraFIX267(int shift,
                                           ENUM_LADO_ROBO ladoContra,
                                           int shiftGatilho,
                                           double extremaSetup,
                                           double nivelFiboSetup)
{
   if(!InpContraExigirSegundoCandle)
      return true;
   if(shift < 1 || shiftGatilho != shift + 1)
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double open0 = iOpen(_Symbol, tf, shift);
   double high0 = iHigh(_Symbol, tf, shift);
   double low0 = iLow(_Symbol, tf, shift);
   double close0 = iClose(_Symbol, tf, shift);
   double highG = iHigh(_Symbol, tf, shiftGatilho);
   double lowG = iLow(_Symbol, tf, shiftGatilho);
   double rsi0 = RSIHistoricoContraFIX261(shift);
   double rsiG = RSIHistoricoContraFIX261(shiftGatilho);
   double agrCompra0 = AgressaoCompradoraEstimadaContraFIX261(shift);
   double atr = ATRManualContraFIX265(shift, InpContraATRPeriodo);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 ||
      highG <= 0.0 || lowG <= 0.0 || rsi0 < 0.0 || rsiG < 0.0 || atr <= 0.0)
      return false;

   double range = high0 - low0;
   if(range <= 0.0)
      return false;
   double corpo = MathAbs(close0 - open0) / range;
   double corpoMin = MathMax(0.10, MathMin(0.90, MathAbs(InpContraCorpoMinSegundoCandle)));
   if(corpo < corpoMin)
      return false;

   int periodoLongo = InpContraMediaTendenciaPeriodo;
   if(periodoLongo < 10) periodoLongo = 10;
   if(periodoLongo > 100) periodoLongo = 100;
   double ma8 = MediaFechamentoIncluindoAtualContraFIX266(shift, 8);
   double ma8Anterior = MediaFechamentoIncluindoAtualContraFIX266(shift + 1, 8);
   double ma21 = MediaFechamentoIncluindoAtualContraFIX266(shift, periodoLongo);
   if(ma8 <= 0.0 || ma8Anterior <= 0.0 || ma21 <= 0.0)
      return false;

   double margemRompimento = atr * MathMax(0.0, MathMin(1.0, MathAbs(InpContraMargemEntradaATR)));
   double margemMedia21 = atr * MathMax(0.0, MathMin(1.0, MathAbs(InpContraMargemMedia21ATR)));
   double toleranciaExtrema = atr * MathMax(0.0, MathMin(1.0, MathAbs(InpContraMaxNovaExtremaATR)));
   double deltaRSI = MathMax(0.0, MathMin(20.0, MathAbs(InpContraDeltaRSIMinimo)));
   double agrMin = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoEntradaMinima)));
   double nivelForte = MathMax(MathAbs(InpContraFiboNivelMinimo), MathAbs(InpContraFiboNivelForte));
   bool fiboForte = (nivelFiboSetup >= nivelForte - 0.0001);
   int minTecnicas = InpContraMinConfirmacoesSegundo;
   if(minTecnicas < 1) minTecnicas = 1;
   if(minTecnicas > 5) minTecnicas = 5;
   if(fiboForte && minTecnicas > 1)
      minTecnicas--; // Fibo 1.618 permite uma confirmação técnica a menos, mas não elimina o segundo candle

   if(ladoContra == LADO_VENDA)
   {
      bool candleContinua = (close0 < open0);
      bool rompeGatilho = (close0 < lowG - margemRompimento);
      bool semNovaMaxima = (high0 <= highG + toleranciaExtrema &&
                            (extremaSetup <= 0.0 || high0 <= extremaSetup + toleranciaExtrema));
      bool rsiContinua = (rsi0 <= MathMax(50.0, MathMin(70.0, MathAbs(InpContraRSILimiteEntradaVenda))) &&
                          rsi0 <= rsiG - deltaRSI);
      bool agressaoContinua = ((100.0 - agrCompra0) >= agrMin);
      bool abaixoMedia21 = (close0 < ma21 - margemMedia21);
      bool abaixoMedia8 = (close0 < ma8);
      bool media8Inclinou = (ma8 < ma8Anterior);
      bool mediasAlinhadas = (ma8 < ma21);
      int tecnicas = 0;
      if(agressaoContinua) tecnicas++;
      if(abaixoMedia21) tecnicas++;
      if(abaixoMedia8) tecnicas++;
      if(media8Inclinou) tecnicas++;
      if(mediasAlinhadas) tecnicas++;
      bool protecaoMinima = (agressaoContinua || abaixoMedia21);
      return (candleContinua && rompeGatilho && semNovaMaxima && rsiContinua &&
              protecaoMinima && tecnicas >= minTecnicas);
   }

   if(ladoContra == LADO_COMPRA)
   {
      bool candleContinua = (close0 > open0);
      bool rompeGatilho = (close0 > highG + margemRompimento);
      bool semNovaMinima = (low0 >= lowG - toleranciaExtrema &&
                            (extremaSetup <= 0.0 || low0 >= extremaSetup - toleranciaExtrema));
      bool rsiContinua = (rsi0 >= MathMin(50.0, MathMax(30.0, MathAbs(InpContraRSILimiteEntradaCompra))) &&
                          rsi0 >= rsiG + deltaRSI);
      bool agressaoContinua = (agrCompra0 >= agrMin);
      bool acimaMedia21 = (close0 > ma21 + margemMedia21);
      bool acimaMedia8 = (close0 > ma8);
      bool media8Inclinou = (ma8 > ma8Anterior);
      bool mediasAlinhadas = (ma8 > ma21);
      int tecnicas = 0;
      if(agressaoContinua) tecnicas++;
      if(acimaMedia21) tecnicas++;
      if(acimaMedia8) tecnicas++;
      if(media8Inclinou) tecnicas++;
      if(mediasAlinhadas) tecnicas++;
      bool protecaoMinima = (agressaoContinua || acimaMedia21);
      return (candleContinua && rompeGatilho && semNovaMinima && rsiContinua &&
              protecaoMinima && tecnicas >= minTecnicas);
   }
   return false;
}


bool ExisteSinalRecenteContraFIX265(int shift, ENUM_LADO_ROBO ladoContra)
{
   int cooldown = InpContraCooldownBarras;
   if(cooldown < 0)
      cooldown = 0;
   if(cooldown > 100)
      cooldown = 100;
   if(cooldown == 0)
      return false;

   string ladoNome = (ladoContra == LADO_COMPRA ? "AZUL_COMPRA_" : "AMARELO_VENDA_");
   string prefixo = PrefixoCandleContraFIX258() + ladoNome;
   for(int i = shift + 1; i <= shift + cooldown; i++)
   {
      datetime tempo = iTime(_Symbol, TimeframeFiltroAtualFIX255(), i);
      if(tempo <= 0)
         continue;
      string base = prefixo + IntegerToString((int)tempo);
      if(ObjectFind(0, base + "_CORPO") >= 0 || ObjectFind(0, base + "_SETA") >= 0)
         return true;
   }
   return false;
}




// FIX271: calcula o OTT em ordem cronologica, do candle mais antigo para o mais novo.
// A media de suporte e VAR/VIDYA: a velocidade muda conforme o CMO absoluto dos ultimos 9 candles.
bool PrepararCacheOTTFIX271(int maxShift)
{
   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   int barras = Bars(_Symbol, tf);
   if(barras < 80)
      return false;

   int deslocamento = InpContraOTTDeslocamentoFIX271;
   if(deslocamento < 0) deslocamento = 0;
   if(deslocamento > 5) deslocamento = 5;
   int necessario = maxShift + deslocamento + 20;
   if(necessario < 80) necessario = 80;
   if(necessario > barras - 2) necessario = barras - 2;
   if(necessario < 20)
      return false;

   datetime barraAtual = iTime(_Symbol, tf, 0);
   if(g_ottCacheMaxShiftFIX271 >= necessario &&
      g_ottCacheBarraAtualFIX271 == barraAtual &&
      g_ottCacheTFFIX271 == tf &&
      ArraySize(g_ottSuporteFIX271) > necessario)
      return true;

   int tamanho = necessario + 2;
   ArrayResize(g_ottSuporteFIX271, tamanho);
   ArrayResize(g_ottLinhaRawFIX271, tamanho);
   ArrayResize(g_ottLongStopFIX271, tamanho);
   ArrayResize(g_ottShortStopFIX271, tamanho);
   ArrayResize(g_ottDirecaoFIX271, tamanho);
   ArrayInitialize(g_ottSuporteFIX271, 0.0);
   ArrayInitialize(g_ottLinhaRawFIX271, 0.0);
   ArrayInitialize(g_ottLongStopFIX271, 0.0);
   ArrayInitialize(g_ottShortStopFIX271, 0.0);
   ArrayInitialize(g_ottDirecaoFIX271, 1);

   int periodo = InpContraOTTPeriodoFIX271;
   if(periodo < 1) periodo = 1;
   if(periodo > 100) periodo = 100;
   double percentual = MathAbs(InpContraOTTPercentualFIX271);
   if(percentual < 0.05) percentual = 0.05;
   if(percentual > 10.0) percentual = 10.0;
   double alpha = 2.0 / (periodo + 1.0);

   for(int s = necessario; s >= 0; s--)
   {
      double fechamento = iClose(_Symbol, tf, s);
      if(fechamento <= 0.0)
         continue;

      double somaAlta = 0.0;
      double somaBaixa = 0.0;
      for(int j = s; j < s + 9 && (j + 1) <= necessario; j++)
      {
         double atual = iClose(_Symbol, tf, j);
         double anterior = iClose(_Symbol, tf, j + 1);
         if(atual <= 0.0 || anterior <= 0.0)
            continue;
         double diferenca = atual - anterior;
         if(diferenca > 0.0) somaAlta += diferenca;
         else somaBaixa += -diferenca;
      }
      double denominador = somaAlta + somaBaixa;
      double cmo = (denominador > 0.0 ? (somaAlta - somaBaixa) / denominador : 0.0);
      double peso = alpha * MathAbs(cmo);

      double suporteAnterior = (s < necessario && g_ottSuporteFIX271[s + 1] > 0.0 ? g_ottSuporteFIX271[s + 1] : fechamento);
      double suporte = peso * fechamento + (1.0 - peso) * suporteAnterior;
      if(suporte <= 0.0) suporte = fechamento;
      g_ottSuporteFIX271[s] = suporte;

      double diferencaStop = suporte * percentual * 0.01;
      double longBase = suporte - diferencaStop;
      double shortBase = suporte + diferencaStop;
      double longAnterior = (s < necessario && g_ottLongStopFIX271[s + 1] > 0.0 ? g_ottLongStopFIX271[s + 1] : longBase);
      double shortAnterior = (s < necessario && g_ottShortStopFIX271[s + 1] > 0.0 ? g_ottShortStopFIX271[s + 1] : shortBase);
      double longStop = (suporte > longAnterior ? MathMax(longBase, longAnterior) : longBase);
      double shortStop = (suporte < shortAnterior ? MathMin(shortBase, shortAnterior) : shortBase);
      g_ottLongStopFIX271[s] = longStop;
      g_ottShortStopFIX271[s] = shortStop;

      int direcaoAnterior = (s < necessario ? g_ottDirecaoFIX271[s + 1] : 1);
      if(direcaoAnterior != 1 && direcaoAnterior != -1) direcaoAnterior = 1;
      int direcao = direcaoAnterior;
      if(direcaoAnterior == -1 && suporte > shortAnterior)
         direcao = 1;
      else if(direcaoAnterior == 1 && suporte < longAnterior)
         direcao = -1;
      g_ottDirecaoFIX271[s] = direcao;

      double stopTendencia = (direcao == 1 ? longStop : shortStop);
      double ott = (suporte > stopTendencia
                    ? stopTendencia * (200.0 + percentual) / 200.0
                    : stopTendencia * (200.0 - percentual) / 200.0);
      g_ottLinhaRawFIX271[s] = ott;
   }

   g_ottCacheMaxShiftFIX271 = necessario;
   g_ottCacheBarraAtualFIX271 = barraAtual;
   g_ottCacheTFFIX271 = tf;
   return true;
}

double ValorSuporteOTTFIX271(int shift)
{
   if(shift < 0 || shift >= ArraySize(g_ottSuporteFIX271))
      return 0.0;
   return g_ottSuporteFIX271[shift];
}

double ValorLinhaOTTFIX271(int shift)
{
   int deslocamento = InpContraOTTDeslocamentoFIX271;
   if(deslocamento < 0) deslocamento = 0;
   if(deslocamento > 5) deslocamento = 5;
   int indice = shift + deslocamento;
   if(indice < 0 || indice >= ArraySize(g_ottLinhaRawFIX271))
      return 0.0;
   return g_ottLinhaRawFIX271[indice];
}

void ConfigurarSegmentoOTTFIX271(string nome, datetime t1, double p1, datetime t2, double p2, color cor, int largura)
{
   if(t1 <= 0 || t2 <= 0 || p1 <= 0.0 || p2 <= 0.0)
      return;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_TREND, 0, t1, p1, t2, p2))
         return;
   }
   else
   {
      ObjectMove(0, nome, 0, t1, p1);
      ObjectMove(0, nome, 1, t2, p2);
   }
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, largura);
   ObjectSetInteger(0, nome, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nome, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nome, OBJPROP_BACK, true);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

void LimparLinhasOTTFIX271()
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, "OTT271_VIS_") == 0)
         ObjectDelete(0, nome);
   }
}

void PlotarLinhasOTTFIX271()
{
   if(!InpContraUsarOTTFIX271 || !InpContraOTTPlotarLinhasFIX271)
   {
      LimparLinhasOTTFIX271();
      return;
   }
   int barras = InpContraOTTBarrasLinhasFIX271;
   if(barras < 30) barras = 30;
   if(barras > 1000) barras = 1000;
   if(!PrepararCacheOTTFIX271(barras + 30))
      return;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   int disponiveis = Bars(_Symbol, tf);
   barras = MathMin(barras, disponiveis - 5);
   if(barras < 3) return;

   datetime corte = iTime(_Symbol, tf, barras + 1);
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, "OTT271_VIS_") != 0)
         continue;
      datetime tempoObjeto = (datetime)ObjectGetInteger(0, nome, OBJPROP_TIME, 0);
      if(tempoObjeto > 0 && corte > 0 && tempoObjeto < corte)
         ObjectDelete(0, nome);
   }

   for(int s = barras; s >= 2; s--)
   {
      datetime t1 = iTime(_Symbol, tf, s);
      datetime t2 = iTime(_Symbol, tf, s - 1);
      double suporte1 = ValorSuporteOTTFIX271(s);
      double suporte2 = ValorSuporteOTTFIX271(s - 1);
      double ott1 = ValorLinhaOTTFIX271(s);
      double ott2 = ValorLinhaOTTFIX271(s - 1);
      string chave = IntegerToString((int)t1);
      ConfigurarSegmentoOTTFIX271("OTT271_VIS_SUP_" + chave, t1, suporte1, t2, suporte2, InpContraOTTCorSuporteFIX271, 1);
      ConfigurarSegmentoOTTFIX271("OTT271_VIS_LIN_" + chave, t1, ott1, t2, ott2, InpContraOTTCorLinhaFIX271, 2);
   }
}

// FIX272: o OTT continua sendo o gatilho principal, mas o cruzamento pode ser confirmado
// no candle atual ou nos candles imediatamente seguintes. Isso evita perder a entrada porque
// o cruzamento ocorreu em um candle pequeno e a confirmação veio depois.
bool AvaliarCandleContraOTTFIX271(int shift,
                                   ENUM_LADO_ROBO &ladoContra,
                                   double &rsi,
                                   double &agrCompra,
                                   double &ratioQtd,
                                   double &ratioFin,
                                   int &confirmacoes)
{
   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   ratioQtd = 0.0;
   ratioFin = 0.0;
   g_ultimoFiboNivelSinalFIX269 = 0.0;
   g_textoEtiquetaContraFIX271 = "";
   g_ultimoOTTSuporteSinalFIX271 = 0.0;
   g_ultimoOTTLinhaSinalFIX271 = 0.0;
   if(shift < 1)
      return false;

   int janelaPivo = InpContraOTTJanelaPivoFIX271;
   if(janelaPivo < 5) janelaPivo = 5;
   if(janelaPivo > 40) janelaPivo = 40;
   int lookback = InpContraOTTLookbackPivoFIX271;
   if(lookback < 3) lookback = 3;
   if(lookback > 30) lookback = 30;
   int janelaCruz = InpContraOTTJanelaConfirmacaoFIX272;
   if(janelaCruz < 1) janelaCruz = 1;
   if(janelaCruz > 5) janelaCruz = 5;

   if(!PrepararCacheOTTFIX271(shift + janelaPivo + lookback + janelaCruz + 40))
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double open0 = iOpen(_Symbol, tf, shift);
   double high0 = iHigh(_Symbol, tf, shift);
   double low0 = iLow(_Symbol, tf, shift);
   double close0 = iClose(_Symbol, tf, shift);
   double close1 = iClose(_Symbol, tf, shift + 1);
   double suporte0 = ValorSuporteOTTFIX271(shift);
   double suporte1 = ValorSuporteOTTFIX271(shift + 1);
   double ott0 = ValorLinhaOTTFIX271(shift);
   double ott1 = ValorLinhaOTTFIX271(shift + 1);
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 || close1 <= 0.0 ||
      suporte0 <= 0.0 || suporte1 <= 0.0 || ott0 <= 0.0 || ott1 <= 0.0 || rsi < 0.0)
      return false;

   bool cruzSuporteVendaAtual = (suporte0 < ott0 && suporte1 >= ott1);
   bool cruzSuporteCompraAtual = (suporte0 > ott0 && suporte1 <= ott1);
   bool cruzPrecoVendaAtual = (close0 < ott0 && close1 >= ott1);
   bool cruzPrecoCompraAtual = (close0 > ott0 && close1 <= ott1);
   if(cruzSuporteVendaAtual || cruzPrecoVendaAtual) g_ottCruzVendaFIX272++;
   if(cruzSuporteCompraAtual || cruzPrecoCompraAtual) g_ottCruzCompraFIX272++;

   bool cruzSuporteVenda = false;
   bool cruzSuporteCompra = false;
   bool cruzPrecoVenda = false;
   bool cruzPrecoCompra = false;
   int shiftCruzVenda = -1;
   int shiftCruzCompra = -1;
   for(int c = shift; c < shift + janelaCruz; c++)
   {
      double supC = ValorSuporteOTTFIX271(c);
      double supP = ValorSuporteOTTFIX271(c + 1);
      double ottC = ValorLinhaOTTFIX271(c);
      double ottP = ValorLinhaOTTFIX271(c + 1);
      double clC = iClose(_Symbol, tf, c);
      double clP = iClose(_Symbol, tf, c + 1);
      if(supC <= 0.0 || supP <= 0.0 || ottC <= 0.0 || ottP <= 0.0 || clC <= 0.0 || clP <= 0.0)
         continue;

      bool sv = (supC < ottC && supP >= ottP);
      bool sc = (supC > ottC && supP <= ottP);
      bool pv = (clC < ottC && clP >= ottP);
      bool pc = (clC > ottC && clP <= ottP);
      if(!cruzSuporteVenda && sv) { cruzSuporteVenda = true; shiftCruzVenda = c; }
      if(!cruzSuporteCompra && sc) { cruzSuporteCompra = true; shiftCruzCompra = c; }
      if(!cruzPrecoVenda && pv) { cruzPrecoVenda = true; if(shiftCruzVenda < 0) shiftCruzVenda = c; }
      if(!cruzPrecoCompra && pc) { cruzPrecoCompra = true; if(shiftCruzCompra < 0) shiftCruzCompra = c; }
   }

   bool gatilhoOTTVenda = (InpContraOTTExigirCruzSuporteFIX271
                            ? cruzSuporteVenda
                            : (cruzSuporteVenda || (InpContraOTTAceitarCruzPrecoFIX271 && cruzPrecoVenda)));
   bool gatilhoOTTCompra = (InpContraOTTExigirCruzSuporteFIX271
                             ? cruzSuporteCompra
                             : (cruzSuporteCompra || (InpContraOTTAceitarCruzPrecoFIX271 && cruzPrecoCompra)));
   if(!gatilhoOTTVenda && !gatilhoOTTCompra)
      return false;

   double range0 = high0 - low0;
   if(range0 <= 0.0)
      return false;
   double corpo0 = MathAbs(close0 - open0) / range0;
   double corpoMin = MathMax(0.08, MathMin(0.80, MathAbs(InpContraOTTCorpoMinEntradaFIX271)));
   if(corpo0 < corpoMin)
      return false;

   double rsiArmarVenda = MathMax(50.0, MathMin(85.0, MathAbs(InpContraOTTRSIArmarVendaFIX271)));
   double rsiArmarCompra = MathMax(15.0, MathMin(50.0, MathAbs(InpContraOTTRSIArmarCompraFIX271)));
   double rsiDisparoVenda = MathMax(45.0, MathMin(rsiArmarVenda, MathAbs(InpContraOTTRSIDisparoVendaFIX271)));
   double rsiDisparoCompra = MathMin(55.0, MathMax(rsiArmarCompra, MathAbs(InpContraOTTRSIDisparoCompraFIX271)));
   double retornoMin = MathMax(0.5, MathMin(15.0, MathAbs(InpContraOTTRetornoMinimoFIX271)));
   double fiboMin = MathMax(0.50, MathMin(2.50, MathAbs(InpContraOTTFiboMinimoFIX271)));
   int scoreMin = InpContraOTTScoreSetupMinFIX271;
   if(scoreMin < 3) scoreMin = 3;
   if(scoreMin > 10) scoreMin = 10;

   int melhorScoreVenda = -1, melhorScoreCompra = -1;
   double melhorRSIVenda = -1.0, melhorRSICompra = 101.0;
   double melhorMaxVenda = 0.0, melhorMinCompra = 0.0;
   double melhorFiboVenda = 0.0, melhorFiboCompra = 0.0;
   double melhorRqVenda = 0.0, melhorRfVenda = 0.0;
   double melhorRqCompra = 0.0, melhorRfCompra = 0.0;

   for(int p = shift + 1; p <= shift + janelaPivo; p++)
   {
      double op = iOpen(_Symbol, tf, p);
      double hp = iHigh(_Symbol, tf, p);
      double lp = iLow(_Symbol, tf, p);
      double cp = iClose(_Symbol, tf, p);
      double rsiP = RSIHistoricoContraFIX261(p);
      double atrP = ATRManualContraFIX265(p, InpContraATRPeriodo);
      double suporteP = ValorSuporteOTTFIX271(p);
      if(op <= 0.0 || hp <= 0.0 || lp <= 0.0 || cp <= 0.0 || rsiP < 0.0 || atrP <= 0.0 || suporteP <= 0.0)
         continue;

      double maiorAnterior = -1.0e100;
      double menorAnterior = 1.0e100;
      for(int i = p + 1; i <= p + lookback; i++)
      {
         double h = iHigh(_Symbol, tf, i);
         double l = iLow(_Symbol, tf, i);
         if(h > maiorAnterior) maiorAnterior = h;
         if(l > 0.0 && l < menorAnterior) menorAnterior = l;
      }
      if(maiorAnterior <= -1.0e99 || menorAnterior >= 1.0e99)
         continue;

      double rangeP = hp - lp;
      if(rangeP <= 0.0) continue;
      double pavioSuperior = (hp - MathMax(op, cp)) / rangeP;
      double pavioInferior = (MathMin(op, cp) - lp) / rangeP;
      bool topo = (hp >= maiorAnterior);
      bool fundo = (lp <= menorAnterior);
      bool rsiTopo = (rsiP >= rsiArmarVenda);
      bool rsiFundo = (rsiP <= rsiArmarCompra);

      bool hiloCompra=false, hiloVenda=false, strCompra=false, strVenda=false;
      HiLoSTRHistoricoContraFIX261(p, hiloCompra, hiloVenda, strCompra, strVenda);
      bool impulsoTopo = (hiloCompra || strCompra);
      bool impulsoFundo = (hiloVenda || strVenda);

      double rq=0.0, rf=0.0;
      VolumeQtdFinHistoricoContraFIX261(p, rq, rf);
      double volumeMin = MathMax(0.90, InpContraVolumePivoMinimoFIX269);
      bool volumeForte = (rq >= volumeMin && rf >= volumeMin);
      double agrP = AgressaoCompradoraEstimadaContraFIX261(p);
      bool agressaoTopo = (agrP >= MathMax(52.0, InpContraAgressaoPivoMinimaFIX269));
      bool agressaoFundo = ((100.0 - agrP) >= MathMax(52.0, InpContraAgressaoPivoMinimaFIX269));
      bool distanciaTopo = ((hp - suporteP) >= atrP * 0.25);
      bool distanciaFundo = ((suporteP - lp) >= atrP * 0.25);
      bool rejeicaoTopo = (pavioSuperior >= 0.18 || cp < op);
      bool rejeicaoFundo = (pavioInferior >= 0.18 || cp > op);

      double nivelFiboVenda=0.0, extATRVenda=0.0, extEstrVenda=0.0;
      double nivelFiboCompra=0.0, extATRCompra=0.0, extEstrCompra=0.0;
      CalcularFiboExaustaoContraFIX269(p, LADO_VENDA, nivelFiboVenda, extATRVenda, extEstrVenda);
      CalcularFiboExaustaoContraFIX269(p, LADO_COMPRA, nivelFiboCompra, extATRCompra, extEstrCompra);
      double fiboVenda = MathMax(extATRVenda, extEstrVenda);
      double fiboCompra = MathMax(extATRCompra, extEstrCompra);
      bool fiboVendaOK = (fiboVenda >= fiboMin);
      bool fiboCompraOK = (fiboCompra >= fiboMin);

      int scoreVenda = 0;
      if(topo) scoreVenda += 2;
      if(rsiTopo) scoreVenda += 2;
      if(impulsoTopo) scoreVenda++;
      if(rejeicaoTopo) scoreVenda++;
      if(volumeForte) scoreVenda++;
      if(agressaoTopo) scoreVenda++;
      if(distanciaTopo) scoreVenda++;
      if(fiboVendaOK) scoreVenda++;

      int scoreCompra = 0;
      if(fundo) scoreCompra += 2;
      if(rsiFundo) scoreCompra += 2;
      if(impulsoFundo) scoreCompra++;
      if(rejeicaoFundo) scoreCompra++;
      if(volumeForte) scoreCompra++;
      if(agressaoFundo) scoreCompra++;
      if(distanciaFundo) scoreCompra++;
      if(fiboCompraOK) scoreCompra++;

      bool contextoVenda = (topo || rejeicaoTopo || fiboVendaOK || distanciaTopo);
      bool contextoCompra = (fundo || rejeicaoFundo || fiboCompraOK || distanciaFundo);
      bool setupVenda = rsiTopo && scoreVenda >= scoreMin &&
                        (InpContraOTTAceitarPivoFlexivelFIX272 ? contextoVenda : topo);
      bool setupCompra = rsiFundo && scoreCompra >= scoreMin &&
                         (InpContraOTTAceitarPivoFlexivelFIX272 ? contextoCompra : fundo);
      if(InpContraOTTFiboObrigatorioFIX271)
      {
         setupVenda = setupVenda && fiboVendaOK;
         setupCompra = setupCompra && fiboCompraOK;
      }

      if(setupVenda && scoreVenda > melhorScoreVenda)
      {
         melhorScoreVenda = scoreVenda;
         melhorRSIVenda = rsiP;
         melhorMaxVenda = hp;
         melhorFiboVenda = fiboVenda;
         melhorRqVenda = rq;
         melhorRfVenda = rf;
      }
      if(setupCompra && scoreCompra > melhorScoreCompra)
      {
         melhorScoreCompra = scoreCompra;
         melhorRSICompra = rsiP;
         melhorMinCompra = lp;
         melhorFiboCompra = fiboCompra;
         melhorRqCompra = rq;
         melhorRfCompra = rf;
      }
   }

   if(gatilhoOTTVenda && melhorScoreVenda >= scoreMin) g_ottSetupVendaFIX272++;
   if(gatilhoOTTCompra && melhorScoreCompra >= scoreMin) g_ottSetupCompraFIX272++;

   double posFechamento = (close0 - low0) / range0;
   bool candleVenda = (close0 < open0 && posFechamento <= 0.58);
   bool candleCompra = (close0 > open0 && posFechamento >= 0.42);
   bool rsiVendaOK = (melhorScoreVenda >= scoreMin && rsi <= rsiDisparoVenda && (melhorRSIVenda - rsi) >= retornoMin);
   bool rsiCompraOK = (melhorScoreCompra >= scoreMin && rsi >= rsiDisparoCompra && (rsi - melhorRSICompra) >= retornoMin);
   bool rompeVenda = (close0 < suporte0 || close0 < ott0 || close0 < iLow(_Symbol, tf, shift + 1));
   bool rompeCompra = (close0 > suporte0 || close0 > ott0 || close0 > iHigh(_Symbol, tf, shift + 1));
   bool semNovaMaxima = (melhorMaxVenda > 0.0 && high0 <= melhorMaxVenda + range0 * 0.25);
   bool semNovaMinima = (melhorMinCompra > 0.0 && low0 >= melhorMinCompra - range0 * 0.25);
   bool inclinacaoOTTVenda = (ott0 <= ott1);
   bool inclinacaoOTTCompra = (ott0 >= ott1);
   bool suporteCaindo = (suporte0 < suporte1);
   bool suporteSubindo = (suporte0 > suporte1);
   bool abaixoLinhas = (close0 < suporte0 || close0 < ott0);
   bool acimaLinhas = (close0 > suporte0 || close0 > ott0);
   double agrMin = MathMax(50.0, MathMin(100.0, MathAbs(InpContraOTTAgressaoEntradaFIX271)));
   bool agressaoVenda = ((100.0 - agrCompra) >= agrMin);
   bool agressaoCompra = (agrCompra >= agrMin);
   double rqAtual=0.0, rfAtual=0.0;
   bool volumeAtual = VolumeQtdFinHistoricoContraFIX261(shift, rqAtual, rfAtual);

   int extrasVenda = 0;
   if(agressaoVenda) extrasVenda++;
   if(inclinacaoOTTVenda) extrasVenda++;
   if(abaixoLinhas) extrasVenda++;
   if(semNovaMaxima) extrasVenda++;
   if(volumeAtual) extrasVenda++;
   if(suporteCaindo) extrasVenda++;
   if(cruzPrecoVendaAtual || cruzSuporteVendaAtual) extrasVenda++;

   int extrasCompra = 0;
   if(agressaoCompra) extrasCompra++;
   if(inclinacaoOTTCompra) extrasCompra++;
   if(acimaLinhas) extrasCompra++;
   if(semNovaMinima) extrasCompra++;
   if(volumeAtual) extrasCompra++;
   if(suporteSubindo) extrasCompra++;
   if(cruzPrecoCompraAtual || cruzSuporteCompraAtual) extrasCompra++;

   int extrasMin = InpContraOTTExtrasEntradaMinFIX271;
   if(extrasMin < 1) extrasMin = 1;
   if(extrasMin > 7) extrasMin = 7;

   bool vendaValida = (gatilhoOTTVenda && melhorScoreVenda >= scoreMin && candleVenda && rsiVendaOK && rompeVenda && extrasVenda >= extrasMin);
   bool compraValida = (gatilhoOTTCompra && melhorScoreCompra >= scoreMin && candleCompra && rsiCompraOK && rompeCompra && extrasCompra >= extrasMin);
   int qualidadeVenda = melhorScoreVenda + extrasVenda + (gatilhoOTTVenda ? 2 : 0) + (rsiVendaOK ? 1 : 0);
   int qualidadeCompra = melhorScoreCompra + extrasCompra + (gatilhoOTTCompra ? 2 : 0) + (rsiCompraOK ? 1 : 0);
   confirmacoes = MathMax(qualidadeVenda, qualidadeCompra);

   if(vendaValida && qualidadeVenda >= qualidadeCompra && !ExisteSinalRecenteContraFIX265(shift, LADO_VENDA))
   {
      ladoContra = LADO_VENDA;
      ratioQtd = MathMax(melhorRqVenda, rqAtual);
      ratioFin = MathMax(melhorRfVenda, rfAtual);
      g_ultimoFiboNivelSinalFIX269 = melhorFiboVenda;
      g_textoEtiquetaContraFIX271 = "VOTT";
      g_ultimoOTTSuporteSinalFIX271 = suporte0;
      g_ultimoOTTLinhaSinalFIX271 = ott0;
      return true;
   }
   if(compraValida && !ExisteSinalRecenteContraFIX265(shift, LADO_COMPRA))
   {
      ladoContra = LADO_COMPRA;
      ratioQtd = MathMax(melhorRqCompra, rqAtual);
      ratioFin = MathMax(melhorRfCompra, rfAtual);
      g_ultimoFiboNivelSinalFIX269 = melhorFiboCompra;
      g_textoEtiquetaContraFIX271 = "COTT";
      g_ultimoOTTSuporteSinalFIX271 = suporte0;
      g_ultimoOTTLinhaSinalFIX271 = ott0;
      return true;
   }
   return false;
}

// FIX273: calcula a caixa usando somente candles MAIS ANTIGOS que a barra analisada.
// Assim, nenhuma barra futura participa do sinal historico.

// ============================================================================
// RESPONSABILIDADE: SINAIS DARVAS FIBO CRUZAMENTO E CIRURGICO
// ============================================================================

bool CalcularCaixaDarvasFIX273(int shiftReferencia,
                               int periodo,
                               double &topo,
                               double &fundo)
{
   topo = -1.0e100;
   fundo = 1.0e100;
   if(shiftReferencia < 0)
      return false;
   if(periodo < 5) periodo = 5;
   if(periodo > 120) periodo = 120;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   int barras = Bars(_Symbol, tf);
   if(shiftReferencia + periodo + 2 >= barras)
      return false;

   for(int i = shiftReferencia + 1; i <= shiftReferencia + periodo; i++)
   {
      double h = iHigh(_Symbol, tf, i);
      double l = iLow(_Symbol, tf, i);
      if(h <= 0.0 || l <= 0.0)
         return false;
      if(h > topo) topo = h;
      if(l < fundo) fundo = l;
   }
   return (topo > fundo && topo < 1.0e99 && fundo > 0.0);
}

string PrefixoDarvasFIX273()
{
   return "DARVAS273_VIS_";
}

void ConfigurarSegmentoDarvasFIX273(string nome,
                                    datetime t1,
                                    double p1,
                                    datetime t2,
                                    double p2,
                                    color cor,
                                    int largura,
                                    ENUM_LINE_STYLE estilo)
{
   if(t1 <= 0 || t2 <= 0 || p1 <= 0.0 || p2 <= 0.0)
      return;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_TREND, 0, t1, p1, t2, p2))
         return;
   }
   else
   {
      ObjectMove(0, nome, 0, t1, p1);
      ObjectMove(0, nome, 1, t2, p2);
   }
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, largura);
   ObjectSetInteger(0, nome, OBJPROP_STYLE, estilo);
   ObjectSetInteger(0, nome, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nome, OBJPROP_BACK, true);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

void LimparCaixasDarvasFIX273()
{
   string prefixo = PrefixoDarvasFIX273();
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, prefixo) == 0)
         ObjectDelete(0, nome);
   }
}

void PlotarCaixasDarvasFIX273()
{
   if(InpFIX280RemoverLinhasDarvas || !InpContraUsarDarvasFIX273 || !InpContraDarvasPlotarCaixasFIX273)
   {
      LimparCaixasDarvasFIX273();
      return;
   }

   int barras = InpContraDarvasBarrasVisuaisFIX273;
   if(barras < 40) barras = 40;
   if(barras > 1000) barras = 1000;
   int periodo = InpContraDarvasPeriodoFIX273;
   if(periodo < 5) periodo = 5;
   if(periodo > 120) periodo = 120;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   int disponiveis = Bars(_Symbol, tf);
   barras = (int)MathMin(barras, disponiveis - periodo - 5);
   if(barras < 3)
      return;

   datetime corte = iTime(_Symbol, tf, barras + 1);
   string prefixo = PrefixoDarvasFIX273();
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, prefixo) != 0)
         continue;
      datetime tempoObjeto = (datetime)ObjectGetInteger(0, nome, OBJPROP_TIME, 0);
      if(tempoObjeto > 0 && corte > 0 && tempoObjeto < corte)
         ObjectDelete(0, nome);
   }

   for(int s = barras; s >= 2; s--)
   {
      double topo1=0.0, fundo1=0.0, topo2=0.0, fundo2=0.0;
      if(!CalcularCaixaDarvasFIX273(s, periodo, topo1, fundo1))
         continue;
      if(!CalcularCaixaDarvasFIX273(s - 1, periodo, topo2, fundo2))
         continue;
      datetime t1 = iTime(_Symbol, tf, s);
      datetime t2 = iTime(_Symbol, tf, s - 1);
      string chave = IntegerToString((int)t1);
      ConfigurarSegmentoDarvasFIX273(prefixo + "TOP_" + chave, t1, topo1, t2, topo2,
                                    InpContraDarvasCorTopoFIX273, 2, STYLE_SOLID);
      ConfigurarSegmentoDarvasFIX273(prefixo + "BOT_" + chave, t1, fundo1, t2, fundo2,
                                    InpContraDarvasCorFundoFIX273, 2, STYLE_SOLID);
      if(InpContraDarvasPlotarMeioFIX273)
      {
         double meio1 = (topo1 + fundo1) * 0.5;
         double meio2 = (topo2 + fundo2) * 0.5;
         ConfigurarSegmentoDarvasFIX273(prefixo + "MID_" + chave, t1, meio1, t2, meio2,
                                       InpContraDarvasCorMeioFIX273, 1, STYLE_DOT);
      }
   }
}

// FIX273: entrada contra somente depois de um FALSO ROMPIMENTO.
// Venda: ultrapassa o topo e fecha novamente dentro da caixa.
// Compra: ultrapassa o fundo e fecha novamente dentro da caixa.
bool AvaliarCandleContraDarvasFIX273(int shift,
                                     ENUM_LADO_ROBO &ladoContra,
                                     double &rsi,
                                     double &agrCompra,
                                     double &ratioQtd,
                                     double &ratioFin,
                                     int &confirmacoes)
{
   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   ratioQtd = 0.0;
   ratioFin = 0.0;
   g_ultimoFiboNivelSinalFIX269 = 0.0;
   g_textoEtiquetaContraFIX271 = "";
   if(shift < 1)
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double open0 = iOpen(_Symbol, tf, shift);
   double high0 = iHigh(_Symbol, tf, shift);
   double low0 = iLow(_Symbol, tf, shift);
   double close0 = iClose(_Symbol, tf, shift);
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 || rsi < 0.0)
      return false;
   double range0 = high0 - low0;
   if(range0 <= 0.0)
      return false;

   int periodo = InpContraDarvasPeriodoFIX273;
   if(periodo < 5) periodo = 5;
   if(periodo > 120) periodo = 120;
   int janela = InpContraDarvasJanelaConfirmacaoFIX273;
   if(janela < 1) janela = 1;
   if(janela > 6) janela = 6;

   double corpo0 = MathAbs(close0 - open0) / range0;
   double corpoMin = MathMax(0.08, MathMin(0.80, MathAbs(InpContraDarvasCorpoMinFIX273)));
   double pavioMin = MathMax(0.05, MathMin(0.80, MathAbs(InpContraDarvasPavioMinFIX273)));
   double rsiVendaExt = MathMax(55.0, MathMin(90.0, MathAbs(InpContraDarvasRSIVendaFIX273)));
   double rsiCompraExt = MathMax(10.0, MathMin(45.0, MathAbs(InpContraDarvasRSICompraFIX273)));
   double rsiRetVenda = MathMax(45.0, MathMin(rsiVendaExt, MathAbs(InpContraDarvasRSIRetornoVendaFIX273)));
   double rsiRetCompra = MathMin(55.0, MathMax(rsiCompraExt, MathAbs(InpContraDarvasRSIRetornoCompraFIX273)));
   double agrMin = MathMax(50.0, MathMin(100.0, MathAbs(InpContraDarvasAgressaoEntradaFIX273)));
   double volumeMin = MathMax(0.50, MathMin(3.00, MathAbs(InpContraDarvasVolumeMinFIX273)));
   double alturaMinATR = MathMax(0.10, MathMin(10.0, MathAbs(InpContraDarvasAlturaMinATR_FIX273)));
   double bufferATR = MathMax(0.0, MathMin(1.0, MathAbs(InpContraDarvasBufferATR_FIX273)));

   bool candleVenda = (close0 < open0 && corpo0 >= corpoMin);
   bool candleCompra = (close0 > open0 && corpo0 >= corpoMin);
   double posFechamento = (close0 - low0) / range0;
   candleVenda = candleVenda && (posFechamento <= 0.62);
   candleCompra = candleCompra && (posFechamento >= 0.38);

   double rqAtual=0.0, rfAtual=0.0;
   VolumeQtdFinHistoricoContraFIX261(shift, rqAtual, rfAtual);
   bool volumeAtual = (rqAtual >= volumeMin && rfAtual >= volumeMin);
   ratioQtd = rqAtual;
   ratioFin = rfAtual;

   int micro = InpContraDarvasMicroestruturaFIX273;
   if(micro < 1) micro = 1;
   if(micro > 6) micro = 6;
   double menorMicro = 1.0e100;
   double maiorMicro = -1.0e100;
   for(int m = shift + 1; m <= shift + micro; m++)
   {
      double lm = iLow(_Symbol, tf, m);
      double hm = iHigh(_Symbol, tf, m);
      if(lm > 0.0 && lm < menorMicro) menorMicro = lm;
      if(hm > maiorMicro) maiorMicro = hm;
   }
   bool rompeMicroVenda = (menorMicro < 1.0e99 && close0 < menorMicro);
   bool rompeMicroCompra = (maiorMicro > -1.0e99 && close0 > maiorMicro);

   bool ottVenda = false;
   bool ottCompra = false;
   if(InpContraDarvasUsarOTTConfirmacaoFIX273 && PrepararCacheOTTFIX271(shift + janela + 50))
   {
      double ott0 = ValorLinhaOTTFIX271(shift);
      double ott1 = ValorLinhaOTTFIX271(shift + 1);
      if(ott0 > 0.0 && ott1 > 0.0)
      {
         ottVenda = (close0 < ott0 || ott0 < ott1);
         ottCompra = (close0 > ott0 || ott0 > ott1);
      }
   }

   int melhorVenda = -1;
   int melhorCompra = -1;
   double melhorTopo = 0.0, melhorFundo = 0.0;
   double melhorFiboVenda = 0.0, melhorFiboCompra = 0.0;
   bool achouFalsoVenda = false;
   bool achouFalsoCompra = false;

   for(int b = shift; b <= shift + janela; b++)
   {
      double topo=0.0, fundo=0.0;
      if(!CalcularCaixaDarvasFIX273(b, periodo, topo, fundo))
         continue;
      double atrB = ATRManualContraFIX265(b, InpContraATRPeriodo);
      if(atrB <= 0.0 || (topo - fundo) < atrB * alturaMinATR)
         continue;
      double margem = atrB * bufferATR;
      double ob = iOpen(_Symbol, tf, b);
      double hb = iHigh(_Symbol, tf, b);
      double lb = iLow(_Symbol, tf, b);
      double cb = iClose(_Symbol, tf, b);
      if(ob <= 0.0 || hb <= 0.0 || lb <= 0.0 || cb <= 0.0)
         continue;
      double rangeB = hb - lb;
      if(rangeB <= 0.0)
         continue;

      bool rompeTopo = (hb > topo + margem);
      bool rompeFundo = (lb < fundo - margem);
      bool voltouDentroVenda = (close0 < topo && close0 > fundo);
      bool voltouDentroCompra = (close0 > fundo && close0 < topo);
      bool falsoVenda = (rompeTopo && voltouDentroVenda);
      bool falsoCompra = (rompeFundo && voltouDentroCompra);
      if(!falsoVenda && !falsoCompra)
         continue;

      double rsiExtMax = -1.0;
      double rsiExtMin = 101.0;
      for(int rr = b; rr <= b + 2; rr++)
      {
         double rv = RSIHistoricoContraFIX261(rr);
         if(rv < 0.0) continue;
         if(rv > rsiExtMax) rsiExtMax = rv;
         if(rv < rsiExtMin) rsiExtMin = rv;
      }
      bool rsiVendaOK = (rsiExtMax >= rsiVendaExt && rsi <= rsiRetVenda);
      bool rsiCompraOK = (rsiExtMin <= rsiCompraExt && rsi >= rsiRetCompra);

      double pavioSuperior = (hb - MathMax(ob, cb)) / rangeB;
      double pavioInferior = (MathMin(ob, cb) - lb) / rangeB;
      bool rejeicaoVenda = (pavioSuperior >= pavioMin || cb < topo);
      bool rejeicaoCompra = (pavioInferior >= pavioMin || cb > fundo);

      bool hiloCompra=false, hiloVenda=false, strCompra=false, strVenda=false;
      HiLoSTRHistoricoContraFIX261(b, hiloCompra, hiloVenda, strCompra, strVenda);
      bool impulsoTopo = (hiloCompra || strCompra);
      bool impulsoFundo = (hiloVenda || strVenda);

      double rqB=0.0, rfB=0.0;
      VolumeQtdFinHistoricoContraFIX261(b, rqB, rfB);
      bool volumeB = (rqB >= volumeMin && rfB >= volumeMin);
      double agrB = AgressaoCompradoraEstimadaContraFIX261(b);
      bool agressaoExtTopo = (agrB >= 55.0);
      bool agressaoExtFundo = ((100.0 - agrB) >= 55.0);
      bool agressaoReversaoVenda = ((100.0 - agrCompra) >= agrMin);
      bool agressaoReversaoCompra = (agrCompra >= agrMin);

      double nivelFiboVenda=0.0, extATRVenda=0.0, extEstrVenda=0.0;
      double nivelFiboCompra=0.0, extATRCompra=0.0, extEstrCompra=0.0;
      CalcularFiboExaustaoContraFIX269(b, LADO_VENDA, nivelFiboVenda, extATRVenda, extEstrVenda);
      CalcularFiboExaustaoContraFIX269(b, LADO_COMPRA, nivelFiboCompra, extATRCompra, extEstrCompra);
      double fiboVenda = MathMax(extATRVenda, extEstrVenda);
      double fiboCompra = MathMax(extATRCompra, extEstrCompra);
      bool fiboVendaOK = (fiboVenda >= 0.786);
      bool fiboCompraOK = (fiboCompra >= 0.786);

      int extrasVenda = 0;
      if(volumeAtual || volumeB) extrasVenda++;
      if(agressaoReversaoVenda) extrasVenda++;
      if(rompeMicroVenda) extrasVenda++;
      if(ottVenda) extrasVenda++;
      if(fiboVendaOK) extrasVenda++;
      if(impulsoTopo || agressaoExtTopo) extrasVenda++;
      if(rejeicaoVenda) extrasVenda++;

      int extrasCompra = 0;
      if(volumeAtual || volumeB) extrasCompra++;
      if(agressaoReversaoCompra) extrasCompra++;
      if(rompeMicroCompra) extrasCompra++;
      if(ottCompra) extrasCompra++;
      if(fiboCompraOK) extrasCompra++;
      if(impulsoFundo || agressaoExtFundo) extrasCompra++;
      if(rejeicaoCompra) extrasCompra++;

      if(InpContraDarvasExigirOTT_FIX273)
      {
         falsoVenda = falsoVenda && ottVenda;
         falsoCompra = falsoCompra && ottCompra;
      }

      int qualidadeVenda = extrasVenda + (rsiVendaOK ? 3 : 0) + (candleVenda ? 2 : 0) + (falsoVenda ? 3 : 0);
      int qualidadeCompra = extrasCompra + (rsiCompraOK ? 3 : 0) + (candleCompra ? 2 : 0) + (falsoCompra ? 3 : 0);

      if(falsoVenda)
      {
         achouFalsoVenda = true;
         if(rsiVendaOK && candleVenda && qualidadeVenda > melhorVenda)
         {
            melhorVenda = qualidadeVenda;
            melhorTopo = topo;
            melhorFundo = fundo;
            melhorFiboVenda = fiboVenda;
            ratioQtd = MathMax(ratioQtd, rqB);
            ratioFin = MathMax(ratioFin, rfB);
         }
      }
      if(falsoCompra)
      {
         achouFalsoCompra = true;
         if(rsiCompraOK && candleCompra && qualidadeCompra > melhorCompra)
         {
            melhorCompra = qualidadeCompra;
            melhorTopo = topo;
            melhorFundo = fundo;
            melhorFiboCompra = fiboCompra;
            ratioQtd = MathMax(ratioQtd, rqB);
            ratioFin = MathMax(ratioFin, rfB);
         }
      }
   }

   if(achouFalsoVenda) g_darvasFalsoVendaFIX273++;
   if(achouFalsoCompra) g_darvasFalsoCompraFIX273++;
   int extrasMin = InpContraDarvasExtrasMinFIX273;
   if(extrasMin < 0) extrasMin = 0;
   if(extrasMin > 7) extrasMin = 7;
   int minimoQualidade = 8 + extrasMin;
   if(melhorVenda >= minimoQualidade) g_darvasSetupVendaFIX273++;
   if(melhorCompra >= minimoQualidade) g_darvasSetupCompraFIX273++;
   confirmacoes = MathMax(melhorVenda, melhorCompra);

   if(melhorVenda >= minimoQualidade && melhorVenda >= melhorCompra &&
      !ExisteSinalRecenteContraFIX265(shift, LADO_VENDA))
   {
      ladoContra = LADO_VENDA;
      g_ultimoDarvasTopoFIX273 = melhorTopo;
      g_ultimoDarvasFundoFIX273 = melhorFundo;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboVenda;
      g_textoEtiquetaContraFIX271 = "VDB";
      return true;
   }
   if(melhorCompra >= minimoQualidade &&
      !ExisteSinalRecenteContraFIX265(shift, LADO_COMPRA))
   {
      ladoContra = LADO_COMPRA;
      g_ultimoDarvasTopoFIX273 = melhorTopo;
      g_ultimoDarvasFundoFIX273 = melhorFundo;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboCompra;
      g_textoEtiquetaContraFIX271 = "CDB";
      return true;
   }
   return false;
}

// FIX270: o pivo ARMA a oportunidade, mas somente o cruzamento real 5x13 confirma a entrada.
// A funcao usa apenas candles fechados. O pivo precisa estar ANTES do candle pintado.
bool AvaliarCandleContraCruzamentoFIX270(int shift,
                                         ENUM_LADO_ROBO &ladoContra,
                                         double &rsi,
                                         double &agrCompra,
                                         double &ratioQtd,
                                         double &ratioFin,
                                         int &confirmacoes)
{
   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   g_ultimoFiboNivelSinalFIX269 = 0.0;
   ratioQtd = 0.0;
   ratioFin = 0.0;
   if(shift < 1)
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double open0 = iOpen(_Symbol, tf, shift);
   double high0 = iHigh(_Symbol, tf, shift);
   double low0 = iLow(_Symbol, tf, shift);
   double close0 = iClose(_Symbol, tf, shift);
   double close1 = iClose(_Symbol, tf, shift + 1);
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 || close1 <= 0.0 || rsi < 0.0)
      return false;

   double range0 = high0 - low0;
   if(range0 <= 0.0)
      return false;
   double corpo0 = MathAbs(close0 - open0) / range0;
   double corpoMin = MathMax(0.10, MathMin(0.90, MathAbs(InpContraCorpoMinEntradaFIX270)));
   if(corpo0 < corpoMin)
      return false;

   int rapida = InpContraMediaRapidaFIX270;
   int lenta = InpContraMediaLentaFIX270;
   int contexto = InpContraMediaContextoFIX270;
   if(rapida < 2) rapida = 2;
   if(rapida > 50) rapida = 50;
   if(lenta <= rapida) lenta = rapida + 3;
   if(lenta > 100) lenta = 100;
   if(contexto <= lenta) contexto = lenta + 8;
   if(contexto > 150) contexto = 150;

   int janelaCruz = InpContraJanelaCruzamentoFIX270;
   if(janelaCruz < 1) janelaCruz = 1;
   if(janelaCruz > 3) janelaCruz = 3;

   bool cruzouVenda = false;
   bool cruzouCompra = false;
   int shiftCruzVenda = -1;
   int shiftCruzCompra = -1;
   for(int k = shift; k < shift + janelaCruz; k++)
   {
      double rapidaK = MediaFechamentoIncluindoAtualContraFIX266(k, rapida);
      double lentaK = MediaFechamentoIncluindoAtualContraFIX266(k, lenta);
      double rapidaAnterior = MediaFechamentoIncluindoAtualContraFIX266(k + 1, rapida);
      double lentaAnterior = MediaFechamentoIncluindoAtualContraFIX266(k + 1, lenta);
      if(rapidaK <= 0.0 || lentaK <= 0.0 || rapidaAnterior <= 0.0 || lentaAnterior <= 0.0)
         continue;
      if(!cruzouVenda && rapidaK < lentaK && rapidaAnterior >= lentaAnterior)
      {
         cruzouVenda = true;
         shiftCruzVenda = k;
      }
      if(!cruzouCompra && rapidaK > lentaK && rapidaAnterior <= lentaAnterior)
      {
         cruzouCompra = true;
         shiftCruzCompra = k;
      }
   }
   if(!cruzouVenda && !cruzouCompra)
      return false;

   double maRapida0 = MediaFechamentoIncluindoAtualContraFIX266(shift, rapida);
   double maLenta0 = MediaFechamentoIncluindoAtualContraFIX266(shift, lenta);
   double maLenta1 = MediaFechamentoIncluindoAtualContraFIX266(shift + 1, lenta);
   double maContexto0 = MediaFechamentoIncluindoAtualContraFIX266(shift, contexto);
   double maContexto1 = MediaFechamentoIncluindoAtualContraFIX266(shift + 1, contexto);
   double atr0 = ATRManualContraFIX265(shift, InpContraATRPeriodo);
   if(maRapida0 <= 0.0 || maLenta0 <= 0.0 || maLenta1 <= 0.0 || maContexto0 <= 0.0 || maContexto1 <= 0.0 || atr0 <= 0.0)
      return false;

   int janelaPivo = InpContraJanelaPivoFIX270;
   if(janelaPivo < 2) janelaPivo = 2;
   if(janelaPivo > 12) janelaPivo = 12;
   int lookback = InpContraLookbackPivoFIX270;
   if(lookback < 4) lookback = 4;
   if(lookback > 30) lookback = 30;

   double rsiArmarVenda = MathMax(50.0, MathMin(85.0, MathAbs(InpContraRSIArmarVendaFIX270)));
   double rsiArmarCompra = MathMax(15.0, MathMin(50.0, MathAbs(InpContraRSIArmarCompraFIX270)));
   double rsiDisparoVenda = MathMax(45.0, MathMin(rsiArmarVenda, MathAbs(InpContraRSIDisparoVendaFIX270)));
   double rsiDisparoCompra = MathMin(55.0, MathMax(rsiArmarCompra, MathAbs(InpContraRSIDisparoCompraFIX270)));
   double retornoMin = MathMax(1.0, MathMin(20.0, MathAbs(InpContraRetornoRSIMinFIX270)));
   double fiboMin = MathMax(0.50, MathMin(2.50, MathAbs(InpContraFiboMinimoFIX270)));
   int setupMin = InpContraScoreSetupMinFIX270;
   if(setupMin < 4) setupMin = 4;
   if(setupMin > 12) setupMin = 12;

   int melhorSetupVenda = -1;
   int melhorSetupCompra = -1;
   int melhorPivoVenda = -1;
   int melhorPivoCompra = -1;
   double melhorFiboVenda = 0.0;
   double melhorFiboCompra = 0.0;
   double melhorRSIVenda = -1.0;
   double melhorRSICompra = 101.0;
   double melhorMaxVenda = 0.0;
   double melhorMinCompra = 0.0;
   double melhorRqVenda = 0.0, melhorRfVenda = 0.0;
   double melhorRqCompra = 0.0, melhorRfCompra = 0.0;

   // O pivo comeca em shift+1: nunca usamos o proprio candle de entrada como topo/fundo.
   for(int p = shift + 1; p <= shift + janelaPivo; p++)
   {
      double op = iOpen(_Symbol, tf, p);
      double hp = iHigh(_Symbol, tf, p);
      double lp = iLow(_Symbol, tf, p);
      double cp = iClose(_Symbol, tf, p);
      double rsiP = RSIHistoricoContraFIX261(p);
      double atrP = ATRManualContraFIX265(p, InpContraATRPeriodo);
      double maLentaP = MediaFechamentoIncluindoAtualContraFIX266(p, lenta);
      if(op <= 0.0 || hp <= 0.0 || lp <= 0.0 || cp <= 0.0 || rsiP < 0.0 || atrP <= 0.0 || maLentaP <= 0.0)
         continue;

      double maiorAnterior = -1.0e100;
      double menorAnterior = 1.0e100;
      for(int i = p + 1; i <= p + lookback; i++)
      {
         double h = iHigh(_Symbol, tf, i);
         double l = iLow(_Symbol, tf, i);
         if(h > maiorAnterior) maiorAnterior = h;
         if(l > 0.0 && l < menorAnterior) menorAnterior = l;
      }
      if(maiorAnterior <= -1.0e99 || menorAnterior >= 1.0e99)
         continue;

      double rangeP = hp - lp;
      if(rangeP <= 0.0)
         continue;
      double pavioSuperior = (hp - MathMax(op, cp)) / rangeP;
      double pavioInferior = (MathMin(op, cp) - lp) / rangeP;
      bool topoLocal = (hp >= maiorAnterior);
      bool fundoLocal = (lp <= menorAnterior);
      bool rsiTopo = (rsiP >= rsiArmarVenda);
      bool rsiFundo = (rsiP <= rsiArmarCompra);

      bool hiloCompra=false, hiloVenda=false, strCompra=false, strVenda=false;
      HiLoSTRHistoricoContraFIX261(p, hiloCompra, hiloVenda, strCompra, strVenda);
      bool impulsoTopo = (hiloCompra || strCompra);
      bool impulsoFundo = (hiloVenda || strVenda);

      double rq = 0.0, rf = 0.0;
      VolumeQtdFinHistoricoContraFIX261(p, rq, rf);
      bool volumeForte = (rq >= InpContraVolumePivoMinimoFIX269 && rf >= InpContraVolumePivoMinimoFIX269);
      double agrP = AgressaoCompradoraEstimadaContraFIX261(p);
      bool agressaoTopo = (agrP >= MathMax(50.0, InpContraAgressaoPivoMinimaFIX269));
      bool agressaoFundo = ((100.0 - agrP) >= MathMax(50.0, InpContraAgressaoPivoMinimaFIX269));
      bool distanciaTopo = ((hp - maLentaP) >= atrP * MathMax(0.10, InpContraDistanciaPivoATR_FIX269));
      bool distanciaFundo = ((maLentaP - lp) >= atrP * MathMax(0.10, InpContraDistanciaPivoATR_FIX269));
      bool rejeicaoTopo = (pavioSuperior >= MathMax(0.10, InpContraPavioMinimoPivoFIX269) || cp < op);
      bool rejeicaoFundo = (pavioInferior >= MathMax(0.10, InpContraPavioMinimoPivoFIX269) || cp > op);

      double nivelFiboVenda=0.0, extATRVenda=0.0, extEstrVenda=0.0;
      double nivelFiboCompra=0.0, extATRCompra=0.0, extEstrCompra=0.0;
      CalcularFiboExaustaoContraFIX269(p, LADO_VENDA, nivelFiboVenda, extATRVenda, extEstrVenda);
      CalcularFiboExaustaoContraFIX269(p, LADO_COMPRA, nivelFiboCompra, extATRCompra, extEstrCompra);
      double fiboVenda = MathMax(extATRVenda, extEstrVenda);
      double fiboCompra = MathMax(extATRCompra, extEstrCompra);
      bool fiboVendaOK = (fiboVenda >= fiboMin);
      bool fiboCompraOK = (fiboCompra >= fiboMin);

      int scoreVenda = 0;
      if(topoLocal) scoreVenda += 2;
      if(rsiTopo) scoreVenda += 2;
      if(impulsoTopo) scoreVenda++;
      if(rejeicaoTopo) scoreVenda++;
      if(volumeForte) scoreVenda++;
      if(agressaoTopo) scoreVenda++;
      if(distanciaTopo) scoreVenda++;
      if(fiboVendaOK) scoreVenda++;
      if(fiboVenda >= MathAbs(InpContraFiboNivelMinimo)) scoreVenda++;

      int scoreCompra = 0;
      if(fundoLocal) scoreCompra += 2;
      if(rsiFundo) scoreCompra += 2;
      if(impulsoFundo) scoreCompra++;
      if(rejeicaoFundo) scoreCompra++;
      if(volumeForte) scoreCompra++;
      if(agressaoFundo) scoreCompra++;
      if(distanciaFundo) scoreCompra++;
      if(fiboCompraOK) scoreCompra++;
      if(fiboCompra >= MathAbs(InpContraFiboNivelMinimo)) scoreCompra++;

      bool setupVendaOK = topoLocal && rsiTopo && impulsoTopo && scoreVenda >= setupMin;
      bool setupCompraOK = fundoLocal && rsiFundo && impulsoFundo && scoreCompra >= setupMin;
      if(InpContraFiboObrigatorioFIX270)
      {
         setupVendaOK = setupVendaOK && fiboVendaOK;
         setupCompraOK = setupCompraOK && fiboCompraOK;
      }

      if(setupVendaOK && scoreVenda > melhorSetupVenda)
      {
         melhorSetupVenda = scoreVenda;
         melhorPivoVenda = p;
         melhorFiboVenda = fiboVenda;
         melhorRSIVenda = rsiP;
         melhorMaxVenda = hp;
         melhorRqVenda = rq;
         melhorRfVenda = rf;
      }
      if(setupCompraOK && scoreCompra > melhorSetupCompra)
      {
         melhorSetupCompra = scoreCompra;
         melhorPivoCompra = p;
         melhorFiboCompra = fiboCompra;
         melhorRSICompra = rsiP;
         melhorMinCompra = lp;
         melhorRqCompra = rq;
         melhorRfCompra = rf;
      }
   }

   double posFechamento = (close0 - low0) / range0;
   double zona = MathMax(0.20, MathMin(0.49, MathAbs(InpContraFechamentoExtremoFIX270)));
   bool candleVenda = (close0 < open0 && close0 < close1 && posFechamento <= zona);
   bool candleCompra = (close0 > open0 && close0 > close1 && posFechamento >= (1.0 - zona));

   int micro = InpContraMicroestruturaFIX270;
   if(micro < 1) micro = 1;
   if(micro > 5) micro = 5;
   double menorMicro = 1.0e100;
   double maiorMicro = -1.0e100;
   for(int i = shift + 1; i <= shift + micro; i++)
   {
      double l = iLow(_Symbol, tf, i);
      double h = iHigh(_Symbol, tf, i);
      if(l > 0.0 && l < menorMicro) menorMicro = l;
      if(h > maiorMicro) maiorMicro = h;
   }
   bool rompeVenda = (menorMicro < 1.0e99 && close0 < menorMicro);
   bool rompeCompra = (maiorMicro > -1.0e99 && close0 > maiorMicro);

   bool inclinacaoVenda = (maLenta0 < maLenta1);
   bool inclinacaoCompra = (maLenta0 > maLenta1);
   bool abaixoLenta = (close0 < maLenta0 && maRapida0 < maLenta0);
   bool acimaLenta = (close0 > maLenta0 && maRapida0 > maLenta0);
   bool contextoVenda = (close0 < maContexto0 || maContexto0 <= maContexto1 || melhorFiboVenda >= MathAbs(InpContraFiboNivelMinimo));
   bool contextoCompra = (close0 > maContexto0 || maContexto0 >= maContexto1 || melhorFiboCompra >= MathAbs(InpContraFiboNivelMinimo));
   double agrMinEntrada = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoEntradaFIX270)));
   bool agressaoVenda = ((100.0 - agrCompra) >= agrMinEntrada);
   bool agressaoCompra = (agrCompra >= agrMinEntrada);
   bool rsiVendaOK = (melhorPivoVenda > 0 && rsi <= rsiDisparoVenda && (melhorRSIVenda - rsi) >= retornoMin);
   bool rsiCompraOK = (melhorPivoCompra > 0 && rsi >= rsiDisparoCompra && (rsi - melhorRSICompra) >= retornoMin);
   bool semNovaMaxima = (melhorPivoVenda > 0 && high0 <= melhorMaxVenda + atr0 * 0.10);
   bool semNovaMinima = (melhorPivoCompra > 0 && low0 >= melhorMinCompra - atr0 * 0.10);

   int extrasVenda = 0;
   if(inclinacaoVenda) extrasVenda++;
   if(abaixoLenta) extrasVenda++;
   if(agressaoVenda) extrasVenda++;
   if(contextoVenda) extrasVenda++;
   if(semNovaMaxima) extrasVenda++;

   int extrasCompra = 0;
   if(inclinacaoCompra) extrasCompra++;
   if(acimaLenta) extrasCompra++;
   if(agressaoCompra) extrasCompra++;
   if(contextoCompra) extrasCompra++;
   if(semNovaMinima) extrasCompra++;

   int extrasMin = InpContraExtrasEntradaMinFIX270;
   if(extrasMin < 1) extrasMin = 1;
   if(extrasMin > 5) extrasMin = 5;

   bool vendaValida = (melhorSetupVenda >= setupMin && cruzouVenda && shiftCruzVenda >= shift &&
                        candleVenda && rompeVenda && rsiVendaOK && extrasVenda >= extrasMin);
   bool compraValida = (melhorSetupCompra >= setupMin && cruzouCompra && shiftCruzCompra >= shift &&
                         candleCompra && rompeCompra && rsiCompraOK && extrasCompra >= extrasMin);
   if(InpContraExigirInclinacaoLentaFIX270)
   {
      vendaValida = vendaValida && inclinacaoVenda;
      compraValida = compraValida && inclinacaoCompra;
   }

   int qualidadeVenda = melhorSetupVenda + extrasVenda + (cruzouVenda ? 2 : 0) + (rompeVenda ? 1 : 0);
   int qualidadeCompra = melhorSetupCompra + extrasCompra + (cruzouCompra ? 2 : 0) + (rompeCompra ? 1 : 0);
   confirmacoes = MathMax(qualidadeVenda, qualidadeCompra);

   if(vendaValida && qualidadeVenda >= qualidadeCompra && !ExisteSinalRecenteContraFIX265(shift, LADO_VENDA))
   {
      ladoContra = LADO_VENDA;
      ratioQtd = melhorRqVenda;
      ratioFin = melhorRfVenda;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboVenda;
      return true;
   }
   if(compraValida && !ExisteSinalRecenteContraFIX265(shift, LADO_COMPRA))
   {
      ladoContra = LADO_COMPRA;
      ratioQtd = melhorRqCompra;
      ratioFin = melhorRfCompra;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboCompra;
      return true;
   }
   return false;
}

// FIX269: detecta o topo/fundo local que o usuário marcou no gráfico.
// Não usa candles futuros: o próprio candle de rejeição pode confirmar, ou a entrada ocorre até 3 candles após o pivô.
bool AvaliarCandleContraPivoFiboFIX269(int shift,
                                       ENUM_LADO_ROBO &ladoContra,
                                       double &rsi,
                                       double &agrCompra,
                                       double &ratioQtd,
                                       double &ratioFin,
                                       int &confirmacoes)
{
   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   g_ultimoFiboNivelSinalFIX269 = 0.0;
   ratioQtd = 0.0;
   ratioFin = 0.0;
   if(shift < 1)
      return false;

   ENUM_TIMEFRAMES tf = TimeframeFiltroAtualFIX255();
   double open0 = iOpen(_Symbol, tf, shift);
   double high0 = iHigh(_Symbol, tf, shift);
   double low0 = iLow(_Symbol, tf, shift);
   double close0 = iClose(_Symbol, tf, shift);
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   if(open0 <= 0.0 || high0 <= 0.0 || low0 <= 0.0 || close0 <= 0.0 || rsi < 0.0)
      return false;

   double range0 = high0 - low0;
   if(range0 <= 0.0)
      return false;
   double corpo0 = MathAbs(close0 - open0) / range0;
   double corpoMin = MathMax(0.05, MathMin(0.90, MathAbs(InpContraCorpoMinEntradaPivoFIX269)));
   if(corpo0 < corpoMin)
      return false;

   int lookback = InpContraPivoLookbackFIX269;
   if(lookback < 3) lookback = 3;
   if(lookback > 30) lookback = 30;
   int janela = InpContraJanelaConfirmacaoPivoFIX269;
   if(janela < 1) janela = 1;
   if(janela > 6) janela = 6;
   int janelaRSI = InpContraRSIExtremoRecenteFIX269;
   if(janelaRSI < 1) janelaRSI = 1;
   if(janelaRSI > 10) janelaRSI = 10;

   double rsiVendaSuave = MathMax(50.0, MathMin(80.0, MathAbs(InpContraRSIPivoVendaFIX269)));
   double rsiCompraSuave = MathMax(20.0, MathMin(50.0, MathAbs(InpContraRSIPivoCompraFIX269)));
   double rsiVendaForte = MathMax(rsiVendaSuave, MathMin(100.0, MathAbs(InpContraRSISobrecompra)));
   double rsiCompraForte = MathMin(rsiCompraSuave, MathMax(0.0, MathAbs(InpContraRSISobrevenda)));
   double pavioMin = MathMax(0.05, MathMin(0.80, MathAbs(InpContraPavioMinimoPivoFIX269)));
   double fiboMin = MathMax(0.50, MathMin(2.50, MathAbs(InpContraFiboPivoMinimoFIX269)));
   double volumeMin = MathMax(0.20, MathMin(5.0, MathAbs(InpContraVolumePivoMinimoFIX269)));
   double agrMin = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoPivoMinimaFIX269)));
   double distMin = MathMax(0.0, MathMin(5.0, MathAbs(InpContraDistanciaPivoATR_FIX269)));
   double deltaRSI = MathMax(0.0, MathMin(20.0, MathAbs(InpContraDeltaRSIPivoFIX269)));
   int scoreMin = InpContraScoreMinimoPivoFIX269;
   if(scoreMin < 4) scoreMin = 4;
   if(scoreMin > 14) scoreMin = 14;

   int melhorVenda = -1;
   int melhorCompra = -1;
   double melhorFiboVenda = 0.0;
   double melhorFiboCompra = 0.0;
   double melhorRatioQtd = 0.0;
   double melhorRatioFin = 0.0;

   double ma8Atual = MediaFechamentoIncluindoAtualContraFIX266(shift, 8);
   double ma8Anterior = MediaFechamentoIncluindoAtualContraFIX266(shift + 1, 8);

   for(int p = shift; p <= shift + janela; p++)
   {
      double op = iOpen(_Symbol, tf, p);
      double hp = iHigh(_Symbol, tf, p);
      double lp = iLow(_Symbol, tf, p);
      double cp = iClose(_Symbol, tf, p);
      double rsiP = RSIHistoricoContraFIX261(p);
      double atrP = ATRManualContraFIX265(p, InpContraATRPeriodo);
      double ma8P = MediaFechamentoAnteriorContraFIX265(p, 8);
      if(op <= 0.0 || hp <= 0.0 || lp <= 0.0 || cp <= 0.0 || rsiP < 0.0 || atrP <= 0.0 || ma8P <= 0.0)
         continue;

      double rangeP = hp - lp;
      if(rangeP <= 0.0)
         continue;
      double pavioSuperior = (hp - MathMax(op, cp)) / rangeP;
      double pavioInferior = (MathMin(op, cp) - lp) / rangeP;
      double meioPivo = (hp + lp) / 2.0;

      double maiorAnterior = -1.0e100;
      double menorAnterior = 1.0e100;
      for(int i = p + 1; i <= p + lookback; i++)
      {
         double h = iHigh(_Symbol, tf, i);
         double l = iLow(_Symbol, tf, i);
         if(h > maiorAnterior) maiorAnterior = h;
         if(l > 0.0 && l < menorAnterior) menorAnterior = l;
      }
      if(maiorAnterior <= -1.0e99 || menorAnterior >= 1.0e99)
         continue;

      double maxRSIRecente = rsiP;
      double minRSIRecente = rsiP;
      for(int i = p; i < p + janelaRSI; i++)
      {
         double rv = RSIHistoricoContraFIX261(i);
         if(rv < 0.0) continue;
         if(rv > maxRSIRecente) maxRSIRecente = rv;
         if(rv < minRSIRecente) minRSIRecente = rv;
      }

      double rq = 0.0, rf = 0.0;
      VolumeQtdFinHistoricoContraFIX261(p, rq, rf);
      if(rq > melhorRatioQtd) melhorRatioQtd = rq;
      if(rf > melhorRatioFin) melhorRatioFin = rf;
      bool volumePivo = (rq >= volumeMin && rf >= volumeMin);
      double agrP = AgressaoCompradoraEstimadaContraFIX261(p);
      bool agrTopo = (agrP >= agrMin);
      bool agrFundo = ((100.0 - agrP) >= agrMin);
      bool distanciaTopo = ((hp - ma8P) >= atrP * distMin);
      bool distanciaFundo = ((ma8P - lp) >= atrP * distMin);

      double nivelFiboVenda = 0.0, extATRVenda = 0.0, extEstrVenda = 0.0;
      double nivelFiboCompra = 0.0, extATRCompra = 0.0, extEstrCompra = 0.0;
      CalcularFiboExaustaoContraFIX269(p, LADO_VENDA, nivelFiboVenda, extATRVenda, extEstrVenda);
      CalcularFiboExaustaoContraFIX269(p, LADO_COMPRA, nivelFiboCompra, extATRCompra, extEstrCompra);
      double fiboBrutoVenda = MathMax(extATRVenda, extEstrVenda);
      double fiboBrutoCompra = MathMax(extATRCompra, extEstrCompra);
      bool fiboVenda = (fiboBrutoVenda >= fiboMin);
      bool fiboCompra = (fiboBrutoCompra >= fiboMin);

      bool topoLocal = (hp >= maiorAnterior);
      bool fundoLocal = (lp <= menorAnterior);
      bool rsiZonaVenda = (rsiP >= rsiVendaSuave || maxRSIRecente >= rsiVendaForte);
      bool rsiZonaCompra = (rsiP <= rsiCompraSuave || minRSIRecente <= rsiCompraForte);
      bool rejeicaoVenda = (pavioSuperior >= pavioMin || cp < op || close0 < meioPivo);
      bool rejeicaoCompra = (pavioInferior >= pavioMin || cp > op || close0 > meioPivo);
      bool candleEntradaVenda = (close0 < open0 && close0 < meioPivo);
      bool candleEntradaCompra = (close0 > open0 && close0 > meioPivo);
      double lowAnteriorEntrada = iLow(_Symbol, tf, shift + 1);
      double highAnteriorEntrada = iHigh(_Symbol, tf, shift + 1);
      bool rompeMicroVenda = (lowAnteriorEntrada > 0.0 && low0 < lowAnteriorEntrada && close0 < iClose(_Symbol, tf, shift + 1));
      bool rompeMicroCompra = (highAnteriorEntrada > 0.0 && high0 > highAnteriorEntrada && close0 > iClose(_Symbol, tf, shift + 1));
      bool rsiVirouVenda = (rsi <= rsiP - deltaRSI || rsi <= InpContraRSIRetornoVenda);
      bool rsiVirouCompra = (rsi >= rsiP + deltaRSI || rsi >= InpContraRSIRetornoCompra);
      bool mediaVirouVenda = (ma8Atual > 0.0 && ma8Anterior > 0.0 && (close0 < ma8Atual || ma8Atual < ma8Anterior));
      bool mediaVirouCompra = (ma8Atual > 0.0 && ma8Anterior > 0.0 && (close0 > ma8Atual || ma8Atual > ma8Anterior));

      int scoreVenda = 0;
      if(topoLocal) scoreVenda += 2;
      if(rsiZonaVenda) scoreVenda += 2;
      if(fiboVenda) scoreVenda++;
      if(fiboBrutoVenda >= MathAbs(InpContraFiboNivelMinimo)) scoreVenda++;
      if(rejeicaoVenda) scoreVenda++;
      if(volumePivo) scoreVenda++;
      if(agrTopo) scoreVenda++;
      if(distanciaTopo) scoreVenda++;
      if(candleEntradaVenda) scoreVenda++;
      if(rompeMicroVenda) scoreVenda++;
      if(rsiVirouVenda) scoreVenda++;
      if(mediaVirouVenda) scoreVenda++;

      int scoreCompra = 0;
      if(fundoLocal) scoreCompra += 2;
      if(rsiZonaCompra) scoreCompra += 2;
      if(fiboCompra) scoreCompra++;
      if(fiboBrutoCompra >= MathAbs(InpContraFiboNivelMinimo)) scoreCompra++;
      if(rejeicaoCompra) scoreCompra++;
      if(volumePivo) scoreCompra++;
      if(agrFundo) scoreCompra++;
      if(distanciaFundo) scoreCompra++;
      if(candleEntradaCompra) scoreCompra++;
      if(rompeMicroCompra) scoreCompra++;
      if(rsiVirouCompra) scoreCompra++;
      if(mediaVirouCompra) scoreCompra++;

      bool contextoVenda = (rsiZonaVenda || fiboVenda);
      bool contextoCompra = (rsiZonaCompra || fiboCompra);
      if(InpContraFiboPivoObrigatorioFIX269)
      {
         contextoVenda = contextoVenda && fiboVenda;
         contextoCompra = contextoCompra && fiboCompra;
      }

      bool vendaValida = (topoLocal && contextoVenda && rejeicaoVenda && candleEntradaVenda &&
                           (rompeMicroVenda || rsiVirouVenda) && scoreVenda >= scoreMin);
      bool compraValida = (fundoLocal && contextoCompra && rejeicaoCompra && candleEntradaCompra &&
                            (rompeMicroCompra || rsiVirouCompra) && scoreCompra >= scoreMin);

      if(vendaValida && scoreVenda > melhorVenda)
      {
         melhorVenda = scoreVenda;
         melhorFiboVenda = fiboBrutoVenda;
      }
      if(compraValida && scoreCompra > melhorCompra)
      {
         melhorCompra = scoreCompra;
         melhorFiboCompra = fiboBrutoCompra;
      }
   }

   ratioQtd = melhorRatioQtd;
   ratioFin = melhorRatioFin;
   confirmacoes = MathMax(melhorVenda, melhorCompra);

   if(melhorVenda >= scoreMin && melhorVenda >= melhorCompra &&
      !ExisteSinalRecenteContraFIX265(shift, LADO_VENDA))
   {
      ladoContra = LADO_VENDA;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboVenda;
      return true;
   }
   if(melhorCompra >= scoreMin &&
      !ExisteSinalRecenteContraFIX265(shift, LADO_COMPRA))
   {
      ladoContra = LADO_COMPRA;
      g_ultimoFiboNivelSinalFIX269 = melhorFiboCompra;
      return true;
   }
   return false;
}

bool AvaliarCandleContraCirurgicoFIX265(int shift,
                                        ENUM_LADO_ROBO &ladoContra,
                                        double &rsi,
                                        double &agrCompra,
                                        double &ratioQtd,
                                        double &ratioFin,
                                        int &confirmacoes)
{
   g_textoEtiquetaContraFIX271 = "";
   if(InpContraUsarDarvasFIX273)
      return AvaliarCandleContraDarvasFIX273(shift, ladoContra, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);
   if(InpContraUsarOTTFIX271)
      return AvaliarCandleContraOTTFIX271(shift, ladoContra, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);
   if(InpContraUsarCruzamentoFIX270)
      return AvaliarCandleContraCruzamentoFIX270(shift, ladoContra, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);
   if(InpContraUsarPivoFiboFIX269)
      return AvaliarCandleContraPivoFiboFIX269(shift, ladoContra, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);

   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   g_ultimoFiboNivelSinalFIX269 = 0.0;
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   ratioQtd = 0.0;
   ratioFin = 0.0;
   if(rsi < 0.0 || shift < 1)
      return false;

   int shiftGatilho = shift + 1;
   int janela = InpContraJanelaSetupBarras;
   if(janela < 4) janela = 4;
   if(janela > 40) janela = 40;

   double rsiSuperior = MathMax(50.0, MathMin(100.0, MathAbs(InpContraRSISobrecompra)));
   double rsiInferior = MathMax(0.0, MathMin(50.0, MathAbs(InpContraRSISobrevenda)));
   double agrExtrema = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoMinima)));
   double agrReversao = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoReversaoMinima)));
   double distanciaATR = MathMax(0.0, MathMin(5.0, MathAbs(InpContraDistanciaMinATR)));

   bool setupVendaOK = false;
   bool setupCompraOK = false;
   int shiftSetupVenda = -1;
   int shiftSetupCompra = -1;
   double maximaSetupVenda = 0.0;
   double minimaSetupCompra = 0.0;
   double nivelFiboSetupVenda = 0.0;
   double nivelFiboSetupCompra = 0.0;
   double melhorRatioQtd = 0.0;
   double melhorRatioFin = 0.0;

   // O setup fica antes do gatilho. Assim nenhum dado futuro participa da decisão.
   for(int s = shift + 2; s <= shift + janela; s++)
   {
      double rsiSetup = RSIHistoricoContraFIX261(s);
      if(rsiSetup < 0.0)
         continue;

      bool hiloCompra = false, hiloVenda = false, strCompra = false, strVenda = false;
      if(!HiLoSTRHistoricoContraFIX261(s, hiloCompra, hiloVenda, strCompra, strVenda))
         continue;

      double rq = 0.0, rf = 0.0;
      bool volumeOK = VolumeQtdFinHistoricoContraFIX261(s, rq, rf);
      if(rq > melhorRatioQtd) melhorRatioQtd = rq;
      if(rf > melhorRatioFin) melhorRatioFin = rf;

      double agrSetupCompra = AgressaoCompradoraEstimadaContraFIX261(s);
      double media = MediaFechamentoAnteriorContraFIX265(s, 8);
      double atr = ATRManualContraFIX265(s, InpContraATRPeriodo);
      double high = iHigh(_Symbol, TimeframeFiltroAtualFIX255(), s);
      double low = iLow(_Symbol, TimeframeFiltroAtualFIX255(), s);
      if(media <= 0.0 || atr <= 0.0 || high <= 0.0 || low <= 0.0)
         continue;

      bool vendaRSI = (rsiSetup >= rsiSuperior);
      bool compraRSI = (rsiSetup <= rsiInferior);
      bool vendaDirecao = (InpContraExigirHiLoESTR ? (hiloCompra && strCompra) : (hiloCompra || strCompra));
      bool compraDirecao = (InpContraExigirHiLoESTR ? (hiloVenda && strVenda) : (hiloVenda || strVenda));
      bool vendaAgressao = (agrSetupCompra >= agrExtrema);
      bool compraAgressao = ((100.0 - agrSetupCompra) >= agrExtrema);
      bool vendaDistancia = (high - media >= atr * distanciaATR);
      bool compraDistancia = (media - low >= atr * distanciaATR);

      double nivelFiboVenda = 0.0, atrFiboVenda = 0.0, estrutFiboVenda = 0.0;
      double nivelFiboCompra = 0.0, atrFiboCompra = 0.0, estrutFiboCompra = 0.0;
      bool vendaFibo = CalcularFiboExaustaoContraFIX269(s, LADO_VENDA, nivelFiboVenda, atrFiboVenda, estrutFiboVenda);
      bool compraFibo = CalcularFiboExaustaoContraFIX269(s, LADO_COMPRA, nivelFiboCompra, atrFiboCompra, estrutFiboCompra);

      int minExtras = InpContraMinExtrasSetup;
      if(minExtras < 1) minExtras = 1;
      if(minExtras > 3) minExtras = 3;
      int extrasVenda = (volumeOK ? 1 : 0) + (vendaAgressao ? 1 : 0) + (vendaDistancia ? 1 : 0);
      int extrasCompra = (volumeOK ? 1 : 0) + (compraAgressao ? 1 : 0) + (compraDistancia ? 1 : 0);
      double nivelForte = MathMax(MathAbs(InpContraFiboNivelMinimo), MathAbs(InpContraFiboNivelForte));
      int exigenciaVenda = (nivelFiboVenda >= nivelForte - 0.0001 && minExtras > 1 ? minExtras - 1 : minExtras);
      int exigenciaCompra = (nivelFiboCompra >= nivelForte - 0.0001 && minExtras > 1 ? minExtras - 1 : minExtras);

      if(!setupVendaOK && vendaRSI && vendaDirecao && vendaFibo && extrasVenda >= exigenciaVenda)
      {
         setupVendaOK = true;
         shiftSetupVenda = s;
         maximaSetupVenda = high;
         nivelFiboSetupVenda = nivelFiboVenda;
      }
      if(!setupCompraOK && compraRSI && compraDirecao && compraFibo && extrasCompra >= exigenciaCompra)
      {
         setupCompraOK = true;
         shiftSetupCompra = s;
         minimaSetupCompra = low;
         nivelFiboSetupCompra = nivelFiboCompra;
      }
   }

   ratioQtd = melhorRatioQtd;
   ratioFin = melhorRatioFin;

   double rsiGatilho = RSIHistoricoContraFIX261(shiftGatilho);
   double agrCompraGatilho = AgressaoCompradoraEstimadaContraFIX261(shiftGatilho);
   bool retornoRSIVenda = RetornoRSIConfirmadoContraFIX266(shiftGatilho, LADO_VENDA, rsiGatilho);
   bool retornoRSICompra = RetornoRSIConfirmadoContraFIX266(shiftGatilho, LADO_COMPRA, rsiGatilho);
   bool gatilhoVenda = CandleReversaoBasicoContraFIX265(shiftGatilho, LADO_VENDA);
   bool gatilhoCompra = CandleReversaoBasicoContraFIX265(shiftGatilho, LADO_COMPRA);
   bool agressaoGatilhoVenda = ((100.0 - agrCompraGatilho) >= agrReversao);
   bool agressaoGatilhoCompra = (agrCompraGatilho >= agrReversao);
   bool estruturaVenda = QuebraEstruturaContraFIX266(shiftGatilho, LADO_VENDA);
   bool estruturaCompra = QuebraEstruturaContraFIX266(shiftGatilho, LADO_COMPRA);
   bool cruzouMediaVenda = CruzamentoMedia8ContraFIX266(shiftGatilho, LADO_VENDA);
   bool cruzouMediaCompra = CruzamentoMedia8ContraFIX266(shiftGatilho, LADO_COMPRA);

   bool segundoVenda = ConfirmacaoSegundoCandleContraFIX267(shift, LADO_VENDA, shiftGatilho, maximaSetupVenda, nivelFiboSetupVenda);
   bool segundoCompra = ConfirmacaoSegundoCandleContraFIX267(shift, LADO_COMPRA, shiftGatilho, minimaSetupCompra, nivelFiboSetupCompra);

   bool vendaContra = (setupVendaOK && shiftSetupVenda > shiftGatilho && retornoRSIVenda &&
                        gatilhoVenda && agressaoGatilhoVenda && estruturaVenda && cruzouMediaVenda &&
                        segundoVenda && !ExisteSinalRecenteContraFIX265(shift, LADO_VENDA));
   bool compraContra = (setupCompraOK && shiftSetupCompra > shiftGatilho && retornoRSICompra &&
                         gatilhoCompra && agressaoGatilhoCompra && estruturaCompra && cruzouMediaCompra &&
                         segundoCompra && !ExisteSinalRecenteContraFIX265(shift, LADO_COMPRA));

   if(vendaContra)
   {
      ladoContra = LADO_VENDA;
      g_ultimoFiboNivelSinalFIX269 = nivelFiboSetupVenda;
      confirmacoes = 11;
   }
   else if(compraContra)
   {
      ladoContra = LADO_COMPRA;
      g_ultimoFiboNivelSinalFIX269 = nivelFiboSetupCompra;
      confirmacoes = 11;
   }
   else
   {
      int scoreVenda = 0;
      if(setupVendaOK) scoreVenda += 2;
      if(retornoRSIVenda) scoreVenda++;
      if(gatilhoVenda) scoreVenda++;
      if(agressaoGatilhoVenda) scoreVenda++;
      if(estruturaVenda) scoreVenda++;
      if(cruzouMediaVenda) scoreVenda++;
      if(segundoVenda) scoreVenda += 4;

      int scoreCompra = 0;
      if(setupCompraOK) scoreCompra += 2;
      if(retornoRSICompra) scoreCompra++;
      if(gatilhoCompra) scoreCompra++;
      if(agressaoGatilhoCompra) scoreCompra++;
      if(estruturaCompra) scoreCompra++;
      if(cruzouMediaCompra) scoreCompra++;
      if(segundoCompra) scoreCompra += 4;
      confirmacoes = MathMax(scoreCompra, scoreVenda);
   }
   return (ladoContra != LADO_NENHUM);
}

bool AvaliarCandleContraFIX261(int shift,
                               bool usarAgressaoAtual,
                               ENUM_LADO_ROBO &ladoContra,
                               double &rsi,
                               double &agrCompra,
                               double &ratioQtd,
                               double &ratioFin,
                               int &confirmacoes)
{
   if(InpContraModoCirurgico)
      return AvaliarCandleContraCirurgicoFIX265(shift, ladoContra, rsi, agrCompra, ratioQtd, ratioFin, confirmacoes);

   ladoContra = LADO_NENHUM;
   confirmacoes = 0;
   rsi = RSIHistoricoContraFIX261(shift);
   agrCompra = -1.0;
   ratioQtd = 0.0;
   ratioFin = 0.0;
   if(rsi < 0.0)
      return false;

   bool hiloCompra = false;
   bool hiloVenda = false;
   bool strCompra = false;
   bool strVenda = false;
   if(!HiLoSTRHistoricoContraFIX261(shift, hiloCompra, hiloVenda, strCompra, strVenda))
      return false;

   bool volumeOK = VolumeQtdFinHistoricoContraFIX261(shift, ratioQtd, ratioFin);
   agrCompra = AgressaoCompradoraEstimadaContraFIX261(shift);
   if(usarAgressaoAtual && shift == 1)
   {
      datetime inicio = iTime(_Symbol, TimeframeFiltroAtualFIX255(), shift);
      int segundosTF = PeriodSeconds(TimeframeFiltroAtualFIX255());
      if(segundosTF <= 0)
         segundosTF = 60;
      double atual = CalcularAgressaoCompradoraCandleFIX258(inicio, inicio + segundosTF);
      if(atual >= 0.0)
         agrCompra = atual;
   }

   double agrVenda = 100.0 - agrCompra;
   double minimoAGR = MathMax(50.0, MathMin(100.0, MathAbs(InpContraAgressaoMinima)));
   double rsiSuperior = MathMax(50.0, MathMin(100.0, MathAbs(InpContraRSISobrecompra)));
   double rsiInferior = MathMax(0.0, MathMin(50.0, MathAbs(InpContraRSISobrevenda)));
   int minimoConfirmacoes = InpContraMinConfirmacoes;
   if(minimoConfirmacoes < 2) minimoConfirmacoes = 2;
   if(minimoConfirmacoes > 5) minimoConfirmacoes = 5;

   bool rsiCompraContra = (rsi <= rsiInferior);
   bool rsiVendaContra = (rsi >= rsiSuperior);
   bool agrCompraContra = (agrVenda >= minimoAGR);
   bool agrVendaContra = (agrCompra >= minimoAGR);

   int scoreCompra = 0;
   if(hiloVenda) scoreCompra++;
   if(strVenda) scoreCompra++;
   if(rsiCompraContra) scoreCompra++;
   if(volumeOK) scoreCompra++;
   if(agrCompraContra) scoreCompra++;

   int scoreVenda = 0;
   if(hiloCompra) scoreVenda++;
   if(strCompra) scoreVenda++;
   if(rsiVendaContra) scoreVenda++;
   if(volumeOK) scoreVenda++;
   if(agrVendaContra) scoreVenda++;

   bool direcaoCompraOK = (!InpContraExigirDirecao || hiloVenda || strVenda);
   bool direcaoVendaOK = (!InpContraExigirDirecao || hiloCompra || strCompra);
   bool rsiCompraOK = (!InpContraExigirRSIExtremo || rsiCompraContra);
   bool rsiVendaOK = (!InpContraExigirRSIExtremo || rsiVendaContra);

   bool compraContra = (direcaoCompraOK && rsiCompraOK && scoreCompra >= minimoConfirmacoes);
   bool vendaContra = (direcaoVendaOK && rsiVendaOK && scoreVenda >= minimoConfirmacoes);

   if(compraContra && (!vendaContra || scoreCompra >= scoreVenda))
   {
      ladoContra = LADO_COMPRA;
      confirmacoes = scoreCompra;
   }
   else if(vendaContra)
   {
      ladoContra = LADO_VENDA;
      confirmacoes = scoreVenda;
   }
   else
      confirmacoes = MathMax(scoreCompra, scoreVenda);
   return (ladoContra != LADO_NENHUM);
}


#endif
