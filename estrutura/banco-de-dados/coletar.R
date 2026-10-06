# ==============================================================================
# Script: estrutura/banco-de-dados/coletar.R
# Projeto: Motor de Busca - Centro Antigo de São Vicente (PI III)
# Objetivo: Coletar parágrafos de páginas da Wikipédia sobre São Vicente e
#           gerar o arquivo do corpus (docs.rds)
# ==============================================================================

# Instalar pacotes necessários, se ainda não estiverem instalados
if (!require("rvest")) install.packages("rvest")
if (!require("dplyr")) install.packages("dplyr")

library(rvest)
library(dplyr)

# 1. URLs dos artigos da Wikipédia selecionados para o tema
urls <- c(
  "https://pt.wikipedia.org/wiki/S%C3%A3o_Vicente_(S%C3%A3o_Paulo)",
  "https://pt.wikipedia.org/wiki/Martim_Afonso_de_Sousa",
  "https://pt.wikipedia.org/wiki/Ponte_P%C3%AAnsil_de_S%C3%A3o_Vicente"
)

# 2. Função para extrair e limpar os parágrafos de uma URL
extrair_paragrafos <- function(url) {
  message(paste("Coletando dados de:", url))
  
  html <- read_html(url)
  
  # Extrai todos os elementos de parágrafo (<p>)
  paragrafos <- html %>% 
    html_elements("p") %>% 
    html_text(trim = TRUE)
  
  # Filtra parágrafos vazios ou muito curtos (com menos de 60 caracteres)
  paragrafos <- paragrafos[nchar(paragrafos) > 60]
  
  return(paragrafos)
}

# 3. Execução da coleta de dados
lista_docs <- list()

for (u in urls) {
  pars <- extrair_paragrafos(u)
  if (length(pars) > 0) {
    df <- data.frame(
      url = u,
      texto = pars,
      stringsAsFactors = FALSE
    )
    lista_docs[[u]] <- df
  }
}

# 4. Consolidação do DataFrame e definição do critério de documentos
docs_df <- bind_rows(lista_docs) %>%
  mutate(doc_id = row_number()) %>%
  # Delimita o corpus para ficar dentro da faixa recomendada (20 a 60 documentos)
  slice(1:45)

cat("\n--- Resumo da Coleta ---\n")
cat("Total de documentos (parágrafos) no corpus:", nrow(docs_df), "\n")

# 5. Salvar o arquivo no caminho esperado pelo repositório
dir.create("estrutura/banco-de-dados", showWarnings = FALSE, recursive = TRUE)
saveRDS(docs_df, "estrutura/banco-de-dados/docs.rds")

cat("Corpus salvo com sucesso em: 'estrutura/banco-de-dados/docs.rds'\n")