library(pROC)
library(dplyr)
library(ggplot2)
library(xgboost)

# Load model + data
raw_bytes   <- readRDS("xgb_model.rds")   
bst         <- xgb.load.raw(raw_bytes)  

X_all        <- readRDS("X_all.rds")
train_idx    <- readRDS("train_idx.rds")
y_all        <- readRDS("y_all.rds")
label_levels <- readRDS("label_levels.rds")
CAMIS_all    <- readRDS("CAMIS_all.rds")

num_class <- length(label_levels)       

# Rebuild test set
X_test     <- X_all[-train_idx, , drop = FALSE]
y_test_fac <- y_all[-train_idx]
CAMIS_test <- CAMIS_all[-train_idx]

dtest <- xgboost::xgb.DMatrix(data = X_test)

pred_prob_vec <- predict(
  bst,
  dtest,
  outputmargin = FALSE
)

n_test <- length(y_test_fac)

pred_prob <- matrix(
  pred_prob_vec,
  nrow = n_test,
  ncol = num_class,
  byrow = TRUE
)

colnames(pred_prob) <- label_levels


top10 <- names(sort(table(y_test_fac), decreasing = TRUE))[1:10]

par(mfrow = c(3, 4))

for (lab in top10) {
  j <- which(label_levels == lab)
  
  response  <- as.numeric(y_test_fac == lab)
  predictor <- pred_prob[, j]
  
  roc_obj <- roc(response, predictor)
  
  plot(
    roc_obj,
    main = paste("ROC -", lab,
                 "AUC =", round(auc(roc_obj), 3)),
    col = "blue",
    lwd = 2
  )
  
  abline(a = 0, b = 1, lty = 2, col = "gray")
}

ggsave("figures/auc.png",plot=last_plot())