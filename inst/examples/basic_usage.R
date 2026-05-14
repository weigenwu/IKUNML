library(IKUNML)

data <- read.csv(
  system.file("extdata", "example_data.csv", package = "IKUNML"),
  row.names = 1,
  check.names = FALSE
)

res <- run_feature_selection(
  data = data,
  group_col = "group",
  methods = c("elastic_net", "rf"),
  output_dir = "IKUNML_results",
  seed = 123,
  method_params = list(
    elastic_net = list(alpha = 0.5, lambda_choice = "lambda.min", nfolds = 5),
    rf = list(ntree = 200, cv_ntree = 100, max_features = 5)
  )
)

print(res)
feature_intersection(res)
feature_hit_summary(res)
