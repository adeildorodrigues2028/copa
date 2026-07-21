#ifndef COPA_SINAL_SAIDA_LONGA_MQH
#define COPA_SINAL_SAIDA_LONGA_MQH

// ============================================================================
// RESPONSABILIDADE: SINAL DE SAIDA DA OPERACAO LONGA
// Funcoes movidas do principal na V45 sem alteracao de regra operacional.
// ============================================================================

bool SinalSaidaOperacaoLonga(EstadoLado &estado)
{
   if(!estado.modoLongo)
      return false;
   bool fluxoFraco = (g_mercado.scoreFluxo <= MathAbs(InpOperacaoLongaScoreSaida));
   bool volumeQtdFraco = false;
   if(InpOperacaoLongaUsarVolumeQtd)
      volumeQtdFraco = (!g_mercado.volqCurvaOK && g_mercado.volFarol <= 1);
   bool volumeFinFraco = false;
   if(InpOperacaoLongaUsarVolumeFin)
      volumeFinFraco = (!g_mercado.volfCurvaOK && g_mercado.volFarol <= 1);
   ENUM_LADO_ROBO ladoAtual = LadoDaPosicaoAtual(estado);
   bool hiloContra = false;
   if(InpOperacaoLongaUsarHiLo)
   {
      if(ladoAtual == LADO_COMPRA)
         hiloContra = g_mercado.hiloVenda;
      else if(ladoAtual == LADO_VENDA)
         hiloContra = g_mercado.hiloCompra;
   }
   bool strContra = false;
   if(InpOperacaoLongaUsarSTR)
   {
      if(ladoAtual == LADO_COMPRA)
         strContra = g_mercado.strVenda;
      else if(ladoAtual == LADO_VENDA)
         strContra = g_mercado.strCompra;
   }
   return (fluxoFraco || volumeQtdFraco || volumeFinFraco || hiloContra || strContra);
}

#endif // COPA_SINAL_SAIDA_LONGA_MQH
