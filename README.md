# IKUNML

IKUNML 是一个把常见机器学习特征筛选流程封装起来的 R 包，适合表达矩阵、tsRNA、mRNA 等二分类或多分类分组数据。当前封装的方法包括：

- `lasso`: LASSO / elastic net，基于 `glmnet`
- `boruta`: Boruta 随机森林重要性筛选
- `svm_rfe`: 线性 SVM-RFE
- `rf`: 随机森林重要性排序 + 交叉验证确定特征数量
- `xgboost`: XGBoost 重要性排序 + 交叉验证确定特征数量
- `ga`: caret 遗传算法特征筛选

## 安装

从 GitHub 安装：

```r
install.packages("remotes")
remotes::install_github("weigenwu/IKUNML")
```

在当前本地目录安装：

```r
remotes::install_local("C:/Users/Weigen Wu/Desktop/IKUNML")
```

按需安装算法依赖：

```r
install.packages(c(
  "glmnet", "Boruta", "e1071", "randomForest", "xgboost",
  "caret", "doParallel", "UpSetR", "VennDiagram"
))
```

## 数据格式

输入数据应为 `data.frame`，一列是分组，其余列是数值型特征：

```r
data <- read.csv("data.csv", row.names = 1, check.names = FALSE)
head(data[, 1:5])
```

默认分组列名为 `group`。特征名可以包含 `-`、`.` 等字符，IKUNML 内部会转换成 R 安全列名，输出结果会自动还原成原始特征名。

## 一次运行多种方法

```r
library(IKUNML)

data <- read.csv("data.csv", row.names = 1, check.names = FALSE)

res <- run_feature_selection(
  data = data,
  group_col = "group",
  methods = c("lasso", "boruta", "rf", "xgboost"),
  seed = 123,
  output_dir = "IKUNML_results",
  method_params = list(
    lasso = list(
      alpha = 1,
      nfolds = 10,
      lambda_choice = "lambda.min"
    ),
    boruta = list(
      ntree = 5000,
      maxRuns = 100,
      pValue = 0.001
    ),
    rf = list(
      ntree = 5000,
      cv_ntree = 500,
      max_features = 200,
      nfolds = 5,
      tolerance = 0,
      prefer = "largest"
    ),
    xgboost = list(
      nrounds = 500,
      cv_nrounds = 100,
      max_features = 200,
      nfolds = 5,
      tolerance = 0,
      params = list(max_depth = 3, eta = 0.05)
    )
  )
)

res
```

## 单独运行某一种方法

```r
lasso_res <- run_lasso(
  data,
  group_col = "group",
  lambda_choice = "lambda.1se",
  alpha = 1,
  nfolds = 10
)

lasso_res$selected_features
```

## 运行 SVM-RFE 和 GA

这两个方法通常更耗时，建议明确指定参数后单独运行：

```r
svm_res <- run_svm_rfe(
  data,
  group_col = "group",
  nfolds = 5,
  max_features = 200,
  halve_above = 50,
  tolerance = 0
)

ga_res <- run_ga(
  data,
  group_col = "group",
  iters = 100,
  popSize = 50,
  nfolds = 10,
  ntree = 500,
  parallel = TRUE,
  cores = 8
)
```

## 取交集和汇总命中次数

```r
common <- feature_intersection(res)
common

hit_table <- feature_hit_summary(res)
write.csv(hit_table, "IKUNML_results/feature_hit_summary.csv", row.names = FALSE)
```

如果想要“至少被 4 种方法选中”的特征：

```r
feature_intersection(res, min_hits = 4)
```

## 可视化

6 种方法建议使用 UpSet 图：

```r
plot_upset(res, file = "IKUNML_results/upset.pdf", nintersects = 30)
```

5 种及以下方法可以使用 Venn 图：

```r
plot_venn(res, methods = c("lasso", "boruta", "rf"), file = "IKUNML_results/venn.pdf")
```

## 结果文件

设置 `output_dir` 后会自动导出：

- 每种方法的 `*_selected_features.txt`
- LASSO 系数表
- Boruta 统计表
- RF / XGBoost 重要性表和交叉验证结果
- SVM-RFE 排名和交叉验证结果
- `feature_hit_summary.csv`
- `common_features.txt`
