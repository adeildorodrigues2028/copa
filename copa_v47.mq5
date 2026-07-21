// V36 - AUDITORIA FINANCEIRA E ISOLAMENTO ESTRITO POR MAGIC
// Mesmo par de Magics recupera o historico persistido; par novo inicia zerado.
// Nenhum Magic antigo e agregado automaticamente.
// V105 FIX456 - MAGICS PADRAO AJUSTADOS: COMPRA 326050 | VENDA 326051
// V104 FIX455 - CORRIGE INDICE DO REARME DE VENDA: remove uso fora de escopo e grava timer no agendamento correto
// V106 FIX457 - RECUPERA HISTORICO APOS REINICIO | MAGICS 326050/326051
// V90 FIX441 - CORRIGE LOG maxContratos; JANELAS A1-A5 SEM LIMITE GLOBAL
// V88 FIX439 - A1 unico a 1000 pontos; stop R$500; MOVEL 25/10 e TRAIL 50/25 reais no motor

// FIX439 - CONFIGURACAO OPERACIONAL APROVADA NO TESTE:
// A0=1C | PERDA=R$500 | MOVEL=25/10 | TRAIL=50/25 CONTINUO.
// A1=1C | DISTANCIA=1000 PONTOS DESDE A0 | TIMER=120S | RSI7 70/30 | AGRESSAO>=60 | FORCA>=60.
// A2/A3/A4=DESLIGADOS. A1 possui protecao individual por ticket e nao pode repetir no mesmo ciclo.
// FIX411: DX adaptativo conectado como filtro separado para A0 e A1-A4.
// Janelas, distancias, trailing e protecoes financeiras preservados.
// COPA / AR100 - FIX384 TIMER OPERACIONAL PERMANENTE
// Base operacional: FIX382. Nenhuma funcao alcancavel por OnInit, OnTick, OnTimer,
// OnTradeTransaction, OnChartEvent ou OnDeinit foi modificada.
// Limpeza aplicada: historico antigo do cabecalho, prototipos sem uso e funcoes
// sem caminho de execucao. Entradas A0, aumentos A1-A4, RSI, timer, linha+candle,
// preco melhor, risco, reentrada, trailing, painel e historico ativo preservados.
// FIX415: MsgBox visual totalmente removida; auditoria de entrada/parcial/trailing permanece somente nos logs Experts.
// FIX416: remove completamente a linha dinamica CHECK/ESC/LOSS do painel; novo Magic continua com historico isolado e zerado.
// FIX394: trailing 20/5 com prioridade total no Timer; fecha antes de parcial, aumento ou gain concorrente.
// IMPORTANTE: validar compilacao no MetaEditor e executar Strategy Tester antes de conta real.

#property strict
#property version   "3.73"
#property description "COPA / AR_100 - operação, histórico e painel"
#include "modulos/texto.mqh"
#include "modulos/identidade_texto.mqh"
#include "modulos/horario.mqh"
// FIX362: recurso visual removido; RSI/agressao continuam somente no calculo interno.
// FIX346: recurso DX externo removido; fallback visual interno ja existente sera utilizado.


// ============================================================================
// FIX426 - DX cirurgico: preserva calibracao FIX425 e adiciona distancia minima,
// candle direcional, rompimento do candle anterior, bloqueio de sinais repetidos e uma seta por regiao.
// FIX425 - DX calibrado: perfil NORMAL, faixa 45/85, amostra 14, liberacao 65,
// tolerancia de 50 pontos na media e confirmacao HILO OU STR em ate 2 candles.
// FIX424 - PARAMETROS DO MOTOR CANAIS ORGANIZADOS APOS OS GRUPOS EXISTENTES; A1-A4 REMOVIDOS DA ABA.
// FIX423 - MOTOR CANAIS independente (Bollinger + Keltner + POC + Fundo/Teto)
// ============================================================================
#include "modulos/tipos_parametros_usuario.mqh"
#include "modulos/parametros_usuario.mqh"

#include "modulos/parametros_compatibilidade.mqh"
#include "modulos/parametros_internos.mqh"
enum ENUM_LADO_ROBO
{
   LADO_COMPRA = 0,
   LADO_VENDA  = 1,
   LADO_AMBOS  = 2,
   LADO_NENHUM = 3
};

#include "modulos/lado.mqh"
#include "modulos/formatacao.mqh"

#include "modulos/tipos_estado_operacional.mqh"
#include "modulos/estado_global_operacional.mqh"
#include "modulos/prototipos_configuracao.mqh"
#include "modulos/parser_filtros_base.mqh"
#include "modulos/prototipos_motor.mqh"
#include "modulos/base_historica.mqh"


#include "modulos/motor_canais.mqh"

#include "modulos/auditoria_ticks.mqh"

#include "modulos/ciclo_inicializacao.mqh"
#include "modulos/eventos_trade_grafico.mqh"
#include "modulos/ciclo_timer.mqh"
#include "modulos/ciclo_pontas.mqh"
#include "modulos/reconstrucao_financeira_ciclo.mqh"
#include "modulos/identificacao_niveis_aumentos.mqh"

#include "modulos/memoria_rearme_aumentos.mqh"
#include "modulos/gestao_tickets_aumentos.mqh"
#include "modulos/gerenciamento_ponta.mqh"
#include "modulos/mensagens_fim_dia.mqh"
#include "modulos/controle_operacao.mqh"
#include "modulos/dx_adaptativo.mqh"
#include "modulos/ciclo_tick.mqh"
#include "modulos/ambiente_validacao.mqh"

#include "modulos/instancia_operacional.mqh"
#include "modulos/coordenacao_magics.mqh"
#include "modulos/identidade_ciclo.mqh"
#include "modulos/indicadores_gestao.mqh"
#include "modulos/configuracao_janelas.mqh"
#include "modulos/filtros_humanizados.mqh"
#include "modulos/regras_aumentos.mqh"
#include "modulos/parametros_compactos.mqh"
#include "modulos/historico_core.mqh"
#include "modulos/cesta_ab_diagnostico.mqh"
#include "modulos/fechamento_cesta_ab.mqh"
#include "modulos/resumo_financeiro.mqh"
#include "modulos/filtros_operacionais.mqh"
#include "modulos/protecao_dia.mqh"
#include "modulos/parcial_niveis.mqh"
#include "modulos/parciais_head.mqh"
#include "modulos/gerenciador_parciais_lado.mqh"
#include "modulos/volume_fechamento.mqh"
#include "modulos/execucao_parcial.mqh"
#include "modulos/sinal_saida_longa.mqh"

#include "modulos/validacoes_entrada_aumento.mqh"
#include "modulos/preflight_stops_ordens.mqh"
#include "modulos/envio_ordem_mercado.mqh"
#include "modulos/entrada_direta.mqh"
bool FecharPosicoesLado(EstadoLado &estado, string motivo)
{
   if(!estado.posicaoAberta)
      return false;
   if(!PermiteEnvioOrdem(estado, "Saida financeira"))
      return false;
   bool encontrou = false;
   bool tudoOk = true;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(!PosicaoSelecionadaPertenceEstadoFIX317(estado))
         continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         continue;
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = _Symbol;
      req.volume       = NormalizarVolume(volume);
      req.magic        = (ulong)estado.magic;
      req.deviation    = InpDesvioMaximoPontos;
      req.type_time    = ORDER_TIME_GTC;
      req.type_filling = TipoPreenchimentoSeguro();
      req.comment      = ComentarioComIdentidadeMagicFIX304(InpComentarioOrdens + " SAIDA " + motivo + " " + estado.nome,req.magic);
      if(type == POSITION_TYPE_BUY)
      {
         req.type  = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         req.type  = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      }
      else
         continue;
      encontrou = true;
      estado.ultimaTentativaOrdem = TimeCurrent();
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         RegistrarGerenciadorOrdens(estado, "SAIDA_OK",
                                    StringFormat("SAIDA ENVIADA %s | Ticket %s | Volume %.2f | Aberto %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 req.volume,
                                                 PnlMoedaBRL(estado.resultadoAberto)),
                                    res.retcode, 0, req.volume, req.price, true);
      }
      else
      {
         int ultimoErro = GetLastError();
         tudoOk = false;
         RegistrarGerenciadorOrdens(estado, "SAIDA_REJECT",
                                    StringFormat("SAIDA REJEITADA %s | Ticket %s | Retcode %s | Erro %s",
                                                 motivo,
                                                 IntegerToString((long)ticket),
                                                 IntegerToString((int)res.retcode),
                                                 IntegerToString(ultimoErro)),
                                    res.retcode, ultimoErro, req.volume, req.price, true);
      }
   }
   if(!encontrou)
      RegistrarGerenciadorOrdens(estado, "SAIDA_BLOCK", "Saida solicitada, mas nenhuma posicao do Magic/lado foi encontrada.", 0, 0, 0.0, 0.0, true);
   return (encontrou && tudoOk);
}

#include "modulos/logs_auditoria.mqh"
#include "modulos/locks_ordens.mqh"

#include "modulos/painel.mqh"
#include "modulos/auditoria_core.mqh"

#include "modulos/exportacao_semanal.mqh"

#include "modulos/auditoria_visual.mqh"
