#ifndef COPA_VOLUME_FECHAMENTO_MQH
#define COPA_VOLUME_FECHAMENTO_MQH

// ============================================================================
// RESPONSABILIDADE: NORMALIZACAO E CALCULO SEGURO DO VOLUME
// Funcoes movidas do principal na V45 sem alteracao de regra operacional.
// ============================================================================

double NormalizarVolumeParaFechamento(double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   double vol = MathFloor(volume / step) * step;
   if(vol < minVol)
      return 0.0;
   if(maxVol > 0.0 && vol > maxVol)
      vol = maxVol;
   return NormalizeDouble(vol, 2);
}

double CalcularVolumeParcialSeguro(double volumeAtual, double percentualVolume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 1.0;
   if(volumeAtual <= minVol + 0.0001)
      return 0.0;
   double perc = MathAbs(percentualVolume);
   if(perc <= 0.0)
      perc = 50.0;
   if(perc > 100.0)
      perc = 100.0;
   double desejado = volumeAtual * (perc / 100.0);
   double vol = NormalizarVolumeParaFechamento(desejado);
   if(vol <= 0.0)
      return 0.0;
   if((volumeAtual - vol) > 0.0001 && (volumeAtual - vol) < minVol)
      vol = NormalizarVolumeParaFechamento(volumeAtual - minVol);
   if(vol <= 0.0)
      return 0.0;
   if(vol >= volumeAtual - 0.0001)
      return 0.0;
   return vol;
}


#endif // COPA_VOLUME_FECHAMENTO_MQH
