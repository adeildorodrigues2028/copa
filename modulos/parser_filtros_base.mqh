#ifndef COPA_PARSER_FILTROS_BASE_MQH
#define COPA_PARSER_FILTROS_BASE_MQH

// ============================================================================
// RESPONSABILIDADE: CONVERSAO DA CONFIGURACAO TECNICA DOS FILTROS
// Funcoes movidas do principal na V43 sem alteracao de regra operacional.
// ============================================================================

RegraFiltros ParseFiltrosDaLinha(string linha)
{
   RegraFiltros f;
   ZeroMemory(f);
   f.configuracaoInvalida = IsOn(GetCampo(linha, "INVALIDO", "OFF"));
   f.erroConfiguracao = GetCampo(linha, "ERRO", "");
   f.confirmarFechamento = (Upper(GetCampo(linha, "CONF", "FECHAMENTO")) == "FECHAMENTO");
   f.candlesConfirmacao = ExtrairInteiro(GetCampo(linha, "CANDLES", "1"));
   f.modo = Upper(GetCampo(linha, "MODO", "TODOS"));
   f.minOk = ExtrairInteiro(GetCampo(linha, "MIN_OK", "0"));
   string filtros = GetCampo(linha, "FILTROS", "");
   string tokens[];
   int total = StringSplit(filtros, '|', tokens);
   for(int i = 0; i < total; i++)
      AplicarFiltroToken(f, tokens[i]);
   string v;
   v = GetCampo(linha, "HILO", GetCampo(linha, "HILO8", ""));
   if(v != "")
      f.usarHilo8 = IsOn(v);
   v = GetCampo(linha, "STR", "");
   if(v != "")
      f.usarSTR = IsOn(v);
   v = GetCampo(linha, "DX25", GetCampo(linha, "DX", ""));
   if(v != "")
   {
      f.usarDX = IsOn(v);
      f.dxOp = ">=";
      f.dxMin = ExtrairNumero(GetCampo(linha, "DXMIN", GetCampo(linha, "DX_MIN", "25")));
   }
   v = GetCampo(linha, "RSI", "");
   if(v != "")
   {
      f.usarRSI = IsOn(v);
      f.rsiCompraOp = GetCampo(linha, "RSIC_OP", GetCampo(linha, "RSI_C_OP", ">="));
      f.rsiCompraMin = ExtrairNumero(GetCampo(linha, "RSIC", GetCampo(linha, "RSI_C", "55")));
      f.rsiVendaOp = GetCampo(linha, "RSIV_OP", GetCampo(linha, "RSI_V_OP", "<="));
      f.rsiVendaMax = ExtrairNumero(GetCampo(linha, "RSIV", GetCampo(linha, "RSI_V", "45")));
   }
   v = GetCampo(linha, "VOLQ", "");
   if(v != "")
   {
      f.usarVOLQ = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.volqOp = ">=";
      if(IsOn(v))
         f.volqMin = ExtrairNumero(GetCampo(linha, "VOLQMIN", GetCampo(linha, "VOLQ_MIN", "1000")));
      else
         f.volqMin = ExtrairNumero(v);
   }
   v = GetCampo(linha, "VOLF", "");
   if(v != "")
   {
      f.usarVOLF = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.volfOp = ">=";
      if(IsOn(v))
         f.volfMin = ExtrairNumero(GetCampo(linha, "VOLFMIN", GetCampo(linha, "VOLF_MIN", "1000000")));
      else
         f.volfMin = ExtrairNumero(v);
   }
   f.volumeCombinado = IsOn(GetCampo(linha, "VOLCOMB", "OFF"));
   v = GetCampo(linha, "AGF", GetCampo(linha, "AGR", ""));
   if(v != "")
   {
      f.usarAGR = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.agrOp = ">=";
      if(IsOn(v))
         f.agrMin = ExtrairNumero(GetCampo(linha, "AGFMIN", GetCampo(linha, "AGRMIN", "50")));
      else
         f.agrMin = ExtrairNumero(v);
   }
   v = GetCampo(linha, "SCORE", GetCampo(linha, "SCORE_MIN", ""));
   if(v != "")
   {
      f.usarScore = IsOn(v) || ExtrairNumero(v) > 0.0;
      f.scoreMin = ExtrairNumero(v);
      if(f.scoreMin <= 0.0)
         f.scoreMin = 60.0;
      f.scoreExtremo = ExtrairNumero(GetCampo(linha, "EXT", GetCampo(linha, "EXTREMO", "85")));
   }
   v = GetCampo(linha, "M25", GetCampo(linha, "MEDIA25", GetCampo(linha, "DIR", "")));
   if(v != "")
      f.usarMedia25Direcional = IsOn(v);
   v = GetCampo(linha,"FORCA",GetCampo(linha,"STRENGTH",""));
   if(v!="")
   {
      f.usarForca=IsOn(v) || ExtrairNumero(v)>0.0;
      f.forcaMin=IsOn(v) ? ExtrairNumero(GetCampo(linha,"FORCAMIN","60")) : ExtrairNumero(v);
      if(f.forcaMin<=0.0) f.forcaMin=60.0;
   }
   v = GetCampo(linha,"FIBO","");
   if(v!="")
   {
      f.usarFibo=IsOn(v) || ExtrairNumero(v)>0.0;
      f.fiboMin=IsOn(v) ? ExtrairNumero(GetCampo(linha,"FIBOMIN","1.272")) : ExtrairNumero(v);
      if(f.fiboMin<=0.0) f.fiboMin=1.272;
   }
   v = GetCampo(linha,"WAPBANDS",GetCampo(linha,"VWAPBANDS",GetCampo(linha,"WAP","")));
   if(v!="")
   {
      f.usarWapBands=IsOn(v) || ExtrairNumero(v)>0.0;
      f.wapBandDesvios=IsOn(v) ? ExtrairNumero(GetCampo(linha,"WAPDESVIO","1.0")) : ExtrairNumero(v);
      if(f.wapBandDesvios<=0.0) f.wapBandDesvios=1.0;
   }
   if(f.usarScore && !f.usarMedia25Direcional)
      f.usarMedia25Direcional = true;
   return f;
}

#endif // COPA_PARSER_FILTROS_BASE_MQH
