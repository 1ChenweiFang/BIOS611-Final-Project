library(dplyr)
library(stringr)
library(readr)
library(forcats)
library(xgboost)

restaurants <- read_csv("DOHMH_New_York_City_Restaurant_Inspection_Results.csv",
                        col_types = cols(CAMIS = col_character()))

emb <- read_csv("name_embeddings_unique_camis.csv",
                col_types = cols(CAMIS = col_character()))

dat <- restaurants %>%
  mutate(
    CAMIS   = as.character(CAMIS),
    cuisine = str_squish(str_to_lower(`CUISINE DESCRIPTION`)),
    boro    = str_squish(str_to_lower(BORO)),
    zipcode = as.character(ZIPCODE),
    grade   = as.character(GRADE),
    insptype = str_squish(str_to_lower(`INSPECTION TYPE`)),
    lat     = as.numeric(Latitude),
    lon     = as.numeric(Longitude)
  ) %>%
  distinct(CAMIS, .keep_all = TRUE) %>%   
  inner_join(emb, by = "CAMIS") %>%       # 合并 embedding
  filter(
    !is.na(cuisine), cuisine != "",
    !is.na(boro),    boro    != ""
  )

## ---- 2. 去掉样本特别少的菜系 ----
table_cuisine <- table(dat$cuisine)
rare_class <- names(table_cuisine[table_cuisine < 5])  # 阈值可调

dat2 <- dat %>%
  filter(!cuisine %in% rare_class)

cat("剩余菜系数量：", length(unique(dat2$cuisine)), "\n")
cat("样本数量：", nrow(dat2), "\n")

## ---- 3. 结构化特征预处理（不含 score） ----

# 3.1 ZIPCODE：只保留高频前 50 个，其余合并为 "other"
top_zip <- names(
  sort(table(dat2$zipcode), decreasing = TRUE)
)[1:50]

dat2 <- dat2 %>%
  mutate(
    zipcode_grp = if_else(zipcode %in% top_zip, zipcode, "other")
  )

# 3.2 INSPECTION TYPE：只保留高频前 30 个，其余合并为 "other"
top_insptype <- names(
  sort(table(dat2$insptype), decreasing = TRUE)
)[1:30]

dat2 <- dat2 %>%
  mutate(
    insptype_grp = if_else(insptype %in% top_insptype, insptype, "other")
  )

# 3.3 GRADE：显式标记缺失
dat2 <- dat2 %>%
  mutate(
    grade = fct_explicit_na(as.factor(grade), na_level = "missing")
  )

# 3.4 经纬度：标准化 + 用 0 填补 NA（0 代表“平均附近”）
lat_mean <- mean(dat2$lat, na.rm = TRUE)
lat_sd   <- sd(dat2$lat, na.rm = TRUE)
lon_mean <- mean(dat2$lon, na.rm = TRUE)
lon_sd   <- sd(dat2$lon, na.rm = TRUE)

dat2 <- dat2 %>%
  mutate(
    lat_z = (lat - lat_mean) / lat_sd,
    lon_z = (lon - lon_mean) / lon_sd,
    lat_z = if_else(is.na(lat_z), 0, lat_z),
    lon_z = if_else(is.na(lon_z), 0, lon_z)
  )

## ---- 4. embedding + boro + zipcode + grade + insptype + lat/lon ----

# 4.1 embedding 
X_emb <- as.matrix(dat2 %>% select(starts_with("emb_")))

feat_df <- dat2 %>%
  transmute(
    boro         = factor(boro),
    zipcode      = factor(zipcode_grp),
    grade        = grade,             
    insptype     = factor(insptype_grp),
    lat_z        = lat_z,
    lon_z        = lon_z
  )

X_struct <- model.matrix(~ . - 1, data = feat_df) 

X_all <- cbind(X_emb, X_struct)
y_all <- factor(dat2$cuisine)
label_levels <- levels(y_all)
num_class <- length(label_levels)

cat("dimension：", ncol(X_all), "\n")



set.seed(123)
n <- nrow(X_all)
train_idx <- sample(n, size = 0.8 * n)

X_train <- X_all[train_idx, , drop = FALSE]
X_test  <- X_all[-train_idx, , drop = FALSE]

y_train_fac <- y_all[train_idx]
y_test_fac  <- y_all[-train_idx]

# xgboost label: 0,1,...,K-1
y_train_id <- as.integer(y_train_fac) - 1L
y_test_id  <- as.integer(y_test_fac)  - 1L



dtrain <- xgb.DMatrix(data = X_train, label = y_train_id)
dtest  <- xgb.DMatrix(data = X_test,  label = y_test_id)

watchlist <- list(train = dtrain, eval = dtest)

params <- list(
  objective        = "multi:softmax",
  num_class        = num_class,
  eval_metric      = "merror",
  max_depth        = 6,
  eta              = 0.1,
  subsample        = 0.8,
  colsample_bytree = 0.8
)

set.seed(123)
bst <- xgb.train(
  params  = params,
  data    = dtrain,
  nrounds = 400,               
  watchlist = watchlist,
  early_stopping_rounds = 20  
)


cat("Best iteration:", bst$best_iteration, "\n")


saveRDS(file = "build_model.rds",list(bst = bst,
             dtest = dtest,
             levels = 0:(num_class-1),
             y_test_fac = y_test_fac,
             label_levels = label_levels))
