#ifndef COPA_CONTROLE_OPERACAO_MQH
#define COPA_CONTROLE_OPERACAO_MQH

// ============================================================================
// RESPONSABILIDADE: CONTROLE MANUAL E FECHAMENTO DA OPERACAO
// Funcoes movidas do principal na V41 sem alteracao de regra operacional.
// ============================================================================

string ChaveControleMagicFIX285(long magic)
{
   return StringFormat("AR5CTL_%I64d_%s_%I64d",
                       AccountInfoInteger(ACCOUNT_LOGIN),
                       _Symbol,
                       magic);
}

long MagicControleLocalFIX285()
{
   return MagicOperacionalInstanciaFIX255();
}

string ChaveControleOperacaoFIX284()
{
   return ChaveControleMagicFIX285(MagicControleLocalFIX285());
}

string NomeLadoControleMagicFIX285(long magic)
{
   if(magic == MagicCompraAtual())
      return "COMPRA";
   if(magic == MagicVendaAtual())
      return "VENDA";
   return "MAGIC " + IntegerToString((int)magic);
}

ENUM_CONTROLE_OPERACAO_FIX284 EstadoControleMagicFIX285(long magic)
{
   if(magic == MagicControleLocalFIX285())
   {
      SincronizarControleOperacaoFIX284(false);
      return g_controleOperacaoFIX284;
   }

   string chave = ChaveControleMagicFIX285(magic);
   if(!GlobalVariableCheck(chave))
   {
      GlobalVariableSet(chave, (double)CONTROLE_OPERACAO_ATIVO_FIX284);
      return CONTROLE_OPERACAO_ATIVO_FIX284;
   }

   int valor = (int)MathRound(GlobalVariableGet(chave));
   if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
      valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
   return (ENUM_CONTROLE_OPERACAO_FIX284)valor;
}

bool ControleBloqueiaMagicFIX285(long magic)
{
   return (EstadoControleMagicFIX285(magic) != CONTROLE_OPERACAO_ATIVO_FIX284);
}

string TextoControleMagicFIX285(long magic)
{
   ENUM_CONTROLE_OPERACAO_FIX284 estado = EstadoControleMagicFIX285(magic);
   string lado = NomeLadoControleMagicFIX285(magic);
   if(estado == CONTROLE_OPERACAO_PAUSADO_FIX284)
      return lado + " PAUSADA";
   if(estado == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return lado + " ENCERRADA";
   return lado + " ATIVA";
}

string TextoControleOperacaoFIX284()
{
   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_PAUSADO_FIX284)
      return lado + " PAUSADA";
   if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return lado + " ENCERRADA";
   return lado + " ATIVA";
}

bool ExistePosicaoAbertaControleLocalFIX285()
{
   long magicLocal = MagicControleLocalFIX285();
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) == magicLocal)
         return true;
   }
   return false;
}

bool FecharPosicoesControleLocalFIX285(string motivo)
{
   AtualizarEstadosDePosicao();
   long magicLocal = MagicControleLocalFIX285();
   EstadoLado estadoLocal;
   if(JanelaAtualEhA_FIX255())
      estadoLocal = g_compra;
   else
      estadoLocal = g_venda;

   // Botao de encerramento e uma saida de seguranca: tenta fechar mesmo se entradas estiverem travadas.
   // Se o terminal/servidor nao permitir negociacao, o proprio OrderSend retorna o erro no log.
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estadoLocal))
         continue;

      long tipo = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         continue;

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action = TRADE_ACTION_DEAL;
      req.position = ticket;
      req.symbol = _Symbol;
      req.volume = NormalizarVolume(volume);
      req.magic = (ulong)magicLocal;
      req.deviation = InpDesvioMaximoPontos;
      req.type_time = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " ENCERRAR LOCAL " + motivo,req.magic);

      if(tipo == POSITION_TYPE_BUY)
      {
         req.type = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(tipo == POSITION_TYPE_SELL)
      {
         req.type = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;

      encontrou = true;
      ResetLastError();
      bool enviado = OrderSend(req, res);
      if(enviado && (res.retcode == TRADE_RETCODE_DONE ||
                     res.retcode == TRADE_RETCODE_PLACED ||
                     res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         RegistrarGerenciadorOrdens(estadoLocal, "FIX285_ENCERRAR_LOCAL_OK",
                                    StringFormat("Magic %d | Ticket %I64u | Volume %.2f | %s",
                                                 (int)magicLocal, ticket, req.volume, motivo),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int erro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estadoLocal, "FIX285_ENCERRAR_LOCAL_ERRO",
                                    StringFormat("Magic %d | Ticket %I64u | Retcode %d | Erro %d",
                                                 (int)magicLocal, ticket, (int)res.retcode, erro),
                                    res.retcode, erro, req.volume, req.price, true);
      }
   }
   return (!encontrou || tudoOk);
}

void InicializarControleOperacaoFIX284()
{
   string chave = ChaveControleOperacaoFIX284();
   if(GlobalVariableCheck(chave))
   {
      int valor = (int)MathRound(GlobalVariableGet(chave));
      if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
         valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
      g_controleOperacaoFIX284 = (ENUM_CONTROLE_OPERACAO_FIX284)valor;
   }
   else
   {
      g_controleOperacaoFIX284 = CONTROLE_OPERACAO_ATIVO_FIX284;
      GlobalVariableSet(chave, (double)g_controleOperacaoFIX284);
   }
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
   g_ultimaSincronizacaoControleMsFIX284 = GetTickCount64();
}

void SincronizarControleOperacaoFIX284(bool forcar)
{
   ulong agoraMs = GetTickCount64();
   if(!forcar && g_ultimaSincronizacaoControleMsFIX284 > 0 &&
      agoraMs >= g_ultimaSincronizacaoControleMsFIX284 &&
      (agoraMs - g_ultimaSincronizacaoControleMsFIX284) < 250)
      return;

   g_ultimaSincronizacaoControleMsFIX284 = agoraMs;
   string chave = ChaveControleOperacaoFIX284();
   if(!GlobalVariableCheck(chave))
   {
      GlobalVariableSet(chave, (double)g_controleOperacaoFIX284);
      return;
   }
   int valor = (int)MathRound(GlobalVariableGet(chave));
   if(valor < (int)CONTROLE_OPERACAO_ATIVO_FIX284 || valor > (int)CONTROLE_OPERACAO_ENCERRADO_FIX284)
      valor = (int)CONTROLE_OPERACAO_ATIVO_FIX284;
   g_controleOperacaoFIX284 = (ENUM_CONTROLE_OPERACAO_FIX284)valor;
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
}

void DefinirControleOperacaoFIX284(ENUM_CONTROLE_OPERACAO_FIX284 novoEstado, string motivo)
{
   g_controleOperacaoFIX284 = novoEstado;
   GlobalVariableSet(ChaveControleOperacaoFIX284(), (double)novoEstado);
   g_ultimaSincronizacaoControleMsFIX284 = GetTickCount64();
   g_statusControleOperacaoFIX284 = TextoControleOperacaoFIX284();
   g_ultimaAtualizacaoPainelVisual = 0;

   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   string mensagem = StringFormat("FIX285 CONTROLE %s | Magic %d | %s",
                                  g_statusControleOperacaoFIX284,
                                  (int)MagicControleLocalFIX285(),
                                  motivo);
   g_mestre.mensagemGeral = mensagem;
   RegistrarLogValidacaoSistema("FIX285_CONTROLE_LOCAL", mensagem);

   if(novoEstado == CONTROLE_OPERACAO_PAUSADO_FIX284)
      DispararMsgBoxVisualFIX226(lado + " PAUSADA", "NOVAS ENTRADAS E AUMENTOS DESTE LADO BLOQUEADOS", "TRAILING, ALVO, STOP E PARCIAIS CONTINUAM");
   else if(novoEstado == CONTROLE_OPERACAO_ENCERRADO_FIX284)
      DispararMsgBoxVisualFIX226("ENCERRAR " + lado, "FECHANDO SOMENTE O MAGIC " + IntegerToString((int)MagicControleLocalFIX285()), "O OUTRO LADO CONTINUA NORMALMENTE");
   else
      DispararMsgBoxVisualFIX226(lado + " ATIVA", "NOVAS ENTRADAS E AUMENTOS DESTE LADO LIBERADOS", "O OUTRO LADO NAO FOI ALTERADO");
}



bool ProcessarEncerramentoManualFIX284(bool forcar)
{
   SincronizarControleOperacaoFIX284(false);
   if(g_controleOperacaoFIX284 != CONTROLE_OPERACAO_ENCERRADO_FIX284)
      return false;

   string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
   if(!ExistePosicaoAbertaControleLocalFIX285())
   {
      g_statusControleOperacaoFIX284 = lado + " ENCERRADA | ZERADA";
      return false;
   }

   int intervalo = InpFIX284IntervaloFechamentoMs;
   if(intervalo < 500)
      intervalo = 500;
   ulong agoraMs = GetTickCount64();
   if(!forcar && g_ultimaTentativaEncerrarMsFIX284 > 0 &&
      agoraMs >= g_ultimaTentativaEncerrarMsFIX284 &&
      (agoraMs - g_ultimaTentativaEncerrarMsFIX284) < (ulong)intervalo)
      return true;

   g_ultimaTentativaEncerrarMsFIX284 = agoraMs;
   g_fechamentoManualEmAndamentoFIX284 = true;
   bool ok = FecharPosicoesControleLocalFIX285("BOTAO_ENCERRAR_LOCAL_FIX285");
   g_fechamentoManualEmAndamentoFIX284 = false;

   if(ok)
      g_mestre.mensagemGeral = StringFormat("FIX285: encerramento da %s enviado para o Magic %d; aguardando servidor.", lado, (int)MagicControleLocalFIX285());
   else
      g_mestre.mensagemGeral = StringFormat("FIX285: fechamento da %s ainda pendente; nova tentativa sera somente neste Magic.", lado);
   return true;
}

bool PainelCliqueControleOperacaoFIX284(string objeto)
{
   if(StringFind(objeto, "CTRL_PAUSA_FIX284") >= 0)
   {
      SincronizarControleOperacaoFIX284(true);
      if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ATIVO_FIX284)
      {
         DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_PAUSADO_FIX284, "clique no botao PAUSAR LOCAL");
      }
      else if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_PAUSADO_FIX284)
      {
         DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ATIVO_FIX284, "clique no botao RETOMAR LOCAL");
      }
      else
      {
         AtualizarEstadosDePosicao();
         if(ExistePosicaoAbertaControleLocalFIX285())
         {
            string lado = NomeLadoControleMagicFIX285(MagicControleLocalFIX285());
            g_mestre.mensagemGeral = "FIX285: aguarde somente a " + lado + " ficar zerada antes de reativar.";
            DispararMsgBoxVisualFIX226("REATIVACAO LOCAL BLOQUEADA", "AINDA EXISTE POSICAO DESTE MAGIC", "O OUTRO LADO NAO INTERFERE NESTA REATIVACAO");
         }
         else
         {
            DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ATIVO_FIX284, "clique no botao REATIVAR LOCAL");
         }
      }
      return true;
   }

   if(StringFind(objeto, "CTRL_ENCERRAR_FIX284") >= 0)
   {
      DefinirControleOperacaoFIX284(CONTROLE_OPERACAO_ENCERRADO_FIX284, "clique no botao ENCERRAR LOCAL");
      AtualizarEstadosDePosicao();
      ProcessarEncerramentoManualFIX284(true);
      return true;
   }
   return false;
}

bool ProcessarFechamentoFimDiaFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!HorarioFechamentoObrigatorioFIX215())
      return false;

   if(!ExistePosicaoAbertaGrupoTotalAB())
   {
      if(!g_fimDiaEncerradoFIX215)
      {
         g_fimDiaEncerradoFIX215=true;
         g_mestre.mensagemGeral="FIX226 FIM DO DIA: todas as posicoes foram encerradas e o grupo esta zerado.";
         RegistrarLogValidacaoSistema("FIX226_FIM_DIA_ZERADO",g_mestre.mensagemGeral);
         DispararMsgBoxVisualFIX226(
            StringFormat("FIM DO DIA %s",InpHorarioFecharTudo),
            "POSICOES ENCERRADAS | GRUPO ZERADO",
            "DIA FINALIZADO | NOVAS ORDENS SO NO PROXIMO DIA");
      }
      return true;
   }

   int intervalo=InpFimDiaIntervaloTentativaSegundos;
   if(intervalo<1)
      intervalo=1;
   datetime agora=TimeCurrent();
   if(g_fimDiaUltimaTentativaFIX215>0 && (agora-g_fimDiaUltimaTentativaFIX215)<intervalo)
      return true;

   g_fimDiaUltimaTentativaFIX215=agora;
   g_mestre.mensagemGeral=StringFormat("FIX226 FIM DO DIA: fechando todos os tickets. Limite %s.",InpHorarioFecharTudo);
   RegistrarLogValidacaoSistema("FIX226_FIM_DIA_FECHAR_TUDO",g_mestre.mensagemGeral);
   FecharCestaABOficial("FIM_DIA_FIX215_1815");
   return true;
}



#endif // COPA_CONTROLE_OPERACAO_MQH
