# ============================================================
# STEP 19: MODEL COMPARISON
# Compare all five models for both cryptocurrencies.
# ============================================================

cat("============================================================\n")
cat("STEP 19: MODEL COMPARISON\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Compile the accuracy scores of all five models for Ethereum
# into a single data frame, sorted from best to worst.
# This makes it easy to identify the winning model at a glance.
# ---------------------------------------------------------------
eth_comp <- data.frame(
  Model = c("Decision Tree", "Random Forest", "SVM", "Naive Bayes", "KNN"),
  Accuracy = c(round(eth_dt_acc * 100, 2), round(eth_rf_acc * 100, 2),
               round(eth_svm_acc * 100, 2), round(eth_nb_acc * 100, 2),
               round(eth_knn_acc * 100, 2))
)
eth_comp <- eth_comp[order(-eth_comp$Accuracy), ]
cat("Ethereum:\n")
print(eth_comp)
write.csv(eth_comp, file.path(tables_folder, "eth_model_comparison.csv"), row.names = FALSE)

# ---------------------------------------------------------------
# Horizontal bar chart for the Ethereum model comparison.
# reorder() sorts models by accuracy so the best model appears
# at the top. Labels show the exact accuracy percentage.
# ---------------------------------------------------------------
p_ec <- ggplot(eth_comp, aes(x = reorder(Model, Accuracy), y = Accuracy, fill = Model)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(Accuracy, "%")), hjust = -0.2, size = 5, fontface = "bold") +
  coord_flip() + scale_fill_brewer(palette = "Set2") +
  labs(title = "Ethereum: Model Comparison", x = "Model", y = "Accuracy (%)") +
  ylim(0, 105) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "eth_17_model_comparison.png"), p_ec, width = 10, height = 6, dpi = 300)
cat("Saved: eth_17_model_comparison.png\n")

# ---------------------------------------------------------------
# Compute per-class precision, recall, and F1 score for the
# best Ethereum model (Random Forest, or SVM if it scored
# higher). These metrics give a more detailed picture than
# overall accuracy, especially for whether the model performs
# equally well on all three risk levels.
#
# Precision = TP / (TP + FP) — of all wallets predicted High
#             Risk, what fraction were truly High Risk?
# Recall    = TP / (TP + FN) — of all truly High Risk wallets,
#             what fraction did the model catch?
# F1        = 2 * (Precision * Recall) / (Precision + Recall)
#             — harmonic mean of precision and recall.
# ---------------------------------------------------------------
best_eth_cm <- eth_rf_cm
if (eth_svm_acc > eth_rf_acc) best_eth_cm <- eth_svm_cm
eth_class_met <- data.frame(
  RiskLevel = rownames(best_eth_cm$byClass),
  Precision = round(best_eth_cm$byClass[, "Precision"] * 100, 2),
  Recall = round(best_eth_cm$byClass[, "Recall"] * 100, 2),
  F1 = round(best_eth_cm$byClass[, "F1"] * 100, 2)
)
cat("\nEthereum Per-Class Metrics:\n")
print(eth_class_met)
write.csv(eth_class_met, file.path(tables_folder, "eth_per_class_metrics.csv"), row.names = FALSE)

# ---------------------------------------------------------------
# Grouped bar chart showing Precision, Recall, and F1 side by
# side for each risk level. This reveals whether the model is
# well-calibrated or biased towards some classes.
# ---------------------------------------------------------------
met_long <- reshape2::melt(eth_class_met, id.vars = "RiskLevel", variable.name = "Metric", value.name = "Value")
p_met <- ggplot(met_long, aes(x = RiskLevel, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste0(Value, "%")), position = position_dodge(0.9), vjust = -0.5, size = 3.5) +
  scale_fill_manual(values = c("Precision" = "steelblue", "Recall" = "forestgreen", "F1" = "coral")) +
  labs(title = "Ethereum: Per-Class Metrics", x = "Risk Level", y = "Score (%)") + ylim(0, 110) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_18_per_class_metrics.png"), p_met, width = 10, height = 6, dpi = 300)
cat("Saved: eth_18_per_class_metrics.png\n")

# ---------------------------------------------------------------
# Repeat the same model comparison process for Bitcoin.
# ---------------------------------------------------------------
btc_comp <- data.frame(
  Model = c("Decision Tree", "Random Forest", "SVM", "Naive Bayes", "KNN"),
  Accuracy = c(round(btc_dt_acc * 100, 2), round(btc_rf_acc * 100, 2),
               round(btc_svm_acc * 100, 2), round(btc_nb_acc * 100, 2),
               round(btc_knn_acc * 100, 2))
)
btc_comp <- btc_comp[order(-btc_comp$Accuracy), ]
cat("\nBitcoin:\n")
print(btc_comp)
write.csv(btc_comp, file.path(tables_folder, "btc_model_comparison.csv"), row.names = FALSE)

p_bc <- ggplot(btc_comp, aes(x = reorder(Model, Accuracy), y = Accuracy, fill = Model)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(Accuracy, "%")), hjust = -0.2, size = 5, fontface = "bold") +
  coord_flip() + scale_fill_brewer(palette = "Set1") +
  labs(title = "Bitcoin: Model Comparison", x = "Model", y = "Accuracy (%)") + ylim(0, 105) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "btc_11_model_comparison.png"), p_bc, width = 10, height = 6, dpi = 300)
cat("Saved: btc_11_model_comparison.png\n")

best_btc_cm <- btc_rf_cm
if (btc_svm_acc > btc_rf_acc) best_btc_cm <- btc_svm_cm
btc_class_met <- data.frame(
  RiskLevel = rownames(best_btc_cm$byClass),
  Precision = round(best_btc_cm$byClass[, "Precision"] * 100, 2),
  Recall = round(best_btc_cm$byClass[, "Recall"] * 100, 2),
  F1 = round(best_btc_cm$byClass[, "F1"] * 100, 2)
)
cat("\nBitcoin Per-Class Metrics:\n")
print(btc_class_met)
write.csv(btc_class_met, file.path(tables_folder, "btc_per_class_metrics.csv"), row.names = FALSE)

cat("STEP 19 COMPLETE\n\n")
