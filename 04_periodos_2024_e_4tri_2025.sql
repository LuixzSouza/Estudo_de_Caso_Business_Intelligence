/*
Disciplina Business Intelligence
Professor Gustavo Dias
Estudo de Caso 1 - Vendas em Loja de Varejo

AMPLIACAO 2: ano de 2024 completo + outubro a dezembro de 2025

Motivo: com o DW cobrindo so 2025, o parametro "Ano" do relatorio tinha uma
unica opcao e portanto nao filtrava nada. Com 2024 no banco o filtro passa a
comparar dois anos, e com out-dez/2025 os doze meses ficam disponiveis nos
dois lados.

O que este script acrescenta:
  - d_data : 2024-01-01 a 2024-12-31 (366 dias, ano bissexto)
              2025-10-01 a 2025-12-31 (92 dias)
  - f_vendas: vendas desses 458 dias, com id_venda a partir de 10000

Nada do que ja existia e alterado. Em particular os 197 registros de
setembro/2025 seguem intactos, entao o recorte de setembro continua fechando
em 4.429,46, como consta no relatorio e na documentacao.

A carga e deterministica (nao usa RAND): recriar o banco pelos scripts produz
exatamente os mesmos numeros.

Sazonalidade: novembro e dezembro recebem mais vendas por dia que os demais
meses, para o grafico e os filtros mostrarem variacao com sentido comercial.

Pre-requisitos: scripts 01 e 03 ja executados.
Execucao: mysql -h 127.0.0.1 -P 3307 -u root < 04_periodos_2024_e_4tri_2025.sql
*/

USE dw_vendas;

-- ---------------------------------------------------------------------
-- 1. DIMENSAO DATA
-- ---------------------------------------------------------------------
INSERT INTO d_data
    (id_data, dat_venda, num_dia, num_mes, nom_mes, num_trimestre, num_ano, nom_dia_semana)
WITH RECURSIVE calendario (dat_venda) AS (
    SELECT DATE '2024-01-01'
    UNION ALL
    SELECT dat_venda + INTERVAL 1 DAY FROM calendario WHERE dat_venda < DATE '2025-12-31'
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
FROM calendario
WHERE dat_venda NOT IN (SELECT dat_venda FROM d_data);   -- nao recarrega o que ja existe

-- ---------------------------------------------------------------------
-- 2. TABELA FATO
--
-- Grao mantido: 1 linha por produto vendido em um dia.
--   vendas no dia = 4 a 9, e 7 a 12 em novembro/dezembro (pico de fim de ano)
--   produto       = derivado do dia do ano, da sequencia e do ano
--   qtd_vendida   = 1 a 5
--   vlr_unitario  = d_produto.vlr_uni (preco sempre igual ao do catalogo)
-- ---------------------------------------------------------------------
INSERT INTO f_vendas
    (id_venda, id_data, id_produto, qtd_vendida, vlr_unitario, vlr_total)
WITH RECURSIVE seq (k) AS (
    SELECT 1 UNION ALL SELECT k + 1 FROM seq WHERE k < 12
),
vendas AS (
    SELECT
        d.id_data,
        1 + MOD(DAYOFYEAR(d.dat_venda) * 7 + s.k * 13 + (d.num_ano - 2024) * 5, 50) AS id_produto,
        1 + MOD(DAYOFYEAR(d.dat_venda) + s.k * 3, 5)                                AS qtd_vendida,
        ROW_NUMBER() OVER (ORDER BY d.id_data, s.k)                                 AS num_seq
    FROM d_data d
        INNER JOIN seq s
            ON s.k <= 4 + MOD(DAYOFYEAR(d.dat_venda) * 3, 6)
                    + CASE WHEN d.num_mes IN (11, 12) THEN 3 ELSE 0 END
    WHERE d.dat_venda BETWEEN '2024-01-01' AND '2024-12-31'
       OR d.dat_venda BETWEEN '2025-10-01' AND '2025-12-31'
)
SELECT
    9999 + v.num_seq                                                AS id_venda,
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
    d.num_ano                       AS ano,
    COUNT(DISTINCT d.dat_venda)     AS dias,
    COUNT(*)                        AS qtd_vendas,
    ROUND(SUM(f.vlr_total), 2)      AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
GROUP BY d.num_ano
ORDER BY d.num_ano;

SELECT
    d.num_ano                       AS ano,
    d.num_mes                       AS mes,
    d.nom_mes                       AS nome_mes,
    COUNT(*)                        AS qtd_vendas,
    ROUND(SUM(f.vlr_total), 2)      AS vlr_faturamento
FROM f_vendas f
    INNER JOIN d_data d ON d.id_data = f.id_data
GROUP BY d.num_ano, d.num_mes, d.nom_mes
ORDER BY d.num_ano, d.num_mes;
