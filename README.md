# IKUNML

IKUNML 是一个用于组学数据机器学习特征筛选的 R 包。输入一个带分组列的表达矩阵后，可以选择运行 LASSO/elastic net、Boruta、SVM-RFE、RF、caret RFE、GBM、rpart、XGBoost、GA 等方法，并自动导出每种算法的结果文件夹。

## 支持的方法

- `lasso`: 基于 `glmnet`，默认 `alpha = 1`
- `elastic_net`: 基于 `glmnet`，默认 `alpha = 0.5`
- `boruta`: Boruta 随机森林重要性筛选
- `SVM`: 使用旧 `msvmRFE.R` 风格的 multiple SVM-RFE
- `rf`: 随机森林重要性排序 + 交叉验证筛选变量数
- `caret_rfe`: `caret` 通用 RFE 框架，默认随机森林 RFE
- `gbm`: 传统梯度提升树重要性排序 + 交叉验证筛选变量数
- `rpart`: 决策树重要性排序 + 交叉验证筛选变量数
- `xgboost`: XGBoost 重要性排序 + 交叉验证筛选变量数
- `ga`: `caret` 遗传算法特征筛选

## 安装依赖

```r
install.packages(c(
  "glmnet", "Boruta", "e1071", "randomForest", "xgboost",
  "caret", "gbm", "rpart", "doParallel", "UpSetR", "VennDiagram"
))
```

从 GitHub 安装：

```r
install.packages("remotes")
remotes::install_github("weigenwu/IKUNML")
```

## 基本用法

```r
library(IKUNML)

data <- read.csv("data.csv", row.names = 1, check.names = FALSE)

res <- run_feature_selection(
  data = data,
  group_col = "group",
  methods = c("lasso", "boruta", "SVM", "rf", "xgboost"),
  output_dir = "IKUNML_results",
  method_params = list(
    lasso = list(alpha = 1, lambda_choice = "lambda.min"),
    boruta = list(ntree = 5000, maxRuns = 100, pValue = 0.001),
    SVM = list(k = 10, halve_above = 50, max_features = 200, tolerance = 0.02),
    rf = list(ntree = 5000, cv_ntree = 500, max_features = 200, tolerance = 0.02),
    xgboost = list(nrounds = 500, cv_nrounds = 100, max_features = 200, tolerance = 0.02)
  )
)
```

默认会生成 `IKUNML_results/`。每种算法一个子文件夹，例如：

- `IKUNML_results/lasso/`
- `IKUNML_results/boruta/`
- `IKUNML_results/SVM/`
- `IKUNML_results/RF/`
- `IKUNML_results/XGBoost/`

每个方法文件夹会包含：

- `*_selected_features.txt`
- `*_selected_features.csv`
- 该方法的系数、排名、重要性或交叉验证表
- 诊断图的 `.pdf` 和 `.tiff`

根目录还会导出：

- `feature_hit_summary.csv`
- `common_features.txt`
- `method_runtime.csv`

## 进度和耗时

运行时会显示当前跑到哪个算法，以及每个算法耗时：

```text
[IKUNML] (1/3) Starting lasso at 2026-05-14 10:00:00
[IKUNML] (1/3) Finished lasso in 1.24 seconds; selected 8 feature(s)
```

耗时结果保存在：

```r
res$runtimes
```

也会自动写入：

```r
IKUNML_results/method_runtime.csv
```

如果不想显示进度：

```r
res <- run_feature_selection(data, progress = FALSE)
```

## 只跑一个算法

例如只跑 LASSO：

```r
res <- run_feature_selection(
  data,
  group_col = "group",
  methods = "lasso",
  output_dir = "IKUNML_results",
  method_params = list(
    lasso = list(alpha = 1, lambda_choice = "lambda.min")
  )
)
```

会生成 `IKUNML_results/lasso/`，里面包含 LASSO 的 txt/csv 变量列表、系数表、CV 曲线和系数路径图，图片同时有 PDF 和 TIFF。

## 宽容度 tolerance

SVM、RF、XGBoost、GBM、rpart 都支持 `tolerance`。

- SVM：`tolerance` 表示允许误差率比最低误差升高多少。
- RF/XGBoost/GBM/rpart：`tolerance` 表示允许准确率比最高准确率下降多少。

例如 `tolerance = 0.02` 表示允许 2% 的性能宽容，并在可接受范围内用 `prefer = "largest"` 选择变量数最多的方案：

```r
res <- run_feature_selection(
  data,
  group_col = "group",
  methods = c("SVM", "rf", "xgboost"),
  method_params = list(
    SVM = list(tolerance = 0.02, prefer = "largest"),
    rf = list(tolerance = 0.02, prefer = "largest"),
    xgboost = list(tolerance = 0.02, prefer = "largest")
  )
)
```

## SVM-RFE

现在只有一个 SVM 方法名：`SVM`。它内部使用贴近你旧 `msvmRFE.R` 的流程，包括 `k`、`halve_above`、fold-specific ranking 和特征数量 sweep。
旧脚本中的 `halve.above` 也可以继续传入；`cost` 和 `scale` 会被映射到新的 SVM-RFE 排名/性能评估参数。

```r
svm_res <- run_SVM(
  data,
  group_col = "group",
  k = 10,
  halve_above = 50,
  nfolds = 5,
  max_features = 200,
  tune = TRUE,
  tune_ranges = list(gamma = 2^(-12:0), cost = 2^(-6:6)),
  tolerance = 0.02,
  prefer = "largest"
)
```

旧别名 `svm_rfe`、`msvm_rfe`、`msvmrfe` 仍可输入，但都会自动映射到 `SVM`，不会再产生两个 SVM 方法。

## 图片格式

默认导出 PDF 和 TIFF：

```r
res <- run_feature_selection(data, plot_formats = c("pdf", "tiff"), tiff_res = 300)
```

只导出 PDF：

```r
res <- run_feature_selection(data, plot_formats = "pdf")
```

不导出任何文件：

```r
res <- run_feature_selection(data, output_dir = NULL)
```

## 交集和命中次数

```r
common <- feature_intersection(res)
hit_table <- feature_hit_summary(res)

feature_intersection(res, min_hits = 4)
```

## UpSet 和 Venn

```r
plot_upset(res, file = "IKUNML_results/upset.pdf", nintersects = 30)
plot_venn(res, methods = c("lasso", "boruta", "rf"), file = "IKUNML_results/venn.pdf")
```
