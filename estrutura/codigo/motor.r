# ==============================================================================
# Motor de Busca em Dois Estagios — Grupo Predicarga
# Corpus: Patrimonio Historico e Centro Antigo de Sao Vicente
# ==============================================================================

# 1. Carrega funcoes base de indexacao, BM25, LSA, RRF e metricas
source("https://raw.githubusercontent.com/fractalarea/pi3-motor-de-busca/main/motor/motor08.R")

# 2. Funcoes do Estagio 2 (Reordenamento por Proximidade - Aula 08)
if (!exists("proximidade")) {
  proximidade <- function(qt, doc_tokens, janela = 3) {
    m <- length(qt)
    if (m < 2 || length(doc_tokens) == 0) return(0)
    pos <- lapply(qt, function(t) which(doc_tokens == t))
    pares_ok <- 0
    total_pares <- m * (m - 1) / 2
    for (i in 1:(m - 1)) {
      if (length(pos[[i]]) == 0) next
      for (j in (i + 1):m) {
        if (length(pos[[j]]) == 0) next
        diffs <- outer(pos[[j]], pos[[i]], "-")
        if (any(diffs >= 1 & diffs <= janela)) {
          pares_ok <- pares_ok + 1
        }
      }
    }
    pares_ok / total_pares
  }
}

if (!exists("reordenar")) {
  reordenar <- function(rk, sc, k) {
    if (k <= 1 || length(rk) <= 1) return(rk)
    k <- min(k, length(rk))
    cabeca <- rk[1:k]
    ord <- order(-sc[1:k], seq_len(k))
    c(cabeca[ord], rk[-(1:k)])
  }
}

if (!exists("rerank_prox")) {
  rerank_prox <- function(rk, qt, tokens, k = 10, janela = 3) {
    if (k <= 0 || length(rk) == 0) return(rk)
    k <- min(k, length(rk))
    ids <- names(rk)[1:k]
    sc <- sapply(ids, function(d) proximidade(qt, tokens[[d]], janela))
    reordenar(rk, sc, k)
  }
}

# 3. Estagio 1: Recuperacao base (BM25, LSA ou Hibrido RRF conforme config.R)
estagio1 <- function(texto, ix, cfg, m = NULL) {
  modelo <- if (is.null(cfg$modelo)) "bm25" else cfg$modelo
  rb <- ranking_bm25(texto, ix, cfg)
  if (modelo == "bm25") return(rb)

  if (is.null(m)) {
    lsa_k <- if (is.null(cfg$lsa_k)) 20 else cfg$lsa_k
    m <- lsa(ix, lsa_k)
  }
  rl <- ranking_lsa(texto, ix, cfg, m)
  if (modelo == "lsa") return(rl)

  rrf_c <- if (is.null(cfg$rrf_c)) 60 else cfg$rrf_c
  rrf(rb, rl, c = rrf_c)
}

# 4. Pipeline completo de busca (Estagio 1 + Estagio 2 condicional)
buscar <- function(texto, ix, cfg, m = NULL) {
  rk <- estagio1(texto, ix, cfg, m)

  k_rerank <- if (is.null(cfg$rerank_k)) 0 else cfg$rerank_k
  janela   <- if (is.null(cfg$janela))   3 else cfg$janela

  # Executa o Estagio 2 apenas quando rerank_k > 0 (evita overhead c0 quando k = 0)
  if (k_rerank > 0) {
    qt <- preparar(texto, cfg)
    rk <- rerank_prox(rk, qt, ix$tokens, k = k_rerank, janela = janela)
  }

  rk
}

# --- Exemplo de uso apos carregar config.R, corpus.csv e montar(docs, cfg) ---
# source("estrutura/codigo/config.R")
# res <- buscar("ponte pensil arquitetura", ix, cfg)
# head(res, 5)