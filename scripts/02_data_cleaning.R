
# ============================================================
# STEP 4: DATA CLEANING - ETHEREUM
# Remove unnecessary columns, handle missing values,
# remove duplicates, fix data types.
# ============================================================

cat("============================================================\n")
cat("STEP 4: DATA CLEANING - ETHEREUM\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Work on a copy of the raw data so the original eth_data
# object is preserved unchanged for reference.
# ---------------------------------------------------------------
eth_clean <- eth_data

# ---------------------------------------------------------------
# Drop the 'Index' column if it exists — it is just a row
# number added by some export tools and carries no analytical
# value. Similarly, the 'X' column is an artefact that
# sometimes appears when a CSV was exported from R with
# row names enabled.
# ---------------------------------------------------------------
if ("Index" %in% names(eth_clean)) {
  eth_clean$Index <- NULL
  cat("Removed Index column\n")
}

if ("X" %in% names(eth_clean)) {
  eth_clean$X <- NULL
  cat("Removed X column\n")
}

# ---------------------------------------------------------------
# Ensure there is an 'Address' column that uniquely identifies
# each wallet. If the column exists under a different name
# (address, account, etc.) we rename it. If no address-like
# column exists at all, we generate synthetic IDs like ETH_1,
# ETH_2, etc.
# ---------------------------------------------------------------
if (!"Address" %in% names(eth_clean)) {
  addr_cols <- grep("addr|address|account", names(eth_clean), ignore.case = TRUE, value = TRUE)
  if (length(addr_cols) > 0) {
    names(eth_clean)[names(eth_clean) == addr_cols[1]] <- "Address"
  } else {
    eth_clean$Address <- paste0("ETH_", seq_len(nrow(eth_clean)))
  }
}

cat("Unique addresses:", length(unique(eth_clean$Address)), "\n")

# ---------------------------------------------------------------
# Identify all numeric columns. Only numeric columns need the
# infinite-value and missing-value treatments that follow.
# ---------------------------------------------------------------
numeric_cols <- names(eth_clean)[sapply(eth_clean, is.numeric)]
cat("Numeric columns:", length(numeric_cols), "\n")

# ---------------------------------------------------------------
# Some columns may contain Inf or -Inf values (e.g. from
# division-by-zero in the original data). These cannot be used
# in models or distance calculations, so we replace them with
# NA so they can be handled by the imputation step below.
# ---------------------------------------------------------------
for (col in numeric_cols) {
  inf_count <- sum(is.infinite(eth_clean[[col]]))
  if (inf_count > 0) {
    eth_clean[[col]][is.infinite(eth_clean[[col]])] <- NA
    cat("Replaced", inf_count, "infinite values in", col, "\n")
  }
}

# ---------------------------------------------------------------
# Impute remaining NA values with the column median. The median
# is preferred over the mean because it is robust to extreme
# outlier values that are common in financial transaction data.
# ---------------------------------------------------------------
for (col in numeric_cols) {
  na_count <- sum(is.na(eth_clean[[col]]))
  if (na_count > 0) {
    eth_clean[[col]][is.na(eth_clean[[col]])] <- median(eth_clean[[col]], na.rm = TRUE)
    cat("Filled", na_count, "NAs in", col, "\n")
  }
}

# ---------------------------------------------------------------
# Remove completely duplicate rows. Duplicates can bias model
# training by over-representing certain wallets.
# ---------------------------------------------------------------
dup_count <- sum(duplicated(eth_clean))
if (dup_count > 0) {
  eth_clean <- eth_clean[!duplicated(eth_clean), ]
  cat("Removed", dup_count, "duplicates\n")
}

# ---------------------------------------------------------------
# Coerce the FLAG column to integer type and keep only rows
# where FLAG is exactly 0 or 1. This removes any corrupted or
# ambiguous label values that could confuse the classifiers.
# ---------------------------------------------------------------
eth_clean$FLAG <- as.integer(eth_clean$FLAG)
eth_clean <- eth_clean[eth_clean$FLAG %in% c(0, 1), ]

cat("Cleaned Ethereum:", nrow(eth_clean), "rows,", ncol(eth_clean), "columns\n")
cat("FLAG distribution:\n")
print(table(eth_clean$FLAG))

# ---------------------------------------------------------------
# Persist the cleaned dataset to disk so we can reload it
# quickly in future without repeating the cleaning steps.
# ---------------------------------------------------------------
write.csv(eth_clean, file.path(cleaned_data_folder, "ethereum_cleaned.csv"), row.names = FALSE)
cat("Saved: ethereum_cleaned.csv\n")
cat("STEP 4 COMPLETE\n\n")


# ============================================================
# STEP 5: DATA CLEANING - BITCOIN
# Convert ransomware labels to binary fraud flag, handle
# missing values, take a balanced sample for analysis.
# ============================================================

cat("============================================================\n")
cat("STEP 5: DATA CLEANING - BITCOIN\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Work on a copy of the raw Bitcoin data to preserve the original.
# ---------------------------------------------------------------
btc_clean <- btc_data

# ---------------------------------------------------------------
# Convert the multi-class 'label' column (ransomware family
# names vs "white") into a simple binary FLAG:
#   0 = legitimate address (label == "white")
#   1 = ransomware address (any other label)
# This binary flag is used throughout the project as the ground
# truth for fraud/risk evaluation.
# ---------------------------------------------------------------
btc_clean$FLAG <- ifelse(btc_clean$label == "white", 0, 1)

cat("Binary FLAG created:\n")
print(table(btc_clean$FLAG))
cat("Fraud percentage:", round(sum(btc_clean$FLAG == 1) / nrow(btc_clean) * 100, 2), "%\n")

# Keep the original label column for reference but also keep FLAG
# Remove the address column if it is just a hash (too long for display)
# Keep numeric feature columns: year, day, length, weight, count, looped, neighbors, income

# ---------------------------------------------------------------
# Define the set of meaningful numeric features available in
# the Bitcoin Heist dataset. These eight columns describe the
# transaction behaviour of each Bitcoin address.
# ---------------------------------------------------------------
btc_feature_names <- c("year", "day", "length", "weight", "count", "looped", "neighbors", "income")

# ---------------------------------------------------------------
# Some datasets may be missing one or more of these columns
# (e.g. an older version). We intersect with the actual column
# names to get only the features that exist.
# ---------------------------------------------------------------
available_btc_features <- btc_feature_names[btc_feature_names %in% names(btc_clean)]
cat("Available Bitcoin features:", paste(available_btc_features, collapse = ", "), "\n")

# ---------------------------------------------------------------
# Create a wallet identifier column. If the raw data already
# has an 'address' column (the Bitcoin address hash), we use
# it directly. Otherwise we generate sequential IDs.
# ---------------------------------------------------------------
if ("address" %in% names(btc_clean)) {
  btc_clean$WalletID <- btc_clean$address
} else {
  btc_clean$WalletID <- paste0("BTC_", seq_len(nrow(btc_clean)))
}

# ---------------------------------------------------------------
# Replace any NA values in the feature columns with the column
# median, using the same robust imputation strategy as for
# the Ethereum data.
# ---------------------------------------------------------------
for (col in available_btc_features) {
  if (is.numeric(btc_clean[[col]])) {
    na_count <- sum(is.na(btc_clean[[col]]))
    if (na_count > 0) {
      btc_clean[[col]][is.na(btc_clean[[col]])] <- median(btc_clean[[col]], na.rm = TRUE)
      cat("Filled", na_count, "NAs in", col, "\n")
    }
  }
}

# ---------------------------------------------------------------
# Count duplicate feature rows (rows with identical values
# across all feature columns and FLAG). We report the count
# but do not remove duplicates here because we will address
# balance through stratified sampling next.
# ---------------------------------------------------------------
dup_btc <- sum(duplicated(btc_clean[, c(available_btc_features, "FLAG")]))
cat("Duplicate feature rows:", dup_btc, "\n")

# ---------------------------------------------------------------
# The full Bitcoin Heist dataset has ~2.9 million rows which
# is too large for interactive training and testing on most
# laptops. We create a stratified sample:
#   - Keep ALL ransomware addresses (the minority class)
#   - Sample legitimate addresses at 3x the ransomware count
# This gives a roughly 25% ransomware / 75% legitimate split,
# which is more realistic than 50/50 while still being manageable.
# set.seed(42) ensures reproducibility — the same rows will be
# selected every time this code is run.
# ---------------------------------------------------------------
set.seed(42)
btc_ransomware <- btc_clean[btc_clean$FLAG == 1, ]
btc_legitimate <- btc_clean[btc_clean$FLAG == 0, ]

cat("Total ransomware addresses:", nrow(btc_ransomware), "\n")
cat("Total legitimate addresses:", nrow(btc_legitimate), "\n")

# Sample legitimate addresses to create a balanced dataset
# Take 3 times the ransomware count for a realistic but manageable dataset
sample_size <- min(nrow(btc_legitimate), nrow(btc_ransomware) * 3)
btc_leg_sample <- btc_legitimate[sample(nrow(btc_legitimate), sample_size), ]

# ---------------------------------------------------------------
# Combine the full ransomware subset with the sampled legitimate
# subset, then randomly shuffle the combined rows. Shuffling is
# important so that the training/test split (done later) does
# not accidentally put all ransomware rows in one partition.
# ---------------------------------------------------------------
btc_sampled <- rbind(btc_ransomware, btc_leg_sample)
# Shuffle the rows randomly
btc_sampled <- btc_sampled[sample(nrow(btc_sampled)), ]

cat("\nSampled Bitcoin dataset:", nrow(btc_sampled), "rows\n")
cat("Sampled FLAG distribution:\n")
print(table(btc_sampled$FLAG))
cat("Ransomware percentage in sample:",
    round(sum(btc_sampled$FLAG == 1) / nrow(btc_sampled) * 100, 2), "%\n")

# ---------------------------------------------------------------
# Save the cleaned, sampled Bitcoin dataset to disk.
# ---------------------------------------------------------------
write.csv(btc_sampled, file.path(cleaned_data_folder, "bitcoin_cleaned.csv"), row.names = FALSE)
cat("Saved: bitcoin_cleaned.csv\n")
cat("STEP 5 COMPLETE\n\n")
