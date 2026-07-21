#ifndef COPA_PARAMETROS_COMPACTOS_MQH
#define COPA_PARAMETROS_COMPACTOS_MQH

// ============================================================================
// RESPONSABILIDADE: LEITURA DAS MATRIZES COMPACTAS
// Funcoes movidas do principal na V38 sem alteracao de regra operacional.
// ============================================================================

void ParseRiscoOperacao(string linha)
{
   g_risco.ativo = IsOn(GetCampo(linha, "", "ON"));
   g_risco.metaOperacao = ExtrairNumero(GetCampo(linha, "META_OP", "150"));
   g_risco.stopOperacao = ExtrairNumero(GetCampo(linha, "STOP_OP", "450"));
   g_risco.valorProtecao = ExtrairNumero(GetCampo(linha, "VALOR_PROT", "75"));
   g_risco.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT_INICIAL", "50%"));
   g_risco.zerar50 = IsOn(GetCampo(linha, "ZERAR_50", "OFF"));
   g_risco.buscar100 = IsOn(GetCampo(linha, "BUSCAR_100", "ON"));
   g_risco.escalonar = IsOn(GetCampo(linha, "ESCALONAR", "ON"));
   g_risco.sincronizarFinanceiro = IsOn(GetCampo(linha, "SINCRONIZAR_FINANCEIRO", "ON"));
}

void ParseRiscoDiario(string linha)
{
   // FIX362: histórico diário nunca bloqueia entrada. O limite operacional
   // vem exclusivamente do campo visível LOSS HEAD.
   g_risco.metaDia = 0.0;
   g_risco.stopDia = LossHeadEfetivoFIX362();
}

void ParseProtecaoLucro(string linha)
{
   g_risco.defesaAtivaEm = ExtrairNumero(GetCampo(linha, "ATIVA_EM", "10R"));
   g_risco.naoVirarPrejuizo = IsOn(GetCampo(linha, "NAO_VIRAR_PREJUIZO", "ON"));
   g_risco.defesaMinima = ExtrairNumero(GetCampo(linha, "DEFESA_MIN", "1"));
   g_risco.protecaoPercent = ExtrairNumero(GetCampo(linha, "PROT_PERCENT", "50%"));
   g_risco.trailPasso = ExtrairNumero(GetCampo(linha, "TRAIL_PASSO", "2.5"));
}

void ParseOperacaoLonga(string linha)
{
   g_risco.operacaoLongaAtiva = IsOn(GetCampo(linha, "", "ON"));
   g_risco.ativaLongaEm = ExtrairNumero(GetCampo(linha, "ATIVA_LUCRO", "20R"));
   g_risco.operacaoLongaScoreSaida = ExtrairNumero(GetCampo(linha, "SCORE_VOL_SAIR", "40"));
   g_risco.operacaoLongaSomenteSeGanhoMaiorQue = 50.0;
}

void AplicarParametrosCompactos()
{
   AplicarConfirmacaoLinhasAumentos();
   InpMaxAumentos = ExtrairInteiro(GetCampo(InpAumentos, "MAX_AUMENTOS", GetCampo(InpAumentos, "MAX_AUM", "5")));
   InpMaxContratosTotal = ExtrairInteiro(GetCampo(InpAumentos, "MAX_CONTRATOS", GetCampo(InpAumentos, "MAX_CONTR", "100000")));
   // FIX237: a regra antiga nunca usa score para escolher ou pular niveis.
   // O modo SOMENTE SCORE continua sequencial: A1, depois A2, depois A3.
   InpModoAumentoExecucao = AUMENTO_SEQUENCIAL;
   InpPermitirAumentosNaValidacao = IsOn(GetCampo(InpAumentos, "VALIDACAO", "ON"));
   InpValidacaoAumentoIgnorarScoreExtremo = true; // FIX237: score geral removido da regra antiga.
   InpAumentosLivreTeste = (InpCenarioAuditoriaFIX302==AUD302_TESTE_SEM_FILTROS) ? true :
                              ((InpCenarioAuditoriaFIX302==AUD302_TESTE_COM_FILTROS) ? false : IsOn(GetCampo(InpAumentos, "LIVRE_TESTE", "OFF")));
   // FIX363: LIVRE pode retirar filtros, mas nunca pode retirar LINHA, CANDLE e PREÇO MELHOR.
   InpAumentosLivreIgnorarTimerPreco = false;
   InpAumentosLivreIgnorarMetaDia = IsOn(GetCampo(InpAumentos, "IGNORAR_META_DIA", "OFF"));
   string dirAum = Upper(GetCampo(InpAumentos, "DIR", "CONTRA"));
   InpAumentosContraPosicao = (dirAum == "CONTRA" || dirAum == "RECUPERACAO" || dirAum == "RECOVERY" || dirAum == "LOSS");
   AplicarAumentoCompactoNosInputs(1, InpA1);
   AplicarAumentoCompactoNosInputs(2, InpA2);
   AplicarAumentoCompactoNosInputs(3, InpA3);
   string filtroA1Normalizado = NormalizarFiltrosHumanizados(FiltroEfetivoAuditoriaFIX302(InpA1Filtros));
   InpAumentosModoFiltro = Upper(GetCampo(filtroA1Normalizado, "MODO", "TODOS"));
   InpAumentosMinOkFiltro = ExtrairInteiro(GetCampo(filtroA1Normalizado, "MIN_OK", "0"));
   InpAumentosConfirmarFechamento = (Upper(GetCampo(filtroA1Normalizado, "CONF", "FECHAMENTO")) == "FECHAMENTO");
   InpAumentosCandlesConfirmacao = ExtrairInteiro(GetCampo(filtroA1Normalizado, "CANDLES", "1"));
   InpAumentosDXMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "DXMIN", "25"));
   InpAumentosRSICompraMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "RSIC", "70"));
   InpAumentosRSIVendaMax = ExtrairNumero(GetCampo(filtroA1Normalizado, "RSIV", "30"));
   InpAumentosVolumeQtdMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "VOLQMIN", "1000"));
   InpAumentosVolumeFinMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "VOLFMIN", "1000000"));
   InpAumentosAgressaoMin = ExtrairNumero(GetCampo(filtroA1Normalizado, "AGFMIN", "50"));
}

void AplicarAumentoCompactoNosInputs(int nivel, string linha)
{
   linha = NormalizarLinhaAumentoHumanizada(linha);
   bool ativo = IsOn(GetCampo(linha, "", "ON"));
   double qtd = ExtrairNumero(GetCampo(linha, "QTD", GetCampo(linha, "A1", GetCampo(linha, "A2", GetCampo(linha, "A3", GetCampo(linha, "A4", "1"))))));
   int tempo = ExtrairInteiro(GetCampo(linha, "TEMPO", GetCampo(linha, "ESPERA", GetCampo(linha, "TIMER", "1m"))));
   double gatilho = ExtrairNumero(GetCampo(linha, "GATILHO", "20G"));
   int distancia = ExtrairInteiro(GetCampo(linha, "DIST", GetCampo(linha, "DISTANCIA", "200p")));
   double protecao = ExtrairNumero(GetCampo(linha, "PROT", "0%")); // FIX282: 50%P removido; TRAIL e lido por nivel em ParseAumento
   if(nivel == 1)
   {
      InpA1Ativo = ativo;
      InpA1Contratos = qtd;
      InpA1TempoMinutos = tempo;
      InpA1GatilhoReais = gatilho;
      InpA1DistanciaPontos = distancia;
      InpA1ProtecaoPercent = protecao;
   }
   else if(nivel == 2)
   {
      InpA2Ativo = ativo;
      InpA2Contratos = qtd;
      InpA2TempoMinutos = tempo;
      InpA2GatilhoReais = gatilho;
      InpA2DistanciaPontos = distancia;
      InpA2ProtecaoPercent = protecao;
   }
   else if(nivel == 3)
   {
      InpA3Ativo = ativo;
      InpA3Contratos = qtd;
      InpA3TempoMinutos = tempo;
      InpA3GatilhoReais = gatilho;
      InpA3DistanciaPontos = distancia;
      InpA3ProtecaoPercent = protecao;
   }
}

void AplicarParcialOperacaoCompacta()
{
   g_parcialOperacaoAtivaEfetiva = InpParcial50Ativa;
   g_parcialGatilhoReaisEfetivo = MathAbs(InpParcialGatilhoReais);
   g_parcialPorContratoEfetivo = InpParcialGatilhoPorContrato;
   g_parcialPassoReaisEfetivo = MathAbs(InpHedgeLucroPontaPassoReais);
   if(g_parcialPassoReaisEfetivo <= 0.0)
      g_parcialPassoReaisEfetivo = MathAbs(InpProtecaoTrailPassoReais);
   if(g_parcialPassoReaisEfetivo <= 0.0)
      g_parcialPassoReaisEfetivo = 5.0;
   g_parcialPercentualVolumeEfetivo = MathAbs(InpParcial50PercentualVolume);
   g_parcialRecuoAumentoAtivoEfetivo = InpParcialRecuoAumentoAtivo;
   g_parcialValorEmPontosEfetivo = false;
   if(g_parcialPercentualVolumeEfetivo <= 0.0)
      g_parcialPercentualVolumeEfetivo = 50.0;
   if(g_parcialPercentualVolumeEfetivo > 100.0)
      g_parcialPercentualVolumeEfetivo = 100.0;
   string linhaRaw = Trim(InpParcialOperacao);
   if(linhaRaw == "")
      return;
   string linha = Upper(linhaRaw);
   string linhaCampo = linha;
   StringReplace(linhaCampo, "|", ";");
   string primeiro = Upper(Trim(GetCampo(linhaCampo, "", "ON")));
   if(primeiro == "OFF" || primeiro == "NAO" || primeiro == "NÃO" || primeiro == "0")
      g_parcialOperacaoAtivaEfetiva = false;
   else if(primeiro == "ON" || primeiro == "SIM" || primeiro == "1")
      g_parcialOperacaoAtivaEfetiva = true;
   string valorCampo = GetCampo(linhaCampo, "PVALOR", GetCampo(linhaCampo, "VALOR", GetCampo(linhaCampo, "PARCIAL", "")));
   string passoCampo = GetCampo(linhaCampo, "PASSO", GetCampo(linhaCampo, "STEP", ""));
   string volumeCampo = GetCampo(linhaCampo, "VOLUME", GetCampo(linhaCampo, "VOL", ""));
   string modoCampo = Upper(GetCampo(linhaCampo, "MODO", ""));
   string partes[];
   int total = StringSplit(linha, '|', partes);
   if(total <= 1)
      total = StringSplit(linha, ';', partes);
   for(int i = 0; i < total; i++)
   {
      string parte = Upper(Trim(partes[i]));
      if(parte == "")
         continue;
      if(StringFind(parte, "OFF") >= 0)
         g_parcialOperacaoAtivaEfetiva = false;
      if(StringFind(parte, "ON") >= 0)
         g_parcialOperacaoAtivaEfetiva = true;
      if(StringFind(parte, "/C") >= 0 || StringFind(parte, "CONTRATO") >= 0)
         g_parcialPorContratoEfetivo = true;
      if(StringFind(parte, "TOTAL") >= 0 || StringFind(parte, "CESTA") >= 0)
         g_parcialPorContratoEfetivo = false;
      if(StringFind(parte, "RECUO") >= 0 || StringFind(parte, "PONT") >= 0 || StringFind(parte, "25P") >= 0 || StringFind(parte, "P;") >= 0)
         g_parcialRecuoAumentoAtivoEfetivo = true;
      if(StringFind(parte, "TOTAL") >= 0 || StringFind(parte, "FINANCEIRO") >= 0 || StringFind(parte, "REAIS") >= 0 || StringFind(parte, " R") >= 0)
         g_parcialRecuoAumentoAtivoEfetivo = false;
      if(StringFind(parte, "P") >= 0 && StringFind(parte, "%") < 0)
         g_parcialValorEmPontosEfetivo = true;
      if(StringFind(parte, "PASSO") >= 0 || StringFind(parte, "STEP") >= 0)
      {
         double vPasso = MathAbs(ExtrairNumero(parte));
         if(vPasso > 0.0)
            g_parcialPassoReaisEfetivo = vPasso;
         continue;
      }
      if(StringFind(parte, "VOL") >= 0 || StringFind(parte, "VOLUME") >= 0)
      {
         double vVol = MathAbs(ExtrairNumero(parte));
         if(vVol > 0.0)
            g_parcialPercentualVolumeEfetivo = MathMin(100.0, vVol);
         continue;
      }
      if(i > 0 && valorCampo == "")
      {
         double vParc = MathAbs(ExtrairNumero(parte));
         if(vParc > 0.0)
         {
            g_parcialGatilhoReaisEfetivo = vParc;
            valorCampo = parte;
         }
      }
   }
   if(valorCampo != "")
   {
      double v = MathAbs(ExtrairNumero(valorCampo));
      if(v > 0.0)
         g_parcialGatilhoReaisEfetivo = v;
      string valorUpper = Upper(valorCampo);
      if(StringFind(valorUpper, "/C") >= 0 || StringFind(valorUpper, "CONTRATO") >= 0)
         g_parcialPorContratoEfetivo = true;
      if(StringFind(valorUpper, "TOTAL") >= 0 || StringFind(valorUpper, "CESTA") >= 0)
         g_parcialPorContratoEfetivo = false;
   }
   if(passoCampo != "")
   {
      double v = MathAbs(ExtrairNumero(passoCampo));
      if(v > 0.0)
         g_parcialPassoReaisEfetivo = v;
   }
   if(volumeCampo != "")
   {
      double v = MathAbs(ExtrairNumero(volumeCampo));
      if(v > 0.0)
         g_parcialPercentualVolumeEfetivo = MathMin(100.0, v);
   }
   if(modoCampo == "TOTAL" || modoCampo == "CESTA")
   {
      g_parcialPorContratoEfetivo = false;
      g_parcialRecuoAumentoAtivoEfetivo = false;
   }
   if(modoCampo == "FINANCEIRO" || modoCampo == "REAIS")
      g_parcialRecuoAumentoAtivoEfetivo = false;
   if(modoCampo == "RECUO" || modoCampo == "RECUO_AUMENTO" || modoCampo == "PONTOS")
   {
      g_parcialRecuoAumentoAtivoEfetivo = true;
      g_parcialValorEmPontosEfetivo = true;
   }
   if(modoCampo == "CONTRATO" || modoCampo == "POR_CONTRATO" || modoCampo == "R/C")
      g_parcialPorContratoEfetivo = true;
}

bool ParcialOperacaoAtivaEfetiva()
{
   return g_parcialOperacaoAtivaEfetiva;
}

double ParcialGatilhoBaseReaisEfetivo()
{
   double v = MathAbs(g_parcialGatilhoReaisEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpParcialGatilhoReais);
   return v;
}

double ParcialPassoBaseReaisEfetivo()
{
   double v = MathAbs(g_parcialPassoReaisEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpHedgeLucroPontaPassoReais);
   if(v <= 0.0)
      v = MathAbs(InpProtecaoTrailPassoReais);
   if(v <= 0.0)
      v = 5.0;
   return v;
}

double ParcialPercentualVolumeEfetivo()
{
   double v = MathAbs(g_parcialPercentualVolumeEfetivo);
   if(v <= 0.0)
      v = MathAbs(InpParcial50PercentualVolume);
   if(v <= 0.0)
      v = 50.0;
   if(v > 100.0)
      v = 100.0;
   return v;
}

bool ParcialPorContratoEfetivo()
{
   return g_parcialPorContratoEfetivo;
}

bool ParcialRecuoAumentoAtivoEfetivo()
{
   return g_parcialRecuoAumentoAtivoEfetivo;
}

long TipoPosicaoPeloLadoEstado(EstadoLado &estado)
{
   if(estado.lado == LADO_COMPRA)
      return POSITION_TYPE_BUY;
   if(estado.lado == LADO_VENDA)
      return POSITION_TYPE_SELL;
   if(estado.tipoPosicaoAtual == POSITION_TYPE_BUY || estado.tipoPosicaoAtual == POSITION_TYPE_SELL)
      return estado.tipoPosicaoAtual;
   return -1;
}

string ValorMatrizCompactaFIX373(string matriz,string chave,string padrao="")
{
   string partes[];
   int total=StringSplit(matriz,'|',partes);
   string alvo=Upper(Trim(chave));
   for(int i=0;i<total;i++)
   {
      string item=Trim(partes[i]);
      int pos=StringFind(item,"=");
      if(pos<1) continue;
      string nome=Upper(Trim(StringSubstr(item,0,pos)));
      if(nome!=alvo) continue;
      return Trim(StringSubstr(item,pos+1));
   }
   return padrao;
}

bool SimCompactoFIX373(string valor,bool padrao=false)
{
   string t=Upper(Trim(valor));
   if(t=="") return padrao;
   if(t=="SIM" || t=="S" || t=="ON" || t=="TRUE" || t=="1" || t=="ATIVO" || t=="ATIVADO") return true;
   if(t=="NAO" || t=="N" || t=="OFF" || t=="FALSE" || t=="0" || t=="INATIVO" || t=="DESATIVADO") return false;
   return padrao;
}

double NumeroCompactoFIX373(string valor,double padrao=0.0)
{
   string t=Upper(Trim(valor));
   if(t=="" || t=="NULO" || t=="VAZIO") return padrao;
   StringReplace(t,",",".");
   StringReplace(t,"R$","");
   StringReplace(t,"%","");
   StringReplace(t," ","");
   int n=StringLen(t);
   while(n>0)
   {
      ushort c=StringGetCharacter(t,n-1);
      if((c>='0' && c<='9') || c=='.') break;
      t=StringSubstr(t,0,n-1);
      n=StringLen(t);
   }
   if(t=="" || t=="-" || t=="+") return padrao;
   return StringToDouble(t);
}

void SepararValoresCompactosFIX373(string valor,string &a,string &b,string &c)
{
   a=""; b=""; c="";
   string p[];
   int n=StringSplit(valor,'/',p);
   if(n>0) a=Trim(p[0]);
   if(n>1) b=Trim(p[1]);
   if(n>2) c=Trim(p[2]);
}

ENUM_MODO_ENTRADA_A0_FIX310 ModoEntradaCompactoFIX373(string valor)
{
   string t=Upper(Trim(valor));
   if(StringFind(t,"FAVOR_E_CONTRA")>=0 || StringFind(t,"AMBOS")>=0) return A0_FIX310_FAVOR_E_CONTRA;
   if(StringFind(t,"CONTRA")>=0) return A0_FIX310_CONTRA;
   if(StringFind(t,"FAVOR")>=0) return A0_FIX310_FAVOR;
   return A0_FIX310_LIVRE;
}

void LerJanelaCompactaFIX373(string matriz,string horarioPadrao,string &horario,string &f1,string &f2,string &f3)
{
   horario=ValorMatrizCompactaFIX373(matriz,"HORARIO",horarioPadrao);
   f1=ValorMatrizCompactaFIX373(matriz,"F1","NULO");
   f2=ValorMatrizCompactaFIX373(matriz,"F2","NULO");
   f3=ValorMatrizCompactaFIX373(matriz,"F3","NULO");
}

bool EntradaA0SemFiltrosCompactaFIX377()
{
   bool usar=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"USAR","SIM"),true);
   string f1=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"1o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F1","NULO"));
   string f2=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"2o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F2","NULO"));
   string f3=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"3o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F3","NULO"));
   string n1=Upper(Trim(f1)),n2=Upper(Trim(f2)),n3=Upper(Trim(f3));
   bool z1=(n1=="" || n1=="0" || n1=="NULL" || n1=="NULO" || n1=="NENHUM" || n1=="OFF" || n1=="LIVRE");
   bool z2=(n2=="" || n2=="0" || n2=="NULL" || n2=="NULO" || n2=="NENHUM" || n2=="OFF" || n2=="LIVRE");
   bool z3=(n3=="" || n3=="0" || n3=="NULL" || n3=="NULO" || n3=="NENHUM" || n3=="OFF" || n3=="LIVRE");
   return (!usar || (z1 && z2 && z3));
}

string FiltroAumentoCompactoInternoFIX377(string linha)
{
   bool usar=SimCompactoFIX373(ValorMatrizCompactaFIX373(linha,"USAR","SIM"),true);
   if(!usar)
      return "LIVRE";
   string f1=ValorMatrizCompactaFIX373(linha,"1o",ValorMatrizCompactaFIX373(linha,"F1","NULO"));
   string f2=ValorMatrizCompactaFIX373(linha,"2o",ValorMatrizCompactaFIX373(linha,"F2","NULO"));
   string f3=ValorMatrizCompactaFIX373(linha,"3o",ValorMatrizCompactaFIX373(linha,"F3","NULO"));

   // FIX379: cada A1-A5 conserva os seus tres filtros. A normalizacao
   // existente aplica RSI, VOLUME, FORCA, HILO, STR, MEDIA, DX, AGR,
   // FIBO ou WAP sem compartilhar o perfil com outro nivel.
   string perfil=MontarPerfilTresFiltrosFIX372(f1,f2,f3);
   if(Upper(Trim(perfil))=="LIVRE")
      return "LIVRE";
   string normalizado=NormalizarFiltrosHumanizados(perfil);
   // Preserva a leitura atual que ja era usada pelo filtro RSI dos aumentos.
   // O fechamento M1 continua obrigatorio na regra propria do aumento.
   StringReplace(normalizado,"CONF=FECHAMENTO","CONF=ATUAL");
   return normalizado;
}

void AplicarMatrizesCompactasFIX373()
{
   // 01 - Magic, lados e janela. FIX378: operacao e janela vem de caixas de escolha reais.
   if(InpOperacaoUsuarioFIX378==VENDIDO)
      InpLadosHabilitadosFIX346=OPERACAO_VENDA;
   else if(InpOperacaoUsuarioFIX378==AMBOS)
      InpLadosHabilitadosFIX346=OPERACAO_AMBOS;
   else
      InpLadosHabilitadosFIX346=OPERACAO_COMPRA;

   InpJanelaDesteGrafico=(InpJanelaUsuarioFIX378==JANELA_B ? JANELA_B_VENDA : JANELA_A_COMPRA);

   string magicCompra=ValorMatrizCompactaFIX373(InpMatrizMagicsFIX378,"MAGIC_COMPRA","326050");
   string magicVenda=ValorMatrizCompactaFIX373(InpMatrizMagicsFIX378,"MAGIC_VENDA","326051");
   InpMagicsCompraVenda=magicCompra+" / "+magicVenda;

   // 02 - HEAD e A0.
   InpAtivarRobo=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ROBO","SIM"),true);
   InpPermitirEnvioOrdens=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ORDENS","SIM"),true);
   InpContratosA0FIX372=(int)MathMax(1.0,NumeroCompactoFIX373(
      ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"CONTRATOS",
      ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ENTRADA",
      ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"A0","1C"))),1.0));
   string abertura=Upper(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ABERTURA","LIVRE_PROTEGIDA"));
   if(StringFind(abertura,"DESLIG")>=0) InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_DESLIGADA;
   else if(StringFind(abertura,"NORMAL")>=0) InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_NORMAL;
   else InpComoAbrirPrimeiraOrdem=PRIMEIRA_ORDEM_LIVRE_PROTEGIDA;
   InpModoEntradaCompra=ModoEntradaCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"COMPRA","LIVRE"));
   InpModoEntradaVenda=ModoEntradaCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"VENDA","LIVRE"));

   // 03 - Financeiro, escala e reentrada.
   InpGanhoPorTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ALVO",ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GANHO_OPERACAO","50")),50.0));
   InpPerdaPorTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"PERDA",ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"PERDA_OPERACAO","500")),500.0));
   string tA,tB,tC;
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"ACOMPANHA",
                                  ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"TRAIL","20/5")),tA,tB,tC);
   InpTrailingAtivarTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,20.0));
   InpTrailingPassoTicketReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,5.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"PROTEGE",
                                  ValorMatrizCompactaFIX373(InpMatrizHeadEntradaFIX373,"MOVEL","10/5")),tA,tB,tC);
   InpMovelAtivarTicketReaisFIX395=MathAbs(NumeroCompactoFIX373(tA,10.0));
   InpMovelPassoTicketReaisFIX395=MathAbs(NumeroCompactoFIX373(tB,5.0));
   InpGarantiaPorContratoReaisFIX372=MathAbs(NumeroCompactoFIX373(
      ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GARANTIA_CONTRATO",
      ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GAR_CTT","100")),100.0));
   InpGarantiaPorLadoReaisFIX372=MathAbs(NumeroCompactoFIX373(
      ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GARANTIA_LADO",
      ValorMatrizCompactaFIX373(InpMatrizFinanceiroFIX373,"GAR_LADO","500")),500.0));

   InpMetaDiaEscalonadaAtiva=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"ATIVA","SIM"),true);
   InpProtecaoDiaAtivarReais=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"INICIO","250"),250.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"DEFESAS","50/100/150"),tA,tB,tC);
   InpProtecaoDiaInicialReais=MathAbs(NumeroCompactoFIX373(tA,50.0));
   InpDefesaEscala300ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,100.0));
   InpDefesaEscala350ReaisFIX372=MathAbs(NumeroCompactoFIX373(tC,150.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"RECUOS","75/100/150"),tA,tB,tC);
   InpRecuoEscala400ReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,75.0));
   InpRecuoEscala500ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,100.0));
   InpRecuoEscala600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tC,150.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizEscalaHeadFIX373,"ACIMA600","100/50"),tA,tB,tC);
   InpPassoLucroAcima600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tA,100.0));
   InpAumentoRecuoAcima600ReaisFIX372=MathAbs(NumeroCompactoFIX373(tB,50.0));
   InpGainGlobalCestaAtivo=false; // SEM_TETO e regra congelada.
   InpReentradaLucroSegundosFIX372=(int)MathMax(0.0,NumeroCompactoFIX373(
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"APOS_GANHO",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"REENT_GANHO",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"GANHO",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"LUCRO","5S")))),5.0));
   InpPausaReentradaSegundos=(int)MathMax(0.0,NumeroCompactoFIX373(
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"APOS_PERDA",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"REENT_PREJUIZO",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"PREJUIZO",
      ValorMatrizCompactaFIX373(InpMatrizReentradaFIX373,"PERDA","120S")))),120.0));

   // 04 - Filtros normais da A0.
   InpFiltroA0_1_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"1o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F1","NULO"));
   InpFiltroA0_2_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"2o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F2","NULO"));
   InpFiltroA0_3_FIX372=ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"3o",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"F3","NULO"));
   string tf=Upper(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"TEMPO",ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"TF","M5")));
   InpTimeframeFiltrosOperacionais=(StringFind(tf,"10")>=0 ? FILTROS_CANDLE_M10 : FILTROS_CANDLE_M5);
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizFiltrosEntradaFIX373,"DX","2/2/0"),tA,tB,tC);
   InpDXPeriodo=(int)MathMax(1.0,NumeroCompactoFIX373(tA,2.0));
   InpDXMediaPeriodo=(int)MathMax(1.0,NumeroCompactoFIX373(tB,2.0));
   InpDXDistanciaMedia=MathMax(0.0,NumeroCompactoFIX373(tC,0.0));

   // 05 - Aumentos e filtros exclusivos do gerenciador.
   InpQuantidadeReforcos=(int)MathMax(0.0,MathMin(5.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"MAX","5"),5.0)));
   string regra=Upper(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"REGRA","LINHA+TIMER+CANDLE+FILTROS"));
   InpModoGatilhoAumentos=(StringFind(regra,"SCORE")>=0 ? AUMENTOS_SOMENTE_POR_SCORE : AUMENTOS_POR_REGRA_ATUAL);
   string base=Upper(ValorMatrizCompactaFIX373(InpMatrizControleAumentosFIX373,"BASE","A0"));
   if(StringFind(base,"MEDIO")>=0 || StringFind(base,"PROTEG")>=0) InpBasePrecoAumento=BASE_PRECO_MEDIO_PROTEGIDO;
   else if(StringFind(base,"ULTIMO")>=0) InpBasePrecoAumento=BASE_ULTIMO_AUMENTO;
   else InpBasePrecoAumento=BASE_ENTRADA_INICIAL;
   InpFiltroAumento_1_FIX372="RSI";
   InpFiltroAumento_2_FIX372="NULO";
   InpFiltroAumento_3_FIX372="NULO";
   InpA1Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA1CompactoFIX375);
   InpA2Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA2CompactoFIX375);
   InpA3Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA3CompactoFIX375);
   InpA4Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA4CompactoFIX375);
   InpA5Filtros=FiltroAumentoCompactoInternoFIX377(InpFiltroA5CompactoFIX375);

   // 06 - Janelas sincronizadas somente com a entrada A0.
   LerJanelaCompactaFIX373(InpMatrizJanela1FIX373,"09:00-10:00",InpJanela1HorarioFIX372,InpJanela1Filtro1FIX372,InpJanela1Filtro2FIX372,InpJanela1Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela2FIX373,"10:00-12:00",InpJanela2HorarioFIX372,InpJanela2Filtro1FIX372,InpJanela2Filtro2FIX372,InpJanela2Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela3FIX373,"12:00-15:00",InpJanela3HorarioFIX372,InpJanela3Filtro1FIX372,InpJanela3Filtro2FIX372,InpJanela3Filtro3FIX372);
   LerJanelaCompactaFIX373(InpMatrizJanela4FIX373,"15:00-18:00",InpJanela4HorarioFIX372,InpJanela4Filtro1FIX372,InpJanela4Filtro2FIX372,InpJanela4Filtro3FIX372);

   // 07 - Seguranca e execucao.
   string ambiente=Upper(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"AMBIENTE","DEMO"));
   InpAmbienteExecucaoFIX342=(StringFind(ambiente,"REAL")>=0 ? AMBIENTE_FIX342_REAL : AMBIENTE_FIX342_DEMO);
   InpConfirmarContaRealFIX342=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"CONFIRMAR_REAL","NAO"),false);
   InpContaRealAutorizadaFIX342=(long)NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"CONTA","0"),0.0);
   InpServidorRealAutorizadoFIX342=ValorMatrizCompactaFIX373(InpMatrizAmbienteFIX373,"SERVIDOR","");
   if(Upper(InpServidorRealAutorizadoFIX342)=="VAZIO" || Upper(InpServidorRealAutorizadoFIX342)=="NULO") InpServidorRealAutorizadoFIX342="";
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"SL","SIM/2000"),tA,tB,tC);
   InpStopServidorEmergenciaAtivoFIX342=SimCompactoFIX373(tA,true);
   InpStopServidorEmergenciaPontosFIX342=MathAbs(NumeroCompactoFIX373(tB,2000.0));
   InpSpreadMaximoTicksFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"SPREAD","4"),4.0));
   InpTickMaximoIdadeSegundosFIX342=(int)MathMax(1.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"TICK","5S"),5.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"MARGEM","1000/300%"),tA,tB,tC);
   InpMargemLivreMinimaReaisFIX342=MathAbs(NumeroCompactoFIX373(tA,1000.0));
   InpNivelMargemMinimoPercentFIX342=MathAbs(NumeroCompactoFIX373(tB,300.0));
   InpMaxContratosBrutosABFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"MAX_AB","10"),10.0));
   InpMaxExposicaoLiquidaABFIX342=MathAbs(NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizProtecoesFIX373,"LIQ","5"),5.0));
   InpBloquearDiasAntesVencimentoFIX342=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"VENCIMENTO","2D"),2.0));
   InpIntervaloMinimoOrdensRealSegFIX342=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"INTERVALO_REAL","2S"),2.0));
   SepararValoresCompactosFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"COMISSAO","MANUAL/0/SIM"),tA,tB,tC);
   string modoComissao=Upper(tA);
   if(StringFind(modoComissao,"AUTO")>=0) InpModoComissaoAtivoFIX305=COMISSAO_AUTO_FIX305;
   else if(StringFind(modoComissao,"CORRET")>=0 || StringFind(modoComissao,"SERVIDOR")>=0) InpModoComissaoAtivoFIX305=COMISSAO_SERVIDOR_FIX305;
   else InpModoComissaoAtivoFIX305=COMISSAO_MANUAL_IDA_VOLTA_FIX305;
   InpComissaoIdaVoltaPorContratoReaisFIX305=MathAbs(NumeroCompactoFIX373(tB,0.0));
   InpComissaoAfetaFinanceiroRoboFIX305=SimCompactoFIX373(tC,true);
   InpDesvioMaximoPontos=(int)MathMax(0.0,NumeroCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizCustosFIX373,"DESVIO_A0","20"),20.0));

   // 08 - Encerramento.
   InpHorarioBloquearNovasOperacoes=ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"BLOQUEAR","18:00");
   InpFechamentoFimDiaAtivo=SimCompactoFIX373(ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"ZERAR","SIM"),true);
   InpHorarioFecharTudo=ValorMatrizCompactaFIX373(InpMatrizEncerramentoFIX373,"HORARIO","18:15");

   // 09 - Teste e auditoria.
   string teste=Upper(ValorMatrizCompactaFIX373(InpMatrizTesteFIX373,"TESTE","A0+A1-A4"));
   if(teste=="A0" || StringFind(teste,"SOMENTE A0")>=0) InpModoValidacaoExecucao=VALIDAR_A0_APENAS;
   else if(StringFind(teste,"NORMAL")>=0 || StringFind(teste,"COMPLETO")>=0) InpModoValidacaoExecucao=OPERAR_COMPLETO;
   else InpModoValidacaoExecucao=VALIDAR_A0_E_AUMENTOS;
   string auditoria=Upper(ValorMatrizCompactaFIX373(InpMatrizTesteFIX373,"AUDITORIA","CONFIG_ATUAL"));
   if(StringFind(auditoria,"SEM_FILTRO")>=0 || StringFind(auditoria,"LIVRE")>=0) InpCenarioAuditoriaFIX302=AUD302_TESTE_SEM_FILTROS;
   else if(StringFind(auditoria,"COM_FILTRO")>=0) InpCenarioAuditoriaFIX302=AUD302_TESTE_COM_FILTROS;
   else InpCenarioAuditoriaFIX302=AUD302_USAR_CONFIG_ATUAL;
}

#endif // COPA_PARAMETROS_COMPACTOS_MQH
