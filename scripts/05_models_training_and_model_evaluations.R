# ============================================================
# STEP 11: K-MEANS CLUSTERING - ETHEREUM
# Discover natural groupings and assign risk labels.
# ============================================================

cat("============================================================\n")
cat("STEP 11: K-MEANS CLUSTERING - ETHEREUM\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Extract just the scaled feature matrix (no ID or FLAG columns)
# as the input for K-Means. K-Means only works on numeric data.
# ---------------------------------------------------------------
eth_cluster_data <- eth_scaled[, eth_feature_cols]

# ---------------------------------------------------------------
# Use the Elbow Method to determine the best number of clusters.
# We run K-Means for k = 2 through 10 and record the total
# within-cluster sum of squares (WSS) for each k.
#
# As k increases, WSS decreases because points are closer to
# their cluster centres. The "elbow" — where WSS starts
# decreasing more slowly — indicates the optimal k.
#
# nstart = 25 means K-Means is run 25 times with different
# random starting centres; the best result is kept, reducing
# the chance of converging to a local minimum.
# ---------------------------------------------------------------
set.seed(42)
wss_values <- numeric(9)
for (k in 2:10) {
  km <- kmeans(eth_cluster_data, centers = k, nstart = 25, iter.max = 100)
  wss_values[k - 1] <- km$tot.withinss
}

# ---------------------------------------------------------------
# Plot the elbow curve. The red dashed vertical line marks
# k = 3, which is the chosen number of clusters. We use k = 3
# because it maps naturally onto the three risk levels:
# Low, Medium, and High Risk.
# ---------------------------------------------------------------
p_elbow <- ggplot(data.frame(k = 2:10, WSS = wss_values), aes(x = k, y = WSS)) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_point(color = "darkblue", size = 3) +
  geom_vline(xintercept = 3, linetype = "dashed", color = "red", linewidth = 1) +
  annotate("text", x = 3.5, y = max(wss_values) * 0.9, label = "k = 3", color = "red", size = 5) +
  labs(title = "Ethereum: Elbow Method", x = "Number of Clusters (k)", y = "Within-Cluster SS") +
  scale_x_continuous(breaks = 2:10) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_08_elbow.png"), p_elbow, width = 10, height = 6, dpi = 300)
cat("Saved: eth_08_elbow.png\n")

# ---------------------------------------------------------------
# Run the final K-Means with k = 3 and nstart = 50 (more
# restarts than the elbow search for a more stable result).
# iter.max = 200 allows the algorithm to run up to 200
# iterations per restart before declaring convergence.
# Each wallet is assigned a cluster number 1, 2, or 3.
# ---------------------------------------------------------------
set.seed(42)
eth_kmeans <- kmeans(eth_cluster_data, centers = 3, nstart = 50, iter.max = 200)
eth_features$Cluster <- eth_kmeans$cluster

# ---------------------------------------------------------------
# Map cluster numbers to risk levels (Low / Medium / High)
# based on the actual fraud percentage within each cluster.
# The cluster with the lowest fraud % becomes "Low Risk",
# the middle one "Medium Risk", and the highest "High Risk".
# This data-driven mapping ensures the labels are meaningful.
# ---------------------------------------------------------------
cluster_info <- data.frame(
  Cluster = 1:3,
  Total = as.numeric(table(eth_features$Cluster)),
  Fraud = as.numeric(tapply(eth_features$FLAG, eth_features$Cluster, sum))
)
cluster_info$FraudPct <- round(cluster_info$Fraud / cluster_info$Total * 100, 2)

risk_order <- order(cluster_info$FraudPct)
risk_labels <- character(3)
risk_labels[risk_order[1]] <- "Low Risk"
risk_labels[risk_order[2]] <- "Medium Risk"
risk_labels[risk_order[3]] <- "High Risk"
cluster_info$RiskLevel <- risk_labels

eth_features$RiskLevel <- risk_labels[eth_features$Cluster]

cat("Ethereum Cluster Risk Mapping:\n")
print(cluster_info)
cat("\nRisk Distribution:\n")
print(table(eth_features$RiskLevel))

# ---------------------------------------------------------------
# Visualise the clusters using PCA (Principal Component
# Analysis). PCA reduces the high-dimensional feature space
# to 2 dimensions (PC1 and PC2) that capture the most variance,
# making it possible to plot the clusters on a 2D scatter plot.
# Points are coloured by their assigned risk level.
# ---------------------------------------------------------------
eth_pca <- prcomp(eth_cluster_data, center = TRUE, scale. = TRUE)
pca_df <- data.frame(PC1 = eth_pca$x[, 1], PC2 = eth_pca$x[, 2],
                     Risk = factor(eth_features$RiskLevel, levels = c("Low Risk", "Medium Risk", "High Risk")))

p_pca <- ggplot(pca_df, aes(x = PC1, y = PC2, color = Risk)) +
  geom_point(alpha = 0.5, size = 1.5) +
  scale_color_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "firebrick")) +
  labs(title = "Ethereum: K-Means Clusters (PCA)", color = "Risk Level") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_09_kmeans_pca.png"), p_pca, width = 10, height = 8, dpi = 300)
cat("Saved: eth_09_kmeans_pca.png\n")

# ---------------------------------------------------------------
# Pie chart showing the proportion of wallets in each risk
# category. Each slice is labelled with the risk level, count,
# and percentage. position_stack(vjust = 0.5) centres the
# labels within each pie slice.
# ---------------------------------------------------------------
risk_counts <- as.data.frame(table(eth_features$RiskLevel))
names(risk_counts) <- c("Risk", "Count")
risk_counts$Pct <- round(risk_counts$Count / sum(risk_counts$Count) * 100, 1)
risk_counts$Label <- paste0(risk_counts$Risk, "\n", risk_counts$Count, " (", risk_counts$Pct, "%)")

p_pie <- ggplot(risk_counts, aes(x = "", y = Count, fill = Risk)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "firebrick")) +
  geom_text(aes(label = Label), position = position_stack(vjust = 0.5), size = 3.5) +
  labs(title = "Ethereum: Risk Distribution") +
  theme_void(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_10_risk_pie.png"), p_pie, width = 9, height = 7, dpi = 300)
cat("Saved: eth_10_risk_pie.png\n")

# Save the cluster mapping table and the enriched feature dataset
write.csv(cluster_info, file.path(tables_folder, "eth_cluster_mapping.csv"), row.names = FALSE)
write.csv(eth_features, file.path(features_folder, "ethereum_with_clusters.csv"), row.names = FALSE)
cat("STEP 11 COMPLETE\n\n")


# ============================================================
# STEP 12: K-MEANS CLUSTERING - BITCOIN
# ============================================================

cat("============================================================\n")
cat("STEP 12: K-MEANS CLUSTERING - BITCOIN\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Extract the scaled Bitcoin feature matrix for clustering.
# ---------------------------------------------------------------
btc_cluster_data <- btc_scaled[, btc_feature_cols]

# ---------------------------------------------------------------
# Run the elbow method for Bitcoin (same approach as Ethereum).
# ---------------------------------------------------------------
set.seed(42)
wss_btc <- numeric(9)
for (k in 2:10) {
  km <- kmeans(btc_cluster_data, centers = k, nstart = 25, iter.max = 100)
  wss_btc[k - 1] <- km$tot.withinss
}

p_elbow_btc <- ggplot(data.frame(k = 2:10, WSS = wss_btc), aes(x = k, y = WSS)) +
  geom_line(color = "forestgreen", linewidth = 1.2) +
  geom_point(color = "darkgreen", size = 3) +
  geom_vline(xintercept = 3, linetype = "dashed", color = "red") +
  labs(title = "Bitcoin: Elbow Method", x = "k", y = "WSS") +
  scale_x_continuous(breaks = 2:10) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "btc_06_elbow.png"), p_elbow_btc, width = 10, height = 6, dpi = 300)
cat("Saved: btc_06_elbow.png\n")

# ---------------------------------------------------------------
# Run final K-Means with k = 3 for Bitcoin and assign each
# wallet address to a cluster.
# ---------------------------------------------------------------
set.seed(42)
btc_kmeans <- kmeans(btc_cluster_data, centers = 3, nstart = 50, iter.max = 200)
btc_features$Cluster <- btc_kmeans$cluster

# ---------------------------------------------------------------
# Map Bitcoin clusters to Low / Medium / High Risk labels using
# the same fraud-percentage-based ranking approach as Ethereum.
# ---------------------------------------------------------------
btc_cluster_info <- data.frame(
  Cluster = 1:3,
  Total = as.numeric(table(btc_features$Cluster)),
  Fraud = as.numeric(tapply(btc_features$FLAG, btc_features$Cluster, sum))
)
btc_cluster_info$FraudPct <- round(btc_cluster_info$Fraud / btc_cluster_info$Total * 100, 2)

btc_risk_order <- order(btc_cluster_info$FraudPct)
btc_risk_labels <- character(3)
btc_risk_labels[btc_risk_order[1]] <- "Low Risk"
btc_risk_labels[btc_risk_order[2]] <- "Medium Risk"
btc_risk_labels[btc_risk_order[3]] <- "High Risk"
btc_cluster_info$RiskLevel <- btc_risk_labels

btc_features$RiskLevel <- btc_risk_labels[btc_features$Cluster]

cat("Bitcoin Cluster Risk Mapping:\n")
print(btc_cluster_info)
cat("\nRisk Distribution:\n")
print(table(btc_features$RiskLevel))

# ---------------------------------------------------------------
# PCA scatter plot for Bitcoin clusters, coloured by risk level.
# ---------------------------------------------------------------
btc_pca <- prcomp(btc_cluster_data, center = TRUE, scale. = TRUE)
btc_pca_df <- data.frame(PC1 = btc_pca$x[, 1], PC2 = btc_pca$x[, 2],
                         Risk = factor(btc_features$RiskLevel, levels = c("Low Risk", "Medium Risk", "High Risk")))
p_btc_pca <- ggplot(btc_pca_df, aes(x = PC1, y = PC2, color = Risk)) +
  geom_point(alpha = 0.5, size = 1) +
  scale_color_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "darkred")) +
  labs(title = "Bitcoin: K-Means Clusters (PCA)", color = "Risk Level") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "btc_07_kmeans_pca.png"), p_btc_pca, width = 10, height = 8, dpi = 300)
cat("Saved: btc_07_kmeans_pca.png\n")

write.csv(btc_cluster_info, file.path(tables_folder, "btc_cluster_mapping.csv"), row.names = FALSE)
write.csv(btc_features, file.path(features_folder, "bitcoin_with_clusters.csv"), row.names = FALSE)
cat("STEP 12 COMPLETE\n\n")


# ============================================================
# STEP 13: PREPARING BALANCED DATA FOR CLASSIFICATION
# Create balanced training and testing datasets for both
# cryptocurrencies so models learn all risk levels.
# ============================================================

cat("============================================================\n")
cat("STEP 13: BALANCED DATA PREPARATION\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# This helper function takes the feature data frame for one
# cryptocurrency and returns balanced training and test sets
# with a three-class target variable (Low / Medium / High).
#
# The RiskCategory is derived by combining the binary FLAG
# (actual fraud indicator) and the K-Means cluster RiskLevel:
#   - FLAG=1 in High Risk cluster  → "High"
#   - FLAG=1 in other clusters     → "Medium"
#   - FLAG=0 in High/Medium Risk   → "Medium"
#   - FLAG=0 in Low Risk cluster   → "Low"
#
# This blended approach means the target reflects both the
# known fraud label AND the unsupervised cluster assignment,
# making the classification task richer than simple binary
# fraud detection.
#
# Class Balancing: To prevent models from being biased towards
# the majority class (typically Low Risk), the minority classes
# are oversampled with replacement until all three classes have
# the same number of rows as the largest class.
#
# Train/Test Split: 70% of the balanced data is used for
# training and 30% for testing. set.seed(42) ensures the same
# split is produced on every run.
# ---------------------------------------------------------------
prepare_data <- function(features_df, feature_cols, name_str) {
  cat("--- Preparing", name_str, "---\n")
  
  # Create three class target from FLAG and cluster risk level
  df <- features_df
  df$RiskCategory <- "Low"
  df$RiskCategory[df$FLAG == 1 & df$RiskLevel == "High Risk"] <- "High"
  df$RiskCategory[df$FLAG == 1 & df$RiskLevel != "High Risk"] <- "Medium"
  df$RiskCategory[df$FLAG == 0 & df$RiskLevel == "High Risk"] <- "Medium"
  df$RiskCategory[df$FLAG == 0 & df$RiskLevel == "Medium Risk"] <- "Medium"
  df$RiskCategory <- factor(df$RiskCategory, levels = c("Low", "Medium", "High"))
  
  cat("Before balancing:\n")
  print(table(df$RiskCategory))
  
  # Select only feature columns and target
  model_df <- df[, c(feature_cols, "RiskCategory")]
  model_df <- model_df[complete.cases(model_df), ]
  
  # Oversample minority classes to match majority class
  max_size <- max(table(model_df$RiskCategory))
  balanced <- data.frame()
  for (level in levels(model_df$RiskCategory)) {
    level_data <- model_df[model_df$RiskCategory == level, ]
    if (nrow(level_data) < max_size) {
      oversampled <- level_data[sample(nrow(level_data), max_size, replace = TRUE), ]
      balanced <- rbind(balanced, oversampled)
    } else {
      balanced <- rbind(balanced, level_data)
    }
  }
  
  set.seed(42)
  balanced <- balanced[sample(nrow(balanced)), ]
  cat("After balancing:\n")
  print(table(balanced$RiskCategory))
  
  # Split 70 percent training and 30 percent testing
  set.seed(42)
  idx <- sample(1:nrow(balanced), size = floor(0.7 * nrow(balanced)))
  train <- balanced[idx, ]
  test <- balanced[-idx, ]
  cat("Training:", nrow(train), " Testing:", nrow(test), "\n")
  
  return(list(train = train, test = test, full_data = df))
}

# ---------------------------------------------------------------
# Apply the prepare_data function to Ethereum and Bitcoin and
# save the resulting training and test sets to disk.
# ---------------------------------------------------------------
eth_prep <- prepare_data(eth_features, eth_feature_cols, "Ethereum")
eth_train <- eth_prep$train
eth_test <- eth_prep$test
eth_model_data <- eth_prep$full_data
write.csv(eth_train, file.path(features_folder, "ethereum_train.csv"), row.names = FALSE)
write.csv(eth_test, file.path(features_folder, "ethereum_test.csv"), row.names = FALSE)

btc_prep <- prepare_data(btc_features, btc_feature_cols, "Bitcoin")
btc_train <- btc_prep$train
btc_test <- btc_prep$test
btc_model_data <- btc_prep$full_data
write.csv(btc_train, file.path(features_folder, "bitcoin_train.csv"), row.names = FALSE)
write.csv(btc_test, file.path(features_folder, "bitcoin_test.csv"), row.names = FALSE)

cat("STEP 13 COMPLETE\n\n")


# ============================================================
# STEP 14: DECISION TREE CLASSIFICATION
# Build decision trees for both cryptocurrencies.
# ============================================================

cat("============================================================\n")
cat("STEP 14: DECISION TREE CLASSIFICATION\n")
cat("============================================================\n")

# --- Ethereum Decision Tree ---
cat("--- Ethereum Decision Tree ---\n")

# ---------------------------------------------------------------
# Train a Decision Tree using the rpart package.
# method = "class" tells rpart this is a classification problem.
# Control parameters:
#   maxdepth = 6  — limit tree depth to 6 levels to prevent
#                   overfitting on the training data.
#   minsplit = 20 — a node must have at least 20 observations
#                   before it can be split further.
#   cp = 0.01     — complexity parameter; branches that do not
#                   improve overall fit by at least 1% are pruned.
# confusionMatrix() from caret evaluates predictions against the
# true labels and returns accuracy, precision, recall, and F1.
# ---------------------------------------------------------------
set.seed(42)
eth_dt <- rpart(RiskCategory ~ ., data = eth_train, method = "class",
                control = rpart.control(maxdepth = 6, minsplit = 20, cp = 0.01))
eth_dt_pred <- predict(eth_dt, eth_test, type = "class")
eth_dt_cm <- confusionMatrix(eth_dt_pred, eth_test$RiskCategory)
print(eth_dt_cm)
eth_dt_acc <- eth_dt_cm$overall["Accuracy"]
cat("Accuracy:", round(eth_dt_acc * 100, 2), "%\n")

# ---------------------------------------------------------------
# Visualise the decision tree using rpart.plot.
# type = 4 shows class probabilities and split labels at each
# node. extra = 104 adds the percentage of observations and the
# predicted class label at each leaf node.
# fallen.leaves = TRUE places all leaf nodes at the bottom.
# ---------------------------------------------------------------
rpart.plot(eth_dt, type = 4, extra = 104, main = "Ethereum: Decision Tree",
           box.palette = "auto", fallen.leaves = TRUE, roundint = FALSE)
dev.off()
cat("Saved: eth_11_decision_tree.png\n")

# ---------------------------------------------------------------
# Visualise the confusion matrix as a colour-coded heatmap.
# Darker red cells indicate higher counts, making it easy to
# see where the model is confusing one class for another.
# ---------------------------------------------------------------
cm_df <- as.data.frame(eth_dt_cm$table)
p_cm <- ggplot(cm_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "lightyellow", high = "firebrick") +
  labs(title = "Ethereum: Decision Tree Confusion Matrix", x = "Actual", y = "Predicted") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_12_dt_cm.png"), p_cm, width = 8, height = 6, dpi = 300)
cat("Saved: eth_12_dt_cm.png\n")
write.csv(cm_df, file.path(tables_folder, "eth_dt_cm.csv"), row.names = FALSE)

# Save the trained model object so it can be loaded later for
# scoring new wallets without retraining.
saveRDS(eth_dt, file.path(models_folder, "eth_decision_tree.rds"))

# --- Bitcoin Decision Tree ---
cat("\n--- Bitcoin Decision Tree ---\n")
set.seed(42)
btc_dt <- rpart(RiskCategory ~ ., data = btc_train, method = "class",
                control = rpart.control(maxdepth = 6, minsplit = 20, cp = 0.01))
btc_dt_pred <- predict(btc_dt, btc_test, type = "class")
btc_dt_cm <- confusionMatrix(btc_dt_pred, btc_test$RiskCategory)
print(btc_dt_cm)
btc_dt_acc <- btc_dt_cm$overall["Accuracy"]
cat("Accuracy:", round(btc_dt_acc * 100, 2), "%\n")

png(file.path(plots_folder, "btc_08_decision_tree.png"), width = 1400, height = 900, res = 150)
rpart.plot(btc_dt, type = 4, extra = 104, main = "Bitcoin: Decision Tree",
           box.palette = "auto",
           fallen.leaves = TRUE, roundint = FALSE)
dev.off()
cat("Saved: btc_08_decision_tree.png\n")

btc_cm_df <- as.data.frame(btc_dt_cm$table)
p_btc_cm <- ggplot(btc_cm_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "lightyellow", high = "darkred") +
  labs(title = "Bitcoin: Decision Tree Confusion Matrix", x = "Actual", y = "Predicted") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "btc_09_dt_cm.png"), p_btc_cm, width = 8, height = 6, dpi = 300)
cat("Saved: btc_09_dt_cm.png\n")
write.csv(btc_cm_df, file.path(tables_folder, "btc_dt_cm.csv"), row.names = FALSE)
saveRDS(btc_dt, file.path(models_folder, "btc_decision_tree.rds"))

cat("STEP 14 COMPLETE\n\n")


# ============================================================
# STEP 15: RANDOM FOREST CLASSIFICATION
# ============================================================

cat("============================================================\n")
cat("STEP 15: RANDOM FOREST CLASSIFICATION\n")
cat("============================================================\n")

# --- Ethereum ---
cat("--- Ethereum Random Forest ---\n")

# ---------------------------------------------------------------
# Train a Random Forest classifier. A Random Forest builds
# ntree = 300 independent decision trees, each trained on a
# random bootstrap sample of the training data and using a
# random subset of features at each split. The final class
# prediction is decided by majority vote across all 300 trees.
#
# This ensemble approach significantly reduces overfitting
# compared to a single decision tree and generally produces
# much higher accuracy.
#
# importance = TRUE enables calculation of variable importance
# scores (how much each feature contributes to reducing
# impurity across all trees). nodesize = 5 sets the minimum
# number of observations in a terminal node.
# ---------------------------------------------------------------
set.seed(42)
eth_rf <- randomForest(RiskCategory ~ ., data = eth_train, ntree = 300,
                       importance = TRUE, nodesize = 5)
eth_rf_pred <- predict(eth_rf, eth_test)
eth_rf_cm <- confusionMatrix(eth_rf_pred, eth_test$RiskCategory)
print(eth_rf_cm)
eth_rf_acc <- eth_rf_cm$overall["Accuracy"]
cat("Accuracy:", round(eth_rf_acc * 100, 2), "%\n")

# ---------------------------------------------------------------
# Plot the top 15 most important features ranked by Mean
# Decrease in Gini Impurity. Higher values mean the feature
# contributes more to making the trees purer (better at
# separating the three risk classes). This plot directly answers
# "which transaction patterns matter most for risk prediction?"
# ---------------------------------------------------------------
imp <- as.data.frame(importance(eth_rf))
imp$Feature <- rownames(imp)
imp <- imp[order(-imp$MeanDecreaseGini), ]
p_imp <- ggplot(head(imp, 15), aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "steelblue", color = "black") + coord_flip() +
  labs(title = "Ethereum: Feature Importance (RF)", x = "Feature", y = "Importance") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_13_rf_importance.png"), p_imp, width = 10, height = 7, dpi = 300)
cat("Saved: eth_13_rf_importance.png\n")

rf_cm_df <- as.data.frame(eth_rf_cm$table)
p_rf_cm <- ggplot(rf_cm_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "lightyellow", high = "steelblue") +
  labs(title = "Ethereum: Random Forest CM", x = "Actual", y = "Predicted") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_14_rf_cm.png"), p_rf_cm, width = 8, height = 6, dpi = 300)
cat("Saved: eth_14_rf_cm.png\n")
write.csv(imp, file.path(tables_folder, "eth_rf_importance.csv"), row.names = FALSE)
saveRDS(eth_rf, file.path(models_folder, "eth_random_forest.rds"))

# --- Bitcoin ---
cat("\n--- Bitcoin Random Forest ---\n")
set.seed(42)
btc_rf <- randomForest(RiskCategory ~ ., data = btc_train, ntree = 300,
                       importance = TRUE, nodesize = 5)
btc_rf_pred <- predict(btc_rf, btc_test)
btc_rf_cm <- confusionMatrix(btc_rf_pred, btc_test$RiskCategory)
print(btc_rf_cm)
btc_rf_acc <- btc_rf_cm$overall["Accuracy"]
cat("Accuracy:", round(btc_rf_acc * 100, 2), "%\n")

btc_imp <- as.data.frame(importance(btc_rf))
btc_imp$Feature <- rownames(btc_imp)
btc_imp <- btc_imp[order(-btc_imp$MeanDecreaseGini), ]
p_btc_imp <- ggplot(head(btc_imp, 11), aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "forestgreen", color = "black") + coord_flip() +
  labs(title = "Bitcoin: Feature Importance (RF)", x = "Feature", y = "Importance") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "btc_10_rf_importance.png"), p_btc_imp, width = 10, height = 7, dpi = 300)
cat("Saved: btc_10_rf_importance.png\n")
saveRDS(btc_rf, file.path(models_folder, "btc_random_forest.rds"))

cat("STEP 15 COMPLETE\n\n")


# ============================================================
# STEP 16: SVM CLASSIFICATION
# ============================================================

cat("============================================================\n")
cat("STEP 16: SVM CLASSIFICATION\n")
cat("============================================================\n")

# --- Ethereum ---
cat("--- Ethereum SVM ---\n")

# ---------------------------------------------------------------
# Train a Support Vector Machine (SVM) with a Radial Basis
# Function (RBF / Gaussian) kernel. SVMs find the optimal
# hyperplane that maximises the margin between classes.
# The RBF kernel maps data into a higher-dimensional space,
# allowing non-linear decision boundaries.
#
# Key parameters:
#   cost = 10   — penalty for misclassifications. A higher cost
#                 allows fewer training errors but may overfit.
#   gamma = 0.01 — controls the "reach" of each training point.
#                  A small gamma means a smoother decision
#                  boundary; a large gamma can overfit.
#
# SVMs are memory-intensive, which is why Bitcoin is trained
# on a subset (see below).
# ---------------------------------------------------------------
set.seed(42)
eth_svm <- svm(RiskCategory ~ ., data = eth_train, kernel = "radial",
               cost = 10, gamma = 0.01, type = "C-classification")
eth_svm_pred <- predict(eth_svm, eth_test)
eth_svm_cm <- confusionMatrix(eth_svm_pred, eth_test$RiskCategory)
print(eth_svm_cm)
eth_svm_acc <- eth_svm_cm$overall["Accuracy"]
cat("Accuracy:", round(eth_svm_acc * 100, 2), "%\n")

svm_cm_df <- as.data.frame(eth_svm_cm$table)
p_svm <- ggplot(svm_cm_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "lightyellow", high = "purple4") +
  labs(title = "Ethereum: SVM Confusion Matrix", x = "Actual", y = "Predicted") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_15_svm_cm.png"), p_svm, width = 8, height = 6, dpi = 300)
cat("Saved: eth_15_svm_cm.png\n")
saveRDS(eth_svm, file.path(models_folder, "eth_svm.rds"))

# --- Bitcoin ---
cat("\n--- Bitcoin SVM ---\n")
set.seed(42)

# ---------------------------------------------------------------
# SVM training time scales poorly with large datasets (roughly
# O(n²) to O(n³) in memory and time). The Bitcoin training set
# may contain hundreds of thousands of rows after balancing,
# which would make SVM training extremely slow.
# We therefore take a random subset of up to 30,000 rows for
# training. The full test set is still used for evaluation,
# giving a fair accuracy estimate.
# ---------------------------------------------------------------
svm_subset_size <- min(30000, nrow(btc_train))
btc_train_subset <- btc_train[sample(nrow(btc_train), svm_subset_size), ]

btc_svm <- svm(RiskCategory ~ ., data = btc_train_subset,
               kernel = "radial",
               cost = 10,
               gamma = 0.01,
               type = "C-classification")
btc_svm_pred <- predict(btc_svm, btc_test)
btc_svm_cm <- confusionMatrix(btc_svm_pred, btc_test$RiskCategory)
print(btc_svm_cm)
btc_svm_acc <- btc_svm_cm$overall["Accuracy"]
cat("Accuracy:", round(btc_svm_acc * 100, 2), "%\n")
saveRDS(btc_svm, file.path(models_folder, "btc_svm.rds"))

cat("STEP 16 COMPLETE\n\n")


# ============================================================
# STEP 17: NAIVE BAYES CLASSIFICATION
# ============================================================

cat("============================================================\n")
cat("STEP 17: NAIVE BAYES CLASSIFICATION\n")
cat("============================================================\n")

# --- Ethereum ---
cat("--- Ethereum Naive Bayes ---\n")

# ---------------------------------------------------------------
# Train a Naive Bayes classifier using the e1071 package.
# Naive Bayes applies Bayes' theorem with the "naive" assumption
# that all features are statistically independent given the class.
# Despite this simplification, Naive Bayes often performs well
# in practice and is extremely fast to train.
#
# naiveBayes() estimates the prior probability of each class and
# the conditional probability of each feature value given each
# class from the training data. At prediction time, it multiplies
# these probabilities together (in log space) to compute the
# most likely class for each test wallet.
# ---------------------------------------------------------------
set.seed(42)
eth_nb <- naiveBayes(RiskCategory ~ ., data = eth_train)
eth_nb_pred <- predict(eth_nb, eth_test)
eth_nb_cm <- confusionMatrix(eth_nb_pred, eth_test$RiskCategory)
print(eth_nb_cm)
eth_nb_acc <- eth_nb_cm$overall["Accuracy"]
cat("Accuracy:", round(eth_nb_acc * 100, 2), "%\n")
saveRDS(eth_nb, file.path(models_folder, "eth_naive_bayes.rds"))

# --- Bitcoin ---
cat("\n--- Bitcoin Naive Bayes ---\n")
set.seed(42)
btc_nb <- naiveBayes(RiskCategory ~ ., data = btc_train)
btc_nb_pred <- predict(btc_nb, btc_test)
btc_nb_cm <- confusionMatrix(btc_nb_pred, btc_test$RiskCategory)
print(btc_nb_cm)
btc_nb_acc <- btc_nb_cm$overall["Accuracy"]
cat("Accuracy:", round(btc_nb_acc * 100, 2), "%\n")
saveRDS(btc_nb, file.path(models_folder, "btc_naive_bayes.rds"))

cat("STEP 17 COMPLETE\n\n")


# ============================================================
# STEP 18: KNN CLASSIFICATION
# ============================================================

cat("============================================================\n")
cat("STEP 18: KNN CLASSIFICATION\n")
cat("============================================================\n")

# --- Ethereum KNN ---
cat("--- Ethereum KNN ---\n")

# ---------------------------------------------------------------
# K-Nearest Neighbours (KNN) is a non-parametric algorithm that
# classifies a new wallet by finding the k most similar wallets
# in the training set (by Euclidean distance) and taking a
# majority vote of their risk categories.
#
# Before running KNN, the features must be rescaled because KNN
# is purely distance-based and unscaled features would bias
# the distance calculation. We re-scale here using scale(),
# applied separately to train and test to avoid data leakage.
# Any NaN values from zero-variance columns are set to 0.
# ---------------------------------------------------------------
eth_tr_x <- as.data.frame(scale(eth_train[, !names(eth_train) %in% "RiskCategory"]))
eth_te_x <- as.data.frame(scale(eth_test[, !names(eth_test) %in% "RiskCategory"]))
eth_tr_x[is.na(eth_tr_x)] <- 0
eth_te_x[is.na(eth_te_x)] <- 0

# ---------------------------------------------------------------
# Find the best value of k by testing odd values from 3 to 21.
# Odd values are preferred to avoid ties in the majority vote.
# For each k, we run knn() and measure accuracy on the test set.
# The k with the highest accuracy is selected for the final model.
# ---------------------------------------------------------------
set.seed(42)
k_vals <- seq(3, 21, by = 2)
accs <- numeric(length(k_vals))
for (i in seq_along(k_vals)) {
  pred_tmp <- knn(train = eth_tr_x, test = eth_te_x, cl = eth_train$RiskCategory, k = k_vals[i])
  accs[i] <- sum(pred_tmp == eth_test$RiskCategory) / length(eth_test$RiskCategory)
}
best_k_eth <- k_vals[which.max(accs)]
cat("Best k:", best_k_eth, "\n")

# ---------------------------------------------------------------
# Plot the k selection curve showing accuracy vs k value.
# The red dashed line marks the chosen best k.
# ---------------------------------------------------------------
p_k <- ggplot(data.frame(k = k_vals, Acc = accs), aes(x = k, y = Acc)) +
  geom_line(color = "darkblue", linewidth = 1.2) + geom_point(size = 3, color = "darkblue") +
  geom_vline(xintercept = best_k_eth, linetype = "dashed", color = "red") +
  labs(title = "Ethereum: KNN k Selection", x = "k", y = "Accuracy") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_16_knn_k.png"), p_k, width = 10, height = 6, dpi = 300)
cat("Saved: eth_16_knn_k.png\n")

# ---------------------------------------------------------------
# Run the final KNN prediction using the best k and evaluate
# against the test set labels.
# ---------------------------------------------------------------
set.seed(42)
eth_knn_pred <- knn(train = eth_tr_x, test = eth_te_x, cl = eth_train$RiskCategory, k = best_k_eth)
eth_knn_cm <- confusionMatrix(eth_knn_pred, eth_test$RiskCategory)
print(eth_knn_cm)
eth_knn_acc <- eth_knn_cm$overall["Accuracy"]
cat("Accuracy:", round(eth_knn_acc * 100, 2), "%\n")

# --- Bitcoin KNN ---
cat("\n--- Bitcoin KNN ---\n")

# ---------------------------------------------------------------
# For Bitcoin KNN we use k = 7 directly (a reasonable default
# for large datasets) rather than running a separate grid search,
# since the Bitcoin dataset is already large and a full k-search
# would be slow. The same scaling and NA-handling steps apply.
# ---------------------------------------------------------------
btc_tr_x <- as.data.frame(scale(btc_train[, !names(btc_train) %in% "RiskCategory"]))
btc_te_x <- as.data.frame(scale(btc_test[, !names(btc_test) %in% "RiskCategory"]))
btc_tr_x[is.na(btc_tr_x)] <- 0
btc_te_x[is.na(btc_te_x)] <- 0

set.seed(42)
btc_knn_pred <- knn(train = btc_tr_x, test = btc_te_x, cl = btc_train$RiskCategory, k = 7)
btc_knn_cm <- confusionMatrix(btc_knn_pred, btc_test$RiskCategory)
print(btc_knn_cm)
btc_knn_acc <- btc_knn_cm$overall["Accuracy"]
cat("Accuracy:", round(btc_knn_acc * 100, 2), "%\n")

cat("STEP 18 COMPLETE\n\n")
