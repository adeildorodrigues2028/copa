#ifndef COPA_GERENCIADOR_PARCIAIS_LADO_MQH
#define COPA_GERENCIADOR_PARCIAIS_LADO_MQH

// ============================================================================
// RESPONSABILIDADE: DECISAO DAS PARCIAIS POR LADO
// Funcoes movidas do principal na V45 sem alteracao de regra operacional.
// ============================================================================

bool GerenciarParciaisLado(EstadoLado &estado)
{
   if(CestaABTemDuasPontasAbertas())
      return false;
   if(!estado.posicaoAberta)
      return false;
   string cfg = Upper(GetCampo(InpParciais, "", "ON"));
   if(cfg == "OFF" || cfg == "0" || cfg == "FALSE")
      return false;
   double resultadoProtecao = ResultadoProtecaoOperacaoLado(estado);
   double alvo = MathAbs(InpEntradaGanhoAlvoReais);
   double gatilhoParcial = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   if(gatilhoParcial <= 0.0)
   {
      double percMeta = MathAbs(InpParcial50PercentualMeta);
      if(percMeta <= 0.0)
         percMeta = 50.0;
      if(percMeta > 100.0)
         percMeta = 100.0;
      if(alvo > 0.0)
         gatilhoParcial = alvo * (percMeta / 100.0);
   }
   double gatilhoParcialEfetivo = GatilhoParcialEfetivoLado(estado, gatilhoParcial);
   if(ParcialOperacaoAtivaEfetiva() && !estado.parcial50Executada && gatilhoParcialEfetivo > 0.0 && resultadoProtecao >= gatilhoParcialEfetivo)
   {
      double volumeParcial = CalcularVolumeParcialSeguro(estado.contratos, ParcialPercentualVolumeEfetivo());
      if(volumeParcial <= 0.0)
      {
         RegistrarGerenciadorOrdens(estado,
                                    "PARCIAL_BLOCK",
                                    StringFormat("Parcial livre aguardando volume: total %s | gatilho %s | atual %.2f contrato(s). Com 1 contrato não existe meia parcial segura; precisa de aumento ou volume maior.",
                                                 PnlMoedaBRL(resultadoProtecao),
                                                 PnlMoedaBRL(gatilhoParcialEfetivo),
                                                 estado.contratos),
                                    0, 0, 0.0, 0.0, false);
         return false;
      }
      estado.parcial50Executada = true;
      if(InpParcialArmarProtecao)
      {
         if(resultadoProtecao > estado.melhorResultadoAberto)
            estado.melhorResultadoAberto = resultadoProtecao;
         estado.lucroProtegido = true;
         ArmarProtecaoFinanceiraLado(estado, "PARCIAL_PROTECAO", true);
      }
      bool ok = FecharParcialPosicoesLado(estado, volumeParcial, "PARCIAL_LIVRE_REAIS");
      if(!ok)
         estado.parcial50Executada = false;
      return ok;
   }
   if(InpParcialFinalFecharTudo && !estado.parcialFinalExecutada && alvo > 0.0 && resultadoProtecao >= alvo)
   {
      estado.parcialFinalExecutada = true;
      bool ok = FecharPosicoesLado(estado, "PARCIAL_FINAL_100");
      if(!ok)
         estado.parcialFinalExecutada = false;
      return ok;
   }
   return false;
}


#endif // COPA_GERENCIADOR_PARCIAIS_LADO_MQH
