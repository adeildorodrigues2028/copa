#ifndef COPA_RECONSTRUCAO_FINANCEIRA_CICLO_MQH
#define COPA_RECONSTRUCAO_FINANCEIRA_CICLO_MQH

// ============================================================================
// RESPONSABILIDADE: RECONSTRUCAO DE PARCIAIS E REALIZACOES DO CICLO
// Funcoes movidas do principal na V44 sem alteracao de regra operacional.
// ============================================================================

void ReconstruirParciaisCicloLadoFIX214(long magic, long tipoPosicao, datetime inicio, double &valorLiquido, double &valorNominal, int &quantidade)
{
   valorLiquido=0.0;
   valorNominal=0.0;
   quantidade=0;
   if(magic<=0 || inicio<=0)
      return;
   datetime fim=TimeCurrent();
   if(fim<=inicio || !HistorySelect(inicio,fim))
      return;
   ulong ordensContadas[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0)
         continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      datetime horario=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(horario<inicio || horario>fim)
         continue;
      valorLiquido+=ResultadoDealHistorico(deal);
      valorNominal+=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0)
         ordem=deal;
      bool jaContada=false;
      int n=ArraySize(ordensContadas);
      for(int j=0;j<n;j++)
      {
         if(ordensContadas[j]==ordem)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         ArrayResize(ordensContadas,n+1);
         ordensContadas[n]=ordem;
         quantidade++;
      }
   }
   valorLiquido=NormalizeDouble(valorLiquido,2);
   valorNominal=NormalizeDouble(valorNominal,2);
}

void ReconstruirRealizacoesAumentosCicloFIX281(long magic, long tipoPosicao, datetime inicio, double &financeiro, double &volume, int &quantidade)
{
   financeiro=0.0;
   volume=0.0;
   quantidade=0;
   if(magic<=0 || inicio<=0)
      return;
   datetime fim=TimeCurrent();
   if(fim<=inicio || !HistorySelect(inicio,fim))
      return;
   ulong ordensContadas[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      datetime horario=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(horario<inicio || horario>fim)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<=0)
         continue; // Saida de A0 ou deal externo: nao entra no contador de aumentos realizados.
      financeiro+=ResultadoDealHistorico(deal);
      volume+=HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0) ordem=deal;
      bool jaContada=false;
      for(int j=0;j<ArraySize(ordensContadas);j++)
      {
         if(ordensContadas[j]==ordem)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         int n=ArraySize(ordensContadas);
         ArrayResize(ordensContadas,n+1);
         ordensContadas[n]=ordem;
         quantidade++;
      }
   }
   financeiro=NormalizeDouble(financeiro,2);
   volume=NormalizeDouble(volume,2);
}

void ReconstruirRealizacoesAumentosPorNivelFIX324(long magic,
                                                   long tipoPosicao,
                                                   datetime inicio,
                                                   double &financeiroNivel[],
                                                   double &volumeNivel[],
                                                   int &quantidadeNivel[])
{
   for(int nivelZero=0;nivelZero<5;nivelZero++)
   {
      financeiroNivel[nivelZero]=0.0;
      volumeNivel[nivelZero]=0.0;
      quantidadeNivel[nivelZero]=0;
   }
   if(magic<=0 || inicio<=0 || !HistorySelect(inicio,TimeCurrent()+60))
      return;

   ulong ordensContadas[];
   int niveisContados[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(tipoPosicao==POSITION_TYPE_BUY && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(tipoPosicao==POSITION_TYPE_SELL && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<1 || nivel>5)
         continue;

      int idx=nivel-1;
      financeiroNivel[idx]+=ResultadoDealHistorico(deal);
      volumeNivel[idx]+=HistoryDealGetDouble(deal,DEAL_VOLUME);
      ulong ordem=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
      if(ordem==0) ordem=deal;
      bool jaContada=false;
      for(int j=0;j<ArraySize(ordensContadas);j++)
      {
         if(ordensContadas[j]==ordem && niveisContados[j]==nivel)
         {
            jaContada=true;
            break;
         }
      }
      if(!jaContada)
      {
         int n=ArraySize(ordensContadas);
         ArrayResize(ordensContadas,n+1);
         ArrayResize(niveisContados,n+1);
         ordensContadas[n]=ordem;
         niveisContados[n]=nivel;
         quantidadeNivel[idx]++;
      }
   }
   for(int idx=0;idx<5;idx++)
   {
      financeiroNivel[idx]=NormalizeDouble(financeiroNivel[idx],2);
      volumeNivel[idx]=NormalizeDouble(volumeNivel[idx],2);
   }
}

void ReconstruirMarcacaoAumentosRealizadosFIX296(EstadoLado &estado, datetime inicio)
{
   if(inicio<=0 || !HistorySelect(inicio,TimeCurrent()+60))
      return;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=estado.magic)
         continue;
      if(!DealEhSaidaParcial(HistoryDealGetInteger(deal,DEAL_ENTRY)))
         continue;
      long tipoDeal=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(estado.lado==LADO_COMPRA && tipoDeal!=DEAL_TYPE_SELL)
         continue;
      if(estado.lado==LADO_VENDA && tipoDeal!=DEAL_TYPE_BUY)
         continue;
      int nivel=NivelAumentoDealRobustoFIX296(deal);
      if(nivel<=0)
         continue;
      MarcarAumentoRealizadoFIX212(estado,nivel,HistoryDealGetDouble(deal,DEAL_PRICE));
   }
}

void SincronizarRealizacoesAumentosFIX296(bool forcar)
{
   datetime agora=TimeCurrent();
   if(!forcar && g_ultimaSincronizacaoRealizacoesAumentosFIX296>0 &&
      (agora-g_ultimaSincronizacaoRealizacoesAumentosFIX296)<1)
      return;
   g_ultimaSincronizacaoRealizacoesAumentosFIX296=agora;

   for(int idx=0;idx<5;idx++)
   {
      g_realizadoAumentosNivelBuyFIX324[idx]=0.0;
      g_realizadoAumentosNivelSellFIX324[idx]=0.0;
      g_volumeRealizadoNivelBuyFIX324[idx]=0.0;
      g_volumeRealizadoNivelSellFIX324[idx]=0.0;
      g_qtdRealizacoesNivelBuyFIX324[idx]=0;
      g_qtdRealizacoesNivelSellFIX324[idx]=0;
   }

   if(g_cicloInicioCompra>0)
   {
      double fin=0.0,vol=0.0; int qtd=0;
      ReconstruirRealizacoesAumentosCicloFIX281(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,fin,vol,qtd);
      g_realizadoAumentosCicloBuy=fin;
      g_volumeRealizadoAumentosCicloBuy=vol;
      g_qtdRealizacoesAumentosCicloBuy=qtd;
      ReconstruirRealizacoesAumentosPorNivelFIX324(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                                    g_realizadoAumentosNivelBuyFIX324,g_volumeRealizadoNivelBuyFIX324,g_qtdRealizacoesNivelBuyFIX324);
      ReconstruirMarcacaoAumentosRealizadosFIX296(g_compra,g_cicloInicioCompra);
   }
   if(g_cicloInicioVenda>0)
   {
      double fin=0.0,vol=0.0; int qtd=0;
      ReconstruirRealizacoesAumentosCicloFIX281(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,fin,vol,qtd);
      g_realizadoAumentosCicloSell=fin;
      g_volumeRealizadoAumentosCicloSell=vol;
      g_qtdRealizacoesAumentosCicloSell=qtd;
      ReconstruirRealizacoesAumentosPorNivelFIX324(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                                    g_realizadoAumentosNivelSellFIX324,g_volumeRealizadoNivelSellFIX324,g_qtdRealizacoesNivelSellFIX324);
      ReconstruirMarcacaoAumentosRealizadosFIX296(g_venda,g_cicloInicioVenda);
   }
}

void RestaurarParciaisCicloAbertoFIX214()
{
   if(g_compra.posicaoAberta)
   {
      ReconstruirParciaisCicloLadoFIX214(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                         g_parciaisCicloBuy,g_parciaisNominaisCicloBuy,g_qtdParciaisCicloBuy);
      ReconstruirRealizacoesAumentosCicloFIX281(MagicCompraAtual(),POSITION_TYPE_BUY,g_cicloInicioCompra,
                                                g_realizadoAumentosCicloBuy,g_volumeRealizadoAumentosCicloBuy,g_qtdRealizacoesAumentosCicloBuy);
   }
   if(g_venda.posicaoAberta)
   {
      ReconstruirParciaisCicloLadoFIX214(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                         g_parciaisCicloSell,g_parciaisNominaisCicloSell,g_qtdParciaisCicloSell);
      ReconstruirRealizacoesAumentosCicloFIX281(MagicVendaAtual(),POSITION_TYPE_SELL,g_cicloInicioVenda,
                                                g_realizadoAumentosCicloSell,g_volumeRealizadoAumentosCicloSell,g_qtdRealizacoesAumentosCicloSell);
   }
   g_totalCicloMestreSimples=g_parciaisCicloBuy+g_parciaisCicloSell;
   RegistrarLogValidacaoSistema("FIX214_PARCIAIS_RESTAURADAS",
      StringFormat("BUY liq %s / nom %s / %d | SELL liq %s / nom %s / %d | TOTAL LIQ %s",
                   PnlMoedaBRL(g_parciaisCicloBuy),PnlMoedaBRL(g_parciaisNominaisCicloBuy),g_qtdParciaisCicloBuy,
                   PnlMoedaBRL(g_parciaisCicloSell),PnlMoedaBRL(g_parciaisNominaisCicloSell),g_qtdParciaisCicloSell,
                   PnlMoedaBRL(g_totalCicloMestreSimples)));
   RegistrarLogValidacaoSistema("FIX281_AUMENTOS_RESTAURADOS",
      StringFormat("BUY QTD %d VOL %.2f FIN %s | SELL QTD %d VOL %.2f FIN %s",
                   g_qtdRealizacoesAumentosCicloBuy,g_volumeRealizadoAumentosCicloBuy,PnlMoedaBRL(g_realizadoAumentosCicloBuy),
                   g_qtdRealizacoesAumentosCicloSell,g_volumeRealizadoAumentosCicloSell,PnlMoedaBRL(g_realizadoAumentosCicloSell)));
}

void AtualizarCicloMestreSimplesFIX195()
{
   if(!g_cicloMestreSimplesAtivo && CestaABTemAlgumaPosicaoFIX195())
   {
      g_cicloMestreSimplesAtivo=true;

      // FIX457: ao reiniciar o computador/MT5 com posição ainda aberta,
      // não iniciar o ciclo em TimeCurrent(). Isso apagava da reconstrução
      // todas as parciais realizadas antes do reinício. Recupera o horário
      // real mais antigo das posições abertas dos Magics 326050/326051.
      datetime inicioRealFIX457=0;
      for(int posFIX457=0; posFIX457<PositionsTotal(); posFIX457++)
      {
         ulong ticketFIX457=PositionGetTicket(posFIX457);
         if(ticketFIX457==0 || !PositionSelectByTicket(ticketFIX457))
            continue;
         if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
            continue;
         long magicFIX457=(long)PositionGetInteger(POSITION_MAGIC);
         if(magicFIX457!=MagicCompraAtual() && magicFIX457!=MagicVendaAtual())
            continue;
         datetime horaFIX457=(datetime)PositionGetInteger(POSITION_TIME);
         if(horaFIX457>0 && (inicioRealFIX457==0 || horaFIX457<inicioRealFIX457))
            inicioRealFIX457=horaFIX457;
         if(magicFIX457==MagicCompraAtual() && (g_cicloInicioCompra<=0 || horaFIX457<g_cicloInicioCompra))
            g_cicloInicioCompra=horaFIX457;
         if(magicFIX457==MagicVendaAtual() && (g_cicloInicioVenda<=0 || horaFIX457<g_cicloInicioVenda))
            g_cicloInicioVenda=horaFIX457;
      }
      if(inicioRealFIX457<=0)
         inicioRealFIX457=TimeCurrent();
      g_cicloMestreSimplesInicio=inicioRealFIX457;

      g_parciaisCicloBuy=0.0;
      g_parciaisCicloSell=0.0;
      g_qtdParciaisCicloBuy=0;
      g_qtdParciaisCicloSell=0;
      g_parciaisNominaisCicloBuy=0.0;
      g_parciaisNominaisCicloSell=0.0;
      g_realizadoAumentosCicloBuy=0.0;
      g_realizadoAumentosCicloSell=0.0;
      g_volumeRealizadoAumentosCicloBuy=0.0;
      g_volumeRealizadoAumentosCicloSell=0.0;
      g_qtdRealizacoesAumentosCicloBuy=0;
      g_qtdRealizacoesAumentosCicloSell=0;
      for(int iFIX281=0;iFIX281<5;iFIX281++)
      {
         ResetarTrailAumentoFIX281(g_trailAumentoBuy[iFIX281]);
         ResetarTrailAumentoFIX281(g_trailAumentoSell[iFIX281]);
      }
      g_totalCicloMestreSimples=0.0;
      RestaurarParciaisCicloAbertoFIX214(); // recupera parciais do ciclo se o EA foi recompilado/recolocado com posicao aberta.
      g_fechamentoMestreSimplesPendente=false;
      ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
      ResetarEstadoPontaSimplesFIX195(g_simplesSell);
      RegistrarLogValidacaoSistema("FIX195_CICLO_INICIO","Novo ciclo simples iniciado.");
   }
}

void ResetarCicloMestreSimplesFIX195SeFlat()
{
   if(!g_cicloMestreSimplesAtivo) return;
   if(CestaABTemAlgumaPosicaoFIX195()) return;
   if(g_simplesBuy.parcialPendente || g_simplesSell.parcialPendente) return;
   RegistrarLogValidacaoSistema("FIX214_CICLO_FIM",StringFormat("Real BUY %s (%d parc) | Real SELL %s (%d parc) | Total %s. Valores preservados nos cards ate a proxima A0.",PnlMoedaBRL(g_parciaisCicloBuy),g_qtdParciaisCicloBuy,PnlMoedaBRL(g_parciaisCicloSell),g_qtdParciaisCicloSell,PnlMoedaBRL(g_totalCicloMestreSimples)));
   g_cicloMestreSimplesAtivo=false;
   g_cicloMestreSimplesInicio=0;
   g_totalCicloMestreSimples=g_parciaisCicloBuy+g_parciaisCicloSell;
   g_fechamentoMestreSimplesPendente=false;
   ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
   ResetarEstadoPontaSimplesFIX195(g_simplesSell);
}


#endif // COPA_RECONSTRUCAO_FINANCEIRA_CICLO_MQH
