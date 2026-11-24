-- =====================================================================
-- Distribuidora Vale Sul - validação dos dados no banco (SQLite)
-- Confere, direto no banco, se cada tarefa da limpeza funcionou.
-- Banco: data/processed/vale_sul.db (gerado por src/carga.py)
-- =====================================================================


-- ---------------------------------------------------------------------
-- CLIENTES
-- ---------------------------------------------------------------------

-- Tarefa 1 - CNPJ só com números
-- Esperado: Zero registros

SELECT cnpj
FROM clientes
WHERE cnpj GLOB '*[^0-9]*';

-- Tarefa 2 - Sem espaços sobrando no começo e no fim dos textos
-- Esperado: Zero registros

SELECT cidade, razao_social, nome_fantasia, cnpj, segmento, uf
FROM clientes
WHERE cidade <> TRIM(cidade)
OR razao_social <> TRIM(razao_social)
OR nome_fantasia <> TRIM(nome_fantasia)
OR cnpj <> TRIM(cnpj)
OR segmento <> TRIM(segmento)
OR uf <> TRIM(uf);

-- Tarefa 3 - Cidade padronizada
-- Esperado: Apenas o nome da cidade uma vez, seguindo o mesmo padrão

SELECT cidade FROM clientes
GROUP BY cidade;

-- Tarefa 4 - Segmento padronizado
-- Esperado: Apenas o segmento uma vez, seguindo o mesmo padrão

SELECT segmento FROM clientes
GROUP BY segmento;

-- Tarefa 5 - UF vazia preenchida com "SP"
-- Esperado: Zero registros

SELECT * FROM clientes
WHERE uf IS NULL;

-- Tarefa 6 - Segmento e vendedor vazios mantidos vazios
-- 6a - Clientes sem segmento
-- Esperado: 14

SELECT COUNT(*) AS qtd
FROM clientes
WHERE segmento IS NULL;

-- 6b - Clientes sem vendedor
-- Esperado: 9

SELECT COUNT(*) AS qtd
FROM clientes
WHERE vendedor_id IS NULL;

-- Tarefa 7 - Clientes unificados pelo CNPJ
-- 7a - Nenhum CNPJ repetido na tabela de clientes
-- Esperado: Zero registros

SELECT cnpj, COUNT(*) AS qtd
FROM clientes
GROUP BY cnpj
HAVING COUNT(*) > 1;

-- 7b - Nenhum pedido apontando para um cliente_id que não existe mais em clientes
-- Esperado: Zero registros

SELECT pedido_id
FROM pedidos
WHERE cliente_id NOT IN (SELECT cliente_id FROM clientes);

-- 7c - Nenhum título apontando para um cliente_id que não existe mais em clientes
-- Esperado: Zero registros

SELECT titulo_id
FROM titulos_receber
WHERE cliente_id NOT IN (SELECT cliente_id FROM clientes);

-- ---------------------------------------------------------------------
-- PEDIDOS
-- ---------------------------------------------------------------------

-- Tarefa 8 - Ano 2052 corrigido para 2025
-- Esperado: Zero registros

SELECT data_pedido
FROM pedidos
WHERE strftime('%Y', data_pedido) = '2052';

-- ---------------------------------------------------------------------
-- PRODUTOS
-- ---------------------------------------------------------------------

-- Tarefa 9 - Produtos sem categoria
-- Esperado: Nenhum Registro

SELECT *
FROM produtos
WHERE categoria IS NULL;

-- Tarefa 10 - Custo dos produtos 37, 40, 134 e 216
-- Esperado: Zero registros

SELECT produto_id, custo_unitario, preco_venda
FROM produtos
WHERE custo_unitario > preco_venda;

-- Tarefa 11 - Produtos 901, 902 e 903 com categoria "Desconhecido"
-- Esperado: Os produtos, 901, 902 e 903

SELECT produto_id
FROM produtos
WHERE categoria = 'Desconhecido';

-- Tarefa 12 - Ativo como 1/0
-- Esperado: apenas 1 e 0

SELECT ativo
FROM produtos
GROUP BY ativo;

-- ---------------------------------------------------------------------
-- ITENS DO PEDIDO
-- ---------------------------------------------------------------------

-- Tarefa 13 - Quantidade digitada 100 vezes maior
-- Esperado: Zero registros

SELECT item_id, quantidade, preco_unitario, valor_total_item
FROM itens_pedido
WHERE ABS(quantidade * preco_unitario - valor_total_item) > 0.01;

-- ---------------------------------------------------------------------
-- PAGAMENTOS
-- ---------------------------------------------------------------------

-- Tarefa 14 - Data de pagamento num formato só (AAAA-MM-DD)
-- Esperado: Zero registros

SELECT pagamento_id, data_pagamento
FROM pagamentos
WHERE data_pagamento NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
OR data_pagamento IS NULL;

-- Tarefa 15 - Pagamentos duplicados
-- Esperado: Zero registros

SELECT pagamento_id, COUNT(*) AS qtd
FROM pagamentos
GROUP BY pagamento_id
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- TÍTULOS A RECEBER
-- ---------------------------------------------------------------------

-- Tarefa 16 - Status recalculado pelos pagamentos
-- Esperado: Zero registros

SELECT t.titulo_id, COALESCE(SUM(p.valor_pago), 0) AS total_pago, t.status, t.valor
FROM titulos_receber t
LEFT JOIN pagamentos p ON p.titulo_id = t.titulo_id
GROUP BY t.titulo_id, t.status, t.valor
HAVING (t.status = 'PAGO' AND total_pago < t.valor - 0.01)
    OR (t.status = 'ABERTO' AND total_pago > 0)
    OR (t.status = 'PARCIAL' AND (total_pago = 0 OR total_pago >= t.valor - 0.01));

-- Tarefa 17 - Títulos de pedidos cancelados
-- 17a - Nenhum título de pedido cancelado com status diferente de CANCELADO
-- Esperado: Zero registros

SELECT titulo_id, pedido_id, status
FROM titulos_receber
WHERE pedido_id IN (SELECT pedido_id FROM pedidos WHERE status = 'CANCELADO')
AND status <> 'CANCELADO';

-- 17b - Quantidade de títulos cancelados
-- Esperado: 15

SELECT COUNT(*) AS qtd
FROM titulos_receber
WHERE status = 'CANCELADO';

-- ---------------------------------------------------------------------
-- BANCO 
-- ---------------------------------------------------------------------

-- Tarefa 18 - Regras das tabelas respeitadas
-- Lista as linhas que apontam para um registro que não existe (todas as ligações)
-- Esperado: Zero registros

PRAGMA foreign_key_check;