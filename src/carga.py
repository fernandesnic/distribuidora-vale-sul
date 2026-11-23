from pathlib import Path
import sqlite3

import numpy as np
import pandas as pd

PASTA_PROJETO = Path(__file__).resolve().parent.parent
PASTA_BRUTOS = PASTA_PROJETO / "data" / "raw"
ARQUIVO_BANCO = PASTA_PROJETO / "data" / "processed" / "vale_sul.db"
SCRIPT_TABELAS = PASTA_PROJETO / "sql" / "01_criar_tabelas.sql"


# ---------------------------------------------------------------------
# Leitura
# ---------------------------------------------------------------------

def ler_csv(nome_arquivo):
    return pd.read_csv(PASTA_BRUTOS / nome_arquivo, sep=";", decimal=",")


# ---------------------------------------------------------------------
# Limpeza
# ---------------------------------------------------------------------

def limpar_clientes(clientes, pedidos, titulos):
    clientes["cnpj"] = clientes["cnpj"].str.replace(r"\D", "", regex=True)

    for coluna in ["razao_social", "nome_fantasia", "cnpj", "segmento", "cidade", "uf"]:
        clientes[coluna] = clientes[coluna].str.strip()

    padrao_cidade = {
        "Sao Paulo": "São Paulo",
        "S. Paulo": "São Paulo",
        "SP": "São Paulo",
        "SAO PAULO": "São Paulo",
        "GUARULHOS": "Guarulhos",
        "MOGI DAS CRUZES": "Mogi das Cruzes",
        "STO ANDRE": "Santo André",
        "Santo Andre": "Santo André",
        "S. Bernardo do Campo": "São Bernardo do Campo",
        "SBC": "São Bernardo do Campo",
        "Sao Bernardo do Campo": "São Bernardo do Campo",
        "Mogi": "Mogi das Cruzes",
    }
    clientes["cidade"] = clientes["cidade"].replace(padrao_cidade)

    padrao_segmento = {
        "Bar/Restaurante": "Bar e Restaurante",
        "MERCADO": "Mercado",
        "Conveniencia": "Conveniência",
        "padaria": "Padaria",
    }
    clientes["segmento"] = clientes["segmento"].replace(padrao_segmento)

    clientes["uf"] = clientes["uf"].fillna("SP")

    clientes["id_novo"] = clientes.groupby("cnpj")["cliente_id"].transform("min")
    mudam = clientes[clientes["cliente_id"] != clientes["id_novo"]]
    de_para = dict(zip(mudam["cliente_id"], mudam["id_novo"]))

    pedidos["cliente_id"] = pedidos["cliente_id"].replace(de_para)
    titulos["cliente_id"] = titulos["cliente_id"].replace(de_para)

    clientes = clientes[clientes["cliente_id"] == clientes["id_novo"]]
    clientes = clientes.drop(columns=["id_novo"])

    clientes["vendedor_id"] = clientes["vendedor_id"].astype("Int64")

    return clientes, pedidos, titulos


def limpar_pedidos(pedidos):
    pedidos["data_pedido"] = pd.to_datetime(pedidos["data_pedido"], format="%Y-%m-%d")
    filtro = pedidos["data_pedido"].dt.year == 2052
    pedidos.loc[filtro, "data_pedido"] = pedidos.loc[filtro, "data_pedido"] - pd.DateOffset(years=27)
    return pedidos


def limpar_produtos(produtos, itens, pedidos):
    categoria_por_id = {
        22: "Bebidas",
        45: "Bebidas",
        75: "Bebidas",
        141: "Mercearia",
        143: "Mercearia",
        160: "Frios e Laticínios",
    }
    produtos["categoria"] = produtos["categoria"].fillna(produtos["produto_id"].map(categoria_por_id))


    itens_data = itens.merge(pedidos[["pedido_id", "data_pedido"]], on="pedido_id", how="left")
    ultimo = itens_data.sort_values("data_pedido").drop_duplicates(subset="produto_id", keep="last")
    valor_produto = ultimo.set_index("produto_id")["custo_unitario"]

    filtro = produtos["produto_id"].isin([37, 40, 134, 216])
    produtos.loc[filtro, "custo_unitario"] = produtos.loc[filtro, "produto_id"].map(valor_produto)

    novos_produtos = pd.DataFrame({
        "produto_id": [901, 902, 903],
        "sku": ["VS00901", "VS00902", "VS00903"],
        "descricao": ["Produto desconhecido"] * 3,
        "categoria": ["Desconhecido"] * 3,
        "marca": ["Desconhecido"] * 3,
        "unidade": ["N/D"] * 3,
        "custo_unitario": [56.94, 83.75, 65.46],
        "preco_venda": [75.69, 99.13, 77.76],
        "ativo": ["N"] * 3,
    })
    produtos = pd.concat([produtos, novos_produtos], ignore_index=True)

    produtos["ativo"] = produtos["ativo"].map({"S": 1, "N": 0})

    return produtos


def limpar_itens(itens):
    diferenca_item = itens["quantidade"] * itens["preco_unitario"] - itens["valor_total_item"]
    filtro = diferenca_item.abs() > 0.01
    itens.loc[filtro, "quantidade"] = itens.loc[filtro, "quantidade"] // 100
    return itens


def limpar_pagamentos(pagamentos):
    formato_iso = pd.to_datetime(pagamentos["data_pagamento"], format="%Y-%m-%d", errors="coerce")
    formato_barra = pd.to_datetime(pagamentos["data_pagamento"], format="%d/%m/%Y", errors="coerce")
    pagamentos["data_pagamento"] = formato_iso.fillna(formato_barra)

    pagamentos = pagamentos.drop_duplicates()
    return pagamentos


def limpar_titulos(titulos, pagamentos, pedidos):
    pagamento_por_titulo = pagamentos.groupby("titulo_id")["valor_pago"].sum()
    total_pago = titulos["titulo_id"].map(pagamento_por_titulo).fillna(0)

    condicoes = [
        total_pago >= titulos["valor"] - 0.01,
        total_pago > 0,
    ]
    resultados = ["PAGO", "PARCIAL"]
    titulos["status"] = np.select(condicoes, resultados, default="ABERTO")

    pedidos_cancelados = pedidos.loc[pedidos["status"] == "CANCELADO", "pedido_id"]
    filtro = titulos["pedido_id"].isin(pedidos_cancelados)
    titulos.loc[filtro, "status"] = "CANCELADO"

    return titulos


# ---------------------------------------------------------------------
# Gravação no banco
# ---------------------------------------------------------------------

def gravar_no_banco(tabelas):
    ARQUIVO_BANCO.parent.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(ARQUIVO_BANCO)

    with open(SCRIPT_TABELAS, encoding="utf-8") as arquivo:
        con.executescript(arquivo.read())
    con.execute("PRAGMA foreign_keys = ON")

    for nome, df in tabelas.items():
        df.to_sql(nome, con, if_exists="append", index=False)
    con.commit()

    print(f"{'tabela':16} {'pandas':>8} {'banco':>8}")
    for nome, df in tabelas.items():
        no_banco = con.execute(f"SELECT COUNT(*) FROM {nome}").fetchone()[0]
        print(f"{nome:16} {len(df):>8} {no_banco:>8}")

    con.close()


# ---------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------

def main():
    vendedores = ler_csv("vendedores.csv")
    clientes = ler_csv("clientes.csv")
    produtos = ler_csv("produtos.csv")
    pedidos = ler_csv("pedidos.csv")
    itens = ler_csv("itens_pedido.csv")
    titulos = ler_csv("titulos_receber.csv")
    pagamentos = ler_csv("pagamentos.csv")

    clientes, pedidos, titulos = limpar_clientes(clientes, pedidos, titulos)
    pedidos = limpar_pedidos(pedidos)
    produtos = limpar_produtos(produtos, itens, pedidos)
    itens = limpar_itens(itens)
    pagamentos = limpar_pagamentos(pagamentos)
    titulos = limpar_titulos(titulos, pagamentos, pedidos)

    pedidos["data_pedido"] = pedidos["data_pedido"].dt.strftime("%Y-%m-%d")
    pagamentos["data_pagamento"] = pagamentos["data_pagamento"].dt.strftime("%Y-%m-%d")

    tabelas = {
        "vendedores": vendedores,
        "clientes": clientes,
        "produtos": produtos,
        "pedidos": pedidos,
        "itens_pedido": itens,
        "titulos_receber": titulos,
        "pagamentos": pagamentos,
    }
    gravar_no_banco(tabelas)


if __name__ == "__main__":
    main()