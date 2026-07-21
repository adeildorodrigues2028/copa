#ifndef COPA_CONFIGURACAO_JANELAS_MQH
#define COPA_CONFIGURACAO_JANELAS_MQH

// ============================================================================
// RESPONSABILIDADE: MATRIZES E JANELAS DE HORARIO
// Funcoes movidas do principal na V38 sem alteracao de regra operacional.
// ============================================================================

string MontarLinhaAumentoVisivelFIX340(string execucao, string trailing, bool ativo)
{
   string linha=Trim(execucao)+";"+Trim(trailing);
   StringReplace(linha,"|",";");
   string qtd=Trim(GetCampo(linha,"QTD",GetCampo(linha,"CONTRATOS",GetCampo(linha,"A1",GetCampo(linha,"A2",GetCampo(linha,"A3",GetCampo(linha,"A4",GetCampo(linha,"A5","1C"))))))));
   string timer=Trim(GetCampo(linha,"TIMER",GetCampo(linha,"TEMPO","2M")));
   string gatilho=Trim(GetCampo(linha,"GATILHO",GetCampo(linha,"G","20")));
   string distancia=Trim(GetCampo(linha,"DIST",GetCampo(linha,"DISTANCIA","100")));
   string trail=Trim(GetCampo(linha,"TRAIL",GetCampo(linha,"TRAILING","20/5")));
   return StringFormat("%s;QTD=%s;TEMPO=%s;GATILHO=%s;DIST=%s;TRAIL=%s",
                       ativo ? "ON" : "OFF",qtd,timer,gatilho,distancia,trail);
}

void MontarReforcosDaTelaFIX312()
{
   int quantidade=InpQuantidadeReforcos;
   if(quantidade<0) quantidade=0;
   if(quantidade>5) quantidade=5;

   // FIX340: a tela fica humana e curta; estas linhas remontam exatamente as
   // strings técnicas já usadas pelo motor, sem alterar a estratégia.
   InpEntradaOperacao=Trim(InpEntradaA0QuantidadeAlvoFIX340)+" | "+Trim(InpEntradaA0PerdaTrailingFIX340);
   InpA1=MontarLinhaAumentoVisivelFIX340(InpA1ExecucaoFIX340,InpA1TrailingFIX340,quantidade>=1);
   InpA2=MontarLinhaAumentoVisivelFIX340(InpA2ExecucaoFIX340,InpA2TrailingFIX340,quantidade>=2);
   InpA3=MontarLinhaAumentoVisivelFIX340(InpA3ExecucaoFIX340,InpA3TrailingFIX340,quantidade>=3);
   InpA4=MontarLinhaAumentoVisivelFIX340(InpA4ExecucaoFIX340,InpA4TrailingFIX340,quantidade>=4);
   InpA5=MontarLinhaAumentoVisivelFIX340(InpA5ExecucaoFIX340,InpA5TrailingFIX340,quantidade>=5);

   string risco=Trim(InpRiscoAumentosFIX340);
   StringReplace(risco,"|",";");
   // Os valores de alvo/perda dos aumentos permanecem comuns por contrato,
   // como no motor existente. A1 fornece apenas os defaults operacionais.
   InpGestaoAumentosFIX324=InpA1+";"+risco;
   AplicarGestaoAumentosCompactaFIX324();

   // FIX440: cada janela A1-A5 define sua propria quantidade.
   // Nao existe bloqueio global pela soma dos contratos configurados.
   InpAumentos=StringFormat("ON;DIR=CONTRA;LIVRE_TESTE=OFF;LIVRE_TOTAL=OFF;IGNORAR_META_DIA=OFF;MAX_AUMENTOS=%d;MAX_CONTRATOS=100000;VALIDACAO=ON",
                            quantidade);
}

void CarregarTodasMatrizes()
{
   SincronizarParametrosUsuarioFIX362(true,"INIT_MATRIZES");
}

void CarregarMatrizJanelas()
{
   // FIX302: uma linha compacta controla as quatro faixas de A0.
   g_janelas[0] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,0), InpJanela1Filtros));
   g_janelas[1] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,1), InpJanela2Filtros));
   g_janelas[2] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,2), InpJanela3Filtros));
   g_janelas[3] = ParseJanela(MontarLinhaJanelaClara(FaixaHorarioCompacta(InpHorariosEntradaA0,3), InpJanela4Filtros));
   g_janelas[4] = ParseJanela("OFF;HOR=18:00-18:15;LADO=AMBOS;A0=OFF;QTD=1;PERFIL=FIM_DIA");
   ValidarJanelasClaras();
}

string MontarLinhaJanelaClara(string configuracao, string filtros)
{
   string raw = Trim(configuracao);
   string horarioCompleto = raw;

   // Compatibilidade com arquivos antigos: aceita ON | HH:MM - HH:MM | A0=ON
   // e também ON;HOR=HH:MM-HH:MM;..., mas ignora ON/OFF, A0 e LADO.
   if(StringFind(raw, "|") >= 0)
   {
      string partesConfig[];
      int totalConfig = StringSplit(raw, '|', partesConfig);
      horarioCompleto = "";
      for(int i = 0; i < totalConfig; i++)
      {
         string parte = Trim(partesConfig[i]);
         if(StringFind(parte, ":") >= 0 && StringFind(parte, "-") >= 0)
         {
            horarioCompleto = parte;
            break;
         }
      }
   }
   else if(StringFind(Upper(raw), "HOR=") >= 0)
      horarioCompleto = GetCampo(raw, "HOR", "00:00-00:00");

   string horario = Trim(horarioCompleto);
   string partesHorario[];
   int quantidadePartes = StringSplit(horario, '-', partesHorario);
   bool formatoValido = (quantidadePartes >= 2 &&
                         StringFind(Trim(partesHorario[0]), ":") >= 0 &&
                         StringFind(Trim(partesHorario[1]), ":") >= 0);
   if(formatoValido)
      horario = Trim(partesHorario[0]) + "-" + Trim(partesHorario[1]);
   else
   {
      horario = "00:00-00:00";
      PrintFormat("[COPA_AR100][HORARIOS] Formato invalido; janela bloqueada: '%s'. Use HH:MM - HH:MM.", configuracao);
   }

   // Regras fixas protegidas: janela ligada, entrada A0 permitida e ambos os lados.
   string base = StringFormat("%s;HOR=%s;LADO=AMBOS;A0=ON;QTD=1;PERFIL=HARD",
                              formatoValido ? "ON" : "OFF",
                              horario);
   return CombinarLinhaFiltro(base, NormalizarFiltrosHumanizados(filtros));
}

bool MinutoDentroJanelaValor(int minuto, RegraJanela &j)
{
   if(!j.ativa || j.minutoInicio == j.minutoFim)
      return false;
   if(j.minutoInicio < j.minutoFim)
      return (minuto >= j.minutoInicio && minuto < j.minutoFim);
   return (minuto >= j.minutoInicio || minuto < j.minutoFim);
}

void ValidarJanelasClaras()
{
   for(int i = 0; i < 4; i++)
   {
      if(!g_janelas[i].ativa)
         continue;
      if(g_janelas[i].minutoInicio == g_janelas[i].minutoFim)
      {
         PrintFormat("[COPA_AR100][JANELAS] J%d desativada na pratica: inicio e fim iguais (%s).", i + 1, g_janelas[i].horario);
         continue;
      }
      for(int k = i + 1; k < 4; k++)
      {
         if(!g_janelas[k].ativa)
            continue;
         bool sobrepoe = false;
         for(int minuto = 0; minuto < 1440 && !sobrepoe; minuto++)
            sobrepoe = (MinutoDentroJanelaValor(minuto, g_janelas[i]) && MinutoDentroJanelaValor(minuto, g_janelas[k]));
         if(sobrepoe)
            PrintFormat("[COPA_AR100][JANELAS] ATENCAO: J%d (%s) sobrepoe J%d (%s).", i + 1, g_janelas[i].horario, k + 1, g_janelas[k].horario);
      }
   }
}

void CarregarMatrizAumentos()
{
   ParseGerenciadorAumentos(InpAumentos);
   ParseScoreAumentos(InpAumentosSomenteScore);
   g_aumentos[0] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA1), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA1Filtros))));
   g_aumentos[1] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA2), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA2Filtros))));
   g_aumentos[2] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA3), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA3Filtros))));
   g_aumentos[3] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA4), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA4Filtros))));
   g_aumentos[4] = ParseAumento(CombinarLinhaFiltro(NormalizarLinhaAumentoHumanizada(InpA5), NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA5Filtros))));
}


#endif // COPA_CONFIGURACAO_JANELAS_MQH
