#ifndef COPA_LOCKS_ORDENS_MQH
#define COPA_LOCKS_ORDENS_MQH

// ============================================================================
// RESPONSABILIDADE: AUTORIZACAO FINAL DOS AUMENTOS
// ============================================================================

bool PodeExecutarAumento(EstadoLado &estado, RegraAumento &aum, int indiceZero)
{
   if(!aum.ativa)
      return false;
   if(aum.lado != LADO_AMBOS && aum.lado != estado.lado)
      return false;
   if(!estado.posicaoAberta)
      return false;
   if(!GerenciadorAutorizaAumento(estado, aum))
      return false;

   // FIX250: no modo SCORE, timer, linha e candle ja foram aprovados; aqui somente o score final e validado.
   if(ModoAumentoSomenteScore())
   {
      // Cada chamada avalia somente o proximo nivel sequencial e usa a leitura adaptativa mais recente.
      string detalheScoreAumento = "";
      if(!ScoreAumentoAutoriza(estado, indiceZero, detalheScoreAumento))
      {
         estado.motivoBloqueioAumento = detalheScoreAumento;
         RegistrarLogEntradaFiltros(estado, "SCORE_PURO_AUMENTO", "AUMENTO", aum.filtros, false, detalheScoreAumento, true);
         return false;
      }
      estado.motivoBloqueioAumento = detalheScoreAumento;
      return true;
   }

   // REGRA ATUAL: somente os filtros escritos na linha podem bloquear o aumento.
   bool possuiFiltroConfigurado=(aum.filtros.usarRSI ||
                                 aum.filtros.usarVOLQ ||
                                 aum.filtros.usarVOLF ||
                                 aum.filtros.volumeCombinado ||
                                 aum.filtros.usarAGR ||
                                 aum.filtros.usarForca ||
                                 aum.filtros.usarHilo8 ||
                                 aum.filtros.usarSTR ||
                                 aum.filtros.usarMedia25Direcional ||
                                 aum.filtros.usarDX ||
                                 aum.filtros.usarScore ||
                                 aum.filtros.usarFibo ||
                                 aum.filtros.usarWapBands);
   bool filtrosAumentoOk = !possuiFiltroConfigurado || ValidarFiltros(aum.filtros, estado.lado);
   string detalheFiltroFIX381="";
   if(aum.filtros.usarRSI)
   {
      string opRSI=(estado.lado==LADO_COMPRA ? aum.filtros.rsiCompraOp : aum.filtros.rsiVendaOp);
      double limiteRSI=(estado.lado==LADO_COMPRA ? aum.filtros.rsiCompraMin : aum.filtros.rsiVendaMax);
      bool rsiIndividualOk=ValidarComparacao(g_mercado.rsi,opRSI,limiteRSI);
      detalheFiltroFIX381=StringFormat("RSI %s %.1f %s %.1f | %s",
                                       NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                                       g_mercado.rsi,
                                       opRSI,
                                       limiteRSI,
                                       rsiIndividualOk ? "RSI OK" : "RSI BLOQUEOU");
   }
   string motivoFiltroAumento = !possuiFiltroConfigurado
                                ? "SEM_FILTROS: TIMER+NOVO_CRUZAMENTO"
                                : (filtrosAumentoOk ? "FILTROS_CONFIGURADOS_OK" : "FILTROS_CONFIGURADOS_BLOQUEARAM");
   if(detalheFiltroFIX381!="")
      motivoFiltroAumento+=" | "+detalheFiltroFIX381;
   RegistrarLogEntradaFiltros(estado, "FILTRO_REGRA_ATUAL_AUMENTO", "AUMENTO", aum.filtros, filtrosAumentoOk, motivoFiltroAumento, true);
   if(!filtrosAumentoOk)
   {
      estado.motivoBloqueioAumento=StringFormat("A%d FILTRO BLOQUEOU | %s",
                                                indiceZero+1,
                                                detalheFiltroFIX381!="" ? detalheFiltroFIX381 : "REGRA ATUAL NAO PASSOU");
      return false;
   }
   if(!InpAumentosLivreTeste && InpScoreVolumeAumentosAtivo)
   {
      string detalheScoreVolume="";
      bool volumeAprovadoFIX352=ScoreVolumeAumentoAutorizaFIX334(LadoDaPosicaoAtual(estado),indiceZero,detalheScoreVolume);
      if(!volumeAprovadoFIX352 && !ModoContinuidadeTesteFIX352())
      {
         estado.motivoBloqueioAumento=detalheScoreVolume;
         RegistrarLogEntradaFiltros(estado,"SCORE_VOLUME_AUMENTO_FIX334","AUMENTO",aum.filtros,false,detalheScoreVolume,true);
         return false;
      }
      if(!volumeAprovadoFIX352 && ModoContinuidadeTesteFIX352())
      {
         estado.motivoBloqueioAumento="FIX352 VOL DIAGNOSTICO, NAO BLOQUEIA | "+detalheScoreVolume;
         RegistrarLogEntradaFiltros(estado,"FIX352_VOLUME_DIAGNOSTICO","AUMENTO",aum.filtros,true,estado.motivoBloqueioAumento,true);
      }
      else
      {
         estado.motivoBloqueioAumento=detalheScoreVolume;
         RegistrarLogEntradaFiltros(estado,"SCORE_VOLUME_AUMENTO_FIX334","AUMENTO",aum.filtros,true,detalheScoreVolume,true);
      }
   }
   if(InpAumentosLivreTeste)
      estado.motivoBloqueioAumento = InpAumentosLivreIgnorarTimerPreco
                                    ? "LIVRE_TOTAL: aumento depende apenas de posicao aberta, Magic e limite maximo; meta diaria ignorada no teste."
                                    : "TESTE LIVRE: timer e linha continuam obrigatorios; filtros da regra atual liberados.";
   return true;
}


bool GerenciadorAutorizaAumento(EstadoLado &estado, RegraAumento &aum)
{
   if(ControleBloqueiaMagicFIX285(estado.magic))
   {
      estado.motivoBloqueioAumento = "FIX285: aumentos bloqueados pelo botao " + TextoControleMagicFIX285(estado.magic) + ".";
      return false;
   }
   if(RearmeParcialPendenteFIX248(estado))
   {
      estado.motivoBloqueioAumento="Parcial confirmada: aguardando atualizar volume, preco medio e novas linhas.";
      return false;
   }
   if(!g_gerAumentos.ativo)
   {
      estado.motivoBloqueioAumento = "Gerenciador de aumentos OFF.";
      return false;
   }
   if(false /* FIX440 sem limite global de contratos */)
   {
      estado.motivoBloqueioAumento = "Maximo de contratos atingido.";
      return false;
   }
   // FIX453: o máximo limita os níveis A1-A5, não a quantidade de
   // ciclos de reentrada. Um nível já realizado pode reentrar novamente.
   int nivelRearme=NivelInicioRearmeFIX248(estado);
   if(estado.aumentosExecutados >= g_gerAumentos.maxAumentos && nivelRearme<=0)
   {
      estado.motivoBloqueioAumento = "Máximo de níveis iniciais atingido; aguarda rearme individual.";
      return false;
   }
   // FIX362: sem bloqueio por resultado histórico, meta antiga ou projeção futura.
   // Quantidade, sequência, timer, linha, margem real e confirmação do servidor permanecem.
   return true;
}


bool ExistePosicaoMagicQualquerInstancia(long magic)
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
      if((long)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      return true;
   }
   return false;
}

string PrefixoLockCicloMagic(long magic)
{
   string bruto=StringFormat("%I64d|%s|%s|%I64d",
                             AccountInfoInteger(ACCOUNT_LOGIN),
                             AccountInfoString(ACCOUNT_SERVER),_Symbol,magic);
   return "AR36LK_"+Base36FIX304(HashTextoFIX304(bruto),10)+"_";
}

string ChaveLockA0(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic) + "A0";
}

bool ExisteOrdemPendenteA0FIX257(EstadoLado &estado)
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC)!=estado.magic)
         continue;
      string comentario=" "+OrderGetString(ORDER_COMMENT)+" ";
      if(StringFind(comentario," A0 ")>=0)
         return true;
   }
   return false;
}

string ChaveLockAumento(EstadoLado &estado, int idx)
{
   datetime inicioCiclo = estado.horarioEntrada;
   if(inicioCiclo <= 0)
   {
      if(estado.lado == LADO_COMPRA)
         inicioCiclo = g_cicloInicioCompra;
      else if(estado.lado == LADO_VENDA)
         inicioCiclo = g_cicloInicioVenda;
   }
   if(inicioCiclo < 0)
      inicioCiclo = 0;
   return PrefixoLockCicloMagic(estado.magic) + "C" + IntegerToString((long)inicioCiclo) + "_A" + IntegerToString(idx);
}

string ChaveLockAumentoConfirmadoFIX208(EstadoLado &estado, int idx)
{
   return ChaveLockAumento(estado, idx) + "_OK";
}

double VolumePlanejadoAteAumentoFIX208(int idx)
{
   double total = MathAbs(InpEntradaContratos);
   if(total <= 0.0)
      total = 1.0;
   int limite = idx;
   if(limite < 1) limite = 1;
   if(limite > ArraySize(g_aumentos)) limite = ArraySize(g_aumentos);
   for(int i = 0; i < limite; i++)
   {
      if(g_aumentos[i].ativa)
         total += MathAbs(g_aumentos[i].qtd);
   }
   return total;
}

bool ExisteOrdemPendenteAumentoFIX208(EstadoLado &estado, int idx)
{
   string marcador = " A" + IntegerToString(idx) + " ";
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != estado.magic)
         continue;
      string comentario = " " + OrderGetString(ORDER_COMMENT) + " ";
      if(StringFind(comentario, marcador) >= 0)
         return true;
   }
   return false;
}

void MarcarLockAumentoConfirmadoFIX208(EstadoLado &estado, int idx)
{
   string chaveOK = ChaveLockAumentoConfirmadoFIX208(estado, idx);
   double token = (double)TimeCurrent();
   if(token <= 0.0) token = 1.0;
   GlobalVariableSet(chaveOK, token);
}

bool RegistrarLockCiclo(string chave)
{
   if(chave == "")
      return false;
   if(!GlobalVariableCheck(chave))
      GlobalVariableSet(chave, 0.0);
   double valorAtual = GlobalVariableGet(chave);
   if(valorAtual > 0.0)
      return false;
   double token = (double)TimeCurrent();
   if(token <= 0.0)
      token = 1.0;
   return GlobalVariableSetOnCondition(chave, token, 0.0);
}

void LiberarLockCiclo(string chave)
{
   if(chave != "" && GlobalVariableCheck(chave))
      GlobalVariableDel(chave);
}

bool RegistrarLockA0(EstadoLado &estado)
{
   string chave = ChaveLockA0(estado);
   if(GlobalVariableCheck(chave) && GlobalVariableGet(chave) > 0.0)
   {
      datetime token=(datetime)GlobalVariableGet(chave);
      int espera=InpIntervaloMinimoOrdensSeg;
      if(espera<5) espera=5;
      int idade=(int)(TimeCurrent()-token);
      bool ocupado=ExistePosicaoMagicQualquerInstancia(estado.magic) || ExisteOrdemPendenteA0FIX257(estado);
      bool livreProtegidaDemoFIX350=(g_contaDemo && PrimeiraOrdemLivreProtegidaFIX314() && EntradaDiretaDemoEfetivaFIX302());
      bool lockAbandonadoFIX350=(!ocupado && livreProtegidaDemoFIX350 && idade<0);
      if((ocupado || idade<espera) && !lockAbandonadoFIX350)
      {
         estado.ultimaMensagem = "A0 bloqueado: este Magic ja tem A0 reservado, pendente ou executado neste ciclo.";
         g_fix279StatusGeral=estado.ultimaMensagem;
         RegistrarDecisaoOperacional(estado, "A0_LOCK", estado.ultimaMensagem);
         return false;
      }
      GlobalVariableDel(chave);
      RegistrarLogValidacaoSistema("FIX257_LOCK_A0_RECUPERADO",
         StringFormat("Magic %d: lock A0 antigo sem ordem/posicao foi liberado apos %d s.",(int)estado.magic,idade));
   }
   if(!RegistrarLockCiclo(chave))
   {
      estado.ultimaMensagem = "A0 bloqueado: outra janela reservou este Magic agora.";
      g_fix279StatusGeral=estado.ultimaMensagem;
      RegistrarDecisaoOperacional(estado, "A0_LOCK", estado.ultimaMensagem);
      return false;
   }
   return true;
}

bool LockAumentoJaRegistrado(EstadoLado &estado, int idx)
{
   string chave = ChaveLockAumento(estado, idx);
   string chaveOK = ChaveLockAumentoConfirmadoFIX208(estado, idx);
   if(GlobalVariableCheck(chaveOK) && GlobalVariableGet(chaveOK) > 0.0)
      return true;
   if(!GlobalVariableCheck(chave))
      return false;
   double token = GlobalVariableGet(chave);
   if(token <= 0.0)
      return false;
   double volumeEsperado = VolumePlanejadoAteAumentoFIX208(idx);
   if(estado.contratos + 0.0001 >= volumeEsperado || estado.ultimoNivelAumentoUsado >= idx)
   {
      MarcarLockAumentoConfirmadoFIX208(estado, idx);
      return true;
   }
   if(ExisteOrdemPendenteAumentoFIX208(estado, idx))
      return true;
   int espera = InpIntervaloMinimoOrdensSeg;
   if(espera < 3) espera = 3;
   int idade = (int)(TimeCurrent() - (datetime)token);
   if(idade < espera)
      return true;
   GlobalVariableDel(chave);
   estado.motivoBloqueioAumento = StringFormat("A%d: lock pendente sem ordem/volume foi liberado para nova tentativa.", idx);
   RegistrarLogValidacaoSistema("FIX208_LOCK_AUMENTO_RECUPERADO", estado.motivoBloqueioAumento);
   return false;
}

bool RegistrarLockAumento(EstadoLado &estado, int idx)
{
   string chave = ChaveLockAumento(estado, idx);
   if(LockAumentoJaRegistrado(estado, idx))
   {
      estado.motivoBloqueioAumento = StringFormat("A%d ja executado/reservado neste ciclo.", idx);
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      RegistrarDecisaoOperacional(estado, "AUMENTO_LOCK", estado.motivoBloqueioAumento);
      return false;
   }
   if(!RegistrarLockCiclo(chave))
   {
      estado.motivoBloqueioAumento = StringFormat("A%d bloqueado: outra janela reservou este nivel agora.", idx);
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      RegistrarDecisaoOperacional(estado, "AUMENTO_LOCK", estado.motivoBloqueioAumento);
      return false;
   }
   return true;
}

int AumentosExecutadosPlanejadosPorContratos(double contratos)
{
   double total = MathAbs(InpEntradaContratos);
   int feitos = 0;
   for(int i = 0; i < ArraySize(g_aumentos); i++)
   {
      if(!g_aumentos[i].ativa)
         continue;
      total += MathAbs(g_aumentos[i].qtd);
      if(contratos + 0.0001 >= total)
         feitos = i + 1;
   }
   if(feitos > g_gerAumentos.maxAumentos)
      feitos = g_gerAumentos.maxAumentos;
   return feitos;
}

void LimparLocksCicloMagic(long magic)
{
   string prefixo = PrefixoLockCicloMagic(magic);
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string nome = GlobalVariableName(i);
      if(StringFind(nome, prefixo) == 0)
         GlobalVariableDel(nome);
   }
}

#endif // COPA_LOCKS_ORDENS_MQH
