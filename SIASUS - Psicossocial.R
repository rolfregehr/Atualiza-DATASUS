rm(list = ls())
library(tidyverse)
library(curl)
library(RCurl)
library(read.dbc)

# Origem dos dados
fonte <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/"

# Define a pasta de destino para os arquivos baixados
destino = "H:/SIASUS_PS/fonte/"                                                         

# Cria o objeto para armazenar nomes e url de
# todos os arquivos dbc

arquivos_ftp <- tibble(arquivo = character(),                                   
                       
                       url = character())                                       



# Armazena nomes url e datas de todos os arquivos no FTP

arquivos_ftp <- bind_rows(arquivos_ftp,
                          tibble(arquivo = 
                                   strsplit(getURL(fonte,
                                                   verbose=TRUE,
                                                   ftp.use.epsv=TRUE,
                                                   dirlistonly = TRUE),
                                            '\\r\\n')[[1]],
                                 data_info = mdy(str_sub(strsplit(getURL(fonte,
                                                               verbose=TRUE,
                                                               ftp.use.epsv=TRUE,
                                                               dirlistonly = F),
                                                        '\\r\\n')[[1]], 1, 10)),
                                 url = fonte))





# Defina os parâmetros
tipo_arq <- 'PS'

# Filtra os arquivos pelo tipo 

arquivos_ftp <- arquivos_ftp %>% 
  filter(str_sub(arquivo, 1, 2) == tipo_arq) %>% 
  mutate(arquivo = toupper(arquivo))
arquivos_h <- toupper(list.files(destino))


# REVISADO ATÈ AQUI!!!!!!!!











arquivos_ftp <- arquivos_ftp %>% filter(!(arquivo %in% arquivos_h))


for(i in 1:nrow(arquivos_ftp)) {                                                # Baixa os arquivos 
  arq <- paste0(arquivos_ftp$url[i],
                arquivos_ftp$arquivo[i])
  download.file(arq,
                destfile = paste0(destino, 
                                  arquivos_ftp$arquivo[i]),
                mode = "wb")
}















# GERA RDA ####
arq_dbc <- toupper(list.files(destino,
                              full.names = T,
                              pattern = ".dbc|.DBC"))                                          

arq_rda <- toupper(list.files('H:/SIASUS/rda/'))


arq_dbc <- arq_dbc[which(!(str_extract(arq_dbc, "[A-Z]{4}[0-9]{4}")  %in% str_extract(arq_rda, "[A-Z]{4}[0-9]{4}")))]


for(arq in arq_dbc){
  temp <- read.dbc(arq)
  save(temp, file = paste0('h:/SIASUS/rda/', str_extract(arq, "[A-Z]{4}[0-9]{4}[A-Z]{0,1}"), '.RDA'))
  print(arq)
}
