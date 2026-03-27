# ============================================================
# STEP 6: FEATURE ENGINEERING - ETHEREUM
# Select and create the most relevant features for risk scoring.
# ============================================================

cat("============================================================\n")
cat("STEP 6: FEATURE ENGINEERING - ETHEREUM\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Identify all numeric columns in the cleaned Ethereum data,
# excluding the FLAG label column which is the target, not
# a predictor feature.
# ---------------------------------------------------------------
eth_numeric <- names(eth_clean)[sapply(eth_clean, is.numeric)]
eth_numeric <- eth_numeric[eth_numeric != "FLAG"]

# ---------------------------------------------------------------
# Specify the preferred set of domain-relevant features.
# These columns describe the transaction behaviour of each
# Ethereum wallet in terms of timing, volume, and ERC20
# token activity — all of which are known fraud indicators
# in the academic literature on blockchain analytics.
# ---------------------------------------------------------------
desired_features <- c(
  "Avg.min.between.sent.tnx",
  "Avg.min.between.received.tnx",
  "Time.Diff.between.first.and.last..Mins.",
  "Sent.tnx",
  "Received.Tnx",
  "Number.of.Created.Contracts",
  "max.value.received..",
  "avg.val.received",
  "avg.val.sent",
  "total.Ether.sent",
  "total.ether.received",
  "total.ether.balance",
  "Total.ERC20.tnxs",
  "ERC20.total.Ether.received",
  "ERC20.total.ether.sent",
  "ERC20.uniq.sent.addr",
  "ERC20.uniq.rec.addr"
)

# ---------------------------------------------------------------
# Check which of the desired features actually exist in the
# dataset (different dataset versions may have different names).
# If fewer than 5 are found, fall back to using all numeric
# columns to ensure the models have enough input to work with.
# ---------------------------------------------------------------
available_features <- desired_features[desired_features %in% names(eth_clean)]
cat("Features found:", length(available_features), "out of", length(desired_features), "\n")

# If not enough features found use all numeric columns
if (length(available_features) < 5) {
  available_features <- eth_numeric
}

# ---------------------------------------------------------------
# Build a focused feature data frame containing only the wallet
# address identifier, the selected feature columns, and FLAG.
# ---------------------------------------------------------------
eth_features <- eth_clean[, c("Address", available_features, "FLAG")]

# ---------------------------------------------------------------
# Create three engineered features that capture behavioural
# ratios not directly present in the raw data:
#
#   sent_received_ratio: how many transactions a wallet sends
#     relative to what it receives. Fraud accounts often send
#     far more than they receive (money dispersal pattern).
#
#   total_transactions: overall activity level of the wallet.
#
#   ether_flow_ratio: ratio of Ether sent to Ether received.
#     A high ratio may indicate a wallet used to funnel funds.
#
# ifelse() guards against division by zero by using the
# numerator directly when the denominator is zero.
# ---------------------------------------------------------------
if ("Sent.tnx" %in% names(eth_features) && "Received.Tnx" %in% names(eth_features)) {
  eth_features$sent_received_ratio <- ifelse(eth_features$Received.Tnx > 0,
                                             eth_features$Sent.tnx / eth_features$Received.Tnx,
                                             eth_features$Sent.tnx)
  eth_features$total_transactions <- eth_features$Sent.tnx + eth_features$Received.Tnx
  cat("Created: sent_received_ratio, total_transactions\n")
}

if ("total.Ether.sent" %in% names(eth_features) && "total.ether.received" %in% names(eth_features)) {
  eth_features$ether_flow_ratio <- ifelse(eth_features$total.ether.received > 0,
                                          eth_features$total.Ether.sent / eth_features$total.ether.received,
                                          eth_features$total.Ether.sent)
  cat("Created: ether_flow_ratio\n")
}

# ---------------------------------------------------------------
# Winsorise (cap) extreme outliers at the 1st and 99th
# percentiles. Transaction data often contains astronomical
# outliers (e.g. one whale wallet with billions of ETH) that
# would dominate distance-based algorithms like K-Means and KNN.
# Capping at the 1st/99th percentile retains the shape of the
# distribution while removing the most extreme values.
# ---------------------------------------------------------------
eth_feature_cols <- names(eth_features)[sapply(eth_features, is.numeric)]
eth_feature_cols <- eth_feature_cols[eth_feature_cols != "FLAG"]

for (col in eth_feature_cols) {
  upper <- quantile(eth_features[[col]], 0.99, na.rm = TRUE)
  lower <- quantile(eth_features[[col]], 0.01, na.rm = TRUE)
  eth_features[[col]] <- pmin(pmax(eth_features[[col]], lower), upper)
}

# ---------------------------------------------------------------
# Replace any remaining NA values with 0. After outlier capping,
# NAs can appear if a column's 1st and 99th percentile are
# identical (zero-variance column). Setting these to 0 is safe
# because a zero-variance column will be uninformative anyway.
# ---------------------------------------------------------------
eth_features[is.na(eth_features)] <- 0

cat("Ethereum features:", nrow(eth_features), "rows,", length(eth_feature_cols), "features\n")

# Save features
write.csv(eth_features, file.path(features_folder, "ethereum_features.csv"), row.names = FALSE)
cat("Saved: ethereum_features.csv\n")
cat("STEP 6 COMPLETE\n\n")


# ============================================================
# STEP 7: FEATURE ENGINEERING - BITCOIN
# Select and prepare Bitcoin features for risk scoring.
# ============================================================

cat("============================================================\n")
cat("STEP 7: FEATURE ENGINEERING - BITCOIN\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Subset the sampled Bitcoin data to keep only the wallet ID,
# the raw feature columns, and the binary FLAG label.
# ---------------------------------------------------------------
btc_features <- btc_sampled[, c("WalletID", available_btc_features, "FLAG")]

# ---------------------------------------------------------------
# Engineer three new ratio features specific to Bitcoin
# transaction behaviour:
#
#   income_per_tx: average Bitcoin received per transaction.
#     Ransomware wallets typically receive fixed ransom amounts,
#     giving them a distinctive income_per_tx pattern.
#
#   weight_neighbor_ratio: the 'weight' feature measures the
#     fraction of coins in the largest transaction. Dividing by
#     the number of neighbours (connected addresses) normalises
#     for wallet connectivity.
#
#   length_count_ratio: 'length' is the longest chain of
#     transactions. Dividing by the number of transactions gives
#     the average depth per transaction, a potential indicator
#     of how deeply funds are being routed through the network.
# ---------------------------------------------------------------
if ("income" %in% names(btc_features) && "count" %in% names(btc_features)) {
  btc_features$income_per_tx <- ifelse(btc_features$count > 0,
                                       btc_features$income / btc_features$count, 0)
  cat("Created: income_per_tx\n")
}

if ("weight" %in% names(btc_features) && "neighbors" %in% names(btc_features)) {
  btc_features$weight_neighbor_ratio <- ifelse(btc_features$neighbors > 0,
                                               btc_features$weight / btc_features$neighbors, 0)
  cat("Created: weight_neighbor_ratio\n")
}

if ("length" %in% names(btc_features) && "count" %in% names(btc_features)) {
  btc_features$length_count_ratio <- ifelse(btc_features$count > 0,
                                            btc_features$length / btc_features$count, 0)
  cat("Created: length_count_ratio\n")
}

# ---------------------------------------------------------------
# Collect the names of all numeric Bitcoin feature columns
# (excluding FLAG) for use in downstream steps.
# ---------------------------------------------------------------
btc_feature_cols <- names(btc_features)[sapply(btc_features, is.numeric)]
btc_feature_cols <- btc_feature_cols[btc_feature_cols != "FLAG"]

# ---------------------------------------------------------------
# Apply the same 1st/99th percentile winsorisation as done for
# Ethereum to remove extreme outliers from the Bitcoin features.
# ---------------------------------------------------------------
for (col in btc_feature_cols) {
  upper <- quantile(btc_features[[col]], 0.99, na.rm = TRUE)
  lower <- quantile(btc_features[[col]], 0.01, na.rm = TRUE)
  btc_features[[col]] <- pmin(pmax(btc_features[[col]], lower), upper)
}

# Replace NAs
btc_features[is.na(btc_features)] <- 0

cat("Bitcoin features:", nrow(btc_features), "rows,", length(btc_feature_cols), "features\n")
cat("Feature names:", paste(btc_feature_cols, collapse = ", "), "\n")

# Save features
write.csv(btc_features, file.path(features_folder, "bitcoin_features.csv"), row.names = FALSE)
cat("Saved: bitcoin_features.csv\n")
cat("STEP 7 COMPLETE\n\n")


# ============================================================