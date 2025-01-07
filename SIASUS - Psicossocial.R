rm(list = ls())
library(tidyverse)
library(curl)
library(RCurl)
library(read.dbc)

# variáveis iniciais ####
tipo_arq <- 'PS'

# Origem dos dados
fonte <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/"
# Define a pasta de destino para os arquivos baixados
destino = "H:/SIASUS_PS/fonte/"                                                         


# Conexão FTP ####
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
                                 data_ftp = mdy(str_sub(strsplit(getURL(fonte,
                                                               verbose=TRUE,
                                                               ftp.use.epsv=TRUE,
                                                               dirlistonly = F),
                                                        '\\r\\n')[[1]], 1, 10)),
                                 url = fonte))

# Filtra os arquivos pelo tipo 

arquivos_ftp <- arquivos_ftp %>% 
  filter(str_sub(arquivo, 1, 2) == tipo_arq) %>% 
  mutate(arquivo = toupper(arquivo))
arquivos_h <- toupper(list.files(destino))

# Informações dos arquivos locais ####

arquivos_locais <- tibble(arquivo = toupper(list.files(destino)),
                          arquivos_locais = toupper(list.files(destino, full.names = T)),
                          data_local = ymd(str_sub((file.info(arquivos_locais)[, 4]), 1, 10))
                          )

arquivos_download <- left_join(arquivos_ftp,
                               arquivos_locais,
                               by = 'arquivo') |> 
  mutate(baixa = if_else(data_local < data_ftp | is.na(data_local), 1, 0),
         arq = paste0(url, arquivo)) |> 
  filter(baixa == 1) 


# Download ####

arquivos_destino <- paste0(destino ,arquivos_download$arquivo)
arquivos_download <- arquivos_download$arq



for(i in 1:length(arquivos_download)) {                                                # Baixa os arquivos 
  download.file(arquivos_download[i],
                destfile = arquivos_destino[i],
                mode = "wb")
  }



# GERA RDA ####
arq_dbc <- toupper(list.files(destino,
                              full.names = T,
                              pattern = ".dbc|.DBC"))                                          

arq_rda <- toupper(list.files('H:/SIASUS_PS/rda/'))


arq_dbc <- arq_dbc[which(!(str_extract(arq_dbc, "[A-Z]{4}[0-9]{4}")  %in% str_extract(arq_rda, "[A-Z]{4}[0-9]{4}")))]


for(arq in arq_dbc){
  temp <- read.dbc(arq)
  save(temp, file = paste0('h:/SIASUS_PS/rda/', str_extract(arq, "[A-Z]{4}[0-9]{4}[A-Z]{0,1}"), '.RDA'))
  print(arq)
}
