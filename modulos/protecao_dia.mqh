#ifndef COPA_PROTECAO_DIA_MQH
#define COPA_PROTECAO_DIA_MQH

// RESPONSABILIDADE: RISCO MESTRE E STOP DIARIO

void AtualizarRiscoMestre()
{
   // FIX360: risco operacional e entrada não usam o acumulado civil do dia.
   // A fotografia oficial da CESTA ATUAL soma somente o aberto dos dois Magics A/B.
   // O realizado permanece no histórico, sem bloquear o motor operacional.
   FotoCestaAB fotoCicloFIX360;
   CalcularFotoCestaABOficial(fotoCicloFIX360, false);
   bool cestaAbertaFIX360=(fotoCicloFIX360.qtdTotal>0.0001);

   if(!cestaAbertaFIX360)
   {
      // FLAT significa novo ciclo: nenhuma perda histórica pode travar a próxima A0.
      datetime hojeFIX362=InicioDoDia(TimeCurrent());
      bool precisavaPersistirFIX362=(MathAbs(g_mestre.melhorResultadoDiaTotal)>0.0001 ||
                                     MathAbs(g_mestre.defesaDiaTotal)>0.0001 ||
                                     g_mestre.diaLucroProtegido ||
                                     g_mestre.diaProtecaoDisparada ||
                                     g_mestre.diaProtecaoRef!=hojeFIX362);
      g_mestre.resultadoAbertoTotal=0.0;
      g_mestre.resultadoFechadoTotal=0.0;
      g_mestre.resultadoDiaTotal=0.0;
      g_mestre.bloqueadoPorMeta=false;
      g_mestre.bloqueadoPorStop=false;
      g_mestre.melhorResultadoDiaTotal=0.0;
      g_mestre.defesaDiaTotal=0.0;
      g_mestre.diaLucroProtegido=false;
      g_mestre.diaProtecaoDisparada=false;
      g_resultadoHeadCicloFIX372=0.0;
      g_melhorHeadCicloFIX372=0.0;
      g_defesaHeadCicloFIX372=0.0;
      g_escalaHeadAtivaFIX372=false;
      g_mestre.diaProtecaoRef=hojeFIX362;
      if(precisavaPersistirFIX362)
         PersistirProtecaoDiaEscalonadaFIX333();
      return;
   }

   g_mestre.resultadoAbertoTotal=NormalizeDouble(fotoCicloFIX360.abertoTotal,2);
   g_mestre.resultadoFechadoTotal=NormalizeDouble(fotoCicloFIX360.realizadoTotal,2);
   g_mestre.resultadoDiaTotal=NormalizeDouble(fotoCicloFIX360.saldoTotal,2);
   g_resultadoHeadCicloFIX372=g_mestre.resultadoDiaTotal;
   g_mestre.bloqueadoPorMeta=false; // FIX372: nao existe trava maxima de ganho
   g_risco.stopDia=LossHeadEfetivoFIX362();
   g_mestre.bloqueadoPorStop=(g_mestre.resultadoDiaTotal<=-g_risco.stopDia);
   AtualizarProtecaoResultadoDia();
}

bool GerenciarStopDiaMestreFIX320()
{
   // Somente a janela A proprietaria atua como MESTRE. As pontas continuam
   // independentes ate o limite financeiro global ser realmente atingido.
   if(!InstanciaMestreGrupoFIX255() || !g_coordenacaoMagicsOK_FIX256)
      return false;
   if(!g_mestre.bloqueadoPorStop || g_risco.stopDia<=0.0)
      return false;
   bool temCompra=g_compra.posicaoAberta;
   bool temVenda=g_venda.posicaoAberta;
   if(!temCompra && !temVenda)
      return false;
   datetime agora=TimeCurrent();
   if(g_ultimaTentativaStopDiaMestreFIX320>0 &&
      (agora-g_ultimaTentativaStopDiaMestreFIX320)<1)
      return true;
   g_ultimaTentativaStopDiaMestreFIX320=agora;
   string msg=StringFormat("STOP MOVEL A+B: aberto compra+venda %s | realizado separado %s | saldo operacional %s <= -%s | encerrando as duas pontas",
                           PnlMoedaBRL(g_mestre.resultadoAbertoTotal),
                           PnlMoedaBRL(g_mestre.resultadoFechadoTotal),
                           PnlMoedaBRL(g_mestre.resultadoDiaTotal),
                           PnlMoedaBRL(g_risco.stopDia));
   g_mestre.mensagemGeral=msg;
   RegistrarLogValidacaoSistema("FIX320_STOP_DIA_MESTRE",msg);
   if(temCompra) FecharPosicoesLado(g_compra,"STOP_MOVEL_CESTA_AB_FIX360");
   if(temVenda)  FecharPosicoesLado(g_venda, "STOP_MOVEL_CESTA_AB_FIX360");
   return true;
}


bool EscalonamentoGanhosAtivo()
{
   return InpMetaDiaEscalonadaAtiva;
}

bool ValidarParametrosOperacionaisFIX331(string &erro)
{
   erro="";
   if((int)InpLadosHabilitadosFIX346<(int)OPERACAO_COMPRA ||
      (int)InpLadosHabilitadosFIX346>(int)OPERACAO_AMBOS)
      erro="Seleção de lados habilitados é inválida.";
   else if(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL &&
      (!InpConfirmarContaRealFIX342 || InpContaRealAutorizadaFIX342<=0 || Trim(InpServidorRealAutorizadoFIX342)==""))
      erro="Produção REAL exige confirmação, login e servidor autorizados.";
   else if(InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL &&
           (InpComoAbrirPrimeiraOrdem!=PRIMEIRA_ORDEM_NORMAL || InpCenarioAuditoriaFIX302!=AUD302_USAR_CONFIG_ATUAL))
      erro="Produção REAL exige A0 NORMAL COM SINAIS e cenário CONFIG ATUAL.";
   else if(!InpStopServidorEmergenciaAtivoFIX342 || InpStopServidorEmergenciaPontosFIX342<=0.0)
      erro="Stop de emergência no servidor deve permanecer ativo e maior que zero.";
   else if(InpSpreadMaximoTicksFIX342<=0.0 || InpTickMaximoIdadeSegundosFIX342<1)
      erro="Limites de spread e idade da cotação devem ser positivos.";
   else if(InpMargemLivreMinimaReaisFIX342<0.0 || InpNivelMargemMinimoPercentFIX342<=0.0)
      erro="Limites de margem da produção são inválidos.";
   else if(InpMaxContratosBrutosABFIX342<=0.0)
      erro="Limite bruto de contratos A+B deve ser maior que zero.";
   else if(InpMaxExposicaoLiquidaABFIX342<=0.0 || InpMaxExposicaoLiquidaABFIX342>InpMaxContratosBrutosABFIX342)
      erro="Exposição líquida A+B deve ser positiva e não superar a exposição bruta.";
   else if(InpFiltroRangeAtivoFIX344 &&
           (InpRangeMinimoPontosFIX344<0.0 || InpRangeMaximoPontosFIX344<=0.0 ||
            InpRangeMinimoPontosFIX344>InpRangeMaximoPontosFIX344))
      erro="Filtro range exige minimo >= 0, maximo > 0 e minimo <= maximo.";
   else if(InpGridEntradasAtivoFIX344 &&
           (InpGridTamanhoPontosFIX344<=0.0 || InpGridToleranciaPontosFIX344<0.0 ||
            InpGridToleranciaPontosFIX344>InpGridTamanhoPontosFIX344*0.5))
      erro="Grid exige tamanho positivo e tolerancia entre zero e metade do grid.";
   else if(InpBloquearDiasAntesVencimentoFIX342<0 || InpIntervaloMinimoOrdensRealSegFIX342<1)
      erro="Vencimento e intervalo mínimo de ordens possuem valor inválido.";
   else if(InpQuantidadeReforcos<0 || InpQuantidadeReforcos>5)
      erro="Quantidade de aumentos deve ficar entre 0 e 4.";
   else if(InpGanhoPorTicketReaisFIX372<=0.0 || InpPerdaPorTicketReaisFIX372<=0.0)
      erro="Ganho e perda por ticket devem ser maiores que zero.";
   else if(InpGarantiaPorContratoReaisFIX372<=0.0 || InpGarantiaPorLadoReaisFIX372<=0.0)
      erro="Garantia por contrato e por lado devem ser maiores que zero.";
   else if(InpGarantiaPorLadoReaisFIX372+0.0001 < InpGarantiaPorContratoReaisFIX372)
      erro="Garantia por lado nao pode ser menor que a garantia de um contrato.";
   else if(InpReentradaLucroSegundosFIX372<0 || InpPausaReentradaSegundos<0)
      erro="Tempos de reentrada nao podem ser negativos.";
   else if(InpDXPeriodo<1 || InpDXMediaPeriodo<1)
      erro="Períodos DX devem ser maiores que zero.";
   else if(InpDesvioMaximoPontos<0)
      erro="Desvio máximo da ordem não pode ser negativo.";
   else if((int)InpTimeframeFiltrosOperacionais!=(int)PERIOD_M5 &&
           (int)InpTimeframeFiltrosOperacionais!=(int)PERIOD_M10)
      erro="Timeframe dos filtros deve ser M5 ou M10.";
   else if(InpMargemExecucaoAlemLinhaPontos<=0.0 || InpMargemExecucaoAlemLinhaPontos>5000.0)
      erro="Margem alem da linha deve ser maior que zero e no maximo 5000 pontos.";
   else if(InpAumentoFolgaRompimentoPontos<0.0 || InpAumentoFolgaRompimentoPontos>1000.0)
      erro="Folga do rompimento deve ficar entre zero e 1000 pontos.";
   else if(InpAumentoValidadeRompimentoCandles<1 || InpAumentoValidadeRompimentoCandles>20)
      erro="Validade do rompimento deve ficar entre 1 e 20 candles.";
   else if(InpScoreVolumeAumentosAtivo && (InpScoreVolumeMediaCandles<3 || InpScoreVolumeMediaCandles>200))
      erro="Média do score de volume deve ficar entre 3 e 200 candles.";
   else if(InpScoreVolumeAumentosAtivo &&
           (InpScoreVolumeMinA1<0.0 || InpScoreVolumeMinA1>100.0 ||
            InpScoreVolumeMinA2<0.0 || InpScoreVolumeMinA2>100.0 ||
            InpScoreVolumeMinA3<0.0 || InpScoreVolumeMinA3>100.0 ||
            InpScoreVolumeMinA4<0.0 || InpScoreVolumeMinA4>100.0))
      erro="Score de volume A1-A4 deve ficar entre zero e 100.";
   else if(InpScoreVolumeAumentosAtivo &&
           (InpScoreVolumeMinA2<InpScoreVolumeMinA1 ||
            InpScoreVolumeMinA3<InpScoreVolumeMinA2 ||
            InpScoreVolumeMinA4<InpScoreVolumeMinA3))
      erro="Score de volume deve crescer ou permanecer igual de A1 ate A4.";
   else if(InpCorredorLucroAtivo && InpCorredorAtivarReais<=0.0)
      erro="Ativacao do corredor de lucro deve ser maior que zero.";
   else if(InpCorredorLucroAtivo &&
           (InpCorredorPisoInicialReais<0.0 || InpCorredorPisoInicialReais>=InpCorredorAtivarReais))
      erro="Piso inicial do corredor deve ficar entre zero e a ativacao.";
   else if(InpCorredorLucroAtivo && InpCorredorDegrauReais<=0.0)
      erro="Degrau do corredor de lucro deve ser maior que zero.";
   else if(InpCorredorLucroAtivo &&
           (InpCorredorFolgaForteReais<=0.0 ||
            InpCorredorFolgaNeutraReais<=0.0 ||
            InpCorredorFolgaViradaReais<=0.0 ||
            InpCorredorFolgaForteReais<InpCorredorFolgaNeutraReais ||
            InpCorredorFolgaNeutraReais<InpCorredorFolgaViradaReais))
      erro="Folgas do corredor devem seguir FORTE >= NEUTRA >= VIRADA e ser positivas.";
   else if(InpCorredorLucroAtivo &&
           (InpCorredorConfirmacoesVirada<1 || InpCorredorConfirmacoesVirada>5))
      erro="Confirmacoes de virada do corredor devem ficar entre 1 e 5 candles.";
   if(erro!="" || !InpMetaDiaEscalonadaAtiva)
      return (erro=="");
   if(InpProtecaoDiaAtivarReais<=0.0)
      erro="Ativacao da escala HEAD deve ser maior que zero.";
   else if(InpProtecaoDiaInicialReais<=0.0 || InpProtecaoDiaInicialReais>=InpProtecaoDiaAtivarReais)
      erro="Defesa de 250 deve ficar entre zero e a ativacao.";
   else if(InpDefesaEscala300ReaisFIX372<InpProtecaoDiaInicialReais || InpDefesaEscala300ReaisFIX372>=300.0)
      erro="Defesa de 300 deve ser crescente e menor que 300.";
   else if(InpDefesaEscala350ReaisFIX372<InpDefesaEscala300ReaisFIX372 || InpDefesaEscala350ReaisFIX372>=350.0)
      erro="Defesa de 350 deve ser crescente e menor que 350.";
   else if(InpRecuoEscala400ReaisFIX372<=0.0 || InpRecuoEscala500ReaisFIX372<=0.0 || InpRecuoEscala600ReaisFIX372<=0.0)
      erro="Recuos de 400, 500 e 600 devem ser positivos.";
   else if(InpPassoLucroAcima600ReaisFIX372<=0.0 || InpAumentoRecuoAcima600ReaisFIX372<0.0)
      erro="Passo e aumento de recuo acima de 600 sao invalidos.";
   if(erro!="")
      return false;
   return true;
}

double DefesaMetaDiaEscalonadaFIX331(double melhorLucro, double &etapaAtingida)
{
   etapaAtingida=0.0;
   if(!EscalonamentoGanhosAtivo())
      return -1.0;
   double maximo=MathMax(0.0,melhorLucro);
   double ativacao=MathAbs(InpProtecaoDiaAtivarReais);
   if(ativacao<=0.0 || maximo<ativacao)
      return -1.0;

   double defesa=0.0;
   if(maximo<300.0)
   {
      etapaAtingida=250.0;
      defesa=MathAbs(InpProtecaoDiaInicialReais);
   }
   else if(maximo<350.0)
   {
      etapaAtingida=300.0;
      defesa=MathAbs(InpDefesaEscala300ReaisFIX372);
   }
   else if(maximo<400.0)
   {
      etapaAtingida=350.0;
      defesa=MathAbs(InpDefesaEscala350ReaisFIX372);
   }
   else if(maximo<500.0)
   {
      etapaAtingida=400.0;
      defesa=etapaAtingida-MathAbs(InpRecuoEscala400ReaisFIX372);
   }
   else if(maximo<600.0)
   {
      etapaAtingida=500.0;
      defesa=etapaAtingida-MathAbs(InpRecuoEscala500ReaisFIX372);
   }
   else
   {
      double passo=MathAbs(InpPassoLucroAcima600ReaisFIX372);
      if(passo<=0.0) passo=100.0;
      double k=MathFloor((maximo-600.0)/passo);
      if(k<0.0) k=0.0;
      etapaAtingida=600.0+(k*passo);
      double recuo=MathAbs(InpRecuoEscala600ReaisFIX372)+(k*MathAbs(InpAumentoRecuoAcima600ReaisFIX372));
      defesa=etapaAtingida-recuo;
   }
   if(defesa<0.0) defesa=0.0;
   if(defesa>maximo) defesa=maximo;
   return NormalizeDouble(defesa,2);
}

double NivelEscalonamentoAtual(double melhorLucro)
{
   double etapa=0.0;
   DefesaMetaDiaEscalonadaFIX331(melhorLucro,etapa);
   return etapa;
}


double CalcularDefesaEscalonadaPorGanho(double melhorLucro)
{
   double etapa=0.0;
   return DefesaMetaDiaEscalonadaFIX331(melhorLucro,etapa);
}

string TextoEscalonamentoGanhosPainel(double melhorLucro)
{
   if(!EscalonamentoGanhosAtivo())
      return "ESC OFF";
   double inicio=MathAbs(InpProtecaoDiaAtivarReais);
   double nivel = NivelEscalonamentoAtual(melhorLucro);
   if(nivel <= 0.0)
      return StringFormat("ESC aguarda +%.0f", inicio);
   double defesa = CalcularDefesaEscalonadaPorGanho(melhorLucro);
   return StringFormat("ESC +%.0f | DEF %s | SEM TETO",nivel,PnlMoedaBRL(defesa));
}

string ChaveProtecaoDiaEscalonadaFIX333(string campo)
{
   return ChaveGlobalCurtaAB()+"FIX333_PROTECAO_DIA_"+campo;
}

void PersistirProtecaoDiaEscalonadaFIX333()
{
   if(!MathIsValidNumber(g_mestre.melhorResultadoDiaTotal) || !MathIsValidNumber(g_mestre.defesaDiaTotal))
   {
      Print("[COPA_AR100][V36][PROTECAO_NAO_GRAVADA] valor financeiro invalido.");
      return;
   }
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("V"),0.0);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("DATA"),(double)g_mestre.diaProtecaoRef);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("MELHOR"),g_mestre.melhorResultadoDiaTotal);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("DEFESA"),g_mestre.defesaDiaTotal);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("ATIVA"),g_mestre.diaLucroProtegido ? 1.0 : 0.0);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("DISPAROU"),g_mestre.diaProtecaoDisparada ? 1.0 : 0.0);
   GlobalVariableSet(ChaveProtecaoDiaEscalonadaFIX333("V"),(double)TimeCurrent());
   GlobalVariablesFlush();
}

void RestaurarProtecaoDiaEscalonadaFIX333(datetime hoje)
{
   string chaveData=ChaveProtecaoDiaEscalonadaFIX333("DATA");
   datetime dataSalva=(GlobalVariableCheck(chaveData) ? (datetime)GlobalVariableGet(chaveData) : 0);
   string chaveVersao=ChaveProtecaoDiaEscalonadaFIX333("V");
   if(GlobalVariableCheck(chaveVersao) && GlobalVariableGet(chaveVersao)<=0.0)
      dataSalva=0; // escrita interrompida; nunca restaurar conjunto parcial
   if(dataSalva!=hoje)
   {
      g_mestre.diaProtecaoRef=hoje;
      g_mestre.melhorResultadoDiaTotal=0.0;
      g_mestre.defesaDiaTotal=0.0;
      g_mestre.diaLucroProtegido=false;
      g_mestre.diaProtecaoDisparada=false;
      PersistirProtecaoDiaEscalonadaFIX333();
      return;
   }
   g_mestre.diaProtecaoRef=hoje;
   g_mestre.melhorResultadoDiaTotal=GlobalVariableCheck(ChaveProtecaoDiaEscalonadaFIX333("MELHOR")) ? GlobalVariableGet(ChaveProtecaoDiaEscalonadaFIX333("MELHOR")) : 0.0;
   g_mestre.defesaDiaTotal=GlobalVariableCheck(ChaveProtecaoDiaEscalonadaFIX333("DEFESA")) ? GlobalVariableGet(ChaveProtecaoDiaEscalonadaFIX333("DEFESA")) : 0.0;
   if(!MathIsValidNumber(g_mestre.melhorResultadoDiaTotal) || !MathIsValidNumber(g_mestre.defesaDiaTotal) ||
      g_mestre.melhorResultadoDiaTotal<0.0 || g_mestre.defesaDiaTotal<0.0 ||
      g_mestre.defesaDiaTotal>g_mestre.melhorResultadoDiaTotal)
   {
      g_mestre.melhorResultadoDiaTotal=0.0;
      g_mestre.defesaDiaTotal=0.0;
      g_mestre.diaLucroProtegido=false;
      g_mestre.diaProtecaoDisparada=false;
      Print("[COPA_AR100][V36][PROTECAO_INVALIDA] checkpoint descartado e reconstruido.");
      PersistirProtecaoDiaEscalonadaFIX333();
      return;
   }
   g_mestre.diaLucroProtegido=(GlobalVariableCheck(ChaveProtecaoDiaEscalonadaFIX333("ATIVA")) && GlobalVariableGet(ChaveProtecaoDiaEscalonadaFIX333("ATIVA"))>0.5);
   g_mestre.diaProtecaoDisparada=(GlobalVariableCheck(ChaveProtecaoDiaEscalonadaFIX333("DISPAROU")) && GlobalVariableGet(ChaveProtecaoDiaEscalonadaFIX333("DISPAROU"))>0.5);
}

void AtualizarProtecaoResultadoDia()
{
   // FIX362: a protecao pertence somente a cesta aberta atual.
   if(!ExistePosicaoAbertaGrupoTotalAB())
   {
      datetime hojeFIX362=InicioDoDia(TimeCurrent());
      bool precisavaPersistirFIX362=(MathAbs(g_mestre.melhorResultadoDiaTotal)>0.0001 ||
                                     MathAbs(g_mestre.defesaDiaTotal)>0.0001 ||
                                     g_mestre.diaLucroProtegido ||
                                     g_mestre.diaProtecaoDisparada ||
                                     g_mestre.diaProtecaoRef!=hojeFIX362);
      g_mestre.melhorResultadoDiaTotal=0.0;
      g_mestre.defesaDiaTotal=0.0;
      g_mestre.diaLucroProtegido=false;
      g_mestre.diaProtecaoDisparada=false;
      g_mestre.diaProtecaoRef=hojeFIX362;
      if(precisavaPersistirFIX362)
         PersistirProtecaoDiaEscalonadaFIX333();
      return;
   }
   if(!EscalonamentoGanhosAtivo())
      return;
   datetime hoje = InicioDoDia(TimeCurrent());
   RestaurarProtecaoDiaEscalonadaFIX333(hoje);
   if(g_mestre.diaProtecaoDisparada)
   {
      g_mestre.bloqueadoPorMeta=true;
      g_mestre.mensagemGeral=StringFormat("ESCALA HEAD EXECUTADA | melhor %s | defesa %s | aguardando fechamento total do ciclo.",
                                          PnlMoedaBRL(g_mestre.melhorResultadoDiaTotal),
                                          PnlMoedaBRL(g_mestre.defesaDiaTotal));
      if(InstanciaMestreGrupoFIX255() && g_coordenacaoMagicsOK_FIX256 && ExistePosicaoAbertaGrupoTotalAB())
         FecharCestaABOficial("DEFESA_HEAD_ESCALONADA_RETRY_FIX372");
      return;
   }
   if(g_mestre.resultadoDiaTotal > g_mestre.melhorResultadoDiaTotal)
   {
      g_mestre.melhorResultadoDiaTotal = g_mestre.resultadoDiaTotal;
      PersistirProtecaoDiaEscalonadaFIX333();
   }
   double defesaDia = CalcularDefesaEscalonadaPorGanho(g_mestre.melhorResultadoDiaTotal);
   g_resultadoHeadCicloFIX372=g_mestre.resultadoDiaTotal;
   g_melhorHeadCicloFIX372=g_mestre.melhorResultadoDiaTotal;
   if(defesaDia >= 0.0)
   {
      g_mestre.diaLucroProtegido = true;
      g_escalaHeadAtivaFIX372=true;
      if(defesaDia > g_mestre.defesaDiaTotal)
      {
         g_mestre.defesaDiaTotal = defesaDia;
         g_defesaHeadCicloFIX372=defesaDia;
         PersistirProtecaoDiaEscalonadaFIX333();
      }
   }
   if(g_mestre.diaLucroProtegido &&
      g_mestre.defesaDiaTotal > 0.0 &&
      g_mestre.resultadoDiaTotal <= g_mestre.defesaDiaTotal)
   {
      g_mestre.bloqueadoPorMeta = true;
      g_mestre.mensagemGeral = StringFormat("DEFESA HEAD: resultado do ciclo %s <= defesa %s | melhor %s | fechando A+B.",
                                             PnlMoedaBRL(g_mestre.resultadoDiaTotal),
                                             PnlMoedaBRL(g_mestre.defesaDiaTotal),
                                             PnlMoedaBRL(g_mestre.melhorResultadoDiaTotal));
      if(!g_mestre.diaProtecaoDisparada)
      {
         g_mestre.diaProtecaoDisparada = true;
         PersistirProtecaoDiaEscalonadaFIX333();
         // Apenas a Janela A coordena a saída global; a Janela B somente lê o estado.
         if(InstanciaMestreGrupoFIX255() && g_coordenacaoMagicsOK_FIX256 && ExistePosicaoAbertaGrupoTotalAB())
            FecharCestaABOficial("DEFESA_HEAD_ESCALONADA_FIX372");
      }
   }
}


// RESPONSABILIDADE: AUXILIARES DE PROTECAO POR LADO E CESTA

double ResultadoProtecaoOperacaoLado(EstadoLado &estado)
{
   double total = estado.resultadoFechado + estado.resultadoAberto;
   return total;
}

bool CestaABTemDuasPontasAbertas()
{
   if(!RiscoOperacaoModoCesta())
      return false;
   return CestaABTemDuasPontasAbertasGrupo();
}


#endif // COPA_PROTECAO_DIA_MQH
