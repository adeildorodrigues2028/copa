#ifndef COPA_INDICADORES_GESTAO_MQH
#define COPA_INDICADORES_GESTAO_MQH

// ============================================================================
// RESPONSABILIDADE: INDICADORES, TRAILING E CONFIGURACAO DOS AUMENTOS
// Funcoes movidas do principal na V40 sem alteracao de regra operacional.
// ============================================================================

bool InicializarIndicadores()
{
   int periodoDX = InpDXPeriodo;
   if(periodoDX <= 0)
      periodoDX = 2;
   int periodoMediaGrafico = PeriodoMediaGraficoEfetivo();
   g_handleADX = iADX(_Symbol, TimeframeFiltroAtualFIX255(), periodoDX);
   g_handleMedia25Grafico = iMA(_Symbol,
                                (ENUM_TIMEFRAMES)_Period,
                                periodoMediaGrafico,
                                0,
                                InpMedia25MetodoGrafico,
                                InpMedia25PrecoGrafico);
   int periodoRSIAumentosFIX399=InpRSIPeriodoAumentosFIX399;
   if(periodoRSIAumentosFIX399<2) periodoRSIAumentosFIX399=14;
   g_handleRSI = iRSI(_Symbol, TimeframeFiltroAtualFIX255(), periodoRSIAumentosFIX399, PRICE_CLOSE);
   if(g_handleADX == INVALID_HANDLE || g_handleRSI == INVALID_HANDLE)
   {
      g_mestre.mensagemGeral = "Aviso: DX/RSI interno nao inicializou corretamente.";
      return false;
   }
   if(g_handleMedia25Grafico == INVALID_HANDLE && InpGerenciadorOrdensExperts)
      Print("[COPA_AR100][MEDIA_GRAFICA] Aviso: media grafica do grafico nao inicializou.");
   GarantirDXIndicadorNoGrafico();
   GarantirOsciladoresSelecionadosFIX343();
   return true;
}

void LiberarIndicadores()
{
   RemoverOsciladoresSelecionadosFIX343();
   RemoverDXVisualEditavelFIX345();
   if(g_handleADX != INVALID_HANDLE)
      IndicatorRelease(g_handleADX);
   if(g_handleMedia25Grafico != INVALID_HANDLE)
      IndicatorRelease(g_handleMedia25Grafico);
   if(g_handleRSI != INVALID_HANDLE)
      IndicatorRelease(g_handleRSI);
}

void AplicarTrailingInteligenteLinhasFIX325()
{
   string linha=InpTrailingInteligenteLinhasFIX325;
   StringReplace(linha,"|",";");
   g_trailInteligenteLinhasAtivoFIX325=IsOn(GetCampo(linha,"","ON"));
   g_trailInteligenteAtivaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"ATIVA","75")));
   g_trailInteligentePassoPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"PASSO","35")));
   g_trailInteligenteDistanciaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"DIST","75")));
   g_trailInteligenteReduzirFIX325=IsOn(GetCampo(linha,"REDUZ","ON"));
   g_trailInteligenteReducaoPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"REDUZ_PTS","35")));
   g_trailInteligenteDistanciaMinimaPontosFIX325=MathAbs(ExtrairNumero(GetCampo(linha,"MIN","10")));
   g_trailInteligenteApitarFIX325=IsOn(GetCampo(linha,"APITO","ON"));
   if(g_trailInteligenteAtivaPontosFIX325<=0.0) g_trailInteligenteAtivaPontosFIX325=75.0;
   if(g_trailInteligentePassoPontosFIX325<=0.0) g_trailInteligentePassoPontosFIX325=35.0;
   if(g_trailInteligenteDistanciaPontosFIX325<=0.0) g_trailInteligenteDistanciaPontosFIX325=75.0;
   if(g_trailInteligenteReducaoPontosFIX325<=0.0) g_trailInteligenteReducaoPontosFIX325=35.0;
   if(g_trailInteligenteDistanciaMinimaPontosFIX325<=0.0) g_trailInteligenteDistanciaMinimaPontosFIX325=10.0;
   // Distancia minima maior que a inicial impediria a reducao; limita ao valor inicial.
   if(g_trailInteligenteDistanciaMinimaPontosFIX325>g_trailInteligenteDistanciaPontosFIX325)
      g_trailInteligenteDistanciaMinimaPontosFIX325=g_trailInteligenteDistanciaPontosFIX325;
}

void AplicarGestaoAumentosCompactaFIX324()
{
   AplicarTrailingInteligenteLinhasFIX325();
   string linha=InpGestaoAumentosFIX324;
   StringReplace(linha,"|",";");

   double contratos=ExtrairNumero(GetCampo(linha,"QTD",GetCampo(linha,"CONTRATOS","1")));
   int espera=ExtrairInteiro(GetCampo(linha,"TIMER",GetCampo(linha,"TEMPO","0")));
   double gatilho=MathAbs(ExtrairNumero(GetCampo(linha,"GATILHO",GetCampo(linha,"G","20"))));
   int distancia=(int)MathRound(MathAbs(ExtrairNumero(GetCampo(linha,"DIST",GetCampo(linha,"DISTANCIA","100")))));
   double alvo=MathAbs(ExtrairNumero(GetCampo(linha,"ALVO",GetCampo(linha,"GAIN",GetCampo(linha,"GANHO","100")))));
   double perda=MathAbs(ExtrairNumero(GetCampo(linha,"PERDA",GetCampo(linha,"LOSS",GetCampo(linha,"STOP","100")))));
   string trail=GetCampo(linha,"TRAIL",GetCampo(linha,"TRAILING","20/5"));
   double proteger=20.0;
   double passo=5.0;
   ParseTrailAumentoFIX282(trail,proteger,passo);

   if(contratos<=0.0) contratos=1.0;
   if(espera<0) espera=0;
   if(gatilho<0.0) gatilho=0.0;
   if(distancia<1) distancia=1;
   if(alvo<=0.0) alvo=100.0;
   if(perda<=0.0) perda=100.0;

   InpContratosPorReforco=contratos;
   InpEsperaAntesReforcoMinutos=espera;
   InpDistanciaEntreReforcosPontos=distancia;
   InpLucroAumentoPorContratoReaisFIX207=alvo;
   InpLossAumentoPorContratoReaisFIX321=perda;
   InpTrailingAumentoAtivarReaisFIX281=proteger;
   InpTrailingAumentoPassoReaisFIX281=passo;
   InpLucroAumentoPorContratoReaisFIX207=10.0; // FIX447: alvo de teste por ticket.
   InpAumentoFecharNoAlvoFIX281=true; // FIX447: fecha somente o ticket do nivel em +R$10.

   string perfilA0=Trim(g_perfilA0PadraoFIX372);
   if(perfilA0=="") perfilA0="LIVRE";
   string perfilAumento=Trim(g_perfilAumentosFIX372);
   if(perfilAumento=="") perfilAumento="LIVRE";
   InpPerfilFiltrosAuditoriaFIX302=perfilA0;
   // FIX377: cada aumento usa sua propria linha visivel de filtros.
   InpA1Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA1CompactoFIX375);
   InpA2Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA2CompactoFIX375);
   InpA3Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA3CompactoFIX375);
   InpA4Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA4CompactoFIX375);
   InpA5Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA5CompactoFIX375);

   string j1=MontarPerfilTresFiltrosFIX372(InpJanela1Filtro1FIX372,InpJanela1Filtro2FIX372,InpJanela1Filtro3FIX372);
   string j2=MontarPerfilTresFiltrosFIX372(InpJanela2Filtro1FIX372,InpJanela2Filtro2FIX372,InpJanela2Filtro3FIX372);
   string j3=MontarPerfilTresFiltrosFIX372(InpJanela3Filtro1FIX372,InpJanela3Filtro2FIX372,InpJanela3Filtro3FIX372);
   string j4=MontarPerfilTresFiltrosFIX372(InpJanela4Filtro1FIX372,InpJanela4Filtro2FIX372,InpJanela4Filtro3FIX372);
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
   {
      InpJanela1Filtros="LIVRE"; InpJanela2Filtros="LIVRE";
      InpJanela3Filtros="LIVRE"; InpJanela4Filtros="LIVRE";
      InpA1Filtros="LIVRE"; InpA2Filtros="LIVRE"; InpA3Filtros="LIVRE"; InpA4Filtros="LIVRE"; InpA5Filtros="LIVRE";
   }
   else
   {
      InpJanela1Filtros=PerfilJanelaOuPadraoFIX372(0,j1,perfilA0);
      InpJanela2Filtros=PerfilJanelaOuPadraoFIX372(1,j2,perfilA0);
      InpJanela3Filtros=PerfilJanelaOuPadraoFIX372(2,j3,perfilA0);
      InpJanela4Filtros=PerfilJanelaOuPadraoFIX372(3,j4,perfilA0);
   }
}


#endif // COPA_INDICADORES_GESTAO_MQH
