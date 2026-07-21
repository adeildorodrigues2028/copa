#ifndef COPA_RESUMO_FINANCEIRO_MQH
#define COPA_RESUMO_FINANCEIRO_MQH

// RESPONSABILIDADE: ESTADO DAS POSICOES E PAINEL FINANCEIRO

void PrepararSlotPainel(EstadoLado &slot, string nome, long magic, ENUM_LADO_ROBO slotHistorico)
{
   slot.lado = slotHistorico;   // usado somente para buscar historico A/B.
   slot.nome = nome;
   slot.magic = magic;
   slot.tipoPosicaoAtual = -1;
}

void ResetarDadosCicloSemPosicao(EstadoLado &estado)
{
   if(estado.posicaoAberta)
      return;
   estado.precoMedio = 0.0;
   estado.precoEntradaInicial = 0.0;
   estado.resultadoAberto = 0.0;
   estado.resultadoAbertoServidor = 0.0;
   estado.resultadoAbertoManual = 0.0;
   estado.melhorResultadoAberto = 0.0;
   estado.lucroProtegido = false;
   estado.valorDefendido = 0.0;
   estado.modoLongo = false;
   estado.parcial50Executada = false;
   estado.parcialFinalExecutada = false;
   estado.aumentosExecutados = 0;
   bool existePosicaoMagicFIX257=ExistePosicaoMagicQualquerInstancia(estado.magic);
   bool existeOrdemA0PendenteFIX257=ExisteOrdemPendenteA0FIX257(estado);
   string chaveA0FIX257=ChaveLockA0(estado);
   bool lockA0RecenteFIX257=false;
   if(GlobalVariableCheck(chaveA0FIX257) && GlobalVariableGet(chaveA0FIX257)>0.0)
   {
      int idadeLockFIX257=(int)(TimeCurrent()-(datetime)GlobalVariableGet(chaveA0FIX257));
      lockA0RecenteFIX257=(idadeLockFIX257>=0 && idadeLockFIX257<5);
   }
   if(!existePosicaoMagicFIX257 && !existeOrdemA0PendenteFIX257 && !lockA0RecenteFIX257)
      LimparLocksCicloMagic(estado.magic);
   estado.horarioEntrada = 0;
   estado.horarioUltimoAumento = 0;
   estado.ultimoNivelAumentoUsado = 0;
   estado.motivoBloqueioAumento = "";
   ResetarRastreamentoAumentosFIX212(estado);
}

void SincronizarResultadoFechadoDiaComHistorico()
{
   if(InpModoSimplesFIX195)
   {
      g_compra.resultadoFechado = g_parciaisCicloBuy;
      g_venda.resultadoFechado  = g_parciaisCicloSell;
      g_compra.resultadoDia     = g_compra.resultadoFechado + g_compra.resultadoAberto;
      g_venda.resultadoDia      = g_venda.resultadoFechado  + g_venda.resultadoAberto;
      return;
   }
   HistoricoPeriodo hBase;
   if(InpRiscoUsarFinanceiroOperacaoAtual || InpPainelFinanceiroSomenteOperacaoAtual)
      CalcularHistoricoOperacaoAtual(hBase);
   else
      hBase = g_histDia;
   g_compra.resultadoFechado = hBase.financeiroCompra;
   g_venda.resultadoFechado  = hBase.financeiroVenda;
   g_compra.resultadoDia     = g_compra.resultadoFechado + g_compra.resultadoAberto;
   g_venda.resultadoDia      = g_venda.resultadoFechado  + g_venda.resultadoAberto;
}

void AtualizarEstadosPainelFinanceiro()
{
   PrepararSlotPainel(g_painelA, "A", MagicPainelAAtual(), LADO_COMPRA);
   PrepararSlotPainel(g_painelB, "B", MagicPainelBAtual(), LADO_VENDA);
   AtualizarEstadoLado(g_painelA);
   AtualizarEstadoLado(g_painelB);
}

void AtualizarEstadosDePosicao()
{
   // FIX287: varias rotinas chamam esta funcao dentro do mesmo evento.
   // Se a quantidade de posicoes nao mudou e a chamada ocorre no mesmo milissegundo,
   // reutiliza o estado ja calculado em vez de percorrer todas as posicoes quatro vezes novamente.
   ulong agoraMsFIX287=GetTickCount64();
   int qtdPosFIX287=PositionsTotal();
   if(InpFIX287UltraLeve && g_ultimaAtualizacaoEstadosMsFIX287==agoraMsFIX287 &&
      g_ultimaQtdPosicoesEstadosFIX287==qtdPosFIX287)
      return;

   g_ultimaAtualizacaoEstadosMsFIX287=agoraMsFIX287;
   g_ultimaQtdPosicoesEstadosFIX287=qtdPosFIX287;
   AtualizarEstadoLado(g_compra);
   AtualizarEstadoLado(g_venda);
   AtualizarEstadosPainelFinanceiro();
}



bool PosicaoEhAceitaParaLeituraDoEstado(EstadoLado &estado, string comentarioPosicao)
{
   // FIX317: painel, motor, volume, parcial e fechamento usam a mesma regra.
   // comentarioPosicao permanece no parâmetro para compatibilidade e auditoria,
   // mas nunca bloqueia a gestão de uma posição real do ativo/Magic/lado.
   return PosicaoSelecionadaPertenceEstadoFIX317(estado);
}

void AtualizarEstadoLado(EstadoLado &estado)
{
   estado.posicaoAberta = false;
   estado.contratos = 0.0;
   estado.contratosCompra = 0.0;
   estado.contratosVenda = 0.0;
   estado.tipoPosicaoAtual = -1;
   estado.precoMedio = 0.0;
   estado.resultadoAberto = 0.0;
   estado.resultadoAbertoServidor = 0.0;
   estado.resultadoAbertoManual = 0.0;
   estado.aumentosExecutados = 0;
   double somaPrecoVolume = 0.0;
   datetime menorHorarioEntrada = 0;
   double precoMenorHorarioEntrada = 0.0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      string symbol = PositionGetString(POSITION_SYMBOL);
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      long type = PositionGetInteger(POSITION_TYPE);
      if(symbol != _Symbol || magic != estado.magic)
         continue;
      string comentarioPosicao = PositionGetString(POSITION_COMMENT);
      if(!PosicaoEhAceitaParaLeituraDoEstado(estado, comentarioPosicao))
         continue;
      if(type != POSITION_TYPE_BUY && type != POSITION_TYPE_SELL)
         continue;
      // FIX316: A é sempre COMPRA e B é sempre VENDA, inclusive no painel.
      if(estado.lado == LADO_COMPRA && type != POSITION_TYPE_BUY)
         continue;
      if(estado.lado == LADO_VENDA && type != POSITION_TYPE_SELL)
         continue;
      double volume = PositionGetDouble(POSITION_VOLUME);
      double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      double profitServidor = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double profitManual   = LucroAbertoPosicaoSelecionada(type);
      double profit         = InpLucroAbertoUsarCalculoManual ? profitManual : profitServidor;
      datetime posTime = (datetime)PositionGetInteger(POSITION_TIME);
      estado.posicaoAberta = true;
      estado.contratos += volume;
      if(type == POSITION_TYPE_BUY)
         estado.contratosCompra += volume;
      else if(type == POSITION_TYPE_SELL)
         estado.contratosVenda += volume;
      estado.resultadoAberto += profit;
      estado.resultadoAbertoServidor += profitServidor;
      estado.resultadoAbertoManual += profitManual;
      somaPrecoVolume += priceOpen * volume;
      if(menorHorarioEntrada <= 0 || posTime < menorHorarioEntrada)
      {
         menorHorarioEntrada = posTime;
         precoMenorHorarioEntrada = priceOpen;
      }
   }
   if(estado.contratos > 0.0)
   {
      estado.precoMedio = somaPrecoVolume / estado.contratos;
      estado.horarioEntrada = menorHorarioEntrada;
      RestaurarPrecosEntradaAumentosFIX220(estado);
      if(estado.precoEntradaInicial <= 0.0 && precoMenorHorarioEntrada > 0.0)
         estado.precoEntradaInicial = precoMenorHorarioEntrada;
      if(estado.contratosCompra > 0.0 && estado.contratosVenda > 0.0)
         estado.tipoPosicaoAtual = -2; // MISTO/HEDGE dentro do mesmo Magic.
      else if(estado.contratosCompra > 0.0)
         estado.tipoPosicaoAtual = POSITION_TYPE_BUY;
      else if(estado.contratosVenda > 0.0)
         estado.tipoPosicaoAtual = POSITION_TYPE_SELL;
      if(estado.lado == LADO_COMPRA && g_cicloInicioCompra <= 0)
         g_cicloInicioCompra = menorHorarioEntrada;
      else if(estado.lado == LADO_VENDA && g_cicloInicioVenda <= 0)
         g_cicloInicioVenda = menorHorarioEntrada;
      int qtdAumentosPorPlano = AumentosExecutadosPlanejadosPorContratos(estado.contratos);
      for(int nivelConfirmado = 1; nivelConfirmado <= qtdAumentosPorPlano; nivelConfirmado++)
      {
         if(!g_aumentos[nivelConfirmado - 1].ativa)
            continue;
         string chaveNivel = ChaveLockAumento(estado, nivelConfirmado);
         if(!GlobalVariableCheck(chaveNivel) || GlobalVariableGet(chaveNivel) <= 0.0)
            GlobalVariableSet(chaveNivel, (double)TimeCurrent());
         MarcarLockAumentoConfirmadoFIX208(estado, nivelConfirmado);
         if(estado.ultimoNivelAumentoUsado < nivelConfirmado)
            estado.ultimoNivelAumentoUsado = nivelConfirmado;
      }
      int qtdAumentos = qtdAumentosPorPlano;
      if(estado.ultimoNivelAumentoUsado > qtdAumentos)
         qtdAumentos = estado.ultimoNivelAumentoUsado;
      if(qtdAumentos < 0)
         qtdAumentos = 0;
      if(qtdAumentos > g_gerAumentos.maxAumentos)
         qtdAumentos = g_gerAumentos.maxAumentos;
      estado.aumentosExecutados = qtdAumentos;
   }
   else
   {
      ResetarDadosCicloSemPosicao(estado);
   }
}

ENUM_LADO_ROBO LadoDaPosicaoAtual(EstadoLado &estado)
{
   if(estado.tipoPosicaoAtual == POSITION_TYPE_BUY)
      return LADO_COMPRA;
   if(estado.tipoPosicaoAtual == POSITION_TYPE_SELL)
      return LADO_VENDA;
   return estado.lado;
}

double LucroAbertoPosicaoSelecionadaFIX354(long tipo)
{
   string simbolo=PositionGetString(POSITION_SYMBOL);
   if(simbolo=="")
      simbolo=_Symbol;
   double volume=PositionGetDouble(POSITION_VOLUME);
   double openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
   double servidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
   if(volume<=0.0 || openPrice<=0.0)
      return NormalizeDouble(servidor,2);

   MqlTick tick;
   ZeroMemory(tick);
   if(!SymbolInfoTick(simbolo,tick))
      return NormalizeDouble(servidor,2);

   double closePrice=0.0;
   ENUM_ORDER_TYPE ordem=ORDER_TYPE_BUY;
   if(tipo==POSITION_TYPE_BUY)
   {
      ordem=ORDER_TYPE_BUY;
      closePrice=tick.bid;
   }
   else if(tipo==POSITION_TYPE_SELL)
   {
      ordem=ORDER_TYPE_SELL;
      closePrice=tick.ask;
   }
   else
      return NormalizeDouble(servidor,2);

   if(closePrice<=0.0)
      return NormalizeDouble(servidor,2);

   double calculado=0.0;
   ResetLastError();
   if(OrderCalcProfit(ordem,simbolo,volume,openPrice,closePrice,calculado) && MathIsValidNumber(calculado))
      return NormalizeDouble(calculado+PositionGetDouble(POSITION_SWAP),2);

   return NormalizeDouble(servidor,2);
}

double LucroAbertoPosicaoSelecionada(long tipo)
{
   return LucroAbertoPosicaoSelecionadaFIX354(tipo);
}



// V36: isolamento financeiro estrito. O historico aceita somente o par atual.
// Magics antigos jamais sao somados automaticamente: uma migracao, quando
// desejada, precisa ser explicita e auditada fora do motor financeiro.
bool MagicHistoricoCompraFIX458(long magic)
{
   return (magic==MagicPainelAAtual());
}

bool MagicHistoricoVendaFIX458(long magic)
{
   return (magic==MagicPainelBAtual());
}

bool MagicPertenceHistoricoFinanceiroFIX458(long magic)
{
   return (MagicHistoricoCompraFIX458(magic) || MagicHistoricoVendaFIX458(magic));
}

long TipoLadoHistoricoMagicFIX458(long magic)
{
   if(MagicHistoricoCompraFIX458(magic)) return POSITION_TYPE_BUY;
   if(MagicHistoricoVendaFIX458(magic))  return POSITION_TYPE_SELL;
   return -1;
}

long TipoPosicaoEsperadoMagicPainelFIX316(long magic)
{
   if(magic==MagicPainelAAtual())
      return POSITION_TYPE_BUY;
   if(magic==MagicPainelBAtual())
      return POSITION_TYPE_SELL;
   return -1;
}

bool PosicaoSelecionadaPertencePainelFIX316(long magic)
{
   // A posição já deve estar selecionada por ticket antes desta chamada.
   if(magic<=0)
      return false;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return false;
   if((long)PositionGetInteger(POSITION_MAGIC)!=magic)
      return false;
   long tipoEsperado=TipoPosicaoEsperadoMagicPainelFIX316(magic);
   if(tipoEsperado<0)
      return false;
   return ((long)PositionGetInteger(POSITION_TYPE)==tipoEsperado);
}

bool PosicaoSelecionadaPertenceEstadoFIX317(EstadoLado &estado)
{
   // FIX317: a posição já deve estar selecionada por ticket.
   // A identidade operacional é única e simples: ativo + Magic + lado.
   // O comentário não participa da gestão porque pode mudar após reiniciar,
   // recompilar, recolocar o EA ou ser encurtado pela corretora.
   if(estado.magic<=0)
      return false;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return false;
   if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
      return false;
   long tipo=(long)PositionGetInteger(POSITION_TYPE);
   if(estado.lado==LADO_COMPRA)
      return (tipo==POSITION_TYPE_BUY);
   if(estado.lado==LADO_VENDA)
      return (tipo==POSITION_TYPE_SELL);
   return false;
}

bool DealPertenceHistoricoPainelFIX316(ulong deal)
{
   if(deal==0)
      return false;
   if(!SimboloAceitoHistoricoFIX347(HistoryDealGetString(deal,DEAL_SYMBOL)))
      return false;
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   return MagicPertenceHistoricoFinanceiroFIX458(magic);
}

void ObterEntradasAbertasPainelFIX316(double &qtdCompra, double &qtdVenda, int &entradasCompra, int &entradasVenda)
{
   qtdCompra=0.0;
   qtdVenda=0.0;
   entradasCompra=0;
   entradasVenda=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(!PosicaoSelecionadaPertencePainelFIX316(magic))
         continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(magic==MagicPainelAAtual())
      {
         qtdCompra+=volume;
         entradasCompra++;
      }
      else if(magic==MagicPainelBAtual())
      {
         qtdVenda+=volume;
         entradasVenda++;
      }
   }
}

void AplicarFallbackEntradasAbertasHistoricoFIX316(HistoricoPeriodo &h)
{
   // FIX349: somente HOJE pode usar a posição aberta como fallback.
   // ONTEM/7D/15D/30D/TUDO mostram exclusivamente os deals realizados do periodo,
   // sem contaminar quantidade, entradas ou financeiro com a operacao atual.
   bool periodoHojeFIX349=(h.periodoId==HIST_PAINEL_DIA || h.nome=="DIA" || h.nome=="HOJE");
   if(!periodoHojeFIX349 || h.periodoId==HIST_PAINEL_INVALIDO)
      return;

   double qtdCompraAberta=0.0,qtdVendaAberta=0.0;
   int entradasCompraAbertas=0,entradasVendaAbertas=0;
   ObterEntradasAbertasPainelFIX316(qtdCompraAberta,qtdVendaAberta,entradasCompraAbertas,entradasVendaAbertas);

   // É fallback, não soma cega: impede zero sem duplicar volume já reconhecido no histórico.
   if(qtdCompraAberta>h.qtdCompra) h.qtdCompra=qtdCompraAberta;
   if(qtdVendaAberta>h.qtdVenda) h.qtdVenda=qtdVendaAberta;
   if(entradasCompraAbertas>h.compras) h.compras=entradasCompraAbertas;
   if(entradasVendaAbertas>h.vendas) h.vendas=entradasVendaAbertas;
   h.qtdTotal=h.qtdCompra+h.qtdVenda;
}

bool PosicaoTemIdentidadeAR100FIX311(long magic)
{
   // FIX316: no painel, a identidade é conta/servidor atuais (do terminal),
   // símbolo, Magic e lado. Comentário antigo não pode zerar posição real.
   return PosicaoSelecionadaPertencePainelFIX316(magic);
}

void CalcularAbertoContratosPorMagicDireto(long magic, double &contratos, double &aberto)
{
   contratos=0.0;
   aberto=0.0;
   if(magic<=0) return;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if(!PosicaoTemIdentidadeAR100FIX311(magic)) continue;
      long type=PositionGetInteger(POSITION_TYPE);
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL) continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      double profitServidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double profitManual=LucroAbertoPosicaoSelecionadaFIX354(type);
      // FIX354: o painel direto sempre tenta a fotografia BID/ASK atual.
      // O valor do servidor fica apenas como reserva se o cálculo vivo falhar.
      double profit=MathIsValidNumber(profitManual) ? profitManual : profitServidor;
      contratos+=volume;
      aberto+=profit;
   }
   aberto=NormalizeDouble(aberto,2);
}

bool PainelTotalABUsaGrupoMagics()
{
   return true; // FIX252: grupo automático é exatamente o par atual A/B.
}

bool MagicPertencePainelTotalAB(long magic)
{
   return (magic == MagicPainelAAtual() || magic == MagicPainelBAtual());
}

string TextoGrupoMagicsTotalAB()
{
   return "A " + IntegerToString((int)MagicPainelAAtual()) + " | B " + IntegerToString((int)MagicPainelBAtual());
}

string ChaveSnapshotTotalABPrefixo()
{
   string bruto=StringFormat("%I64d|%s|%s|%d|%d",
                             AccountInfoInteger(ACCOUNT_LOGIN),
                             AccountInfoString(ACCOUNT_SERVER),_Symbol,
                             (int)MagicPainelAAtual(),(int)MagicPainelBAtual());
   return "AR36AB_"+Base36FIX304(HashTextoFIX304(bruto),10)+"_";
}

void InvalidarSnapshotTotalABFIX292()
{
   // Qualquer negocio invalida o retrato compartilhado; a proxima leitura recalcula pelos Magics A/B.
   string p=ChaveSnapshotTotalABPrefixo();
   GlobalVariableSet(p+"TS",0.0);
}

bool LerSnapshotTotalAB(double &qtdCompra,
                        double &qtdVenda,
                        double &totalBruto,
                        double &abertoCompra,
                        double &abertoVenda,
                        double &abertoTotal)
{
   if(!InpTotalABSincronizarEntreJanelas)
      return false;
   int validade = InpTotalABSnapshotSegundos;
   if(validade <= 0)
      return false;
   string p = ChaveSnapshotTotalABPrefixo();
   string kTS = p + "TS";
   if(!GlobalVariableCheck(kTS))
      return false;
   double ts = GlobalVariableGet(kTS);
   double agora = (double)TimeCurrent();
   if(ts <= 0.0 || agora - ts > (double)validade)
      return false;
   string kQC = p + "QC";
   string kQV = p + "QV";
   string kAC = p + "AC";
   string kAV = p + "AV";
   if(!GlobalVariableCheck(kQC) || !GlobalVariableCheck(kQV) || !GlobalVariableCheck(kAC) || !GlobalVariableCheck(kAV))
      return false;
   qtdCompra = GlobalVariableGet(kQC);
   qtdVenda = GlobalVariableGet(kQV);
   abertoCompra = GlobalVariableGet(kAC);
   abertoVenda = GlobalVariableGet(kAV);
   if(!MathIsValidNumber(qtdCompra) || !MathIsValidNumber(qtdVenda) ||
      !MathIsValidNumber(abertoCompra) || !MathIsValidNumber(abertoVenda) ||
      qtdCompra<0.0 || qtdVenda<0.0)
      return false;
   totalBruto = qtdCompra + qtdVenda;
   abertoTotal = abertoCompra + abertoVenda;
   return true;
}

void GravarSnapshotTotalAB(double qtdCompra,
                           double qtdVenda,
                           double totalBruto,
                           double abertoCompra,
                           double abertoVenda,
                           double abertoTotal)
{
   if(!InpTotalABSincronizarEntreJanelas)
      return;
   string p = ChaveSnapshotTotalABPrefixo();
   GlobalVariableSet(p + "QC", qtdCompra);
   GlobalVariableSet(p + "QV", qtdVenda);
   GlobalVariableSet(p + "TB", totalBruto);
   GlobalVariableSet(p + "AC", abertoCompra);
   GlobalVariableSet(p + "AV", abertoVenda);
   GlobalVariableSet(p + "AT", abertoTotal);
   GlobalVariableSet(p + "TS", (double)TimeCurrent());
}

void CalcularAbertoTotalABGrupoDiretoBase(double &qtdCompra,
                                          double &qtdVenda,
                                          double &totalBruto,
                                          double &abertoCompra,
                                          double &abertoVenda,
                                          double &abertoTotal)
{
   // FIX311: A e B usam a mesma filtragem de identidade do historico.
   CalcularAbertoContratosPorMagicDireto(MagicPainelAAtual(),qtdCompra,abertoCompra);
   CalcularAbertoContratosPorMagicDireto(MagicPainelBAtual(),qtdVenda,abertoVenda);
   totalBruto=qtdCompra+qtdVenda;
   abertoTotal=NormalizeDouble(abertoCompra+abertoVenda,2);
}

void CalcularAbertoTotalABGrupoDireto(double &qtdCompra,
                                      double &qtdVenda,
                                      double &totalBruto,
                                      double &abertoCompra,
                                      double &abertoVenda,
                                      double &abertoTotal)
{
   if(LerSnapshotTotalAB(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal))
      return;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal);
   GravarSnapshotTotalAB(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal);
}

void CalcularContratosCompraVendaABDireto(double &compras, double &vendas, double &totalBruto)
{
   double abertoCompra = 0.0;
   double abertoVenda = 0.0;
   double abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDireto(compras, vendas, totalBruto, abertoCompra, abertoVenda, abertoTotal);
}

string TextoQtdCabecalhoTotalAB()
{
   double compras = 0.0;
   double vendas = 0.0;
   double totalBruto = 0.0;
   CalcularContratosCompraVendaABDireto(compras, vendas, totalBruto);
   double liquido = MathAbs(compras - vendas);
   if(totalBruto <= 0.0)
      return "QTD 0";
   return StringFormat("C%.0f|V%.0f|L%.0f|T%.0f", compras, vendas, liquido, totalBruto);
}

void AplicarAbertoDiretoNoResumoMagic(ResumoFinanceiroPainel &r, long magic)
{
   double contratosDireto = 0.0;
   double abertoDireto = 0.0;
   CalcularAbertoContratosPorMagicDireto(magic, contratosDireto, abertoDireto);
   r.contratos = contratosDireto;
   r.aberto = NormalizeDouble(abertoDireto,2);
   r.saldo = NormalizeDouble(r.realizado + r.aberto,2);
   r.lucro = (r.realizado>0.0 ? r.realizado : 0.0) + (r.aberto>0.0 ? r.aberto : 0.0);
   r.prejuizo = (r.realizado<0.0 ? r.realizado : 0.0) + (r.aberto<0.0 ? r.aberto : 0.0);
   r.expPrejuizo = (r.aberto<0.0 ? r.aberto : 0.0);
   double riscoPorContrato=MathAbs(InpPainelExposicaoPorContratoReais);
   if(riscoPorContrato<=0.0)
      riscoPorContrato=MathAbs(InpEntradaPerdaMaximaReais);
   if(riscoPorContrato<=0.0)
      riscoPorContrato=MathAbs(g_risco.stopOperacao);
   r.expAtual = riscoPorContrato*r.contratos;
}

void CalcularResumoFinanceiroSlotPainel(EstadoLado &e, HistoricoPeriodo &h, ResumoFinanceiroPainel &r)
{
   ZeroMemory(r);
   r.magic = e.magic;
   r.nomeSlot = e.nome;
   r.posTexto = TextoPosicaoCard(e);
   HistoricoPeriodo hLocal;
   ObterHistoricoMagicLocalPainel(e, hLocal);
   r.realizado = hLocal.financeiro;
   bool periodoHistoricoFechado = true;
   r.aberto = 0.0;
   r.saldo = r.realizado;
   r.lucro = hLocal.financeiroLucroCompra + hLocal.financeiroLucroVenda;
   r.prejuizo = hLocal.financeiroPrejuCompra + hLocal.financeiroPrejuVenda;
   r.parcialPositiva = (hLocal.parcial > 0.0 ? hLocal.parcial : 0.0);
   r.qtdParciais = hLocal.tradesLucroCompra + hLocal.tradesLucroVenda;
   r.contratos = 0.0;
   r.totalTrades = hLocal.tradesLucroCompra + hLocal.tradesLucroVenda + hLocal.tradesPrejuCompra + hLocal.tradesPrejuVenda;
   r.tradesLucro = hLocal.tradesLucroCompra + hLocal.tradesLucroVenda;
   r.tradesPrejuizo = hLocal.tradesPrejuCompra + hLocal.tradesPrejuVenda;
   r.aumentosFeitos = e.aumentosExecutados;
   r.expPrejuizo = 0.0;
   r.expAtual = 0.0;
}

void CalcularResumoFinanceiroTotalAB(ResumoFinanceiroPainel &a, ResumoFinanceiroPainel &b, ResumoFinanceiroPainel &t)
{
   ZeroMemory(t);
   t.magic = 0;
   t.nomeSlot = "TOTAL_A_B";
   t.posTexto = "A+B";
   t.realizado = a.realizado + b.realizado;
   t.aberto = a.aberto + b.aberto;
   t.saldo = a.saldo + b.saldo;
   t.lucro = a.lucro + b.lucro;
   t.prejuizo = a.prejuizo + b.prejuizo;
   t.parcialPositiva = a.parcialPositiva + b.parcialPositiva;
   t.qtdParciais = a.qtdParciais + b.qtdParciais;
   t.contratos = a.contratos + b.contratos;
   t.totalTrades = a.totalTrades + b.totalTrades;
   t.tradesLucro = a.tradesLucro + b.tradesLucro;
   t.tradesPrejuizo = a.tradesPrejuizo + b.tradesPrejuizo;
   t.aumentosFeitos = a.aumentosFeitos + b.aumentosFeitos;
   t.expPrejuizo = a.expPrejuizo + b.expPrejuizo;
   t.expAtual = a.expAtual + b.expAtual;
}

string TextoFormulaSaldoCard3(ResumoFinanceiroPainel &a, ResumoFinanceiroPainel &b, ResumoFinanceiroPainel &t)
{
   return StringFormat("A %s + B %s = %s",
                       TextoMoedaPainelCurto(a.saldo),
                       TextoMoedaPainelCurto(b.saldo),
                       TextoMoedaPainelCurto(t.saldo));
}


#endif // COPA_RESUMO_FINANCEIRO_MQH
