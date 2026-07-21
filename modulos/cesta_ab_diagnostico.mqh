#ifndef COPA_CESTA_AB_DIAGNOSTICO_MQH
#define COPA_CESTA_AB_DIAGNOSTICO_MQH

bool PainelSlotEhA(EstadoLado &e)
{
   return (e.magic == MagicPainelAAtual());
}

bool PainelSlotEhB(EstadoLado &e)
{
   return (e.magic == MagicPainelBAtual());
}

double ParcialHistoricoDoSlotPainel(HistoricoPeriodo &h, EstadoLado &e)
{
   if(PainelSlotEhA(e)) return h.parcialCompra;
   if(PainelSlotEhB(e)) return h.parcialVenda;
   return 0.0;
}




void ZerarFotoCestaAB(FotoCestaAB &f)
{
   f.inicio = 0;
   f.fim = 0;
   f.grupoMagics = "";
   f.qtdCompra = 0.0;
   f.qtdVenda = 0.0;
   f.qtdTotal = 0.0;
   f.qtdLiquida = 0.0;
   f.abertoCompra = 0.0;
   f.abertoVenda = 0.0;
   f.abertoTotal = 0.0;
   f.realizadoCompra = 0.0;
   f.realizadoVenda = 0.0;
   f.realizadoTotal = 0.0;
   f.saldoCompra = 0.0;
   f.saldoVenda = 0.0;
   f.saldoTotal = 0.0;
   f.lucroRealizado = 0.0;
   f.prejuRealizado = 0.0;
   f.parcialCompra = 0.0;
   f.parcialVenda = 0.0;
   f.parcialTotal = 0.0;
   f.tradesLucro = 0;
   f.tradesPreju = 0;
   f.tradesTotal = 0;
   f.dealsSaidaUsados = 0;
}

datetime InicioHistoricoCestaABOficial()
{
   datetime inicio = 0;
   if(g_cicloInicioCompra > 0)
      inicio = g_cicloInicioCompra;
   if(g_cicloInicioVenda > 0 && (inicio <= 0 || g_cicloInicioVenda < inicio))
      inicio = g_cicloInicioVenda;
   if(inicio <= 0)
      inicio = g_horarioInicioRobo;
   if(InpHistoricoSomenteSessaoAtual && g_horarioInicioRobo > 0 && inicio < g_horarioInicioRobo)
      inicio = g_horarioInicioRobo;
   return inicio;
}

void CalcularRealizadoCestaABGrupo(FotoCestaAB &f)
{
   if(f.fim <= f.inicio || f.inicio <= 0)
      return;
   if(!HistorySelect(f.inicio, f.fim))
      return;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      string symbol = HistoryDealGetString(deal, DEAL_SYMBOL);
      if(symbol != _Symbol)
         continue;
      long magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(!MagicPertenceHistoricoFinanceiroFIX458(magic))
         continue;
      if(!DealEhDepoisDoMarcoHistoricoSessao(deal))
         continue;
      datetime dealTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(dealTime < f.inicio || dealTime > f.fim)
         continue;
      long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(!DealEhSaidaParcial(entry))
         continue;
      long type = HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      double resultado = ResultadoDealHistorico(deal);
      if(MagicHistoricoCompraFIX458(magic))
      {
         f.realizadoCompra += resultado;
         f.parcialCompra += resultado;
      }
      else if(MagicHistoricoVendaFIX458(magic))
      {
         f.realizadoVenda += resultado;
         f.parcialVenda += resultado;
      }
      f.realizadoTotal += resultado;
      f.parcialTotal += resultado;
      f.dealsSaidaUsados++;
      f.tradesTotal++;
      if(resultado >= 0.0)
      {
         f.lucroRealizado += resultado;
         f.tradesLucro++;
      }
      else
      {
         f.prejuRealizado += resultado;
         f.tradesPreju++;
      }
   }
}

void CopiarRealizadoFotoFIX283(FotoCestaAB &destino, FotoCestaAB &origem)
{
   destino.realizadoCompra=origem.realizadoCompra;
   destino.realizadoVenda=origem.realizadoVenda;
   destino.realizadoTotal=origem.realizadoTotal;
   destino.lucroRealizado=origem.lucroRealizado;
   destino.prejuRealizado=origem.prejuRealizado;
   destino.parcialCompra=origem.parcialCompra;
   destino.parcialVenda=origem.parcialVenda;
   destino.parcialTotal=origem.parcialTotal;
   destino.tradesLucro=origem.tradesLucro;
   destino.tradesPreju=origem.tradesPreju;
   destino.tradesTotal=origem.tradesTotal;
   destino.dealsSaidaUsados=origem.dealsSaidaUsados;
}

void CalcularFotoCestaABOficial(FotoCestaAB &f, bool usarSnapshotAberto)
{
   ZerarFotoCestaAB(f);
   f.inicio = InicioHistoricoCestaABOficial();
   f.fim = TimeCurrent();
   f.grupoMagics = TextoGrupoMagicsTotalAB();
   if(usarSnapshotAberto)
      CalcularAbertoTotalABGrupoDireto(f.qtdCompra, f.qtdVenda, f.qtdTotal, f.abertoCompra, f.abertoVenda, f.abertoTotal);
   else
      CalcularAbertoTotalABGrupoDiretoBase(f.qtdCompra, f.qtdVenda, f.qtdTotal, f.abertoCompra, f.abertoVenda, f.abertoTotal);
   f.qtdLiquida = MathAbs(f.qtdCompra - f.qtdVenda);

   // FIX283: o realizado so muda quando chega uma transacao. Nao ha motivo para
   // executar HistorySelect e percorrer todos os deals varias vezes no mesmo tick.
   ulong agoraMsFIX283=GetTickCount64();
   bool cacheRecenteFIX283=(g_cacheRealizadoCestaValidoFIX283 &&
                            g_cacheRealizadoCestaInicioFIX283==f.inicio &&
                            agoraMsFIX283>=g_cacheRealizadoCestaMsFIX283 &&
                            (agoraMsFIX283-g_cacheRealizadoCestaMsFIX283)<=1000);
   if(InpFIX283ModoLeve && cacheRecenteFIX283)
      CopiarRealizadoFotoFIX283(f,g_cacheRealizadoCestaFIX283);
   else
   {
      CalcularRealizadoCestaABGrupo(f);
      if(InpFIX283ModoLeve)
      {
         ZerarFotoCestaAB(g_cacheRealizadoCestaFIX283);
         CopiarRealizadoFotoFIX283(g_cacheRealizadoCestaFIX283,f);
         g_cacheRealizadoCestaInicioFIX283=f.inicio;
         g_cacheRealizadoCestaMsFIX283=agoraMsFIX283;
         g_cacheRealizadoCestaValidoFIX283=true;
      }
   }
   f.saldoCompra = f.realizadoCompra + f.abertoCompra;
   f.saldoVenda  = f.realizadoVenda  + f.abertoVenda;
   f.saldoTotal  = f.realizadoTotal  + f.abertoTotal;
}

string TextoLogFotoCestaAB(FotoCestaAB &f)
{
   return StringFormat("%s | C qtd %.2f aberto %s realizado %s saldo %s | V qtd %.2f aberto %s realizado %s saldo %s | TOTAL qtd %.2f liq %.2f aberto %s realizado %s saldo %s | lucro real %s | preju real %s | parciais %s | trades +%d -%d total %d | deals %d",
                       f.grupoMagics,
                       f.qtdCompra,
                       PnlMoedaBRL(f.abertoCompra),
                       PnlMoedaBRL(f.realizadoCompra),
                       PnlMoedaBRL(f.saldoCompra),
                       f.qtdVenda,
                       PnlMoedaBRL(f.abertoVenda),
                       PnlMoedaBRL(f.realizadoVenda),
                       PnlMoedaBRL(f.saldoVenda),
                       f.qtdTotal,
                       f.qtdLiquida,
                       PnlMoedaBRL(f.abertoTotal),
                       PnlMoedaBRL(f.realizadoTotal),
                       PnlMoedaBRL(f.saldoTotal),
                       PnlMoedaBRL(f.lucroRealizado),
                       PnlMoedaBRL(f.prejuRealizado),
                       PnlMoedaBRL(f.parcialTotal),
                       f.tradesLucro,
                       f.tradesPreju,
                       f.tradesTotal,
                       f.dealsSaidaUsados);
}

void LogCestaABDetalhado(string contexto, bool forcar)
{
   if(!InpLogCestaABDetalhado)
      return;
   datetime agora = TimeCurrent();
   int intervalo = InpLogCestaABIntervaloSegundos;
   if(intervalo <= 0)
      intervalo = 1;
   if(!forcar && g_ultimoLogCestaABDetalhado > 0 && (agora - g_ultimoLogCestaABDetalhado) < intervalo)
      return;
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   if(!forcar && f.qtdTotal <= 0.0 && f.dealsSaidaUsados <= 0)
      return;
   g_ultimoLogCestaABDetalhado = agora;
   string msg = "VALIDA A+B => " + TextoLogFotoCestaAB(f) +
                " | formula: saldo_total = realizado_total + aberto_total";
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][FIX155][", contexto, "] ", msg);
   RegistrarLogValidacaoCSV(g_painelA, contexto, msg, 0, 0, 0.0, 0.0, true);
}

void LogDealSaidaCestaAB(ulong deal)
{
   if(!InpLogCestaABDetalhado)
      return;
   if(deal == 0 || !HistoryDealSelect(deal))
      return;
   long type = HistoryDealGetInteger(deal, DEAL_TYPE);
   string pontaFechada = "OUTRA";
   if(type == DEAL_TYPE_SELL)
      pontaFechada = "COMPRA";
   else if(type == DEAL_TYPE_BUY)
      pontaFechada = "VENDA";
   long magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
   double volume = HistoryDealGetDouble(deal, DEAL_VOLUME);
   double resultado = ResultadoDealHistorico(deal);
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   string msg = StringFormat("DEAL SAIDA DETALHADO | deal %s | magic %d | fechou ponta %s | volume %.2f | resultado %s | depois: %s",
                             IntegerToString((long)deal),
                             (int)magic,
                             pontaFechada,
                             volume,
                             PnlMoedaBRL(resultado),
                             TextoLogFotoCestaAB(f));
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][FIX155][DEAL_AB] ", msg);
   RegistrarLogValidacaoCSV(g_painelA, "DEAL_AB_DETALHE", msg, 0, 0, volume, 0.0, true);
}

string NomeTipoPosicaoHedge(long type)
{
   if(type == POSITION_TYPE_BUY)
      return "BUY";
   if(type == POSITION_TYPE_SELL)
      return "SELL";
   return "OUTRA";
}

string NomeTipoDealHedge(long type)
{
   if(type == DEAL_TYPE_BUY)
      return "DEAL_BUY";
   if(type == DEAL_TYPE_SELL)
      return "DEAL_SELL";
   if(type == DEAL_TYPE_BALANCE)
      return "DEAL_BALANCE";
   if(type == DEAL_TYPE_CREDIT)
      return "DEAL_CREDIT";
   if(type == DEAL_TYPE_CHARGE)
      return "DEAL_CHARGE";
   if(type == DEAL_TYPE_CORRECTION)
      return "DEAL_CORRECTION";
   return "DEAL_OUTRO";
}

string NomeEntryDealHedge(long entry)
{
   if(entry == DEAL_ENTRY_IN)
      return "IN";
   if(entry == DEAL_ENTRY_OUT)
      return "OUT";
   if(entry == DEAL_ENTRY_INOUT)
      return "INOUT";
   if(entry == DEAL_ENTRY_OUT_BY)
      return "OUT_BY";
   return "ENTRY_OUTRO";
}

int ContarPosicoesAbertasGrupoAB()
{
   int totalGrupo = 0;
   for(int i = 0; i < PositionsTotal(); i++)
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
      totalGrupo++;
   }
   return totalGrupo;
}

string TextoPosicoesAbertasGrupoAB()
{
   if(!InpLogHedgeCompletoListarTickets)
      return "LISTA_TICKETS_DESLIGADA";
   string txt = "";
   for(int i = 0; i < PositionsTotal(); i++)
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
      double volume = PositionGetDouble(POSITION_VOLUME);
      double precoMedio = PositionGetDouble(POSITION_PRICE_OPEN);
      double precoAtual = PositionGetDouble(POSITION_PRICE_CURRENT);
      double aberto = PositionGetDouble(POSITION_PROFIT);
      double swap = PositionGetDouble(POSITION_SWAP);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      string comentario = PositionGetString(POSITION_COMMENT);
      string item = StringFormat("ticket %s magic %d %s vol %.2f pm %.0f atual %.0f aberto %.2f swap %.2f sl %.0f tp %.0f coment %s",
                                 IntegerToString((long)ticket),
                                 (int)magic,
                                 NomeTipoPosicaoHedge(type),
                                 volume,
                                 precoMedio,
                                 precoAtual,
                                 aberto,
                                 swap,
                                 sl,
                                 tp,
                                 comentario);
      if(txt != "")
         txt += " || ";
      txt += item;
   }
   if(txt == "")
      txt = "SEM_POSICAO_ABERTA_GRUPO";
   return txt;
}

string TextoHedgeStatusAB(FotoCestaAB &f)
{
   bool temCompra = (f.qtdCompra > 0.0001);
   bool temVenda  = (f.qtdVenda  > 0.0001);
   if(temCompra && temVenda)
      return "HEDGE_ATIVO_COMPRA_E_VENDA";
   if(temCompra)
      return "SOMENTE_COMPRA";
   if(temVenda)
      return "SOMENTE_VENDA";
   if(f.dealsSaidaUsados > 0)
      return "FLAT_COM_HISTORICO_DA_CESTA";
   return "FLAT_SEM_CESTA";
}

void LogHedgeCompleto(string contexto,
                      string etapa,
                      string motivo,
                      ulong ticket,
                      ulong deal,
                      long magic,
                      uint retcode,
                      int erro,
                      double volume,
                      double preco,
                      bool forcar)
{
   if(!InpLogHedgeCompletoAtivo)
      return;
   datetime agora = TimeCurrent();
   int intervalo = InpLogHedgeCompletoIntervaloSegundos;
   if(intervalo <= 0)
      intervalo = 1;
   if(!forcar && g_ultimoLogHedgeCompleto > 0 && (agora - g_ultimoLogHedgeCompleto) < intervalo)
      return;
   FotoCestaAB f;
   CalcularFotoCestaABOficial(f, false);
   if(!forcar && f.qtdTotal <= 0.0001 && f.dealsSaidaUsados <= 0)
      return;
   g_ultimoLogHedgeCompleto = agora;
   double somaConferencia = f.realizadoCompra + f.realizadoVenda + f.abertoCompra + f.abertoVenda;
   double diferenca = f.saldoTotal - somaConferencia;
   string status = TextoHedgeStatusAB(f);
   string duasPontas = (f.qtdCompra > 0.0001 && f.qtdVenda > 0.0001) ? "SIM" : "NAO";
   string dealInfo = "SEM_DEAL";
   if(deal > 0 && HistoryDealSelect(deal))
   {
      long dealType = HistoryDealGetInteger(deal, DEAL_TYPE);
      long dealEntry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      double dealProfit = HistoryDealGetDouble(deal, DEAL_PROFIT);
      double dealComissao = HistoryDealGetDouble(deal, DEAL_COMMISSION);
      double dealSwap = HistoryDealGetDouble(deal, DEAL_SWAP);
      double dealResultado = ResultadoDealHistorico(deal);
      string dealComent = HistoryDealGetString(deal, DEAL_COMMENT);
      dealInfo = StringFormat("deal %s tipo %s entry %s profit %.2f comissao %.2f swap %.2f resultado %.2f comentario %s",
                              IntegerToString((long)deal),
                              NomeTipoDealHedge(dealType),
                              NomeEntryDealHedge(dealEntry),
                              dealProfit,
                              dealComissao,
                              dealSwap,
                              dealResultado,
                              dealComent);
   }
   string msg = StringFormat("HEDGE LOG COMPLETO | etapa %s | motivo %s | status %s | duas_pontas %s | ticket %s | deal %s | magic %d | volume %.2f | preco %.0f | retcode %d | erro %d | qtd_posicoes %d | check %.2f | soma %.2f | saldo %.2f | %s | posicoes %s | %s",
                             etapa,
                             motivo,
                             status,
                             duasPontas,
                             ticket > 0 ? IntegerToString((long)ticket) : "",
                             deal > 0 ? IntegerToString((long)deal) : "",
                             (int)magic,
                             volume,
                             preco,
                             (int)retcode,
                             erro,
                             ContarPosicoesAbertasGrupoAB(),
                             diferenca,
                             somaConferencia,
                             f.saldoTotal,
                             TextoLogFotoCestaAB(f),
                             TextoPosicoesAbertasGrupoAB(),
                             dealInfo);
   if(InpLogCestaABNoExperts)
      Print("[COPA_AR100][FIX157][", contexto, "] ", msg);
   RegistrarLogValidacaoCSV(g_painelA, contexto, msg, retcode, erro, volume, preco, true);
}

bool ExistePosicaoAbertaGrupoTotalAB()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      if(MagicPertencePainelTotalAB(magic))
         return true;
   }
   return false;
}

bool CestaABTemDuasPontasAbertasGrupo()
{
   double qtdCompra = 0.0;
   double qtdVenda = 0.0;
   double qtdTotal = 0.0;
   double abertoCompra = 0.0;
   double abertoVenda = 0.0;
   double abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, qtdTotal, abertoCompra, abertoVenda, abertoTotal);
   return (qtdCompra > 0.0001 && qtdVenda > 0.0001);
}


#endif // COPA_CESTA_AB_DIAGNOSTICO_MQH
