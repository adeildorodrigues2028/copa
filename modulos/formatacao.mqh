// COPA V05 - Etapa 05: formatacao de textos, arquivos e valores.
// Funcoes puras: nao acessam ordens, posicoes ou estado financeiro.
#ifndef COPA_V05_MODULOS_FORMATACAO_MQH
#define COPA_V05_MODULOS_FORMATACAO_MQH

string NomeTimeframeBaseHistorica(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return EnumToString(tf);
   }
}

string SanitizarNomeArquivoBase(string texto)
{
   string s = texto;
   StringReplace(s, "\\", "_");
   StringReplace(s, "/", "_");
   StringReplace(s, ":", "_");
   StringReplace(s, "*", "_");
   StringReplace(s, "?", "_");
   StringReplace(s, "\"", "_");
   StringReplace(s, "<", "_");
   StringReplace(s, ">", "_");
   StringReplace(s, "|", "_");
   StringReplace(s, " ", "_");
   return s;
}

string DataArquivoBase(datetime dataHora)
{
   string s = TimeToString(dataHora, TIME_DATE|TIME_MINUTES);
   StringReplace(s, ".", "");
   StringReplace(s, ":", "");
   StringReplace(s, " ", "_");
   return s;
}

string SanitizarCampoCSV(string texto)
{
   string s = texto;
   StringReplace(s, "\r", " ");
   StringReplace(s, "\n", " ");
   StringReplace(s, ";", ",");
   StringReplace(s, "\"", "'");
   return s;
}

string ValorBoolSN(bool v)
{
   return v ? "SIM" : "NAO";
}

string TextoLadoOrdem(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return "BUY";
   if(lado == LADO_VENDA)
      return "SELL";
   if(lado == LADO_AMBOS)
      return "AMBOS";
   return "NENHUM";
}

string TextoLadoCurto(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return "COMPRA";
   if(lado == LADO_VENDA)
      return "VENDA";
   if(lado == LADO_AMBOS)
      return "AMBOS";
   return "OFF";
}

string FormatarMoeda(double valor)
{
   string sinal = "";
   if(valor > 0.0)
      sinal = "+";
   return StringFormat("%sR$ %.2f", sinal, valor);
}

// ============================================================================

#endif
