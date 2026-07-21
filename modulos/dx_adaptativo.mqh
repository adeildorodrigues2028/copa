#ifndef COPA_DX_ADAPTATIVO_MQH
#define COPA_DX_ADAPTATIVO_MQH

// ============================================================================
// RESPONSABILIDADE: FILTRO E PLOTAGEM DO DX ADAPTATIVO
// Funcoes movidas do principal na V41 sem alteracao de regra operacional.
// ============================================================================

string RegimeDXFIX411(double forcaMax)
{
   if(forcaMax>=86.0) return "EXPLOSAO";
   if(forcaMax>=71.0) return "MUITO FORTE";
   if(forcaMax>=51.0) return "FORTE";
   if(forcaMax>=31.0) return "NORMAL";
   return "FRACO";
}

int MinutoHorarioTextoFIX411(string hhmm)
{
   string p[];
   if(StringSplit(hhmm,':',p)<2) return 565;
   return (int)StringToInteger(p[0])*60+(int)StringToInteger(p[1]);
}

void LimparPlotagemDXAdaptativoFIX411()
{
   ObjectDelete(0,"COPA_FIX411_DX_SUP");
   ObjectDelete(0,"COPA_FIX411_DX_INF");
   ObjectDelete(0,"COPA_FIX411_DX_MEDIA");
   ObjectDelete(0,"COPA_FIX411_DX_STATUS");
}

void CriarLinhaDXFIX411(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura)
{
   if(preco<=0.0) return;
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_HLINE,0,0,preco);
   ObjectSetDouble(0,nome,OBJPROP_PRICE,preco);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,estilo);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,nome,OBJPROP_BACK,true);
}

void AtualizarPlotagemDXAdaptativoFIX411()
{
   if(!InpDXAdaptativoAtivoFIX410 || !InpDXPlotarBandasFIX410 || g_dxMediaAtualFIX411<=0.0)
   {
      LimparPlotagemDXAdaptativoFIX411();
      return;
   }
   CriarLinhaDXFIX411("COPA_FIX411_DX_MEDIA",g_dxMediaAtualFIX411,clrWhite,STYLE_SOLID,2);
   CriarLinhaDXFIX411("COPA_FIX411_DX_SUP",g_dxBandaSuperiorFIX411,clrGold,STYLE_DOT,1);
   CriarLinhaDXFIX411("COPA_FIX411_DX_INF",g_dxBandaInferiorFIX411,clrDeepSkyBlue,STYLE_DOT,1);
   string txt=StringFormat("DX %.0fP | FC %.0f | FV %.0f | %s",g_dxDistanciaAtualPtsFIX411,g_dxForcaCompraFIX411,g_dxForcaVendaFIX411,g_dxRegimeFIX411);
   if(ObjectFind(0,"COPA_FIX411_DX_STATUS")<0)
      ObjectCreate(0,"COPA_FIX411_DX_STATUS",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_XDISTANCE,20);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_YDISTANCE,75);
   ObjectSetString(0,"COPA_FIX411_DX_STATUS",OBJPROP_TEXT,txt);
   ObjectSetString(0,"COPA_FIX411_DX_STATUS",OBJPROP_FONT,"Consolas");
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,"COPA_FIX411_DX_STATUS",OBJPROP_SELECTABLE,false);
}

void AtualizarDXAdaptativoFIX411(bool forcar)
{
   if(!InpDXAdaptativoAtivoFIX410)
   {
      g_dxDadosProntosFIX411=false;
      LimparPlotagemDXAdaptativoFIX411();
      return;
   }
   ENUM_TIMEFRAMES tf=PERIOD_M1;
   datetime barra=iTime(_Symbol,tf,0);
   if(!forcar && barra>0 && barra==g_dxUltimoCalculoBarraFIX411)
   {
      AtualizarPlotagemDXAdaptativoFIX411();
      return;
   }
   int periodo=MathMax(2,InpDXMediaPeriodoFIX411);
   int amostra=MathMax(5,InpDXAmostraCandlesFIX411);
   int necessario=periodo+amostra+5;
   if(Bars(_Symbol,tf)<necessario)
   {
      g_dxDadosProntosFIX411=false;
      g_dxRegimeFIX411="CALCULANDO";
      AtualizarPlotagemDXAdaptativoFIX411();
      return;
   }
   int h=iMA(_Symbol,tf,periodo,0,InpDXMediaMetodoFIX411,InpDXMediaPrecoFIX411);
   if(h==INVALID_HANDLE) return;
   double ma[];
   ArraySetAsSeries(ma,true);
   int cop=CopyBuffer(h,0,0,amostra+3,ma);
   IndicatorRelease(h);
   if(cop<amostra+2) return;
   double soma=0.0,maxDist=0.0;
   int usados=0;
   for(int i=1;i<=amostra;i++)
   {
      double c=iClose(_Symbol,tf,i);
      if(c<=0.0 || ma[i]<=0.0) continue;
      double d=MathAbs(c-ma[i])/_Point;
      soma+=d;
      if(d>maxDist) maxDist=d;
      usados++;
   }
   if(usados<MathMin(amostra,10)) return;
   double mediaDist=soma/(double)usados;
   g_dxMediaAtualFIX411=ma[0];

   double peso=100.0/6.0;
   double fc=0.0,fv=0.0;
   if(g_mercado.hiloCompra) fc+=peso;
   if(g_mercado.hiloVenda) fv+=peso;
   if(g_mercado.strCompra) fc+=peso;
   if(g_mercado.strVenda) fv+=peso;
   double o1=iOpen(_Symbol,tf,1),c1=iClose(_Symbol,tf,1);
   bool alta=(c1>o1),baixa=(c1<o1);
   if(g_mercado.volqRatioCandle>=1.0 || g_mercado.volqCurvaOK)
   {
      if(alta) fc+=peso; else if(baixa) fv+=peso;
   }
   if(g_mercado.volfRatioCandle>=1.0 || g_mercado.volfCurvaOK)
   {
      if(alta) fc+=peso; else if(baixa) fv+=peso;
   }
   if(g_mercado.rsi>=70.0) fc+=peso;
   if(g_mercado.rsi<=30.0) fv+=peso;
   int shiftInclinacao=MathMin(amostra,3);
   double inclinacao=(ma[1]-ma[shiftInclinacao])/_Point;
   if(inclinacao>0.0) fc+=peso;
   if(inclinacao<0.0) fv+=peso;
   g_dxForcaCompraFIX411=MathMin(100.0,fc);
   g_dxForcaVendaFIX411=MathMin(100.0,fv);
   double forcaMax=MathMax(fc,fv);
   g_dxRegimeFIX411=RegimeDXFIX411(forcaMax);

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   int minuto=dt.hour*60+dt.min;
   int corte=MinutoHorarioTextoFIX411(InpDXHorarioInicioAutoFIX411);
   if(minuto<corte)
      g_dxDistanciaAtualPtsFIX411=MathMax(1.0,InpDXManualAberturaPontosFIX411);
   else
   {
      double pctMin=MathMax(0.0,MathMin(100.0,InpDXPercentualExtremoMinFIX411));
      double pctMax=MathMax(pctMin,MathMin(150.0,InpDXPercentualExtremoMaxFIX411));
      double pct=pctMin+(pctMax-pctMin)*(forcaMax/100.0);
      double extremo=maxDist*(pct/100.0);
      g_dxDistanciaAtualPtsFIX411=MathMax(mediaDist,extremo);
   }
   g_dxBandaSuperiorFIX411=g_dxMediaAtualFIX411+g_dxDistanciaAtualPtsFIX411*_Point;
   g_dxBandaInferiorFIX411=g_dxMediaAtualFIX411-g_dxDistanciaAtualPtsFIX411*_Point;
   // O toque e memorizado continuamente, mesmo antes de A0/A1-A4 chegarem ao ultimo filtro.
   double bidFIX411=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double askFIX411=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(bidFIX411>0.0 && bidFIX411<=g_dxBandaInferiorFIX411)
   {
      g_dxToqueCompraA0FIX411=true;
      g_dxBarraToqueCompraA0FIX411=barra;
      for(int nivelFIX417=0;nivelFIX417<4;nivelFIX417++)
      {
         g_dxToqueCompraAumFIX417[nivelFIX417]=true;
         g_dxBarraToqueCompraAumFIX417[nivelFIX417]=barra;
      }
   }
   if(askFIX411>0.0 && askFIX411>=g_dxBandaSuperiorFIX411)
   {
      g_dxToqueVendaA0FIX411=true;
      g_dxBarraToqueVendaA0FIX411=barra;
      for(int nivelFIX417=0;nivelFIX417<4;nivelFIX417++)
      {
         g_dxToqueVendaAumFIX417[nivelFIX417]=true;
         g_dxBarraToqueVendaAumFIX417[nivelFIX417]=barra;
      }
   }
   g_dxDadosProntosFIX411=true;
   g_dxUltimoCalculoBarraFIX411=barra;
   AtualizarPlotagemDXAdaptativoFIX411();
   PrintFormat("[COPA_AR100][FIX411][DX_CALC] MEDIA=%.0f | MEDIA_DIST=%.0fP | MAX_DIST=%.0fP | DX=%.0fP | FC=%.0f | FV=%.0f | REGIME=%s",
               g_dxMediaAtualFIX411,mediaDist,maxDist,g_dxDistanciaAtualPtsFIX411,fc,fv,g_dxRegimeFIX411);
}

bool DXAdaptativoAutorizaFIX411(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento,string &detalhe)
{
   detalhe="";
   int idxDXFIX417=nivelAumento;
   if(aumento && (idxDXFIX417<0 || idxDXFIX417>=4))
   {
      detalhe="DX AUMENTO: NIVEL INVALIDO";
      return false;
   }
   if(!InpDXAdaptativoAtivoFIX410)
   {
      detalhe="DX OFF";
      return true;
   }
   AtualizarDXAdaptativoFIX411(false);
   if(!g_dxDadosProntosFIX411)
   {
      detalhe="DX CALCULANDO; USA MANUAL/AGUARDA DADOS";
      return false;
   }
   bool compra=(lado==LADO_COMPRA);
   double forcaContra=compra ? g_dxForcaVendaFIX411 : g_dxForcaCompraFIX411;
   if(forcaContra>=InpDXForcaBloqueioContraFIX411)
   {
      detalhe=StringFormat("REGIME %s | FORCA CONTRARIA %.0f >= %.0f | CONTRA BLOQUEADA",g_dxRegimeFIX411,forcaContra,InpDXForcaBloqueioContraFIX411);
      return false;
   }
   double preco=compra ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   datetime barra0=iTime(_Symbol,PERIOD_M1,0);
   bool tocou=false;
   datetime toque=0,liberado=0;
   if(!aumento && compra){ tocou=g_dxToqueCompraA0FIX411; toque=g_dxBarraToqueCompraA0FIX411; liberado=g_dxLiberadoCompraA0FIX411; }
   if(!aumento && !compra){ tocou=g_dxToqueVendaA0FIX411; toque=g_dxBarraToqueVendaA0FIX411; liberado=g_dxLiberadoVendaA0FIX411; }
   if(aumento && compra){ tocou=g_dxToqueCompraAumFIX417[idxDXFIX417]; toque=g_dxBarraToqueCompraAumFIX417[idxDXFIX417]; liberado=g_dxLiberadoCompraAumFIX417[idxDXFIX417]; }
   if(aumento && !compra){ tocou=g_dxToqueVendaAumFIX417[idxDXFIX417]; toque=g_dxBarraToqueVendaAumFIX417[idxDXFIX417]; liberado=g_dxLiberadoVendaAumFIX417[idxDXFIX417]; }

   if(!tocou)
   {
      bool atingiu=compra ? (preco<=g_dxBandaInferiorFIX411) : (preco>=g_dxBandaSuperiorFIX411);
      if(atingiu)
      {
         tocou=true; toque=barra0;
         if(!aumento && compra){g_dxToqueCompraA0FIX411=true;g_dxBarraToqueCompraA0FIX411=barra0;}
         if(!aumento && !compra){g_dxToqueVendaA0FIX411=true;g_dxBarraToqueVendaA0FIX411=barra0;}
         if(aumento && compra){g_dxToqueCompraAumFIX417[idxDXFIX417]=true;g_dxBarraToqueCompraAumFIX417[idxDXFIX417]=barra0;}
         if(aumento && !compra){g_dxToqueVendaAumFIX417[idxDXFIX417]=true;g_dxBarraToqueVendaAumFIX417[idxDXFIX417]=barra0;}
         PrintFormat("[COPA_AR100][FIX411][DX_TOQUE] TIPO=%s | LADO=%s | PRECO=%.0f | BANDA=%.0f | DX=%.0fP",
                     aumento?StringFormat("A%d",idxDXFIX417+1):"A0",compra?"COMPRA":"VENDA",preco,compra?g_dxBandaInferiorFIX411:g_dxBandaSuperiorFIX411,g_dxDistanciaAtualPtsFIX411);
      }
      detalhe=StringFormat("AGUARDA TOQUE DX %s %.0f | PRECO %.0f",compra?"INF":"SUP",compra?g_dxBandaInferiorFIX411:g_dxBandaSuperiorFIX411,preco);
      return false;
   }

   if(forcaContra>InpDXForcaLiberacaoFIX411)
   {
      detalhe=StringFormat("DX TOCADO | AGUARDA PERDA FORCA %.0f <= %.0f",forcaContra,InpDXForcaLiberacaoFIX411);
      return false;
   }
   datetime barraFechada=iTime(_Symbol,PERIOD_M1,1);
   double ma1=g_dxMediaAtualFIX411;
   int h=iMA(_Symbol,PERIOD_M1,MathMax(2,InpDXMediaPeriodoFIX411),0,InpDXMediaMetodoFIX411,InpDXMediaPrecoFIX411);
   if(h!=INVALID_HANDLE)
   {
      double m[]; ArraySetAsSeries(m,true);
      if(CopyBuffer(h,0,1,1,m)>0) ma1=m[0];
      IndicatorRelease(h);
   }
   double high1=iHigh(_Symbol,PERIOD_M1,1),low1=iLow(_Symbol,PERIOD_M1,1),close1=iClose(_Symbol,PERIOD_M1,1);
   bool retorno=compra ? (high1>=ma1 && close1>ma1) : (low1<=ma1 && close1<ma1);
   bool tempoConfirmado=InpDXEntradaProximoCandleFIX411 ? (barraFechada>toque) : (barraFechada>=toque);
   if(retorno && tempoConfirmado)
   {
      if(!aumento && compra) g_dxLiberadoCompraA0FIX411=barra0;
      if(!aumento && !compra) g_dxLiberadoVendaA0FIX411=barra0;
      if(aumento && compra) g_dxLiberadoCompraAumFIX417[idxDXFIX417]=barra0;
      if(aumento && !compra) g_dxLiberadoVendaAumFIX417[idxDXFIX417]=barra0;
      liberado=barra0;
      PrintFormat("[COPA_AR100][FIX411][DX_RETORNO_MEDIA] TIPO=%s | LADO=%s | CLOSE=%.0f | MEDIA=%.0f | PROXIMO_CANDLE_LIBERADO",
                  aumento?StringFormat("A%d",idxDXFIX417+1):"A0",compra?"COMPRA":"VENDA",close1,ma1);
   }
   bool autorizado=(liberado>0); // FIX417: permanece autorizado ate a ordem ser aceita e o sinal ser consumido
   if(autorizado)
   {
      detalhe=StringFormat("DX OK | %s | FORCA CONTRA %.0f | DX %.0fP | ENTRADA PROXIMO CANDLE",g_dxRegimeFIX411,forcaContra,g_dxDistanciaAtualPtsFIX411);
      // FIX417: nao consumir aqui. O sinal permanece valido se RSI, volume, risco, preco ou envio bloquearem.
      // O consumo ocorre somente depois que a ordem for aceita pelo servidor.
      return true;
   }
   detalhe=StringFormat("DX TOCADO | FORCA %.0f | AGUARDA RETORNO/FECHAMENTO NA MEDIA %.0f",forcaContra,ma1);
   return false;
}

void ConsumirSinalDXAposOrdemFIX417(ENUM_LADO_ROBO lado,bool aumento,int nivelAumento)
{
   bool compra=(lado==LADO_COMPRA);
   if(!aumento)
   {
      if(compra){ g_dxToqueCompraA0FIX411=false; g_dxLiberadoCompraA0FIX411=0; g_dxBarraToqueCompraA0FIX411=0; }
      else      { g_dxToqueVendaA0FIX411=false;  g_dxLiberadoVendaA0FIX411=0;  g_dxBarraToqueVendaA0FIX411=0; }
      PrintFormat("[COPA_AR100][FIX417][DX_CONSUMIDO] TIPO=A0 | LADO=%s | MOTIVO=ORDEM_ACEITA",compra?"COMPRA":"VENDA");
      return;
   }
   if(nivelAumento<0 || nivelAumento>=4) return;
   if(compra)
   {
      g_dxToqueCompraAumFIX417[nivelAumento]=false;
      g_dxLiberadoCompraAumFIX417[nivelAumento]=0;
      g_dxBarraToqueCompraAumFIX417[nivelAumento]=0;
   }
   else
   {
      g_dxToqueVendaAumFIX417[nivelAumento]=false;
      g_dxLiberadoVendaAumFIX417[nivelAumento]=0;
      g_dxBarraToqueVendaAumFIX417[nivelAumento]=0;
   }
   PrintFormat("[COPA_AR100][FIX417][DX_CONSUMIDO] TIPO=A%d | LADO=%s | MOTIVO=ORDEM_ACEITA",nivelAumento+1,compra?"COMPRA":"VENDA");
}


#endif // COPA_DX_ADAPTATIVO_MQH
