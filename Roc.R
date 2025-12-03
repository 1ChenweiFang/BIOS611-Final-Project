library(pROC)
dtest <- xgb.DMatrix(data = X_test, label = y_test_id)
pred_vec  <- predict(bst, dtest)   # length = n_test * num_class
n_test    <- length(y_test_fac)

pred_prob <- matrix(
  pred_vec,
  nrow = n_test,
  ncol = num_class,
  byrow = TRUE
)
colnames(pred_prob) <- label_levels

par(mfrow = c(3, 3))
for (i in seq_len(min(9, num_class))) {
  this_label <- label_levels[i]
  
  roc_obj <- roc(
    response  = (y_test_fac == this_label),  # TRUE/FALSE
    predictor = pred_prob[ , i]
  )
  
  plot(
    roc_obj,
    main = paste("ROC -", this_label),
    col  = "blue",
    lwd  = 2
  )
}
ggsave("figures/roc_curve.png",plot=last_plot())