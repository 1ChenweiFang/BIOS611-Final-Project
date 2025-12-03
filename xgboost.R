library(xgboost)
library(pROC)
library(dplyr)

# Load model + data
raw_bytes   <- readRDS("xgb_model.rds")
bst         <- xgb.load.raw(raw_bytes)

X_all        <- readRDS("X_all.rds")
train_idx    <- readRDS("train_idx.rds")
y_all        <- readRDS("y_all.rds")
label_levels <- readRDS("label_levels.rds")
CAMIS_all    <- readRDS("CAMIS_all.rds")

num_class <- length(label_levels)

# Rebuild train / test labels exactly as before
y_train_fac <- y_all[train_idx]
y_test_fac  <- y_all[-train_idx]

# Rebuild test X
X_test     <- X_all[-train_idx, , drop = FALSE]
CAMIS_test <- CAMIS_all[-train_idx]

# Predict on test set
dtest   <- xgb.DMatrix(X_test)
pred_id <- predict(bst, dtest)

pred_fac <- factor(
  pred_id,
  levels = 0:(num_class - 1),
  labels = label_levels
)

xgb_acc <- mean(pred_fac == y_test_fac)
print(xgb_acc)

train_counts   <- table(y_train_fac)
train_majority <- names(which.max(train_counts))

test_counts <- table(y_test_fac)
majority_count_in_test <- as.numeric(test_counts[train_majority])

if (is.na(majority_count_in_test)) majority_count_in_test <- 0

null_acc <- majority_count_in_test / length(y_test_fac)

cat("Major cuisine in TRAIN set is:", train_majority, "\n",
    file = "major.txt", append = FALSE)

cat("Null Accuracy =", round(null_acc, 4), "\n",
    file = "acc.txt", append = FALSE)

cat("XGBoost Accuracy =", round(xgb_acc, 4), "\n",
    file = "acc.txt", append = TRUE)

