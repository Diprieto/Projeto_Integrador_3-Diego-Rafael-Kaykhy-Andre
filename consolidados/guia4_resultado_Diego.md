# Resultado do Guia 4 (Aula 08) — Reordenamento por Proximidade

* **Grupo:** Predicarga (André, Diego, Kaykhy)
* **Repositório:** `andrecesar00/predicarga_andre_diego_kaykhy`
* **Corpus:** Patrimônio Histórico e Centro Antigo de São Vicente
* **Julgamentos (`qrels`):** `qrels_Andre_2026-10-25.csv`
* **Parâmetros avaliados:** Estágio 1 = BM25 ($k_1 = 1{,}2$, $b = 0{,}75$); Estágio 2 = Proximidade com janela $w = 3$

---

## 1. Latência Base e Curva Qualidade × Custo no Conjunto `dev`

O estágio 1 (BM25) apresentou tempo médio de **$T_1 = 1{,}333\text{ ms}$** por consulta no conjunto de validação (`dev`). Ao variar o corte $k$ de documentos reordenados pelo estágio 2 entre $0$ e $50$, as métricas de relevância permaneceram constantes enquanto o custo computacional cresceu linearmente:

| $k$ (Candidatos) | MAP (`dev`) | nDCG (`dev`) | Custo Estágio 2 (ms/consulta) |
| :---: | :---: | :---: | :---: |
| **0** | 0,066 | 0,268 | 0,000 |
| **1** | 0,066 | 0,268 | 0,133 |
| **2** | 0,066 | 0,268 | 0,183 |
| **3** | 0,066 | 0,268 | 0,233 |
| **5** | 0,066 | 0,268 | 0,367 |
| **10** | 0,066 | 0,268 | 0,550 |
| **20** | 0,066 | 0,268 | 0,967 |
| **50** | 0,066 | 0,268 | 2,167 |

A verificação pareada consulta a consulta entre $k = 0$ e $k = 5$ retornou conjuntos vazios tanto para ganhos (`dev[ap1 > ap0]`) quanto para perdas (`dev[ap1 < ap0]`).

---

## 2. Diagnóstico por Consulta no Conjunto `dev`

| Consulta | Texto | Termos Úteis | Docs com Par ($w = 3$) | `max_prox` | Mudou Ordem? |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `q01` | `monumentos historicos centro` | 3 | 0 | 0 | `FALSE` |
| `q02` | `fundacao vila martim afonso` | 4 | 21 | 1 | `TRUE` |
| `q03` | `ponte pensil arquitetura` | 3 | 2 | 1 | `FALSE` |

* **`q01`:** nenhum dos 50 candidatos apresentou pares ordenados dentro da janela $w = 3$, mantendo a fila do BM25 intacta.
* **`q02`:** 21 documentos pontuaram pela expressão frequente *"Martim Afonso"* e houve troca de posições (`mudou_ordem = TRUE`), mas apenas entre documentos não relevantes ou de mesma relevância, sem impacto no `AP`.
* **`q03`:** dois documentos atingiram escore máximo pela ocorrência adjacente de *"Ponte Pênsil"*, porém o estágio 1 (BM25) já os havia posicionado no topo (`mudou_ordem = FALSE`).

---

## 3. Escolha de $k = 0$ e Avaliação Única no Conjunto `teste`

Como o estágio 2 adicionou até **2,167 ms** por consulta (mais que dobrando o tempo do estágio 1) sem ganho de qualidade no `dev`, definiu-se **`k = 0`** (`cfg$rerank_k <- 0` e `cfg$janela <- 3` em `config.R`). Na execução única sobre o conjunto inédito `teste`, o sistema obteve:

| Conjunto | $k$ Escolhido | MAP | nDCG | Tempo Estágio 2 (ms/consulta) |
| :--- | :---: | :---: | :---: | :---: |
| **`dev`** | 0 | 0,066 | 0,268 | 0,000 |
| **`teste`** | 0 | 0,092 | 0,342 | 0,100 |

O desempenho superior no `teste` (**MAP = 0,092** e **nDCG = 0,342**) confirma a capacidade de generalização do estágio 1 sem sobreajuste. O valor residual de **0,100 ms** refere-se apenas ao custo fixo ($c_0$) da chamada da função no R, eliminado no `motor.R` final ao pular a etapa quando `cfg$rerank_k == 0`.