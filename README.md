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
| `Relatorio_Estudo_de_Caso_1.docx` | Relatório formal (entrega ao professor) |
| `dashboard_vendas.html` | Painel visual para projetar na apresentação |
| `RESUMO_ESTUDO_DE_CASO_1.md` | Resumo do trabalho + roteiro de apresentação |
| `GUIA_PENTAHO.md` | Passo a passo: MySQL + instalação/uso do Pentaho |

## Como executar

1. **MySQL:** rodar `01_modelo_dimensional.sql`, depois `03_periodos_adicionais.sql` e
   por fim `02_consulta_relatorio.sql`.
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

Para o filtro ter o que filtrar, o DW foi ampliado de 1 para **9 meses**
(`03_periodos_adicionais.sql`): janeiro a setembro de 2025, **273 dias** e
**1.535 vendas**, faturamento total de **R$ 49.796,79**.

Os 197 registros de setembro/2025 **não foram alterados** — por isso a análise acima e
o relatório formal em `.docx` seguem válidos: são o recorte de setembro, reproduzível
pelo filtro com `Ano = 2025, Mês = Setembro, Dia = 0`.

## Fundamentação teórica

O relatório aplica os pensamentos de **Inmon** (integridade / fonte única de verdade),
**Kimball** (modelagem dimensional), **Davenport** (cultura analítica / decisão) e
**Few** (comunicação visual). Detalhes na seção 4 do relatório em `.docx`.
