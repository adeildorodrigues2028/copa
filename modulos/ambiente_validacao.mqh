#ifndef COPA_AMBIENTE_VALIDACAO_MQH
#define COPA_AMBIENTE_VALIDACAO_MQH

// ============================================================================
// RESPONSABILIDADE: AMBIENTE, VALIDACOES INICIAIS E MAGICS
// Funcoes movidas do principal na V42 sem alteracao de regra operacional.
// ============================================================================

void AplicarAmbienteExecucaoFIX342()
{
   bool real=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   InpExigirContaDemo=!real;
   if(real)
   {
      // Em produção a auditoria antiga deixa de ser apenas informativa.
      InpAuditoriaTesteFIX274=true;
      InpBloquearOrdensSeAuditoriaFalharFIX274=true;
      int intervalo=InpIntervaloMinimoOrdensRealSegFIX342;
      if(intervalo<1) intervalo=1;
      if(InpIntervaloMinimoOrdensSeg<intervalo)
         InpIntervaloMinimoOrdensSeg=intervalo;
   }
}

bool ExecutarAuditoriaProducaoFIX342(string &detalhes)
{
   detalhes="";
   g_auditoriaProducaoOKFIX342=false;
   bool real=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   if(!real)
   {
      g_auditoriaProducaoOKFIX342=true;
      g_auditoriaProducaoStatusFIX342="DEMO | PRODUCAO NAO ARMADA";
      detalhes=g_auditoriaProducaoStatusFIX342;
      RegistrarLogValidacaoSistema("FIX342_AUDITORIA_DEMO",detalhes);
      return true;
   }

   int falhas=0;
   if(!InpConfirmarContaRealFIX342) { falhas++; detalhes+="CONFIRMACAO_REAL_OFF | "; }
   if(InpContaRealAutorizadaFIX342<=0) { falhas++; detalhes+="LOGIN_REAL_NAO_INFORMADO | "; }
   if(Trim(InpServidorRealAutorizadoFIX342)=="") { falhas++; detalhes+="SERVIDOR_REAL_NAO_INFORMADO | "; }
   if(InpComoAbrirPrimeiraOrdem!=PRIMEIRA_ORDEM_NORMAL) { falhas++; detalhes+="A0_NAO_E_NORMAL_COM_SINAIS | "; }
   if(InpCenarioAuditoriaFIX302!=AUD302_USAR_CONFIG_ATUAL) { falhas++; detalhes+="CENARIO_DE_TESTE_ATIVO | "; }
   if(EntradaDiretaDemoEfetivaFIX302() || InpTesteLivreEntradaA0) { falhas++; detalhes+="BYPASS_A0_ATIVO | "; }
   if(InpAumentosLivreTeste || InpAumentosLivreIgnorarTimerPreco) { falhas++; detalhes+="BYPASS_AUMENTOS_ATIVO | "; }
   if(!InpAuditoriaTesteFIX274 || !InpBloquearOrdensSeAuditoriaFalharFIX274 || !g_auditoriaTesteFIX274OK)
      { falhas++; detalhes+="AUDITORIA_BLOQUEANTE_NAO_APROVADA | "; }
   if(!InpStopServidorEmergenciaAtivoFIX342 || InpStopServidorEmergenciaPontosFIX342<=0.0)
      { falhas++; detalhes+="STOP_SERVIDOR_INVALIDO | "; }
   if(InpSpreadMaximoTicksFIX342<=0.0 || InpTickMaximoIdadeSegundosFIX342<1)
      { falhas++; detalhes+="QUALIDADE_COTACAO_INVALIDA | "; }
   if(InpMargemLivreMinimaReaisFIX342<0.0 || InpNivelMargemMinimoPercentFIX342<=0.0)
      { falhas++; detalhes+="LIMITE_MARGEM_INVALIDO | "; }
   if(InpMaxContratosBrutosABFIX342<=0.0)
      { falhas++; detalhes+="EXPOSICAO_AB_INVALIDA | "; }
   if(InpMaxExposicaoLiquidaABFIX342<=0.0 || InpMaxExposicaoLiquidaABFIX342>InpMaxContratosBrutosABFIX342)
      { falhas++; detalhes+="EXPOSICAO_LIQUIDA_INVALIDA | "; }
   if(InpFiltroRangeAtivoFIX344 &&
      (InpRangeMinimoPontosFIX344<0.0 || InpRangeMaximoPontosFIX344<=0.0 ||
       InpRangeMinimoPontosFIX344>InpRangeMaximoPontosFIX344))
      { falhas++; detalhes+="FILTRO_RANGE_INVALIDO | "; }
   if(InpGridEntradasAtivoFIX344 &&
      (InpGridTamanhoPontosFIX344<=0.0 || InpGridToleranciaPontosFIX344<0.0 ||
       InpGridToleranciaPontosFIX344>InpGridTamanhoPontosFIX344*0.5))
      { falhas++; detalhes+="GRID_ENTRADAS_INVALIDO | "; }
   if(!InpFechamentoFimDiaAtivo)
      { falhas++; detalhes+="FECHAMENTO_FIM_DIA_OFF | "; }

   g_auditoriaProducaoOKFIX342=(falhas==0);
   g_auditoriaProducaoStatusFIX342=g_auditoriaProducaoOKFIX342
      ? "REAL APROVADO PELA AUDITORIA"
      : StringFormat("REAL BLOQUEADO | %d FALHA(S) | %s",falhas,detalhes);
   detalhes=g_auditoriaProducaoStatusFIX342;
   RegistrarLogValidacaoSistema(g_auditoriaProducaoOKFIX342 ? "FIX342_AUDITORIA_REAL_OK" : "FIX342_AUDITORIA_REAL_FALHOU",detalhes);
   return g_auditoriaProducaoOKFIX342;
}

bool ValidarAmbienteConta()
{
   long tradeMode  = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   long marginMode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   g_loginContaAtual    = AccountInfoInteger(ACCOUNT_LOGIN);
   g_servidorContaAtual = AccountInfoString(ACCOUNT_SERVER);
   g_empresaContaAtual  = AccountInfoString(ACCOUNT_COMPANY);
   g_contaDemo  = (tradeMode == ACCOUNT_TRADE_MODE_DEMO);
   g_contaHedge = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   bool ambienteReal=(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL);
   if(!ambienteReal && !g_contaDemo)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = "BLOQUEADO: ambiente DEMO exige conta demonstrativa.";
      return false;
   }
   if(ambienteReal)
   {
      if(tradeMode!=ACCOUNT_TRADE_MODE_REAL)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: ambiente REAL exige conta real.";
         return false;
      }
      if(!InpConfirmarContaRealFIX342 || InpContaRealAutorizadaFIX342<=0 ||
         g_loginContaAtual!=InpContaRealAutorizadaFIX342)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente=StringFormat("BLOQUEADO: login REAL %I64d nao autorizado.",g_loginContaAtual);
         return false;
      }
      string servidorEsperado=Upper(Trim(InpServidorRealAutorizadoFIX342));
      if(servidorEsperado=="" || Upper(Trim(g_servidorContaAtual))!=servidorEsperado)
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: servidor REAL diferente do autorizado.";
         return false;
      }
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
      {
         g_ambienteLiberado=false;
         g_mestre.mensagemAmbiente="BLOQUEADO: terminal sem conexao com o servidor real.";
         return false;
      }
   }
   if(!ambienteReal && InpTravarContaDemoAutorizada && InpContaDemoAutorizada > 0 && g_loginContaAtual != InpContaDemoAutorizada)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = StringFormat("BLOQUEADO: login %s diferente da conta demo autorizada %s.",
                                               IntegerToString((int)g_loginContaAtual),
                                               IntegerToString((int)InpContaDemoAutorizada));
      return false;
   }
   if(InpExigirContaHedge && !g_contaHedge)
   {
      g_ambienteLiberado = false;
      g_mestre.mensagemAmbiente = "BLOQUEADO: conta nao e HEDGE.";
      return false;
   }
   g_ambienteLiberado = true;
   g_mestre.mensagemAmbiente = StringFormat("AMBIENTE %s OK: %s | TF %s | HEDGING.",
                                             ambienteReal ? "REAL" : "DEMO",
                                             NomeJanelaInstanciaFIX255(),
                                             NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));
   return true;
}

bool ValidarTravasDeValidacaoInicial()
{
   g_bloqueioValidacaoInicial = false;
   g_posicaoInicialAssumida = false;
   if(!g_ambienteLiberado)
      return false;
   if(ExistePosicaoAR100Aberta())
   {
      if(InpBloquearSePosicaoInicial)
      {
         g_bloqueioValidacaoInicial = true;
         g_ambienteLiberado = false;
         g_mestre.mensagemAmbiente = "BLOQUEADO VALIDACAO: existe posicao AR_100 aberta. Para testar A0 puro, iniciar zerado.";
         if(InpGerenciadorOrdensExperts)
            Print("[COPA_AR100][VALIDACAO] BLOQUEADO: posicao inicial existente. Feche a posicao ou deixe InpBloquearSePosicaoInicial=false.");
         return false;
      }
      if(InpPermitirAssumirPosicaoInicial)
      {
         g_posicaoInicialAssumida = true;
         g_mestre.mensagemAmbiente = "VALIDACAO: posicao inicial AR_100 assumida. A0 nao duplica; aumentos seguem travados pelo modo de validacao.";
         if(InpGerenciadorOrdensExperts)
            Print("[COPA_AR100][VALIDACAO] POSICAO INICIAL ASSUMIDA | Compra=", DoubleToString(g_compra.contratos, 2),
                  " | B=", DoubleToString(g_venda.contratos, 2),
                  " | Modo=", TextoModoValidacaoExecucao(),
                  " | AumentosValidacao=", (InpPermitirAumentosNaValidacao ? "ON" : "OFF"));
      }
   }
   return true;
}

bool ExistePosicaoAR100Aberta()
{
   return (g_compra.posicaoAberta || g_venda.posicaoAberta);
}

bool PermitirEntradaA0PeloModoValidacao(EstadoLado &estado)
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS ||
      InpModoValidacaoExecucao == VALIDAR_A0_E_AUMENTOS ||
      InpModoValidacaoExecucao == OPERAR_COMPLETO)
      return true;
   RegistrarGerenciadorOrdens(estado, "VALIDACAO", "Entrada A0 bloqueada: modo de validacao invalido.", 0, 0, 0.0, 0.0, true);
   return false;
}

bool PermitirAumentoPeloModoValidacao(EstadoLado &estado, int idxAlvo)
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS)
   {
      RegistrarGerenciadorOrdens(estado, "VALIDACAO",
                                 StringFormat("Aumento A%d bloqueado: modo VALIDAR_A0_APENAS. Primeiro validar entrada A0 com 1 contrato.", idxAlvo + 1),
                                 0, 0, 0.0, 0.0, false);
      return false;
   }
   if(!InpPermitirAumentosNaValidacao && InpModoValidacaoExecucao != OPERAR_COMPLETO)
   {
      RegistrarGerenciadorOrdens(estado, "VALIDACAO",
                                 StringFormat("Aumento A%d bloqueado: InpPermitirAumentosNaValidacao=false.", idxAlvo + 1),
                                 0, 0, 0.0, 0.0, false);
      return false;
   }
   return true;
}

string TextoModoValidacaoExecucao()
{
   if(InpModoValidacaoExecucao == VALIDAR_A0_APENAS)
      return "VALIDAR_A0_APENAS";
   if(InpModoValidacaoExecucao == VALIDAR_A0_E_AUMENTOS)
      return "VALIDAR_A0_E_AUMENTOS";
   if(InpModoValidacaoExecucao == OPERAR_COMPLETO)
      return "OPERAR_COMPLETO";
   return "MODO_INVALIDO";
}

string NomeTimeframeCurto(ENUM_TIMEFRAMES tf)
{
   string s = EnumToString(tf);
   StringReplace(s, "PERIOD_", "");
   return s;
}

void InicializarEstados()
{
   ZeroMemory(g_mercado);
   ZeroMemory(g_gerAumentos);
   ZeroMemory(g_scoreAumentos);
   ZeroMemory(g_risco);
   ZeroMemory(g_mestre);
   ZeroMemory(g_compra);
   ZeroMemory(g_venda);
   ZeroMemory(g_painelA);
   ZeroMemory(g_painelB);
   ZeroMemory(g_alvoLinhaAumentoBuy);
   ZeroMemory(g_alvoLinhaAumentoSell);
   ZeroMemory(g_precoRealizadoAumentoBuy);
   ZeroMemory(g_precoRealizadoAumentoSell);
   ZeroMemory(g_precoEntradaAumentoBuy);
   ZeroMemory(g_precoEntradaAumentoSell);
   g_precosAumentosRestauradosBuy=false;
   g_precosAumentosRestauradosSell=false;
   ZeroMemory(g_aumentoRealizadoBuy);
   ZeroMemory(g_aumentoRealizadoSell);
   g_compra.lado = LADO_COMPRA;
   g_compra.nome = "MOTOR_COMPRA";
   g_compra.magic = MagicCompraAtual();
   g_compra.tipoPosicaoAtual = -1;
   g_venda.lado = LADO_VENDA;
   g_venda.nome = "MOTOR_VENDA";
   g_venda.magic = MagicVendaAtual();
   g_venda.tipoPosicaoAtual = -1;
   PrepararSlotPainel(g_painelA, "A", MagicPainelAAtual(), LADO_COMPRA);
   PrepararSlotPainel(g_painelB, "B", MagicPainelBAtual(), LADO_VENDA);
}

bool AplicarMagicsCompactosFIX255(string &motivo)
{
   motivo = "";
   double valorA=0.0, valorB=0.0, valorExtra=0.0;
   int fimA=0, fimB=0, fimExtra=0;

   // FIX260: pode informar somente um Magic base.
   // Exemplo: 200100 gera automaticamente Compra=200100 e Venda=200101.
   if(!ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,0,valorA,fimA))
   {
      motivo = "Informe um Magic base (ex.: 147025) ou o par Compra/Venda (ex.: 147025 / 147026).";
      return false;
   }

   bool temMagicB=ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,fimA,valorB,fimB);
   if(temMagicB && ExtrairPrimeiroNumeroAPartir(InpMagicsCompraVenda,fimB,valorExtra,fimExtra))
   {
      motivo = "Foram encontrados mais de dois numeros na linha de Magics.";
      return false;
   }

   long magicA=(long)MathRound(valorA);
   if(MathAbs(valorA-(double)magicA)>0.000001)
   {
      motivo = "O Magic precisa ser um numero inteiro.";
      return false;
   }

   long magicB=0;
   if(temMagicB)
   {
      magicB=(long)MathRound(valorB);
      if(MathAbs(valorB-(double)magicB)>0.000001)
      {
         motivo = "Os Magics precisam ser numeros inteiros.";
         return false;
      }
   }
   else
   {
      if(magicA>=2147483647)
      {
         motivo = "O Magic base e muito alto para gerar automaticamente o Magic de venda.";
         return false;
      }
      magicB=magicA+1;
   }

   if(magicA<=0 || magicB<=0 || magicA>2147483647 || magicB>2147483647)
   {
      motivo = "Os Magics precisam ser inteiros positivos validos.";
      return false;
   }
   if(magicA==magicB)
   {
      motivo = "Compra e venda precisam usar numeros Magic diferentes.";
      return false;
   }

   // FIX412: respeita o Magic informado pelo usuario.
   // Um novo par de Magics possui historico, painel, posicoes e resultado isolados.
   InpMagicA=(int)magicA;
   InpMagicB=(int)magicB;
   Print("[COPA_AR100][FIX412][MAGIC_USUARIO] Compra=",IntegerToString(InpMagicA),
         " | Venda=",IntegerToString(InpMagicB),
         " | HISTORICO_ISOLADO=SIM");
   if(!temMagicB)
      Print("[COPA_AR100][FIX260][MAGIC_BASE] Base=",IntegerToString((int)magicA),
            " | Compra=",IntegerToString((int)magicA),
            " | Venda=",IntegerToString((int)magicB));
   return true;
}

long MagicCompraAtual()
{
   return (long)InpMagicA;
}

long MagicVendaAtual()
{
   return (long)InpMagicB;
}

long MagicPainelAAtual()
{
   return MagicCompraAtual();
}

long MagicPainelBAtual()
{
   return MagicVendaAtual();
}


#endif // COPA_AMBIENTE_VALIDACAO_MQH
