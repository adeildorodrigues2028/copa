#ifndef COPA_PARCIAL_NIVEIS_MQH
#define COPA_PARCIAL_NIVEIS_MQH

bool CalcularInfoGrupoTipoAB(long tipo, double &volume, double &precoMedio, double &lucroAberto, double &precoFechamento)
{
   volume = 0.0;
   precoMedio = 0.0;
   lucroAberto = 0.0;
   precoFechamento = 0.0;
   double somaPrecoVolume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
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
      long ptype = PositionGetInteger(POSITION_TYPE);
      if(ptype != tipo)
         continue;
      double vol = PositionGetDouble(POSITION_VOLUME);
      double preco = PositionGetDouble(POSITION_PRICE_OPEN);
      if(vol <= 0.0 || preco <= 0.0)
         continue;
      volume += vol;
      somaPrecoVolume += preco * vol;
      lucroAberto += LucroAbertoPosicaoSelecionada(tipo);
   }
   if(volume <= 0.0 || somaPrecoVolume <= 0.0)
      return false;
   precoMedio = somaPrecoVolume / volume;
   precoFechamento = (tipo == POSITION_TYPE_BUY ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   if(precoFechamento <= 0.0)
      precoFechamento = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
   return (precoMedio > 0.0 && precoFechamento > 0.0);
}

double LucroEstimadoGrupoTipoPorPreco(long tipo, double volume, double precoMedio, double precoFechamento)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(volume <= 0.0 || precoMedio <= 0.0 || precoFechamento <= 0.0 || tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;
   double pontos = 0.0;
   if(tipo == POSITION_TYPE_BUY)
      pontos = precoFechamento - precoMedio;
   else if(tipo == POSITION_TYPE_SELL)
      pontos = precoMedio - precoFechamento;
   else
      return 0.0;
   return (pontos / tickSize) * tickValue * volume;
}

double DistanciaAumentoPontosIndice(int indiceZero)
{
   if(indiceZero < 0)
      return 0.0;
   if(indiceZero >= ArraySize(g_aumentos))
      indiceZero = ArraySize(g_aumentos) - 1;
   if(indiceZero < 0 || indiceZero >= ArraySize(g_aumentos))
      return 0.0;
   if(InpAumentosDistanciaAbsolutaEntrada)
      return (double)MathMax(0, g_aumentos[indiceZero].distanciaPontos);
   return DistanciaAcumuladaAumentoPontos(indiceZero);
}

bool PrecoEntradaReferenciaGrupoTipoAB(long tipo, double &precoEntradaRef, double &volume, double &precoFechamento)
{
   precoEntradaRef = 0.0;
   volume = 0.0;
   precoFechamento = 0.0;
   datetime tempoMaisAntigo = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
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
      long ptype = PositionGetInteger(POSITION_TYPE);
      if(ptype != tipo)
         continue;
      double vol = PositionGetDouble(POSITION_VOLUME);
      double preco = PositionGetDouble(POSITION_PRICE_OPEN);
      if(vol <= 0.0 || preco <= 0.0)
         continue;
      volume += vol;
      datetime tpos = (datetime)PositionGetInteger(POSITION_TIME);
      if(precoEntradaRef <= 0.0 || tempoMaisAntigo <= 0 || tpos < tempoMaisAntigo)
      {
         tempoMaisAntigo = tpos;
         precoEntradaRef = preco;
      }
   }
   precoFechamento = (tipo == POSITION_TYPE_BUY ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   if(precoFechamento <= 0.0)
      precoFechamento = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
   return (precoEntradaRef > 0.0 && volume > 0.0 && precoFechamento > 0.0);
}

int AumentosExecutadosEfetivosLado(EstadoLado &estado, long tipo)
{
   int feitos = estado.aumentosExecutados;
   if(feitos > 0)
      return feitos;
   double vol = 0.0;
   double precoEntrada = 0.0;
   double precoFechamento = 0.0;
   if(PrecoEntradaReferenciaGrupoTipoAB(tipo, precoEntrada, vol, precoFechamento))
   {
      double entrada = MathAbs(InpEntradaContratos);
      if(entrada <= 0.0)
         entrada = 1.0;
      feitos = (int)MathFloor((vol - entrada) + 0.0001);
      if(feitos < 0)
         feitos = 0;
   }
   if(feitos > 5)
      feitos = 5;
   return feitos;
}

double PrecoNivelParcialRecuoAumento(EstadoLado &estado, long tipo, double recuoPontos, double &distAumentoPontos, double &distLinhaPontos, double &precoEntradaRef)
{
   distAumentoPontos = 0.0;
   distLinhaPontos = 0.0;
   precoEntradaRef = 0.0;
   if(!ParcialRecuoAumentoAtivoEfetivo())
      return 0.0;
   if(tipo != POSITION_TYPE_BUY && tipo != POSITION_TYPE_SELL)
      return 0.0;
   int feitos = AumentosExecutadosEfetivosLado(estado, tipo);
   if(feitos <= 0)
      return 0.0;
   int idx = feitos - 1;
   if(idx < 0)
      idx = 0;
   if(idx >= ArraySize(g_aumentos))
      idx = ArraySize(g_aumentos) - 1;
   distAumentoPontos = DistanciaAumentoPontosIndice(idx);
   if(distAumentoPontos <= 0.0)
      return 0.0;
   double vol = 0.0;
   double precoFechamento = 0.0;
   if(!PrecoEntradaReferenciaGrupoTipoAB(tipo, precoEntradaRef, vol, precoFechamento))
   {
      precoEntradaRef = estado.precoMedio;
      if(precoEntradaRef <= 0.0)
         return 0.0;
   }
   double minimo = MathAbs(InpParcialRecuoMinimoPontos);
   if(minimo < 0.0)
      minimo = 0.0;
   double recuo = MathAbs(recuoPontos);
   distLinhaPontos = distAumentoPontos - recuo;
   if(distLinhaPontos < minimo)
      distLinhaPontos = minimo;
   double distPreco = distLinhaPontos * _Point;
   if(tipo == POSITION_TYPE_BUY)
      return precoEntradaRef - distPreco;
   if(tipo == POSITION_TYPE_SELL)
      return precoEntradaRef + distPreco;
   return 0.0;
}

double PrecoNivelParcialGraficoLado(EstadoLado &estado, double valorBaseNivel, double &valorNivelEfetivo, double &volumeReferencia)
{
   volumeReferencia = estado.contratos;
   valorNivelEfetivo = GatilhoParcialEfetivoPorVolume(valorBaseNivel, volumeReferencia);
   long tipo = TipoPosicaoPeloLadoEstado(estado);
   if(ParcialRecuoAumentoAtivoEfetivo() && (tipo == POSITION_TYPE_BUY || tipo == POSITION_TYPE_SELL))
   {
      double distAum = 0.0;
      double distLinha = 0.0;
      double precoEntradaRef = 0.0;
      double precoRecuo = PrecoNivelParcialRecuoAumento(estado, tipo, valorBaseNivel, distAum, distLinha, precoEntradaRef);
      if(precoRecuo > 0.0)
      {
         volumeReferencia = estado.contratos;
         valorNivelEfetivo = MathAbs(valorBaseNivel);
         RegistrarLogValidacaoSistema("PARAM_PARCIAL_RECUO_GRAFICO",
            StringFormat("lado=%s | tipo=%s | entrada=%.0f | dist_aum=%.0f | parcial=%.0f | dist_linha=%.0f | preco_linha=%.0f | fonte=ABA_PARAMETROS",
                         NomeLado(estado.lado),
                         (tipo == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                         precoEntradaRef, distAum, MathAbs(valorBaseNivel), distLinha, precoRecuo));
         return precoRecuo;
      }
   }
   if(InpParcialLinhaGraficoUsarGrupoHeadAB && RiscoOperacaoModoCesta() && (tipo == POSITION_TYPE_BUY || tipo == POSITION_TYPE_SELL))
   {
      double volGrupo = 0.0;
      double precoMedioGrupo = 0.0;
      double lucroGrupo = 0.0;
      double precoFechamento = 0.0;
      if(CalcularInfoGrupoTipoAB(tipo, volGrupo, precoMedioGrupo, lucroGrupo, precoFechamento))
      {
         volumeReferencia = volGrupo;
         valorNivelEfetivo = GatilhoParcialEfetivoPorVolume(valorBaseNivel, volGrupo);
         double gainPorPonta = MathAbs(g_risco.metaOperacao);
         if(gainPorPonta <= 0.0)
            gainPorPonta = MathAbs(InpEntradaGanhoAlvoReais);
         if(InpParcialForcarTotalAntesDoGain && gainPorPonta > 0.0 && valorNivelEfetivo >= gainPorPonta)
            valorNivelEfetivo = MathAbs(valorBaseNivel);
         double distGrupo = DistanciaPrecoPorFinanceiro(MathAbs(valorNivelEfetivo), volGrupo);
         if(distGrupo > 0.0)
         {
            if(tipo == POSITION_TYPE_BUY)
               return precoMedioGrupo + distGrupo;
            if(tipo == POSITION_TYPE_SELL)
               return precoMedioGrupo - distGrupo;
         }
      }
   }
   return PrecoNivelFinanceiroLado(estado, valorNivelEfetivo);
}

int HashTextoCurtoAB(string texto)
{
   long h = 0;
   for(int i = 0; i < StringLen(texto); i++)
      h = (h * 31 + (long)StringGetCharacter(texto, i)) % 1000000;
   if(h < 0)
      h = -h;
   return (int)h;
}

string ChaveGlobalCurtaAB()
{
   string lista = IntegerToString((int)MagicPainelAAtual()) + "," + IntegerToString((int)MagicPainelBAtual());
   string simbolo = _Symbol;
   StringReplace(simbolo, ".", "");
   StringReplace(simbolo, "#", "");
   StringReplace(simbolo, "-", "");
   StringReplace(simbolo, " ", "");
   if(StringLen(simbolo) > 8)
      simbolo = StringSubstr(simbolo, 0, 8);
   long login = (long)AccountInfoInteger(ACCOUNT_LOGIN);
   if(login < 0)
      login = -login;
   login = login % 100000;
   return "AR100_" + IntegerToString(login) + "_" + simbolo + "_" + IntegerToString(HashTextoCurtoAB(lista)) + "_";
}

string ChaveParABCompletadoFIX274()
{
   return ChaveGlobalCurtaAB() + "FIX275_HEAD_PAR_ATIVO";
}

bool ParABJaCompletadoFIX274()
{
   string chave = ChaveParABCompletadoFIX274();
   return (GlobalVariableCheck(chave) && GlobalVariableGet(chave) > 0.5);
}

void AtualizarEstadoParABFIX274()
{
   bool temCompra = GrupoHeadTemPosicaoTipo(POSITION_TYPE_BUY);
   bool temVenda  = GrupoHeadTemPosicaoTipo(POSITION_TYPE_SELL);
   string chave = ChaveParABCompletadoFIX274();
   if(temCompra && temVenda)
   {
      if(!GlobalVariableCheck(chave) || GlobalVariableGet(chave) < 0.5)
      {
         GlobalVariableSet(chave,1.0);
         RegistrarLogValidacaoSistema("FIX275_PAR_AB_ATIVO","Par A+B confirmado. Se uma ponta encerrar, ela sera rearmada apos a pausa tecnica sem fechar a ponta oposta.");
      }
      return;
   }
   if(!temCompra && !temVenda)
   {
      if(GlobalVariableCheck(chave))
         GlobalVariableDel(chave);
   }
}

string ChaveCicloGrupoTipoAB(long tipo)
{
   datetime tempoMaisAntigo = 0;
   ulong ticketMaisAntigo = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
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
      long ptype = PositionGetInteger(POSITION_TYPE);
      if(ptype != tipo)
         continue;
      datetime tpos = (datetime)PositionGetInteger(POSITION_TIME);
      if(tempoMaisAntigo <= 0 || tpos < tempoMaisAntigo || (tpos == tempoMaisAntigo && ticket < ticketMaisAntigo))
      {
         tempoMaisAntigo = tpos;
         ticketMaisAntigo = ticket;
      }
   }
   if(ticketMaisAntigo == 0)
      return "SEM";
   return IntegerToString((long)tempoMaisAntigo % 1000000) + "_" + IntegerToString((long)(ticketMaisAntigo % 100000));
}

void LimparLocksParciaisHedgeABPorPrefixo()
{
   string prefixo = ChaveGlobalCurtaAB();
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string nome = GlobalVariableName(i);
      if(StringFind(nome, prefixo) != 0)
         continue;
      if(StringFind(nome, "PL_") >= 0 || StringFind(nome, "LP_") >= 0)
         GlobalVariableDel(nome);
   }
}

string ChaveParcialLinhaHeadAB(long tipo, string sufixo)
{
   string lado = (tipo == POSITION_TYPE_BUY ? "B" : "S");
   return ChaveGlobalCurtaAB() + "PL_" + lado + "_" + ChaveCicloGrupoTipoAB(tipo) + "_" + sufixo;
}

int NivelParcialLinhaHeadABRegistrado(long tipo)
{
   string chave = ChaveParcialLinhaHeadAB(tipo, "NIVEL");
   if(!GlobalVariableCheck(chave))
      return 0;
   return (int)GlobalVariableGet(chave);
}

void RegistrarNivelParcialLinhaHeadAB(long tipo, int nivel)
{
   if(nivel <= 0)
      return;
   GlobalVariableSet(ChaveParcialLinhaHeadAB(tipo, "NIVEL"), (double)nivel);
}

bool RegistrarLockParcialLinhaHeadAB(long tipo)
{
   int cooldown = InpParcialLinhaCooldownSegundos;
   if(cooldown < 0)
      cooldown = 0;
   string chave = ChaveParcialLinhaHeadAB(tipo, "LOCK");
   double agora = (double)TimeCurrent();
   if(!GlobalVariableCheck(chave))
      GlobalVariableSet(chave, 0.0);
   double anterior = GlobalVariableGet(chave);
   if(cooldown > 0 && (agora - anterior) < cooldown)
      return false;
   return GlobalVariableSetOnCondition(chave, agora, anterior);
}


#endif // COPA_PARCIAL_NIVEIS_MQH
