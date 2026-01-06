# Resumo Executivo - Arquitetura de Banco de Dados
## SaaS Peladeiros - Versão Simplificada

---

## 🎯 **O QUE ESTE DOCUMENTO FAZ?**

Este é um resumo rápido da arquitetura de banco de dados. Use este documento para:
- ✅ Entender rapidamente a estrutura geral
- ✅ Explicar para investidores ou stakeholders
- ✅ Ter uma visão de alto nível antes de mergulhar nos detalhes

---

## 📊 **VISÃO GERAL EM 3 PARTES**

### **PARTE 1: AUTENTICAÇÃO E PERFIL**
```
Usuário faz Login → Vira um Atleta → Tem um Perfil FIFA Card
```

**Tabelas:**
- `usuarios`: Login (Google ou Telefone)
- `atletas`: Perfil do jogador com todas as estatísticas
- `atributos_atleta`: Atributos do FIFA Card (Ritmo, Chute, etc.)

### **PARTE 2: COMUNIDADE E EVENTOS**
```
Grupo de Pelada → Tem Membros → Faz Partidas → Registra Estatísticas
```

**Tabelas:**
- `grupos`: Uma pelada fixa (ex: "Pelada da AABB")
- `membros_grupo`: Quem faz parte do grupo
- `partidas`: Um jogo específico de uma noite
- `participantes_partida`: Quem jogou naquele dia
- `desempenho_scout`: Estatísticas de cada jogador (gols, assistências, etc.)

### **PARTE 3: SOCIAL E GAMIFICAÇÃO**
```
Jogadores Avaliam Uns aos Outros → Ganham Badges → Recebem Notificações
```

**Tabelas:**
- `avaliacoes`: Notas que jogadores dão uns para os outros
- `badges`: Conquistas (ex: "Artilheiro da RA")
- `notificacoes`: Push notifications para usuários

---

## 🔑 **CONCEITOS CHAVE**

### **1. Identidade Unificada**
Um mesmo atleta pode jogar em várias peladas diferentes, mas tem **UMA** identidade única no sistema. Todas as estatísticas são agregadas em um só lugar.

**Exemplo:**
- João joga na "Pelada da AABB" (Asa Sul) e na "Pelada do Noroeste"
- Ele tem UM perfil com estatísticas de AMBAS as peladas
- Pode ver ranking geral ou filtrar por região/grupo

### **2. Hierarquia de Dados**
```
Grupo (Pelada Fixa)
  └── Partida (Jogo de uma Noite)
      └── Participantes (Quem Jogou)
          └── Desempenho (Estatísticas Individuais)
```

### **3. Cálculo de Rankings (Fase 1)**
```
Pontos = (Gols × 3) + (Assistências × 2)
```

**Exemplo:**
- João marcou 2 gols e deu 1 assistência
- Pontos = (2 × 3) + (1 × 2) = 8 pontos

---

## 📋 **11 TABELAS PRINCIPAIS**

| # | Tabela | O que guarda | Quantidade |
|---|--------|--------------|------------|
| 1 | `usuarios` | Login e autenticação | 1 por pessoa |
| 2 | `atletas` | Perfil do jogador | 1 por pessoa |
| 3 | `atributos_atleta` | Atributos FIFA Card | 1+ por atleta (por temporada) |
| 4 | `grupos` | Peladas fixas | 1 por grupo |
| 5 | `membros_grupo` | Quem faz parte do grupo | N por grupo |
| 6 | `partidas` | Jogos específicos | N por grupo |
| 7 | `participantes_partida` | Quem jogou naquele dia | N por partida |
| 8 | `desempenho_scout` | Estatísticas individuais | 1 por jogador por partida |
| 9 | `avaliacoes` | Notas entre jogadores | N por partida (Fase 2) |
| 10 | `badges` | Conquistas | N por atleta (Fase 2) |
| 11 | `notificacoes` | Push notifications | N por usuário |

---

## 🔄 **FLUXO DE DADOS PRINCIPAL**

### **Cenário: Uma Partida Completa**

1. **Scout cria evento**
   - Cria registro em `partidas`
   - Status: `aberta`

2. **Jogadores confirmam presença**
   - Scout adiciona em `participantes_partida`
   - Ou jogadores confirmam via app

3. **Após o jogo, Scout preenche súmula**
   - Para cada participante, cria registro em `desempenho_scout`
   - Preenche: gols, assistências, vitórias/empates/derrotas
   - Sistema calcula automaticamente: `pontos_partida`

4. **Scout fecha súmula**
   - Atualiza `partidas.status_sumula` para `fechada`
   - Sistema valida: soma de gols = `gols_total_noite`
   - Sistema atualiza automaticamente estatísticas em `atletas`
   - Sistema cria notificações em `notificacoes`

5. **Jogadores recebem notificação**
   - Push: "O Scout registrou 2 gols para você"
   - Podem ver ranking atualizado

---

## 🎮 **FUNCIONALIDADES SUPORTADAS**

### ✅ **Fase 1 (MVP)**
- [x] Cadastro e login (Google/Telefone)
- [x] Criação de grupos de pelada
- [x] Criação de eventos/partidas
- [x] Súmula rápida (RF04)
- [x] FIFA Card básico (gols, assistências, vitórias)
- [x] Ranking por grupo
- [x] Ranking regional (DF)
- [x] Validação de consistência (RF08)

### ✅ **Fase 2 (Social)**
- [x] Sistema de avaliações (RF05)
- [x] Badges e conquistas
- [x] Atributos do FIFA Card evoluídos

### ✅ **Fase 3 (Tecnologia)**
- [x] Estrutura pronta para IA
- [x] Estrutura pronta para vídeos/replays

---

## 🔒 **SEGURANÇA E VALIDAÇÕES**

### **Validações Automáticas:**
1. ✅ Um jogador não pode ter mais de 1 resultado por partida (vitória OU empate OU derrota)
2. ✅ Soma de gols deve bater com total da partida
3. ✅ Notas entre 0-10 ou 1-5 (dependendo do contexto)
4. ✅ Um jogador não pode se auto-avaliar

### **Soft Delete:**
- Contas desativadas não são deletadas
- Dados históricos são preservados
- Usa campo `ativo = false`

---

## 📈 **PERFORMANCE E ESCALABILIDADE**

### **Índices Criados:**
- Busca rápida de atletas por usuário
- Rankings ordenados rapidamente
- Busca de partidas por grupo/data
- Notificações não lidas

### **Cálculos Automáticos:**
- `pontos_partida` calculado automaticamente
- Estatísticas do atleta atualizadas automaticamente
- Timestamps atualizados automaticamente

---

## 🚀 **PRÓXIMOS PASSOS**

1. **Revisar documentação completa**
   - Ler: `Arquitetura de Banco de Dados - Completa e Simplificada.md`

2. **Executar scripts SQL**
   - Usar: `Scripts SQL - Exemplo de Implementação.sql`
   - Testar com dados de exemplo

3. **Validar com equipe técnica**
   - Ajustar conforme necessário
   - Definir ambiente de desenvolvimento

4. **Começar desenvolvimento**
   - Implementar APIs que usam essas tabelas
   - Criar interface do app

---

## ❓ **PERGUNTAS FREQUENTES**

### **P: Quantos registros o banco suporta?**
**R:** Milhões. A estrutura foi pensada para escalar. Com índices adequados, pode suportar milhões de atletas, grupos e partidas.

### **P: E se precisar mudar algo depois?**
**R:** A estrutura é flexível. Campos podem ser adicionados, tabelas podem evoluir. O importante é manter compatibilidade com dados existentes.

### **P: Como funciona a "Temporada"?**
**R:** É um campo de texto (ex: `2025-1`). Você define quando uma temporada começa/termina. Permite resetar rankings ou comparar períodos.

### **P: E se um Scout errar os dados?**
**R:** Enquanto `status_sumula = 'aberta'`, pode editar. Depois de fechar, pode marcar como `revisao_pendente` e corrigir.

---

## 📞 **SUPORTE**

Para dúvidas técnicas detalhadas, consulte:
- `Arquitetura de Banco de Dados - Completa e Simplificada.md` (documentação completa)
- `Scripts SQL - Exemplo de Implementação.sql` (código SQL)

---

**Última atualização:** Janeiro 2025
**Versão:** 1.0

