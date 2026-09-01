# Estudo de Caso 1 — Relatório Analítico de Vendas

**Curso:** Sistemas de Informação · **Disciplina:** Business Intelligence (8º período)
**Professor:** Luiz Gustavo Dias · **Valor:** 20 pontos · **Apresentação:** 15/09
**Público-alvo:** Gerente comercial e equipe de vendas
**Ferramenta:** MySQL (Data Warehouse) + Pentaho Report Designer (camada de visualização)

> **Observação sobre os dados:** o enunciado descreve uma loja de cosméticos, mas o único
> dataset publicado no repositório da disciplina (`03-datasets/d_produto.sql`) é um catálogo
> de **varejo de supermercado** com 50 produtos e 10 categorias. Optamos por usar **o dataset
> oficial, sem nenhuma alteração**, e construir sobre ele as tabelas que faltavam
> (`d_data` e `f_vendas`). A estrutura do relatório é exatamente a exigida no enunciado.

---

## 1. Requisitos × Solução

| Requisito do enunciado | Como foi atendido |
|---|---|
| Listar as vendas realizadas no período | `SELECT` sobre a fato `f_vendas` (setembro/2025) |
| Colunas: Data da Venda, Produto, Categoria, Valor Total | `JOIN` de `f_vendas` com `d_data` e `d_produto` |
| Ordenar por data da venda | `ORDER BY d.dat_venda, p.nome_produto` |
| Fato `f_vendas` + dimensões `d_produto` e `d_data` | Star schema criado em MySQL (arquivo 01) |

## 2. Como foi feito — 5 etapas

1. **Levantamento** — leitura do enunciado e do dataset oficial do repositório da disciplina.
2. **Modelagem dimensional** — star schema: 1 tabela fato + 2 dimensões, grão definido como
   *um produto vendido em um dia*.
3. **Construção do DW (ETL)** — `d_produto` veio pronta do professor; geramos `d_data`
   (30 dias de setembro/2025) e `f_vendas` (197 registros), com `vlr_total = qtd × vlr_unitário`.
4. **Consultas analíticas** — 1 consulta principal (a do relatório) + 6 de apoio.
5. **Relatório** — organizado do resumido para o detalhado: KPIs → gráficos → listagem.

### Modelo dimensional (star schema)

```
        d_data                     f_vendas                    d_produto
  ┌──────────────────┐      ┌──────────────────────┐     ┌────────────────────┐
  │ id_data      (PK)│─────<│ id_data          (FK)│>────│ id_produto     (PK)│
  │ dat_venda        │      │ id_produto       (FK)│     │ nome_produto       │
  │ num_dia          │      │ qtd_vendida       ★  │     │ categoria_produto  │
  │ num_mes/nom_mes  │      │ vlr_unitario         │     │ vlr_uni            │
  │ num_trimestre    │      │ vlr_total         ★  │     │ qtd_estoque        │
  │ num_ano          │      └──────────────────────┘     └────────────────────┘
  │ nom_dia_semana   │           ★ métricas aditivas      (script oficial da
  └──────────────────┘        grão: 1 produto por dia       disciplina)
```

## 3. Consulta principal (a que gera o relatório no PRD)

```sql
SELECT d.dat_venda         AS data_venda,
       p.nome_produto      AS produto,
       p.categoria_produto AS categoria,
       f.vlr_total         AS valor_total
FROM f_vendas f
    INNER JOIN d_data    d ON d.id_data    = f.id_data
    INNER JOIN d_produto p ON p.id_produto = f.id_produto
ORDER BY d.dat_venda, p.nome_produto;
```

## 4. Resultados — Setembro/2025

**Indicadores gerais**

| Vendas registradas | Itens vendidos | Faturamento total | Ticket médio |
|---:|---:|---:|---:|
| 197 | 398 | R$ 4.429,46 | R$ 22,48 |

**Faturamento por categoria**

| Categoria | Itens | Faturamento | % do total |
|---|---:|---:|---:|
| Mercearia | 78 | R$ 940,18 | 21,2% |
| Carnes | 33 | R$ 687,70 | 15,5% |
| Padaria | 32 | R$ 460,52 | 10,4% |
| Laticínios | 47 | R$ 455,28 | 10,3% |
| Congelados | 23 | R$ 413,70 | 9,3% |
| Bebidas | 53 | R$ 353,67 | 8,0% |
| Higiene | 30 | R$ 295,62 | 6,7% |
| Limpeza | 43 | R$ 290,37 | 6,6% |
| Perfumaria | 24 | R$ 288,77 | 6,5% |
| Hortifruti | 35 | R$ 243,65 | 5,5% |

**Desempenho por dia da semana**

| Dia da semana | Vendas | Faturamento | Ticket médio |
|---|---:|---:|---:|
| Sábado | 45 | R$ 909,68 | R$ 20,22 |
| Sexta-feira | 36 | R$ 803,18 | R$ 22,31 |
| Quarta-feira | 26 | R$ 743,87 | R$ 28,61 |
| Quinta-feira | 27 | R$ 726,58 | R$ 26,91 |
| Terça-feira | 22 | R$ 477,48 | R$ 21,70 |
| Segunda-feira | 25 | R$ 429,54 | R$ 17,18 |
| Domingo | 16 | R$ 339,13 | R$ 21,20 |

**Top 5 produtos**

| # | Produto | Categoria | Itens | Faturamento |
|---|---|---|---:|---:|
| 1 | Arroz Branco 5kg | Mercearia | 14 | R$ 404,60 |
| 2 | Pão Francês 1kg | Padaria | 17 | R$ 253,30 |
| 3 | Carne Bovina Patinho 1kg | Carnes | 6 | R$ 239,40 |
| 4 | Café Torrado e Moído 500g | Mercearia | 12 | R$ 226,80 |
| 5 | Pizza Congelada 400g | Congelados | 12 | R$ 202,80 |

**Extremos do período:** melhor dia 27/09 (sábado) com R$ 301,65 · pior dia 21/09 (domingo) com R$ 34,37.

## 5. Análise — o que os números dizem ao gerente

- **Mercearia e Carnes concentram 36,7%** do faturamento: são as categorias que sustentam
  o resultado e não podem faltar em estoque.
- **Sábado e sexta somam 38,6%** do faturamento do mês. O reforço de equipe e de reposição
  deve se concentrar nesses dois dias.
- **Ticket médio é maior no meio da semana** (quarta R$ 28,61 e quinta R$ 26,91) e menor na
  segunda (R$ 17,18): no fim de semana vem *mais gente comprando pouco*; no meio da semana,
  *menos gente comprando mais*. São duas estratégias promocionais diferentes.
- **Bebidas e Hortifruti vendem volume e faturam pouco** (53 e 35 itens para 8,0% e 5,5%):
  são produtos de ticket baixo, úteis como atração de fluxo, não como fonte de margem.
- **Nenhum dos 50 produtos ficou sem venda** no mês (a consulta 7 retorna vazio) — o catálogo
  inteiro teve giro, o que é um bom sinal de qualidade da grade de produtos.
- **Recomendação:** ação promocional casada de Bebidas/Hortifruti (fluxo) com Mercearia/Carnes
  (margem) nas sextas e sábados; e promoção de ticket na segunda-feira, o dia mais fraco.

## 6. Fundamentação teórica — os 4 autores (5 pontos da nota)

| Autor | Ideia central (material da disciplina) | Onde aparece neste trabalho |
|---|---|---|
| **Bill Inmon** | Visão *top-down*: DW corporativo como **fonte única de verdade**, integrado e histórico; relatórios padronizados e consistentes | Base `dw_vendas` separada do transacional, com dimensão de tempo e nomenclatura padronizada; usamos o dataset **oficial** sem alterá-lo, garantindo integridade com a fonte |
| **Ralph Kimball** | Visão *bottom-up*: **Data Mart dimensional** (fato + dimensões), grão definido, navegação intuitiva e autonomia do usuário | Star schema `f_vendas` + `d_produto` + `d_data`, com grão declarado; o usuário navega por data, produto ou categoria sem apoio técnico |
| **Thomas Davenport** | **Cultura analítica**: relatório com propósito, orientado a perguntas de negócio, com narrativa e storytelling | Cada consulta responde a uma pergunta do gerente ("qual categoria fatura mais?", "qual dia vende mais?"); a seção 5 entrega **decisão**, não só dado |
| **Stephen Few** | Clareza visual: **sem sobrecarga**, hierarquia de leitura, gráfico adequado a cada análise, consistência de layout | Relatório do resumo ao detalhe (KPIs → categoria → dia → listagem); linha para série temporal, colunas para comparação; tabelas enxutas e formatação uniforme |

**Síntese:** Inmon garantiu a **integridade** dos dados, Kimball a **modelagem** voltada ao usuário,
Davenport a **interpretação** que vira decisão e Few a **comunicação** clara do resultado.

## 7. Arquivos entregues

| Arquivo | Conteúdo |
|---|---|
| `01_modelo_dimensional.sql` | Cria o banco `dw_vendas`, as 3 tabelas e carrega os dados (d_produto oficial + d_data + f_vendas) |
| `02_consulta_relatorio.sql` | Consulta principal do relatório + 6 consultas de apoio |
| `RESUMO_ESTUDO_DE_CASO_1.md` | Este documento (relatório + roteiro de apresentação) |

**Como executar:** no MySQL, rodar `01_modelo_dimensional.sql` e depois `02_consulta_relatorio.sql`.
No Pentaho Report Designer, conectar via JDBC ao banco `dw_vendas` e usar a consulta 1 como *Data Set*.

## 8. Roteiro da apresentação (5 a 10 min)

| # | Momento | Quem fala | Tempo |
|---|---|---|---|
| 1 | Contexto, público-alvo e pergunta de negócio | Integrante 1 | 1 min |
| 2 | Modelo dimensional na tela (star schema e grão) | Integrante 1 | 1,5 min |
| 3 | Consulta principal rodando no MySQL | Integrante 2 | 1,5 min |
| 4 | Resultados: KPIs, categorias, dia da semana, top produtos | Integrante 2 | 2 min |
| 5 | Análise e recomendação ao gerente comercial | Integrante 3 | 1,5 min |
| 6 | Inmon, Kimball, Davenport e Few aplicados (seção 6) | Integrante 3 | 2 min |

**Frase-chave para fechar:** "Não entregamos uma lista de vendas — entregamos uma decisão:
onde reforçar equipe, o que promover e em qual dia."
