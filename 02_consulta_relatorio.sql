/*
Disciplina Business Intelligence
Professor Gustavo Dias
Estudo de Caso 1 - Consultas do relatorio analitico
Executar apos 01_modelo_dimensional.sql
A consulta 1 e a query principal usada no Pentaho Report Designer (JDBC/MySQL)
*/

USE dw_vendas;

-- ---------------------------------------------------------------------
-- 1. CONSULTA PRINCIPAL DO RELATORIO
-- Requisito do estudo: Data da Venda, Produto, Categoria e Valor Total,
-- ordenado por data da venda.
-- ---------------------------------------------------------------------
SELECT
    d.dat_venda            AS data_venda,
    p.nome_produto         AS produto,
    p.categoria_produto    AS categoria,
    f.vlr_total            AS valor_total
FROM f_vendas f
    INNER JOIN d_data    d ON d.id_data    = f.id_data
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
ORDER BY d.dat_venda, p.nome_produto;

-- A versao parametrizada usada de fato no Pentaho esta na secao 8.

-- ---------------------------------------------------------------------
-- 2. INDICADORES GERAIS (cabecalho do relatorio)
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                        AS qtd_vendas,
    SUM(f.qtd_vendida)              AS qtd_itens,
    SUM(f.vlr_total)                AS vlr_faturamento,
    ROUND(AVG(f.vlr_total), 2)      AS vlr_ticket_medio
FROM f_vendas f;

-- ---------------------------------------------------------------------
-- 3. FATURAMENTO POR DIA (serie temporal - grafico de linha)
-- ---------------------------------------------------------------------
SELECT
    d.dat_venda           AS data_venda,
    d.nom_dia_semana      AS dia_semana,
    SUM(f.vlr_total)      AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
GROUP BY d.dat_venda, d.nom_dia_semana
ORDER BY d.dat_venda;

-- ---------------------------------------------------------------------
-- 4. FATURAMENTO POR CATEGORIA (grafico de colunas)
-- ---------------------------------------------------------------------
SELECT
    p.categoria_produto   AS categoria,
    SUM(f.qtd_vendida)    AS qtd_itens,
    SUM(f.vlr_total)      AS vlr_faturamento,
    ROUND(100 * SUM(f.vlr_total) / (SELECT SUM(vlr_total) FROM f_vendas), 1) AS pct_participacao
FROM f_vendas f
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
GROUP BY p.categoria_produto
ORDER BY vlr_faturamento DESC;

-- ---------------------------------------------------------------------
-- 5. TOP 10 PRODUTOS POR FATURAMENTO
-- ---------------------------------------------------------------------
SELECT
    p.nome_produto        AS produto,
    p.categoria_produto   AS categoria,
    SUM(f.qtd_vendida)    AS qtd_itens,
    SUM(f.vlr_total)      AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
GROUP BY p.nome_produto, p.categoria_produto
ORDER BY vlr_faturamento DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 6. DESEMPENHO POR DIA DA SEMANA
-- ---------------------------------------------------------------------
SELECT
    d.nom_dia_semana                 AS dia_semana,
    COUNT(*)                         AS qtd_vendas,
    SUM(f.vlr_total)                 AS vlr_faturamento,
    ROUND(AVG(f.vlr_total), 2)       AS vlr_ticket_medio
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
GROUP BY d.nom_dia_semana
ORDER BY vlr_faturamento DESC;

-- ---------------------------------------------------------------------
-- 7. PRODUTOS DO CATALOGO SEM VENDA NO PERIODO (giro zero)
-- ---------------------------------------------------------------------
SELECT
    p.nome_produto        AS produto,
    p.categoria_produto   AS categoria,
    p.qtd_estoque         AS qtd_estoque
FROM d_produto p
    LEFT JOIN f_vendas f ON f.id_produto = p.id_produto
WHERE f.id_produto IS NULL
ORDER BY p.categoria_produto, p.nome_produto;

-- =====================================================================
-- 8. VERSAO PARAMETRIZADA - QUERIES USADAS NO PENTAHO REPORT DESIGNER
--
-- O relatorio tem tres parametros, todos INTEGER:
--   p_ano  obrigatorio
--   p_mes  0 = todos os meses do ano escolhido
--   p_dia  0 = todos os dias do mes escolhido
-- O valor 0 como "todos" evita tratar NULL em parametro de driver JDBC.
-- No PRD as tres listas de opcoes sao alimentadas pelas queries 8.4 a 8.6,
-- portanto o filtro reflete automaticamente o que existe no DW.
-- Aqui os parametros aparecem como @p_ano/@p_mes/@p_dia para poder testar
-- no cliente MySQL; no PRD a sintaxe e ${p_ano}, ${p_mes} e ${p_dia}.
-- =====================================================================

SET @p_ano = 2025, @p_mes = 9, @p_dia = 0;

-- ---------------------------------------------------------------------
-- 8.1 q_vendas - listagem detalhada (banda Details)
-- ---------------------------------------------------------------------
SELECT
    d.dat_venda            AS data_venda,
    p.nome_produto         AS produto,
    p.categoria_produto    AS categoria,
    f.vlr_total            AS valor_total
FROM f_vendas f
    INNER JOIN d_data    d ON d.id_data    = f.id_data
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
WHERE d.num_ano = @p_ano
  AND (@p_mes = 0 OR d.num_mes = @p_mes)
  AND (@p_dia = 0 OR d.num_dia = @p_dia)
ORDER BY d.dat_venda, p.nome_produto;

-- ---------------------------------------------------------------------
-- 8.2 q_categoria - faturamento por categoria (grafico do subrelatorio)
-- ---------------------------------------------------------------------
SELECT
    p.categoria_produto    AS categoria,
    SUM(f.vlr_total)       AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_data    d ON d.id_data    = f.id_data
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
WHERE d.num_ano = @p_ano
  AND (@p_mes = 0 OR d.num_mes = @p_mes)
  AND (@p_dia = 0 OR d.num_dia = @p_dia)
GROUP BY p.categoria_produto
ORDER BY vlr_faturamento DESC;

-- ---------------------------------------------------------------------
-- 8.3 q_kpi - indicadores do periodo filtrado (cabecalho do relatorio)
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                        AS qtd_vendas,
    SUM(f.qtd_vendida)              AS qtd_itens,
    SUM(f.vlr_total)                AS vlr_faturamento,
    ROUND(AVG(f.vlr_total), 2)      AS vlr_ticket_medio
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
WHERE d.num_ano = @p_ano
  AND (@p_mes = 0 OR d.num_mes = @p_mes)
  AND (@p_dia = 0 OR d.num_dia = @p_dia);

-- ---------------------------------------------------------------------
-- 8.4 q_anos - lista de opcoes do parametro p_ano
-- Value Column = valor / Display Column = rotulo
-- ---------------------------------------------------------------------
SELECT DISTINCT
    num_ano                AS valor,
    num_ano                AS rotulo
FROM d_data
ORDER BY valor DESC;

-- ---------------------------------------------------------------------
-- 8.5 q_meses - lista de opcoes do parametro p_mes (depende de p_ano)
-- ---------------------------------------------------------------------
SELECT 0 AS valor, 'Todos os meses' AS rotulo
UNION ALL
(SELECT DISTINCT num_mes, nom_mes FROM d_data WHERE num_ano = @p_ano)
ORDER BY valor;

-- ---------------------------------------------------------------------
-- 8.6 q_dias - lista de opcoes do parametro p_dia (depende de p_ano/p_mes)
-- ---------------------------------------------------------------------
SELECT 0 AS valor, 'Todos os dias' AS rotulo
UNION ALL
(SELECT DISTINCT num_dia, CAST(num_dia AS CHAR)
   FROM d_data
  WHERE num_ano = @p_ano
    AND (@p_mes = 0 OR num_mes = @p_mes))
ORDER BY valor;
