# ============================================================
# STEP 20: FINAL RISK SCORING
# Assign risk scores (0 to 100) using the best model.
# ============================================================

cat("============================================================\n")
cat("STEP 20: FINAL RISK SCORING\n")
cat("============================================================\n")

# --- Ethereum ---
cat("--- Ethereum Risk Scores ---\n")

# ---------------------------------------------------------------
# Compute a continuous risk score (0–100) for every Ethereum
# wallet using the Random Forest's class probability estimates.
# predict(..., type = "prob") returns a matrix with one column
# per class showing the fraction of trees that voted for each
# class. The risk score is a weighted sum:
#
#   RiskScore = Prob(Low) × 0  +  Prob(Medium) × 50  +  Prob(High) × 100
#
# A wallet with 100% confidence in Low Risk scores 0.
# A wallet with 100% confidence in High Risk scores 100.
# Wallets with mixed probabilities get intermediate scores,
# providing a nuanced measure of risk rather than just a label.
#
# The continuous score is then bucketed:
#   0–32  → "Low Risk"
#  33–65  → "Medium Risk"
#  66–100 → "High Risk"
# ---------------------------------------------------------------
eth_mf <- eth_model_data[, c(eth_feature_cols, "RiskCategory")]
eth_mf <- eth_mf[complete.cases(eth_mf), ]
eth_prob <- predict(eth_rf, eth_mf, type = "prob")
eth_risk_score <- round(eth_prob[, "Low"] * 0 + eth_prob[, "Medium"] * 50 + eth_prob[, "High"] * 100, 2)
eth_final_risk <- ifelse(eth_risk_score < 33, "Low Risk",
                         ifelse(eth_risk_score < 66, "Medium Risk", "High Risk"))

n_eth <- min(length(eth_risk_score), nrow(eth_features))
eth_results <- data.frame(
  Address = eth_features$Address[1:n_eth],
  RiskScore = eth_risk_score[1:n_eth],
  RiskCategory = eth_final_risk[1:n_eth],
  Prob_Low = round(eth_prob[1:n_eth, "Low"], 4),
  Prob_Medium = round(eth_prob[1:n_eth, "Medium"], 4),
  Prob_High = round(eth_prob[1:n_eth, "High"], 4),
  ActualFraud = eth_features$FLAG[1:n_eth],
  stringsAsFactors = FALSE
)

cat("Ethereum Risk Distribution:\n")
print(table(eth_results$RiskCategory))
write.csv(eth_results, file.path(results_folder, "ethereum_final_risk_scores.csv"), row.names = FALSE)
cat("Saved: ethereum_final_risk_scores.csv\n")

# ---------------------------------------------------------------
# Histogram of the final risk scores coloured by category, with
# dashed vertical lines at the 33 and 66 score boundaries.
# ---------------------------------------------------------------
eth_results$RiskCat <- factor(eth_results$RiskCategory, levels = c("Low Risk", "Medium Risk", "High Risk"))
p_rs <- ggplot(eth_results, aes(x = RiskScore, fill = RiskCat)) +
  geom_histogram(bins = 50, color = "black", linewidth = 0.2) +
  scale_fill_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "firebrick")) +
  geom_vline(xintercept = c(33, 66), linetype = "dashed") +
  labs(title = "Ethereum: Risk Score Distribution", x = "Risk Score (0-100)", y = "Count", fill = "Category") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "eth_19_risk_scores.png"), p_rs, width = 10, height = 6, dpi = 300)
cat("Saved: eth_19_risk_scores.png\n")

# ---------------------------------------------------------------
# Box plot comparing risk scores against the ground-truth fraud
# label. If the scoring system is working correctly, fraud
# wallets should have significantly higher risk scores than
# legitimate wallets.
# ---------------------------------------------------------------
eth_results$ActualLabel <- factor(eth_results$ActualFraud, levels = c(0, 1), labels = c("Legitimate", "Fraud"))
p_va <- ggplot(eth_results, aes(x = ActualLabel, y = RiskScore, fill = ActualLabel)) +
  geom_boxplot() +
  scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
  geom_hline(yintercept = c(33, 66), linetype = "dashed") +
  labs(title = "Ethereum: Risk Score vs Actual Label", x = "Actual", y = "Risk Score") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "eth_20_risk_vs_actual.png"), p_va, width = 8, height = 6, dpi = 300)
cat("Saved: eth_20_risk_vs_actual.png\n")

# ---------------------------------------------------------------
# Compute fraud detection effectiveness: for each risk category,
# count how many wallets it contains and how many of those are
# actually fraudulent. The FraudRate column tells us what
# percentage of High/Medium/Low Risk wallets are truly fraudulent.
# A good system should have a very high fraud rate in High Risk
# and a very low fraud rate in Low Risk.
# ---------------------------------------------------------------
eth_fd <- data.frame(
  Risk = c("High Risk", "Medium Risk", "Low Risk"),
  Total = c(sum(eth_results$RiskCategory == "High Risk"),
            sum(eth_results$RiskCategory == "Medium Risk"),
            sum(eth_results$RiskCategory == "Low Risk")),
  Frauds = c(sum(eth_results$RiskCategory == "High Risk" & eth_results$ActualFraud == 1),
             sum(eth_results$RiskCategory == "Medium Risk" & eth_results$ActualFraud == 1),
             sum(eth_results$RiskCategory == "Low Risk" & eth_results$ActualFraud == 1))
)
eth_fd$FraudRate <- round(eth_fd$Frauds / pmax(eth_fd$Total, 1) * 100, 2)
cat("Ethereum Fraud Detection:\n")
print(eth_fd)
write.csv(eth_fd, file.path(tables_folder, "eth_fraud_detection.csv"), row.names = FALSE)

p_fd <- ggplot(eth_fd, aes(x = Risk, y = FraudRate, fill = Risk)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(FraudRate, "%")), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "firebrick")) +
  labs(title = "Ethereum: Fraud Rate by Risk Category", x = "Category", y = "Fraud Rate (%)") +
  ylim(0, max(eth_fd$FraudRate) * 1.3) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "eth_21_fraud_rate.png"), p_fd, width = 8, height = 6, dpi = 300)
cat("Saved: eth_21_fraud_rate.png\n")

# ---------------------------------------------------------------
# Extract and save the top 20 highest-risk Ethereum wallets
# sorted by descending risk score. This is the actionable output
# of the system — these are the wallets that should be
# investigated or flagged by analysts first.
# ---------------------------------------------------------------
top20_eth <- eth_results[order(-eth_results$RiskScore), ][1:20, ]
write.csv(top20_eth, file.path(tables_folder, "eth_top20_risky.csv"), row.names = FALSE)
cat("Saved: eth_top20_risky.csv\n")

# --- Bitcoin ---
cat("\n--- Bitcoin Risk Scores ---\n")

# ---------------------------------------------------------------
# Apply the same weighted probability risk scoring approach to
# all Bitcoin wallet addresses using the trained Bitcoin RF model.
# ---------------------------------------------------------------
btc_mf <- btc_model_data[, c(btc_feature_cols, "RiskCategory")]
btc_mf <- btc_mf[complete.cases(btc_mf), ]
btc_prob <- predict(btc_rf, btc_mf, type = "prob")
btc_risk_score <- round(btc_prob[, "Low"] * 0 + btc_prob[, "Medium"] * 50 + btc_prob[, "High"] * 100, 2)
btc_final_risk <- ifelse(btc_risk_score < 33, "Low Risk",
                         ifelse(btc_risk_score < 66, "Medium Risk", "High Risk"))

n_btc <- min(length(btc_risk_score), nrow(btc_features))
btc_results <- data.frame(
  WalletID = btc_features$WalletID[1:n_btc],
  RiskScore = btc_risk_score[1:n_btc],
  RiskCategory = btc_final_risk[1:n_btc],
  Prob_Low = round(btc_prob[1:n_btc, "Low"], 4),
  Prob_Medium = round(btc_prob[1:n_btc, "Medium"], 4),
  Prob_High = round(btc_prob[1:n_btc, "High"], 4),
  ActualFraud = btc_features$FLAG[1:n_btc],
  stringsAsFactors = FALSE
)

cat("Bitcoin Risk Distribution:\n")
print(table(btc_results$RiskCategory))
write.csv(btc_results, file.path(results_folder, "bitcoin_final_risk_scores.csv"), row.names = FALSE)
cat("Saved: bitcoin_final_risk_scores.csv\n")

btc_results$RiskCat <- factor(btc_results$RiskCategory, levels = c("Low Risk", "Medium Risk", "High Risk"))
p_btc_rs <- ggplot(btc_results, aes(x = RiskScore, fill = RiskCat)) +
  geom_histogram(bins = 50, color = "black", linewidth = 0.2) +
  scale_fill_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "darkred")) +
  geom_vline(xintercept = c(33, 66), linetype = "dashed") +
  labs(title = "Bitcoin: Risk Score Distribution", x = "Risk Score", y = "Count", fill = "Category") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "btc_12_risk_scores.png"), p_btc_rs, width = 10, height = 6, dpi = 300)
cat("Saved: btc_12_risk_scores.png\n")

btc_fd <- data.frame(
  Risk = c("High Risk", "Medium Risk", "Low Risk"),
  Total = c(sum(btc_results$RiskCategory == "High Risk"),
            sum(btc_results$RiskCategory == "Medium Risk"),
            sum(btc_results$RiskCategory == "Low Risk")),
  Frauds = c(sum(btc_results$RiskCategory == "High Risk" & btc_results$ActualFraud == 1),
             sum(btc_results$RiskCategory == "Medium Risk" & btc_results$ActualFraud == 1),
             sum(btc_results$RiskCategory == "Low Risk" & btc_results$ActualFraud == 1))
)
btc_fd$FraudRate <- round(btc_fd$Frauds / pmax(btc_fd$Total, 1) * 100, 2)
cat("Bitcoin Fraud Detection:\n")
print(btc_fd)
write.csv(btc_fd, file.path(tables_folder, "btc_fraud_detection.csv"), row.names = FALSE)

p_btc_fd <- ggplot(btc_fd, aes(x = Risk, y = FraudRate, fill = Risk)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(FraudRate, "%")), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Low Risk" = "forestgreen", "Medium Risk" = "orange", "High Risk" = "darkred")) +
  labs(title = "Bitcoin: Fraud Rate by Risk Category", x = "Category", y = "Fraud Rate (%)") +
  ylim(0, max(btc_fd$FraudRate) * 1.3) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "btc_13_fraud_rate.png"), p_btc_fd, width = 8, height = 6, dpi = 300)
cat("Saved: btc_13_fraud_rate.png\n")

# Save the top 20 riskiest Bitcoin addresses for analyst review
top20_btc <- btc_results[order(-btc_results$RiskScore), ][1:20, ]
write.csv(top20_btc, file.path(tables_folder, "btc_top20_risky.csv"), row.names = FALSE)
cat("Saved: btc_top20_risky.csv\n")

cat("STEP 20 COMPLETE\n\n")
