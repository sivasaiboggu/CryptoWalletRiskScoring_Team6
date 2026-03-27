
# ============================================================
# STEP 21: COMBINED CRYPTOCURRENCY COMPARISON
# Compare risk patterns between Ethereum and Bitcoin.
# ============================================================

cat("============================================================\n")
cat("STEP 21: COMBINED COMPARISON\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Combine the risk category distributions from both datasets
# into a single data frame for side-by-side comparison.
# Percentage rather than raw count is used so the comparison is
# fair even if the two datasets have different sizes.
# ---------------------------------------------------------------
eth_rc <- as.data.frame(table(eth_results$RiskCategory))
eth_rc$Crypto <- "Ethereum"
btc_rc <- as.data.frame(table(btc_results$RiskCategory))
btc_rc$Crypto <- "Bitcoin"
names(eth_rc) <- names(btc_rc) <- c("RiskCategory", "Count", "Crypto")
combined_risk <- rbind(eth_rc, btc_rc)
combined_risk <- combined_risk %>%
  group_by(Crypto) %>%
  mutate(Pct = round(Count / sum(Count) * 100, 1)) %>%
  ungroup()

p_cr <- ggplot(combined_risk, aes(x = RiskCategory, y = Pct, fill = Crypto)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste0(Pct, "%")), position = position_dodge(0.9), vjust = -0.5, size = 4, fontface = "bold") +
  scale_fill_manual(values = c("Ethereum" = "steelblue", "Bitcoin" = "forestgreen")) +
  labs(title = "Risk Distribution: Ethereum vs Bitcoin", x = "Risk Category", y = "Percentage (%)") +
  ylim(0, max(combined_risk$Pct) * 1.25) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "combined_01_risk_comparison.png"), p_cr, width = 10, height = 6, dpi = 300)
cat("Saved: combined_01_risk_comparison.png\n")

# ---------------------------------------------------------------
# Combined model accuracy chart. Plotting both cryptocurrencies
# side by side allows direct comparison of how consistently
# each algorithm performs across the two very different datasets.
# ---------------------------------------------------------------
combined_acc <- rbind(
  data.frame(eth_comp, Crypto = "Ethereum"),
  data.frame(btc_comp, Crypto = "Bitcoin")
)

p_ca <- ggplot(combined_acc, aes(x = Model, y = Accuracy, fill = Crypto)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste0(Accuracy, "%")), position = position_dodge(0.9), vjust = -0.5, size = 3.5) +
  scale_fill_manual(values = c("Ethereum" = "steelblue", "Bitcoin" = "forestgreen")) +
  labs(title = "Model Accuracy: Ethereum vs Bitcoin", x = "Model", y = "Accuracy (%)") + ylim(0, 105) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(file.path(plots_folder, "combined_02_accuracy.png"), p_ca, width = 12, height = 7, dpi = 300)
cat("Saved: combined_02_accuracy.png\n")

# ---------------------------------------------------------------
# Density plot overlaying the risk score distributions from
# both cryptocurrencies. This shows whether the two blockchains
# have different risk profiles — e.g. Bitcoin might have a
# more bimodal distribution (very low or very high risk) while
# Ethereum's distribution may be more spread out.
# ---------------------------------------------------------------
combined_scores <- rbind(
  data.frame(RiskScore = eth_results$RiskScore, Crypto = "Ethereum"),
  data.frame(RiskScore = btc_results$RiskScore, Crypto = "Bitcoin")
)

p_cd <- ggplot(combined_scores, aes(x = RiskScore, fill = Crypto)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("Ethereum" = "steelblue", "Bitcoin" = "forestgreen")) +
  geom_vline(xintercept = c(33, 66), linetype = "dashed") +
  labs(title = "Risk Score Density: Ethereum vs Bitcoin", x = "Risk Score", y = "Density") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "combined_03_density.png"), p_cd, width = 10, height = 6, dpi = 300)
cat("Saved: combined_03_density.png\n")

# ---------------------------------------------------------------
# Side-by-side fraud detection rate comparison. This is the key
# validation chart: it shows that High Risk wallets contain a
# much higher percentage of actual fraud/ransomware than Low
# Risk wallets, confirming that the risk scoring system works.
# ---------------------------------------------------------------
combined_fd <- rbind(
  data.frame(eth_fd, Crypto = "Ethereum"),
  data.frame(btc_fd, Crypto = "Bitcoin")
)

p_cfd <- ggplot(combined_fd, aes(x = Risk, y = FraudRate, fill = Crypto)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  geom_text(aes(label = paste0(FraudRate, "%")), position = position_dodge(0.9), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Ethereum" = "steelblue", "Bitcoin" = "forestgreen")) +
  labs(title = "Fraud Detection Rate: Ethereum vs Bitcoin", x = "Risk Category", y = "Fraud Rate (%)") +
  ylim(0, max(combined_fd$FraudRate) * 1.3) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
ggsave(file.path(plots_folder, "combined_04_fraud_detection.png"), p_cfd, width = 10, height = 6, dpi = 300)
cat("Saved: combined_04_fraud_detection.png\n")

# Save combined tables
write.csv(combined_risk, file.path(tables_folder, "combined_risk_distribution.csv"), row.names = FALSE)
write.csv(combined_acc, file.path(tables_folder, "combined_model_accuracy.csv"), row.names = FALSE)
write.csv(combined_fd, file.path(tables_folder, "combined_fraud_detection.csv"), row.names = FALSE)

cat("STEP 21 COMPLETE\n\n")
