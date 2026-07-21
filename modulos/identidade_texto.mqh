// COPA V02 - Etapa 02: conversoes puras da identidade operacional.
// Nao acessa posicoes, ordens, painel ou estado global do robo.
#ifndef COPA_V02_MODULOS_IDENTIDADE_TEXTO_MQH
#define COPA_V02_MODULOS_IDENTIDADE_TEXTO_MQH

string Base36FIX304(long valor,int largura)
{
   string chars="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   if(valor<0) valor=-valor;
   string r="";
   do
   {
      int d=(int)(valor%36);
      r=StringSubstr(chars,d,1)+r;
      valor/=36;
   }
   while(valor>0);
   while(StringLen(r)<largura) r="0"+r;
   if(StringLen(r)>largura) r=StringSubstr(r,StringLen(r)-largura,largura);
   return r;
}

long HashTextoFIX304(string texto)
{
   long h=17;
   for(int i=0;i<StringLen(texto);i++)
      h=(h*131+(long)StringGetCharacter(texto,i))%2176782336;
   if(h<0) h=-h;
   if(h==0) h=1;
   return h;
}

string ExtrairGeracaoComentarioFIX304(string comentario)
{
   int p=StringFind(comentario,"#IG");
   if(p<0 || StringLen(comentario)<p+9) return "";
   string g=StringSubstr(comentario,p+2,7);
   if(StringLen(g)!=7 || StringSubstr(g,0,1)!="G") return "";
   return g;
}

string ExtrairCicloComentarioFIX304(string comentario)
{
   int p=StringFind(comentario,"|C");
   if(p<0 || StringLen(comentario)<p+5) return "";
   return StringSubstr(comentario,p+1,4);
}

long Base36ParaLongFIX311(string texto)
{
   string chars="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   string t=texto;
   StringToUpper(t);
   if(StringLen(t)>0 && StringSubstr(t,0,1)=="G")
      t=StringSubstr(t,1);
   long valor=0;
   for(int i=0;i<StringLen(t);i++)
   {
      int p=StringFind(chars,StringSubstr(t,i,1));
      if(p<0) return 0;
      valor=valor*36+p;
   }
   return valor;
}

#endif
