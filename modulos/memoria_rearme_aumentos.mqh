#ifndef COPA_MEMORIA_REARME_AUMENTOS_MQH
#define COPA_MEMORIA_REARME_AUMENTOS_MQH

// ============================================================================
// RESPONSABILIDADE: MEMORIA, PRECOS E REARME DOS AUMENTOS
// Funcoes movidas do principal na V42 sem alteracao de regra operacional.
// ============================================================================

double PrecoRealizacaoAumentoFIX212(long tipo, double precoEntrada, double volume, double alvoReais)
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(precoEntrada<=0.0 || volume<=0.0 || alvoReais<=0.0 || tickSize<=0.0 || tickValue<=0.0)
      return 0.0;
   double distancia=(MathAbs(alvoReais)/(tickValue*volume))*tickSize;
   if(tipo==POSITION_TYPE_BUY)
      return NormalizeDouble(precoEntrada+distancia,_Digits);
   if(tipo==POSITION_TYPE_SELL)
      return NormalizeDouble(precoEntrada-distancia,_Digits);
   return 0.0;
}

double PrecoLossAumentoFIX321(long tipo, double precoEntrada, double volume, double lossReais)
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(precoEntrada<=0.0 || volume<=0.0 || lossReais<=0.0 || tickSize<=0.0 || tickValue<=0.0)
      return 0.0;
   double distancia=(MathAbs(lossReais)/(tickValue*volume))*tickSize;
   if(tipo==POSITION_TYPE_BUY)
      return NormalizeDouble(precoEntrada-distancia,_Digits);
   if(tipo==POSITION_TYPE_SELL)
      return NormalizeDouble(precoEntrada+distancia,_Digits);
   return 0.0;
}

void SalvarAlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel, double precoAlvo)
{
   int i=nivel-1;
   if(i<0 || i>=5 || precoAlvo<=0.0)
      return;
   if(estado.lado==LADO_COMPRA)
      g_alvoLinhaAumentoBuy[i]=precoAlvo;
   else if(estado.lado==LADO_VENDA)
      g_alvoLinhaAumentoSell[i]=precoAlvo;
}

double AlvoLinhaAumentoFIX212(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return 0.0;
   if(estado.lado==LADO_COMPRA)
      return g_alvoLinhaAumentoBuy[i];
   if(estado.lado==LADO_VENDA)
      return g_alvoLinhaAumentoSell[i];
   return 0.0;
}

void MarcarAumentoRealizadoFIX212(EstadoLado &estado, int nivel, double precoRealizado)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return;
   if(estado.lado==LADO_COMPRA)
   {
      g_aumentoRealizadoBuy[i]=true;
      if(precoRealizado>0.0)
         g_precoRealizadoAumentoBuy[i]=precoRealizado;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_aumentoRealizadoSell[i]=true;
      if(precoRealizado>0.0)
         g_precoRealizadoAumentoSell[i]=precoRealizado;
   }
}

bool AumentoRealizadoFIX212(EstadoLado &estado, int nivel, double &precoRealizado)
{
   precoRealizado=0.0;
   int i=nivel-1;
   if(i<0 || i>=5)
      return false;
   if(estado.lado==LADO_COMPRA)
   {
      precoRealizado=g_precoRealizadoAumentoBuy[i];
      return g_aumentoRealizadoBuy[i];
   }
   if(estado.lado==LADO_VENDA)
   {
      precoRealizado=g_precoRealizadoAumentoSell[i];
      return g_aumentoRealizadoSell[i];
   }
   return false;
}

void ResetarRastreamentoAumentosFIX212(EstadoLado &estado)
{
   if(estado.nome!="MOTOR_COMPRA" && estado.nome!="MOTOR_VENDA")
      return;
   for(int i=0; i<5; i++)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_precosAumentosRestauradosBuy=false;
         g_alvoLinhaAumentoBuy[i]=0.0;
         g_precoRealizadoAumentoBuy[i]=0.0;
         g_precoEntradaAumentoBuy[i]=0.0;
         g_audPrecoProgramadoAumentoBuyFIX358[i]=0.0;
         g_audPrecoExecutadoAumentoBuyFIX358[i]=0.0;
         g_aumentoRealizadoBuy[i]=false;
         g_candleToqueAumentoBuyFIX224[i]=0;
         g_linhaCandleAumentoBuyFIX224[i]=0.0;
         g_candleAumentoConfirmadoBuyFIX224[i]=false;
         g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
         g_horaGatilhoRompimentoBuyFIX337[i]=0;
         ResetarTrailAumentoFIX281(g_trailAumentoBuy[i]);
      }
      else if(estado.lado==LADO_VENDA)
      {
         g_precosAumentosRestauradosSell=false;
         g_alvoLinhaAumentoSell[i]=0.0;
         g_precoRealizadoAumentoSell[i]=0.0;
         g_precoEntradaAumentoSell[i]=0.0;
         g_audPrecoProgramadoAumentoSellFIX358[i]=0.0;
         g_audPrecoExecutadoAumentoSellFIX358[i]=0.0;
         g_aumentoRealizadoSell[i]=false;
         g_candleToqueAumentoSellFIX224[i]=0;
         g_linhaCandleAumentoSellFIX224[i]=0.0;
         g_candleAumentoConfirmadoSellFIX224[i]=false;
         g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
         g_horaGatilhoRompimentoSellFIX337[i]=0;
         ResetarTrailAumentoFIX281(g_trailAumentoSell[i]);
      }
   }
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=0.0;
      g_cicloRearmeA1BuyFIX225=0;
      g_nivelInicioRearmeBuyFIX248=0;
      g_rearmeParcialPendenteBuyFIX248=false;
      g_nivelParcialPendenteBuyFIX248=0;
      g_volumeParcialPendenteBuyFIX248=0.0;
      g_horaParcialPendenteBuyFIX248=0;
      for(int r=0;r<5;r++) g_aguardaRetornoLinhaBuyFIX248[r]=false;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=0.0;
      g_cicloRearmeA1SellFIX225=0;
      g_nivelInicioRearmeSellFIX248=0;
      g_rearmeParcialPendenteSellFIX248=false;
      g_nivelParcialPendenteSellFIX248=0;
      g_volumeParcialPendenteSellFIX248=0.0;
      g_horaParcialPendenteSellFIX248=0;
      for(int r=0;r<5;r++) g_aguardaRetornoLinhaSellFIX248[r]=false;
   }
   string chaveAncora=ChaveAncoraRearmeA1FIX225(estado);
   string chaveCiclo=ChaveCicloRearmeA1FIX225(estado);
   string chaveNivel=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chaveAncora)) GlobalVariableDel(chaveAncora);
   if(GlobalVariableCheck(chaveCiclo)) GlobalVariableDel(chaveCiclo);
   if(GlobalVariableCheck(chaveNivel)) GlobalVariableDel(chaveNivel);
   LimparRearmePendenteFIX251(estado);
}

string NomeBasePrecoAumentoFIX220()
{
   if(InpBasePrecoAumento==BASE_ULTIMO_AUMENTO)
      return "0 ULTIMO AUMENTO";
   if(InpBasePrecoAumento==BASE_ENTRADA_INICIAL)
      return "1 ENTRADA A0";
   return "2 PRECO MEDIO PROTEGIDO";
}

string ChaveAncoraRearmeA1FIX225(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX225_ANCORA_REARME_A1";
}

string ChaveCicloRearmeA1FIX225(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX225_CICLO_REARME_A1";
}

double AncoraRearmeA1FIX225(EstadoLado &estado)
{
   double preco=(estado.lado==LADO_COMPRA ? g_ancoraRearmeA1BuyFIX225 : g_ancoraRearmeA1SellFIX225);
   if(preco>0.0)
      return preco;
   string chave=ChaveAncoraRearmeA1FIX225(estado);
   if(GlobalVariableCheck(chave))
   {
      preco=GlobalVariableGet(chave);
      if(preco>0.0)
      {
         if(estado.lado==LADO_COMPRA) g_ancoraRearmeA1BuyFIX225=preco;
         else if(estado.lado==LADO_VENDA) g_ancoraRearmeA1SellFIX225=preco;
      }
   }
   return preco;
}

int CicloRearmeA1FIX225(EstadoLado &estado)
{
   int ciclo=(estado.lado==LADO_COMPRA ? g_cicloRearmeA1BuyFIX225 : g_cicloRearmeA1SellFIX225);
   if(ciclo>0)
      return ciclo;
   string chave=ChaveCicloRearmeA1FIX225(estado);
   if(GlobalVariableCheck(chave))
   {
      ciclo=(int)GlobalVariableGet(chave);
      if(estado.lado==LADO_COMPRA) g_cicloRearmeA1BuyFIX225=ciclo;
      else if(estado.lado==LADO_VENDA) g_cicloRearmeA1SellFIX225=ciclo;
   }
   return ciclo;
}

string ChaveNivelInicioRearmeFIX248(EstadoLado &estado)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX248_NIVEL_INICIO_REARME";
}

int NivelInicioRearmeFIX248(EstadoLado &estado)
{
   int nivel=(estado.lado==LADO_COMPRA ? g_nivelInicioRearmeBuyFIX248 : g_nivelInicioRearmeSellFIX248);
   if(nivel>0)
      return nivel;
   string chave=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chave))
   {
      nivel=(int)GlobalVariableGet(chave);
      if(estado.lado==LADO_COMPRA) g_nivelInicioRearmeBuyFIX248=nivel;
      else if(estado.lado==LADO_VENDA) g_nivelInicioRearmeSellFIX248=nivel;
   }
   return nivel;
}

void SalvarContextoRearmeFIX248(EstadoLado &estado, double precoMedio, int nivelInicio)
{
   if(precoMedio<=0.0 || nivelInicio<1 || nivelInicio>5)
      return;
   SalvarAncoraRearmeA1FIX225(estado,precoMedio);
   if(estado.lado==LADO_COMPRA) g_nivelInicioRearmeBuyFIX248=nivelInicio;
   else if(estado.lado==LADO_VENDA) g_nivelInicioRearmeSellFIX248=nivelInicio;
   GlobalVariableSet(ChaveNivelInicioRearmeFIX248(estado),(double)nivelInicio);
}

void LimparContextoRearmeFIX248(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=0.0;
      g_nivelInicioRearmeBuyFIX248=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=0.0;
      g_nivelInicioRearmeSellFIX248=0;
   }
   string chaveAncora=ChaveAncoraRearmeA1FIX225(estado);
   string chaveNivel=ChaveNivelInicioRearmeFIX248(estado);
   if(GlobalVariableCheck(chaveAncora)) GlobalVariableDel(chaveAncora);
   if(GlobalVariableCheck(chaveNivel)) GlobalVariableDel(chaveNivel);
}

string ChaveRearmePendenteFIX251(EstadoLado &estado, string campo)
{
   return PrefixoLockCicloMagic(estado.magic)+"FIX251_REARME_PEND_"+campo;
}

void PersistirRearmePendenteFIX251(EstadoLado &estado)
{
   bool pendente=(estado.lado==LADO_COMPRA ? g_rearmeParcialPendenteBuyFIX248 : g_rearmeParcialPendenteSellFIX248);
   int nivel=(estado.lado==LADO_COMPRA ? g_nivelParcialPendenteBuyFIX248 : g_nivelParcialPendenteSellFIX248);
   double volume=(estado.lado==LADO_COMPRA ? g_volumeParcialPendenteBuyFIX248 : g_volumeParcialPendenteSellFIX248);
   datetime hora=(estado.lado==LADO_COMPRA ? g_horaParcialPendenteBuyFIX248 : g_horaParcialPendenteSellFIX248);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"PEND"),pendente ? 1.0 : 0.0);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"NIVEL"),(double)nivel);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"VOL"),volume);
   GlobalVariableSet(ChaveRearmePendenteFIX251(estado,"HORA"),(double)hora);
}

void RestaurarRearmePendenteFIX251(EstadoLado &estado)
{
   string chavePend=ChaveRearmePendenteFIX251(estado,"PEND");
   if(!GlobalVariableCheck(chavePend) || GlobalVariableGet(chavePend)<=0.0)
      return;
   int nivel=(int)GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"NIVEL"));
   double volume=GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"VOL"));
   datetime hora=(datetime)GlobalVariableGet(ChaveRearmePendenteFIX251(estado,"HORA"));
   if(nivel<1) nivel=1;
   if(hora<=0) hora=TimeCurrent();
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeParcialPendenteBuyFIX248=true;
      g_nivelParcialPendenteBuyFIX248=nivel;
      g_volumeParcialPendenteBuyFIX248=MathAbs(volume);
      g_horaParcialPendenteBuyFIX248=hora;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeParcialPendenteSellFIX248=true;
      g_nivelParcialPendenteSellFIX248=nivel;
      g_volumeParcialPendenteSellFIX248=MathAbs(volume);
      g_horaParcialPendenteSellFIX248=hora;
   }
}

void LimparRearmePendenteFIX251(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeParcialPendenteBuyFIX248=false;
      g_nivelParcialPendenteBuyFIX248=0;
      g_volumeParcialPendenteBuyFIX248=0.0;
      g_horaParcialPendenteBuyFIX248=0;
      g_rearmeSnapshotVolumeBuyFIX251=-1.0;
      g_rearmeSnapshotMediaBuyFIX251=0.0;
      g_rearmeSnapshotHoraBuyFIX251=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeParcialPendenteSellFIX248=false;
      g_nivelParcialPendenteSellFIX248=0;
      g_volumeParcialPendenteSellFIX248=0.0;
      g_horaParcialPendenteSellFIX248=0;
      g_rearmeSnapshotVolumeSellFIX251=-1.0;
      g_rearmeSnapshotMediaSellFIX251=0.0;
      g_rearmeSnapshotHoraSellFIX251=0;
   }
   string campos[4]={"PEND","NIVEL","VOL","HORA"};
   for(int i=0;i<4;i++)
   {
      string chave=ChaveRearmePendenteFIX251(estado,campos[i]);
      if(GlobalVariableCheck(chave)) GlobalVariableDel(chave);
   }
}

bool RearmeParcialPendenteFIX248(EstadoLado &estado)
{
   RestaurarRearmePendenteFIX251(estado);
   if(estado.lado==LADO_COMPRA) return g_rearmeParcialPendenteBuyFIX248;
   if(estado.lado==LADO_VENDA) return g_rearmeParcialPendenteSellFIX248;
   return false;
}

void AgendarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido)
{
   if(nivelRealizado<1) nivelRealizado=1;
   if(nivelRealizado>5) nivelRealizado=5;
   int indiceNivelFIX453=nivelRealizado-1;
   if(estado.lado==LADO_COMPRA)
   {
      g_horaRearmeNivelBuyFIX453[indiceNivelFIX453]=TimeCurrent();
      g_rearmeParcialPendenteBuyFIX248=true;
      g_nivelParcialPendenteBuyFIX248=MathMax(g_nivelParcialPendenteBuyFIX248,nivelRealizado);
      g_volumeParcialPendenteBuyFIX248+=MathAbs(volumeRemovido);
      g_horaParcialPendenteBuyFIX248=TimeCurrent();
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_horaRearmeNivelSellFIX453[indiceNivelFIX453]=TimeCurrent();
      g_rearmeParcialPendenteSellFIX248=true;
      g_nivelParcialPendenteSellFIX248=MathMax(g_nivelParcialPendenteSellFIX248,nivelRealizado);
      g_volumeParcialPendenteSellFIX248+=MathAbs(volumeRemovido);
      g_horaParcialPendenteSellFIX248=TimeCurrent();
   }
   if(estado.lado==LADO_COMPRA)
   {
      g_rearmeSnapshotVolumeBuyFIX251=-1.0;
      g_rearmeSnapshotMediaBuyFIX251=0.0;
      g_rearmeSnapshotHoraBuyFIX251=0;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_rearmeSnapshotVolumeSellFIX251=-1.0;
      g_rearmeSnapshotMediaSellFIX251=0.0;
      g_rearmeSnapshotHoraSellFIX251=0;
   }
   PersistirRearmePendenteFIX251(estado);
   estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL CONFIRMADA | aguarda duas leituras estaveis de volume e preco medio para rearmar.",nivelRealizado);
   estado.ultimaMensagem=estado.motivoBloqueioAumento;
   RegistrarLogValidacaoSistema("FIX251_REARME_AGENDADO_SEGURO",estado.motivoBloqueioAumento);
}

int PrimeiroNivelRearmavelFIX248(EstadoLado &estado, int nivelRealizado)
{
   // FIX450: rearme verdadeiramente individual. O mesmo nível que realizou
   // volta a ficar disponível, independentemente de níveis superiores abertos.
   if(nivelRealizado<1 || nivelRealizado>g_gerAumentos.maxAumentos || nivelRealizado>ArraySize(g_aumentos))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d fora do limite configurado para rearme.",nivelRealizado);
      return 0;
   }
   if(!g_aumentos[nivelRealizado-1].ativa)
   {
      estado.motivoBloqueioAumento=StringFormat("A%d está desativado; sem rearme.",nivelRealizado);
      return 0;
   }

   ulong ticket=0;
   double preco=0.0,volume=0.0;
   long tipo=-1;
   if(ObterPosicaoAumentoNivelFIX212(estado,nivelRealizado,ticket,preco,volume,tipo))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d ainda possui ticket %I64u com %.2f contrato(s); rearme aguarda fechamento integral.",
                                                nivelRealizado,ticket,volume);
      return 0;
   }
   return nivelRealizado;
}

void LimparMemoriaNiveisAPartirFIX248(EstadoLado &estado, int nivelInicial)
{
   if(nivelInicial<1) nivelInicial=1;
   if(nivelInicial>5) return;
   for(int nivel=nivelInicial;nivel<=5;nivel++)
   {
      int i=nivel-1;
      LiberarLockCiclo(ChaveLockAumento(estado,nivel));
      LiberarLockCiclo(ChaveLockAumentoConfirmadoFIX208(estado,nivel));
      string chavePreco=ChavePrecoEntradaAumentoFIX220(estado,nivel);
      if(GlobalVariableCheck(chavePreco)) GlobalVariableDel(chavePreco);
      if(estado.lado==LADO_COMPRA)
      {
         g_alvoLinhaAumentoBuy[i]=0.0;
         g_precoRealizadoAumentoBuy[i]=0.0;
         g_precoEntradaAumentoBuy[i]=0.0;
         g_aumentoRealizadoBuy[i]=false;
         g_candleToqueAumentoBuyFIX224[i]=0;
         g_linhaCandleAumentoBuyFIX224[i]=0.0;
         g_candleAumentoConfirmadoBuyFIX224[i]=false;
         g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
         g_horaGatilhoRompimentoBuyFIX337[i]=0;
         g_aguardaRetornoLinhaBuyFIX248[i]=false;
      }
      else if(estado.lado==LADO_VENDA)
      {
         g_alvoLinhaAumentoSell[i]=0.0;
         g_precoRealizadoAumentoSell[i]=0.0;
         g_precoEntradaAumentoSell[i]=0.0;
         g_aumentoRealizadoSell[i]=false;
         g_candleToqueAumentoSellFIX224[i]=0;
         g_linhaCandleAumentoSellFIX224[i]=0.0;
         g_candleAumentoConfirmadoSellFIX224[i]=false;
         g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
         g_horaGatilhoRompimentoSellFIX337[i]=0;
         g_aguardaRetornoLinhaSellFIX248[i]=false;
      }
   }
   if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
   else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
   estado.ultimoNivelAumentoUsado=nivelInicial-1;
   estado.aumentosExecutados=nivelInicial-1;
}

void LimparMemoriaSomenteNivelFIX450(EstadoLado &estado,int nivel)
{
   if(nivel<1 || nivel>5) return;
   int i=nivel-1;
   LiberarLockCiclo(ChaveLockAumento(estado,nivel));
   LiberarLockCiclo(ChaveLockAumentoConfirmadoFIX208(estado,nivel));
   string chavePreco=ChavePrecoEntradaAumentoFIX220(estado,nivel);
   if(GlobalVariableCheck(chavePreco)) GlobalVariableDel(chavePreco);

   if(estado.lado==LADO_COMPRA)
   {
      g_alvoLinhaAumentoBuy[i]=0.0;
      g_precoRealizadoAumentoBuy[i]=0.0;
      g_precoEntradaAumentoBuy[i]=0.0;
      g_aumentoRealizadoBuy[i]=false;
      g_candleToqueAumentoBuyFIX224[i]=0;
      g_linhaCandleAumentoBuyFIX224[i]=0.0;
      g_candleAumentoConfirmadoBuyFIX224[i]=false;
      g_gatilhoRompimentoAumentoBuyFIX337[i]=0.0;
      g_horaGatilhoRompimentoBuyFIX337[i]=0;
      g_aguardaRetornoLinhaBuyFIX248[i]=false;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_alvoLinhaAumentoSell[i]=0.0;
      g_precoRealizadoAumentoSell[i]=0.0;
      g_precoEntradaAumentoSell[i]=0.0;
      g_aumentoRealizadoSell[i]=false;
      g_candleToqueAumentoSellFIX224[i]=0;
      g_linhaCandleAumentoSellFIX224[i]=0.0;
      g_candleAumentoConfirmadoSellFIX224[i]=false;
      g_gatilhoRompimentoAumentoSellFIX337[i]=0.0;
      g_horaGatilhoRompimentoSellFIX337[i]=0;
      g_aguardaRetornoLinhaSellFIX248[i]=false;
   }

   // Faz o sequenciador apontar novamente para o mesmo nível, sem limpar os demais.
   estado.ultimoNivelAumentoUsado=nivel-1;
   estado.aumentosExecutados=nivel-1;
}

bool PrecoNoLadoGatilhoAumentoFIX248(EstadoLado &estado, double linha)
{
   if(linha<=0.0) return false;
   double precoExecucao=(estado.lado==LADO_COMPRA) ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(precoExecucao<=0.0) return false;
   if(estado.lado==LADO_COMPRA)
      return InpAumentosContraPosicao ? (precoExecucao<=linha) : (precoExecucao>=linha);
   if(estado.lado==LADO_VENDA)
      return InpAumentosContraPosicao ? (precoExecucao>=linha) : (precoExecucao<=linha);
   return false;
}

double PrecoExecutavelAumentoFIX363(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
      return SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(estado.lado==LADO_VENDA)
      return SymbolInfoDouble(_Symbol,SYMBOL_BID);
   return 0.0;
}

bool PrecoAumentoNaLinhaOuMelhorFIX363(EstadoLado &estado,double linha,string &status)
{
   status="";
   if(linha<=0.0)
   {
      status="LINHA PROGRAMADA INVALIDA";
      return false;
   }
   double preco=PrecoExecutavelAumentoFIX363(estado);
   if(preco<=0.0)
   {
      status="SEM PRECO EXECUTAVEL";
      return false;
   }

   bool correto=false;
   if(estado.lado==LADO_COMPRA)
      correto=InpAumentosContraPosicao ? (preco<=linha) : (preco>=linha);
   else if(estado.lado==LADO_VENDA)
      correto=InpAumentosContraPosicao ? (preco>=linha) : (preco<=linha);

   if(!correto)
   {
      status=StringFormat("PRECO PIOR QUE A LINHA | PROG %.0f | EXEC %.0f | AGUARDA NOVO TOQUE+CANDLE",linha,preco);
      return false;
   }
   status=StringFormat("PRECO MELHOR OK | PROG %.0f | EXEC %.0f",linha,preco);
   return true;
}

bool ValidarAumentoFinalAntesEnvioFIX363(EstadoLado &estado,int indiceZero,double linhaProgramada,string &status)
{
   status="";
   if(indiceZero<0 || indiceZero>=ArraySize(g_aumentos))
   {
      status="NIVEL INVALIDO";
      return false;
   }
   if(!InpAumentoConfirmarFechamentoCandle || !CandleAumentoConfirmadoFIX224(estado,indiceZero))
   {
      status=StringFormat("A%d SEM CANDLE M1 CONFIRMADO",indiceZero+1);
      return false;
   }

   double linhaAtual=PrecoNivelAumentoValorIndice(estado,indiceZero);
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0.0) tickSize=_Point;
   if(linhaAtual<=0.0 || MathAbs(linhaAtual-linhaProgramada)>tickSize*0.5)
   {
      status=StringFormat("A%d LINHA MUDOU | ARMADA %.0f | ATUAL %.0f | NOVA CONFIRMACAO",indiceZero+1,linhaProgramada,linhaAtual);
      LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
      return false;
   }

   if(!PrecoAumentoNaLinhaOuMelhorFIX363(estado,linhaProgramada,status))
   {
      LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
      return false;
   }
   return true;
}

void PrepararNovoCruzamentoNivelFIX248(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5 || i>=ArraySize(g_aumentos) || !g_aumentos[i].ativa)
      return;
   double linha=PrecoNivelAumentoValorIndice(estado,i);
   bool aguarda=(linha>0.0 && PrecoNoLadoGatilhoAumentoFIX248(estado,linha));
   if(estado.lado==LADO_COMPRA) g_aguardaRetornoLinhaBuyFIX248[i]=aguarda;
   else if(estado.lado==LADO_VENDA) g_aguardaRetornoLinhaSellFIX248[i]=aguarda;
   LimparConfirmacaoCandleAumentoFIX224(estado,i);
}

bool NovoCruzamentoLiberadoFIX248(EstadoLado &estado, int nivel, double linha, string &status)
{
   status="";
   int i=nivel-1;
   if(i<0 || i>=5) return false;
   bool aguarda=(estado.lado==LADO_COMPRA ? g_aguardaRetornoLinhaBuyFIX248[i] : g_aguardaRetornoLinhaSellFIX248[i]);
   if(!aguarda) return true;
   if(PrecoNoLadoGatilhoAumentoFIX248(estado,linha))
   {
      status=StringFormat("A%d NOVA LINHA %.0f | aguarda preco voltar e cruzar novamente",nivel,linha);
      return false;
   }
   if(estado.lado==LADO_COMPRA) g_aguardaRetornoLinhaBuyFIX248[i]=false;
   else if(estado.lado==LADO_VENDA) g_aguardaRetornoLinhaSellFIX248[i]=false;
   LimparConfirmacaoCandleAumentoFIX224(estado,i);
   status=StringFormat("A%d RETORNO CONFIRMADO | novo cruzamento liberado",nivel);
   RegistrarLogValidacaoSistema("FIX248_NOVO_CRUZAMENTO_ARMADO",status);
   return false;
}

bool AplicarRearmeDinamicoAposParcialFIX248(EstadoLado &estado, int nivelRealizado, double volumeRemovido)
{
   AtualizarEstadoLado(estado);
   if(!estado.posicaoAberta || estado.precoMedio<=0.0)
   {
      LimparContextoRearmeFIX248(estado);
      estado.motivoBloqueioAumento="Parcial confirmou encerramento da ponta; sem rearme.";
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      return false;
   }
   int nivelInicio=PrimeiroNivelRearmavelFIX248(estado,nivelRealizado);
   if(nivelInicio<=0)
   {
      if(estado.motivoBloqueioAumento=="")
         estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL OK | %.2f contratos | nenhum nivel integral livre dentro do limite.",nivelRealizado,estado.contratos);
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      RegistrarLogValidacaoSistema("FIX248_SEM_NIVEL_REARMAVEL",estado.motivoBloqueioAumento);
      return false;
   }
   double novaMedia=estado.precoMedio;
   RestaurarPrecosEntradaAumentosFIX220(estado);
   int nivelAncora=0;
   double ancoraUltimoAumento=UltimoPrecoAumentoAntesFIX220(estado,5,nivelAncora);
   if(ancoraUltimoAumento<=0.0)
      ancoraUltimoAumento=novaMedia;
   // A média atual serve para gain/loss e painel. A distância do novo aumento
   // parte do último aumento realmente executado deste mesmo Magic/lado.
   SalvarContextoRearmeFIX248(estado,ancoraUltimoAumento,nivelInicio);
   // FIX450: limpa somente o nível realizado; tickets e memórias dos outros níveis permanecem.
   LimparMemoriaSomenteNivelFIX450(estado,nivelInicio);
   estado.horarioUltimoAumento=TimeCurrent();
   double novaLinha=PrecoNivelAumentoValorIndice(estado,nivelInicio-1);
   PrepararNovoCruzamentoNivelFIX248(estado,nivelInicio);
   int minutos=MathMax(0,g_aumentos[nivelInicio-1].tempoMinutos);
   int ciclo=CicloRearmeA1FIX225(estado);
   estado.motivoBloqueioAumento=StringFormat("A%d PARCIAL OK %.2f CT | REARME MESMO NIVEL A%d | MEDIA %.0f | ANCORA A%d %.0f | CICLO #%d | LINHA %.0f | TIMER %dM | OUTROS NIVEIS PRESERVADOS.",
                                             nivelRealizado,MathAbs(volumeRemovido),nivelInicio,novaMedia,nivelAncora,ancoraUltimoAumento,ciclo,novaLinha,minutos);
   estado.ultimaMensagem=estado.motivoBloqueioAumento;
   RegistrarLogValidacaoSistema("FIX248_REARME_DINAMICO_OK",estado.motivoBloqueioAumento);
   g_ultimaAtualizacaoPainelVisual=0;
   return true;
}

bool RecuperarRearmeSemEventoFIX452(EstadoLado &estado)
{
   // Recupera parcial/rearme quando o EA foi recompilado ou recolocado depois
   // do deal. A marcação e o acumulado são reconstruídos do histórico do ciclo.
   AtualizarEstadoLado(estado);
   if(!estado.posicaoAberta)
      return false;
   if(RearmeParcialPendenteFIX248(estado) || NivelInicioRearmeFIX248(estado)>0)
      return false;

   for(int nivel=1;nivel<=g_gerAumentos.maxAumentos && nivel<=ArraySize(g_aumentos);nivel++)
   {
      if(!g_aumentos[nivel-1].ativa)
         continue;

      ulong ticket=0;
      double preco=0.0,volumeAberto=0.0;
      long tipo=-1;
      if(ObterPosicaoAumentoNivelFIX212(estado,nivel,ticket,preco,volumeAberto,tipo))
         continue;

      double precoRealizado=0.0;
      if(!AumentoRealizadoFIX212(estado,nivel,precoRealizado))
         continue;

      double acumulado=(estado.lado==LADO_COMPRA
                        ? g_realizadoAumentosNivelBuyFIX324[nivel-1]
                        : g_realizadoAumentosNivelSellFIX324[nivel-1]);
      int qtdReal=(estado.lado==LADO_COMPRA
                   ? g_qtdRealizacoesNivelBuyFIX324[nivel-1]
                   : g_qtdRealizacoesNivelSellFIX324[nivel-1]);
      if(qtdReal<=0 && MathAbs(acumulado)<0.005)
         continue;

      double volumeReal=(estado.lado==LADO_COMPRA
                         ? g_volumeRealizadoNivelBuyFIX324[nivel-1]
                         : g_volumeRealizadoNivelSellFIX324[nivel-1]);
      if(volumeReal<=0.0)
         volumeReal=MathMax(1.0,g_aumentos[nivel-1].qtd);

      AgendarRearmeDinamicoAposParcialFIX248(estado,nivel,volumeReal);
      RegistrarLogValidacaoSistema(
         "FIX452_REARME_RECUPERADO_APOS_REINICIO",
         StringFormat("A%d sem ticket | acumulado %s | %d realizacao(oes) | rearme recuperado.",
                      nivel,PnlMoedaBRL(acumulado),qtdReal));
      return true; // Um contexto por vez; os demais serão recuperados depois.
   }
   return false;
}

bool ProcessarRearmeDinamicoPendenteFIX248(EstadoLado &estado)
{
   if(!RearmeParcialPendenteFIX248(estado))
      return false;

   AtualizarEstadoLado(estado);
   datetime agora=TimeCurrent();
   datetime horaPendente=(estado.lado==LADO_COMPRA ? g_horaParcialPendenteBuyFIX248 : g_horaParcialPendenteSellFIX248);
   if(horaPendente>0 && (agora-horaPendente)<2)
   {
      estado.motivoBloqueioAumento="Parcial confirmada: aguardando estabilizacao inicial do servidor.";
      return false;
   }

   double volumeAtual=(estado.posicaoAberta ? MathAbs(estado.contratos) : 0.0);
   double mediaAtual=(estado.posicaoAberta ? estado.precoMedio : 0.0);
   double snapshotVolume=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotVolumeBuyFIX251 : g_rearmeSnapshotVolumeSellFIX251);
   double snapshotMedia=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotMediaBuyFIX251 : g_rearmeSnapshotMediaSellFIX251);
   datetime snapshotHora=(estado.lado==LADO_COMPRA ? g_rearmeSnapshotHoraBuyFIX251 : g_rearmeSnapshotHoraSellFIX251);

   if(snapshotHora<=0)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_rearmeSnapshotVolumeBuyFIX251=volumeAtual;
         g_rearmeSnapshotMediaBuyFIX251=mediaAtual;
         g_rearmeSnapshotHoraBuyFIX251=agora;
      }
      else
      {
         g_rearmeSnapshotVolumeSellFIX251=volumeAtual;
         g_rearmeSnapshotMediaSellFIX251=mediaAtual;
         g_rearmeSnapshotHoraSellFIX251=agora;
      }
      estado.motivoBloqueioAumento=StringFormat("Parcial confirmada: primeira leitura servidor %.2f CT | MEDIA %.0f; aguardando confirmacao.",volumeAtual,mediaAtual);
      return false;
   }
   if((agora-snapshotHora)<1)
      return false;

   bool volumeEstavel=(MathAbs(volumeAtual-snapshotVolume)<=0.0001);
   double toleranciaMedia=MathMax(_Point,0.0000001);
   bool mediaEstavel=(MathAbs(mediaAtual-snapshotMedia)<=toleranciaMedia);
   if(!volumeEstavel || !mediaEstavel)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_rearmeSnapshotVolumeBuyFIX251=volumeAtual;
         g_rearmeSnapshotMediaBuyFIX251=mediaAtual;
         g_rearmeSnapshotHoraBuyFIX251=agora;
      }
      else
      {
         g_rearmeSnapshotVolumeSellFIX251=volumeAtual;
         g_rearmeSnapshotMediaSellFIX251=mediaAtual;
         g_rearmeSnapshotHoraSellFIX251=agora;
      }
      estado.motivoBloqueioAumento=StringFormat("Servidor ainda atualizando: %.2f CT | MEDIA %.0f; nova verificacao antes do rearme.",volumeAtual,mediaAtual);
      RegistrarLogValidacaoSistema("FIX251_REARME_AGUARDA_ESTABILIDADE",estado.motivoBloqueioAumento);
      return false;
   }

   int nivel=(estado.lado==LADO_COMPRA ? g_nivelParcialPendenteBuyFIX248 : g_nivelParcialPendenteSellFIX248);
   double volume=(estado.lado==LADO_COMPRA ? g_volumeParcialPendenteBuyFIX248 : g_volumeParcialPendenteSellFIX248);
   bool aplicado=AplicarRearmeDinamicoAposParcialFIX248(estado,nivel,volume);
   LimparRearmePendenteFIX251(estado);
   return aplicado;
}

void SalvarAncoraRearmeA1FIX225(EstadoLado &estado, double preco)
{
   if(preco<=0.0)
      return;
   preco=NormalizeDouble(preco,_Digits);
   int ciclo=CicloRearmeA1FIX225(estado)+1;
   if(estado.lado==LADO_COMPRA)
   {
      g_ancoraRearmeA1BuyFIX225=preco;
      g_cicloRearmeA1BuyFIX225=ciclo;
   }
   else if(estado.lado==LADO_VENDA)
   {
      g_ancoraRearmeA1SellFIX225=preco;
      g_cicloRearmeA1SellFIX225=ciclo;
   }
   GlobalVariableSet(ChaveAncoraRearmeA1FIX225(estado),preco);
   GlobalVariableSet(ChaveCicloRearmeA1FIX225(estado),(double)ciclo);
}

bool EscadaA1RearmadaFIX225(EstadoLado &estado)
{
   return (InpRearmarA1AposParcialFIX225 && AncoraRearmeA1FIX225(estado)>0.0 && NivelInicioRearmeFIX248(estado)>0);
}



string ChavePrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel)
{
   return PrefixoLockCicloMagic(estado.magic)+"PENT_A"+IntegerToString(nivel);
}

void SalvarPrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel, double preco)
{
   int i=nivel-1;
   if(i<0 || i>=5 || preco<=0.0)
      return;
   preco=NormalizeDouble(preco,_Digits);
   if(estado.lado==LADO_COMPRA)
      g_precoEntradaAumentoBuy[i]=preco;
   else if(estado.lado==LADO_VENDA)
      g_precoEntradaAumentoSell[i]=preco;
   GlobalVariableSet(ChavePrecoEntradaAumentoFIX220(estado,nivel),preco);
}

double PrecoEntradaAumentoFIX220(EstadoLado &estado, int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return 0.0;
   double preco=(estado.lado==LADO_COMPRA ? g_precoEntradaAumentoBuy[i] : g_precoEntradaAumentoSell[i]);
   if(preco>0.0)
      return preco;
   string chave=ChavePrecoEntradaAumentoFIX220(estado,nivel);
   if(GlobalVariableCheck(chave))
   {
      preco=GlobalVariableGet(chave);
      if(preco>0.0)
      {
         if(estado.lado==LADO_COMPRA)
            g_precoEntradaAumentoBuy[i]=preco;
         else if(estado.lado==LADO_VENDA)
            g_precoEntradaAumentoSell[i]=preco;
      }
   }
   return preco;
}

void RegistrarAuditoriaVisualAumentoFIX358(EstadoLado &estado,int nivel,double programado,double executado)
{
   int i=nivel-1;
   if(i<0 || i>=5)
      return;
   if(programado>0.0) programado=NormalizeDouble(programado,_Digits);
   if(executado>0.0) executado=NormalizeDouble(executado,_Digits);
   if(estado.lado==LADO_COMPRA)
   {
      if(programado>0.0) g_audPrecoProgramadoAumentoBuyFIX358[i]=programado;
      if(executado>0.0) g_audPrecoExecutadoAumentoBuyFIX358[i]=executado;
   }
   else if(estado.lado==LADO_VENDA)
   {
      if(programado>0.0) g_audPrecoProgramadoAumentoSellFIX358[i]=programado;
      if(executado>0.0) g_audPrecoExecutadoAumentoSellFIX358[i]=executado;
   }
}

double PrecoProgramadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5) return 0.0;
   return (estado.lado==LADO_COMPRA ? g_audPrecoProgramadoAumentoBuyFIX358[i] : g_audPrecoProgramadoAumentoSellFIX358[i]);
}

double PrecoExecutadoAuditoriaAumentoFIX358(EstadoLado &estado,int nivel)
{
   int i=nivel-1;
   if(i<0 || i>=5) return 0.0;
   return (estado.lado==LADO_COMPRA ? g_audPrecoExecutadoAumentoBuyFIX358[i] : g_audPrecoExecutadoAumentoSellFIX358[i]);
}

void RestaurarPrecosEntradaAumentosFIX220(EstadoLado &estado)
{
   for(int nivel=1;nivel<=5;nivel++)
      PrecoEntradaAumentoFIX220(estado,nivel);
   bool jaRestaurado=(estado.lado==LADO_COMPRA ? g_precosAumentosRestauradosBuy : g_precosAumentosRestauradosSell);
   if(jaRestaurado)
      return;

   // Recupera uma unica vez de posicoes abertas quando o EA foi colocado no meio do ciclo.
   for(int p=PositionsTotal()-1;p>=0;p--)
   {
      ulong ticket=PositionGetTicket(p);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(estado.lado==LADO_COMPRA && tipo!=POSITION_TYPE_BUY)
         continue;
      if(estado.lado==LADO_VENDA && tipo!=POSITION_TYPE_SELL)
         continue;
      int nivel=NivelAumentoComentarioFIX207(PositionGetString(POSITION_COMMENT));
      if(nivel>0 && PrecoEntradaAumentoFIX220(estado,nivel)<=0.0)
         SalvarPrecoEntradaAumentoFIX220(estado,nivel,PositionGetDouble(POSITION_PRICE_OPEN));
   }

   // FIX225: com escada rearmada, os niveis antigos fechados pertencem ao ciclo anterior.
   // Posicoes ainda abertas ja foram recuperadas acima; nao repopular A1/A2 antigos pelo historico.
   if(EscadaA1RearmadaFIX225(estado))
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }

   // Recupera aumentos ja realizados pelo historico do ciclo atual.
   datetime inicio=estado.horarioEntrada;
   if(inicio<=0)
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }
   if(!HistorySelect(inicio,TimeCurrent()))
   {
      if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
      else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
      return;
   }
   for(int d=0;d<HistoryDealsTotal();d++)
   {
      ulong deal=HistoryDealGetTicket(d);
      if(deal==0)
         continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=estado.magic)
         continue;
      if(HistoryDealGetInteger(deal,DEAL_ENTRY)!=DEAL_ENTRY_IN)
         continue;
      int nivel=NivelAumentoComentarioFIX207(HistoryDealGetString(deal,DEAL_COMMENT));
      if(nivel<=0 || PrecoEntradaAumentoFIX220(estado,nivel)>0.0)
         continue;
      SalvarPrecoEntradaAumentoFIX220(estado,nivel,HistoryDealGetDouble(deal,DEAL_PRICE));
   }
   if(estado.lado==LADO_COMPRA) g_precosAumentosRestauradosBuy=true;
   else if(estado.lado==LADO_VENDA) g_precosAumentosRestauradosSell=true;
}

double PassoAumentoPontosFIX220(int indiceZero)
{
   if(indiceZero<0 || indiceZero>=ArraySize(g_aumentos))
      return 0.0;
   double atual=MathAbs((double)g_aumentos[indiceZero].distanciaPontos);
   if(atual<=0.0)
      return 0.0;
   if(!InpAumentosDistanciaAbsolutaEntrada || indiceZero==0)
      return atual;
   for(int i=indiceZero-1;i>=0;i--)
   {
      if(!g_aumentos[i].ativa)
         continue;
      double anterior=MathAbs((double)g_aumentos[i].distanciaPontos);
      double passo=atual-anterior;
      if(passo>0.0)
         return passo;
      break;
   }
   return atual;
}

double UltimoPrecoAumentoAntesFIX220(EstadoLado &estado, int indiceZero, int &nivelEncontrado)
{
   nivelEncontrado=0;
   for(int i=(int)MathMin(indiceZero-1,4);i>=0;i--)
   {
      double preco=PrecoEntradaAumentoFIX220(estado,i+1);
      if(preco>0.0)
      {
         nivelEncontrado=i+1;
         return preco;
      }
   }
   return 0.0;
}

int ProximoIndiceAumentoSequencialFIX218(EstadoLado &estado)
{
   // FIX451: um nível confirmado como rearmado tem prioridade sobre o maior
   // nível histórico usado. Sem isso, A3/A4 permaneciam como FEITO para sempre.
   int nivelRearme=NivelInicioRearmeFIX248(estado);
   if(nivelRearme>=1 && nivelRearme<=g_gerAumentos.maxAumentos &&
      nivelRearme<=ArraySize(g_aumentos) && g_aumentos[nivelRearme-1].ativa)
   {
      ulong ticketRearme=0;
      double precoRearme=0.0,volumeRearme=0.0;
      long tipoRearme=-1;
      if(!ObterPosicaoAumentoNivelFIX212(estado,nivelRearme,ticketRearme,precoRearme,volumeRearme,tipoRearme))
         return nivelRearme-1;
   }

   int idx=estado.ultimoNivelAumentoUsado;
   if(estado.aumentosExecutados>idx)
      idx=estado.aumentosExecutados;
   if(idx<0)
      idx=0;
   while(idx<ArraySize(g_aumentos))
   {
      if(!g_aumentos[idx].ativa)
      {
         idx++;
         continue;
      }
      int nivel=idx+1;
      string chaveOK=ChaveLockAumentoConfirmadoFIX208(estado,nivel);
      if(GlobalVariableCheck(chaveOK) && GlobalVariableGet(chaveOK)>0.0)
      {
         if(estado.ultimoNivelAumentoUsado<nivel)
            estado.ultimoNivelAumentoUsado=nivel;
         if(estado.aumentosExecutados<nivel)
            estado.aumentosExecutados=nivel;
         idx++;
         continue;
      }
      // Lock ainda pendente nao libera o proximo nivel. ExecutarAumento trata confirmacao/recuperacao sem duplicar ordem.
      break;
   }
   return idx;
}



#endif // COPA_MEMORIA_REARME_AUMENTOS_MQH
