-- =====================================================================
-- Distribuidora Vale Sul - criação das tabelas (SQLite)
-- Tradução do modelo em docs/modelo_dados.dbml
--   enum        -> CHECK (coluna IN (...))
--   ref         -> FOREIGN KEY ... REFERENCES ...
--   boolean     -> INTEGER (1 = verdadeiro, 0 = falso)
-- Ordem: primeiro as tabelas que não apontam para ninguém.
-- =====================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS pagamentos;
DROP TABLE IF EXISTS titulos_receber;
DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS vendedores;

CREATE TABLE vendedores (
    vendedor_id        INTEGER PRIMARY KEY,
    nome               VARCHAR(100) NOT NULL,
    canal              VARCHAR(20)  NOT NULL CHECK (canal IN ('EXTERNO', 'TELEVENDAS')),
    data_admissao      DATE         NOT NULL,
    data_desligamento  DATE,
    regiao             VARCHAR(100) NOT NULL
);

CREATE TABLE clientes (
    cliente_id      INTEGER PRIMARY KEY,
    razao_social    VARCHAR(100)  NOT NULL,
    nome_fantasia   VARCHAR(100),
    cnpj            VARCHAR(14)   NOT NULL UNIQUE,
    segmento        VARCHAR(40),
    cidade          VARCHAR(40)   NOT NULL,
    uf              VARCHAR(2)    NOT NULL,
    vendedor_id     INTEGER,
    data_cadastro   DATE          NOT NULL,
    limite_credito  DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (vendedor_id) REFERENCES vendedores (vendedor_id)
);

CREATE TABLE produtos (
    produto_id      INTEGER PRIMARY KEY,
    sku             VARCHAR(7)    NOT NULL UNIQUE,
    descricao       VARCHAR(100)  NOT NULL,
    categoria       VARCHAR(40)   NOT NULL CHECK (categoria IN (
                        'Bebidas', 'Mercearia', 'Frios e Laticínios',
                        'Limpeza e Descartáveis', 'Desconhecido')),
    marca           VARCHAR(40)   NOT NULL,
    unidade         VARCHAR(10)   NOT NULL,
    custo_unitario  DECIMAL(12,2) NOT NULL,
    preco_venda     DECIMAL(12,2) NOT NULL,
    ativo           INTEGER       NOT NULL CHECK (ativo IN (0, 1))
);

CREATE TABLE pedidos (
    pedido_id           INTEGER PRIMARY KEY,
    cliente_id          INTEGER       NOT NULL,
    vendedor_id         INTEGER       NOT NULL,
    canal               VARCHAR(20)   NOT NULL CHECK (canal IN ('EXTERNO', 'TELEVENDAS')),
    data_pedido         DATE          NOT NULL,
    data_faturamento    DATE,
    status              VARCHAR(20)   NOT NULL CHECK (status IN ('FATURADO', 'CANCELADO')),
    condicao_pagamento  VARCHAR(20)   NOT NULL CHECK (condicao_pagamento IN (
                            'PIX A VISTA', 'BOLETO 7 DIAS', 'BOLETO 14 DIAS',
                            'BOLETO 28 DIAS', 'BOLETO 35 DIAS')),
    valor_produtos      DECIMAL(12,2) NOT NULL,
    valor_desconto      DECIMAL(12,2) NOT NULL,
    valor_total         DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (cliente_id)  REFERENCES clientes (cliente_id),
    FOREIGN KEY (vendedor_id) REFERENCES vendedores (vendedor_id)
);

CREATE TABLE itens_pedido (
    item_id           INTEGER PRIMARY KEY,
    pedido_id         INTEGER       NOT NULL,
    produto_id        INTEGER       NOT NULL,
    quantidade        INTEGER       NOT NULL,
    preco_unitario    DECIMAL(12,2) NOT NULL,
    custo_unitario    DECIMAL(12,2) NOT NULL,
    valor_total_item  DECIMAL(12,2) NOT NULL,
    qtd_devolvida     INTEGER       NOT NULL,
    data_devolucao    DATE,
    FOREIGN KEY (pedido_id)  REFERENCES pedidos (pedido_id),
    FOREIGN KEY (produto_id) REFERENCES produtos (produto_id)
);

CREATE TABLE titulos_receber (
    titulo_id        INTEGER PRIMARY KEY,
    pedido_id        INTEGER       NOT NULL,
    cliente_id       INTEGER       NOT NULL,
    data_emissao     DATE          NOT NULL,
    data_vencimento  DATE          NOT NULL,
    valor            DECIMAL(12,2) NOT NULL,
    status           VARCHAR(20)   NOT NULL CHECK (status IN ('PAGO', 'ABERTO', 'PARCIAL', 'CANCELADO')),
    FOREIGN KEY (pedido_id)  REFERENCES pedidos (pedido_id),
    FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id)
);

CREATE TABLE pagamentos (
    pagamento_id     INTEGER PRIMARY KEY,
    titulo_id        INTEGER       NOT NULL,
    data_pagamento   DATE          NOT NULL,
    valor_pago       DECIMAL(12,2) NOT NULL,
    valor_juros      DECIMAL(12,2) NOT NULL,
    forma_pagamento  VARCHAR(25)   NOT NULL CHECK (forma_pagamento IN ('PIX', 'BOLETO', 'ABATIMENTO DEVOLUCAO')),
    FOREIGN KEY (titulo_id) REFERENCES titulos_receber (titulo_id)
);
