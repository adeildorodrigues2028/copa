#ifndef COPA_IDENTIDADE_CICLO_MQH
#define COPA_IDENTIDADE_CICLO_MQH

// ============================================================================
// RESPONSABILIDADE: IDENTIDADE PERSISTENTE E CICLOS DOS MAGICS
// Funcoes movidas do principal na V40 sem alteracao de regra operacional.
// ============================================================================

bool ValidarMagicsConfiguradosFIX252(string &motivo)
{
   long magicA = MagicCompraAtual();
   long magicB = MagicVendaAtual();
   motivo = "";
   if(magicA <= 0 || magicB <= 0)
   {
      motivo = StringFormat("Magic invalido: A=%d B=%d. Ambos precisam ser maiores que zero.", (int)magicA, (int)magicB);
      return false;
   }
   if(magicA == magicB)
   {
      motivo = StringFormat("Magic duplicado: A e B usam %d. Compra e venda precisam de identificadores diferentes.", (int)magicA);
      return false;
   }
   return true;
}


string ChaveIdentidadeBaseFIX304()
{
   string servidor=AccountInfoString(ACCOUNT_SERVER);
   string bruto=IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN))+"|"+servidor+"|"+_Symbol+"|"+
                IntegerToString((int)MagicCompraAtual())+"|"+IntegerToString((int)MagicVendaAtual());
   return "AR304_"+Base36FIX304(HashTextoFIX304(bruto),8);
}

string RecuperarGeracaoHistoricoFIX311()
{
   datetime fim=AgoraServidorHistorico()+86400;
   if(!HistorySelect(0,fim))
      return "";
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) continue;
      long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
      if(magic!=MagicCompraAtual() && magic!=MagicVendaAtual()) continue;
      string geracao=ExtrairGeracaoComentarioFIX304(HistoryDealGetString(deal,DEAL_COMMENT));
      if(geracao!="") return geracao;
   }
   return "";
}

string RecuperarGeracaoPosicoesFIX304()
{
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic!=MagicCompraAtual() && magic!=MagicVendaAtual() && magic!=MagicPainelAAtual() && magic!=MagicPainelBAtual()) continue;
      string g=ExtrairGeracaoComentarioFIX304(PositionGetString(POSITION_COMMENT));
      if(g!="") return g;
   }
   return "";
}

void InicializarIdentidadeUnicaFIX304()
{
   if(g_identidadeInicializadaFIX304) return;
   g_identidadeChaveBaseFIX304=ChaveIdentidadeBaseFIX304();
   g_identidadeChaveGeracaoFIX304=g_identidadeChaveBaseFIX304+"_GEN";
   g_identidadeChaveHeartbeatAFIX304=g_identidadeChaveBaseFIX304+"_HBA";
   g_identidadeChaveHeartbeatBFIX304=g_identidadeChaveBaseFIX304+"_HBB";
   g_identidadeGrupoFIX304="H"+Base36FIX304(HashTextoFIX304(g_identidadeChaveBaseFIX304),6);

   string manual=InpIDInstanciaRobo;
   StringTrimLeft(manual); StringTrimRight(manual);
   string recuperadaPosicao=RecuperarGeracaoPosicoesFIX304();
   long numeroPersistido=GlobalVariableCheck(g_identidadeChaveGeracaoFIX304)
                         ? (long)GlobalVariableGet(g_identidadeChaveGeracaoFIX304) : 0;

   if(manual!="")
   {
      numeroPersistido=HashTextoFIX304(manual+"|"+g_identidadeChaveBaseFIX304);
      g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
      GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }
   else if(numeroPersistido>0)
   {
      // FIX311: a geracao persistida e reutilizada mesmo quando as duas janelas e o MT5 foram fechados.
      g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
   }
   else if(recuperadaPosicao!="")
   {
      g_identidadeGeracaoFIX304=recuperadaPosicao;
      numeroPersistido=Base36ParaLongFIX311(recuperadaPosicao);
      if(numeroPersistido>0)
         GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }
   else
   {
      string recuperadaHistorico=RecuperarGeracaoHistoricoFIX311();
      if(recuperadaHistorico!="")
      {
         g_identidadeGeracaoFIX304=recuperadaHistorico;
         numeroPersistido=Base36ParaLongFIX311(recuperadaHistorico);
      }
      if(numeroPersistido<=0)
      {
         // Deterministico: mesma conta/servidor/simbolo/par de Magics recebe sempre a mesma identidade.
         numeroPersistido=HashTextoFIX304(g_identidadeChaveBaseFIX304+"|FIX311_ESTAVEL");
         g_identidadeGeracaoFIX304="G"+Base36FIX304(numeroPersistido,6);
      }
      GlobalVariableSet(g_identidadeChaveGeracaoFIX304,(double)numeroPersistido);
   }

   g_identidadeInicializadaFIX304=true;
   AtualizarHeartbeatIdentidadeFIX304();
   g_identidadeCicloLocalFIX304=CicloAtualMagicFIX304(MagicOperacionalInstanciaFIX255(),false);
   Print("[AR100][FIX311][IDENTIDADE_ESTAVEL] grupo=",g_identidadeGrupoFIX304,
         " | geracao=",g_identidadeGeracaoFIX304,
         " | A=",IntegerToString((int)MagicCompraAtual()),
         " | B=",IntegerToString((int)MagicVendaAtual()),
         " | janela=",NomeJanelaInstanciaFIX255());
}

void AtualizarHeartbeatIdentidadeFIX304()
{
   if(!g_identidadeInicializadaFIX304) return;
   string chave=JanelaAtualEhA_FIX255() ? g_identidadeChaveHeartbeatAFIX304 : g_identidadeChaveHeartbeatBFIX304;
   if(chave!="") GlobalVariableSet(chave,(double)TimeLocal());
}

void EncerrarHeartbeatIdentidadeFIX304()
{
   if(!g_identidadeInicializadaFIX304) return;
   string chave=JanelaAtualEhA_FIX255() ? g_identidadeChaveHeartbeatAFIX304 : g_identidadeChaveHeartbeatBFIX304;
   if(chave!="") GlobalVariableSet(chave,0.0);
}

string NovoCicloMagicFIX304(long magic)
{
   string chave=g_identidadeChaveBaseFIX304+"_"+g_identidadeGeracaoFIX304+"_M"+IntegerToString((int)magic)+"_SEQ";
   long seq=GlobalVariableCheck(chave) ? (long)GlobalVariableGet(chave) : 0;
   seq++;
   if(seq>46655) seq=1;
   GlobalVariableSet(chave,(double)seq);
   return "C"+Base36FIX304(seq,3);
}

string CicloAtualMagicFIX304(long magic,bool criarSeNecessario)
{
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      string cmt=PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt,"#I"+g_identidadeGeracaoFIX304)<0) continue;
      string ciclo=ExtrairCicloComentarioFIX304(cmt);
      if(ciclo!="")
      {
         if(magic==MagicOperacionalInstanciaFIX255()) g_identidadeCicloLocalFIX304=ciclo;
         return ciclo;
      }
   }
   if(magic==MagicOperacionalInstanciaFIX255() && g_identidadeCicloLocalFIX304!="")
      return g_identidadeCicloLocalFIX304;
   if(!criarSeNecessario) return "";
   string novo=NovoCicloMagicFIX304(magic);
   if(magic==MagicOperacionalInstanciaFIX255()) g_identidadeCicloLocalFIX304=novo;
   return novo;
}

void EncerrarCicloIdentidadeLocalFIX304()
{
   g_identidadeCicloLocalFIX304="";
}

bool ComentarioTemIdentidadeAtualFIX304(string comentario,long magic)
{
   if(g_identidadeGeracaoFIX304=="") return false;
   if(StringFind(comentario,"#I"+g_identidadeGeracaoFIX304)<0) return false;
   if(StringFind(comentario,"|M"+IntegerToString((int)magic))<0) return false;
   if(ExtrairCicloComentarioFIX304(comentario)=="") return false;
   return true;
}

string ComentarioComIdentidadeMagicFIX304(string comentarioBase,long magic)
{
   if(!g_identidadeInicializadaFIX304) InicializarIdentidadeUnicaFIX304();
   string marcador=MarcadorComentarioOperacionalFIX252(comentarioBase);
   bool precisaCiclo=(StringFind(marcador,"|A")>=0 || StringFind(marcador,"|PC")>=0 || StringFind(marcador,"|PR")>=0 || StringFind(marcador,"|OUT")>=0);
   string ciclo=CicloAtualMagicFIX304(magic,precisaCiclo);
   if(ciclo=="") ciclo="C000";
   string c="#I"+g_identidadeGeracaoFIX304+"|M"+IntegerToString((int)magic)+"|"+ciclo+marcador;
   if(StringLen(c)>31) c=StringSubstr(c,0,31);
   return c;
}

int ContarPosicoesMagicFIX304(long magic,double &contratos)
{
   contratos=0.0;
   int qtd=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if(!PosicaoSelecionadaPertencePainelFIX316(magic)) continue;
      qtd++;
      contratos+=PositionGetDouble(POSITION_VOLUME);
   }
   return qtd;
}

string IDInstanciaAtual()
{
   if(!g_identidadeInicializadaFIX304) InicializarIdentidadeUnicaFIX304();
   return g_identidadeGeracaoFIX304;
}


string MarcadorComentarioOperacionalFIX252(string comentarioBase)
{
   string c = Upper(comentarioBase);
   int nivel = NivelAumentoComentarioFIX207(c);
   bool parcial = (StringFind(c, "PARCIAL") >= 0 || StringFind(c, "PARC_") >= 0);
   bool protecao = (StringFind(c, "PROTECAO") >= 0);
   bool saida = (StringFind(c, "SAIDA") >= 0);
   string marcador = "";
   if(nivel > 0)
      marcador = "|A" + IntegerToString(nivel);
   else if(StringFind(" " + c + " ", " A0 ") >= 0)
      marcador = "|A0";
   if(parcial)
      marcador += "|PC";
   else if(protecao)
      marcador += "|PR";
   else if(saida)
      marcador += "|OUT";
   else if(marcador == "")
      marcador = "|OP";
   return marcador;
}



void SincronizarMagicParametros(bool forcar)
{
   long novoMagicCompra = MagicCompraAtual();
   long novoMagicVenda  = MagicVendaAtual();
   long novoMagicPainelA = MagicPainelAAtual();
   long novoMagicPainelB = MagicPainelBAtual();
   bool mudou = (forcar ||
                 g_magicCompraSincronizado != novoMagicCompra ||
                 g_magicVendaSincronizado  != novoMagicVenda  ||
                 g_compra.magic != novoMagicCompra ||
                 g_venda.magic  != novoMagicVenda ||
                 g_painelA.magic != novoMagicPainelA ||
                 g_painelB.magic != novoMagicPainelB);
   g_compra.magic = novoMagicCompra;
   g_venda.magic  = novoMagicVenda;
   PrepararSlotPainel(g_painelA, "A", novoMagicPainelA, LADO_COMPRA);
   PrepararSlotPainel(g_painelB, "B", novoMagicPainelB, LADO_VENDA);
   if(!mudou)
      return;
   LimparTodosObjetosCOPA();
   g_magicCompraSincronizado = novoMagicCompra;
   g_magicVendaSincronizado  = novoMagicVenda;
   g_ultimaAtualizacaoHistorico = 0;
   g_ultimaAtualizacaoPainelVisual = 0;
   g_cicloInicioCompra = 0;
   g_cicloInicioVenda  = 0;
   g_ordemUltimoMagic = 0;
   g_ordemUltimoEvento = "MAGIC ALTERADO PELOS PARAMETROS";
   g_ordemUltimoContexto = "MAGIC_SYNC";
   g_ordemUltimaHora = TimeCurrent();
   g_mestre.mensagemGeral = StringFormat("Magic aplicado: A %s | B %s | Painel A %s | Painel B %s | ID %s",
                                         IntegerToString(novoMagicCompra),
                                         IntegerToString(novoMagicVenda),
                                         IntegerToString(novoMagicPainelA),
                                         IntegerToString(novoMagicPainelB),
                                         IDInstanciaAtual());
   if(InpGerenciadorOrdensExperts)
   {
      Print("[COPA_AR100][MAGIC_SYNC] MagicA=", IntegerToString(novoMagicCompra),
            " | MagicB=", IntegerToString(novoMagicVenda),
            " | PainelA=", IntegerToString(novoMagicPainelA),
            " | PainelB=", IntegerToString(novoMagicPainelB),
            " | Janela=", NomeJanelaInstanciaFIX255(),
            " | TF=", NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
            " | Fonte=InpMagicsCompraVenda | FIX260");
   }
}


#endif // COPA_IDENTIDADE_CICLO_MQH
