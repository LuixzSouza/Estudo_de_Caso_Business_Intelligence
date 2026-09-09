# Guia — Rodar no MySQL e montar o relatório no Pentaho Report Designer

Este guia leva do zero até um relatório aberto no PRD, usando o banco `dw_vendas`.
Tudo que tem `!` na frente você **cola no chat do Claude Code** que ele executa aqui
na sua máquina (ou rode você mesmo no PowerShell, sem o `!`).

---

## Parte 1 — Banco de dados (JÁ FEITO ✅)

O banco `dw_vendas` foi criado e carregado na instância **MySQL 8.4 na porta 3307**
(`MySQLThaiCross`), que aceita `root` **sem senha**. A instância da porta 3306 tem
senha de root desconhecida, por isso não foi usada.

Cliente: `C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe`

Conferência (opcional):

```
! & 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe' -h 127.0.0.1 -P 3307 -u root -e "USE dw_vendas; SELECT COUNT(*) produtos FROM d_produto; SELECT COUNT(*) vendas FROM f_vendas; SELECT SUM(vlr_total) faturamento FROM f_vendas;"
```

Resultado esperado: **50 produtos, 4420 vendas, faturamento 146993.60** (2024 e 2025). Só setembro continua sendo **197 vendas / 4429.46** — ver
`03_periodos_adicionais.sql` e a Parte 4 deste guia.

Ver o relatório inteiro no terminal:

```
! & 'C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe' -h 127.0.0.1 -P 3307 -u root -t --default-character-set=utf8mb4 < "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\02_consulta_relatorio.sql"
```

---

## Parte 2 — Pentaho Report Designer (JÁ INSTALADO ✅)

Não precisa baixar nada. O PRD já está em:

`C:\Users\Administrador\Desktop\LuixzSouza\pentaho\report-designer\report-designer.bat`

O driver JDBC do MySQL (`mysql-connector-java-5.1.49.jar`) já vem dentro dele em
`lib\jdbc\` e foi testado com sucesso contra o MySQL 8.4 desta máquina.

**Atenção ao Java:** o PRD é a versão 5.0.1 e precisa de **Java 8**. O Java padrão do
sistema é o 17, que não roda o PRD. Para abrir, use o JRE 8 que está instalado:

```
! & 'C:\Program Files (x86)\Java\jre1.8.0_461\bin\javaw.exe' -Xmx512M -jar 'C:\Users\Administrador\Desktop\LuixzSouza\pentaho\report-designer\launcher.jar'
```

(É preciso estar na pasta do report-designer — ou peça pra mim que eu abro.)

---

## Dados da conexão JDBC (para colar no PRD)

| Campo | Valor |
|---|---|
| Connection Name | `dw_vendas` |
| Database Type | MySQL |
| Access | Native (JDBC) |
| Host Name | `127.0.0.1` |
| Port | `3307` |
| Database Name | `dw_vendas` |
| User Name | `root` |
| Password | *(deixe em branco)* |

Driver: `org.gjt.mm.mysql.Driver`
URL completa: `jdbc:mysql://127.0.0.1:3307/dw_vendas`

---

## Parte 3 — Montar o relatório dentro do PRD

1. **File → New** (novo relatório).
2. **Data → Add Data Source → JDBC.**
3. Clique no **+** para nova conexão e preencha:
   - **Connection Name:** dw_vendas
   - **Database Type:** MySQL
   - **Access:** Native (JDBC)
   - **Host Name:** 127.0.0.1   **Port:** 3307
   - **Database Name:** dw_vendas
   - **User Name:** root   **Password:** *(em branco)*
   - Clique em **Test** → deve dizer conexão OK.
4. Na mesma janela, em **Query**, cole a **consulta principal** (está no arquivo
   `02_consulta_relatorio.sql`, a de número 1):

   ```sql
   SELECT d.dat_venda AS data_venda, p.nome_produto AS produto,
          p.categoria_produto AS categoria, f.vlr_total AS valor_total
   FROM f_vendas f
     INNER JOIN d_data d ON d.id_data = f.id_data
     INNER JOIN d_produto p ON p.id_produto = f.id_produto
   ORDER BY d.dat_venda, p.nome_produto;
   ```
   Dê um nome à query (ex.: `q_vendas`) e **OK**.

5. Arraste os campos (`data_venda`, `produto`, `categoria`, `valor_total`) da aba
   **Structure** para a banda **Details** do relatório.
6. Coloque os títulos das colunas na banda **Page Header** (caixas de texto).
7. (Opcional) Em **Report Header**, adicione um título "Relatório de Vendas — Setembro/2025".
8. (Opcional) Para o total: selecione o campo `valor_total`, botão direito →
   **Add Summary/Sum** para somar o faturamento no rodapé.
9. **File → Preview** (ou o ícone ▶) para ver o relatório renderizado.
10. **File → Export → PDF** para gerar a versão de entrega.

---

## Parte 4 — Filtro de período (ano / mês / dia)

> **Já está pronto no arquivo.** O `relatorio_vendas.prpt` do repositório vem com os três
> parâmetros, as queries filtradas e o mapeamento do subrelatório. Abra-o no PRD e vá
> direto em **File → Preview**. O passo a passo abaixo fica como documentação de como
> foi montado (e para refazer, se precisar).

O DW cobre **2024 e 2025 completos** (731 dias, 4.420 vendas) depois dos scripts
`03_periodos_adicionais.sql` e `04_periodos_2024_e_4tri_2025.sql`, e o relatório tem três parâmetros que permitem olhar
um ano inteiro, um mês ou um único dia. As queries prontas estão na **seção 8** do
`02_consulta_relatorio.sql`.

### 4.1 Criar os parâmetros

Aba **Data** → botão direito em **Parameters** → **Add Parameter**. Os três são
`Integer`, o que evita a caixa de data em vermelho por causa de formato/locale:

| Name | Label | Value Type | Display Type | Query (lista) | Value / Display Column | Default |
|---|---|---|---|---|---|---|
| `p_ano` | Ano | Integer | Drop Down | `q_anos` | `valor` / `rotulo` | `2025` |
| `p_mes` | Mês | **Long** | Drop Down | `q_meses` | `valor` / `rotulo` | `9` |
| `p_dia` | Dia | **Long** | Drop Down | `q_dias` | `valor` / `rotulo` | `0` |

> **Cuidado com o tipo — foi o que quebrou o filtro na primeira versão.** `q_meses` e
> `q_dias` usam `UNION ALL` com o literal `0` para criar a opção "todos"; nesse caso o
> MySQL devolve a coluna como **BIGINT**, que o driver JDBC entrega como `java.lang.Long`.
> Se o parâmetro estiver declarado `Integer` e com `strict-values`, o PRD **descarta em
> silêncio** o valor escolhido no dropdown (`This prompt value is of an invalid type`),
> ele vira `NULL`, e `(NULL = 0 OR d.num_dia = NULL)` não retorna nenhuma linha — o
> relatório abre vazio sem mensagem de erro. Por isso `p_mes` e `p_dia` são `Long`.
> `p_ano` continua `Integer` porque `q_anos` não tem `UNION`: vem direto da coluna `INT`.
>
> Sintoma típico: o preview abre certo (o default vem do XML, já tipado) e só quebra
> quando você escolhe um valor no dropdown.

As listas vêm das queries `q_anos`, `q_meses` e `q_dias` (seções 8.4 a 8.6), então o
filtro reflete automaticamente o que existe no DW — carregar mais meses amplia o
dropdown sem tocar no relatório. O valor **0** significa "todos": `p_mes = 0` mostra o
ano inteiro, `p_dia = 0` mostra o mês inteiro. Usamos 0 em vez de `NULL` porque
parâmetro nulo em driver JDBC costuma dar erro de tipo.

`q_meses` e `q_dias` usam `${p_ano}` / `${p_mes}` dentro da própria query — isso é
cascateamento: ao trocar o ano, a lista de meses se refaz.

### 4.2 Aplicar o filtro nas queries

Troque `q_vendas` pela versão da seção 8.1 e `q_categoria` pela 8.2. O filtro é:

```sql
WHERE d.num_ano = ${p_ano}
  AND (${p_mes} = 0 OR d.num_mes = ${p_mes})
  AND (${p_dia} = 0 OR d.num_dia = ${p_dia})
```

Atenção: a `q_categoria` precisa do `INNER JOIN d_data` (a versão sem filtro não
tinha), senão o gráfico ignora o período e fica inconsistente com a listagem.

### 4.3 Passar os parâmetros ao subrelatório do gráfico

Selecione o elemento **subreport** no relatório pai → aba **Data** → tabela
**Import Parameters**, e mapeie os três (nome igual dos dois lados):

| Outer Name (pai) | Inner Name (subrelatório) |
|---|---|
| `p_ano` | `p_ano` |
| `p_mes` | `p_mes` |
| `p_dia` | `p_dia` |

Sem esse mapeamento o gráfico vem vazio ou dá erro de parâmetro desconhecido.

### 4.4 Casos de teste (valores conferidos no banco)

| p_ano | p_mes | p_dia | Linhas | Faturamento |
|---|---|---|---|---|
| 2025 | 9 (Setembro) | 0 | 197 | 4.429,46 |
| 2025 | 0 (todos) | 0 | 2224 | 72.961,22 |
| 2025 | 3 (Março) | 15 | 4 | 51,31 |
| 2025 | 9 (Setembro) | 1 | 4 | 74,91 |
| 2024 | 0 (todos) | 0 | 2196 | 74.032,38 |
| 2024 | 12 (Dezembro) | 0 | 262 | 8.772,61 |
| 2024 | 12 (Dezembro) | 25 | 7 | 307,85 |

A primeira linha é o cenário original da entrega — ele continua fechando igual,
porque os 197 registros de setembro não foram alterados.

### 4.5 Formatação visual

O `.prpt` do repositório já vem formatado. As decisões, caso precise refazer:

| Item | Escolha | Porquê |
|---|---|---|
| Fonte | `Helvetica` | com `SansSerif` o motor calcula mal a largura do espaço e as palavras saem grudadas ("RelatórioAnalíticode Vendas") |
| `font-size` | sempre inteiro | o parser do bundle rejeita `7.5` com *Failed to parse value* |
| Grade | 532pt (carta − margens de 40) em 4 colunas: 72 / 234 / 118 / 108 | valor sempre alinhado à direita |
| Cabeçalho | faixa `#1F3B57` com rótulos brancos, no **page-header** | repete em todas as páginas; os rótulos ficavam na banda Details e se repetiam a cada linha |
| Linhas | altura 14pt, borda inferior `#E3E8ED` | 197 linhas cabem em 5 páginas em vez de 17 |
| Rodapé | `PageOfPagesFunction` com formato `Página {0} de {1}` | use `text-field` para exibi-la; `content-field` não renderiza texto |
| Gráfico | barras `#1F3B57`, sem legenda, eixo começando em zero | uma série só — legenda "Series 1" era ruído |

Duas armadilhas do bundle 5.0.1 que custam tempo:

- O **page-header não fica no `layout.xml`** — ele mora no `styles.xml`, com prefixo
  `layout:`. No `layout.xml` a raiz só aceita `report-header`, `group`, `report-footer`,
  `crosstab`, `preprocessor` e `layout-processors`; qualquer outra banda é ignorada em
  silêncio.
- O elemento de texto com parâmetros embutidos é `<message>`, não `message-field`.

---

## Resumo dos artefatos

| Arquivo | Para quê |
|---|---|
| `01_modelo_dimensional.sql` | Cria o banco e carrega os dados |
| `02_consulta_relatorio.sql` | Consulta principal + apoio + queries parametrizadas (seção 8) |
| `03_periodos_adicionais.sql` | Amplia o DW para janeiro–agosto/2025 (filtro de período) |
| `04_periodos_2024_e_4tri_2025.sql` | Acrescenta 2024 e out–dez/2025 (dois anos no filtro) |
| `relatorio_vendas.prpt` | Relatório do PRD, com filtro de período pronto |
| `relatorio_vendas_setembro.pdf` | PDF de entrega (recorte de setembro/2025) |
| `preview_pagina1.png` / `preview_ultima_pagina.png` | Como o relatório fica impresso |
| `Relatorio_Estudo_de_Caso_1_ACENTOS.docx` | Relatório formal (entrega ao professor) |
| `dashboard_vendas.html` | Painel visual para projetar na apresentação |
| `GUIA_PENTAHO.md` | Este guia |

**Dica de apresentação:** mostre o dashboard (`dashboard_vendas.html`) aberto em tela
cheia no navegador enquanto explica os resultados — é mais visual que o PRD. Deixe o
PRD como prova de que o relatório também roda na ferramenta oficial da disciplina.
