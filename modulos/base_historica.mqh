// COPA V06 - Etapa 06: exportacao da base historica para CSV.
// Este modulo apenas le candles e grava arquivos; nao envia ordens.
#ifndef COPA_V06_MODULOS_BASE_HISTORICA_MQH
#define COPA_V06_MODULOS_BASE_HISTORICA_MQH

datetime FimBaseHistorica()
{
   datetime fim = TimeCurrent();
   if(fim <= 100000)
      fim = TimeTradeServer();
   if(fim <= 100000)
      fim = TimeLocal();
   return fim;
}

string NomeArquivoBaseHistorica(ENUM_TIMEFRAMES tf, datetime inicio, datetime fim)
{
   string prefixo = InpBaseHistoricaPrefixoArquivo;
   if(prefixo == "")
      prefixo = "AR100_BASE";
   string symbolLimpo = SanitizarNomeArquivoBase(_Symbol);
   string tfTexto     = NomeTimeframeBaseHistorica(tf);
   return StringFormat("%s_%s_%s_%s_%s.csv",
                       SanitizarNomeArquivoBase(prefixo),
                       symbolLimpo,
                       tfTexto,
                       DataArquivoBase(inicio),
                       DataArquivoBase(fim));
}

bool ExportarBaseHistoricaTF(ENUM_TIMEFRAMES tf, datetime inicio, datetime fim)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   ResetLastError();
   int lidos = CopyRates(_Symbol, tf, inicio, fim, rates);
   if(lidos <= 0)
   {
      Print("[COPA_AR100][FIX137][BASE] ERRO CopyRates | Symbol=", _Symbol,
            " | TF=", NomeTimeframeBaseHistorica(tf),
            " | Inicio=", TimeToString(inicio, TIME_DATE|TIME_SECONDS),
            " | Fim=", TimeToString(fim, TIME_DATE|TIME_SECONDS),
            " | Erro=", IntegerToString(GetLastError()));
      return false;
   }
   int maxBarras = InpBaseHistoricaMaxBarrasPorArquivo;
   if(maxBarras < 1000)
      maxBarras = 1000;
   int inicioIndice = 0;
   if(lidos > maxBarras)
      inicioIndice = lidos - maxBarras;
   string nomeArquivo = NomeArquivoBaseHistorica(tf, inicio, fim);
   int flags = FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE;
   if(InpBaseHistoricaArquivoComum)
      flags |= FILE_COMMON;
   ResetLastError();
   int h = FileOpen(nomeArquivo, flags, 59);
   if(h == INVALID_HANDLE)
   {
      Print("[COPA_AR100][FIX137][BASE] ERRO FileOpen | Arquivo=", nomeArquivo,
            " | Erro=", IntegerToString(GetLastError()));
      return false;
   }
   FileWrite(h,
             "symbol",
             "timeframe",
             "time",
             "open",
             "high",
             "low",
             "close",
             "tick_volume",
             "real_volume",
             "spread",
             "range_pts",
             "body_pts",
             "ret_close_pts",
             "direcao_candle");
   for(int i = inicioIndice; i < lidos; i++)
   {
      double rangePts = 0.0;
      double bodyPts  = 0.0;
      double retPts   = 0.0;
      int direcao     = 0;
      if(_Point > 0.0)
      {
         rangePts = (rates[i].high - rates[i].low) / _Point;
         bodyPts  = (rates[i].close - rates[i].open) / _Point;
         if(i > inicioIndice)
            retPts = (rates[i].close - rates[i - 1].close) / _Point;
      }
      if(rates[i].close > rates[i].open)
         direcao = 1;
      else if(rates[i].close < rates[i].open)
         direcao = -1;
      FileWrite(h,
                _Symbol,
                NomeTimeframeBaseHistorica(tf),
                TimeToString(rates[i].time, TIME_DATE|TIME_SECONDS),
                DoubleToString(rates[i].open, _Digits),
                DoubleToString(rates[i].high, _Digits),
                DoubleToString(rates[i].low, _Digits),
                DoubleToString(rates[i].close, _Digits),
                (long)rates[i].tick_volume,
                (long)rates[i].real_volume,
                (int)rates[i].spread,
                DoubleToString(rangePts, 1),
                DoubleToString(bodyPts, 1),
                DoubleToString(retPts, 1),
                direcao);
   }
   FileClose(h);
   Print("[COPA_AR100][FIX137][BASE] CSV gerado | Arquivo=", nomeArquivo,
         " | Pasta=", (InpBaseHistoricaArquivoComum ? "Common\\Files" : "MQL5\\Files"),
         " | Symbol=", _Symbol,
         " | TF=", NomeTimeframeBaseHistorica(tf),
         " | Barras=", IntegerToString(lidos - inicioIndice),
         " | Inicio=", TimeToString(rates[inicioIndice].time, TIME_DATE|TIME_SECONDS),
         " | Fim=", TimeToString(rates[lidos - 1].time, TIME_DATE|TIME_SECONDS));
   return true;
}

void GerarBaseHistoricaValidacao()
{
   if(!InpBaseHistoricaGerarNoInit)
      return;
   int dias = InpBaseHistoricaDias;
   if(dias < 1)
      dias = 1;
   if(dias > 370)
      dias = 370;
   datetime fim = FimBaseHistorica();
   datetime inicio = fim - (datetime)(dias * 86400);
   g_baseHistoricaSomenteExportarAtivo = InpBaseHistoricaSomenteExportar;
   Print("[COPA_AR100][FIX137][BASE] Inicio exportacao historica | Dias=", IntegerToString(dias),
         " | Inicio=", TimeToString(inicio, TIME_DATE|TIME_SECONDS),
         " | Fim=", TimeToString(fim, TIME_DATE|TIME_SECONDS),
         " | SomenteExportar=", (g_baseHistoricaSomenteExportarAtivo ? "SIM" : "NAO"));
   ExportarBaseHistoricaTF(InpBaseHistoricaTFPrincipal, inicio, fim);
   if(InpBaseHistoricaGerarM5 && InpBaseHistoricaTFPrincipal != PERIOD_M5)
      ExportarBaseHistoricaTF(PERIOD_M5, inicio, fim);
   if(InpBaseHistoricaGerarM15 && InpBaseHistoricaTFPrincipal != PERIOD_M15)
      ExportarBaseHistoricaTF(PERIOD_M15, inicio, fim);
}

#endif
