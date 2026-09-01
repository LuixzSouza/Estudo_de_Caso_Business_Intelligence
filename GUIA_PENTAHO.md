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

Resultado esperado: **50 produtos, 197 vendas, faturamento 4429.46**.

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
