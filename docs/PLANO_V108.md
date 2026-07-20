# Plano de modularização V108

## Regra de segurança
Não alterar entradas, aumentos, horários, Magics, stop, gain, trailing, painel, histórico, OnTick, OnTimer ou gerenciamento financeiro.

## Ordem de trabalho
1. Criar estrutura e documentação.
2. Separar somente funções utilitárias.
3. Compilar e testar.
4. Separar histórico.
5. Compilar e testar.
6. Separar painel.
7. Compilar e testar.
8. Separar gerenciamento.
9. Compilar e testar.
10. Separar entradas e aumentos somente em etapas diferentes.

## Arquivos planejados
- modulos/Utilitarios.mqh
- modulos/Historico.mqh
- modulos/Painel.mqh
- modulos/Gerenciamento.mqh
- modulos/Entradas.mqh
- modulos/Aumentos.mqh
