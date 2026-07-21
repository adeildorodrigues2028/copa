#ifndef COPA_LOGS_AUDITORIA_MQH
#define COPA_LOGS_AUDITORIA_MQH

// ============================================================================
// RESPONSABILIDADE: PARAMETROS HUMANIZADOS E AUDITORIA
// ============================================================================

int QuantidadeLadosHabilitadosFIX372()
{
   return (InpLadosHabilitadosFIX346==OPERACAO_AMBOS ? 2 : 1);
}

bool CampoFiltroNuloFIX372(string valor)
{
   string t=Upper(Trim(valor));
   return (t=="" || t=="0" || t=="NULL" || t=="NULO" || t=="NENHUM" || t=="OFF" || t=="LIVRE");
}

string MontarPerfilTresFiltrosFIX372(string f1,string f2,string f3)
{
   string itens[3];
   itens[0]=f1;
   itens[1]=f2;
   itens[2]=f3;
   string perfil="";
   for(int i=0;i<3;i++)
   {
      string item=Trim(itens[i]);
      if(CampoFiltroNuloFIX372(item))
         continue;
      if(perfil!="") perfil+=" / ";
      perfil+=item;
   }
   return (perfil=="" ? "LIVRE" : perfil);
}

string PerfilJanelaOuPadraoFIX372(int indice,string perfilJanela,string perfilPadrao)
{
   bool janelaAtiva=!CampoFiltroNuloFIX372(perfilJanela);
   if(indice>=0 && indice<4)
   {
      g_origemFiltroJanelaFIX372[indice]=(janelaAtiva ? "JANELA" : "PADRAO A0");
      g_perfilFiltroJanelaFIX372[indice]=(janelaAtiva ? perfilJanela : perfilPadrao);
   }
   return (janelaAtiva ? perfilJanela : perfilPadrao);
}

void PrepararParametrosMestreFIX372()
{
   AplicarMatrizesCompactasFIX373();
   int lados=QuantidadeLadosHabilitadosFIX372();
   if(lados<1) lados=1;
   int qtdA0=InpContratosA0FIX372;
   if(qtdA0<1) qtdA0=1;
   double ganho=MathAbs(InpGanhoPorTicketReaisFIX372);
   double perda=MathAbs(InpPerdaPorTicketReaisFIX372);
   double trAtiva=MathAbs(InpTrailingAtivarTicketReaisFIX372);
   double trPasso=MathAbs(InpTrailingPassoTicketReaisFIX372);
   if(ganho<=0.0) ganho=50.0;
   if(perda<=0.0) perda=100.0;
   if(trAtiva<=0.0) trAtiva=20.0;
   if(trPasso<=0.0) trPasso=5.0;

   InpHorariosEntradaA0=Trim(InpJanela1HorarioFIX372)+";"+Trim(InpJanela2HorarioFIX372)+";"+
                         Trim(InpJanela3HorarioFIX372)+";"+Trim(InpJanela4HorarioFIX372);
   InpHorariosFiltros=InpHorariosEntradaA0;
   InpHorariosAumentos="00:00-23:59";

   InpEntradaA0QuantidadeAlvoFIX340=StringFormat("QTD=%dC | ALVO=%.2f",qtdA0,ganho);
   InpEntradaA0PerdaTrailingFIX340=StringFormat("PERDA=%.2f | TRAIL=%.2f/%.2f",perda,trAtiva,trPasso);
   InpRiscoAumentosFIX340=StringFormat("ALVO=%.2f | PERDA=%.2f",ganho,perda);

   // Fonte unica FIX372: neutraliza qualquer valor legado que poderia sobrescrever
   // os campos visiveis durante AplicarEntradaOperacaoCompacta/AplicarParametrosHumanizados.
   InpEntradaContratos=(double)qtdA0;
   InpEntradaGanhoAlvoReais=ganho;
   InpEntradaPerdaMaximaReais=perda;
   InpFIX280AlvoPorPontaReais=ganho;
   InpLossEntradaLocalReaisFIX321=perda;
   InpFIX280TrailingAtivarReais=trAtiva;
   InpFIX280TrailingPassoReais=trPasso;
   InpProtecaoAtivarEmReais=trAtiva;
   InpProtecaoTrailPassoReais=trPasso;
   InpLucroAumentoPorContratoReaisFIX207=10.0; // FIX447: parcial individual dos aumentos em +R$10.
   InpLossAumentoPorContratoReaisFIX321=perda;
   InpTrailingAumentoAtivarReaisFIX281=trAtiva;
   InpTrailingAumentoPassoReaisFIX281=trPasso;
   string trail=StringFormat("TRAIL=%.2f/%.2f",trAtiva,trPasso);
   InpA1TrailingFIX340=trail;
   InpA2TrailingFIX340=trail;
   InpA3TrailingFIX340=trail;
   InpA4TrailingFIX340=trail;
   InpA5TrailingFIX340=trail;

   g_perfilA0PadraoFIX372=MontarPerfilTresFiltrosFIX372(InpFiltroA0_1_FIX372,InpFiltroA0_2_FIX372,InpFiltroA0_3_FIX372);
   g_perfilAumentosFIX372=MontarPerfilTresFiltrosFIX372(InpFiltroAumento_1_FIX372,InpFiltroAumento_2_FIX372,InpFiltroAumento_3_FIX372);
   InpFiltrosProjetoFIX324=g_perfilA0PadraoFIX372;

   InpFIX280GainHeadABReais=NormalizeDouble(ganho*lados,2);
   InpFIX280LossHeadABReais=NormalizeDouble(MathAbs(InpGarantiaPorLadoReaisFIX372)*lados,2);
   InpStopOperacaoCestaABReais=InpFIX280LossHeadABReais;
   InpGainGlobalCestaReais=MathAbs(InpProtecaoDiaAtivarReais);
   InpMetaMestreABReais=MathAbs(InpProtecaoDiaAtivarReais);

   InpCorredorAtivarReais=trAtiva;
   InpCorredorPisoInicialReais=trPasso;
   InpCorredorDegrauReais=trAtiva;
   InpCorredorFolgaForteReais=trPasso;
   InpCorredorFolgaNeutraReais=trPasso;
   InpCorredorFolgaViradaReais=trPasso;
   InpProtecaoDiaDegrauReais=50.0;
   InpProtecaoDiaFolgaReais=200.0;
}

double GainHeadEfetivoFIX362()
{
   double valor=MathAbs(InpGanhoPorTicketReaisFIX372)*QuantidadeLadosHabilitadosFIX372();
   if(valor<=0.0) valor=50.0*QuantidadeLadosHabilitadosFIX372();
   return NormalizeDouble(valor,2);
}

double LossHeadEfetivoFIX362()
{
   double valor=MathAbs(InpGarantiaPorLadoReaisFIX372)*QuantidadeLadosHabilitadosFIX372();
   if(valor<=0.0) valor=500.0*QuantidadeLadosHabilitadosFIX372();
   return NormalizeDouble(valor,2);
}

string AssinaturaParametrosUsuarioFIX362()
{
   return InpMatrizMagicsFIX378+"|"+IntegerToString((int)InpOperacaoUsuarioFIX378)+"|"+IntegerToString((int)InpJanelaUsuarioFIX378)+"|"+InpMatrizHeadEntradaFIX373+"|"+
          InpMatrizFinanceiroFIX373+"|"+InpMatrizEscalaHeadFIX373+"|"+InpMatrizReentradaFIX373+"|"+
          InpMatrizFiltrosEntradaFIX373+"|"+InpMatrizControleAumentosFIX373+"|"+InpMatrizFiltrosAumentosFIX373+"|"+
          InpMatrizJanela1FIX373+"|"+InpMatrizJanela2FIX373+"|"+InpMatrizJanela3FIX373+"|"+InpMatrizJanela4FIX373+"|"+
          InpMatrizAmbienteFIX373+"|"+InpMatrizProtecoesFIX373+"|"+InpMatrizCustosFIX373+"|"+
          InpMatrizEncerramentoFIX373+"|"+InpMatrizTesteFIX373+"|"+
          InpMagicsCompraVenda+"|"+
          IntegerToString((int)InpJanelaDesteGrafico)+"|"+
          IntegerToString((int)InpLadosHabilitadosFIX346)+"|"+
          InpHorariosEntradaA0+"|"+InpHorariosFiltros+"|"+InpHorariosAumentos+"|"+
          IntegerToString(InpPausaReentradaSegundos)+"|"+
          InpEntradaA0QuantidadeAlvoFIX340+"|"+InpEntradaA0PerdaTrailingFIX340+"|"+
          IntegerToString(InpQuantidadeReforcos)+"|"+IntegerToString((int)InpModoGatilhoAumentos)+"|"+
          IntegerToString((int)InpBasePrecoAumento)+"|"+InpRiscoAumentosFIX340+"|"+
          InpA1ExecucaoFIX340+"|"+InpA1TrailingFIX340+"|"+
          InpA2ExecucaoFIX340+"|"+InpA2TrailingFIX340+"|"+
          InpA3ExecucaoFIX340+"|"+InpA3TrailingFIX340+"|"+
          InpA4ExecucaoFIX340+"|"+InpA4TrailingFIX340+"|"+
          InpFiltroA1CompactoFIX375+"|"+InpFiltroA2CompactoFIX375+"|"+InpFiltroA3CompactoFIX375+"|"+InpFiltroA4CompactoFIX375+"|"+
          InpTrailingInteligenteLinhasFIX325+"|"+InpFiltrosProjetoFIX324+"|"+
          InpFiltroA0_1_FIX372+"|"+InpFiltroA0_2_FIX372+"|"+InpFiltroA0_3_FIX372+"|"+
          InpFiltroAumento_1_FIX372+"|"+InpFiltroAumento_2_FIX372+"|"+InpFiltroAumento_3_FIX372+"|"+
          InpJanela1HorarioFIX372+"|"+InpJanela1Filtro1FIX372+"|"+InpJanela1Filtro2FIX372+"|"+InpJanela1Filtro3FIX372+"|"+
          InpJanela2HorarioFIX372+"|"+InpJanela2Filtro1FIX372+"|"+InpJanela2Filtro2FIX372+"|"+InpJanela2Filtro3FIX372+"|"+
          InpJanela3HorarioFIX372+"|"+InpJanela3Filtro1FIX372+"|"+InpJanela3Filtro2FIX372+"|"+InpJanela3Filtro3FIX372+"|"+
          InpJanela4HorarioFIX372+"|"+InpJanela4Filtro1FIX372+"|"+InpJanela4Filtro2FIX372+"|"+InpJanela4Filtro3FIX372+"|"+
          DoubleToString(InpGanhoPorTicketReaisFIX372,2)+"|"+DoubleToString(InpPerdaPorTicketReaisFIX372,2)+"|"+
          DoubleToString(InpGarantiaPorContratoReaisFIX372,2)+"|"+DoubleToString(InpGarantiaPorLadoReaisFIX372,2)+"|"+
          IntegerToString(InpReentradaLucroSegundosFIX372)+"|"+IntegerToString(InpPausaReentradaSegundos)+"|"+
          IntegerToString(InpDXPeriodo)+"|"+IntegerToString(InpDXMediaPeriodo)+"|"+
          DoubleToString(InpDXDistanciaMedia,2)+"|"+
          DoubleToString(GainHeadEfetivoFIX362(),2)+"|"+DoubleToString(LossHeadEfetivoFIX362(),2)+"|"+
          IntegerToString(InpStopDinamicoHeadFIX359?1:0)+"|"+
          IntegerToString((int)InpModoPainelVisual)+"|"+
          InpEntradaOperacao+"|"+InpGestaoAumentosFIX324+"|"+InpParcialOperacao;
}

bool SincronizarParametrosUsuarioFIX362(bool forcar, string origem)
{
   PrepararParametrosMestreFIX372();
   string assinatura=AssinaturaParametrosUsuarioFIX362();
   if(!forcar && assinatura==g_assinaturaParametrosUsuarioFIX362)
      return false;

   // Campos visiveis sao a autoridade. Nenhum campo legado pode sobrescrever o HEAD.
   g_gainHeadEfetivoFIX362=GainHeadEfetivoFIX362();
   g_lossHeadEfetivoFIX362=LossHeadEfetivoFIX362();

   MontarReforcosDaTelaFIX312();
   AplicarConfirmacaoLinhasAumentos();
   CarregarMatrizJanelas();
   CarregarMatrizAumentos();
   CarregarMatrizSaida();
   AplicarParametrosHumanizados();

   g_risco.metaDia=0.0;
   g_risco.stopDia=g_lossHeadEfetivoFIX362;
   g_assinaturaParametrosUsuarioFIX362=assinatura;
   g_assinaturaParametrosEfetivos=assinatura;

   InvalidarSnapshotTotalABFIX292();
   g_cacheRealizadoCestaValidoFIX283=false;
   g_ultimaAtualizacaoEstadosMsFIX287=0;
   g_ultimaQtdPosicoesEstadosFIX287=-1;
   g_ultimaAtualizacaoCamposFIX354=0;
   g_ultimaFotoFinanceiraMsFIX362=0;
   g_ultimaAtualizacaoGanhoQtdMsFIX362=0;
   g_ultimaAtualizacaoPainelVisual=0;
   g_ultimaAtualizacaoRodapeVisual=0;
   g_ultimaAtualizacaoHistorico=0;
   g_assinaturaPlotagemRangeGridFIX344="";

   if(g_handleADX!=INVALID_HANDLE || g_handleMedia25Grafico!=INVALID_HANDLE)
   {
      LimparPlotagemOperacional();
      AtualizarBandasMedia25Grafico(true);
      AtualizarRangeGridGraficoFIX344(true);
   }
   RemoverOsciladoresSelecionadosFIX343();

   RegistrarLogValidacaoSistema("FIX373_PARAM_SYNC",
      StringFormat("%s | MAGIC %s | BASE GAIN HEAD %s | LOSS HEAD AUTO %s | A0 %s %s | A1 %s | A2 %s | A3 %s | A4 %s | FIL A0 %s | FIL AUM %s | REENT L%ds/P%ds | ESC 250 SEM TETO",
                   origem,InpMagicsCompraVenda,PnlMoedaBRL(g_gainHeadEfetivoFIX362),PnlMoedaBRL(g_lossHeadEfetivoFIX362),
                   InpEntradaA0QuantidadeAlvoFIX340,InpEntradaA0PerdaTrailingFIX340,
                   InpA1ExecucaoFIX340,InpA2ExecucaoFIX340,InpA3ExecucaoFIX340,InpA4ExecucaoFIX340,
                   g_perfilA0PadraoFIX372,g_perfilAumentosFIX372,InpReentradaLucroSegundosFIX372,InpPausaReentradaSegundos));
   RegistrarLogValidacaoSistema("FIX367_PARAM_SYNC",
      StringFormat("%s | LOSS_HEAD_INPUT=%.2f | LOSS_HEAD_EFETIVO=%.2f | GAIN_HEAD_INPUT=%.2f | GAIN_HEAD_EFETIVO=%.2f | BASE=%d | A1_DIST=%.0f | A2_DIST=%.0f | A3_DIST=%.0f | A4_DIST=%.0f",
                   origem,MathAbs(InpFIX280LossHeadABReais),g_lossHeadEfetivoFIX362,
                   MathAbs(InpFIX280GainHeadABReais),g_gainHeadEfetivoFIX362,(int)InpBasePrecoAumento,
                   MathAbs(NumeroDepoisDoMarcador(InpA1ExecucaoFIX340,"DIST",0.0)),
                   MathAbs(NumeroDepoisDoMarcador(InpA2ExecucaoFIX340,"DIST",0.0)),
                   MathAbs(NumeroDepoisDoMarcador(InpA3ExecucaoFIX340,"DIST",0.0)),
                   MathAbs(NumeroDepoisDoMarcador(InpA4ExecucaoFIX340,"DIST",0.0))));
   return true;
}

void ReaplicarParametrosAntesDoGrafico(string origem)
{
   if(!SincronizarParametrosUsuarioFIX362(false,origem))
      return;
   AtualizarPainelMestre();
   AtualizarCamposFinanceirosCriticosFIX354(true);
   PainelChartRedrawLeve(true);
}

void AplicarEntradaOperacaoCompacta()
{
   string linha = Trim(InpEntradaOperacao);
   double qtd = 0.0;
   double ganho = 0.0;
   double perda = 0.0;
   double trailingAtivar = MathAbs(InpProtecaoAtivarEmReais);
   double trailingPasso = MathAbs(InpProtecaoTrailPassoReais);
   string linhaUpper = Upper(linha);
   bool formatoTecnico = (StringFind(linhaUpper, "QTD=") >= 0 ||
                           StringFind(linhaUpper, "CONTRATOS=") >= 0 ||
                           StringFind(linhaUpper, "ALVO=") >= 0 ||
                           StringFind(linhaUpper, "GAIN=") >= 0 ||
                           StringFind(linhaUpper, "GANHO=") >= 0 ||
                           StringFind(linhaUpper, "PERDA=") >= 0 ||
                           StringFind(linhaUpper, "STOP=") >= 0);
   if(formatoTecnico)
   {
      string linhaTecnica=linha;
      StringReplace(linhaTecnica,"|",";");
      qtd = ExtrairNumero(GetCampo(linhaTecnica, "QTD", GetCampo(linhaTecnica, "CONTRATOS", "1")));
      ganho = ExtrairNumero(GetCampo(linhaTecnica, "ALVO", GetCampo(linhaTecnica, "GAIN", GetCampo(linhaTecnica, "GANHO", GetCampo(linhaTecnica, "G", "100")))));
      perda = ExtrairNumero(GetCampo(linhaTecnica, "PERDA", GetCampo(linhaTecnica, "STOP", GetCampo(linhaTecnica, "P", "300"))));
      string trailCampo = GetCampo(linhaTecnica, "TRAIL", GetCampo(linhaTecnica, "TRAILING", "20/5"));
      string trailPartes[];
      int trailTotal = StringSplit(trailCampo, '/', trailPartes);
      if(trailTotal >= 1) trailingAtivar = MathAbs(ExtrairNumero(trailPartes[0]));
      if(trailTotal >= 2) trailingPasso = MathAbs(ExtrairNumero(trailPartes[1]));
   }
   else
   {
      string partes[];
      int total = StringSplit(linha, '|', partes);
      if(total < 3)
         total = StringSplit(linha, ';', partes);
      if(total >= 1)
         qtd = ExtrairNumero(partes[0]);
      if(total >= 2)
         ganho = ExtrairNumero(partes[1]);
      if(total >= 3)
         perda = ExtrairNumero(partes[2]);
      if(total >= 4)
      {
         string trailCampo = Upper(Trim(partes[3]));
         StringReplace(trailCampo, "TRAIL=", "");
         StringReplace(trailCampo, "TRAILING=", "");
         StringReplace(trailCampo, "T=", "");
         string trailPartes[];
         int trailTotal = StringSplit(trailCampo, '/', trailPartes);
         if(trailTotal >= 1) trailingAtivar = MathAbs(ExtrairNumero(trailPartes[0]));
         if(trailTotal >= 2) trailingPasso = MathAbs(ExtrairNumero(trailPartes[1]));
      }
   }
   if(qtd <= 0.0)
      qtd = 1.0;
   ganho = MathAbs(ganho);
   perda = MathAbs(perda);
   InpEntradaContratos = qtd;
   InpEntradaGanhoAlvoReais = ganho;
   InpEntradaPerdaMaximaReais = perda;
   if(InpFIX280UsarCamposClaros)
   {
      if(InpFIX280AlvoPorPontaReais > 0.0)
         ganho = MathAbs(InpFIX280AlvoPorPontaReais);
      if(InpLossEntradaLocalReaisFIX321 > 0.0)
         perda = MathAbs(InpLossEntradaLocalReaisFIX321);
      if(InpFIX280TrailingAtivarReais > 0.0)
         trailingAtivar = MathAbs(InpFIX280TrailingAtivarReais);
      if(InpFIX280TrailingPassoReais > 0.0)
         trailingPasso = MathAbs(InpFIX280TrailingPassoReais);
      InpEntradaGanhoAlvoReais = ganho;
      InpEntradaPerdaMaximaReais = perda;
   }
   if(trailingAtivar <= 0.0) trailingAtivar = 20.0;
   if(trailingPasso <= 0.0) trailingPasso = 5.0;
   InpFIX280AlvoPorPontaReais = ganho;
   InpLossEntradaLocalReaisFIX321 = perda;
   InpFIX280TrailingAtivarReais = trailingAtivar;
   InpFIX280TrailingPassoReais = trailingPasso;
   InpEntradaGanhoAlvoReais = ganho;
   InpEntradaPerdaMaximaReais = perda;
   g_entradaTrailingAtivarReaisEfetivo = trailingAtivar;
   g_entradaTrailingPassoReaisEfetivo = trailingPasso;
}

void AplicarAumentosDiretoDasLinhasParametros()
{
   g_aumentos[0] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA1), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA1Filtros))));
   g_aumentos[1] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA2), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA2Filtros))));
   g_aumentos[2] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA3), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA3Filtros))));
   g_aumentos[3] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA4), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA4Filtros))));
   g_aumentos[4] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA5), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA5Filtros))));
}

void AplicarParametrosHumanizados()
{
   AplicarParametrosCompactos();
   AplicarEntradaOperacaoCompacta();
   AplicarParcialOperacaoCompacta();
   double contratosEntrada = InpEntradaContratos;
   if(contratosEntrada <= 0.0)
      contratosEntrada = 1.0;
   for(int i = 0; i < 5; i++)
   {
      if(g_janelas[i].entradaAtiva)
         g_janelas[i].qtd = contratosEntrada;
   }
   if(InpMaxAumentos >= 0)
      g_gerAumentos.maxAumentos = InpMaxAumentos;
   if(InpMaxContratosTotal > 0)
      g_gerAumentos.maxContratos = InpMaxContratosTotal;
   AplicarAumentoHumanizado(0, InpA1Ativo, InpA1Contratos, InpA1TempoMinutos, InpA1GatilhoReais, InpA1DistanciaPontos, InpA1ProtecaoPercent, InpA1Filtros);
   AplicarAumentoHumanizado(1, InpA2Ativo, InpA2Contratos, InpA2TempoMinutos, InpA2GatilhoReais, InpA2DistanciaPontos, InpA2ProtecaoPercent, InpA2Filtros);
   AplicarAumentoHumanizado(2, InpA3Ativo, InpA3Contratos, InpA3TempoMinutos, InpA3GatilhoReais, InpA3DistanciaPontos, InpA3ProtecaoPercent, InpA3Filtros);
   AplicarAumentosDiretoDasLinhasParametros();
   g_risco.metaOperacao = MathAbs(InpEntradaGanhoAlvoReais);
   g_risco.stopOperacao = MathAbs(InpEntradaPerdaMaximaReais);
   g_risco.defesaAtivaEm = MathAbs(g_entradaTrailingAtivarReaisEfetivo);
   g_risco.naoVirarPrejuizo = InpProtecaoLucroAtiva;
   g_risco.defesaMinima = MathAbs(InpProtecaoDefesaMinimaReais);
   g_risco.trailPasso = MathAbs(g_entradaTrailingPassoReaisEfetivo);
   if(g_risco.trailPasso <= 0.0)
      g_risco.trailPasso = 2.50;
   g_risco.operacaoLongaAtiva = InpOperacaoLongaUsar;
   g_risco.ativaLongaEm = MathAbs(InpOperacaoLongaAtivarEmReais);
   g_risco.operacaoLongaSomenteSeGanhoMaiorQue = MathAbs(InpOperacaoLongaSomenteSeGanhoMaiorQue);
   g_risco.operacaoLongaScoreSaida = MathAbs(InpOperacaoLongaScoreSaida);
   // FIX362: reaplica o LOSS HEAD visível depois de qualquer parser legado.
   g_risco.metaDia = 0.0;
   g_risco.stopDia = LossHeadEfetivoFIX362();
   g_risco.protecaoPercent = InpProtecaoDefenderPercent;
   if(g_risco.protecaoPercent < 0.0)
      g_risco.protecaoPercent = 0.0;
   if(g_risco.protecaoPercent > 100.0)
      g_risco.protecaoPercent = 100.0;
}

void AuditoriaCheckFIX274(bool condicao, string mensagem, int &erros, string &detalhes)
{
   if(condicao)
      return;
   erros++;
   if(detalhes != "")
      detalhes += " | ";
   detalhes += mensagem;
}

bool ExecutarAuditoriaTesteFIX274()
{
   g_auditoriaTesteFIX274OK=true;
   g_auditoriaTesteFIX274Status="OK";
   if(!InpAuditoriaTesteFIX274)
   {
      g_auditoriaTesteFIX274Status="DESLIGADA";
      return true;
   }

   // FIX362: a auditoria valida o que o USUARIO configurou. Nao exige mais
   // valores antigos fixos (D100, HEAD 200/-1000, novo candle obrigatorio etc.).
   int erros=0;
   string detalhes="";
   AuditoriaCheckFIX274(InpEntradaContratos>0.0,"A0 deve ter quantidade maior que zero",erros,detalhes);
   AuditoriaCheckFIX274(InpEntradaGanhoAlvoReais>0.0,"alvo A0 deve ser maior que zero",erros,detalhes);
   AuditoriaCheckFIX274(InpEntradaPerdaMaximaReais>0.0,"perda A0 deve ser maior que zero",erros,detalhes);
   AuditoriaCheckFIX274(GainHeadEfetivoFIX362()>0.0,"GAIN HEAD deve ser maior que zero",erros,detalhes);
   AuditoriaCheckFIX274(LossHeadEfetivoFIX362()>0.0,"LOSS HEAD deve ser maior que zero",erros,detalhes);
   AuditoriaCheckFIX274(MathAbs(g_risco.stopDia-LossHeadEfetivoFIX362())<0.01,
                         "LOSS HEAD visivel nao sincronizou com o motor",erros,detalhes);
   AuditoriaCheckFIX274(!InpStopDinamicoHeadFIX359,"FIX442: STOP individual deve estar ligado e STOP MOVEL HEAD desligado",erros,detalhes);
   AuditoriaCheckFIX274(InpQuantidadeReforcos>=0 && InpQuantidadeReforcos<=5,
                         "quantidade de aumentos deve ficar entre 0 e 5",erros,detalhes);
   AuditoriaCheckFIX274(g_gerAumentos.maxAumentos==InpQuantidadeReforcos,
                         "quantidade efetiva de aumentos diverge da tela",erros,detalhes);
   AuditoriaCheckFIX274(InpAumentoConfirmarFechamentoCandle,
                         "FIX363 exige fechamento de candle nos aumentos",erros,detalhes);
   AuditoriaCheckFIX274(InpAumentoTimeframeConfirmacao==PERIOD_M1,
                         "FIX363 exige confirmação M1 nos aumentos",erros,detalhes);
   AuditoriaCheckFIX274(!InpAumentosLivreIgnorarTimerPreco,
                         "FIX363 proíbe LIVRE_TOTAL sem linha/candle",erros,detalhes);
   AuditoriaCheckFIX274(InpPausaReentradaSegundos>=0,
                         "pausa apos prejuizo deve ser zero ou positiva",erros,detalhes);
   AuditoriaCheckFIX274(MagicCompraAtual()>0 && MagicVendaAtual()>0 && MagicCompraAtual()!=MagicVendaAtual(),
                         "Magics COMPRA/VENDA devem ser positivos e diferentes",erros,detalhes);
   AuditoriaCheckFIX274(InpFIX353GraficoLimpoSemIndicadores,
                         "GRAFICO LIMPO deve permanecer ligado para retirar indicadores visuais",erros,detalhes);

   double distanciaAnterior=-1.0;
   for(int i=0;i<InpQuantidadeReforcos && i<5;i++)
   {
      AuditoriaCheckFIX274(g_aumentos[i].ativa,
                           StringFormat("A%d configurado na tela mas ficou OFF",i+1),erros,detalhes);
      AuditoriaCheckFIX274(g_aumentos[i].qtd>0.0,
                           StringFormat("A%d deve ter quantidade maior que zero",i+1),erros,detalhes);
      AuditoriaCheckFIX274(g_aumentos[i].tempoMinutos>=0,
                           StringFormat("A%d possui timer invalido",i+1),erros,detalhes);
      AuditoriaCheckFIX274(g_aumentos[i].distanciaPontos>=0.0,
                           StringFormat("A%d possui distancia negativa",i+1),erros,detalhes);
      if(InpBasePrecoAumento==BASE_ENTRADA_INICIAL && distanciaAnterior>=0.0)
         AuditoriaCheckFIX274(g_aumentos[i].distanciaPontos>distanciaAnterior,
                              StringFormat("A%d deve ficar depois do nivel anterior",i+1),erros,detalhes);
      distanciaAnterior=g_aumentos[i].distanciaPontos;
   }

   g_auditoriaTesteFIX274OK=(erros==0);
   g_auditoriaTesteFIX274Status=g_auditoriaTesteFIX274OK
      ? StringFormat("OK | GAIN HEAD %s | LOSS HEAD %s | AUMENTOS %d | OSC VISUAL OFF | USUARIO SINCRONIZADO",
                     PnlMoedaBRL(GainHeadEfetivoFIX362()),PnlMoedaBRL(LossHeadEfetivoFIX362()),InpQuantidadeReforcos)
      : StringFormat("FALHOU %d ITEM(NS): %s",erros,detalhes);
   Print("[COPA_AR100][FIX362][AUDITORIA_USUARIO] ",g_auditoriaTesteFIX274Status);
   RegistrarLogValidacaoSistema("FIX362_AUDITORIA_USUARIO",g_auditoriaTesteFIX274Status);
   return g_auditoriaTesteFIX274OK;
}

void AplicarAumentoHumanizado(int idx, bool ativo, double qtd, int tempoMinutos, double gatilhoReais, int distanciaPontos, double protecaoPercent, string filtrosLinha)
{
   if(idx < 0 || idx >= 5)
      return;
   g_aumentos[idx].ativa = ativo;
   if(qtd <= 0.0)
      qtd = 1.0;
   if(tempoMinutos < 0)
      tempoMinutos = 0;
   if(distanciaPontos < 0)
      distanciaPontos = 0;
   if(protecaoPercent < 0.0)
      protecaoPercent = 0.0;
   if(protecaoPercent > 100.0)
      protecaoPercent = 100.0;
   g_aumentos[idx].qtd = qtd;
   g_aumentos[idx].tempoMinutos = tempoMinutos;
   g_aumentos[idx].distanciaPontos = distanciaPontos;
   g_aumentos[idx].gatilhoReais = MathAbs(gatilhoReais);
   g_aumentos[idx].protecaoPercent = protecaoPercent;
   if(InpAumentosUsarFiltrosHumanizados)
   {
      string linhaFiltro = Trim(filtrosLinha);
      if(linhaFiltro != "")
         g_aumentos[idx].filtros = ParseFiltrosDaLinha(NormalizarFiltrosHumanizados(linhaFiltro));
      else
         AplicarFiltrosHumanizadosAoAumento(idx);
   }
}

void AplicarFiltrosHumanizadosAoAumento(int idx)
{
   if(idx < 0 || idx >= 5)
      return;
   RegraFiltros f;
   ZeroMemory(f);
   f.confirmarFechamento = InpAumentosConfirmarFechamento;
   f.candlesConfirmacao = InpAumentosCandlesConfirmacao;
   if(f.candlesConfirmacao < 1)
      f.candlesConfirmacao = 1;
   f.modo = Upper(InpAumentosModoFiltro);
   if(f.modo != "TODOS" && f.modo != "MINIMO")
      f.modo = "TODOS";
   f.minOk = InpAumentosMinOkFiltro;
   if(f.minOk < 0)
      f.minOk = 0;
   f.usarHilo8 = InpAumentosFiltroHiLo;
   f.usarSTR   = InpAumentosFiltroSTR;
   f.usarDX = InpAumentosFiltroDX;
   f.dxOp   = ">=";
   f.dxMin  = MathAbs(InpAumentosDXMin);
   f.usarRSI     = InpAumentosFiltroRSI;
   f.rsiCompraOp = ">=";
   f.rsiCompraMin = MathAbs(InpAumentosRSICompraMin);
   f.rsiVendaOp  = "<=";
   f.rsiVendaMax = MathAbs(InpAumentosRSIVendaMax);
   f.usarVOLQ = InpAumentosFiltroVolumeQtd;
   f.volqOp   = ">=";
   f.volqMin  = MathAbs(InpAumentosVolumeQtdMin);
   f.usarVOLF = InpAumentosFiltroVolumeFin;
   f.volfOp   = ">=";
   f.volfMin  = MathAbs(InpAumentosVolumeFinMin);
   f.usarAGR = InpAumentosFiltroAgressao;
   f.agrOp   = ">=";
   f.agrMin  = MathAbs(InpAumentosAgressaoMin);
   g_aumentos[idx].filtros = f;
}

void AplicarFiltroToken(RegraFiltros &f, string token)
{
   token = Trim(token);
   if(token == "" || Upper(token) == "OFF")
      return;
   int pos = StringFind(token, ":");
   string nome = token;
   string args = "";
   if(pos >= 0)
   {
      nome = StringSubstr(token, 0, pos);
      args = StringSubstr(token, pos + 1);
   }
   nome = Upper(Trim(nome));
   if(nome == "HILO8")
   {
      f.usarHilo8 = IsOn(GetArg(args, "", "ON"));
      return;
   }
   if(nome == "STR")
   {
      f.usarSTR = IsOn(GetArg(args, "", "ON"));
      return;
   }
   if(nome == "DX")
   {
      f.usarDX = IsOn(GetArg(args, "", "ON"));
      f.dxOp = GetArg(args, "OP", ">=");
      f.dxMin = ExtrairNumero(GetArg(args, "MIN", "0"));
      return;
   }
   if(nome == "RSI")
   {
      f.usarRSI = IsOn(GetArg(args, "", "ON"));
      f.rsiCompraOp = GetArg(args, "C_OP", ">=");
      f.rsiCompraMin = ExtrairNumero(GetArg(args, "C_MIN", "0"));
      f.rsiVendaOp = GetArg(args, "V_OP", "<=");
      f.rsiVendaMax = ExtrairNumero(GetArg(args, "V_MAX", "100"));
      return;
   }
   if(nome == "VOLQ")
   {
      f.usarVOLQ = IsOn(GetArg(args, "", "ON"));
      f.volqOp = GetArg(args, "OP", ">=");
      f.volqMin = ExtrairNumero(GetArg(args, "MIN", "0"));
      return;
   }
   if(nome == "VOLF")
   {
      f.usarVOLF = IsOn(GetArg(args, "", "ON"));
      f.volfOp = GetArg(args, "OP", ">=");
      f.volfMin = ExtrairNumero(GetArg(args, "MIN", "0"));
      return;
   }
   if(nome == "AGR")
   {
      f.usarAGR = IsOn(GetArg(args, "", "ON"));
      f.agrOp = GetArg(args, "OP", ">=");
      f.agrMin = ExtrairNumero(GetArg(args, "MIN", "0"));
      return;
   }
   if(nome == "SCORE")
   {
      f.usarScore = IsOn(GetArg(args, "", "ON"));
      f.scoreMin = ExtrairNumero(GetArg(args, "MIN", "60"));
      f.scoreExtremo = ExtrairNumero(GetArg(args, "EXT", "85"));
      f.usarMedia25Direcional = true;
      return;
   }
   if(nome == "M25" || nome == "MEDIA25" || nome == "DIR")
   {
      f.usarMedia25Direcional = IsOn(GetArg(args, "", "ON"));
      return;
   }
}


// RESPONSABILIDADE: PREENCHIMENTO SEGURO DE ORDENS

ENUM_ORDER_TYPE_FILLING TipoPreenchimentoSeguro()
{
   // FIX317: RETURN não é permitido em Market Execution.
   // Primeiro respeita a preferência configurada quando ela é aceita;
   // depois escolhe automaticamente uma alternativa suportada pelo ativo.
   long filling=(long)SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   long execucao=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE);
   bool suportaFOK=((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK);
   bool suportaIOC=((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC);
   bool marketExecution=(execucao==SYMBOL_TRADE_EXECUTION_MARKET);

   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_FOK && suportaFOK)
      return ORDER_FILLING_FOK;
   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_IOC && suportaIOC)
      return ORDER_FILLING_IOC;
   if(InpTipoPreenchimentoOrdem==ORDER_FILLING_RETURN && !marketExecution)
      return ORDER_FILLING_RETURN;

   if(suportaIOC)
      return ORDER_FILLING_IOC;
   if(suportaFOK)
      return ORDER_FILLING_FOK;

   // Em execução Request/Instant/Exchange, RETURN é a alternativa mais segura.
   if(!marketExecution)
      return ORDER_FILLING_RETURN;

   // Proteção final para Market Execution com flags incompletas do servidor.
   // FOK evita enviar RETURN, que seria rejeitado nesse modo de execução.
   return ORDER_FILLING_FOK;
}


// RESPONSABILIDADE: NORMALIZACAO DE VOLUME

double NormalizarVolume(double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   double vol = MathFloor(volume / step) * step;
   if(vol < minVol)
      vol = minVol;
   if(maxVol > 0.0 && vol > maxVol)
      vol = maxVol;
   return NormalizeDouble(vol, 2);
}


void RegistrarDecisaoOperacional(EstadoLado &estado, string contexto, string mensagem)
{
   estado.ultimaMensagem = mensagem;
   g_mestre.mensagemGeral = mensagem;
   if(contexto == "AUMENTO" && !InpLogAumentosAguardandoExperts)
      return;
   if(!InpLogBloqueiosExperts)
      return;
   RegistrarGerenciadorOrdens(estado, contexto, mensagem, 0, 0, 0.0, 0.0, false);
}


void CSVWriteLinha(const int handle, string linha)
{
   FileWriteString(handle, linha);
   FileWriteString(handle, "\r\n");
}


void FecharLogValidacaoCSV()
{
   AuditoriaFecharFIX302();
}

bool ContextoLogValidacaoRelevante(string contexto, string mensagem, bool importante)
{
   if(!InpLogValidacaoSomenteRelevantes)
      return true;
   string c = Upper(contexto);
   string m = Upper(mensagem);
   if(importante)
      return true;
   if(StringFind(c, "A0") >= 0)
      return true;
   if(StringFind(c, "FILTRO") >= 0)
      return true;
   if(StringFind(c, "ENTRADA") >= 0)
      return true;
   if(StringFind(c, "AUMENT") >= 0)
      return true;
   if(StringFind(c, "ORDER") >= 0)
      return true;
   if(StringFind(c, "PARCIAL") >= 0)
      return true;
   if(StringFind(c, "PROTECAO") >= 0)
      return true;
   if(StringFind(c, "STOP") >= 0)
      return true;
   if(StringFind(c, "GAIN") >= 0)
      return true;
   if(StringFind(c, "SAIDA") >= 0)
      return true;
   if(StringFind(c, "BLOCK") >= 0)
      return true;
   if(StringFind(m, "BLOQUEAD") >= 0)
      return true;
   return false;
}

void LimparSnapshotEntradaFiltros()
{
   g_logFiltroTipoEntrada = "";
   g_logFiltroDecisao = "";
   g_logFiltroMotivo = "";
   g_logFiltroM25Status = "";
   g_logFiltroScoreStatus = "";
   g_logFiltroResumo = "";
   g_logFiltroDetalhe = "";
   g_logFiltroTotal = 0;
   g_logFiltroOk = 0;
   g_logFiltroScoreLado = 0.0;
   g_logFiltroDX = 0.0;
   g_logFiltroRSI = 0.0;
   g_logFiltroVolQ = 0.0;
   g_logFiltroVolF = 0.0;
   g_logFiltroAgr = 0.0;
   g_logFiltroHiloOK = "";
   g_logFiltroSTROK = "";
   g_logFiltroDXOK = "";
   g_logFiltroRSIOK = "";
   g_logFiltroVOLQOK = "";
   g_logFiltroVOLFOK = "";
   g_logFiltroAGROK = "";
}

bool MontarDiagnosticoFiltros(RegraFiltros &f,
                              ENUM_LADO_ROBO lado,
                              string &resumo,
                              string &detalhe,
                              int &total,
                              int &ok,
                              string &m25Status,
                              string &scoreStatus,
                              double &scoreLado,
                              string &hiloOK,
                              string &strOK,
                              string &dxOK,
                              string &rsiOK,
                              string &volqOK,
                              string &volfOK,
                              string &agrOK)
{
   total = 0;
   ok = 0;
   resumo = "";
   detalhe = "";
   m25Status = "NAO_USA";
   scoreStatus = "NAO_USA";
   scoreLado = ScoreDirecionalDoLado(lado);
   hiloOK = "NAO_USA";
   strOK  = "NAO_USA";
   dxOK   = "NAO_USA";
   rsiOK  = "NAO_USA";
   volqOK = "NAO_USA";
   volfOK = "NAO_USA";
   agrOK  = "NAO_USA";
   bool liberado = true;
   string motivoM25 = "";
   if(f.usarMedia25Direcional)
   {
      total++;
      bool m25OK = Media25PermiteLado(lado, motivoM25);
      m25Status = m25OK ? "OK" : "BLOQUEIA";
      if(m25OK) ok++;
   }
   if(f.usarScore)
   {
      total++;
      bool scoreOK = (scoreLado >= f.scoreMin);
      scoreStatus = scoreOK ? "OK" : "BLOQUEIA";
      if(scoreOK) ok++;
   }
   bool hiloPassou = false;
   if(f.usarHilo8)
   {
      total++;
      hiloPassou = ((lado == LADO_COMPRA && g_mercado.hiloCompra) || (lado == LADO_VENDA && g_mercado.hiloVenda));
      if(hiloPassou) ok++;
      hiloOK = hiloPassou ? "OK" : "BLOQUEIA";
   }
   bool strPassou = false;
   if(f.usarSTR)
   {
      total++;
      strPassou = ((lado == LADO_COMPRA && g_mercado.strCompra) || (lado == LADO_VENDA && g_mercado.strVenda));
      if(strPassou) ok++;
      strOK = strPassou ? "OK" : "BLOQUEIA";
   }
   bool dxPassou = false;
   if(f.usarDX)
   {
      total++;
      dxPassou = ValidarComparacao(g_mercado.dx, f.dxOp, f.dxMin);
      if(dxPassou) ok++;
      dxOK = dxPassou ? "OK" : "BLOQUEIA";
   }
   bool rsiPassou = false;
   if(f.usarRSI)
   {
      total++;
      if(lado == LADO_COMPRA)
         rsiPassou = ValidarComparacao(g_mercado.rsi, f.rsiCompraOp, f.rsiCompraMin);
      else if(lado == LADO_VENDA)
         rsiPassou = ValidarComparacao(g_mercado.rsi, f.rsiVendaOp, f.rsiVendaMax);
      if(rsiPassou) ok++;
      rsiOK = rsiPassou ? "OK" : "BLOQUEIA";
   }
   bool volqPassou = false;
   bool volfPassou = false;
   double limiteVolQ = LimiteVolumeQtdDinamico(f);
   double limiteVolF = LimiteVolumeFinDinamico(f);
   if(f.volumeCombinado)
   {
      total++;
      volqPassou = ValidarComparacao(g_mercado.volqProjetadoHora, f.volqOp, limiteVolQ);
      volfPassou = ValidarComparacao(g_mercado.volfProjetadoHora, f.volfOp, limiteVolF);
      bool volumeCompostoOK = (volqPassou && volfPassou);
      if(volumeCompostoOK) ok++;
      volqOK = volqPassou ? "OK" : "BLOQUEIA";
      volfOK = volfPassou ? "OK" : "BLOQUEIA";
   }
   else
   {
      if(f.usarVOLQ)
      {
         total++;
         volqPassou = ValidarComparacao(g_mercado.volqProjetadoHora, f.volqOp, limiteVolQ);
         if(volqPassou) ok++;
         volqOK = volqPassou ? "OK" : "BLOQUEIA";
      }
      if(f.usarVOLF)
      {
         total++;
         volfPassou = ValidarComparacao(g_mercado.volfProjetadoHora, f.volfOp, limiteVolF);
         if(volfPassou) ok++;
         volfOK = volfPassou ? "OK" : "BLOQUEIA";
      }
   }
   bool agrPassou = false;
   double agrDirecional = AgressaoDirecionalPercentual(lado);
   if(f.usarAGR)
   {
      total++;
      agrPassou = ValidarComparacao(agrDirecional, f.agrOp, f.agrMin);
      if(agrPassou) ok++;
      agrOK = agrPassou ? "OK" : "BLOQUEIA";
   }
   string forcaStatus="NAO_USA";
   if(f.usarForca)
   {
      total++;
      bool forcaPassou=(g_mercado.scoreFluxo>=f.forcaMin);
      if(forcaPassou) ok++;
      forcaStatus=forcaPassou ? "OK" : "BLOQUEIA";
   }
   string fiboStatus="NAO_USA",detalheFibo="";
   if(f.usarFibo)
   {
      total++;
      bool fiboPassou=FiboPermiteLadoFIX326(lado,f.fiboMin,detalheFibo);
      if(fiboPassou) ok++;
      fiboStatus=fiboPassou ? "OK" : "BLOQUEIA";
   }
   string wapStatus="NAO_USA",detalheWap="";
   if(f.usarWapBands)
   {
      total++;
      bool wapPassou=WapBandsPermiteLadoFIX326(lado,f.wapBandDesvios,detalheWap);
      if(wapPassou) ok++;
      wapStatus=wapPassou ? "OK" : "BLOQUEIA";
   }
   bool filtrosTecnicosOK = true;
   if(total > 0)
   {
      if(f.modo == "TODOS")
         filtrosTecnicosOK = (ok == total);
      else
         filtrosTecnicosOK = (ok >= f.minOk);
   }
   bool tecnicosLiberadosPorValidacao = false;
   if(InpValidacaoLiberarFiltrosEntradaAumento)
   {
      filtrosTecnicosOK = true;
      tecnicosLiberadosPorValidacao = true;
   }
   if(!filtrosTecnicosOK)
      liberado = false;
   resumo = StringFormat("lado=%s | resultado=%s | modo=%s | ok=%d/%d | M25=%s | SCORE=%s %.1f/min %.1f | DX=%.2f | RSI=%.2f | VOLQ=%.0f | VOLF=%.0f | AGR=%.2f | HILO C=%s V=%s | STR C=%s V=%s",
                         TextoLadoOrdem(lado),
                         liberado ? "LIBERA" : "BLOQUEIA",
                         f.modo,
                         ok,
                         total,
                         m25Status,
                         scoreStatus,
                         scoreLado,
                         f.scoreMin,
                         g_mercado.dx,
                         g_mercado.rsi,
                         g_mercado.volqProjetadoHora,
                         g_mercado.volfProjetadoHora,
                         agrDirecional,
                         ValorBoolSN(g_mercado.hiloCompra),
                         ValorBoolSN(g_mercado.hiloVenda),
                         ValorBoolSN(g_mercado.strCompra),
                         ValorBoolSN(g_mercado.strVenda));
   resumo+=StringFormat(" | FORCA=%s %.1f/min %.1f | FIBO=%s | WAP=%s",
                        forcaStatus,g_mercado.scoreFluxo,f.forcaMin,fiboStatus,wapStatus);
   detalhe = StringFormat("HILO=%s | STR=%s | DX=%s regra %.2f %s %.2f | RSI=%s C %s %.2f V %s %.2f | VOLQ=%s regra %.0f %s %.0f | VOLF=%s regra %.0f %s %.0f | AGR=%s regra %.2f %s %.2f | CONF=%s CANDLES=%d | tecnicos_liberados_validacao=%s | motivo_m25=%s",
                          hiloOK,
                          strOK,
                          dxOK,
                          g_mercado.dx,
                          f.dxOp,
                          f.dxMin,
                          rsiOK,
                          f.rsiCompraOp,
                          f.rsiCompraMin,
                          f.rsiVendaOp,
                          f.rsiVendaMax,
                          volqOK,
                          g_mercado.volqProjetadoHora,
                          f.volqOp,
                          limiteVolQ,
                          volfOK,
                          g_mercado.volfProjetadoHora,
                          f.volfOp,
                          limiteVolF,
                          agrOK,
                          agrDirecional,
                          f.agrOp,
                          f.agrMin,
                          f.confirmarFechamento ? "FECHAMENTO" : "TICK",
                          f.candlesConfirmacao,
                          ValorBoolSN(tecnicosLiberadosPorValidacao),
                          motivoM25);
   detalhe+=StringFormat(" | FORCA=%s | FIBO=%s [%s] | WAP=%s [%s]",
                         forcaStatus,fiboStatus,detalheFibo,wapStatus,detalheWap);
   return liberado;
}

void RegistrarLogEntradaFiltros(EstadoLado &estado, string contexto, string tipoEntrada, RegraFiltros &f, bool decisaoLiberada, string motivo, bool importante)
{
   if(!InpLogEntradaFiltrosAtivo)
      return;
   string resumo = "";
   string detalhe = "";
   string m25Status = "";
   string scoreStatus = "";
   string hiloOK = "";
   string strOK = "";
   string dxOK = "";
   string rsiOK = "";
   string volqOK = "";
   string volfOK = "";
   string agrOK = "";
   int total = 0;
   int ok = 0;
   double scoreLado = 0.0;
   bool diagnosticoLiberaria = MontarDiagnosticoFiltros(f, estado.lado, resumo, detalhe, total, ok, m25Status, scoreStatus, scoreLado, hiloOK, strOK, dxOK, rsiOK, volqOK, volfOK, agrOK);
   g_logFiltroTipoEntrada = tipoEntrada;
   g_logFiltroDecisao = decisaoLiberada ? "LIBERADA" : "BLOQUEADA";
   g_logFiltroMotivo = motivo;
   g_logFiltroM25Status = m25Status;
   g_logFiltroScoreStatus = scoreStatus;
   g_logFiltroResumo = resumo;
   g_logFiltroDetalhe = detalhe;
   g_logFiltroTotal = total;
   g_logFiltroOk = ok;
   g_logFiltroScoreLado = scoreLado;
   g_logFiltroDX = g_mercado.dx;
   g_logFiltroRSI = g_mercado.rsi;
   g_logFiltroVolQ = g_mercado.volqProjetadoHora;
   g_logFiltroVolF = g_mercado.volfProjetadoHora;
   g_logFiltroAgr = AgressaoDirecionalPercentual(estado.lado);
   g_logFiltroHiloOK = hiloOK;
   g_logFiltroSTROK = strOK;
   g_logFiltroDXOK = dxOK;
   g_logFiltroRSIOK = rsiOK;
   g_logFiltroVOLQOK = volqOK;
   g_logFiltroVOLFOK = volfOK;
   g_logFiltroAGROK = agrOK;
   string msg = StringFormat("%s | decisao_final=%s | diagnostico_filtro=%s | motivo=%s | %s | %s",
                             tipoEntrada,
                             decisaoLiberada ? "LIBERADA" : "BLOQUEADA",
                             diagnosticoLiberaria ? "LIBERARIA" : "BLOQUEARIA",
                             motivo,
                             resumo,
                             detalhe);
   RegistrarLogValidacaoCSV(estado, contexto, msg, 0, 0, 0.0, 0.0, importante);
   if(InpLogEntradaFiltrosNoExperts)
      Print("[COPA_AR100][FILTROS_ENTRADA] ", contexto, " | ", estado.nome, " | ", msg);
   LimparSnapshotEntradaFiltros();
}

void RegistrarLogValidacaoCSV(EstadoLado &estado, string contexto, string mensagem, uint retcode, int erro, double volume, double preco, bool importante)
{
   if(!InpLogValidacaoCSVAtivo)
      return;
   if(!ContextoLogValidacaoRelevante(contexto,mensagem,importante))
      return;
   AuditoriaRegistrarEventoFIX302(estado,contexto,mensagem,retcode,erro,volume,preco,importante);
}

void RegistrarLogValidacaoSistema(string contexto, string mensagem)
{
   // FIX302: trailing e demais mudancas importantes entram na fila leve.
   // A deduplicacao evita repeticao por tick e preserva a prova dos degraus 20/5.
   if(JanelaAtualEhA_FIX255())
      RegistrarLogValidacaoCSV(g_compra, contexto, mensagem, 0, 0, 0.0, 0.0, true);
   else
      RegistrarLogValidacaoCSV(g_venda, contexto, mensagem, 0, 0, 0.0, 0.0, true);
}

void RegistrarGerenciadorOrdens(EstadoLado &estado, string contexto, string mensagem, uint retcode, int erro, double volume, double preco, bool importante)
{
   estado.ultimaMensagem = mensagem;
   g_mestre.mensagemGeral = mensagem;
   g_ordemUltimoEvento   = mensagem;
   g_ordemUltimoContexto = contexto;
   g_ordemUltimoRetcode  = retcode > 0 ? IntegerToString((int)retcode) : "--";
   g_ordemUltimoErro     = erro > 0 ? IntegerToString(erro) : "--";
   g_ordemUltimaHora     = TimeCurrent();
   g_ordemUltimoVolume   = volume;
   g_ordemUltimoPreco    = preco;
   g_ordemUltimoMagic    = estado.magic;
   if(contexto == "ORDER_SEND")
      g_ordemTentativas++;
   else if(contexto == "ORDER_OK")
      g_ordemEnviadas++;
   else if(contexto == "ORDER_REJECT")
      g_ordemRejeitadas++;
   else if(StringFind(contexto, "BLOCK") >= 0 || StringFind(mensagem, "bloquead") >= 0 || StringFind(mensagem, "TRAVADAS") >= 0)
      g_ordemBloqueadas++;
   RegistrarLogValidacaoCSV(estado, contexto, mensagem, retcode, erro, volume, preco, importante);
   AvaliarEventoMsgBoxFIX226(contexto,mensagem,importante);
   LogExpertsGerenciador(contexto + "|" + estado.nome + "|" + mensagem, contexto, estado, mensagem, importante);
}

void LogExpertsGerenciador(string assinatura, string contexto, EstadoLado &estado, string mensagem, bool importante)
{
   if(!InpGerenciadorOrdensExperts)
      return;
   // Bloqueio repetido e estado de espera sao diagnostico, nao um novo erro
   // a cada tick. Confirmacoes e rejeicoes reais continuam imediatas.
   bool eventoRepetitivo=(!importante ||
                          StringFind(mensagem,"bloquead")>=0 ||
                          StringFind(mensagem,"JA TESTADA")>=0 ||
                          StringFind(contexto,"_LOCK")>=0);
   if(eventoRepetitivo && InpIntervaloLogRepetidoSeg > 0)
   {
      if(assinatura == g_ultimoLogAssinatura && (TimeCurrent() - g_ultimoLogHora) < InpIntervaloLogRepetidoSeg)
         return;
   }
   g_ultimoLogAssinatura = assinatura;
   g_ultimoLogHora = TimeCurrent();
   Print("[COPA_AR100][GER_ORDENS] ",
         TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
         " | ", contexto,
         " | ", estado.nome,
         " | Magic ", IntegerToString(estado.magic),
         " | Pos=", TextoPosicaoCard(estado),
         " | Ctt=", DoubleToString(estado.contratos, 2),
         " | Aberto=", FormatarMoeda(estado.resultadoAberto),
         " | Ganho QTD/R$=", TextoGanhoQtdReaisFIX362(estado.lado,false),
         " | HEAD=", TextoGanhoQtdReaisFIX362(LADO_AMBOS,true),
         " | ", TextoLossHeadGerenciadorFIX367(),
         " | ", mensagem);
}

string ResumoGerenciadorOrdens()
{
   string hora = g_ordemUltimaHora > 0 ? TimeToString(g_ordemUltimaHora, TIME_SECONDS) : "--:--:--";
   return StringFormat("GER ORDENS %s | %s | T:%d OK:%d REJ:%d BLOQ:%d | Ret:%s Err:%s | %s",
                       hora,
                       TextoModoValidacaoExecucao(),
                       g_ordemTentativas,
                       g_ordemEnviadas,
                       g_ordemRejeitadas,
                       g_ordemBloqueadas,
                       g_ordemUltimoRetcode,
                       g_ordemUltimoErro,
                       g_ordemUltimoEvento);
}


#endif // COPA_LOGS_AUDITORIA_MQH
