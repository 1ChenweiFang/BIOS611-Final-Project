library(tidyverse)
library(xgboost)

mod_val <- read_rds("build_model.rds")

pred_id <- predict(mod_val$bst, mod_val$dtest)   

pred_fac <- factor(mod_val$pred_id,
                   levels = mod_val$levels,
                   labels = mod_val$label_levels)

acc <- mean(pred_fac == mod_val$y_test_fac)
cat("Test Accuracy (xgboost + emb + boro/zip/grade/type/lat/lon) =",
    round(acc, 4), "\n", file = "xgboost_acc.txt") 