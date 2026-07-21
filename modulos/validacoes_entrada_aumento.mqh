#ifndef COPA_VALIDACOES_ENTRADA_AUMENTO_MQH
#define COPA_VALIDACOES_ENTRADA_AUMENTO_MQH

bool PermiteEnvioOrdem(EstadoLado &estado, string contexto)
{
   if(!InpAtivarRobo && !g_fechamentoManualEmAndamentoFIX284)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " bloqueado: robo desligado no controle principal.", 0, 0, 0.0, 0.0, false);
      return false;
   }
   if(!InpPermitirEnvioOrdens && !g_fechamentoManualEmAndamentoFIX284)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " autorizado, mas ordens estao TRAVADAS nos parametros.", 0, 0, 0.0, 0.0, false);
      return false;
   }
   if(InpExigirContaDemo && !g_contaDemo)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " bloqueado: conta nao e DEMO.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!g_ambienteLiberado)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " bloqueado: ambiente nao liberado.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(g_bloqueioValidacaoInicial)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " bloqueado: posicao existente no inicio da validacao.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   bool contextoSaida = (StringFind(contexto, "Saida") >= 0 ||
                         StringFind(contexto, "SAIDA") >= 0 ||
                         StringFind(contexto, "Protecao") >= 0 ||
                         StringFind(contexto, "PROTECAO") >= 0);
   if(!contextoSaida && ControleBloqueiaMagicFIX285(estado.magic))
   {
      RegistrarGerenciadorOrdens(estado, contexto,
                                 contexto + " bloqueado pelo botao FIX285: " + TextoControleMagicFIX285(estado.magic) + ".",
                                 0, 0, 0.0, 0.0, false);
      return false;
   }
   if(!contextoSaida && !EntradaDiretaDemoEfetivaFIX302() && InpBloquearOrdensSeAuditoriaFalharFIX274 && !g_auditoriaTesteFIX274OK)
   {
      RegistrarGerenciadorOrdens(estado, contexto, contexto + " bloqueado pela auditoria FIX274: " + g_auditoriaTesteFIX274Status, 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!contextoSaida && InpAmbienteExecucaoFIX342==AMBIENTE_FIX342_REAL && !g_auditoriaProducaoOKFIX342)
   {
      RegistrarGerenciadorOrdens(estado,contexto,contexto+" bloqueado: "+g_auditoriaProducaoStatusFIX342,0,0,0.0,0.0,true);
      return false;
   }
   if(!contextoSaida)
   {
      string motivoCfgFIX342="";
      if(!ConfiguracaoParABCompativelFIX342(motivoCfgFIX342))
      {
         RegistrarGerenciadorOrdens(estado,contexto,contexto+" bloqueado: configuracao A/B divergente | "+motivoCfgFIX342,0,0,0.0,0.0,true);
         return false;
      }
   }
   // FIX256: saídas permanecem permitidas por segurança; novas entradas/aumentos exigem A+B sincronizadas.
   if(!contextoSaida && !CoordenacaoPermiteNovaOrdemFIX256(estado,contexto))
      return false;
   if(!contextoSaida && InpIntervaloMinimoOrdensSeg > 0 && estado.ultimaTentativaOrdem > 0)
   {
      int segundos = (int)(TimeCurrent() - estado.ultimaTentativaOrdem);
      if(segundos < InpIntervaloMinimoOrdensSeg)
      {
         RegistrarGerenciadorOrdens(estado, contexto,
                                    StringFormat("%s bloqueado: intervalo minimo entre ordens (%ds).", contexto, InpIntervaloMinimoOrdensSeg),
                                    0, 0, 0.0, 0.0, false);
         return false;
      }
   }
   return true;
}

bool PermiteEnvioAumentoDiretoFIX211(EstadoLado &estado, string contexto)
{
   if(!EntradaDiretaDemoEfetivaFIX302() && InpBloquearOrdensSeAuditoriaFalharFIX274 && !g_auditoriaTesteFIX274OK)
   {
      RegistrarGerenciadorOrdens(estado, "AUMENTO_BLOCK", contexto + " bloqueado pela auditoria FIX274: " + g_auditoriaTesteFIX274Status, 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!InpAtivarRobo)
   {
      RegistrarGerenciadorOrdens(estado, "AUMENTO_BLOCK", contexto + " bloqueado: execucao geral OFF.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!InpPermitirEnvioOrdens)
   {
      RegistrarGerenciadorOrdens(estado, "AUMENTO_BLOCK", contexto + " bloqueado: envio de ordens OFF.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(InpExigirContaDemo && !g_contaDemo)
   {
      RegistrarGerenciadorOrdens(estado, "AUMENTO_BLOCK", contexto + " bloqueado: conta nao e DEMO.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!g_ambienteLiberado)
   {
      RegistrarGerenciadorOrdens(estado, "AUMENTO_BLOCK", contexto + " bloqueado: ambiente nao liberado.", 0, 0, 0.0, 0.0, true);
      return false;
   }
   if(!CoordenacaoPermiteNovaOrdemFIX256(estado,contexto))
      return false;
   if(InpIntervaloMinimoOrdensSeg > 0 && estado.ultimaTentativaOrdem > 0)
   {
      int segundos = (int)(TimeCurrent() - estado.ultimaTentativaOrdem);
      if(segundos < InpIntervaloMinimoOrdensSeg)
      {
         estado.motivoBloqueioAumento = StringFormat("FIX211 LIVRE: aguardando apenas intervalo tecnico %ds.", InpIntervaloMinimoOrdensSeg - segundos);
         return false;
      }
   }
   return true;
}

bool ReentradaTimerAtivo()
{
   return InpUsarSTFTAntiReentrada;
}


bool STFTPermiteNovaEntrada(EstadoLado &estado)
{
   if(!ReentradaTimerAtivo())
      return true;
   if(estado.bloqueioReentradaAte <= 0)
      return true;
   if(TimeCurrent() >= estado.bloqueioReentradaAte)
      return true;
   int restante = (int)(estado.bloqueioReentradaAte - TimeCurrent());
   int minRest = restante / 60;
   int segRest = restante % 60;
   estado.ultimaMensagem = StringFormat("Reentrada pausada por %02dm%02ds: aguardando timer antes de validar filtros A0.", minRest, segRest);
   RegistrarDecisaoOperacional(estado, "REENTRADA_TIMER", estado.ultimaMensagem);
   return false;
}

void AplicarPausaReentradaEstadoFIX372(EstadoLado &alvo,int segundos,bool lucro,double resultadoHead)
{
   if(segundos<0) segundos=0;
   alvo.reentradaImediataAposLucro=false;
   alvo.bloqueioReentradaAte=(segundos>0 ? TimeCurrent()+(datetime)segundos : 0);
   alvo.ultimaTentativaOrdem=0;
   LiberarLockCiclo(ChaveLockA0(alvo));
   int minBloq=segundos/60;
   int segBloq=segundos%60;
   alvo.ultimaMensagem=StringFormat("HEAD %s %s | REENTRADA EM %02dm%02ds",
                                    lucro ? "LUCRO" : "PERDA",FormatarMoeda(resultadoHead),minBloq,segBloq);
}

void RegistrarSTFTFechamento(EstadoLado &estado, double resultadoDeal)
{
   // Parcial ou fechamento de apenas uma ponta nao encerra o ciclo HEAD.
   if(VolumeAtualMagicServidor(estado)>0.0001)
      return;
   if(ExistePosicaoAbertaGrupoTotalAB())
      return;

   FotoCestaAB fotoCicloFIX372;
   CalcularFotoCestaABOficial(fotoCicloFIX372,false);
   double resultadoHead=fotoCicloFIX372.saldoTotal;
   if(!MathIsValidNumber(resultadoHead))
      resultadoHead=resultadoDeal;

   bool lucro=(resultadoHead>=0.0); // Resultado exatamente zero preserva o comportamento anterior ate decisao especifica.
   int segundos=(lucro ? InpReentradaLucroSegundosFIX372 : InpPausaReentradaSegundos);
   AplicarPausaReentradaEstadoFIX372(g_compra,segundos,lucro,resultadoHead);
   AplicarPausaReentradaEstadoFIX372(g_venda,segundos,lucro,resultadoHead);

   g_fix279CompraSolicitada=false;
   g_fix279VendaSolicitada=false;
   g_fix279UltimaTentativaCompra=0;
   g_fix279UltimaTentativaVenda=0;
   g_ultimoCandleA0DiretoCompraFIX313=0;
   g_ultimoCandleA0DiretoVendaFIX313=0;
   g_fix279StatusCompra=lucro ? "C REENTRADA 5S" : "C REENTRADA 120S";
   g_fix279StatusVenda=lucro ? "V REENTRADA 5S" : "V REENTRADA 120S";
   g_mestre.mensagemGeral=StringFormat("FIX372 CICLO HEAD ENCERRADO %s | RESULTADO %s | NOVA A0 EM %ds",
                                       lucro ? "POSITIVO" : "NEGATIVO",FormatarMoeda(resultadoHead),segundos);
   RegistrarGerenciadorOrdens(estado,lucro ? "REENTRADA_HEAD_LUCRO_5S" : "REENTRADA_HEAD_PERDA_120S",
                              g_mestre.mensagemGeral,0,0,0.0,0.0,true);
}


bool ExistePontaContrariaAberta(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return g_venda.posicaoAberta;
   if(lado == LADO_VENDA)
      return g_compra.posicaoAberta;
   return false;
}

bool BloquearA0OutraPontaAutomatica(EstadoLado &estado)
{
   if(!InpBloquearA0OutraPontaAutomatica)
      return false;
   bool pontaContrariaAberta = ExistePontaContrariaAberta(estado.lado);
   if(pontaContrariaAberta && !InpPermitirOutraPontaSeDirecionalFavor)
   {
      RegistrarDecisaoOperacional(estado, "A0", "Entrada bloqueada: A0 oposto automatico desligado. Ja existe ponta contraria aberta.");
      return true;
   }
   int seg = InpBloqueioA0AposEntradaSegundos;
   if(seg < 0)
      seg = 0;
   if(seg > 0 && g_ultimaEntradaA0OkHora > 0 && g_ultimoLadoEntradaA0Ok >= 0)
   {
      int decorrido = (int)(TimeCurrent() - g_ultimaEntradaA0OkHora);
      if(decorrido < seg && g_ultimoLadoEntradaA0Ok != (int)estado.lado)
      {
         RegistrarDecisaoOperacional(estado, "A0",
                                     StringFormat("Entrada bloqueada: trava tecnica %ds apos A0 para nao abrir duas pontas automaticas.", seg - decorrido));
         return true;
      }
   }
   return false;
}


bool ExisteMesmoSentidoOutroMagicMesmoTF(EstadoLado &estado)
{
   // FIX315: número único significa isolamento real por Magic.
   // Esta trava olha diretamente as posições do servidor e bloqueia somente
   // uma duplicidade do próprio motor local: mesmo ativo, mesmo sentido e
   // exatamente o mesmo Magic. Posição manual, Magic antigo ou outro EA não
   // pode impedir a entrada deste par.
   if(!InpBloquearMesmoSentidoOutroMagicMesmoTF)
      return false;

   long tipoDesejado=-1;
   if(estado.lado==LADO_COMPRA)
      tipoDesejado=POSITION_TYPE_BUY;
   else if(estado.lado==LADO_VENDA)
      tipoDesejado=POSITION_TYPE_SELL;
   else
      return false;

   for(int i=0;i<PositionsTotal();i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_TYPE)!=tipoDesejado)
         continue;

      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic!=estado.magic)
         continue; // outro Magic é outra operação e não bloqueia este motor

      if(InpLogBloqueiosExperts)
      {
         RegistrarGerenciadorOrdens(estado,
                                    "A0_BLOQ_DUPLICIDADE_LOCAL",
                                    StringFormat("A0 bloqueada: já existe %s do próprio Magic %d | Ticket %s",
                                                 tipoDesejado==POSITION_TYPE_BUY ? "BUY" : "SELL",
                                                 (int)magic,
                                                 IntegerToString((long)ticket)),
                                    0,0,0.0,0.0,true);
      }
      return true;
   }
   return false;
}


double ResultadoPontaContraria(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return g_venda.resultadoAberto;
   if(lado == LADO_VENDA)
      return g_compra.resultadoAberto;
   return 0.0;
}

bool PontaContrariaNegativaParaHedge(ENUM_LADO_ROBO lado)
{
   if(InpGestaoCadaMagicVidaPropria)
      return false;
   if(!InpPermitirHedgeRecuperacao)
      return false;
   if(!InpHedgeIgnorarUmaPontaPorTF)
      return false;
   if(!ExistePontaContrariaAberta(lado))
      return false;
   double gatilho = MathAbs(InpHedgeDispararPrejuizoReais);
   if(gatilho <= 0.0)
      gatilho = 1.0;
   double resultadoContra = ResultadoPontaContraria(lado);
   return (resultadoContra <= -gatilho);
}

bool PermitirEntradaHedgeRecuperacao(EstadoLado &estado, string &motivo)
{
   motivo = "";
   if(estado.posicaoAberta)
      return false;
   if(!PontaContrariaNegativaParaHedge(estado.lado))
      return false;
   if(InpHedgeIntervaloTentativaSegundos > 0 && estado.ultimaTentativaOrdem > 0)
   {
      int segundos = (int)(TimeCurrent() - estado.ultimaTentativaOrdem);
      if(segundos < InpHedgeIntervaloTentativaSegundos)
      {
         motivo = StringFormat("Hedge recuperacao aguardando intervalo tecnico %ds.", InpHedgeIntervaloTentativaSegundos - segundos);
         return false;
      }
   }
   double resultadoContra = ResultadoPontaContraria(estado.lado);
   motivo = StringFormat("HEDGE RECUPERACAO: ponta contraria negativa %s | alvo %s | protecao %s / %.0f%% | entrada %s liberada.",
                         PnlMoedaBRL(resultadoContra),
                         PnlMoedaBRL(InpHedgeMetaResolucaoReais),
                         PnlMoedaBRL(InpHedgeProtecaoReais),
                         InpHedgeProtecaoPercent,
                         estado.nome);
   return true;
}


int PrimeiroIndiceAumentoAtivoApartir(int inicio)
{
   if(inicio < 0)
      inicio = 0;
   for(int i = inicio; i < ArraySize(g_aumentos); i++)
   {
      if(g_aumentos[i].ativa)
         return i;
   }
   return -1;
}

int EscolherIndiceAumentoInteligente(EstadoLado &estado)
{
   // FIX451: painel e motor apontam para o mesmo nível rearmado.
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

   // FIX362: histórico/meta não escolhe nem cancela aumento. O STOP HEAD real
   // encerra a cesta somente quando a soma aberta A+B alcançar o limite.
   int sequencial = estado.aumentosExecutados;
   if(estado.ultimoNivelAumentoUsado > sequencial)
      sequencial = estado.ultimoNivelAumentoUsado;
   if(sequencial < 0)
      sequencial = 0;
   if(sequencial > 4)
      sequencial = 4;
   return PrimeiroIndiceAumentoAtivoApartir(sequencial);
}

bool TimerAumentoLiberado(EstadoLado &estado, RegraAumento &aum, int indiceZero=-1)
{
   // FIX453: cada nível possui seu próprio relógio de rearme.
   datetime referencia=0;
   if(indiceZero>=0 && indiceZero<5)
      referencia=(estado.lado==LADO_COMPRA ? g_horaRearmeNivelBuyFIX453[indiceZero]
                                           : g_horaRearmeNivelSellFIX453[indiceZero]);

   // Entrada inicial do nível: usa a última entrada da cesta. Reentrada: usa
   // exclusivamente a hora em que aquele ticket foi realizado.
   if(referencia<=0)
   {
      referencia=estado.horarioUltimoAumento;
      datetime ultimoEnvio=(estado.lado==LADO_COMPRA ? g_ultimoEnvioAumentoBuyFIX434 : g_ultimoEnvioAumentoSellFIX434);
      if(ultimoEnvio>referencia) referencia=ultimoEnvio;
      if(referencia<=0) referencia=estado.horarioEntrada;
   }
   if(referencia<=0) return false;

   int segundosLinha=MathMax(0,aum.tempoMinutos)*60;
   int segundosMinimos=MathMax(0,InpIntervaloMinimoEntreAumentosSegundosFIX434);
   int segundosNecessarios=MathMax(segundosLinha,segundosMinimos);
   return ((int)(TimeCurrent()-referencia)>=segundosNecessarios);
}

bool PrecoChegouNivelAumentoNivel(EstadoLado &estado, RegraAumento &aum, int indiceZero)
{
   if(InpAumentosLivreTeste && InpAumentosLivreIgnorarTimerPreco)
      return true;
   if(aum.distanciaPontos <= 0)
      return true;
   double nivel = PrecoNivelAumentoValorIndice(estado, indiceZero);
   if(nivel <= 0.0)
      return false;
   // FIX224: usa o preco realmente executavel. BUY entra no ASK; SELL entra no BID.
   double precoExecucao = (estado.lado == LADO_COMPRA)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                          : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(precoExecucao <= 0.0)
      return false;
   if(estado.lado == LADO_COMPRA)
      return InpAumentosContraPosicao ? (precoExecucao <= nivel) : (precoExecucao >= nivel);
   if(estado.lado == LADO_VENDA)
      return InpAumentosContraPosicao ? (precoExecucao >= nivel) : (precoExecucao <= nivel);
   return false;
}

void LimparConfirmacaoCandleAumentoFIX224(EstadoLado &estado, int indiceZero)
{
   if(indiceZero < 0 || indiceZero >= 5)
      return;
   if(estado.lado == LADO_COMPRA)
   {
      g_candleToqueAumentoBuyFIX224[indiceZero]=0;
      g_linhaCandleAumentoBuyFIX224[indiceZero]=0.0;
      g_candleAumentoConfirmadoBuyFIX224[indiceZero]=false;
      g_gatilhoRompimentoAumentoBuyFIX337[indiceZero]=0.0;
      g_horaGatilhoRompimentoBuyFIX337[indiceZero]=0;
   }
   else if(estado.lado == LADO_VENDA)
   {
      g_candleToqueAumentoSellFIX224[indiceZero]=0;
      g_linhaCandleAumentoSellFIX224[indiceZero]=0.0;
      g_candleAumentoConfirmadoSellFIX224[indiceZero]=false;
      g_gatilhoRompimentoAumentoSellFIX337[indiceZero]=0.0;
      g_horaGatilhoRompimentoSellFIX337[indiceZero]=0;
   }
}


bool CandleAumentoConfirmadoFIX224(EstadoLado &estado, int indiceZero)
{
   if(indiceZero < 0 || indiceZero >= 5)
      return false;
   if(estado.lado == LADO_COMPRA)
      return g_candleAumentoConfirmadoBuyFIX224[indiceZero];
   if(estado.lado == LADO_VENDA)
      return g_candleAumentoConfirmadoSellFIX224[indiceZero];
   return false;
}

datetime CandleToqueAumentoFIX224(EstadoLado &estado, int indiceZero)
{
   if(indiceZero < 0 || indiceZero >= 5)
      return 0;
   if(estado.lado == LADO_COMPRA)
      return g_candleToqueAumentoBuyFIX224[indiceZero];
   if(estado.lado == LADO_VENDA)
      return g_candleToqueAumentoSellFIX224[indiceZero];
   return 0;
}

string StatusCandleAumentoFIX224(EstadoLado &estado, int indiceZero)
{
   if(!InpAumentoConfirmarFechamentoCandle)
      return PrecoChegouNivelAumentoNivel(estado,g_aumentos[indiceZero],indiceZero) ? "OK" : "PRECO";
   if(CandleAumentoConfirmadoFIX224(estado,indiceZero))
      return InpAumentoRomperExtremoCandle ? "ROMPE" : "OK";
   if(CandleToqueAumentoFIX224(estado,indiceZero)>0)
      return "BUSCA";
   return "PRECO";
}

bool ConfirmarFechamentoCandleAumentoFIX224(EstadoLado &estado, int indiceZero, double linha, string &status)
{
   status="";
   if(indiceZero < 0 || indiceZero >= 5 || linha <= 0.0)
   {
      status="LINHA INVALIDA";
      return false;
   }
   // FIX363: fechamento de candle é obrigatório; nunca libera aumento apenas pelo toque.
   if(!InpAumentoConfirmarFechamentoCandle)
      InpAumentoConfirmarFechamentoCandle=true;

   ENUM_TIMEFRAMES tf=InpAumentoTimeframeConfirmacao;
   if(tf==PERIOD_CURRENT)
      tf=(ENUM_TIMEFRAMES)_Period;
   datetime candleAtual=iTime(_Symbol,tf,0);
   if(candleAtual<=0)
   {
      status="SEM CANDLE";
      return false;
   }

   double margem=MathMax(0.0,InpAumentoMargemFechamentoPontos)*_Point;
   bool precisaAcima=false;
   if(estado.lado==LADO_COMPRA)
      precisaAcima=!InpAumentosContraPosicao;
   else if(estado.lado==LADO_VENDA)
      precisaAcima=InpAumentosContraPosicao;
   else
   {
      status="LADO INVALIDO";
      return false;
   }
   double linhaReferencia=linha;
   double linhaPersistida=(estado.lado==LADO_COMPRA)
                           ? g_linhaCandleAumentoBuyFIX224[indiceZero]
                           : g_linhaCandleAumentoSellFIX224[indiceZero];
   if(linhaPersistida>0.0)
      linhaReferencia=linhaPersistida;
   double linhaExecucao=precisaAcima ? (linhaReferencia+margem) : (linhaReferencia-margem);

   // Preco efetivo da ordem: compra no ASK, venda no BID.
   double precoExecucao=(estado.lado==LADO_COMPRA)
                        ? SymbolInfoDouble(_Symbol,SYMBOL_ASK)
                        : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   bool precoAindaMelhor=precisaAcima ? (precoExecucao>=linhaExecucao) : (precoExecucao<=linhaExecucao); // FIX363: linha exata também é válida

   bool confirmado=CandleAumentoConfirmadoFIX224(estado,indiceZero);
   if(confirmado)
   {
      double gatilho=(estado.lado==LADO_COMPRA)
                      ? g_gatilhoRompimentoAumentoBuyFIX337[indiceZero]
                      : g_gatilhoRompimentoAumentoSellFIX337[indiceZero];
      datetime horaGatilho=(estado.lado==LADO_COMPRA)
                             ? g_horaGatilhoRompimentoBuyFIX337[indiceZero]
                             : g_horaGatilhoRompimentoSellFIX337[indiceZero];
      if(InpAumentoRomperExtremoCandle && gatilho>0.0)
      {
         int segundosTF=PeriodSeconds(tf);
         if(segundosTF<=0) segundosTF=60;
         int validade=MathMax(1,InpAumentoValidadeRompimentoCandles);
         if(horaGatilho>0 && candleAtual>=horaGatilho+(validade*segundosTF))
         {
            LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
            status=StringFormat("GATILHO %.0f EXPIROU | NOVA LEITURA",gatilho);
            return false;
         }
         bool rompeu=(estado.lado==LADO_COMPRA) ? (precoExecucao>=gatilho) : (precoExecucao<=gatilho);
         if(rompeu)
         {
            status=StringFormat("ROMPEU %s %.0f | FILTROS %s FECHADOS",
                                estado.lado==LADO_COMPRA ? "MAX" : "MIN",
                                gatilho,NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));
            return true;
         }
         status=StringFormat("AGUARDA ROMPER %s %.0f | FILTROS %s",
                             estado.lado==LADO_COMPRA ? "MAX" : "MIN",
                             gatilho,NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));
         return false;
      }
      if(precoAindaMelhor)
      {
         status=StringFormat("CANDLE OK | EXEC %.0f",linhaExecucao);
         return true;
      }
      // O filtro demorou e o mercado voltou para o lado pior: exige nova confirmacao.
      LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
      status="PRECO VOLTOU | NOVO CANDLE";
      return false;
   }

   datetime candleToque=CandleToqueAumentoFIX224(estado,indiceZero);
   if(candleToque<=0)
   {
      // O toque so e armado depois de o timer estar OK, pois esta funcao e chamada apos o timer.
      bool tocouAgora=precisaAcima ? (precoExecucao>=linha) : (precoExecucao<=linha);
      if(!tocouAgora)
      {
         status=StringFormat("AGUARDA LINHA %.0f | EXEC %.0f",linha,linhaExecucao);
         return false;
      }
      if(estado.lado==LADO_COMPRA)
      {
         g_candleToqueAumentoBuyFIX224[indiceZero]=candleAtual;
         g_linhaCandleAumentoBuyFIX224[indiceZero]=linha;
      }
      else
      {
         g_candleToqueAumentoSellFIX224[indiceZero]=candleAtual;
         g_linhaCandleAumentoSellFIX224[indiceZero]=linha;
      }
      status=StringFormat("LINHA TOCADA | BUSCA EXEC %.0f",linhaExecucao);
      return false;
   }

   if(candleAtual==candleToque)
   {
      status=StringFormat("ARMADO | AGUARDA CANDLE EM %.0f",linhaExecucao);
      return false;
   }

   datetime candleFechado=iTime(_Symbol,tf,1);
   double linhaArmada=linhaReferencia;
   double fechamento=iClose(_Symbol,tf,1);
   double maxima=iHigh(_Symbol,tf,1);
   double minima=iLow(_Symbol,tf,1);
   bool candleCorreto=(candleFechado==candleToque);
   bool tocouNoCandle=precisaAcima ? (maxima>=linhaArmada) : (minima<=linhaArmada);
   // FIX381: fechamento exatamente na linha programada e valido.
   // Antes, o uso de >/< rejeitava FECHOU 179410 | LINHA 179410.
   bool fechouAlem=precisaAcima ? (fechamento>=linhaArmada+margem) : (fechamento<=linhaArmada-margem);

   LimparConfirmacaoCandleAumentoFIX224(estado,indiceZero);
   if(candleCorreto && tocouNoCandle && fechouAlem && precoAindaMelhor)
   {
      double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tickSize<=0.0) tickSize=_Point;
      double folgaRompimento=MathMax(MathAbs(InpAumentoFolgaRompimentoPontos)*_Point,tickSize);
      double gatilhoRompimento=(estado.lado==LADO_COMPRA) ? (maxima+folgaRompimento) : (minima-folgaRompimento);
      if(estado.lado==LADO_COMPRA)
         gatilhoRompimento=MathCeil(gatilhoRompimento/tickSize)*tickSize;
      else
         gatilhoRompimento=MathFloor(gatilhoRompimento/tickSize)*tickSize;
      gatilhoRompimento=NormalizeDouble(gatilhoRompimento,_Digits);
      bool gatilhoMantemDistancia=precisaAcima ? (gatilhoRompimento>=linhaExecucao) : (gatilhoRompimento<=linhaExecucao);
      if(InpAumentoRomperExtremoCandle && !gatilhoMantemDistancia)
      {
         status=StringFormat("CANDLE SEM ESPACO | %s %.0f CRUZARIA EXEC %.0f | NOVA LEITURA",
                             estado.lado==LADO_COMPRA ? "MAX" : "MIN",
                             gatilhoRompimento,linhaExecucao);
         return false;
      }
      if(estado.lado==LADO_COMPRA)
      {
         g_candleAumentoConfirmadoBuyFIX224[indiceZero]=true;
         g_linhaCandleAumentoBuyFIX224[indiceZero]=linhaArmada;
         g_gatilhoRompimentoAumentoBuyFIX337[indiceZero]=InpAumentoRomperExtremoCandle ? gatilhoRompimento : 0.0;
         g_horaGatilhoRompimentoBuyFIX337[indiceZero]=candleAtual;
      }
      else
      {
         g_candleAumentoConfirmadoSellFIX224[indiceZero]=true;
         g_linhaCandleAumentoSellFIX224[indiceZero]=linhaArmada;
         g_gatilhoRompimentoAumentoSellFIX337[indiceZero]=InpAumentoRomperExtremoCandle ? gatilhoRompimento : 0.0;
         g_horaGatilhoRompimentoSellFIX337[indiceZero]=candleAtual;
      }
      if(InpAumentoRomperExtremoCandle)
      {
         status=StringFormat("CANDLE OK | AGUARDA ROMPER %s %.0f | FILTROS %s",
                             estado.lado==LADO_COMPRA ? "MAX" : "MIN",
                             gatilhoRompimento,NomeTimeframeCurto(TimeframeFiltroAtualFIX255()));
         return false;
      }
      status=StringFormat("CANDLE FECHOU %s %.0f | LINHA %.0f | EXEC %.0f",
                          precisaAcima ? "ACIMA" : "ABAIXO",fechamento,linhaArmada,linhaExecucao);
      return true;
   }

   // Se o candle novo ja estiver do lado da linha, arma uma nova tentativa sem enviar ordem.
   bool tocouNovo=precisaAcima ? (precoExecucao>=linha) : (precoExecucao<=linha);
   if(tocouNovo)
   {
      if(estado.lado==LADO_COMPRA)
      {
         g_candleToqueAumentoBuyFIX224[indiceZero]=candleAtual;
         g_linhaCandleAumentoBuyFIX224[indiceZero]=linha;
      }
      else
      {
         g_candleToqueAumentoSellFIX224[indiceZero]=candleAtual;
         g_linhaCandleAumentoSellFIX224[indiceZero]=linha;
      }
   }
   status=StringFormat("CANDLE NAO CONFIRMOU | FECHOU %.0f | LINHA %.0f",fechamento,linhaArmada);
   return false;
}


// ============================================================================
// RESPONSABILIDADE: EXECUCAO DE A0 E AUMENTOS
// ============================================================================

bool ExecutarEntradaA0(EstadoLado &estado, RegraJanela &janela)
{
   if(ControleBloqueiaMagicFIX285(estado.magic))
   {
      estado.ultimaMensagem = "FIX285: entrada A0 bloqueada pelo botao " + TextoControleMagicFIX285(estado.magic) + ".";
      return false;
   }
   if(estado.posicaoAberta)
      return false;
   if(!ProtecaoRepeticaoPermiteNovaOrdemFIX313(estado,"ENTRADA A0"))
      return false;

   // FIX254: primeira verificacao independente do estado em memoria.
   // A leitura vem diretamente das posicoes do servidor.
   if(ExisteMesmoSentidoOutroMagicMesmoTF(estado))
   {
      RegistrarDecisaoOperacional(estado, "A0", "A0 bloqueada: já existe posição aberta no mesmo lado e no próprio Magic local.");
      return false;
   }

   double volume = InpEntradaContratos;
   if(volume <= 0.0)
      volume = janela.qtd;
   if(volume <= 0.0)
      volume = 1.0;
   string comentario = InpComentarioOrdens + " A0 " + estado.nome;
   RegistrarGerenciadorOrdens(estado, "A0_SINAL",
                              StringFormat("Sinal A0 liberado pela matriz | Volume %.2f | Preco medio atual %.2f", volume, estado.precoMedio),
                              0, 0, volume, 0.0, false);
   string chaveA0 = ChaveLockA0(estado);
   if(!RegistrarLockA0(estado))
      return false;
   if(!PermiteEnvioOrdem(estado, "Entrada A0"))
   {
      LiberarLockCiclo(chaveA0);
      return false;
   }

   // FIX254: segunda leitura imediatamente antes do OrderSend.
   // Protege contra atualizacao atrasada, outro grafico ou ordem externa
   // aberta entre a decisao do filtro e o envio da A0.
   if(ExisteMesmoSentidoOutroMagicMesmoTF(estado))
   {
      LiberarLockCiclo(chaveA0);
      RegistrarDecisaoOperacional(estado, "A0", "A0 cancelada antes do envio: surgiu posição do mesmo lado no próprio Magic local.");
      return false;
   }

   // FIX275: cada A0 inicia um ciclo financeiro novo apenas para esta ponta.
   // Isso impede que o R$100 realizado no ciclo anterior feche a nova A0 imediatamente.
   PrepararNovoCicloPontaFIX275(estado);

   bool ok = EnviarOrdemMercado(estado, volume, comentario, "Entrada A0");
   if(!ok)
      LiberarLockCiclo(chaveA0);
   if(ok)
   {
      g_ultimaEntradaA0OkHora = TimeCurrent();
      g_ultimoLadoEntradaA0Ok = (int)estado.lado;
      AtualizarEstadoLado(estado);
      double volumeConfirmadoFIX342=VolumeAtualMagicServidor(estado);
      if(volumeConfirmadoFIX342>0.0001)
      {
         estado.posicaoAberta = true;
         estado.contratos = volumeConfirmadoFIX342;
         estado.horarioEntrada = TimeCurrent();
         MarcarInicioCicloOperacional(estado);
      }
      else
      {
         // A ordem foi aceita, mas o negócio ainda não apareceu no servidor.
         // O lock permanece e OnTradeTransaction/AtualizarEstado fará a confirmação.
         g_ultimoEnvioAguardandoDealFIX342=true;
         estado.ultimaMensagem="A0 ACEITA | AGUARDANDO DEAL DO SERVIDOR";
         RegistrarGerenciadorOrdens(estado,"FIX342_A0_AGUARDA_DEAL",estado.ultimaMensagem,
                                    0,0,volume,0.0,true);
      }
   }
   return ok;
}

double VolumeAtualMagicServidor(EstadoLado &estado)
{
   // FIX317: mesma identidade usada pelo painel e pelos fechamentos.
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
         continue;
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume > 0.0)
         total += volume;
   }
   return total;
}

bool ExecutarAumento(EstadoLado &estado, RegraAumento &aum, int idx)
{
   if(ControleBloqueiaMagicFIX285(estado.magic))
   {
      estado.motivoBloqueioAumento = "FIX285: aumento bloqueado pelo botao " + TextoControleMagicFIX285(estado.magic) + ".";
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      return false;
   }
   if(!estado.posicaoAberta)
      return false;
   if(idx < 1 || idx > 5)
   {
      estado.motivoBloqueioAumento = "Aumento bloqueado: nivel invalido.";
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      return false;
   }
   // FIX440: sem bloqueio global pela soma de contratos; A1-A5 usam a quantidade definida em cada janela.
   bool diretoFIX211 = (InpAumentosLivreTeste && !InpAumentosLivreIgnorarTimerPreco);
   if(diretoFIX211)
   {
      double volumeReal = VolumeAtualMagicServidor(estado);
      double volumeEsperado = VolumePlanejadoAteAumentoFIX208(idx);
      if(volumeReal + 0.0001 >= volumeEsperado)
      {
         MarcarLockAumentoConfirmadoFIX208(estado, idx);
         ulong ticketBaseFIX220=0;
         double precoBaseFIX220=0.0, volumeBaseFIX220=0.0;
         long tipoBaseFIX220=-1;
         if(ObterPosicaoAumentoNivelFIX212(estado,idx,ticketBaseFIX220,precoBaseFIX220,volumeBaseFIX220,tipoBaseFIX220))
         {
            double programadoDiretoFIX358=PrecoNivelAumentoValorIndice(estado,idx-1);
            SalvarPrecoEntradaAumentoFIX220(estado,idx,precoBaseFIX220);
            RegistrarAuditoriaVisualAumentoFIX358(estado,idx,programadoDiretoFIX358,precoBaseFIX220);
         }
         estado.contratos = volumeReal;
         if(estado.ultimoNivelAumentoUsado < idx)
            estado.ultimoNivelAumentoUsado = idx;
         if(estado.aumentosExecutados < idx)
            estado.aumentosExecutados = idx;
         estado.motivoBloqueioAumento = StringFormat("FIX211 A%d confirmado pelo volume real %.0f; proximo nivel liberado pela fila.", idx, volumeReal);
         return true;
      }
      if(!ExisteOrdemPendenteAumentoFIX208(estado, idx))
      {
         LiberarLockCiclo(ChaveLockAumento(estado, idx));
         LiberarLockCiclo(ChaveLockAumentoConfirmadoFIX208(estado, idx));
      }
   }
   if(LockAumentoJaRegistrado(estado, idx))
   {
      estado.motivoBloqueioAumento = diretoFIX211
         ? StringFormat("FIX211 A%d aguardando confirmacao do servidor; sem duplicar ordem.", idx)
         : StringFormat("Aumento A%d bloqueado: nivel ja executado neste ciclo.", idx);
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      return false;
   }
   // FIX363: segunda conferência usa a MESMA linha que armou o candle.
   // Se a base/preço médio mudou, não aproxima o aumento: exige nova confirmação.
   double linhaFinalFIX363=(estado.lado==LADO_COMPRA
                            ? g_linhaCandleAumentoBuyFIX224[idx-1]
                            : g_linhaCandleAumentoSellFIX224[idx-1]);
   if(linhaFinalFIX363<=0.0)
      linhaFinalFIX363=PrecoNivelAumentoValorIndice(estado,idx-1);
   string statusFinalFIX363="";
   if(!ValidarAumentoFinalAntesEnvioFIX363(estado,idx-1,linhaFinalFIX363,statusFinalFIX363))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d CANCELADO NO ULTIMO CHECK | %s",idx,statusFinalFIX363);
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      RegistrarGerenciadorOrdens(estado,"FIX363_ULTIMO_CHECK_BLOQUEOU",estado.motivoBloqueioAumento,0,0,aum.qtd,PrecoExecutavelAumentoFIX363(estado),true);
      return false;
   }

   // FIX434: segunda trava imediatamente antes do envio. Impede A1/A2 no mesmo tick
   // ou concorrencia entre OnTick e OnTimer.
   if(!TimerAumentoLiberado(estado,aum,idx-1))
   {
      datetime referenciaFIX434=estado.horarioUltimoAumento;
      datetime ultimoEnvioFIX434=(estado.lado==LADO_COMPRA ? g_ultimoEnvioAumentoBuyFIX434 : g_ultimoEnvioAumentoSellFIX434);
      if(ultimoEnvioFIX434>referenciaFIX434) referenciaFIX434=ultimoEnvioFIX434;
      if(referenciaFIX434<=0) referenciaFIX434=estado.horarioEntrada;
      int faltamFIX434=MathMax(0,InpIntervaloMinimoEntreAumentosSegundosFIX434-(int)(TimeCurrent()-referenciaFIX434));
      estado.motivoBloqueioAumento=StringFormat("A%d BLOQUEADO FIX434 | intervalo minimo 120s | faltam %ds",idx,faltamFIX434);
      estado.ultimaMensagem=estado.motivoBloqueioAumento;
      RegistrarGerenciadorOrdens(estado,"FIX434_TIMER_120S",estado.motivoBloqueioAumento,0,0,aum.qtd,0.0,false);
      return false;
   }

   string chaveAum = ChaveLockAumento(estado, idx);
   if(!RegistrarLockAumento(estado, idx))
      return false;
   string comentario = StringFormat("%s A%d %s", InpComentarioOrdens, idx, estado.nome);
   RegistrarGerenciadorOrdens(estado, StringFormat("A%d_SINAL", idx),
                              StringFormat("Sinal de aumento A%d liberado | +%.2f contrato | Dist %d pts | Timer %s",
                                           idx, aum.qtd, aum.distanciaPontos, TimerAumentoCard(estado, aum)),
                              0, 0, aum.qtd, 0.0, false);
   bool envioPermitidoFIX211 = diretoFIX211
      ? PermiteEnvioAumentoDiretoFIX211(estado, StringFormat("Aumento A%d", idx))
      : PermiteEnvioOrdem(estado, StringFormat("Aumento A%d", idx));
   if(!envioPermitidoFIX211)
   {
      LiberarLockCiclo(chaveAum);
      return false;
   }
   double volumeAntesServidor = VolumeAtualMagicServidor(estado);
   // FIX358: fotografia visual do nivel que liberou a ordem. Nao altera a decisao operacional.
   double precoProgramadoAuditoriaFIX358=PrecoNivelAumentoValorIndice(estado,idx-1);
   bool ok = EnviarOrdemMercado(estado, aum.qtd, comentario, StringFormat("Aumento A%d",idx));
   if(ok)
   {
      // FIX434: marca imediatamente no mesmo fluxo, antes de qualquer nova avaliacao.
      if(estado.lado==LADO_COMPRA) g_ultimoEnvioAumentoBuyFIX434=TimeCurrent();
      else if(estado.lado==LADO_VENDA) g_ultimoEnvioAumentoSellFIX434=TimeCurrent();
      AtualizarEstadoLado(estado);
      double volumeDepoisServidor = VolumeAtualMagicServidor(estado);
      double volumeEsperadoMinimo = volumeAntesServidor + MathAbs(aum.qtd) - 0.0001;
      if(volumeDepoisServidor < volumeEsperadoMinimo)
      {
         string msgAguarda = StringFormat("A%d AINDA NAO CONFIRMADO NO SERVIDOR | antes %.2f | depois %.2f | esperado %.2f | lock pendente; sera confirmado pelo volume ou liberado automaticamente se a ordem desaparecer",
                                          idx, volumeAntesServidor, volumeDepoisServidor, volumeEsperadoMinimo);
         estado.motivoBloqueioAumento = msgAguarda;
         estado.ultimaMensagem = msgAguarda;
         RegistrarGerenciadorOrdens(estado, StringFormat("A%d_AGUARDA_CONF", idx), msgAguarda, 0, 0, aum.qtd, 0.0, true);
         RegistrarLogValidacaoSistema("AUMENTO_NAO_CONFIRMADO_VOLUME", msgAguarda);
         return false;
      }
      MarcarLockAumentoConfirmadoFIX208(estado, idx);
      double precoEntradaConfirmadoFIX220=g_ordemUltimoPreco;
      ulong ticketConfirmadoFIX220=0;
      double volumeConfirmadoFIX220=0.0;
      long tipoConfirmadoFIX220=-1;
      double precoPosicaoConfirmadoFIX220=0.0;
      if(ObterPosicaoAumentoNivelFIX212(estado,idx,ticketConfirmadoFIX220,precoPosicaoConfirmadoFIX220,volumeConfirmadoFIX220,tipoConfirmadoFIX220) && precoPosicaoConfirmadoFIX220>0.0)
         precoEntradaConfirmadoFIX220=precoPosicaoConfirmadoFIX220;
      if(precoEntradaConfirmadoFIX220<=0.0)
         precoEntradaConfirmadoFIX220=(estado.lado==LADO_COMPRA ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID));
      SalvarPrecoEntradaAumentoFIX220(estado,idx,precoEntradaConfirmadoFIX220);
      RegistrarAuditoriaVisualAumentoFIX358(estado,idx,precoProgramadoAuditoriaFIX358,precoEntradaConfirmadoFIX220);
      if(estado.lado==LADO_COMPRA && idx>=1 && idx<=5) g_aguardaRetornoLinhaBuyFIX248[idx-1]=false;
      else if(estado.lado==LADO_VENDA && idx>=1 && idx<=5) g_aguardaRetornoLinhaSellFIX248[idx-1]=false;
      estado.horarioUltimoAumento = TimeCurrent();
      estado.ultimoNivelAumentoUsado = idx;
      estado.contratos = volumeDepoisServidor;
      estado.aumentosExecutados = AumentosExecutadosPlanejadosPorContratos(estado.contratos);
      if(estado.aumentosExecutados < idx)
         estado.aumentosExecutados = idx;
      if(estado.aumentosExecutados > g_gerAumentos.maxAumentos)
         estado.aumentosExecutados = g_gerAumentos.maxAumentos;
      string msgAumOk = StringFormat("A%d EXECUTADO CONFIRMADO | +%.0f contrato | Servidor %.0f | SEM LIMITE GLOBAL | Dist %d pts | Aberto %s",
                                     idx,
                                     aum.qtd,
                                     estado.contratos,
                                     aum.distanciaPontos,
                                     PnlMoedaBRL(estado.resultadoAberto));
      RegistrarGerenciadorOrdens(estado, StringFormat("A%d_OK", idx), msgAumOk, 0, 0, aum.qtd, 0.0, true);
      RegistrarLogValidacaoSistema("AUMENTO_CONFIRMADO_VOLUME", msgAumOk);

      // FIX451: a reentrada do mesmo nível foi confirmada. Encerra o contexto
      // pendente para que o próximo fechamento desse ticket crie um novo ciclo.
      int nivelRearmeConfirmado=NivelInicioRearmeFIX248(estado);
      if(nivelRearmeConfirmado==idx)
      {
         RegistrarLogValidacaoSistema("FIX451_REENTRADA_MESMO_NIVEL_OK",
                                      StringFormat("A%d reentrou confirmado; contexto de rearme consumido.",idx));
         if(estado.lado==LADO_COMPRA) g_horaRearmeNivelBuyFIX453[idx-1]=0;
         else if(estado.lado==LADO_VENDA) g_horaRearmeNivelSellFIX453[idx-1]=0;
         LimparContextoRearmeFIX248(estado);
      }
      else if(EscadaA1RearmadaFIX225(estado) && idx<g_gerAumentos.maxAumentos)
         PrepararNovoCruzamentoNivelFIX248(estado,idx+1);
   }
   else
   {
      LiberarLockCiclo(chaveAum);
   }
   return ok;
}


#endif // COPA_VALIDACOES_ENTRADA_AUMENTO_MQH
