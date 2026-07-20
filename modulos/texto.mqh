// COPA V01 - Etapa 01: utilitarios de texto e horario.
// Esta unidade nao envia ordens e nao altera estado operacional do robo.
#ifndef COPA_V01_MODULOS_TEXTO_MQH
#define COPA_V01_MODULOS_TEXTO_MQH

string Trim(string s)
{
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
}

string Upper(string s)
{
   s = Trim(s);
   StringToUpper(s);
   return s;
}

bool IsOn(string s)
{
   s = Upper(s);
   return (s == "ON" || s == "TRUE" || s == "1" || s == "SIM");
}

double ExtrairNumero(string s)
{
   string out = "";
   int len = StringLen(s);
   for(int i = 0; i < len; i++)
   {
      ushort ch = StringGetCharacter(s, i);
      if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-')
         out += ShortToString(ch);
   }
   if(out == "" || out == "-")
      return 0.0;
   return StringToDouble(out);
}

int ExtrairInteiro(string s)
{
   return (int)ExtrairNumero(s);
}

string GetCampo(string linha, string chave, string padrao="")
{
   string partes[];
   int total = StringSplit(linha, ';', partes);
   chave = Upper(chave);
   if(chave == "")
   {
      if(total > 0)
         return Trim(partes[0]);
      return padrao;
   }
   for(int i = 0; i < total; i++)
   {
      string p = Trim(partes[i]);
      int eq = StringFind(p, "=");
      if(eq <= 0)
         continue;
      string k = Upper(StringSubstr(p, 0, eq));
      string v = Trim(StringSubstr(p, eq + 1));
      if(k == chave)
         return v;
   }
   return padrao;
}

string NormalizarLinhaAumentoHumanizada(string linha)
{
   string raw = Trim(linha);
   if(StringFind(raw, "|") < 0)
      return raw;
   string base = raw;
   string resto = "";
   int posSemi = StringFind(raw, ";");
   if(posSemi >= 0)
   {
      base = Trim(StringSubstr(raw, 0, posSemi));
      resto = StringSubstr(raw, posSemi);
   }
   string partes[];
   int total = StringSplit(base, '|', partes);
   string tokens[];
   int n = 0;
   for(int i = 0; i < total; i++)
   {
      string t = Trim(partes[i]);
      if(t == "")
         continue;
      ArrayResize(tokens, n + 1);
      tokens[n] = t;
      n++;
   }
   if(n < 5)
      return raw;
   string qtd = "1";
   string tempo = "0M";
   string gatilho = "0G";
   string dist = "0P";
   string gestao = "TRAIL=20/5";
   string ativo = "ON";
   int idx = 0;
   string primeiro = Upper(tokens[0]);
   if(primeiro == "ON" || primeiro == "OFF")
   {
      ativo = primeiro;
      idx = 1;
   }
   if(n - idx >= 5)
   {
      qtd = tokens[idx];
      tempo = tokens[idx + 1];
      gatilho = tokens[idx + 2];
      dist = tokens[idx + 3];
      gestao = tokens[idx + 4];
      if(n - idx >= 6)
      {
         string ultimo = Upper(tokens[idx + 5]);
         if(ultimo == "ON" || ultimo == "OFF")
            ativo = ultimo;
      }
   }
   string gestaoUpper = Upper(gestao);
   if(StringFind(gestaoUpper,"TRAIL") >= 0 || StringFind(gestao,"/") >= 0)
   {
      int eqTrail = StringFind(gestao,"=");
      string valorTrail = (eqTrail >= 0 ? Trim(StringSubstr(gestao,eqTrail+1)) : Trim(gestao));
      return ativo + ";QTD=" + qtd + ";TEMPO=" + tempo + ";GATILHO=" + gatilho + ";DIST=" + dist + ";TRAIL=" + valorTrail + ";PROT=0" + resto;
   }
   return ativo + ";QTD=" + qtd + ";TEMPO=" + tempo + ";GATILHO=" + gatilho + ";DIST=" + dist + ";PROT=" + gestao + resto;
}

string GetArg(string args, string chave, string padrao="")
{
   string partes[];
   int total = StringSplit(args, ',', partes);
   chave = Upper(chave);
   if(chave == "")
   {
      if(total > 0)
         return Trim(partes[0]);
      return padrao;
   }
   for(int i = 0; i < total; i++)
   {
      string p = Trim(partes[i]);
      int eq = StringFind(p, "=");
      if(eq <= 0)
         continue;
      string k = Upper(StringSubstr(p, 0, eq));
      string v = Trim(StringSubstr(p, eq + 1));
      if(k == chave)
         return v;
   }
   return padrao;
}

int HorarioParaMinutos(string hhmm)
{
   string p[];
   int n = StringSplit(hhmm, ':', p);
   if(n < 2)
      return 0;
   int h = (int)StringToInteger(p[0]);
   int m = (int)StringToInteger(p[1]);
   return h * 60 + m;
}

bool ParseHorario(string horario, int &ini, int &fim)
{
   string p[];
   int n = StringSplit(horario, '-', p);
   if(n < 2)
   {
      ini = 0;
      fim = 1439;
      return false;
   }
   ini = HorarioParaMinutos(Trim(p[0]));
   fim = HorarioParaMinutos(Trim(p[1]));
   return true;
}

#endif
