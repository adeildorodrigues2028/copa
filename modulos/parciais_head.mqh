#ifndef COPA_PARCIAIS_HEAD_MQH
#define COPA_PARCIAIS_HEAD_MQH

// RESPONSABILIDADE: CALCULOS DE RISCO DA CESTA

bool RiscoOperacaoModoCesta()
{
   string modo = Upper(GetCampo(InpRiscoOperacao, "MODO", "CESTA"));
   return (modo == "CESTA" || modo == "AB" || modo == "A+B");
}

double MultiplicadorEntradaOperacaoHeadAB()
{
   if(!InpEntradaOperacaoComandaHeadAB)
      return 1.0;
   if(!InpEntradaOperacaoSomarDuasPontasHeadAB)
      return 1.0;
   double mult = MathAbs(InpEntradaOperacaoPontasHeadAB);
   if(mult < 1.0)
      mult = 1.0;
   return mult;
}

double StopGeralDinamicoHeadFIX359()
{
   // FIX362: uma unica fonte, exatamente o LOSS HEAD digitado pelo usuario.
   return LossHeadEfetivoFIX362();
}

void CalcularStopDinamicoHeadFIX359(double &saldoA,double &saldoB,double &saldoTotal,
                                    double &limiteA,double &limiteB,double &restante,double &usado)
{
   // FIX360: a fonte única do STOP é o ABERTO ATUAL A+B, nunca o acumulado realizado.
   FotoCestaAB fotoCicloFIX360;
   CalcularFotoCestaABOficial(fotoCicloFIX360,false);
   if(fotoCicloFIX360.qtdTotal<=0.0001)
   {
      saldoA=0.0;
      saldoB=0.0;
      saldoTotal=0.0;
   }
   else
   {
      saldoA=NormalizeDouble(fotoCicloFIX360.abertoCompra,2);
      saldoB=NormalizeDouble(fotoCicloFIX360.abertoVenda,2);
      saldoTotal=NormalizeDouble(fotoCicloFIX360.abertoTotal,2);
   }
   double stop=StopGeralDinamicoHeadFIX359();

   // Para o lado A: A + B = -STOP, portanto A_limite = -STOP - B.
   // Para o lado B: A + B = -STOP, portanto B_limite = -STOP - A.
   limiteA=NormalizeDouble(-stop-saldoB,2);
   limiteB=NormalizeDouble(-stop-saldoA,2);
   restante=NormalizeDouble(stop+saldoTotal,2);
   if(restante<0.0) restante=0.0;
   usado=NormalizeDouble(MathMax(0.0,-saldoTotal),2);
}

double StopMovelLadoHeadFIX359(ENUM_LADO_ROBO lado)
{
   double saldoA=0.0,saldoB=0.0,total=0.0,limiteA=0.0,limiteB=0.0,restante=0.0,usado=0.0;
   CalcularStopDinamicoHeadFIX359(saldoA,saldoB,total,limiteA,limiteB,restante,usado);
   return lado==LADO_VENDA ? limiteB : limiteA;
}

double AbertoNecessarioStopMovelHeadFIX359(EstadoLado &estado)
{
   ENUM_LADO_ROBO lado=(estado.lado==LADO_VENDA ? LADO_VENDA : LADO_COMPRA);
   double limiteSaldo=StopMovelLadoHeadFIX359(lado);
   // FIX360: limite por ponta já considera o aberto da outra ponta; realizado não entra novamente.
   return NormalizeDouble(limiteSaldo,2);
}


double StopBaseCestaAB()
{
   // FIX362: LOSS HEAD visivel e a unica fonte em todos os modos.
   return LossHeadEfetivoFIX362();
}

double GainGlobalCestaAB()
{
   // FIX372: marco de ativacao da escala; nao e take-profit.
   double valor=MathAbs(InpProtecaoDiaAtivarReais);
   return NormalizeDouble(valor>0.0 ? valor : 250.0,2);
}

double ResultadoRealizadoCestaABAtual()
{
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   return f.realizadoTotal;
}

double ResultadoAbertoCestaABAtual()
{
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   return f.abertoTotal;
}

double SaldoLiquidoCestaABAtual()
{
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   return f.saldoTotal;
}

double StopMovelAbertoPermitidoCestaAB()
{
   if(InpStopDinamicoHeadFIX359)
   {
      // FIX360: o espaço do stop é calculado apenas sobre o aberto A+B.
      return NormalizeDouble(StopGeralDinamicoHeadFIX359(),2);
   }
   double creditoRealizado = ResultadoRealizadoCestaABAtual();
   if(creditoRealizado < 0.0)
      creditoRealizado = 0.0;
   return StopBaseCestaAB() + creditoRealizado;
}

double EspacoStopRestanteCestaAB()
{
   if(InpStopDinamicoHeadFIX359)
   {
      double saldoA=0.0,saldoB=0.0,total=0.0,limiteA=0.0,limiteB=0.0,restante=0.0,usado=0.0;
      CalcularStopDinamicoHeadFIX359(saldoA,saldoB,total,limiteA,limiteB,restante,usado);
      return restante;
   }
   double espaco = StopBaseCestaAB() + SaldoLiquidoCestaABAtual();
   if(espaco < 0.0)
      espaco = 0.0;
   return espaco;
}

string TextoGainStopCestaPainel()
{
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f,false);
   string escala=TextoEscalonamentoGanhosPainel(MathMax(g_mestre.melhorResultadoDiaTotal,f.saldoTotal));
   return StringFormat("HEAD %s | %s | LOSS %s",
                       TextoMoedaPainelCurto(f.saldoTotal),escala,TextoMoedaPainelCurto(-StopBaseCestaAB()));
}

double LinhaStopFullAtualHedgeAB()
{
   double linha = -StopBaseCestaAB();
   if(g_cestaDefesaCurtaAB > linha)
      linha = g_cestaDefesaCurtaAB;
   if(g_cestaDefesaMaiorAB > linha)
      linha = g_cestaDefesaMaiorAB;
   return NormalizeDouble(linha, 2);
}

string MotivoLinhaStopFullHedgeAB()
{
   double linha = LinhaStopFullAtualHedgeAB();
   double base  = -StopBaseCestaAB();
   if(g_cestaDefesaMaiorAB > 0.0 && MathAbs(linha - g_cestaDefesaMaiorAB) < 0.01)
      return "PROTECAO_MAIOR";
   if(g_cestaDefesaCurtaAB > 0.0 && MathAbs(linha - g_cestaDefesaCurtaAB) < 0.01)
      return "PROTECAO_CURTA";
   if(MathAbs(linha - base) < 0.01)
      return "STOP_FULL_BASE";
   return "STOP_FULL_CALCULADO";
}

void LogStopFullHedgeAB(string contexto, bool forcar=false)
{
   if(!InpLogStopFullHedgeAtivo)
      return;
   datetime agora = TimeCurrent();
   int intervalo = InpLogStopFullHedgeIntervaloSegundos;
   if(intervalo < 0)
      intervalo = 0;
   if(!forcar && intervalo > 0 && (agora - g_ultimoLogStopFullHedgeAB) < intervalo)
      return;
   bool haPosicao = ExistePosicaoAbertaGrupoTotalAB();
   if(!haPosicao && !forcar)
      return;
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   double linhaStop = LinhaStopFullAtualHedgeAB();
   double espaco    = f.saldoTotal - linhaStop;
   if(espaco < 0.0)
      espaco = 0.0;
   double saldoAFIX359=0.0,saldoBFIX359=0.0,totalFIX359=0.0,limiteAFIX359=0.0,limiteBFIX359=0.0,restanteFIX359=0.0,usadoFIX359=0.0;
   CalcularStopDinamicoHeadFIX359(saldoAFIX359,saldoBFIX359,totalFIX359,limiteAFIX359,limiteBFIX359,restanteFIX359,usadoFIX359);
   string msg = StringFormat("STOP FULL HEDGE A+B => modo=%s | multiplicador_head=%.0f | gain_total=%s | saldo=%s | linha_stop=%s | espaco=%s | stop_base=%s | A_saldo=%s | B_saldo=%s | A_stop_movel=%s | B_stop_movel=%s | usado=%s | restante=%s | melhor=%s | defesa_curta=%s | defesa_maior=%s | realizado=%s | aberto=%s | C %.2f V %.2f L %.2f T %.2f | regra: fecha grupo inteiro somente quando saldo diario A+B <= -stop_geral.",
                             MotivoLinhaStopFullHedgeAB(),
                             MultiplicadorEntradaOperacaoHeadAB(),
                             PnlMoedaBRL(GainGlobalCestaAB()),
                             PnlMoedaBRL(f.saldoTotal),
                             PnlMoedaBRL(linhaStop),
                             PnlMoedaBRL(espaco),
                             PnlMoedaBRL(-StopBaseCestaAB()),
                             PnlMoedaBRL(saldoAFIX359),
                             PnlMoedaBRL(saldoBFIX359),
                             PnlMoedaBRL(limiteAFIX359),
                             PnlMoedaBRL(limiteBFIX359),
                             PnlMoedaBRL(usadoFIX359),
                             PnlMoedaBRL(restanteFIX359),
                             PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                             PnlMoedaBRL(g_cestaDefesaCurtaAB),
                             PnlMoedaBRL(g_cestaDefesaMaiorAB),
                             PnlMoedaBRL(f.realizadoTotal),
                             PnlMoedaBRL(f.abertoTotal),
                             f.qtdCompra,
                             f.qtdVenda,
                             f.qtdLiquida,
                             f.qtdTotal);
   RegistrarLogValidacaoSistema(contexto, msg);
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][STOP_FULL_HEDGE_AB] ", msg);
   g_ultimoLogStopFullHedgeAB = agora;
}


// RESPONSABILIDADE: CICLO GAIN STOP E ATUALIZACAO RAPIDA

void ResetarCicloCestaABQuandoFlat()
{
   if(!g_cestaResetarCicloDepoisFlat)
      return;
   if(ExistePosicaoAbertaGrupoTotalAB())
      return;
   g_cestaResetarCicloDepoisFlat = false;
   g_cestaGainDisparado = false;
   g_cestaStopDisparado = false;
   g_cestaMelhorSaldoLiquido = 0.0;
   g_cestaStopMovelAbertoPermitido = StopMovelAbertoPermitidoCestaAB();
   g_cestaEspacoStopRestante = EspacoStopRestanteCestaAB();
   g_cestaDefesaMaiorAB = 0.0;
   g_cestaProtecaoMaiorDisparada = false;
   g_cestaDefesaCurtaAB = 0.0;
   g_cestaParcialCurtaExecutada = false;
   g_cestaProtecaoCurtaDisparada = false;
   g_cestaMetaMarcoCorredorFIX338 = false;
   LimparLocksLucroPontaHedgeAB();
   LimparLocksParciaisHedgeABPorPrefixo();
   g_cicloInicioCompra = 0;
   g_cicloInicioVenda  = 0;
   g_ultimaAtualizacaoHistorico = 0;
   g_mestre.mensagemGeral = "GAIN CESTA A+B finalizado. Ciclo financeiro zerado para nova operação.";
   if(InpGerenciadorOrdensExperts)
      Print("[COPA_AR100][GAIN_CESTA_AB][RESET] Cesta flat. Ciclo A+B zerado para nova entrada limpa.");
}

bool GerenciarGainGlobalCestaAB()
{
   if(!RiscoOperacaoModoCesta())
      return false;
   if(!InpGainGlobalCestaAtivo)
      return false;
   double alvo = GainGlobalCestaAB();
   if(alvo <= 0.0)
      return false;
   bool haPosicao = ExistePosicaoAbertaGrupoTotalAB();
   if(!haPosicao)
   {
      g_cestaGainDisparado = false;
      g_cestaMetaMarcoCorredorFIX338 = false;
      return false;
   }
   FotoCestaAB fotoFIX283;
   CalcularFotoCestaABOficial(fotoFIX283,false);
   double realizado = fotoFIX283.realizadoTotal;
   double aberto    = fotoFIX283.abertoTotal;
   double saldo     = fotoFIX283.abertoTotal;         // FIX360: ganho HEAD usa somente aberto COMPRA+VENDA
   if(CorredorMetaABViraMarcoFIX338())
   {
      if(saldo>g_cestaMelhorSaldoLiquido)
         g_cestaMelhorSaldoLiquido=saldo;
      if(g_cestaMelhorSaldoLiquido<alvo)
         return false;
      double degrau=MathAbs(InpCorredorDegrauReais);
      double folga=MathAbs(InpCorredorFolgaForteReais);
      double pisoInicial=MathMax(0.0,alvo-folga);
      double novoPiso=CalcularPisoCorredorFIX338(g_cestaMelhorSaldoLiquido,alvo,pisoInicial,degrau,folga);
      bool subiu=(novoPiso>g_cestaDefesaCurtaAB);
      if(subiu)
         g_cestaDefesaCurtaAB=novoPiso;
      if(!g_cestaMetaMarcoCorredorFIX338)
      {
         g_cestaMetaMarcoCorredorFIX338=true;
         RegistrarLogValidacaoSistema("FIX338_META_AB_VIROU_MARCO",
            StringFormat("A+B atingiu %s; meta virou marco sem teto | realizado %s | aberto %s | piso inicial %s.",
                         PnlMoedaBRL(alvo),PnlMoedaBRL(realizado),PnlMoedaBRL(aberto),PnlMoedaBRL(g_cestaDefesaCurtaAB)));
      }
      else if(subiu)
      {
         RegistrarLogValidacaoSistema("FIX338_CORREDOR_AB_SUBIU",
            StringFormat("A+B melhor %s | novo piso %s | saldo %s.",
                         PnlMoedaBRL(g_cestaMelhorSaldoLiquido),PnlMoedaBRL(g_cestaDefesaCurtaAB),PnlMoedaBRL(saldo)));
      }
      g_mestre.mensagemGeral=StringFormat("CORREDOR A+B SEM TETO | saldo %s | melhor %s | piso %s | marco %s",
                                          PnlMoedaBRL(saldo),PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                                          PnlMoedaBRL(g_cestaDefesaCurtaAB),PnlMoedaBRL(alvo));
      if(g_cestaDefesaCurtaAB<=0.0 || saldo>g_cestaDefesaCurtaAB)
         return false;
      if(g_cestaProtecaoCurtaDisparada)
         return true;
      g_cestaProtecaoCurtaDisparada=true;
      g_cestaGainDisparado=true;
      g_cestaUltimoFechamentoGlobal=TimeCurrent();
      g_cestaResetarCicloDepoisFlat=true;
      string msgCorredor=StringFormat("CORREDOR A+B: saldo %s <= piso %s | melhor %s | realizado %s | aberto %s. Fecha as duas pontas.",
                                      PnlMoedaBRL(saldo),PnlMoedaBRL(g_cestaDefesaCurtaAB),
                                      PnlMoedaBRL(g_cestaMelhorSaldoLiquido),PnlMoedaBRL(realizado),PnlMoedaBRL(aberto));
      g_mestre.mensagemGeral=msgCorredor;
      RegistrarGerenciadorOrdens(g_painelA,"FIX338_CORREDOR_AB",msgCorredor,0,0,0.0,0.0,true);
      LogStopFullHedgeAB("STOP_FULL_HEDGE_CORREDOR_AB_PRE",true);
      FecharCestaABOficial("CORREDOR_MESTRE_AB_FIX338");
      return true;
   }
   if(saldo < alvo)
      return false;
   if(g_cestaGainDisparado)
      return true;
   g_cestaGainDisparado = true;
   g_cestaUltimoFechamentoGlobal = TimeCurrent();
   if(InpGainGlobalCestaZerarCiclo)
      g_cestaResetarCicloDepoisFlat = true;
   string msg = StringFormat("GAIN CESTA A+B: aberto compra+venda %s >= meta %s | realizado histórico %s | aberto %s. Regra: soma algébrica A+B.",
                             PnlMoedaBRL(saldo),
                             PnlMoedaBRL(alvo),
                             PnlMoedaBRL(realizado),
                             PnlMoedaBRL(aberto));
   g_mestre.mensagemGeral = msg;
   RegistrarGerenciadorOrdens(g_painelA, "GAIN_CESTA_AB", msg, 0, 0, 0.0, 0.0, true);
   LogStopFullHedgeAB("STOP_FULL_HEDGE_GAIN_PRE", true);
   FecharCestaABOficial("GAIN_CESTA_AB");
   return true;
}

bool GerenciarStopMovelCestaAB()
{
   if(!RiscoOperacaoModoCesta())
      return false;
   bool haPosicao = ExistePosicaoAbertaGrupoTotalAB();
   if(!haPosicao)
   {
      g_cestaMelhorSaldoLiquido = 0.0;
      g_cestaStopMovelAbertoPermitido = StopMovelAbertoPermitidoCestaAB();
      g_cestaEspacoStopRestante = EspacoStopRestanteCestaAB();
      g_cestaDefesaMaiorAB = 0.0;
      g_cestaProtecaoMaiorDisparada = false;
      g_cestaStopDisparado = false;
      return false;
   }
   double stopBase = StopBaseCestaAB();
   FotoCestaAB fotoFIX283;
   CalcularFotoCestaABOficial(fotoFIX283,false);
   double realizado = fotoFIX283.realizadoTotal; // apenas informativo/histórico
   double aberto = fotoFIX283.abertoTotal;
   double saldo = fotoFIX283.abertoTotal; // FIX360: STOP MOVEL = aberto COMPRA + aberto VENDA
   if(saldo > g_cestaMelhorSaldoLiquido)
      g_cestaMelhorSaldoLiquido = saldo;
   g_cestaStopMovelAbertoPermitido = StopMovelAbertoPermitidoCestaAB();
   g_cestaEspacoStopRestante = EspacoStopRestanteCestaAB();
   if(stopBase > 0.0 && saldo <= -stopBase)
   {
      if(g_cestaStopDisparado)
         return true;
      g_cestaStopDisparado = true;
      string msg = StringFormat(InpStopDinamicoHeadFIX359 ? "STOP MOVEL A+B: aberto compra+venda %s <= -%s | realizado histórico %s | aberto A+B %s | limite aberto %s." : "STOP CESTA A+B: saldo liquido %s <= -%s | realizado %s | aberto %s | aberto permitido ate %s.",
                                PnlMoedaBRL(saldo),
                                PnlMoedaBRL(stopBase),
                                PnlMoedaBRL(realizado),
                                PnlMoedaBRL(aberto),
                                PnlMoedaBRL(-g_cestaStopMovelAbertoPermitido));
      g_mestre.mensagemGeral = msg;
      RegistrarGerenciadorOrdens(g_painelA, "STOP_CESTA_AB", msg, 0, 0, 0.0, 0.0, true);
      RegistrarLogValidacaoSistema("STOP_PERDA_HEAD_AB_ACIONADO", msg);
      LogStopFullHedgeAB("STOP_FULL_HEDGE_STOP_PRE", true);
      LogStopFullHedgeAB("STOP_PERDA_HEAD_AB_PRE", true);
      FecharCestaABOficial("STOP_CESTA_AB");
      LogStopFullHedgeAB("STOP_PERDA_HEAD_AB_POS", true);
      return true;
   }
   return false;
}

int IntervaloHistoricoEfetivo()
{
   int segundos = InpHistoricoAtualizarSegundos;
   if(segundos <= 0)
      segundos = 1;
   // FIX227: o histórico do DIA precisa responder rápido. O modo leve não impõe mais 5s.
   return segundos;
}

int IntervaloPainelEfetivo()
{
   int segundos = InpPainelAtualizarSegundos;
   if(segundos <= 0)
      segundos = 1;
   if(InpFIX287UltraLeve)
   {
      int minimoFIX287=InpFIX287PainelIntervaloSegundos;
      if(minimoFIX287<1) minimoFIX287=1;
      if(segundos<minimoFIX287) segundos=minimoFIX287;
   }
   return segundos;
}

void ArmarAtualizacaoHistoricoRapidaFIX227(string motivo)
{
   datetime agora=TimeCurrent();
   g_historicoRefreshRapidoAteFIX227=agora+3;
   g_ultimaTentativaHistoricoRapidoFIX227=0;
   g_ultimaAtualizacaoHistorico=0;
   g_ultimaAtualizacaoPainelVisual=0;
   g_ultimaAtualizacaoRodapeVisual=0;
   if(motivo!="")
      RegistrarLogValidacaoSistema("FIX227_HIST_RAPIDO_ARMADO",motivo);
}

void ProcessarAtualizacaoHistoricoRapidaFIX227()
{
   if(g_historicoRefreshRapidoAteFIX227<=0)
      return;
   datetime agora=TimeCurrent();
   if(agora>g_historicoRefreshRapidoAteFIX227)
   {
      g_historicoRefreshRapidoAteFIX227=0;
      g_ultimaTentativaHistoricoRapidoFIX227=0;
      return;
   }
   if(g_ultimaTentativaHistoricoRapidoFIX227>0 &&
      (agora-g_ultimaTentativaHistoricoRapidoFIX227)<1)
      return;
   g_ultimaTentativaHistoricoRapidoFIX227=agora;

   // Reconfirma por 3 segundos: captura imediatamente deal, comissão/taxa e estado final do ticket.
   g_ultimaAtualizacaoHistorico=0;
   AtualizarEstadosDePosicao();
   AtualizarHistoricoObrigatorio();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AtualizarRodapePainelRapido();
   g_ultimaAtualizacaoPainelVisual=agora;
   AtualizarPainelMestre();
   PainelChartRedrawLeve(true);
}

void InicializarMarcoHistoricoZero()
{
   if(!g_identidadeInicializadaFIX304)
      InicializarIdentidadeUnicaFIX304();
   string bruto=StringFormat("%I64d|%s|%s|%d|%d|%s",
                             AccountInfoInteger(ACCOUNT_LOGIN),AccountInfoString(ACCOUNT_SERVER),_Symbol,
                             (int)MagicCompraAtual(),(int)MagicVendaAtual(),g_identidadeGeracaoFIX304);
   string baseChave="AR311_HZ_"+Base36FIX304(HashTextoFIX304(bruto),8);
   g_historicoMarcoZeroChave=baseChave+"_T";
   g_historicoTicketZeroChave=baseChave+"_K";

   bool temHora=GlobalVariableCheck(g_historicoMarcoZeroChave);
   bool temTicket=GlobalVariableCheck(g_historicoTicketZeroChave);
   if(temHora && temTicket)
   {
      g_historicoMarcoZero=(datetime)GlobalVariableGet(g_historicoMarcoZeroChave);
      g_historicoTicketZero=(ulong)GlobalVariableGet(g_historicoTicketZeroChave);
   }
   else
   {
      // V36: migracao permitida somente quando a chave antiga tambem contem
      // conta, simbolo e o mesmo par de Magics. A chave FIX196 nao possui Magic
      // e poderia importar o marco financeiro de outro robo.
      string simboloLegado=_Symbol;
      StringReplace(simboloLegado,".",""); StringReplace(simboloLegado,"#",""); StringReplace(simboloLegado,"-","");
      string baseLegado=StringFormat("AR100_HZ_%I64d_%s_%d_%d",
                                     AccountInfoInteger(ACCOUNT_LOGIN),simboloLegado,
                                     (int)MagicCompraAtual(),(int)MagicVendaAtual());
      if(StringLen(baseLegado)>54) baseLegado=StringSubstr(baseLegado,0,54);
      string horaLegada=baseLegado+"_T";
      string ticketLegado=baseLegado+"_K";
      if(GlobalVariableCheck(horaLegada) && GlobalVariableCheck(ticketLegado))
      {
         g_historicoMarcoZero=(datetime)GlobalVariableGet(horaLegada);
         g_historicoTicketZero=(ulong)GlobalVariableGet(ticketLegado);
      }
      else
      {
         g_historicoMarcoZero=AgoraServidorHistorico();
         g_historicoTicketZero=CapturarMaiorTicketHistoricoExistente();
      }
      GlobalVariableSet(g_historicoMarcoZeroChave,(double)g_historicoMarcoZero);
      GlobalVariableSet(g_historicoTicketZeroChave,(double)g_historicoTicketZero);
   }
   ZerarHistoricoPeriodo(g_histDia,"DIA");
   ZerarHistoricoPeriodo(g_histOntem,"ONTEM");
   ZerarHistoricoPeriodo(g_hist7Dias,"7D");
   ZerarHistoricoPeriodo(g_hist15Dias,"15D");
   ZerarHistoricoPeriodo(g_hist30Dias,"30D");
   ZerarHistoricoPeriodo(g_histTudo,"TUDO");
   PrintFormat("[COPA_AR100][FIX311][HIST_ZERO] hora=%s | ticket_zero=%I64u | chave=%s | id=%s",
               TimeToString(g_historicoMarcoZero,TIME_DATE|TIME_SECONDS),g_historicoTicketZero,
               g_historicoTicketZeroChave,g_identidadeGeracaoFIX304);
}


bool AvaliarExecutarParcialLinhaTipo(long tipo)
{
   double vol = 0.0;
   double precoMedio = 0.0;
   double lucroAbertoServidorManual = 0.0;
   double precoFechamento = 0.0;
   if(!CalcularInfoGrupoTipoAB(tipo, vol, precoMedio, lucroAbertoServidorManual, precoFechamento))
      return false;
   double gatilhoBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   double passoBase = MathAbs(ParcialPassoBaseReaisEfetivo());
   if(gatilhoBase <= 0.0)
      gatilhoBase = MathAbs(InpParcialGatilhoReais);
   if(passoBase <= 0.0)
      passoBase = 5.0;
   double gatilho = GatilhoParcialEfetivoPorVolume(gatilhoBase, vol);
   double passo = GatilhoParcialEfetivoPorVolume(passoBase, vol);
   double gainPorPonta = MathAbs(g_risco.metaOperacao);
   if(gainPorPonta <= 0.0)
      gainPorPonta = MathAbs(InpEntradaGanhoAlvoReais);
   if(InpParcialForcarTotalAntesDoGain && gainPorPonta > 0.0 && gatilho >= gainPorPonta)
   {
      gatilho = MathAbs(gatilhoBase);
      passo = MathAbs(passoBase);
   }
   double lucroEstimado = LucroEstimadoGrupoTipoPorPreco(tipo, vol, precoMedio, precoFechamento);
   if(gatilho <= 0.0 || passo <= 0.0)
      return false;
   EstadoLado estadoRef;
   if(tipo == POSITION_TYPE_BUY)
      estadoRef = g_compra;
   else
      estadoRef = g_venda;
   double precoAlvo = 0.0;
   bool tocouLinha = false;
   int nivel = 0;
   string criterioLinha = "FINANCEIRO";
   double distAumPontos = 0.0;
   double distLinhaPontos = 0.0;
   double precoEntradaRef = 0.0;
   if(ParcialRecuoAumentoAtivoEfetivo())
   {
      precoAlvo = PrecoNivelParcialRecuoAumento(estadoRef, tipo, gatilhoBase, distAumPontos, distLinhaPontos, precoEntradaRef);
      if(precoAlvo > 0.0)
      {
         criterioLinha = "RECUO_AUMENTO";
         tocouLinha = (tipo == POSITION_TYPE_BUY ? precoFechamento >= precoAlvo : precoFechamento <= precoAlvo);
         double distAtual = 0.0;
         if(tipo == POSITION_TYPE_BUY)
            distAtual = (precoEntradaRef - precoFechamento) / _Point;
         else
            distAtual = (precoFechamento - precoEntradaRef) / _Point;
         double recuoAtual = distAumPontos - distAtual;
         if(tocouLinha || recuoAtual >= gatilhoBase)
            nivel = 1 + (int)MathFloor((MathMax(recuoAtual, gatilhoBase) - gatilhoBase) / passoBase);
      }
   }
   if(precoAlvo <= 0.0)
   {
      double distAlvo = DistanciaPrecoPorFinanceiro(gatilho, vol);
      if(distAlvo <= 0.0)
         return false;
      precoAlvo = (tipo == POSITION_TYPE_BUY ? precoMedio + distAlvo : precoMedio - distAlvo);
      tocouLinha = (tipo == POSITION_TYPE_BUY ? precoFechamento >= precoAlvo : precoFechamento <= precoAlvo);
      if(tocouLinha || lucroEstimado >= gatilho)
         nivel = 1 + (int)MathFloor((MathMax(lucroEstimado, gatilho) - gatilho) / passo);
   }
   string lado = (tipo == POSITION_TYPE_BUY ? "COMPRA" : "VENDA");
   string msgCheck = StringFormat("PARCIAL LINHA CHECK | %s | criterio %s | vol %.2f | medio %.0f | entrada_ref %.0f | preco fecha %.0f | linha %.0f | dist_aum %.0f | dist_linha %.0f | lucro estimado %s | gatilho %s | tocou %s | nivel %d",
                                  lado,
                                  criterioLinha,
                                  vol,
                                  precoMedio,
                                  precoEntradaRef,
                                  precoFechamento,
                                  precoAlvo,
                                  distAumPontos,
                                  distLinhaPontos,
                                  PnlMoedaBRL(lucroEstimado),
                                  (criterioLinha == "RECUO_AUMENTO" ? StringFormat("%.0fP", gatilhoBase) : PnlMoedaBRL(gatilho)),
                                  tocouLinha ? "SIM" : "NAO",
                                  nivel);
   RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_CHECK", msgCheck);
   if(nivel <= 0)
      return false;
   int nivelRegistrado = NivelParcialLinhaHeadABRegistrado(tipo);
   if(nivelRegistrado >= nivel)
      return false;
   double volumeParcial = CalcularVolumeParcialSeguro(vol, ParcialPercentualVolumeEfetivo());
   if(volumeParcial <= 0.0)
   {
      RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_BLOCK", "Tocou linha, mas volume parcial ficou abaixo do minimo seguro. " + msgCheck);
      return false;
   }
   if(!RegistrarLockParcialLinhaHeadAB(tipo))
   {
      RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_LOCK", "Outra janela ja esta enviando parcial por linha. " + msgCheck);
      return false;
   }
   string msgPre = StringFormat("PARCIAL POR LINHA DO GRAFICO | %s | preco %.0f tocou linha %.0f | lucro %s >= gatilho %s | vol fecha %.2f | nivel %d",
                                lado,
                                precoFechamento,
                                precoAlvo,
                                PnlMoedaBRL(lucroEstimado),
                                PnlMoedaBRL(gatilho),
                                volumeParcial,
                                nivel);
   RegistrarGerenciadorOrdens(g_painelA, "PARCIAL_LINHA_PRECO_PRE", msgPre, 0, 0, volumeParcial, precoFechamento, true);
   RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_PRE", msgPre);
   LogHedgeCompleto("PARCIAL_LINHA_PRECO_PRE", "ANTES_PARCIAL_POR_LINHA", msgPre, 0, 0, 0, 0, 0, volumeParcial, precoFechamento, true);
   bool ok = FecharParcialGrupoPorTipo(tipo, volumeParcial, "PARCIAL_LINHA_GRAFICO_AB");
   if(ok)
   {
      RegistrarNivelParcialLinhaHeadAB(tipo, nivel);
      RegistrarNivelLucroPontaHedgeAB(tipo, nivel);
      g_cestaParcialCurtaExecutada = true;
      RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_OK", msgPre);
   }
   else
   {
      RegistrarLogValidacaoSistema("PARCIAL_LINHA_PRECO_REJECT", msgPre);
   }
   return ok;
}

bool GerenciarParcialPorLinhaGraficoHeadAB()
{
   if(!InpParcialExecutarAoTocarLinhaGrafico)
      return false;
   if(!ParcialOperacaoAtivaEfetiva())
      return false;
   if(!RiscoOperacaoModoCesta())
      return false;
   bool okBuy = AvaliarExecutarParcialLinhaTipo(POSITION_TYPE_BUY);
   if(okBuy)
      return true;
   bool okSell = AvaliarExecutarParcialLinhaTipo(POSITION_TYPE_SELL);
   if(okSell)
      return true;
   return false;
}

bool GerenciarParcialProtecaoCurtaCestaAB()
{
   if(!CestaABTemDuasPontasAbertas())
      return false;
   double realizado = ResultadoRealizadoCestaABAtual();
   double aberto    = ResultadoAbertoCestaABAtual();
   double saldo     = realizado + aberto;
   if(saldo > g_cestaMelhorSaldoLiquido)
      g_cestaMelhorSaldoLiquido = saldo;
   double gatilhoParcialBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   double gatilhoParcial = GatilhoParcialEfetivoCestaAB(gatilhoParcialBase);
   double gatilhoProtecao = MathAbs(g_entradaTrailingAtivarReaisEfetivo);
   double gatilho = gatilhoParcial;
   if(gatilho <= 0.0 || (gatilhoProtecao > 0.0 && gatilhoProtecao < gatilho))
      gatilho = gatilhoProtecao;
   if(gatilho > 0.0 && g_cestaMelhorSaldoLiquido >= gatilho)
   {
      double defesa = CalcularDefesaCurtaPorDegrau(g_cestaMelhorSaldoLiquido);
      if(defesa > g_cestaDefesaCurtaAB)
         g_cestaDefesaCurtaAB = defesa;
   }
   if(ParcialOperacaoAtivaEfetiva() && !g_cestaParcialCurtaExecutada && gatilhoParcial > 0.0 && saldo >= gatilhoParcial)
   {
      bool usarA = (g_painelA.resultadoAberto >= g_painelB.resultadoAberto);
      double volumeParcial = usarA
                              ? CalcularVolumeParcialSeguro(g_painelA.contratos, ParcialPercentualVolumeEfetivo())
                              : CalcularVolumeParcialSeguro(g_painelB.contratos, ParcialPercentualVolumeEfetivo());
      if(volumeParcial <= 0.0)
      {
         usarA = !usarA;
         volumeParcial = usarA
                         ? CalcularVolumeParcialSeguro(g_painelA.contratos, ParcialPercentualVolumeEfetivo())
                         : CalcularVolumeParcialSeguro(g_painelB.contratos, ParcialPercentualVolumeEfetivo());
      }
      if(volumeParcial > 0.0)
      {
         bool ok = false;
         string msg = StringFormat("PARCIAL CURTA A+B: saldo %s >= gatilho %s | realizado %s | aberto %s | ponta %s | volume %.2f.",
                                   PnlMoedaBRL(saldo),
                                   PnlMoedaBRL(gatilhoParcial),
                                   PnlMoedaBRL(realizado),
                                   PnlMoedaBRL(aberto),
                                   usarA ? "A" : "B",
                                   volumeParcial);
         g_mestre.mensagemGeral = msg;
         if(usarA)
         {
            RegistrarGerenciadorOrdens(g_painelA, "PARCIAL_CURTA_AB", msg, 0, 0, volumeParcial, 0.0, true);
            ok = FecharParcialPosicoesLado(g_painelA, volumeParcial, "PARCIAL_CURTA_AB");
         }
         else
         {
            RegistrarGerenciadorOrdens(g_painelB, "PARCIAL_CURTA_AB", msg, 0, 0, volumeParcial, 0.0, true);
            ok = FecharParcialPosicoesLado(g_painelB, volumeParcial, "PARCIAL_CURTA_AB");
         }
         if(ok)
         {
            g_cestaParcialCurtaExecutada = true;
            return true;
         }
      }
      else
      {
         string msg = StringFormat("PARCIAL CURTA A+B aguardando volume: saldo %s >= gatilho %s, mas nenhuma ponta tem volume parcial seguro.",
                                   PnlMoedaBRL(saldo),
                                   PnlMoedaBRL(gatilhoParcial));
         g_mestre.mensagemGeral = msg;
         RegistrarGerenciadorOrdens(g_painelA, "PARCIAL_CURTA_AB_BLOCK", msg, 0, 0, 0.0, 0.0, false);
      }
   }
   if(g_cestaDefesaCurtaAB <= 0.0)
      return false;
   g_mestre.mensagemGeral = StringFormat("Protecao curta A+B ON: saldo %s | melhor %s | defesa %s.",
                                         PnlMoedaBRL(saldo),
                                         PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                                         PnlMoedaBRL(g_cestaDefesaCurtaAB));
   if(saldo > g_cestaDefesaCurtaAB)
      return false;
   if(g_cestaProtecaoCurtaDisparada)
      return true;
   g_cestaProtecaoCurtaDisparada = true;
   g_cestaUltimoFechamentoGlobal = TimeCurrent();
   g_cestaResetarCicloDepoisFlat = true;
   string msg = StringFormat("PROTECAO CURTA A+B: saldo %s <= defesa %s | melhor %s | realizado %s | aberto %s. Fecha o grupo inteiro de Magics.",
                             PnlMoedaBRL(saldo),
                             PnlMoedaBRL(g_cestaDefesaCurtaAB),
                             PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                             PnlMoedaBRL(realizado),
                             PnlMoedaBRL(aberto));
   g_mestre.mensagemGeral = msg;
   RegistrarGerenciadorOrdens(g_painelA, "PROTECAO_CURTA_AB", msg, 0, 0, 0.0, 0.0, true);
   LogStopFullHedgeAB("STOP_FULL_HEDGE_PROTECAO_CURTA_PRE", true);
   FecharCestaABOficial("PROTECAO_CURTA_AB");
   return true;
}

string ChaveLucroPontaHedgeAB(long tipo, string sufixo)
{
   string lado = (tipo == POSITION_TYPE_BUY ? "B" : "S");
   return ChaveGlobalCurtaAB() + "LP_" + lado + "_" + ChaveCicloGrupoTipoAB(tipo) + "_" + sufixo;
}

int NivelLucroPontaHedgeAB(double lucro, double volumePonta)
{
   double gatilhoBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   double passoBase   = MathAbs(ParcialPassoBaseReaisEfetivo());
   if(gatilhoBase <= 0.0)
      gatilhoBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   if(gatilhoBase <= 0.0)
      gatilhoBase = 15.0;
   if(passoBase <= 0.0)
      passoBase = 5.0;
   double gatilho = GatilhoParcialEfetivoPorVolume(gatilhoBase, volumePonta);
   double passo   = GatilhoParcialEfetivoPorVolume(passoBase, volumePonta);
   if(gatilho <= 0.0 || passo <= 0.0)
      return 0;
   if(lucro < gatilho)
      return 0;
   return 1 + (int)MathFloor((lucro - gatilho) / passo);
}

int NivelLucroPontaHedgeABRegistrado(long tipo)
{
   string chave = ChaveLucroPontaHedgeAB(tipo, "NIVEL");
   if(!GlobalVariableCheck(chave))
      return 0;
   return (int)GlobalVariableGet(chave);
}

void RegistrarNivelLucroPontaHedgeAB(long tipo, int nivel)
{
   if(nivel <= 0)
      return;
   GlobalVariableSet(ChaveLucroPontaHedgeAB(tipo, "NIVEL"), (double)nivel);
}

bool RegistrarLockLucroPontaHedgeAB(long tipo)
{
   int cooldown = InpHedgeLucroPontaCooldownSegundos;
   if(cooldown < 0)
      cooldown = 0;
   string chave = ChaveLucroPontaHedgeAB(tipo, "LOCK");
   double agora = (double)TimeCurrent();
   if(!GlobalVariableCheck(chave))
      GlobalVariableSet(chave, 0.0);
   double anterior = GlobalVariableGet(chave);
   if(cooldown > 0 && (agora - anterior) < cooldown)
      return false;
   return GlobalVariableSetOnCondition(chave, agora, anterior);
}

void LimparLocksLucroPontaHedgeAB()
{
   GlobalVariableDel(ChaveLucroPontaHedgeAB(POSITION_TYPE_BUY, "NIVEL"));
   GlobalVariableDel(ChaveLucroPontaHedgeAB(POSITION_TYPE_SELL, "NIVEL"));
   GlobalVariableDel(ChaveLucroPontaHedgeAB(POSITION_TYPE_BUY, "LOCK"));
   GlobalVariableDel(ChaveLucroPontaHedgeAB(POSITION_TYPE_SELL, "LOCK"));
}

bool FecharParcialGrupoPorTipo(long tipo, double volumeDesejado, string motivo)
{
   double restante = NormalizarVolumeParaFechamento(volumeDesejado);
   if(restante <= 0.0)
   {
      RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_BLOCK", "Volume parcial abaixo do mínimo do ativo.");
      return false;
   }
   bool enviouAlgo = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0 && restante > 0.0001; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      if(!MagicPertencePainelTotalAB(magic))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if(type != tipo)
         continue;
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
      req.magic        = (ulong)magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " GRUPOAB",req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      string lado = (type == POSITION_TYPE_BUY ? "COMPRA" : "VENDA");
      LogHedgeCompleto("LUCRO_PONTA_HEDGE_ENVIO", "ENVIO_PARCIAL_PONTA_GANHADORA", motivo + " | lado " + lado, ticket, 0, magic, 0, 0, req.volume, req.price, true);
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         enviouAlgo = true;
         restante -= req.volume;
         g_historicoTeveSaidaSessao = true;
         g_ultimaAtualizacaoHistorico = 0;
         string msgOk = StringFormat("LUCRO PONTA HEDGE OK | %s | Magic %d | Ticket %s | Volume %.2f | Preco %.0f",
                                     lado,
                                     (int)magic,
                                     IntegerToString((long)ticket),
                                     req.volume,
                                     req.price);
         RegistrarGerenciadorOrdens(g_painelA, "LUCRO_PONTA_HEDGE_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "LUCRO_PONTA_HEDGE_OK", msgOk, res.retcode, 0, req.volume, req.price, true);
         LogHedgeCompleto("LUCRO_PONTA_HEDGE_RESULT", "RESULTADO_PARCIAL_PONTA_OK", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         string msgErro = StringFormat("LUCRO PONTA HEDGE REJECT | %s | Magic %d | Ticket %s | Retcode %s | Erro %s",
                                       lado,
                                       (int)magic,
                                       IntegerToString((long)ticket),
                                       IntegerToString((int)res.retcode),
                                       IntegerToString(ultimoErro));
         RegistrarGerenciadorOrdens(g_painelA, "LUCRO_PONTA_HEDGE_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         RegistrarLogValidacaoCSV(g_painelA, "LUCRO_PONTA_HEDGE_REJECT", msgErro, res.retcode, ultimoErro, req.volume, req.price, true);
         LogHedgeCompleto("LUCRO_PONTA_HEDGE_RESULT", "RESULTADO_PARCIAL_PONTA_REJECT", motivo + " | " + lado, ticket, res.deal, magic, res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!enviouAlgo)
      RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_BLOCK", "Parcial por ponta solicitada, mas nenhuma posição válida do grupo foi encontrada.");
   return (enviouAlgo && tudoOk);
}

bool GerenciarLucroPontaGanhadoraHedgeAB()
{
   if(!InpHedgeRealizarLucroPontaGanhadora)
      return false;
   if(!RiscoOperacaoModoCesta())
      return false;
   if(!CestaABTemDuasPontasAbertasGrupo())
      return false;
   double qtdCompra = 0.0;
   double qtdVenda = 0.0;
   double totalBruto = 0.0;
   double abertoCompra = 0.0;
   double abertoVenda = 0.0;
   double abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal);
   double realizado = ResultadoRealizadoCestaABAtual();
   double saldo = realizado + abertoTotal;
   double gatilhoBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   if(gatilhoBase <= 0.0)
      gatilhoBase = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   if(gatilhoBase <= 0.0)
      gatilhoBase = 15.0;
   double gatilhoCompra = GatilhoParcialEfetivoPorVolume(gatilhoBase, qtdCompra);
   double gatilhoVenda  = GatilhoParcialEfetivoPorVolume(gatilhoBase, qtdVenda);
   long tipoAlvo = -1;
   double lucroAlvo = 0.0;
   double qtdAlvo = 0.0;
   double gatilhoAlvo = 0.0;
   bool compraPode = (qtdCompra > 0.0001 && abertoCompra >= gatilhoCompra);
   bool vendaPode  = (qtdVenda  > 0.0001 && abertoVenda  >= gatilhoVenda);
   if(compraPode && (!vendaPode || abertoCompra >= abertoVenda))
   {
      tipoAlvo = POSITION_TYPE_BUY;
      lucroAlvo = abertoCompra;
      qtdAlvo = qtdCompra;
      gatilhoAlvo = gatilhoCompra;
   }
   else if(vendaPode)
   {
      tipoAlvo = POSITION_TYPE_SELL;
      lucroAlvo = abertoVenda;
      qtdAlvo = qtdVenda;
      gatilhoAlvo = gatilhoVenda;
   }
   else
   {
      string msgCheck = StringFormat("Sem captura: C %s/%.2f | V %s/%.2f | saldo A+B %s | gatilho %s.",
                                     PnlMoedaBRL(abertoCompra), qtdCompra,
                                     PnlMoedaBRL(abertoVenda), qtdVenda,
                                     PnlMoedaBRL(saldo),
                                     ParcialPorContratoEfetivo() ? StringFormat("C %s / V %s", PnlMoedaBRL(gatilhoCompra), PnlMoedaBRL(gatilhoVenda)) : PnlMoedaBRL(gatilhoBase));
      RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_CHECK", msgCheck);
      return false;
   }
   int nivel = NivelLucroPontaHedgeAB(lucroAlvo, qtdAlvo);
   if(nivel <= 0)
      return false;
   int nivelRegistrado = NivelLucroPontaHedgeABRegistrado(tipoAlvo);
   if(nivelRegistrado >= nivel)
      return false;
   double volumeParcial = CalcularVolumeParcialSeguro(qtdAlvo, InpHedgeLucroPontaPercentualVolume);
   if(volumeParcial <= 0.0)
   {
      string msgBlock = StringFormat("Captura bloqueada: ponta %s lucro %s nivel %d, mas volume %.2f não permite parcial segura.",
                                     tipoAlvo == POSITION_TYPE_BUY ? "COMPRA" : "VENDA",
                                     PnlMoedaBRL(lucroAlvo),
                                     nivel,
                                     qtdAlvo);
      RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_BLOCK", msgBlock);
      return false;
   }
   if(!RegistrarLockLucroPontaHedgeAB(tipoAlvo))
   {
      RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_LOCK", "Outra janela já está enviando captura de lucro da ponta ganhadora.");
      return false;
   }
   string lado = (tipoAlvo == POSITION_TYPE_BUY ? "COMPRA" : "VENDA");
   string msg = StringFormat("CAPTURA LUCRO PONTA HEDGE: lado %s | lucro ponta %s >= gatilho %s | nivel %d | volume %.2f | C %s V %s | realizado %s | saldo A+B %s.",
                             lado,
                             PnlMoedaBRL(lucroAlvo),
                             PnlMoedaBRL(gatilhoAlvo),
                             nivel,
                             volumeParcial,
                             PnlMoedaBRL(abertoCompra),
                             PnlMoedaBRL(abertoVenda),
                             PnlMoedaBRL(realizado),
                             PnlMoedaBRL(saldo));
   g_mestre.mensagemGeral = msg;
   RegistrarGerenciadorOrdens(g_painelA, "LUCRO_PONTA_HEDGE_PRE", msg, 0, 0, volumeParcial, 0.0, true);
   RegistrarLogValidacaoSistema("LUCRO_PONTA_HEDGE_PRE", msg);
   LogHedgeCompleto("LUCRO_PONTA_HEDGE_PRE", "ANTES_PARCIAL_PONTA_GANHADORA", lado, 0, 0, 0, 0, 0, volumeParcial, 0.0, true);
   bool ok = FecharParcialGrupoPorTipo(tipoAlvo, volumeParcial, "LUCRO_PONTA_HEDGE_AB");
   if(ok)
   {
      RegistrarNivelLucroPontaHedgeAB(tipoAlvo, nivel);
      g_cestaParcialCurtaExecutada = true;
   }
   return ok;
}


// ============================================================================
// RESPONSABILIDADE: PROTECAO FINANCEIRA DA CESTA E POR LADO
// ============================================================================

double CalcularDefesaCurtaPorDegrau(double melhorLucro)
{
   double passo = g_risco.trailPasso;
   if(passo <= 0.0)
      passo = 2.50;
   if(melhorLucro <= 0.0)
      return 0.0;
   double defesa = melhorLucro - passo;
   if(defesa < 0.0)
      defesa = 0.0;
   defesa = MathFloor(defesa / passo) * passo;
   if(defesa < g_risco.defesaMinima)
      defesa = g_risco.defesaMinima;
   double tetoCurto = MathAbs(InpProtecaoCurtaDefesaMaxReais);
   if(tetoCurto > 0.0 && defesa > tetoCurto)
      defesa = tetoCurto;
   if(defesa > melhorLucro)
      defesa = melhorLucro;
   return NormalizeDouble(defesa, 2);
}

double CalcularDefesaMaiorCestaAB(double melhorLucro)
{
   if(!InpProtecaoMaiorCestaABAtiva)
      return 0.0;
   double ativar = MathAbs(InpProtecaoMaiorAtivarEmReais);
   double folga  = MathAbs(InpProtecaoMaiorFolgaReais);
   double passo  = MathAbs(InpProtecaoMaiorPassoReais);
   if(ativar <= 0.0 || folga <= 0.0)
      return 0.0;
   if(passo <= 0.0)
      passo = 50.0;
   if(melhorLucro < ativar)
      return 0.0;
   double nivel = MathFloor(melhorLucro / passo) * passo;
   if(nivel < ativar)
      nivel = ativar;
   double defesa = nivel - folga;
   if(defesa < 0.0)
      defesa = 0.0;
   return NormalizeDouble(defesa, 2);
}

bool GerenciarProtecaoMaiorCestaAB()
{
   if(!RiscoOperacaoModoCesta())
      return false;
   if(!InpProtecaoMaiorCestaABAtiva)
      return false;
   bool haPosicao = ExistePosicaoAbertaGrupoTotalAB();
   if(!haPosicao)
   {
      g_cestaMelhorSaldoLiquido = 0.0;
      g_cestaDefesaMaiorAB = 0.0;
      g_cestaProtecaoMaiorDisparada = false;
      return false;
   }
   double realizado = ResultadoRealizadoCestaABAtual();
   double aberto    = ResultadoAbertoCestaABAtual();
   double saldo     = realizado + aberto;
   if(saldo > g_cestaMelhorSaldoLiquido)
      g_cestaMelhorSaldoLiquido = saldo;
   double defesa = CalcularDefesaMaiorCestaAB(g_cestaMelhorSaldoLiquido);
   if(defesa > g_cestaDefesaMaiorAB)
      g_cestaDefesaMaiorAB = defesa;
   if(g_cestaDefesaMaiorAB <= 0.0)
      return false;
   g_mestre.mensagemGeral = StringFormat("Protecao A+B ON: saldo %s | melhor %s | defesa %s | folga %s",
                                         PnlMoedaBRL(saldo),
                                         PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                                         PnlMoedaBRL(g_cestaDefesaMaiorAB),
                                         PnlMoedaBRL(MathAbs(InpProtecaoMaiorFolgaReais)));
   if(saldo > g_cestaDefesaMaiorAB)
      return false;
   if(g_cestaProtecaoMaiorDisparada)
      return true;
   g_cestaProtecaoMaiorDisparada = true;
   g_cestaUltimoFechamentoGlobal = TimeCurrent();
   g_cestaResetarCicloDepoisFlat = true;
   string msg = StringFormat("PROTECAO MAIOR A+B: saldo %s <= defesa %s | melhor %s | realizado %s | aberto %s. Fecha o grupo inteiro de Magics.",
                             PnlMoedaBRL(saldo),
                             PnlMoedaBRL(g_cestaDefesaMaiorAB),
                             PnlMoedaBRL(g_cestaMelhorSaldoLiquido),
                             PnlMoedaBRL(realizado),
                             PnlMoedaBRL(aberto));
   g_mestre.mensagemGeral = msg;
   RegistrarGerenciadorOrdens(g_painelA, "PROTECAO_MAIOR_AB", msg, 0, 0, 0.0, 0.0, true);
   LogStopFullHedgeAB("STOP_FULL_HEDGE_PROTECAO_MAIOR_PRE", true);
   FecharCestaABOficial("PROTECAO_MAIOR_AB");
   return true;
}

void ArmarProtecaoFinanceiraLado(EstadoLado &estado, string contexto, bool importante)
{
   double resultadoProtecao = ResultadoProtecaoOperacaoLado(estado);
   if(resultadoProtecao > estado.melhorResultadoAberto)
      estado.melhorResultadoAberto = resultadoProtecao;
   double defesa = CalcularDefesaCurtaPorDegrau(estado.melhorResultadoAberto);
   if(defesa > estado.valorDefendido)
   {
      estado.valorDefendido = defesa;
      estado.lucroProtegido = true;
      RegistrarGerenciadorOrdens(estado, contexto,
                                 StringFormat("Protecao curta armada: total %s | aberto %s | realizado %s | melhor %s | defesa %s | passo %s",
                                              PnlMoedaBRL(resultadoProtecao),
                                              PnlMoedaBRL(estado.resultadoAberto),
                                              PnlMoedaBRL(estado.resultadoFechado),
                                              PnlMoedaBRL(estado.melhorResultadoAberto),
                                              PnlMoedaBRL(estado.valorDefendido),
                                              PnlMoedaBRL(g_risco.trailPasso)),
                                 0, 0, 0.0, 0.0, importante);
   }
   else if(estado.lucroProtegido)
   {
      estado.ultimaMensagem = StringFormat("Protecao curta ON: total %s | aberto %s | realizado %s | defesa %s.",
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado),
                                           PnlMoedaBRL(estado.valorDefendido));
   }
}

bool GerenciarProtecaoLado(EstadoLado &estado)
{
   if(!estado.posicaoAberta)
   {
      estado.lucroProtegido = false;
      estado.valorDefendido = 0.0;
      estado.melhorResultadoAberto = 0.0;
      estado.modoLongo = false;
      return false;
   }
   double resultadoProtecao = ResultadoProtecaoOperacaoLado(estado);
   if(resultadoProtecao > estado.melhorResultadoAberto)
      estado.melhorResultadoAberto = resultadoProtecao;
   double alvoGanho = MathAbs(InpEntradaGanhoAlvoReais);
   if(GerenciarParciaisLado(estado))
      return true;
   resultadoProtecao = ResultadoProtecaoOperacaoLado(estado);
   if(resultadoProtecao > estado.melhorResultadoAberto)
      estado.melhorResultadoAberto = resultadoProtecao;
   bool usarLonga = InpOperacaoLongaUsar;
   if(!usarLonga && alvoGanho > 0.0 && resultadoProtecao >= alvoGanho)
   {
      estado.ultimaMensagem = StringFormat("Saida positiva: alvo %s atingido. Total %s | aberto %s | realizado %s.",
                                           PnlMoedaBRL(alvoGanho),
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado));
      FecharPosicoesLado(estado, "ALVO_GANHO");
      return true;
   }
   bool bateuProtecao = (g_risco.naoVirarPrejuizo &&
                         g_risco.defesaAtivaEm > 0.0 &&
                         estado.melhorResultadoAberto >= g_risco.defesaAtivaEm);
   if(bateuProtecao || estado.lucroProtegido)
   {
      ArmarProtecaoFinanceiraLado(estado, "PROTECAO_TRAIL", false);
      estado.ultimaMensagem = StringFormat("Protecao ON: total %s | aberto %s | realizado %s | melhor %s | defesa %s.",
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado),
                                           PnlMoedaBRL(estado.melhorResultadoAberto),
                                           PnlMoedaBRL(estado.valorDefendido));
   }
   if(usarLonga && resultadoProtecao >= MathAbs(InpOperacaoLongaAtivarEmReais))
   {
      if(!estado.modoLongo)
      {
         estado.modoLongo = true;
         RegistrarGerenciadorOrdens(estado, "LONGA_20_ON",
                                    StringFormat("Operacao longa ativada: total %s | gatilho %s | saida por HiLo/STR/VOLQ/VOLF/protecao.",
                                                 PnlMoedaBRL(resultadoProtecao),
                                                 PnlMoedaBRL(MathAbs(InpOperacaoLongaAtivarEmReais))),
                                    0, 0, 0.0, 0.0, true);
      }
   }
   double gatilhoLonga = MathAbs(InpOperacaoLongaAtivarEmReais);
   bool alvoFinalLongaConfigurado = (alvoGanho > gatilhoLonga);
   if(usarLonga && alvoFinalLongaConfigurado && resultadoProtecao >= alvoGanho)
   {
      estado.ultimaMensagem = StringFormat("Saida longa: alvo final %s atingido. Total %s | aberto %s | realizado %s.",
                                           PnlMoedaBRL(alvoGanho),
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado));
      FecharPosicoesLado(estado, "ALVO_LONGA_FINAL");
      return true;
   }
   if(usarLonga && estado.modoLongo && SinalSaidaOperacaoLonga(estado))
   {
      estado.ultimaMensagem = StringFormat("Saida longa tecnica: total %s | aberto %s | realizado %s | score %.1f | vol qtd %.0f | vol fin %.0f.",
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado),
                                           g_mercado.scoreFluxo,
                                           g_mercado.volq,
                                           g_mercado.volf);
      FecharPosicoesLado(estado, "LONGA_TECNICA");
      return true;
   }
   if(InpProtecaoFecharAoRetrair &&
      estado.lucroProtegido &&
      estado.valorDefendido > 0.0 &&
      resultadoProtecao <= estado.valorDefendido)
   {
      estado.ultimaMensagem = StringFormat("Saida por protecao: total %s <= defesa %s | aberto %s | realizado %s | melhor %s.",
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(estado.valorDefendido),
                                           PnlMoedaBRL(estado.resultadoAberto),
                                           PnlMoedaBRL(estado.resultadoFechado),
                                           PnlMoedaBRL(estado.melhorResultadoAberto));
      FecharPosicoesLado(estado, "PROTECAO_LUCRO");
      return true;
   }
   if(InpProtecaoFecharAoRetrair &&
      estado.lucroProtegido &&
      estado.melhorResultadoAberto >= g_risco.defesaAtivaEm &&
      resultadoProtecao <= 0.0)
   {
      estado.ultimaMensagem = StringFormat("Saida seguranca protecao: ja bateu %s e voltou para total %s.",
                                           PnlMoedaBRL(estado.melhorResultadoAberto),
                                           PnlMoedaBRL(resultadoProtecao));
      FecharPosicoesLado(estado, "PROTECAO_ZERO");
      return true;
   }
   double perdaMaxima = InpStopDinamicoHeadFIX359 ? 0.0 : MathAbs(InpEntradaPerdaMaximaReais);
   if(perdaMaxima > 0.0 && resultadoProtecao <= -perdaMaxima)
   {
      estado.ultimaMensagem = StringFormat("Saida por perda maxima: total %s <= -%s.",
                                           PnlMoedaBRL(resultadoProtecao),
                                           PnlMoedaBRL(perdaMaxima));
      FecharPosicoesLado(estado, "PERDA_MAXIMA");
      return true;
   }
   return false;
}


#endif // COPA_PARCIAIS_HEAD_MQH
