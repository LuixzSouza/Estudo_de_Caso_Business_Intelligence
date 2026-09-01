# Guia — Rodar no MySQL e montar o relatório no Pentaho Report Designer

Este guia leva do zero até um relatório aberto no PRD, usando o banco `dw_vendas`.
Tudo que tem `!` na frente você **cola no chat do Claude Code** que ele executa aqui
na sua máquina (ou rode você mesmo no PowerShell, sem o `!`).

---

## Parte 1 — Criar o banco no MySQL

Você tem duas instâncias: **MySQL80 (porta 3306)** e **MySQLThaiCross (porta 3307)**.
Vamos usar a 3306. O executável do cliente fica em:
`C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`

### 1.1 Descobrir/confirmar a senha do root

```
! & 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -u root -e "SELECT VERSION();"
```

- Se mostrar a versão → a senha é vazia, siga para 1.2.
- Se pedir senha (*Access denied*) → abra o **MySQL Workbench**, a conexão
  "Local instance MySQL80" costuma ter a senha salva. Anote-a e, nos comandos
  abaixo, troque `-u root` por `-u root -p` (ele vai perguntar a senha).

### 1.2 Rodar o script que cria tudo

```
! & 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -u root < "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\01_modelo_dimensional.sql"
```

### 1.3 Conferir que carregou

```
! & 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -u root -e "USE dw_vendas; SELECT COUNT(*) AS produtos FROM d_produto; SELECT COUNT(*) AS vendas FROM f_vendas; SELECT SUM(vlr_total) AS faturamento FROM f_vendas;"
```

Esperado: **50 produtos, 197 vendas, faturamento ≈ 4429.46**.

### 1.4 (Opcional) Ver o relatório direto no terminal

```
! & 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -u root -t < "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\02_consulta_relatorio.sql"
```

---

## Parte 2 — Baixar o Pentaho Report Designer (PRD)

> **Importante:** o download **precisa ser feito pelo navegador**. O SourceForge tem
> proteção anti-robô que bloqueia download por script/linha de comando (só devolve uma
> página HTML). Pelo navegador é 1 clique normal.

**O driver JDBC do MySQL já está baixado** em
`_setup\mysql-connector-j-8.4.0.jar` — não precisa baixar de novo.

### 2.1 Baixar o PRD (Community Edition 9.4, ~1 GB) pelo navegador

1. Abra este link no navegador:
   **https://sourceforge.net/projects/pentaho/files/Pentaho%209.4/client-tools/prd-ce-9.4.0.0-343.zip/download**
2. O download começa sozinho em alguns segundos.
3. Quando terminar, **mova o arquivo `prd-ce-9.4.0.0-343.zip` para a pasta `_setup`**
   (dentro de `Estudo_de_Caso`).

> Dica: pode digitar `! ` no chat que eu descompacto e configuro o JDBC pra você
> assim que o arquivo estiver na pasta `_setup` — é só me avisar "já baixei".

### 2.2 Descompactar e instalar o driver JDBC (eu faço, ou você roda)

Depois que o zip estiver em `_setup`, rode (ou peça pra mim):

```
! Expand-Archive "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\_setup\prd-ce-9.4.0.0-343.zip" -DestinationPath "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\_setup\PRD" -Force
! Copy-Item "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\_setup\mysql-connector-j-8.4.0.jar" "C:\Users\Administrador\Desktop\LuixzSouza\Estudo_de_Caso\_setup\PRD\report-designer\lib\"
```

### 2.3 Abrir o PRD

Dê dois cliques em:
`_setup\PRD\report-designer\report-designer.bat`
(O Java 17 já está instalado na máquina, então ele abre.)

---

## Parte 3 — Montar o relatório dentro do PRD

1. **File → New** (novo relatório).
2. **Data → Add Data Source → JDBC.**
3. Clique no **+** para nova conexão e preencha:
   - **Connection Name:** dw_vendas
   - **Database Type:** MySQL
   - **Access:** Native (JDBC)
   - **Host Name:** localhost   **Port:** 3306
   - **Database Name:** dw_vendas
   - **User Name:** root   **Password:** (a senha do passo 1.1; vazia se for o caso)
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

## Resumo dos artefatos

| Arquivo | Para quê |
|---|---|
| `01_modelo_dimensional.sql` | Cria o banco e carrega os dados |
| `02_consulta_relatorio.sql` | Consulta principal + apoio |
| `Relatorio_Estudo_de_Caso_1_ACENTOS.docx` | Relatório formal (entrega ao professor) |
| `dashboard_vendas.html` | Painel visual para projetar na apresentação |
| `GUIA_PENTAHO.md` | Este guia |

**Dica de apresentação:** mostre o dashboard (`dashboard_vendas.html`) aberto em tela
cheia no navegador enquanto explica os resultados — é mais visual que o PRD. Deixe o
PRD como prova de que o relatório também roda na ferramenta oficial da disciplina.
