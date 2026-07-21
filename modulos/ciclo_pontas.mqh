#ifndef COPA_CICLO_PONTAS_MQH
#define COPA_CICLO_PONTAS_MQH

// ============================================================================
// RESPONSABILIDADE: ESTADO E CICLO DAS PONTAS
// Funcoes movidas do principal na V44 sem alteracao de regra operacional.
// ============================================================================

bool CestaABTemAlgumaPosicaoFIX195()
{
   double qC=0.0,qV=0.0,qT=0.0,aC=0.0,aV=0.0,aT=0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qC,qV,qT,aC,aV,aT);
   return (qT>0.0001);
}

void ResetarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &e)
{
   e.melhorLucro=0.0;
   e.defesaAtual=0.0;
   e.proximaRealizacao=MathAbs(InpRealizacaoPrimeiraReais);
   if(e.proximaRealizacao<=0.0) e.proximaRealizacao=10.0;
   e.protecaoArmada=false;
   e.movelArmadoFIX395=false;
   e.defesaMovelFIX395=0.0;
   e.parcialPendente=false;
   e.ticketParcialPendente=0;
   e.identificadorParcialPendente=0;
   e.nivelAumentoPendente=0;
   e.valorNominalParcialPendente=0.0;
   e.horaParcialPendente=0;
   e.ultimaParcialConfirmada=0;
   e.regimeCorredor=CORREDOR_FIX338_AGUARDA;
   e.confirmacoesViradaCorredor=0;
   e.ultimoCandleCorredor=0;
   e.alvoMarcoCorredorRegistrado=false;
}

void PrepararNovoCicloPontaFIX275(EstadoLado &estado)
{
   if(!InpHeadCiclosIndependentesFIX275 || estado.posicaoAberta)
      return;

   if(estado.lado == LADO_COMPRA)
   {
      g_parciaisCicloBuy = 0.0;
      g_parciaisNominaisCicloBuy = 0.0;
      g_qtdParciaisCicloBuy = 0;
      g_realizadoAumentosCicloBuy = 0.0;
      g_volumeRealizadoAumentosCicloBuy = 0.0;
      g_qtdRealizacoesAumentosCicloBuy = 0;
      for(int iFIX281=0;iFIX281<5;iFIX281++) ResetarTrailAumentoFIX281(g_trailAumentoBuy[iFIX281]);
      g_cicloInicioCompra = 0;
      ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
   }
   else if(estado.lado == LADO_VENDA)
   {
      g_parciaisCicloSell = 0.0;
      g_parciaisNominaisCicloSell = 0.0;
      g_qtdParciaisCicloSell = 0;
      g_realizadoAumentosCicloSell = 0.0;
      g_volumeRealizadoAumentosCicloSell = 0.0;
      g_qtdRealizacoesAumentosCicloSell = 0;
      for(int iFIX281=0;iFIX281<5;iFIX281++) ResetarTrailAumentoFIX281(g_trailAumentoSell[iFIX281]);
      g_cicloInicioVenda = 0;
      ResetarEstadoPontaSimplesFIX195(g_simplesSell);
   }
   else
      return;

   g_totalCicloMestreSimples = g_parciaisCicloBuy + g_parciaisCicloSell;
   estado.resultadoFechado = 0.0;
   estado.resultadoDia = estado.resultadoAberto;
   estado.parcial50Executada = false;
   estado.parcialFinalExecutada = false;
   estado.melhorResultadoAberto = 0.0;
   estado.valorDefendido = 0.0;
   estado.lucroProtegido = false;
   estado.modoLongo = false;

   RegistrarLogValidacaoSistema("FIX275_NOVO_CICLO_PONTA",
      StringFormat("%s iniciou novo ciclo independente: realizado local zerado; alvo R$100; ponta oposta permanece intacta.",
                   estado.lado == LADO_COMPRA ? "BUY" : "SELL"));
}


#endif // COPA_CICLO_PONTAS_MQH
