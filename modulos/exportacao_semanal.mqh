// COPA V09 - Etapa 09: exportacao semanal e estatistica externa.
#ifndef COPA_V09_MODULOS_EXPORTACAO_SEMANAL_MQH
#define COPA_V09_MODULOS_EXPORTACAO_SEMANAL_MQH

// ============================================================================
// FIX306 - EXPORTACAO SEMANAL_MESES_2 PARA AUDITORIA/ESTATISTICA EXTERNA
// Um clique para ABRIR AUDIT inicia a exportacao. O Timer grava lotes pequenos.
// ============================================================================
enum ENUM_EXP306_BAR_COL
{
   XB_EXPORT_ID=0,XB_EXPORTED_AT,XB_WEEK_START,XB_WEEK_END,XB_ACCOUNT,XB_SERVER,XB_SYMBOL,XB_WINDOW,XB_MOTOR,XB_MAGIC,XB_MAGIC_A,XB_MAGIC_B,XB_GROUP,XB_GENERATION,XB_SCENARIO,XB_TIMEFRAME,XB_BAR_TIME,XB_BAR_UNIX,XB_BAR_INDEX,XB_OPEN,XB_HIGH,XB_LOW,XB_CLOSE,XB_TICK_VOLUME,XB_REAL_VOLUME,XB_SPREAD_POINTS,XB_RANGE_POINTS,XB_BODY_POINTS,XB_UPPER_WICK_POINTS,XB_LOWER_WICK_POINTS,XB_CLOSE_CHANGE_POINTS,XB_GAP_POINTS,XB_TRUE_RANGE_POINTS,XB_RETURN_PCT,XB_LOG_RETURN,XB_TYPICAL_PRICE,XB_MEDIAN_PRICE,XB_WEIGHTED_PRICE,XB_SMA8,XB_SMA20,XB_SMA50,XB_RSI14,XB_ATR14_POINTS,XB_VOLUME_SMA20,XB_VOLUME_RATIO20,XB_VWAP_DAY,XB_DIRECTION,XB_DAY_OF_WEEK,XB_HOUR,XB_MINUTE,XB_IS_NEW_DAY,XB_BID_SNAPSHOT,XB_ASK_SNAPSHOT,XB_LAST_SNAPSHOT,XB_EXPORT_STATUS,XB_TOTAL
};

enum ENUM_EXP306_AUD_COL
{
   XA_RECORD_TYPE=0,XA_EXPORT_ID,XA_EXPORTED_AT,XA_WEEK_START,XA_WEEK_END,XA_ACCOUNT,XA_SERVER,XA_CURRENCY,XA_SYMBOL,XA_CHART_ID,XA_CHART_PERIOD,XA_WINDOW,XA_MOTOR,XA_MAGIC_LOCAL,XA_MAGIC_A,XA_MAGIC_B,XA_GROUP,XA_GENERATION,XA_SCENARIO,XA_KEY,XA_VALUE,XA_TIME,XA_TIME_MSC,XA_CYCLE,XA_LEVEL,XA_DEAL,XA_POSITION_ID,XA_ORDER_ID,XA_ENTRY,XA_TYPE,XA_PRICE,XA_VOLUME,XA_PROFIT,XA_COMMISSION,XA_FEE,XA_SWAP,XA_NET_SERVER,XA_NET_AUDITED,XA_COMMENT,XA_IDENTITY_STATUS,XA_OBJECT_NAME,XA_OBJECT_TYPE,XA_OBJECT_TIME1,XA_OBJECT_PRICE1,XA_OBJECT_TIME2,XA_OBJECT_PRICE2,XA_OBJECT_TEXT,XA_OBJECT_COLOR,XA_TICKET,XA_POSITION_MAGIC,XA_POSITION_TYPE,XA_POSITION_VOLUME,XA_POSITION_OPEN,XA_POSITION_CURRENT,XA_POSITION_SL,XA_POSITION_TP,XA_POSITION_PROFIT,XA_POSITION_SWAP,XA_POSITION_COMMENT,XA_BID,XA_ASK,XA_LAST,XA_SPREAD_POINTS,XA_CONTRACTS_BUY,XA_CONTRACTS_SELL,XA_OPEN_BUY,XA_OPEN_SELL,XA_REALIZED_BUY,XA_REALIZED_SELL,XA_BALANCE_HEAD,XA_STATUS,XA_TOTAL
};

void Exp306CamposInit(string &c[],int total)
{
   ArrayResize(c,total);
   for(int i=0;i<total;i++) c[i]="";
}

void Exp306EscreverCampos(int handle,string &c[])
{
   if(handle==INVALID_HANDLE) return;
   string linha="";
   for(int i=0;i<ArraySize(c);i++)
   {
      if(i>0) linha+=";";
      linha+=SanitizarCampoCSV(c[i]);
   }
   FileWriteString(handle,linha+"\r\n");
}

string Exp306DataCompacta(datetime t)
{
   MqlDateTime d; TimeToStruct(t,d);
   return StringFormat("%04d%02d%02d",d.year,d.mon,d.day);
}

string Exp306DataHoraCompacta(datetime t)
{
   MqlDateTime d; TimeToStruct(t,d);
   return StringFormat("%04d%02d%02d_%02d%02d%02d",d.year,d.mon,d.day,d.hour,d.min,d.sec);
}

datetime Exp306InicioSemana(datetime t)
{
   MqlDateTime d; TimeToStruct(t,d);
   d.hour=0; d.min=0; d.sec=0;
   datetime dia=StructToTime(d);
   int volta=(d.day_of_week+6)%7; // segunda=0
   return dia-(datetime)(volta*86400);
}

datetime Exp306MinTime(datetime a,datetime b){ return a<b?a:b; }
datetime Exp306MaxTime(datetime a,datetime b){ return a>b?a:b; }

string Exp306NomeBaseSemana()
{
   string symbolLimpo=SanitizarNomeArquivoBase(_Symbol);
   // FIX309: ESM2_ATIVO_JANELA_M<magic>_R<execucao>_W<inicio>-<fim>.
   // Identidade completa permanece nas colunas group_id, generation_id, cycle_id, magic e position_id.
   return StringFormat("%s_%s_%s_M%d_R%s_W%s-%s",
                       g_exp306PrefixoArquivo,symbolLimpo,Aud302JanelaLocal(),
                       (int)Aud302MagicLocal(),g_exp306RunId,
                       Exp306DataCompacta(g_exp306WeekDataStart),
                       Exp306DataCompacta(g_exp306WeekDataEnd));
}

int Exp306FlagsArquivo()
{
   int f=FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE;
   if(InpExportacaoArquivoComumFIX306) f|=FILE_COMMON;
   return f;
}

void Exp306Manifesto(string tipo,string arquivo,string status,long registros,string detalhe)
{
   if(g_exp306ManifestHandle==INVALID_HANDLE) return;
   string c[]; Exp306CamposInit(c,8);
   c[0]=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
   c[1]=g_exp306ExportId; c[2]=tipo; c[3]=arquivo; c[4]=status;
   c[5]=IntegerToString(registros); c[6]=Aud302JanelaLocal(); c[7]=detalhe;
   Exp306EscreverCampos(g_exp306ManifestHandle,c);
}

void Exp306AudInit(string &c[],string tipo)
{
   Exp306CamposInit(c,XA_TOTAL);
   c[XA_RECORD_TYPE]=tipo;
   c[XA_EXPORT_ID]=g_exp306ExportId;
   c[XA_EXPORTED_AT]=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
   c[XA_WEEK_START]=TimeToString(g_exp306WeekDataStart,TIME_DATE|TIME_SECONDS);
   c[XA_WEEK_END]=TimeToString(g_exp306WeekDataEnd,TIME_DATE|TIME_SECONDS);
   c[XA_ACCOUNT]=IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   c[XA_SERVER]=AccountInfoString(ACCOUNT_SERVER);
   c[XA_CURRENCY]=AccountInfoString(ACCOUNT_CURRENCY);
   c[XA_SYMBOL]=_Symbol;
   c[XA_CHART_ID]=IntegerToString((long)ChartID());
   c[XA_CHART_PERIOD]=EnumToString((ENUM_TIMEFRAMES)Period());
   c[XA_WINDOW]=Aud302JanelaLocal();
   c[XA_MOTOR]=Aud302LadoLocal();
   c[XA_MAGIC_LOCAL]=IntegerToString((int)Aud302MagicLocal());
   c[XA_MAGIC_A]=IntegerToString((int)MagicCompraAtual());
   c[XA_MAGIC_B]=IntegerToString((int)MagicVendaAtual());
   c[XA_GROUP]=g_identidadeGrupoFIX304;
   c[XA_GENERATION]=g_identidadeGeracaoFIX304;
   c[XA_SCENARIO]=Aud302Cenario();
   MqlTick tk; if(SymbolInfoTick(_Symbol,tk))
   {
      c[XA_BID]=DoubleToString(tk.bid,_Digits); c[XA_ASK]=DoubleToString(tk.ask,_Digits); c[XA_LAST]=DoubleToString(tk.last,_Digits);
      if(_Point>0.0) c[XA_SPREAD_POINTS]=DoubleToString((tk.ask-tk.bid)/_Point,1);
   }
   c[XA_CONTRACTS_BUY]=DoubleToString(g_compra.contratos,2);
   c[XA_CONTRACTS_SELL]=DoubleToString(g_venda.contratos,2);
   c[XA_OPEN_BUY]=DoubleToString(g_compra.resultadoAberto,2);
   c[XA_OPEN_SELL]=DoubleToString(g_venda.resultadoAberto,2);
   c[XA_REALIZED_BUY]=DoubleToString(g_parciaisCicloBuy,2);
   c[XA_REALIZED_SELL]=DoubleToString(g_parciaisCicloSell,2);
   c[XA_BALANCE_HEAD]=DoubleToString(g_parciaisCicloBuy+g_parciaisCicloSell+g_compra.resultadoAberto+g_venda.resultadoAberto,2);
}

void Exp306EscreverMeta(string chave,string valor,string status="OK")
{
   string c[]; Exp306AudInit(c,"META");
   c[XA_KEY]=chave; c[XA_VALUE]=valor; c[XA_STATUS]=status;
   Exp306EscreverCampos(g_exp306AuditHandle,c);
}

void Exp306EscreverCabecalhoBarras()
{
   string h[]; Exp306CamposInit(h,XB_TOTAL);
   string nomes[]={"export_id","exported_at","week_start","week_end","account_login","server","symbol","window","motor","magic_local","magic_a","magic_b","group_id","generation_id","scenario","timeframe","bar_time","bar_time_unix","bar_index_tf","open","high","low","close","tick_volume","real_volume","spread_points","range_points","body_points","upper_wick_points","lower_wick_points","close_change_points","gap_points","true_range_points","return_pct","log_return","typical_price","median_price","weighted_price","sma8","sma20","sma50","rsi14","atr14_points","volume_sma20","volume_ratio20","vwap_day","direction","day_of_week","hour","minute","is_new_day","bid_snapshot","ask_snapshot","last_snapshot","export_status"};
   for(int i=0;i<XB_TOTAL;i++) h[i]=nomes[i];
   Exp306EscreverCampos(g_exp306BarsHandle,h);
}

void Exp306EscreverCabecalhoAuditoria()
{
   string h[]; Exp306CamposInit(h,XA_TOTAL);
   string nomes[]={"record_type","export_id","exported_at","week_start","week_end","account_login","server","currency","symbol","chart_id","chart_period","window","motor","magic_local","magic_a","magic_b","group_id","generation_id","scenario","key","value","time","time_msc","cycle_id","level","deal","position_id","order_id","entry","type","price","volume","profit","commission_server","fee","swap","net_server","net_audited","comment","identity_status","object_name","object_type","object_time1","object_price1","object_time2","object_price2","object_text","object_color","ticket","position_magic","position_type","position_volume","position_open","position_current","sl","tp","position_profit","position_swap","position_comment","bid","ask","last","spread_points","contracts_buy","contracts_sell","open_buy","open_sell","realized_buy","realized_sell","balance_head","status"};
   for(int i=0;i<XA_TOTAL;i++) h[i]=nomes[i];
   Exp306EscreverCampos(g_exp306AuditHandle,h);
}

void Exp306EscreverMetadadosSemana()
{
   Exp306EscreverMeta("export_name",g_exp306Prefixo);
   Exp306EscreverMeta("export_version","FIX309_3.27");
   Exp306EscreverMeta("range_start",TimeToString(g_exp306RangeStart,TIME_DATE|TIME_SECONDS));
   Exp306EscreverMeta("range_end",TimeToString(g_exp306RangeEnd,TIME_DATE|TIME_SECONDS));
   Exp306EscreverMeta("timeframes","M1,M2,M3,M4,M5");
   Exp306EscreverMeta("digits",IntegerToString((int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS)));
   Exp306EscreverMeta("point",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_POINT),_Digits));
   Exp306EscreverMeta("tick_size",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),_Digits));
   Exp306EscreverMeta("tick_value",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE),8));
   Exp306EscreverMeta("contract_size",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE),2));
   Exp306EscreverMeta("volume_min",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),2));
   Exp306EscreverMeta("volume_max",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),2));
   Exp306EscreverMeta("volume_step",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),2));
   Exp306EscreverMeta("dx_period",IntegerToString(InpDXPeriodo));
   Exp306EscreverMeta("dx_media_period",IntegerToString(InpDXMediaPeriodo));
   Exp306EscreverMeta("dx_distance",DoubleToString(InpDXDistanciaMedia,2));
   Exp306EscreverMeta("target_side_brl",DoubleToString(InpFIX280AlvoPorPontaReais,2));
   Exp306EscreverMeta("gain_head_brl",DoubleToString(GainHeadEfetivoFIX362(),2));
   Exp306EscreverMeta("loss_head_brl",DoubleToString(LossHeadEfetivoFIX362(),2));
   Exp306EscreverMeta("trail_activate_brl",DoubleToString(InpFIX280TrailingAtivarReais,2));
   Exp306EscreverMeta("trail_step_brl",DoubleToString(InpFIX280TrailingPassoReais,2));
   Exp306EscreverMeta("commission_mode",NomeModoComissaoFIX305());
   Exp306EscreverMeta("commission_round_trip_contract_brl",DoubleToString(InpComissaoIdaVoltaPorContratoReaisFIX305,2));
   Exp306EscreverMeta("filters_profile",InpPerfilFiltrosAuditoriaFIX302);
   Exp306EscreverMeta("a1",InpA1); Exp306EscreverMeta("a2",InpA2); Exp306EscreverMeta("a3",InpA3); Exp306EscreverMeta("a4",InpA4); Exp306EscreverMeta("a5",InpA5);
}

bool Exp306AbrirSemana()
{
   g_exp306WeekDataStart=Exp306MaxTime(g_exp306WeekStart,g_exp306RangeStart);
   g_exp306WeekDataEnd=Exp306MinTime(g_exp306WeekStart+(datetime)(7*86400-1),g_exp306RangeEnd);
   if(g_exp306WeekDataStart>g_exp306WeekDataEnd) return false;
   string base=Exp306NomeBaseSemana();
   g_exp306BarsArquivo=base+"_BARRAS_M1_M5.csv";
   g_exp306AuditArquivo=base+"_AUDITORIA.csv";
   ResetLastError(); g_exp306BarsHandle=FileOpen(g_exp306BarsArquivo,Exp306FlagsArquivo()); int e1=GetLastError();
   ResetLastError(); g_exp306AuditHandle=FileOpen(g_exp306AuditArquivo,Exp306FlagsArquivo()); int e2=GetLastError();
   if(g_exp306BarsHandle==INVALID_HANDLE || g_exp306AuditHandle==INVALID_HANDLE)
   {
      if(g_exp306BarsHandle!=INVALID_HANDLE){FileClose(g_exp306BarsHandle);g_exp306BarsHandle=INVALID_HANDLE;}
      if(g_exp306AuditHandle!=INVALID_HANDLE){FileClose(g_exp306AuditHandle);g_exp306AuditHandle=INVALID_HANDLE;}
      g_exp306Falhas++; g_exp306Status=StringFormat("ERRO ABRIR SEMANA %d/%d",e1,e2);
      Exp306Manifesto("SEMANA",base,"ERRO",0,g_exp306Status);
      return false;
   }
   Exp306EscreverCabecalhoBarras(); Exp306EscreverCabecalhoAuditoria(); Exp306EscreverMetadadosSemana();
   g_exp306TfIndex=0; g_exp306TfCarregado=false; g_exp306TfTentativas=0;
   g_exp306BarrasSemana=0; g_exp306DealsSemana=0; g_exp306PosicoesSemana=0; g_exp306ObjetosSemana=0;
   g_exp306Fase=EXP306_BARRAS;
   g_exp306Status=StringFormat("SEM %d/%d PREPARANDO M1",g_exp306SemanaAtual,g_exp306SemanasTotal);
   return true;
}

void Exp306FecharHandlesSemana(bool flush=true)
{
   if(g_exp306BarsHandle!=INVALID_HANDLE){if(flush)FileFlush(g_exp306BarsHandle);FileClose(g_exp306BarsHandle);g_exp306BarsHandle=INVALID_HANDLE;}
   if(g_exp306AuditHandle!=INVALID_HANDLE){if(flush)FileFlush(g_exp306AuditHandle);FileClose(g_exp306AuditHandle);g_exp306AuditHandle=INVALID_HANDLE;}
}

double Exp306SMAClose(int i,int p)
{
   if(p<=0 || i-p+1<0) return 0.0; double s=0.0;
   for(int k=i-p+1;k<=i;k++) s+=g_exp306Rates[k].close;
   return s/(double)p;
}

double Exp306SMAVolume(int i,int p)
{
   if(p<=0 || i-p+1<0) return 0.0; double s=0.0;
   for(int k=i-p+1;k<=i;k++) s+=(double)(g_exp306Rates[k].real_volume>0?g_exp306Rates[k].real_volume:g_exp306Rates[k].tick_volume);
   return s/(double)p;
}

double Exp306TR(int i)
{
   if(i<0) return 0.0;
   double tr=g_exp306Rates[i].high-g_exp306Rates[i].low;
   if(i>0)
   {
      tr=MathMax(tr,MathAbs(g_exp306Rates[i].high-g_exp306Rates[i-1].close));
      tr=MathMax(tr,MathAbs(g_exp306Rates[i].low-g_exp306Rates[i-1].close));
   }
   return tr;
}

double Exp306ATR(int i,int p)
{
   if(p<=0 || i-p+1<0) return 0.0; double s=0.0;
   for(int k=i-p+1;k<=i;k++) s+=Exp306TR(k);
   return s/(double)p;
}

double Exp306RSI(int i,int p)
{
   if(p<=0 || i-p<0) return 0.0; double gain=0.0,loss=0.0;
   for(int k=i-p+1;k<=i;k++)
   {
      double d=g_exp306Rates[k].close-g_exp306Rates[k-1].close;
      if(d>0) gain+=d; else loss-=d;
   }
   if(loss<=0.0) return gain>0.0?100.0:50.0;
   double rs=(gain/(double)p)/(loss/(double)p);
   return 100.0-(100.0/(1.0+rs));
}

bool Exp306CarregarTF()
{
   if(g_exp306TfIndex>=5) return false;
   ENUM_TIMEFRAMES tf=g_exp306TFs[g_exp306TfIndex];
   datetime warm=InicioDoDia(g_exp306WeekDataStart)-(datetime)(2*86400);
   ArrayFree(g_exp306Rates); ArraySetAsSeries(g_exp306Rates,false);
   ResetLastError(); int n=CopyRates(_Symbol,tf,warm,g_exp306WeekDataEnd,g_exp306Rates); int err=GetLastError();
   if(n<=0)
   {
      g_exp306TfTentativas++;
      g_exp306Status=StringFormat("AGUARDANDO %s TENT %d ERRO %d",NomeTimeframeBaseHistorica(tf),g_exp306TfTentativas,err);
      if(g_exp306TfTentativas<4) return false;
      string c[]; Exp306AudInit(c,"ERRO_SERIE"); c[XA_KEY]=NomeTimeframeBaseHistorica(tf); c[XA_VALUE]=IntegerToString(err); c[XA_STATUS]="SEM_DADOS"; Exp306EscreverCampos(g_exp306AuditHandle,c);
      g_exp306Falhas++; g_exp306TfIndex++; g_exp306TfTentativas=0; g_exp306TfCarregado=false;
      return false;
   }
   g_exp306RateTotal=n; g_exp306RateCursor=0; g_exp306BarIndexTF=0; g_exp306VwapDia=0; g_exp306VwapPV=0.0; g_exp306VwapVol=0.0;
   datetime diaInicio=InicioDoDia(g_exp306WeekDataStart);
   while(g_exp306RateCursor<n && g_exp306Rates[g_exp306RateCursor].time<diaInicio) g_exp306RateCursor++;
   g_exp306TfCarregado=true; g_exp306TfTentativas=0;
   g_exp306Status=StringFormat("SEM %d/%d %s 0/%d",g_exp306SemanaAtual,g_exp306SemanasTotal,NomeTimeframeBaseHistorica(tf),n);
   return true;
}

void Exp306EscreverBarra(int i,ENUM_TIMEFRAMES tf,double vwap)
{
   MqlRates r=g_exp306Rates[i]; string c[]; Exp306CamposInit(c,XB_TOTAL);
   MqlDateTime d; TimeToStruct(r.time,d);
   double pt=_Point>0.0?_Point:1.0; double prev=i>0?g_exp306Rates[i-1].close:r.open;
   double range=(r.high-r.low)/pt,body=(r.close-r.open)/pt;
   double upper=(r.high-MathMax(r.open,r.close))/pt,lower=(MathMin(r.open,r.close)-r.low)/pt;
   double ch=(r.close-prev)/pt,gap=(r.open-prev)/pt,tr=Exp306TR(i)/pt;
   double ret=(prev!=0.0?(r.close/prev-1.0)*100.0:0.0); double logr=(prev>0.0&&r.close>0.0?MathLog(r.close/prev):0.0);
   double typical=(r.high+r.low+r.close)/3.0,median=(r.high+r.low)/2.0,weighted=(r.high+r.low+2.0*r.close)/4.0;
   double vol=(double)(r.real_volume>0?r.real_volume:r.tick_volume),vma=Exp306SMAVolume(i,20),vr=vma>0.0?vol/vma:0.0;
   MqlTick tk; ZeroMemory(tk); SymbolInfoTick(_Symbol,tk);
   c[XB_EXPORT_ID]=g_exp306ExportId; c[XB_EXPORTED_AT]=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
   c[XB_WEEK_START]=TimeToString(g_exp306WeekDataStart,TIME_DATE|TIME_SECONDS); c[XB_WEEK_END]=TimeToString(g_exp306WeekDataEnd,TIME_DATE|TIME_SECONDS);
   c[XB_ACCOUNT]=IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)); c[XB_SERVER]=AccountInfoString(ACCOUNT_SERVER); c[XB_SYMBOL]=_Symbol;
   c[XB_WINDOW]=Aud302JanelaLocal(); c[XB_MOTOR]=Aud302LadoLocal(); c[XB_MAGIC]=IntegerToString((int)Aud302MagicLocal()); c[XB_MAGIC_A]=IntegerToString((int)MagicCompraAtual()); c[XB_MAGIC_B]=IntegerToString((int)MagicVendaAtual());
   c[XB_GROUP]=g_identidadeGrupoFIX304; c[XB_GENERATION]=g_identidadeGeracaoFIX304; c[XB_SCENARIO]=Aud302Cenario(); c[XB_TIMEFRAME]=NomeTimeframeBaseHistorica(tf);
   c[XB_BAR_TIME]=TimeToString(r.time,TIME_DATE|TIME_SECONDS); c[XB_BAR_UNIX]=IntegerToString((long)r.time); c[XB_BAR_INDEX]=IntegerToString(g_exp306BarIndexTF++);
   c[XB_OPEN]=DoubleToString(r.open,_Digits); c[XB_HIGH]=DoubleToString(r.high,_Digits); c[XB_LOW]=DoubleToString(r.low,_Digits); c[XB_CLOSE]=DoubleToString(r.close,_Digits);
   c[XB_TICK_VOLUME]=IntegerToString((long)r.tick_volume); c[XB_REAL_VOLUME]=IntegerToString((long)r.real_volume); c[XB_SPREAD_POINTS]=IntegerToString((int)r.spread);
   c[XB_RANGE_POINTS]=DoubleToString(range,2); c[XB_BODY_POINTS]=DoubleToString(body,2); c[XB_UPPER_WICK_POINTS]=DoubleToString(upper,2); c[XB_LOWER_WICK_POINTS]=DoubleToString(lower,2);
   c[XB_CLOSE_CHANGE_POINTS]=DoubleToString(ch,2); c[XB_GAP_POINTS]=DoubleToString(gap,2); c[XB_TRUE_RANGE_POINTS]=DoubleToString(tr,2); c[XB_RETURN_PCT]=DoubleToString(ret,8); c[XB_LOG_RETURN]=DoubleToString(logr,10);
   c[XB_TYPICAL_PRICE]=DoubleToString(typical,_Digits); c[XB_MEDIAN_PRICE]=DoubleToString(median,_Digits); c[XB_WEIGHTED_PRICE]=DoubleToString(weighted,_Digits);
   c[XB_SMA8]=DoubleToString(Exp306SMAClose(i,8),_Digits); c[XB_SMA20]=DoubleToString(Exp306SMAClose(i,20),_Digits); c[XB_SMA50]=DoubleToString(Exp306SMAClose(i,50),_Digits);
   c[XB_RSI14]=DoubleToString(Exp306RSI(i,14),4); c[XB_ATR14_POINTS]=DoubleToString(Exp306ATR(i,14)/pt,4); c[XB_VOLUME_SMA20]=DoubleToString(vma,2); c[XB_VOLUME_RATIO20]=DoubleToString(vr,6); c[XB_VWAP_DAY]=DoubleToString(vwap,_Digits);
   c[XB_DIRECTION]=r.close>r.open?"ALTA":(r.close<r.open?"BAIXA":"DOJI"); c[XB_DAY_OF_WEEK]=IntegerToString(d.day_of_week); c[XB_HOUR]=IntegerToString(d.hour); c[XB_MINUTE]=IntegerToString(d.min);
   c[XB_IS_NEW_DAY]=(i==0 || InicioDoDia(r.time)!=InicioDoDia(g_exp306Rates[i-1].time))?"SIM":"NAO";
   c[XB_BID_SNAPSHOT]=DoubleToString(tk.bid,_Digits); c[XB_ASK_SNAPSHOT]=DoubleToString(tk.ask,_Digits); c[XB_LAST_SNAPSHOT]=DoubleToString(tk.last,_Digits); c[XB_EXPORT_STATUS]="OK";
   Exp306EscreverCampos(g_exp306BarsHandle,c);
}

void Exp306ProcessarBarras(ulong limiteUs)
{
   if(g_exp306TfIndex>=5){g_exp306Fase=EXP306_DEALS;ArrayFree(g_exp306Rates);return;}
   if(!g_exp306TfCarregado){if(!Exp306CarregarTF()) return;}
   ENUM_TIMEFRAMES tf=g_exp306TFs[g_exp306TfIndex]; ulong ini=GetMicrosecondCount(); int escritos=0;
   int lote=InpExportacaoLoteBarrasFIX306; if(lote<25)lote=25; if(lote>2000)lote=2000;
   while(g_exp306RateCursor<g_exp306RateTotal)
   {
      MqlRates r=g_exp306Rates[g_exp306RateCursor]; MqlDateTime d; TimeToStruct(r.time,d); long dia=(long)InicioDoDia(r.time);
      if(dia!=g_exp306VwapDia){g_exp306VwapDia=dia;g_exp306VwapPV=0.0;g_exp306VwapVol=0.0;}
      double vol=(double)(r.real_volume>0?r.real_volume:r.tick_volume); double typical=(r.high+r.low+r.close)/3.0;
      g_exp306VwapPV+=typical*vol; g_exp306VwapVol+=vol; double vwap=g_exp306VwapVol>0.0?g_exp306VwapPV/g_exp306VwapVol:typical;
      if(r.time>=g_exp306WeekDataStart && r.time<=g_exp306WeekDataEnd)
      {
         Exp306EscreverBarra(g_exp306RateCursor,tf,vwap); escritos++; g_exp306BarrasSemana++; g_exp306TotalBarras++;
      }
      g_exp306RateCursor++;
      if(escritos>=lote) break;
      ulong agora=GetMicrosecondCount(); if(agora>=ini && agora-ini>=limiteUs) break;
   }
   g_exp306Status=StringFormat("SEM %d/%d %s %d/%d",g_exp306SemanaAtual,g_exp306SemanasTotal,NomeTimeframeBaseHistorica(tf),g_exp306RateCursor,g_exp306RateTotal);
   if(g_exp306RateCursor>=g_exp306RateTotal)
   {
      FileFlush(g_exp306BarsHandle); g_exp306TfIndex++; g_exp306TfCarregado=false; ArrayFree(g_exp306Rates);
   }
}

void Exp306PrepararDeals()
{
   ArrayFree(g_exp306Deals); g_exp306DealCursor=0;
   if(!HistorySelect(g_exp306WeekDataStart,g_exp306WeekDataEnd+1)) return;
   int n=HistoryDealsTotal();
   for(int i=0;i<n;i++)
   {
      ulong d=HistoryDealGetTicket(i); if(d==0)continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=_Symbol)continue;
      int z=ArraySize(g_exp306Deals); ArrayResize(g_exp306Deals,z+1); g_exp306Deals[z]=d;
   }
}

void Exp306EscreverDeal(ulong deal)
{
   if(deal==0 || !HistoryDealSelect(deal)) return;
   string c[]; Exp306AudInit(c,"DEAL"); long magic=HistoryDealGetInteger(deal,DEAL_MAGIC); string cm=HistoryDealGetString(deal,DEAL_COMMENT);
   c[XA_TIME]=TimeToString((datetime)HistoryDealGetInteger(deal,DEAL_TIME),TIME_DATE|TIME_SECONDS); c[XA_TIME_MSC]=IntegerToString((long)HistoryDealGetInteger(deal,DEAL_TIME_MSC));
   c[XA_CYCLE]=ExtrairCicloComentarioFIX304(cm); int nivel=NivelAumentoComentarioFIX207(cm); if(nivel<0)nivel=0; c[XA_LEVEL]=IntegerToString(nivel);
   c[XA_DEAL]=IntegerToString((long)deal); c[XA_POSITION_ID]=IntegerToString((long)HistoryDealGetInteger(deal,DEAL_POSITION_ID)); c[XA_ORDER_ID]=IntegerToString((long)HistoryDealGetInteger(deal,DEAL_ORDER));
   c[XA_ENTRY]=IntegerToString((int)HistoryDealGetInteger(deal,DEAL_ENTRY)); c[XA_TYPE]=IntegerToString((int)HistoryDealGetInteger(deal,DEAL_TYPE));
   c[XA_PRICE]=DoubleToString(HistoryDealGetDouble(deal,DEAL_PRICE),_Digits); c[XA_VOLUME]=DoubleToString(HistoryDealGetDouble(deal,DEAL_VOLUME),2);
   c[XA_PROFIT]=DoubleToString(HistoryDealGetDouble(deal,DEAL_PROFIT),2); c[XA_COMMISSION]=DoubleToString(HistoryDealGetDouble(deal,DEAL_COMMISSION),2); c[XA_FEE]=DoubleToString(HistoryDealGetDouble(deal,DEAL_FEE),2); c[XA_SWAP]=DoubleToString(HistoryDealGetDouble(deal,DEAL_SWAP),2);
   c[XA_NET_SERVER]=DoubleToString(ResultadoDealServidorFIX305(deal),2);
   bool par=(magic==MagicCompraAtual()||magic==MagicVendaAtual()); c[XA_NET_AUDITED]=DoubleToString(par?ResultadoDealLiquidoAuditadoFIX305(deal):ResultadoDealServidorFIX305(deal),2);
   c[XA_COMMENT]=cm;
   if(par && ComentarioTemIdentidadeAtualFIX304(cm,magic)) c[XA_IDENTITY_STATUS]="IDENTIDADE_ATUAL";
   else if(par) c[XA_IDENTITY_STATUS]="LEGADO_REJEITADO";
   else c[XA_IDENTITY_STATUS]="OUTRO_MAGIC";
   c[XA_KEY]="deal_magic"; c[XA_VALUE]=IntegerToString((int)magic); c[XA_STATUS]="OK";
   Exp306EscreverCampos(g_exp306AuditHandle,c);
}

void Exp306ProcessarDeals(ulong limiteUs)
{
   if(ArraySize(g_exp306Deals)==0 && g_exp306DealCursor==0) Exp306PrepararDeals();
   ulong ini=GetMicrosecondCount(); int feitos=0;
   while(g_exp306DealCursor<ArraySize(g_exp306Deals))
   {
      Exp306EscreverDeal(g_exp306Deals[g_exp306DealCursor++]); feitos++; g_exp306DealsSemana++; g_exp306TotalDeals++;
      if(feitos>=100)break; ulong agora=GetMicrosecondCount(); if(agora>=ini && agora-ini>=limiteUs)break;
   }
   g_exp306Status=StringFormat("SEM %d/%d DEALS %d/%d",g_exp306SemanaAtual,g_exp306SemanasTotal,g_exp306DealCursor,ArraySize(g_exp306Deals));
   if(g_exp306DealCursor>=ArraySize(g_exp306Deals))
   {
      ArrayFree(g_exp306Deals); g_exp306DealCursor=0;
      bool ultima=(g_exp306WeekDataEnd>=g_exp306RangeEnd);
      g_exp306Fase=ultima?EXP306_POSICOES:EXP306_FECHAR_SEMANA;
   }
}

void Exp306EscreverPosicao(int index)
{
   ulong ticket=PositionGetTicket(index); if(ticket==0 || !PositionSelectByTicket(ticket))return;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)return;
   string c[]; Exp306AudInit(c,"POSITION"); long magic=PositionGetInteger(POSITION_MAGIC); string cm=PositionGetString(POSITION_COMMENT);
   c[XA_TIME]=TimeToString((datetime)PositionGetInteger(POSITION_TIME),TIME_DATE|TIME_SECONDS); c[XA_TIME_MSC]=IntegerToString((long)PositionGetInteger(POSITION_TIME_MSC)); c[XA_CYCLE]=ExtrairCicloComentarioFIX304(cm);
   c[XA_TICKET]=IntegerToString((long)ticket); c[XA_POSITION_ID]=IntegerToString((long)PositionGetInteger(POSITION_IDENTIFIER)); c[XA_POSITION_MAGIC]=IntegerToString((int)magic); c[XA_POSITION_TYPE]=IntegerToString((int)PositionGetInteger(POSITION_TYPE));
   c[XA_POSITION_VOLUME]=DoubleToString(PositionGetDouble(POSITION_VOLUME),2); c[XA_POSITION_OPEN]=DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),_Digits); c[XA_POSITION_CURRENT]=DoubleToString(PositionGetDouble(POSITION_PRICE_CURRENT),_Digits);
   c[XA_POSITION_SL]=DoubleToString(PositionGetDouble(POSITION_SL),_Digits); c[XA_POSITION_TP]=DoubleToString(PositionGetDouble(POSITION_TP),_Digits); c[XA_POSITION_PROFIT]=DoubleToString(PositionGetDouble(POSITION_PROFIT),2); c[XA_POSITION_SWAP]=DoubleToString(PositionGetDouble(POSITION_SWAP),2); c[XA_POSITION_COMMENT]=cm;
   c[XA_IDENTITY_STATUS]=(magic==MagicCompraAtual()||magic==MagicVendaAtual())?(ComentarioTemIdentidadeAtualFIX304(cm,magic)?"IDENTIDADE_ATUAL":"LEGADO_REJEITADO"):"OUTRO_MAGIC"; c[XA_STATUS]="SNAPSHOT_ATUAL";
   Exp306EscreverCampos(g_exp306AuditHandle,c); g_exp306PosicoesSemana++; g_exp306TotalPosicoes++;
}

void Exp306ProcessarPosicoes(ulong limiteUs)
{
   ulong ini=GetMicrosecondCount(); int n=PositionsTotal(),feitos=0;
   while(g_exp306PosCursor<n)
   {
      Exp306EscreverPosicao(g_exp306PosCursor++); feitos++;
      if(feitos>=25)break; ulong agora=GetMicrosecondCount(); if(agora>=ini&&agora-ini>=limiteUs)break;
   }
   g_exp306Status=StringFormat("SNAPSHOT POSICOES %d/%d",g_exp306PosCursor,n);
   if(g_exp306PosCursor>=n){g_exp306PosCursor=0;g_exp306Fase=EXP306_OBJETOS;}
}

void Exp306EscreverObjeto(int index)
{
   string nome=ObjectName(0,index,-1,-1); if(nome=="")return;
   string c[]; Exp306AudInit(c,"OBJECT"); long tipo=ObjectGetInteger(0,nome,OBJPROP_TYPE);
   c[XA_OBJECT_NAME]=nome; c[XA_OBJECT_TYPE]=EnumToString((ENUM_OBJECT)tipo);
   c[XA_OBJECT_TIME1]=TimeToString((datetime)ObjectGetInteger(0,nome,OBJPROP_TIME,0),TIME_DATE|TIME_SECONDS); c[XA_OBJECT_PRICE1]=DoubleToString(ObjectGetDouble(0,nome,OBJPROP_PRICE,0),_Digits);
   c[XA_OBJECT_TIME2]=TimeToString((datetime)ObjectGetInteger(0,nome,OBJPROP_TIME,1),TIME_DATE|TIME_SECONDS); c[XA_OBJECT_PRICE2]=DoubleToString(ObjectGetDouble(0,nome,OBJPROP_PRICE,1),_Digits);
   c[XA_OBJECT_TEXT]=ObjectGetString(0,nome,OBJPROP_TEXT); c[XA_OBJECT_COLOR]=IntegerToString((int)ObjectGetInteger(0,nome,OBJPROP_COLOR)); c[XA_STATUS]="SNAPSHOT_GRAFICO";
   Exp306EscreverCampos(g_exp306AuditHandle,c); g_exp306ObjetosSemana++; g_exp306TotalObjetos++;
}

void Exp306ProcessarObjetos(ulong limiteUs)
{
   ulong ini=GetMicrosecondCount(); int n=ObjectsTotal(0,-1,-1),feitos=0;
   while(g_exp306ObjCursor<n)
   {
      Exp306EscreverObjeto(g_exp306ObjCursor++); feitos++;
      if(feitos>=40)break; ulong agora=GetMicrosecondCount(); if(agora>=ini&&agora-ini>=limiteUs)break;
   }
   g_exp306Status=StringFormat("SNAPSHOT GRAFICO %d/%d",g_exp306ObjCursor,n);
   if(g_exp306ObjCursor>=n){g_exp306ObjCursor=0;g_exp306Fase=EXP306_FECHAR_SEMANA;}
}

void Exp306FecharSemana()
{
   string c[]; Exp306AudInit(c,"WEEK_SUMMARY"); c[XA_KEY]="counts";
   c[XA_VALUE]=StringFormat("bars=%I64d deals=%I64d positions=%I64d objects=%I64d",g_exp306BarrasSemana,g_exp306DealsSemana,g_exp306PosicoesSemana,g_exp306ObjetosSemana); c[XA_STATUS]=g_exp306Falhas==0?"OK":"COM_ALERTAS";
   Exp306EscreverCampos(g_exp306AuditHandle,c); FileFlush(g_exp306BarsHandle); FileFlush(g_exp306AuditHandle);
   Exp306Manifesto("BARRAS_M1_M5",g_exp306BarsArquivo,"OK",g_exp306BarrasSemana,TimeToString(g_exp306WeekDataStart,TIME_DATE)+" a "+TimeToString(g_exp306WeekDataEnd,TIME_DATE));
   Exp306Manifesto("AUDITORIA",g_exp306AuditArquivo,g_exp306Falhas==0?"OK":"COM_ALERTAS",g_exp306DealsSemana+g_exp306PosicoesSemana+g_exp306ObjetosSemana,"deals/posicoes/objetos/meta");
   Exp306FecharHandlesSemana(true);
   if(g_exp306WeekDataEnd>=g_exp306RangeEnd)
   {
      g_exp306Ativa=false; g_exp306Fase=EXP306_CONCLUIDO;
      g_exp306Status=StringFormat("CONCLUIDA | %I64d BARRAS | %I64d DEALS | FALHAS %d",g_exp306TotalBarras,g_exp306TotalDeals,g_exp306Falhas);
      Exp306Manifesto("EXPORTACAO","-",g_exp306Falhas==0?"CONCLUIDA":"CONCLUIDA_COM_ALERTAS",g_exp306TotalBarras,g_exp306Status);
      if(g_exp306ManifestHandle!=INVALID_HANDLE){FileFlush(g_exp306ManifestHandle);FileClose(g_exp306ManifestHandle);g_exp306ManifestHandle=INVALID_HANDLE;}
      Print("[AR100][FIX309][EXPORT] ",g_exp306Status," | Pasta=",InpExportacaoArquivoComumFIX306?"Terminal\\Common\\Files":"MQL5\\Files");
      return;
   }
   g_exp306WeekStart+=(datetime)(7*86400); g_exp306SemanaAtual++;
   if(!Exp306AbrirSemana())
   {
      g_exp306Ativa=false; g_exp306Fase=EXP306_ERRO;
      g_exp306Status="ENCERRADA: FALHA AO ABRIR ARQUIVOS DA PROXIMA SEMANA";
      Exp306Manifesto("EXPORTACAO","-","ERRO",g_exp306TotalBarras,g_exp306Status);
      if(g_exp306ManifestHandle!=INVALID_HANDLE){FileFlush(g_exp306ManifestHandle);FileClose(g_exp306ManifestHandle);g_exp306ManifestHandle=INVALID_HANDLE;}
   }
}

bool ExportacaoIniciarFIX306()
{
   if(!InpExportacaoSemanalMeses2FIX306) return false;
   if(g_exp306Ativa) return true;
   ExportacaoFecharFIX306();
   int meses=InpExportacaoMesesFIX306; if(meses<1)meses=1; if(meses>12)meses=12;
   g_exp306RangeEnd=FimBaseHistorica(); g_exp306RangeStart=g_exp306RangeEnd-(datetime)(meses*31*86400);
   g_exp306WeekStart=Exp306InicioSemana(g_exp306RangeStart); g_exp306SemanasTotal=(int)((g_exp306RangeEnd-g_exp306WeekStart)/(7*86400))+1; g_exp306SemanaAtual=1;
   g_exp306RunId=Exp306DataHoraCompacta(TimeCurrent()); g_exp306ExportId=StringFormat("%s_%s_%s_MAGIC%d_%s",g_exp306Prefixo,g_exp306RunId,Aud302JanelaLocal(),(int)Aud302MagicLocal(),g_identidadeGeracaoFIX304);
   string manifestBase=StringFormat("%s_%s_%s_M%d_R%s_MANIFESTO.csv",
                                    g_exp306PrefixoArquivo,SanitizarNomeArquivoBase(_Symbol),
                                    Aud302JanelaLocal(),(int)Aud302MagicLocal(),g_exp306RunId);
   g_exp306ManifestArquivo=manifestBase; g_exp306ManifestHandle=FileOpen(g_exp306ManifestArquivo,Exp306FlagsArquivo());
   if(g_exp306ManifestHandle!=INVALID_HANDLE) FileWriteString(g_exp306ManifestHandle,"time;export_id;type;file;status;records;window;detail\r\n");
   g_exp306TotalBarras=0;g_exp306TotalDeals=0;g_exp306TotalPosicoes=0;g_exp306TotalObjetos=0;g_exp306Falhas=0;g_exp306Inicio=TimeCurrent();g_exp306Ativa=true;
   if(InpExportacaoCapturarGraficoFIX306)
   {
      g_exp306ScreenshotArquivo=StringFormat("%s_%s_%s_M%d_R%s_GRAFICO.png",
                                               g_exp306PrefixoArquivo,SanitizarNomeArquivoBase(_Symbol),
                                               Aud302JanelaLocal(),(int)Aud302MagicLocal(),g_exp306RunId);
      bool ok=ChartScreenShot(0,g_exp306ScreenshotArquivo,1920,1080,ALIGN_RIGHT);
      Exp306Manifesto("GRAFICO_PNG",g_exp306ScreenshotArquivo,ok?"OK":"FALHOU",ok?1:0,"PNG salvo em MQL5\\Files do terminal desta janela");
      if(!ok)g_exp306Falhas++;
   }
   if(!Exp306AbrirSemana())
   {
      g_exp306Ativa=false;g_exp306Fase=EXP306_ERRO;g_exp306Status="ERRO AO ABRIR PRIMEIRA SEMANA";return false;
   }
   Print("[AR100][FIX309][EXPORT] INICIADA | ID=",g_exp306ExportId," | ",TimeToString(g_exp306RangeStart,TIME_DATE|TIME_SECONDS)," a ",TimeToString(g_exp306RangeEnd,TIME_DATE|TIME_SECONDS)," | M1-M5 | semanas=",g_exp306SemanasTotal);
   return true;
}

void ExportacaoProcessarTimerFIX306()
{
   if(!g_exp306Ativa) return;
   ulong limite=(ulong)InpExportacaoLimiteMicrosTimerFIX306; if(limite<5000)limite=5000; if(limite>100000)limite=100000;
   if(g_exp306Fase==EXP306_BARRAS) Exp306ProcessarBarras(limite);
   else if(g_exp306Fase==EXP306_DEALS) Exp306ProcessarDeals(limite);
   else if(g_exp306Fase==EXP306_POSICOES) Exp306ProcessarPosicoes(limite);
   else if(g_exp306Fase==EXP306_OBJETOS) Exp306ProcessarObjetos(limite);
   else if(g_exp306Fase==EXP306_FECHAR_SEMANA) Exp306FecharSemana();
}

void ExportacaoFecharFIX306()
{
   Exp306FecharHandlesSemana(true); ArrayFree(g_exp306Rates); ArrayFree(g_exp306Deals);
   if(g_exp306ManifestHandle!=INVALID_HANDLE){FileFlush(g_exp306ManifestHandle);FileClose(g_exp306ManifestHandle);g_exp306ManifestHandle=INVALID_HANDLE;}
   g_exp306Ativa=false;
}

string ExportacaoStatusCurtoFIX306()
{
   if(g_exp306Ativa) return "EXP ATIVA | "+g_exp306Status;
   if(g_exp306Fase==EXP306_CONCLUIDO) return "EXP OK | "+g_exp306Status;
   if(g_exp306Fase==EXP306_ERRO) return "EXP ERRO | "+g_exp306Status;
   return "EXP PARADA";
}

#endif
