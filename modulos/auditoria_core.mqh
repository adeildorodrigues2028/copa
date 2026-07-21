// COPA V12 - Etapa 12: nucleo da auditoria leve.
#ifndef COPA_V12_MODULOS_AUDITORIA_CORE_MQH
#define COPA_V12_MODULOS_AUDITORIA_CORE_MQH

// ============================================================================
// FIX302 - MODULO DE AUDITORIA COMPLETA LEVE
// ============================================================================
string Aud302San(string s)
{
   StringReplace(s,"\r"," ");
   StringReplace(s,"\n"," ");
   StringReplace(s,";",",");
   StringReplace(s,"\"","'");
   return s;
}

string Aud302DataArquivo()
{
   string s=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS);
   StringReplace(s,".","");
   StringReplace(s,":","");
   StringReplace(s," ","_");
   return s;
}

string Aud302LadoLocal()
{
   return JanelaAtualEhA_FIX255() ? "BUY" : "SELL";
}

string Aud302JanelaLocal()
{
   return JanelaAtualEhA_FIX255() ? "A" : "B";
}

long Aud302MagicLocal()
{
   return MagicOperacionalInstanciaFIX255();
}

string Aud302Cenario()
{
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS) return "SEM_FILTROS_BYPASS";
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS) return "COM_FILTROS";
   return "CONFIG_ATUAL";
}

bool EntradaDiretaDemoEfetivaFIX302()
{
   // FIX377: USAR=NAO ou os tres filtros NULO liberam a A0 direta em DEMO,
   // sem desligar os filtros individuais dos aumentos.
   if(EntradaA0SemFiltrosCompactaFIX377())
      return true;
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS)
      return false;
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
      return true;
   return InpFIX279EntradaDiretaDemo;
}

bool ModoContinuidadeTesteFIX352()
{
   // Exclusivo do teste técnico: não altera conta REAL nem A0 NORMAL COM SINAIS.
   return (g_contaDemo && PrimeiraOrdemLivreProtegidaFIX314() && EntradaDiretaDemoEfetivaFIX302());
}

string FiltroEfetivoAuditoriaFIX302(string configurado)
{
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
      return "LIVRE";
   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS)
      return InpPerfilFiltrosAuditoriaFIX302;
   return configurado;
}

void AplicarCenarioAuditoriaFIX302()
{
   // FIX372: LIVRE PROTEGIDA significa entrada imediata depois das protecoes,
   // mas filtros preenchidos continuam obrigatorios. Bypass existe somente no cenario explicito SEM FILTROS.
   InpFIX279EntradaDiretaDemo=(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS);
   InpFIX293TesteDX2ZeroAmbosLados=false;
   InpTesteLivreEntradaA0=(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS);

   if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
   {
      InpTesteLivreEntradaA0=true;
      InpJanela1Filtros="LIVRE";
      InpJanela2Filtros="LIVRE";
      InpJanela3Filtros="LIVRE";
      InpJanela4Filtros="LIVRE";
   }
   else if(InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS)
   {
      InpTesteLivreEntradaA0=false;
      InpJanela1Filtros=InpPerfilFiltrosAuditoriaFIX302;
      InpJanela2Filtros=InpPerfilFiltrosAuditoriaFIX302;
      InpJanela3Filtros=InpPerfilFiltrosAuditoriaFIX302;
      InpJanela4Filtros=InpPerfilFiltrosAuditoriaFIX302;
   }
}

void AuditoriaResetarNiveisFIX302()
{
   for(int i=0;i<6;i++)
   {
      g_aud302FiltroNivel[i]="PENDENTE";
      g_aud302EntradaNivel[i]="PENDENTE";
      g_aud302TrailNivel[i]="PENDENTE";
      g_aud302ParcialNivel[i]="PENDENTE";
      g_aud302GraficoNivel[i]="PENDENTE";
      g_aud302FinanceiroNivel[i]="PENDENTE";
      g_aud302PrecoEsperado[i]=0.0;
      g_aud302PrecoEntrada[i]=0.0;
      g_aud302PrecoSaida[i]=0.0;
      g_aud302ResultadoNivel[i]=0.0;
      g_aud302TicketNivel[i]=0;
      g_aud302DealNivel[i]=0;
   }
}

void AuditoriaInicializarFIX302()
{
   if(g_aud302Inicializada)
      return;
   g_aud302Inicializada=true;
   // FIX303: nunca abrir a auditoria por cima do painel durante Init/recompilacao.
   // A coleta, CSV, LOG e performance continuam ativos; somente a camada visual fica recolhida.
   g_aud302TelaAtiva=false;
   AuditoriaLimparTelaFIX302();
   g_aud302Sessao=StringFormat("%s_%s_M%d_%s_%s_C%I64d_%s",_Symbol,Aud302JanelaLocal(),(int)Aud302MagicLocal(),g_identidadeGrupoFIX304,g_identidadeGeracaoFIX304,ChartID(),Aud302DataArquivo());
   AuditoriaResetarNiveisFIX302();
   bool aberta=JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
   g_aud302PosAnterior=aberta;
   if(aberta)
   {
      g_aud302CicloAtivo=true;
      string cicloRec=CicloAtualMagicFIX304(Aud302MagicLocal(),false);
      if(cicloRec=="") cicloRec="CLEG";
      g_aud302Ciclo=g_identidadeGeracaoFIX304+"_"+cicloRec;
   }
   g_aud302UltimoEvento=StringFormat("AUDITORIA INICIADA | %s | MAGIC %d | %s",Aud302JanelaLocal(),(int)Aud302MagicLocal(),Aud302Cenario());
}

int AuditoriaNivelFIX302(string contexto,string mensagem)
{
   string s=Upper(contexto+" "+mensagem);
   for(int n=5;n>=1;n--)
   {
      string a="A"+IntegerToString(n);
      if(StringFind(s,a)>=0)
         return n;
   }
   if(StringFind(s,"A0")>=0 || StringFind(s,"ENTRADA")>=0 || StringFind(s,"ORDER")>=0)
      return 0;
   return -1;
}

string AuditoriaClasseFIX302(string contexto,string mensagem)
{
   string s=Upper(contexto+" "+mensagem);
   if(StringFind(s,"FILTRO")>=0 || StringFind(s,"SCORE")>=0) return "FILTRO";
   if(StringFind(s,"TRAIL")>=0 || StringFind(s,"PROTECAO")>=0) return "TRAIL";
   if(StringFind(s,"PARCIAL")>=0 || StringFind(s,"REALIZADO")>=0 || StringFind(s,"DEAL_SAIDA")>=0) return "PARCIAL";
   if(StringFind(s,"ORDER")>=0 || StringFind(s,"ENTRADA")>=0 || StringFind(s,"AUMENTO")>=0 || StringFind(s,"_OK")>=0) return "ORDEM";
   if(StringFind(s,"GAIN")>=0 || StringFind(s,"STOP")>=0 || StringFind(s,"SAIDA")>=0) return "RISCO_SAIDA";
   if(StringFind(s,"GRAF")>=0) return "GRAFICO";
   if(StringFind(s,"PERF")>=0) return "PERFORMANCE";
   return "SISTEMA";
}

string AuditoriaStatusEventoFIX302(string contexto,string mensagem,uint retcode,int erro)
{
   string s=Upper(contexto+" "+mensagem);
   if(erro>0 || StringFind(s,"REJECT")>=0 || StringFind(s,"ERRO")>=0 || StringFind(s,"FALH")>=0)
      return "FALHOU";
   if(StringFind(s,"BLOQ")>=0 || StringFind(s,"AGUARDA")>=0 || StringFind(s,"PENDENTE")>=0 || StringFind(s,"NAO CONFIRM")>=0)
      return "PENDENTE";
   if(retcode==TRADE_RETCODE_DONE || retcode==TRADE_RETCODE_DONE_PARTIAL || StringFind(s,"OK")>=0 || StringFind(s,"CONFIRM")>=0 || StringFind(s,"EXECUT")>=0 || StringFind(s,"ARMADO")>=0)
      return "APROVADO";
   return "INFO";
}

long AuditoriaNumeroDepoisFIX302(string texto,string marcador)
{
   int p=StringFind(texto,marcador);
   if(p<0) return 0;
   p+=StringLen(marcador);
   while(p<StringLen(texto))
   {
      ushort c=StringGetCharacter(texto,p);
      if(c>='0' && c<='9') break;
      p++;
   }
   int ini=p;
   while(p<StringLen(texto))
   {
      ushort c=StringGetCharacter(texto,p);
      if(c<'0' || c>'9') break;
      p++;
   }
   if(p<=ini) return 0;
   return (long)StringToInteger(StringSubstr(texto,ini,p-ini));
}

string AuditoriaIdCicloFIX302()
{
   return g_aud302CicloAtivo ? g_aud302Ciclo : "SEM_CICLO";
}

void AuditoriaCSVAddFIX302(string &linha,string valor)
{
   if(StringLen(linha)>0) linha+=";";
   linha+=Aud302San(valor);
}

ulong AuditoriaMediaFIX302(ulong total,ulong qtd)
{
   if(qtd==0) return 0;
   return total/qtd;
}

void AuditoriaFotoLeveFIX302(EstadoLado &estado,
                             double &realLocal,double &abertoLocal,double &saldoLocal,
                             double &realC,double &realV,double &abertoC,double &abertoV,double &saldoC,double &saldoV)
{
   realC=g_parciaisCicloBuy;
   realV=g_parciaisCicloSell;
   abertoC=g_compra.resultadoAberto;
   abertoV=g_venda.resultadoAberto;
   saldoC=realC+abertoC;
   saldoV=realV+abertoV;
   if(estado.lado==LADO_COMPRA)
   {
      realLocal=realC; abertoLocal=abertoC; saldoLocal=saldoC;
   }
   else
   {
      realLocal=realV; abertoLocal=abertoV; saldoLocal=saldoV;
   }
}

bool AuditoriaEnfileirarFIX302(string csv,string log,int destino,bool critica)
{
   if(g_aud302FilaQtd>=AUD302_FILA_MAX)
   {
      // Operacao nunca espera disco. Evento critico substitui o mais antigo; informativo e descartado.
      if(!critica)
      {
         g_aud302FilaDescartada++;
         return false;
      }
      g_aud302FilaInicio=(g_aud302FilaInicio+1)%AUD302_FILA_MAX;
      g_aud302FilaQtd--;
      g_aud302FilaDescartada++;
   }
   int pos=(g_aud302FilaInicio+g_aud302FilaQtd)%AUD302_FILA_MAX;
   g_aud302FilaCSV[pos]=csv;
   g_aud302FilaLOG[pos]=log;
   g_aud302FilaDestino[pos]=destino;
   g_aud302FilaCritica[pos]=critica;
   g_aud302FilaQtd++;
   if(critica) g_aud302FlushUrgente=true;
   return true;
}

bool AuditoriaContextoPeriodicoFIX302(string contexto)
{
   string c=Upper(contexto);
   return (StringFind(c,"TICK_")>=0 || StringFind(c,"TIMER_")>=0 || StringFind(c,"SNAPSHOT")>=0);
}

void AuditoriaAtualizarEstadoEventoFIX302(int nivel,string classe,string status,string contexto,string mensagem,double preco)
{
   if(nivel<0 || nivel>5) return;
   if(classe=="FILTRO")
   {
      if(InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS)
         g_aud302FiltroNivel[nivel]="BYPASS_TESTE";
      else
         g_aud302FiltroNivel[nivel]=(g_logFiltroDecisao!="" ? g_logFiltroDecisao : status);
   }
   if(classe=="ORDEM")
   {
      if(status=="APROVADO") g_aud302EntradaNivel[nivel]="APROVADO";
      else if(status=="FALHOU") g_aud302EntradaNivel[nivel]="FALHOU";
      if(preco>0.0) g_aud302PrecoEntrada[nivel]=preco;
      long t=AuditoriaNumeroDepoisFIX302(mensagem,"Ticket");
      long d=AuditoriaNumeroDepoisFIX302(mensagem,"Deal");
      if(t>0) g_aud302TicketNivel[nivel]=(ulong)t;
      if(d>0) g_aud302DealNivel[nivel]=(ulong)d;
   }
   if(classe=="TRAIL")
   {
      if(StringFind(Upper(contexto+" "+mensagem),"ARM")>=0 || StringFind(Upper(contexto+" "+mensagem),"STOP TR")>=0)
         g_aud302TrailNivel[nivel]="APROVADO";
   }
   if(classe=="PARCIAL" && status=="APROVADO")
      g_aud302ParcialNivel[nivel]="APROVADO";
}

void AuditoriaRegistrarEventoFIX302(EstadoLado &estado,string contexto,string mensagem,uint retcode,int erro,double volume,double preco,bool importante)
{
   if(!g_aud302Inicializada)
      AuditoriaInicializarFIX302();
   if(AuditoriaContextoPeriodicoFIX302(contexto))
   {
      string ass=Upper(contexto)+"|"+IntegerToString((int)estado.magic)+"|"+DoubleToString(estado.contratos,2)+"|"+DoubleToString(estado.resultadoAberto,2);
      if(ass==g_aud302UltimaAssinatura && g_aud302UltimaAssinaturaHora>0 && (TimeCurrent()-g_aud302UltimaAssinaturaHora)<30)
         return;
      g_aud302UltimaAssinatura=ass;
      g_aud302UltimaAssinaturaHora=TimeCurrent();
   }

   int nivel=AuditoriaNivelFIX302(contexto,mensagem);
   string classe=AuditoriaClasseFIX302(contexto,mensagem);
   string status=AuditoriaStatusEventoFIX302(contexto,mensagem,retcode,erro);
   bool critica=(importante && (classe=="ORDEM" || classe=="PARCIAL" || classe=="RISCO_SAIDA" || status=="FALHOU"));
   AuditoriaAtualizarEstadoEventoFIX302(nivel,classe,status,contexto,mensagem,preco);
   if(classe=="ORDEM" || classe=="TRAIL" || classe=="PARCIAL" || classe=="RISCO_SAIDA")
      g_aud302ValidarGraficoPendente=true;

   double realLocal=0,abertoLocal=0,saldoLocal=0,realC=0,realV=0,abertoC=0,abertoV=0,saldoC=0,saldoV=0;
   AuditoriaFotoLeveFIX302(estado,realLocal,abertoLocal,saldoLocal,realC,realV,abertoC,abertoV,saldoC,saldoV);
   double realAB=realC+realV;
   double abertoAB=abertoC+abertoV;
   double saldoAB=saldoC+saldoV;
   double checkAB=saldoAB-(realAB+abertoAB);
   string financeiro=(MathAbs(checkAB)<=0.01 ? "APROVADO" : "FALHOU");
   if(nivel>=0 && nivel<=5) g_aud302FinanceiroNivel[nivel]=financeiro;
   if(financeiro=="APROVADO") g_aud302ChecksOK++; else g_aud302ChecksFalha++;

   double esperado=0.0;
   if(nivel>=1 && nivel<=5)
      esperado=PrecoEntradaAumentoFIX220(estado,nivel);
   if(esperado<=0.0 && nivel>=1 && nivel<=5)
      esperado=PrecoNivelAumentoValorIndice(estado,nivel-1);
   if(nivel>=0 && nivel<=5 && esperado>0.0) g_aud302PrecoEsperado[nivel]=esperado;

   string graf=(nivel>=0 && nivel<=5 ? g_aud302GraficoNivel[nivel] : "N/A");
   string linha="";
   AuditoriaCSVAddFIX302(linha,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   AuditoriaCSVAddFIX302(linha,g_aud302Sessao);
   AuditoriaCSVAddFIX302(linha,_Symbol);
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)ChartID()));
   AuditoriaCSVAddFIX302(linha,Aud302JanelaLocal());
   AuditoriaCSVAddFIX302(linha,Aud302LadoLocal());
   AuditoriaCSVAddFIX302(linha,IntegerToString((int)Aud302MagicLocal()));
   AuditoriaCSVAddFIX302(linha,g_identidadeGrupoFIX304);
   AuditoriaCSVAddFIX302(linha,g_identidadeGeracaoFIX304);
   AuditoriaCSVAddFIX302(linha,Aud302Cenario());
   AuditoriaCSVAddFIX302(linha,AuditoriaIdCicloFIX302());
   AuditoriaCSVAddFIX302(linha,nivel>=0 ? "A"+IntegerToString(nivel) : "SISTEMA");
   AuditoriaCSVAddFIX302(linha,contexto);
   AuditoriaCSVAddFIX302(linha,classe);
   AuditoriaCSVAddFIX302(linha,status);
   AuditoriaCSVAddFIX302(linha,TextoPosicaoCard(estado));
   AuditoriaCSVAddFIX302(linha,DoubleToString(estado.contratos,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(estado.precoMedio,_Digits));
   AuditoriaCSVAddFIX302(linha,DoubleToString(esperado,_Digits));
   AuditoriaCSVAddFIX302(linha,DoubleToString(preco,_Digits));
   AuditoriaCSVAddFIX302(linha,DoubleToString(volume,2));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)(nivel>=0 ? g_aud302TicketNivel[nivel] : 0)));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)(nivel>=0 ? g_aud302DealNivel[nivel] : 0)));
   AuditoriaCSVAddFIX302(linha,retcode>0 ? IntegerToString((int)retcode) : "");
   AuditoriaCSVAddFIX302(linha,erro>0 ? IntegerToString(erro) : "");
   AuditoriaCSVAddFIX302(linha,g_logFiltroDecisao);
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_logFiltroTotal));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_logFiltroOk));
   AuditoriaCSVAddFIX302(linha,g_logFiltroHiloOK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroSTROK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroDXOK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroRSIOK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroVOLQOK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroVOLFOK);
   AuditoriaCSVAddFIX302(linha,g_logFiltroAGROK);
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_logFiltroDX,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_logFiltroRSI,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_logFiltroVolQ,0));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_logFiltroVolF,0));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_logFiltroAgr,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(abertoLocal,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(realLocal,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(saldoLocal,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_compra.contratos,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_venda.contratos,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_compra.contratos+g_venda.contratos,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(abertoC,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(abertoV,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(realC,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(realV,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(saldoC,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(saldoV,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(estado.lado==LADO_COMPRA ? g_realizadoAumentosCicloBuy : g_realizadoAumentosCicloSell,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(estado.lado==LADO_COMPRA ? g_volumeRealizadoAumentosCicloBuy : g_volumeRealizadoAumentosCicloSell,2));
   AuditoriaCSVAddFIX302(linha,IntegerToString(estado.lado==LADO_COMPRA ? g_qtdRealizacoesAumentosCicloBuy : g_qtdRealizacoesAumentosCicloSell));
   AuditoriaCSVAddFIX302(linha,DoubleToString(InpFIX280AlvoPorPontaReais,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(InpEntradaPerdaMaximaReais,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(GainHeadEfetivoFIX362(),2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(LossHeadEfetivoFIX362(),2));
   AtualizarGanhoQtdReaisFIX362(false);
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdCompra,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisCompra,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdVenda,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisVenda,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdHead,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisHead,2));
   AuditoriaCSVAddFIX302(linha,graf);
   AuditoriaCSVAddFIX302(linha,financeiro);
   AuditoriaCSVAddFIX302(linha,DoubleToString(checkAB,2));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_ordemTentativas));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_ordemEnviadas));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_ordemRejeitadas));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_ordemBloqueadas));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_aud302FilaQtd));
   AuditoriaCSVAddFIX302(linha,IntegerToString(g_aud302FilaDescartada));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)AuditoriaMediaFIX302(g_aud302TickUsTotal,g_aud302Ticks)));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)g_aud302TickUsMax));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)AuditoriaMediaFIX302(g_aud302TimerUsTotal,g_aud302Timers)));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)g_aud302TimerUsMax));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)AuditoriaMediaFIX302(g_aud302EscritaUsTotal,g_aud302LotesEscrita)));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)g_aud302EscritaUsMax));
   AuditoriaCSVAddFIX302(linha,mensagem);

   string log=StringFormat("%s | [%s][%s][MAGIC=%d][GER=%s][CICLO=%s][%s][%s] %s | %s",
                           TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),Aud302JanelaLocal(),Aud302LadoLocal(),
                           (int)Aud302MagicLocal(),g_identidadeGeracaoFIX304,AuditoriaIdCicloFIX302(),nivel>=0 ? "A"+IntegerToString(nivel) : "SYS",status,contexto,mensagem);
   AuditoriaEnfileirarFIX302(linha,log,0,critica);
   g_aud302UltimoEvento=StringFormat("%s %s %s",nivel>=0 ? "A"+IntegerToString(nivel) : "SYS",contexto,status);
}

string AuditoriaCabecalhoEventosFIX302()
{
   return "time;session_id;symbol;chart_id;window;side;magic;group_id;generation_id;scenario;cycle_id;level;context;class;status;position;contracts;avg_price;expected_price;event_price;volume;ticket;deal;retcode;error;filter_decision;filter_total;filter_ok;filter_hilo;filter_str;filter_dx;filter_rsi;filter_volq;filter_volf;filter_agr;dx_value;rsi_value;volq_value;volf_value;agr_value;open_local;realized_local;balance_local;qty_buy;qty_sell;qty_total;open_buy;open_sell;realized_buy;realized_sell;balance_buy;balance_sell;realized_increases_local;volume_realized_increases;partial_increases_count;gain_side;stop_side;gain_head;stop_head;ganho_qtd_compra;ganho_rs_compra;ganho_qtd_venda;ganho_rs_venda;ganho_qtd_head;ganho_rs_head;graph_status;financial_status;financial_diff;order_attempts;orders_ok;orders_reject;orders_blocked;queue_count;queue_dropped;tick_avg_us;tick_max_us;timer_avg_us;timer_max_us;write_avg_us;write_max_us;message";
}

string AuditoriaCabecalhoResumoFIX302()
{
   return "time;session_id;symbol;window;side;magic;group_id;generation_id;scenario;cycle_id;a0_filter;a0_entry;a0_trail;a0_graph;a0_fin;a1_filter;a1_entry;a1_trail;a1_partial;a1_graph;a1_fin;a2_filter;a2_entry;a2_trail;a2_partial;a2_graph;a2_fin;a3_filter;a3_entry;a3_trail;a3_partial;a3_graph;a3_fin;a4_filter;a4_entry;a4_trail;a4_partial;a4_graph;a4_fin;a5_filter;a5_entry;a5_trail;a5_partial;a5_graph;a5_fin;realized_local;open_local;balance_local;ganho_qtd_compra;ganho_rs_compra;ganho_qtd_venda;ganho_rs_venda;ganho_qtd_head;ganho_rs_head;orders_ok;orders_reject;queue_dropped;tick_avg_us;tick_max_us;timer_avg_us;timer_max_us;write_avg_us;write_max_us;result";
}

string AuditoriaCabecalhoDealsFIX305()
{
   return "time;session_id;symbol;chart_id;window;side;magic;group_id;generation_id;scenario;cycle_id;level;deal;position_id;order_id;entry;deal_type;price;volume;profit;commission_server;fee_server;swap;commission_manual_roundtrip;commission_applied;result_server;result_audited;ganho_qtd_compra;ganho_rs_compra;ganho_qtd_venda;ganho_rs_venda;ganho_qtd_head;ganho_rs_head;commission_mode;affects_robot;comment";
}

void AuditoriaRegistrarDealBrutoFIX305(ulong deal,int nivel)
{
   if(!InpLogValidacaoCSVAtivo || deal==0 || !HistoryDealSelect(deal))
      return;
   string simbolo=HistoryDealGetString(deal,DEAL_SYMBOL);
   long magic=(long)HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(simbolo!=_Symbol || magic!=Aud302MagicLocal())
      return;
   if(nivel<0 || nivel>5)
      nivel=0;

   ulong positionId=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
   ulong orderId=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
   long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
   long tipo=HistoryDealGetInteger(deal,DEAL_TYPE);
   double preco=HistoryDealGetDouble(deal,DEAL_PRICE);
   double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
   double profit=HistoryDealGetDouble(deal,DEAL_PROFIT);
   double commission=HistoryDealGetDouble(deal,DEAL_COMMISSION);
   double fee=HistoryDealGetDouble(deal,DEAL_FEE);
   double swap=HistoryDealGetDouble(deal,DEAL_SWAP);
   double manual=ComissaoManualDealFIX305(deal);
   double aplicada=ComissaoAplicadaDealFIX305(deal);
   double resultadoServidor=ResultadoDealServidorFIX305(deal);
   double resultadoAuditado=ResultadoDealLiquidoAuditadoFIX305(deal);
   string comentario=HistoryDealGetString(deal,DEAL_COMMENT);
   string cicloDeal=ExtrairCicloComentarioFIX304(comentario);
   string cicloAud=AuditoriaIdCicloFIX302();
   if(cicloDeal!="") cicloAud=g_identidadeGeracaoFIX304+"_"+cicloDeal;

   string linha="";
   AuditoriaCSVAddFIX302(linha,TimeToString((datetime)HistoryDealGetInteger(deal,DEAL_TIME),TIME_DATE|TIME_SECONDS));
   AuditoriaCSVAddFIX302(linha,g_aud302Sessao);
   AuditoriaCSVAddFIX302(linha,_Symbol);
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)ChartID()));
   AuditoriaCSVAddFIX302(linha,Aud302JanelaLocal());
   AuditoriaCSVAddFIX302(linha,Aud302LadoLocal());
   AuditoriaCSVAddFIX302(linha,IntegerToString((int)magic));
   AuditoriaCSVAddFIX302(linha,g_identidadeGrupoFIX304);
   AuditoriaCSVAddFIX302(linha,g_identidadeGeracaoFIX304);
   AuditoriaCSVAddFIX302(linha,Aud302Cenario());
   AuditoriaCSVAddFIX302(linha,cicloAud);
   AuditoriaCSVAddFIX302(linha,IntegerToString(nivel));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)deal));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)positionId));
   AuditoriaCSVAddFIX302(linha,IntegerToString((long)orderId));
   AuditoriaCSVAddFIX302(linha,IntegerToString((int)entry));
   AuditoriaCSVAddFIX302(linha,IntegerToString((int)tipo));
   AuditoriaCSVAddFIX302(linha,DoubleToString(preco,_Digits));
   AuditoriaCSVAddFIX302(linha,DoubleToString(volume,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(profit,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(commission,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(fee,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(swap,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(manual,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(aplicada,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(resultadoServidor,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(resultadoAuditado,2));
   AtualizarGanhoQtdReaisFIX362(true);
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdCompra,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisCompra,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdVenda,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisVenda,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.qtdHead,2));
   AuditoriaCSVAddFIX302(linha,DoubleToString(g_ganhoQtdReaisFIX362.reaisHead,2));
   AuditoriaCSVAddFIX302(linha,NomeModoComissaoFIX305());
   AuditoriaCSVAddFIX302(linha,InpComissaoAfetaFinanceiroRoboFIX305 ? "SIM" : "NAO");
   AuditoriaCSVAddFIX302(linha,comentario);

   string log=StringFormat("%s | [DEAL_RAW][MAGIC=%d][CICLO=%s][A%d] deal=%I64u pos=%I64u vol=%.2f profit=%.2f com_srv=%.2f fee=%.2f swap=%.2f com_apl=%.2f srv=%.2f aud=%.2f | GANHO C %.0fC/%.2f V %.0fC/%.2f HEAD %.0fC/%.2f | modo=%s",
                           TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),(int)magic,cicloAud,nivel,
                           deal,positionId,volume,profit,commission,fee,swap,aplicada,resultadoServidor,resultadoAuditado,
                           g_ganhoQtdReaisFIX362.qtdCompra,g_ganhoQtdReaisFIX362.reaisCompra,
                           g_ganhoQtdReaisFIX362.qtdVenda,g_ganhoQtdReaisFIX362.reaisVenda,
                           g_ganhoQtdReaisFIX362.qtdHead,g_ganhoQtdReaisFIX362.reaisHead,
                           NomeModoComissaoFIX305());
   AuditoriaEnfileirarFIX302(linha,log,2,true);
}

bool AuditoriaAbrirArquivosFIX302()
{
   if(g_logValidacaoHandle!=INVALID_HANDLE && g_aud302LogHandle!=INVALID_HANDLE &&
      g_aud302ResumoHandle!=INVALID_HANDLE && g_aud305DealsHandle!=INVALID_HANDLE)
      return true;
   if(g_aud302SuspensoAte>TimeCurrent())
      return false;
   // FIX309: grupo, geracao, ChartID, conta, servidor e ciclo continuam nos campos internos.
   // O nome fisico fica curto para leitura no Windows e selecao no auditor externo.
   string base=StringFormat("AR100_%s_%s_M%d_%s",
                            SanitizarNomeArquivoBase(_Symbol),Aud302JanelaLocal(),
                            (int)Aud302MagicLocal(),Aud302DataArquivo());
   int flags=FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE;
   int flagsLog=FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE;
   if(InpLogValidacaoCSVCommon)
   {
      flags|=FILE_COMMON;
      flagsLog|=FILE_COMMON;
   }
   ResetLastError();
   g_logValidacaoHandle=FileOpen(base+"_EVENTOS.csv",flags,59);
   int e1=GetLastError();
   ResetLastError();
   g_aud302LogHandle=FileOpen(base+"_EVENTOS.log",flagsLog);
   int e2=GetLastError();
   ResetLastError();
   g_aud302ResumoHandle=FileOpen(base+"_RESUMO.csv",flags,59);
   int e3=GetLastError();
   ResetLastError();
   g_aud305DealsHandle=FileOpen(base+"_DEALS.csv",flags,59);
   int e4=GetLastError();
   if(g_logValidacaoHandle==INVALID_HANDLE || g_aud302LogHandle==INVALID_HANDLE ||
      g_aud302ResumoHandle==INVALID_HANDLE || g_aud305DealsHandle==INVALID_HANDLE)
   {
      if(g_logValidacaoHandle!=INVALID_HANDLE) { FileClose(g_logValidacaoHandle); g_logValidacaoHandle=INVALID_HANDLE; }
      if(g_aud302LogHandle!=INVALID_HANDLE) { FileClose(g_aud302LogHandle); g_aud302LogHandle=INVALID_HANDLE; }
      if(g_aud302ResumoHandle!=INVALID_HANDLE) { FileClose(g_aud302ResumoHandle); g_aud302ResumoHandle=INVALID_HANDLE; }
      if(g_aud305DealsHandle!=INVALID_HANDLE) { FileClose(g_aud305DealsHandle); g_aud305DealsHandle=INVALID_HANDLE; }
      g_aud302FalhasArquivo++;
      g_aud302SuspensoAte=TimeCurrent()+30;
      Print("[AR100][AUD302][ARQUIVO] falha sem bloquear operacao | erros ",e1,"/",e2,"/",e3,"/",e4," | nova tentativa em 30s");
      return false;
   }
   g_logValidacaoArquivo=base+"_EVENTOS.csv";
   g_aud302ArquivoLOG=base+"_EVENTOS.log";
   g_aud302ArquivoResumo=base+"_RESUMO.csv";
   g_aud305ArquivoDeals=base+"_DEALS.csv";
   CSVWriteLinha(g_logValidacaoHandle,AuditoriaCabecalhoEventosFIX302());
   FileWriteString(g_aud302LogHandle,StringFormat("AR100 FIX309 AUDITORIA | SESSAO %s | GRUPO %s | GERACAO %s | MAGIC %d | MOTOR %s | CENARIO %s | COMISSAO %s RT %.2f | AFETA_ROBO %s\r\n",
                    g_aud302Sessao,g_identidadeGrupoFIX304,g_identidadeGeracaoFIX304,(int)Aud302MagicLocal(),Aud302LadoLocal(),Aud302Cenario(),
                    NomeModoComissaoFIX305(),InpComissaoIdaVoltaPorContratoReaisFIX305,InpComissaoAfetaFinanceiroRoboFIX305 ? "SIM" : "NAO"));
   CSVWriteLinha(g_aud302ResumoHandle,AuditoriaCabecalhoResumoFIX302());
   CSVWriteLinha(g_aud305DealsHandle,AuditoriaCabecalhoDealsFIX305());
   g_aud302UltimoFileFlush=TimeCurrent();
   Print("[AR100][AUD302] arquivos por Magic abertos | ",g_logValidacaoArquivo," | ",g_aud302ArquivoLOG," | ",g_aud302ArquivoResumo," | ",g_aud305ArquivoDeals);
   return true;
}

void AuditoriaFlushFIX302(bool forcar)
{
   if(!InpLogValidacaoCSVAtivo || g_aud302FilaQtd<=0)
      return;
   datetime agora=TimeCurrent();
   if(!forcar && !g_aud302FlushUrgente && g_aud302UltimoFlush>0 && (agora-g_aud302UltimoFlush)<5)
      return;
   if(!AuditoriaAbrirArquivosFIX302())
      return;
   ulong ini=GetMicrosecondCount();
   int limite=forcar ? g_aud302FilaQtd : MathMin(g_aud302FilaQtd,32);
   bool teveCritico=false;
   for(int i=0;i<limite;i++)
   {
      int pos=g_aud302FilaInicio;
      if(g_aud302FilaDestino[pos]==1)
         CSVWriteLinha(g_aud302ResumoHandle,g_aud302FilaCSV[pos]);
      else if(g_aud302FilaDestino[pos]==2)
         CSVWriteLinha(g_aud305DealsHandle,g_aud302FilaCSV[pos]);
      else
         CSVWriteLinha(g_logValidacaoHandle,g_aud302FilaCSV[pos]);
      FileWriteString(g_aud302LogHandle,g_aud302FilaLOG[pos]+"\r\n");
      if(g_aud302FilaCritica[pos]) teveCritico=true;
      g_aud302FilaCSV[pos]="";
      g_aud302FilaLOG[pos]="";
      g_aud302FilaInicio=(g_aud302FilaInicio+1)%AUD302_FILA_MAX;
      g_aud302FilaQtd--;
      g_aud302EventosGravados++;
   }
   g_aud302UltimoFlush=agora;
   if(forcar || teveCritico || g_aud302UltimoFileFlush==0 || (agora-g_aud302UltimoFileFlush)>=30)
   {
      FileFlush(g_logValidacaoHandle);
      FileFlush(g_aud302LogHandle);
      FileFlush(g_aud302ResumoHandle);
      FileFlush(g_aud305DealsHandle);
      g_aud302UltimoFileFlush=agora;
   }
   g_aud302FlushUrgente=false;
   for(int i=0;i<g_aud302FilaQtd;i++)
   {
      int pos=(g_aud302FilaInicio+i)%AUD302_FILA_MAX;
      if(g_aud302FilaCritica[pos]) { g_aud302FlushUrgente=true; break; }
   }
   ulong fim=GetMicrosecondCount();
   ulong dur=fim>=ini ? fim-ini : 0;
   g_aud302LotesEscrita++;
   g_aud302EscritaUsTotal+=dur;
   if(dur>g_aud302EscritaUsMax) g_aud302EscritaUsMax=dur;
}

void AuditoriaFecharFIX302()
{
   AuditoriaFlushFIX302(true);
   if(g_logValidacaoHandle!=INVALID_HANDLE) { FileFlush(g_logValidacaoHandle); FileClose(g_logValidacaoHandle); g_logValidacaoHandle=INVALID_HANDLE; }
   if(g_aud302LogHandle!=INVALID_HANDLE) { FileFlush(g_aud302LogHandle); FileClose(g_aud302LogHandle); g_aud302LogHandle=INVALID_HANDLE; }
   if(g_aud302ResumoHandle!=INVALID_HANDLE) { FileFlush(g_aud302ResumoHandle); FileClose(g_aud302ResumoHandle); g_aud302ResumoHandle=INVALID_HANDLE; }
   if(g_aud305DealsHandle!=INVALID_HANDLE) { FileFlush(g_aud305DealsHandle); FileClose(g_aud305DealsHandle); g_aud305DealsHandle=INVALID_HANDLE; }
}

void AuditoriaRegistrarTempoTickFIX302(ulong micros)
{
   g_aud302Ticks++;
   g_aud302TickUsTotal+=micros;
   if(micros>g_aud302TickUsMax) g_aud302TickUsMax=micros;
}

void AuditoriaRegistrarTempoTimerFIX302(ulong micros)
{
   g_aud302Timers++;
   g_aud302TimerUsTotal+=micros;
   if(micros>g_aud302TimerUsMax) g_aud302TimerUsMax=micros;
}

void AuditoriaRegistrarTempoTradeFIX302(ulong micros)
{
   g_aud302Trades++;
   g_aud302TradeUsTotal+=micros;
   if(micros>g_aud302TradeUsMax) g_aud302TradeUsMax=micros;
}

void AuditoriaRegistrarDealEntradaFIX302(ulong deal,int nivel)
{
   if(deal==0 || !HistoryDealSelect(deal)) return;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(magic!=Aud302MagicLocal()) return;
   double preco=HistoryDealGetDouble(deal,DEAL_PRICE);
   double vol=HistoryDealGetDouble(deal,DEAL_VOLUME);
   if(nivel<0 || nivel>5) nivel=0;
   g_aud302DealNivel[nivel]=deal;
   g_aud302PrecoEntrada[nivel]=preco;
   g_aud302EntradaNivel[nivel]="APROVADO";
   if(JanelaAtualEhA_FIX255())
      AuditoriaRegistrarEventoFIX302(g_compra,"DEAL_ENTRADA_CONFIRMADA",StringFormat("A%d deal %I64u confirmado pelo servidor em %.0f volume %.2f",nivel,deal,preco,vol),TRADE_RETCODE_DONE,0,vol,preco,true);
   else
      AuditoriaRegistrarEventoFIX302(g_venda,"DEAL_ENTRADA_CONFIRMADA",StringFormat("A%d deal %I64u confirmado pelo servidor em %.0f volume %.2f",nivel,deal,preco,vol),TRADE_RETCODE_DONE,0,vol,preco,true);
}

void AuditoriaRegistrarDealSaidaFIX302(ulong deal,int nivel,double resultado)
{
   if(deal==0 || !HistoryDealSelect(deal)) return;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(magic!=Aud302MagicLocal()) return;
   double preco=HistoryDealGetDouble(deal,DEAL_PRICE);
   double vol=HistoryDealGetDouble(deal,DEAL_VOLUME);
   if(nivel<0 || nivel>5) nivel=0;
   g_aud302DealNivel[nivel]=deal;
   g_aud302PrecoSaida[nivel]=preco;
   g_aud302ResultadoNivel[nivel]+=resultado;
   g_aud302ParcialNivel[nivel]="APROVADO";
   g_aud302FinanceiroNivel[nivel]="APROVADO";
   if(JanelaAtualEhA_FIX255())
      AuditoriaRegistrarEventoFIX302(g_compra,"DEAL_PARCIAL_CONFIRMADA",StringFormat("A%d deal %I64u saida confirmada em %.0f volume %.2f resultado %.2f",nivel,deal,preco,vol,resultado),TRADE_RETCODE_DONE,0,vol,preco,true);
   else
      AuditoriaRegistrarEventoFIX302(g_venda,"DEAL_PARCIAL_CONFIRMADA",StringFormat("A%d deal %I64u saida confirmada em %.0f volume %.2f resultado %.2f",nivel,deal,preco,vol,resultado),TRADE_RETCODE_DONE,0,vol,preco,true);
}

bool AuditoriaObjetoPrecoFIX302(string base,double esperado,string &detalhe)
{
   string nome=base+"_LIN";
   if(ObjectFind(0,nome)<0)
   {
      detalhe=nome+" AUSENTE";
      return false;
   }
   double atual=ObjectGetDouble(0,nome,OBJPROP_PRICE);
   double tol=MathMax(_Point*2.0,SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)*2.0);
   bool ok=(esperado<=0.0 || MathAbs(atual-esperado)<=tol);
   detalhe=StringFormat("%s atual %.0f esperado %.0f diff %.1fpt",nome,atual,esperado,MathAbs(atual-esperado)/_Point);
   return ok;
}

void AuditoriaValidarGraficoFIX302(bool forcar)
{
   if(!g_aud302Inicializada || (!forcar && !g_aud302ValidarGraficoPendente)) return;
   g_aud302ValidarGraficoPendente=false;
   EstadoLado estado;
   if(JanelaAtualEhA_FIX255()) estado=g_compra; else estado=g_venda;
   string p=JanelaAtualEhA_FIX255() ? "C" : "V";
   if(!estado.posicaoAberta)
      return;
   double parcialCiclo=ParcialCicloLadoGraficoFIX330(estado);
   double abertoNecessarioGain=MathAbs(InpEntradaGanhoAlvoReais)-parcialCiclo;
   double abertoNecessarioLoss=-MathAbs(InpEntradaPerdaMaximaReais)-parcialCiclo;
   double pg=PrecoResultadoAbertoGraficoFIX330(estado,abertoNecessarioGain);
   double ps=PrecoResultadoAbertoGraficoFIX330(estado,abertoNecessarioLoss);
   string detG="",detS="";
   bool okG=AuditoriaObjetoPrecoFIX302(p+"_GAIN",pg,detG);
   bool okS=AuditoriaObjetoPrecoFIX302(p+"_STOP",ps,detS);
   g_aud302GraficoNivel[0]=(okG && okS) ? "APROVADO" : "FALHOU";
   for(int nivel=1;nivel<=5;nivel++)
   {
      double esperado=0.0;
      ulong ticket=0; double pe=0,vol=0; long tipo=-1;
      bool aberto=ObterPosicaoAumentoNivelFIX212(estado,nivel,ticket,pe,vol,tipo);
      if(aberto)
      {
         double alvo=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*vol;
         bool armado=false; double defesa=0;
         if(estado.lado==LADO_COMPRA) { armado=g_trailAumentoBuy[nivel-1].protecaoArmada; defesa=g_trailAumentoBuy[nivel-1].defesaAtual; }
         else { armado=g_trailAumentoSell[nivel-1].protecaoArmada; defesa=g_trailAumentoSell[nivel-1].defesaAtual; }
         esperado=PrecoRealizacaoAumentoFIX212(tipo,pe,vol,armado ? defesa : alvo);
      }
      else
      {
         double pr=0.0;
         if(AumentoRealizadoFIX212(estado,nivel,pr)) esperado=pr;
         else esperado=PrecoNivelAumentoValorIndice(estado,nivel-1);
      }
      string det="";
      bool ok=AuditoriaObjetoPrecoFIX302(p+"_A"+IntegerToString(nivel),esperado,det);
      g_aud302GraficoNivel[nivel]=ok ? "APROVADO" : "FALHOU";
      if(!ok)
      {
         g_aud302ChecksFalha++;
         if(JanelaAtualEhA_FIX255()) AuditoriaRegistrarEventoFIX302(g_compra,"GRAFICO_DIVERGENTE",StringFormat("A%d %s",nivel,det),0,0,0,esperado,true);
         else AuditoriaRegistrarEventoFIX302(g_venda,"GRAFICO_DIVERGENTE",StringFormat("A%d %s",nivel,det),0,0,0,esperado,true);
      }
      else g_aud302ChecksOK++;
   }
   if(!okG || !okS)
   {
      if(JanelaAtualEhA_FIX255()) AuditoriaRegistrarEventoFIX302(g_compra,"GRAFICO_GAIN_STOP_DIVERGENTE",detG+" | "+detS,0,0,0,0,true);
      else AuditoriaRegistrarEventoFIX302(g_venda,"GRAFICO_GAIN_STOP_DIVERGENTE",detG+" | "+detS,0,0,0,0,true);
   }
}

string AuditoriaResumoNivelFIX302(int n)
{
   return StringFormat("A%d F:%s E:%s T:%s P:%s G:%s $:%s",n,g_aud302FiltroNivel[n],g_aud302EntradaNivel[n],g_aud302TrailNivel[n],g_aud302ParcialNivel[n],g_aud302GraficoNivel[n],g_aud302FinanceiroNivel[n]);
}

string AuditoriaResultadoCicloFIX302()
{
   for(int i=0;i<6;i++)
   {
      if(g_aud302EntradaNivel[i]=="FALHOU" || g_aud302GraficoNivel[i]=="FALHOU" || g_aud302FinanceiroNivel[i]=="FALHOU")
         return "FALHOU";
   }
   return "APROVADO_COM_PENDENCIAS";
}

void AuditoriaEnfileirarResumoFIX302()
{
   EstadoLado estado;
   if(JanelaAtualEhA_FIX255()) estado=g_compra; else estado=g_venda;
   double realLocal=0,abertoLocal=0,saldoLocal=0,realC=0,realV=0,abertoC=0,abertoV=0,saldoC=0,saldoV=0;
   AuditoriaFotoLeveFIX302(estado,realLocal,abertoLocal,saldoLocal,realC,realV,abertoC,abertoV,saldoC,saldoV);
   string l="";
   AuditoriaCSVAddFIX302(l,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   AuditoriaCSVAddFIX302(l,g_aud302Sessao); AuditoriaCSVAddFIX302(l,_Symbol); AuditoriaCSVAddFIX302(l,Aud302JanelaLocal()); AuditoriaCSVAddFIX302(l,Aud302LadoLocal()); AuditoriaCSVAddFIX302(l,IntegerToString((int)Aud302MagicLocal())); AuditoriaCSVAddFIX302(l,g_identidadeGrupoFIX304); AuditoriaCSVAddFIX302(l,g_identidadeGeracaoFIX304); AuditoriaCSVAddFIX302(l,Aud302Cenario()); AuditoriaCSVAddFIX302(l,g_aud302Ciclo);
   for(int n=0;n<6;n++)
   {
      AuditoriaCSVAddFIX302(l,g_aud302FiltroNivel[n]); AuditoriaCSVAddFIX302(l,g_aud302EntradaNivel[n]); AuditoriaCSVAddFIX302(l,g_aud302TrailNivel[n]);
      if(n>0) AuditoriaCSVAddFIX302(l,g_aud302ParcialNivel[n]);
      AuditoriaCSVAddFIX302(l,g_aud302GraficoNivel[n]); AuditoriaCSVAddFIX302(l,g_aud302FinanceiroNivel[n]);
   }
   AuditoriaCSVAddFIX302(l,DoubleToString(realLocal,2)); AuditoriaCSVAddFIX302(l,DoubleToString(abertoLocal,2)); AuditoriaCSVAddFIX302(l,DoubleToString(saldoLocal,2));
   AtualizarGanhoQtdReaisFIX362(false);
   AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.qtdCompra,2)); AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.reaisCompra,2));
   AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.qtdVenda,2)); AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.reaisVenda,2));
   AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.qtdHead,2)); AuditoriaCSVAddFIX302(l,DoubleToString(g_ganhoQtdReaisFIX362.reaisHead,2));
   AuditoriaCSVAddFIX302(l,IntegerToString(g_ordemEnviadas)); AuditoriaCSVAddFIX302(l,IntegerToString(g_ordemRejeitadas)); AuditoriaCSVAddFIX302(l,IntegerToString(g_aud302FilaDescartada));
   AuditoriaCSVAddFIX302(l,IntegerToString((long)AuditoriaMediaFIX302(g_aud302TickUsTotal,g_aud302Ticks))); AuditoriaCSVAddFIX302(l,IntegerToString((long)g_aud302TickUsMax));
   AuditoriaCSVAddFIX302(l,IntegerToString((long)AuditoriaMediaFIX302(g_aud302TimerUsTotal,g_aud302Timers))); AuditoriaCSVAddFIX302(l,IntegerToString((long)g_aud302TimerUsMax));
   AuditoriaCSVAddFIX302(l,IntegerToString((long)AuditoriaMediaFIX302(g_aud302EscritaUsTotal,g_aud302LotesEscrita))); AuditoriaCSVAddFIX302(l,IntegerToString((long)g_aud302EscritaUsMax));
   AuditoriaCSVAddFIX302(l,AuditoriaResultadoCicloFIX302());
   string log="RESUMO CICLO "+g_aud302Ciclo+" | "+AuditoriaResumoNivelFIX302(0)+" | "+AuditoriaResumoNivelFIX302(1)+" | "+AuditoriaResumoNivelFIX302(2)+" | "+AuditoriaResumoNivelFIX302(3)+" | "+AuditoriaResumoNivelFIX302(4)+" | "+AuditoriaResumoNivelFIX302(5);
   AuditoriaEnfileirarFIX302(l,log,1,true);
}

void AuditoriaAtualizarCicloFIX302()
{
   // FIX310: a auditoria de runtime precisa conferir a data mesmo sem ciclo/posicao.
   AuditoriaViradaDiaFIX310(AgoraServidorHistorico());
   AuditoriaHistoricoMagicFIX311(false);
   if(!g_aud302Inicializada) return;
   bool aberta=JanelaAtualEhA_FIX255() ? g_compra.posicaoAberta : g_venda.posicaoAberta;
   if(!g_aud302PosAnterior && aberta)
   {
      AuditoriaResetarNiveisFIX302();
      string cicloNovo=CicloAtualMagicFIX304(Aud302MagicLocal(),true);
      g_aud302Ciclo=g_identidadeGeracaoFIX304+"_"+cicloNovo;
      g_aud302CicloAtivo=true;
      if(JanelaAtualEhA_FIX255()) AuditoriaRegistrarEventoFIX302(g_compra,"CICLO_INICIO","Novo ciclo local detectado",0,0,0,g_compra.precoMedio,true);
      else AuditoriaRegistrarEventoFIX302(g_venda,"CICLO_INICIO","Novo ciclo local detectado",0,0,0,g_venda.precoMedio,true);
   }
   else if(g_aud302PosAnterior && !aberta && g_aud302CicloAtivo)
   {
      AuditoriaValidarGraficoFIX302(true);
      AuditoriaEnfileirarResumoFIX302();
      g_aud302StatusGeral=AuditoriaResultadoCicloFIX302();
      g_aud302CicloAtivo=false;
      EncerrarCicloIdentidadeLocalFIX304();
      g_aud302UltimoEvento="CICLO FINALIZADO | "+g_aud302StatusGeral;
   }
   g_aud302PosAnterior=aberta;
}


#endif
