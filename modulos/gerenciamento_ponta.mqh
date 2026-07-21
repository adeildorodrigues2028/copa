#ifndef COPA_GERENCIAMENTO_PONTA_MQH
#define COPA_GERENCIAMENTO_PONTA_MQH

// ============================================================================
// RESPONSABILIDADE: GERENCIAMENTO OPERACIONAL DA PONTA SIMPLES
// Funcoes movidas do principal na V42 sem alteracao de regra operacional.
// ============================================================================

string NomeRegimeCorredorFIX338(ENUM_REGIME_CORREDOR_FIX338 regime)
{
   if(regime==CORREDOR_FIX338_FORTE)  return "FORTE";
   if(regime==CORREDOR_FIX338_NEUTRO) return "NEUTRO";
   if(regime==CORREDOR_FIX338_VIRADA) return "VIRADA";
   return "AGUARDA";
}

bool CorredorAlvoPontaViraMarcoFIX338()
{
   return (InpCorredorLucroAtivo && InpCorredorAlvoPontaViraMarco);
}

bool CorredorMetaABViraMarcoFIX338()
{
   return (InpCorredorLucroAtivo && InpCorredorMetaABViraMarco);
}

ENUM_REGIME_CORREDOR_FIX338 AvaliarRegimeCorredorFIX338(long tipo,
                                                        int &favoraveis,
                                                        int &contrarios,
                                                        string &leitura)
{
   favoraveis=0;
   contrarios=0;
   bool compra=(tipo==POSITION_TYPE_BUY);
   bool hiloFavor=(compra ? g_mercado.hiloCompra : g_mercado.hiloVenda);
   bool hiloContra=(compra ? g_mercado.hiloVenda : g_mercado.hiloCompra);
   bool strFavor=(compra ? g_mercado.strCompra : g_mercado.strVenda);
   bool strContra=(compra ? g_mercado.strVenda : g_mercado.strCompra);
   // QTD+FIN formam um unico pilar: ambos precisam confirmar para ser forte;
   // ambos precisam falhar, com farol baixo, para contar como virada.
   bool volumeFavor=(g_mercado.volqCurvaOK && g_mercado.volfCurvaOK && g_mercado.volFarol>=1);
   bool volumeContra=(!g_mercado.volqCurvaOK && !g_mercado.volfCurvaOK && g_mercado.volFarol<=1);
   if(hiloFavor) favoraveis++;
   if(strFavor) favoraveis++;
   if(volumeFavor) favoraveis++;
   if(hiloContra) contrarios++;
   if(strContra) contrarios++;
   if(volumeContra) contrarios++;
   ENUM_REGIME_CORREDOR_FIX338 regime=CORREDOR_FIX338_NEUTRO;
   if(contrarios>=2)
      regime=CORREDOR_FIX338_VIRADA;
   else if(favoraveis>=3)
      regime=CORREDOR_FIX338_FORTE;
   leitura=StringFormat("TF %s | HiLo %s | STR %s | VOL Q+F %s | fav %d/3 | contra %d/3",
                        NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                        hiloFavor ? "FAVOR" : (hiloContra ? "CONTRA" : "NEUTRO"),
                        strFavor ? "FAVOR" : (strContra ? "CONTRA" : "NEUTRO"),
                        volumeFavor ? "FORTE" : (volumeContra ? "FRACO" : "NEUTRO"),
                        favoraveis,contrarios);
   return regime;
}

double CalcularPisoCorredorFIX338(double melhorLucro,
                                  double ativacao,
                                  double pisoInicial,
                                  double degrau,
                                  double folga)
{
   ativacao=MathAbs(ativacao);
   pisoInicial=MathMax(0.0,MathAbs(pisoInicial));
   degrau=MathAbs(degrau);
   folga=MathAbs(folga);
   if(ativacao<=0.0 || melhorLucro<ativacao)
      return 0.0;
   if(degrau<=0.0)
      degrau=20.0;
   if(folga<=0.0)
      folga=degrau;
   double quantidade=MathFloor(((melhorLucro-ativacao)+0.0000001)/degrau);
   if(quantidade<0.0)
      quantidade=0.0;
   double marco=ativacao+(quantidade*degrau);
   double piso=MathMax(pisoInicial,marco-folga);
   if(piso>melhorLucro)
      piso=melhorLucro;
   return NormalizeDouble(MathMax(0.0,piso),2);
}

bool ProcessarEstadoPontaSimplesFIX195(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, double lucroPonta, double volumePonta)
{
   if(volumePonta<=0.0001)
   {
      if(!p.parcialPendente)
      {
         ResetarEstadoPontaSimplesFIX195(p);
         estado.lucroProtegido=false;
         estado.valorDefendido=0.0;
         estado.melhorResultadoAberto=0.0;
         estado.modoLongo=false;
      }
      return false;
   }
   // FIX380: separa o resultado total do ciclo do lucro aberto usado pelo trailing.
   // O alvo pode considerar o ciclo, mas o TRAIL 20/5 usa exclusivamente a operacao aberta atual.
   double resultadoCiclo=ResultadoCicloPontaFIX207(tipo,lucroPonta);
   double resultadoTrail=lucroPonta;
   if(resultadoTrail>p.melhorLucro)
      p.melhorLucro=resultadoTrail;

   // FIX439: MOVEL 25/10, camada anterior ao TRAIL continuo 50/25.
   // +R$25 => defesa inicial em +R$10. A cada novo bloco de R$10, a defesa sobe R$10.
   // Ao chegar em +R$50, o trailing assume com distancia financeira de R$25.
   double movelInicioFIX395=MathAbs(InpMovelAtivarTicketReaisFIX395);
   double movelPassoFIX395=MathAbs(InpMovelPassoTicketReaisFIX395);
   if(movelInicioFIX395<=0.0) movelInicioFIX395=25.0;
   if(movelPassoFIX395<=0.0) movelPassoFIX395=10.0;
   bool armouMovelAgoraFIX395=false;
   if(!p.movelArmadoFIX395 && p.melhorLucro>=movelInicioFIX395)
   {
      p.movelArmadoFIX395=true;
      p.defesaMovelFIX395=10.0;
      armouMovelAgoraFIX395=true;
      RegistrarLogValidacaoSistema("FIX439_MOVEL_ARMADO",
         StringFormat("%s melhor %s atingiu MOVEL %s; defesa posicionada em +R$10. Passo %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                      PnlMoedaBRL(movelInicioFIX395),PnlMoedaBRL(movelPassoFIX395)));
   }
   if(p.movelArmadoFIX395)
   {
      double degrausMovelFIX395=MathFloor(((p.melhorLucro-movelInicioFIX395)+0.0000001)/movelPassoFIX395);
      if(degrausMovelFIX395<0.0) degrausMovelFIX395=0.0;
      double novaDefesaMovelFIX395=NormalizeDouble(10.0+(degrausMovelFIX395*movelPassoFIX395),2);
      if(novaDefesaMovelFIX395>p.defesaMovelFIX395)
      {
         p.defesaMovelFIX395=novaDefesaMovelFIX395;
         RegistrarLogValidacaoSistema("FIX395_MOVEL_SUBIU",
            StringFormat("%s melhor %s; defesa movel subiu para %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                         PnlMoedaBRL(p.defesaMovelFIX395)));
      }
   }
   bool usarCorredor=InpCorredorLucroAtivo;
   double inicio=usarCorredor ? MathAbs(InpCorredorAtivarReais) : MathAbs(g_entradaTrailingAtivarReaisEfetivo);
   double passo=usarCorredor ? MathAbs(InpCorredorDegrauReais) : MathAbs(g_entradaTrailingPassoReaisEfetivo);
   if(inicio<=0.0) inicio=15.0;
   if(passo<=0.0) passo=5.0;
   bool armouProtecaoAgora=false;
   if(!p.protecaoArmada && p.melhorLucro>=inicio)
   {
      p.protecaoArmada=true;
      p.defesaAtual=usarCorredor
                     ? MathMax(0.0,MathAbs(InpCorredorPisoInicialReais))
                     : MathMax(0.0,inicio-passo);
      armouProtecaoAgora=true;
      RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_ARMADO" : "FIX211_TRAIL_ARMADO",
         StringFormat("%s lucro aberto atingiu %s; %s armado em %s; defesa inicial %s. Parciais e rearme permanecem ativos.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),
                      usarCorredor ? "corredor inteligente" : "trailing por degrau",
                      PnlMoedaBRL(inicio),PnlMoedaBRL(p.defesaAtual)));
   }
   bool saidaTecnicaCorredor=false;
   string leituraCorredor="";
   if(p.protecaoArmada)
   {
      double novaDefesa=0.0;
      if(usarCorredor)
      {
         int favoraveis=0,contrarios=0;
         ENUM_REGIME_CORREDOR_FIX338 regimeAnterior=p.regimeCorredor;
         ENUM_REGIME_CORREDOR_FIX338 regime=AvaliarRegimeCorredorFIX338(tipo,favoraveis,contrarios,leituraCorredor);
         p.regimeCorredor=regime;
         datetime candleFechado=iTime(_Symbol,TimeframeFiltroAtualFIX255(),1);
         if(candleFechado>0 && candleFechado!=p.ultimoCandleCorredor)
         {
            p.ultimoCandleCorredor=candleFechado;
            if(regime==CORREDOR_FIX338_VIRADA)
               p.confirmacoesViradaCorredor++;
            else
               p.confirmacoesViradaCorredor=0;
         }
         double pisoInicial=MathAbs(InpCorredorPisoInicialReais);
         double folgaForte=MathAbs(InpCorredorFolgaForteReais);
         novaDefesa=CalcularPisoCorredorFIX338(p.melhorLucro,inicio,pisoInicial,passo,folgaForte);
         if(regime==CORREDOR_FIX338_NEUTRO)
            novaDefesa=MathMax(novaDefesa,p.melhorLucro-MathAbs(InpCorredorFolgaNeutraReais));
         else if(regime==CORREDOR_FIX338_VIRADA)
            novaDefesa=MathMax(novaDefesa,p.melhorLucro-MathAbs(InpCorredorFolgaViradaReais));
         novaDefesa=NormalizeDouble(MathMax(0.0,MathMin(p.melhorLucro,novaDefesa)),2);
         int confirmacoesNecessarias=MathMax(1,InpCorredorConfirmacoesVirada);
         saidaTecnicaCorredor=(regime==CORREDOR_FIX338_VIRADA &&
                               p.confirmacoesViradaCorredor>=confirmacoesNecessarias);
         if(regime!=regimeAnterior)
         {
            RegistrarLogValidacaoSistema("FIX338_CORREDOR_REGIME",
               StringFormat("%s corredor %s -> %s | %s | defesa atual %s.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",
                            NomeRegimeCorredorFIX338(regimeAnterior),
                            NomeRegimeCorredorFIX338(regime),
                            leituraCorredor,PnlMoedaBRL(p.defesaAtual)));
         }
      }
      else
         novaDefesa=CalcularDefesaDegrauFIX281(p.melhorLucro,inicio,passo);
      if(novaDefesa>p.defesaAtual)
      {
         p.defesaAtual=novaDefesa;
         RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_SUBIU" : "FIX211_TRAIL_SUBIU",
            StringFormat("%s melhor %s; nova defesa %s%s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),
                         usarCorredor ? " | "+NomeRegimeCorredorFIX338(p.regimeCorredor)+" | "+leituraCorredor : ""));
      }
   }
   estado.lucroProtegido=p.protecaoArmada;
   estado.valorDefendido=p.defesaAtual;
   estado.melhorResultadoAberto=p.melhorLucro;
   estado.modoLongo=(usarCorredor && p.protecaoArmada);
   if(usarCorredor && p.protecaoArmada)
      estado.ultimaMensagem=StringFormat("CORREDOR %s | total %s | melhor %s | piso %s | virada %d/%d | %s",
                                         NomeRegimeCorredorFIX338(p.regimeCorredor),
                                         PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),
                                         p.confirmacoesViradaCorredor,MathMax(1,InpCorredorConfirmacoesVirada),
                                         NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));

   // FIX403: NAO usa o zero agregado da cesta.
   // Cada aumento A1-A4 e acompanhado pelo lucro do proprio ticket em ProcessarTicketAumentoFIX281.
   // Ao devolver ate sua defesa individual, fecha somente aquele ticket; o deal confirma a parcial
   // e o fluxo FIX248 rearma somente o nivel realizado para permitir nova entrada pelos filtros.

   // FIX439: antes de o TRAIL 50/25 armar, o MOVEL 25/10 preserva pelo menos +R$10.
   if(p.movelArmadoFIX395 && !p.protecaoArmada && !armouMovelAgoraFIX395 &&
      resultadoTrail<=p.defesaMovelFIX395+0.01)
   {
      string motivoMovelFIX395=(tipo==POSITION_TYPE_BUY?"MOVEL25_10_BUY_FIX439":"MOVEL25_10_SELL_FIX439");
      bool okMovelFIX395=FecharPosicoesLado(estado,motivoMovelFIX395);
      if(okMovelFIX395)
      {
         RegistrarLogValidacaoSistema("FIX395_MOVEL_DISPARADO",
            StringFormat("%s atual %s <= defesa movel %s | melhor %s | fechamento enviado. TRAIL 50/25 permanece independente.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaMovelFIX395),PnlMoedaBRL(p.melhorLucro)));
         return true;
      }
      RegistrarLogValidacaoSistema("FIX395_MOVEL_RETRY",
         StringFormat("%s tocou defesa movel %s com atual %s; envio falhou e sera repetido no proximo Timer.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.defesaMovelFIX395),PnlMoedaBRL(resultadoTrail)));
   }

   // FIX394: o trailing financeiro tem prioridade absoluta.
   // Assim, quando o lucro volta ao piso protegido, nenhuma parcial, aumento ou gain concorrente
   // consegue atrasar o fechamento. Esta rotina roda pelo Timer de 1 segundo.
   if(p.protecaoArmada && !armouProtecaoAgora && resultadoTrail<=p.defesaAtual+0.01)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX394_TRAIL_PRIORIDADE",
            "Trailing sobrepos parcial pendente; fechamento local tem prioridade absoluta.");
      string motivoTrailFIX394=(usarCorredor
                                ? (tipo==POSITION_TYPE_BUY?"CORREDOR_PISO_BUY_FIX394":"CORREDOR_PISO_SELL_FIX394")
                                : (tipo==POSITION_TYPE_BUY?"TRAIL20_5_BUY_FIX394":"TRAIL20_5_SELL_FIX394"));
      bool okTrailFIX394=FecharPosicoesLado(estado,motivoTrailFIX394);
      if(okTrailFIX394)
      {
         RegistrarLogValidacaoSistema("FIX394_TRAIL_DISPARADO",
            StringFormat("%s | atual %s <= defesa %s | melhor %s | ativa %s | passo %s | fechamento enviado pelo Timer.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(p.melhorLucro),
                         PnlMoedaBRL(inicio),PnlMoedaBRL(passo)));
         return true;
      }
      RegistrarLogValidacaoSistema("FIX394_TRAIL_RETRY",
         StringFormat("%s tocou defesa %s com atual %s, mas envio falhou; nova tentativa no proximo Timer.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(resultadoTrail)));
   }

   if(GerenciarRealizacaoAumentosPorTicketFIX207(p,estado,tipo))
      return true;
   double lossLocal=InpStopDinamicoHeadFIX359 ? 0.0 : MathAbs(InpLossEntradaLocalReaisFIX321);
   if(lossLocal>0.0 && resultadoCiclo<=-lossLocal)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Loss local sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"LOSS_LOCAL_BUY_FIX321":"LOSS_LOCAL_SELL_FIX321");
      if(ok)
      {
         RegistrarLogValidacaoSistema("FIX321_LOSS_ENTRADA_LOCAL",
            StringFormat("%s local %s atingiu LOSS -%s; fechando somente o Magic local, sem usar o lado oposto.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(lossLocal)));
         return true;
      }
   }
   double metaFinal=MathAbs(InpEntradaGanhoAlvoReais);
   if(metaFinal>0.0 && resultadoCiclo>=metaFinal)
   {
      if(CorredorAlvoPontaViraMarcoFIX338() && p.protecaoArmada)
      {
         if(!p.alvoMarcoCorredorRegistrado)
         {
            p.alvoMarcoCorredorRegistrado=true;
            RegistrarLogValidacaoSistema("FIX338_ALVO_VIROU_MARCO",
               StringFormat("%s atingiu o alvo %s; nao fecha: corredor continua sem teto | melhor %s | piso %s.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(metaFinal),
                            PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual)));
         }
      }
      else
      {
         bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"GAIN_PONTA_BUY_FIX207":"GAIN_PONTA_SELL_FIX207");
         if(ok)
         {
            RegistrarLogValidacaoSistema("FIX207_GAIN_PONTA",
               StringFormat("%s ciclo %s atingiu gain %s; fechando somente o Magic local.",
                            tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoCiclo),PnlMoedaBRL(metaFinal)));
            return true;
         }
      }
   }
   if(!InpRealizarAumentosPorTicketFIX207)
   {
      if(p.proximaRealizacao<=0.0)
         p.proximaRealizacao=(InpRealizacaoPrimeiraReais>0.0?InpRealizacaoPrimeiraReais:10.0);
      if(!p.parcialPendente && resultadoCiclo>=p.proximaRealizacao && volumePonta>1.0001)
      {
         double qtd=MathAbs(InpRealizacaoContratos);
         if(qtd<=0.0) qtd=1.0;
         bool ok=FecharParcialPosicoesLado(estado,qtd,tipo==POSITION_TYPE_BUY?"PARCIAL_SIMPLES_BUY_FIX207":"PARCIAL_SIMPLES_SELL_FIX207");
         if(ok)
         {
            p.parcialPendente=true;
            p.horaParcialPendente=TimeCurrent();
            double passoFallback=MathAbs(InpRealizacaoPassoReais);
            if(passoFallback<=0.0) passoFallback=10.0;
            p.proximaRealizacao+=passoFallback;
            return true;
         }
      }
   }
   if(usarCorredor && p.protecaoArmada && !armouProtecaoAgora && saidaTecnicaCorredor)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Virada do corredor sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,tipo==POSITION_TYPE_BUY?"CORREDOR_VIRADA_BUY_FIX338":"CORREDOR_VIRADA_SELL_FIX338");
      if(ok)
      {
         RegistrarLogValidacaoSistema("FIX338_CORREDOR_SAIDA_TECNICA",
            StringFormat("%s encerrou por virada confirmada %d/%d candles | total %s | melhor %s | piso %s | %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",p.confirmacoesViradaCorredor,
                         MathMax(1,InpCorredorConfirmacoesVirada),PnlMoedaBRL(resultadoCiclo),
                         PnlMoedaBRL(p.melhorLucro),PnlMoedaBRL(p.defesaAtual),leituraCorredor));
         return true;
      }
   }
   // FIX394: bloco legado mantido apenas como referencia; a execucao ocorre antes das parciais.
   if(false && p.protecaoArmada && !armouProtecaoAgora && resultadoTrail<=p.defesaAtual)
   {
      if(p.parcialPendente)
         RegistrarLogValidacaoSistema("FIX339_SAIDA_PRIORITARIA",
            "Piso financeiro sobrepos parcial pendente; protecao tem prioridade.");
      bool ok=FecharPosicoesLado(estado,
                                usarCorredor
                                ? (tipo==POSITION_TYPE_BUY?"CORREDOR_PISO_BUY_FIX338":"CORREDOR_PISO_SELL_FIX338")
                                : (tipo==POSITION_TYPE_BUY?"PROTECAO_SIMPLES_BUY_FIX207":"PROTECAO_SIMPLES_SELL_FIX207"));
      if(ok)
      {
         RegistrarLogValidacaoSistema(usarCorredor ? "FIX338_CORREDOR_PISO" : "FIX211_TRAIL_DISPARADO",
            StringFormat("%s lucro aberto voltou para %s; defesa %s; melhor aberto %s; fechando somente a ponta local.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",PnlMoedaBRL(resultadoTrail),
                         PnlMoedaBRL(p.defesaAtual),PnlMoedaBRL(p.melhorLucro)));
         return true;
      }
   }
   return false;
}

bool ProcessarPontaSimplesFIX195(long tipo,double lucroPonta,double volumePonta)
{
   if(tipo==POSITION_TYPE_BUY) return ProcessarEstadoPontaSimplesFIX195(g_simplesBuy, g_compra, tipo, lucroPonta, volumePonta);
   if(tipo==POSITION_TYPE_SELL) return ProcessarEstadoPontaSimplesFIX195(g_simplesSell, g_venda, tipo, lucroPonta, volumePonta);
   return false;
}


bool ProcessarGerenciamentoSimplesInstanciaFIX255()
{
   AtualizarCicloMestreSimplesFIX195();
   ResetarCicloMestreSimplesFIX195SeFlat();
   if(!g_cicloMestreSimplesAtivo)
      return false;

   double qBuy=0.0,qSell=0.0,qTotal=0.0,aBuy=0.0,aSell=0.0,aTotal=0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qBuy,qSell,qTotal,aBuy,aSell,aTotal);

   bool saiuLocal=false;
   if(JanelaAtualEhA_FIX255())
      saiuLocal=ProcessarPontaSimplesFIX195(POSITION_TYPE_BUY,g_compra.resultadoAberto,g_compra.contratos);
   else
      saiuLocal=ProcessarPontaSimplesFIX195(POSITION_TYPE_SELL,g_venda.resultadoAberto,g_venda.contratos);
   if(saiuLocal)
      return true;

   // FIX320: no modo LADO, esta instancia encerra aqui. Resultado, meta,
   // stop e reentrada do Magic oposto nao participam de nenhuma decisao.
   if(!RiscoOperacaoModoCesta())
   {
      g_mestre.mensagemGeral=StringFormat("%s INDEPENDENTE | Magic %d | aberto %s",
                                          NomeJanelaInstanciaFIX255(),
                                          (int)MagicOperacionalInstanciaFIX255(),
                                          PnlMoedaBRL(JanelaAtualEhA_FIX255() ? g_compra.resultadoAberto : g_venda.resultadoAberto));
      return false;
   }

   g_totalCicloMestreSimples=aBuy+aSell+g_parciaisCicloBuy+g_parciaisCicloSell;
   if(CorredorMetaABViraMarcoFIX338() && g_cestaMetaMarcoCorredorFIX338)
      g_mestre.mensagemGeral=StringFormat("FIX338 %s | CORREDOR A+B %s | MELHOR %s | PISO %s | SEM TETO",
                                          NomeJanelaInstanciaFIX255(),PnlMoedaBRL(g_totalCicloMestreSimples),
                                          PnlMoedaBRL(g_cestaMelhorSaldoLiquido),PnlMoedaBRL(g_cestaDefesaCurtaAB));
   else
      g_mestre.mensagemGeral=StringFormat("FIX256 %s | TOTAL A+B %s / META %s",
                                          NomeJanelaInstanciaFIX255(),
                                          PnlMoedaBRL(g_totalCicloMestreSimples),
                                          PnlMoedaBRL(InpMetaMestreABReais));

   // Somente a Janela A envia o fechamento global; a B apenas acompanha o total no painel.
   if(!InstanciaMestreGrupoFIX255())
      return false;

   double meta=MathAbs(InpMetaMestreABReais);
   if(!CorredorMetaABViraMarcoFIX338() && meta>0.0 && !g_fechamentoMestreSimplesPendente && g_totalCicloMestreSimples>=meta)
   {
      g_fechamentoMestreSimplesPendente=true;
      RegistrarLogValidacaoSistema("FIX256_META_MESTRE",
         StringFormat("Janela A coordenadora: total %s >= meta %s.",
                      PnlMoedaBRL(g_totalCicloMestreSimples),PnlMoedaBRL(meta)));
      bool ok=FecharCestaABOficial("META_MESTRE_FIX255_JANELA_A");
      if(!ok)
         g_fechamentoMestreSimplesPendente=false;
      return ok;
   }
   return false;
}


#endif // COPA_GERENCIAMENTO_PONTA_MQH
