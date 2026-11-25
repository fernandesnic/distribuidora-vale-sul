# 📦 Distribuidora Vale Sul — Análise de Vendas e Recebíveis

Projeto de portfólio de análise de dados: do dado bruto até o dashboard, passando por banco de dados, Excel, Power BI e Python.

> 🚧 **Projeto em andamento.** Este README será atualizado a cada etapa concluída.

---

## 🏢 Contexto

A **Distribuidora Vale Sul** é uma distribuidora de alimentos e bebidas de médio porte que atende a Grande São Paulo. Ela vende para mercados, bares e restaurantes, padarias e lojas de conveniência, por meio de vendedores externos e televendas, e recebe por boleto a prazo ou PIX à vista.

> ⚠️ **A empresa e os dados são fictícios.** Todos os dados foram gerados para este projeto e nenhum vem de uma empresa ou cliente real.

Para deixar o trabalho mais próximo da realidade, a base tem problemas comuns em sistemas de empresas, como cliente cadastrado duas vezes, pagamento parcial de título, pedidos cancelados e devoluções.

---

## 🎯 Objetivo

Praticar o caminho completo de um analista de dados em um cenário parecido com o de uma empresa real: organizar e limpar os dados, responder perguntas de negócio e apresentar os resultados de forma clara para quem toma decisões.

---

## ❓ Perguntas de negócio

**Vendas**

1. Quanto vendemos por mês e estamos crescendo?
2. Em que época do ano vendemos mais, e de quê?
3. Quais vendedores e qual canal (externo ou televendas) vendem mais?

**Clientes**

4. Quem são nossos melhores clientes? *(RFM)*
5. Dos clientes que começaram a comprar em cada mês, quantos continuam comprando? *(Cohort)*
6. Quais clientes bons pararam de comprar ou estão comprando menos?

**Produtos**

7. Quais produtos dão mais lucro e quais vendem muito mas lucram pouco?
8. Quais produtos têm mais devolução?

**Financeiro**

9. Quanto dinheiro está em atraso e com quais clientes?
10. Os clientes que pagam com prazo maior atrasam mais?
11. Quanto devemos receber no mês que vem? *(previsão)*

**Decisão**

12. O que a empresa deveria fazer para vender mais e receber melhor? *(recomendação)*

---

## 🗺️ Etapas do projeto

| Etapa | Descrição | Status |
|---|---|---|
| 1 - Banco de dados | Modelagem das tabelas, limpeza dos dados com Python, carga automática no banco e validação com SQL | ✅ Concluída |
| 2 - Excel | Importação com Power Query, painel de vendas mensal e análises de Cohort e RFM | ⏳ A fazer |
| 3 - Power BI | Painéis Comercial, Produtos e Financeiro | ⏳ A fazer |
| 4 - Análise completa | Análises descritiva, diagnóstica, preditiva e prescritiva | ⏳ A fazer |
| 5 - Dashboard web | Dashboard em Python (Streamlit) publicado na internet | ⏳ A fazer |
| 6 - Apresentação web | Página de apresentação do projeto com gráficos interativos, publicada no GitHub Pages | ⏳ A fazer |
| 7 - Divulgação | README final com conclusões e post no LinkedIn | ⏳ A fazer |

---

## 🛠️ Ferramentas

- **SQL** — criação das tabelas, validação e consultas
- **Python (pandas)** — limpeza, carga automática e análises
- **Excel (Power Query)** — painel de vendas, Cohort e RFM
- **Power BI** — painéis
- **Streamlit** — dashboard web
- **HTML, CSS e JavaScript** — página de apresentação (GitHub Pages)

---

## 📁 Estrutura do repositório

```
distribuidora-vale-sul/
├── README.md
├── data/
│   ├── raw/          (dados brutos gerados)
│   └── processed/    (dados tratados)
├── sql/              (criação das tabelas e consultas)
├── src/              (scripts Python de limpeza e carga)
├── notebooks/        (análises em Jupyter)
├── excel/            (painel em Excel)
├── powerbi/          (arquivo .pbix)
├── app/              (dashboard Streamlit)
└── docs/             (imagens e relatório final)
```

---

## 📈 Resultados

*(serão adicionados ao final das análises)*

---

## 👤 Autor

**Nicolas Fernandes**
[LinkedIn](https://www.linkedin.com/in/fernandesnic/)
