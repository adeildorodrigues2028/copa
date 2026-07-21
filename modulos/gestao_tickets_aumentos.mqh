#ifndef COPA_GESTAO_TICKETS_AUMENTOS_MQH
#define COPA_GESTAO_TICKETS_AUMENTOS_MQH

// ============================================================================
// RESPONSABILIDADE: GESTAO FINANCEIRA INDIVIDUAL DOS TICKETS DE AUMENTO
// Funcoes movidas do principal na V42 sem alteracao de regra operacional.
// ============================================================================

double ResultadoCicloPontaFIX207(long tipo, double lucroAberto)
{
   if(tipo==POSITION_TYPE_BUY)
      return lucroAberto+g_parciaisCicloBuy;
   if(tipo==POSITION_TYPE_SELL)
      return lucroAberto+g_parciaisCicloSell;
   return lucroAberto;
}

bool FecharTicketAumentoFIX207(EstadoLado &estado, ulong ticket, double volumeDesejado, int nivel, double lucroTicket, string motivoFIX281)
{
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return false;
   if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
      return false;
   long tipoPosicao=PositionGetInteger(POSITION_TYPE);
   double volumePosicao=PositionGetDouble(POSITION_VOLUME);
   if(volumePosicao<=0.0)
      return false;
   double volumeFechar=MathMin(volumePosicao,MathAbs(volumeDesejado));
   volumeFechar=NormalizarVolumeParaFechamento(volumeFechar);
   if(volumeFechar<=0.0)
      return false;
   if(!PermiteEnvioOrdem(estado,"Saida aumento alvo/trailing FIX281"))
      return false;
   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action=TRADE_ACTION_DEAL;
   req.position=ticket;
   req.symbol=_Symbol;
   req.volume=volumeFechar;
   req.magic=(ulong)estado.magic;
   req.deviation=InpDesvioMaximoPontos;
   req.type_time=ORDER_TIME_GTC;
   req.type_filling=TipoPreenchimentoSeguro();
   req.comment=ComentarioComIdentidadeMagicFIX304(StringFormat("%s PARCIAL_AUMENTO_FIX281 A%d %s",InpComentarioOrdens,nivel,motivoFIX281),req.magic);
   if(tipoPosicao==POSITION_TYPE_BUY)
   {
      req.type=ORDER_TYPE_SELL;
      req.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   }
   else if(tipoPosicao==POSITION_TYPE_SELL)
   {
      req.type=ORDER_TYPE_BUY;
      req.price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   }
   else
      return false;
   estado.ultimaTentativaOrdem=TimeCurrent();
   ResetLastError();
   bool ok=OrderSend(req,res);
   bool aceito=(ok && (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED || res.retcode==TRADE_RETCODE_DONE_PARTIAL));
   if(aceito)
   {
      RegistrarGerenciadorOrdens(estado,"AUMENTO_SAIDA_OK",
         StringFormat("FIX282 A%d %s | ticket %s | lucro %s | fecha %.2f contrato",
                      nivel,motivoFIX281,IntegerToString((long)ticket),PnlMoedaBRL(lucroTicket),volumeFechar),
         res.retcode,0,volumeFechar,req.price,true);
      return true;
   }
   RegistrarGerenciadorOrdens(estado,"AUMENTO_SAIDA_REJECT",
      StringFormat("FIX282 A%d %s ticket %s rejeitado | retcode %d | erro %d",
                   nivel,motivoFIX281,IntegerToString((long)ticket),(int)res.retcode,GetLastError()),
      res.retcode,GetLastError(),volumeFechar,req.price,true);
   return false;
}

double CalcularDefesaDegrauFIX281(double melhorLucro, double ativacao, double passo)
{
   ativacao=MathAbs(ativacao);
   passo=MathAbs(passo);
   if(ativacao<=0.0 || passo<=0.0 || melhorLucro<ativacao)
      return 0.0;
   double degraus=MathFloor(((melhorLucro-ativacao)+0.0000001)/passo);
   return MathMax(0.0,(ativacao-passo)+(degraus*passo));
}

void ResetarTrailAumentoFIX281(EstadoTrailAumentoFIX281 &trail)
{
   trail.ticket=0;
   trail.identificador=0;
   trail.melhorLucro=0.0;
   trail.defesaAtual=0.0;
   trail.protecaoArmada=false;
   trail.movelArmadoFIX397=false;
   trail.defesaMovelFIX397=0.0;
   trail.melhorPrecoFIX325=0.0;
   trail.stopPrecoFIX325=0.0;
   trail.distanciaAtualPontosFIX325=0.0;
   trail.degrauAtualFIX325=-1;
   trail.alertaToqueEmitidoFIX325=false;
}

double NormalizarPrecoTrailInteligenteFIX325(double preco, long tipo)
{
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick<=0.0) tick=_Point;
   if(tick<=0.0) return NormalizeDouble(preco,_Digits);
   double unidades=preco/tick;
   if(tipo==POSITION_TYPE_BUY)
      unidades=MathFloor(unidades+0.0000001);
   else
      unidades=MathCeil(unidades-0.0000001);
   return NormalizeDouble(unidades*tick,_Digits);
}

bool AtualizarTrailInteligenteAumentoFIX325(EstadoLado &estado,
                                             long tipo,
                                             ulong ticket,
                                             int nivel,
                                             double volume,
                                             EstadoTrailAumentoFIX281 &trail,
                                             bool &armouAgora,
                                             bool &moveuAgora)
{
   armouAgora=false;
   moveuAgora=false;
   if(!g_trailInteligenteLinhasAtivoFIX325 || ticket==0 || volume<=0.0 || !PositionSelectByTicket(ticket))
      return false;
   double entrada=PositionGetDouble(POSITION_PRICE_OPEN);
   double atual=(tipo==POSITION_TYPE_BUY ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK));
   if(entrada<=0.0 || atual<=0.0 || _Point<=0.0)
      return false;
   if(trail.melhorPrecoFIX325<=0.0)
      trail.melhorPrecoFIX325=entrada;
   if(tipo==POSITION_TYPE_BUY && atual>trail.melhorPrecoFIX325)
      trail.melhorPrecoFIX325=atual;
   else if(tipo==POSITION_TYPE_SELL && (trail.melhorPrecoFIX325<=0.0 || atual<trail.melhorPrecoFIX325))
      trail.melhorPrecoFIX325=atual;

   double favorPontos=(tipo==POSITION_TYPE_BUY
                       ? (trail.melhorPrecoFIX325-entrada)/_Point
                       : (entrada-trail.melhorPrecoFIX325)/_Point);
   if(favorPontos+0.0001<g_trailInteligenteAtivaPontosFIX325)
      return false;
   int degrau=(int)MathFloor((favorPontos-g_trailInteligenteAtivaPontosFIX325+0.0001)/g_trailInteligentePassoPontosFIX325);
   if(degrau<0) degrau=0;
   bool precisaMover=(!trail.protecaoArmada || degrau>trail.degrauAtualFIX325);
   if(precisaMover)
   {
      double distancia=g_trailInteligenteDistanciaPontosFIX325;
      if(g_trailInteligenteReduzirFIX325)
         distancia-=((double)degrau*g_trailInteligenteReducaoPontosFIX325);
      if(distancia<g_trailInteligenteDistanciaMinimaPontosFIX325)
         distancia=g_trailInteligenteDistanciaMinimaPontosFIX325;
      double candidato=(tipo==POSITION_TYPE_BUY
                        ? trail.melhorPrecoFIX325-(distancia*_Point)
                        : trail.melhorPrecoFIX325+(distancia*_Point));
      // O primeiro stop nunca fica pior que o preco de entrada.
      if(tipo==POSITION_TYPE_BUY && candidato<entrada) candidato=entrada;
      if(tipo==POSITION_TYPE_SELL && candidato>entrada) candidato=entrada;
      candidato=NormalizarPrecoTrailInteligenteFIX325(candidato,tipo);
      bool melhorou=(!trail.protecaoArmada || trail.stopPrecoFIX325<=0.0 ||
                     (tipo==POSITION_TYPE_BUY && candidato>trail.stopPrecoFIX325) ||
                     (tipo==POSITION_TYPE_SELL && candidato<trail.stopPrecoFIX325));
      if(melhorou)
      {
         armouAgora=!trail.protecaoArmada;
         moveuAgora=trail.protecaoArmada;
         trail.protecaoArmada=true;
         trail.stopPrecoFIX325=candidato;
         trail.distanciaAtualPontosFIX325=distancia;
         trail.degrauAtualFIX325=degrau;
         double protegidoPontos=(tipo==POSITION_TYPE_BUY ? (candidato-entrada)/_Point : (entrada-candidato)/_Point);
         double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
         trail.defesaAtual=(tickSize>0.0 && tickValue>0.0)
                            ? MathMax(0.0,protegidoPontos*_Point/tickSize*tickValue*volume)
                            : MathMax(0.0,protegidoPontos);
         trail.alertaToqueEmitidoFIX325=false;
         RegistrarLogValidacaoSistema(armouAgora ? "FIX325_TRAIL_INT_ARMADO" : "FIX325_TRAIL_INT_MOVEU",
            StringFormat("%s A%d | favor %.0f pts | degrau %d | stop %.0f | distancia %.0f pts | protegido %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,favorPontos,degrau,
                         trail.stopPrecoFIX325,distancia,PnlMoedaBRL(trail.defesaAtual)));
         if(g_trailInteligenteApitarFIX325)
            PlaySound("alert.wav");
      }
   }
   if(!trail.protecaoArmada || armouAgora || moveuAgora || trail.stopPrecoFIX325<=0.0)
      return false;
   bool tocou=(tipo==POSITION_TYPE_BUY
               ? atual<=trail.stopPrecoFIX325+(_Point*0.1)
               : atual>=trail.stopPrecoFIX325-(_Point*0.1));
   if(tocou && !trail.alertaToqueEmitidoFIX325)
   {
      trail.alertaToqueEmitidoFIX325=true;
      if(g_trailInteligenteApitarFIX325)
         PlaySound("alert.wav");
   }
   return tocou;
}

bool ProcessarTicketAumentoFIX281(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo, ulong ticket, int nivel, double volume, double lucroTicket, EstadoTrailAumentoFIX281 &trail)
{
   if(ticket==0 || nivel<1 || nivel>5 || volume<=0.0)
      return false;
   if(!PositionSelectByTicket(ticket))
      return false;
   ulong identificador=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   if(trail.ticket!=ticket || trail.identificador!=identificador)
   {
      ResetarTrailAumentoFIX281(trail);
      trail.ticket=ticket;
      trail.identificador=identificador;
   }
   if(lucroTicket>trail.melhorLucro)
      trail.melhorLucro=lucroTicket;

   double alvo=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*volume;
   double lossIndividual=InpStopDinamicoHeadFIX359 ? 0.0 : MathAbs(InpLossAumentoPorContratoReaisFIX321)*volume;
   int idxRegra=nivel-1;
   double ativacaoUnitaria=MathAbs(InpTrailingAumentoAtivarReaisFIX281);
   double passoUnitario=MathAbs(InpTrailingAumentoPassoReaisFIX281);
   if(idxRegra>=0 && idxRegra<5)
   {
      if(g_aumentos[idxRegra].trailingAtivarReais>0.0) ativacaoUnitaria=g_aumentos[idxRegra].trailingAtivarReais;
      if(g_aumentos[idxRegra].trailingPassoReais>0.0) passoUnitario=g_aumentos[idxRegra].trailingPassoReais;
   }
   double ativacao=ativacaoUnitaria*volume;
   double passo=passoUnitario*volume;
   if(alvo<=0.0) alvo=100.0*volume;
   if(ativacao<=0.0) ativacao=20.0*volume;
   if(passo<=0.0) passo=5.0*volume;

   // FIX442: MOVEL e TRAIL sao individuais e lidos da janela A1-A5.
   // MOVEL=X/Y: ao atingir X por contrato, fixa defesa em Y por contrato.
   // TRAIL=X/Y: ao atingir X, defesa continua = melhor lucro - Y.
   double movelAtivarUnit=0.0;
   double movelDefenderUnit=0.0;
   if(idxRegra>=0 && idxRegra<5)
   {
      movelAtivarUnit=MathAbs(g_aumentos[idxRegra].movelAtivarReais);
      movelDefenderUnit=MathAbs(g_aumentos[idxRegra].movelDefenderReais);
   }
   double movelAtivar=movelAtivarUnit*volume;
   double movelDefender=movelDefenderUnit*volume;
   bool movelHabilitado=(movelAtivarUnit>0.0);
   bool armouMovelAgoraFIX397=false;
   if(movelHabilitado && !trail.movelArmadoFIX397 && trail.melhorLucro+0.0001>=movelAtivar)
   {
      trail.movelArmadoFIX397=true;
      trail.defesaMovelFIX397=movelDefender;
      armouMovelAgoraFIX397=true;
      RegistrarLogValidacaoSistema("FIX442_TICKET_MOVEL_ARMADO",
         StringFormat("%s A%d ticket %s | melhor %s | MOVEL %.2f/%.2f | defesa %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,IntegerToString((long)ticket),
                      PnlMoedaBRL(trail.melhorLucro),movelAtivarUnit,movelDefenderUnit,
                      PnlMoedaBRL(trail.defesaMovelFIX397)));
   }

   bool armouAgora=false;
   bool moveuAgora=false;
   bool tocouTrailInteligente=false;
   if(g_trailInteligenteLinhasAtivoFIX325)
      tocouTrailInteligente=AtualizarTrailInteligenteAumentoFIX325(estado,tipo,ticket,nivel,volume,trail,armouAgora,moveuAgora);
   else if(ativacaoUnitaria>0.0 && passoUnitario>0.0 && !trail.protecaoArmada && trail.melhorLucro+0.0001>=ativacao)
   {
      trail.protecaoArmada=true;
      trail.defesaAtual=NormalizeDouble(MathMax(0.0,trail.melhorLucro-passo),2);
      armouAgora=true;
      RegistrarLogValidacaoSistema("FIX442_TICKET_TRAIL_ARMADO",
         StringFormat("%s A%d ticket %s | melhor %s | TRAIL %.2f/%.2f continuo | defesa %s.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,IntegerToString((long)ticket),
                      PnlMoedaBRL(trail.melhorLucro),ativacaoUnitaria,passoUnitario,PnlMoedaBRL(trail.defesaAtual)));
   }
   if(!g_trailInteligenteLinhasAtivoFIX325 && trail.protecaoArmada)
   {
      double novaDefesa=NormalizeDouble(MathMax(0.0,trail.melhorLucro-passo),2);
      if(novaDefesa>trail.defesaAtual+0.0001)
      {
         trail.defesaAtual=novaDefesa;
         RegistrarLogValidacaoSistema("FIX442_TICKET_TRAIL_SUBIU",
            StringFormat("%s A%d melhor %s | defesa continua %s | distancia %s.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,
                         PnlMoedaBRL(trail.melhorLucro),PnlMoedaBRL(trail.defesaAtual),PnlMoedaBRL(passo)));
      }
   }

   string motivo="";
   if(lossIndividual>0.0 && lucroTicket<=-lossIndividual+0.0001)
      motivo="LOSS_INDIVIDUAL";
   else if(InpAumentoFecharNoAlvoFIX281 && lucroTicket+0.0001>=alvo)
      motivo="ALVO_FIXO";
   else if(trail.movelArmadoFIX397 && !trail.protecaoArmada && !armouMovelAgoraFIX397 &&
           lucroTicket<=trail.defesaMovelFIX397+0.0001)
      motivo="MOVEL_INDIVIDUAL_FIX442";
   else if(g_trailInteligenteLinhasAtivoFIX325 && tocouTrailInteligente)
      motivo="TRAIL_INTELIGENTE_LINHA";
   else if(!g_trailInteligenteLinhasAtivoFIX325 && trail.protecaoArmada && !armouAgora && lucroTicket<=trail.defesaAtual+0.0001)
      motivo="TRAIL_CONTINUO_INDIVIDUAL_FIX442";
   if(motivo=="")
      return false;

   // FIX296: registrar a pendencia ANTES do OrderSend. Assim um deal confirmado muito rapido
   // ja encontra POSITION_IDENTIFIER, nivel e ticket preparados no OnTradeTransaction.
   p.parcialPendente=true;
   p.ticketParcialPendente=ticket;
   p.identificadorParcialPendente=identificador;
   p.nivelAumentoPendente=nivel;
   p.valorNominalParcialPendente=NormalizeDouble(MathMax(0.0,lucroTicket),2);
   p.horaParcialPendente=TimeCurrent();
   if(FecharTicketAumentoFIX207(estado,ticket,volume,nivel,lucroTicket,motivo))
   {
      RegistrarLogValidacaoSistema("FIX296_AUMENTO_SAIDA_ENVIADA",
         StringFormat("%s A%d %s | atual %s | melhor %s | defesa %s | alvo %s | loss -%s | volume %.2f | aguardando confirmacao do servidor.",
                      tipo==POSITION_TYPE_BUY?"BUY":"SELL",nivel,motivo,PnlMoedaBRL(lucroTicket),
                      PnlMoedaBRL(trail.melhorLucro),
                      PnlMoedaBRL(trail.protecaoArmada ? trail.defesaAtual : trail.defesaMovelFIX397),
                      PnlMoedaBRL(alvo),PnlMoedaBRL(lossIndividual),volume));
      return true;
   }
   p.parcialPendente=false;
   p.ticketParcialPendente=0;
   p.identificadorParcialPendente=0;
   p.nivelAumentoPendente=0;
   p.valorNominalParcialPendente=0.0;
   p.horaParcialPendente=0;
   return false;
}

void CalcularAumentosAbertosLadoFIX281(EstadoLado &estado, double &volumeAberto, double &financeiroAberto, int &ticketsAbertos)
{
   volumeAberto=0.0;
   financeiroAberto=0.0;
   ticketsAbertos=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
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
      int nivel=NivelAumentoPosicaoFIX212(estado,ticket,PositionGetString(POSITION_COMMENT));
      if(nivel<=0)
         continue;
      double lucroServidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double lucroManual=LucroAbertoPosicaoSelecionada(tipo);
      financeiroAberto+=(InpLucroAbertoUsarCalculoManual?lucroManual:lucroServidor);
      volumeAberto+=PositionGetDouble(POSITION_VOLUME);
      ticketsAbertos++;
   }
   financeiroAberto=NormalizeDouble(financeiroAberto,2);
   volumeAberto=NormalizeDouble(volumeAberto,2);
}


bool GerenciarRealizacaoAumentosPorTicketFIX207(EstadoPontaSimplesFIX195 &p, EstadoLado &estado, long tipo)
{
   if(!InpRealizarAumentosPorTicketFIX207)
      return false;
   if(p.parcialPendente)
   {
      int timeoutParcial=30;
      if(p.horaParcialPendente>0 && (TimeCurrent()-p.horaParcialPendente)>=timeoutParcial)
      {
         RegistrarLogValidacaoSistema("FIX251_PARCIAL_TIMEOUT_RECUPERADA",
            StringFormat("%s parcial pendente por %d s sem deal confirmado; liberando nova verificacao. Deal tardio ainda sera reconhecido pela tag PARCIAL.",
                         tipo==POSITION_TYPE_BUY?"BUY":"SELL",timeoutParcial));
         p.parcialPendente=false;
         p.ticketParcialPendente=0;
         p.identificadorParcialPendente=0;
         p.nivelAumentoPendente=0;
         p.valorNominalParcialPendente=0.0;
         p.horaParcialPendente=0;
      }
      else
         return false;
   }
   if(!estado.posicaoAberta)
      return false;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=estado.magic)
         continue;
      if(PositionGetInteger(POSITION_TYPE)!=tipo)
         continue;
      string comentario=PositionGetString(POSITION_COMMENT);
      int nivel=NivelAumentoPosicaoFIX212(estado,ticket,comentario);
      if(nivel<=0 || nivel>5)
         continue; // A0 continua com alvo/trailing da ponta; A1-A5 usam gestao individual FIX281.
      if(!PositionSelectByTicket(ticket))
         continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(volume<=0.0)
         continue;
      double lucroServidor=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      double lucroManual=LucroAbertoPosicaoSelecionada(tipo);
      double lucroTicket=InpLucroAbertoUsarCalculoManual ? lucroManual : lucroServidor;
      int idx=nivel-1;
      bool saiu=false;
      if(tipo==POSITION_TYPE_BUY)
         saiu=ProcessarTicketAumentoFIX281(p,estado,tipo,ticket,nivel,volume,lucroTicket,g_trailAumentoBuy[idx]);
      else
         saiu=ProcessarTicketAumentoFIX281(p,estado,tipo,ticket,nivel,volume,lucroTicket,g_trailAumentoSell[idx]);
      if(saiu)
         return true; // uma saida por tick; espera confirmacao real do servidor.
   }
   return false;
}


#endif // COPA_GESTAO_TICKETS_AUMENTOS_MQH
