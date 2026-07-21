#ifndef COPA_IDENTIFICACAO_NIVEIS_AUMENTOS_MQH
#define COPA_IDENTIFICACAO_NIVEIS_AUMENTOS_MQH

// ============================================================================
// RESPONSABILIDADE: IDENTIFICACAO DOS NIVEIS DOS AUMENTOS
// Funcoes movidas do principal na V44 sem alteracao de regra operacional.
// ============================================================================

int NivelAumentoComentarioFIX207(string comentario)
{
   string c=" "+Upper(comentario)+" ";
   StringReplace(c,"_"," ");
   StringReplace(c,"-"," ");
   StringReplace(c,"|"," ");
   StringReplace(c,";"," ");
   for(int nivel=1; nivel<=5; nivel++)
   {
      string marca=" A"+IntegerToString(nivel)+" ";
      if(StringFind(c,marca)>=0)
         return nivel;
   }
   return 0;
}

int NivelAumentoDealRobustoFIX296(ulong deal)
{
   if(deal==0)
      return 0;
   string simbolo=HistoryDealGetString(deal,DEAL_SYMBOL);
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(simbolo!=_Symbol || (magic!=MagicCompraAtual() && magic!=MagicVendaAtual() &&
                           magic!=MagicPainelAAtual() && magic!=MagicPainelBAtual()))
      return 0;

   int nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(deal,DEAL_COMMENT));
   if(nivel>0)
      return nivel;

   ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
   if(ordem>0)
   {
      string comentarioOrdem=HistoryOrderGetString(ordem,ORDER_COMMENT);
      nivel=NivelAumentoComentarioFIX207(comentarioOrdem);
      if(nivel>0)
         return nivel;
   }

   ulong identificador=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
   if(identificador==0)
      return 0;

   // Primeiro usa a selecao historica atual. Isso evita destruir a lista enquanto
   // ReconstruirRealizacoesAumentosCicloFIX281 percorre os deals do ciclo.
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong d=HistoryDealGetTicket(i);
      if(d==0 || d==deal)
         continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=simbolo)
         continue;
      if((long)HistoryDealGetInteger(d,DEAL_MAGIC)!=magic)
         continue;
      if((ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID)!=identificador)
         continue;
      long entrada=HistoryDealGetInteger(d,DEAL_ENTRY);
      if(entrada!=DEAL_ENTRY_IN && entrada!=DEAL_ENTRY_INOUT)
         continue;
      nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(d,DEAL_COMMENT));
      if(nivel<=0)
      {
         ulong ordemEntrada=(ulong)HistoryDealGetInteger(d,DEAL_ORDER);
         if(ordemEntrada>0)
            nivel=NivelAumentoComentarioFIX207(HistoryOrderGetString(ordemEntrada,ORDER_COMMENT));
      }
      if(nivel>0)
         return nivel;
   }

   // OnTradeTransaction pode ter somente o deal atual selecionado. Nesse caso,
   // abre uma janela curta e procura o deal de entrada pelo POSITION_IDENTIFIER.
   datetime horaDeal=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
   datetime inicio=horaDeal-(datetime)(7*86400);
   if(inicio<0) inicio=0;
   datetime fim=TimeCurrent()+60;
   if(fim<horaDeal) fim=horaDeal+60;
   if(!HistorySelect(inicio,fim))
      return 0;
   total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong d=HistoryDealGetTicket(i);
      if(d==0)
         continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=simbolo)
         continue;
      if((long)HistoryDealGetInteger(d,DEAL_MAGIC)!=magic)
         continue;
      if((ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID)!=identificador)
         continue;
      long entrada=HistoryDealGetInteger(d,DEAL_ENTRY);
      if(entrada!=DEAL_ENTRY_IN && entrada!=DEAL_ENTRY_INOUT)
         continue;
      nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(d,DEAL_COMMENT));
      if(nivel<=0)
      {
         ulong ordemEntrada=(ulong)HistoryDealGetInteger(d,DEAL_ORDER);
         if(ordemEntrada>0)
            nivel=NivelAumentoComentarioFIX207(HistoryOrderGetString(ordemEntrada,ORDER_COMMENT));
      }
      if(nivel>0)
         return nivel;
   }
   return 0;
}

int NivelAumentoPosicaoFIX212(EstadoLado &estado, ulong ticket, string comentario)
{
   int nivel=NivelAumentoComentarioFIX207(comentario);
   if(nivel>0)
      return nivel;
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return 0;
   long tipoAtual=PositionGetInteger(POSITION_TYPE);
   datetime horaAtual=(datetime)PositionGetInteger(POSITION_TIME);
   double precoAtual=PositionGetDouble(POSITION_PRICE_OPEN);
   int anteriores=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong outro=PositionGetTicket(i);
      if(outro==0 || outro==ticket || !PositionSelectByTicket(outro))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=tipoAtual)
         continue;
      datetime horaOutro=(datetime)PositionGetInteger(POSITION_TIME);
      if(horaOutro<horaAtual || (horaOutro==horaAtual && outro<ticket))
         anteriores++;
   }
   if(anteriores<=0)
      return 0;
   int melhorNivel=0;
   double melhorDiferenca=1.0e100;
   for(int n=1; n<=5 && (n-1)<ArraySize(g_aumentos); n++)
   {
      if(!g_aumentos[n-1].ativa)
         continue;
      double esperado=PrecoNivelAumentoValorIndice(estado,n-1);
      if(esperado<=0.0)
         continue;
      double diferenca=MathAbs(precoAtual-esperado);
      if(diferenca<melhorDiferenca)
      {
         melhorDiferenca=diferenca;
         melhorNivel=n;
      }
   }
   if(melhorNivel>0)
      return melhorNivel;
   if(anteriores>=1 && anteriores<=5)
      return anteriores;
   return 0;
}

bool ObterPosicaoAumentoNivelFIX212(EstadoLado &estado, int nivel, ulong &ticket, double &precoEntrada, double &volume, long &tipo)
{
   ticket=0;
   precoEntrada=0.0;
   volume=0.0;
   tipo=-1;
   if(nivel<1 || nivel>5)
      return false;
   datetime melhorHora=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong t=PositionGetTicket(i);
      if(t==0 || !PositionSelectByTicket(t))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      long tp=PositionGetInteger(POSITION_TYPE);
      if(estado.lado==LADO_COMPRA && tp!=POSITION_TYPE_BUY)
         continue;
      if(estado.lado==LADO_VENDA && tp!=POSITION_TYPE_SELL)
         continue;
      string comentario=PositionGetString(POSITION_COMMENT);
      int n=NivelAumentoPosicaoFIX212(estado,t,comentario);
      if(n!=nivel)
         continue;
      if(!PositionSelectByTicket(t))
         continue;
      tp=PositionGetInteger(POSITION_TYPE);
      datetime h=(datetime)PositionGetInteger(POSITION_TIME);
      if(ticket==0 || h>=melhorHora)
      {
         ticket=t;
         melhorHora=h;
         precoEntrada=PositionGetDouble(POSITION_PRICE_OPEN);
         volume=PositionGetDouble(POSITION_VOLUME);
         tipo=tp;
      }
   }
   return (ticket>0 && precoEntrada>0.0 && volume>0.0);
}

#endif // COPA_IDENTIFICACAO_NIVEIS_AUMENTOS_MQH
