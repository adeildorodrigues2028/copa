#ifndef COPA_INSTANCIA_OPERACIONAL_MQH
#define COPA_INSTANCIA_OPERACIONAL_MQH

// ============================================================================
// RESPONSABILIDADE: LADO, JANELA E TIMEFRAMES DA INSTANCIA
// Funcoes movidas do principal na V40 sem alteracao de regra operacional.
// ============================================================================

bool JanelaAtualEhA_FIX255()
{
   return (InpJanelaDesteGrafico == JANELA_A_COMPRA);
}

bool JanelaAtualEhB_FIX255()
{
   return (InpJanelaDesteGrafico == JANELA_B_VENDA);
}

ENUM_LADO_ROBO LadoOperacionalInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? LADO_COMPRA : LADO_VENDA;
}

long MagicOperacionalInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? MagicCompraAtual() : MagicVendaAtual();
}

bool InstanciaGerenciaLadoFIX255(ENUM_LADO_ROBO lado)
{
   // FIX288: papel imutavel por janela.
   // JANELA A gerencia somente COMPRA; JANELA B gerencia somente VENDA.
   return (lado == LadoOperacionalInstanciaFIX255());
}

bool LadoHabilitadoUsuarioFIX346(ENUM_LADO_ROBO lado)
{
   if(InpLadosHabilitadosFIX346==OPERACAO_AMBOS)
      return (lado==LADO_COMPRA || lado==LADO_VENDA);
   if(InpLadosHabilitadosFIX346==OPERACAO_COMPRA)
      return (lado==LADO_COMPRA);
   if(InpLadosHabilitadosFIX346==OPERACAO_VENDA)
      return (lado==LADO_VENDA);
   return false;
}

string TextoLadosHabilitadosFIX346()
{
   if(InpLadosHabilitadosFIX346==OPERACAO_COMPRA) return "SOMENTE COMPRA";
   if(InpLadosHabilitadosFIX346==OPERACAO_VENDA)  return "SOMENTE VENDA";
   return "COMPRA + VENDA";
}

bool InstanciaMestreGrupoFIX255()
{
   // FIX342: A continua mestre preferencial. Se o heartbeat de A desaparecer,
   // B assume imediatamente a supervisão A+B e o fechamento de emergência.
   if(JanelaAtualEhA_FIX255())
      return true;
   long chartA=0;
   datetime heartbeatA=0;
   return !RegistroJanelaAtivoFIX256(true,chartA,heartbeatA);
}

string NomeJanelaInstanciaFIX255()
{
   return JanelaAtualEhA_FIX255() ? "JANELA A | SOMENTE COMPRA" : "JANELA B | SOMENTE VENDA";
}

ENUM_TIMEFRAMES TimeframeFiltroAtualFIX255()
{
   int tf=(int)InpTimeframeFiltrosOperacionais;
   if(tf!=(int)PERIOD_M5 && tf!=(int)PERIOD_M10)
      tf=(int)PERIOD_M5;
   return (ENUM_TIMEFRAMES)tf;
}

ENUM_TIMEFRAMES TimeframeEntradaAtualFIX255()
{
   return (ENUM_TIMEFRAMES)_Period;
}


#endif // COPA_INSTANCIA_OPERACIONAL_MQH
