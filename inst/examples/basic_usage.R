library(IKUNML)

data <- read.csv("data.csv", row.names = 1, check.names = FALSE)

res <- run_feature_selection(
  data = data,
  group_col = "group",
  methods = c("elastic_net", "boruta", "rf", "xgboost"),
  output_dir = "IKUNML_results",
  seed = 123,
  method_params = list(
    elastic_net = list(alpha = 0.5, lambda_choice = "lambda.min", nfolds = 10),
    boruta = list(ntree = 5000, pValue = 0.001, maxRuns = 100),
    rf = list(ntree = 5000, cv_ntree = 500, max_features = 200),
    xgboost = list(nrounds = 500, cv_nrounds = 100, max_features = 200)
  )
)

print(res)
feature_intersection(res)
feature_hit_summary(res)
