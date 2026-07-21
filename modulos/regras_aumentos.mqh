#ifndef COPA_REGRAS_AUMENTOS_MQH
#define COPA_REGRAS_AUMENTOS_MQH

// ============================================================================
// RESPONSABILIDADE: PARSER, SCORE E REGRAS DOS AUMENTOS
// Funcoes movidas do principal na V38 sem alteracao de regra operacional.
// ============================================================================

RegraJanela ParseJanela(string linha)
{
   RegraJanela j;
   ZeroMemory(j);
   j.ativa = IsOn(GetCampo(linha, "", "ON"));
   j.horario = GetCampo(linha, "HOR", "00:00-23:59");
   ParseHorario(j.horario, j.minutoInicio, j.minutoFim);
   j.lado = ParseLado(GetCampo(linha, "LADO", "AMBOS"));
   j.entradaAtiva = IsOn(GetCampo(linha, "A0", GetCampo(linha, "ENT", "ON")));
   j.qtd = ExtrairNumero(GetCampo(linha, "QTD", "1"));
   j.perfil = Upper(GetCampo(linha, "PERFIL", "DINAMICO"));
   j.filtros = ParseFiltrosDaLinha(linha);
   return j;
}

void ParseTrailAumentoFIX282(string campo, double &ativar, double &passo)
{
   ativar = MathAbs(InpTrailingAumentoAtivarReaisFIX281);
   passo = MathAbs(InpTrailingAumentoPassoReaisFIX281);
   string valor = Trim(campo);
   int eq = StringFind(valor,"=");
   if(eq >= 0)
      valor = Trim(StringSubstr(valor,eq+1));
   string partes[];
   int total = StringSplit(valor,'/',partes);
   if(total >= 1 && Trim(partes[0]) != "")
      ativar = MathAbs(ExtrairNumero(partes[0]));
   if(total >= 2 && Trim(partes[1]) != "")
      passo = MathAbs(ExtrairNumero(partes[1]));
   if(ativar <= 0.0) ativar = 20.0;
   if(passo <= 0.0) passo = 5.0;
}

void ParseMovelAumentoFIX442(string campo, double &ativar, double &defender)
{
   ativar=0.0;
   defender=0.0;
   string valor=Trim(campo);
   int eq=StringFind(valor,"=");
   if(eq>=0) valor=Trim(StringSubstr(valor,eq+1));
   string partes[];
   int total=StringSplit(valor,'/',partes);
   if(total>=1 && Trim(partes[0])!="") ativar=MathAbs(ExtrairNumero(partes[0]));
   if(total>=2 && Trim(partes[1])!="") defender=MathAbs(ExtrairNumero(partes[1]));
   if(ativar<=0.0)
   {
      ativar=0.0;
      defender=0.0;
   }
   if(defender>ativar) defender=ativar;
}

RegraAumento ParseAumento(string linha)
{
   RegraAumento a;
   ZeroMemory(a);
   linha = NormalizarLinhaAumentoHumanizada(linha);
   a.ativa = IsOn(GetCampo(linha, "", "ON"));
   a.qtd = ExtrairNumero(GetCampo(linha, "QTD", "1"));
   a.tempoMinutos = ExtrairInteiro(GetCampo(linha, "TEMPO", "0m"));
   a.distanciaPontos = ExtrairInteiro(GetCampo(linha, "DIST", "0pts"));
   a.gatilhoReais = ExtrairNumero(GetCampo(linha, "GATILHO", "0G"));
   a.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT", "0%"));
   ParseMovelAumentoFIX442(GetCampo(linha, "MOVEL", "0/0"), a.movelAtivarReais, a.movelDefenderReais);
   ParseTrailAumentoFIX282(GetCampo(linha, "TRAIL", "0/0"), a.trailingAtivarReais, a.trailingPassoReais);
   a.lado = ParseLado(GetCampo(linha, "LADO", "AMBOS"));
   a.filtros = ParseFiltrosDaLinha(linha);
   return a;
}

void ParseGerenciadorAumentos(string linha)
{
   ZeroMemory(g_gerAumentos);
   g_gerAumentos.ativo = IsOn(GetCampo(linha, "", "ON"));
   g_gerAumentos.modo = Upper(GetCampo(linha, "MODO", "DINAMICO"));
   g_gerAumentos.maxAumentos = ExtrairInteiro(GetCampo(linha, "MAX_AUMENTOS", GetCampo(linha, "MAX_AUM", "5")));
   g_gerAumentos.maxContratos = ExtrairInteiro(GetCampo(linha, "MAX_CONTRATOS", GetCampo(linha, "MAX_CONTR", "100000")));
   g_gerAumentos.scoreNormalMax = ExtrairNumero(GetCampo(linha, "SCORE_NORMAL_MAX", "79"));
   g_gerAumentos.scoreForteMax = ExtrairNumero(GetCampo(linha, "SCORE_FORTE_MAX", "84"));
   g_gerAumentos.scoreExtremo = ExtrairNumero(GetCampo(linha, "SCORE_EXTREMO", "85"));
   g_gerAumentos.acaoExtremo = Upper(GetCampo(linha, "ACAO_EXTREMO", "BLOQUEAR_AUMENTOS"));
   g_gerAumentos.exigirPausa = IsOn(GetCampo(linha, "EXIGIR_RESFRIAMENTO", "ON"));
   g_gerAumentos.usarAX = IsOn(GetCampo(linha, "USAR_AX", "OFF"));
}

void ParseScoreAumentos(string linha)
{
   ZeroMemory(g_scoreAumentos);
   g_scoreAumentos.ativo = (InpModoGatilhoAumentos == AUMENTOS_SOMENTE_POR_SCORE);
   g_scoreAumentos.usarHilo8 = IsOn(GetCampo(linha, "HILO8", GetCampo(linha, "HILO", "ON")));
   g_scoreAumentos.usarSTR = IsOn(GetCampo(linha, "STR", "ON"));
   g_scoreAumentos.usarVOLQ = IsOn(GetCampo(linha, "VOLQ", "ON"));
   g_scoreAumentos.usarVOLF = IsOn(GetCampo(linha, "VOLF", "ON"));
   g_scoreAumentos.exigirDirecao = IsOn(GetCampo(linha, "EXIGIR_DIRECAO", "ON"));
   string cfgHistorico = Upper(InpScoreHistorico);
   g_scoreAumentos.adaptarHistoricoHora = (StringFind(cfgHistorico, "OFF") < 0 && StringFind(cfgHistorico, "ONTEM") >= 0);
   g_scoreAumentos.ajustarPeloDiaAtual = (g_scoreAumentos.adaptarHistoricoHora && StringFind(cfgHistorico, "DIA ATUAL") >= 0);
   g_scoreAumentos.pesoHilo8 = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_HILO8", GetCampo(linha, "PESO_HILO", "25"))));
   g_scoreAumentos.pesoSTR = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_STR", "25")));
   g_scoreAumentos.pesoVOLQ = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_VOLQ", "25")));
   g_scoreAumentos.pesoVOLF = MathAbs(ExtrairNumero(GetCampo(linha, "PESO_VOLF", "25")));
   g_scoreAumentos.minimoA1 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A1", "50")));
   g_scoreAumentos.minimoA2 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A2", "75")));
   g_scoreAumentos.minimoA3 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A3", "100")));
   g_scoreAumentos.minimoA4 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A4", "100")));
   g_scoreAumentos.minimoA5 = MathAbs(ExtrairNumero(GetCampo(linha, "MIN_A5", "100")));
}

bool ModoAumentoSomenteScore()
{
   return (InpModoGatilhoAumentos == AUMENTOS_SOMENTE_POR_SCORE);
}

double MinimoScoreAumentoNivel(int indiceZero)
{
   if(indiceZero <= 0)
      return g_scoreAumentos.minimoA1;
   if(indiceZero == 1)
      return g_scoreAumentos.minimoA2;
   if(indiceZero == 2)
      return g_scoreAumentos.minimoA3;
   if(indiceZero == 3)
      return g_scoreAumentos.minimoA4;
   return g_scoreAumentos.minimoA5;
}

double QualidadeVolumeScoreAdaptativo(bool quantidade, bool &aprovado, string &detalhe)
{
   double ratioHoraBruto = quantidade ? g_mercado.volqRatioHora : g_mercado.volfRatioHora;
   double ratioHoraAjustado = quantidade ? g_mercado.volqRatioAjustadoHora : g_mercado.volfRatioAjustadoHora;
   double ratio5 = quantidade ? g_mercado.volqRatio5m : g_mercado.volfRatio5m;
   double ratio15 = quantidade ? g_mercado.volqRatio15m : g_mercado.volfRatio15m;
   double fatorDia = quantidade ? g_mercado.volqFatorDia : g_mercado.volfFatorDia;
   double baseHora = quantidade ? g_mercado.volqBaseHora : g_mercado.volfBaseHora;
   bool curvaOk = quantidade ? g_mercado.volqCurvaOK : g_mercado.volfCurvaOK;

   bool historicoDisponivel = (baseHora > 0.0 && ratioHoraBruto > 0.0);
   if(!g_scoreAumentos.adaptarHistoricoHora)
   {
      aprovado = (curvaOk || g_mercado.volFarol >= 2 || ratio5 >= 1.0 || ratio15 >= 1.0);
      detalhe = aprovado ? "FIXO_OK" : "FIXO_NAO";
      return aprovado ? 1.0 : 0.0;
   }
   if(!historicoDisponivel)
   {
      double ratioAtualSemBase = MathMax(ratio15 * 0.85, ratio5 * 0.70);
      double qualidadeSemBase = MathMax(0.0, MathMin(1.0, ratioAtualSemBase));
      aprovado = (ratioAtualSemBase >= 1.0);
      detalhe = StringFormat("SEM_BASE_ONTEM | ATUAL %.2f", ratioAtualSemBase);
      return qualidadeSemBase;
   }

   double ratioUsado = g_scoreAumentos.ajustarPeloDiaAtual ? ratioHoraAjustado : ratioHoraBruto;
   if(g_scoreAumentos.ajustarPeloDiaAtual)
      ratioUsado = MathMax(ratioUsado, MathMax(ratio15 * 0.85, ratio5 * 0.70));
   if(g_mercado.volFarol >= 2)
      ratioUsado = MathMax(ratioUsado, 1.0);

   double qualidade = MathMax(0.0, MathMin(1.0, ratioUsado));
   aprovado = (ratioUsado >= 1.0);
   detalhe = StringFormat("ADAPT %.2f | ONTEM_HORA | DIA %.2f", ratioUsado, fatorDia);
   return qualidade;
}

double CalcularScoreAumentoDedicado(ENUM_LADO_ROBO lado, string &detalhe)
{
   detalhe = "SCORE_AUMENTO_OFF";
   if(!g_scoreAumentos.ativo)
      return 100.0;

   double pontos = 0.0;
   double totalPesos = 0.0;
   bool hiloOk = false;
   bool strOk = false;
   bool volqOk = false;
   bool volfOk = false;
   string detalheVolQ = "OFF";
   string detalheVolF = "OFF";

   if(g_scoreAumentos.usarHilo8)
   {
      totalPesos += g_scoreAumentos.pesoHilo8;
      hiloOk = ((lado == LADO_COMPRA && g_mercado.hiloCompra) || (lado == LADO_VENDA && g_mercado.hiloVenda));
      if(hiloOk)
         pontos += g_scoreAumentos.pesoHilo8;
   }
   if(g_scoreAumentos.usarSTR)
   {
      totalPesos += g_scoreAumentos.pesoSTR;
      strOk = ((lado == LADO_COMPRA && g_mercado.strCompra) || (lado == LADO_VENDA && g_mercado.strVenda));
      if(strOk)
         pontos += g_scoreAumentos.pesoSTR;
   }
   if(g_scoreAumentos.usarVOLQ)
   {
      totalPesos += g_scoreAumentos.pesoVOLQ;
      double qualidadeVolQ = QualidadeVolumeScoreAdaptativo(true, volqOk, detalheVolQ);
      pontos += g_scoreAumentos.pesoVOLQ * qualidadeVolQ;
   }
   if(g_scoreAumentos.usarVOLF)
   {
      totalPesos += g_scoreAumentos.pesoVOLF;
      double qualidadeVolF = QualidadeVolumeScoreAdaptativo(false, volfOk, detalheVolF);
      pontos += g_scoreAumentos.pesoVOLF * qualidadeVolF;
   }

   double score = 0.0;
   if(totalPesos > 0.0)
      score = (pontos / totalPesos) * 100.0;
   bool direcaoOk = (!g_scoreAumentos.exigirDirecao || hiloOk || strOk);
   if(!direcaoOk)
      score = 0.0;
   if(score < 0.0)
      score = 0.0;
   if(score > 100.0)
      score = 100.0;

   string modoHistorico = g_scoreAumentos.adaptarHistoricoHora
                          ? (g_scoreAumentos.ajustarPeloDiaAtual ? "ONTEM_HORA+DIA_ATUAL" : "ONTEM_HORA")
                          : "FIXO";
   detalhe = StringFormat("SCORE=%.1f | HILO8=%s | STR=%s | VOLQ=%s[%s] | VOLF=%s[%s] | DIR=%s | BASE=%s",
                          score,
                          hiloOk ? "OK" : "NAO",
                          strOk ? "OK" : "NAO",
                          volqOk ? "OK" : "PARCIAL",
                          detalheVolQ,
                          volfOk ? "OK" : "PARCIAL",
                          detalheVolF,
                          direcaoOk ? "OK" : "NAO",
                          modoHistorico);
   return score;
}

bool ScoreAumentoAutoriza(EstadoLado &estado, int indiceZero, string &detalhe)
{
   if(!g_scoreAumentos.ativo)
   {
      detalhe = "Score de aumentos desligado.";
      return true;
   }
   ENUM_LADO_ROBO lado = LadoDaPosicaoAtual(estado);
   double score = CalcularScoreAumentoDedicado(lado, detalhe);
   double minimo = MinimoScoreAumentoNivel(indiceZero);
   if(score + 0.000001 < minimo)
   {
      detalhe = StringFormat("A%d bloqueado: %.1f < minimo %.1f | %s", indiceZero + 1, score, minimo, detalhe);
      return false;
   }
   detalhe = StringFormat("A%d liberado: %.1f >= minimo %.1f | %s", indiceZero + 1, score, minimo, detalhe);
   return true;
}

string TextoScoreAumentoNivel(EstadoLado &estado, int indiceZero)
{
   if(!g_scoreAumentos.ativo)
      return "SCORE OFF";
   string detalhe = "";
   double score = CalcularScoreAumentoDedicado(LadoDaPosicaoAtual(estado), detalhe);
   return StringFormat("SCORE %.0f/%.0f", score, MinimoScoreAumentoNivel(indiceZero));
}

double MinimoScoreVolumeAumentoFIX334(int indiceZero)
{
   if(indiceZero<=0)
      return MathAbs(InpScoreVolumeMinA1);
   if(indiceZero==1)
      return MathAbs(InpScoreVolumeMinA2);
   if(indiceZero==2)
      return MathAbs(InpScoreVolumeMinA3);
   return MathAbs(InpScoreVolumeMinA4);
}

double CalcularScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, string &detalhe)
{
   detalhe="VOL SCORE OFF";
   if(!InpScoreVolumeAumentosAtivo)
      return 100.0;

   bool qtdOk=false;
   bool finOk=false;
   string detalheQtd="";
   string detalheFin="";
   double qualidadeHoraQtd=QualidadeVolumeScoreAdaptativo(true,qtdOk,detalheQtd);
   double qualidadeHoraFin=QualidadeVolumeScoreAdaptativo(false,finOk,detalheFin);
   qualidadeHoraQtd=MathMax(0.0,MathMin(1.0,qualidadeHoraQtd));
   qualidadeHoraFin=MathMax(0.0,MathMin(1.0,qualidadeHoraFin));

   bool candleDisponivel=(g_mercado.volCandleTempo>0 &&
                          g_mercado.volqMediaCandles>0.0 &&
                          g_mercado.volfMediaCandles>0.0);
   double qualidadeCandleQtd=candleDisponivel ? MathMax(0.0,MathMin(1.0,g_mercado.volqRatioCandle)) : qualidadeHoraQtd;
   double qualidadeCandleFin=candleDisponivel ? MathMax(0.0,MathMin(1.0,g_mercado.volfRatioCandle)) : qualidadeHoraFin;
   // Candle fechado comanda 70%; contexto historico por horario preserva 30%.
   double qualidadeQtd=candleDisponivel ? (qualidadeCandleQtd*0.70+qualidadeHoraQtd*0.30) : qualidadeHoraQtd;
   double qualidadeFin=candleDisponivel ? (qualidadeCandleFin*0.70+qualidadeHoraFin*0.30) : qualidadeHoraFin;

   // O componente mais fraco comanda. Volume financeiro alto sem participacao,
   // ou muita quantidade sem dinheiro real, nao libera aumento arriscado.
   double scoreQtd=qualidadeQtd*100.0;
   double scoreFin=qualidadeFin*100.0;
   double scoreBase=MathMin(scoreQtd,scoreFin);
   double score=scoreBase;
   double forcaLado=ScoreDirecionalDoLado(lado);
   double fatorForca=1.0;
   ENUM_LADO_ROBO direcao=DirecaoMedia25Operacional();
   bool direcaoContra=(direcao!=LADO_NENHUM && direcao!=LADO_AMBOS && direcao!=lado);
   if(InpScoreVolumeAjustarForcaMercado && g_mercado.status>=MERCADO_FORTE)
   {
      fatorForca=0.65+0.35*(MathMax(0.0,MathMin(100.0,forcaLado))/100.0);
      if(direcaoContra)
         fatorForca*=(g_mercado.status==MERCADO_EXTREMO ? 0.55 : 0.75);
      else if(direcao==LADO_NENHUM || direcao==LADO_AMBOS)
         fatorForca*=(g_mercado.status==MERCADO_EXTREMO ? 0.80 : 0.90);
      score=scoreBase*fatorForca;
   }
   score=MathMax(0.0,MathMin(100.0,score));
   string regime=(g_mercado.status==MERCADO_EXTREMO ? "EXTREMO" :
                  (g_mercado.status==MERCADO_FORTE ? "FORTE" :
                   (g_mercado.status==MERCADO_NORMAL ? "NORMAL" : "FRACO")));
   string dirTexto=(direcao==LADO_COMPRA ? "COMPRA" : (direcao==LADO_VENDA ? "VENDA" : "NEUTRA"));
   detalhe=StringFormat("VOL=%.1f BASE=%.1f | CND Qx%.2f Fx%.2f | QTD=%.1f FIN=%.1f | FORCA=%.1f FATOR=%.2f %s/%s",
                        score,scoreBase,g_mercado.volqRatioCandle,g_mercado.volfRatioCandle,
                        scoreQtd,scoreFin,forcaLado,fatorForca,regime,dirTexto);
   return score;
}

bool ScoreVolumeAumentoAutorizaFIX334(ENUM_LADO_ROBO lado, int indiceZero, string &detalhe)
{
   if(!InpScoreVolumeAumentosAtivo)
   {
      detalhe="Score VOL QTD+FIN desligado.";
      return true;
   }
   string leitura="";
   double score=CalcularScoreVolumeAumentoFIX334(lado,leitura);
   double minimo=MinimoScoreVolumeAumentoFIX334(indiceZero);
   if(score+0.000001<minimo)
   {
      detalhe=StringFormat("A%d bloqueado por volume: %.1f < %.1f | %s",
                           indiceZero+1,score,minimo,leitura);
      return false;
   }
   detalhe=StringFormat("A%d volume aprovado: %.1f >= %.1f | %s",
                        indiceZero+1,score,minimo,leitura);
   return true;
}

string TextoScoreVolumeAumentoFIX334(ENUM_LADO_ROBO lado, int indiceZero)
{
   if(!InpScoreVolumeAumentosAtivo)
      return "VOL OFF";
   string detalhe="";
   double score=CalcularScoreVolumeAumentoFIX334(lado,detalhe);
   return StringFormat("VOL %.0f/%.0f",score,MinimoScoreVolumeAumentoFIX334(indiceZero));
}


#endif // COPA_REGRAS_AUMENTOS_MQH
