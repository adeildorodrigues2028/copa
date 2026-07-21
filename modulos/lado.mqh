// COPA V04 - Etapa 04: conversao entre texto e lado operacional.
// Nao decide entradas e nao envia ordens.
#ifndef COPA_V04_MODULOS_LADO_MQH
#define COPA_V04_MODULOS_LADO_MQH

ENUM_LADO_ROBO ParseLado(string s)
{
   s = Upper(s);
   if(s == "COMPRA")
      return LADO_COMPRA;
   if(s == "VENDA")
      return LADO_VENDA;
   if(s == "AMBOS")
      return LADO_AMBOS;
   return LADO_NENHUM;
}

string NomeLado(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return "COMPRA";
   if(lado == LADO_VENDA)
      return "VENDA";
   if(lado == LADO_AMBOS)
      return "AMBOS";
   return "NENHUM";
}

#endif
