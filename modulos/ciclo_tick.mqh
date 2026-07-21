#ifndef COPA_CICLO_TICK_MQH
#define COPA_CICLO_TICK_MQH

// ============================================================================
// RESPONSABILIDADE: ORQUESTRACAO DO ONTICK
// Funcoes movidas do principal na V41 sem alteracao de regra operacional.
// ============================================================================

void OnTick()
{
   FIX433RegistrarTick();
   CanaisProcessarTick();
   ulong inicioFIX302=GetMicrosecondCount();
   ProcessarOnTickMotorFIX302();
   ulong fimFIX302=GetMicrosecondCount();
   AuditoriaRegistrarTempoTickFIX302(fimFIX302>=inicioFIX302 ? fimFIX302-inicioFIX302 : 0);
   AuditoriaAtualizarCicloFIX302();
}

void ProcessarOnTickMotorFIX302()
{
   g_ultimoTickRecebidoMsFIX283=GetTickCount64();
   ReaplicarParametrosAntesDoGrafico("TICK_FIX283");
   AtualizarCoordenacaoMagicsFIX256(false);
   SincronizarMagicParametros(false);
   AtualizarNovoCandle();
   // FIX287: indicadores/filtros nao precisam ser recalculados centenas de vezes por segundo.
   // A gestao financeira de alvo, stop e trailing continua executando abaixo em TODO tick.
   ulong agoraMercadoMsFIX287=GetTickCount64();
   int intervaloMercadoMsFIX287=InpFIX287MercadoIntervaloMinimoMs;
   if(intervaloMercadoMsFIX287<20) intervaloMercadoMsFIX287=20;
   if(!InpFIX287UltraLeve || g_novoCandle || g_ultimaAtualizacaoMercadoMsFIX287==0 ||
      agoraMercadoMsFIX287<g_ultimaAtualizacaoMercadoMsFIX287 ||
      (agoraMercadoMsFIX287-g_ultimaAtualizacaoMercadoMsFIX287)>=(ulong)intervaloMercadoMsFIX287)
   {
      g_ultimaAtualizacaoMercadoMsFIX287=agoraMercadoMsFIX287;
      AtualizarMercado();
      AtualizarDXAdaptativoFIX411(g_novoCandle);
   }
   // A carga historica dos candles coloridos fica somente no Timer; no OnTick ela varria ObjectsTotal.
   AtualizarCandlesContraFIX258(false);
   AtualizarEstadosDePosicao();
   GarantirStopsServidorFIX342(false);
   int intervaloParABMsFIX287=500;
   if(!InpFIX287UltraLeve || g_ultimaAtualizacaoParABMsFIX287==0 ||
      agoraMercadoMsFIX287<g_ultimaAtualizacaoParABMsFIX287 ||
      (agoraMercadoMsFIX287-g_ultimaAtualizacaoParABMsFIX287)>=(ulong)intervaloParABMsFIX287)
   {
      g_ultimaAtualizacaoParABMsFIX287=agoraMercadoMsFIX287;
      AtualizarEstadoParABFIX274();
   }
   if(JanelaAtualEhA_FIX255())
   {
      RecuperarRearmeSemEventoFIX452(g_compra);
      ProcessarRearmeDinamicoPendenteFIX248(g_compra);
   }
   else
   {
      RecuperarRearmeSemEventoFIX452(g_venda);
      ProcessarRearmeDinamicoPendenteFIX248(g_venda);
   }
   ResetarCicloCestaABQuandoFlat();
   AtualizarHistoricoObrigatorio();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AtualizarCamposFinanceirosCriticosFIX354(false);
   if(GerenciarStopDiaMestreFIX320())
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual=TimeCurrent();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(false);
      return;
   }
   ProcessarAtualizacaoHistoricoRapidaFIX227();
   LogCestaABDetalhado("TICK_FINANCEIRO_AB", false);
   LogHedgeCompleto("TICK_HEDGE_AB", "SNAPSHOT", "fotografia completa do grupo A+B", 0, 0, 0, 0, 0, 0.0, 0.0, false);
   LogStopFullHedgeAB("TICK_STOP_FULL_HEDGE_AB", false);
   if(ProcessarEncerramentoManualFIX284(false))
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      int intervaloPainelFIX284 = IntervaloPainelEfetivo();
      if(g_ultimaAtualizacaoPainelVisual == 0 ||
         (TimeCurrent() - g_ultimaAtualizacaoPainelVisual) >= intervaloPainelFIX284)
      {
         g_ultimaAtualizacaoPainelVisual = TimeCurrent();
         AtualizarPainelMestre();
      }
      return;
   }
   if(InstanciaMestreGrupoFIX255() && ProcessarFechamentoFimDiaFIX215())
   {
      AtualizarEstadosDePosicao();
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual=TimeCurrent();
      AtualizarPainelMestre();
      PainelChartRedrawLeve(false);
      return;
   }
   if(BloquearNovasOperacoesFimDiaFIX215() && !g_fimDiaAvisoBloqueioFIX215)
   {
      g_fimDiaAvisoBloqueioFIX215=true;
      g_mestre.mensagemGeral=StringFormat("FIX215: novas entradas e aumentos bloqueados as %s. Operacao atual segue com os mesmos valores ate zerar; fechamento obrigatorio as %s.",InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
      RegistrarLogValidacaoSistema("FIX215_FIM_DIA_BLOQUEIO",g_mestre.mensagemGeral);
   }
   if(g_baseHistoricaSomenteExportarAtivo)
   {
      AtualizarRodapePainelRapido();
      return;
   }
   bool saidaCesta = false;
   bool saidaProtecaoCompra = false;
   bool saidaProtecaoVenda  = false;
   if(g_ambienteLiberado)
   {
      if(InpModoSimplesFIX195)
      {
         // FIX257: o modo simples tambem deve respeitar o STOP e o GAIN financeiros do grupo A+B.
         // Somente a Janela A coordena o fechamento global; a Janela B continua cuidando apenas do seu Magic.
         if(InstanciaMestreGrupoFIX255())
         {
            saidaCesta = GerenciarStopMovelCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarGainGlobalCestaAB();
         }
         if(!saidaCesta)
            saidaCesta = ProcessarGerenciamentoSimplesInstanciaFIX255();
      }
      else
      {
         // Funções que podem fechar o grupo A+B são coordenadas somente pela Janela A.
         if(InstanciaMestreGrupoFIX255())
         {
            saidaCesta = GerenciarProtecaoMaiorCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarParcialPorLinhaGraficoHeadAB();
            if(!saidaCesta)
               saidaCesta = GerenciarParcialProtecaoCurtaCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarLucroPontaGanhadoraHedgeAB();
            if(!saidaCesta)
               saidaCesta = GerenciarGainGlobalCestaAB();
            if(!saidaCesta)
               saidaCesta = GerenciarStopMovelCestaAB();
         }
         if(!saidaCesta)
         {
            if(!(InpSaidaCestaABBloquearSaidaIsoladaQuandoDuasPontas && CestaABTemDuasPontasAbertasGrupo()))
            {
               if(JanelaAtualEhA_FIX255())
                  saidaProtecaoCompra = GerenciarProtecaoLado(g_compra);
               else
                  saidaProtecaoVenda = GerenciarProtecaoLado(g_venda);
            }
            else if(InstanciaMestreGrupoFIX255())
            {
               LogCestaABDetalhado("BLOQ_SAIDA_ISOLADA_DUAS_PONTAS", false);
               LogHedgeCompleto("BLOQ_SAIDA_ISOLADA_DUAS_PONTAS", "BLOQUEIO", "grupo tem compra e venda abertas; saída isolada por lado bloqueada", 0, 0, 0, 0, 0, 0.0, 0.0, false);
            }
         }
      }
   }
   if(!(saidaCesta || saidaProtecaoCompra || saidaProtecaoVenda) && !BloquearNovasOperacoesFimDiaFIX215())
   {
      if(InpAtivarRobo && g_ambienteLiberado)
      {
         // FIX361/FIX362: depois de ciclo lucrativo, a A0 desse lado pode ser
         // revalidada no proximo tick mesmo que o candle ainda seja o mesmo.
         ENUM_LADO_ROBO ladoLocalFIX255 = LadoOperacionalInstanciaFIX255();
         bool reentradaLucroLocalFIX362=(ladoLocalFIX255==LADO_VENDA
                                         ? g_venda.reentradaImediataAposLucro
                                         : g_compra.reentradaImediataAposLucro);
         bool liberarA0NesteTick = (!InpExecutarSomenteNovoCandleEntrada || g_novoCandle || reentradaLucroLocalFIX362);

         // FIX288: cada grafico envia e gerencia somente seu proprio lado.
         bool posicaoLocalAbertaFIX255 = JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
         bool ladoHabilitadoUsuarioFIX346=LadoHabilitadoUsuarioFIX346(ladoLocalFIX255);

         // FIX318: no modo LIVRE PROTEGIDA, a primeira A0 e tentada imediatamente no primeiro tick.
         // A protecao interna ainda impede duplicidade e nova A0 no mesmo candle depois de uma saida.
         if(EntradaDiretaDemoEfetivaFIX302() && !posicaoLocalAbertaFIX255 && ladoHabilitadoUsuarioFIX346)
         {
            ProcessarEntradaDiretaFIX279();
            AtualizarEstadosDePosicao();
            posicaoLocalAbertaFIX255 = JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
         }

         bool gerenciarLocalFIX255 = posicaoLocalAbertaFIX255 ||
                                     (!EntradaDiretaDemoEfetivaFIX302() && liberarA0NesteTick &&
                                      ladoHabilitadoUsuarioFIX346 &&
                                      TipoOperacaoPermiteLado(ladoLocalFIX255) &&
                                      LadoPermitidoPelaSelecaoHead(ladoLocalFIX255));
         if(gerenciarLocalFIX255)
            GerenciarLado(ladoLocalFIX255);
      }
   }
   int intervaloPainel = IntervaloPainelEfetivo();
   if(g_ultimaAtualizacaoPainelVisual == 0 ||
      (TimeCurrent() - g_ultimaAtualizacaoPainelVisual) >= intervaloPainel)
   {
      AtualizarRodapePainelRapido();
      g_ultimaAtualizacaoPainelVisual = TimeCurrent();
      AtualizarPainelMestre();
   }
   else
   {
      AtualizarRodapePainelRapido();
   }
}


#endif // COPA_CICLO_TICK_MQH
