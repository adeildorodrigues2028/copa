#ifndef COPA_MENSAGENS_FIM_DIA_MQH
#define COPA_MENSAGENS_FIM_DIA_MQH

// ============================================================================
// RESPONSABILIDADE: MENSAGENS VISUAIS E ENCERRAMENTO DO DIA
// Funcoes movidas do principal na V41 sem alteracao de regra operacional.
// ============================================================================

void DispararMsgBoxVisualFIX226(string titulo, string linha1, string linha2)
{
   // FIX415: nenhuma caixa visual. Mantém auditoria somente nos logs Experts.
   if(titulo!="" || linha1!="" || linha2!="")
      Print("[COPA_AR100][FIX415][AUDITORIA_SEM_MSGBOX] ",titulo," | ",linha1," | ",linha2);
   g_msgBoxVisualHoraFIX226=0;
   g_msgBoxVisualTituloFIX226="";
   g_msgBoxVisualLinha1FIX226="";
   g_msgBoxVisualLinha2FIX226="";
}

bool MsgBoxVisualAtivaFIX226()
{
   // FIX415: desligada de forma definitiva para impedir amarelo/pisca no painel.
   return false;
}

void LimparMsgBoxVisualFIX226(string pfx)
{
   ObjectDelete(0,pfx+"_BG");
   ObjectDelete(0,pfx+"_TIT");
   ObjectDelete(0,pfx+"_MSG");
   ObjectDelete(0,pfx+"_SCORE");
}

void AvaliarEventoMsgBoxFIX226(string contexto, string mensagem, bool importante)
{
   // FIX408: nenhuma entrada, aumento, parcial, saída, stop ou proteção gera
   // caixa visual temporária. O processamento e os logs permanecem ativos.
   return;
}

void AtualizarEstadoFimDiaFIX215()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   dt.hour=0;
   dt.min=0;
   dt.sec=0;
   datetime inicioDia=StructToTime(dt);
   if(g_fimDiaDataReferenciaFIX215==inicioDia)
      return;
   g_fimDiaDataReferenciaFIX215=inicioDia;
   g_fimDiaUltimaTentativaFIX215=0;
   g_fimDiaEncerradoFIX215=false;
   g_fimDiaAvisoBloqueioFIX215=false;
   g_msgBoxVisualHoraFIX226=0;
   g_msgBoxVisualTituloFIX226="";
   g_msgBoxVisualLinha1FIX226="";
   g_msgBoxVisualLinha2FIX226="";
}

bool BloquearNovasOperacoesFimDiaFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!InpFechamentoFimDiaAtivo)
      return false;
   int minutoBloqueio=HorarioParaMinutos(InpHorarioBloquearNovasOperacoes);
   int minutoAgora=MinutoAtualDoDia();
   return (minutoAgora>=minutoBloqueio);
}

bool HorarioFechamentoObrigatorioFIX215()
{
   AtualizarEstadoFimDiaFIX215();
   if(!InpFechamentoFimDiaAtivo)
      return false;
   int minutoFechamento=HorarioParaMinutos(InpHorarioFecharTudo);
   int minutoAgora=MinutoAtualDoDia();
   return (minutoAgora>=minutoFechamento);
}

string TextoStatusFimDiaFIX215()
{
   if(!InpFechamentoFimDiaAtivo)
      return "FIM DIA OFF";
   if(HorarioFechamentoObrigatorioFIX215())
      return g_fimDiaEncerradoFIX215 ? "DIA ENCERRADO | ZERADO" : "FECHANDO TUDO AGORA";
   if(BloquearNovasOperacoesFimDiaFIX215())
      return StringFormat("NOVAS ORDENS BLOQUEADAS | FECHA %s",InpHorarioFecharTudo);
   return StringFormat("OPERA ATE %s | FECHA %s",InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
}


#endif // COPA_MENSAGENS_FIM_DIA_MQH
