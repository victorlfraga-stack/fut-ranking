-- =====================================================
-- SCRIPTS SQL - SAAS PELADEIROS
-- Banco de Dados: PostgreSQL
-- =====================================================
-- Este arquivo contém os scripts SQL para criar todas
-- as tabelas do banco de dados do SaaS Peladeiros.
-- 
-- INSTRUÇÕES:
-- 1. Execute os scripts na ordem apresentada
-- 2. Ajuste os tipos de dados conforme necessário
-- 3. Teste com dados de exemplo antes de produção
-- =====================================================

-- =====================================================
-- 1. CRIAÇÃO DAS TABELAS
-- =====================================================

-- -----------------------------------------------------
-- 1.1. TABELA: usuarios
-- -----------------------------------------------------
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    telefone VARCHAR(20) UNIQUE,
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('google', 'telefone')),
    provider_id VARCHAR(255),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_email_ou_telefone CHECK (
        email IS NOT NULL OR telefone IS NOT NULL
    )
);

-- Comentários para documentação
COMMENT ON TABLE usuarios IS 'Tabela de autenticação de usuários do sistema';
COMMENT ON COLUMN usuarios.provider IS 'Método de autenticação: google ou telefone';
COMMENT ON COLUMN usuarios.ativo IS 'FALSE = conta desativada (soft delete)';

-- -----------------------------------------------------
-- 1.2. TABELA: atletas
-- -----------------------------------------------------
CREATE TABLE atletas (
    id_atleta SERIAL PRIMARY KEY,
    id_usuario INTEGER UNIQUE NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    nome_completo VARCHAR(255) NOT NULL,
    apelido VARCHAR(100),
    foto_url VARCHAR(500),
    ra_principal VARCHAR(100),
    posicao_preferencial VARCHAR(50) CHECK (posicao_preferencial IN ('Goleiro', 'Zagueiro', 'Meia', 'Atacante')),
    overall_global DECIMAL(5,2) DEFAULT 0.00 CHECK (overall_global >= 0 AND overall_global <= 100),
    pontos_ranking INTEGER DEFAULT 0,
    total_gols INTEGER DEFAULT 0,
    total_assistencias INTEGER DEFAULT 0,
    total_vitorias INTEGER DEFAULT 0,
    total_empates INTEGER DEFAULT 0,
    total_derrotas INTEGER DEFAULT 0,
    partidas_jogadas INTEGER DEFAULT 0,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE atletas IS 'Perfil esportivo do jogador - Identidade Unificada';
COMMENT ON COLUMN atletas.overall_global IS 'Nota geral calculada (0-100)';
COMMENT ON COLUMN atletas.pontos_ranking IS 'Pontos = (gols × 3) + (assistencias × 2)';

-- -----------------------------------------------------
-- 1.3. TABELA: atributos_atleta
-- -----------------------------------------------------
CREATE TABLE atributos_atleta (
    id_atributo SERIAL PRIMARY KEY,
    id_atleta INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    ritmo INTEGER CHECK (ritmo >= 0 AND ritmo <= 100),
    chute INTEGER CHECK (chute >= 0 AND chute <= 100),
    passe INTEGER CHECK (passe >= 0 AND passe <= 100),
    defesa INTEGER CHECK (defesa >= 0 AND defesa <= 100),
    fisico INTEGER CHECK (fisico >= 0 AND fisico <= 100),
    temporada VARCHAR(50),
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_atleta_temporada UNIQUE (id_atleta, temporada)
);

COMMENT ON TABLE atributos_atleta IS 'Atributos do FIFA Card por temporada';
COMMENT ON COLUMN atributos_atleta.temporada IS 'Formato: 2025-1, 2025-2, etc.';

-- -----------------------------------------------------
-- 1.4. TABELA: grupos
-- -----------------------------------------------------
CREATE TABLE grupos (
    id_grupo SERIAL PRIMARY KEY,
    nome_grupo VARCHAR(255) NOT NULL,
    descricao TEXT,
    id_scout_adm INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE RESTRICT,
    localizacao_ra VARCHAR(100),
    endereco VARCHAR(500),
    fator_k_dificuldade DECIMAL(3,2) DEFAULT 3.0 CHECK (fator_k_dificuldade >= 1.0 AND fator_k_dificuldade <= 5.0),
    nivel_pelada VARCHAR(50) CHECK (nivel_pelada IN ('competitivo', 'resenha', 'misto')),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE grupos IS 'Comunidade fixa de pelada (ex: Pelada da AABB)';
COMMENT ON COLUMN grupos.fator_k_dificuldade IS '1.0=muito fácil, 3.0=médio, 5.0=muito difícil';
COMMENT ON COLUMN grupos.id_scout_adm IS 'Scout principal/autoridade do grupo';

-- -----------------------------------------------------
-- 1.5. TABELA: membros_grupo
-- -----------------------------------------------------
CREATE TABLE membros_grupo (
    id_membro SERIAL PRIMARY KEY,
    id_grupo INTEGER NOT NULL REFERENCES grupos(id_grupo) ON DELETE CASCADE,
    id_atleta INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    tipo_membro VARCHAR(50) CHECK (tipo_membro IN ('fixo', 'mensalista', 'avulso')),
    ativo BOOLEAN DEFAULT TRUE,
    entrou_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    saiu_em TIMESTAMP,
    CONSTRAINT unique_membro_grupo UNIQUE (id_grupo, id_atleta)
);

COMMENT ON TABLE membros_grupo IS 'Relacionamento N:N entre atletas e grupos';
COMMENT ON COLUMN membros_grupo.ativo IS 'FALSE = saiu do grupo (mas histórico permanece)';

-- -----------------------------------------------------
-- 1.6. TABELA: partidas
-- -----------------------------------------------------
CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    id_grupo INTEGER NOT NULL REFERENCES grupos(id_grupo) ON DELETE CASCADE,
    data_evento DATE NOT NULL,
    hora_inicio TIME,
    hora_fim TIME,
    gols_total_noite INTEGER DEFAULT 0 CHECK (gols_total_noite >= 0),
    status_sumula VARCHAR(50) DEFAULT 'aberta' CHECK (status_sumula IN ('aberta', 'fechada', 'revisao_pendente')),
    id_scout_responsavel INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE RESTRICT,
    id_scout_delegado INTEGER REFERENCES atletas(id_atleta) ON DELETE SET NULL,
    temporada VARCHAR(50),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fechado_em TIMESTAMP
);

COMMENT ON TABLE partidas IS 'Evento/jogo específico de uma noite';
COMMENT ON COLUMN partidas.gols_total_noite IS 'Soma total para validação RF08';
COMMENT ON COLUMN partidas.status_sumula IS 'aberta=editável, fechada=finalizada, revisao_pendente=contestada';
COMMENT ON COLUMN partidas.id_scout_delegado IS 'Assistente (RF06) - opcional';

-- -----------------------------------------------------
-- 1.7. TABELA: participantes_partida
-- -----------------------------------------------------
CREATE TABLE participantes_partida (
    id_participante SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL REFERENCES partidas(id_partida) ON DELETE CASCADE,
    id_atleta INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    confirmado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    compareceu BOOLEAN DEFAULT TRUE,
    CONSTRAINT unique_participante_partida UNIQUE (id_partida, id_atleta)
);

COMMENT ON TABLE participantes_partida IS 'Check-in/Presença - Lista de quem jogou';
COMMENT ON COLUMN participantes_partida.compareceu IS 'FALSE = confirmou mas não foi';

-- -----------------------------------------------------
-- 1.8. TABELA: desempenho_scout
-- -----------------------------------------------------
CREATE TABLE desempenho_scout (
    id_scout SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL REFERENCES partidas(id_partida) ON DELETE CASCADE,
    id_atleta INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    gols INTEGER DEFAULT 0 CHECK (gols >= 0),
    assistencias INTEGER DEFAULT 0 CHECK (assistencias >= 0),
    vitorias INTEGER DEFAULT 0 CHECK (vitorias IN (0, 1)),
    empates INTEGER DEFAULT 0 CHECK (empates IN (0, 1)),
    derrotas INTEGER DEFAULT 0 CHECK (derrotas IN (0, 1)),
    nota_desempenho DECIMAL(3,2) CHECK (nota_desempenho >= 0 AND nota_desempenho <= 10),
    pontos_partida INTEGER DEFAULT 0,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_desempenho_partida_atleta UNIQUE (id_partida, id_atleta),
    CONSTRAINT check_resultado_unico CHECK (vitorias + empates + derrotas <= 1)
);

COMMENT ON TABLE desempenho_scout IS 'A Súmula - Estatísticas de cada jogador por partida';
COMMENT ON COLUMN desempenho_scout.pontos_partida IS 'Calculado: (gols × 3) + (assistencias × 2)';
COMMENT ON COLUMN desempenho_scout.nota_desempenho IS 'Nota do Scout (0-10) - opcional na Fase 1';

-- -----------------------------------------------------
-- 1.9. TABELA: avaliacoes
-- -----------------------------------------------------
CREATE TABLE avaliacoes (
    id_avaliacao SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL REFERENCES partidas(id_partida) ON DELETE CASCADE,
    id_avaliador INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    id_avaliado INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    nota INTEGER NOT NULL CHECK (nota >= 1 AND nota <= 5),
    comentario TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_nao_auto_avaliacao CHECK (id_avaliador != id_avaliado),
    CONSTRAINT unique_avaliacao UNIQUE (id_partida, id_avaliador, id_avaliado)
);

COMMENT ON TABLE avaliacoes IS 'Notas que jogadores dão uns para os outros (RF05 - Fase 2)';
COMMENT ON COLUMN avaliacoes.nota IS 'Nota de 1 a 5';

-- -----------------------------------------------------
-- 1.10. TABELA: badges
-- -----------------------------------------------------
CREATE TABLE badges (
    id_badge SERIAL PRIMARY KEY,
    id_atleta INTEGER NOT NULL REFERENCES atletas(id_atleta) ON DELETE CASCADE,
    tipo_badge VARCHAR(100) NOT NULL,
    regiao VARCHAR(100),
    temporada VARCHAR(50),
    conquistado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_badge UNIQUE (id_atleta, tipo_badge, regiao, temporada)
);

COMMENT ON TABLE badges IS 'Conquistas/Badges dos jogadores (Fase 2)';
COMMENT ON COLUMN badges.tipo_badge IS 'Ex: artilheiro_ra, muralha, assistente';

-- -----------------------------------------------------
-- 1.11. TABELA: notificacoes
-- -----------------------------------------------------
CREATE TABLE notificacoes (
    id_notificacao SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensagem TEXT NOT NULL,
    lida BOOLEAN DEFAULT FALSE,
    enviada_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lida_em TIMESTAMP
);

COMMENT ON TABLE notificacoes IS 'Notificações push para usuários (RF07)';
COMMENT ON COLUMN notificacoes.tipo IS 'Ex: sumula_fechada, avaliacao_recebida';

-- =====================================================
-- 2. CRIAÇÃO DE ÍNDICES (Para Performance)
-- =====================================================

-- Índices para buscas frequentes
CREATE INDEX idx_atletas_id_usuario ON atletas(id_usuario);
CREATE INDEX idx_atletas_overall_global ON atletas(overall_global DESC);
CREATE INDEX idx_atletas_pontos_ranking ON atletas(pontos_ranking DESC);
CREATE INDEX idx_atletas_ra_principal ON atletas(ra_principal);

CREATE INDEX idx_membros_grupo_id_grupo ON membros_grupo(id_grupo);
CREATE INDEX idx_membros_grupo_id_atleta ON membros_grupo(id_atleta);
CREATE INDEX idx_membros_grupo_ativo ON membros_grupo(ativo) WHERE ativo = TRUE;

CREATE INDEX idx_partidas_id_grupo ON partidas(id_grupo);
CREATE INDEX idx_partidas_data_evento ON partidas(data_evento DESC);
CREATE INDEX idx_partidas_status ON partidas(status_sumula);
CREATE INDEX idx_partidas_temporada ON partidas(temporada);

CREATE INDEX idx_participantes_partida_id_partida ON participantes_partida(id_partida);
CREATE INDEX idx_participantes_partida_id_atleta ON participantes_partida(id_atleta);

CREATE INDEX idx_desempenho_scout_id_partida ON desempenho_scout(id_partida);
CREATE INDEX idx_desempenho_scout_id_atleta ON desempenho_scout(id_atleta);
CREATE INDEX idx_desempenho_scout_pontos ON desempenho_scout(pontos_partida DESC);

CREATE INDEX idx_avaliacoes_id_partida ON avaliacoes(id_partida);
CREATE INDEX idx_avaliacoes_id_avaliado ON avaliacoes(id_avaliado);
CREATE INDEX idx_avaliacoes_id_avaliador ON avaliacoes(id_avaliador);

CREATE INDEX idx_badges_id_atleta ON badges(id_atleta);
CREATE INDEX idx_badges_tipo ON badges(tipo_badge);

CREATE INDEX idx_notificacoes_id_usuario ON notificacoes(id_usuario);
CREATE INDEX idx_notificacoes_lida ON notificacoes(lida) WHERE lida = FALSE;

-- =====================================================
-- 3. FUNÇÕES E TRIGGERS (Automações)
-- =====================================================

-- -----------------------------------------------------
-- 3.1. Função para atualizar timestamp automaticamente
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em tabelas que têm atualizado_em
CREATE TRIGGER trigger_atualizar_usuarios
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_atletas
    BEFORE UPDATE ON atletas
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_grupos
    BEFORE UPDATE ON grupos
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_desempenho_scout
    BEFORE UPDATE ON desempenho_scout
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

-- -----------------------------------------------------
-- 3.2. Função para calcular pontos_partida automaticamente
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION calcular_pontos_partida()
RETURNS TRIGGER AS $$
BEGIN
    NEW.pontos_partida = (NEW.gols * 3) + (NEW.assistencias * 2);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_pontos_partida
    BEFORE INSERT OR UPDATE ON desempenho_scout
    FOR EACH ROW
    EXECUTE FUNCTION calcular_pontos_partida();

-- -----------------------------------------------------
-- 3.3. Função para atualizar estatísticas do atleta
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION atualizar_estatisticas_atleta()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar estatísticas agregadas do atleta
    UPDATE atletas SET
        total_gols = (
            SELECT COALESCE(SUM(gols), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        total_assistencias = (
            SELECT COALESCE(SUM(assistencias), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        total_vitorias = (
            SELECT COALESCE(SUM(vitorias), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        total_empates = (
            SELECT COALESCE(SUM(empates), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        total_derrotas = (
            SELECT COALESCE(SUM(derrotas), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        partidas_jogadas = (
            SELECT COUNT(DISTINCT id_partida)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        pontos_ranking = (
            SELECT COALESCE(SUM(pontos_partida), 0)
            FROM desempenho_scout
            WHERE id_atleta = NEW.id_atleta
        ),
        atualizado_em = CURRENT_TIMESTAMP
    WHERE id_atleta = NEW.id_atleta;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_estatisticas_atleta
    AFTER INSERT OR UPDATE OR DELETE ON desempenho_scout
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_estatisticas_atleta();

-- -----------------------------------------------------
-- 3.4. Função para validar gols_total_noite (RF08)
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION validar_gols_total_noite()
RETURNS TRIGGER AS $$
DECLARE
    soma_gols INTEGER;
BEGIN
    -- Calcular soma de gols dos participantes
    SELECT COALESCE(SUM(gols), 0) INTO soma_gols
    FROM desempenho_scout
    WHERE id_partida = NEW.id_partida;
    
    -- Validar se bate com gols_total_noite
    IF NEW.status_sumula = 'fechada' AND soma_gols != NEW.gols_total_noite THEN
        RAISE EXCEPTION 'Inconsistência: Soma de gols (%) não confere com gols_total_noite (%)', 
            soma_gols, NEW.gols_total_noite;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_gols_total_noite
    BEFORE UPDATE ON partidas
    FOR EACH ROW
    WHEN (NEW.status_sumula = 'fechada')
    EXECUTE FUNCTION validar_gols_total_noite();

-- =====================================================
-- 4. VIEWS ÚTEIS (Consultas Pré-definidas)
-- =====================================================

-- -----------------------------------------------------
-- 4.1. View: Ranking Global de Atletas
-- -----------------------------------------------------
CREATE OR REPLACE VIEW vw_ranking_global AS
SELECT 
    a.id_atleta,
    a.nome_completo,
    a.apelido,
    a.foto_url,
    a.ra_principal,
    a.overall_global,
    a.pontos_ranking,
    a.total_gols,
    a.total_assistencias,
    a.total_vitorias,
    a.total_empates,
    a.total_derrotas,
    a.partidas_jogadas,
    CASE 
        WHEN a.partidas_jogadas > 0 
        THEN ROUND((a.total_vitorias::DECIMAL / a.partidas_jogadas) * 100, 2)
        ELSE 0 
    END AS taxa_vitorias
FROM atletas a
WHERE a.partidas_jogadas > 0
ORDER BY a.pontos_ranking DESC, a.overall_global DESC;

-- -----------------------------------------------------
-- 4.2. View: Ranking por Grupo
-- -----------------------------------------------------
CREATE OR REPLACE VIEW vw_ranking_grupo AS
SELECT 
    g.id_grupo,
    g.nome_grupo,
    a.id_atleta,
    a.nome_completo,
    a.foto_url,
    COALESCE(SUM(ds.pontos_partida), 0) AS pontos_grupo,
    COALESCE(SUM(ds.gols), 0) AS gols_grupo,
    COALESCE(SUM(ds.assistencias), 0) AS assistencias_grupo,
    COUNT(DISTINCT ds.id_partida) AS partidas_jogadas_grupo
FROM grupos g
INNER JOIN membros_grupo mg ON g.id_grupo = mg.id_grupo AND mg.ativo = TRUE
INNER JOIN atletas a ON mg.id_atleta = a.id_atleta
LEFT JOIN partidas p ON g.id_grupo = p.id_grupo AND p.status_sumula = 'fechada'
LEFT JOIN desempenho_scout ds ON p.id_partida = ds.id_partida AND a.id_atleta = ds.id_atleta
GROUP BY g.id_grupo, g.nome_grupo, a.id_atleta, a.nome_completo, a.foto_url
ORDER BY g.id_grupo, pontos_grupo DESC;

-- -----------------------------------------------------
-- 4.3. View: Estatísticas por Região (RA)
-- -----------------------------------------------------
CREATE OR REPLACE VIEW vw_ranking_por_ra AS
SELECT 
    a.ra_principal,
    COUNT(DISTINCT a.id_atleta) AS total_atletas,
    AVG(a.overall_global) AS media_overall,
    SUM(a.total_gols) AS total_gols_ra,
    SUM(a.total_assistencias) AS total_assistencias_ra,
    SUM(a.partidas_jogadas) AS total_partidas_ra
FROM atletas a
WHERE a.ra_principal IS NOT NULL
GROUP BY a.ra_principal
ORDER BY media_overall DESC;

-- =====================================================
-- 5. DADOS DE EXEMPLO (Para Testes)
-- =====================================================

-- Inserir usuários de exemplo
INSERT INTO usuarios (email, telefone, provider, provider_id) VALUES
('joao@email.com', '+5561999999999', 'google', 'google_123'),
('maria@email.com', '+5561888888888', 'telefone', 'telefone_456'),
('pedro@email.com', NULL, 'google', 'google_789');

-- Inserir atletas de exemplo
INSERT INTO atletas (id_usuario, nome_completo, apelido, ra_principal, posicao_preferencial) VALUES
(1, 'João Silva', 'Joãozinho', 'Asa Sul', 'Atacante'),
(2, 'Maria Santos', 'Mari', 'Noroeste', 'Meia'),
(3, 'Pedro Costa', 'Pedrão', 'Asa Sul', 'Goleiro');

-- Inserir grupo de exemplo
INSERT INTO grupos (nome_grupo, id_scout_adm, localizacao_ra, fator_k_dificuldade, nivel_pelada) VALUES
('Pelada da AABB', 1, 'Asa Sul', 3.5, 'competitivo');

-- Inserir membros do grupo
INSERT INTO membros_grupo (id_grupo, id_atleta, tipo_membro) VALUES
(1, 1, 'fixo'),
(1, 2, 'fixo'),
(1, 3, 'fixo');

-- Inserir partida de exemplo
INSERT INTO partidas (id_grupo, data_evento, hora_inicio, hora_fim, gols_total_noite, id_scout_responsavel, temporada) VALUES
(1, '2025-01-20', '20:00:00', '22:00:00', 8, 1, '2025-1');

-- Inserir participantes da partida
INSERT INTO participantes_partida (id_partida, id_atleta) VALUES
(1, 1),
(1, 2),
(1, 3);

-- Inserir desempenho dos jogadores
INSERT INTO desempenho_scout (id_partida, id_atleta, gols, assistencias, vitorias, nota_desempenho) VALUES
(1, 1, 2, 1, 1, 8.5),
(1, 2, 1, 2, 1, 7.5),
(1, 3, 0, 0, 0, 6.5);

-- =====================================================
-- 6. CONSULTAS ÚTEIS (Queries de Exemplo)
-- =====================================================

-- Consulta 1: Listar todos os atletas de um grupo
-- SELECT a.nome_completo, a.apelido, mg.tipo_membro
-- FROM membros_grupo mg
-- INNER JOIN atletas a ON mg.id_atleta = a.id_atleta
-- WHERE mg.id_grupo = 1 AND mg.ativo = TRUE;

-- Consulta 2: Listar partidas de um grupo ordenadas por data
-- SELECT p.id_partida, p.data_evento, p.status_sumula, COUNT(pp.id_participante) AS total_participantes
-- FROM partidas p
-- LEFT JOIN participantes_partida pp ON p.id_partida = pp.id_partida
-- WHERE p.id_grupo = 1
-- GROUP BY p.id_partida, p.data_evento, p.status_sumula
-- ORDER BY p.data_evento DESC;

-- Consulta 3: Ver desempenho de um atleta em todas as partidas
-- SELECT 
--     p.data_evento,
--     g.nome_grupo,
--     ds.gols,
--     ds.assistencias,
--     ds.pontos_partida,
--     ds.nota_desempenho
-- FROM desempenho_scout ds
-- INNER JOIN partidas p ON ds.id_partida = p.id_partida
-- INNER JOIN grupos g ON p.id_grupo = g.id_grupo
-- WHERE ds.id_atleta = 1
-- ORDER BY p.data_evento DESC;

-- Consulta 4: Ranking de um grupo específico
-- SELECT * FROM vw_ranking_grupo WHERE id_grupo = 1 ORDER BY pontos_grupo DESC;

-- Consulta 5: Validar consistência de gols de uma partida
-- SELECT 
--     p.id_partida,
--     p.gols_total_noite,
--     COALESCE(SUM(ds.gols), 0) AS soma_gols_registrados,
--     CASE 
--         WHEN p.gols_total_noite = COALESCE(SUM(ds.gols), 0) THEN 'OK'
--         ELSE 'INCONSISTENTE'
--     END AS status_validacao
-- FROM partidas p
-- LEFT JOIN desempenho_scout ds ON p.id_partida = ds.id_partida
-- WHERE p.id_partida = 1
-- GROUP BY p.id_partida, p.gols_total_noite;

-- =====================================================
-- FIM DOS SCRIPTS
-- =====================================================

