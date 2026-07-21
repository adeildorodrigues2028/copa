#ifndef COPA_ENTRADA_DIRETA_MQH
#define COPA_ENTRADA_DIRETA_MQH

bool PermissoesTradingFIX279(ENUM_LADO_ROBO lado, string &motivo)
{
   motivo="";
   if(!EntradaDiretaDemoEfetivaFIX302())
   {
      motivo="MODO DIRETO OFF";
      return false;
   }
   if(!InpAtivarRobo)
   {
      motivo="ROBO OFF";
      return false;
   }
   // FIX319: LIVRE PROTEGIDA é um teste técnico de envio. Ela não depende
   // das quatro janelas A0, mas continua respeitando o bloqueio global do fim do dia.
   if(!PrimeiraOrdemLivreProtegidaFIX314() && !HorarioCompactoPermitidoAgora(InpHorariosEntradaA0))
   {
      motivo="A0 FORA DO HORARIO DE ENTRADA";
      return false;
   }
   if(!InpPermitirEnvioOrdens)
   {
      motivo="ORDENS OFF NOS PARAMETROS";
      return false;
   }
   if(!g_ambienteLiberado)
   {
      motivo="AMBIENTE BLOQUEADO: "+g_mestre.mensagemAmbiente;
      return false;
   }
   if(InpExigirContaDemo && !g_contaDemo)
   {
      motivo="CONTA NAO E DEMO";
      return false;
   }
   if(!g_contaHedge)
   {
      motivo="CONTA NAO E HEDGE";
      return false;
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      motivo="ALGOTRADING GLOBAL DESLIGADO";
      return false;
   }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      motivo="NEGOCIACAO DO EA NAO AUTORIZADA";
      return false;
   }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      motivo="CONTA NAO AUTORIZA TRADE";
      return false;
   }
   long tradeMode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(tradeMode==SYMBOL_TRADE_MODE_DISABLED || tradeMode==SYMBOL_TRADE_MODE_CLOSEONLY)
   {
      motivo=StringFormat("SIMBOLO BLOQUEADO TRADE_MODE=%d",(int)tradeMode);
      return false;
   }
   if(lado==LADO_COMPRA && tradeMode==SYMBOL_TRADE_MODE_SHORTONLY)
   {
      motivo="SIMBOLO SOMENTE VENDA";
      return false;
   }
   if(lado==LADO_VENDA && tradeMode==SYMBOL_TRADE_MODE_LONGONLY)
   {
      motivo="SIMBOLO SOMENTE COMPRA";
      return false;
   }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
   {
      motivo="SEM BID/ASK VALIDO";
      return false;
   }
   return true;
}

bool EnviarA0DiretoFIX279(EstadoLado &estado)
{
   string motivoDirecaoFIX288="";
   if(!ValidarDirecaoFixaOrdemFIX288(estado,motivoDirecaoFIX288))
   {
      g_fix279StatusGeral="FIX288 BLOQUEADO: "+motivoDirecaoFIX288;
      RegistrarGerenciadorOrdens(estado,"FIX288_DIRECAO_BLOCK",g_fix279StatusGeral,0,0,0.0,0.0,true);
      return false;
   }
   if(ControleBloqueiaMagicFIX285(estado.magic))
   {
      g_fix279StatusGeral="FIX285: lado local pausado/encerrado";
      estado.ultimaMensagem=g_fix279StatusGeral;
      return false;
   }
   if(!CoordenacaoPermiteNovaOrdemFIX256(estado,"FIX279 A0 DIRETO LOCAL"))
   {
      g_fix279StatusGeral=g_statusCoordenacaoMagics_FIX256;
      estado.ultimaMensagem=g_fix279StatusGeral;
      return false;
   }
   string chaveA0FIX319=ChaveLockA0(estado);
   if(!RegistrarLockA0(estado))
   {
      g_fix279StatusGeral=estado.ultimaMensagem;
      return false;
   }
   if(!ProtecaoRepeticaoPermiteNovaOrdemFIX313(estado,"ENTRADA DIRETA"))
   {
      g_fix279StatusGeral=(estado.ultimaMensagem!="" ? estado.ultimaMensagem : g_mestre.mensagemGeral);
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   string motivoPermissao="";
   if(!PermissoesTradingFIX279(estado.lado,motivoPermissao))
   {
      if(estado.lado==LADO_COMPRA)
         g_fix279StatusCompra="C BLOQ: "+motivoPermissao;
      else
         g_fix279StatusVenda="V BLOQ: "+motivoPermissao;
      g_fix279StatusGeral="BLOQUEADO: "+motivoPermissao;
      estado.ultimaMensagem=g_fix279StatusGeral;
      RegistrarGerenciadorOrdens(estado,"FIX279_BLOQ",g_fix279StatusGeral,0,GetLastError(),0.0,0.0,true);
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   AtualizarEstadoLado(estado);
   double volumeServidor=VolumeAtualMagicServidor(estado);
   if(estado.posicaoAberta || volumeServidor>0.0)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_fix279CompraSolicitada=false;
         g_fix279StatusCompra=StringFormat("C OK %.0fC M%d",volumeServidor,(int)estado.magic);
      }
      else
      {
         g_fix279VendaSolicitada=false;
         g_fix279StatusVenda=StringFormat("V OK %.0fC M%d",volumeServidor,(int)estado.magic);
      }
      LiberarLockCiclo(chaveA0FIX319);
      return true;
   }

   datetime agora=TimeCurrent();
   datetime ultima=(estado.lado==LADO_COMPRA ? g_fix279UltimaTentativaCompra : g_fix279UltimaTentativaVenda);
   bool solicitada=(estado.lado==LADO_COMPRA ? g_fix279CompraSolicitada : g_fix279VendaSolicitada);
   // Evita duplicar A0 quando a corretora aceitou a ordem, mas a posicao ainda nao apareceu no terminal.
   if(solicitada && ultima>0 && (agora-ultima)<5)
   {
      g_fix279StatusGeral=StringFormat("AGUARDANDO CONFIRMACAO DO SERVIDOR %ds",5-(int)(agora-ultima));
      estado.ultimaMensagem=g_fix279StatusGeral;
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }
   int intervalo=InpFIX279RepetirTentativaSeg;
   if(intervalo<1) intervalo=1;
   if(ultima>0 && (agora-ultima)<intervalo)
   {
      g_fix279StatusGeral=StringFormat("NOVA TENTATIVA EM %ds",intervalo-(int)(agora-ultima));
      estado.ultimaMensagem=g_fix279StatusGeral;
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   if(ReentradaTimerAtivo() && estado.bloqueioReentradaAte>agora)
   {
      int resta=(int)(estado.bloqueioReentradaAte-agora);
      string aguarda=StringFormat("REENTRADA %ds",resta);
      if(estado.lado==LADO_COMPRA) g_fix279StatusCompra="C "+aguarda;
      else g_fix279StatusVenda="V "+aguarda;
      estado.ultimaMensagem=aguarda;
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   // O Timer e o OnTick nunca podem abrir mais de uma A0 automática
   // dentro do mesmo candle da janela. O candle só é marcado depois que
   // o servidor aceita a ordem; uma rejeição técnica ainda pode ser tentada novamente.
   datetime candleA0DiretoFIX313=0;
   bool continuidadeMesmoCandleFIX352=ModoContinuidadeTesteFIX352();
   if(InpExecutarSomenteNovoCandleEntrada)
   {
      candleA0DiretoFIX313=iTime(_Symbol,TimeframeFiltroAtualFIX255(),0);
      datetime ultimoCandle=(estado.lado==LADO_COMPRA ? g_ultimoCandleA0DiretoCompraFIX313 : g_ultimoCandleA0DiretoVendaFIX313);
      if(!continuidadeMesmoCandleFIX352 && candleA0DiretoFIX313>0 && ultimoCandle==candleA0DiretoFIX313)
      {
         estado.ultimaMensagem="A0 JA EXECUTADA NESTE CANDLE";
         g_fix279StatusGeral=estado.ultimaMensagem;
         LiberarLockCiclo(chaveA0FIX319);
         return false;
      }
      if(continuidadeMesmoCandleFIX352 && candleA0DiretoFIX313>0 && ultimoCandle==candleA0DiretoFIX313)
      {
         estado.ultimaMensagem="FIX352 REENTRADA CONTINUA: POSICAO FECHOU; MESMO CANDLE LIBERADO";
         g_fix279StatusGeral=estado.ultimaMensagem;
      }
   }

   double vol=NormalizarVolume(InpEntradaContratos);
   if(vol<=0.0) vol=NormalizarVolume(1.0);
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
   {
      g_fix279StatusGeral="BLOQUEADO: SEM TICK DO ATIVO";
      estado.ultimaMensagem=g_fix279StatusGeral;
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action=TRADE_ACTION_DEAL;
   req.symbol=_Symbol;
   req.volume=vol;
   req.magic=(ulong)estado.magic;
   req.deviation=InpDesvioMaximoPontos;
   req.type_time=ORDER_TIME_GTC;
   req.type_filling=TipoPreenchimentoSeguro();
   req.comment=ComentarioComIdentidadeMagicFIX304(StringFormat("FIX279 A0 %s",estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA"),req.magic);
   if(estado.lado==LADO_COMPRA)
   {
      req.type=ORDER_TYPE_BUY;
      req.price=tick.ask;
      req.sl=CalcularStopServidorEntradaFIX342(LADO_COMPRA,tick.ask);
      g_fix279UltimaTentativaCompra=agora;
      g_fix279StatusCompra=StringFormat("C ENVIANDO %.0fC M%d",vol,(int)estado.magic);
   }
   else
   {
      req.type=ORDER_TYPE_SELL;
      req.price=tick.bid;
      req.sl=CalcularStopServidorEntradaFIX342(LADO_VENDA,tick.bid);
      g_fix279UltimaTentativaVenda=agora;
      g_fix279StatusVenda=StringFormat("V ENVIANDO %.0fC M%d",vol,(int)estado.magic);
   }

   MqlTradeCheckResult checkFIX319;
   string motivoPreflightFIX342="";
   if(!ValidarPreflightEntradaFIX342(estado,req,motivoPreflightFIX342,checkFIX319))
   {
      int erroCheckFIX319=GetLastError();
      g_fix279StatusGeral="PREFLIGHT BLOQ: "+motivoPreflightFIX342;
      estado.ultimaMensagem=g_fix279StatusGeral;
      // FIX351: o motivo aparece primeiro no Experts, sem ficar escondido pelo texto longo do gerenciador.
      PrintFormat("[COPA_AR100][FIX351][PREFLIGHT_BLOQUEOU] %s | Lado %s | Magic %I64d | RC %u | E %d | preço %.0f | volume %.2f",
                  motivoPreflightFIX342,estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",estado.magic,
                  checkFIX319.retcode,erroCheckFIX319,req.price,vol);
      RegistrarGerenciadorOrdens(estado,"FIX351_PREFLIGHT_BLOCK",g_fix279StatusGeral,checkFIX319.retcode,erroCheckFIX319,vol,req.price,true);
      LiberarLockCiclo(chaveA0FIX319);
      return false;
   }

   PrepararNovoCicloPontaFIX275(estado);
   estado.ultimaTentativaOrdem=agora;
   estado.ultimaMensagem=StringFormat("FIX319 ENVIANDO A0 %s %.0fC M%d",estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",vol,(int)estado.magic);
   ResetLastError();
   g_ultimoEnvioAguardandoDealFIX342=false;
   g_ultimaOrdemPendenteFIX342=0;
   PrintFormat("[COPA_AR100][FIX351][ORDERSEND_A0] ENVIANDO %s | Magic %I64d | preço %.0f | volume %.2f | SL %.0f",
               estado.lado==LADO_COMPRA ? "COMPRA" : "VENDA",estado.magic,req.price,req.volume,req.sl);
   bool ok=OrderSend(req,res);
   g_ultimoRetcodeExternoFIX342=res.retcode_external;
   ProcessarRetcodeEntradaFIX342(estado,res.retcode,res.retcode_external,"A0 DIRETA DEMO");
   int erro=GetLastError();
   bool aceito=(ok && (res.retcode==TRADE_RETCODE_DONE ||
                       res.retcode==TRADE_RETCODE_DONE_PARTIAL ||
                       res.retcode==TRADE_RETCODE_PLACED));
   if(aceito && res.retcode==TRADE_RETCODE_PLACED)
   {
      g_ultimoEnvioAguardandoDealFIX342=true;
      g_ultimaOrdemPendenteFIX342=res.order;
   }

   if(estado.lado==LADO_COMPRA)
   {
      g_fix279RetcodeCompra=res.retcode;
      g_fix279ErroCompra=erro;
      g_fix279CompraSolicitada=aceito;
      g_fix279StatusCompra=aceito
         ? StringFormat("C ACEITA RC%d DEAL%s",(int)res.retcode,IntegerToString((long)res.deal))
         : StringFormat("C REJ RC%d E%d",(int)res.retcode,erro);
   }
   else
   {
      g_fix279RetcodeVenda=res.retcode;
      g_fix279ErroVenda=erro;
      g_fix279VendaSolicitada=aceito;
      g_fix279StatusVenda=aceito
         ? StringFormat("V ACEITA RC%d DEAL%s",(int)res.retcode,IntegerToString((long)res.deal))
         : StringFormat("V REJ RC%d E%d",(int)res.retcode,erro);
   }

   g_fix279StatusGeral=StringFormat("FIX293 DX2 D0 | C RC%d/E%d | V RC%d/E%d",
                                    (int)g_fix279RetcodeCompra,g_fix279ErroCompra,
                                    (int)g_fix279RetcodeVenda,g_fix279ErroVenda);
   RegistrarGerenciadorOrdens(estado,
                              aceito ? "FIX279_ORDER_OK" : "FIX279_ORDER_REJECT",
                              (estado.lado==LADO_COMPRA ? g_fix279StatusCompra : g_fix279StatusVenda),
                              res.retcode,erro,vol,req.price,true);
   estado.ultimaMensagem=(estado.lado==LADO_COMPRA ? g_fix279StatusCompra : g_fix279StatusVenda);
   if(!aceito)
      LiberarLockCiclo(chaveA0FIX319);
   if(aceito)
   {
      if(InpExecutarSomenteNovoCandleEntrada && candleA0DiretoFIX313>0)
      {
         if(estado.lado==LADO_COMPRA) g_ultimoCandleA0DiretoCompraFIX313=candleA0DiretoFIX313;
         else g_ultimoCandleA0DiretoVendaFIX313=candleA0DiretoFIX313;
      }
      estado.reentradaImediataAposLucro=false; // FIX361: benefício consumido somente após servidor aceitar a nova A0
      estado.posicaoAberta=true;
      estado.contratos=vol;
      estado.horarioEntrada=agora;
      MarcarInicioCicloOperacional(estado);
   }
   return aceito;
}

bool ProcessarEntradaDiretaFIX279()
{
   if(!EntradaDiretaDemoEfetivaFIX302())
      return false;

   AtualizarEstadosDePosicao();
   if(JanelaAtualEhA_FIX255())
   {
      bool temCompra=(g_compra.posicaoAberta || VolumeAtualMagicServidor(g_compra)>0.0);
      if(!temCompra && !ControleBloqueiaMagicFIX285(g_compra.magic))
         EnviarA0DiretoFIX279(g_compra);
      AtualizarEstadosDePosicao();
      temCompra=(g_compra.posicaoAberta || VolumeAtualMagicServidor(g_compra)>0.0);
      if(temCompra)
      {
         GarantirStopsServidorFIX342(true);
         g_fix279StatusGeral="A0 COMPRA ABERTA E PROTEGIDA";
      }
      else if(g_fix279StatusGeral=="")
         g_fix279StatusGeral="TENTANDO A0 COMPRA";
      return temCompra;
   }

   bool temVenda=(g_venda.posicaoAberta || VolumeAtualMagicServidor(g_venda)>0.0);
   if(!temVenda && !ControleBloqueiaMagicFIX285(g_venda.magic))
      EnviarA0DiretoFIX279(g_venda);
   AtualizarEstadosDePosicao();
   temVenda=(g_venda.posicaoAberta || VolumeAtualMagicServidor(g_venda)>0.0);
   if(temVenda)
   {
      GarantirStopsServidorFIX342(true);
      g_fix279StatusGeral="A0 VENDA ABERTA E PROTEGIDA";
   }
   else if(g_fix279StatusGeral=="")
      g_fix279StatusGeral="TENTANDO A0 VENDA";
   return temVenda;
}


#endif // COPA_ENTRADA_DIRETA_MQH
