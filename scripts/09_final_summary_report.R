# ============================================================
# STEP 22: FINAL SUMMARY REPORT
# Generate a complete text report of all findings.
# ============================================================

cat("============================================================\n")
cat("STEP 22: FINAL REPORT\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Write a comprehensive plain-text summary report of the entire
# project to disk. sink() redirects all cat() output to the file.
# The report includes: dataset statistics, model accuracy tables,
# risk distributions, and fraud detection rates for both
# cryptocurrencies. Calling sink() at the end restores normal
# console output. This report can be shared as a standalone
# summary without needing to re-run any code.
# ---------------------------------------------------------------
report_path <- file.path(results_folder, "FINAL_PROJECT_REPORT.txt")
sink(report_path)

cat("================================================================\n")
cat("  CRYPTO WALLET RISK SCORING SYSTEM - FINAL REPORT\n")
cat("================================================================\n")
cat("Generated:", as.character(Sys.time()), "\n\n")

cat("PROJECT OVERVIEW\n")
cat("This system analyzes cryptocurrency wallet transactions\n")
cat("using data mining to identify risky wallets.\n")
cat("Two real datasets: Ethereum Fraud Detection and\n")
cat("Bitcoin Heist Ransomware Address Dataset.\n\n")

cat("ETHEREUM DATASET\n")
cat("Source: Kaggle Ethereum Fraud Detection Dataset\n")
cat("Total records:", nrow(eth_data), "\n")
cat("Features used:", length(eth_feature_cols), "\n")
cat("Fraud wallets:", sum(eth_features$FLAG == 1), "\n")
cat("Legitimate wallets:", sum(eth_features$FLAG == 0), "\n\n")

cat("Ethereum Model Accuracy:\n")
print(eth_comp)
cat("\nEthereum Risk Distribution:\n")
print(table(eth_results$RiskCategory))
cat("\nEthereum Fraud Detection:\n")
print(eth_fd)

cat("\n\nBITCOIN DATASET\n")
cat("Source: UCI Bitcoin Heist Ransomware Address Dataset\n")
cat("Original records:", nrow(btc_data), "\n")
cat("Sampled records:", nrow(btc_sampled), "\n")
cat("Features used:", length(btc_feature_cols), "\n")
cat("Ransomware addresses:", sum(btc_features$FLAG == 1), "\n")
cat("Legitimate addresses:", sum(btc_features$FLAG == 0), "\n\n")

cat("Bitcoin Model Accuracy:\n")
print(btc_comp)
cat("\nBitcoin Risk Distribution:\n")
print(table(btc_results$RiskCategory))
cat("\nBitcoin Fraud Detection:\n")
print(btc_fd)

cat("\n\nKEY FINDINGS\n")
cat("1. System classifies wallets into Low, Medium, High risk\n")
cat("2. Five models compared: DT, RF, SVM, NB, KNN\n")
cat("3. High risk wallets have highest actual fraud rates\n")
cat("4. Clustering reveals natural behavior groupings\n")
cat("5. Feature importance shows key risk indicators\n")
cat("6. Both cryptocurrencies show distinct risk patterns\n")

cat("\n\nFILES LOCATION:", project_folder, "\n")
cat("================================================================\n")
sink()

cat("Report saved:", report_path, "\n")
