// COPA V10 - Etapa 10: tela e clique da auditoria visual.
#ifndef COPA_V10_MODULOS_AUDITORIA_VISUAL_MQH
#define COPA_V10_MODULOS_AUDITORIA_VISUAL_MQH

void Aud302ObjetoTexto(string nome,string texto,int y,color cor,int fonte)
{
   if(ObjectFind(0,nome)<0) ObjectCreate(0,nome,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,nome,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,nome,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,18);
   ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,nome,OBJPROP_TEXT,texto);
   ObjectSetString(0,nome,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(0,nome,OBJPROP_FONTSIZE,fonte);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER,20000);
}

void AuditoriaLimparTelaFIX302()
{
   for(int i=0;i<20;i++) ObjectDelete(0,"COPA_AR100_AUD302_L"+IntegerToString(i));
   ObjectDelete(0,"COPA_AR100_AUD302_BG");
}

void AuditoriaAtualizarTelaFIX302(bool forcar)
{
   if(!g_aud302TelaAtiva)
   {
      AuditoriaLimparTelaFIX302();
      return;
   }
   if(ObjectFind(0,"COPA_AR100_AUD302_BG")<0) ObjectCreate(0,"COPA_AR100_AUD302_BG",OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_XDISTANCE,8);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_YDISTANCE,28);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_XSIZE,500);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_YSIZE,336);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_BGCOLOR,C'12,18,28');
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_BORDER_COLOR,C'50,150,220');
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_BACK,false);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,"COPA_AR100_AUD302_BG",OBJPROP_ZORDER,19999);
   int y=38;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L0",StringFormat("AUDITORIA FIX309 | %s %s | MAGIC %d",Aud302JanelaLocal(),Aud302LadoLocal(),(int)Aud302MagicLocal()),y,clrAqua,9); y+=20;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L1","GRUPO: "+g_identidadeGrupoFIX304+" | GER: "+g_identidadeGeracaoFIX304+" | MAGIC: "+IntegerToString((int)Aud302MagicLocal())+" | MOTOR: "+Aud302LadoLocal(),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L2","CENARIO: "+Aud302Cenario()+" | CICLO: "+AuditoriaIdCicloFIX302()+" | COM "+NomeModoComissaoFIX305()+" RT "+DoubleToString(InpComissaoIdaVoltaPorContratoReaisFIX305,2),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L3",StringFormat("FILA %d/%d | GRAV %d | DESC %d | ERRO ARQ %d",g_aud302FilaQtd,AUD302_FILA_MAX,g_aud302EventosGravados,g_aud302FilaDescartada,g_aud302FalhasArquivo),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L4",StringFormat("PERF TICK avg %I64u us max %I64u | TIMER avg %I64u max %I64u",AuditoriaMediaFIX302(g_aud302TickUsTotal,g_aud302Ticks),g_aud302TickUsMax,AuditoriaMediaFIX302(g_aud302TimerUsTotal,g_aud302Timers),g_aud302TimerUsMax),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L5",StringFormat("DISCO avg %I64u us max %I64u | TRADE avg %I64u max %I64u",AuditoriaMediaFIX302(g_aud302EscritaUsTotal,g_aud302LotesEscrita),g_aud302EscritaUsMax,AuditoriaMediaFIX302(g_aud302TradeUsTotal,g_aud302Trades),g_aud302TradeUsMax),y,clrWhite,8); y+=22;
   for(int n=0;n<6;n++)
   {
      color c=(g_aud302EntradaNivel[n]=="FALHOU" || g_aud302GraficoNivel[n]=="FALHOU" || g_aud302FinanceiroNivel[n]=="FALHOU") ? clrTomato : clrLightGreen;
      Aud302ObjetoTexto("COPA_AR100_AUD302_L"+IntegerToString(6+n),AuditoriaResumoNivelFIX302(n),y,c,7); y+=18;
   }
   double realC=g_parciaisCicloBuy,realV=g_parciaisCicloSell,abC=g_compra.resultadoAberto,abV=g_venda.resultadoAberto;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L12",StringFormat("QTD C %.0f V %.0f T %.0f | REAL C %.2f V %.2f AB %.2f",g_compra.contratos,g_venda.contratos,g_compra.contratos+g_venda.contratos,realC,realV,realC+realV),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L13",StringFormat("ABERTO C %.2f V %.2f AB %.2f | SALDO AB %.2f",abC,abV,abC+abV,realC+realV+abC+abV),y,clrWhite,8); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L14","ULTIMO: "+g_aud302UltimoEvento,y,clrGold,7); y+=18;
   Aud302ObjetoTexto("COPA_AR100_AUD302_L15",ExportacaoStatusCurtoFIX306(),y,g_exp306Ativa?clrAqua:(g_exp306Fase==EXP306_ERRO?clrTomato:clrLightGreen),7);
   if(forcar) ChartRedraw(0);
}

bool PainelCliqueAuditoriaFIX302(string objeto)
{
   if(StringFind(objeto,"_ABA_CSV")<0)
      return false;
   g_aud302TelaAtiva=!g_aud302TelaAtiva;
   bool iniciouExport=false;
   if(g_aud302TelaAtiva && InpExportacaoSemanalMeses2FIX306 && !g_exp306Ativa)
      iniciouExport=ExportacaoIniciarFIX306();
   if(g_aud302TelaAtiva)
      g_mestre.mensagemGeral=iniciouExport ? "AUDITORIA FIX309 ABERTA | EXPORTACAO_SEMANAL_MESES_2 INICIADA" : "AUDITORIA FIX309 ABERTA | "+ExportacaoStatusCurtoFIX306();
   else
      g_mestre.mensagemGeral="AUDITORIA FIX307 RECOLHIDA | EXPORTACAO CONTINUA NO TIMER | HEAD VISIVEL";
   AuditoriaAtualizarTelaFIX302(true);
   return true;
}

#endif
