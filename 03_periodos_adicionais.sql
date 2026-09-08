/*
Disciplina Business Intelligence
Professor Gustavo Dias
Estudo de Caso 1 - Vendas em Loja de Varejo

AMPLIACAO DO PERIODO DO DW (janeiro a agosto de 2025)

Motivo: o relatorio no Pentaho Report Designer passou a ter filtro de periodo
(ano / mes / dia). Com apenas setembro/2025 no DW o filtro nao tinha o que
filtrar. Este script acrescenta os 8 meses anteriores.

Os 30 dias e os 197 registros de setembro/2025 carregados pelo script 01 NAO
sao alterados: os id_venda gerados aqui comecam em 1000. Portanto o total de
setembro continua sendo 4.429,46, como consta no relatorio e na documentacao.

A carga e deterministica (nao usa RAND): rodar o script duas vezes no mesmo
banco recriado produz exatamente os mesmos numeros, o que mantem a
documentacao verificavel.

Pre-requisito: script 01_modelo_dimensional.sql ja executado.
Execucao: mysql -h 127.0.0.1 -P 3307 -u root < 03_periodos_adicionais.sql
*/

USE dw_vendas;

-- ---------------------------------------------------------------------
-- 1. DIMENSAO DATA - 2025-01-01 a 2025-08-31 (243 dias)
-- ---------------------------------------------------------------------
INSERT INTO d_data
    (id_data, dat_venda, num_dia, num_mes, nom_mes, num_trimestre, num_ano, nom_dia_semana)
WITH RECURSIVE calendario (dat_venda) AS (
    SELECT DATE '2025-01-01'
    UNION ALL
    SELECT dat_venda + INTERVAL 1 DAY FROM calendario WHERE dat_venda < DATE '2025-08-31'
)
SELECT
    CAST(DATE_FORMAT(dat_venda, '%Y%m%d') AS UNSIGNED)              AS id_data,
    dat_venda,
    DAY(dat_venda)                                                  AS num_dia,
    MONTH(dat_venda)                                                AS num_mes,
    ELT(MONTH(dat_venda), 'Janeiro', 'Fevereiro', 'Marco', 'Abril',
        'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro',
        'Novembro', 'Dezembro')                                     AS nom_mes,
    QUARTER(dat_venda)                                              AS num_trimestre,
    YEAR(dat_venda)                                                 AS num_ano,
    ELT(DAYOFWEEK(dat_venda), 'Domingo', 'Segunda-feira', 'Terca-feira',
        'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sabado')    AS nom_dia_semana
FROM calendario;

-- ---------------------------------------------------------------------
-- 2. TABELA FATO - vendas dos 8 meses acrescentados
--
-- Grao mantido: 1 linha por produto vendido em um dia.
-- Regras da geracao deterministica:
--   qtd de vendas no dia = 4 a 9, em funcao do dia do ano
--   produto              = derivado do dia do ano e da sequencia
--   qtd_vendida          = 1 a 5
--   vlr_unitario         = d_produto.vlr_uni (integridade preco x catalogo)
--   vlr_total            = qtd_vendida * vlr_unitario
-- ---------------------------------------------------------------------
INSERT INTO f_vendas
    (id_venda, id_data, id_produto, qtd_vendida, vlr_unitario, vlr_total)
WITH RECURSIVE seq (k) AS (
    SELECT 1 UNION ALL SELECT k + 1 FROM seq WHERE k < 9
),
vendas AS (
    SELECT
        d.id_data,
        1 + MOD(DAYOFYEAR(d.dat_venda) * 7 + s.k * 13, 50)          AS id_produto,
        1 + MOD(DAYOFYEAR(d.dat_venda) + s.k * 3, 5)                AS qtd_vendida,
        ROW_NUMBER() OVER (ORDER BY d.id_data, s.k)                 AS num_seq
    FROM d_data d
        INNER JOIN seq s ON s.k <= 4 + MOD(DAYOFYEAR(d.dat_venda) * 3, 6)
    WHERE d.dat_venda BETWEEN '2025-01-01' AND '2025-08-31'
)
SELECT
    999 + v.num_seq                                                 AS id_venda,
    v.id_data,
    v.id_produto,
    v.qtd_vendida,
    p.vlr_uni                                                       AS vlr_unitario,
    ROUND(v.qtd_vendida * p.vlr_uni, 2)                             AS vlr_total
FROM vendas v
    INNER JOIN d_produto p ON p.id_produto = v.id_produto;

-- ---------------------------------------------------------------------
-- 3. CONFERENCIA
-- ---------------------------------------------------------------------
SELECT
    d.num_mes                       AS mes,
    d.nom_mes                       AS nome_mes,
    COUNT(*)                        AS qtd_vendas,
    ROUND(SUM(f.vlr_total), 2)      AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
GROUP BY d.num_mes, d.nom_mes
ORDER BY d.num_mes;
