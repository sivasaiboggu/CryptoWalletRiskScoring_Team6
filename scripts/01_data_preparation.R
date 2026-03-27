# ============================================================
# CRYPTO WALLET RISK SCORING SYSTEM - COMPLETE PROJECT
# ============================================================
# This project analyzes cryptocurrency wallet transaction data
# using data mining techniques to identify risky wallets.
# We use two real cryptocurrency datasets:
# 1. Ethereum Fraud Detection Dataset (real Ethereum accounts)
# 2. Bitcoin Heist Ransomware Dataset (real Bitcoin addresses)
# Each wallet is classified as low, medium, or high risk.
# ============================================================


# ============================================================
# STEP 1: PROJECT SETUP AND LIBRARY INSTALLATION
# We create the folder structure on C drive and install all
# required R packages for the entire project.
# ============================================================

# ---------------------------------------------------------------
# Clear the R workspace so no leftover variables from previous
# sessions interfere with this run. rm(list = ls()) removes
# every object currently stored in memory.
# ---------------------------------------------------------------
rm(list = ls())

# ---------------------------------------------------------------
# Close any graphics windows that may be open from a previous
# session. This prevents conflicts when we start saving new plots.
# ---------------------------------------------------------------
graphics.off()

# ---------------------------------------------------------------
# Define the root folder path where every project file will be
# saved. All sub-folders (data, plots, models, etc.) will be
# created inside this directory on the C drive.
# ---------------------------------------------------------------
project_folder <- "C:/CryptoRiskCombined"

# ---------------------------------------------------------------
# Create the main project folder on disk only if it does not
# already exist. recursive = TRUE means parent folders are also
# created automatically if needed.
# ---------------------------------------------------------------
if (!dir.exists(project_folder)) {
  dir.create(project_folder, recursive = TRUE)
}

# ---------------------------------------------------------------
# Define paths for each sub-folder. Keeping data, features,
# plots, tables, models, and results in separate folders makes
# the project organised and easy to navigate during the
# presentation or future work.
# ---------------------------------------------------------------
raw_data_folder <- file.path(project_folder, "RawData")
cleaned_data_folder <- file.path(project_folder, "CleanedData")
features_folder <- file.path(project_folder, "Features")
plots_folder <- file.path(project_folder, "Plots")
tables_folder <- file.path(project_folder, "Tables")
models_folder <- file.path(project_folder, "Models")
results_folder <- file.path(project_folder, "Results")

# ---------------------------------------------------------------
# Loop through every sub-folder path and create the folder on
# disk if it does not already exist. Using a loop avoids
# repeating the same dir.create() call seven times.
# ---------------------------------------------------------------
for (folder in c(raw_data_folder, cleaned_data_folder, features_folder,
                 plots_folder, tables_folder, models_folder, results_folder)) {
  if (!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
  }
}

# Print confirmation that all folders are created
cat("All project folders created under:", project_folder, "\n")

# ---------------------------------------------------------------
# List every R package required by this project. These packages
# provide tools for data manipulation (dplyr, tidyr), plotting
# (ggplot2, corrplot), clustering (factoextra, cluster, dbscan),
# machine learning (randomForest, caret, e1071, rpart, class),
# and performance evaluation (pROC, ROSE).
# ---------------------------------------------------------------
packages_list <- c(
  "dplyr", "ggplot2", "tidyr", "readr", "scales", "corrplot",
  "factoextra", "cluster", "dbscan", "randomForest", "caret",
  "e1071", "rpart", "rpart.plot", "class", "gridExtra",
  "reshape2", "stringr", "pROC", "ROSE"
)

# ---------------------------------------------------------------
# For each package in the list: check whether it is already
# installed using requireNamespace(). If it is missing, install
# it from CRAN automatically. Then load it into the current
# session with library(). character.only = TRUE is needed
# because the package name is stored as a string variable.
# ---------------------------------------------------------------
for (pkg in packages_list) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE, quiet = TRUE,
                     repos = "https://cran.r-project.org")
  }
  library(pkg, character.only = TRUE, quietly = TRUE)
}

# Confirm all packages loaded
cat("All", length(packages_list), "packages installed and loaded successfully\n")

# ---------------------------------------------------------------
# Enable parallel processing so that computationally heavy
# operations (like Random Forest training) can use multiple CPU
# cores simultaneously. detectCores() - 1 leaves one core free
# for the operating system so the computer stays responsive.
# makeCluster() creates the worker processes, and
# registerDoParallel() tells R to use them.
# ---------------------------------------------------------------
library(doParallel)

cores <- parallel::detectCores() - 1
cl <- makeCluster(cores)
registerDoParallel(cl)

cat("Using", cores, "CPU cores for processing\n")
cat("STEP 1 COMPLETE\n\n")


# ============================================================
# STEP 2: DOWNLOADING REAL CRYPTOCURRENCY DATASETS
# Dataset 1: Ethereum Fraud Detection Dataset
#   Real Ethereum accounts with transaction features
#   FLAG column: 0 = legitimate, 1 = fraud
# Dataset 2: Bitcoin Heist Ransomware Address Dataset
#   Real Bitcoin addresses used in ransomware attacks
#   Contains address, year, day, length, weight, count,
#   looped, neighbors, income and label columns
#   Source: UCI Machine Learning Repository
# ============================================================

cat("============================================================\n")
cat("STEP 2: DOWNLOADING REAL DATASETS\n")
cat("============================================================\n")

# ---------------------------------------------------------------
# Set the download timeout to 600 seconds (10 minutes) because
# the Bitcoin Heist dataset is very large (~200 MB) and may be
# slow to download on some connections.
# ---------------------------------------------------------------
options(timeout = 600)

# ----------------------------------------------------------
# DATASET 1: Ethereum Fraud Detection Dataset
# ----------------------------------------------------------

# ---------------------------------------------------------------
# Define the local path where the Ethereum dataset will be saved.
# ---------------------------------------------------------------
eth_file <- file.path(raw_data_folder, "ethereum_fraud.csv")

# ---------------------------------------------------------------
# Provide multiple mirror URLs for the same Ethereum dataset.
# If the first URL fails (e.g. due to a broken link), the code
# will automatically try the next one. This makes the download
# more robust.
# ---------------------------------------------------------------
eth_urls <- c(
  "https://raw.githubusercontent.com/Vagif12/Ethereum-Fraud-Detection/main/transaction_dataset.csv",
  "https://raw.githubusercontent.com/rupakc/Ethereum-Fraud-Detection/master/datasets/transaction_dataset.csv",
  "https://raw.githubusercontent.com/anmolter/Ethereum/main/transaction_dataset.csv"
)

# ---------------------------------------------------------------
# Only attempt a download if the file does not already exist
# locally. This avoids wasting bandwidth on repeated runs.
# The loop tries each URL in order. A successful download is
# confirmed by checking that the saved file is larger than
# 1000 bytes (to reject empty or error HTML pages).
# If all URLs fail, the script stops with an error message.
# ---------------------------------------------------------------
if (!file.exists(eth_file)) {
  eth_downloaded <- FALSE
  for (url in eth_urls) {
    cat("Trying Ethereum download from:\n", url, "\n")
    tryCatch({
      download.file(url, eth_file, mode = "wb", quiet = FALSE, method = "auto")
      if (file.exists(eth_file) && file.info(eth_file)$size > 1000) {
        cat("Ethereum dataset downloaded successfully\n")
        cat("File size:", round(file.info(eth_file)$size / 1024, 1), "KB\n")
        eth_downloaded <- TRUE
        break
      } else {
        if (file.exists(eth_file)) file.remove(eth_file)
      }
    }, error = function(e) {
      cat("Failed:", e$message, "\nTrying next URL...\n")
    })
  }
  if (!eth_downloaded) {
    stop("Could not download Ethereum dataset. Please download manually from Kaggle.")
  }
} else {
  cat("Ethereum dataset already exists at:", eth_file, "\n")
}

# ----------------------------------------------------------
# DATASET 2: Bitcoin Heist Ransomware Address Dataset
# This is a real dataset from UCI Machine Learning Repository
# It contains 2916697 Bitcoin addresses with features
# Labels include known ransomware families and white (legitimate)
# ----------------------------------------------------------

# ---------------------------------------------------------------
# Define the local path for the Bitcoin Heist dataset.
# ---------------------------------------------------------------
btc_file <- file.path(raw_data_folder, "bitcoin_heist.csv")

# ---------------------------------------------------------------
# Same multi-URL strategy as the Ethereum download above.
# The minimum size check is raised to 10000 bytes because this
# dataset is much larger (millions of rows).
# ---------------------------------------------------------------
btc_urls <- c(
  "https://archive.ics.uci.edu/ml/machine-learning-databases/00526/BitcoinHeistData.csv",
  "https://raw.githubusercontent.com/jamesrobertlloyd/bitcoinheist/main/BitcoinHeistData.csv",
  "https://raw.githubusercontent.com/Crypt-the-data/Bitcoin-Heist-Ransomware-Address-Dataset/main/BitcoinHeistData.csv"
)

# Only download if file does not exist
if (!file.exists(btc_file)) {
  btc_downloaded <- FALSE
  for (url in btc_urls) {
    cat("Trying Bitcoin download from:\n", url, "\n")
    tryCatch({
      download.file(url, btc_file, mode = "wb", quiet = FALSE, method = "auto")
      if (file.exists(btc_file) && file.info(btc_file)$size > 10000) {
        cat("Bitcoin dataset downloaded successfully\n")
        cat("File size:", round(file.info(btc_file)$size / (1024 * 1024), 1), "MB\n")
        btc_downloaded <- TRUE
        break
      } else {
        if (file.exists(btc_file)) file.remove(btc_file)
      }
    }, error = function(e) {
      cat("Failed:", e$message, "\nTrying next URL...\n")
    })
  }
  if (!btc_downloaded) {
    stop("Could not download Bitcoin dataset. Please download BitcoinHeistData.csv from UCI.")
  }
} else {
  cat("Bitcoin dataset already exists at:", btc_file, "\n")
}

# ----------------------------------------------------------
# LOAD BOTH DATASETS INTO R
# ----------------------------------------------------------

cat("\nLoading datasets into R...\n")

# ---------------------------------------------------------------
# Read the Ethereum CSV file into a data frame. stringsAsFactors
# = FALSE prevents character columns from being auto-converted
# to factors, which gives us more control during cleaning.
# ---------------------------------------------------------------
eth_data <- read.csv(eth_file, stringsAsFactors = FALSE)
cat("Ethereum data loaded:", nrow(eth_data), "rows,", ncol(eth_data), "columns\n")

# ---------------------------------------------------------------
# Ensure the fraud label column is named exactly "FLAG" for
# consistent access throughout the project. Different versions
# of the dataset may use slightly different column names, so
# we check a list of common alternatives and rename if needed.
# ---------------------------------------------------------------
if (!"FLAG" %in% names(eth_data)) {
  possible_flags <- c("flag", "Flag", "isFraud", "is_fraud", "label", "Label")
  for (fname in possible_flags) {
    if (fname %in% names(eth_data)) {
      names(eth_data)[names(eth_data) == fname] <- "FLAG"
      break
    }
  }
}

# ---------------------------------------------------------------
# Read the Bitcoin Heist CSV file. This file has ~2.9 million
# rows so loading may take a moment.
# ---------------------------------------------------------------
btc_data <- read.csv(btc_file, stringsAsFactors = FALSE)
cat("Bitcoin data loaded:", nrow(btc_data), "rows,", ncol(btc_data), "columns\n")

# Print column names of Bitcoin data so we can see what we have
cat("Bitcoin columns:", paste(names(btc_data), collapse = ", "), "\n")

# Confirm both datasets loaded
cat("\nBoth datasets loaded successfully\n")
cat("STEP 2 COMPLETE\n\n")


# ============================================================
# STEP 3: INITIAL DATA EXPLORATION
# We examine structure, dimensions, column names, data types,
# distributions, and missing values in both datasets.
# ============================================================

cat("============================================================\n")
cat("STEP 3: INITIAL DATA EXPLORATION\n")
cat("============================================================\n")

# ----------------------------------------------------------
# Ethereum Exploration
# ----------------------------------------------------------

# ---------------------------------------------------------------
# Print key facts about the Ethereum dataset so we understand
# what we are working with before any modifications.
# We check: row/column count, column names, fraud label
# distribution, fraud percentage, and total missing values.
# ---------------------------------------------------------------
cat("\n--- Ethereum Dataset ---\n")
cat("Rows:", nrow(eth_data), "\n")
cat("Columns:", ncol(eth_data), "\n")
cat("Column names:\n")
print(names(eth_data))
cat("\nFraud distribution:\n")
print(table(eth_data$FLAG))
cat("Fraud percentage:", round(sum(eth_data$FLAG == 1) / nrow(eth_data) * 100, 2), "%\n")
cat("Missing values:", sum(is.na(eth_data)), "\n")

# ----------------------------------------------------------
# Bitcoin Exploration
# ----------------------------------------------------------

# ---------------------------------------------------------------
# Print similar diagnostics for the Bitcoin dataset. We also
# look at the 'label' column which contains the name of the
# ransomware family (e.g. "Cerber", "WannaCry") or "white"
# for legitimate addresses. Showing the top 10 most frequent
# labels gives a quick overview of the ransomware families
# present in the data.
# ---------------------------------------------------------------
cat("\n--- Bitcoin Heist Dataset ---\n")
cat("Rows:", nrow(btc_data), "\n")
cat("Columns:", ncol(btc_data), "\n")
cat("Column names:\n")
print(names(btc_data))
cat("\nFirst 5 rows:\n")
print(head(btc_data, 5))

# The label column contains ransomware family names or white for legitimate
cat("\nLabel distribution (top 10):\n")
label_table <- sort(table(btc_data$label), decreasing = TRUE)
print(head(label_table, 10))
cat("Total unique labels:", length(unique(btc_data$label)), "\n")
cat("Legitimate (white):", sum(btc_data$label == "white"), "\n")
cat("Ransomware (non-white):", sum(btc_data$label != "white"), "\n")
cat("Ransomware percentage:", round(sum(btc_data$label != "white") / nrow(btc_data) * 100, 2), "%\n")
cat("Missing values:", sum(is.na(btc_data)), "\n")

# ---------------------------------------------------------------
# Save the exploration summaries to plain text files so they
# can be reviewed later without re-running the script.
# sink() redirects console output to a file; calling sink()
# again with no arguments restores normal console output.
# ---------------------------------------------------------------
sink(file.path(tables_folder, "ethereum_exploration.txt"))
cat("ETHEREUM EXPLORATION\n")
cat("Rows:", nrow(eth_data), " Columns:", ncol(eth_data), "\n")
cat("Fraud:", sum(eth_data$FLAG == 1), " Legitimate:", sum(eth_data$FLAG == 0), "\n")
cat("Columns:", paste(names(eth_data), collapse = ", "), "\n")
sink()

sink(file.path(tables_folder, "bitcoin_exploration.txt"))
cat("BITCOIN HEIST EXPLORATION\n")
cat("Rows:", nrow(btc_data), " Columns:", ncol(btc_data), "\n")
cat("Ransomware:", sum(btc_data$label != "white"), " Legitimate:", sum(btc_data$label == "white"), "\n")
cat("Columns:", paste(names(btc_data), collapse = ", "), "\n")
cat("\nLabel Distribution:\n")
print(head(label_table, 20))
sink()

cat("\nExploration summaries saved to Tables folder\n")
cat("STEP 3 COMPLETE\n\n")