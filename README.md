# Crypto Wallet Risk Scoring using Data Mining Techniques

## Repository Link

CryptoWalletRiskScoring_Team6  
https://github.com/sivasaiboggu/CryptoWalletRiskScoring_Team6.git

## Team Members

* M V Raghupathi Sai – 2023BCS0096
* C H Bhargav        – 2023BCS0219
* T Sai Karthik      – 2023BCS0159
* B Sivasai          – 2023BCS0228

## Problem Statement

Cryptocurrency transactions are large in volume and complex in structure. Fraudulent wallets are difficult to identify using simple rules.The problem in this project is to analyze transaction data from Ethereum and Bitcoin and identify wallets that show suspicious behavior. Instead of only classifying wallets as fraud or not fraud, this project aims to group them into different risk levels so that high-risk wallets can be identified and prioritized for further investigation.

## Objectives

- To study transaction patterns of cryptocurrency wallets using real datasets  
- To clean and prepare large-scale blockchain data for analysis  
- To identify important features that indicate suspicious behavior  
- To group wallets into Low, Medium, and High risk categories using clustering  
- To build classification models that can predict the risk category of a wallet  
- To compare different models and select the best performing one  
- To evaluate model performance using accuracy, precision, recall, and F1 score  
- To generate meaningful insights and visualizations for better understanding of fraud patterns  
## Dataset

### Ethereum Fraud Detection Dataset

Source: https://www.kaggle.com/datasets/vagifa/ethereum-frauddetection-dataset

* Number of observations:9842 
* Number of variables: 50
* Target: FLAG (0 = Legitimate, 1 = Fraud)

### Bitcoin Heist Dataset

Source: https://archive.ics.uci.edu/dataset/526/bitcoin+heist+ransomware+address+dataset

* Number of observations: ~2.9 million (sampled subset used)
* Number of variables: 10
* Target: label (white = Legitimate, others = Fraud)

### Important Attributes

#### Ethereum Dataset

- Sent.tnx (number of transactions sent)  
- Received.Tnx (number of transactions received)  
- Total.ERC20.tnxs (number of ERC20 token transactions)  
- total.Ether.sent (total Ether sent)  
- total.ether.received (total Ether received)  
- total.ether.balance (current wallet balance)  
- avg.val.sent (average value of sent transactions)  
- avg.val.received (average value of received transactions)  
- Avg.min.between.sent.tnx (average time between sent transactions)  
- Avg.min.between.received.tnx (average time between received transactions)  
- Time.Diff.between.first.and.last..Mins. (overall transaction activity duration)  
- sent_received_ratio (ratio of sent to received transactions)  
- total_transactions (total number of transactions)  

#### Bitcoin Dataset

- year (year of transaction activity)  
- day (day of transaction activity)  
- length (longest transaction chain length)  
- weight (fraction of Bitcoin in largest transaction)  
- count (total number of transactions)  
- looped (number of looped transactions)  
- neighbors (number of connected addresses)  
- income (total Bitcoin received)  
- income_per_tx (average income per transaction)  
- weight_neighbor_ratio (ratio of weight to neighbors)  
- length_count_ratio (ratio of chain length to transaction count)  
## Methodology

### Data Preprocessing
- Removed duplicate records and unnecessary columns  
- Handled missing values using median imputation  
- Replaced infinite values with valid numerical values  
- Converted labels into binary format for fraud detection  
- Applied winsorization to reduce the impact of extreme outliers  
- Standardized features using Z-score normalization  

### Exploratory Analysis
- Analyzed distribution of fraudulent and legitimate wallets  
- Visualized transaction patterns using histograms and box plots  
- Examined relationships between features using correlation analysis  
- Compared behavioral differences between fraud and non-fraud wallets  

### Models Used
- K-Means Clustering to group wallets into Low, Medium, and High risk  
- Decision Tree for classification and interpretability  
- Random Forest for improved accuracy and feature importance  
- Naive Bayes as a probabilistic baseline model  
- K-Nearest Neighbors (KNN) based on similarity between wallets  

### Evaluation Methods
- Accuracy to measure overall correctness  
- Precision to measure correctness of predicted fraud cases  
- Recall to measure how well fraud cases are detected  
- F1 Score to balance precision and recall  
- Confusion Matrix to analyze model performance in detail  
## Results

- Random Forest achieved the highest accuracy among all models for both Ethereum and Bitcoin datasets  
- K-Nearest Neighbors (KNN) showed good performance after applying feature scaling and selecting the optimal value of k  
- Decision Tree provided clear interpretability but slightly lower accuracy compared to Random Forest  
- Naive Bayes performed the lowest due to the assumption of feature independence, which does not hold well for transaction data  

- The use of K-Means clustering helped in grouping wallets into Low, Medium, and High risk categories based on behavior  
- High Risk category contained the highest proportion of actual fraudulent wallets  
- Low Risk category contained mostly legitimate wallets, showing effective separation  

- The risk scoring system (0–100) provided a more detailed understanding of wallet risk instead of only categorical labels  
- Fraud detection effectiveness improved when combining clustering with supervised learning models  

- Evaluation metrics such as Accuracy, Precision, Recall, and F1 Score confirmed that the models are effective in identifying risky wallets  
- Visualization results supported model findings by clearly showing differences between fraud and legitimate behavior  

- Overall, the system successfully identifies and categorizes risky cryptocurrency wallets and can be used as a scalable approach for fraud detection  
## Key Visualizations

### Ethereum Analysis

#### Fraud Distribution
![Fraud Distribution](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_01_fraud_distribution.png)

#### Total Transactions Distribution
![Total Transactions](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_02_total_transactions.png)

#### Average Value Sent
![Average Value Sent](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_03_avg_value_sent.png)

#### Ether Balance Comparison
![Ether Balance](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_04_ether_balance.png)

#### Correlation Heatmap
![Correlation Heatmap](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_05_correlation_heatmap.png)

#### Sent vs Received Transactions
![Sent vs Received](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_06_sent_vs_received.png)

#### K-Means Clustering (PCA)
![KMeans PCA](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_08_kmeans_pca.png)

#### Risk Distribution (Pie Chart)
![Risk Distribution](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_09_risk_pie.png)

#### Decision Tree Confusion Matrix
![Decision Tree CM](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_10_dt_cm.png)

#### Random Forest Confusion Matrix
![Random Forest CM](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_12_rf_cm.png)

#### Model Comparison
![Model Comparison](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_15_model_comparison.png)

#### Risk Score Distribution
![Risk Score](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_17_risk_scores.png)

#### Risk Score vs Actual Label
![Risk vs Actual](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_18_risk_vs_actual.png)

#### Fraud Rate by Risk Category
![Fraud Rate](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/eth_19_fraud_rate.png)

---

### Bitcoin Analysis

#### Class Distribution
![Bitcoin Distribution](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_01_class_distribution.png)

#### Income Distribution
![Income Distribution](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_02_income_distribution.png)

#### Weight Boxplot
![Weight Boxplot](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_03_weight_boxplot.png)

#### Neighbors vs Transaction Count
![Neighbors vs Count](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_04_neighbors_vs_count.png)

#### Correlation Heatmap
![BTC Correlation](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_05_correlation_heatmap.png)

#### K-Means Clustering (PCA)
![BTC PCA](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_07_kmeans_pca.png)

#### Decision Tree
![Decision Tree](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_08_decision_tree.png)

#### Decision Tree Confusion Matrix
![DT CM](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_09_dt_cm.png)

#### Model Comparison
![BTC Models](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_11_model_comparison.png)

#### Risk Score Distribution
![BTC Risk Score](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_12_risk_scores.png)

#### Fraud Rate by Risk Category
![BTC Fraud Rate](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/btc_13_fraud_rate.png)

---

### Combined Analysis

#### Risk Distribution Comparison
![Risk Comparison](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/combined_01_risk_comparison.png)

#### Model Accuracy Comparison
![Accuracy Comparison](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/combined_02_accuracy.png)

#### Risk Score Density Comparison
![Density Comparison](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/combined_03_density.png)

#### Fraud Detection Comparison
![Fraud Comparison](https://raw.githubusercontent.com/sivasaiboggu/CryptoWalletRiskScoring_Team6/main/results/figures/combined_04_fraud_detection.png)
## How to Run the Project

### Step 1: Clone the Repository

Download or clone the project repository to your local system.

---

### Step 2: Install Required Packages

Open R or RStudio and run:

source("requirements.R")

This will install all required packages used in the project.

---

### Step 3: Download Datasets

The datasets are not included in the repository due to size and public availability.

Download them from:

- Ethereum dataset from Kaggle  
- Bitcoin dataset from UCI Machine Learning Repository  

Place the datasets inside the `data/` folder.

---

### Step 4: Run the Scripts

Run the following scripts in order:

scripts/01_data_preparation.R  
scripts/02_data_cleaning.R  
scripts/03_feature_engineering.R  
scripts/04_exploratory_data_analysis_and_visualization.R  
scripts/05_models_training_and_model_evaluation.R  
scripts/06_model_comparisons.R  
scripts/07_cryptocurrency_risk_scoring.R  
scripts/08_combined_cryptocurrency_comparison.R  
scripts/09_final_summary_report.R  

Each script performs a specific part of the workflow:
- Data preparation and cleaning  
- Feature engineering  
- Exploratory data analysis and visualization  
- Model training and evaluation  
- Model comparison  
- Risk scoring  
- Combined cryptocurrency analysis  
- Final report generation  

---

### Step 5: View Results

All outputs are saved in the `results/` folder:

- `results/figures/` contains all plots and visualizations  
- `results/tables/` contains evaluation results and summary tables  

---

## Folder Organization

project/  
 ├── data/  
 │    └── dataset_description.md  
 ├── scripts/  
 │    ├── 01_data_preparation.R  
 │    ├── 02_data_cleaning.R  
 │    ├── 03_feature_engineering.R  
 │    ├── 04_exploratory_data_analysis_and_visualization.R  
 │    ├── 05_models_training_and_model_evaluation.R  
 │    ├── 06_model_comparisons.R  
 │    ├── 07_cryptocurrency_risk_scoring.R  
 │    ├── 08_combined_cryptocurrency_comparison.R  
 │    └── 09_final_summary_report.R  
 ├── results/  
 │    ├── figures/  
 │    └── tables/  
 ├── presentation/  
 │    └── project_presentation.pptx  
 ├── requirements.R  
 └── README.md  

---

### Notes

- Make sure datasets are placed in the correct folder before running scripts  
- Run scripts in the given order to avoid errors  
- All results will be generated automatically after execution  
## Conclusion

- The project successfully analyzes cryptocurrency transaction data to identify risky wallets  
- Transaction patterns such as frequency, value, and timing provide strong indicators of suspicious behavior  

- K-Means clustering effectively groups wallets into Low, Medium, and High risk categories based on behavior  
- Supervised models learn these patterns and accurately predict the risk category for new wallets  

- Random Forest achieved the best overall performance among all models, while KNN also showed strong results after scaling  
- Naive Bayes performed comparatively lower due to the dependency between transaction features  

- The risk scoring system (0–100) provides a more detailed and practical measure of wallet risk compared to simple classification  

- High Risk wallets show a significantly higher proportion of actual fraudulent activity, confirming the effectiveness of the system  
- Low Risk wallets are mostly legitimate, indicating good separation between categories  

- Combining clustering, feature engineering, and machine learning improves fraud detection performance  

- Overall, the system provides a scalable and effective approach for identifying fraudulent cryptocurrency wallets and can be extended for real-world applications  
## Contribution

C H Bhargav – 2023BCS0219  
Data collection, Data preprocessing, Data cleaning  

M V Raghupathi Sai – 2023BCS0096  
Feature engineering, Exploratory Data Analysis, Visualizations  

T Sai Karthik – 2023BCS0159  
Model development, Model evaluation, Model comparison, Visualizations  

B Sivasai – 2023BCS0228  
Model evaluation, Model comparison, Visualizations, Result analysis, Risk scoring system, Final report  
## References

### Datasets

- Ethereum Fraud Detection Dataset (Kaggle)  
  https://www.kaggle.com/datasets/vagifa/ethereum-frauddetection-dataset  

- Bitcoin Heist Ransomware Address Dataset (UCI)  
  https://archive.ics.uci.edu/dataset/526/bitcoin+heist+ransomware+address+dataset  

---

### Research Papers

- RiskSEA: Scalable Graph Embedding for Detecting On-chain Fraudulent Activities on Ethereum  
  https://arxiv.org/abs/2103.08860  

- Ethereum Fraud Detection using Deep Learning and Feature Selection (JFS + FTDNet)  
  https://link.springer.com/article/10.1007/s41870-025-02900-7  

- Bitcoin Fraud Detection using Machine Learning  
  https://ieeexplore.ieee.org/document/8731487  

---

### Technologies and Documentation

- R Documentation  
  https://cran.r-project.org/manuals.html  

- Caret Package Documentation  
  https://topepo.github.io/caret/  

- Random Forest (R Package)  
  https://cran.r-project.org/web/packages/randomForest/index.html  

- e1071 Package (SVM, Naive Bayes)  
  https://cran.r-project.org/web/packages/e1071/index.html  

- KNN (class package)  
  https://cran.r-project.org/web/packages/class/index.html  

---

### Additional Resources

- Blockchain Basics  
  https://www.ibm.com/topics/blockchain  

- Introduction to Fraud Detection  
  https://www.sciencedirect.com/topics/computer-science/fraud-detection  
