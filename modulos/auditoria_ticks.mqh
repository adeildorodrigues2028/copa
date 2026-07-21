// COPA V08 - Etapa 08: auditoria e exportacao do teste em ticks.
#ifndef COPA_V08_MODULOS_AUDITORIA_TICKS_MQH
#define COPA_V08_MODULOS_AUDITORIA_TICKS_MQH

// ============================================================================
// FIX433 - AUDITORIA COMPLETA PARA TESTE EM TICKS REAIS
// ============================================================================
int g_fix433Ticks=INVALID_HANDLE;
int g_fix433Posicoes=INVALID_HANDLE;
int g_fix433Deals=INVALID_HANDLE;
int g_fix433RSI7=INVALID_HANDLE;
datetime g_fix433Inicio=0;
datetime g_fix433UltimoFlush=0;
ulong g_fix433ContTicks=0;
string g_fix433Prefixo="";
int g_fix435Minutos=INVALID_HANDLE;
int g_fix437Status=INVALID_HANDLE;
int g_fix435Bands=INVALID_HANDLE;
int g_fix435EMA=INVALID_HANDLE;
int g_fix435ATR=INVALID_HANDLE;
datetime g_fix435UltimoM1=0;

double FIX433LerRSI7()
{
   if(g_fix433RSI7==INVALID_HANDLE) return -1.0;
   double b[]; ArraySetAsSeries(b,true);
   if(CopyBuffer(g_fix433RSI7,0,0,1,b)!=1) return -1.0;
   return b[0];
}

string FIX433NivelPorComentario(const string comentario)
{
   string c=comentario; StringToUpper(c);
   if(StringFind(c,"A1")>=0) return "A1";
   if(StringFind(c,"A2")>=0) return "A2";
   if(StringFind(c,"A3")>=0) return "A3";
   if(StringFind(c,"A4")>=0) return "A4";
   return "A0";
}

bool FIX433EhTestador()
{
   return (bool)MQLInfoInteger(MQL_TESTER);
}

bool FIX433Permitido()
{
   if(!InpTesteTicksCompletoFIX433) return false;
   if(InpTesteExportarSomenteTestadorFIX433 && !FIX433EhTestador()) return false;
   return true;
}

double FIX435POC(const int shift)
{
   int periodo=MathMax(10,InpTestePOCPeriodoFIX435);
   int faixa=MathMax(1,InpTestePOCFaixaPontosFIX435);
   MqlRates r[]; ArraySetAsSeries(r,true);
   int copiados=CopyRates(_Symbol,PERIOD_M1,shift,periodo,r);
   if(copiados<10) return 0.0;
   double minimo=DBL_MAX,maximo=-DBL_MAX;
   for(int i=0;i<copiados;i++){ minimo=MathMin(minimo,r[i].low); maximo=MathMax(maximo,r[i].high); }
   double passo=faixa*_Point; if(passo<=0.0 || maximo<=minimo) return 0.0;
   int bins=(int)MathFloor((maximo-minimo)/passo)+1; bins=MathMax(1,MathMin(2000,bins));
   double vol[]; ArrayResize(vol,bins); ArrayInitialize(vol,0.0);
   for(int i=0;i<copiados;i++)
   {
      double preco=(r[i].high+r[i].low+r[i].close)/3.0;
      int b=(int)MathFloor((preco-minimo)/passo); b=MathMax(0,MathMin(bins-1,b));
      vol[b]+=(double)r[i].tick_volume;
   }
   int melhor=0; for(int b=1;b<bins;b++) if(vol[b]>vol[melhor]) melhor=b;
   return minimo+(melhor+0.5)*passo;
}

bool FIX435LerBuffer(const int handle,const int buffer,const int shift,double &valor)
{
   valor=0.0; if(handle==INVALID_HANDLE) return false;
   double a[]; ArraySetAsSeries(a,true);
   if(CopyBuffer(handle,buffer,shift,1,a)!=1) return false;
   valor=a[0]; return MathIsValidNumber(valor);
}

void FIX435CabecalhoMinuto()
{
   if(g_fix435Minutos==INVALID_HANDLE) return;
   FileWrite(g_fix435Minutos,"TIME","SYMBOL","OPEN","HIGH","LOW","CLOSE","TICK_VOL","REAL_VOL","SPREAD_PTS",
             "RSI7","POC","DIST_POC_PTS","BOLL_SUP","BOLL_MED","BOLL_INF","KELT_SUP","KELT_MED","KELT_INF","ATR10",
             "HILO_COMPRA","HILO_VENDA","STR_COMPRA","STR_VENDA","AGR_COMPRA_PCT","AGR_VENDA_PCT","FORCA_COMPRA","FORCA_VENDA",
             "DX_MEDIA","DX_BANDA_SUP","DX_BANDA_INF","DX_DIST_PTS","DX_REGIME","DX_MASTER_BUY","DX_MASTER_SELL",
             "POSICOES","LUCRO_ABERTO","TICKETS_ABERTOS");
}

string FIX435TicketsAbertos()
{
   string t="";
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(t!="") t+="|"; t+=IntegerToString((long)ticket);
   }
   return t;
}

void FIX435RegistrarMinuto()
{
   if(!FIX433Permitido() || g_fix435Minutos==INVALID_HANDLE) return;
   datetime atual=iTime(_Symbol,PERIOD_M1,0); if(atual<=0 || atual==g_fix435UltimoM1) return;
   g_fix435UltimoM1=atual;
   MqlRates r[]; ArraySetAsSeries(r,true); if(CopyRates(_Symbol,PERIOD_M1,1,2,r)<1) return;
   datetime tempo=r[0].time;
   double rsi=FIX433LerRSI7();
   double poc=FIX435POC(1),distPoc=(poc>0.0?(r[0].close-poc)/_Point:0.0);
   double bollSup=0,bollMed=0,bollInf=0,ema=0,atr=0;
   FIX435LerBuffer(g_fix435Bands,1,1,bollSup); FIX435LerBuffer(g_fix435Bands,0,1,bollMed); FIX435LerBuffer(g_fix435Bands,2,1,bollInf);
   FIX435LerBuffer(g_fix435EMA,0,1,ema); FIX435LerBuffer(g_fix435ATR,0,1,atr);
   double ksup=ema+atr*InpTesteKeltMultiplicadorFIX435,kinf=ema-atr*InpTesteKeltMultiplicadorFIX435;
   int hp=MathMax(2,InpTesteHiloPeriodoFIX435),sp=MathMax(2,InpTesteSTRPeriodoFIX435);
   double highs[],lows[],closes[]; ArraySetAsSeries(highs,true);ArraySetAsSeries(lows,true);ArraySetAsSeries(closes,true);
   CopyHigh(_Symbol,PERIOD_M1,2,hp,highs); CopyLow(_Symbol,PERIOD_M1,2,hp,lows); CopyClose(_Symbol,PERIOD_M1,2,sp,closes);
   double mediaH=0,mediaL=0; int nh=ArraySize(highs),nl=ArraySize(lows); for(int i=0;i<nh;i++)mediaH+=highs[i]; for(int i=0;i<nl;i++)mediaL+=lows[i];
   if(nh>0)mediaH/=nh; if(nl>0)mediaL/=nl;
   bool hiloC=(r[0].close>mediaH),hiloV=(r[0].close<mediaL);
   double refSTR=(ArraySize(closes)>0?closes[ArraySize(closes)-1]:r[0].close);
   bool strC=(r[0].close>refSTR),strV=(r[0].close<refSTR);
   double agrC=CalcularAgressaoCompradoraTicks(256),agrV=(agrC>=0?100.0-agrC:-1.0);
   string nomeB="COPA_DX_MASTER_FIX430_BUY_"+IntegerToString((int)tempo);
   string nomeS="COPA_DX_MASTER_FIX430_SELL_"+IntegerToString((int)tempo);
   bool mb=ObjectFind(0,nomeB)>=0,ms=ObjectFind(0,nomeS)>=0;
   double lucro=0.0; for(int i=PositionsTotal()-1;i>=0;i--){ulong tk=PositionGetTicket(i);if(tk>0&&PositionSelectByTicket(tk)&&PositionGetString(POSITION_SYMBOL)==_Symbol)lucro+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);}
   FileWrite(g_fix435Minutos,TimeToString(tempo,TIME_DATE|TIME_SECONDS),_Symbol,r[0].open,r[0].high,r[0].low,r[0].close,(long)r[0].tick_volume,(long)r[0].real_volume,r[0].spread,
             rsi,poc,distPoc,bollSup,bollMed,bollInf,ksup,ema,kinf,atr,hiloC?1:0,hiloV?1:0,strC?1:0,strV?1:0,
             agrC,agrV,g_dxForcaCompraFIX411,g_dxForcaVendaFIX411,g_dxMediaAtualFIX411,g_dxBandaSuperiorFIX411,g_dxBandaInferiorFIX411,
             g_dxDistanciaAtualPtsFIX411,g_dxRegimeFIX411,mb?1:0,ms?1:0,PositionsTotal(),lucro,FIX435TicketsAbertos());
}

void FIX433CabecalhoTick()
{
   if(g_fix433Ticks==INVALID_HANDLE) return;
   FileWrite(g_fix433Ticks,"TIME_MSC","TIME","SYMBOL","BID","ASK","LAST","SPREAD_PTS","TICK_VOLUME","TICK_VOLUME_REAL","FLAGS",
             "M1_OPEN","M1_HIGH","M1_LOW","M1_CLOSE","RSI7","POC","DIST_POC_PTS","AGR_COMPRA_PCT","AGR_VENDA_PCT","FORCA_COMPRA","FORCA_VENDA",
             "DX_MEDIA","DX_BANDA_SUP","DX_BANDA_INF","DX_DIST_PTS","DX_REGIME","DX_MASTER_BUY_CANDLE","DX_MASTER_SELL_CANDLE",
             "POSICOES","LUCRO_ABERTO","MELHOR_LUCRO_SOMA","DEFESA_SOMA","TICKETS_ABERTOS");
}

void FIX433CabecalhoPosicao()
{
   if(g_fix433Posicoes==INVALID_HANDLE) return;
   FileWrite(g_fix433Posicoes,"TIME_MSC","TICKET","POSITION_ID","SYMBOL","MAGIC","LADO","NIVEL","VOLUME","PRECO_ABERTURA","PRECO_ATUAL",
             "LUCRO","SWAP","SL","TP","MELHOR_LUCRO_ESTIMADO","DEFESA_ZERO","DEFESA_ESCADA","COMENTARIO");
}

void FIX433CabecalhoDeals()
{
   if(g_fix433Deals==INVALID_HANDLE) return;
   FileWrite(g_fix433Deals,"TIME_MSC","DEAL","ORDER","POSITION_ID","SYMBOL","MAGIC","ENTRY","TYPE","VOLUME","PRICE","PROFIT","COMMISSION","SWAP","FEE","COMMENT");
}

bool FIX433AbrirArquivos()
{
   if(!FIX433Permitido()) return true;
   int dias=MathMax(9,MathMin(120,InpTesteDiasFIX433));
   g_fix433Inicio=TimeCurrent();
   g_fix433Prefixo=StringFormat("AR100_COLETA_120D_%s_%dD",_Symbol,dias);
   StringReplace(g_fix433Prefixo,".",""); StringReplace(g_fix433Prefixo,":",""); StringReplace(g_fix433Prefixo," ","_");
   int flags=FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ;
   ResetLastError();
   g_fix437Status=FileOpen(g_fix433Prefixo+"_STATUS.csv",flags,';');
   if(g_fix437Status!=INVALID_HANDLE)
   {
      FileWrite(g_fix437Status,"TIME","ETAPA","PERMITIDO","TESTADOR","TICKS_HANDLE","MINUTOS_HANDLE","POSICOES_HANDLE","DEALS_HANDLE","CONT_TICKS","MENSAGEM");
      FileWrite(g_fix437Status,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),"ONINIT_ABRIU_STATUS",FIX433Permitido()?"SIM":"NAO",FIX433EhTestador()?"SIM":"NAO",g_fix433Ticks,g_fix435Minutos,g_fix433Posicoes,g_fix433Deals,(long)g_fix433ContTicks,"STATUS CRIADO");
      FileFlush(g_fix437Status);
   }
   else PrintFormat("[COPA_AR100][FIX438][ERRO_STATUS] erro=%d",GetLastError());
   if(InpTesteExportarCadaTickFIX433)
   {
      ResetLastError();
      g_fix433Ticks=FileOpen(g_fix433Prefixo+"_TICKS.csv",flags,';');
      if(g_fix433Ticks!=INVALID_HANDLE){ FIX433CabecalhoTick(); FileFlush(g_fix433Ticks); }
      else PrintFormat("[COPA_AR100][FIX436][ERRO_ARQUIVO] TICKS | erro=%d | nome=%s",GetLastError(),g_fix433Prefixo+"_TICKS.csv");
   }
   if(InpTesteExportarPosicoesFIX433)
   {
      ResetLastError();
      g_fix433Posicoes=FileOpen(g_fix433Prefixo+"_POSICOES.csv",flags,';');
      if(g_fix433Posicoes!=INVALID_HANDLE){ FIX433CabecalhoPosicao(); FileFlush(g_fix433Posicoes); }
      else PrintFormat("[COPA_AR100][FIX436][ERRO_ARQUIVO] POSICOES | erro=%d | nome=%s",GetLastError(),g_fix433Prefixo+"_POSICOES.csv");
   }
   if(InpTesteExportarNegociosFIX433)
   {
      ResetLastError();
      g_fix433Deals=FileOpen(g_fix433Prefixo+"_DEALS.csv",flags,';');
      if(g_fix433Deals!=INVALID_HANDLE){ FIX433CabecalhoDeals(); FileFlush(g_fix433Deals); }
      else PrintFormat("[COPA_AR100][FIX436][ERRO_ARQUIVO] DEALS | erro=%d | nome=%s",GetLastError(),g_fix433Prefixo+"_DEALS.csv");
   }
   if(InpTesteExportarMinutoFIX435)
   {
      ResetLastError();
      g_fix435Minutos=FileOpen(g_fix433Prefixo+"_MINUTOS.csv",flags,';');
      if(g_fix435Minutos!=INVALID_HANDLE){ FIX435CabecalhoMinuto(); FileFlush(g_fix435Minutos); }
      else PrintFormat("[COPA_AR100][FIX436][ERRO_ARQUIVO] MINUTOS | erro=%d | nome=%s",GetLastError(),g_fix433Prefixo+"_MINUTOS.csv");
   }
   g_fix433RSI7=iRSI(_Symbol,PERIOD_M1,7,PRICE_CLOSE);
   g_fix435Bands=iBands(_Symbol,PERIOD_M1,InpTesteBollPeriodoFIX435,0,InpTesteBollDesvioFIX435,PRICE_CLOSE);
   g_fix435EMA=iMA(_Symbol,PERIOD_M1,InpTesteKeltEMA_FIX435,0,MODE_EMA,PRICE_CLOSE);
   g_fix435ATR=iATR(_Symbol,PERIOD_M1,InpTesteKeltATR_FIX435);
   PrintFormat("[COPA_AR100][FIX438][EXPORT] PREFIXO=%s | TICKS=%d | MINUTOS=%d | POS=%d | DEALS=%d | STATUS=%d | TESTER=%s | PERMITIDO=%s | PASTA=MQL5\\Files | CAMINHO=%s",
               g_fix433Prefixo,g_fix433Ticks,g_fix435Minutos,g_fix433Posicoes,g_fix433Deals,g_fix437Status,FIX433EhTestador()?"SIM":"NAO",FIX433Permitido()?"SIM":"NAO",TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files");
   if(g_fix437Status!=INVALID_HANDLE)
   {
      FileWrite(g_fix437Status,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),"ONINIT_ARQUIVOS_ABERTOS",FIX433Permitido()?"SIM":"NAO",FIX433EhTestador()?"SIM":"NAO",g_fix433Ticks,g_fix435Minutos,g_fix433Posicoes,g_fix433Deals,(long)g_fix433ContTicks,"HANDLES ATUALIZADOS");
      FileFlush(g_fix437Status);
   }
   return true;
}

void FIX433FecharArquivos()
{
   if(g_fix433Ticks!=INVALID_HANDLE){ FileFlush(g_fix433Ticks); FileClose(g_fix433Ticks); g_fix433Ticks=INVALID_HANDLE; }
   if(g_fix433Posicoes!=INVALID_HANDLE){ FileFlush(g_fix433Posicoes); FileClose(g_fix433Posicoes); g_fix433Posicoes=INVALID_HANDLE; }
   if(g_fix433Deals!=INVALID_HANDLE){ FileFlush(g_fix433Deals); FileClose(g_fix433Deals); g_fix433Deals=INVALID_HANDLE; }
   if(g_fix435Minutos!=INVALID_HANDLE){ FileFlush(g_fix435Minutos); FileClose(g_fix435Minutos); g_fix435Minutos=INVALID_HANDLE; }
   if(g_fix437Status!=INVALID_HANDLE){ FileWrite(g_fix437Status,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),"ONDEINIT","SIM",FIX433EhTestador()?"SIM":"NAO",g_fix433Ticks,g_fix435Minutos,g_fix433Posicoes,g_fix433Deals,(long)g_fix433ContTicks,"ENCERRANDO"); FileFlush(g_fix437Status); FileClose(g_fix437Status); g_fix437Status=INVALID_HANDLE; }
   if(g_fix433RSI7!=INVALID_HANDLE){ IndicatorRelease(g_fix433RSI7); g_fix433RSI7=INVALID_HANDLE; }
   if(g_fix435Bands!=INVALID_HANDLE){ IndicatorRelease(g_fix435Bands); g_fix435Bands=INVALID_HANDLE; }
   if(g_fix435EMA!=INVALID_HANDLE){ IndicatorRelease(g_fix435EMA); g_fix435EMA=INVALID_HANDLE; }
   if(g_fix435ATR!=INVALID_HANDLE){ IndicatorRelease(g_fix435ATR); g_fix435ATR=INVALID_HANDLE; }
}

void FIX433FlushSeNecessario()
{
   datetime agora=TimeCurrent();
   int s=MathMax(1,InpTesteFlushSegundosFIX433);
   if(g_fix433UltimoFlush>0 && agora-g_fix433UltimoFlush<s) return;
   g_fix433UltimoFlush=agora;
   if(g_fix433Ticks!=INVALID_HANDLE) FileFlush(g_fix433Ticks);
   if(g_fix433Posicoes!=INVALID_HANDLE) FileFlush(g_fix433Posicoes);
   if(g_fix433Deals!=INVALID_HANDLE) FileFlush(g_fix433Deals);
   if(g_fix435Minutos!=INVALID_HANDLE) FileFlush(g_fix435Minutos);
   if(g_fix437Status!=INVALID_HANDLE) FileFlush(g_fix437Status);
}

void FIX433RegistrarPosicoes(const MqlTick &tick,double &lucroTotal,double &melhorTotal,double &defesaTotal)
{
   lucroTotal=0.0; melhorTotal=0.0; defesaTotal=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE tipo=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double lucro=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double melhor=MathMax(0.0,lucro); // valor instantaneo; Python recompõe o máximo real por ticket.
      double defesa=0.0;
      if(melhor>=InpTesteAtivaZeroReaisFIX433)
      {
         defesa=0.0;
         if(melhor>=InpTesteTrailingAtivaReaisFIX433)
            defesa=MathMax(0.0,melhor-InpTesteTrailingDistanciaReaisFIX433);
         else if(InpTesteDefesaPassoReaisFIX433>0.0)
            defesa=MathMax(0.0,MathFloor(melhor/InpTesteDefesaPassoReaisFIX433)*InpTesteDefesaPassoReaisFIX433-InpTesteDefesaPassoReaisFIX433);
      }
      lucroTotal+=lucro; melhorTotal+=melhor; defesaTotal+=defesa;
      if(g_fix433Posicoes!=INVALID_HANDLE)
      {
         string comentario=PositionGetString(POSITION_COMMENT);
         FileWrite(g_fix433Posicoes,(long)tick.time_msc,(long)ticket,(long)PositionGetInteger(POSITION_IDENTIFIER),_Symbol,magic,
                   tipo==POSITION_TYPE_BUY?"BUY":"SELL",FIX433NivelPorComentario(comentario),PositionGetDouble(POSITION_VOLUME),
                   PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_PRICE_CURRENT),lucro,PositionGetDouble(POSITION_SWAP),
                   PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),melhor,
                   melhor>=InpTesteAtivaZeroReaisFIX433?0.0:-1.0,defesa,comentario);
      }
   }
}

void FIX433RegistrarTick()
{
   // FIX436: cada exportacao e independente. Falha/disable do TICKS nao pode zerar MINUTOS ou POSICOES.
   if(!FIX433Permitido()) return;
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return;
   g_fix433ContTicks++;
   if(g_fix437Status!=INVALID_HANDLE && (g_fix433ContTicks==1 || (g_fix433ContTicks%10000)==0))
   {
      FileWrite(g_fix437Status,TimeToString((datetime)(tick.time_msc/1000),TIME_DATE|TIME_SECONDS),"ONTICK",FIX433Permitido()?"SIM":"NAO",FIX433EhTestador()?"SIM":"NAO",g_fix433Ticks,g_fix435Minutos,g_fix433Posicoes,g_fix433Deals,(long)g_fix433ContTicks,"TICK RECEBIDO");
      FileFlush(g_fix437Status);
   }

   double agrCompra=CalcularAgressaoCompradoraTicks(256);
   double agrVenda=(agrCompra>=0.0?100.0-agrCompra:-1.0);
   double rsi7=FIX433LerRSI7();
   datetime candleFechado=iTime(_Symbol,PERIOD_M1,1);
   bool masterBuy=(candleFechado>0 && ObjectFind(0,"COPA_DX_MASTER_FIX430_BUY_"+IntegerToString((int)candleFechado))>=0);
   bool masterSell=(candleFechado>0 && ObjectFind(0,"COPA_DX_MASTER_FIX430_SELL_"+IntegerToString((int)candleFechado))>=0);

   double lucroTotal=0.0,melhorTotal=0.0,defesaTotal=0.0;
   // Registra posicoes mesmo que o CSV de ticks esteja desligado ou tenha falhado.
   FIX433RegistrarPosicoes(tick,lucroTotal,melhorTotal,defesaTotal);

   if(g_fix433Ticks!=INVALID_HANDLE)
   {
      double spreadPts=(tick.ask>0.0 && tick.bid>0.0 ? (tick.ask-tick.bid)/_Point : -1.0);
      double m1o=iOpen(_Symbol,PERIOD_M1,0),m1h=iHigh(_Symbol,PERIOD_M1,0),m1l=iLow(_Symbol,PERIOD_M1,0),m1c=iClose(_Symbol,PERIOD_M1,0);
      double poc=FIX435POC(0),distPoc=(poc>0.0?(m1c-poc)/_Point:0.0);
      FileWrite(g_fix433Ticks,(long)tick.time_msc,TimeToString((datetime)(tick.time_msc/1000),TIME_DATE|TIME_SECONDS),_Symbol,tick.bid,tick.ask,tick.last,spreadPts,(long)tick.volume,(long)tick.volume_real,tick.flags,
                m1o,m1h,m1l,m1c,rsi7,poc,distPoc,agrCompra,agrVenda,g_dxForcaCompraFIX411,g_dxForcaVendaFIX411,
                g_dxMediaAtualFIX411,g_dxBandaSuperiorFIX411,g_dxBandaInferiorFIX411,g_dxDistanciaAtualPtsFIX411,g_dxRegimeFIX411,
                masterBuy?1:0,masterSell?1:0,PositionsTotal(),lucroTotal,melhorTotal,defesaTotal,FIX435TicketsAbertos());
   }

   // Registra candle M1 de modo independente do arquivo de ticks.
   FIX435RegistrarMinuto();
   FIX433FlushSeNecessario();
}

void FIX433RegistrarDeal(const MqlTradeTransaction &trans)
{
   if(!FIX433Permitido() || g_fix433Deals==INVALID_HANDLE) return;
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || trans.deal==0 || !HistoryDealSelect(trans.deal)) return;
   FileWrite(g_fix433Deals,(long)HistoryDealGetInteger(trans.deal,DEAL_TIME_MSC),(long)trans.deal,
             (long)HistoryDealGetInteger(trans.deal,DEAL_ORDER),(long)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID),
             HistoryDealGetString(trans.deal,DEAL_SYMBOL),(long)HistoryDealGetInteger(trans.deal,DEAL_MAGIC),
             EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY)),
             EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal,DEAL_TYPE)),
             HistoryDealGetDouble(trans.deal,DEAL_VOLUME),HistoryDealGetDouble(trans.deal,DEAL_PRICE),
             HistoryDealGetDouble(trans.deal,DEAL_PROFIT),HistoryDealGetDouble(trans.deal,DEAL_COMMISSION),
             HistoryDealGetDouble(trans.deal,DEAL_SWAP),HistoryDealGetDouble(trans.deal,DEAL_FEE),
             HistoryDealGetString(trans.deal,DEAL_COMMENT));
   FIX433FlushSeNecessario();
}

#endif
