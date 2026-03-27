# ============================================================
# STEP 8: EXPLORATORY VISUALIZATIONS - ETHEREUM
# Create comprehensive plots showing distributions,
# correlations, and patterns in the Ethereum data.
# ============================================================

cat("============================================================\n")
cat("STEP 8: EXPLORATORY VISUALIZATIONS - ETHEREUM\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Add a human-readable label column (Legitimate / Fraud) derived
# from the numeric FLAG column. factor() ensures ggplot2 treats
# it as a categorical variable with a defined order. This column
# is used only for plotting and is removed afterwards.
# ---------------------------------------------------------------
eth_features$FLAG_label <- factor(eth_features$FLAG, levels = c(0, 1),
                                  labels = c("Legitimate", "Fraud"))

# ---------------------------------------------------------------
# Plot 1: Bar chart showing the absolute count of legitimate vs
# fraud wallets. geom_text with after_stat(count) adds the exact
# count on top of each bar for easy reading during presentation.
# ---------------------------------------------------------------
p1 <- ggplot(eth_features, aes(x = FLAG_label, fill = FLAG_label)) +
  geom_bar(width = 0.6, color = "black") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5, size = 5) +
  scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
  labs(title = "Ethereum: Fraud vs Legitimate Wallets", x = "Type", y = "Count") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "eth_01_fraud_distribution.png"), p1, width = 8, height = 6, dpi = 300)
cat("Saved: eth_01_fraud_distribution.png\n")

# ---------------------------------------------------------------
# Plot 2: Overlapping histogram of total transaction counts
# for legitimate vs fraud wallets. position = "identity" with
# alpha = 0.7 allows both distributions to be visible at once,
# revealing whether fraudulent wallets tend to have unusually
# high or low transaction volumes.
# ---------------------------------------------------------------
if ("total_transactions" %in% names(eth_features)) {
  p2 <- ggplot(eth_features, aes(x = total_transactions, fill = FLAG_label)) +
    geom_histogram(bins = 50, alpha = 0.7, position = "identity", color = "black", linewidth = 0.2) +
    scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
    labs(title = "Ethereum: Total Transactions Distribution", x = "Total Transactions", y = "Count", fill = "Type") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(file.path(plots_folder, "eth_02_total_transactions.png"), p2, width = 10, height = 6, dpi = 300)
  cat("Saved: eth_02_total_transactions.png\n")
}

# ---------------------------------------------------------------
# Plot 3: Box plot of average Ether value sent, split by fraud
# status. Box plots show the median, interquartile range, and
# outliers, making it easy to spot systematic differences in
# transaction amounts between the two groups.
# ---------------------------------------------------------------
if ("avg.val.sent" %in% names(eth_features)) {
  p3 <- ggplot(eth_features, aes(x = FLAG_label, y = avg.val.sent, fill = FLAG_label)) +
    geom_boxplot(outlier.shape = 21, outlier.fill = "orange") +
    scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
    labs(title = "Ethereum: Average Value Sent", x = "Type", y = "Avg Value Sent") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
  ggsave(file.path(plots_folder, "eth_03_avg_value_sent.png"), p3, width = 8, height = 6, dpi = 300)
  cat("Saved: eth_03_avg_value_sent.png\n")
}

# ---------------------------------------------------------------
# Plot 4: Box plot of total Ether balance. Comparing balances
# between legitimate and fraud accounts can reveal patterns
# such as fraud accounts draining their balance quickly after
# receiving funds.
# ---------------------------------------------------------------
if ("total.ether.balance" %in% names(eth_features)) {
  p4 <- ggplot(eth_features, aes(x = FLAG_label, y = total.ether.balance, fill = FLAG_label)) +
    geom_boxplot(outlier.shape = 21, outlier.fill = "orange") +
    scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
    labs(title = "Ethereum: Ether Balance by Type", x = "Type", y = "Balance") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
  ggsave(file.path(plots_folder, "eth_04_ether_balance.png"), p4, width = 8, height = 6, dpi = 300)
  cat("Saved: eth_04_ether_balance.png\n")
}

# ---------------------------------------------------------------
# Plot 5: Correlation heatmap using corrplot. We limit to the
# first 15 features if there are more, to keep the plot legible.
# cor() computes the Pearson correlation matrix. The "color"
# method fills cells with a red-white-blue gradient where red =
# strong positive, blue = strong negative correlation. This
# helps identify redundant features (highly correlated pairs)
# and potential multicollinearity issues.
# ---------------------------------------------------------------
corr_cols <- eth_feature_cols
if (length(corr_cols) > 15) corr_cols <- corr_cols[1:15]
corr_matrix <- cor(eth_features[, corr_cols], use = "complete.obs")
png(file.path(plots_folder, "eth_05_correlation_heatmap.png"), width = 1200, height = 1000, res = 150)
corrplot(corr_matrix, method = "color", type = "upper", tl.cex = 0.7, tl.col = "black",
         title = "Ethereum: Feature Correlation Heatmap", mar = c(0, 0, 2, 0),
         col = colorRampPalette(c("blue", "white", "red"))(100), addCoef.col = "black", number.cex = 0.5)
dev.off()
cat("Saved: eth_05_correlation_heatmap.png\n")

# ---------------------------------------------------------------
# Plot 6: Scatter plot of Sent transactions vs Received
# transactions, coloured by fraud status. This shows whether
# fraud wallets cluster in a different region of the
# sent/received space compared to legitimate wallets.
# ---------------------------------------------------------------
if ("Sent.tnx" %in% names(eth_features) && "Received.Tnx" %in% names(eth_features)) {
  p6 <- ggplot(eth_features, aes(x = Sent.tnx, y = Received.Tnx, color = FLAG_label)) +
    geom_point(alpha = 0.5, size = 1.5) +
    scale_color_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
    labs(title = "Ethereum: Sent vs Received Transactions", x = "Sent", y = "Received", color = "Type") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(file.path(plots_folder, "eth_06_sent_vs_received.png"), p6, width = 10, height = 7, dpi = 300)
  cat("Saved: eth_06_sent_vs_received.png\n")
}

# ---------------------------------------------------------------
# Plot 7: Density curve of total Ether sent for each class.
# Density plots are smoother than histograms and better reveal
# the overall shape of the distribution, including how much the
# two classes overlap in this feature.
# ---------------------------------------------------------------
if ("total.Ether.sent" %in% names(eth_features)) {
  p7 <- ggplot(eth_features, aes(x = total.Ether.sent, fill = FLAG_label)) +
    geom_density(alpha = 0.6) +
    scale_fill_manual(values = c("Legitimate" = "steelblue", "Fraud" = "firebrick")) +
    labs(title = "Ethereum: Density of Total Ether Sent", x = "Total Ether Sent", y = "Density", fill = "Type") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(file.path(plots_folder, "eth_07_ether_sent_density.png"), p7, width = 10, height = 6, dpi = 300)
  cat("Saved: eth_07_ether_sent_density.png\n")
}

# ---------------------------------------------------------------
# Remove the temporary plotting label column before saving the
# feature dataset, since it is derived and should not be treated
# as an input feature by any model.
# ---------------------------------------------------------------
eth_features$FLAG_label <- NULL

# ---------------------------------------------------------------
# Compute and save a summary statistics table: mean and median
# of the first 8 features grouped by fraud status. This table
# can be included directly in a presentation or report to
# show numeric differences between the two groups.
# ---------------------------------------------------------------
eth_summary <- eth_features %>%
  mutate(Type = ifelse(FLAG == 1, "Fraud", "Legitimate")) %>%
  group_by(Type) %>%
  summarise(across(all_of(eth_feature_cols[1:min(8, length(eth_feature_cols))]),
                   list(Mean = ~round(mean(., na.rm = TRUE), 2),
                        Median = ~round(median(., na.rm = TRUE), 2)),
                   .names = "{.col}_{.fn}"),
            Count = n(), .groups = "drop")
write.csv(eth_summary, file.path(tables_folder, "ethereum_summary_by_type.csv"), row.names = FALSE)
cat("Saved: ethereum_summary_by_type.csv\n")
cat("STEP 8 COMPLETE\n\n")


# ============================================================
# STEP 9: EXPLORATORY VISUALIZATIONS - BITCOIN
# Create plots showing Bitcoin ransomware patterns.
# ============================================================

cat("============================================================\n")
cat("STEP 9: EXPLORATORY VISUALIZATIONS - BITCOIN\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Add a human-readable FLAG label for Bitcoin (Legitimate vs
# Ransomware) to be used in the plots below.
# ---------------------------------------------------------------
btc_features$FLAG_label <- factor(btc_features$FLAG, levels = c(0, 1),
                                  labels = c("Legitimate", "Ransomware"))

# ---------------------------------------------------------------
# Plot 8: Bar chart of Legitimate vs Ransomware addresses in
# the sampled Bitcoin dataset. Gives an immediate sense of
# class balance.
# ---------------------------------------------------------------
p8 <- ggplot(btc_features, aes(x = FLAG_label, fill = FLAG_label)) +
  geom_bar(width = 0.6, color = "black") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5, size = 5) +
  scale_fill_manual(values = c("Legitimate" = "forestgreen", "Ransomware" = "darkred")) +
  labs(title = "Bitcoin: Legitimate vs Ransomware Addresses", x = "Type", y = "Count") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
ggsave(file.path(plots_folder, "btc_01_class_distribution.png"), p8, width = 8, height = 6, dpi = 300)
cat("Saved: btc_01_class_distribution.png\n")

# ---------------------------------------------------------------
# Plot 9: Income distribution histogram. The 'income' feature
# records the total Bitcoin received by an address. Ransomware
# wallets typically receive consistent small amounts (ransom
# payments), which may produce a distinct distribution shape.
# ---------------------------------------------------------------
if ("income" %in% names(btc_features)) {
  p9 <- ggplot(btc_features, aes(x = income, fill = FLAG_label)) +
    geom_histogram(bins = 50, alpha = 0.7, position = "identity", color = "black", linewidth = 0.2) +
    scale_fill_manual(values = c("Legitimate" = "forestgreen", "Ransomware" = "darkred")) +
    labs(title = "Bitcoin: Income Distribution", x = "Income", y = "Count", fill = "Type") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(file.path(plots_folder, "btc_02_income_distribution.png"), p9, width = 10, height = 6, dpi = 300)
  cat("Saved: btc_02_income_distribution.png\n")
}

# ---------------------------------------------------------------
# Plot 10: Box plot of the 'weight' feature by class. 'weight'
# represents the fraction of Bitcoin in the largest single
# transaction relative to total income — a high weight suggests
# the address received one large payment (typical of ransomware
# command-and-control wallets collecting payments).
# ---------------------------------------------------------------
if ("weight" %in% names(btc_features)) {
  p10 <- ggplot(btc_features, aes(x = FLAG_label, y = weight, fill = FLAG_label)) +
    geom_boxplot(outlier.shape = 21, outlier.fill = "orange") +
    scale_fill_manual(values = c("Legitimate" = "forestgreen", "Ransomware" = "darkred")) +
    labs(title = "Bitcoin: Weight by Type", x = "Type", y = "Weight") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"), legend.position = "none")
  ggsave(file.path(plots_folder, "btc_03_weight_boxplot.png"), p10, width = 8, height = 6, dpi = 300)
  cat("Saved: btc_03_weight_boxplot.png\n")
}

# ---------------------------------------------------------------
# Plot 11: Scatter plot of 'neighbors' (number of directly
# connected addresses) vs 'count' (total transactions). Plotting
# these two activity measures against each other, coloured by
# class, can reveal whether ransomware wallets occupy a distinct
# cluster in this 2D space.
# ---------------------------------------------------------------
if ("neighbors" %in% names(btc_features) && "count" %in% names(btc_features)) {
  p11 <- ggplot(btc_features, aes(x = neighbors, y = count, color = FLAG_label)) +
    geom_point(alpha = 0.4, size = 1) +
    scale_color_manual(values = c("Legitimate" = "forestgreen", "Ransomware" = "darkred")) +
    labs(title = "Bitcoin: Neighbors vs Count", x = "Neighbors", y = "Count", color = "Type") +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  ggsave(file.path(plots_folder, "btc_04_neighbors_vs_count.png"), p11, width = 10, height = 7, dpi = 300)
  cat("Saved: btc_04_neighbors_vs_count.png\n")
}

# ---------------------------------------------------------------
# Plot 12: Correlation heatmap for the Bitcoin features. Uses
# a navy-white-darkred colour scale instead of blue-white-red
# to visually distinguish the Bitcoin plots from Ethereum ones.
# ---------------------------------------------------------------
btc_corr <- cor(btc_features[, btc_feature_cols], use = "complete.obs")
png(file.path(plots_folder, "btc_05_correlation_heatmap.png"), width = 1000, height = 900, res = 150)
corrplot(btc_corr, method = "color", type = "upper", tl.cex = 0.8, tl.col = "black",
         title = "Bitcoin: Feature Correlation", mar = c(0, 0, 2, 0),
         col = colorRampPalette(c("navy", "white", "darkred"))(100),
         addCoef.col = "black", number.cex = 0.6)
dev.off()
cat("Saved: btc_05_correlation_heatmap.png\n")

# Remove the temporary FLAG label column before proceeding
btc_features$FLAG_label <- NULL

cat("STEP 9 COMPLETE\n\n")


# ============================================================
# STEP 10: DATA SCALING FOR CLUSTERING
# Normalize features to zero mean and unit variance.
# ============================================================

cat("============================================================\n")
cat("STEP 10: DATA SCALING\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Standardise (z-score normalise) the feature columns so that
# every feature has mean = 0 and standard deviation = 1.
# This is essential for K-Means clustering and KNN because both
# algorithms use Euclidean distance — without scaling, features
# with large numeric ranges (e.g. total Ether balance in the
# thousands) would dominate over features with small ranges
# (e.g. looped, which is 0 or 1).
#
# After scaling, replace any NaN values that arise when a
# column has zero variance (standard deviation = 0) with 0.
# Re-attach the FLAG and wallet ID columns that are not scaled.
# ---------------------------------------------------------------
eth_scaled <- as.data.frame(scale(eth_features[, eth_feature_cols]))
eth_scaled[is.na(eth_scaled)] <- 0
eth_scaled$FLAG <- eth_features$FLAG
eth_scaled$Address <- eth_features$Address
cat("Ethereum scaled:", nrow(eth_scaled), "rows\n")
write.csv(eth_scaled, file.path(features_folder, "ethereum_scaled.csv"), row.names = FALSE)

# ---------------------------------------------------------------
# Apply the same standardisation to the Bitcoin feature columns.
# ---------------------------------------------------------------
btc_scaled <- as.data.frame(scale(btc_features[, btc_feature_cols]))
btc_scaled[is.na(btc_scaled)] <- 0
btc_scaled$FLAG <- btc_features$FLAG
btc_scaled$WalletID <- btc_features$WalletID
cat("Bitcoin scaled:", nrow(btc_scaled), "rows\n")
write.csv(btc_scaled, file.path(features_folder, "bitcoin_scaled.csv"), row.names = FALSE)

cat("STEP 10 COMPLETE\n\n")
