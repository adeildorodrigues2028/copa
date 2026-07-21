#ifndef COPA_PARCIAIS_LADO_MQH
#define COPA_PARCIAIS_LADO_MQH

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

double NormalizarVolumeParaFechamento(double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   double vol = MathFloor(volume / step) * step;
   if(vol < minVol)
      return 0.0;
   if(maxVol > 0.0 && vol > maxVol)
      vol = maxVol;
   return NormalizeDouble(vol, 2);
}

double CalcularVolumeParcialSeguro(double volumeAtual, double percentualVolume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   if(volumeAtual <= minVol + 0.0001)
      return 0.0;
   double perc = MathAbs(percentualVolume);
   if(perc <= 0.0)
      perc = 50.0;
   if(perc > 100.0)
      perc = 100.0;
   double desejado = volumeAtual * (perc / 100.0);
   double vol = NormalizarVolumeParaFechamento(desejado);
   if(vol <= 0.0)
      return 0.0;
   if((volumeAtual - vol) > 0.0001 && (volumeAtual - vol) < minVol)
      vol = NormalizarVolumeParaFechamento(volumeAtual - minVol);
   if(vol <= 0.0)
      return 0.0;
   if(vol >= volumeAtual - 0.0001)
      return 0.0;
   return vol;
}

bool FecharParcialPosicoesLado(EstadoLado &estado, double volumeDesejado, string motivo)
{
   if(!estado.posicaoAberta)
      return false;
   if(!PermiteEnvioOrdem(estado, "Saida parcial"))
      return false;
   double restante = NormalizarVolumeParaFechamento(volumeDesejado);
   if(restante <= 0.0)
   {
      RegistrarGerenciadorOrdens(estado, "PARCIAL_BLOCK", "Parcial bloqueada: volume desejado abaixo do mínimo do ativo.", 0, 0, volumeDesejado, 0.0, true);
      return false;
   }
   bool enviouAlgo = false;
   bool tudoOk = true;
   double volumeEnviado = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0 && restante > 0.0001; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double volumePosicao = PositionGetDouble(POSITION_VOLUME);
      if(volumePosicao <= 0.0)
         continue;
      double volFechar = MathMin(volumePosicao, restante);
      volFechar = NormalizarVolumeParaFechamento(volFechar);
      if(volFechar <= 0.0)
         continue;
      double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if((volumePosicao - volFechar) > 0.0001 && (volumePosicao - volFechar) < minVol)
      {
         volFechar = NormalizarVolumeParaFechamento(volumePosicao - minVol);
         if(volFechar <= 0.0)
            continue;
      }
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = _Symbol;
      req.volume       = volFechar;
      req.magic        = (ulong)estado.magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " " + estado.nome,req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;
      estado.ultimaTentativaOrdem = TimeCurrent();
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         enviouAlgo = true;
         volumeEnviado += req.volume;
         restante -= req.volume;
         RegistrarGerenciadorOrdens(estado, "PARCIAL_OK",
                                    StringFormat("PARCIAL ENVIADA %s | Ticket %s | Volume %.2f | Aberto %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 req.volume,
                                                 PnlMoedaBRL(estado.resultadoAberto)),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estado, "PARCIAL_REJECT",
                                    StringFormat("PARCIAL REJEITADA %s | Ticket %s | Retcode %s | Erro %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 IntegerToString((int)res.retcode),
                                                 IntegerToString(ultimoErro)),
                                    res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!enviouAlgo)
      RegistrarGerenciadorOrdens(estado, "PARCIAL_BLOCK", "Parcial solicitada, mas nenhuma posição válida do Magic/instância foi encontrada.", 0, 0, volumeDesejado, 0.0, true);
   return (enviouAlgo && tudoOk);
}

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

#include "modulos/validacoes_entrada_aumento.mqh"

#endif // COPA_PARCIAIS_LADO_MQH
