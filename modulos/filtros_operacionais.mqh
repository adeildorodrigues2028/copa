#ifndef COPA_FILTROS_OPERACIONAIS_MQH
#define COPA_FILTROS_OPERACIONAIS_MQH

bool ExisteJanelaAtivaParaLado(ENUM_LADO_ROBO lado, RegraJanela &janelaOut)
{
   int primeiraJanelaCompativel = -1;
   for(int i = 0; i < 5; i++)
   {
      if(!g_janelas[i].ativa)
         continue;
      if(!g_janelas[i].entradaAtiva)
         continue;
      if(g_janelas[i].lado != LADO_AMBOS && g_janelas[i].lado != lado)
         continue;
      if(primeiraJanelaCompativel < 0)
         primeiraJanelaCompativel = i;
      if(!EstaDentroJanela(g_janelas[i]))
         continue;
      janelaOut = g_janelas[i];
      return true;
   }
   if(InpValidacaoIgnorarJanelaHoraria &&
      InpModoValidacaoExecucao != OPERAR_COMPLETO &&
      primeiraJanelaCompativel >= 0)
   {
      janelaOut = g_janelas[primeiraJanelaCompativel];
      return true;
   }
   return false;
}

bool EstaDentroJanela(RegraJanela &j)
{
   int agora = MinutoAtualDoDia();
   return MinutoDentroJanelaValor(agora, j);
}

bool CalcularWapBandsAoVivoFIX326(double desvios,
                                  double &wap,
                                  double &bandaInferior,
                                  double &bandaSuperior,
                                  double &fechamento)
{
   static datetime barraCache=0;
   static double desviosCache=0.0;
   static double wapCache=0.0,infCache=0.0,supCache=0.0,closeCache=0.0;
   static bool cacheOK=false;
   ENUM_TIMEFRAMES tf=TimeframeFiltroAtualFIX255();
   datetime barraFechada=iTime(_Symbol,tf,1);
   if(barraFechada<=0)
      return false;
   if(cacheOK && barraCache==barraFechada && MathAbs(desviosCache-desvios)<0.0001)
   {
      wap=wapCache;
      bandaInferior=infCache;
      bandaSuperior=supCache;
      fechamento=closeCache;
      return true;
   }
   MqlDateTime dt;
   TimeToStruct(barraFechada,dt);
   dt.hour=0; dt.min=0; dt.sec=0;
   datetime inicioDia=StructToTime(dt);
   int segundosTF=PeriodSeconds(tf);
   if(segundosTF<=0) segundosTF=60;
   MqlRates rates[];
   ArraySetAsSeries(rates,false);
   int copiados=CopyRates(_Symbol,tf,inicioDia,barraFechada+segundosTF-1,rates);
   if(copiados<3)
      return false;
   double somaPV=0.0,somaV=0.0;
   for(int i=0;i<copiados;i++)
   {
      if(rates[i].time>barraFechada) continue;
      double volume=(rates[i].real_volume>0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      if(volume<=0.0) continue;
      double tipico=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      somaPV+=tipico*volume;
      somaV+=volume;
   }
   if(somaV<=0.0)
      return false;
   wap=somaPV/somaV;
   double somaVar=0.0;
   for(int i=0;i<copiados;i++)
   {
      if(rates[i].time>barraFechada) continue;
      double volume=(rates[i].real_volume>0 ? (double)rates[i].real_volume : (double)rates[i].tick_volume);
      if(volume<=0.0) continue;
      double tipico=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      double delta=tipico-wap;
      somaVar+=delta*delta*volume;
   }
   double desvioPadrao=MathSqrt(MathMax(0.0,somaVar/somaV));
   if(desvios<=0.0) desvios=1.0;
   bandaInferior=wap-(desvioPadrao*desvios);
   bandaSuperior=wap+(desvioPadrao*desvios);
   fechamento=iClose(_Symbol,tf,1);
   cacheOK=(fechamento>0.0 && bandaSuperior>bandaInferior);
   if(!cacheOK)
      return false;
   barraCache=barraFechada;
   desviosCache=desvios;
   wapCache=wap;
   infCache=bandaInferior;
   supCache=bandaSuperior;
   closeCache=fechamento;
   return true;
}

bool WapBandsPermiteLadoFIX326(ENUM_LADO_ROBO lado,double desvios,string &detalhe)
{
   double wap=0.0,inf=0.0,sup=0.0,fechamento=0.0;
   if(!CalcularWapBandsAoVivoFIX326(desvios,wap,inf,sup,fechamento))
   {
      detalhe="SEM_DADOS";
      return false;
   }
   bool ok=(lado==LADO_COMPRA ? fechamento<=inf : (lado==LADO_VENDA ? fechamento>=sup : false));
   detalhe=StringFormat("C=%.0f W=%.0f B=%.0f/%.0f",fechamento,wap,inf,sup);
   return ok;
}

bool FiboPermiteLadoFIX326(ENUM_LADO_ROBO lado,double minimo,string &detalhe)
{
   double nivel=0.0,extATR=0.0,extEstrutural=0.0;
   CalcularFiboExaustaoContraFIX269(1,lado,nivel,extATR,extEstrutural);
   detalhe=StringFormat("N=%.3f ATR=%.2f EST=%.2f",nivel,extATR,extEstrutural);
   return (nivel+0.0001>=minimo);
}

bool ValidarFiltros(RegraFiltros &f, ENUM_LADO_ROBO lado)
{
   if(f.configuracaoInvalida)
      return false;
   // FIX302: filtros somente podem liberar sinais no horario configurado.
   if(!HorarioCompactoPermitidoAgora(InpHorariosFiltros))
      return false;
   int total = 0;
   int ok = 0;
   string motivoM25 = "";
   if(f.usarMedia25Direcional)
   {
      total++;
      if(Media25PermiteLado(lado,motivoM25))
         ok++;
   }
   if(f.usarScore)
   {
      total++;
      double scoreLado = ScoreDirecionalDoLado(lado);
      if(scoreLado >= f.scoreMin)
         ok++;
   }
   if(InpValidacaoLiberarFiltrosEntradaAumento)
      return true;
   if(f.usarHilo8)
   {
      total++;
      if((lado == LADO_COMPRA && g_mercado.hiloCompra) || (lado == LADO_VENDA && g_mercado.hiloVenda))
         ok++;
   }
   if(f.usarSTR)
   {
      total++;
      if((lado == LADO_COMPRA && g_mercado.strCompra) || (lado == LADO_VENDA && g_mercado.strVenda))
         ok++;
   }
   if(f.usarDX)
   {
      total++;
      if(ValidarComparacao(g_mercado.dx, f.dxOp, f.dxMin))
         ok++;
   }
   if(f.usarRSI)
   {
      total++;
      if(lado == LADO_COMPRA && ValidarComparacao(g_mercado.rsi, f.rsiCompraOp, f.rsiCompraMin))
         ok++;
      else if(lado == LADO_VENDA && ValidarComparacao(g_mercado.rsi, f.rsiVendaOp, f.rsiVendaMax))
         ok++;
   }
   if(f.volumeCombinado)
   {
      total++;
      double limiteVolQ = LimiteVolumeQtdDinamico(f);
      double limiteVolF = LimiteVolumeFinDinamico(f);
      bool volumeQtdOK = ValidarComparacao(g_mercado.volqProjetadoHora, f.volqOp, limiteVolQ);
      bool volumeFinOK = ValidarComparacao(g_mercado.volfProjetadoHora, f.volfOp, limiteVolF);
      if(volumeQtdOK && volumeFinOK)
         ok++;
   }
   else
   {
      if(f.usarVOLQ)
      {
         total++;
         double limiteVolQ = LimiteVolumeQtdDinamico(f);
         if(ValidarComparacao(g_mercado.volqProjetadoHora, f.volqOp, limiteVolQ))
            ok++;
      }
      if(f.usarVOLF)
      {
         total++;
         double limiteVolF = LimiteVolumeFinDinamico(f);
         if(ValidarComparacao(g_mercado.volfProjetadoHora, f.volfOp, limiteVolF))
            ok++;
      }
   }
   if(f.usarAGR)
   {
      total++;
      double agrDirecional = AgressaoDirecionalPercentual(lado);
      if(ValidarComparacao(agrDirecional, f.agrOp, f.agrMin))
         ok++;
   }
   if(f.usarForca)
   {
      total++;
      if(g_mercado.scoreFluxo>=f.forcaMin)
         ok++;
   }
   if(f.usarFibo)
   {
      total++;
      string detalheFibo="";
      if(FiboPermiteLadoFIX326(lado,f.fiboMin,detalheFibo))
         ok++;
   }
   if(f.usarWapBands)
   {
      total++;
      string detalheWap="";
      if(WapBandsPermiteLadoFIX326(lado,f.wapBandDesvios,detalheWap))
         ok++;
   }
   if(total == 0)
      return true;
   if(f.modo == "TODOS")
      return (ok == total);
   return (ok >= f.minOk);
}

bool ValidarComparacao(double valor, string op, double limite)
{
   op = Trim(op);
   if(op == ">=")
      return (valor >= limite);
   if(op == "<=")
      return (valor <= limite);
   if(op == ">")
      return (valor > limite);
   if(op == "<")
      return (valor < limite);
   if(op == "==")
      return (MathAbs(valor - limite) < 0.0000001);
   return (valor >= limite);
}

double Media25FiltroValor(int shift)
{
   int periodo = PeriodoMediaGraficoEfetivo();
   int h = iMA(_Symbol, TimeframeFiltroAtualFIX255(), periodo, 0, InpMedia25MetodoGrafico, InpMedia25PrecoGrafico);
   if(h == INVALID_HANDLE)
      return 0.0;
   double buf[];
   ArraySetAsSeries(buf, true);
   int lidos = CopyBuffer(h, 0, shift, 1, buf);
   IndicatorRelease(h);
   if(lidos <= 0)
      return 0.0;
   return buf[0];
}

ENUM_LADO_ROBO DirecaoMedia25Operacional()
{
   int shift = InpUsarCandleFiltroFechado ? 1 : 0;
   double media0 = Media25FiltroValor(shift);
   double media3 = Media25FiltroValor(shift + 3);
   double open0  = iOpen(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close0 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift);
   double close1 = iClose(_Symbol, TimeframeFiltroAtualFIX255(), shift + 1);
   if(media0 <= 0.0 || media3 <= 0.0 || open0 <= 0.0 || close0 <= 0.0 || close1 <= 0.0)
      return LADO_NENHUM;
   bool mediaSubindo = (media0 >= media3);
   bool mediaCaindo  = (media0 <= media3);
   bool candleCompra = (close0 > open0 && close0 >= close1);
   bool candleVenda  = (close0 < open0 && close0 <= close1);
   if(close0 > media0 && mediaSubindo && candleCompra)
      return LADO_COMPRA;
   if(close0 < media0 && mediaCaindo && candleVenda)
      return LADO_VENDA;
   return LADO_NENHUM;
}

string TextoDirecaoMedia25()
{
   string rotulo = "M" + IntegerToString(PeriodoMediaGraficoEfetivo());
   ENUM_LADO_ROBO d = DirecaoMedia25Operacional();
   if(d == LADO_COMPRA)
      return rotulo + " COMPRA";
   if(d == LADO_VENDA)
      return rotulo + " VENDA";
   return rotulo + " NEUTRA";
}

bool Media25PermiteLado(ENUM_LADO_ROBO lado, string &motivo)
{
   if(InpTesteHardPermitirContraM25)
   {
      motivo = "TESTE HARD: M25 liberada para validar os dois sentidos.";
      return true;
   }
   ENUM_LADO_ROBO direcao = DirecaoMedia25Operacional();
   if(lado == LADO_AMBOS || lado == LADO_NENHUM)
      return true;
   if(direcao == LADO_NENHUM)
   {
      motivo = "Bloqueado: M25 sem direcao confirmada.";
      return false;
   }
   if(direcao == lado)
      return true;
   motivo = StringFormat("Bloqueado: %s contra %s.", NomeLado(lado), TextoDirecaoMedia25());
   return false;
}

double ScoreDirecionalDoLado(ENUM_LADO_ROBO lado)
{
   double score = g_mercado.scoreFluxo;
   ENUM_LADO_ROBO direcao = DirecaoMedia25Operacional();
   if(direcao == lado)
      score += 15.0;
   else if(direcao != LADO_NENHUM && lado != LADO_AMBOS && lado != LADO_NENHUM)
      score -= 40.0;
   if(lado == LADO_COMPRA && g_mercado.rsi < 45.0)
      score -= 10.0;
   if(lado == LADO_VENDA && g_mercado.rsi > 55.0)
      score -= 10.0;
   if(score < 0.0)
      score = 0.0;
   if(score > 100.0)
      score = 100.0;
   return score;
}

bool TipoOperacaoPermiteLado(ENUM_LADO_ROBO lado)
{
   if(!InstanciaGerenciaLadoFIX255(lado))
      return false;
   if(InpHeadForcarEntradaOpostaGrupo && InpHeadOpostoIgnoraTipoOperacao)
   {
      if(LadoObrigatorioOpostoGrupoHead(lado))
         return true;
      if(LadoBloqueadoPorOpostoGrupoHead(lado))
         return false;
   }
   if(InpTipoOperacao == OPERACAO_COMPRA)
      return (lado == LADO_COMPRA);
   if(InpTipoOperacao == OPERACAO_VENDA)
      return (lado == LADO_VENDA);
   if(InpTipoOperacao == OPERACAO_AMBOS)
      return (lado == LADO_COMPRA || lado == LADO_VENDA);
   return false;
}

string TextoTipoOperacaoParametro()
{
   if(InpTipoOperacao == OPERACAO_COMPRA)
      return "TIPO: COMPRA";
   if(InpTipoOperacao == OPERACAO_VENDA)
      return "TIPO: VENDA";
   if(InpTipoOperacao == OPERACAO_AMBOS)
      return "TIPO: AMBOS";
   return "TIPO: INVALIDO";
}


// ============================================================================
// RESPONSABILIDADE: COORDENACAO DO GERENCIAMENTO POR LADO
// ============================================================================

void GerenciarLado(ENUM_LADO_ROBO lado)
{
   if(!InstanciaGerenciaLadoFIX255(lado))
      return;
   if(lado == LADO_COMPRA)
   {
      GerenciarEstadoLado(g_compra);
      return;
   }
   if(lado == LADO_VENDA)
   {
      GerenciarEstadoLado(g_venda);
      return;
   }
}

void GerenciarEstadoLado(EstadoLado &estado)
{
   if(!estado.posicaoAberta && ControleBloqueiaMagicFIX285(estado.magic))
   {
      estado.ultimaMensagem = "FIX285 " + TextoControleMagicFIX285(estado.magic) + ": A0 bloqueada; gerenciamento de saida permanece ativo.";
      return;
   }
   if(!estado.posicaoAberta)
   {
      if(!TipoOperacaoPermiteLado(estado.lado))
      {
         RegistrarDecisaoOperacional(estado, "A0", "Entrada bloqueada pelo InpTipoOperacao: " + TextoTipoOperacaoParametro());
         return;
      }
      if(!LadoPermitidoPelaSelecaoHead(estado.lado))
      {
         RegistrarDecisaoOperacional(estado, "HEAD", "Entrada bloqueada pelo seletor HEAD: " + TextoSelecaoHead());
         return;
      }
   }
   // FIX380: no modo simples, ProcessarGerenciamentoSimplesFIX195 ja controla
   // alvo, perda e trailing 20/5. Nao executar o gerenciador legado uma segunda vez.
   if(!InpModoSimplesFIX195 && GerenciarProtecaoLado(estado))
      return;
   if(!estado.posicaoAberta)
   {
      if(PrimeiraOrdemDesligadaFIX314())
      {
         RegistrarDecisaoOperacional(estado,"A0","Primeira ordem desligada nos parâmetros.");
         return;
      }
      if(InpGerenciadorOrdensExperts)
      {
         RegistrarGerenciadorOrdens(estado,
                                    "A0_CHECK",
                                    StringFormat("Checando A0 | lado=%s | DX=%.1f | HiloC=%s HiloV=%s | Score=%.1f | Magic=%d",
                                                 estado.lado == LADO_COMPRA ? "BUY" : "SELL",
                                                 g_mercado.dx,
                                                 g_mercado.hiloCompra ? "ON" : "OFF",
                                                 g_mercado.hiloVenda ? "ON" : "OFF",
                                                 g_mercado.scoreFluxo,
                                                 estado.magic),
                                    0, 0, 0.0, 0.0, false);
      }
      if(!PermitirEntradaA0PeloModoValidacao(estado))
         return;

      // FIX275: quando uma ponta estiver ausente, a outra janela recompõe o par A+B.
      // A ponta faltante respeita a escolha feita para COMPRA ou VENDA e a pausa após uma saída.
      bool entradaOpostaObrigatoriaFIX257 = LadoObrigatorioOpostoGrupoHead(estado.lado);

      // Cada lado possui sua própria escolha: LIVRE, A FAVOR, CONTRA ou AMBOS.
      // No padrão LIVRE, as entradas de teste continuam exatamente como antes.
      string motivoModoA0FIX310 = "";
      if(!ModoEntradaA0PermiteFIX310(estado,motivoModoA0FIX310))
      {
         RegistrarDecisaoOperacional(estado,"MODO_ENTRADA",motivoModoA0FIX310);
         return;
      }
      RegistrarDecisaoOperacional(estado,"MODO_ENTRADA_OK",motivoModoA0FIX310);

      // FIX362: sem posição deste lado, A0 fica livre de saldo histórico,
      // meta antiga e stop de ciclo já encerrado. Segurança real permanece abaixo.
      if(!ExistePosicaoAbertaGrupoTotalAB())
      {
         g_mestre.bloqueadoPorMeta=false;
         g_mestre.bloqueadoPorStop=false;
      }

      RegraJanela janela;
      bool janelaAtivaA0=ExisteJanelaAtivaParaLado(estado.lado, janela);
      if(!janelaAtivaA0 && InpFIX278UmaJanelaAbreDuasPontas && JanelaAtualEhA_FIX255())
      {
         // FIX278: janela virtual imediata para validar toda a operacao.
         ZeroMemory(janela);
         janela.ativa=true;
         janela.qtd=InpEntradaContratos;
         janela.horario="FIX278 IMEDIATO";
         janelaAtivaA0=true;
      }
      if(!janelaAtivaA0)
      {
         RegistrarDecisaoOperacional(estado, "A0", "Sem janela ativa. Verifique horario do servidor, InpValidacaoIgnorarJanelaHoraria e matriz J1-J5.");
         return;
      }
      bool a0TesteLivre = EntradaDiretaDemoEfetivaFIX302();
      if(!a0TesteLivre && !(entradaOpostaObrigatoriaFIX257 && InpHeadOpostoIgnoraSTFTFIX257) && !STFTPermiteNovaEntrada(estado))
         return;
      bool pontaContrariaAberta = ExistePontaContrariaAberta(estado.lado);
      string motivoHedge = "";
      bool hedgeRecuperacao = false;
      if(!InpGestaoCadaMagicVidaPropria)
         hedgeRecuperacao = PermitirEntradaHedgeRecuperacao(estado, motivoHedge);
      if(!hedgeRecuperacao && BloquearA0OutraPontaAutomatica(estado))
         return;
      if(InpGestaoCadaMagicVidaPropria && pontaContrariaAberta && !InpPermitirOutraPontaSeDirecionalFavor)
      {
         RegistrarDecisaoOperacional(estado, "A0", "Entrada bloqueada: ja existe ponta contraria aberta. A0 oposto automatico desligado no FIX103.");
         return;
      }
      if(InpUmaPontaPorTimeframe && pontaContrariaAberta && !hedgeRecuperacao && !InpPermitirOutraPontaSeDirecionalFavor)
      {
         RegistrarDecisaoOperacional(estado, "A0", "Entrada bloqueada: ponta contraria aberta no mesmo timeframe.");
         return;
      }
      if(ExisteMesmoSentidoOutroMagicMesmoTF(estado))
      {
         RegistrarDecisaoOperacional(estado, "A0",
                                     "Entrada bloqueada: já existe posição do mesmo sentido no próprio Magic local.");
         return;
      }
      bool liberarFiltrosOpostoFIX257 = (entradaOpostaObrigatoriaFIX257 && InpHeadOpostoIgnoraFiltrosA0FIX257);
      bool filtrosOk = a0TesteLivre || liberarFiltrosOpostoFIX257 || ValidarFiltros(janela.filtros, estado.lado);
      bool filtrosLiberamA0 = (filtrosOk || (hedgeRecuperacao && !InpHedgeExigirFiltroEntrada));
      string motivoFiltroA0 = a0TesteLivre
                              ? "A0_TESTE_LIVRE"
                              : (liberarFiltrosOpostoFIX257
                                 ? "FIX257_COMPLETA_PAR_AB"
                                 : (hedgeRecuperacao && !InpHedgeExigirFiltroEntrada
                                    ? "HEDGE_REC_SEM_EXIGIR_FILTRO"
                                    : (filtrosOk ? "FILTROS_OK" : "FILTROS_BLOQUEARAM")));
      RegistrarLogEntradaFiltros(estado, "FILTRO_ENTRADA_A0", "A0", janela.filtros, filtrosLiberamA0, motivoFiltroA0, true);
      if(!filtrosOk && !(hedgeRecuperacao && !InpHedgeExigirFiltroEntrada))
      {
         RegistrarDecisaoOperacional(estado, "A0", "Entrada A0 bloqueada por filtros ST/FT da matriz.");
         return;
      }
      if(a0TesteLivre)
         RegistrarDecisaoOperacional(estado, "A0_TESTE", "A0 LIVRE COM PROTEÇÕES: filtros de sinal ignorados; horário, candle novo, pausa, Magic, posição e proteção de repetição continuam obrigatórios.");
      else if(liberarFiltrosOpostoFIX257)
         RegistrarDecisaoOperacional(estado, "FIX278_HEAD_LIVRE", "Ponta faltante liberada para recompor 1 COMPRA + 1 VENDA; A0 de teste esta sem filtro.");
      else if(hedgeRecuperacao)
         RegistrarDecisaoOperacional(estado, "HEDGE_REC", motivoHedge);
      if(InpDXAdaptativoAtivoFIX410 && InpDXUsarA0FIX411)
      {
         string detalheDXA0FIX411="";
         if(!DXAdaptativoAutorizaFIX411(estado.lado,false,-1,detalheDXA0FIX411))
         {
            RegistrarDecisaoOperacional(estado,"FIX411_DX_A0_BLOQUEOU",detalheDXA0FIX411);
            RegistrarLogEntradaFiltros(estado,"FIX411_DX_A0","A0",janela.filtros,false,detalheDXA0FIX411,true);
            return;
         }
         RegistrarLogEntradaFiltros(estado,"FIX411_DX_A0","A0",janela.filtros,true,detalheDXA0FIX411,true);
      }
      bool entradaA0EnviadaFIX417=ExecutarEntradaA0(estado, janela);
      if(entradaA0EnviadaFIX417 && InpDXAdaptativoAtivoFIX410 && InpDXUsarA0FIX411)
         ConsumirSinalDXAposOrdemFIX417(estado.lado,false,-1);
      return;
   }
   if(ControleBloqueiaMagicFIX285(estado.magic))
   {
      estado.motivoBloqueioAumento = "FIX285 " + TextoControleMagicFIX285(estado.magic) + ": aumentos bloqueados; trailing, alvo, stop e parciais continuam.";
      estado.ultimaMensagem = estado.motivoBloqueioAumento;
      return;
   }

   // FIX302: A1-A5 possuem horario independente do A0 e do horario dos filtros.
   if(!HorarioCompactoPermitidoAgora(InpHorariosAumentos))
   {
      estado.motivoBloqueioAumento="AUMENTOS FORA DO HORARIO CONFIGURADO.";
      RegistrarDecisaoOperacional(estado,"FIX292_HORARIO_AUMENTOS",estado.motivoBloqueioAumento);
      return;
   }

   // FIX238: escolhe somente o proximo nivel sequencial; cada tick recalcula o score desse nivel.
   int idxAlvo=ProximoIndiceAumentoSequencialFIX218(estado);
   if(idxAlvo<0 || idxAlvo>=ArraySize(g_aumentos) || idxAlvo>=g_gerAumentos.maxAumentos)
   {
      estado.motivoBloqueioAumento="FIX224: todos os aumentos ativos deste ciclo ja foram usados.";
      RegistrarDecisaoOperacional(estado,"AUMENTO",estado.motivoBloqueioAumento);
      return;
   }
   if(!PermitirAumentoPeloModoValidacao(estado,idxAlvo))
      return;

   // FIX250: ambos os modos respeitam timer -> linha -> confirmacao. A decisao final usa filtros OU score.
   bool timerOk=TimerAumentoLiberado(estado,g_aumentos[idxAlvo],idxAlvo);
   if(!timerOk)
   {
      estado.motivoBloqueioAumento=StringFormat("A%d AGUARDA TIMER.",idxAlvo+1);
      RegistrarDecisaoOperacional(estado,"FIX224_TIMER_AGUARDA",estado.motivoBloqueioAumento);
      return;
   }

   double linhaAumento=PrecoNivelAumentoValorIndice(estado,idxAlvo);
   string statusCruzamentoFIX248="";
   if(!NovoCruzamentoLiberadoFIX248(estado,idxAlvo+1,linhaAumento,statusCruzamentoFIX248))
   {
      estado.motivoBloqueioAumento=statusCruzamentoFIX248;
      RegistrarDecisaoOperacional(estado,"FIX248_AGUARDA_NOVO_CRUZAMENTO",estado.motivoBloqueioAumento);
      return;
   }
   string statusCandle="";
   bool candleOk=ConfirmarFechamentoCandleAumentoFIX224(estado,idxAlvo,linhaAumento,statusCandle);
   if(!candleOk)
   {
      estado.motivoBloqueioAumento=StringFormat("A%d TIMER OK | %s.",idxAlvo+1,statusCandle);
      RegistrarDecisaoOperacional(estado,"FIX224_CANDLE_AGUARDA",estado.motivoBloqueioAumento);
      return;
   }

   bool podeAumentar=PodeExecutarAumento(estado,g_aumentos[idxAlvo],idxAlvo);
   if(!podeAumentar)
   {
      if(estado.motivoBloqueioAumento=="")
         estado.motivoBloqueioAumento=StringFormat("A%d TIMER OK | LINHA OK | CANDLE OK | AGUARDA %s/LIMITES.",
                                                   idxAlvo+1, ModoAumentoSomenteScore() ? "SCORE" : "FILTROS");
      RegistrarDecisaoOperacional(estado,
                                  ModoAumentoSomenteScore() ? "FIX250_SCORE_BLOQUEOU" : "FIX224_FILTROS_BLOQUEARAM",
                                  estado.motivoBloqueioAumento);
      return;
   }

   string statusFinalFIX363="";
   if(!ValidarAumentoFinalAntesEnvioFIX363(estado,idxAlvo,linhaAumento,statusFinalFIX363))
   {
      estado.motivoBloqueioAumento=StringFormat("A%d BLOQUEADO ANTES DO ENVIO | %s",idxAlvo+1,statusFinalFIX363);
      RegistrarDecisaoOperacional(estado,"FIX363_PRECO_FINAL_BLOQUEOU",estado.motivoBloqueioAumento);
      return;
   }

   // FIX417: DX e o ultimo filtro antes do envio. Nao e consumido enquanto qualquer filtro/preco/risco bloquear.
   if(InpDXAdaptativoAtivoFIX410 && InpDXUsarAumentosFIX411)
   {
      string detalheDXAumFIX411="";
      if(!DXAdaptativoAutorizaFIX411(estado.lado,true,idxAlvo,detalheDXAumFIX411))
      {
         estado.motivoBloqueioAumento=StringFormat("A%d DX BLOQUEOU | %s",idxAlvo+1,detalheDXAumFIX411);
         RegistrarDecisaoOperacional(estado,"FIX417_DX_AUMENTO_BLOQUEOU",estado.motivoBloqueioAumento);
         RegistrarLogEntradaFiltros(estado,"FIX417_DX_AUMENTO","AUMENTO",g_aumentos[idxAlvo].filtros,false,detalheDXAumFIX411,true);
         return;
      }
      RegistrarLogEntradaFiltros(estado,"FIX417_DX_AUMENTO","AUMENTO",g_aumentos[idxAlvo].filtros,true,detalheDXAumFIX411,true);
   }

   bool modoScore = ModoAumentoSomenteScore();
   string liberado = "";
   string contexto = "";
   if(modoScore)
   {
      string detalheScoreFinal = "";
      double scoreFinal = CalcularScoreAumentoDedicado(LadoDaPosicaoAtual(estado), detalheScoreFinal);
      liberado = StringFormat("A%d SCORE | TIMER OK | LINHA OK | CANDLE OK | %.1f/%.1f | ENTRANDO +%.0f CONTRATO | %s",
                              idxAlvo+1, scoreFinal, MinimoScoreAumentoNivel(idxAlvo), g_aumentos[idxAlvo].qtd, detalheScoreFinal);
      contexto = StringFormat("A%d_TRIGGER_SCORE_FIX250",idxAlvo+1);
   }
   else
   {
      string modo=InpAumentosLivreTeste ? "FILTROS LIVRES" : "FILTROS OK";
      liberado=StringFormat("A%d REGRA | TIMER OK | LINHA OK | CANDLE OK | %s | ENTRANDO +%.0f CONTRATO",
                            idxAlvo+1,modo,g_aumentos[idxAlvo].qtd);
      contexto=StringFormat("A%d_TRIGGER_FIX250",idxAlvo+1);
   }
   estado.motivoBloqueioAumento=liberado;
   RegistrarGerenciadorOrdens(estado,contexto,liberado,0,0,g_aumentos[idxAlvo].qtd,0.0,true);
   bool aumentoEnviadoFIX250=ExecutarAumento(estado,g_aumentos[idxAlvo],idxAlvo+1);
   if(aumentoEnviadoFIX250)
   {
      if(InpDXAdaptativoAtivoFIX410 && InpDXUsarAumentosFIX411)
         ConsumirSinalDXAposOrdemFIX417(estado.lado,true,idxAlvo);
      LimparConfirmacaoCandleAumentoFIX224(estado,idxAlvo);
      if(modoScore)
      {
         int proximoNivelScore = idxAlvo + 2;
         if(proximoNivelScore <= g_gerAumentos.maxAumentos && proximoNivelScore <= ArraySize(g_aumentos))
            estado.motivoBloqueioAumento = StringFormat("A%d executado; A%d aguardara nova linha, novo timer e NOVO score.",
                                                        idxAlvo + 1, proximoNivelScore);
         else
            estado.motivoBloqueioAumento = StringFormat("A%d executado; ultimo nivel configurado concluido.", idxAlvo + 1);
         RegistrarDecisaoOperacional(estado, "FIX250_SCORE_REAVALIAR_PROXIMO_NIVEL", estado.motivoBloqueioAumento);
      }
   }
   return;
}


#endif // COPA_FILTROS_OPERACIONAIS_MQH
