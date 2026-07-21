#ifndef COPA_HISTORICO_CORE_MQH
#define COPA_HISTORICO_CORE_MQH

// ============================================================================
// RESPONSABILIDADE: MARCO INICIAL DO HISTORICO
// ============================================================================

ulong CapturarMaiorTicketHistoricoExistente()
{
   ulong maior = 0;
   datetime fim = AgoraServidorHistorico() + 7 * 86400;
   if(!HistorySelect(0, fim))
      return 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > maior)
         maior = ticket;
   }
   return maior;
}

bool DealEhDepoisDoMarcoHistoricoZero(ulong deal)
{
   if(deal == 0)
      return false;
   if(g_historicoTicketZero == 0 && g_historicoMarcoZero <= 0)
      InicializarMarcoHistoricoZero();
   if(g_historicoTicketZero > 0 && deal <= g_historicoTicketZero)
      return false;
   if(g_historicoTicketZero == 0 && g_historicoMarcoZero > 0)
   {
      datetime horarioDeal = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(horarioDeal < g_historicoMarcoZero)
         return false;
   }
   return true;
}

bool AplicarMarcoHistoricoZero(datetime &inicio, datetime fim, HistoricoPeriodo &h, string nome)
{
   // V36: o marco da identidade vale para TODOS os periodos. Ele atravessa
   // vencimentos, mas nunca atravessa a criacao de um novo par de Magics.
   if(g_historicoMarcoZero <= 0)
      InicializarMarcoHistoricoZero();
   if(fim < g_historicoMarcoZero)
   {
      ZerarHistoricoPeriodo(h, nome);
      DefinirJanelaHistorico(h, inicio, fim, false);
      return false;
   }
   if(inicio < g_historicoMarcoZero)
      inicio = g_historicoMarcoZero;
   return true;
}

// ============================================================================
// FIX311 - VIRADA CIVIL, HISTORICO UNICO E SELETOR DE ENTRADA FAVOR/CONTRA
// O ciclo operacional continua intacto. Somente a fotografia do DIA usa um
// baseline do financeiro aberto para nascer em R$0,00 na troca de data.
// ============================================================================

// ============================================================================
// RESPONSABILIDADE: CONTROLE FINANCEIRO DIARIO
// ============================================================================

string ChaveControleDiaFIX310(string sufixo)
{
   if(!g_identidadeInicializadaFIX304)
      InicializarIdentidadeUnicaFIX304();
   string bruto=StringFormat("%I64d|%s|%s|%d|%d|%s",
                             AccountInfoInteger(ACCOUNT_LOGIN),AccountInfoString(ACCOUNT_SERVER),_Symbol,
                             (int)MagicCompraAtual(),(int)MagicVendaAtual(),g_identidadeGeracaoFIX304);
   return "A311_"+Base36FIX304(HashTextoFIX304(bruto),8)+"_"+sufixo;
}

string ChaveControleDiaLegadaFIX311(string sufixo)
{
   string simbolo=_Symbol;
   StringReplace(simbolo,".",""); StringReplace(simbolo,"#",""); StringReplace(simbolo,"-","");
   if(StringLen(simbolo)>10) simbolo=StringSubstr(simbolo,0,10);
   string chave=StringFormat("A310_%I64d_%s_%d_%d_%s",AccountInfoInteger(ACCOUNT_LOGIN),simbolo,
                             (int)MagicCompraAtual(),(int)MagicVendaAtual(),sufixo);
   if(StringLen(chave)>63) chave=StringSubstr(chave,0,63);
   return chave;
}

double AbertoAtualLadoFIX310(ENUM_LADO_ROBO lado)
{
   double qtd=0.0,aberto=0.0;
   long magic=(lado==LADO_VENDA ? MagicPainelBAtual() : MagicPainelAAtual());
   CalcularAbertoContratosPorMagicDireto(magic,qtd,aberto);
   if(qtd<=0.0001)
      return 0.0;
   return NormalizeDouble(aberto,2);
}

void SalvarControleDiaFIX310(bool forcar)
{
   datetime agora=AgoraServidorHistorico();
   if(!forcar && g_ultimaPersistenciaDiaFIX310>0 && (agora-g_ultimaPersistenciaDiaFIX310)<30)
      return;
   if(!MathIsValidNumber(g_abertoBaseDiaCompraFIX310) || !MathIsValidNumber(g_abertoBaseDiaVendaFIX310) ||
      !MathIsValidNumber(g_saldoOntemCompraFIX310) || !MathIsValidNumber(g_saldoOntemVendaFIX310) ||
      !MathIsValidNumber(g_ultimoAbertoCompraFIX310) || !MathIsValidNumber(g_ultimoAbertoVendaFIX310))
   {
      Print("[COPA_AR100][V36][CHECKPOINT_REJEITADO] controle diario contem valor financeiro invalido.");
      return;
   }
   // V=0 marca transacao em andamento; V>0 somente depois de todos os campos.
   GlobalVariableSet(ChaveControleDiaFIX310("V"),0.0);
   GlobalVariableSet(ChaveControleDiaFIX310("D"),(double)g_diaFinanceiroRefFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("BC"),g_abertoBaseDiaCompraFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("BV"),g_abertoBaseDiaVendaFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("OC"),g_saldoOntemCompraFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("OV"),g_saldoOntemVendaFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("UC"),g_ultimoAbertoCompraFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("UV"),g_ultimoAbertoVendaFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("UH"),(double)g_ultimaFotoAbertoFIX310);
   GlobalVariableSet(ChaveControleDiaFIX310("V"),(double)agora);
   if(forcar) GlobalVariablesFlush();
   g_ultimaPersistenciaDiaFIX310=agora;
}

void InicializarControleDiaFIX310()
{
   if(g_controleDiaProntoFIX310) return;
   datetime agora=AgoraServidorHistorico();
   datetime hoje=InicioDoDia(agora);
   bool usarLegado=false;
   string chaveDia=ChaveControleDiaFIX310("D");
   if(!GlobalVariableCheck(chaveDia) && GlobalVariableCheck(ChaveControleDiaLegadaFIX311("D")))
      usarLegado=true;
   string chaveD=usarLegado ? ChaveControleDiaLegadaFIX311("D") : chaveDia;
   bool carregou=GlobalVariableCheck(chaveD);
   string chaveVersao=ChaveControleDiaFIX310("V");
   if(!usarLegado && GlobalVariableCheck(chaveVersao) && GlobalVariableGet(chaveVersao)<=0.0)
      carregou=false; // checkpoint interrompido: reconstruir em vez de usar dados parciais
   if(carregou)
   {
      g_diaFinanceiroRefFIX310=(datetime)GlobalVariableGet(chaveD);
      string kBC=usarLegado?ChaveControleDiaLegadaFIX311("BC"):ChaveControleDiaFIX310("BC");
      string kBV=usarLegado?ChaveControleDiaLegadaFIX311("BV"):ChaveControleDiaFIX310("BV");
      string kOC=usarLegado?ChaveControleDiaLegadaFIX311("OC"):ChaveControleDiaFIX310("OC");
      string kOV=usarLegado?ChaveControleDiaLegadaFIX311("OV"):ChaveControleDiaFIX310("OV");
      string kUC=usarLegado?ChaveControleDiaLegadaFIX311("UC"):ChaveControleDiaFIX310("UC");
      string kUV=usarLegado?ChaveControleDiaLegadaFIX311("UV"):ChaveControleDiaFIX310("UV");
      string kUH=usarLegado?ChaveControleDiaLegadaFIX311("UH"):ChaveControleDiaFIX310("UH");
      if(GlobalVariableCheck(kBC)) g_abertoBaseDiaCompraFIX310=GlobalVariableGet(kBC);
      if(GlobalVariableCheck(kBV)) g_abertoBaseDiaVendaFIX310=GlobalVariableGet(kBV);
      if(GlobalVariableCheck(kOC)) g_saldoOntemCompraFIX310=GlobalVariableGet(kOC);
      if(GlobalVariableCheck(kOV)) g_saldoOntemVendaFIX310=GlobalVariableGet(kOV);
      if(GlobalVariableCheck(kUC)) g_ultimoAbertoCompraFIX310=GlobalVariableGet(kUC);
      if(GlobalVariableCheck(kUV)) g_ultimoAbertoVendaFIX310=GlobalVariableGet(kUV);
      if(GlobalVariableCheck(kUH)) g_ultimaFotoAbertoFIX310=(datetime)GlobalVariableGet(kUH);
      if(!MathIsValidNumber(g_abertoBaseDiaCompraFIX310) || !MathIsValidNumber(g_abertoBaseDiaVendaFIX310) ||
         !MathIsValidNumber(g_saldoOntemCompraFIX310) || !MathIsValidNumber(g_saldoOntemVendaFIX310) ||
         !MathIsValidNumber(g_ultimoAbertoCompraFIX310) || !MathIsValidNumber(g_ultimoAbertoVendaFIX310))
      {
         g_abertoBaseDiaCompraFIX310=AbertoAtualLadoFIX310(LADO_COMPRA);
         g_abertoBaseDiaVendaFIX310=AbertoAtualLadoFIX310(LADO_VENDA);
         g_saldoOntemCompraFIX310=0.0;
         g_saldoOntemVendaFIX310=0.0;
         g_ultimoAbertoCompraFIX310=g_abertoBaseDiaCompraFIX310;
         g_ultimoAbertoVendaFIX310=g_abertoBaseDiaVendaFIX310;
         g_ultimaFotoAbertoFIX310=agora;
         Print("[COPA_AR100][V36][CHECKPOINT_INVALIDO] valores diarios reconstruidos com seguranca.");
      }
   }
   else
   {
      g_diaFinanceiroRefFIX310=hoje;
      g_abertoBaseDiaCompraFIX310=AbertoAtualLadoFIX310(LADO_COMPRA);
      g_abertoBaseDiaVendaFIX310=AbertoAtualLadoFIX310(LADO_VENDA);
      g_ultimoAbertoCompraFIX310=g_abertoBaseDiaCompraFIX310;
      g_ultimoAbertoVendaFIX310=g_abertoBaseDiaVendaFIX310;
      g_ultimaFotoAbertoFIX310=agora;
      HistoricoPeriodo hOntemInicial;
      datetime inicioOntem=InicioOntemCivilFIX311(agora);
      CalcularHistoricoPeriodoHeadGrupo(inicioOntem,hoje-1,hOntemInicial,"ONTEM",false);
      // Sem fotografia antiga, o fallback seguro e o realizado oficial do dia civil anterior.
      g_saldoOntemCompraFIX310=hOntemInicial.financeiroCompra;
      g_saldoOntemVendaFIX310=hOntemInicial.financeiroVenda;
   }
   // Revalida ONTEM com o motor financeiro seguro. Mantemos a fotografia antiga
   // quando ela é plausível (pode conter variação de posição atravessada). Valores
   // fora de escala são substituídos pelo realizado oficial reconstruído.
   HistoricoPeriodo hOntemSeguroFIX313;
   datetime inicioOntemSeguroFIX313=InicioOntemCivilFIX311(agora);
   CalcularHistoricoPeriodoHeadGrupo(inicioOntemSeguroFIX313,hoje-1,hOntemSeguroFIX313,"ONTEM",false);
   double limiteOntemC=MathMax(5000.0,MathAbs(hOntemSeguroFIX313.financeiroCompra)*20.0+500.0);
   double limiteOntemV=MathMax(5000.0,MathAbs(hOntemSeguroFIX313.financeiroVenda)*20.0+500.0);
   if(!MathIsValidNumber(g_saldoOntemCompraFIX310) || MathAbs(g_saldoOntemCompraFIX310)>limiteOntemC)
      g_saldoOntemCompraFIX310=hOntemSeguroFIX313.financeiroCompra;
   if(!MathIsValidNumber(g_saldoOntemVendaFIX310) || MathAbs(g_saldoOntemVendaFIX310)>limiteOntemV)
      g_saldoOntemVendaFIX310=hOntemSeguroFIX313.financeiroVenda;

   g_controleDiaProntoFIX310=true;
   if(g_diaFinanceiroRefFIX310<=0) g_diaFinanceiroRefFIX310=hoje;
   if(g_diaFinanceiroRefFIX310!=hoje)
      ProcessarViradaFinanceiraFIX310(agora,true);
   else
   {
      g_statusViradaDiaFIX310="OK "+TimeToString(hoje,TIME_DATE);
      SalvarControleDiaFIX310(true); // tambem migra automaticamente a chave A310 para A311.
   }
}

void ProcessarViradaFinanceiraFIX310(datetime agora, bool forcar)
{
   if(!g_controleDiaProntoFIX310)
   {
      g_controleDiaProntoFIX310=true;
      if(g_diaFinanceiroRefFIX310<=0)
         g_diaFinanceiroRefFIX310=InicioDoDia(agora);
   }
   datetime hoje=InicioDoDia(agora);
   if(!forcar && g_diaFinanceiroRefFIX310==hoje)
      return;

   datetime inicioOntem=hoje-86400;
   HistoricoPeriodo histOntemFIX310;
   CalcularHistoricoPeriodoHeadGrupo(inicioOntem,hoje-1,histOntemFIX310,"ONTEM",false);

   double abertoFechamentoC=g_ultimoAbertoCompraFIX310;
   double abertoFechamentoV=g_ultimoAbertoVendaFIX310;
   if(g_ultimaFotoAbertoFIX310<=0 || InicioDoDia(g_ultimaFotoAbertoFIX310)!=g_diaFinanceiroRefFIX310)
   {
      abertoFechamentoC=AbertoAtualLadoFIX310(LADO_COMPRA);
      abertoFechamentoV=AbertoAtualLadoFIX310(LADO_VENDA);
   }

   bool viradaSequencial=(g_diaFinanceiroRefFIX310==inicioOntem);
   if(viradaSequencial)
   {
      g_saldoOntemCompraFIX310=histOntemFIX310.financeiroCompra + (abertoFechamentoC-g_abertoBaseDiaCompraFIX310);
      g_saldoOntemVendaFIX310=histOntemFIX310.financeiroVenda + (abertoFechamentoV-g_abertoBaseDiaVendaFIX310);
   }
   else
   {
      // Se o EA ficou desligado por mais de um dia, ONTEM usa o realizado oficial.
      g_saldoOntemCompraFIX310=histOntemFIX310.financeiroCompra;
      g_saldoOntemVendaFIX310=histOntemFIX310.financeiroVenda;
   }

   g_diaFinanceiroRefFIX310=hoje;
   g_abertoBaseDiaCompraFIX310=AbertoAtualLadoFIX310(LADO_COMPRA);
   g_abertoBaseDiaVendaFIX310=AbertoAtualLadoFIX310(LADO_VENDA);
   g_ultimoAbertoCompraFIX310=g_abertoBaseDiaCompraFIX310;
   g_ultimoAbertoVendaFIX310=g_abertoBaseDiaVendaFIX310;
   g_ultimaFotoAbertoFIX310=agora;
   g_statusViradaDiaFIX310=StringFormat("OK %s | HOJE C %s V %s | ONTEM C %s V %s",
                                        TimeToString(hoje,TIME_DATE),
                                        PnlMoedaBRL(0.0),PnlMoedaBRL(0.0),
                                        PnlMoedaBRL(g_saldoOntemCompraFIX310),PnlMoedaBRL(g_saldoOntemVendaFIX310));
   SalvarControleDiaFIX310(true);
   RegistrarLogValidacaoSistema("FIX310_VIRADA_DIA",
      StringFormat("Data anterior encerrada e HOJE zerado sem reset operacional | ref=%s | base aberto C=%s V=%s | ontem C=%s V=%s",
                   TimeToString(hoje,TIME_DATE|TIME_SECONDS),
                   PnlMoedaBRL(g_abertoBaseDiaCompraFIX310),PnlMoedaBRL(g_abertoBaseDiaVendaFIX310),
                   PnlMoedaBRL(g_saldoOntemCompraFIX310),PnlMoedaBRL(g_saldoOntemVendaFIX310)));
}


// ============================================================================
// RESPONSABILIDADE: AUDITORIAS DE HISTORICO E VIRADA
// ============================================================================

bool QuaseIgualFIX311(double a,double b)
{
   return (MathAbs(a-b)<=0.02);
}

int ContarPosicoesMesmoMagicSemIdentidadeFIX311()
{
   int qtd=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(!MagicPertencePainelTotalAB(magic)) continue;
      if(!ComentarioTemIdentidadeAtualFIX304(PositionGetString(POSITION_COMMENT),magic)) qtd++;
   }
   return qtd;
}


int ContarPosicoesLadoMagicIncorretoFIX311()
{
   int qtd=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(!MagicPertencePainelTotalAB(magic)) continue;
      if(!ComentarioTemIdentidadeAtualFIX304(PositionGetString(POSITION_COMMENT),magic)) continue;
      long tipo=(long)PositionGetInteger(POSITION_TYPE);
      if(magic==MagicPainelAAtual() && tipo!=POSITION_TYPE_BUY) qtd++;
      if(magic==MagicPainelBAtual() && tipo!=POSITION_TYPE_SELL) qtd++;
   }
   return qtd;
}

void AuditCheckHistFIX311(bool ok,string nome,int &passou,int &falhou,string &falhas)
{
   if(ok) passou++;
   else
   {
      falhou++;
      if(falhas!="") falhas+=" | ";
      falhas+=nome;
   }
}

void AuditoriaHistoricoMagicFIX311(bool forcar)
{
   datetime agora=AgoraServidorHistorico();
   if(!forcar && g_ultimaAuditoriaHistMagicFIX311>0 && (agora-g_ultimaAuditoriaHistMagicFIX311)<60) return;
   g_ultimaAuditoriaHistMagicFIX311=agora;
   int passou=0,falhou=0; string falhas="";
   datetime hoje=InicioDoDia(agora),ontem=InicioOntemCivilFIX311(agora);
   AuditCheckHistFIX311(MagicCompraAtual()>0,"01_MAGIC_A_VALIDO",passou,falhou,falhas);
   AuditCheckHistFIX311(MagicVendaAtual()>0,"02_MAGIC_B_VALIDO",passou,falhou,falhas);
   AuditCheckHistFIX311(MagicCompraAtual()!=MagicVendaAtual(),"03_MAGICS_DIFERENTES",passou,falhou,falhas);
   AuditCheckHistFIX311(g_identidadeInicializadaFIX304,"04_IDENTIDADE_INICIALIZADA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_identidadeGeracaoFIX304!="","05_IDENTIDADE_ESTAVEL",passou,falhou,falhas);
   AuditCheckHistFIX311(AccountInfoString(ACCOUNT_SERVER)!="","06_SERVIDOR_NA_CHAVE",passou,falhou,falhas);
   AuditCheckHistFIX311(g_diaFinanceiroRefFIX310==hoje,"07_DATA_FINANCEIRA_HOJE",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histDia.periodoId==HIST_PAINEL_DIA,"08_CACHE_DIA_TIPO",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histDia.chaveDiaServidor==(long)hoje,"09_CACHE_DIA_DATA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histDia.janelaInicio==0 || g_histDia.janelaInicio==hoje || g_histDia.janelaInicio==g_historicoMarcoZero,"10_JANELA_HOJE",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histOntem.periodoId==HIST_PAINEL_ONTEM,"11_CACHE_ONTEM_TIPO",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histOntem.janelaInicio==0 || g_histOntem.janelaInicio==ontem || g_histOntem.janelaInicio==g_historicoMarcoZero,"12_ONTEM_CIVIL",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist7Dias.periodoId==HIST_PAINEL_7D,"13_CACHE_7D",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist15Dias.periodoId==HIST_PAINEL_15D,"14_CACHE_15D",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist30Dias.periodoId==HIST_PAINEL_30D,"15_CACHE_30D",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histTudo.periodoId==HIST_PAINEL_TUDO,"16_CACHE_TUDO",passou,falhou,falhas);
   HistoricoPeriodo arr[6]; arr[0]=g_histDia; arr[1]=g_histOntem; arr[2]=g_hist7Dias; arr[3]=g_hist15Dias; arr[4]=g_hist30Dias; arr[5]=g_histTudo;
   for(int i=0;i<6;i++)
   {
      string n=IntegerToString(i+17)+"_SOMA_"+arr[i].nome;
      AuditCheckHistFIX311(QuaseIgualFIX311(arr[i].financeiro,arr[i].financeiroCompra+arr[i].financeiroVenda),n,passou,falhou,falhas);
      string q=IntegerToString(i+23)+"_QTD_"+arr[i].nome;
      AuditCheckHistFIX311(QuaseIgualFIX311(arr[i].qtdTotal,arr[i].qtdCompra+arr[i].qtdVenda),q,passou,falhou,falhas);
   }
   AuditCheckHistFIX311(!InpHistoricoSomenteSessaoAtual,"29_HISTORICO_NAO_LIMITADO_SESSAO",passou,falhou,falhas);
   AuditCheckHistFIX311(InpHistoricoPeriodosPreservarAoRecolocar,"30_PRESERVA_REINICIO",passou,falhou,falhas);
   AuditCheckHistFIX311(ContarPosicoesMesmoMagicSemIdentidadeFIX311()==0 || InpAceitarPosicaoSemIDInstancia,
                        "31_SEM_POSICAO_OUTRO_ROBO_MESMO_MAGIC",passou,falhou,falhas);
   AuditCheckHistFIX311(MathIsValidNumber(SaldoHojeLadoFIX310(LADO_COMPRA)+SaldoHojeLadoFIX310(LADO_VENDA)),
                        "32_SALDO_HOJE_VALIDO",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist7Dias.janelaInicio==InicioDiasAtras(7),
                        "33_JANELA_7D_EXATA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist15Dias.janelaInicio==InicioDiasAtras(15),
                        "34_JANELA_15D_EXATA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_hist30Dias.janelaInicio==InicioDiasAtras(30),
                        "35_JANELA_30D_EXATA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histTudo.janelaInicio==0,
                        "36_JANELA_TUDO_EXATA",passou,falhou,falhas);
   AuditCheckHistFIX311(g_histOntem.janelaFim==hoje-1 || g_histOntem.calculadoEm==0,
                        "37_FIM_ONTEM_235959",passou,falhou,falhas);
   AuditCheckHistFIX311(ContarPosicoesLadoMagicIncorretoFIX311()==0,
                        "38_A_COMPRA_B_VENDA",passou,falhou,falhas);
   int corrigidosFinanceiro=0,semBaseFinanceiro=0;
   double somaBrutaFinanceiro=0.0,somaSeguraFinanceiro=0.0;
   bool unidadeOk=AuditarUnidadeFinanceiraHojeFIX313(corrigidosFinanceiro,semBaseFinanceiro,somaBrutaFinanceiro,somaSeguraFinanceiro);
   g_financeiroHistoricoValidoFIX314=unidadeOk;
   AuditCheckHistFIX311(unidadeOk,"39_UNIDADE_FINANCEIRA_VALIDA",passou,falhou,falhas);
   int saidasRecentes=ContarSaidasRecentesFIX313(InpJanelaProtecaoRepeticaoSegundosFIX313);
   AuditCheckHistFIX311(saidasRecentes<InpMaxSaidasEmCincoMinutosFIX313,"40_SEM_REPETICAO_ANORMAL",passou,falhou,falhas);
   AuditCheckHistFIX311(QuaseIgualFIX311(g_histDia.financeiro,somaSeguraFinanceiro),
                        "41_PAINEL_IGUAL_RECALCULO_SEGURO",passou,falhou,falhas);
   AuditCheckHistFIX311(!InpFIX279EntradaDiretaDemo && !InpFIX293TesteDX2ZeroAmbosLados && InpExecutarSomenteNovoCandleEntrada,
                        "42_ENTRADA_SEM_BYPASS",passou,falhou,falhas);
   AuditCheckHistFIX311(InpPausaReentradaSegundos>=0,
                        "43_PAUSA_REENTRADA_SEGURA",passou,falhou,falhas);
   g_statusFinanceiroFIX313=StringFormat("SEGURO %s | ultimo fator %.8f | corrigidos %d | sem base %d | bruto %.2f | usado %.2f | saidas5m %d",
                                         unidadeOk?"OK":"FALHA",g_fatorFinanceiroServidorFIX313,corrigidosFinanceiro,semBaseFinanceiro,
                                         somaBrutaFinanceiro,somaSeguraFinanceiro,saidasRecentes);
   // V36: inventario explicito para provar, no Experts, quantos deals foram
   // aceitos pelo par atual e quantos foram rejeitados como outro Magic.
   int dealsAceitosV36=0,dealsOutroMagicV36=0;
   double financeiroAceitoV36=0.0;
   if(HistorySelect(g_historicoMarcoZero,agora+86400))
   {
      for(int dV36=0;dV36<HistoryDealsTotal();dV36++)
      {
         ulong dealV36=HistoryDealGetTicket(dV36);
         if(dealV36==0 || !DealEhDepoisDoMarcoHistoricoZero(dealV36)) continue;
         if(!SimboloAceitoHistoricoFIX347(HistoryDealGetString(dealV36,DEAL_SYMBOL))) continue;
         long tipoV36=HistoryDealGetInteger(dealV36,DEAL_TYPE);
         if(tipoV36!=DEAL_TYPE_BUY && tipoV36!=DEAL_TYPE_SELL) continue;
         long magicV36=(long)HistoryDealGetInteger(dealV36,DEAL_MAGIC);
         if(MagicPertenceHistoricoFinanceiroFIX458(magicV36))
         {
            dealsAceitosV36++;
            financeiroAceitoV36+=ResultadoDealHistorico(dealV36);
         }
         else
            dealsOutroMagicV36++;
      }
   }
   if(forcar)
      PrintFormat("[COPA_AR100][V36][AUDITORIA_MAGIC] conta=%I64d | servidor=%s | simbolo=%s | A=%d | B=%d | id=%s | marco=%s | aceitos=%d | rejeitados_outro_magic=%d | financeiro_aceito=%.2f",
                  AccountInfoInteger(ACCOUNT_LOGIN),AccountInfoString(ACCOUNT_SERVER),_Symbol,
                  (int)MagicCompraAtual(),(int)MagicVendaAtual(),g_identidadeGeracaoFIX304,
                  TimeToString(g_historicoMarcoZero,TIME_DATE|TIME_SECONDS),
                  dealsAceitosV36,dealsOutroMagicV36,NormalizeDouble(financeiroAceitoV36,2));
   string novo=StringFormat("%s %d/%d",falhou==0?"APROVADO":"FALHOU",passou,passou+falhou);
   bool mudou=(novo!=g_auditoriaHistStatusFIX311 || falhas!=g_auditoriaHistFalhasFIX311);
   g_auditoriaHistPassFIX311=passou;
   g_auditoriaHistFailFIX311=falhou;
   g_auditoriaHistFalhasFIX311=falhas;
   g_auditoriaHistStatusFIX311=novo;
   if(falhou>0)
      RegistrarLogValidacaoSistema("FIX311_AUDIT_HIST_MAGIC_FAIL",novo+" | "+falhas+" | "+g_statusFinanceiroFIX313);
   else if(forcar || mudou)
      RegistrarLogValidacaoSistema("FIX311_AUDIT_HIST_MAGIC_OK",novo+" | HOJE/ONTEM/7D/15D/30D/TUDO consistentes | "+g_statusFinanceiroFIX313);
}

void AuditoriaViradaDiaFIX310(datetime agora)
{
   if(agora<=0)
      agora=AgoraServidorHistorico();
   if(!g_controleDiaProntoFIX310)
      InicializarControleDiaFIX310();
   datetime hoje=InicioDoDia(agora);
   if(g_diaFinanceiroRefFIX310!=hoje)
   {
      RegistrarLogValidacaoSistema("FIX310_AUDIT_DATA_DIVERGENTE",
         StringFormat("Auditoria encontrou ref=%s e servidor=%s; correcao automatica aplicada.",
                      TimeToString(g_diaFinanceiroRefFIX310,TIME_DATE|TIME_SECONDS),
                      TimeToString(hoje,TIME_DATE|TIME_SECONDS)));
      ProcessarViradaFinanceiraFIX310(agora,true);
   }

   // Impede cache DIA antigo de sobreviver a troca de data.
   if(g_histDia.calculadoEm>0 && g_histDia.chaveDiaServidor!=(long)hoje)
   {
      ZerarHistoricoPeriodo(g_histDia,"DIA");
      DefinirJanelaHistorico(g_histDia,hoje,agora,false);
      g_ultimaAtualizacaoHistorico=0;
      RegistrarLogValidacaoSistema("FIX310_AUDIT_CACHE_DIA_CORRIGIDO","Cache do DIA pertencia a outra data e foi zerado.");
   }

   g_ultimoAbertoCompraFIX310=AbertoAtualLadoFIX310(LADO_COMPRA);
   g_ultimoAbertoVendaFIX310=AbertoAtualLadoFIX310(LADO_VENDA);
   g_ultimaFotoAbertoFIX310=agora;
   g_statusViradaDiaFIX310="OK "+TimeToString(hoje,TIME_DATE);
   SalvarControleDiaFIX310(false);
}


// ============================================================================
// RESPONSABILIDADE: SALDOS MODOS E ATUALIZACAO DO HISTORICO
// ============================================================================

double RealizadoHojeLadoFIX310(ENUM_LADO_ROBO lado)
{
   return (lado==LADO_VENDA ? g_histDia.financeiroVenda : g_histDia.financeiroCompra);
}

double VariacaoAbertaHojeLadoFIX310(ENUM_LADO_ROBO lado)
{
   double atual=AbertoAtualLadoFIX310(lado);
   double base=(lado==LADO_VENDA ? g_abertoBaseDiaVendaFIX310 : g_abertoBaseDiaCompraFIX310);
   return NormalizeDouble(atual-base,2);
}

double SaldoHojeLadoFIX310(ENUM_LADO_ROBO lado)
{
   return NormalizeDouble(RealizadoHojeLadoFIX310(lado)+VariacaoAbertaHojeLadoFIX310(lado),2);
}


bool ExisteSinalContraValidoFIX310(ENUM_LADO_ROBO lado, string &detalhe)
{
   string ladoNome=(lado==LADO_COMPRA ? "AZUL_COMPRA_" : "AMARELO_VENDA_");
   string prefixo=PrefixoCandleContraFIX258()+ladoNome;
   const int validadeBarras=3;
   for(int shift=1;shift<=validadeBarras;shift++)
   {
      datetime tempo=iTime(_Symbol,TimeframeFiltroAtualFIX255(),shift);
      if(tempo<=0)
         continue;
      string base=prefixo+IntegerToString((int)tempo);
      if(ObjectFind(0,base+"_CORPO")>=0 || ObjectFind(0,base+"_SETA")>=0)
      {
         detalhe=StringFormat("CONTRA %s confirmado no candle %s (shift %d)",
                              NomeLado(lado),TimeToString(tempo,TIME_MINUTES),shift);
         return true;
      }
   }
   if(g_ultimoSinalContraLadoFIX310==lado && g_ultimoSinalContraHoraFIX310>0)
   {
      int shiftUltimo=iBarShift(_Symbol,TimeframeFiltroAtualFIX255(),g_ultimoSinalContraHoraFIX310,false);
      if(shiftUltimo>=1 && shiftUltimo<=validadeBarras)
      {
         detalhe=StringFormat("CONTRA %s confirmado e ainda valido",NomeLado(lado));
         return true;
      }
   }
   detalhe=StringFormat("Sem candle CONTRA %s valido nas ultimas %d barras",NomeLado(lado),validadeBarras);
   return false;
}

bool PrimeiraOrdemLivreProtegidaFIX314()
{
   return (InpComoAbrirPrimeiraOrdem==PRIMEIRA_ORDEM_LIVRE_PROTEGIDA);
}

bool PrimeiraOrdemDesligadaFIX314()
{
   return (InpComoAbrirPrimeiraOrdem==PRIMEIRA_ORDEM_DESLIGADA);
}

string TextoComoAbrirPrimeiraOrdemFIX314()
{
   if(InpComoAbrirPrimeiraOrdem==PRIMEIRA_ORDEM_DESLIGADA) return "DESLIGADA";
   if(InpComoAbrirPrimeiraOrdem==PRIMEIRA_ORDEM_LIVRE_PROTEGIDA) return "LIVRE PROTEGIDA";
   return "NORMAL COM SINAIS";
}

string TextoModoEntradaHumanoFIX312(ENUM_MODO_ENTRADA_A0_FIX310 modo)
{
   if(modo==A0_FIX310_FAVOR) return "FAVOR";
   if(modo==A0_FIX310_CONTRA) return "CONTRA";
   if(modo==A0_FIX310_FAVOR_E_CONTRA) return "AMBOS";
   return "LIVRE";
}

string TextoModoEntradaA0FIX310()
{
   return StringFormat("%s | C:%s V:%s",
                       TextoComoAbrirPrimeiraOrdemFIX314(),
                       TextoModoEntradaHumanoFIX312(InpModoEntradaCompra),
                       TextoModoEntradaHumanoFIX312(InpModoEntradaVenda));
}

bool ModoEntradaA0PermiteFIX310(EstadoLado &estado, string &motivo)
{
   ENUM_MODO_ENTRADA_A0_FIX310 modo=(estado.lado==LADO_COMPRA ? InpModoEntradaCompra : InpModoEntradaVenda);
   if(modo==A0_FIX310_LIVRE)
   {
      motivo=StringFormat("%s liberada para teste.",NomeLado(estado.lado));
      return true;
   }

   ENUM_LADO_ROBO direcao=DirecaoMedia25Operacional();
   bool favorOk=(direcao==estado.lado);
   string detalheContra="";
   bool contraOk=ExisteSinalContraValidoFIX310(estado.lado,detalheContra);

   if(modo==A0_FIX310_FAVOR)
   {
      motivo=favorOk
             ? StringFormat("%s liberada: acompanha o movimento principal.",NomeLado(estado.lado))
             : StringFormat("%s aguardando: o movimento principal está no outro sentido.",NomeLado(estado.lado));
      return favorOk;
   }
   if(modo==A0_FIX310_CONTRA)
   {
      motivo=contraOk ? StringFormat("%s liberada por sinal de virada.",NomeLado(estado.lado))
                      : StringFormat("%s aguardando sinal confirmado de virada.",NomeLado(estado.lado));
      return contraOk;
   }

   bool ambosOk=(favorOk || contraOk);
   motivo=ambosOk
          ? StringFormat("%s liberada: condição a favor ou contra confirmada.",NomeLado(estado.lado))
          : StringFormat("%s aguardando movimento a favor ou sinal de virada.",NomeLado(estado.lado));
   return ambosOk;
}

void AtualizarHistoricoObrigatorio()
{
   datetime agora=AgoraServidorHistorico();
   AuditoriaViradaDiaFIX310(agora);
   VerificarViradaDiaHistorico(agora);
   int intervaloHistorico=IntervaloHistoricoEfetivo();
   if(g_ultimaAtualizacaoHistorico>0 && (agora-g_ultimaAtualizacaoHistorico)<intervaloHistorico)
      return;
   g_ultimaAtualizacaoHistorico=agora;
   datetime inicioHoje=InicioDoDia(agora);
   datetime inicioOntem=InicioOntemCivilFIX311(agora);
   CalcularHistoricoPeriodo(inicioHoje,agora,g_histDia,"DIA",false);
   AtualizarHistoricoLongoEmRodizio(agora,inicioHoje,inicioOntem,InicioDiasAtras(7),InicioDiasAtras(15),InicioDiasAtras(30),0,0);
   SincronizarResultadoFechadoDiaComHistorico();
   AuditoriaHistoricoMagicFIX311(false);
}

void AtualizarHistoricoLongoEmRodizio(datetime agora,
                                      datetime inicioHoje,
                                      datetime inicioOntem,
                                      datetime inicio7,
                                      datetime inicio15,
                                      datetime inicio30,
                                      datetime inicioTudo,
                                      datetime corteSessao)
{
   if(!g_historicoPrimeiraCargaFeita)
   {
      CalcularHistoricoPeriodo(inicioOntem,inicioHoje-1,g_histOntem,"ONTEM",false);
      CalcularHistoricoPeriodo(inicio7,agora,g_hist7Dias,"7D",false);
      CalcularHistoricoPeriodo(inicio15,agora,g_hist15Dias,"15D",false);
      CalcularHistoricoPeriodo(inicio30,agora,g_hist30Dias,"30D",false);
      CalcularHistoricoPeriodo(inicioTudo,agora,g_histTudo,"TUDO",false);
      g_historicoPrimeiraCargaFeita=true;
      g_ultimaAtualizacaoHistoricoLongo=agora;
      g_historicoPassoLongo=0;
      return;
   }
   if(!InpHistoricoSeguroSemTravamento)
   {
      CalcularHistoricoPeriodo(inicioOntem,inicioHoje-1,g_histOntem,"ONTEM",false);
      CalcularHistoricoPeriodo(inicio7,agora,g_hist7Dias,"7D",false);
      CalcularHistoricoPeriodo(inicio15,agora,g_hist15Dias,"15D",false);
      CalcularHistoricoPeriodo(inicio30,agora,g_hist30Dias,"30D",false);
      CalcularHistoricoPeriodo(inicioTudo,agora,g_histTudo,"TUDO",false);
      return;
   }
   int intervaloLongo=InpHistoricoLongoAtualizarSegundos;
   if(intervaloLongo<5) intervaloLongo=5;
   if(g_ultimaAtualizacaoHistoricoLongo>0 && (agora-g_ultimaAtualizacaoHistoricoLongo)<intervaloLongo)
      return;
   g_ultimaAtualizacaoHistoricoLongo=agora;
   if(g_historicoPassoLongo<0 || g_historicoPassoLongo>4) g_historicoPassoLongo=0;
   if(g_historicoPassoLongo==0) CalcularHistoricoPeriodo(inicioOntem,inicioHoje-1,g_histOntem,"ONTEM",false);
   else if(g_historicoPassoLongo==1) CalcularHistoricoPeriodo(inicio7,agora,g_hist7Dias,"7D",false);
   else if(g_historicoPassoLongo==2) CalcularHistoricoPeriodo(inicio15,agora,g_hist15Dias,"15D",false);
   else if(g_historicoPassoLongo==3) CalcularHistoricoPeriodo(inicio30,agora,g_hist30Dias,"30D",false);
   else CalcularHistoricoPeriodo(inicioTudo,agora,g_histTudo,"TUDO",false);
   g_historicoPassoLongo++;
   if(g_historicoPassoLongo>4) g_historicoPassoLongo=0;
}

void AtualizarHistoricoSelecionadoAgora()
{
   datetime agora=AgoraServidorHistorico();
   datetime inicioHoje=InicioDoDia(agora);
   datetime inicioOntem=InicioOntemCivilFIX311(agora);
   if(g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
      CalcularHistoricoPeriodo(inicioHoje,agora,g_histDia,"DIA",false);
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_ONTEM)
      CalcularHistoricoPeriodo(inicioOntem,inicioHoje-1,g_histOntem,"ONTEM",false);
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_7D)
      CalcularHistoricoPeriodo(InicioDiasAtras(7),agora,g_hist7Dias,"7D",false);
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_15D)
      CalcularHistoricoPeriodo(InicioDiasAtras(15),agora,g_hist15Dias,"15D",false);
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_30D)
      CalcularHistoricoPeriodo(InicioDiasAtras(30),agora,g_hist30Dias,"30D",false);
   else
      CalcularHistoricoPeriodo(0,agora,g_histTudo,"TUDO",false);
   SincronizarResultadoFechadoDiaComHistorico();
   AuditoriaHistoricoMagicFIX311(true);
}

void ForcarAtualizacaoHistoricoPainel(string motivo)
{
   bool periodoCivilCurto = (g_periodoHistoricoAtivo == HIST_PAINEL_DIA ||
                              g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM);
   if(InpHistoricoCliqueRecalcularAgora || periodoCivilCurto)
   {
      g_ultimaAtualizacaoHistorico = 0;
      AtualizarHistoricoSelecionadoAgora();
      g_mestre.mensagemGeral = "Historico atualizado: " + NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo) + " | " + motivo;
   }
   else
   {
      g_mestre.mensagemGeral = "Historico selecionado: " + NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo) + " | clique rapido sem varredura pesada";
   }
   g_ultimoCliqueHistorico = TimeCurrent();
}

void RedesenharAbasHistoricoRapidas(string pfx, int tx, int ty, int fonte)
{
   PnlAba(pfx + "_ABA_HOJE",  "hoje>",  tx, ty,       g_periodoHistoricoAtivo == HIST_PAINEL_DIA,   fonte);
   PnlAba(pfx + "_ABA_ONTEM", "ontem",  tx, ty + 30,  g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM, fonte);
   PnlAba(pfx + "_ABA_7D",    "7 dias", tx, ty + 60,  g_periodoHistoricoAtivo == HIST_PAINEL_7D,    fonte);
   PnlAba(pfx + "_ABA_15D",   "15 dias",tx, ty + 90,  g_periodoHistoricoAtivo == HIST_PAINEL_15D,   fonte);
   PnlAba(pfx + "_ABA_30D",   "30 dias",tx, ty + 120, g_periodoHistoricoAtivo == HIST_PAINEL_30D,   fonte);
   PnlAba(pfx + "_ABA_TUDO",  "tudo",   tx, ty + 150, g_periodoHistoricoAtivo == HIST_PAINEL_TUDO,  fonte);
   PnlAba(pfx + "_ABA_CSV",   "AUDIT", tx, ty + 180, g_aud302TelaAtiva, fonte);
}

void AtualizarVisualHistoricoRapido()
{
   if(g_modoPainelVisualAtivo != PAINEL_VISUAL_COMPLETO)
   {
      g_ultimaAtualizacaoPainelVisual = 0;
      return;
   }
   int px = InpPainelCardX;
   int py = InpPainelCardY;
   int pw = InpPainelCardLargura;
   int ph = InpPainelCardAltura;
   PainelPrepararCompletoAutoFitFIX319(px, py, pw, ph);
   int fonteTexto = InpPainelFonteTexto;
   if(fonteTexto < 7) fonteTexto = 7;
   if(fonteTexto > 8) fonteTexto = 8;
   if(pw < 1280 || ph < 900)
      fonteTexto = 7;
   int gap = (ph < 900 ? 8 : 10);
   int finY = py + (ph < 900 ? 84 : 92);
   int finH = (ph < 820 ? 300 : (ph < 900 ? 324 : 348));
   int aumH = (ph < 820 ? 202 : (ph < 1000 ? 210 : 218));
   int indH = (ph < 820 ? 64 : (ph < 1000 ? 74 : 96));
   int minHistH = (ph < 820 ? 76 : 82);
   int histYPrev = finY + finH + gap + aumH + gap + indH + gap;
   int histHPrev = (py + ph - 8) - histYPrev;
   if(histHPrev < minHistH)
   {
      int falta = minHistH - histHPrev;
      int red = 0;
      red = (int)MathMin((double)falta, (double)MathMax(0, finH - (ph < 820 ? 280 : 300)));
      finH -= red; falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, aumH - 202));
      aumH -= red; falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, indH - 56));
      indH -= red; falta -= red;
      if(falta > 0 && gap > 6)
      {
         int reduzirGap = (int)MathMin((double)(gap - 6), (double)((falta + 3) / 3));
         gap -= reduzirGap;
      }
   }
   int boxW = (pw - 36 - gap) / 2;
   int bx1 = px + 12;
   int bx2 = bx1 + boxW + gap;
   int ty = finY + 76;
   RedesenharAbasHistoricoRapidas("COPA_AR100_CARD_FIN_A", bx1 + 10, ty, fonteTexto);
   RedesenharAbasHistoricoRapidas("COPA_AR100_CARD_FIN_T", bx2 + 10, ty, fonteTexto);
   int aumY = finY + finH + gap;
   int indY = aumY + aumH + gap;
   int histY = indY + indH + gap;
   int histH = (py + ph - 8) - histY;
   if(histH < 76) histH = 76;
   DesenharCardHistorico(px + 12, histY, pw - 24, histH);
   PainelChartRedrawLeve(true);
}



// RESPONSABILIDADE: CLIQUES DAS ABAS DE HISTORICO

bool PainelCliqueHistorico(string objeto)
{
   if(StringFind(objeto, "COPA_AR100_CARD_") != 0)
      return false;
   if(StringFind(objeto, "_ABA_HOJE") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_DIA;
      return true;
   }
   if(StringFind(objeto, "_ABA_ONTEM") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_ONTEM;
      return true;
   }
   if(StringFind(objeto, "_ABA_7D") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_7D;
      return true;
   }
   if(StringFind(objeto, "_ABA_15D") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_15D;
      return true;
   }
   if(StringFind(objeto, "_ABA_30D") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_30D;
      return true;
   }
   if(StringFind(objeto, "_ABA_TUDO") >= 0)
   {
      g_periodoHistoricoAtivo = HIST_PAINEL_TUDO;
      return true;
   }
   if(StringFind(objeto, "_ABA_CSV") >= 0)
   {
      g_mestre.mensagemGeral = "AUDITORIA FIX302: use o botao AUDIT para abrir ou fechar a tela.";
      return true;
   }
   return false;
}


void ObterHistoricoSelecionado(HistoricoPeriodo &h)
{
   if(g_periodoHistoricoAtivo==HIST_PAINEL_DIA) h=g_histDia;
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_ONTEM) h=g_histOntem;
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_7D) h=g_hist7Dias;
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_15D) h=g_hist15Dias;
   else if(g_periodoHistoricoAtivo==HIST_PAINEL_30D) h=g_hist30Dias;
   else h=g_histTudo;
   if(!HistoricoPeriodoCompativel(h,g_periodoHistoricoAtivo))
   {
      string nome="DIA";
      if(g_periodoHistoricoAtivo==HIST_PAINEL_ONTEM) nome="ONTEM";
      else if(g_periodoHistoricoAtivo==HIST_PAINEL_7D) nome="7D";
      else if(g_periodoHistoricoAtivo==HIST_PAINEL_15D) nome="15D";
      else if(g_periodoHistoricoAtivo==HIST_PAINEL_30D) nome="30D";
      else if(g_periodoHistoricoAtivo==HIST_PAINEL_TUDO) nome="TUDO";
      ZerarHistoricoPeriodo(h,nome);
   }
   // FIX316: evita C/V/QTD zerados enquanto há posição aberta real.
   AplicarFallbackEntradasAbertasHistoricoFIX316(h);
}

void MarcarInicioCicloOperacional(EstadoLado &estado)
{
   datetime inicio = TimeCurrent() - 5;
   if(inicio < g_horarioInicioRobo)
      inicio = g_horarioInicioRobo;
   if(estado.lado == LADO_COMPRA)
      g_cicloInicioCompra = inicio;
   else if(estado.lado == LADO_VENDA)
      g_cicloInicioVenda = inicio;
   g_ultimaAtualizacaoHistorico = 0;
}



void CalcularHistoricoPeriodoCoreFIX311(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto, long magicFiltro)
{
   if(!AplicarMarcoHistoricoZero(inicio,fim,h,nome)) return;
   ZerarHistoricoPeriodo(h,nome);
   DefinirJanelaHistorico(h,inicio,fim,incluirAberto);
   // A entrada que originou uma saída pode estar antes do marco visual do painel.
   // Selecionamos o histórico completo e depois aplicamos os filtros de data/Magic no loop.
   datetime inicioSelecao=0;
   if(fim<inicio || !HistorySelect(inicioSelecao,fim)) return;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) continue;
      if(!DealEhDepoisDoMarcoHistoricoZero(deal)) continue;
      if(!SimboloAceitoHistoricoFIX347(HistoryDealGetString(deal,DEAL_SYMBOL))) continue;
      long magicDeal=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
      if(magicFiltro>0)
      {
         if(magicDeal!=magicFiltro) continue;
      }
      else if(!MagicPertenceHistoricoFinanceiroFIX458(magicDeal)) continue;
      if(!DealPertenceHistoricoPainelFIX316(deal)) continue;
      datetime dealTime=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(dealTime<inicio || dealTime>fim) continue;
      long type=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
      bool ehEntrada=(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT);
      bool ehSaida=DealEhSaidaParcial(entry);
      if(InpHistoricoSomenteDealsSaida && !ehSaida) continue;
      bool ehParcialReal=(ehSaida && DealEhParcialHistoricaReal(deal));
      double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
      double resultado=ResultadoDealHistorico(deal);
      // FIX311: o lado do painel e definido pelo Magic fixo. Assim A+B e sempre exatamente A + B.
      bool ladoCompra=MagicHistoricoCompraFIX458(magicDeal);
      if(ladoCompra)
      {
         // FIX386: quantidade representa contratos realmente ENTRADOS.
         // Deals de saida/parcial nao podem aumentar novamente a quantidade.
         if(ehEntrada)
         {
            h.compras++;
            h.qtdCompra+=volume;
         }
         h.financeiroCompra+=resultado;
         if(resultado>=0.0) h.financeiroLucroCompra+=resultado; else h.financeiroPrejuCompra+=resultado;
         if(ehSaida)
         {
            if(ehParcialReal)
            {
               h.parcialCompra+=resultado;
               if(resultado>=0.0)
               {
                  h.parciaisLucroQtdCompra++;
                  h.financeiroParcialLucroCompra+=resultado;
               }
               else
               {
                  h.parciaisPrejuQtdCompra++;
                  h.financeiroParcialPrejuCompra+=resultado;
               }
            }
            if(resultado>=0.0) h.tradesLucroCompra++; else h.tradesPrejuCompra++;
         }
      }
      else
      {
         // FIX386: quantidade representa contratos realmente ENTRADOS.
         if(ehEntrada)
         {
            h.vendas++;
            h.qtdVenda+=volume;
         }
         h.financeiroVenda+=resultado;
         if(resultado>=0.0) h.financeiroLucroVenda+=resultado; else h.financeiroPrejuVenda+=resultado;
         if(ehSaida)
         {
            if(ehParcialReal)
            {
               h.parcialVenda+=resultado;
               if(resultado>=0.0)
               {
                  h.parciaisLucroQtdVenda++;
                  h.financeiroParcialLucroVenda+=resultado;
               }
               else
               {
                  h.parciaisPrejuQtdVenda++;
                  h.financeiroParcialPrejuVenda+=resultado;
               }
            }
            if(resultado>=0.0) h.tradesLucroVenda++; else h.tradesPrejuVenda++;
         }
      }
   }
   // FIX316: deals de saída continuam sendo a fonte oficial do realizado;
   // se ainda não houve saída, a posição aberta preenche somente entrada/QTD.
   AplicarFallbackEntradasAbertasHistoricoFIX316(h);
   h.qtdTotal=h.qtdCompra+h.qtdVenda;
   h.financeiro=NormalizeDouble(h.financeiroCompra+h.financeiroVenda,2);
   h.parcialCompra=NormalizeDouble(h.parcialCompra,2);
   h.parcialVenda=NormalizeDouble(h.parcialVenda,2);
   h.parcial=NormalizeDouble(h.parcialCompra+h.parcialVenda,2);
   h.financeiroParcialLucroCompra=NormalizeDouble(h.financeiroParcialLucroCompra,2);
   h.financeiroParcialPrejuCompra=NormalizeDouble(h.financeiroParcialPrejuCompra,2);
   h.financeiroParcialLucroVenda=NormalizeDouble(h.financeiroParcialLucroVenda,2);
   h.financeiroParcialPrejuVenda=NormalizeDouble(h.financeiroParcialPrejuVenda,2);
   h.lucroTotal=h.financeiro;
   if(incluirAberto)
   {
      double aberto=0.0,qtd=0.0;
      if(magicFiltro>0)
         CalcularAbertoContratosPorMagicDireto(magicFiltro,qtd,aberto);
      else
      {
         double qc=0.0,qv=0.0,qt=0.0,ac=0.0,av=0.0;
         CalcularAbertoTotalABGrupoDiretoBase(qc,qv,qt,ac,av,aberto);
      }
      h.lucroTotal=NormalizeDouble(h.lucroTotal+aberto,2);
   }
   double saldoConta=AccountInfoDouble(ACCOUNT_BALANCE);
   if(saldoConta>0.0) h.percentual=(h.lucroTotal/saldoConta)*100.0;
}

void CalcularHistoricoPeriodoHeadGrupo(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto)
{
   CalcularHistoricoPeriodoCoreFIX311(inicio,fim,h,nome,incluirAberto,0);
}


void ObterHistoricoMagicLocalPainel(EstadoLado &e, HistoricoPeriodo &h)
{
   HistoricoPeriodo base;
   ObterHistoricoSelecionado(base);
   h=base;
   bool compra=(e.magic==MagicPainelAAtual());
   if(compra)
   {
      h.vendas=0; h.tradesLucroVenda=0; h.tradesPrejuVenda=0; h.qtdVenda=0.0;
      h.parciaisLucroQtdVenda=0; h.parciaisPrejuQtdVenda=0;
      h.financeiroVenda=0.0; h.financeiroLucroVenda=0.0; h.financeiroPrejuVenda=0.0; h.parcialVenda=0.0;
      h.financeiroParcialLucroVenda=0.0; h.financeiroParcialPrejuVenda=0.0;
      h.financeiro=h.financeiroCompra; h.qtdTotal=h.qtdCompra; h.parcial=h.parcialCompra;
   }
   else
   {
      h.compras=0; h.tradesLucroCompra=0; h.tradesPrejuCompra=0; h.qtdCompra=0.0;
      h.parciaisLucroQtdCompra=0; h.parciaisPrejuQtdCompra=0;
      h.financeiroCompra=0.0; h.financeiroLucroCompra=0.0; h.financeiroPrejuCompra=0.0; h.parcialCompra=0.0;
      h.financeiroParcialLucroCompra=0.0; h.financeiroParcialPrejuCompra=0.0;
      h.financeiro=h.financeiroVenda; h.qtdTotal=h.qtdVenda; h.parcial=h.parcialVenda;
   }
   h.lucroTotal=h.financeiro;
}

void CalcularHistoricoOperacaoAtual(HistoricoPeriodo &h)
{
   ZerarHistoricoPeriodo(h, "OPERACAO");
   if(InpHistoricoSomenteSessaoAtual && !g_historicoTeveSaidaSessao)
   {
      h.lucroTotal = ResultadoAbertoTotalPainel();
      h.financeiro = 0.0;
      h.percentual = 0.0;
      return;
   }
   datetime agora = TimeCurrent();
   datetime inicio = 0;
   if(g_cicloInicioCompra > 0)
      inicio = g_cicloInicioCompra;
   if(g_cicloInicioVenda > 0 && (inicio <= 0 || g_cicloInicioVenda < inicio))
      inicio = g_cicloInicioVenda;
   if(inicio <= 0)
   {
      h.lucroTotal = ResultadoAbertoTotalPainel();
      h.financeiro = 0.0;
      h.percentual = 0.0;
      return;
   }
   CalcularHistoricoPeriodo(inicio, agora, h, "OPERACAO", true);
}

void ObterHistoricoPainelPrincipal(HistoricoPeriodo &h)
{
   if(InpPainelFinanceiroSomenteOperacaoAtual)
      CalcularHistoricoOperacaoAtual(h);
   else
      ObterHistoricoSelecionado(h);
}

string NomePeriodoHistoricoPainel(ENUM_PERIODO_HISTORICO_PAINEL periodo)
{
   if(periodo == HIST_PAINEL_DIA)   return "hoje";
   if(periodo == HIST_PAINEL_ONTEM) return "ontem";
   if(periodo == HIST_PAINEL_7D)    return "7 dias";
   if(periodo == HIST_PAINEL_15D)   return "15 dias";
   if(periodo == HIST_PAINEL_30D)   return "30 dias";
   return "tudo";
}

void CalcularHistoricoPeriodo(datetime inicio, datetime fim, HistoricoPeriodo &h, string nome, bool incluirAberto)
{
   CalcularHistoricoPeriodoCoreFIX311(inicio,fim,h,nome,incluirAberto,0);
}

ENUM_PERIODO_HISTORICO_PAINEL PeriodoIdPorNome(string nome)
{
   if(nome == "DIA")      return HIST_PAINEL_DIA;
   if(nome == "ONTEM")    return HIST_PAINEL_ONTEM;
   if(nome == "7D")       return HIST_PAINEL_7D;
   if(nome == "15D")      return HIST_PAINEL_15D;
   if(nome == "30D")      return HIST_PAINEL_30D;
   if(nome == "TUDO")     return HIST_PAINEL_TUDO;
   if(nome == "OPERACAO") return HIST_PAINEL_OPERACAO;
   return HIST_PAINEL_INVALIDO;
}

void DefinirJanelaHistorico(HistoricoPeriodo &h, datetime inicio, datetime fim, bool incluirAberto)
{
   h.janelaInicio = inicio;
   h.janelaFim = fim;
   h.calculadoEm = AgoraServidorHistorico();
   h.incluiAberto = incluirAberto;
   h.chaveDiaServidor = (long)InicioDoDia(h.calculadoEm);
}

bool HistoricoPeriodoCompativel(HistoricoPeriodo &h, ENUM_PERIODO_HISTORICO_PAINEL esperado)
{
   if(h.periodoId != esperado)
      return false;
   if(esperado == HIST_PAINEL_DIA || esperado == HIST_PAINEL_ONTEM)
   {
      long chaveHoje = (long)InicioDoDia(AgoraServidorHistorico());
      if(h.chaveDiaServidor != chaveHoje)
         return false;
   }
   return true;
}

void VerificarViradaDiaHistorico(datetime agora)
{
   AuditoriaViradaDiaFIX310(agora);
   datetime inicioHoje=InicioDoDia(agora);
   if(g_diaHistoricoAtivo==0)
   {
      g_diaHistoricoAtivo=inicioHoje;
      return;
   }
   if(g_diaHistoricoAtivo==inicioHoje) return;
   g_diaHistoricoAtivo=inicioHoje;
   ZerarHistoricoPeriodo(g_histDia,"DIA");
   DefinirJanelaHistorico(g_histDia,inicioHoje,agora,false);
   datetime inicioOntem=InicioOntemCivilFIX311(agora);
   CalcularHistoricoPeriodo(inicioOntem,inicioHoje-1,g_histOntem,"ONTEM",false);
   g_ultimaAtualizacaoHistorico=0;
   g_ultimaAtualizacaoHistoricoLongo=0;
   g_historicoPrimeiraCargaFeita=false;
   g_historicoPassoLongo=0;
   Print("[COPA_AR100][FIX311] Virada civil | DIA zerado | ONTEM civil recalculado | inicioHoje=",
         TimeToString(inicioHoje,TIME_DATE|TIME_SECONDS));
}

void ZerarHistoricoPeriodo(HistoricoPeriodo &h, string nome)
{
   h.periodoId = PeriodoIdPorNome(nome);
   h.janelaInicio = 0;
   h.janelaFim = 0;
   h.calculadoEm = 0;
   h.incluiAberto = false;
   h.chaveDiaServidor = (long)InicioDoDia(AgoraServidorHistorico());
   h.nome = nome;
   h.compras = 0;
   h.vendas = 0;
   h.tradesLucroCompra = 0;
   h.tradesPrejuCompra = 0;
   h.tradesLucroVenda = 0;
   h.tradesPrejuVenda = 0;
   h.parciaisLucroQtdCompra = 0;
   h.parciaisPrejuQtdCompra = 0;
   h.parciaisLucroQtdVenda = 0;
   h.parciaisPrejuQtdVenda = 0;
   h.qtdCompra = 0.0;
   h.qtdVenda = 0.0;
   h.qtdTotal = 0.0;
   h.financeiro = 0.0;
   h.financeiroCompra = 0.0;
   h.financeiroVenda = 0.0;
   h.financeiroLucroCompra = 0.0;
   h.financeiroPrejuCompra = 0.0;
   h.financeiroLucroVenda = 0.0;
   h.financeiroPrejuVenda = 0.0;
   h.percentual = 0.0;
   h.parcial = 0.0;
   h.parcialCompra = 0.0;
   h.parcialVenda = 0.0;
   h.financeiroParcialLucroCompra = 0.0;
   h.financeiroParcialPrejuCompra = 0.0;
   h.financeiroParcialLucroVenda = 0.0;
   h.financeiroParcialPrejuVenda = 0.0;
   h.lucroTotal = 0.0;
}

void InicializarHistoricoPainelZerado()
{
   g_diaHistoricoAtivo = InicioDoDia(AgoraServidorHistorico());
   ZerarHistoricoPeriodo(g_histDia,    "DIA");
   ZerarHistoricoPeriodo(g_histOntem,  "ONTEM");
   ZerarHistoricoPeriodo(g_hist7Dias,  "7D");
   ZerarHistoricoPeriodo(g_hist15Dias, "15D");
   ZerarHistoricoPeriodo(g_hist30Dias, "30D");
   ZerarHistoricoPeriodo(g_histTudo,   "TUDO");
   g_periodoHistoricoAtivo = HIST_PAINEL_DIA;
   g_ultimaAtualizacaoHistorico = 0;
   g_ultimaAtualizacaoHistoricoLongo = 0;
   g_historicoPassoLongo = 0;
   g_historicoTeveSaidaSessao = false;
   g_historicoPrimeiraCargaFeita = false;
}

void CapturarMarcoHistoricoInicial()
{
   g_historicoMarcoDealInicial = 0;
   g_historicoMarcoHoraInicial = 0;
   if(!InpHistoricoSomenteSessaoAtual)
      return;
   datetime fim = AgoraServidorHistorico() + (86400 * 30);
   if(fim <= 0)
      fim = D'2037.12.31 23:59';
   if(!HistorySelect(0, fim))
      return;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      if(!DealEhDoRoboHistorico(deal))
         continue;
      if(deal > g_historicoMarcoDealInicial)
         g_historicoMarcoDealInicial = deal;
      datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(t > g_historicoMarcoHoraInicial)
         g_historicoMarcoHoraInicial = t;
   }
   g_historicoTeveSaidaSessao = false;
}

bool DealEhDepoisDoMarcoHistoricoSessao(ulong deal)
{
   if(!InpHistoricoSomenteSessaoAtual)
      return true;
   if(deal == 0)
      return false;
   if(g_historicoMarcoDealInicial > 0 && deal <= g_historicoMarcoDealInicial)
      return false;
   datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
   if(g_historicoMarcoDealInicial <= 0 && g_horarioInicioRobo > 0 && t < g_horarioInicioRobo)
      return false;
   return true;
}

string FamiliaContratoHistoricoFIX347(string simbolo)
{
   string s=simbolo;
   StringToUpper(s);
   // Contratos B3: todos os vencimentos de mini indice comecam por WIN
   // e todos os vencimentos de mini dolar comecam por WDO.
   if(StringFind(s,"WIN")==0) return "WIN";
   if(StringFind(s,"WDO")==0) return "WDO";
   return s;
}

bool SimboloAceitoHistoricoFIX347(string simbolo)
{
   if(simbolo==_Symbol)
      return true;
   if(!InpHistoricoUnificarVencimentosFIX347)
      return false;
   string familiaDeal=FamiliaContratoHistoricoFIX347(simbolo);
   string familiaAtual=FamiliaContratoHistoricoFIX347(_Symbol);
   return (familiaDeal!="" && familiaDeal==familiaAtual && (familiaAtual=="WIN" || familiaAtual=="WDO"));
}

datetime InicioOntemCivilFIX311(datetime referencia)
{
   return InicioDoDia(referencia)-86400;
}

datetime InicioDoDia(datetime ref)
{
   MqlDateTime dt;
   TimeToStruct(ref, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

datetime AgoraServidorHistorico()
{
   if((bool)MQLInfoInteger(MQL_TESTER))
      return TimeCurrent();
   datetime servidor = TimeTradeServer();
   if(servidor > 0)
      return servidor;
   datetime atual = TimeCurrent();
   if(atual > 0)
      return atual;
   return TimeLocal();
}

datetime InicioDiasAtras(int quantidadeDias)
{
   datetime agora = AgoraServidorHistorico();
   if(quantidadeDias <= 1)
      return InicioDoDia(agora);
   return InicioDoDia(agora) - (datetime)((quantidadeDias - 1) * 86400);
}

string NomeModoComissaoFIX305()
{
   if(InpModoComissaoAtivoFIX305==COMISSAO_SERVIDOR_FIX305)
      return "SERVIDOR";
   if(InpModoComissaoAtivoFIX305==COMISSAO_AUTO_FIX305)
      return "AUTO";
   return "MANUAL_RT";
}

double ResultadoDealServidorFIX305(ulong deal)
{
   if(deal==0)
      return 0.0;
   double profit=HistoryDealGetDouble(deal,DEAL_PROFIT);
   double commission=HistoryDealGetDouble(deal,DEAL_COMMISSION);
   double swap=HistoryDealGetDouble(deal,DEAL_SWAP);
   double fee=HistoryDealGetDouble(deal,DEAL_FEE);
   return profit+commission+swap+fee;
}

double ComissaoManualDealFIX305(ulong deal)
{
   if(deal==0 || InpComissaoIdaVoltaPorContratoReaisFIX305<=0.0)
      return 0.0;
   long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(!DealEhSaidaParcial(entry))
      return 0.0; // custo manual ida+volta e reconhecido uma unica vez, no volume encerrado
   double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
   return -MathAbs(InpComissaoIdaVoltaPorContratoReaisFIX305)*MathMax(0.0,volume);
}

double ComissaoAplicadaDealFIX305(ulong deal)
{
   if(deal==0)
      return 0.0;
   double servidor=HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);
   if(InpModoComissaoAtivoFIX305==COMISSAO_SERVIDOR_FIX305)
      return servidor;
   double manual=ComissaoManualDealFIX305(deal);
   if(InpModoComissaoAtivoFIX305==COMISSAO_AUTO_FIX305)
   {
      if(MathAbs(servidor)>0.0000001)
         return servidor;
      return manual;
   }
   return manual;
}

bool CalcularLucroEsperadoDealReaisFIX313(ulong dealSaida, double &lucroEsperado, double &precoMedio, double &volumeSaida)
{
   lucroEsperado=0.0;
   precoMedio=0.0;
   volumeSaida=0.0;
   if(dealSaida==0)
      return false;
   long entrySaida=(long)HistoryDealGetInteger(dealSaida,DEAL_ENTRY);
   if(!DealEhSaidaParcial(entrySaida))
      return false;
   string simbolo=HistoryDealGetString(dealSaida,DEAL_SYMBOL);
   if(simbolo=="")
      return false;
   long tipoSaida=(long)HistoryDealGetInteger(dealSaida,DEAL_TYPE);
   long tipoEntrada=-1;
   ENUM_ORDER_TYPE ordemEntrada=ORDER_TYPE_BUY;
   if(tipoSaida==DEAL_TYPE_SELL)
   {
      tipoEntrada=DEAL_TYPE_BUY;
      ordemEntrada=ORDER_TYPE_BUY;
   }
   else if(tipoSaida==DEAL_TYPE_BUY)
   {
      tipoEntrada=DEAL_TYPE_SELL;
      ordemEntrada=ORDER_TYPE_SELL;
   }
   else
      return false;

   long positionId=(long)HistoryDealGetInteger(dealSaida,DEAL_POSITION_ID);
   long tempoAlvo=(long)HistoryDealGetInteger(dealSaida,DEAL_TIME_MSC);
   if(positionId<=0)
      return false;

   // Guardamos o recorte atual para poder restaurá-lo se precisarmos ampliar a busca.
   int totalOriginal=HistoryDealsTotal();
   datetime restaurarInicio=0,restaurarFim=0;
   if(totalOriginal>0)
   {
      ulong primeiro=HistoryDealGetTicket(0);
      ulong ultimo=HistoryDealGetTicket(totalOriginal-1);
      if(primeiro>0) restaurarInicio=(datetime)HistoryDealGetInteger(primeiro,DEAL_TIME);
      if(ultimo>0) restaurarFim=(datetime)HistoryDealGetInteger(ultimo,DEAL_TIME)+1;
   }

   double volumeAberto=0.0;
   double precoPonderado=0.0;
   bool ampliouSelecao=false;
   for(int tentativa=0;tentativa<2;tentativa++)
   {
      volumeAberto=0.0;
      precoPonderado=0.0;
      int total=HistoryDealsTotal();
      for(int i=0;i<total;i++)
      {
      ulong d=HistoryDealGetTicket(i);
      if(d==0 || d==dealSaida)
         continue;
      if((long)HistoryDealGetInteger(d,DEAL_POSITION_ID)!=positionId)
         continue;
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=simbolo)
         continue;
      long tempo=(long)HistoryDealGetInteger(d,DEAL_TIME_MSC);
      if(tempo>tempoAlvo || (tempo==tempoAlvo && d>=dealSaida))
         continue;
      long entrada=(long)HistoryDealGetInteger(d,DEAL_ENTRY);
      long tipo=(long)HistoryDealGetInteger(d,DEAL_TYPE);
      double vol=HistoryDealGetDouble(d,DEAL_VOLUME);
      double preco=HistoryDealGetDouble(d,DEAL_PRICE);
      if(vol<=0.0 || preco<=0.0)
         continue;
      if((entrada==DEAL_ENTRY_IN || entrada==DEAL_ENTRY_INOUT) && tipo==tipoEntrada)
      {
         double novoVolume=volumeAberto+vol;
         if(novoVolume>0.0)
            precoPonderado=(precoPonderado*volumeAberto+preco*vol)/novoVolume;
         volumeAberto=novoVolume;
      }
       else if((entrada==DEAL_ENTRY_OUT || entrada==DEAL_ENTRY_OUT_BY || entrada==DEAL_ENTRY_INOUT) && tipo==tipoSaida)
       {
          volumeAberto-=vol;
          if(volumeAberto<0.0) volumeAberto=0.0;
       }
      }
      if(precoPonderado>0.0)
         break;
      if(tentativa==0)
      {
         datetime fimSelecao=(datetime)HistoryDealGetInteger(dealSaida,DEAL_TIME)+60;
         if(HistorySelect(0,fimSelecao))
            ampliouSelecao=true;
      }
   }

   volumeSaida=HistoryDealGetDouble(dealSaida,DEAL_VOLUME);
   double precoSaida=HistoryDealGetDouble(dealSaida,DEAL_PRICE);
   if(ampliouSelecao && restaurarFim>restaurarInicio)
      HistorySelect(restaurarInicio,restaurarFim);
   if(precoPonderado<=0.0 || volumeSaida<=0.0 || precoSaida<=0.0)
      return false;
   precoMedio=precoPonderado;

   double calculado=0.0;
   if(OrderCalcProfit(ordemEntrada,simbolo,volumeSaida,precoMedio,precoSaida,calculado) && MathIsValidNumber(calculado))
   {
      lucroEsperado=NormalizeDouble(calculado,2);
      return true;
   }

   double tickSize=SymbolInfoDouble(simbolo,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(simbolo,SYMBOL_TRADE_TICK_VALUE);
   if(tickSize<=0.0 || tickValue<=0.0)
      return false;
   double diferenca=(tipoEntrada==DEAL_TYPE_BUY ? precoSaida-precoMedio : precoMedio-precoSaida);
   lucroEsperado=NormalizeDouble((diferenca/tickSize)*tickValue*volumeSaida,2);
   return MathIsValidNumber(lucroEsperado);
}

bool ObterResultadoDealCacheFIX313(ulong deal, double &resultado)
{
   resultado=0.0;
   int n=ArraySize(g_cacheDealTicketFIX313);
   int esquerda=0,direita=n-1;
   while(esquerda<=direita)
   {
      int meio=(esquerda+direita)/2;
      ulong atual=g_cacheDealTicketFIX313[meio];
      if(atual==deal)
      {
         resultado=g_cacheDealResultadoFIX313[meio];
         return true;
      }
      if(atual<deal) esquerda=meio+1;
      else direita=meio-1;
   }
   return false;
}

void SalvarResultadoDealCacheFIX313(ulong deal, double resultado)
{
   if(deal==0) return;
   int n=ArraySize(g_cacheDealTicketFIX313);
   if(n==0 || g_cacheDealTicketFIX313[n-1]<deal)
   {
      ArrayResize(g_cacheDealTicketFIX313,n+1);
      ArrayResize(g_cacheDealResultadoFIX313,n+1);
      g_cacheDealTicketFIX313[n]=deal;
      g_cacheDealResultadoFIX313[n]=resultado;
      return;
   }
   int pos=0;
   while(pos<n && g_cacheDealTicketFIX313[pos]<deal) pos++;
   if(pos<n && g_cacheDealTicketFIX313[pos]==deal)
   {
      g_cacheDealResultadoFIX313[pos]=resultado;
      return;
   }
   ArrayResize(g_cacheDealTicketFIX313,n+1);
   ArrayResize(g_cacheDealResultadoFIX313,n+1);
   for(int i=n;i>pos;i--)
   {
      g_cacheDealTicketFIX313[i]=g_cacheDealTicketFIX313[i-1];
      g_cacheDealResultadoFIX313[i]=g_cacheDealResultadoFIX313[i-1];
   }
   g_cacheDealTicketFIX313[pos]=deal;
   g_cacheDealResultadoFIX313[pos]=resultado;
}

double ResultadoDealSeguroReaisFIX313(ulong deal)
{
   if(deal==0)
      return 0.0;
   double cache=0.0;
   if(ObterResultadoDealCacheFIX313(deal,cache))
      return cache;

   double bruto=HistoryDealGetDouble(deal,DEAL_PROFIT);
   double esperado=0.0,precoMedio=0.0,volumeSaida=0.0;
   bool temBase=CalcularLucroEsperadoDealReaisFIX313(deal,esperado,precoMedio,volumeSaida);
   double profitSeguro=bruto;
   double fatorServidor=1.0;
   if(temBase)
   {
      double tolerancia=MathMax(InpToleranciaFinanceiraMinimaFIX313,MathAbs(esperado)*InpToleranciaFinanceiraPercentualFIX313);
      if(MathAbs(bruto-esperado)>tolerancia)
      {
         profitSeguro=esperado;
         if(MathAbs(bruto)>0.0000001)
            fatorServidor=esperado/bruto;
         g_fatorFinanceiroServidorFIX313=fatorServidor;
         g_fatorFinanceiroDetectadoFIX313=true;
         g_amostrasFatorFinanceiroFIX313++;
         g_financeiroDealsReconstruidosFIX313++;
         g_ultimoDealFinanceiroReconstruidoFIX313=deal;
         g_ultimoProfitBrutoFIX313=bruto;
         g_ultimoProfitSeguroFIX313=profitSeguro;
      }
      else
      {
         g_fatorFinanceiroServidorFIX313=1.0;
         g_fatorFinanceiroDetectadoFIX313=true;
         g_amostrasFatorFinanceiroFIX313++;
      }
   }
   else
   {
      g_financeiroDealsSemBaseFIX313++;
      g_financeiroHistoricoValidoFIX314=false;
      g_financeiroHistoricoErrosFIX314++;
      g_financeiroHistoricoUltimoDealErroFIX314=deal;
      profitSeguro=0.0; // Nunca usar um valor bruto que não pôde ser conferido.
   }

   // Profit é reconstruído pelo preço. Swap, comissão e taxa continuam na unidade
   // informada pela conta, pois são componentes separados do lucro do preço.
   double swap=HistoryDealGetDouble(deal,DEAL_SWAP);
   double comissaoServidor=HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);

   double custo=0.0;
   if(InpModoComissaoAtivoFIX305==COMISSAO_SERVIDOR_FIX305)
      custo=comissaoServidor;
   else if(InpModoComissaoAtivoFIX305==COMISSAO_AUTO_FIX305)
      custo=(MathAbs(comissaoServidor)>0.0000001 ? comissaoServidor : ComissaoManualDealFIX305(deal));
   else
      custo=ComissaoManualDealFIX305(deal);

   double resultado=NormalizeDouble(profitSeguro+swap+custo,2);
   // Só guarda quando a base foi reconstruída. Se faltou a entrada no recorte atual,
   // uma leitura histórica mais ampla poderá tentar novamente depois.
   if(temBase)
      SalvarResultadoDealCacheFIX313(deal,resultado);
   return resultado;
}

double ResultadoDealLiquidoAuditadoFIX305(ulong deal)
{
   return ResultadoDealSeguroReaisFIX313(deal);
}

double ResultadoDealHistorico(ulong deal)
{
   if(InpComissaoAfetaFinanceiroRoboFIX305)
      return ResultadoDealSeguroReaisFIX313(deal);
   double esperado=0.0,precoMedio=0.0,volumeSaida=0.0;
   if(CalcularLucroEsperadoDealReaisFIX313(deal,esperado,precoMedio,volumeSaida))
      return esperado;
   g_financeiroHistoricoValidoFIX314=false;
   g_financeiroHistoricoErrosFIX314++;
   g_financeiroHistoricoUltimoDealErroFIX314=deal;
   return 0.0;
}

bool AuditarUnidadeFinanceiraHojeFIX313(int &corrigidos, int &semBase, double &somaBruta, double &somaSegura)
{
   corrigidos=0; semBase=0; somaBruta=0.0; somaSegura=0.0;
   g_financeiroHistoricoValidoFIX314=true;
   g_financeiroHistoricoErrosFIX314=0;
   g_financeiroHistoricoUltimoDealErroFIX314=0;
   datetime agora=AgoraServidorHistorico();
   datetime inicio=InicioDoDia(agora);
   if(!HistorySelect(0,agora))
      return false;
   int total=HistoryDealsTotal();
   int saidasAuditadas=0;
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || !DealEhDepoisDoMarcoHistoricoZero(deal)) continue;
      if(!DealEhDoRoboHistorico(deal)) continue;
      datetime horarioDeal=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(horarioDeal<inicio || horarioDeal>agora) continue;
      if(!DealEhSaidaParcial((long)HistoryDealGetInteger(deal,DEAL_ENTRY))) continue;
      saidasAuditadas++;
      double bruto=HistoryDealGetDouble(deal,DEAL_PROFIT);
      double esperado=0.0,pm=0.0,vol=0.0;
      bool temBase=CalcularLucroEsperadoDealReaisFIX313(deal,esperado,pm,vol);
      somaBruta+=bruto;
      if(!temBase)
      {
         semBase++;
         somaSegura+=ResultadoDealSeguroReaisFIX313(deal);
         continue;
      }
      double tolerancia=MathMax(InpToleranciaFinanceiraMinimaFIX313,MathAbs(esperado)*InpToleranciaFinanceiraPercentualFIX313);
      if(MathAbs(bruto-esperado)>tolerancia) corrigidos++;
      double seguro=ResultadoDealSeguroReaisFIX313(deal);
      if(!MathIsValidNumber(seguro)) return false;
      somaSegura+=seguro;
   }
   somaBruta=NormalizeDouble(somaBruta,2);
   somaSegura=NormalizeDouble(somaSegura,2);
   if(!MathIsValidNumber(somaSegura)) return false;
   return (saidasAuditadas==0 || semBase==0);
}

int ContarSaidasRecentesFIX313(int janelaSegundos)
{
   if(janelaSegundos<60) janelaSegundos=60;
   datetime fim=AgoraServidorHistorico();
   datetime inicio=fim-janelaSegundos;
   if(g_historicoMarcoZero>inicio) inicio=g_historicoMarcoZero;
   if(!HistorySelect(inicio,fim)) return 0;
   int qtd=0;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || !DealEhDoRoboHistorico(deal)) continue;
      if(!DealEhSaidaParcial((long)HistoryDealGetInteger(deal,DEAL_ENTRY))) continue;
      if(DealEhParcialHistoricaReal(deal)) continue;
      qtd++;
   }
   return qtd;
}

bool ProtecaoRepeticaoPermiteNovaOrdemFIX313(EstadoLado &estado, string contexto)
{
   // FIX361: a primeira A0 depois de um ciclo lucrativo não espera cooldown.
   // Proteções reais de conta, margem, spread, direção e duplicidade continuam ativas.
   if(estado.reentradaImediataAposLucro)
      return true;
   int qtd=ContarSaidasRecentesFIX313(InpJanelaProtecaoRepeticaoSegundosFIX313);
   if(qtd<InpMaxSaidasEmCincoMinutosFIX313)
      return true;
   string msg=StringFormat("PROTECAO DE REPETICAO: %d saidas em %d minutos. Novas ordens bloqueadas; gestao e fechamento continuam ativos.",
                           qtd,InpJanelaProtecaoRepeticaoSegundosFIX313/60);
   g_mestre.mensagemGeral=msg;
   datetime agora=TimeCurrent();
   if(g_ultimaProtecaoRepeticaoLogFIX313<=0 || (agora-g_ultimaProtecaoRepeticaoLogFIX313)>=30)
   {
      g_ultimaProtecaoRepeticaoLogFIX313=agora;
      RegistrarGerenciadorOrdens(estado,contexto,msg,0,0,0.0,0.0,true);
      RegistrarLogValidacaoSistema("PROTECAO_REPETICAO",msg);
   }
   return false;
}

bool DealEhParcialHistoricaReal(ulong deal)
{
   string c = HistoryDealGetString(deal, DEAL_COMMENT);
   StringToUpper(c);
   return (StringFind(c, "|PC") >= 0 || StringFind(c, "PARCIAL") >= 0 || StringFind(c, "PARC_") >= 0);
}



bool DealEhDoRoboHistorico(ulong deal)
{
   if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) return false;
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(!MagicPertencePainelTotalAB(magic)) return false;
   return ComentarioTemIdentidadeAtualFIX304(HistoryDealGetString(deal,DEAL_COMMENT),magic);
}

bool DealEhDoRobo(ulong deal)
{
   if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) return false;
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(!MagicPertencePainelTotalAB(magic)) return false;
   return ComentarioTemIdentidadeAtualFIX304(HistoryDealGetString(deal,DEAL_COMMENT),magic);
}

bool DealEhSaidaParcial(long entry)
{
   if(entry == DEAL_ENTRY_OUT)
      return true;
   if(entry == DEAL_ENTRY_OUT_BY)
      return true;
   if(entry == DEAL_ENTRY_INOUT)
      return true;
   return false;
}

double ParcialHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return h.parcialCompra;
   if(lado == LADO_VENDA)
      return h.parcialVenda;
   return h.parcial;
}

double ParcialPositivaHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   double v = ParcialHistoricoDoLado(h, lado);
   if(v > 0.0)
      return v;
   return 0.0;
}

double ParcialPositivaHistoricoTotal(HistoricoPeriodo &h)
{
   double a = h.parcialCompra > 0.0 ? h.parcialCompra : 0.0;
   double b = h.parcialVenda  > 0.0 ? h.parcialVenda  : 0.0;
   return a + b;
}

int TradesLucroHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return h.tradesLucroCompra;
   if(lado == LADO_VENDA)
      return h.tradesLucroVenda;
   return h.tradesLucroCompra + h.tradesLucroVenda;
}

int TradesPrejuHistoricoDoLado(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return h.tradesPrejuCompra;
   if(lado == LADO_VENDA)
      return h.tradesPrejuVenda;
   return h.tradesPrejuCompra + h.tradesPrejuVenda;
}


#endif // COPA_HISTORICO_CORE_MQH
