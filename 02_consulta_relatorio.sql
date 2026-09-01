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

-- Versao parametrizada (parametros ${p_data_ini} e ${p_data_fim} do PRD)
-- WHERE d.dat_venda BETWEEN ${p_data_ini} AND ${p_data_fim}

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
