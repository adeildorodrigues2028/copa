// COPA V03 - Etapa 03: utilitarios de horario e janelas compactas.
// Nao envia ordens e nao altera posicoes ou estado financeiro.
#ifndef COPA_V03_MODULOS_HORARIO_MQH
#define COPA_V03_MODULOS_HORARIO_MQH

int MinutoAtualDoDia()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return dt.hour * 60 + dt.min;
}

string FaixaHorarioCompacta(string lista, int indice)
{
   string partes[];
   int total=StringSplit(lista,';',partes);
   if(indice<0 || indice>=total)
      return "00:00-00:00";
   string faixa=Trim(partes[indice]);
   if(faixa=="")
      return "00:00-00:00";
   return faixa;
}

bool HorarioCompactoPermitidoAgora(string lista)
{
   string cfg=Upper(Trim(lista));
   if(cfg=="" || cfg=="OFF")
      return false;
   if(cfg=="ON" || cfg=="LIVRE" || cfg=="24H" || cfg=="00:00-24:00")
      return true;

   int agora=MinutoAtualDoDia();
   string partes[];
   int total=StringSplit(lista,';',partes);
   for(int i=0;i<total;i++)
   {
      int ini=0, fim=0;
      string faixa=Trim(partes[i]);
      if(!ParseHorario(faixa,ini,fim))
         continue;
      if(ini==fim)
         continue;
      if(ini<fim)
      {
         if(agora>=ini && agora<fim)
            return true;
      }
      else
      {
         if(agora>=ini || agora<fim)
            return true;
      }
   }
   return false;
}

#endif
