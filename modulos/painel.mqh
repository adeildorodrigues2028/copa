// COPA V11 - Etapa 11: painel, cards e plotagem visual.
#ifndef COPA_V11_MODULOS_PAINEL_MQH
#define COPA_V11_MODULOS_PAINEL_MQH

void AtualizarPainelMestre()
{
   // FIX353: o painel nunca depende de uma leitura antiga feita por outra rotina.
   // Antes de desenhar, relê posições, histórico do DIA e risco diretamente.
   g_ultimaAtualizacaoEstadosMsFIX287=0;
   AtualizarEstadosDePosicao();
   AtualizarHistoricoObrigatorio();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AtualizarPainelGrafico();
   if(InpPainelVisualDesligarComment && g_modoPainelVisualAtivo != PAINEL_VISUAL_OFF)
   {
      Comment("");
      return;
   }
   if(!InpMostrarPainel)
   {
      Comment("");
      return;
   }
   string p = "";
   p += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
   p += "COPA / AR_100  |  COMMIT 01\n";
   p += "Monolitico | Parametros + Parser + Painel\n";
   p += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
   if(InpMostrarAmbiente)
   {
      p += StringFormat("Ambiente: %s\n", g_mestre.mensagemAmbiente);
      p += StringFormat("Demo: %s | Hedge: %s | Ordens: %s\n",
                        g_contaDemo ? "SIM" : "NAO",
                        g_contaHedge ? "SIM" : "NAO",
                        InpPermitirEnvioOrdens ? "LIBERADAS" : "TRAVADAS");
      p += StringFormat("Auditoria de producao: %s\n",g_auditoriaProducaoStatusFIX342);
      p += "\n";
   }
   if(InpMostrarScoreFluxo)
   {
      p += StringFormat("Mercado: DX=%.2f | RSI=%.2f | VOLQ=%.0f | VOLF=%.0f | AGR=%.2f\n",
                        g_mercado.dx,
                        g_mercado.rsi,
                        g_mercado.volq,
                        g_mercado.volf,
                        g_mercado.agr);
      p += StringFormat("Score Fluxo: %.2f | Status: %s\n\n",
                        g_mercado.scoreFluxo,
                        NomeStatusMercado(g_mercado.status));
   }
   if(InpMostrarPontaCompra)
      p += LinhaEstadoLado(g_compra) + "\n";
   if(InpMostrarPontaVenda)
      p += LinhaEstadoLado(g_venda) + "\n";
   if(InpMostrarMestre)
   {
      p += "MESTRE\n";
      p += StringFormat("Aberto Total: R$ %.2f | Dia Total: R$ %.2f\n",
                        g_mestre.resultadoAbertoTotal,
                        g_mestre.resultadoDiaTotal);
      p += StringFormat("Operacao: ganho R$ %.2f | perda R$ %.2f | aumento alvo R$ %.2f (trail %.0f/%.0f)\n",
                        MathAbs(InpEntradaGanhoAlvoReais),
                        MathAbs(InpEntradaPerdaMaximaReais),
                        MathAbs(InpLucroAumentoPorContratoReaisFIX207),
                        MathAbs(InpTrailingAumentoAtivarReaisFIX281),
                        MathAbs(InpTrailingAumentoPassoReaisFIX281));
      p += TextoStatusFimDiaFIX215() + "\n\n";
   }
   if(InpMostrarHistorico)
   {
      p += "HISTORICO OBRIGATORIO\n";
      p += "Periodo | Compras/Vendas | Qtd | Financeiro | % Conta | Parcial | Lucro Total\n";
      p += LinhaHistoricoPeriodo(g_histDia) + "\n";
      p += LinhaHistoricoPeriodo(g_histOntem) + "\n";
      p += LinhaHistoricoPeriodo(g_hist7Dias) + "\n";
      p += LinhaHistoricoPeriodo(g_hist15Dias) + "\n";
      p += LinhaHistoricoPeriodo(g_hist30Dias) + "\n";
      p += LinhaHistoricoPeriodo(g_histTudo) + "\n\n";
   }
   if(InpMostrarGerenciadorAumento)
   {
      p += "GERENCIADOR DE AUMENTOS\n";
      p += StringFormat("Ativo: %s | Modo: %s | Max Aum: %d | Max Contratos: %d\n",
                        g_gerAumentos.ativo ? "SIM" : "NAO",
                        g_gerAumentos.modo,
                        g_gerAumentos.maxAumentos,
                        g_gerAumentos.maxContratos);
      p += StringFormat("Score Normal Max: %.0f | Forte Max: %.0f | Extremo: %.0f\n\n",
                        g_gerAumentos.scoreNormalMax,
                        g_gerAumentos.scoreForteMax,
                        g_gerAumentos.scoreExtremo);
   }
   if(InpMostrarMatrizJanelas)
   {
      p += "MATRIZ 01 - JANELAS\n";
      for(int i = 0; i < 5; i++)
         p += LinhaJanela(g_janelas[i], i + 1) + "\n";
      p += "\n";
   }
   if(InpMostrarMatrizAumentos)
   {
      p += "MATRIZ 02 - AUMENTOS\n";
      for(int i = 0; i < 5; i++)
         p += LinhaAumento(g_aumentos[i], i + 1) + "\n";
      p += "\n";
   }
   if(InpMostrarMatrizRisco)
   {
      p += "MATRIZ 03 - RISCO / PROTECAO\n";
      p += StringFormat("Meta Op: R$ %.2f | Stop Op: R$ %.2f | Valor Prot: R$ %.2f\n",
                        g_risco.metaOperacao,
                        g_risco.stopOperacao,
                        g_risco.valorProtecao);
      p += StringFormat("Defesa ativa em: R$ %.2f | Longa ativa em: R$ %.2f | Nao virar prejuizo: %s\n\n",
                        g_risco.defesaAtivaEm,
                        g_risco.ativaLongaEm,
                        g_risco.naoVirarPrejuizo ? "SIM" : "NAO");
   }
   if(InpMostrarLog)
   {
      p += "LOG\n";
      p += g_mestre.mensagemGeral + "\n";
   }
   Comment(p);
}

bool PainelObjetoAutoFitFIX319(string nome)
{
   return (StringFind(nome,"COPA_AR100_CARD_")==0 ||
           StringFind(nome,"COPA_AR100_CARD_RED_")==0 ||
           StringFind(nome,"COPA_AR100_CARD_SLIM_")==0);
}

void PainelDesativarAutoFitFIX319()
{
   g_painelAutoFitFIX319=false;
   g_painelEscalaXFIX319=1.0;
   g_painelEscalaYFIX319=1.0;
}

void PainelConfigurarAutoFitFIX319(int baseX,int baseY,int baseW,int baseH,
                                   int &x,int &y,int &largura,int &altura)
{
   int chartW=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   int margem=6;
   if(baseW<320) baseW=320;
   if(baseH<120) baseH=120;
   if(chartW<=0) chartW=baseX+baseW+margem;
   if(chartH<=0) chartH=baseY+baseH+margem;

   int realX=baseX;
   int realY=baseY;
   if(realX<2) realX=2;
   if(realY<2) realY=2;
   if(realX>chartW-80) realX=2;
   if(realY>chartH-60) realY=2;

   int disponivelW=chartW-realX-margem;
   int disponivelH=chartH-realY-margem;
   // Nunca inventar uma area maior que o grafico. Os antigos minimos de
   // 240x120 podiam empurrar objetos para fora da borda em janelas pequenas.
   if(disponivelW<1) disponivelW=1;
   if(disponivelH<1) disponivelH=1;

   g_painelAutoFitFIX319=true;
   g_painelBaseXFIX319=baseX;
   g_painelBaseYFIX319=baseY;
   g_painelRealXFIX319=realX;
   g_painelRealYFIX319=realY;
   g_painelBaseWFIX319=baseW;
   g_painelBaseHFIX319=baseH;
   // Largura e altura ocupam a area real disponivel. Isso preserva a leitura
   // quando a Caixa de Ferramentas reduz muito a altura do grafico.
   double escalaW=(double)disponivelW/(double)baseW;
   double escalaH=(double)disponivelH/(double)baseH;
   if(escalaW<=0.0) escalaW=0.01;
   if(escalaH<=0.0) escalaH=0.01;
   // A mesma escala nos dois eixos evita painel largo e colunas esticadas.
   double escalaFinal=MathMin(1.0,MathMin(escalaW,escalaH));
   g_painelEscalaXFIX319=escalaFinal;
   g_painelEscalaYFIX319=escalaFinal;

   // As rotinas continuam trabalhando em coordenadas lógicas. A conversão
   // para os pixels reais acontece somente nos criadores de objetos.
   x=baseX;
   y=baseY;
   largura=baseW;
   altura=baseH;
}

void PainelPrepararCompletoAutoFitFIX319(int &x,int &y,int &largura,int &altura)
{
   int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   int baseW=InpPainelCardLargura;
   if(baseW<1180) baseW=1180;
   // Limite visual fino: conserva toda a grade, mas evita o painel excessivamente largo.
   if(baseW>1180) baseW=1180;
   int baseH=InpPainelCardAltura;
   // Em gráficos baixos usa a mesma composição completa em uma grade lógica
   // compacta. Depois a grade é encaixada exatamente na altura disponível.
   if(chartH>0 && chartH<900) baseH=760;
   if(baseH<760) baseH=760;
   if(baseH>960) baseH=960;
   PainelConfigurarAutoFitFIX319(InpPainelCardX,InpPainelCardY,baseW,baseH,x,y,largura,altura);
}

int PainelAutoXFIX319(string nome,int x)
{
   if(!g_painelAutoFitFIX319 || !PainelObjetoAutoFitFIX319(nome)) return x;
   return g_painelRealXFIX319+(int)MathRound((double)(x-g_painelBaseXFIX319)*g_painelEscalaXFIX319);
}

int PainelAutoYFIX319(string nome,int y)
{
   if(!g_painelAutoFitFIX319 || !PainelObjetoAutoFitFIX319(nome)) return y;
   return g_painelRealYFIX319+(int)MathRound((double)(y-g_painelBaseYFIX319)*g_painelEscalaYFIX319);
}

int PainelAutoWFIX319(string nome,int largura)
{
   if(!g_painelAutoFitFIX319 || !PainelObjetoAutoFitFIX319(nome)) return largura;
   int v=(int)MathRound((double)largura*g_painelEscalaXFIX319);
   return (v<1 ? 1 : v);
}

int PainelAutoHFIX319(string nome,int altura)
{
   if(!g_painelAutoFitFIX319 || !PainelObjetoAutoFitFIX319(nome)) return altura;
   int v=(int)MathRound((double)altura*g_painelEscalaYFIX319);
   return (v<1 ? 1 : v);
}

int PainelAutoFonteFIX319(string nome,int fonte)
{
   if(!g_painelAutoFitFIX319 || !PainelObjetoAutoFitFIX319(nome)) return fonte;
   double escala=MathMin(g_painelEscalaXFIX319,g_painelEscalaYFIX319);
   // Não deixa a letra microscópica. O espaçamento vertical continua escalado.
   // Mantem a fonte legivel mesmo com a Caixa de Ferramentas aberta.
   if(escala<0.92) escala=0.92;
   int v=(int)MathRound((double)fonte*escala);
   if(v<7) v=7;
   return v;
}


void AtualizarPainelGrafico()
{
   if(!InpMostrarCardAumentosVisual)
   {
      PainelDesativarAutoFitFIX319();
      LimparPainelGrafico();
      return;
   }
   EstadoLado estadoCard;
   ObterEstadoMotorPainelLocal(estadoCard);
   int px=InpPainelCardX;
   int py=InpPainelCardY;
   int pw=InpPainelCardLargura;
   int ph=InpPainelCardAltura;
   int chartW=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   // O painel completo possui muita informacao para duas janelas lado a
   // lado. Nesse caso usamos a composicao premium compacta, sem esmagar
   // fontes. Ao maximizar o grafico, o FULL retorna automaticamente.
   // Mantem o desenho escolhido pelo usuario; o FULL nao e trocado por
   // outro painel quando a janela muda de tamanho.
   g_painelCompactoAutomaticoFIX320=false;
   int layoutAtualFIX320=0;
   if(g_modoPainelVisualAtivo==PAINEL_VISUAL_COMPLETO && !g_painelCompactoAutomaticoFIX320)
      layoutAtualFIX320=2;
   else if(g_modoPainelVisualAtivo==PAINEL_VISUAL_SLIM)
      layoutAtualFIX320=3;
   else if(g_modoPainelVisualAtivo==PAINEL_VISUAL_REDUZIDO || g_painelCompactoAutomaticoFIX320)
      layoutAtualFIX320=1;
   if(layoutAtualFIX320!=g_painelLayoutResponsivoFIX320)
   {
      LimparSomentePainelVisual();
      g_painelLayoutResponsivoFIX320=layoutAtualFIX320;
   }

   // FIX319: cada modo recebe uma grade lógica e é convertido para o tamanho
   // real do gráfico. Nenhum bloco pode ultrapassar a borda direita ou inferior.
   if(g_modoPainelVisualAtivo==PAINEL_VISUAL_OFF)
   {
      LimparSomentePainelVisual();
      PainelConfigurarAutoFitFIX319(InpPainelCardX,InpPainelCardY,560,34,px,py,pw,ph);
      DesenharBotoesModoPainel("COPA_AR100_CARD_CTRL_",px+198,py,InpPainelFonteTexto);
   }
   else if(g_modoPainelVisualAtivo==PAINEL_VISUAL_REDUZIDO || g_painelCompactoAutomaticoFIX320)
   {
      PainelConfigurarAutoFitFIX319(InpPainelCardX,InpPainelCardY,760,210,px,py,pw,ph);
      DesenharPainelReduzido(px,py,pw,ph);
   }
   else if(g_modoPainelVisualAtivo==PAINEL_VISUAL_COMPLETO)
   {
      PainelPrepararCompletoAutoFitFIX319(px,py,pw,ph);
      DesenharCardAumentos(estadoCard,px,py,pw,ph);
   }
   else
   {
      int baseW=InpPainelSlimLargura;
      int baseH=InpPainelSlimAltura;
      if(baseW<760) baseW=760;
      if(baseH<220) baseH=220;
      PainelConfigurarAutoFitFIX319(InpPainelCardX,InpPainelCardY,baseW,baseH,px,py,pw,ph);
      DesenharPainelSlimDia(px,py,pw,ph);
   }
   AtualizarPlotagemOperacional();
   AtualizarPlotagemDX();
   PainelChartRedrawLeve(false);
}

void LimparSomentePainelVisual()
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, "COPA_AR100_CARD_") == 0 ||
         StringFind(nome, "COPA_AR100_CARD_RED_") == 0 ||
         StringFind(nome, "COPA_AR100_CARD_SLIM_") == 0)
         ObjectDelete(0, nome);
   }
}

void LimparPainelGrafico()
{
   LimparSomentePainelVisual();
   LimparPlotagemOperacional();
   LimparPlotagemDX();
}

void LimparTodosObjetosCOPA()
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      bool ehCandleContraFIX263 = (StringFind(nome, PrefixoCandleContraFIX258()) == 0);
      if(!ehCandleContraFIX263 &&
         (StringFind(nome, "COPA_AR100") >= 0 ||
         StringFind(nome, "DX25_ACIMA_") == 0 ||
         StringFind(nome, "DX25_ABAIXO_") == 0 ||
         StringFind(nome, "DX25_TX_") == 0 ||
         StringFind(nome, "C_ENT_") == 0 || StringFind(nome, "C_GAIN_") == 0 ||
         StringFind(nome, "C_STOP_") == 0 || StringFind(nome, "C_PROT_") == 0 ||
         StringFind(nome, "C_A") == 0 ||
         StringFind(nome, "V_ENT_") == 0 || StringFind(nome, "V_GAIN_") == 0 ||
         StringFind(nome, "V_STOP_") == 0 || StringFind(nome, "V_PROT_") == 0 ||
         StringFind(nome, "V_A") == 0))
         ObjectDelete(0, nome);
   }
   g_ultimoCandleContraProcessadoFIX258 = 0;
   g_historicoCandlesContraCarregadoFIX261 = false;
   g_ultimaVarreduraCandlesContraFIX262 = 0;
}

bool PnlTemaClaro()
{
   return (InpTemaPainel == TEMA_CLARO);
}

color PnlCorFundo()
{
   return PnlTemaClaro() ? C'242,246,250' : C'5,10,18';
}

color PnlCorBloco()
{
   return PnlTemaClaro() ? C'255,255,255' : C'10,18,30';
}

color PnlCorBloco2()
{
   return PnlTemaClaro() ? C'248,250,252' : C'13,24,38';
}

color PnlCorLinha()
{
   return PnlTemaClaro() ? C'203,213,225' : C'45,65,82';
}

color PnlCorAbaAtiva()
{
   return C'0,120,212';
}

color PnlCorAbaInativa()
{
   return PnlTemaClaro() ? C'241,245,249' : C'30,41,59';
}

color PnlCorTitulo()
{
   return PnlTemaClaro() ? C'3,105,161' : C'0,255,255';
}

color PnlCorTexto()
{
   return PnlTemaClaro() ? C'17,24,39' : clrWhite;
}

color PnlCorSecundario()
{
   return PnlTemaClaro() ? C'71,85,105' : C'175,190,205';
}

color PnlCorVerde()
{
   return PnlTemaClaro() ? C'22,163,74' : clrLime;
}

color PnlCorVermelho()
{
   return PnlTemaClaro() ? C'220,38,38' : clrRed;
}

color PnlCorAmarelo()
{
   return PnlTemaClaro() ? C'180,83,9' : clrYellow;
}

color PnlCorCinza()
{
   return PnlTemaClaro() ? C'100,116,139' : clrSilver;
}

color PnlCorDivisoria()
{
   return PnlTemaClaro() ? C'226,232,240' : C'45,65,82';
}

color PnlCorLinhaAlternada(int row)
{
   if(PnlTemaClaro())
      return (row % 2 == 0) ? C'255,255,255' : C'248,250,252';
   return (row % 2 == 0) ? C'8,16,26' : C'11,21,33';
}

color PnlCorStatusFundo(string status)
{
   status = Upper(status);
   if(StringFind(status, "FEITO") >= 0 || StringFind(status, "PRONTO") >= 0)
      return PnlTemaClaro() ? C'220,252,231' : C'5,32,22';
   if(StringFind(status, "BLOQ") >= 0 || StringFind(status, "MAX") >= 0)
      return PnlTemaClaro() ? C'254,226,226' : C'34,8,12';
   if(StringFind(status, "AGUARDA") >= 0 || StringFind(status, "FILA") >= 0)
      return PnlTemaClaro() ? C'254,243,199' : C'48,38,7';
   return PnlCorLinhaAlternada(0);
}

string PnlMoedaBRL(double valor)
{
   return FormatarMoeda(valor) + " BRL";
}



void PnlAba(string nome, string texto, int x, int y, bool ativa, int fonte)
{
   bool novo = false;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_BUTTON, 0, 0, 0))
         return;
      novo = true;
   }
   color fundo = ativa ? PnlCorAbaAtiva() : PnlCorAbaInativa();
   color corTxt = ativa ? clrWhite : PnlCorSecundario();
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, PainelAutoXFIX319(nome,x));
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, PainelAutoYFIX319(nome,y));
   ObjectSetInteger(0, nome, OBJPROP_XSIZE, PainelAutoWFIX319(nome,82));
   ObjectSetInteger(0, nome, OBJPROP_YSIZE, PainelAutoHFIX319(nome,25));
   ObjectSetInteger(0, nome, OBJPROP_BGCOLOR, fundo);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, corTxt);
   ObjectSetInteger(0, nome, OBJPROP_BORDER_COLOR, ativa ? PnlCorTitulo() : PnlCorLinha());
   ObjectSetInteger(0, nome, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, nome, OBJPROP_STATE, false);
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetString(0, nome, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, PainelAutoFonteFIX319(nome,fonte));
   if(novo)
   {
      ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nome, OBJPROP_BACK, false);
      ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, nome, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, nome, OBJPROP_ZORDER, 9500);
   }
}

void PnlMetrica(string nome, string label, string valor, int x, int y, int largura, color corValor, int fonte)
{
   int valorW = 120;
   if(largura < 250)
      valorW = 96;
   int valorX = x + largura - valorW;
   if(valorX < x + 70)
      valorX = x + 70;
   int labelW = valorX - x - 4;
   PainelTextoCortado(nome + "_L", label, x, y, PnlCorTexto(), fonte, "Consolas", labelW);
   PainelTextoCortado(nome + "_V", valor, valorX, y, corValor, fonte, "Consolas", valorW);
}

void PnlMetricaGrande(string nome, string label, string valor, int x, int y, int largura, color corValor, int fonte)
{
   int valorW = 132;
   if(largura < 250)
      valorW = 108;
   int valorX = x + largura - valorW;
   if(valorX < x + 86)
      valorX = x + 86;
   int labelW = valorX - x - 4;
   PainelTextoCortado(nome + "_L", label, x, y, PnlCorTexto(), fonte + 1, "Arial Bold", labelW);
   PainelTextoCortado(nome + "_V", valor, valorX, y - 1, corValor, fonte + 2, "Arial Bold", valorW);
}

double ExposicaoMaximaLado(EstadoLado &estado)
{
   if(!estado.posicaoAberta || estado.contratos <= 0.0)
      return 0.0;
   double perdaPorContrato = MathAbs(InpPainelExposicaoPorContratoReais);
   if(perdaPorContrato <= 0.0)
      perdaPorContrato = MathAbs(InpEntradaPerdaMaximaReais);
   if(perdaPorContrato <= 0.0)
      perdaPorContrato = MathAbs(g_risco.stopOperacao);
   return perdaPorContrato * estado.contratos;
}

double ExposicaoNegativaLado(EstadoLado &estado)
{
   if(!estado.posicaoAberta)
      return 0.0;
   if(estado.resultadoAberto < 0.0)
      return estado.resultadoAberto;
   return 0.0;
}

double ExposicaoNegativaTotalPainel()
{
   return ExposicaoNegativaLado(g_painelA) + ExposicaoNegativaLado(g_painelB);
}

double ResultadoAbertoTotalPainel()
{
   double qtdCompra = 0.0, qtdVenda = 0.0, totalBruto = 0.0;
   double abertoCompra = 0.0, abertoVenda = 0.0, abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDireto(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal);
   return abertoTotal;
}

double ExposicaoMaximaTotal()
{
   double total = 0.0;
   total += ExposicaoMaximaLado(g_painelA);
   total += ExposicaoMaximaLado(g_painelB);
   return total;
}

double ExposicaoMaximaOperacaoConfiguradaFIX228()
{
   // Campo essencial do painel: usa o limite financeiro real da operacao.
   // Nao cria um numero novo; mostra o mesmo valor de PERDA MAXIMA configurado.
   double valor = MathAbs(InpEntradaPerdaMaximaReais);
   if(valor <= 0.0)
      valor = MathAbs(g_risco.stopOperacao);
   if(valor <= 0.0)
      valor = MathAbs(InpPainelExposicaoMaximaReais);
   return valor;
}


string TextoMoedaPainelCurto(double valor)
{
   double absValor = MathAbs(valor);
   if(valor > 0.0)
      return StringFormat("+R$ %.2f", absValor);
   if(valor < 0.0)
      return StringFormat("-R$ %.2f", absValor);
   return StringFormat("R$ %.2f", absValor);
}

void DesenharLinhaParametrosResumo(string pfx, int x, int y, int fonte, double ganhoParam, double perdaParam, double contratosAbertos, double abertoValor, bool focoAtivo, string textoFoco, bool protecaoOn, double valorDefendido, double melhorAberto, bool painelTotal, int larguraCard, string posicaoTopo, string identidade1, string identidade2)
{
   ObjectDelete(0, pfx + "_MAGIC");
   ObjectDelete(0, pfx + "_PARAM");
   ObjectDelete(0, pfx + "_P_GLBL");
   ObjectDelete(0, pfx + "_P_GVAL");
   ObjectDelete(0, pfx + "_P_PLBL");
   ObjectDelete(0, pfx + "_P_PVAL");
   ObjectDelete(0, pfx + "_P_EXPLBL");
   ObjectDelete(0, pfx + "_P_EXPVAL");
   ObjectDelete(0, pfx + "_P_PROTLBL");
   ObjectDelete(0, pfx + "_P_PROTVAL");
   ObjectDelete(0, pfx + "_ID3");
   ObjectDelete(0, pfx + "_RISCO3");

   bool compacto = (larguraCard > 0 && larguraCard < 390);
   int fonteCab = compacto ? 7 : 8;
   int areaW = larguraCard - 20;
   if(areaW <= 0)
      areaW = 330;

   int gap = compacto ? 8 : 14;
   int colEsqW = (areaW - gap) / 2;
   int colDirW = areaW - colEsqW - gap;
   if(colEsqW < 150)
      colEsqW = 150;
   if(colDirW < 150)
      colDirW = 150;

   int xEsq = x + 10;
   int xDir = xEsq + colEsqW + gap;

   // Exposicao atual = perda financeira aberta da operacao.
   // O limite maximo e o stop financeiro TOTAL da operacao, inclusive com 4 contratos.
   double expMax = MathAbs(perdaParam);
   if(expMax <= 0.0)
      expMax = ExposicaoMaximaOperacaoConfiguradaFIX228();

   double expAtual = (abertoValor < 0.0 ? MathAbs(abertoValor) : 0.0);
   double restaStop = MathMax(0.0, expMax - expAtual);
   double usoPercent = (expMax > 0.0 ? (expAtual / expMax) * 100.0 : 0.0);

   double maxContratos = (double)g_gerAumentos.maxContratos;
   if(maxContratos <= 0.0)
      maxContratos = 4.0;

   string textoProtecao = protecaoOn
                          ? StringFormat("PROT ON | DEF R$ %.2f", MathAbs(valorDefendido))
                          : StringFormat("PROT OFF | GAT R$ %.2f", MathAbs(g_entradaTrailingAtivarReaisEfetivo));

   string linhaEsq1 = identidade1;
   string linhaEsq2 = identidade2;
   string linhaEsq3 = textoProtecao;
   string linhaDir1 = StringFormat("CT %.0f/%.0f", contratosAbertos, maxContratos);
   string linhaDir2 = StringFormat("EXP ATUAL %s", TextoMoedaPainelCurto(-expAtual));
   string linhaDir3 = StringFormat("MAX %s | RESTA %s | USO %.0f%%",
                                   TextoMoedaPainelCurto(-expMax),
                                   TextoMoedaPainelCurto(-restaStop),
                                   usoPercent);

   color corIdentidade = PnlCorTexto();
   color corExp = (usoPercent >= 80.0 ? PnlCorVermelho() :
                  (usoPercent >= 50.0 ? PnlCorAmarelo() : PnlCorVerde()));
   color corProtecao = protecaoOn ? PnlCorVerde() : PnlCorSecundario();

   PainelTextoCortado(pfx + "_ID1", linhaEsq1, xEsq, y, corIdentidade, fonteCab, "Consolas", colEsqW);
   PainelTextoCortado(pfx + "_ID2", linhaEsq2, xEsq, y + 14, PnlCorSecundario(), fonteCab, "Consolas", colEsqW);
   PainelTextoCortado(pfx + "_ID3", linhaEsq3, xEsq, y + 28, corProtecao, fonteCab, "Consolas", colEsqW);
   PainelTextoCortado(pfx + "_RISCO1", linhaDir1, xDir, y, corExp, fonteCab, "Arial Bold", colDirW);
   PainelTextoCortado(pfx + "_RISCO2", linhaDir2, xDir, y + 14, corExp, fonteCab, "Arial Bold", colDirW);
   PainelTextoCortado(pfx + "_RISCO3", linhaDir3, xDir, y + 28, corExp, fonteCab, "Consolas", colDirW);

   int yAberto = y + 46;
   color corAberto = CorFinanceiro(abertoValor);
   int bgW = areaW;
   if(bgW < 210)
      bgW = 210;

   bool mostrarAbertoNoCabecalho = (painelTotal || focoAtivo || contratosAbertos > 0.0);
   if(mostrarAbertoNoCabecalho)
   {
      int fonteAberto = compacto ? fonte + 1 : fonte + 2;
      if(posicaoTopo == "")
         posicaoTopo = painelTotal ? "A+B" : "SEM POS";
      string rotuloAberto = painelTotal ? "ABERTO A+B" : (posicaoTopo + " | ABERTO");
      string textoQtdTopo = painelTotal ? TextoQtdCabecalhoTotalAB() : StringFormat("QTD %.0f", contratosAbertos);
      PainelRetangulo(pfx + "_P_AB_BG", x + 8, yAberto - 3, bgW, compacto ? 20 : 22, PnlCorBloco2(), PnlCorLinha());
      PainelTextoCortado(pfx + "_P_ABLBL",
                         StringFormat("%s | %s | %s", rotuloAberto, textoQtdTopo, TextoMoedaPainelCurto(abertoValor)),
                         x + 14, yAberto, corAberto, fonteAberto, "Arial Bold", bgW - 12);
   }
   else
   {
      PainelRetangulo(pfx + "_P_AB_BG", x + 8, yAberto - 3, bgW, compacto ? 20 : 22, PnlCorBloco2(), PnlCorLinha());
      PainelTextoCortado(pfx + "_P_ABLBL", "SEM POS | ABERTO | QTD 0 | R$ 0.00",
                         x + 14, yAberto, PnlCorSecundario(), fonte, "Consolas", bgW - 12);
   }

   ObjectDelete(0, pfx + "_P_ABSEP1");
   ObjectDelete(0, pfx + "_P_ABQTD");
   ObjectDelete(0, pfx + "_P_ABSEP2");
   ObjectDelete(0, pfx + "_P_ABVAL");
   ObjectDelete(0, pfx + "_P_FOCO");
}
void DesenharCamposGanhoPerdaOperacao(string pfx, int x, int y, int largura, int fonte, bool painelTotalAB=false)
{
   fonte = 7;
   int gap = 10;
   int w = (largura - gap) / 2;
   if(w < 96)
      w = 96;
   int h = 22;
   double ganho = painelTotalAB ? GainHeadEfetivoFIX362() : MathAbs(InpEntradaGanhoAlvoReais);
   double perda = (painelTotalAB || InpStopDinamicoHeadFIX359) ? LossHeadEfetivoFIX362() : MathAbs(InpEntradaPerdaMaximaReais);
   PainelRetangulo(pfx + "_GAN_BG", x, y, w, h, PnlCorBloco2(), PnlCorVerde());
   PainelTextoCortado(pfx + "_GAN_L", painelTotalAB ? "GAIN HEAD" : "ALVO OP", x + 7, y + 5, PnlCorVerde(), fonte, "Arial Bold", w - 80);
   PainelTextoCortado(pfx + "_GAN_V", TextoMoedaPainelCurto(ganho), x + w - 74, y + 5, PnlCorVerde(), fonte, "Arial Bold", 72);
   int x2 = x + w + gap;
   PainelRetangulo(pfx + "_PER_BG", x2, y, w, h, PnlCorBloco2(), PnlCorVermelho());
   PainelTextoCortado(pfx + "_PER_L", (painelTotalAB || InpStopDinamicoHeadFIX359) ? "LOSS HEAD" : "STOP OP", x2 + 7, y + 5, PnlCorVermelho(), fonte, "Arial Bold", w - 80);
   PainelTextoCortado(pfx + "_PER_V", TextoMoedaPainelCurto(-perda), x2 + w - 74, y + 5, PnlCorVermelho(), fonte, "Arial Bold", 72);
}

void SanitizarFonteOperacionalABQuandoFlat()
{
   double qtdCompra = 0.0, qtdVenda = 0.0, qtdTotal = 0.0;
   double abertoCompra = 0.0, abertoVenda = 0.0, abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, qtdTotal,
                                        abertoCompra, abertoVenda, abertoTotal);
   if(qtdTotal > 0.0001)
      return;
   g_totalCicloMestreSimples = g_parciaisCicloBuy + g_parciaisCicloSell;
   g_cicloMestreSimplesAtivo = false;
   g_cicloMestreSimplesInicio = 0;
   g_fechamentoMestreSimplesPendente = false;
   ResetarEstadoPontaSimplesFIX195(g_simplesBuy);
   ResetarEstadoPontaSimplesFIX195(g_simplesSell);
}

double SaldoOperacionalMestreABAtual()
{
   SanitizarFonteOperacionalABQuandoFlat();
   double qtdCompra = 0.0, qtdVenda = 0.0, qtdTotal = 0.0;
   double abertoCompra = 0.0, abertoVenda = 0.0, abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, qtdTotal,
                                        abertoCompra, abertoVenda, abertoTotal);
   return NormalizeDouble(abertoTotal + g_parciaisCicloBuy + g_parciaisCicloSell, 2);
}

void DesenharResumoFinanceiroLado(string pfx, string titulo, EstadoLado &e, HistoricoPeriodo &h, int x, int y, int largura, int altura, int fonte)
{
   // FIX353: evita combinacoes impossiveis como "SEM POS" junto com QTD/ABERTO diferentes de zero.
   AtualizarEstadoLado(e);
   bool focoAtivo = CardFinanceiroEhFoco(e);
   color bordaCard = focoAtivo ? CorMagicPiscando(PnlCorAmarelo()) : PnlCorLinha();
   PainelRetangulo(pfx + "_BG", x, y, largura, altura, PnlCorBloco(), bordaCard);
   PainelTexto(pfx + "_TIT", (focoAtivo ? "▶ " : "v ") + titulo, x + 10, y + 8, focoAtivo ? CorMagicPiscando(PnlCorAmarelo()) : PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "_REAL", focoAtivo ? "[FOCO]" : "[dados]", x + largura - 64, y + 8, focoAtivo ? CorMagicPiscando(PnlCorAmarelo()) : PnlCorVerde(), fonte, "Consolas");
   int tx = x + 10;
   int ty = y + 100;
   PnlAba(pfx + "_ABA_HOJE",  "hoje>",  tx, ty,       g_periodoHistoricoAtivo == HIST_PAINEL_DIA,   fonte);
   PnlAba(pfx + "_ABA_ONTEM", "ontem",  tx, ty + 30,  g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM, fonte);
   PnlAba(pfx + "_ABA_7D",    "7 dias", tx, ty + 60,  g_periodoHistoricoAtivo == HIST_PAINEL_7D,    fonte);
   PnlAba(pfx + "_ABA_15D",   "15 dias",tx, ty + 90,  g_periodoHistoricoAtivo == HIST_PAINEL_15D,   fonte);
   PnlAba(pfx + "_ABA_30D",   "30 dias",tx, ty + 120, g_periodoHistoricoAtivo == HIST_PAINEL_30D,   fonte);
   PnlAba(pfx + "_ABA_TUDO",  "tudo",   tx, ty + 150, g_periodoHistoricoAtivo == HIST_PAINEL_TUDO,  fonte);
   PnlAba(pfx + "_ABA_CSV",   "AUDIT", tx, ty + 180, g_aud302TelaAtiva, fonte);
   int mx = x + 96;
   int mw = largura - 108;
   ResumoFinanceiroPainel rf;
   CalcularResumoFinanceiroSlotPainel(e, h, rf);
   if(g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
      AplicarAbertoDiretoNoResumoMagic(rf,e.magic);
   double realizado = rf.realizado;
   double abertoFinanceiro = rf.aberto;
   double saldo = rf.saldo;
   double lucro = rf.lucro;
   double preju = rf.prejuizo;
   int totalTrades = rf.totalTrades;
   int tradesLucro = rf.tradesLucro;
   int tradesPreju = rf.tradesPrejuizo;
   double parcialLado = rf.parcialPositiva;
   int qtdParciaisLado = rf.qtdParciais;
   if(InpModoSimplesFIX195 && g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
   {
      SanitizarFonteOperacionalABQuandoFlat();
      double contratosDiretoLocal = 0.0;
      double abertoDiretoLocal = 0.0;
      CalcularAbertoContratosPorMagicDireto(e.magic, contratosDiretoLocal, abertoDiretoLocal);
      bool slotVendaFIX209 = (e.magic == MagicVendaAtual() || e.magic == MagicPainelBAtual());
      realizado = slotVendaFIX209 ? g_parciaisCicloSell : g_parciaisCicloBuy;
      if(contratosDiretoLocal <= 0.0001)
         abertoDiretoLocal = 0.0;
      abertoFinanceiro = abertoDiretoLocal;
      saldo = realizado + abertoFinanceiro;
      lucro = 0.0;
      preju = 0.0;
      if(realizado >= 0.0) lucro += realizado; else preju += realizado;
      if(abertoFinanceiro >= 0.0) lucro += abertoFinanceiro; else preju += abertoFinanceiro;
      parcialLado = slotVendaFIX209 ? g_realizadoAumentosCicloSell : g_realizadoAumentosCicloBuy;
      qtdParciaisLado = slotVendaFIX209 ? g_qtdRealizacoesAumentosCicloSell : g_qtdRealizacoesAumentosCicloBuy;
      // FIX302: nao transformar toda a operacao em apenas "1 trade".
      // Mantem a contagem real dos deals de saida do periodo; usa 1 somente antes da primeira saida.
      if(totalTrades<=0 && (contratosDiretoLocal > 0.0 || MathAbs(realizado) > 0.0001))
      {
         totalTrades=1;
         tradesLucro=(saldo>0.0 ? 1 : 0);
         tradesPreju=(saldo<0.0 ? 1 : 0);
      }
   }
   ENUM_LADO_ROBO ladoVisual = LadoDaPosicaoAtual(e);
   string motorTxt = (e.lado == LADO_VENDA ? "VENDA" : "COMPRA");
   string identidade1FIX235 = StringFormat("MAGIC %s | %s",
                                             IntegerToString(e.magic),
                                             motorTxt);
   string identidade2FIX235 = StringFormat("POS %s | F:%s | E:%s",
                                             TextoPosicaoCard(e),
                                             NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                                             NomeTimeframeCurto(TimeframeEntradaAtualFIX255()));
   DesenharLinhaParametrosResumo(pfx,
                                 x,
                                 y + 30,
                                 fonte,
                                 MathAbs(InpEntradaGanhoAlvoReais),
                                 MathAbs(InpEntradaPerdaMaximaReais),
                                 e.posicaoAberta ? e.contratos : 0.0,
                                 e.resultadoAberto,
                                 focoAtivo,
                                 TextoFocoUnico(e),
                                 e.lucroProtegido,
                                 e.valorDefendido,
                                 e.melhorResultadoAberto,
                                 false,
                                 largura,
                                 TextoPosicaoCard(e),
                                 identidade1FIX235,
                                 identidade2FIX235);
   int colGap = 18;
   int colW = (mw - colGap) / 2;
   if(colW < 210)
   {
      colGap = 10;
      colW = (mw - colGap) / 2;
   }
   int c1 = mx;
   int c2 = mx + colW + colGap;
   bool slotVendaDiaFIX211 = (e.magic == MagicVendaAtual() || e.magic == MagicPainelBAtual());
   ENUM_LADO_ROBO ladoPeriodoFIX310 = slotVendaDiaFIX211 ? LADO_VENDA : LADO_COMPRA;
   double realizadoPeriodoFIX310 = realizado;
   double abertoPeriodoFIX310 = abertoFinanceiro;
   double saldoPeriodoFIX310 = saldo;
   string periodoCurtoFIX310 = NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo);
   HistoricoPeriodo histSelecionadoFIX310;
   ObterHistoricoSelecionado(histSelecionadoFIX310);
   if(g_periodoHistoricoAtivo == HIST_PAINEL_DIA)
   {
      // FIX360: no card operacional, HOJE mostra a cesta ativa do lado, não perdas antigas do dia.
      FotoCestaAB fotoCicloLadoFIX360;
      CalcularFotoCestaABOficial(fotoCicloLadoFIX360,true);
      if(fotoCicloLadoFIX360.qtdTotal<=0.0001)
      {
         realizadoPeriodoFIX310=0.0;
         abertoPeriodoFIX310=0.0;
         saldoPeriodoFIX310=0.0;
      }
      else if(ladoPeriodoFIX310==LADO_VENDA)
      {
         realizadoPeriodoFIX310=fotoCicloLadoFIX360.realizadoVenda;
         abertoPeriodoFIX310=fotoCicloLadoFIX360.abertoVenda;
         saldoPeriodoFIX310=fotoCicloLadoFIX360.abertoVenda;
      }
      else
      {
         realizadoPeriodoFIX310=fotoCicloLadoFIX360.realizadoCompra;
         abertoPeriodoFIX310=fotoCicloLadoFIX360.abertoCompra;
         saldoPeriodoFIX310=fotoCicloLadoFIX360.abertoCompra;
      }
   }
   else if(g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM)
   {
      // FIX349: todo periodo historico diferente de DIA exibe somente o realizado.
      // somente o resultado realizado; a fotografia antiga de virada nao pode
      // criar um ABR artificial que anule o lucro/prejuizo verdadeiro.
      realizadoPeriodoFIX310 = slotVendaDiaFIX211 ? histSelecionadoFIX310.financeiroVenda : histSelecionadoFIX310.financeiroCompra;
      abertoPeriodoFIX310 = 0.0;
      saldoPeriodoFIX310 = realizadoPeriodoFIX310;
   }
   else
   {
      realizadoPeriodoFIX310 = slotVendaDiaFIX211 ? histSelecionadoFIX310.financeiroVenda : histSelecionadoFIX310.financeiroCompra;
      abertoPeriodoFIX310 = 0.0;
      saldoPeriodoFIX310 = realizadoPeriodoFIX310;
   }
   int gapRealFIX211 = 18;
   int wRealFIX211 = (mw - gapRealFIX211) / 2;
   double saldoOperacaoLocalFIX362=(g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? (realizadoPeriodoFIX310 + abertoPeriodoFIX310) : realizadoPeriodoFIX310); // FIX396: saldo operacional = realizado separado + aberto do lado.
   double lucroOperacaoLocalFIX362=(g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? MathMax(0.0,abertoPeriodoFIX310) : lucro);
   double prejuOperacaoLocalFIX362=(g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? MathMin(0.0,abertoPeriodoFIX310) : preju);
   PnlMetricaGrande(pfx + "_M1", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? (ladoPeriodoFIX310==LADO_VENDA ? "Saldo aberto V" : "Saldo aberto C") : "Saldo " + periodoCurtoFIX310, PnlMoedaBRL(saldoPeriodoFIX310), mx, y + 98, mw, CorFinanceiro(saldoPeriodoFIX310), fonte);
   PnlMetrica(pfx + "_M2_OP", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Realizado separado" : "Real. periodo", PnlMoedaBRL(realizadoPeriodoFIX310), mx, y + 122, wRealFIX211, CorFinanceiro(realizadoPeriodoFIX310), fonte);
   PnlMetrica(pfx + "_M2_DIA", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Saldo operacional" : "Real. operacao", PnlMoedaBRL(saldoOperacaoLocalFIX362), mx + wRealFIX211 + gapRealFIX211, y + 122, wRealFIX211, CorFinanceiro(saldoOperacaoLocalFIX362), fonte);
   PnlMetrica(pfx + "_M3", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Aberto do lado" : "Variacao aberta", PnlMoedaBRL(abertoPeriodoFIX310), mx, y + 140, mw, CorFinanceiro(abertoPeriodoFIX310), fonte);
   ObjectDelete(0, pfx + "_M2_L"); ObjectDelete(0, pfx + "_M2_V");
   PainelRetangulo(pfx + "_DIV1", mx, y + 162, mw, 1, PnlCorDivisoria(), PnlCorDivisoria());
   int rowStep = (altura < 335 ? 16 : 18);
   int rowY = y + (altura < 335 ? 168 : 176);
   PainelTextoCortado(pfx + "_C1_T", "POSICAO LOCAL", c1, rowY, PnlCorTitulo(), fonte, "Arial Bold", colW);
   PainelTextoCortado(pfx + "_C2_T", "AUMENTOS / PARCIAIS", c2, rowY, PnlCorTitulo(), fonte, "Arial Bold", colW);
   rowY += rowStep;
   string precoMedioTxt = e.posicaoAberta ? DoubleToString(e.precoMedio, _Digits) : "--";
   double abertoPorContrato = (e.posicaoAberta && e.contratos > 0.0) ? abertoPeriodoFIX310 / e.contratos : 0.0;
   string modoAumTxt = InpAumentosLivreTeste ? "TESTE LIVRE" : "NORMAL";
   if(InpAumentosContraPosicao)
      modoAumTxt += " / CONTRA";
   else
      modoAumTxt += " / FAVOR";
   PnlMetrica(pfx + "_M4",  "Lado real",      TextoPosicaoCard(e),           c1, rowY, colW, CorLadoTexto(LadoDaPosicaoAtual(e)), fonte);
   PnlMetrica(pfx + "_M10", "Aumentos",       StringFormat("%d de %d", e.aumentosExecutados, g_gerAumentos.maxAumentos), c2, rowY, colW, e.aumentosExecutados > 0 ? PnlCorVerde() : PnlCorTexto(), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M5",  "Qtd atual",      DoubleToString(e.contratos, 0) + " contr.", c1, rowY, colW, e.contratos > 0.0 ? PnlCorAmarelo() : PnlCorTexto(), fonte);
   PnlMetrica(pfx + "_M11", "Proximo",        ProximoAumentoCard(e),         c2, rowY, colW, PnlCorAmarelo(), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M6",  "Preco medio",    precoMedioTxt,                 c1, rowY, colW, PnlCorTexto(), fonte);
   PnlMetrica(pfx + "_M12", "Modo",           modoAumTxt,                    c2, rowY, colW, InpAumentosLivreTeste ? PnlCorVerde() : PnlCorAmarelo(), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M7",  "Aberto/contr.",  PnlMoedaBRL(abertoPorContrato), c1, rowY, colW, CorFinanceiro(abertoPorContrato), fonte);
   PnlMetrica(pfx + "_M13", StringFormat("Parciais %d", qtdParciaisLado), PnlMoedaBRL(parcialLado), c2, rowY, colW, CorFinanceiro(parcialLado), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M8",  g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Lucro aberto" : "Lucro operacao", PnlMoedaBRL(lucroOperacaoLocalFIX362), c1, rowY, colW, PnlCorVerde(), fonte);
   PnlMetrica(pfx + "_M14", InpStopDinamicoHeadFIX359 ? "Stop movel HEAD" : "Preju operacao", InpStopDinamicoHeadFIX359 ? PnlMoedaBRL(StopMovelLadoHeadFIX359(ladoPeriodoFIX310)) : PnlMoedaBRL(prejuOperacaoLocalFIX362), c2, rowY, colW, PnlCorVermelho(), fonte);
   rowY += rowStep;
   double expAtual = rf.expAtual;
   double expNegativa = (g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? MathMin(0.0,abertoPeriodoFIX310) : rf.expPrejuizo);
   PnlMetrica(pfx + "_M9",  "Exp. prej.",     PnlMoedaBRL(expNegativa),      c1, rowY, colW, CorFinanceiro(expNegativa), fonte);
   PnlMetrica(pfx + "_M15", "Protecao",       StringFormat("%s | %s", e.lucroProtegido ? "ON" : "OFF", PnlMoedaBRL(e.valorDefendido)), c2, rowY, colW, e.lucroProtegido ? PnlCorVerde() : PnlCorSecundario(), fonte);
   rowY += rowStep;
   if(rowY < y + altura - 34)
   {
      PnlMetrica(pfx + "_M16", "Exp. atual", PnlMoedaBRL(expAtual), c1, rowY, colW, PnlCorAmarelo(), fonte);
      PnlMetrica(pfx + "_M17", "Saidas", StringFormat("%d | +%d | -%d", totalTrades, tradesLucro, tradesPreju), c2, rowY, colW, PnlCorTexto(), fonte);
   }
   else
   {
      ObjectDelete(0, pfx + "_M16_L"); ObjectDelete(0, pfx + "_M16_V");
      ObjectDelete(0, pfx + "_M17_L"); ObjectDelete(0, pfx + "_M17_V");
   }
   DesenharCamposGanhoPerdaOperacao(pfx + "_GP", mx, y + altura - 26, mw, fonte, false);
}

void DesenharResumoFinanceiroTotal(string pfx, HistoricoPeriodo &h, int x, int y, int largura, int altura, int fonte)
{
   PainelRetangulo(pfx + "_BG", x, y, largura, altura, PnlCorBloco(), PnlCorLinha());
   PainelTexto(pfx + "_TIT", "v Resumo financeiro / operacao atual", x + 10, y + 8, PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "_REAL", "[real]", x + largura - 54, y + 8, PnlCorVerde(), fonte, "Consolas");
   int tx = x + 10;
   int ty = y + 100;
   PnlAba(pfx + "_ABA_HOJE",  "hoje>",  tx, ty,       g_periodoHistoricoAtivo == HIST_PAINEL_DIA,   fonte);
   PnlAba(pfx + "_ABA_ONTEM", "ontem",  tx, ty + 30,  g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM, fonte);
   PnlAba(pfx + "_ABA_7D",    "7 dias", tx, ty + 60,  g_periodoHistoricoAtivo == HIST_PAINEL_7D,    fonte);
   PnlAba(pfx + "_ABA_15D",   "15 dias",tx, ty + 90,  g_periodoHistoricoAtivo == HIST_PAINEL_15D,   fonte);
   PnlAba(pfx + "_ABA_30D",   "30 dias",tx, ty + 120, g_periodoHistoricoAtivo == HIST_PAINEL_30D,   fonte);
   PnlAba(pfx + "_ABA_TUDO",  "tudo",   tx, ty + 150, g_periodoHistoricoAtivo == HIST_PAINEL_TUDO,  fonte);
   PnlAba(pfx + "_ABA_CSV",   "AUDIT", tx, ty + 180, g_aud302TelaAtiva, fonte);
   int mx = x + 96;
   int mw = largura - 108;
   ResumoFinanceiroPainel resumoA, resumoB, resumoTotal;
   CalcularResumoFinanceiroSlotPainel(g_painelA, h, resumoA);
   CalcularResumoFinanceiroSlotPainel(g_painelB, h, resumoB);
   if(g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
   {
      AplicarAbertoDiretoNoResumoMagic(resumoA, MagicPainelAAtual());
      AplicarAbertoDiretoNoResumoMagic(resumoB, MagicPainelBAtual());
   }
   CalcularResumoFinanceiroTotalAB(resumoA, resumoB, resumoTotal);
   double qtdCompraAB = 0.0;
   double qtdVendaAB = 0.0;
   double qtdBrutaAB = 0.0;
   double abertoCompraGrupoAB = 0.0;
   double abertoVendaGrupoAB = 0.0;
   double abertoGrupoAB = 0.0;
   CalcularAbertoTotalABGrupoDireto(qtdCompraAB, qtdVendaAB, qtdBrutaAB, abertoCompraGrupoAB, abertoVendaGrupoAB, abertoGrupoAB);
   FotoCestaAB fotoABPainel;
   CalcularFotoCestaABOficial(fotoABPainel, true);
   HistoricoPeriodo histHeadAB;
   ObterHistoricoSelecionado(histHeadAB);
   bool periodoFechadoOntemAB = true; // válido somente para o Histórico HEAD
   bool totalABGrupoAtivo = PainelTotalABUsaGrupoMagics();
   if(totalABGrupoAtivo && g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
   {
      if(InpModoSimplesFIX195)
      {
         SanitizarFonteOperacionalABQuandoFlat();
         CalcularAbertoTotalABGrupoDiretoBase(qtdCompraAB, qtdVendaAB, qtdBrutaAB,
                                              abertoCompraGrupoAB, abertoVendaGrupoAB, abertoGrupoAB);
         resumoTotal.contratos = qtdBrutaAB;
         resumoTotal.realizado = g_parciaisCicloBuy + g_parciaisCicloSell;
         resumoTotal.aberto = abertoGrupoAB;
         resumoTotal.saldo = resumoTotal.realizado + resumoTotal.aberto;
         resumoTotal.lucro = (resumoTotal.realizado > 0.0 ? resumoTotal.realizado : 0.0)
                           + (abertoCompraGrupoAB > 0.0 ? abertoCompraGrupoAB : 0.0)
                           + (abertoVendaGrupoAB > 0.0 ? abertoVendaGrupoAB : 0.0);
         resumoTotal.prejuizo = (resumoTotal.realizado < 0.0 ? resumoTotal.realizado : 0.0)
                              + (abertoCompraGrupoAB < 0.0 ? abertoCompraGrupoAB : 0.0)
                              + (abertoVendaGrupoAB < 0.0 ? abertoVendaGrupoAB : 0.0);
         resumoTotal.parcialPositiva = g_realizadoAumentosCicloBuy + g_realizadoAumentosCicloSell;
         resumoTotal.qtdParciais = g_qtdRealizacoesAumentosCicloBuy + g_qtdRealizacoesAumentosCicloSell;
         // FIX302: usar contagem real dos dois Magics, sem reduzir toda a cesta a um unico trade.
         resumoTotal.tradesLucro = resumoA.tradesLucro + resumoB.tradesLucro;
         resumoTotal.tradesPrejuizo = resumoA.tradesPrejuizo + resumoB.tradesPrejuizo;
         resumoTotal.totalTrades = resumoA.totalTrades + resumoB.totalTrades;
         if(resumoTotal.totalTrades<=0 && (qtdBrutaAB>0.0 || MathAbs(resumoTotal.realizado)>0.0001))
            resumoTotal.totalTrades=1;
         resumoTotal.expPrejuizo = (abertoCompraGrupoAB<0.0 ? abertoCompraGrupoAB : 0.0)
                                 + (abertoVendaGrupoAB<0.0 ? abertoVendaGrupoAB : 0.0);
      }
      else
      {
         resumoTotal.contratos = 0.0;
         resumoTotal.realizado = histHeadAB.financeiro;
         resumoTotal.aberto = 0.0;
         resumoTotal.saldo = resumoTotal.realizado;
         resumoTotal.lucro = histHeadAB.financeiroLucroCompra + histHeadAB.financeiroLucroVenda;
         resumoTotal.prejuizo = histHeadAB.financeiroPrejuCompra + histHeadAB.financeiroPrejuVenda;
         resumoTotal.parcialPositiva = (histHeadAB.parcial > 0.0 ? histHeadAB.parcial : 0.0);
         resumoTotal.qtdParciais = histHeadAB.tradesLucroCompra + histHeadAB.tradesLucroVenda;
         resumoTotal.tradesLucro = histHeadAB.tradesLucroCompra + histHeadAB.tradesLucroVenda;
         resumoTotal.tradesPrejuizo = histHeadAB.tradesPrejuCompra + histHeadAB.tradesPrejuVenda;
         resumoTotal.totalTrades = resumoTotal.tradesLucro + resumoTotal.tradesPrejuizo;
         resumoTotal.expPrejuizo = 0.0;
         qtdCompraAB = 0.0; qtdVendaAB = 0.0; qtdBrutaAB = 0.0;
         abertoCompraGrupoAB = 0.0; abertoVendaGrupoAB = 0.0; abertoGrupoAB = 0.0;
      }
      double perdaPorContratoGrupo = MathAbs(InpPainelExposicaoPorContratoReais);
      if(perdaPorContratoGrupo <= 0.0)
         perdaPorContratoGrupo = MathAbs(InpEntradaPerdaMaximaReais);
      if(perdaPorContratoGrupo <= 0.0)
         perdaPorContratoGrupo = MathAbs(g_risco.stopOperacao);
      resumoTotal.expAtual = perdaPorContratoGrupo * qtdBrutaAB;
   }
   double realizadoA = resumoA.realizado;
   double realizadoB = resumoB.realizado;
   double abertoA = totalABGrupoAtivo ? abertoCompraGrupoAB : resumoA.aberto;
   double abertoB = totalABGrupoAtivo ? abertoVendaGrupoAB : resumoB.aberto;
   double realizado = resumoTotal.realizado;
   double abertoFinanceiro = resumoTotal.aberto;
   double lucro = resumoTotal.lucro;
   double preju = resumoTotal.prejuizo;
   // FIX362: contadores de saidas usam somente deals encerrados do periodo selecionado.
   double lucroSaidasFIX362=histHeadAB.financeiroLucroCompra+histHeadAB.financeiroLucroVenda;
   double prejuSaidasFIX362=histHeadAB.financeiroPrejuCompra+histHeadAB.financeiroPrejuVenda;
   double saldo = resumoTotal.saldo;
   if(InpModoSimplesFIX195 && g_periodoHistoricoAtivo==HIST_PAINEL_DIA)
   {
      saldo = SaldoOperacionalMestreABAtual();
      resumoTotal.saldo = saldo;
   }
   if(InpHistoricoRoboUsarGrupoTotalAB)
   {
      bool periodoHojeHeadFIX349=(g_periodoHistoricoAtivo==HIST_PAINEL_DIA);
      g_totalHeadSaldoABExibido = periodoHojeHeadFIX349 ? saldo : histHeadAB.financeiro;
      g_totalHeadSaldoABExibidoValido = true;
      g_totalHeadSaldoABExibidoHora = TimeCurrent();
      g_totalHeadResultadoABExibido = periodoHojeHeadFIX349 ? abertoFinanceiro : 0.0;
      g_totalHeadResultadoABExibidoValido = true;
      g_totalHeadResultadoABExibidoHora = TimeCurrent();
   }
   double saldoLiquidoAB = saldo;
   int tradesSlotA = resumoA.totalTrades;
   int tradesSlotB = resumoB.totalTrades;
   int totalTrades = resumoTotal.totalTrades;
   int tradesLucro = resumoTotal.tradesLucro;
   int tradesPreju = resumoTotal.tradesPrejuizo;
   int qtdParciaisTotal = resumoTotal.qtdParciais;
   double parcialTotalAB = resumoTotal.parcialPositiva;
   string identidadeTotal1FIX235 = StringFormat("%s", TextoGrupoMagicsTotalAB());
   string identidadeTotal2FIX235 = StringFormat("%s | L:%s | F:%s | E:%s",
                                                InpPermitirEnvioOrdens ? "ORDENS ON" : "ORDENS OFF",
                                                TextoLadosHabilitadosFIX346(),
                                                NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                                                NomeTimeframeCurto(TimeframeEntradaAtualFIX255()));
   DesenharLinhaParametrosResumo(pfx,
                                 x,
                                 y + 30,
                                 fonte,
                                 GainGlobalCestaAB(),
                                 StopBaseCestaAB(),
                                 qtdBrutaAB,
                                 abertoFinanceiro,
                                 false,
                                 "OPERACAO ATUAL",
                                 false,
                                 0.0,
                                 saldo,
                                 true,
                                 largura,
                                 "A+B",
                                 identidadeTotal1FIX235,
                                 identidadeTotal2FIX235);
   int colGap = 18;
   int colW = (mw - colGap) / 2;
   if(colW < 210)
   {
      colGap = 10;
      colW = (mw - colGap) / 2;
   }
   int c1 = mx;
   int c2 = mx + colW + colGap;
   double realizadoPeriodoABFIX310 = realizado;
   double abertoPeriodoABFIX310 = abertoFinanceiro;
   double saldoPeriodoABFIX310 = saldoLiquidoAB;
   string periodoCurtoABFIX310 = NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo);
   HistoricoPeriodo histSelecionadoABFIX310;
   ObterHistoricoSelecionado(histSelecionadoABFIX310);
   bool periodoHistoricoFechadoFIX349=(g_periodoHistoricoAtivo!=HIST_PAINEL_DIA);
   if(periodoHistoricoFechadoFIX349)
   {
      qtdCompraAB=histSelecionadoABFIX310.qtdCompra;
      qtdVendaAB=histSelecionadoABFIX310.qtdVenda;
      qtdBrutaAB=qtdCompraAB+qtdVendaAB;
      abertoCompraGrupoAB=0.0;
      abertoVendaGrupoAB=0.0;
      abertoGrupoAB=0.0;
      abertoA=0.0;
      abertoB=0.0;
      abertoFinanceiro=0.0;
      resumoTotal.aberto=0.0;
      resumoTotal.saldo=resumoTotal.realizado;
      saldo=resumoTotal.realizado;
      saldoLiquidoAB=saldo;
   }
   if(g_periodoHistoricoAtivo == HIST_PAINEL_DIA)
   {
      // FIX360: HEAD é exatamente COMPRA + VENDA da cesta operacional atual.
      if(fotoABPainel.qtdTotal<=0.0001)
      {
         realizadoPeriodoABFIX310=0.0;
         abertoPeriodoABFIX310=0.0;
         saldoPeriodoABFIX310=0.0;
      }
      else
      {
         realizadoPeriodoABFIX310=NormalizeDouble(fotoABPainel.realizadoTotal,2);
         abertoPeriodoABFIX310=NormalizeDouble(fotoABPainel.abertoTotal,2);
         saldoPeriodoABFIX310=NormalizeDouble(fotoABPainel.abertoTotal,2);
      }
      saldo=saldoPeriodoABFIX310;
      saldoLiquidoAB=saldoPeriodoABFIX310;
      abertoFinanceiro=abertoPeriodoABFIX310;
      realizado=realizadoPeriodoABFIX310;
   }
   else if(g_periodoHistoricoAtivo == HIST_PAINEL_ONTEM)
   {
      // FIX349: periodo historico fechado usa o realizado oficial A+B.
      realizadoPeriodoABFIX310 = histSelecionadoABFIX310.financeiro;
      abertoPeriodoABFIX310 = 0.0;
      saldoPeriodoABFIX310 = realizadoPeriodoABFIX310;
   }
   else
   {
      realizadoPeriodoABFIX310 = histSelecionadoABFIX310.financeiro;
      abertoPeriodoABFIX310 = 0.0;
      saldoPeriodoABFIX310 = realizadoPeriodoABFIX310;
   }
   int gapRealABFIX211 = 18;
   int wRealABFIX211 = (mw - gapRealABFIX211) / 2;
   PnlMetricaGrande(pfx + "_M1", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Saldo aberto A+B" : "Saldo " + periodoCurtoABFIX310, PnlMoedaBRL(saldoPeriodoABFIX310), mx, y + 98, mw, CorFinanceiro(saldoPeriodoABFIX310), fonte);
   PnlMetrica(pfx + "_M2_OP", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Realizado separado" : "Realizado periodo", PnlMoedaBRL(realizadoPeriodoABFIX310), mx, y + 122, wRealABFIX211, CorFinanceiro(realizadoPeriodoABFIX310), fonte);
   PnlMetrica(pfx + "_M2_DIA", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Saldo operacional A+B" : "Realizado A+B", PnlMoedaBRL(saldoPeriodoABFIX310), mx + wRealABFIX211 + gapRealABFIX211, y + 122, wRealABFIX211, CorFinanceiro(saldoPeriodoABFIX310), fonte);
   PnlMetrica(pfx + "_M3", g_periodoHistoricoAtivo==HIST_PAINEL_DIA ? "Aberto compra+venda" : "Variacao aberta", PnlMoedaBRL(abertoPeriodoABFIX310), mx, y + 140, mw, CorFinanceiro(abertoPeriodoABFIX310), fonte);
   ObjectDelete(0, pfx + "_M2_L"); ObjectDelete(0, pfx + "_M2_V");
   PainelRetangulo(pfx + "_DIV1", mx, y + 162, mw, 1, PnlCorDivisoria(), PnlCorDivisoria());
   int rowStep = (altura < 335 ? 16 : 18);
   int rowY = y + (altura < 335 ? 168 : 176);
   PainelTextoCortado(pfx + "_C1_T", "OPERACAO ATUAL", c1, rowY, PnlCorTitulo(), fonte, "Arial Bold", colW);
   PainelTextoCortado(pfx + "_C2_T", "RESULTADO / RISCO", c2, rowY, PnlCorTitulo(), fonte, "Arial Bold", colW);
   rowY += rowStep;
   double qtdLiquidaAB = MathAbs(qtdCompraAB - qtdVendaAB);
   PnlMetrica(pfx + "_M4",  "Qtd C|V|L",     StringFormat("%.0f|%.0f|%.0f", qtdCompraAB, qtdVendaAB, qtdLiquidaAB), c1, rowY, colW, qtdBrutaAB > 0.0 ? PnlCorAmarelo() : PnlCorTexto(), fonte);
   PnlMetrica(pfx + "_M10", "Saidas lucro",  StringFormat("%d | %s", tradesLucro, PnlMoedaBRL(lucroSaidasFIX362)), c2, rowY, colW, PnlCorVerde(), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M5",  totalABGrupoAtivo ? "Qtd C|V|T" : "Qtd A|B|T",     totalABGrupoAtivo ? StringFormat("%.0f|%.0f|%.0f", qtdCompraAB, qtdVendaAB, qtdBrutaAB) : StringFormat("%.0f|%.0f|%.0f", resumoA.contratos, resumoB.contratos, resumoTotal.contratos), c1, rowY, colW, qtdBrutaAB > 0.0 ? PnlCorAmarelo() : PnlCorTexto(), fonte);
   PnlMetrica(pfx + "_M11", "Saidas preju",  StringFormat("%d | %s", tradesPreju, PnlMoedaBRL(prejuSaidasFIX362)), c2, rowY, colW, PnlCorVermelho(), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M6",  totalABGrupoAtivo ? "Aberto C" : "Aberto A",      PnlMoedaBRL(abertoA), c1, rowY, colW, CorFinanceiro(abertoA), fonte);
   PnlMetrica(pfx + "_M12", StringFormat("Parciais %d", qtdParciaisTotal), PnlMoedaBRL(parcialTotalAB), c2, rowY, colW, CorFinanceiro(parcialTotalAB), fonte);
   rowY += rowStep;
   PnlMetrica(pfx + "_M7",  totalABGrupoAtivo ? "Aberto V" : "Aberto B",      PnlMoedaBRL(abertoB), c1, rowY, colW, CorFinanceiro(abertoB), fonte);
   PnlMetrica(pfx + "_M13", "Exp. prej.",    PnlMoedaBRL(resumoTotal.expPrejuizo), c2, rowY, colW, CorFinanceiro(resumoTotal.expPrejuizo), fonte);
   rowY += rowStep;
   // FIX416: linha dinamica CHECK/ESC/LOSS removida definitivamente.
   // Apaga objetos residuais de versoes anteriores e nao recria a linha.
   ObjectDelete(0,pfx + "_M8_L");
   ObjectDelete(0,pfx + "_M8_V");
   ObjectDelete(0,pfx + "_M14_L");
   ObjectDelete(0,pfx + "_M14_V");
   if(rowY < y + altura - 34)
   {
      PnlMetrica(pfx + "_M9",  "Saidas total", IntegerToString(totalTrades), c1, rowY, colW, PnlCorTexto(), fonte);
      PnlMetrica(pfx + "_M15", "GANHO QTD/R$ HEAD",
                 TextoGanhoQtdReaisFIX362(LADO_AMBOS,true),
                 c2,rowY,colW,PnlCorVerde(),fonte);
   }
   else
   {
      ObjectDelete(0, pfx + "_M9_L"); ObjectDelete(0, pfx + "_M9_V");
      ObjectDelete(0, pfx + "_M15_L"); ObjectDelete(0, pfx + "_M15_V");
   }
   DesenharCamposGanhoPerdaOperacao(pfx + "_GP", mx, y + altura - 26, mw, fonte, true);
}

string TimerAumentoCard(EstadoLado &estado, RegraAumento &aum)
{
   if(InpAumentosLivreTeste && InpAumentosLivreIgnorarTimerPreco)
      return "LIVRE";
   if(!aum.ativa)
      return "OFF";
   if(aum.tempoMinutos <= 0)
      return "--";
   if(!estado.posicaoAberta)
      return "--";
   datetime referencia = estado.horarioUltimoAumento;
   if(referencia <= 0)
      referencia = estado.horarioEntrada;
   if(referencia <= 0)
      return "--";
   int segundosNecessarios = aum.tempoMinutos * 60;
   int segundosPassados = (int)(TimeCurrent() - referencia);
   int segundosRestantes = segundosNecessarios - segundosPassados;
   if(segundosRestantes <= 0)
      return "OK";
   int minRest = segundosRestantes / 60;
   int segRest = segundosRestantes % 60;
   return StringFormat("%02dm%02ds", minRest, segRest);
}

void DesenharAumentosPremium(string pfx, EstadoLado &estado, int x, int y, int largura, int altura, int fonte)
{
   bool compacto = (largura < 820);
   PainelRetangulo(pfx + "_BG", x, y, largura, altura, PnlCorBloco2(), PnlCorLinha());
   PainelTextoCortado(pfx + "_TIT", "v Gerenciador de aumentos", x + 10, y + 8, PnlCorTitulo(), fonte + 1, "Arial Bold", largura - 70);
   PainelTexto(pfx + "_REAL", "[real]", x + largura - 54, y + 8, PnlCorVerde(), fonte, "Consolas");
   if(InpModoSimplesFIX195)
      SincronizarRealizacoesAumentosFIX296(false);
   bool slotVendaFIX281 = (estado.magic == MagicVendaAtual() || estado.magic == MagicPainelBAtual());
   RestaurarPrecosEntradaAumentosFIX220(estado);
   int ultimoNivelCard=0;
   double ultimoPrecoCard=UltimoPrecoAumentoAntesFIX220(estado,5,ultimoNivelCard);
   double ultimoBaseInicialFIX371=(estado.precoEntradaInicial>0.0 ? estado.precoEntradaInicial : estado.precoMedio);
   string ultimoCard=(ultimoBaseInicialFIX371>0.0 ? "A0 "+DoubleToString(ultimoBaseInicialFIX371,0) : "--");
   if(ultimoNivelCard>0 && ultimoPrecoCard>0.0)
      ultimoCard=StringFormat("A%d %.0f",ultimoNivelCard,ultimoPrecoCard);
   string baseCurtaCard=(InpBasePrecoAumento==BASE_ULTIMO_AUMENTO ? "ULTIMO" : (InpBasePrecoAumento==BASE_ENTRADA_INICIAL ? "A0" : "MEDIO"));
   double ancoraRearmeCard=AncoraRearmeA1FIX225(estado);
   int cicloRearmeCard=CicloRearmeA1FIX225(estado);
   if(ancoraRearmeCard>0.0)
      ultimoCard=StringFormat("ANC #%d %.0f",cicloRearmeCard,ancoraRearmeCard);
   double a0OriginalFIX358=(estado.precoEntradaInicial>0.0 ? estado.precoEntradaInicial : estado.precoMedio);

   // FIX371: cabecalho unico do Gerenciador. Remove as tres faixas repetidas
   // (contratos/plano, A0/base e GANHO/LOSS HEAD) e preserva apenas identificacao operacional.
   string statusCurtoFIX371=estado.posicaoAberta
                            ? StringFormat("%s %.0fC",estado.lado==LADO_VENDA?"VENDA":"COMPRA",estado.contratos)
                            : "SEM POS";
   string modoCurtoFIX371=InpAumentosLivreTeste ? "LIVRE" : "REGRA";
   string linhaCabecalhoFIX371=StringFormat("MAGIC %I64d | %s | BASE %s | ULT %s | PROX %s | MODO %s",
                                            estado.magic,statusCurtoFIX371,baseCurtaCard,ultimoCard,
                                            ProximoAumentoCard(estado),modoCurtoFIX371);
   PainelTextoCortado(pfx + "_L1",linhaCabecalhoFIX371,x+12,y+30,PnlCorTexto(),fonte,"Consolas",largura-24);
   ObjectDelete(0,pfx+"_L2");
   ObjectDelete(0,pfx+"_GANHO_QTD_RS");
   ObjectDelete(0,pfx+"_LOSS_HEAD");
   int yHead = y + (compacto ? 48 : 50);
   // FIX358: colunas distribuidas na largura total. Prog/Exec usa o formato solicitado 180650/180800.
   int cNivel    = x + 14;
   int cA0       = x + 58;
   int cProgExec = x + 145;
   int cDif      = x + 300;
   int cDistA0   = x + 370;
   int cQtd      = x + 475;
   int cGain     = x + 565;
   int cStop     = x + 655;
   int cTrail    = x + 730;
   int cTimer    = x + 840;
   int cStatus   = x + 900;
   int cAcum     = x + 970; // FIX449: ganho realizado acumulado do nivel.
   PainelTexto(pfx + "_H1",  "Niv",       cNivel,    yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H2",  "A0 orig",   cA0,       yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H3",  "Prog/Exec", cProgExec, yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H4",  "Dif P",     cDif,      yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H5",  "D.A0 P/R",  cDistA0,   yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H6",  "Qtd/T",     cQtd,      yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H7",  "Gain",      cGain,     yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H8",  "Stop",      cStop,     yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H9",  g_trailInteligenteLinhasAtivoFIX325 ? "Trail linha" : "Trailing", cTrail, yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H10", "Tmr",       cTimer,    yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H11", "Status",    cStatus,   yHead, PnlCorSecundario(), fonte, "Arial Bold");
   PainelTexto(pfx + "_H12", "Acum",      cAcum,     yHead, PnlCorSecundario(), fonte, "Arial Bold");
   int linhas = 4;
   int rowStart = y + (compacto ? 66 : 68);
   int rowStep = 18;
   for(int i = 0; i < linhas; i++)
   {
      int idx = i + 1;
      RegraAumento a = g_aumentos[i];
      int ly = rowStart + (i * rowStep);
      string status = StatusAumentoCard(estado, a, idx);
      ulong ticketNivel=0;
      double precoAbertoNivel=0.0,volumeAbertoNivel=0.0;
      long tipoAbertoNivel=-1;
      bool aumentoAberto=ObterPosicaoAumentoNivelFIX212(estado,idx,ticketNivel,precoAbertoNivel,volumeAbertoNivel,tipoAbertoNivel);
      double lucroAbertoNivel=0.0;
      if(aumentoAberto && PositionSelectByTicket(ticketNivel))
      {
         double lucroServidorNivel=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         double lucroManualNivel=LucroAbertoPosicaoSelecionada(tipoAbertoNivel);
         lucroAbertoNivel=(InpLucroAbertoUsarCalculoManual ? lucroManualNivel : lucroServidorNivel);
      }
      int qtdRealNivel=slotVendaFIX281 ? g_qtdRealizacoesNivelSellFIX324[i] : g_qtdRealizacoesNivelBuyFIX324[i];
      double volRealNivel=slotVendaFIX281 ? g_volumeRealizadoNivelSellFIX324[i] : g_volumeRealizadoNivelBuyFIX324[i];
      double finRealNivel=slotVendaFIX281 ? g_realizadoAumentosNivelSellFIX324[i] : g_realizadoAumentosNivelBuyFIX324[i];
      // FIX449: acumulado confirmado por nivel; novas realizacoes do mesmo nivel sao somadas.
      string txtAcumNivel=(MathAbs(finRealNivel)<0.005 ? "R$0" : StringFormat("%sR$%.0f",finRealNivel>0.0?"+":"-",MathAbs(finRealNivel)));
      if(qtdRealNivel>0)
         status=StringFormat("%dT | %s",qtdRealNivel,status);
      color rowBg = PnlCorLinhaAlternada(i);
      if(StringFind(status, "FEITO") >= 0 || StringFind(status, "PRONTO") >= 0 ||
         StringFind(status, "BLOQ") >= 0 || StringFind(status, "MAX") >= 0 ||
         StringFind(status, "AGUARDA") >= 0 || StringFind(status, "FILA") >= 0)
         rowBg = PnlCorStatusFundo(status);
      PainelRetangulo(pfx + "_ROW_" + IntegerToString(idx), x + 8, ly - 3, largura - 16, 18, rowBg, rowBg);
      string timerLinha = TimerAumentoCard(estado, a);
      double precoProgramadoAtualFIX358=PrecoNivelAumentoValorIndice(estado,i);
      double precoExecutadoAtualFIX358=PrecoEntradaAumentoFIX220(estado,idx);
      double precoProgramadoAudFIX358=PrecoProgramadoAuditoriaAumentoFIX358(estado,idx);
      double precoExecutadoAudFIX358=PrecoExecutadoAuditoriaAumentoFIX358(estado,idx);
      double precoProgramadoExibidoFIX358=(precoExecutadoAudFIX358>0.0 && precoProgramadoAudFIX358>0.0 ? precoProgramadoAudFIX358 : precoProgramadoAtualFIX358);
      double precoExecutadoExibidoFIX358=(precoExecutadoAtualFIX358>0.0 ? precoExecutadoAtualFIX358 : precoExecutadoAudFIX358);
      string txtA0FIX358=(a0OriginalFIX358>0.0 ? DoubleToString(a0OriginalFIX358,_Digits) : "--");
      string txtProgFIX358=(precoProgramadoExibidoFIX358>0.0 ? DoubleToString(precoProgramadoExibidoFIX358,_Digits) : "--");
      string txtExecFIX358=(precoExecutadoExibidoFIX358>0.0 ? DoubleToString(precoExecutadoExibidoFIX358,_Digits) : "--");
      string txtProgExecFIX358=txtProgFIX358+"/"+txtExecFIX358;
      double difPtsFIX358=0.0;
      bool temDifFIX358=(precoProgramadoExibidoFIX358>0.0 && precoExecutadoExibidoFIX358>0.0 && _Point>0.0);
      if(temDifFIX358) difPtsFIX358=(precoExecutadoExibidoFIX358-precoProgramadoExibidoFIX358)/_Point;
      string txtDifFIX358=(temDifFIX358 ? StringFormat("%s%.0f",difPtsFIX358>0.0?"+":"",difPtsFIX358) : "--");
      double distProgA0FIX358=(a0OriginalFIX358>0.0 && precoProgramadoExibidoFIX358>0.0 && _Point>0.0 ? MathAbs(precoProgramadoExibidoFIX358-a0OriginalFIX358)/_Point : 0.0);
      double distExecA0FIX358=(a0OriginalFIX358>0.0 && precoExecutadoExibidoFIX358>0.0 && _Point>0.0 ? MathAbs(precoExecutadoExibidoFIX358-a0OriginalFIX358)/_Point : 0.0);
      string txtDistA0FIX358=(distProgA0FIX358>0.0 ? StringFormat("%.0f/%s",distProgA0FIX358,(distExecA0FIX358>0.0 ? DoubleToString(distExecA0FIX358,0) : "--")) : "--/--");
      color corDifFIX358=PnlCorCinza();
      if(temDifFIX358)
      {
         double absDifFIX358=MathAbs(difPtsFIX358);
         corDifFIX358=(absDifFIX358<=0.5 ? PnlCorVerde() : (absDifFIX358<=5.0 ? PnlCorAmarelo() : PnlCorVermelho()));
      }
      double volumeTotalNivel=volRealNivel+(aumentoAberto ? volumeAbertoNivel : 0.0);
      double financeiroTotalNivel=finRealNivel+lucroAbertoNivel;
      string txtQtdNivel=StringFormat("%.0fC/%dT",volumeTotalNivel,qtdRealNivel);
      double alvoNivel=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*MathMax(1.0,a.qtd);
      double stopNivel=MathAbs(InpLossAumentoPorContratoReaisFIX321)*MathMax(1.0,a.qtd);
      string txtGain=StringFormat("%.0f/%.0f",financeiroTotalNivel,alvoNivel);
      string txtStop=StringFormat("-%.0f",stopNivel);
      double trailAtivar=(a.trailingAtivarReais>0.0 ? a.trailingAtivarReais : MathAbs(InpTrailingAumentoAtivarReaisFIX281));
      double trailPasso=(a.trailingPassoReais>0.0 ? a.trailingPassoReais : MathAbs(InpTrailingAumentoPassoReaisFIX281));
      bool trailArmado=false;
      double trailDefesa=0.0;
      if(aumentoAberto)
      {
         if(slotVendaFIX281)
         {
            trailArmado=(g_trailAumentoSell[i].ticket==ticketNivel && g_trailAumentoSell[i].protecaoArmada);
            trailDefesa=g_trailAumentoSell[i].defesaAtual;
         }
         else
         {
            trailArmado=(g_trailAumentoBuy[i].ticket==ticketNivel && g_trailAumentoBuy[i].protecaoArmada);
            trailDefesa=g_trailAumentoBuy[i].defesaAtual;
         }
      }
      string txtTrail=trailArmado ? StringFormat("ARM %.0f",trailDefesa) : StringFormat("%.0f/%.0f",trailAtivar,trailPasso);
      if(g_trailInteligenteLinhasAtivoFIX325)
      {
         double stopLinha=slotVendaFIX281 ? g_trailAumentoSell[i].stopPrecoFIX325 : g_trailAumentoBuy[i].stopPrecoFIX325;
         double distLinha=slotVendaFIX281 ? g_trailAumentoSell[i].distanciaAtualPontosFIX325 : g_trailAumentoBuy[i].distanciaAtualPontosFIX325;
         txtTrail=(trailArmado && stopLinha>0.0)
                  ? StringFormat("SL %.0f D%.0f",stopLinha,distLinha)
                  : StringFormat("A%.0f P%.0f",g_trailInteligenteAtivaPontosFIX325,g_trailInteligentePassoPontosFIX325);
         if(trailArmado)
            status="TR INT | "+status;
      }
      PainelTexto(pfx + "_A" + IntegerToString(idx) + "_N",  StringFormat("A%d", idx), cNivel, ly, a.ativa ? PnlCorTitulo() : PnlCorCinza(), fonte, "Consolas");
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_A0", txtA0FIX358, cA0, ly, a0OriginalFIX358>0.0 ? PnlCorTexto() : PnlCorCinza(), fonte, "Consolas", cProgExec-cA0-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_PE", txtProgExecFIX358, cProgExec, ly, precoExecutadoExibidoFIX358>0.0 ? PnlCorVerde() : PnlCorAmarelo(), fonte, "Consolas", cDif-cProgExec-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_DF", txtDifFIX358, cDif, ly, corDifFIX358, fonte, "Consolas", cDistA0-cDif-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_DA0", txtDistA0FIX358, cDistA0, ly, precoExecutadoExibidoFIX358>0.0 ? PnlCorVerde() : PnlCorTexto(), fonte, "Consolas", cQtd-cDistA0-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_QA", txtQtdNivel, cQtd, ly, volumeTotalNivel>0.0 ? PnlCorVerde() : PnlCorCinza(), fonte, "Consolas", cGain-cQtd-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_GAIN", txtGain, cGain, ly, CorFinanceiro(financeiroTotalNivel), fonte, "Consolas", cStop-cGain-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_STOP", txtStop, cStop, ly, PnlCorVermelho(), fonte, "Consolas", cTrail-cStop-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_TR", txtTrail, cTrail, ly, trailArmado ? PnlCorVerde() : PnlCorAmarelo(), fonte, "Consolas", cTimer-cTrail-3);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_TM", timerLinha, cTimer, ly, (timerLinha == "OK" || timerLinha=="--") ? PnlCorVerde() : PnlCorAmarelo(), fonte, "Consolas", cStatus-cTimer-4);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_S", status, cStatus, ly, CorStatusTexto(status), fonte, "Arial Bold", cAcum-cStatus-4);
      PainelTextoCortado(pfx + "_A" + IntegerToString(idx) + "_ACUM", txtAcumNivel, cAcum, ly, CorFinanceiro(finRealNivel), fonte, "Consolas", largura - (cAcum - x) - 12);
      // Remove os nomes antigos da grade para evitar qualquer sobreposicao apos atualizar do FIX357.
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_G");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_D");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_PX");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_QX_BG");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_QX");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_QT");
      ObjectDelete(0,pfx + "_A" + IntegerToString(idx) + "_FI");
   }
   HistoricoPeriodo hTmp;
   ObterHistoricoPainelPrincipal(hTmp);
   double contratosDireto = 0.0;
   double abertoDireto = 0.0;
   CalcularAbertoContratosPorMagicDireto(estado.magic, contratosDireto, abertoDireto);
   double contratosAbertosOperacao = contratosDireto > 0.0 ? contratosDireto : (estado.posicaoAberta ? estado.contratos : 0.0);
   double abertoAtual = contratosDireto > 0.0 ? abertoDireto : (estado.posicaoAberta ? estado.resultadoAberto : 0.0);
   double parcialLiquida = ParcialHistoricoDoSlotPainel(hTmp, estado);
   double financeiroAumentosRealizado=0.0;
   double volumeAumentosRealizado=0.0;
   int qtdAumentosRealizados=0;
   if(InpModoSimplesFIX195)
   {
      parcialLiquida = slotVendaFIX281 ? g_parciaisCicloSell : g_parciaisCicloBuy;
      financeiroAumentosRealizado = slotVendaFIX281 ? g_realizadoAumentosCicloSell : g_realizadoAumentosCicloBuy;
      volumeAumentosRealizado = slotVendaFIX281 ? g_volumeRealizadoAumentosCicloSell : g_volumeRealizadoAumentosCicloBuy;
      qtdAumentosRealizados = slotVendaFIX281 ? g_qtdRealizacoesAumentosCicloSell : g_qtdRealizacoesAumentosCicloBuy;
   }
   double totalOperacao = abertoAtual + parcialLiquida;
   double qtdAumentosAbertos=0.0;
   double valorAumentosAbertos=0.0;
   int ticketsAumentosAbertos=0;
   CalcularAumentosAbertosLadoFIX281(estado,qtdAumentosAbertos,valorAumentosAbertos,ticketsAumentosAbertos);
   double valorEntradaAberto=abertoAtual-valorAumentosAbertos;
   // FIX371: unica faixa-resumo abaixo da tabela; nenhum total financeiro e repetido no topo.
   int yTotalParcial = y + altura - 36;
   PainelRetangulo(pfx + "_PARC_BG", x + 8, yTotalParcial - 3, largura - 16, 18, PnlCorBloco(), CorFinanceiro(totalOperacao));
   FotoFinanceiraPainelFIX362 fotoResumoFIX371;
   MontarFotoFinanceiraPainelFIX362(fotoResumoFIX371,false);
   double contratosProjetadosResumoFIX372=MathMax(0.0,contratosAbertosOperacao);
   double garantiaNecResumoFIX372=contratosProjetadosResumoFIX372*MathAbs(InpGarantiaPorContratoReaisFIX372);
   string linhaResumoUnicaFIX371 = StringFormat("TOT %s | A0 %s | AUM %.0fC/%dT %s | REAL %dT/%.0fC %s | GAR %.0f/%.0f | ALV %.0f | LOS %.0f | TR %.0f/%.0f",
                                                TextoFinanceiroHistoricoCompactoFIX369(totalOperacao),
                                                TextoFinanceiroHistoricoCompactoFIX369(valorEntradaAberto),
                                                qtdAumentosAbertos,ticketsAumentosAbertos,
                                                TextoFinanceiroHistoricoCompactoFIX369(valorAumentosAbertos),
                                                qtdAumentosRealizados,volumeAumentosRealizado,
                                                TextoFinanceiroHistoricoCompactoFIX369(financeiroAumentosRealizado),
                                                garantiaNecResumoFIX372,MathAbs(InpGarantiaPorLadoReaisFIX372),
                                                MathAbs(InpGanhoPorTicketReaisFIX372),
                                                MathAbs(InpPerdaPorTicketReaisFIX372),
                                                MathAbs(InpTrailingAtivarTicketReaisFIX372),
                                                MathAbs(InpTrailingPassoTicketReaisFIX372));
   PainelTextoCortado(pfx + "_PARC_T", linhaResumoUnicaFIX371, x + 14, yTotalParcial, CorFinanceiro(totalOperacao), fonte, "Consolas", largura - 28);
   ObjectDelete(0, pfx + "_PARC_VL_AUM");
   ObjectDelete(0, pfx + "_PARC_Q");
   ObjectDelete(0, pfx + "_PARC_V");
   ObjectDelete(0, pfx + "_PARC_C");
   int indiceScoreResumo = estado.aumentosExecutados;
   if(indiceScoreResumo < 0) indiceScoreResumo = 0;
   if(indiceScoreResumo > 4) indiceScoreResumo = 4;
   string msgAumento = estado.motivoBloqueioAumento;
   if(msgAumento == "")
      msgAumento = (InpAumentosLivreTeste && !InpAumentosLivreIgnorarTimerPreco)
                   ? StringFormat("AUMENTOS | LINHA+CANDLE M1+PRECO MELHOR | FILTROS OFF | BASE %s | DIR %s", NomeBasePrecoAumentoFIX220(), InpAumentosContraPosicao ? "CONTRA" : "FAVOR")
                   : (InpAumentosLivreTeste
                      ? StringFormat("LIVRE_TOTAL DESATIVADO PELO FIX363 | DIR %s | candle e preco continuam obrigatorios.", InpAumentosContraPosicao ? "CONTRA" : "FAVOR")
                      : (g_scoreAumentos.ativo
                         ? TextoScoreAumentoNivel(estado, indiceScoreResumo) + " | ORIGEM AUMENTOS"
                         : StringFormat("FILTROS AUMENTOS: %s | Score %.1f/%.0f.",g_perfilAumentosFIX372,g_mercado.scoreFluxo,g_gerAumentos.scoreExtremo)));
   PainelTextoCortado(pfx + "_MSG", "Status: " + msgAumento + " | Prog/Exec | Dif=Exec-Prog | D.A0=Programada/Real", x + 12, y + altura - 14, PnlCorSecundario(), fonte, "Consolas", largura - 24);
}

void DesenharIndicadoresEntrada(string pfx, EstadoLado &estado, int x, int y, int largura, int altura, int fonte)
{
   PainelRetangulo(pfx+"_BG",x,y,largura,altura,PnlCorBloco(),PnlCorLinha());
   PainelTexto(pfx+"_TIT","v Entrada / parametros ativos",x+10,y+7,PnlCorTitulo(),fonte+1,"Arial Bold");

   RegraJanela janela;
   bool temJanela=ExisteJanelaAtivaParaLado(estado.lado,janela);
   bool stftOk=(!ReentradaTimerAtivo() || estado.bloqueioReentradaAte<=0 || TimeCurrent()>=estado.bloqueioReentradaAte);
   bool auditoriaOk=(!InpAuditoriaTesteFIX274 || g_auditoriaTesteFIX274OK);
   bool ordemOk=(InpPermitirEnvioOrdens && auditoriaOk);
   bool modoMasterFIX278=(InpFIX278UmaJanelaAbreDuasPontas && JanelaAtualEhA_FIX255());
   bool janelaPassivaFIX278=(InpFIX278UmaJanelaAbreDuasPontas && JanelaAtualEhB_FIX255());

   string linha1="";
   string linha2="";
   string linha3="";

   if(!estado.posicaoAberta)
   {
      if(modoMasterFIX278)
      {
         string statusMaster="PRONTO";
         if(BloquearNovasOperacoesFimDiaFIX215())
            statusMaster="FIM DIA";
         else if(!stftOk)
            statusMaster="REENTRADA AGUARDA";
         else if(!auditoriaOk)
            statusMaster="AUDITORIA FALHOU";
         else if(!InpPermitirEnvioOrdens)
            statusMaster="ORDEM TRAVADA";

         if(EntradaDiretaDemoEfetivaFIX302())
         {
            linha1=StringFormat("FIX280 DIRETO %s | %s",statusMaster,g_fix279StatusGeral);
            linha2=StringFormat("%s | %s",g_fix279StatusCompra,g_fix279StatusVenda);
            linha3=StringFormat("PONTA R$%.0f | HEAD GAIN R$%.0f LOSS R$%.0f | TRAIL %.0f/%.0f | DX +/-%.0f",
                                InpEntradaGanhoAlvoReais, GainGlobalCestaAB(), StopBaseCestaAB(),
                                g_entradaTrailingAtivarReaisEfetivo, g_entradaTrailingPassoReaisEfetivo,
                                MathAbs(InpFIX280DistanciaBandaDXPontos));
         }
         else
         {
            linha1=StringFormat("FIX278 MASTER %s | A0 IMEDIATO | ABRE COMPRA + VENDA",statusMaster);
            linha2=StringFormat("C %.0fC M%d | V %.0fC M%d | SEM FILTRO | COORD BYPASS",
                                InpEntradaContratos,(int)MagicCompraAtual(),
                                InpEntradaContratos,(int)MagicVendaAtual());
            linha3=StringFormat("PONTA R$%.0f | HEAD GAIN R$%.0f LOSS R$%.0f | TRAIL %.0f/%.0f | DX +/-%.0f",
                                InpEntradaGanhoAlvoReais, GainGlobalCestaAB(), StopBaseCestaAB(),
                                g_entradaTrailingAtivarReaisEfetivo, g_entradaTrailingPassoReaisEfetivo,
                                MathAbs(InpFIX280DistanciaBandaDXPontos));
         }
      }
      else if(janelaPassivaFIX278)
      {
         linha1="FIX278 JANELA B PASSIVA | NAO ENVIA ORDENS";
         linha2="USE SOMENTE A JANELA A MASTER PARA ABRIR COMPRA + VENDA";
         linha3=StringFormat("MAGICS C %d | V %d | EVITA DUPLICIDADE",
                             (int)MagicCompraAtual(),(int)MagicVendaAtual());
      }
      else
      {
         string decisao="A0 LIVRE";
         if(BloquearNovasOperacoesFimDiaFIX215())
            decisao="FIM DIA";
         else if(!g_ambienteLiberado)
            decisao="AMBIENTE BLOQUEADO";
         else if(!temJanela && !EntradaDiretaDemoEfetivaFIX302())
            decisao="SEM JANELA";
         else if(!stftOk)
            decisao="REENTRADA AGUARDA";
         else if(!auditoriaOk)
            decisao="AUDITORIA FALHOU";
         else if(!InpPermitirEnvioOrdens)
            decisao="ORDEM TRAVADA";

         if(EntradaDiretaDemoEfetivaFIX302())
         {
            string statusDireto=g_fix279StatusGeral;
            if(!g_ambienteLiberado)
               statusDireto=g_mestre.mensagemAmbiente;
            if(statusDireto=="")
               statusDireto="PRONTA PARA ENVIAR";
            linha1=StringFormat("A0 DIRETA %s | %s",estado.nome,statusDireto);
            linha2=StringFormat("%.0fC | %s | LOCK MAGIC %d | %s",
                                InpEntradaContratos,TextoComoAbrirPrimeiraOrdemFIX314(),
                                (int)estado.magic,TextoControleMagicFIX285(estado.magic));
            linha3=StringFormat("ALVO R$%.0f | STOP R$%.0f | SL SERVIDOR %.0f PTS | %s",
                                InpEntradaGanhoAlvoReais,InpEntradaPerdaMaximaReais,
                                InpStopServidorEmergenciaPontosFIX342,
                                g_statusCoordenacaoMagics_FIX256);
         }
         else
         {
            linha1=StringFormat("DECISAO %s | %s | JANELA %s",
                                decisao,estado.nome,temJanela ? janela.horario : "--");
            linha2=StringFormat("A0 %.0fC | MODO %s | HEAD A+B | REENTRADA %ds",
                                InpEntradaContratos,TextoModoEntradaA0FIX310(),InpPausaReentradaSegundos);
            linha3=StringFormat("DX%d/M%d D%.0f LEITURA | ALVO R$%.0f | STOP R$%.0f",
                                InpDXPeriodo,InpDXMediaPeriodo,InpDXDistanciaMedia,
                                InpEntradaGanhoAlvoReais,InpEntradaPerdaMaximaReais);
         }
      }
   }
   else
   {
      int d1=(ArraySize(g_aumentos)>0 ? g_aumentos[0].distanciaPontos : 0);
      int d2=(ArraySize(g_aumentos)>1 ? g_aumentos[1].distanciaPontos : 0);
      string entradasExecutadas=(estado.aumentosExecutados>0
                                 ? StringFormat("A0+A%d EXEC | %.0fC ABERTO",estado.aumentosExecutados,estado.contratos)
                                 : StringFormat("A0 EXEC | %.0fC ABERTO",estado.contratos));
      linha1=StringFormat("ENTRADAS %s | POS %s | FIN %s",
                          entradasExecutadas,TextoPosicaoCard(estado),PnlMoedaBRL(estado.resultadoAberto));
      linha2=StringFormat("A1 +1C D%d | A2 +1C D%d | MAX %dC | BASE ULTIMO",
                          d1,d2,g_gerAumentos.maxContratos);
      linha3=StringFormat("AUM ALVO R$%.0f TR %.0f/%.0f | PONTA R$%.0f TR %.0f/%.0f | HEAD %.0f/-%.0f",
                          InpLucroAumentoPorContratoReaisFIX207,InpTrailingAumentoAtivarReaisFIX281,InpTrailingAumentoPassoReaisFIX281,
                          InpEntradaGanhoAlvoReais,g_entradaTrailingAtivarReaisEfetivo,g_entradaTrailingPassoReaisEfetivo,
                          GainGlobalCestaAB(),StopBaseCestaAB());
   }

   if(InpFiltroRangeAtivoFIX344 || InpGridEntradasAtivoFIX344)
      linha2+=" | "+g_statusRangeGridFIX344;

   bool contextoEntradaOK=(modoMasterFIX278 ? true : temJanela);
   color corLinha1=(ordemOk && contextoEntradaOK && stftOk && !BloquearNovasOperacoesFimDiaFIX215() && !janelaPassivaFIX278)
                   ? PnlCorVerde() : PnlCorSecundario(); // FIX413: sem mensagem amarela piscando
   if(estado.posicaoAberta)
      corLinha1=PnlCorTexto();

   PainelTextoCortado(pfx+"_I1",linha1,x+12,y+27,corLinha1,
                      fonte,"Consolas",largura-24);
   PainelTextoCortado(pfx+"_I2",linha2,x+12,y+44,PnlCorSecundario(), // FIX413: texto neutro
                      fonte,"Consolas",largura-24);
   if(altura>=65)
      PainelTextoCortado(pfx+"_I3",linha3,x+12,y+61,
                         PnlCorSecundario(), // FIX413: sem amarelo piscando
                         fonte,"Consolas",largura-24);
   else
      ObjectDelete(0,pfx+"_I3");

   ObjectDelete(0,pfx+"_HEAD");
   ObjectDelete(0,pfx+"_GER");
}

void DesenharMsgBoxVisual3s(string pfx, EstadoLado &estado, int x, int y, int largura, int altura, int fonte)
{
   // FIX415: remove qualquer objeto antigo e não desenha MsgBox visual.
   LimparMsgBoxVisualFIX226(pfx);
   return;
   if(!MsgBoxVisualAtivaFIX226())
   {
      LimparMsgBoxVisualFIX226(pfx);
      return;
   }

   PainelRetangulo(pfx+"_BG",x,y,largura,altura,C'0,120,212',clrWhite);
   string titulo=(g_msgBoxVisualTituloFIX226!="" ? g_msgBoxVisualTituloFIX226 : "EVENTO DA OPERACAO");
   string linha1=(g_msgBoxVisualLinha1FIX226!="" ? g_msgBoxVisualLinha1FIX226 : g_mestre.mensagemGeral);
   string linha2=(g_msgBoxVisualLinha2FIX226!="" ? g_msgBoxVisualLinha2FIX226 : TimeToString(g_msgBoxVisualHoraFIX226,TIME_SECONDS));

   PainelTextoCortado(pfx+"_TIT",titulo,x+10,y+7,clrWhite,fonte+1,"Arial Bold",largura-20);
   PainelTextoCortado(pfx+"_MSG",linha1,x+10,y+27,clrWhite,fonte,"Consolas",largura-20);
   if(altura>=58)
      PainelTextoCortado(pfx+"_SCORE",linha2,x+10,y+45,clrWhite,fonte,"Consolas",largura-20);
   else
      ObjectDelete(0,pfx+"_SCORE");
}

void DesenharCardAumentos(EstadoLado &estado, int x, int y, int largura, int altura)
{
   string pfx = "COPA_AR100_CARD_";
   int fonteTitulo = InpPainelFonteTitulo;
   int fonteTexto = InpPainelFonteTexto;
   if(fonteTitulo < 9) fonteTitulo = 9;
   if(fonteTexto < 7) fonteTexto = 7;
   if(fonteTexto > 8) fonteTexto = 8;
   if(largura < 1280 || altura < 900)
      fonteTexto = 7;
   PainelRetangulo(pfx + "FUNDO", x, y, largura, altura, PnlCorFundo(), PnlCorLinha());
   int headerH = (altura < 900 ? 70 : 76);
   PainelRetangulo(pfx + "HDR_BG", x + 10, y + 8, largura - 20, headerH - 12, PnlCorAbaAtiva(), PnlCorAbaAtiva());
   string dt = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   PainelTextoCortado(pfx + "HDR_T1",
               StringFormat("COPA / AR_100 | MESTRE | %s | F:%s E:%s | %s", _Symbol, NomeTimeframeCurto(TimeframeFiltroAtualFIX255()), NomeTimeframeCurto(TimeframeEntradaAtualFIX255()), dt),
               x + 22, y + 18, clrWhite, fonteTitulo, "Arial Bold", largura - 460);
   PainelTextoCortado(pfx + "HDR_T2",
               "HORARIOS: " + LinhaJanelaCabecalho(0) + " | " + LinhaJanelaCabecalho(1) + " | " + LinhaJanelaCabecalho(2),
               x + 22, y + 38, C'219,234,254', fonteTexto, "Consolas", largura - 44);
   PainelTextoCortado(pfx + "HDR_T3",
               StringFormat("%s | %s | Painel: %s | Ordens: %s | Controle: %s",
                            LinhaJanelaCabecalho(3),
                            TextoStatusFimDiaFIX215(),
                            NomeModoPainelVisual(g_modoPainelVisualAtivo),
                            InpPermitirEnvioOrdens ? "LIBERADAS" : "TRAVADAS",
                            TextoControleOperacaoFIX284()),
               x + 22, y + 55, InpPermitirEnvioOrdens ? PnlCorVerde() : PnlCorAmarelo(), fonteTexto, "Consolas", 520);
   PainelTextoCortado(pfx + "HDR_MAGIC", TextoMagicTopoPiscando(), x + 560, y + 55, CorMagicPiscando(clrWhite), fonteTexto + 1, "Arial Bold", largura - 580);
   DesenharBotoesModoPainel(pfx + "BTN_", x + largura - 250, y + 16, fonteTexto);
   PainelTextoCortado(pfx + "HDR_DX", TextoDXConfigPainel(), x + 22, y + 74, PnlCorAmarelo(), fonteTexto, "Consolas", largura - 44);
   int gap = (altura < 900 ? 8 : 10);
   int finY = y + (altura < 900 ? 84 : 92);
   int finH = (altura < 820 ? 324 : (altura < 900 ? 356 : 382));
   int aumH = (altura < 820 ? 208 : (altura < 1000 ? 218 : 228));
   int indH = (altura < 820 ? 56 : (altura < 1000 ? 62 : 78));
   int minHistH = (altura < 820 ? 76 : 82);
   int alvoHistH = (altura < 820 ? 42 : 50);
   // FIX235: historico head mais compacto para liberar espaco aos cards de resumo.
   int histYPrev = finY + finH + gap + aumH + gap + indH + gap;
   int histHPrev = (y + altura - 8) - histYPrev;
   if(histHPrev > alvoHistH)
      finH += (histHPrev - alvoHistH);

   histYPrev = finY + finH + gap + aumH + gap + indH + gap;
   histHPrev = (y + altura - 8) - histYPrev;
   if(histHPrev < minHistH)
   {
      int falta = minHistH - histHPrev;
      int red = 0;
      red = (int)MathMin((double)falta, (double)MathMax(0, finH - (altura < 820 ? 300 : 326)));
      finH -= red;
      falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, aumH - 198));
      aumH -= red;
      falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, indH - 52));
      indH -= red;
      falta -= red;
      if(falta > 0 && gap > 6)
      {
         int reduzirGap = (int)MathMin((double)(gap - 6), (double)((falta + 3) / 4));
         gap -= reduzirGap;
      }
   }
   int boxW = (largura - 36 - gap) / 2;
   int bx1 = x + 12;
   int bx2 = bx1 + boxW + gap;
   HistoricoPeriodo histPainel;
   ObterHistoricoPainelPrincipal(histPainel);
   EstadoLado estadoResumoLocal;
   ObterEstadoResumoPainelLocal(estadoResumoLocal);
   string tituloResumoLocal = TituloResumoLocalPainel(estadoResumoLocal);
   DesenharResumoFinanceiroLado(pfx + "FIN_A", tituloResumoLocal, estadoResumoLocal, histPainel, bx1, finY, boxW, finH, fonteTexto);
   DesenharResumoFinanceiroTotal(pfx + "FIN_T", histPainel, bx2, finY, boxW, finH, fonteTexto);
   int aumY = finY + finH + gap;
   // FIX324: o antigo quadro lateral "Entrada e reforcos" foi removido.
   // O gerenciador usa toda a largura para exibir QTD total, gain, stop e trailing por nivel.
   int aumW = largura - 24;
   DesenharAumentosPremium(pfx + "AUM", estado, x + 12, aumY, aumW, aumH, fonteTexto);
   int indY = aumY + aumH + gap;
   int faixaW = largura - 24;
   bool msgAtivaFIX226=MsgBoxVisualAtivaFIX226();
   int indW=faixaW;
   int msgW=0;
   int msgX=x+12+faixaW;
   if(msgAtivaFIX226)
   {
      indW=(int)MathRound((double)(faixaW-gap)*0.58);
      if(indW<620) indW=620;
      if(indW>faixaW-gap-380) indW=faixaW-gap-380;
      msgW=faixaW-gap-indW;
      msgX=x+12+indW+gap;
   }
   DesenharIndicadoresEntrada(pfx+"IND",estado,x+12,indY,indW,indH,fonteTexto);
   if(msgAtivaFIX226)
      DesenharMsgBoxVisual3s(pfx+"EVT",estado,msgX,indY,msgW,indH,fonteTexto);
   else
      LimparMsgBoxVisualFIX226(pfx+"EVT");
   int histY = indY + indH + gap + 4;
   int histH = (y + altura - 8) - histY;
   if(histH < 76)
      histH = 76;
   DesenharCardHistorico(x + 12, histY, largura - 24, histH);
}

double DistanciaPrecoPorFinanceiro(double valorReais, double volume)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(valorReais <= 0.0 || volume <= 0.0 || tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;
   double ticks = valorReais / (tickValue * volume);
   return ticks * tickSize;
}

double GatilhoParcialEfetivoPorVolume(double valorBaseReais, double volume)
{
   double base = MathAbs(valorBaseReais);
   if(base <= 0.0)
      return 0.0;
   if(ParcialPorContratoEfetivo() && volume > 0.0)
      return base * volume;
   return base;
}

double GatilhoParcialEfetivoLado(EstadoLado &estado, double valorBaseReais)
{
   return GatilhoParcialEfetivoPorVolume(valorBaseReais, estado.contratos);
}

double GatilhoParcialEfetivoCestaAB(double valorBaseReais)
{
   double qtdCompra = 0.0;
   double qtdVenda = 0.0;
   double totalBruto = 0.0;
   double abertoCompra = 0.0;
   double abertoVenda = 0.0;
   double abertoTotal = 0.0;
   CalcularAbertoTotalABGrupoDiretoBase(qtdCompra, qtdVenda, totalBruto, abertoCompra, abertoVenda, abertoTotal);
   return GatilhoParcialEfetivoPorVolume(valorBaseReais, totalBruto);
}

double DistanciaAcumuladaAumentoPontos(int indiceZero)
{
   if(indiceZero < 0)
      indiceZero = 0;
   if(indiceZero >= ArraySize(g_aumentos))
      indiceZero = ArraySize(g_aumentos) - 1;
   if(InpAumentosDistanciaAbsolutaEntrada && indiceZero >= 0 && indiceZero < ArraySize(g_aumentos))
   {
      double distAbs = (double)MathMax(0, g_aumentos[indiceZero].distanciaPontos);
      if(distAbs > 0.0)
         return distAbs;
   }
   double totalPontos = 0.0;
   for(int i = 0; i <= indiceZero && i < ArraySize(g_aumentos); i++)
   {
      if(g_aumentos[i].ativa && g_aumentos[i].distanciaPontos > 0)
         totalPontos += (double)g_aumentos[i].distanciaPontos;
   }
   if(totalPontos <= 0.0 && indiceZero >= 0 && indiceZero < ArraySize(g_aumentos))
      totalPontos = (double)MathMax(0, g_aumentos[indiceZero].distanciaPontos);
   return totalPontos;
}

double PrecoNivelAumentoValorIndice(EstadoLado &estado, int indiceZero)
{
   double entradaA0=(estado.precoEntradaInicial>0.0 ? estado.precoEntradaInicial : estado.precoMedio);
   if(!estado.posicaoAberta || entradaA0<=0.0 || indiceZero<0 || indiceZero>=ArraySize(g_aumentos))
      return 0.0;

   double base=entradaA0;
   double pontos=DistanciaAcumuladaAumentoPontos(indiceZero);
   double ancoraRearme=AncoraRearmeA1FIX225(estado);
   int nivelInicioRearme=NivelInicioRearmeFIX248(estado);
   int nivelBase=0;
   double ultimo=UltimoPrecoAumentoAntesFIX220(estado,indiceZero,nivelBase);

   // FIX331: o primeiro nível liberado pela parcial parte da âncora do último
   // aumento real deste lado. A média atual não aproxima a nova exposição.
   if(InpRearmarA1AposParcialFIX225 && ancoraRearme>0.0 && nivelInicioRearme>0 && indiceZero==nivelInicioRearme-1)
   {
      base=ancoraRearme;
      pontos=PassoAumentoPontosFIX220(indiceZero); // FIX357: no rearme, próximo ticket avança um passo de 150 pontos da âncora
   }
   else if(InpRearmarA1AposParcialFIX225 && ancoraRearme>0.0 && nivelInicioRearme>0 && indiceZero>nivelInicioRearme-1)
   {
      double precoNivelAnterior=PrecoEntradaAumentoFIX220(estado,indiceZero);
      if(precoNivelAnterior<=0.0)
         return 0.0;
      base=precoNivelAnterior;
      pontos=PassoAumentoPontosFIX220(indiceZero);
   }
   else if(indiceZero>0 && InpBasePrecoAumento==BASE_ULTIMO_AUMENTO && ultimo>0.0)
   {
      base=ultimo;
      pontos=PassoAumentoPontosFIX220(indiceZero);
   }
   else if(indiceZero>0 && InpBasePrecoAumento==BASE_PRECO_MEDIO_PROTEGIDO && estado.precoMedio>0.0)
   {
      base=estado.precoMedio;
      if(ultimo>0.0)
      {
         bool direcaoSobe=((estado.lado==LADO_COMPRA && !InpAumentosContraPosicao) ||
                           (estado.lado==LADO_VENDA  &&  InpAumentosContraPosicao));
         base=direcaoSobe ? MathMax(base,ultimo) : MathMin(base,ultimo);
      }
      pontos=(ultimo>0.0 ? PassoAumentoPontosFIX220(indiceZero) : DistanciaAcumuladaAumentoPontos(indiceZero));
   }

   if(pontos<=0.0)
      return 0.0;
   double distancia=pontos*_Point;
   if(estado.lado==LADO_COMPRA)
      return InpAumentosContraPosicao ? (base-distancia) : (base+distancia);
   if(estado.lado==LADO_VENDA)
      return InpAumentosContraPosicao ? (base+distancia) : (base-distancia);
   return 0.0;
}
void LimparPlotagemPrefixo(string prefixo)
{
   ObjectDelete(0, prefixo + "_LIN");
   ObjectDelete(0, prefixo + "_BG");
   ObjectDelete(0, prefixo + "_TX");
}

void LimparPlotagemOperacional()
{
   string prefixos[] = {
      "C_ENT", "C_GAIN", "C_STOP", "C_PROT",
      "C_PAR1", "C_PAR2", "C_PAR3", "C_PAR4", "C_PAR5",
      "C_A1", "C_A2", "C_A3", "C_A4", "C_A5",
      "C_TRAIL_A0", "C_TRAIL_A1", "C_TRAIL_A2", "C_TRAIL_A3", "C_TRAIL_A4", "C_TRAIL_A5",
      "V_ENT", "V_GAIN", "V_STOP", "V_PROT",
      "V_PAR1", "V_PAR2", "V_PAR3", "V_PAR4", "V_PAR5",
      "V_A1", "V_A2", "V_A3", "V_A4", "V_A5",
      "V_TRAIL_A0", "V_TRAIL_A1", "V_TRAIL_A2", "V_TRAIL_A3", "V_TRAIL_A4", "V_TRAIL_A5",
      "COPA_AR100_PLOT_C_ENT", "COPA_AR100_PLOT_C_GAIN", "COPA_AR100_PLOT_C_STOP", "COPA_AR100_PLOT_C_PROT",
      "COPA_AR100_PLOT_C_A1", "COPA_AR100_PLOT_C_A2", "COPA_AR100_PLOT_C_A3", "COPA_AR100_PLOT_C_A4", "COPA_AR100_PLOT_C_A5",
      "COPA_AR100_PLOT_V_ENT", "COPA_AR100_PLOT_V_GAIN", "COPA_AR100_PLOT_V_STOP", "COPA_AR100_PLOT_V_PROT",
      "COPA_AR100_PLOT_V_A1", "COPA_AR100_PLOT_V_A2", "COPA_AR100_PLOT_V_A3", "COPA_AR100_PLOT_V_A4", "COPA_AR100_PLOT_V_A5"
   };
   for(int i = 0; i < ArraySize(prefixos); i++)
      LimparPlotagemPrefixo(prefixos[i]);

   // FIX327: gain, loss e trailing dos aumentos agora sao objetos independentes.
   // A limpeza geral precisa remover tambem esses sufixos para nao deixar linhas
   // antigas no grafico ao desligar a plotagem ou recarregar o EA.
   string lados[] = { "C", "V" };
   for(int lado=0; lado<ArraySize(lados); lado++)
   {
      for(int nivel=1; nivel<=5; nivel++)
      {
         string baseAum=lados[lado]+"_A"+IntegerToString(nivel);
         LimparPlotagemPrefixo(baseAum+"_GAIN");
         LimparPlotagemPrefixo(baseAum+"_LOSS");
         LimparPlotagemPrefixo(baseAum+"_TRAIL");
      }
   }
}

void PlotarLinhaPrecoBox(string nomeBase, double preco, color corLinha, ENUM_LINE_STYLE estilo, int larguraLinha, string legenda, color corTexto, color corFundo, int yAjuste)
{
   if(preco <= 0.0)
   {
      LimparPlotagemPrefixo(nomeBase);
      return;
   }
   string nomeLinha = nomeBase + "_LIN";
   if(ObjectFind(0, nomeLinha) < 0)
      ObjectCreate(0, nomeLinha, OBJ_HLINE, 0, 0, preco);
   ObjectSetDouble(0, nomeLinha, OBJPROP_PRICE, preco);
   ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corLinha);
   ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, estilo);
   ObjectSetInteger(0, nomeLinha, OBJPROP_WIDTH, larguraLinha);
   ObjectSetInteger(0, nomeLinha, OBJPROP_BACK, InpLinhasOperacionaisAtrasDoPainel);
   ObjectSetInteger(0, nomeLinha, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nomeLinha, OBJPROP_HIDDEN, true);
   if(!InpMostrarCaixasLinhasOperacionaisFIX399)
   {
      ObjectDelete(0, nomeBase + "_BG");
      ObjectDelete(0, nomeBase + "_TX");
      return;
   }
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   int px = 0;
   int py = 0;
   if(!ChartTimePriceToXY(0, 0, t, preco, px, py))
      return;
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int reservaEscalaPreco = 190;
   int boxW = 92;
   int boxTextoW=12+(StringLen(legenda)*6);
   if(boxTextoW>boxW) boxW=boxTextoW;
   if(boxW>168) boxW=168;
   int boxH = 15;
   if(chartH > 0 && (py < 24 || py > chartH - 24))
   {
      ObjectDelete(0, nomeBase + "_BG");
      ObjectDelete(0, nomeBase + "_TX");
      return;
   }
   int boxX = chartW - reservaEscalaPreco - boxW - 8;
   if(boxX < 20)
      boxX = 20;
   int boxY = py - 8 + yAjuste;
   if(boxY < 20)
      boxY = 20;
   if(chartH > 0 && boxY > chartH - boxH - 20)
      boxY = chartH - boxH - 20;
   PainelRetangulo(nomeBase + "_BG", boxX, boxY, boxW, boxH, corFundo, corLinha);
   PainelTextoCortado(nomeBase + "_TX", legenda, boxX + 4, boxY + 1, corTexto, 7, "Consolas", boxW - 8);
   if(InpLinhasOperacionaisAtrasDoPainel)
   {
      ConfigurarObjetoAtrasPainel(nomeLinha);
      ConfigurarObjetoAtrasPainel(nomeBase + "_BG");
      ConfigurarObjetoAtrasPainel(nomeBase + "_TX");
   }
}

double PrecoNivelFinanceiroLado(EstadoLado &estado, double alvoFinanceiro)
{
   if(alvoFinanceiro <= 0.0 || estado.precoMedio <= 0.0 || estado.contratos <= 0.0)
      return 0.0;
   double dist = DistanciaPrecoPorFinanceiro(MathAbs(alvoFinanceiro), estado.contratos);
   if(dist <= 0.0)
      return 0.0;
   if(estado.lado == LADO_COMPRA)
      return estado.precoMedio + dist;
   if(estado.lado == LADO_VENDA)
      return estado.precoMedio - dist;
   return 0.0;
}

// FIX330: o limite financeiro do ciclo permanece fixo, mas o preco da linha
// acompanha o volume/preco medio ainda aberto e desconta as parciais realizadas.
double ParcialCicloLadoGraficoFIX330(EstadoLado &estado)
{
   if(estado.lado==LADO_COMPRA)
      return g_parciaisCicloBuy;
   if(estado.lado==LADO_VENDA)
      return g_parciaisCicloSell;
   return 0.0;
}

double PrecoResultadoAbertoGraficoFIX330(EstadoLado &estado, double resultadoAbertoNecessario)
{
   double volume=MathAbs(estado.contratos);
   if(estado.precoMedio<=0.0 || volume<=0.0)
      return 0.0;
   double distancia=DistanciaPrecoPorFinanceiro(MathAbs(resultadoAbertoNecessario),volume);
   double sinal=(resultadoAbertoNecessario>=0.0 ? 1.0 : -1.0);
   if(estado.lado==LADO_COMPRA)
      return NormalizeDouble(estado.precoMedio+(sinal*distancia),_Digits);
   if(estado.lado==LADO_VENDA)
      return NormalizeDouble(estado.precoMedio-(sinal*distancia),_Digits);
   return 0.0;
}

void LimparLinhasParciaisLado(string prefixo)
{
   for(int i = 1; i <= 5; i++)
      LimparPlotagemPrefixo(prefixo + "_PAR" + IntegerToString(i));
}

void PlotarLinhasParciaisLado(string prefixo, EstadoLado &estado)
{
   // FIX220: quando cada aumento A1/A2/A3 realiza pelo proprio ticket,
   // as antigas linhas azuis REAL 10/C, PROX 20/C e PROX 30/C eram duplicadas
   // e pareciam indicar 10, 20 e 30 contratos. Nesse modo mostramos somente
   // as linhas do proprio aumento: A1/A2/A3 ENTRA, FECHA +R$ e PARCIAL OK.
   if(InpRealizarAumentosPorTicketFIX207)
   {
      LimparLinhasParciaisLado(prefixo);
      return;
   }
   if(!InpPlotarLinhasParciais || !ParcialOperacaoAtivaEfetiva() || !estado.posicaoAberta || estado.precoMedio <= 0.0 || estado.contratos <= 0.0)
   {
      LimparLinhasParciaisLado(prefixo);
      return;
   }
   int qtd = InpPlotarLinhasParciaisQtd;
   if(qtd < 1) qtd = 1;
   if(qtd > 5) qtd = 5;
   double gatilho = MathAbs(ParcialGatilhoBaseReaisEfetivo());
   double passo   = MathAbs(ParcialPassoBaseReaisEfetivo());
   if(passo <= 0.0)
      passo = 5.0;
   if(gatilho <= 0.0)
   {
      LimparLinhasParciaisLado(prefixo);
      return;
   }
   bool parcialFeita = (estado.parcial50Executada || estado.resultadoFechado > 0.0);
   int baseAjuste = InpParcialSubstituiLinhaEntradaAposEntrada ? 0 : 48;
   for(int i = 0; i < 5; i++)
   {
      string nome = prefixo + "_PAR" + IntegerToString(i + 1);
      if(i >= qtd)
      {
         LimparPlotagemPrefixo(nome);
         continue;
      }
      double valorNivelBase = gatilho + (passo * i);
      double valorNivel = 0.0;
      double volumeLinha = 0.0;
      double precoNivel = PrecoNivelParcialGraficoLado(estado, valorNivelBase, valorNivel, volumeLinha);
      if(precoNivel <= 0.0)
      {
         LimparPlotagemPrefixo(nome);
         continue;
      }
      bool nivelRealizado = (InpLinhaParcialRealizadaMudaCor && parcialFeita && i == 0);
      bool nivelAtual = (!parcialFeita && i == 0) || (parcialFeita && i == 1);
      color corLinha = C'0,190,255';
      color corFundo = C'7,88,120';
      color corTexto = clrWhite;
      ENUM_LINE_STYLE estilo = STYLE_DASHDOT;
      int largura = 1;
      string legenda = "";
      bool labelRecuoPontos = (ParcialRecuoAumentoAtivoEfetivo() && estado.aumentosExecutados > 0);
      if(nivelRealizado)
      {
         corLinha = C'0,190,90';
         corFundo = C'12,92,52';
         estilo = STYLE_SOLID;
         largura = MathMax(2, InpPlotLinhasLargura + 1);
         if(labelRecuoPontos)
            legenda = StringFormat("OK %.0fP", valorNivelBase);
         else
            legenda = ParcialPorContratoEfetivo() ? StringFormat("OK %.0f/C", valorNivelBase) : StringFormat("PARC OK %.0f", valorNivel);
      }
      else if(nivelAtual)
      {
         corLinha = C'0,220,255';
         corFundo = C'5,84,118';
         estilo = STYLE_SOLID;
         largura = MathMax(2, InpPlotLinhasLargura + 1);
         if(labelRecuoPontos)
            legenda = StringFormat("REAL %.0fP", valorNivelBase);
         else
            legenda = ParcialPorContratoEfetivo() ? StringFormat("REAL %.0f/C", valorNivelBase) : StringFormat("REALIZA %.0f", valorNivel);
      }
      else
      {
         if(labelRecuoPontos)
            legenda = StringFormat("PROX %.0fP", valorNivelBase);
         else
            legenda = ParcialPorContratoEfetivo() ? StringFormat("PROX %.0f/C", valorNivelBase) : StringFormat("PROX %.0f", valorNivel);
      }
      PlotarLinhaPrecoBox(nome,
                          precoNivel,
                          corLinha, estilo, largura,
                          legenda,
                          corTexto, corFundo,
                          baseAjuste + (i * 16));
   }
}

void LimparTrailingVisualFIX294(string prefixo)
{
   LimparPlotagemPrefixo(prefixo + "_TRAIL_A0");
   for(int i=1;i<=5;i++)
      LimparPlotagemPrefixo(prefixo + "_TRAIL_A" + IntegerToString(i));
}

void DadosTrailingPontaFIX294(EstadoLado &estado,
                              bool &armado,
                              double &defesa,
                              double &melhor,
                              double &ativacao,
                              double &passo)
{
   armado=false;
   defesa=0.0;
   melhor=0.0;
   ativacao=MathAbs(g_entradaTrailingAtivarReaisEfetivo);
   passo=MathAbs(g_entradaTrailingPassoReaisEfetivo);
   if(InpCorredorLucroAtivo)
   {
      ativacao=MathAbs(InpCorredorAtivarReais);
      passo=MathAbs(InpCorredorDegrauReais);
   }
   if(ativacao<=0.0) ativacao=20.0;
   if(passo<=0.0) passo=5.0;

   if(InpModoSimplesFIX195)
   {
      if(estado.lado==LADO_COMPRA)
      {
         armado=g_simplesBuy.protecaoArmada;
         defesa=g_simplesBuy.defesaAtual;
         melhor=g_simplesBuy.melhorLucro;
      }
      else if(estado.lado==LADO_VENDA)
      {
         armado=g_simplesSell.protecaoArmada;
         defesa=g_simplesSell.defesaAtual;
         melhor=g_simplesSell.melhorLucro;
      }
      // FIX301: apos reinicio, o estado de melhor lucro pode ainda estar zerado,
      // mas o ticket real ja pode estar em movimento favoravel. Usa o aberto atual
      // somente para decidir a exibicao da linha; a regra de fechamento nao muda.
      if(melhor<=0.0 && estado.resultadoAberto>0.0)
         melhor=estado.resultadoAberto;
      return;
   }

   armado=estado.lucroProtegido;
   defesa=estado.valorDefendido;
   melhor=estado.melhorResultadoAberto;
   if(g_risco.defesaAtivaEm>0.0)
      ativacao=MathAbs(g_risco.defesaAtivaEm);
   if(g_risco.trailPasso>0.0)
      passo=MathAbs(g_risco.trailPasso);
}

void PlotarTrailingPontaFIX294(string prefixo, EstadoLado &estado)
{
   string nome=prefixo + "_TRAIL_A0";
   if(!estado.posicaoAberta || estado.precoMedio<=0.0 || estado.contratos<=0.0)
   {
      LimparPlotagemPrefixo(nome);
      return;
   }

   bool armado=false;
   double defesa=0.0, melhor=0.0, ativacao=0.0, passo=0.0;
   DadosTrailingPontaFIX294(estado,armado,defesa,melhor,ativacao,passo);
   // FIX300: nao mostra linha de trailing parada no instante da entrada.
   // A linha aparece somente depois que houve algum movimento favoravel ou quando a protecao ja armou.
   if(!armado && melhor<=0.0)
   {
      LimparPlotagemPrefixo(nome);
      return;
   }
   double valorLinha=armado ? defesa : ativacao;
   if(valorLinha<=0.0)
   {
      LimparPlotagemPrefixo(nome);
      return;
   }

   double preco=PrecoNivelFinanceiroLado(estado,valorLinha);
   string legenda=armado
                   ? StringFormat("TR A0 D%.0f",defesa)
                   : StringFormat("TR A0 ARM%.0f",ativacao);
   color corLinha=clrWhite;
   color corFundo=armado ? C'55,55,55' : C'38,38,38';
   ENUM_LINE_STYLE estiloTrail=armado ? STYLE_SOLID : STYLE_DOT;
   PlotarLinhaPrecoBox(nome,preco,corLinha,estiloTrail,
                       armado?2:1,legenda,clrWhite,corFundo,48);
}



void PlotarLinhasOperacionaisLado(string prefixo, EstadoLado &estado)
{
   if(!InpPlotarLinhasOperacionais || !estado.posicaoAberta || estado.precoMedio <= 0.0 || estado.contratos <= 0.0)
   {
      LimparPlotagemPrefixo(prefixo + "_ENT");
      LimparPlotagemPrefixo(prefixo + "_GAIN");
      LimparPlotagemPrefixo(prefixo + "_STOP");
      LimparPlotagemPrefixo(prefixo + "_PROT");
      LimparLinhasParciaisLado(prefixo);
      for(int nivelLimpar=1;nivelLimpar<=5;nivelLimpar++)
      {
         string baseAum=prefixo+"_A"+IntegerToString(nivelLimpar);
         LimparPlotagemPrefixo(baseAum);
         LimparPlotagemPrefixo(baseAum+"_GAIN");
         LimparPlotagemPrefixo(baseAum+"_LOSS");
         LimparPlotagemPrefixo(baseAum+"_TRAIL");
      }
      LimparTrailingVisualFIX294(prefixo);
      return;
   }
   string ladoCurto = TextoLadoCurto(estado.lado);
   int larguraLinha = InpPlotLinhasLargura;
   if(larguraLinha < 1)
      larguraLinha = 1;
   bool parcialAssumeLinhaEntrada = (InpParcialSubstituiLinhaEntradaAposEntrada &&
                                      InpPlotarLinhasParciais &&
                                      ParcialOperacaoAtivaEfetiva() &&
                                      !InpRealizarAumentosPorTicketFIX207); // FIX220: sem linha azul duplicada no modo A1/A2/A3 por ticket.
   if(InpPlotarLinhaEntrada && !parcialAssumeLinhaEntrada)
      PlotarLinhaPrecoBox(prefixo + "_ENT",
                          estado.precoMedio,
                          C'64,128,255', STYLE_SOLID, larguraLinha,
                          StringFormat("%s E %.0f", ladoCurto, estado.contratos),
                          clrWhite, C'27,58,112',
                          0);
   else
      LimparPlotagemPrefixo(prefixo + "_ENT");
   double parcialCiclo=ParcialCicloLadoGraficoFIX330(estado);
   double gainFixo=MathAbs(InpEntradaGanhoAlvoReais);
   double lossFixo=InpStopDinamicoHeadFIX359 ? StopGeralDinamicoHeadFIX359() : MathAbs(InpEntradaPerdaMaximaReais);
   double abertoNecessarioGain=gainFixo-parcialCiclo;
   double abertoNecessarioLoss=InpStopDinamicoHeadFIX359 ? AbertoNecessarioStopMovelHeadFIX359(estado) : (-lossFixo-parcialCiclo);
   double precoGain=PrecoResultadoAbertoGraficoFIX330(estado,abertoNecessarioGain);
   double precoStop=PrecoResultadoAbertoGraficoFIX330(estado,abertoNecessarioLoss);
   PlotarLinhaPrecoBox(prefixo + "_GAIN",
                       precoGain,
                       clrLime, STYLE_SOLID, MathMax(2,larguraLinha+1),
                       StringFormat("GAIN +%.0f | PAR %+.0f",gainFixo,parcialCiclo),
                       clrWhite, C'9,97,52',
                       -16);
   double stopMovelLocalFIX359=StopMovelLadoHeadFIX359(estado.lado==LADO_VENDA?LADO_VENDA:LADO_COMPRA);
   PlotarLinhaPrecoBox(prefixo + "_STOP",
                       precoStop,
                       clrRed, STYLE_SOLID, MathMax(2,larguraLinha+1),
                       InpStopDinamicoHeadFIX359
                       ? StringFormat("STOP HEAD MOV %s | REST %s",TextoMoedaPainelCurto(stopMovelLocalFIX359),TextoMoedaPainelCurto(EspacoStopRestanteCestaAB()))
                       : StringFormat("LOSS -%.0f | PAR %+.0f",lossFixo,parcialCiclo),
                       clrWhite, C'132,24,24',
                       16);
   LimparPlotagemPrefixo(prefixo + "_PROT"); // FIX294: substituida pela linha TR A0.
   PlotarTrailingPontaFIX294(prefixo,estado);
   PlotarLinhasParciaisLado(prefixo, estado);
   if(InpPlotarLinhasAumentos)
   {
      color corAum = C'165,95,20';
      for(int i = 0; i < 5; i++)
      {
         string nome = prefixo + "_A" + IntegerToString(i + 1);
         if(i >= ArraySize(g_aumentos) || !g_aumentos[i].ativa)
         {
            LimparPlotagemPrefixo(nome);
            LimparPlotagemPrefixo(nome+"_GAIN");
            LimparPlotagemPrefixo(nome+"_LOSS");
            LimparPlotagemPrefixo(nome+"_TRAIL");
            continue;
         }
         double precoA = PrecoNivelAumentoValorIndice(estado, i);
         int nivel=i+1;
         ulong ticketAum=0;
         double precoEntradaTicket=0.0;
         double volumeTicket=0.0;
         long tipoTicket=-1;
         bool aumentoAberto=ObterPosicaoAumentoNivelFIX212(estado,nivel,ticketAum,precoEntradaTicket,volumeTicket,tipoTicket);
         double alvoTicket=MathAbs(InpLucroAumentoPorContratoReaisFIX207)*volumeTicket;
         double lossTicket=MathAbs(InpLossAumentoPorContratoReaisFIX321)*volumeTicket;
         if(alvoTicket<=0.0 && volumeTicket>0.0)
            alvoTicket=10.0*volumeTicket;

         // FIX327: cada nivel possui linhas visuais independentes para entrada,
         // gain, loss e trailing movel.
         double precoAlvoTicket=0.0;
         bool trailAumentoArmado=false;
         double trailAumentoDefesa=0.0;
         double trailAumentoAtivacao=0.0;
         double trailAumentoMelhor=0.0;
         double trailAumentoStopPrecoFIX325=0.0;
         double trailAumentoDistanciaFIX325=0.0;
         if(aumentoAberto)
         {
            if(precoEntradaTicket>0.0)
               precoA=precoEntradaTicket;
            precoAlvoTicket=PrecoRealizacaoAumentoFIX212(tipoTicket,precoEntradaTicket,volumeTicket,alvoTicket);
            if(precoAlvoTicket>0.0)
            {
               SalvarAlvoLinhaAumentoFIX212(estado,nivel,precoAlvoTicket);
               // FIX448: linha verde de realizacao do aumento pontilhada e fina.
               PlotarLinhaPrecoBox(nome+"_GAIN",
                                   precoAlvoTicket,
                                   clrLime,STYLE_DOT,1,
                                   StringFormat("A%d GAIN +%.0f",nivel,alvoTicket),
                                   clrWhite,C'9,97,52',
                                   -12+(i*16));
            }
            else
               LimparPlotagemPrefixo(nome+"_GAIN");

            int idxTrail=nivel-1;
            if(estado.lado==LADO_COMPRA)
            {
               trailAumentoArmado=g_trailAumentoBuy[idxTrail].protecaoArmada;
               trailAumentoDefesa=g_trailAumentoBuy[idxTrail].defesaAtual;
               trailAumentoMelhor=g_trailAumentoBuy[idxTrail].melhorLucro;
               trailAumentoStopPrecoFIX325=g_trailAumentoBuy[idxTrail].stopPrecoFIX325;
               trailAumentoDistanciaFIX325=g_trailAumentoBuy[idxTrail].distanciaAtualPontosFIX325;
            }
            else
            {
               trailAumentoArmado=g_trailAumentoSell[idxTrail].protecaoArmada;
               trailAumentoDefesa=g_trailAumentoSell[idxTrail].defesaAtual;
               trailAumentoMelhor=g_trailAumentoSell[idxTrail].melhorLucro;
               trailAumentoStopPrecoFIX325=g_trailAumentoSell[idxTrail].stopPrecoFIX325;
               trailAumentoDistanciaFIX325=g_trailAumentoSell[idxTrail].distanciaAtualPontosFIX325;
            }

            // FIX301: recupera visualmente o movimento favoravel do ticket real
            // quando o EA foi recompilado/recolocado. Nao arma nem altera o trailing;
            // apenas impede que a descricao fique parada em GAIN com lucro positivo.
            if(PositionSelectByTicket(ticketAum))
            {
               double lucroServidorFIX301=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
               double lucroManualFIX301=LucroAbertoPosicaoSelecionada(tipoTicket);
               double lucroAtualFIX301=InpLucroAbertoUsarCalculoManual ? lucroManualFIX301 : lucroServidorFIX301;
               if(lucroAtualFIX301>trailAumentoMelhor)
                  trailAumentoMelhor=lucroAtualFIX301;
            }

            double ativacaoUnitaria=MathAbs(InpTrailingAumentoAtivarReaisFIX281);
            if(idxTrail>=0 && idxTrail<ArraySize(g_aumentos) && g_aumentos[idxTrail].trailingAtivarReais>0.0)
               ativacaoUnitaria=MathAbs(g_aumentos[idxTrail].trailingAtivarReais);
            if(ativacaoUnitaria<=0.0)
               ativacaoUnitaria=20.0;
            trailAumentoAtivacao=ativacaoUnitaria*volumeTicket;
            if(g_trailInteligenteLinhasAtivoFIX325)
               trailAumentoAtivacao=g_trailInteligenteAtivaPontosFIX325;

            // FIX327: entrada, gain, loss e trailing agora possuem linhas separadas.
            if(trailAumentoArmado)
            {
               double precoLinhaTrail=(g_trailInteligenteLinhasAtivoFIX325 && trailAumentoStopPrecoFIX325>0.0)
                                      ? trailAumentoStopPrecoFIX325
                                      : PrecoRealizacaoAumentoFIX212(tipoTicket,precoEntradaTicket,volumeTicket,trailAumentoDefesa);
               if(precoLinhaTrail>0.0)
                  PlotarLinhaPrecoBox(nome+"_TRAIL",
                                      precoLinhaTrail,
                                      clrWhite,STYLE_SOLID,MathMax(3,larguraLinha+2),
                                      g_trailInteligenteLinhasAtivoFIX325
                                      ? StringFormat("A%d TRAIL SL %.0f | D%.0f",nivel,precoLinhaTrail,trailAumentoDistanciaFIX325)
                                      : StringFormat("A%d TRAIL %.0f",nivel,trailAumentoDefesa),
                                      clrWhite,C'45,45,45',
                                      20+(i*16));
            }
            else
               LimparPlotagemPrefixo(nome+"_TRAIL");

            if(InpStopDinamicoHeadFIX359)
               LimparPlotagemPrefixo(nome + "_LOSS");
            else
            {
               double precoLossTicket=PrecoLossAumentoFIX321(tipoTicket,precoEntradaTicket,volumeTicket,lossTicket);
               if(precoLossTicket>0.0)
                  PlotarLinhaPrecoBox(nome + "_LOSS",
                                      precoLossTicket,
                                      clrRed, STYLE_SOLID, MathMax(2,larguraLinha+1),
                                      StringFormat("A%d LOSS -%.0f",nivel,lossTicket),
                                      clrWhite, C'132,24,24',
                                      4 + (i * 16));
            }
         }
         else
         {
            LimparPlotagemPrefixo(nome + "_GAIN");
            LimparPlotagemPrefixo(nome + "_LOSS");
            LimparPlotagemPrefixo(nome + "_TRAIL");
            // FIX452: sem ticket real aberto, não manter linha azul de entrada.
            LimparPlotagemPrefixo(nome);
            continue;
         }

         double precoRealizado=0.0;
         bool aumentoRealizado=AumentoRealizadoFIX212(estado,nivel,precoRealizado);
         // Se o nivel foi rearmado e existe um novo ticket aberto, o trailing atual tem prioridade.
         // Quando o ticket fecha, a mesma linha volta para o preco real daquela parcial.
         if(!aumentoAberto && aumentoRealizado)
         {
            if(precoRealizado>0.0)
               precoA=precoRealizado;
            else if(AlvoLinhaAumentoFIX212(estado,nivel)>0.0)
               precoA=AlvoLinhaAumentoFIX212(estado,nivel);
         }

         bool aumentoExecutado=(estado.aumentosExecutados>=nivel || aumentoAberto || aumentoRealizado);
         color corLinhaAum = (aumentoAberto || aumentoRealizado) ? C'30,144,255' : corAum;
         color corFundoAum = (aumentoAberto || aumentoRealizado) ? C'18,68,125' : C'92,50,14';
         // FIX446: linhas azuis dos aumentos (executado/realizado) ficam pontilhadas
         // para reduzir poluicao visual do grafico.
         ENUM_LINE_STYLE estiloAum = aumentoExecutado ? STYLE_DOT : STYLE_DOT;
         int larguraAum = aumentoExecutado ? 1 : 1;
         bool escadaNovaFIX225=EscadaA1RearmadaFIX225(estado);
         string legendaAum = aumentoAberto
                             ? StringFormat("A%d EXEC +%.0f CT",nivel,volumeTicket)
                             : (aumentoRealizado
                                ? StringFormat("A%d REALIZADO",nivel)
                                : (escadaNovaFIX225
                                   ? StringFormat("A%d NOVO +%.0f CT",nivel,g_aumentos[i].qtd)
                                   : StringFormat("A%d ENTRA +%.0f CT",nivel,g_aumentos[i].qtd)));
         PlotarLinhaPrecoBox(nome,
                             precoA,
                             corLinhaAum, estiloAum, larguraAum,
                             legendaAum,
                             clrWhite, corFundoAum,
                             -44 + (i * 16));
      }
   }
   else
   {
      for(int nivelLimpar=1;nivelLimpar<=5;nivelLimpar++)
      {
         string baseAum=prefixo+"_A"+IntegerToString(nivelLimpar);
         LimparPlotagemPrefixo(baseAum);
         LimparPlotagemPrefixo(baseAum+"_GAIN");
         LimparPlotagemPrefixo(baseAum+"_LOSS");
         LimparPlotagemPrefixo(baseAum+"_TRAIL");
         LimparPlotagemPrefixo(prefixo+"_TRAIL_A"+IntegerToString(nivelLimpar));
      }
   }
}

void LimparPlotagemLadoFIX300(string prefixo)
{
   LimparPlotagemPrefixo(prefixo + "_ENT");
   LimparPlotagemPrefixo(prefixo + "_GAIN");
   LimparPlotagemPrefixo(prefixo + "_STOP");
   LimparPlotagemPrefixo(prefixo + "_PROT");
   LimparLinhasParciaisLado(prefixo);
   for(int nivel=1;nivel<=5;nivel++)
   {
      string baseAum=prefixo+"_A"+IntegerToString(nivel);
      LimparPlotagemPrefixo(baseAum);
      LimparPlotagemPrefixo(baseAum+"_GAIN");
      LimparPlotagemPrefixo(baseAum+"_LOSS");
      LimparPlotagemPrefixo(baseAum+"_TRAIL");
      LimparPlotagemPrefixo(prefixo + "_TRAIL_A" + IntegerToString(nivel));
   }
   LimparPlotagemPrefixo(prefixo + "_TRAIL_A0");
}

void AtualizarPlotagemOperacional()
{
   ReaplicarParametrosAntesDoGrafico("AtualizarPlotagemOperacional");
   if(!InpPlotarLinhasOperacionais)
   {
      LimparPlotagemOperacional();
      return;
   }

   // FIX300: o painel HEAD permanece mestre e continua lendo A+B.
   // Somente os objetos sobre o grafico sao locais: A mostra COMPRA; B mostra VENDA.
   if(JanelaAtualEhA_FIX255())
   {
      PlotarLinhasOperacionaisLado("C", g_compra);
      LimparPlotagemLadoFIX300("V");
   }
   else
   {
      PlotarLinhasOperacionaisLado("V", g_venda);
      LimparPlotagemLadoFIX300("C");
   }
}

void LimparHistoricoLinhaVisual(string pfx, int row)
{
   string sufixos[] = {"ROW_", "P_", "QC_", "QV_", "QT_", "F_", "REAL_", "ABR_", "LT_", "CV_", "PC_", "PA_"};
   for(int i = 0; i < ArraySize(sufixos); i++)
      ObjectDelete(0, pfx + sufixos[i] + IntegerToString(row));
}

void PainelTextoCentroHistoricoFIX368(string nome,string texto,int x,int y,int largura,color cor,int fonte,string fonteNome)
{
   int centro=x+largura/2;
   PainelTextoCortado(nome,texto,centro,y,cor,fonte,fonteNome,largura-4);
   if(ObjectFind(0,nome)>=0)
      ObjectSetInteger(0,nome,OBJPROP_ANCHOR,ANCHOR_CENTER);
}

color CorGrupoHistoricoFIX368(ENUM_LADO_ROBO lado)
{
   if(lado==LADO_COMPRA) return clrAqua;
   if(lado==LADO_VENDA) return clrOrange;
   return clrLime;
}

void DesenharGrupoHistoricoFIX368(string pfx,string grupo,string titulo,HistoricoPeriodo &h,ENUM_LADO_ROBO lado,
                                  int x,int y,int largura,int fonte)
{
   color corGrupo=CorGrupoHistoricoFIX368(lado);
   PainelRetangulo(pfx+grupo+"_GRP_BG",x,y,largura,16,PnlCorBloco2(),PnlCorBloco2()); // FIX413: sem borda superior
   PainelTextoCentroHistoricoFIX368(pfx+grupo+"_GRP_T",titulo,x,y+2,largura,corGrupo,fonte,"Arial Bold");

   string campos[7]={"GQ","G$","LQ","L$","PQ","P$","TOTAL"};
   double pesos[7]={0.10,0.17,0.10,0.17,0.10,0.17,0.19};
   int larguras[7];
   int usado=0;
   for(int i=0;i<6;i++)
   {
      larguras[i]=(int)MathFloor((double)largura*pesos[i]);
      if(larguras[i]<32) larguras[i]=32;
      usado+=larguras[i];
   }
   larguras[6]=largura-usado;
   if(larguras[6]<48) larguras[6]=48;

   int gq=QtdGanhoHistoricoCardFIX368(h,lado);
   int lq=QtdLossHistoricoCardFIX368(h,lado);
   int pq=QtdParcialHistoricoCardFIX368(h,lado);
   double gf=FinanceiroGanhoHistoricoCardFIX368(h,lado);
   double lf=FinanceiroLossHistoricoCardFIX368(h,lado);
   double pf=FinanceiroParcialHistoricoCardFIX368(h,lado);
   double tot=TotalHistoricoCardFIX368(h,lado);
   string valores[7]={IntegerToString(gq),TextoFinanceiroHistoricoCompactoFIX369(gf),IntegerToString(lq),TextoFinanceiroHistoricoCompactoFIX369(lf),
                      IntegerToString(pq),TextoFinanceiroHistoricoCompactoFIX369(pf),TextoFinanceiroHistoricoCompactoFIX369(tot)};
   color cores[7];
   cores[0]=corGrupo;
   cores[1]=CorFinanceiro(gf);
   cores[2]=corGrupo;
   cores[3]=CorFinanceiro(lf);
   cores[4]=corGrupo;
   cores[5]=CorFinanceiro(pf);
   cores[6]=CorFinanceiro(tot);

   int cx=x;
   for(int i=0;i<7;i++)
   {
      string id=grupo+IntegerToString(i);
      PainelRetangulo(pfx+id+"_HBG",cx,y+17,larguras[i],15,PnlCorBloco(),PnlCorDivisoria());
      PainelTextoCentroHistoricoFIX368(pfx+grupo+"_H_"+(i==0?"GQ":i==1?"GF":i==2?"LQ":i==3?"LF":i==4?"PQ":i==5?"PF":"TOT"),
                                       campos[i],cx,y+19,larguras[i],PnlCorSecundario(),fonte,"Arial Bold");
      PainelRetangulo(pfx+id+"_VBG",cx,y+33,larguras[i],18,PnlCorLinhaAlternada(0),PnlCorDivisoria());
      string valorNome=pfx+grupo+"_V_"+(i==0?"GQ":i==1?"GF":i==2?"LQ":i==3?"LF":i==4?"PQ":i==5?"PF":"TOT");
      PainelTextoCentroHistoricoFIX368(valorNome,valores[i],cx,y+36,larguras[i],cores[i],fonte,"Consolas");
      cx+=larguras[i];
   }
}

void DesenharCardHistorico(int x, int y, int largura, int altura)
{
   string pfx="COPA_AR100_CARD_HIST_";
   int fonteTexto=InpPainelFonteTexto;
   if(fonteTexto<7) fonteTexto=7;
   if(fonteTexto>8) fonteTexto=8;
   if(altura<76) altura=76;
   PainelRetangulo(pfx+"FUNDO",x,y,largura,altura,PnlCorBloco(),PnlCorBloco()); // FIX413: sem borda externa/superior no historico

   double ctHistA=0.0,ctHistB=0.0;
   ContarPosicoesMagicFIX304(MagicPainelAAtual(),ctHistA);
   ContarPosicoesMagicFIX304(MagicPainelBAtual(),ctHistB);
   // FIX370: sem titulo superior. O proprio cabecalho PERIODO/LADO A/LADO B/HEAD identifica o card.
   ObjectDelete(0,pfx+"TIT");

   // Remove somente os objetos do desenho antigo de seis linhas.
   for(int r=0;r<6;r++) LimparHistoricoLinhaVisual(pfx,r);
   string antigos[]={"HDR","H_PER","H_QC","H_QV","H_QT","H_FIN","H_REAL","H_ABR","H_TOT","TUDO_RES"};
   for(int a=0;a<ArraySize(antigos);a++) ObjectDelete(0,pfx+antigos[a]);

   HistoricoPeriodo h;
   ObterHistoricoSelecionado(h);
   AplicarFallbackEntradasAbertasHistoricoFIX316(h);

   int corpoY=y+3;
   int margem=8;
   int periodoW=(int)MathRound((double)largura*0.072);
   if(periodoW<74) periodoW=74;
   if(periodoW>104) periodoW=104;
   int disponivel=largura-(margem*2)-periodoW;
   int grupoW=disponivel/3;
   int sobra=disponivel-(grupoW*3);

   PainelRetangulo(pfx+"PER_GRP_BG",x+margem,corpoY,periodoW,16,PnlCorBloco2(),PnlCorBloco2()); // FIX413: sem borda superior
   PainelTextoCentroHistoricoFIX368(pfx+"PER_GRP_T","PERIODO",x+margem,corpoY+2,periodoW,PnlCorTitulo(),fonteTexto,"Arial Bold");
   PainelRetangulo(pfx+"PER_HBG",x+margem,corpoY+17,periodoW,15,PnlCorBloco(),PnlCorDivisoria());
   PainelTextoCentroHistoricoFIX368(pfx+"PER_H","SELECAO",x+margem,corpoY+19,periodoW,PnlCorSecundario(),fonteTexto,"Arial Bold");
   PainelRetangulo(pfx+"PER_VBG",x+margem,corpoY+33,periodoW,18,PnlCorLinhaAlternada(0),PnlCorDivisoria());
   PainelTextoCentroHistoricoFIX368(pfx+"PER_V",PeriodoHistoricoCardFIX368(),x+margem,corpoY+36,periodoW,PnlCorTexto(),fonteTexto,"Consolas");

   int gx=x+margem+periodoW;
   DesenharGrupoHistoricoFIX368(pfx,"A","LADO A",h,LADO_COMPRA,gx,corpoY,grupoW,fonteTexto);
   gx+=grupoW;
   DesenharGrupoHistoricoFIX368(pfx,"B","LADO B",h,LADO_VENDA,gx,corpoY,grupoW,fonteTexto);
   gx+=grupoW;
   DesenharGrupoHistoricoFIX368(pfx,"AB","HEAD A+B",h,LADO_AMBOS,gx,corpoY,grupoW+sobra,fonteTexto);
}

// Compatibilidade: a antiga funcao permanece como encaminhamento para o novo card de uma linha.

bool ExistePosicaoMagicTipo(long magic, long tipo)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      if((long)PositionGetInteger(POSITION_TYPE) != tipo)
         continue;
      return true;
   }
   return false;
}

bool GrupoHeadTemPosicaoTipo(long tipo)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      long magic = (long)PositionGetInteger(POSITION_MAGIC);
      if(!MagicPertencePainelTotalAB(magic))
         continue;
      long ptype = PositionGetInteger(POSITION_TYPE);
      if(ptype == tipo)
         return true;
   }
   return false;
}

bool LadoObrigatorioOpostoGrupoHead(ENUM_LADO_ROBO lado)
{
   if(!InpHeadForcarEntradaOpostaGrupo)
      return false;
   bool temCompra = GrupoHeadTemPosicaoTipo(POSITION_TYPE_BUY);
   bool temVenda  = GrupoHeadTemPosicaoTipo(POSITION_TYPE_SELL);
   if(temCompra && temVenda)
      return false;

   // FIX275: HEAD continuo. Sempre que existir somente uma ponta,
   // a ponta faltante volta a ser obrigatoria, mesmo que o par ja tenha existido antes.
   if(InpHeadCiclosIndependentesFIX275)
   {
      if(temVenda && !temCompra)
         return (lado == LADO_COMPRA);
      if(temCompra && !temVenda)
         return (lado == LADO_VENDA);
      return false;
   }

   // Compatibilidade com o comportamento antigo do FIX274.
   if(ParABJaCompletadoFIX274())
      return false;
   if(temVenda && !temCompra)
      return (lado == LADO_COMPRA);
   if(temCompra && !temVenda)
      return (lado == LADO_VENDA);
   return false;
}

bool LadoBloqueadoPorOpostoGrupoHead(ENUM_LADO_ROBO lado)
{
   if(!InpHeadForcarEntradaOpostaGrupo)
      return false;
   bool temCompra = GrupoHeadTemPosicaoTipo(POSITION_TYPE_BUY);
   bool temVenda  = GrupoHeadTemPosicaoTipo(POSITION_TYPE_SELL);
   if(temCompra && temVenda)
      return false;

   // FIX275: bloqueia somente a ponta que ja esta aberta para impedir A0 duplicada.
   // A ponta faltante permanece liberada e sera reaberta depois do timer ST/FT.
   if(InpHeadCiclosIndependentesFIX275)
   {
      if(temVenda && !temCompra)
         return (lado == LADO_VENDA);
      if(temCompra && !temVenda)
         return (lado == LADO_COMPRA);
      return false;
   }

   if(ParABJaCompletadoFIX274())
   {
      if(temVenda && !temCompra)
         return (lado == LADO_COMPRA);
      if(temCompra && !temVenda)
         return (lado == LADO_VENDA);
      return false;
   }
   if(temVenda && !temCompra)
      return (lado == LADO_VENDA);
   if(temCompra && !temVenda)
      return (lado == LADO_COMPRA);
   return false;
}

bool LadoPermitidoPelaSelecaoHead(ENUM_LADO_ROBO lado)
{
   if(!TipoOperacaoPermiteLado(lado))
      return false;
   if(LadoBloqueadoPorOpostoGrupoHead(lado))
      return false;
   if(LadoObrigatorioOpostoGrupoHead(lado))
      return true;
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_AUTOMATICO)
      return true;
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_SOMENTE_COMPRA)
      return (lado == LADO_COMPRA);
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_SOMENTE_VENDA)
      return (lado == LADO_VENDA);
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_CONFIRMAR_OPOSTO)
   {
      if(!InpUsarRoboHeadExterno)
         return true;
      bool headCompra = ExistePosicaoMagicTipo(InpMagicHeadCompra, POSITION_TYPE_BUY);
      bool headVenda  = ExistePosicaoMagicTipo(InpMagicHeadVenda, POSITION_TYPE_SELL);
      if(InpHeadUsarConfirmacaoLadoOposto)
      {
         if(lado == LADO_COMPRA)
            return headVenda;
         if(lado == LADO_VENDA)
            return headCompra;
      }
      else
      {
         if(lado == LADO_COMPRA)
            return headCompra;
         if(lado == LADO_VENDA)
            return headVenda;
      }
   }
   return true;
}

string TextoSelecaoHead()
{
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_SOMENTE_COMPRA)
      return "HEAD: SOMENTE COMPRA";
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_SOMENTE_VENDA)
      return "HEAD: SOMENTE VENDA";
   if(InpHeadSelecaoOperacao == HEAD_OPERAR_CONFIRMAR_OPOSTO)
      return "HEAD: CONFIRMAR OPOSTO";
   return "HEAD: AUTOMATICO";
}

string TextoHeadExterno()
{
   if(!InpUsarRoboHeadExterno)
      return "HEAD externo OFF";
   bool headCompra = ExistePosicaoMagicTipo(InpMagicHeadCompra, POSITION_TYPE_BUY);
   bool headVenda  = ExistePosicaoMagicTipo(InpMagicHeadVenda, POSITION_TYPE_SELL);
   return StringFormat("%s | Robo HEAD ON | Magic C %s:%s | Magic V %s:%s | Oposto %s",
                       TextoSelecaoHead(),
                       IntegerToString(InpMagicHeadCompra), headCompra ? "ON" : "OFF",
                       IntegerToString(InpMagicHeadVenda),  headVenda  ? "ON" : "OFF",
                       InpHeadUsarConfirmacaoLadoOposto ? "SIM" : "NAO");
}

void DesenharPainelSlimDia(int x, int y, int largura, int altura)
{
   string pfx = "COPA_AR100_CARD_SLIM_";
   int fonte = InpPainelFonteTexto;
   if(fonte < 8) fonte = 8;
   if(largura < 1040) largura = 1040;
   if(altura < 220) altura = 220;
   PainelRetangulo(pfx + "BG", x, y, largura, altura, PnlCorFundo(), PnlCorLinha());
   PainelRetangulo(pfx + "HDR", x + 8, y + 8, largura - 16, 34, PnlCorAbaAtiva(), PnlCorAbaAtiva());
   PainelTextoCortado(pfx + "T1",
               StringFormat("COPA / AR_100 | PAINEL SLIM | %s | F:%s E:%s | %s",
                            _Symbol, NomeTimeframeCurto(TimeframeFiltroAtualFIX255()), NomeTimeframeCurto(TimeframeEntradaAtualFIX255()), TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES)),
               x + 16, y + 17, clrWhite, fonte + 1, "Arial Bold", largura - 450);
   DesenharBotoesModoPainel(pfx + "BTN_", x + largura - 250, y + 14, fonte);
   string hdr2 = StringFormat("A %s %s | B %s %s | Lados %s | Modo %s | Ordens %s | Controle %s",
                              IntegerToString(g_compra.magic), TextoPosicaoCard(g_compra),
                              IntegerToString(g_venda.magic), TextoPosicaoCard(g_venda),
                              TextoLadosHabilitadosFIX346(),
                              TextoModoValidacaoExecucao(),
                              InpPermitirEnvioOrdens ? "ON" : "OFF",
                              TextoControleOperacaoFIX284());
   PainelTexto(pfx + "T2", hdr2, x + 16, y + 48, CorMagicPiscando(InpPermitirEnvioOrdens ? PnlCorVerde() : PnlCorAmarelo()), fonte, "Arial Bold");
   int gap = 8;
   int boxY = y + 70;
   int boxH = 88;
   int boxW = (largura - 16 - (gap * 3)) / 4;
   int bx1 = x + 8;
   int bx2 = bx1 + boxW + gap;
   int bx3 = bx2 + boxW + gap;
   int bx4 = bx3 + boxW + gap;
   HistoricoPeriodo h;
   ObterHistoricoPainelPrincipal(h);
   FotoFinanceiraPainelFIX362 fotoSlimFIX362;
   MontarFotoFinanceiraPainelFIX362(fotoSlimFIX362,false);
   double parcialA = ParcialPositivaHistoricoDoLado(h, g_painelA.lado);
   double parcialB = ParcialPositivaHistoricoDoLado(h, g_painelB.lado);
   double parcialT = ParcialPositivaHistoricoTotal(h);
   EstadoLado estadoBase = g_compra;
   if(!g_compra.posicaoAberta && g_venda.posicaoAberta)
      estadoBase = g_venda;
   string proxAumento = ProximoAumentoCard(estadoBase);
   string precoA1 = PrecoNivelAumentoTextoIndice(estadoBase, 0);
   string precoA2 = PrecoNivelAumentoTextoIndice(estadoBase, 1);
   string precoA3 = PrecoNivelAumentoTextoIndice(estadoBase, 2);
   string precoA4 = PrecoNivelAumentoTextoIndice(estadoBase, 3);
   string precoA5 = PrecoNivelAumentoTextoIndice(estadoBase, 4);
   PainelRetangulo(pfx + "A_BG", bx1, boxY, boxW, boxH, PnlCorBloco(), PnlCorLinha());
   PainelTexto(pfx + "A_T", "A", bx1 + 8, boxY + 8, PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "A_1", StringFormat("%s | %s", IntegerToString(g_compra.magic), TextoPosicaoCard(g_compra)), bx1 + 30, boxY + 8, CardFinanceiroEhFoco(g_compra) ? CorMagicPiscando(CorLadoTexto(LADO_COMPRA)) : CorLadoTexto(LADO_COMPRA), fonte, CardFinanceiroEhFoco(g_compra) ? "Arial Bold" : "Consolas");
   PainelTexto(pfx + "A_2", StringFormat("Aberto %s | Parcial %s", PnlMoedaBRL(fotoSlimFIX362.abertoCompra), PnlMoedaBRL(parcialA)), bx1 + 8, boxY + 30, CorFinanceiro(fotoSlimFIX362.abertoCompra), fonte, "Consolas");
   PainelTexto(pfx + "A_3", StringFormat("Qtd %.0f | Prot %s", fotoSlimFIX362.qtdCompra, PnlMoedaBRL(g_compra.valorDefendido)), bx1 + 8, boxY + 50, PnlCorTexto(), fonte, "Consolas");
   PainelTexto(pfx + "A_4", StringFormat("Lucro %d | Prej %d", TradesLucroHistoricoDoLado(h, LADO_COMPRA), TradesPrejuHistoricoDoLado(h, LADO_COMPRA)), bx1 + 8, boxY + 68, PnlCorSecundario(), fonte, "Consolas");
   PainelRetangulo(pfx + "B_BG", bx2, boxY, boxW, boxH, PnlCorBloco(), PnlCorLinha());
   PainelTexto(pfx + "B_T", "B", bx2 + 8, boxY + 8, PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "B_1", StringFormat("%s | %s", IntegerToString(g_venda.magic), TextoPosicaoCard(g_venda)), bx2 + 30, boxY + 8, CardFinanceiroEhFoco(g_venda) ? CorMagicPiscando(CorLadoTexto(LADO_VENDA)) : CorLadoTexto(LADO_VENDA), fonte, CardFinanceiroEhFoco(g_venda) ? "Arial Bold" : "Consolas");
   PainelTexto(pfx + "B_2", StringFormat("Aberto %s | Parcial %s", PnlMoedaBRL(fotoSlimFIX362.abertoVenda), PnlMoedaBRL(parcialB)), bx2 + 8, boxY + 30, CorFinanceiro(fotoSlimFIX362.abertoVenda), fonte, "Consolas");
   PainelTexto(pfx + "B_3", StringFormat("Qtd %.0f | Prot %s", fotoSlimFIX362.qtdVenda, PnlMoedaBRL(g_venda.valorDefendido)), bx2 + 8, boxY + 50, PnlCorTexto(), fonte, "Consolas");
   PainelTexto(pfx + "B_4", StringFormat("Lucro %d | Prej %d", TradesLucroHistoricoDoLado(h, LADO_VENDA), TradesPrejuHistoricoDoLado(h, LADO_VENDA)), bx2 + 8, boxY + 68, PnlCorSecundario(), fonte, "Consolas");
   PainelRetangulo(pfx + "T_BG", bx3, boxY, boxW, boxH, PnlCorBloco(), PnlCorLinha());
   PainelTexto(pfx + "T_T", "TOTAL", bx3 + 8, boxY + 8, PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "T_1", StringFormat("HEAD C+V %s | Parcial %s", PnlMoedaBRL(fotoSlimFIX362.abertoHead), PnlMoedaBRL(parcialT)), bx3 + 8, boxY + 30, CorFinanceiro(fotoSlimFIX362.abertoHead), fonte, "Consolas");
   PainelTexto(pfx + "T_2", StringFormat("Exp max %s | Exp neg %s", PnlMoedaBRL(ExposicaoMaximaTotal()), PnlMoedaBRL(ExposicaoNegativaTotalPainel())), bx3 + 8, boxY + 50, PnlCorTexto(), fonte, "Consolas");
   PainelTexto(pfx + "T_3", StringFormat("GAIN HEAD %s | LOSS HEAD %s | REST %s", PnlMoedaBRL(fotoSlimFIX362.gainHead), PnlMoedaBRL(-fotoSlimFIX362.lossHead), PnlMoedaBRL(fotoSlimFIX362.restanteHead)), bx3 + 8, boxY + 68, PnlCorSecundario(), fonte, "Consolas");
   PainelRetangulo(pfx + "S_BG", bx4, boxY, boxW, boxH, PnlCorBloco(), PnlCorLinha());
   PainelTexto(pfx + "S_T", "SCORE", bx4 + 8, boxY + 8, PnlCorTitulo(), fonte + 1, "Arial Bold");
   PainelTexto(pfx + "S_1", StringFormat("DX%d %.1f | M%d %.1f | D %.1f", InpDXPeriodo, g_mercado.dx, InpDXMediaPeriodo, g_mercado.dxMedia, MathAbs(InpDXDistanciaMedia)), bx4 + 8, boxY + 30, PnlCorTexto(), fonte, "Consolas");
   PainelTexto(pfx + "S_2", StringFormat("B %.1f/%.1f %s | RSI %.1f", g_mercado.dxBandaBaixa, g_mercado.dxBandaAlta, TextoDXStatus(), g_mercado.rsi), bx4 + 8, boxY + 50, PnlCorTexto(), fonte, "Consolas");
   PainelTexto(pfx + "S_3", StringFormat("Prox %s", proxAumento), bx4 + 8, boxY + 68, PnlCorAmarelo(), fonte, "Consolas");
   int rowY = boxY + boxH + 8;
   PainelRetangulo(pfx + "ROW_BG", x + 8, rowY, largura - 16, 36, PnlCorBloco2(), PnlCorLinha());
   PainelTexto(pfx + "R1", StringFormat("A1 %s | A2 %s | A3 %s | A4 %s | A5 %s", precoA1, precoA2, precoA3, precoA4, precoA5),
               x + 16, rowY + 9, PnlCorTexto(), fonte, "Consolas");
   int msgY = rowY + 40;
   PainelRetangulo(pfx + "MSG_BG", x + 8, msgY, largura - 16, 24, PnlCorBloco(), PnlCorLinha());
   string msg = g_compra.ultimaMensagem;
   if(msg == "") msg = g_venda.ultimaMensagem;
   if(msg == "") msg = g_mestre.mensagemGeral;
   if(msg == "") msg = "Monitorando mercado.";
   PainelTexto(pfx + "MSG_T", "EVENTO", x + 16, msgY + 5, PnlCorTitulo(), fonte, "Arial Bold");
   PainelTexto(pfx + "MSG_V", msg, x + 96, msgY + 5, PnlCorTexto(), fonte, "Consolas");
}

void DesenharPainelReduzido(int x, int y, int largura, int altura)
{
   string pfx = "COPA_AR100_CARD_RED_";
   int fonte = InpPainelFonteTexto;
   if(fonte < 8) fonte = 8;
   if(largura < 720) largura = 720;
   if(altura < 190) altura = 190;
   FotoFinanceiraPainelFIX362 fotoRedFIX362;
   MontarFotoFinanceiraPainelFIX362(fotoRedFIX362,false);
   PainelRetangulo(pfx + "BG", x, y, largura, altura, PnlCorFundo(), PnlCorLinha());
   PainelRetangulo(pfx + "HDR", x + 8, y + 8, largura - 16, 34, PnlCorAbaAtiva(), PnlCorAbaAtiva());
   string tituloCompactoFIX320=(g_painelCompactoAutomaticoFIX320 ? "AR_100 PREMIUM" : "AR_100 REDUZIDO");
   PainelTextoCortado(pfx + "T1",
               StringFormat("%s | %s | %s | %s", tituloCompactoFIX320, _Symbol, TextoMagicTopoPiscando(), TimeToString(TimeCurrent(), TIME_SECONDS)),
               x + 16, y + 17, CorMagicPiscando(clrWhite), fonte + 1, "Arial Bold", largura - 445);
   DesenharBotoesModoPainel(pfx + "BTN_", x + largura - 250, y + 14, fonte);
   PainelTexto(pfx + "A",
               StringFormat("Magic %s | %s | Aberto %s | Def %s",
                            IntegerToString(g_compra.magic), TextoPosicaoCard(g_compra),
                            PnlMoedaBRL(fotoRedFIX362.abertoCompra), PnlMoedaBRL(g_compra.valorDefendido)),
               x + 16, y + 52, CorFinanceiro(fotoRedFIX362.abertoCompra), fonte, "Consolas");
   PainelTexto(pfx + "B",
               StringFormat("Magic %s | %s | Aberto %s | Def %s",
                            IntegerToString(g_venda.magic), TextoPosicaoCard(g_venda),
                            PnlMoedaBRL(fotoRedFIX362.abertoVenda), PnlMoedaBRL(g_venda.valorDefendido)),
               x + 16, y + 70, CorFinanceiro(fotoRedFIX362.abertoVenda), fonte, "Consolas");
   PainelTexto(pfx + "T",
               StringFormat("HEAD C+V %s | GAIN %s | LOSS %s | REST %s | %s",
                            PnlMoedaBRL(fotoRedFIX362.abertoHead),
                            PnlMoedaBRL(fotoRedFIX362.gainHead),
                            PnlMoedaBRL(-fotoRedFIX362.lossHead),
                            PnlMoedaBRL(fotoRedFIX362.restanteHead),
                            TextoControleOperacaoFIX284()),
               x + 16, y + 88, CorFinanceiro(fotoRedFIX362.abertoHead), fonte, "Consolas");
   PainelTexto(pfx + "MKT",
               StringFormat("DX%d %.1f | M%d %.1f | DIST %.1f | B %.1f/%.1f %s | RSI %.1f | SCORE %.1f %s",
                            InpDXPeriodo, g_mercado.dx, InpDXMediaPeriodo, g_mercado.dxMedia, MathAbs(InpDXDistanciaMedia),
                            g_mercado.dxBandaBaixa, g_mercado.dxBandaAlta,
                            TextoDXStatus(), g_mercado.rsi,
                            g_mercado.scoreFluxo, NomeStatusMercado(g_mercado.status)),
               x + 16, y + 110, PnlCorTexto(), fonte, "Consolas");
   if(InpHeadMostrarInfoNoPainel && InpUsarRoboHeadExterno)
      PainelTexto(pfx + "HEAD", TextoHeadExterno(), x + 16, y + 128, PnlCorAmarelo(), fonte, "Consolas");
   else
      ObjectDelete(0, pfx + "HEAD");
   PainelTexto(pfx + "LOG", ResumoGerenciadorOrdens(), x + 16, y + 146,
               (g_ordemRejeitadas > 0 ? PnlCorVermelho() : PnlCorSecundario()), fonte, "Consolas");
}

void PainelRetangulo(string nome, int x, int y, int largura, int altura, color fundo, color borda)
{
   bool novo = false;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return;
      novo = true;
   }
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, PainelAutoXFIX319(nome,x));
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, PainelAutoYFIX319(nome,y));
   ObjectSetInteger(0, nome, OBJPROP_XSIZE, PainelAutoWFIX319(nome,largura));
   ObjectSetInteger(0, nome, OBJPROP_YSIZE, PainelAutoHFIX319(nome,altura));
   ObjectSetInteger(0, nome, OBJPROP_BGCOLOR, fundo);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, borda);
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nome, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, nome, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 1000);
}

void PainelTexto(string nome, string texto, int x, int y, color cor, int fonte, string fontName)
{
   bool novo = false;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_LABEL, 0, 0, 0))
         return;
      novo = true;
   }
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, PainelAutoXFIX319(nome,x));
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, PainelAutoYFIX319(nome,y));
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, PainelAutoFonteFIX319(nome,fonte));
   string fonteVisual="Tahoma";
   ObjectSetString(0, nome, OBJPROP_FONT, fonteVisual);
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 1000);
}

string TextoCortarPainel(string texto, int larguraPx, int fonte)
{
   if(larguraPx <= 0)
      return texto;
   int fonteCalc = fonte;
   if(fonteCalc < 6)
      fonteCalc = 6;
   int charPx = (int)MathRound((double)fonteCalc * 0.62);
   if(charPx < 5)
      charPx = 5;
   int maxChars = larguraPx / charPx;
   if(maxChars < 4)
      maxChars = 4;
   if(StringLen(texto) <= maxChars)
      return texto;
   if(maxChars <= 4)
      return StringSubstr(texto, 0, maxChars);
   return StringSubstr(texto, 0, maxChars - 2) + "..";
}

void PainelTextoCortado(string nome, string texto, int x, int y, color cor, int fonte, string fontName, int larguraPx)
{
   PainelTexto(nome, TextoCortarPainel(texto, larguraPx, fonte), x, y, cor, fonte, fontName);
}

string LinhaJanelaCabecalho(int idx)
{
   if(idx < 0 || idx >= 5)
      return "J? OFF";
   return StringFormat("J%d %s %s", idx + 1, g_janelas[idx].horario, g_janelas[idx].ativa ? "ON" : "OFF");
}

string PrecoNivelAumentoTextoIndice(EstadoLado &estado, int indiceZero)
{
   double nivel = PrecoNivelAumentoValorIndice(estado, indiceZero);
   if(nivel <= 0.0)
      return "--";
   return DoubleToString(nivel, _Digits);
}

string StatusAumentoCard(EstadoLado &estado, RegraAumento &a, int idx)
{
   if(BloquearNovasOperacoesFimDiaFIX215())
      return "FIM DIA";
   if(!a.ativa)
      return "OFF";
   if(!estado.posicaoAberta)
      return "SEM POS";

   // FIX451: o nível rearmado não pode continuar exibido como FEITO.
   int nivelRearmeCard=NivelInicioRearmeFIX248(estado);
   if(nivelRearmeCard==idx)
   {
      ulong ticketRearme=0;
      double precoRearme=0.0,volumeRearme=0.0;
      long tipoRearme=-1;
      if(ObterPosicaoAumentoNivelFIX212(estado,idx,ticketRearme,precoRearme,volumeRearme,tipoRearme))
         return "ABERTO";
      bool aguardaRetorno=(estado.lado==LADO_COMPRA ? g_aguardaRetornoLinhaBuyFIX248[idx-1] : g_aguardaRetornoLinhaSellFIX248[idx-1]);
      if(aguardaRetorno)
         return "RETORNO";
      if(!TimerAumentoLiberado(estado,a,idx-1))
         return "TIMER";
      string statusRearme=StatusCandleAumentoFIX224(estado,idx-1);
      if(statusRearme=="PRECO")
         return "PRECO";
      if(statusRearme=="FECHA")
         return "CANDLE";
      return "REENTRA";
   }

   if(!ModoAumentoSomenteScore() && InpAumentosLivreTeste && !InpAumentosLivreIgnorarTimerPreco)
   {
      int proximo = estado.aumentosExecutados;
      if(estado.ultimoNivelAumentoUsado > proximo)
         proximo = estado.ultimoNivelAumentoUsado;
      if(proximo < 0) proximo = 0;
      int indice = idx - 1;
      if(indice < proximo)
         return "FEITO";
      if(indice > proximo)
         return "FILA";
      if(!TimerAumentoLiberado(estado, a))
         return "TIMER";
      string statusCandle=StatusCandleAumentoFIX224(estado,indice);
      if(statusCandle=="PRECO")
         return "PRECO";
      if(statusCandle=="FECHA")
         return "CANDLE";
      return "PRONTO";
   }
   if(estado.ultimoNivelAumentoUsado == idx && estado.aumentosExecutados > 0)
      return "FEITO";
   if(!g_gerAumentos.ativo)
      return "BLOQ GER";
   if(false /* FIX440 sem limite global de contratos */)
      return "MAX";
   // FIX362: o card nao apresenta bloqueio histórico/meta para A1-A4.
   int alvo = EscolherIndiceAumentoInteligente(estado) + 1;
   if(idx == alvo)
   {
      if(InpAumentosLivreTeste && InpAumentosLivreIgnorarTimerPreco && !ModoAumentoSomenteScore())
         return "LIVRE";
      if(!TimerAumentoLiberado(estado, a))
         return "TIMER";
      string statusCandle=StatusCandleAumentoFIX224(estado,idx-1);
      if(statusCandle=="PRECO")
         return "PRECO";
      if(statusCandle=="FECHA")
         return "CANDLE";
      if(ModoAumentoSomenteScore())
      {
         string detalheScoreCard = "";
         if(!ScoreAumentoAutoriza(estado, idx - 1, detalheScoreCard))
            return TextoScoreAumentoNivel(estado, idx - 1);
         return "SCORE OK";
      }
      bool filtrosCardOk=(InpAumentosLivreTeste || ValidarFiltros(a.filtros, estado.lado));
      if(!filtrosCardOk)
         return "FILTRO";
      if(!InpAumentosLivreTeste && InpScoreVolumeAumentosAtivo && !ModoContinuidadeTesteFIX352())
      {
         string detalheVolumeCard="";
         if(!ScoreVolumeAumentoAutorizaFIX334(LadoDaPosicaoAtual(estado),idx-1,detalheVolumeCard))
            return TextoScoreVolumeAumentoFIX334(LadoDaPosicaoAtual(estado),idx-1);
      }
      return "PRONTO";
   }
   return "FILA";
}

string ProximoAumentoCard(EstadoLado &estado)
{
   if(BloquearNovasOperacoesFimDiaFIX215())
      return TextoStatusFimDiaFIX215();
   if(!estado.posicaoAberta)
      return "aguardando entrada A0";
   int alvo = -1;
   if(!ModoAumentoSomenteScore() && InpAumentosLivreTeste && !InpAumentosLivreIgnorarTimerPreco)
   {
      alvo = estado.aumentosExecutados;
      if(estado.ultimoNivelAumentoUsado > alvo)
         alvo = estado.ultimoNivelAumentoUsado;
   }
   else
      alvo = EscolherIndiceAumentoInteligente(estado);
   if(alvo < 0 && InpAumentosLivreTeste)
      alvo = estado.aumentosExecutados;
   if(alvo < 0)
      return "BLOQUEADO";
   if(alvo >= 5)
      return "aumentos concluidos";
   string prefixoNivel=EscadaA1RearmadaFIX225(estado) ? "NOVO A" : "A";
   if(ModoAumentoSomenteScore())
      return StringFormat("%s%d | %s | LINHA %s | %s", prefixoNivel, alvo + 1, StatusAumentoCard(estado, g_aumentos[alvo], alvo + 1), PrecoNivelAumentoTextoIndice(estado, alvo), TextoScoreAumentoNivel(estado, alvo));
   string resumo=StringFormat("%s%d | %s | LINHA %s", prefixoNivel, alvo + 1, StatusAumentoCard(estado, g_aumentos[alvo], alvo + 1), PrecoNivelAumentoTextoIndice(estado, alvo));
   if(InpScoreVolumeAumentosAtivo && !InpAumentosLivreTeste)
   {
      string textoVolumeFIX352=TextoScoreVolumeAumentoFIX334(LadoDaPosicaoAtual(estado),alvo);
      resumo+=" | "+textoVolumeFIX352+(ModoContinuidadeTesteFIX352() ? " DIAG" : "");
   }
   return resumo;
}

string TextoPosicaoCard(EstadoLado &estado)
{
   if(!estado.posicaoAberta)
      return "SEM POS";
   if(estado.tipoPosicaoAtual == POSITION_TYPE_BUY)
      return "COMPRADO";
   if(estado.tipoPosicaoAtual == POSITION_TYPE_SELL)
      return "VENDIDO";
   if(estado.tipoPosicaoAtual == -2)
      return "MISTO";
   return "SEM POS";
}

color CorFinanceiro(double valor)
{
   if(valor > 0.0000001)
      return clrLime;
   if(valor < -0.0000001)
      return clrRed;
   return clrSilver;
}


color CorStatusTexto(string status)
{
   status = Upper(status);
   if(StringFind(status, "FEITO") >= 0 || StringFind(status, "PRONTO") >= 0)
      return clrLime;
   if(StringFind(status, "BLOQ") >= 0 || StringFind(status, "MAX") >= 0)
      return clrRed;
   if(StringFind(status, "AGUARDA") >= 0 || StringFind(status, "FILA") >= 0 || StringFind(status, "NORMAL") >= 0)
      return clrYellow;
   if(StringFind(status, "FORTE") >= 0)
      return clrLime;
   if(StringFind(status, "FRACO") >= 0)
      return clrSilver;
   if(StringFind(status, "EXTREMO") >= 0)
      return clrRed;
   return clrSilver;
}

color CorLadoTexto(ENUM_LADO_ROBO lado)
{
   if(lado == LADO_COMPRA)
      return clrLime;
   if(lado == LADO_VENDA)
      return clrRed;
   if(lado == LADO_AMBOS)
      return clrAqua;
   return clrSilver;
}

void LimparEntradasHistoricasGraficoFIX385()
{
   string prefixo="AR100_HIST_ENTRY_FIX388_";
   for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
   {
      string nome=ObjectName(0,i,0,-1);
      if(StringFind(nome,prefixo)==0)
         ObjectDelete(0,nome);
   }
}

bool DealEhEntradaPlotavelGraficoFIX385(ulong deal)
{
   if(deal==0)
      return false;
   if(!HistoryDealSelect(deal))
      return false;
   if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
      return false;
   long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(entry!=DEAL_ENTRY_IN)
      return false;
   long tipo=HistoryDealGetInteger(deal,DEAL_TYPE);
   if(tipo!=DEAL_TYPE_BUY && tipo!=DEAL_TYPE_SELL)
      return false;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   // FIX388: operacao continua somente em 999050/999051.
   // Para o desenho historico, preserva tambem as entradas antigas 888050/888051.
   bool magicVisual=(magic==999050 || magic==999051 || magic==888050 || magic==888051);
   if(!magicVisual)
      return false;
   return true;
}

void PlotarEntradaHistoricaNoGraficoFIX385(ulong deal)
{
   if(!DealEhEntradaPlotavelGraficoFIX385(deal))
      return;

   datetime quando=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
   double preco=HistoryDealGetDouble(deal,DEAL_PRICE);
   long tipo=HistoryDealGetInteger(deal,DEAL_TYPE);
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   int nivel=NivelAumentoDealRobustoFIX296(deal);
   color cor=(tipo==DEAL_TYPE_BUY ? PnlCorVerde() : PnlCorVermelho());
   string lado=(tipo==DEAL_TYPE_BUY ? "BUY" : "SELL");
   string nome=StringFormat("AR100_HIST_ENTRY_FIX388_%I64u",deal);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0.0) point=1.0;
   int deslocamento=InpEntradasHistoricasDeslocamentoPontos;
   if(deslocamento<0) deslocamento=0;
   double y=preco + (tipo==DEAL_TYPE_BUY ? -deslocamento*point : deslocamento*point);

   if(ObjectFind(0,nome)<0)
   {
      if(!ObjectCreate(0,nome,OBJ_ARROW,0,quando,y))
         return;
   }
   else
   {
      ObjectMove(0,nome,0,quando,y);
   }

   int largura=InpEntradasHistoricasLarguraSeta;
   if(largura<1) largura=1;
   if(largura>2) largura=2;
   // FIX390: 241/242 sao marcadores pequenos; 233/234 geravam setas enormes.
   ObjectSetInteger(0,nome,OBJPROP_ARROWCODE,(tipo==DEAL_TYPE_BUY ? 241 : 242));
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_BACK,false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER,20);
   string desc=(nivel>0 ? StringFormat("%s A%d | Magic %d",lado,nivel,(int)magic)
                         : StringFormat("%s A0 | Magic %d",lado,(int)magic));
   ObjectSetString(0,nome,OBJPROP_TOOLTIP,desc);
}

void PlotarPosicoesAbertasProvisoriasFIX390()
{
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(magic!=999050 && magic!=999051)
         continue;
      long tipo=PositionGetInteger(POSITION_TYPE);
      if(tipo!=POSITION_TYPE_BUY && tipo!=POSITION_TYPE_SELL)
         continue;
      datetime quando=(datetime)PositionGetInteger(POSITION_TIME);
      double preco=PositionGetDouble(POSITION_PRICE_OPEN);
      if(quando<=0 || preco<=0.0)
         continue;
      string nome=StringFormat("AR100_HIST_ENTRY_FIX388_POS_%I64u",ticket);
      double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      if(point<=0.0) point=1.0;
      int deslocamento=InpEntradasHistoricasDeslocamentoPontos;
      if(deslocamento<0) deslocamento=0;
      double y=preco+(tipo==POSITION_TYPE_BUY ? -deslocamento*point : deslocamento*point);
      if(ObjectFind(0,nome)<0)
      {
         if(!ObjectCreate(0,nome,OBJ_ARROW,0,quando,y))
            continue;
      }
      else
         ObjectMove(0,nome,0,quando,y);
      ObjectSetInteger(0,nome,OBJPROP_ARROWCODE,(tipo==POSITION_TYPE_BUY ? 241 : 242));
      ObjectSetInteger(0,nome,OBJPROP_COLOR,(tipo==POSITION_TYPE_BUY ? PnlCorVerde() : PnlCorVermelho()));
      int larguraPos=InpEntradasHistoricasLarguraSeta;
      if(larguraPos<1) larguraPos=1;
      if(larguraPos>2) larguraPos=2;
      ObjectSetInteger(0,nome,OBJPROP_WIDTH,larguraPos);
      ObjectSetInteger(0,nome,OBJPROP_BACK,false);
      ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
      ObjectSetInteger(0,nome,OBJPROP_ZORDER,25);
      ObjectSetString(0,nome,OBJPROP_TOOLTIP,StringFormat("%s POSICAO ABERTA | Magic %d",
                       (tipo==POSITION_TYPE_BUY ? "BUY" : "SELL"),(int)magic));
   }
}

void AtualizarEntradasHistoricasGraficoFIX385(bool forcar=false)
{
   if(!InpPlotarEntradasHistoricasNoGrafico)
   {
      LimparEntradasHistoricasGraficoFIX385();
      return;
   }

   int dias=InpEntradasHistoricasDias;
   if(dias<1) dias=1;
   int maxSetas=InpEntradasHistoricasMaxSetas;
   if(maxSetas<10) maxSetas=10;
   datetime fim=TimeCurrent();
   datetime inicio=fim-(datetime)(dias*86400);
   if(!HistorySelect(inicio,fim))
      return;

   LimparEntradasHistoricasGraficoFIX385();
   int total=(int)HistoryDealsTotal();
   int plotadas=0;
   for(int i=total-1;i>=0;i--)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(!DealEhEntradaPlotavelGraficoFIX385(deal))
         continue;
      PlotarEntradaHistoricaNoGraficoFIX385(deal);
      plotadas++;
      if(plotadas>=maxSetas)
         break;
   }
   // FIX390: se o deal ainda nao apareceu no historico, desenha pela posicao aberta.
   PlotarPosicoesAbertasProvisoriasFIX390();
   ChartRedraw(0);
   if(forcar && InpGerenciadorOrdensExperts)
      Print("[COPA_AR100][FIX388][SETAS] plotadas=",plotadas," | magics_visuais=888050/888051/999050/999051");
}

string LinhaHistoricoPeriodo(HistoricoPeriodo &h)
{
   return StringFormat("%s | C:%d/%.2f V:%d/%.2f | Qtd:%.2f | Fin:R$ %.2f | Parc:R$ %.2f | Total:R$ %.2f",
                       h.nome,
                       h.compras,
                       h.qtdCompra,
                       h.vendas,
                       h.qtdVenda,
                       h.qtdTotal,
                       h.financeiro,
                       h.parcial,
                       h.lucroTotal);
}

string LinhaEstadoLado(EstadoLado &e)
{
   string s = "";
   s += e.nome + "\n";
   s += StringFormat("Magic: %s | Aberta: %s | Contratos: %.2f | Preco Medio: %.2f\n",
                     IntegerToString(e.magic),
                     e.posicaoAberta ? "SIM" : "NAO",
                     e.contratos,
                     e.precoMedio);
   s += StringFormat("Resultado Aberto: R$ %.2f | Protegido: %s | Valor Defendido: R$ %.2f | Longa: %s\n",
                     e.resultadoAberto,
                     e.lucroProtegido ? "SIM" : "NAO",
                     e.valorDefendido,
                     e.modoLongo ? "SIM" : "NAO");
   s += "Mensagem: " + e.ultimaMensagem + "\n";
   s += "Bloqueio Aumento: " + e.motivoBloqueioAumento + "\n";
   return s;
}

string LinhaJanela(RegraJanela &j, int idx)
{
   return StringFormat("J%d: %s | %s | Lado=%s | Qtd=%.2f | Perfil=%s | MinOK=%d",
                       idx,
                       j.ativa ? "ON" : "OFF",
                       j.horario,
                       NomeLado(j.lado),
                       j.qtd,
                       j.perfil,
                       j.filtros.minOk);
}

string LinhaAumento(RegraAumento &a, int idx)
{
   return StringFormat("A%d: %s | Qtd=%.2f | Tempo=%dm | Dist=%dpts | Gatilho=R$ %.2f | Trail=%.0f/%.0f | Lado=%s",
                       idx,
                       a.ativa ? "ON" : "OFF",
                       a.qtd,
                       a.tempoMinutos,
                       a.distanciaPontos,
                       a.gatilhoReais,
                       a.trailingAtivarReais,
                       a.trailingPassoReais,
                       NomeLado(a.lado));
}

// ============================================================================
// RESPONSABILIDADE: PAINEL FINANCEIRO E CAMPOS CRITICOS
// ============================================================================

void AplicarGraficoLimpoFIX353()
{
   if(!InpFIX353GraficoLimpoSemIndicadores)
      return;

   // Somente a parte visual e desligada. Handles e calculos usados pelos
   // filtros de entrada/aumento permanecem ativos.
   InpPlotarCandlesContra=false;
   InpFIX280PlotarBandaDXPreco=false;
   // FIX392: o modo grafico limpo NAO desliga a media simples solicitada.
   // A media continua controlada somente por InpPlotarMedia25NoGrafico.
   InpPlotarDXBandasNoGrafico=false;
   RemoverDXVisualEditavelFIX345();
   RemoverOsciladoresSelecionadosFIX343();
   // FIX392: nao apagar a media aqui; a rotina visual redesenha normalmente.
   LimparCandlesContraFIX258();
}

void MontarFotoFinanceiraPainelFIX362(FotoFinanceiraPainelFIX362 &foto, bool forcar)
{
   ulong agoraMs=GetTickCount64();
   if(!forcar && g_ultimaFotoFinanceiraMsFIX362>0 &&
      agoraMs>=g_ultimaFotoFinanceiraMsFIX362 &&
      (agoraMs-g_ultimaFotoFinanceiraMsFIX362)<120)
   {
      foto=g_fotoFinanceiraPainelFIX362;
      return;
   }

   ZeroMemory(foto);
   foto.calculadaEm=TimeCurrent();
   CalcularAbertoTotalABGrupoDiretoBase(foto.qtdCompra,foto.qtdVenda,foto.qtdTotal,
                                        foto.abertoCompra,foto.abertoVenda,foto.abertoHead);
   foto.abertoCompra=NormalizeDouble(foto.abertoCompra,2);
   foto.abertoVenda=NormalizeDouble(foto.abertoVenda,2);
   foto.abertoHead=NormalizeDouble(foto.abertoCompra+foto.abertoVenda,2);
   foto.realizadoCompra=NormalizeDouble(RealizadoHojeLadoFIX310(LADO_COMPRA),2);
   foto.realizadoVenda=NormalizeDouble(RealizadoHojeLadoFIX310(LADO_VENDA),2);
   foto.realizadoDia=NormalizeDouble(foto.realizadoCompra+foto.realizadoVenda,2);
   foto.gainHead=GainHeadEfetivoFIX362();
   foto.lossHead=LossHeadEfetivoFIX362();
   foto.restanteHead=NormalizeDouble(foto.lossHead+foto.abertoHead,2);
   if(foto.restanteHead<0.0) foto.restanteHead=0.0;

   g_fotoFinanceiraPainelFIX362=foto;
   g_ultimaFotoFinanceiraMsFIX362=agoraMs;
}

bool DealAceitoGanhoQtdFIX367(ulong deal,long magicC,long magicV)
{
   if(deal==0 || !HistoryDealSelect(deal))
      return false;
   long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY && entry!=DEAL_ENTRY_INOUT)
      return false;
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
   if(magic!=magicC && magic!=magicV)
      return false;
   string simbolo=HistoryDealGetString(deal,DEAL_SYMBOL);
   if(!SimboloAceitoHistoricoFIX347(simbolo))
      return false;
   // HistorySelect já está restrito à conta atual. O comentário não é autoridade
   // para GANHO QTD/R$: corretora/servidor pode alterar ou truncar essa identidade.
   return true;
}

void AtualizarGanhoQtdReaisFIX362(bool forcar)
{
   ulong agoraMs=GetTickCount64();
   if(!forcar && g_ultimaAtualizacaoGanhoQtdMsFIX362>0 &&
      agoraMs>=g_ultimaAtualizacaoGanhoQtdMsFIX362 &&
      (agoraMs-g_ultimaAtualizacaoGanhoQtdMsFIX362)<1000)
      return;

   ZeroMemory(g_ganhoQtdReaisFIX362);
   datetime fim=TimeCurrent();
   datetime inicio=InicioDoDia(AgoraServidorHistorico());
   if(HistorySelect(inicio,fim))
   {
      int total=HistoryDealsTotal();
      long magicC=MagicCompraAtual();
      long magicV=MagicVendaAtual();
      ulong dealsContadosFIX367[];
      ArrayResize(dealsContadosFIX367,0);
      for(int i=0;i<total;i++)
      {
         ulong deal=HistoryDealGetTicket(i);
         if(!DealAceitoGanhoQtdFIX367(deal,magicC,magicV)) continue;
         bool repetido=false;
         for(int k=0;k<ArraySize(dealsContadosFIX367);k++)
         {
            if(dealsContadosFIX367[k]==deal)
            {
               repetido=true;
               break;
            }
         }
         if(repetido) continue;
         int n=ArraySize(dealsContadosFIX367);
         ArrayResize(dealsContadosFIX367,n+1);
         dealsContadosFIX367[n]=deal;

         double resultado=ResultadoDealSeguroReaisFIX313(deal);
         if(resultado<=0.000001) continue;
         double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
         long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
         if(magic==magicC)
         {
            g_ganhoQtdReaisFIX362.qtdCompra+=volume;
            g_ganhoQtdReaisFIX362.reaisCompra+=resultado;
         }
         else if(magic==magicV)
         {
            g_ganhoQtdReaisFIX362.qtdVenda+=volume;
            g_ganhoQtdReaisFIX362.reaisVenda+=resultado;
         }
      }
   }
   g_ganhoQtdReaisFIX362.qtdHead=NormalizeDouble(g_ganhoQtdReaisFIX362.qtdCompra+g_ganhoQtdReaisFIX362.qtdVenda,2);
   g_ganhoQtdReaisFIX362.reaisHead=NormalizeDouble(g_ganhoQtdReaisFIX362.reaisCompra+g_ganhoQtdReaisFIX362.reaisVenda,2);
   g_ultimaAtualizacaoGanhoQtdMsFIX362=agoraMs;
}

string TextoGanhoQtdReaisFIX362(ENUM_LADO_ROBO lado, bool head)
{
   AtualizarGanhoQtdReaisFIX362(false);
   if(head)
      return StringFormat("%.0fC / %s",g_ganhoQtdReaisFIX362.qtdHead,PnlMoedaBRL(g_ganhoQtdReaisFIX362.reaisHead));
   if(lado==LADO_VENDA)
      return StringFormat("%.0fC / %s",g_ganhoQtdReaisFIX362.qtdVenda,PnlMoedaBRL(g_ganhoQtdReaisFIX362.reaisVenda));
   return StringFormat("%.0fC / %s",g_ganhoQtdReaisFIX362.qtdCompra,PnlMoedaBRL(g_ganhoQtdReaisFIX362.reaisCompra));
}

string TextoLossHeadGerenciadorFIX367()
{
   FotoFinanceiraPainelFIX362 foto;
   MontarFotoFinanceiraPainelFIX362(foto,false);
   return StringFormat("LOSS HEAD C %s + V %s = %s | LIM %s | REST %s",
                       TextoMoedaPainelCurto(foto.abertoCompra),
                       TextoMoedaPainelCurto(foto.abertoVenda),
                       TextoMoedaPainelCurto(foto.abertoHead),
                       TextoMoedaPainelCurto(-foto.lossHead),
                       TextoMoedaPainelCurto(foto.restanteHead));
}

int QtdGanhoHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   int qtd=0,parciais=0;
   if(lado==LADO_COMPRA)
   {
      qtd=h.tradesLucroCompra;
      parciais=h.parciaisLucroQtdCompra;
   }
   else if(lado==LADO_VENDA)
   {
      qtd=h.tradesLucroVenda;
      parciais=h.parciaisLucroQtdVenda;
   }
   else
   {
      qtd=h.tradesLucroCompra+h.tradesLucroVenda;
      parciais=h.parciaisLucroQtdCompra+h.parciaisLucroQtdVenda;
   }
   qtd-=parciais;
   return (qtd>0 ? qtd : 0);
}

int QtdLossHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   int qtd=0,parciais=0;
   if(lado==LADO_COMPRA)
   {
      qtd=h.tradesPrejuCompra;
      parciais=h.parciaisPrejuQtdCompra;
   }
   else if(lado==LADO_VENDA)
   {
      qtd=h.tradesPrejuVenda;
      parciais=h.parciaisPrejuQtdVenda;
   }
   else
   {
      qtd=h.tradesPrejuCompra+h.tradesPrejuVenda;
      parciais=h.parciaisPrejuQtdCompra+h.parciaisPrejuQtdVenda;
   }
   qtd-=parciais;
   return (qtd>0 ? qtd : 0);
}

int QtdParcialHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   if(lado==LADO_COMPRA)
      return h.parciaisLucroQtdCompra+h.parciaisPrejuQtdCompra;
   if(lado==LADO_VENDA)
      return h.parciaisLucroQtdVenda+h.parciaisPrejuQtdVenda;
   return h.parciaisLucroQtdCompra+h.parciaisPrejuQtdCompra+
          h.parciaisLucroQtdVenda+h.parciaisPrejuQtdVenda;
}

double FinanceiroGanhoHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   double valor=0.0;
   if(lado==LADO_COMPRA)
      valor=h.financeiroLucroCompra-h.financeiroParcialLucroCompra;
   else if(lado==LADO_VENDA)
      valor=h.financeiroLucroVenda-h.financeiroParcialLucroVenda;
   else
      valor=(h.financeiroLucroCompra-h.financeiroParcialLucroCompra)+
            (h.financeiroLucroVenda-h.financeiroParcialLucroVenda);
   return NormalizeDouble(valor,2);
}

double FinanceiroLossHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   double valor=0.0;
   if(lado==LADO_COMPRA)
      valor=h.financeiroPrejuCompra-h.financeiroParcialPrejuCompra;
   else if(lado==LADO_VENDA)
      valor=h.financeiroPrejuVenda-h.financeiroParcialPrejuVenda;
   else
      valor=(h.financeiroPrejuCompra-h.financeiroParcialPrejuCompra)+
            (h.financeiroPrejuVenda-h.financeiroParcialPrejuVenda);
   return NormalizeDouble(valor,2);
}

double FinanceiroParcialHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   if(lado==LADO_COMPRA) return NormalizeDouble(h.parcialCompra,2);
   if(lado==LADO_VENDA) return NormalizeDouble(h.parcialVenda,2);
   return NormalizeDouble(h.parcialCompra+h.parcialVenda,2);
}

double TotalHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   return NormalizeDouble(FinanceiroGanhoHistoricoCardFIX368(h,lado)+
                          FinanceiroLossHistoricoCardFIX368(h,lado)+
                          FinanceiroParcialHistoricoCardFIX368(h,lado),2);
}

double AcertoHistoricoCardFIX368(HistoricoPeriodo &h, ENUM_LADO_ROBO lado)
{
   int ganhos=QtdGanhoHistoricoCardFIX368(h,lado);
   int losses=QtdLossHistoricoCardFIX368(h,lado);
   int base=ganhos+losses;
   if(base<=0) return 0.0;
   return NormalizeDouble(100.0*(double)ganhos/(double)base,1);
}

string PeriodoHistoricoCardFIX368()
{
   return NomePeriodoHistoricoPainel(g_periodoHistoricoAtivo);
}

// FIX369: formato exclusivo da linha historica. O cabecalho G$/L$/P$
// ja identifica dinheiro, portanto as celulas nao repetem "R$".
string TextoFinanceiroHistoricoCompactoFIX369(double valor)
{
   double v=NormalizeDouble(valor,2);
   if(MathAbs(v)<0.005)
      return "0";

   double absV=MathAbs(v);
   bool inteiro=(MathAbs(absV-MathRound(absV))<0.005);
   string numero=DoubleToString(absV,(inteiro ? 0 : 2));
   StringReplace(numero,".",",");

   if(v>0.0)
      return "+"+numero;
   return "-"+numero;
}

void AtualizarGrupoHistoricoObjetosFIX368(string pHist,string grupo,HistoricoPeriodo &h,ENUM_LADO_ROBO lado,color corGrupo,int &ok,int &total)
{
   int gq=QtdGanhoHistoricoCardFIX368(h,lado);
   int lq=QtdLossHistoricoCardFIX368(h,lado);
   int pq=QtdParcialHistoricoCardFIX368(h,lado);
   double gf=FinanceiroGanhoHistoricoCardFIX368(h,lado);
   double lf=FinanceiroLossHistoricoCardFIX368(h,lado);
   double pf=FinanceiroParcialHistoricoCardFIX368(h,lado);
   double tot=TotalHistoricoCardFIX368(h,lado);
   double pct=AcertoHistoricoCardFIX368(h,lado);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_GQ",IntegerToString(gq),corGrupo,ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_GF",TextoFinanceiroHistoricoCompactoFIX369(gf),CorFinanceiro(gf),ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_LQ",IntegerToString(lq),corGrupo,ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_LF",TextoFinanceiroHistoricoCompactoFIX369(lf),CorFinanceiro(lf),ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_PQ",IntegerToString(pq),corGrupo,ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_PF",TextoFinanceiroHistoricoCompactoFIX369(pf),CorFinanceiro(pf),ok,total);
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_TOT",TextoFinanceiroHistoricoCompactoFIX369(tot),CorFinanceiro(tot),ok,total);
   color corPct=(gq+lq<=0 ? PnlCorSecundario() : (pct>=50.0 ? PnlCorVerde() : PnlCorVermelho()));
   AtualizarObjetoValorFIX354(pHist+grupo+"_V_PCT",StringFormat("%.1f%%",pct),corPct,ok,total);
}

void AtualizarPainelFinanceiroImediatoFIX353(bool forcarHistorico)
{
   InvalidarSnapshotTotalABFIX292();
   g_ultimaFotoFinanceiraMsFIX362=0;
   g_ultimaAtualizacaoGanhoQtdMsFIX362=0;
   g_ultimaAtualizacaoEstadosMsFIX287=0;
   g_ultimaQtdPosicoesEstadosFIX287=-1;
   if(forcarHistorico)
      g_ultimaAtualizacaoHistorico=0;
   g_ultimaAtualizacaoPainelVisual=0;
   g_ultimaAtualizacaoRodapeVisual=0;
   AtualizarPainelMestre();
   PainelChartRedrawLeve(true);
}

void PainelChartRedrawLeve(bool clique)
{
   ulong agoraMs=GetTickCount64();
   bool passouUmSegundo=(g_ultimoRedrawPainelFIX353==0 ||
                         agoraMs<g_ultimoRedrawPainelFIX353 ||
                         (agoraMs-g_ultimoRedrawPainelFIX353)>=1000);
   if(clique || !InpPainelRedrawManualSomenteClique || passouUmSegundo)
   {
      g_ultimoRedrawPainelFIX353=agoraMs;
      ChartRedraw(0);
   }
}

bool AtualizarObjetoValorFIX354(string nome,string texto,color cor,int &ok,int &total)
{
   // FIX362: FULL audita todos os campos; REDUZIDO/SLIM atualizam somente
   // os objetos realmente existentes, sem bloquear a sincronizacao financeira.
   if(ObjectFind(0,nome)<0)
   {
      if(g_modoPainelVisualAtivo==PAINEL_VISUAL_COMPLETO && InpMostrarCardAumentosVisual)
         total++;
      return (g_modoPainelVisualAtivo!=PAINEL_VISUAL_COMPLETO);
   }
   total++;
   bool gravouTexto=ObjectSetString(0,nome,OBJPROP_TEXT,texto);
   bool gravouCor=ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   string lido=ObjectGetString(0,nome,OBJPROP_TEXT);
   bool certo=(gravouTexto && gravouCor && lido==texto);
   if(certo)
      ok++;
   return certo;
}

void RegistrarAuditoriaCamposPainelFIX354(int objOk,int objTotal,int formulaOk,int formulaTotal,string movimento,double bid,double ask,double abertoC,double abertoV,double realizadoC,double realizadoV,double saldoC,double saldoV)
{
   datetime agora=TimeCurrent();
   if(g_ultimaAuditoriaCamposFIX354>0 && (agora-g_ultimaAuditoriaCamposFIX354)<2)
      return;
   g_ultimaAuditoriaCamposFIX354=agora;
   g_auditoriaCamposOkFIX354=objOk+formulaOk;
   g_auditoriaCamposTotalFIX354=objTotal+formulaTotal;
   bool passou=(objTotal>0 && objOk==objTotal && formulaTotal>0 && formulaOk==formulaTotal && StringFind(movimento,"FALHA")<0);
   g_auditoriaCamposStatusFIX354=StringFormat("OBJ %d/%d | FORM %d/%d | MOV %s | %s",
                                              objOk,objTotal,formulaOk,formulaTotal,movimento,
                                              passou?"OK":"FALHA");
   if(InpGerenciadorOrdensExperts)
   {
      Print("[COPA_AR100][FIX354][AUD_CAMPO_A_CAMPO] ",
            g_auditoriaCamposStatusFIX354,
            " | BID=",DoubleToString(bid,_Digits),
            " ASK=",DoubleToString(ask,_Digits),
            " | C ABR=",PnlMoedaBRL(abertoC)," REAL=",PnlMoedaBRL(realizadoC)," SAL=",PnlMoedaBRL(saldoC),
            " | V ABR=",PnlMoedaBRL(abertoV)," REAL=",PnlMoedaBRL(realizadoV)," SAL=",PnlMoedaBRL(saldoV),
            " | AB ABR=",PnlMoedaBRL(abertoC+abertoV),
            " REAL=",PnlMoedaBRL(realizadoC+realizadoV),
            " SAL=",PnlMoedaBRL(saldoC+saldoV));
   }
}

void AtualizarCamposFinanceirosCriticosFIX354(bool forcarRedraw)
{
   // FIX362: a mesma rotina atualiza FULL, REDUZIDO e SLIM.
   // Objetos inexistentes no modo compacto sao ignorados pela funcao de escrita.

   ulong agoraMs=GetTickCount64();
   const ulong intervaloMs=120;
   if(!forcarRedraw && g_ultimaAtualizacaoCamposFIX354>0 &&
      agoraMs>=g_ultimaAtualizacaoCamposFIX354 &&
      (agoraMs-g_ultimaAtualizacaoCamposFIX354)<intervaloMs)
      return;
   g_ultimaAtualizacaoCamposFIX354=agoraMs;

   // Uma única fotografia de mercado para todos os campos. Assim nenhuma linha
   // do painel usa preço de um tick diferente da linha vizinha.
   MqlTick tick;
   ZeroMemory(tick);
   SymbolInfoTick(_Symbol,tick);

   // Força releitura das posições e do resultado aberto antes de escrever textos.
   g_ultimaAtualizacaoEstadosMsFIX287=0;
   g_ultimaQtdPosicoesEstadosFIX287=-1;
   AtualizarEstadosDePosicao();

   FotoFinanceiraPainelFIX362 fotoFIX362;
   MontarFotoFinanceiraPainelFIX362(fotoFIX362,forcarRedraw);
   double qtdC=fotoFIX362.qtdCompra,qtdV=fotoFIX362.qtdVenda,qtdT=fotoFIX362.qtdTotal;
   double abertoC=fotoFIX362.abertoCompra,abertoV=fotoFIX362.abertoVenda,abertoT=fotoFIX362.abertoHead;

   HistoricoPeriodo histSel;
   ObterHistoricoSelecionado(histSel);
   bool periodoDia=(g_periodoHistoricoAtivo==HIST_PAINEL_DIA);

   // SALDO DO PERÍODO: realizado oficial + variação aberta do dia.
   // A variação é calculada com o aberto DIRETO desta mesma fotografia, não com
   // um valor guardado por outra rotina. Mantém a base da virada para posições overnight.
   double realizadoC=periodoDia ? RealizadoHojeLadoFIX310(LADO_COMPRA) : histSel.financeiroCompra;
   double realizadoV=periodoDia ? RealizadoHojeLadoFIX310(LADO_VENDA)  : histSel.financeiroVenda;
   double abertoPeriodoC=periodoDia ? NormalizeDouble(abertoC-g_abertoBaseDiaCompraFIX310,2) : 0.0;
   double abertoPeriodoV=periodoDia ? NormalizeDouble(abertoV-g_abertoBaseDiaVendaFIX310,2)  : 0.0;
   double saldoPeriodoC=periodoDia ? abertoPeriodoC : NormalizeDouble(realizadoC+abertoPeriodoC,2);
   double saldoPeriodoV=periodoDia ? abertoPeriodoV : NormalizeDouble(realizadoV+abertoPeriodoV,2);
   double realizadoAB=NormalizeDouble(realizadoC+realizadoV,2);
   double abertoPeriodoAB=NormalizeDouble(abertoPeriodoC+abertoPeriodoV,2);
   double saldoPeriodoAB=periodoDia ? abertoPeriodoAB : NormalizeDouble(realizadoAB+abertoPeriodoAB,2);

   EstadoLado local;
   ObterEstadoResumoPainelLocal(local);
   AtualizarEstadoLado(local);
   bool localVenda=(local.lado==LADO_VENDA);
   double realizadoPeriodoLocal=localVenda ? realizadoV : realizadoC;
   double abertoPeriodoLocal=localVenda ? abertoPeriodoV : abertoPeriodoC;
   double saldoPeriodoLocal=localVenda ? saldoPeriodoV : saldoPeriodoC;
   double abertoDiretoLocal=localVenda ? abertoV : abertoC;
   double qtdLocal=localVenda ? qtdV : qtdC;

   ResumoFinanceiroPainel rfLocal;
   CalcularResumoFinanceiroSlotPainel(local,histSel,rfLocal);
   if(periodoDia)
      AplicarAbertoDiretoNoResumoMagic(rfLocal,local.magic);

   // Campos de OPERAÇÃO seguem exatamente a regra do desenho original.
   double realOperLocal=rfLocal.realizado;
   double abertoOperLocal=rfLocal.aberto;
   double saldoOperLocal=rfLocal.saldo;
   double lucroLocal=rfLocal.lucro;
   double prejuLocal=rfLocal.prejuizo;
   double parcialLocal=rfLocal.parcialPositiva;
   int qtdParcialLocal=rfLocal.qtdParciais;
   int saidasLocal=rfLocal.totalTrades;
   int saidasLucroLocal=rfLocal.tradesLucro;
   int saidasPrejuLocal=rfLocal.tradesPrejuizo;
   if(periodoDia)
   {
      abertoOperLocal=abertoDiretoLocal;
      if(InpModoSimplesFIX195)
      {
         realOperLocal=localVenda ? g_parciaisCicloSell : g_parciaisCicloBuy;
         parcialLocal=localVenda ? g_realizadoAumentosCicloSell : g_realizadoAumentosCicloBuy;
         qtdParcialLocal=localVenda ? g_qtdRealizacoesAumentosCicloSell : g_qtdRealizacoesAumentosCicloBuy;
      }
      saldoOperLocal=abertoOperLocal;
      lucroLocal=(abertoOperLocal>0.0 ? abertoOperLocal : 0.0);
      prejuLocal=(abertoOperLocal<0.0 ? abertoOperLocal : 0.0);
   }
   else
   {
      abertoOperLocal=0.0;
      saldoOperLocal=realOperLocal;
   }

   double realOperAB=realizadoAB;
   if(periodoDia && InpModoSimplesFIX195)
      realOperAB=g_parciaisCicloBuy+g_parciaisCicloSell;
   double abertoOperC=periodoDia ? abertoC : 0.0;
   double abertoOperV=periodoDia ? abertoV : 0.0;
   double abertoOperAB=NormalizeDouble(abertoOperC+abertoOperV,2);
   double saldoOperAB=periodoDia ? abertoOperAB : realizadoAB;

   int tradesLucroAB=histSel.tradesLucroCompra+histSel.tradesLucroVenda;
   int tradesPrejuAB=histSel.tradesPrejuCompra+histSel.tradesPrejuVenda;
   int totalTradesAB=tradesLucroAB+tradesPrejuAB;
   // FIX362: "Saidas lucro/preju" mostra somente deals encerrados.
   double lucroAB=histSel.financeiroLucroCompra+histSel.financeiroLucroVenda;
   double prejuAB=histSel.financeiroPrejuCompra+histSel.financeiroPrejuVenda;

   double parcialAB=periodoDia && InpModoSimplesFIX195
                     ? g_realizadoAumentosCicloBuy+g_realizadoAumentosCicloSell
                     : (histSel.parcial>0.0 ? histSel.parcial : 0.0);
   int qtdParcialAB=periodoDia && InpModoSimplesFIX195
                    ? g_qtdRealizacoesAumentosCicloBuy+g_qtdRealizacoesAumentosCicloSell
                    : tradesLucroAB;

   double riscoPorContrato=MathAbs(InpPainelExposicaoPorContratoReais);
   if(riscoPorContrato<=0.0) riscoPorContrato=MathAbs(InpEntradaPerdaMaximaReais);
   if(riscoPorContrato<=0.0) riscoPorContrato=MathAbs(g_risco.stopOperacao);
   double expAtualLocal=riscoPorContrato*qtdLocal;
   double abertoPorContrato=(periodoDia && qtdLocal>0.0001 ? abertoDiretoLocal/qtdLocal : 0.0);
   double expPrejLocal=(abertoOperLocal<0.0 ? abertoOperLocal : 0.0);
   double expPrejAB=(abertoOperC<0.0 ? abertoOperC : 0.0)+(abertoOperV<0.0 ? abertoOperV : 0.0);

   int ok=0,total=0;
   string pLocal="COPA_AR100_CARD_FIN_A";
   string pTotal="COPA_AR100_CARD_FIN_T";

   // CARD LOCAL — cada valor visível é escrito e lido de volta.
   AtualizarObjetoValorFIX354(pLocal+"_M1_V",PnlMoedaBRL(saldoPeriodoLocal),CorFinanceiro(saldoPeriodoLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M2_OP_V",PnlMoedaBRL(realizadoPeriodoLocal),CorFinanceiro(realizadoPeriodoLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M2_DIA_V",PnlMoedaBRL(saldoOperLocal),CorFinanceiro(saldoOperLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M3_V",PnlMoedaBRL(abertoPeriodoLocal),CorFinanceiro(abertoPeriodoLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M4_V",TextoPosicaoCard(local),CorLadoTexto(LadoDaPosicaoAtual(local)),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M5_V",DoubleToString(qtdLocal,0)+" contr.",qtdLocal>0.0?PnlCorAmarelo():PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M6_V",qtdLocal>0.0?DoubleToString(local.precoMedio,_Digits):"--",PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M7_V",PnlMoedaBRL(abertoPorContrato),CorFinanceiro(abertoPorContrato),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M8_V",PnlMoedaBRL(lucroLocal),PnlCorVerde(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M9_V",PnlMoedaBRL(expPrejLocal),CorFinanceiro(expPrejLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M10_V",StringFormat("%d de %d",local.aumentosExecutados,g_gerAumentos.maxAumentos),local.aumentosExecutados>0?PnlCorVerde():PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M11_V",ProximoAumentoCard(local),PnlCorAmarelo(),ok,total);
   string modoAumTxt=InpAumentosLivreTeste ? "TESTE LIVRE" : "NORMAL";
   modoAumTxt+=InpAumentosContraPosicao ? " / CONTRA" : " / FAVOR";
   AtualizarObjetoValorFIX354(pLocal+"_M12_V",modoAumTxt,InpAumentosLivreTeste?PnlCorVerde():PnlCorAmarelo(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M13_V",PnlMoedaBRL(parcialLocal),CorFinanceiro(parcialLocal),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M14_V",InpStopDinamicoHeadFIX359 ? PnlMoedaBRL(StopMovelLadoHeadFIX359(localVenda?LADO_VENDA:LADO_COMPRA)) : PnlMoedaBRL(prejuLocal),PnlCorVermelho(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_M15_V",StringFormat("%s | %s",local.lucroProtegido?"ON":"OFF",PnlMoedaBRL(local.valorDefendido)),local.lucroProtegido?PnlCorVerde():PnlCorSecundario(),ok,total);
   if(ObjectFind(0,pLocal+"_M16_V")>=0)
      AtualizarObjetoValorFIX354(pLocal+"_M16_V",PnlMoedaBRL(expAtualLocal),PnlCorAmarelo(),ok,total);
   if(ObjectFind(0,pLocal+"_M17_V")>=0)
      AtualizarObjetoValorFIX354(pLocal+"_M17_V",StringFormat("%d | +%d | -%d",saidasLocal,saidasLucroLocal,saidasPrejuLocal),PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_GP_GAN_V",TextoMoedaPainelCurto(MathAbs(InpEntradaGanhoAlvoReais)),PnlCorVerde(),ok,total);
   AtualizarObjetoValorFIX354(pLocal+"_GP_PER_V",TextoMoedaPainelCurto(-(InpStopDinamicoHeadFIX359?StopGeralDinamicoHeadFIX359():MathAbs(InpEntradaPerdaMaximaReais))),PnlCorVermelho(),ok,total);

   // CARD MESTRE A+B.
   double qtdExibC=periodoDia ? qtdC : histSel.qtdCompra;
   double qtdExibV=periodoDia ? qtdV : histSel.qtdVenda;
   double qtdExibT=qtdExibC+qtdExibV;
   double qtdL=MathAbs(qtdExibC-qtdExibV);
   AtualizarObjetoValorFIX354(pTotal+"_M1_V",PnlMoedaBRL(saldoPeriodoAB),CorFinanceiro(saldoPeriodoAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M2_OP_V",PnlMoedaBRL(realizadoAB),CorFinanceiro(realizadoAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M2_DIA_V",PnlMoedaBRL(saldoOperAB),CorFinanceiro(saldoOperAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M3_V",PnlMoedaBRL(abertoPeriodoAB),CorFinanceiro(abertoPeriodoAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M4_V",StringFormat("%.0f|%.0f|%.0f",qtdExibC,qtdExibV,qtdL),qtdExibT>0.0?PnlCorAmarelo():PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M5_V",StringFormat("%.0f|%.0f|%.0f",qtdExibC,qtdExibV,qtdExibT),qtdExibT>0.0?PnlCorAmarelo():PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M6_V",PnlMoedaBRL(abertoOperC),CorFinanceiro(abertoOperC),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M7_V",PnlMoedaBRL(abertoOperV),CorFinanceiro(abertoOperV),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M8_V",StringFormat("C %s + V %s = %s",TextoMoedaPainelCurto(abertoOperC),TextoMoedaPainelCurto(abertoOperV),TextoMoedaPainelCurto(abertoOperAB)),PnlCorTitulo(),ok,total);
   if(ObjectFind(0,pTotal+"_M9_V")>=0)
      AtualizarObjetoValorFIX354(pTotal+"_M9_V",IntegerToString(totalTradesAB),PnlCorTexto(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M10_V",StringFormat("%d | %s",tradesLucroAB,PnlMoedaBRL(lucroAB)),PnlCorVerde(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M11_V",StringFormat("%d | %s",tradesPrejuAB,PnlMoedaBRL(prejuAB)),PnlCorVermelho(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M12_V",PnlMoedaBRL(parcialAB),CorFinanceiro(parcialAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M13_V",PnlMoedaBRL(expPrejAB),CorFinanceiro(expPrejAB),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_M14_V",TextoGainStopCestaPainel(),PnlCorAmarelo(),ok,total);
   if(ObjectFind(0,pTotal+"_M15_V")>=0)
      AtualizarObjetoValorFIX354(pTotal+"_M15_V",TextoGanhoQtdReaisFIX362(LADO_AMBOS,true),PnlCorVerde(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_GP_GAN_V",TextoMoedaPainelCurto(GainHeadEfetivoFIX362()),PnlCorVerde(),ok,total);
   AtualizarObjetoValorFIX354(pTotal+"_GP_PER_V",TextoMoedaPainelCurto(-LossHeadEfetivoFIX362()),PnlCorVermelho(),ok,total);

   string pAumFIX367="COPA_AR100_CARD_AUM";
   if(ObjectFind(0,pAumFIX367+"_GANHO_QTD_RS")>=0)
      AtualizarObjetoValorFIX354(pAumFIX367+"_GANHO_QTD_RS",
                                 StringFormat("GANHO QTD/R$ %s: %s | HEAD: %s",
                                              localVenda?"VENDA":"COMPRA",
                                              TextoGanhoQtdReaisFIX362(localVenda?LADO_VENDA:LADO_COMPRA,false),
                                              TextoGanhoQtdReaisFIX362(LADO_AMBOS,true)),
                                 PnlCorVerde(),ok,total);
   if(ObjectFind(0,pAumFIX367+"_LOSS_HEAD")>=0)
      AtualizarObjetoValorFIX354(pAumFIX367+"_LOSS_HEAD",TextoLossHeadGerenciadorFIX367(),PnlCorVermelho(),ok,total);

   // FIX368 HISTORICO — uma unica linha, sempre ligada ao periodo selecionado pelos botoes.
   string pHist="COPA_AR100_CARD_HIST_";
   HistoricoPeriodo hLinha=histSel;
   AplicarFallbackEntradasAbertasHistoricoFIX316(hLinha);
   AtualizarObjetoValorFIX354(pHist+"PER_V",PeriodoHistoricoCardFIX368(),PnlCorTexto(),ok,total);
   AtualizarGrupoHistoricoObjetosFIX368(pHist,"A",hLinha,LADO_COMPRA,clrAqua,ok,total);
   AtualizarGrupoHistoricoObjetosFIX368(pHist,"B",hLinha,LADO_VENDA,clrOrange,ok,total);
   AtualizarGrupoHistoricoObjetosFIX368(pHist,"AB",hLinha,LADO_AMBOS,clrLime,ok,total);

   g_totalHeadSaldoABExibido=saldoPeriodoAB;
   g_totalHeadSaldoABExibidoValido=true;
   g_totalHeadSaldoABExibidoHora=TimeCurrent();
   g_totalHeadResultadoABExibido=abertoPeriodoAB;
   g_totalHeadResultadoABExibidoValido=true;
   g_totalHeadResultadoABExibidoHora=TimeCurrent();

   // Auditoria de fórmulas: além de escrever o objeto, confere as contas.
   int formulaOk=0,formulaTotal=0;
   formulaTotal++; if(MathAbs(abertoT-(abertoC+abertoV))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(realizadoAB-(realizadoC+realizadoV))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(saldoPeriodoC-(periodoDia ? abertoPeriodoC : realizadoC+abertoPeriodoC))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(saldoPeriodoV-(periodoDia ? abertoPeriodoV : realizadoV+abertoPeriodoV))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(saldoPeriodoAB-(saldoPeriodoC+saldoPeriodoV))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(abertoPeriodoAB-(abertoPeriodoC+abertoPeriodoV))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(saldoOperLocal-(periodoDia ? abertoOperLocal : realOperLocal))<0.011) formulaOk++;
   formulaTotal++; if(MathAbs(saldoOperAB-(periodoDia ? abertoOperAB : realizadoAB))<0.011) formulaOk++;

   // Auditoria de movimento: quando BID/ASK muda com posição aberta, o aberto do
   // lado correspondente também precisa mudar. Isto detecta exatamente o saldo congelado.
   static bool amostraAnteriorValida=false;
   static double bidAnterior=0.0,askAnterior=0.0,abertoCAnterior=0.0,abertoVAnterior=0.0;
   static int movJanelaOk=0,movJanelaTotal=0;
   string movDetalhe="AGUARDA PRECO";
   if(amostraAnteriorValida)
   {
      bool esperouC=(qtdC>0.0001 && MathAbs(tick.bid-bidAnterior)>=(_Point*0.5));
      bool esperouV=(qtdV>0.0001 && MathAbs(tick.ask-askAnterior)>=(_Point*0.5));
      bool mudouC=(MathAbs(abertoC-abertoCAnterior)>=0.009);
      bool mudouV=(MathAbs(abertoV-abertoVAnterior)>=0.009);
      if(esperouC) { movJanelaTotal++; if(mudouC) movJanelaOk++; }
      if(esperouV) { movJanelaTotal++; if(mudouV) movJanelaOk++; }
   }
   if(movJanelaTotal>0)
      movDetalhe=StringFormat("%d/%d %s",movJanelaOk,movJanelaTotal,(movJanelaOk==movJanelaTotal)?"OK":"FALHA");
   else if(qtdC<=0.0001 && qtdV<=0.0001)
      movDetalhe="SEM POS";

   bidAnterior=tick.bid;
   askAnterior=tick.ask;
   abertoCAnterior=abertoC;
   abertoVAnterior=abertoV;
   amostraAnteriorValida=true;

   datetime auditoriaAntes=g_ultimaAuditoriaCamposFIX354;
   RegistrarAuditoriaCamposPainelFIX354(ok,total,formulaOk,formulaTotal,movDetalhe,
                                        tick.bid,tick.ask,abertoC,abertoV,realizadoC,realizadoV,
                                        saldoPeriodoC,saldoPeriodoV);
   if(g_ultimaAuditoriaCamposFIX354!=auditoriaAntes)
   {
      movJanelaOk=0;
      movJanelaTotal=0;
   }

   // Até 8 atualizações visuais por segundo. O desenho completo continua em 1 s,
   // evitando travamento, mas valores financeiros não ficam esperando o painel inteiro.
   static ulong ultimoRedrawRapido=0;
   if(forcarRedraw || ultimoRedrawRapido==0 || agoraMs<ultimoRedrawRapido || (agoraMs-ultimoRedrawRapido)>=125)
   {
      ultimoRedrawRapido=agoraMs;
      ChartRedraw(0);
   }
}


// ============================================================================
// RESPONSABILIDADE: ESTADO LOCAL E RODAPE DO PAINEL
// ============================================================================

void ReencaixarPainelInicialSeNecessario()
{
   if(!InpPainelReencaixeAutomaticoInicial)
      return;
   if(g_painelReencaixeInicialRestante <= 0)
   {
      // FIX384: nunca desligar o timer aqui; ele pertence ao motor operacional.
      g_timerCriadoSomenteParaPainelInicial = false;
      return;
   }
   g_painelReencaixeInicialRestante--;
   g_ultimaAtualizacaoPainelVisual = 0;
   g_ultimaAtualizacaoRodapeVisual = 0;
   AtualizarEstadosDePosicao();
   SincronizarResultadoFechadoDiaComHistorico();
   AtualizarRiscoMestre();
   AtualizarPainelMestre();
   PainelChartRedrawLeve(true);
   if(g_painelReencaixeInicialRestante <= 0)
   {
      // FIX384: reencaixe terminou, mas o timer de 1 segundo permanece ativo.
      g_timerCriadoSomenteParaPainelInicial = false;
   }
}

void AtualizarRodapePainelRapido()
{
   if(!InpPainelRodapeAtualizacaoRapida)
      return;
   if(g_modoPainelVisualAtivo != PAINEL_VISUAL_COMPLETO)
      return;
   if(!InpMostrarCardAumentosVisual)
      return;
   datetime agora = TimeCurrent();
   int intervalo = InpPainelRodapeAtualizarSegundos;
   if(intervalo < 1)
      intervalo = 1;
   if(InpFIX287UltraLeve)
   {
      int minimoRodapeFIX287=InpFIX287PainelIntervaloSegundos;
      if(minimoRodapeFIX287<1) minimoRodapeFIX287=1;
      if(intervalo<minimoRodapeFIX287) intervalo=minimoRodapeFIX287;
   }
   if(g_ultimaAtualizacaoRodapeVisual > 0 && (agora - g_ultimaAtualizacaoRodapeVisual) < intervalo)
      return;
   g_ultimaAtualizacaoRodapeVisual = agora;
   EstadoLado estadoCard;
   ObterEstadoMotorPainelLocal(estadoCard);
   int px = InpPainelCardX;
   int py = InpPainelCardY;
   int pw = InpPainelCardLargura;
   int ph = InpPainelCardAltura;
   PainelPrepararCompletoAutoFitFIX319(px, py, pw, ph);
   int fonteTexto = InpPainelFonteTexto;
   if(fonteTexto < 7) fonteTexto = 7;
   if(fonteTexto > 8) fonteTexto = 8;
   if(pw < 1280 || ph < 900)
      fonteTexto = 7;
   int gap = (ph < 900 ? 8 : 10);
   int finY = py + (ph < 900 ? 84 : 92);
   int finH = (ph < 820 ? 300 : (ph < 900 ? 324 : 348));
   int aumH = (ph < 820 ? 202 : (ph < 1000 ? 210 : 218));
   int indH = (ph < 820 ? 64 : (ph < 1000 ? 74 : 96));
   int minHistH = (ph < 820 ? 76 : 82);
   int histYPrev = finY + finH + gap + aumH + gap + indH + gap;
   int histHPrev = (py + ph - 8) - histYPrev;
   if(histHPrev < minHistH)
   {
      int falta = minHistH - histHPrev;
      int red = 0;
      red = (int)MathMin((double)falta, (double)MathMax(0, finH - (ph < 820 ? 280 : 300)));
      finH -= red; falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, aumH - 202));
      aumH -= red; falta -= red;
      red = (int)MathMin((double)falta, (double)MathMax(0, indH - 56));
      indH -= red; falta -= red;
      if(falta > 0 && gap > 6)
      {
         int reduzirGap = (int)MathMin((double)(gap - 6), (double)((falta + 3) / 3));
         gap -= reduzirGap;
      }
   }
   int aumY = finY + finH + gap;
   int indY = aumY + aumH + gap;
   int faixaW = pw - 24;
   int indW = (int)MathRound((double)(faixaW - gap) * 0.54);
   if(indW < 560) indW = 560;
   if(indW > faixaW - gap - 440) indW = faixaW - gap - 440;
   int msgW = faixaW - gap - indW;
   int msgX = px + 12 + indW + gap;
   int histY = indY + indH + gap;
   int histH = (py + ph - 8) - histY;
   if(histH < 76)
      histH = 76;
   string pfx = "COPA_AR100_CARD_";
   DesenharIndicadoresEntrada(pfx + "IND", estadoCard, px + 12, indY, indW, indH, fonteTexto);
   DesenharMsgBoxVisual3s(pfx + "EVT", estadoCard, msgX, indY, msgW, indH, fonteTexto);
   DesenharCardHistorico(px + 12, histY, pw - 24, histH);
   PainelChartRedrawLeve(false);
}

color CorMagicPiscando(color corBase)
{
   if(!InpMagicPiscandoPainel)
      return corBase;
   if((TimeCurrent() % 2) == 0)
      return PnlCorAmarelo();
   return corBase;
}


ENUM_LADO_ROBO LadoCardLocalPainelAtual()
{
   // FIX288: o painel nunca troca de lado conforme a ultima posicao.
   // Grafico A mostra sempre COMPRA; grafico B mostra sempre VENDA.
   return LadoOperacionalInstanciaFIX255();
}

void ObterEstadoMotorPainelLocal(EstadoLado &destino)
{
   ENUM_LADO_ROBO ladoLocal = LadoCardLocalPainelAtual();
   if(ladoLocal == LADO_VENDA)
      destino = g_venda;
   else
      destino = g_compra;
}

void ObterEstadoResumoPainelLocal(EstadoLado &destino)
{
   ENUM_LADO_ROBO ladoLocal = LadoCardLocalPainelAtual();
   if(ladoLocal == LADO_VENDA)
      destino = g_painelB;
   else
      destino = g_painelA;
}

string TituloResumoLocalPainel(EstadoLado &e)
{
   if(e.lado == LADO_VENDA)
      return "Resumo financeiro B";
   return "Resumo financeiro A";
}

bool CardFinanceiroEhFoco(EstadoLado &e)
{
   if(!InpFocoUnicoLadoAtual)
      return e.posicaoAberta;
   if(!e.posicaoAberta)
      return false;
   return (e.lado == LadoOperacionalInstanciaFIX255());
}

string TextoFocoUnico(EstadoLado &e)
{
   string ladoTxt = (e.lado == LADO_COMPRA ? "A" : "B");
   string posCurta = "SEM POS";
   if(e.posicaoAberta)
   {
      if(e.tipoPosicaoAtual == (long)POSITION_TYPE_BUY)
         posCurta = "COMP";
      else if(e.tipoPosicaoAtual == (long)POSITION_TYPE_SELL)
         posCurta = "VEND";
      else if(e.tipoPosicaoAtual == -2)
         posCurta = "MISTO";
   }
   if(InpFocoCompactoPainel)
      return StringFormat("FOCO %s | M%s | %s | F:%s E:%s",
                          ladoTxt,
                          IntegerToString(e.magic),
                          posCurta,
                          NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                          NomeTimeframeCurto(TimeframeEntradaAtualFIX255()));
   return StringFormat("FOCO %s | MAGIC %s | %s | F:%s E:%s",
                       ladoTxt,
                       IntegerToString(e.magic),
                       TextoPosicaoCard(e),
                       NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                       NomeTimeframeCurto(TimeframeEntradaAtualFIX255()));
}

string TextoMagicTopoPiscando()
{
   ENUM_LADO_ROBO ladoLocal=LadoOperacionalInstanciaFIX255();
   EstadoLado e=(ladoLocal==LADO_COMPRA ? g_painelA : g_painelB);
   if(e.posicaoAberta)
      return TextoFocoUnico(e);
   return StringFormat("%s | MAGIC %d | SEM POSICAO | F:%s E:%s",
                       ladoLocal==LADO_COMPRA ? "A SOMENTE COMPRA" : "B SOMENTE VENDA",
                       (int)e.magic,
                       NomeTimeframeCurto(TimeframeFiltroAtualFIX255()),
                       NomeTimeframeCurto(TimeframeEntradaAtualFIX255()));
}

double ContratosPlanejadosTotal()
{
   double total = MathAbs(InpEntradaContratos);
   for(int i = 0; i < ArraySize(g_aumentos); i++)
   {
      if(g_aumentos[i].ativa)
         total += MathAbs(g_aumentos[i].qtd);
   }
   double limite = (double)g_gerAumentos.maxContratos;
   if(limite > 0.0 && total > limite)
      total = limite;
   return total;
}



// ============================================================================
// RESPONSABILIDADE: INDICADORES E ELEMENTOS DO GRAFICO
// ============================================================================

void ConfigurarObjetoAtrasPainel(string nome)
{
   if(ObjectFind(0, nome) < 0)
      return;
   ObjectSetInteger(0, nome, OBJPROP_BACK, true);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 0);
}

bool FiltroVisualSelecionadoFIX343(string filtro)
{
   string perfil=Upper(Trim(InpFiltrosProjetoFIX324));
   string alvo=Upper(Trim(filtro));
   if(perfil=="" || alvo=="")
      return false;
   if(alvo=="AGR")
      return (StringFind(perfil,"AGR")>=0 || StringFind(perfil,"AGF")>=0);
   return (StringFind(perfil,alvo)>=0);
}

bool LocalizarIndicadorPorPrefixoFIX345(string prefixo,int &janela,string &nome)
{
   janela=-1;
   nome="";
   int totalJanelas=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   for(int w=0;w<totalJanelas;w++)
   {
      int total=ChartIndicatorsTotal(0,w);
      for(int i=0;i<total;i++)
      {
         string atual=ChartIndicatorName(0,w,i);
         if(StringFind(atual,prefixo)==0)
         {
            janela=w;
            nome=atual;
            return true;
         }
      }
   }
   return false;
}

void RemoverDXVisualEditavelFIX345()
{
   int janela=-1;
   string nome="";
   if(LocalizarIndicadorPorPrefixoFIX345("COPA DX VISUAL",janela,nome))
      ChartIndicatorDelete(0,janela,nome);
   if(g_handleDXVisualFIX345!=INVALID_HANDLE)
      IndicatorRelease(g_handleDXVisualFIX345);
   g_handleDXVisualFIX345=INVALID_HANDLE;
   g_dxVisualAdicionadoFIX345=false;
   g_nomeDXVisualFIX345="";
}

bool GarantirDXVisualEditavelFIX345()
{
   bool dxSelecionado=FiltroVisualSelecionadoFIX343("DX");
   bool visualSolicitado=(dxSelecionado && (InpPlotarMedia25NoGrafico || InpFIX280PlotarBandaDXPreco));
   if(!visualSolicitado)
   {
      RemoverDXVisualEditavelFIX345();
      g_dxVisualFechadoUsuarioFIX345=false;
      return true;
   }
   if(g_dxVisualFechadoUsuarioFIX345)
      return true;

   int janelaExistente=-1;
   string nomeExistente="";
   if(LocalizarIndicadorPorPrefixoFIX345("COPA DX VISUAL",janelaExistente,nomeExistente))
   {
      g_dxVisualAdicionadoFIX345=true;
      g_nomeDXVisualFIX345=nomeExistente;
      return true;
   }

   // FIX346: o recurso externo COPA_AR100_DX_VISUAL.ex5 nao acompanha este arquivo.
   // Retorna false de forma controlada para ativar o fallback interno existente em
   // GarantirDXIndicadorNoGrafico() -> GarantirMedia25NoGrafico().
   // Assim, media e bandas DX continuam sendo desenhadas por objetos no grafico.
   g_handleDXVisualFIX345=INVALID_HANDLE;
   g_dxVisualAdicionadoFIX345=false;
   g_nomeDXVisualFIX345="";
   return false;
}

void DetectarFechamentoVisualUsuarioFIX345()
{
   if(g_dxVisualAdicionadoFIX345)
   {
      int janela=-1;
      string nome="";
      if(LocalizarIndicadorPorPrefixoFIX345("COPA DX VISUAL",janela,nome))
         g_nomeDXVisualFIX345=nome; // Nome pode mudar quando o usuario edita os parametros.
      else
      {
         g_dxVisualAdicionadoFIX345=false;
         g_dxVisualFechadoUsuarioFIX345=true;
         g_nomeDXVisualFIX345="";
         if(g_handleDXVisualFIX345!=INVALID_HANDLE)
            IndicatorRelease(g_handleDXVisualFIX345);
         g_handleDXVisualFIX345=INVALID_HANDLE;
         LimparBandasMedia25Grafico();
         g_objetosDXLegadoRemovidosFIX345=true;
         RegistrarLogValidacaoSistema("FIX345_DX_VISUAL_FECHADO",
            "Usuario fechou o DX visual; o robo respeitou e nao recriou o indicador.");
      }
   }

   if(g_oscVisualAdicionadoFIX343)
   {
      int janela=-1;
      string nome="";
      if(LocalizarIndicadorPorPrefixoFIX345("COPA OSC |",janela,nome))
      {
         g_janelaOscVisualFIX343=janela;
         g_nomeOscVisualFIX343=nome;
      }
      else
      {
         g_oscVisualAdicionadoFIX343=false;
         g_janelaOscVisualFIX343=-1;
         g_nomeOscVisualFIX343="";
         if(g_handleOscVisualFIX343!=INVALID_HANDLE)
            IndicatorRelease(g_handleOscVisualFIX343);
         g_handleOscVisualFIX343=INVALID_HANDLE;
         RegistrarLogValidacaoSistema("FIX345_OSC_VISUAL_FECHADO",
            "Usuario fechou RSI/agressao visual; o robo respeitou a decisao.");
      }
   }
}

void RemoverOsciladoresSelecionadosFIX343()
{
   // FIX362: remove inclusive sobras deixadas por versoes anteriores.
   int totalJanelas=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   for(int w=totalJanelas-1;w>=0;w--)
   {
      for(int i=ChartIndicatorsTotal(0,w)-1;i>=0;i--)
      {
         string nome=ChartIndicatorName(0,w,i);
         if(StringFind(nome,"COPA OSC |") == 0 ||
            StringFind(Upper(nome),"COPA_AR100_OSC_VISUAL")>=0)
            ChartIndicatorDelete(0,w,nome);
      }
   }
   if(g_handleOscVisualFIX343!=INVALID_HANDLE)
      IndicatorRelease(g_handleOscVisualFIX343);
   g_handleOscVisualFIX343=INVALID_HANDLE;
   g_janelaOscVisualFIX343=-1;
   g_oscVisualAdicionadoFIX343=false;
   g_nomeOscVisualFIX343="";
}

bool GarantirOsciladoresSelecionadosFIX343()
{
   // FIX362: nenhum indicador visual e recriado. RSI e agressao continuam
   // calculados internamente para filtros, score e diagnostico.
   RemoverOsciladoresSelecionadosFIX343();
   return true;
}

int PeriodoMediaGraficoEfetivo()
{
   // FIX390: periodo totalmente livre pelo parametro da aba Entradas.
   // Nao segue DX e nao e mais travado em 25.
   int periodo=InpMedia25PeriodoGrafico;
   if(periodo<1) periodo=1;
   if(periodo>1000) periodo=1000;
   return periodo;
}

void LimparPlotagemDX()
{
   string nomes[] = {
      "COPA_AR100_DX_MEDIA",
      "COPA_AR100_DX_BANDA_SUP",
      "COPA_AR100_DX_BANDA_INF",
      "COPA_AR100_DX_ATUAL",
      "COPA_AR100_MEDIA25_STATUS"
   };
   for(int i = 0; i < ArraySize(nomes); i++)
      ObjectDelete(0, nomes[i]);
   LimparBandasMedia25Grafico();
}

void LimparBandasMedia25Grafico()
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nome = ObjectName(0, i, -1, -1);
      if(StringFind(nome, "COPA_AR100_M25_SUP_") == 0 ||
         StringFind(nome, "COPA_AR100_M25_INF_") == 0 ||
         StringFind(nome, "COPA_AR100_M25_TX_") == 0 ||
         StringFind(nome, "COPA_AR100_MEDIAGRAF_") == 0 ||
         StringFind(nome, "DXMEDIA_LIN_") == 0 ||
         StringFind(nome, "COPA_AR100_MEDIAGRAF_TX") == 0 ||
         StringFind(nome, "DX25_ACIMA_") == 0 ||
         StringFind(nome, "DX25_ABAIXO_") == 0 ||
         StringFind(nome, "DX25_TX_") == 0)
         ObjectDelete(0, nome);
   }
}

void RemoverADXVisualLegado()
{
   if(g_adxVisualLegadoRemovido)
      return;
   long totalJanelas = ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   for(int janela = (int)totalJanelas - 1; janela >= 0; janela--)
   {
      ChartIndicatorDelete(0, janela, "ADX(" + IntegerToString(InpDXPeriodo) + ")");
      ChartIndicatorDelete(0, janela, "Average Directional Movement Index(" + IntegerToString(InpDXPeriodo) + ")");
      ChartIndicatorDelete(0, janela, "ADX(25)");
      ChartIndicatorDelete(0, janela, "Average Directional Movement Index(25)");
   }
   g_adxVisualLegadoRemovido = true;
}

void RemoverMediaGraficaNativaLegado()
{
   if(g_mediaGraficaNativaLegadoRemovida)
      return;
   string periodos[6];
   periodos[0] = IntegerToString(PeriodoMediaGraficoEfetivo());
   periodos[1] = IntegerToString(InpMedia25PeriodoGrafico);
   periodos[2] = IntegerToString(InpDXMediaPeriodo);
   periodos[3] = IntegerToString(InpDXPeriodo);
   periodos[4] = "25";
   periodos[5] = "2";
   for(int p = 0; p < ArraySize(periodos); p++)
   {
      string per = periodos[p];
      ChartIndicatorDelete(0, 0, "Moving Average(" + per + ")");
      ChartIndicatorDelete(0, 0, "MA(" + per + ")");
      ChartIndicatorDelete(0, 0, "Media Movel(" + per + ")");
      ChartIndicatorDelete(0, 0, "Média Móvel(" + per + ")");
   }
   g_mediaGraficaNativaLegadoRemovida = true;
}

bool CriarSegmentoMedia25(string nome, datetime t1, double p1, datetime t2, double p2, color cor, ENUM_LINE_STYLE estilo, int largura)
{
   if(t1 <= 0 || t2 <= 0 || p1 <= 0.0 || p2 <= 0.0)
      return false;
   if(ObjectFind(0, nome) < 0)
   {
      if(!ObjectCreate(0, nome, OBJ_TREND, 0, t1, p1, t2, p2))
         return false;
   }
   else
   {
      ObjectMove(0, nome, 0, t1, p1);
      ObjectMove(0, nome, 1, t2, p2);
   }
   ObjectSetInteger(0, nome, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nome, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_STYLE, estilo);
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, largura);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 5);
   return true;
}

void PlotarLabelPrecoClean(string nome, double preco, string texto, color cor, int yAjuste)
{
   if(preco <= 0.0)
   {
      ObjectDelete(0, nome);
      return;
   }
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   int px = 0;
   int py = 0;
   if(!ChartTimePriceToXY(0, 0, t, preco, px, py))
      return;
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int reservaEscalaPreco = 180;
   int labelW = 92;
   int labelH = 14;
   if(chartH > 0 && (py < 24 || py > chartH - 24))
   {
      ObjectDelete(0, nome);
      return;
   }
   int labelX = chartW - reservaEscalaPreco - labelW - 8;
   if(labelX < 20)
      labelX = 20;
   int labelY = py - 7 + yAjuste;
   if(labelY < 18)
      labelY = 18;
   if(chartH > 0 && labelY > chartH - labelH - 18)
      labelY = chartH - labelH - 18;
   if(ObjectFind(0, nome) < 0)
      ObjectCreate(0, nome, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, labelX);
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, labelY);
   ObjectSetInteger(0, nome, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetString(0, nome, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, nome, OBJPROP_BACK, true);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 0);
}

void LimparRangeGridGraficoFIX344()
{
   int total=ObjectsTotal(0,-1,-1);
   for(int i=total-1;i>=0;i--)
   {
      string nome=ObjectName(0,i,-1,-1);
      if(StringFind(nome,"COPA_AR100_RG_")==0)
         ObjectDelete(0,nome);
   }
   g_assinaturaPlotagemRangeGridFIX344="";
}

void CriarLinhaRangeGridFIX344(string nome,double preco,color cor,ENUM_LINE_STYLE estilo,int largura)
{
   if(preco<=0.0) return;
   if(ObjectFind(0,nome)<0)
      ObjectCreate(0,nome,OBJ_HLINE,0,0,preco);
   ObjectSetDouble(0,nome,OBJPROP_PRICE,preco);
   ObjectSetInteger(0,nome,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE,estilo);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH,largura);
   ObjectSetInteger(0,nome,OBJPROP_BACK,true);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER,20);
}

void AtualizarRangeGridGraficoFIX344(bool forcar)
{
   if(!InpFiltroRangeAtivoFIX344 && !InpGridEntradasAtivoFIX344)
   {
      if(g_assinaturaPlotagemRangeGridFIX344!="")
         LimparRangeGridGraficoFIX344();
      g_statusRangeGridFIX344="RANGE OFF | GRID OFF";
      return;
   }
   datetime agora=TimeCurrent();
   if(!forcar && g_ultimaPlotagemRangeGridFIX344>0 &&
      (agora-g_ultimaPlotagemRangeGridFIX344)<5)
      return;
   g_ultimaPlotagemRangeGridFIX344=agora;

   string origemRange="",origemGrid="";
   double referenciaRange=(InpFiltroRangeAtivoFIX344
                           ? PrecoReferenciaFIX344(InpRangeReferenciaFIX344,origemRange) : 0.0);
   double referenciaGrid=(InpGridEntradasAtivoFIX344
                          ? PrecoReferenciaFIX344(InpGridReferenciaFIX344,origemGrid) : 0.0);
   string assinatura=StringFormat("R%d/%d/%.1f/%.1f/%.1f|G%d/%d/%.1f/%.1f/%.1f",
                                  InpFiltroRangeAtivoFIX344 ? 1 : 0,(int)InpRangeReferenciaFIX344,
                                  referenciaRange,InpRangeMinimoPontosFIX344,InpRangeMaximoPontosFIX344,
                                  InpGridEntradasAtivoFIX344 ? 1 : 0,(int)InpGridReferenciaFIX344,
                                  referenciaGrid,InpGridTamanhoPontosFIX344,InpGridToleranciaPontosFIX344);
   if(!forcar && assinatura==g_assinaturaPlotagemRangeGridFIX344)
      return;
   LimparRangeGridGraficoFIX344();
   g_assinaturaPlotagemRangeGridFIX344=assinatura;

   if(InpFiltroRangeAtivoFIX344 && referenciaRange>0.0)
   {
      double minimo=MathAbs(InpRangeMinimoPontosFIX344)*_Point;
      double maximo=MathAbs(InpRangeMaximoPontosFIX344)*_Point;
      CriarLinhaRangeGridFIX344("COPA_AR100_RG_RANGE_REF",referenciaRange,clrSilver,STYLE_DASH,1);
      if(minimo>0.0)
      {
         CriarLinhaRangeGridFIX344("COPA_AR100_RG_RANGE_MIN_SUP",referenciaRange+minimo,clrGold,STYLE_DASH,1);
         CriarLinhaRangeGridFIX344("COPA_AR100_RG_RANGE_MIN_INF",referenciaRange-minimo,clrGold,STYLE_DASH,1);
      }
      if(maximo>0.0)
      {
         CriarLinhaRangeGridFIX344("COPA_AR100_RG_RANGE_MAX_SUP",referenciaRange+maximo,clrTomato,STYLE_SOLID,2);
         CriarLinhaRangeGridFIX344("COPA_AR100_RG_RANGE_MAX_INF",referenciaRange-maximo,clrTomato,STYLE_SOLID,2);
      }
      PlotarLabelPrecoClean("COPA_AR100_RG_TX_RANGE",referenciaRange,
         StringFormat("RANGE %s %.0f",origemRange,referenciaRange),clrSilver,0);
      if(minimo>0.0)
      {
         PlotarLabelPrecoClean("COPA_AR100_RG_TX_MIN_SUP",referenciaRange+minimo,"RANGE MIN +",clrGold,-6);
         PlotarLabelPrecoClean("COPA_AR100_RG_TX_MIN_INF",referenciaRange-minimo,"RANGE MIN -",clrGold,6);
      }
      if(maximo>0.0)
      {
         PlotarLabelPrecoClean("COPA_AR100_RG_TX_MAX_SUP",referenciaRange+maximo,"RANGE MAX +",clrTomato,-6);
         PlotarLabelPrecoClean("COPA_AR100_RG_TX_MAX_INF",referenciaRange-maximo,"RANGE MAX -",clrTomato,6);
      }
   }

   if(InpGridEntradasAtivoFIX344 && referenciaGrid>0.0 && InpGridTamanhoPontosFIX344>0.0)
   {
      double passo=InpGridTamanhoPontosFIX344*_Point;
      for(int nivel=-8;nivel<=8;nivel++)
      {
         double precoLinha=referenciaGrid+(nivel*passo);
         if(precoLinha<=0.0) continue;
         string nome="COPA_AR100_RG_GRID_"+IntegerToString(nivel+8);
         color cor=(nivel==0 ? clrDeepSkyBlue : C'55,105,155');
         CriarLinhaRangeGridFIX344(nome,precoLinha,cor,nivel==0 ? STYLE_SOLID : STYLE_DOT,nivel==0 ? 2 : 1);
      }
      PlotarLabelPrecoClean("COPA_AR100_RG_TX_GRID",referenciaGrid,
         StringFormat("GRID %s | %.0f pts",origemGrid,InpGridTamanhoPontosFIX344),clrDeepSkyBlue,12);
   }
   g_statusRangeGridFIX344=StringFormat("R:%s %.0f-%.0f | G:%s %.0f/T%.0f",
      InpFiltroRangeAtivoFIX344 ? "ON" : "OFF",InpRangeMinimoPontosFIX344,InpRangeMaximoPontosFIX344,
      InpGridEntradasAtivoFIX344 ? "ON" : "OFF",InpGridTamanhoPontosFIX344,InpGridToleranciaPontosFIX344);
   ChartRedraw(0);
}

void AtualizarBandasMedia25Grafico(bool forcar)
{
   // FIX392: a media visual agora e um indicador NATIVO do MT5.
   // Nao desenha centenas de OBJ_TREND e, por isso, pode ser selecionada
   // e alterada pela janela de propriedades do proprio grafico.
   LimparBandasMedia25Grafico();
   GarantirMedia25NoGrafico();
}

void GarantirMedia25NoGrafico()
{
   if(!InpPlotarMedia25NoGrafico)
   {
      if(g_media25AdicionadaNoGrafico)
      {
         string nome=ChartIndicatorName(0,0,ChartIndicatorsTotal(0,0)-1);
         if(StringFind(nome,"Moving Average")>=0 || StringFind(nome,"Media Movel")>=0 || StringFind(nome,"Média Móvel")>=0)
            ChartIndicatorDelete(0,0,nome);
      }
      g_media25AdicionadaNoGrafico=false;
      return;
   }
   if(g_handleMedia25Grafico==INVALID_HANDLE)
      return;

   RemoverADXVisualLegado();

   if(!g_media25AdicionadaNoGrafico && !g_media25TentativaBloqueadaFIX398)
   {
      ResetLastError();
      if(ChartIndicatorAdd(0,0,g_handleMedia25Grafico))
      {
         g_media25AdicionadaNoGrafico=true;
         g_media25UltimoErroFIX398=0;
         ChartRedraw(0);
         Print("[COPA_AR100][FIX398][MEDIA_NATIVA_OK] EDITAVEL=SIM | PERIODO=",
               IntegerToString(PeriodoMediaGraficoEfetivo()),
               " | METODO=",IntegerToString((int)InpMedia25MetodoGrafico),
               " | PRECO=",IntegerToString((int)InpMedia25PrecoGrafico));
      }
      else
      {
         g_media25UltimoErroFIX398=GetLastError();
         // Erro 4114 era repetido a cada Timer. Bloqueia novas tentativas nesta instancia.
         // A operacao, A0, aumentos e protecoes financeiras continuam normalmente.
         g_media25TentativaBloqueadaFIX398=true;
         Print("[COPA_AR100][FIX398][MEDIA_NATIVA_BLOQUEADA] ChartIndicatorAdd falhou uma vez | erro=",
               IntegerToString(g_media25UltimoErroFIX398),
               " | RETENTATIVA_TIMER=OFF | OPERACAO_FINANCEIRA=INALTERADA");
      }
   }
}

void GarantirDXIndicadorNoGrafico()
{
   GarantirDXVisualEditavelFIX345();
   // FIX392: a media nao depende mais do DX nem de fallback.
   // Quando o parametro estiver ligado, ela sempre sera desenhada.
   GarantirMedia25NoGrafico();
}

void AtualizarPlotagemDX()
{
   if(InpFIX353GraficoLimpoSemIndicadores)
   {
      // FIX387: "grafico limpo" remove os osciladores, mas preserva a MEDIA 25
      // e as pequenas setas historicas solicitadas pelo usuario.
      RemoverDXVisualEditavelFIX345();
      AtualizarBandasMedia25Grafico(false);
      AtualizarEntradasHistoricasGraficoFIX385(false);
      AtualizarRangeGridGraficoFIX344(false);
      return;
   }
   GarantirDXIndicadorNoGrafico();
   AtualizarBandasMedia25Grafico(false);
   AtualizarRangeGridGraficoFIX344(false);
}


// ============================================================================
// RESPONSABILIDADE: MODOS E BOTOES VISUAIS
// ============================================================================

string NomeModoPainelVisual(ENUM_MODO_PAINEL_VISUAL modo)
{
   if(modo == PAINEL_VISUAL_COMPLETO)
      return "COMPLETO";
   if(modo == PAINEL_VISUAL_SLIM)
      return "SLIM";
   if(modo == PAINEL_VISUAL_REDUZIDO)
      return "REDUZIDO";
   if(modo == PAINEL_VISUAL_OFF)
      return "OFF";
   return "?";
}

string TextoDXConfigPainel()
{
   return StringFormat("DX%d %.1f | MEDIA%d %.1f | GRAF M%d | DIST %.1f | BANDA %.1f/%.1f %s",
                       InpDXPeriodo,
                       g_mercado.dx,
                       InpDXMediaPeriodo,
                       g_mercado.dxMedia,
                       PeriodoMediaGraficoEfetivo(),
                       MathAbs(InpFIX280DistanciaBandaDXPontos),
                       g_mercado.dxBandaBaixa,
                       g_mercado.dxBandaAlta,
                       TextoDXStatus());
}

bool PainelCliqueModoVisual(string objeto)
{
   if(StringFind(objeto, "MODO_FULL") >= 0)
   {
      g_modoPainelVisualAtivo = PAINEL_VISUAL_COMPLETO;
      g_mestre.mensagemGeral = "Painel visual: COMPLETO.";
      ObjectSetInteger(0, objeto, OBJPROP_STATE, false);
      LimparSomentePainelVisual();
      return true;
   }
   if(StringFind(objeto, "MODO_SLIM") >= 0)
   {
      g_modoPainelVisualAtivo = PAINEL_VISUAL_SLIM;
      g_mestre.mensagemGeral = "Painel visual: SLIM para enxergar melhor o grafico.";
      ObjectSetInteger(0, objeto, OBJPROP_STATE, false);
      LimparSomentePainelVisual();
      return true;
   }
   if(StringFind(objeto, "MODO_RED") >= 0)
   {
      g_modoPainelVisualAtivo = PAINEL_VISUAL_REDUZIDO;
      g_mestre.mensagemGeral = "Painel visual: REDUZIDO.";
      ObjectSetInteger(0, objeto, OBJPROP_STATE, false);
      LimparSomentePainelVisual();
      return true;
   }
   if(StringFind(objeto, "MODO_OFF") >= 0)
   {
      g_modoPainelVisualAtivo = PAINEL_VISUAL_OFF;
      g_mestre.mensagemGeral = "Painel visual: OFF. Linhas do grafico continuam.";
      ObjectSetInteger(0, objeto, OBJPROP_STATE, false);
      LimparSomentePainelVisual();
      return true;
   }
   return false;
}

void DesenharBotoesModoPainel(string pfx, int x, int y, int fonte)
{
   if(InpFIX284MostrarBotoesControle)
      DesenharBotoesControleOperacaoFIX284(pfx, x - 210, y, fonte);
   else
   {
      ObjectDelete(0, pfx + "CTRL_PAUSA_FIX284");
      ObjectDelete(0, pfx + "CTRL_ENCERRAR_FIX284");
   }

   PnlBotaoModo(pfx + "MODO_FULL", "FULL", x,       y, 56, 22, g_modoPainelVisualAtivo == PAINEL_VISUAL_COMPLETO, fonte);
   PnlBotaoModo(pfx + "MODO_SLIM", "SLIM", x + 60,  y, 56, 22, g_modoPainelVisualAtivo == PAINEL_VISUAL_SLIM,     fonte);
   PnlBotaoModo(pfx + "MODO_RED",  "RED",  x + 120, y, 56, 22, g_modoPainelVisualAtivo == PAINEL_VISUAL_REDUZIDO,  fonte);
   PnlBotaoModo(pfx + "MODO_OFF",  "OFF",  x + 180, y, 56, 22, g_modoPainelVisualAtivo == PAINEL_VISUAL_OFF,       fonte);
}

void DesenharBotoesControleOperacaoFIX284(string pfx, int x, int y, int fonte)
{
   SincronizarControleOperacaoFIX284(false);
   string siglaLado = (MagicControleLocalFIX285() == MagicCompraAtual() ? "C" : "V");
   string textoPausa = "PAUSAR " + siglaLado;
   color fundoPausa = C'180,83,9';
   color bordaPausa = C'245,158,11';
   if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_PAUSADO_FIX284)
   {
      textoPausa = "RETOMAR " + siglaLado;
      fundoPausa = C'22,163,74';
      bordaPausa = C'74,222,128';
   }
   else if(g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ENCERRADO_FIX284)
   {
      textoPausa = "REATIVAR " + siglaLado;
      fundoPausa = C'22,163,74';
      bordaPausa = C'74,222,128';
   }

   string textoEncerrar = (g_controleOperacaoFIX284 == CONTROLE_OPERACAO_ENCERRADO_FIX284 ? "ENCERRADO " : "ENCERRAR ") + siglaLado;
   PnlBotaoControleFIX284(pfx + "CTRL_PAUSA_FIX284", textoPausa, x, y, 96, 22,
                          fundoPausa, clrWhite, bordaPausa, fonte);
   PnlBotaoControleFIX284(pfx + "CTRL_ENCERRAR_FIX284", textoEncerrar, x + 100, y, 106, 22,
                          C'185,28,28', clrWhite, C'248,113,113', fonte);
}

void PnlBotaoControleFIX284(string nome, string texto, int x, int y, int largura, int altura, color fundo, color textoCor, color borda, int fonte)
{
   if(ObjectFind(0, nome) < 0)
      ObjectCreate(0, nome, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, PainelAutoXFIX319(nome,x));
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, PainelAutoYFIX319(nome,y));
   ObjectSetInteger(0, nome, OBJPROP_XSIZE, PainelAutoWFIX319(nome,largura));
   ObjectSetInteger(0, nome, OBJPROP_YSIZE, PainelAutoHFIX319(nome,altura));
   ObjectSetInteger(0, nome, OBJPROP_BGCOLOR, fundo);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, textoCor);
   ObjectSetInteger(0, nome, OBJPROP_BORDER_COLOR, borda);
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, PainelAutoFonteFIX319(nome,fonte));
   ObjectSetString(0, nome, OBJPROP_FONT, "Tahoma");
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, nome, OBJPROP_STATE, false);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 12000);
}

void PnlBotaoModo(string nome, string texto, int x, int y, int largura, int altura, bool ativo, int fonte)
{
   if(ObjectFind(0, nome) < 0)
      ObjectCreate(0, nome, OBJ_BUTTON, 0, 0, 0);
   color fundo = ativo ? PnlCorAbaAtiva() : PnlCorAbaInativa();
   color corTxt = ativo ? clrWhite : PnlCorTexto();
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, PainelAutoXFIX319(nome,x));
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, PainelAutoYFIX319(nome,y));
   ObjectSetInteger(0, nome, OBJPROP_XSIZE, PainelAutoWFIX319(nome,largura));
   ObjectSetInteger(0, nome, OBJPROP_YSIZE, PainelAutoHFIX319(nome,altura));
   ObjectSetInteger(0, nome, OBJPROP_BGCOLOR, fundo);
   ObjectSetInteger(0, nome, OBJPROP_COLOR, corTxt);
   ObjectSetInteger(0, nome, OBJPROP_BORDER_COLOR, ativo ? PnlCorTitulo() : PnlCorLinha());
   ObjectSetInteger(0, nome, OBJPROP_FONTSIZE, PainelAutoFonteFIX319(nome,fonte));
   ObjectSetString(0, nome, OBJPROP_FONT, "Tahoma");
   ObjectSetString(0, nome, OBJPROP_TEXT, texto);
   ObjectSetInteger(0, nome, OBJPROP_STATE, false);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, nome, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 10000);
}


#endif
