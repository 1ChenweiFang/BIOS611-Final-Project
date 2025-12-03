FROM rocker/verse
RUN R -e "install.packages c('xgboost','glmnet','stringr','tibble','caret','tidyverse','lubridate','dplyr','randomforest','readr','ggplot2','forcats','pROC')"