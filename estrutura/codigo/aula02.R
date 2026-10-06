# ==============================================================================
# Script: estrutura/codigo/aula02.R
# Projeto: Motor de Busca - Centro Antigo de São Vicente (PI III)
# Objetivo: Executar as 3 consultas de trabalho e gerar os rankings (TF-IDF)
# ==============================================================================

if (!require("dplyr")) install.packages("dplyr")
if (!require("tidytext")) install.packages("tidytext")
if (!require("stringr")) install.packages("stringr")

library(dplyr)
library(tidytext)
library(stringr)

# 1. Carregar o corpus gerado pelo coletar.R
caminho_docs <- "estrutura/banco-de-dados/docs.rds"

if (!file.exists(caminho_docs)) {
  stop("O arquivo 'docs.rds' não foi encontrado. Execute primeiro o script 'coletar.R'.")
}

docs_df <- readRDS(caminho_docs)
cat("Corpus carregado com sucesso!", nrow(docs_df), "documentos encontrados.\n\n")

# 2. Tokenização e cálculo de Frequência de Termos (TF)
tokens <- docs_df %>%
  select(doc_id, texto) %>%
  unnest_tokens(word, texto) %>%
  # Limpeza simples de numerais e caracteres de pontuação
  filter(!str_detect(word, "^[0-9]+$"))

# Calcular a frequência do termo em cada documento
tf_df <- tokens %>%
  count(doc_id, word, name = "tf")

# 3. Função do Motor de Busca para calcular a pontuação das consultas
buscar <- function(consulta, top_n = 5) {
  # Tokenizar a consulta do usuário
  consulta_tokens <- tibble(texto = consulta) %>%
    unnest_tokens(word, texto) %>%
    pull(word) %>%
    unique()
  
  if (length(consulta_tokens) == 0) {
    return("Consulta vazia ou sem termos válidos.")
  }
  
  cat("======================================================================\n")
  cat("CONSULTA:", consulta, "\n")
  cat("TERMOS BUSCADOS:", paste(consulta_tokens, collapse = ", "), "\n")
  cat("======================================================================\n")
  
  # Filtrar documentos que contêm os termos da consulta e somar o peso (TF)
  resultados <- tf_df %>%
    filter(word %in% consulta_tokens) %>%
    group_by(doc_id) %>%
    summarise(
      score = sum(tf),
      termos_encontrados = paste(unique(word), collapse = ", "),
      .groups = "drop"
    ) %>%
    inner_join(docs_df, by = "doc_id") %>%
    arrange(desc(score)) %>%
    head(top_n)
  
  if (nrow(resultados) == 0) {
    cat("Nenhum resultado encontrado no corpus.\n\n")
    return(NULL)
  }
  
  # Exibir os 5 melhores resultados
  for (i in 1:nrow(resultados)) {
    cat(sprintf("\n[%dº Lugar] Doc ID: %d | Pontuação (Score): %d | Termos: %s\n", 
                i, resultados$doc_id[i], resultados$score[i], resultados$termos_encontrados[i]))
    cat("Trecho:", str_trunc(resultados$texto[i], width = 180), "\n")
  }
  cat("\n")
}

# 4. Execução das Três Consultas de Trabalho do Projeto
consulta_1 <- "Quais são os monumentos históricos do centro de São Vicente?"
consulta_2 <- "História da fundação da Vila de São Vicente e Martim Afonso"
consulta_3 <- "Arquitetura e pontos turísticos culturais no centro antigo"

buscar(consulta_1)
buscar(consulta_2)
buscar(consulta_3)