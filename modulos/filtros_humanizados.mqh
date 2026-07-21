#ifndef COPA_FILTROS_HUMANIZADOS_MQH
#define COPA_FILTROS_HUMANIZADOS_MQH

// ============================================================================
// RESPONSABILIDADE: NORMALIZACAO DOS FILTROS HUMANIZADOS
// Funcoes movidas do principal na V38 sem alteracao de regra operacional.
// ============================================================================

bool ExtrairPrimeiroNumeroAPartir(string texto, int inicio, double &valor, int &fimNumero)
{
   valor = 0.0;
   fimNumero = inicio;
   int total = StringLen(texto);
   string numero = "";
   bool iniciou = false;
   int inicioSeguro = (inicio < 0 ? 0 : inicio);
   for(int i = inicioSeguro; i < total; i++)
   {
      ushort ch = StringGetCharacter(texto, i);
      bool digito = (ch >= '0' && ch <= '9');
      bool separadorDecimal = (ch == '.' || ch == ',');
      bool sinal = (ch == '-' && !iniciou);
      if(digito || (separadorDecimal && iniciou) || sinal)
      {
         if(ch == ',')
            numero += ".";
         else
            numero += ShortToString(ch);
         iniciou = true;
         fimNumero = i + 1;
         continue;
      }
      if(iniciou)
         break;
   }
   if(numero == "" || numero == "-")
      return false;
   valor = StringToDouble(numero);
   return true;
}

double NumeroDepoisDoMarcador(string texto, string marcador, double padrao)
{
   string superior = Upper(texto);
   string chave = Upper(marcador);
   int pos = StringFind(superior, chave);
   if(pos < 0)
      return padrao;
   double valor = 0.0;
   int fim = pos + StringLen(chave);
   if(!ExtrairPrimeiroNumeroAPartir(superior, fim, valor, fim))
      return padrao;
   return valor;
}

bool DoisNumerosDepoisDoMarcador(string texto, string marcador, double &primeiro, double &segundo)
{
   primeiro = 0.0;
   segundo = 0.0;
   string superior = Upper(texto);
   string chave = Upper(marcador);
   int pos = StringFind(superior, chave);
   if(pos < 0)
      return false;
   int fimPrimeiro = pos + StringLen(chave);
   if(!ExtrairPrimeiroNumeroAPartir(superior, fimPrimeiro, primeiro, fimPrimeiro))
      return false;
   int fimSegundo = fimPrimeiro;
   if(!ExtrairPrimeiroNumeroAPartir(superior, fimPrimeiro, segundo, fimSegundo))
      return false;
   return true;
}

int CandlesNoFormatoCurto(string texto, int padrao)
{
   string superior = Upper(texto);
   int total = StringLen(superior);
   for(int i = 0; i < total; i++)
   {
      ushort ch = StringGetCharacter(superior, i);
      if(ch < '0' || ch > '9')
         continue;
      double valor = 0.0;
      int fim = i;
      if(!ExtrairPrimeiroNumeroAPartir(superior, i, valor, fim))
         continue;
      int j = fim;
      while(j < total && StringGetCharacter(superior, j) == ' ')
         j++;
      if(j < total && StringGetCharacter(superior, j) == 'C')
      {
         int candles = (int)MathRound(valor);
         if(candles < 1)
            candles = 1;
         return candles;
      }
      i = MathMax(i, fim - 1);
   }
   return padrao;
}

string NormalizarFiltrosHumanizados(string linha)
{
   string raw = Trim(linha);
   string superior = Upper(raw);
   if(raw == "" || superior == "LIVRE" || superior == "SEM FILTRO" ||
      superior == "SEM FILTROS" || superior == "OFF")
      return "MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";

   // Compatibilidade com configurações técnicas antigas em CHAVE=VALOR.
   if(StringFind(raw, "=") >= 0 || StringFind(raw, ";") >= 0)
      return raw;

   // FIX326: matriz humana com volume combinado, forca, Fibo e WAP Bands reais.
   if(StringFind(superior,"MACD")>=0 || StringFind(superior,"ATR")>=0 ||
      StringFind(superior,"SCORE")>=0)
      return "INVALIDO=ON;ERRO=FILTRO_NAO_SUPORTADO_NESTA_MATRIZ;MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";
   int minimoOk=0;
   bool modoMinimo=(StringFind(superior,"MIN ")>=0 || StringFind(superior,"MINIMO")>=0);
   if(modoMinimo)
   {
      minimoOk=(int)MathRound(MathAbs(NumeroDepoisDoMarcador(superior,"MIN",6.0)));
      if(minimoOk<1) minimoOk=1;
      if(minimoOk>10) minimoOk=10;
   }
   string normalizada = (modoMinimo ? StringFormat("MODO=MINIMO;MIN_OK=%d",minimoOk) : "MODO=TODOS;MIN_OK=0");
   int usados = 0;

   if(StringFind(superior, "HILO8") >= 0 || StringFind(superior, "HILO") >= 0)
   {
      normalizada += ";HILO=ON";
      usados++;
   }
   if(StringFind(superior, "STR") >= 0)
   {
      normalizada += ";STR=ON";
      usados++;
   }

   bool volumeCombinado = (StringFind(superior, "VOLUME QTD+FIN") >= 0 ||
                           StringFind(superior, "VOLUME QTD + FIN") >= 0 ||
                           StringFind(superior, "VOLQ+VOLF") >= 0 ||
                           StringFind(superior, "VOLQ + VOLF") >= 0);
   int posVOLQ = StringFind(superior, "VOLQ");
   if(posVOLQ < 0)
      posVOLQ = StringFind(superior, "VOLUME QTD");
   int posVOLF = StringFind(superior, "VOLF");
   if(posVOLF < 0)
      posVOLF = StringFind(superior, "VOLUME FIN");
   if(volumeCombinado)
   {
      normalizada += ";VOLCOMB=ON;VOLQ=ON;VOLQMIN=1000.00;VOLF=ON;VOLFMIN=1000000.00";
      usados++;
   }
   else
   {
      // Compatibilidade: VOLQ ou VOLF separados continuam aceitos, sem criar novas opções visuais.
      if(posVOLQ >= 0)
      {
         string marcadorQ = (StringFind(superior, "VOLQ") >= 0 ? "VOLQ" : "VOLUME QTD");
         double minimoVOLQ = MathAbs(NumeroDepoisDoMarcador(superior, marcadorQ, 1000.0));
         normalizada += StringFormat(";VOLQ=ON;VOLQMIN=%.2f", minimoVOLQ);
         usados++;
      }
      if(posVOLF >= 0)
      {
         string marcadorF = (StringFind(superior, "VOLF") >= 0 ? "VOLF" : "VOLUME FIN");
         double minimoVOLF = MathAbs(NumeroDepoisDoMarcador(superior, marcadorF, 1000000.0));
         normalizada += StringFormat(";VOLF=ON;VOLFMIN=%.2f", minimoVOLF);
         usados++;
      }
   }

   if(StringFind(superior, "DX") >= 0)
   {
      double minimoDX = MathAbs(NumeroDepoisDoMarcador(superior, "DX", 25.0));
      normalizada += StringFormat(";DX25=ON;DXMIN=%.2f", minimoDX);
      usados++;
   }

   if(StringFind(superior, "RSI") >= 0)
   {
      double faixaBaixa = 30.0;
      double faixaAlta = 70.0;
      double numero1 = 0.0;
      double numero2 = 0.0;
      if(DoisNumerosDepoisDoMarcador(superior, "RSI", numero1, numero2))
      {
         faixaBaixa = MathMin(numero1, numero2);
         faixaAlta = MathMax(numero1, numero2);
      }
      // FIX274: RSI 30/70 deve significar COMPRA em sobrevenda (<=30)
      // e VENDA em sobrecompra (>=70). O mapeamento antigo estava invertido.
      normalizada += StringFormat(";RSI=ON;RSIC=%.2f;RSIV=%.2f;RSIC_OP=<=;RSIV_OP=>=",
                                  faixaBaixa, faixaAlta);
      usados++;
   }

   int posAGR = StringFind(superior, "AGR");
   if(posAGR < 0)
      posAGR = StringFind(superior, "AGF");
   if(posAGR >= 0)
   {
      string marcador = (StringFind(superior, "AGR") >= 0 ? "AGR" : "AGF");
      double minimoAGR = MathAbs(NumeroDepoisDoMarcador(superior, marcador, 50.0));
      normalizada += StringFormat(";AGF=ON;AGFMIN=%.2f", minimoAGR);
      usados++;
   }

   if(StringFind(superior,"M25")>=0 || StringFind(superior,"MEDIA25")>=0)
   {
      normalizada += ";M25=ON";
      usados++;
   }

   int posForca=StringFind(superior,"FORCA");
   if(posForca<0) posForca=StringFind(superior,"FORÇA");
   if(posForca>=0)
   {
      string marcadorForca=(StringFind(superior,"FORCA")>=0 ? "FORCA" : "FORÇA");
      double minimoForca=MathAbs(NumeroDepoisDoMarcador(superior,marcadorForca,60.0));
      normalizada+=StringFormat(";FORCA=ON;FORCAMIN=%.2f",minimoForca);
      usados++;
   }

   if(StringFind(superior,"FIBO")>=0)
   {
      double minimoFibo=MathAbs(NumeroDepoisDoMarcador(superior,"FIBO",1.272));
      normalizada+=StringFormat(";FIBO=ON;FIBOMIN=%.3f",minimoFibo);
      usados++;
   }

   int posWap=StringFind(superior,"WAPBANDS");
   string marcadorWap="WAPBANDS";
   if(posWap<0)
   {
      posWap=StringFind(superior,"WAP BANDS");
      marcadorWap="WAP BANDS";
   }
   if(posWap<0)
   {
      posWap=StringFind(superior,"VWAP");
      marcadorWap="VWAP";
   }
   if(posWap>=0)
   {
      double desvios=MathAbs(NumeroDepoisDoMarcador(superior,marcadorWap,1.0));
      normalizada+=StringFormat(";WAPBANDS=ON;WAPDESVIO=%.2f",desvios);
      usados++;
   }

   int candles = CandlesNoFormatoCurto(superior, 1);
   normalizada += StringFormat(";CONF=FECHAMENTO;CANDLES=%d", candles);

   if(usados == 0)
      return "INVALIDO=ON;ERRO=FILTRO_NAO_RECONHECIDO;MODO=TODOS;MIN_OK=0;CONF=FECHAMENTO;CANDLES=1";
   return normalizada;
}


void AplicarConfirmacaoLinhasAumentos()
{
   // FIX363: regra obrigatória e não sobrescrita por modo de teste.
   // A linha apenas arma. A ordem só pode sair depois do candle M1 fechado,
   // filtros aprovados e preço executável ainda na linha ou em posição melhor.
   InpConfirmacaoLinhasAumentos="FECHAMENTO | M1 | 0P | PRECO MELHOR";
   InpAumentoConfirmarFechamentoCandle=true;
   InpAumentoTimeframeConfirmacao=PERIOD_M1;
   InpAumentoMargemFechamentoPontos=0.0;
}

string CombinarLinhaFiltro(string linhaBase, string linhaFiltros)
{
   linhaBase = Trim(linhaBase);
   linhaFiltros = Trim(linhaFiltros);
   if(linhaBase == "")
      return linhaFiltros;
   if(linhaFiltros == "")
      return linhaBase;
   return linhaBase + ";" + linhaFiltros;
}

void CarregarMatrizSaida()
{
   ParseRiscoOperacao(InpRiscoOperacao);
   ParseRiscoDiario(InpRiscoDiario);
   ParseProtecaoLucro(InpProtecaoLucro);
   ParseOperacaoLonga(InpOperacaoLonga);
}


#endif // COPA_FILTROS_HUMANIZADOS_MQH
