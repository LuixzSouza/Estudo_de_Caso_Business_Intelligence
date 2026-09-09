# Estudo de Caso 1 — Business Intelligence

Relatório analítico de vendas desenvolvido para a disciplina de **Business Intelligence**
(Sistemas de Informação, 8º período — UNIVÁS, Prof. Luiz Gustavo Dias).

Modelagem dimensional em **MySQL** (Data Warehouse) e camada de visualização em
**Pentaho Report Designer (PRD)**, com um painel de apoio em HTML para a apresentação.

## Objetivo

Apresentar, ao gerente comercial e à equipe de vendas, um relatório com as vendas do
período — **data, produto, categoria e valor total**, ordenado por data — a partir de um
modelo estrela (star schema): fato `f_vendas` + dimensões `d_produto` e `d_data`.

> **Base de dados:** utilizamos o dataset oficial do repositório da disciplina
> (`d_produto.sql` — catálogo de varejo com 50 produtos e 10 categorias) **sem alterações**,
> e construímos sobre ele as tabelas `d_data` e `f_vendas`.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `01_modelo_dimensional.sql` | Cria o banco `dw_vendas`, as 3 tabelas e carrega os dados |
| `02_consulta_relatorio.sql` | Consulta principal do relatório + 6 consultas de apoio + queries parametrizadas |
| `03_periodos_adicionais.sql` | Amplia o DW para janeiro–agosto/2025, para o filtro de período |
| `04_periodos_2024_e_4tri_2025.sql` | Acrescenta 2024 inteiro e out–dez/2025 (dois anos no filtro) |
| `Relatorio_Estudo_de_Caso_1.docx` | Relatório formal (entrega ao professor) |
| `dashboard_vendas.html` | Painel visual para projetar na apresentação |
| `RESUMO_ESTUDO_DE_CASO_1.md` | Resumo do trabalho + roteiro de apresentação |
| `GUIA_PENTAHO.md` | Passo a passo: MySQL + instalação/uso do Pentaho |

## Como executar

1. **MySQL:** rodar na ordem `01_modelo_dimensional.sql`, `03_periodos_adicionais.sql`,
   `04_periodos_2024_e_4tri_2025.sql` e por fim `02_consulta_relatorio.sql`.
2. **Pentaho:** seguir o `GUIA_PENTAHO.md` (conectar via JDBC ao banco `dw_vendas` e usar
   a consulta principal como Data Set). A Parte 4 do guia monta o filtro de período.

## Principais resultados (setembro/2025)

- Faturamento total: **R$ 4.429,46** em **197 vendas** (398 itens), ticket médio **R$ 22,48**.
- Categorias líderes: **Mercearia (21,2%)** e **Carnes (15,5%)**.
- Dias mais fortes: **sábado e sexta** (38,6% do faturamento).

## Filtro de período

O relatório no PRD tem três parâmetros — **Ano**, **Mês** e **Dia** — com listas
alimentadas por consulta ao próprio `d_data`, de modo que as opções acompanham o que
está carregado no DW. `Mês = 0` mostra o ano inteiro e `Dia = 0` mostra o mês inteiro.

Para o filtro ter o que filtrar, o DW foi ampliado em duas etapas:

| Script | Período acrescentado | |
|---|---|---|
| `03` | jan–ago/2025 | o filtro de mês/dia passa a ter o que comparar |
| `04` | 2024 inteiro + out–dez/2025 | o filtro de **ano** passa a ter duas opções |

Hoje o DW cobre **2024 e 2025 completos**: **731 dias** e **4.420 vendas**, somando
**R$ 146.993,60**. Novembro e dezembro têm mais vendas por dia que os demais meses,
para haver sazonalidade visível no gráfico.

| Ano | Dias | Vendas | Faturamento |
|---|---:|---:|---:|
| 2024 | 366 | 2.196 | R$ 74.032,38 |
| 2025 | 365 | 2.224 | R$ 72.961,22 |

Os 197 registros de setembro/2025 **não foram alterados** — por isso a análise acima e
o relatório formal em `.docx` seguem válidos: são o recorte de setembro, reproduzível
pelo filtro com `Ano = 2025, Mês = Setembro, Dia = 0`.

## Fundamentação teórica

O relatório aplica os pensamentos de **Inmon** (integridade / fonte única de verdade),
**Kimball** (modelagem dimensional), **Davenport** (cultura analítica / decisão) e
**Few** (comunicação visual). Detalhes na seção 4 do relatório em `.docx`.
