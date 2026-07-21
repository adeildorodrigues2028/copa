#ifndef COPA_COORDENACAO_MAGICS_MQH
#define COPA_COORDENACAO_MAGICS_MQH

// ============================================================================
// RESPONSABILIDADE: COORDENACAO E LOCKS ENTRE MAGICS
// Funcoes movidas do principal na V40 sem alteracao de regra operacional.
// ============================================================================

string PrefixoCoordenacaoMagicsFIX256()
{
   string simbolo=_Symbol;
   StringReplace(simbolo,".","_");
   StringReplace(simbolo,"#","_");
   StringReplace(simbolo," ","_");
   StringReplace(simbolo,"/","_");
   StringReplace(simbolo,"\\","_");
   if(StringLen(simbolo)>14)
      simbolo=StringSubstr(simbolo,0,14);
   long login=AccountInfoInteger(ACCOUNT_LOGIN);
   // FIX320: versoes antigas abertas em outras abas nao podem conservar o
   // registro A/B desta versao e impedir o teste. Instancias FIX320 ainda
   // compartilham este prefixo, portanto somente uma COMPRA e uma VENDA
   // permanecem autorizadas por conta e ativo.
   return "AR320_"+IntegerToString(login)+"_"+simbolo+"_";
}

string ChaveCoordenacaoMagicsFIX256(string campo)
{
   return PrefixoCoordenacaoMagicsFIX256()+campo;
}

long AssinaturaConfiguracaoProducaoFIX342()
{
   string cfg=StringFormat("AMB=%d|SIDE=%d|A0=%d|MC=%d|MV=%d|TF=%d|Q=%d|MG=%d|MB=%d",
                           (int)InpAmbienteExecucaoFIX342,(int)InpLadosHabilitadosFIX346,(int)InpComoAbrirPrimeiraOrdem,
                           (int)InpModoEntradaCompra,(int)InpModoEntradaVenda,
                           (int)InpTimeframeFiltrosOperacionais,InpQuantidadeReforcos,
                           (int)MagicCompraAtual(),(int)MagicVendaAtual());
   cfg+="|A0E="+InpEntradaA0QuantidadeAlvoFIX340+"|A0R="+InpEntradaA0PerdaTrailingFIX340;
   cfg+="|AR="+InpRiscoAumentosFIX340+"|A1="+InpA1ExecucaoFIX340+InpA1TrailingFIX340;
   cfg+="|A2="+InpA2ExecucaoFIX340+InpA2TrailingFIX340+"|A3="+InpA3ExecucaoFIX340+InpA3TrailingFIX340;
   cfg+="|A4="+InpA4ExecucaoFIX340+InpA4TrailingFIX340+"|F="+InpFiltrosProjetoFIX324;
   cfg+=StringFormat("|GH=%.2f|LH=%.2f|SL=%.1f|MAX=%.2f|NET=%.2f|H=%s/%s",
                     GainHeadEfetivoFIX362(),LossHeadEfetivoFIX362(),
                     InpStopServidorEmergenciaPontosFIX342,InpMaxContratosBrutosABFIX342,InpMaxExposicaoLiquidaABFIX342,
                     InpHorarioBloquearNovasOperacoes,InpHorarioFecharTudo);
   cfg+=StringFormat("|R=%d/%d/%.1f/%.1f|G=%d/%d/%.1f/%.1f",
                     InpFiltroRangeAtivoFIX344 ? 1 : 0,(int)InpRangeReferenciaFIX344,
                     InpRangeMinimoPontosFIX344,InpRangeMaximoPontosFIX344,
                     InpGridEntradasAtivoFIX344 ? 1 : 0,(int)InpGridReferenciaFIX344,
                     InpGridTamanhoPontosFIX344,InpGridToleranciaPontosFIX344);
   return HashTextoFIX304(cfg);
}

bool ConfiguracaoParABCompativelFIX342(string &motivo)
{
   motivo="";
   string sufixoLocal=JanelaAtualEhA_FIX255() ? "A" : "B";
   string sufixoOutro=JanelaAtualEhA_FIX255() ? "B" : "A";
   long hashLocal=AssinaturaConfiguracaoProducaoFIX342();
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixoLocal+"CFG"),(double)hashLocal);

   long chartOutro=0;
   datetime hbOutro=0;
   bool outroAtivo=RegistroJanelaAtivoFIX256(!JanelaAtualEhA_FIX255(),chartOutro,hbOutro);
   if(!outroAtivo)
      return true;
   string chaveOutro=ChaveCoordenacaoMagicsFIX256(sufixoOutro+"CFG");
   if(!GlobalVariableCheck(chaveOutro))
   {
      motivo="outra janela ativa ainda nao publicou sua configuracao";
      return false;
   }
   long hashOutro=(long)GlobalVariableGet(chaveOutro);
   if(hashOutro!=hashLocal)
   {
      motivo=StringFormat("parametros A/B diferentes | local %I64d outro %I64d",hashLocal,hashOutro);
      return false;
   }
   return true;
}

datetime AgoraCoordenacaoMagicsFIX256()
{
   datetime agora=TimeLocal();
   if(agora<=0)
      agora=TimeCurrent();
   return agora;
}

bool RegistroJanelaAtivoFIX256(bool janelaA, long &chartId, datetime &heartbeat)
{
   chartId=0;
   heartbeat=0;
   string sufixo=janelaA ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   if(!GlobalVariableCheck(chaveChart) || !GlobalVariableCheck(chaveHB))
      return false;
   chartId=(long)GlobalVariableGet(chaveChart);
   heartbeat=(datetime)GlobalVariableGet(chaveHB);
   datetime agora=AgoraCoordenacaoMagicsFIX256();
   if(chartId<=0 || heartbeat<=0 || agora<heartbeat || (agora-heartbeat)>g_timeoutHeartbeatMagics_FIX256)
      return false;
   return true;
}

bool AdquirirLockCoordenacaoMagicsFIX256()
{
   string chaveLock=ChaveCoordenacaoMagicsFIX256("LOCK");
   string chaveHora=ChaveCoordenacaoMagicsFIX256("LTS");
   if(!GlobalVariableCheck(chaveLock))
      GlobalVariableSet(chaveLock,0.0);

   double token=(double)ChartID();
   datetime agora=AgoraCoordenacaoMagicsFIX256();

   // FIX283: recupera trava abandonada, mas nunca bloqueia a thread do EA com Sleep.
   if(GlobalVariableCheck(chaveHora))
   {
      datetime horaLock=(datetime)GlobalVariableGet(chaveHora);
      if(horaLock>0 && agora>=horaLock && (agora-horaLock)>5)
         GlobalVariableSet(chaveLock,0.0);
   }

   if(!GlobalVariableSetOnCondition(chaveLock,token,0.0))
      return false;

   GlobalVariableSet(chaveHora,(double)agora);
   return true;
}

void LiberarLockCoordenacaoMagicsFIX256()
{
   string chaveLock=ChaveCoordenacaoMagicsFIX256("LOCK");
   string chaveHora=ChaveCoordenacaoMagicsFIX256("LTS");
   double token=(double)ChartID();
   if(GlobalVariableCheck(chaveLock) && GlobalVariableGet(chaveLock)==token)
      GlobalVariableSet(chaveLock,0.0);
   GlobalVariableSet(chaveHora,0.0);
}

bool RegistrarCoordenacaoMagicsFIX256(string &motivo)
{
   motivo="";
   if(!AdquirirLockCoordenacaoMagicsFIX256())
   {
      motivo="Nao foi possivel obter a trava de sincronizacao dos Magics.";
      return false;
   }

   bool janelaA=JanelaAtualEhA_FIX255();
   long chartAtual=ChartID();
   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);

   if(janelaA && ativoA && chartA!=chartAtual)
   {
      motivo="Ja existe outra JANELA A/COMPRA ativa neste ativo e conta.";
      LiberarLockCoordenacaoMagicsFIX256();
      return false;
   }
   if(!janelaA && ativoB && chartB!=chartAtual)
   {
      motivo="Ja existe outra JANELA B/VENDA ativa neste ativo e conta.";
      LiberarLockCoordenacaoMagicsFIX256();
      return false;
   }

   string sufixo=janelaA ? "A" : "B";
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"CH"),(double)chartAtual);
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"HB"),(double)AgoraCoordenacaoMagicsFIX256());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"MA"),(double)MagicCompraAtual());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"MB"),(double)MagicVendaAtual());
   GlobalVariableSet(ChaveCoordenacaoMagicsFIX256(sufixo+"CFG"),(double)AssinaturaConfiguracaoProducaoFIX342());

   if(janelaA ||
      !GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("MA")) ||
      !GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("MB")))
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)MagicCompraAtual());
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)MagicVendaAtual());
   }

   LiberarLockCoordenacaoMagicsFIX256();
   AtualizarCoordenacaoMagicsFIX256(true);
   return true;
}

void AtualizarCoordenacaoMagicsFIX256(bool forcar)
{
   datetime agora=AgoraCoordenacaoMagicsFIX256();
   if(!forcar && g_ultimoHeartbeatMagics_FIX256>0 && (agora-g_ultimoHeartbeatMagics_FIX256)<1)
      return;
   g_ultimoHeartbeatMagics_FIX256=agora;

   bool janelaA=JanelaAtualEhA_FIX255();
   string sufixo=janelaA ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   string chaveMA=ChaveCoordenacaoMagicsFIX256(sufixo+"MA");
   string chaveMB=ChaveCoordenacaoMagicsFIX256(sufixo+"MB");
   string chaveCFG=ChaveCoordenacaoMagicsFIX256(sufixo+"CFG");

   bool donoRegistro=(GlobalVariableCheck(chaveChart) &&
                      (long)GlobalVariableGet(chaveChart)==ChartID());
   if(donoRegistro)
   {
      GlobalVariableSet(chaveHB,(double)agora);
      GlobalVariableSet(chaveMA,(double)MagicCompraAtual());
      GlobalVariableSet(chaveMB,(double)MagicVendaAtual());
      GlobalVariableSet(chaveCFG,(double)AssinaturaConfiguracaoProducaoFIX342());
   }

   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);

   bool parAExiste=(GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("AMA")) &&
                    GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("AMB")));
   bool parBExiste=(GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("BMA")) &&
                    GlobalVariableCheck(ChaveCoordenacaoMagicsFIX256("BMB")));
   long magicAA=parAExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("AMA")) : 0;
   long magicAB=parAExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("AMB")) : 0;
   long magicBA=parBExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("BMA")) : 0;
   long magicBB=parBExiste ? (long)GlobalVariableGet(ChaveCoordenacaoMagicsFIX256("BMB")) : 0;

   if(ativoA && parAExiste)
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)magicAA);
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)magicAB);
   }
   else if(ativoB && parBExiste)
   {
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MA"),(double)magicBA);
      GlobalVariableSet(ChaveCoordenacaoMagicsFIX256("MB"),(double)magicBB);
   }

   bool registroLocal=(janelaA ? (ativoA && chartA==ChartID()) : (ativoB && chartB==ChartID()));
   bool publicacaoLocalOK=(janelaA ?
                           (parAExiste && magicAA==MagicCompraAtual() && magicAB==MagicVendaAtual()) :
                           (parBExiste && magicBA==MagicCompraAtual() && magicBB==MagicVendaAtual()));
   bool paresIguais=(parAExiste && parBExiste && magicAA==magicBA && magicAB==magicBB);

   // FIX320: cada lado tem vida propria. A autorizacao local depende somente
   // do registro e dos Magics desta janela; o lado oposto nunca bloqueia.
   bool outraJanelaAtiva = janelaA ? ativoB : ativoA;
   bool parOutraExiste   = janelaA ? parBExiste : parAExiste;
   bool compatibilidadeOutra = true;
   g_coordenacaoMagicsOK_FIX256=(registroLocal && publicacaoLocalOK);

   if(g_coordenacaoMagicsOK_FIX256)
   {
      if(ativoA && ativoB)
         g_statusCoordenacaoMagics_FIX256=StringFormat("LADOS INDEPENDENTES | A=BUY M%d | B=SELL M%d",(int)MagicCompraAtual(),(int)MagicVendaAtual());
      else
         g_statusCoordenacaoMagics_FIX256=StringFormat("LOCAL OK | %s | outro lado opcional",NomeJanelaInstanciaFIX255());
   }
   else if(!registroLocal)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: ja existe outra janela com o mesmo papel A/B";
   else if(!publicacaoLocalOK)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: atualizando o novo Magic desta janela";
   else if(outraJanelaAtiva && !parOutraExiste)
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: publicacao da outra janela incompleta";
   else if(outraJanelaAtiva && !paresIguais)
      g_statusCoordenacaoMagics_FIX256=StringFormat("BLOQUEADO: Magics diferentes | Janela A %d/%d | Janela B %d/%d",
                                                   (int)magicAA,(int)magicAB,(int)magicBA,(int)magicBB);
   else
      g_statusCoordenacaoMagics_FIX256="BLOQUEADO: sincronizacao local incompleta";
}

void DesregistrarCoordenacaoMagicsFIX256()
{
   if(!AdquirirLockCoordenacaoMagicsFIX256())
      return;

   string sufixo=JanelaAtualEhA_FIX255() ? "A" : "B";
   string chaveChart=ChaveCoordenacaoMagicsFIX256(sufixo+"CH");
   string chaveHB=ChaveCoordenacaoMagicsFIX256(sufixo+"HB");
   string chaveMA=ChaveCoordenacaoMagicsFIX256(sufixo+"MA");
   string chaveMB=ChaveCoordenacaoMagicsFIX256(sufixo+"MB");
   string chaveCFG=ChaveCoordenacaoMagicsFIX256(sufixo+"CFG");

   if(GlobalVariableCheck(chaveChart) && (long)GlobalVariableGet(chaveChart)==ChartID())
   {
      GlobalVariableDel(chaveChart);
      if(GlobalVariableCheck(chaveHB)) GlobalVariableDel(chaveHB);
      if(GlobalVariableCheck(chaveMA)) GlobalVariableDel(chaveMA);
      if(GlobalVariableCheck(chaveMB)) GlobalVariableDel(chaveMB);
      if(GlobalVariableCheck(chaveCFG)) GlobalVariableDel(chaveCFG);
   }

   long chartA=0,chartB=0;
   datetime hbA=0,hbB=0;
   bool ativoA=RegistroJanelaAtivoFIX256(true,chartA,hbA);
   bool ativoB=RegistroJanelaAtivoFIX256(false,chartB,hbB);
   if(!ativoA && !ativoB)
   {
      string chaves[6]={ChaveCoordenacaoMagicsFIX256("MA"),
                        ChaveCoordenacaoMagicsFIX256("MB"),
                        ChaveCoordenacaoMagicsFIX256("AMA"),
                        ChaveCoordenacaoMagicsFIX256("AMB"),
                        ChaveCoordenacaoMagicsFIX256("BMA"),
                        ChaveCoordenacaoMagicsFIX256("BMB")};
      for(int i=0;i<6;i++)
         if(GlobalVariableCheck(chaves[i])) GlobalVariableDel(chaves[i]);
   }

   LiberarLockCoordenacaoMagicsFIX256();
   g_coordenacaoMagicsOK_FIX256=false;
}

bool CoordenacaoPermiteNovaOrdemFIX256(EstadoLado &estado, string contexto)
{
   string motivoMagic="";
   if(!ValidarMagicsConfiguradosFIX252(motivoMagic))
   {
      RegistrarGerenciadorOrdens(estado,contexto,contexto+" bloqueado: "+motivoMagic,0,0,0.0,0.0,true);
      return false;
   }

   // FIX350: A0 LIVRE PROTEGIDA em DEMO nao depende do registro visual A/B.
   // Duas abas podem chegar aqui ao mesmo tempo, mas somente uma consegue adquirir
   // o lock global A0 por conta/simbolo/Magic antes do OrderSend.
   bool contextoA0DiretoFIX350=(StringFind(contexto,"A0 DIRETO")>=0);
   bool livreProtegidaDemoFIX350=(g_contaDemo && PrimeiraOrdemLivreProtegidaFIX314() &&
                                  EntradaDiretaDemoEfetivaFIX302() && contextoA0DiretoFIX350);
   if(livreProtegidaDemoFIX350)
      return true;

   AtualizarCoordenacaoMagicsFIX256(false);

   // FIX288: nunca ignorar a coordenacao no modo direto normal/real.
   // Uma unica janela local e permitida; duas janelas do mesmo papel ou pares diferentes sao bloqueados.
   if(g_coordenacaoMagicsOK_FIX256)
      return true;

   // No teste direto, uma aba proprietaria antiga nao pode parar o projeto.
   // A0 avanca protegida pelo lock global do Magic. A1-A5 chegam aqui apenas
   // depois de adquirir o lock global especifico do nivel/ciclo; portanto a
   // liberacao da suplente nao duplica contratos.
   bool contextoA0DiretoFIX322=(StringFind(contexto,"A0 DIRETO")>=0);
   bool contextoAumentoComLockFIX322=(StringFind(contexto,"Aumento A")>=0);
   bool mesmoPapelSuplenteFIX322=(StringFind(g_statusCoordenacaoMagics_FIX256,
                                             "mesmo papel A/B")>=0);
   // FIX322: A1-A5 ja chegam aqui com lock global do nivel/ciclo adquirido.
   // Liberar a janela que possui a posicao nao ignora timer, linha, candle ou filtros:
   // todas essas regras foram validadas antes de ExecutarAumento. O lock impede duplicidade.
   bool testeSuplenteProtegidoFIX320=(mesmoPapelSuplenteFIX322 &&
                                      ((EntradaDiretaDemoEfetivaFIX302() && contextoA0DiretoFIX322) ||
                                       contextoAumentoComLockFIX322));
   if(testeSuplenteProtegidoFIX320)
      return true;

   RegistrarGerenciadorOrdens(estado,contexto,
      contexto+" bloqueado: "+g_statusCoordenacaoMagics_FIX256,
      0,0,0.0,0.0,true);
   return false;
}


#endif // COPA_COORDENACAO_MAGICS_MQH
