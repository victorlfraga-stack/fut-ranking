# Arquitetura de Banco de Dados - SaaS Peladeiros
## Guia Completo e Simplificado

---

## 📚 **PARTE 1: CONCEITOS BÁSICOS (Para Iniciantes)**

### O que é um Banco de Dados?
Imagine um banco de dados como uma **planilha gigante e inteligente** que guarda todas as informações do seu app. Mas ao invés de uma planilha simples, é um sistema que:
- **Organiza** informações de forma estruturada
- **Relaciona** dados entre si (ex: "João pertence ao grupo AABB")
- **Protege** os dados contra perda ou acesso não autorizado
- **Busca** informações rapidamente, mesmo com milhões de registros

### O que são Tabelas?
Cada **tabela** é como uma planilha que guarda um tipo específico de informação:
- **Tabela de Atletas**: Lista todos os jogadores
- **Tabela de Grupos**: Lista todas as peladas
- **Tabela de Partidas**: Lista todos os jogos que aconteceram

### O que são Campos?
Cada **campo** é uma coluna na tabela. Por exemplo, na tabela de Atletas:
- **nome_completo**: O nome do jogador
- **foto_url**: O link da foto dele
- **overall_global**: A nota geral dele

### O que são Relacionamentos?
É como conectar as tabelas. Por exemplo:
- Um **Atleta** pode participar de vários **Grupos**
- Um **Grupo** pode ter várias **Partidas**
- Uma **Partida** tem vários **Atletas** participando

---

## 📊 **PARTE 2: ANÁLISE DA ESTRUTURA PROPOSTA**

### ✅ **Pontos Fortes da Modelagem Atual:**
1. ✅ Boa separação de responsabilidades (cada tabela tem um propósito claro)
2. ✅ Suporta a ideia de "Identidade Unificada" (atleta pode estar em vários grupos)
3. ✅ Estrutura pensada para escalar (suporta muitos grupos e partidas)

### ⚠️ **Gaps Identificados (O que está faltando):**
1. ❌ **Autenticação de Usuários**: Como o jogador faz login? (Google, telefone)
2. ❌ **Sistema de Notificações**: Como enviar push notifications?
3. ❌ **Histórico de Avaliações**: RF05 menciona que jogadores avaliam outros jogadores
4. ❌ **Delegação de Scout**: RF06 menciona que o Scout pode delegar para assistente
5. ❌ **Timestamps**: Quando cada registro foi criado/modificado?
6. ❌ **Soft Delete**: Como "desativar" sem deletar dados históricos?
7. ❌ **Atributos do FIFA Card**: RF01 menciona Ritmo, Chute, Passe, Defesa, Físico
8. ❌ **Badges/Conquistas**: Mencionado na Fase 2
9. ❌ **Temporadas**: Como separar dados por temporada?
10. ❌ **Validação de Dados**: Campos obrigatórios, tipos de dados, limites

---

## 🏗️ **PARTE 3: ARQUITETURA COMPLETA PROPOSTA**

### **VISÃO GERAL DA ESTRUTURA**

```
┌─────────────────┐
│   USUÁRIOS      │ ← Autenticação (Google, Telefone)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    ATLETAS      │ ← Perfil do Jogador
└────────┬────────┘
         │
         ├──────────┐
         │          │
         ▼          ▼
┌─────────────┐  ┌─────────────┐
│   GRUPOS    │  │  PARTIDAS   │
└──────┬──────┘  └──────┬───────┘
       │                │
       │                ▼
       │         ┌──────────────┐
       │         │ DESEMPENHO  │
       │         └──────────────┘
       │
       ▼
┌─────────────┐
│  AVALIAÇÕES │ ← Notas entre jogadores
└─────────────┘
```

---

## 📋 **PARTE 4: TABELAS DETALHADAS**

### **1. TABELA: `usuarios`**
**O que é?** Guarda informações de login e autenticação de TODOS os usuários do sistema.

**Por que precisa?** Antes de ser um "atleta", a pessoa precisa fazer login no app. Esta tabela cuida disso.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_usuario` | UUID/INT | Identificador único | `12345` |
| `email` | VARCHAR(255) | Email para login | `joao@email.com` |
| `telefone` | VARCHAR(20) | Telefone (opcional) | `+5561999999999` |
| `provider` | ENUM | Como fez login | `google`, `telefone` |
| `provider_id` | VARCHAR(255) | ID do provedor | ID do Google |
| `ativo` | BOOLEAN | Conta ativa? | `true` |
| `criado_em` | TIMESTAMP | Quando criou conta | `2025-01-15 10:30:00` |
| `atualizado_em` | TIMESTAMP | Última atualização | `2025-01-20 15:45:00` |

**Regras:**
- Um usuário pode ter email OU telefone (ou ambos)
- `provider` indica se usou Google ou telefone para login
- `ativo = false` significa conta desativada (não deletada)

---

### **2. TABELA: `atletas`**
**O que é?** O "CV" do jogador. Centraliza todas as informações do perfil esportivo.

**Por que precisa?** Esta é a identidade unificada do jogador. Um mesmo atleta pode jogar em várias peladas diferentes.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_atleta` | UUID/INT | Identificador único | `67890` |
| `id_usuario` | FK → usuarios | Link com login | `12345` |
| `nome_completo` | VARCHAR(255) | Nome para exibição | `João Silva` |
| `apelido` | VARCHAR(100) | Apelido (opcional) | `Joãozinho` |
| `foto_url` | VARCHAR(500) | Link da foto | `https://...` |
| `ra_principal` | VARCHAR(100) | Região preferência | `Asa Sul`, `Noroeste` |
| `posicao_preferencial` | ENUM | Posição favorita | `Goleiro`, `Zagueiro`, `Meia`, `Atacante` |
| `overall_global` | DECIMAL(5,2) | Nota geral (0-100) | `75.50` |
| `pontos_ranking` | INT | Pontos totais | `1250` |
| `total_gols` | INT | Gols na carreira | `45` |
| `total_assistencias` | INT | Assistências na carreira | `32` |
| `total_vitorias` | INT | Vitórias totais | `120` |
| `total_empates` | INT | Empates totais | `15` |
| `total_derrotas` | INT | Derrotas totais | `35` |
| `partidas_jogadas` | INT | Total de partidas | `170` |
| `criado_em` | TIMESTAMP | Quando criou perfil | `2025-01-15 10:35:00` |
| `atualizado_em` | TIMESTAMP | Última atualização | `2025-01-20 16:00:00` |

**Regras:**
- Um `usuario` tem UM `atleta` (relação 1:1)
- `overall_global` é calculado automaticamente (não preenchido manualmente)
- `pontos_ranking` = (gols × 3) + (assistências × 2) - conforme Fase 1 do PRD

**Campos Calculados (não ficam na tabela, são calculados na hora):**
- Média de gols por partida
- Taxa de vitórias (%)
- Performance por região

---

### **3. TABELA: `atributos_atleta`** ⭐ NOVA
**O que é?** Guarda os atributos do FIFA Card (Ritmo, Chute, Passe, Defesa, Físico).

**Por que precisa?** RF01 menciona atributos específicos. Esta tabela permite evoluir esses atributos ao longo do tempo.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_atributo` | UUID/INT | Identificador único | `111` |
| `id_atleta` | FK → atletas | Qual jogador | `67890` |
| `ritmo` | INT | Velocidade (0-100) | `80` |
| `chute` | INT | Força/precisão (0-100) | `75` |
| `passe` | INT | Qualidade passe (0-100) | `70` |
| `defesa` | INT | Habilidade defensiva (0-100) | `65` |
| `fisico` | INT | Resistência/força (0-100) | `72` |
| `temporada` | VARCHAR(50) | Qual temporada | `2025-1`, `2025-2` |
| `atualizado_em` | TIMESTAMP | Quando atualizou | `2025-01-20 16:00:00` |

**Regras:**
- Cada atleta pode ter múltiplos registros (um por temporada)
- Valores de 0 a 100
- Na Fase 1 (MVP), pode ficar vazio ou com valores padrão
- Na Fase 3, será calculado automaticamente

---

### **4. TABELA: `grupos`**
**O que é?** Representa uma pelada fixa (ex: "Pelada da AABB").

**Por que precisa?** É a comunidade onde os jogos acontecem. Um grupo tem várias partidas ao longo do tempo.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_grupo` | UUID/INT | Identificador único | `100` |
| `nome_grupo` | VARCHAR(255) | Nome da pelada | `Pelada da AABB` |
| `descricao` | TEXT | Descrição (opcional) | `Pelada tradicional...` |
| `id_scout_adm` | FK → atletas | Scout principal | `67890` |
| `localizacao_ra` | VARCHAR(100) | Região | `Asa Sul`, `Noroeste` |
| `endereco` | VARCHAR(500) | Endereço completo | `Quadra 205, Asa Sul` |
| `fator_k_dificuldade` | DECIMAL(3,2) | Nível técnico (1.0-5.0) | `3.5` |
| `nivel_pelada` | ENUM | Tipo | `competitivo`, `resenha`, `misto` |
| `ativo` | BOOLEAN | Grupo ativo? | `true` |
| `criado_em` | TIMESTAMP | Quando criou | `2025-01-10 08:00:00` |
| `atualizado_em` | TIMESTAMP | Última atualização | `2025-01-20 14:00:00` |

**Regras:**
- `fator_k_dificuldade`: Usado para normalizar rankings
  - `1.0` = Muito fácil (resenha)
  - `3.0` = Médio
  - `5.0` = Muito difícil (competitivo)
- `id_scout_adm` é o dono/autoridade do grupo
- Um grupo pode ter vários membros (tabela `membros_grupo`)

---

### **5. TABELA: `membros_grupo`**
**O que é?** Define quem são os participantes fixos/mensalistas de um grupo.

**Por que precisa?** Um grupo tem vários membros, e um atleta pode estar em vários grupos. Esta tabela conecta os dois.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_membro` | UUID/INT | Identificador único | `200` |
| `id_grupo` | FK → grupos | Qual grupo | `100` |
| `id_atleta` | FK → atletas | Qual jogador | `67890` |
| `tipo_membro` | ENUM | Tipo | `fixo`, `mensalista`, `avulso` |
| `ativo` | BOOLEAN | Ainda é membro? | `true` |
| `entrou_em` | TIMESTAMP | Quando entrou | `2025-01-10 09:00:00` |
| `saiu_em` | TIMESTAMP | Quando saiu (NULL se ativo) | `NULL` |

**Regras:**
- Um atleta pode estar em vários grupos
- Um grupo pode ter vários atletas
- `ativo = false` significa que saiu do grupo (mas histórico permanece)

---

### **6. TABELA: `partidas`**
**O que é?** Representa um evento/jogo específico de uma noite.

**Por que precisa?** Cada jogo precisa ser registrado separadamente para gerar estatísticas e rankings.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_partida` | UUID/INT | Identificador único | `300` |
| `id_grupo` | FK → grupos | Qual grupo | `100` |
| `data_evento` | DATE | Data do jogo | `2025-01-20` |
| `hora_inicio` | TIME | Hora que começou | `20:00:00` |
| `hora_fim` | TIME | Hora que terminou | `22:00:00` |
| `gols_total_noite` | INT | Total de gols (validação) | `12` |
| `status_sumula` | ENUM | Status | `aberta`, `fechada`, `revisao_pendente` |
| `id_scout_responsavel` | FK → atletas | Quem preencheu | `67890` |
| `id_scout_delegado` | FK → atletas | Assistente (opcional) | `11111` |
| `temporada` | VARCHAR(50) | Qual temporada | `2025-1` |
| `criado_em` | TIMESTAMP | Quando criou evento | `2025-01-20 19:00:00` |
| `fechado_em` | TIMESTAMP | Quando fechou súmula | `2025-01-20 22:30:00` |

**Regras:**
- `gols_total_noite`: Soma de todos os gols marcados (validação RF08)
- `status_sumula`:
  - `aberta`: Scout ainda pode editar
  - `fechada`: Súmula finalizada e confirmada
  - `revisao_pendente`: Alguém contestou, precisa revisar
- `id_scout_delegado`: Permite RF06 (delegação)

---

### **7. TABELA: `participantes_partida`**
**O que é?** Lista de quem compareceu/foi confirmado para aquele jogo específico.

**Por que precisa?** RF04 diz que a interface só mostra quem está em `participantes_partida`. É o "check-in" do jogo.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_participante` | UUID/INT | Identificador único | `400` |
| `id_partida` | FK → partidas | Qual jogo | `300` |
| `id_atleta` | FK → atletas | Qual jogador | `67890` |
| `confirmado_em` | TIMESTAMP | Quando confirmou | `2025-01-20 18:00:00` |
| `compareceu` | BOOLEAN | Realmente jogou? | `true` |

**Regras:**
- Um atleta só aparece na súmula se estiver aqui
- Scout pode adicionar durante o evento (RF04)
- `compareceu = false` significa que confirmou mas não foi

---

### **8. TABELA: `desempenho_scout`**
**O que é?** A súmula propriamente dita. Guarda as estatísticas de cada jogador em cada partida.

**Por que precisa?** É aqui que ficam os dados que alimentam o FIFA Card e os rankings.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_scout` | UUID/INT | Identificador único | `500` |
| `id_partida` | FK → partidas | Qual jogo | `300` |
| `id_atleta` | FK → atletas | Qual jogador | `67890` |
| `gols` | INT | Gols marcados | `2` |
| `assistencias` | INT | Assistências dadas | `1` |
| `vitorias` | INT | Quantas vitórias (0 ou 1) | `1` |
| `empates` | INT | Quantos empates (0 ou 1) | `0` |
| `derrotas` | INT | Quantas derrotas (0 ou 1) | `0` |
| `nota_desempenho` | DECIMAL(3,2) | Nota do Scout (0-10) | `8.5` |
| `pontos_partida` | INT | Pontos dessa partida | `8` |
| `criado_em` | TIMESTAMP | Quando registrou | `2025-01-20 22:15:00` |
| `atualizado_em` | TIMESTAMP | Última atualização | `2025-01-20 22:20:00` |

**Regras:**
- `pontos_partida` = (gols × 3) + (assistencias × 2) - conforme Fase 1
- `vitorias + empates + derrotas` deve ser 1 (só pode ter um resultado)
- `nota_desempenho` é opcional na Fase 1, obrigatório na Fase 2
- Só pode ter um registro por `id_partida` + `id_atleta` (único)

**Validação RF08:**
- Soma de todos os `gols` deve igualar `gols_total_noite` da partida

---

### **9. TABELA: `avaliacoes`** ⭐ NOVA
**O que é?** Guarda as notas que jogadores dão uns para os outros (RF05 - Fase 2).

**Por que precisa?** RF05 menciona que após o jogo, jogadores avaliam outros jogadores (1-5).

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_avaliacao` | UUID/INT | Identificador único | `600` |
| `id_partida` | FK → partidas | Qual jogo | `300` |
| `id_avaliador` | FK → atletas | Quem está avaliando | `67890` |
| `id_avaliado` | FK → atletas | Quem está sendo avaliado | `11111` |
| `nota` | INT | Nota (1-5) | `4` |
| `comentario` | TEXT | Comentário (opcional) | `Jogou muito bem!` |
| `criado_em` | TIMESTAMP | Quando avaliou | `2025-01-20 22:30:00` |

**Regras:**
- Um jogador só pode avaliar outros que estiveram na mesma partida
- Um jogador não pode se auto-avaliar (`id_avaliador ≠ id_avaliado`)
- Nota de 1 a 5 (conforme RF05)
- Pode ter múltiplas avaliações por partida (vários avaliadores)

---

### **10. TABELA: `badges`** ⭐ NOVA (Fase 2)
**O que é?** Conquistas/Badges que jogadores podem ganhar (ex: "Artilheiro da RA").

**Por que precisa?** Fase 2 menciona badges sociais para gamificação.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_badge` | UUID/INT | Identificador único | `700` |
| `id_atleta` | FK → atletas | Qual jogador | `67890` |
| `tipo_badge` | ENUM | Tipo | `artilheiro_ra`, `muralha`, `assistente` |
| `regiao` | VARCHAR(100) | Região (se aplicável) | `Asa Sul` |
| `temporada` | VARCHAR(50) | Qual temporada | `2025-1` |
| `conquistado_em` | TIMESTAMP | Quando ganhou | `2025-01-20 23:00:00` |

**Regras:**
- Badges são calculados automaticamente baseado em estatísticas
- Um atleta pode ter vários badges
- Badges podem ser por temporada ou "all-time"

---

### **11. TABELA: `notificacoes`** ⭐ NOVA
**O que é?** Guarda as notificações enviadas para os usuários (RF07).

**Por que precisa?** RF07 menciona push notifications quando a súmula é fechada.

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `id_notificacao` | UUID/INT | Identificador único | `800` |
| `id_usuario` | FK → usuarios | Para quem | `12345` |
| `tipo` | ENUM | Tipo | `sumula_fechada`, `avaliacao_recebida` |
| `titulo` | VARCHAR(255) | Título | `Súmula Fechada` |
| `mensagem` | TEXT | Mensagem | `O Scout registrou 2 gols para você` |
| `lida` | BOOLEAN | Já leu? | `false` |
| `enviada_em` | TIMESTAMP | Quando enviou | `2025-01-20 22:30:00` |
| `lida_em` | TIMESTAMP | Quando leu | `NULL` |

**Regras:**
- Notificações são criadas automaticamente por eventos do sistema
- `lida = false` mostra badge de "não lido" no app

---

## 🔗 **PARTE 5: RELACIONAMENTOS ENTRE TABELAS**

### **Diagrama Simplificado:**

```
usuarios (1) ──── (1) atletas
                           │
                           ├─── (N) membros_grupo ──── (N) grupos
                           │                                    │
                           │                                    │
                           ├─── (N) participantes_partida ──── (N) partidas
                           │                                    │
                           │                                    │
                           ├─── (N) desempenho_scout ───────────┘
                           │
                           ├─── (N) avaliacoes (como avaliador)
                           ├─── (N) avaliacoes (como avaliado)
                           ├─── (N) badges
                           └─── (N) atributos_atleta
```

### **Explicação dos Relacionamentos:**

1. **usuarios ↔ atletas**: 1 para 1
   - Um usuário tem UM perfil de atleta
   - Um atleta pertence a UM usuário

2. **atletas ↔ grupos**: N para N (via `membros_grupo`)
   - Um atleta pode estar em VÁRIOS grupos
   - Um grupo tem VÁRIOS atletas

3. **grupos ↔ partidas**: 1 para N
   - Um grupo tem VÁRIAS partidas
   - Uma partida pertence a UM grupo

4. **atletas ↔ partidas**: N para N (via `participantes_partida`)
   - Um atleta pode jogar VÁRIAS partidas
   - Uma partida tem VÁRIOS atletas

5. **partidas ↔ desempenho_scout**: 1 para N
   - Uma partida tem VÁRIOS registros de desempenho (um por jogador)
   - Um desempenho pertence a UMA partida

---

## 🎯 **PARTE 6: REGRAS DE NEGÓCIO IMPLEMENTADAS**

### **1. Unificação de Identidade**
- Um `atleta` tem um `overall_global` que considera TODAS as partidas
- Estatísticas são agregadas de todos os grupos que participa
- Rankings podem ser filtrados por região ou grupo específico

### **2. Cálculo de Rankings (Fase 1)**
```sql
pontos_ranking = (total_gols × 3) + (total_assistencias × 2)
```

### **3. Validação de Consistência (RF08)**
```sql
SOMA(gols em desempenho_scout) = gols_total_noite da partida
```

### **4. Filtro de Contexto (RF04)**
- Interface de súmula só mostra atletas em `participantes_partida`
- Scout pode adicionar durante o evento

### **5. Delegação de Scout (RF06)**
- `id_scout_responsavel`: Scout oficial
- `id_scout_delegado`: Assistente (opcional)

### **6. Notificações (RF07)**
- Quando `status_sumula` muda para `fechada`
- Cria notificação para cada participante com seus gols/assistências

---

## 📈 **PARTE 7: ÍNDICES E OTIMIZAÇÕES**

### **O que são Índices?**
Imagine um índice como o **índice de um livro**. Ao invés de ler página por página para achar "João Silva", você vai direto na página 45. Índices tornam buscas MUITO mais rápidas.

### **Índices Recomendados:**

1. **`atletas.id_usuario`**: Buscar atleta pelo usuário (login)
2. **`membros_grupo(id_grupo, id_atleta)`**: Listar membros de um grupo
3. **`participantes_partida(id_partida, id_atleta)`**: Listar participantes de uma partida
4. **`desempenho_scout(id_partida, id_atleta)`**: Buscar desempenho específico
5. **`partidas(id_grupo, data_evento)`**: Listar partidas de um grupo por data
6. **`atletas.overall_global DESC`**: Para rankings (ordenação rápida)
7. **`atletas.pontos_ranking DESC`**: Para rankings por pontos

---

## 🔒 **PARTE 8: SEGURANÇA E VALIDAÇÕES**

### **Validações de Dados:**

1. **Campos Obrigatórios:**
   - `usuarios`: email OU telefone (pelo menos um)
   - `atletas`: nome_completo, id_usuario
   - `grupos`: nome_grupo, id_scout_adm
   - `partidas`: id_grupo, data_evento

2. **Validações de Formato:**
   - Email válido
   - Telefone no formato correto
   - Datas não podem ser futuras (para partidas)
   - Notas entre 0-10 ou 1-5 (dependendo do contexto)

3. **Validações de Negócio:**
   - Um atleta não pode ter `vitorias + empates + derrotas > 1` na mesma partida
   - Soma de gols deve bater com `gols_total_noite`
   - Scout só pode editar súmula se `status_sumula = 'aberta'`

---

## 🚀 **PARTE 9: EVOLUÇÃO POR FASES**

### **FASE 1 (MVP) - Tabelas Essenciais:**
- ✅ usuarios
- ✅ atletas
- ✅ grupos
- ✅ membros_grupo
- ✅ partidas
- ✅ participantes_partida
- ✅ desempenho_scout

**Campos que podem ficar vazios:**
- `atributos_atleta` (pode ser criada mas não usada ainda)
- `avaliacoes` (criar estrutura mas não usar)
- `badges` (criar estrutura mas não usar)

### **FASE 2 (Social) - Adicionar:**
- ✅ `avaliacoes` (começar a usar)
- ✅ `badges` (começar a calcular)
- ✅ `atributos_atleta` (começar a calcular)

### **FASE 3 (Tecnologia) - Evoluir:**
- ✅ `atributos_atleta` (calcular automaticamente com IA)
- ✅ Adicionar campos para vídeos/replays
- ✅ Adicionar campos para detecção de fraude

---

## 💡 **PARTE 10: DECISÕES TÉCNICAS IMPORTANTES**

### **1. Tipo de ID (UUID vs INT)**
- **UUID**: Identificadores únicos globais (ex: `550e8400-e29b-41d4-a716-446655440000`)
  - ✅ Mais seguro (não revela quantidade de registros)
  - ✅ Único mesmo em múltiplos servidores
  - ❌ Mais espaço (36 caracteres)
  
- **INT**: Números sequenciais (ex: `1, 2, 3...`)
  - ✅ Mais rápido
  - ✅ Menos espaço
  - ❌ Revela quantidade de registros
  - ❌ Pode ter conflitos em múltiplos servidores

**Recomendação para MVP:** Use **INT** (mais simples). Migre para UUID depois se necessário.

### **2. Banco de Dados Recomendado**
- **PostgreSQL**: Melhor para começar
  - ✅ Gratuito
  - ✅ Suporta todos os tipos de dados necessários
  - ✅ Boa performance
  - ✅ Muito usado em produção

- **MySQL**: Alternativa válida
  - ✅ Também gratuito
  - ✅ Muito popular
  - ⚠️ Algumas limitações em tipos de dados

**Recomendação:** **PostgreSQL**

### **3. Timestamps**
- Sempre use `TIMESTAMP` (data + hora)
- `criado_em`: Preenchido automaticamente quando cria
- `atualizado_em`: Atualizado automaticamente quando modifica

---

## 📝 **PARTE 11: CHECKLIST DE IMPLEMENTAÇÃO**

### **Antes de Começar:**
- [ ] Escolher banco de dados (PostgreSQL recomendado)
- [ ] Definir ambiente de desenvolvimento
- [ ] Criar backup strategy

### **Criar Tabelas (Ordem):**
1. [ ] `usuarios`
2. [ ] `atletas` (depende de usuarios)
3. [ ] `grupos` (depende de atletas para scout_adm)
4. [ ] `membros_grupo` (depende de grupos e atletas)
5. [ ] `partidas` (depende de grupos)
6. [ ] `participantes_partida` (depende de partidas e atletas)
7. [ ] `desempenho_scout` (depende de partidas e atletas)
8. [ ] `atributos_atleta` (depende de atletas) - pode ficar vazio na Fase 1
9. [ ] `avaliacoes` (depende de partidas e atletas) - pode ficar vazio na Fase 1
10. [ ] `badges` (depende de atletas) - pode ficar vazio na Fase 1
11. [ ] `notificacoes` (depende de usuarios)

### **Criar Índices:**
- [ ] Todos os índices mencionados na Parte 7

### **Criar Validações:**
- [ ] Constraints de chave estrangeira
- [ ] Constraints de campos obrigatórios
- [ ] Constraints de valores válidos (ENUMs, ranges)

---

## ❓ **PARTE 12: PERGUNTAS FREQUENTES**

### **P: Por que separar `usuarios` e `atletas`?**
**R:** Porque nem todo usuário precisa ser um atleta imediatamente. Além disso, permite que no futuro você tenha outros tipos de usuários (ex: espectadores, organizadores de torneios).

### **P: Por que `membros_grupo` e `participantes_partida` são tabelas separadas?**
**R:** Porque são conceitos diferentes:
- **Membros do grupo**: Pessoas que fazem parte da comunidade (podem não jogar todas as partidas)
- **Participantes da partida**: Quem realmente jogou naquele dia específico

### **P: Como calcular `overall_global`?**
**R:** Na Fase 1, pode ser simplesmente a média de `nota_desempenho`. Na Fase 2+, pode considerar também o `fator_k_dificuldade` do grupo:
```
overall = MÉDIA(nota_desempenho × fator_k_dificuldade)
```

### **P: E se um jogador quiser deletar sua conta?**
**R:** Use `ativo = false` (soft delete). Não delete os dados, pois eles são importantes para rankings e histórico. Mas o jogador não aparecerá mais em buscas.

### **P: Como funciona a "Temporada"?**
**R:** É um campo de texto (ex: `2025-1`, `2025-2`). Você define quando uma temporada começa e termina. Permite resetar rankings ou comparar desempenho entre períodos.

---

## 🎓 **CONCLUSÃO**

Esta arquitetura foi desenhada para:
- ✅ Suportar todas as funcionalidades do PRD
- ✅ Escalar para milhões de registros
- ✅ Ser fácil de entender e manter
- ✅ Evoluir conforme as fases do produto

**Próximos Passos:**
1. Revisar esta documentação com sua equipe técnica
2. Criar scripts SQL para criar as tabelas
3. Implementar validações e constraints
4. Testar com dados de exemplo
5. Começar desenvolvimento do MVP!

---

**Dúvidas?** Esta documentação é viva e pode ser atualizada conforme necessário. 🚀

