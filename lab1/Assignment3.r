library(ggplot2)
library(caret)

# Define column labels for the data frame
column_labels <- c(
  'Number_of_times_pregnant',
  'Plasma_glucose_concentration',
  'Diastolic_blood_pressure',
  'Triceps_skinfold_thickness',
  'Two_Hour_serum_insulin',
  'Body_mass_index',
  'Diabetes_pedigree_function',
  'Age',
  'Diabetes'
)

# Read the CSV file without headers
df <- read.csv('pima-indians-diabetes.csv', header = FALSE, col.names = column_labels)

##################################Task 1##################################
# Scatterplot with ggplot2
p <- ggplot(df, aes(x = Age, y = Plasma_glucose_concentration, color = factor(Diabetes))) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c('0' = 'blue', '1' = 'red')) +
  labs(title = 'Plasma Glucose Concentration on Age Colored by Diabetes Level',
       x = 'Age',
       y = 'Plasma Glucose Concentration',
       color = 'Diabetes Level') +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p)


##################################Task 2##################################
library(dplyr)
library(ggplot2)
library(caret)

df$Diabetes <- as.factor(df$Diabetes)

# Outlier removal based on the IQR
calculate_bounds <- function(x) {
  Q <- quantile(x, probs = c(.25, .75), na.rm = TRUE)
  iqr <- IQR(x, na.rm = TRUE)
  return(c(Q[1] - 1.5 * iqr, Q[2] + 1.5 * iqr))
}

# Apply the function to Plasma_glucose_concentration and Age
glucose_bounds <- calculate_bounds(df$Plasma_glucose_concentration)
age_bounds <- calculate_bounds(df$Age)

# Filter out the outliers
df_filtered <- df %>%
  filter(Plasma_glucose_concentration >= glucose_bounds[1] & Plasma_glucose_concentration <= glucose_bounds[2]) %>%
  filter(Age >= age_bounds[1] & Age <= age_bounds[2])

# Feature scaling using Z-score standardization
df_filtered <- df_filtered %>%
  mutate(
    Scaled_Glucose = scale(Plasma_glucose_concentration),
    Scaled_Age = scale(Age)
  )

# Prepare the data for logistic regression
df_logistic <- df_filtered[, c('Scaled_Glucose', 'Scaled_Age', 'Diabetes')]

# Split the data into training and test sets
set.seed(42)
index <- createDataPartition(df_logistic$Diabetes, p = 0.8, list = FALSE)
train_data <- df_logistic[index, ]
test_data <- df_logistic[-index, ]

# Fit the logistic regression model
model <- glm(Diabetes ~ Scaled_Age + Scaled_Glucose, data = train_data, family = "binomial")

# Summary to check for convergence
summary(model)

# Predict probabilities
test_data$prob <- predict(model, newdata = test_data, type = "response")

# Apply the classification threshold
test_data$Diabetes_pred <- ifelse(test_data$prob >= 0.5, '1', '0')

# Convert predictions to a factor for consistency with the actual values
test_data$Diabetes_pred <- factor(test_data$Diabetes_pred, levels = levels(df$Diabetes))

# Calculate misclassification error
misclassification_error <- mean(test_data$Diabetes != test_data$Diabetes_pred)
cat(sprintf("Misclassification error: %f\n", misclassification_error))

# Plotting with scaled features
ggplot(test_data, aes(x = Scaled_Age, y = Scaled_Glucose, color = Diabetes_pred)) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c('1' = 'red', '0' = 'blue')) +
  labs(title = 'Scaled Age vs Scaled Plasma Glucose Concentration Colored by Predicted Diabetes Status',
       x = 'Scaled Age',
       y = 'Scaled Plasma Glucose Concentration',
       color = 'Diabetes Status') +
  theme_minimal() +
  theme(legend.position = "bottom")


##################################Task 3##################################
library(ggplot2)
library(dplyr)
library(reshape2)

# Create a meshgrid for the contour plot
age_range <- range(df$Age)
glucose_range <- range(df$Plasma_glucose_concentration) 

age_seq <- seq(from = age_range[1] - 1, to = age_range[2] + 1, by = 0.1)
glucose_seq <- seq(from = glucose_range[1] - 1, to = glucose_range[2] + 1, by = 0.1)

grid <- expand.grid(Age = age_seq, Plasma_glucose_concentration = glucose_seq)

# Predict probabilities on the meshgrid
grid$prob <- predict(model, newdata = grid, type = "response")

# Reshape for ggplot
grid_melt <- melt(grid, id.vars = c("Age", "Plasma_glucose_concentration"))

# Plotting
ggplot() +
  geom_tile(data = grid_melt, aes(x = Age, y = Plasma_glucose_concentration, fill = value), alpha = 0.5) +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0.5, limit = c(0, 1), space = "Lab", name="Probability") +
  geom_contour(data = grid_melt, aes(x = Age, y = Plasma_glucose_concentration, z = value), breaks = c(0.5), color = "grey") +
  geom_point(data = test_data, aes(x = Age, y = Plasma_glucose_concentration, color = as.factor(Diabetes_pred)), alpha = 0.5) +
  labs(title = 'Age vs Plasma Glucose Concentration with Decision Boundary',
       x = 'Age',
       y = 'Plasma Glucose Concentration') +
  theme_minimal() +
  theme(legend.position = "bottom")


##################################Task 4##################################
library(ggplot2)
library(dplyr)
library(caret)

# Assuming that df has already had outliers removed and features scaled as per the previous step
df$Diabetes <- as.factor(df_filtered$Diabetes)

# Prepare the data for logistic regression
df_logistic <- df_filtered[, c('Scaled_Glucose', 'Scaled_Age', 'Diabetes')]

# Split the data into training and test sets
set.seed(42)
index <- createDataPartition(df_logistic$Diabetes, p = 0.8, list = FALSE)
train_data <- df_logistic[index, ]
test_data <- df_logistic[-index, ]

# Fit the logistic regression model to the preprocessed data
model <- glm(Diabetes ~ Scaled_Age + Scaled_Glucose, data = train_data, family = "binomial")

# Predict probabilities on the test data (scaled)
test_data$prob <- predict(model, newdata = test_data, type = "response")

# Apply the lower threshold
test_data$y_pred_low_threshold <- ifelse(test_data$prob >= 0.2, '1', '0')
test_data$y_pred_low_threshold <- factor(test_data$y_pred_low_threshold, levels = levels(df$Diabetes))

# Apply the higher threshold
test_data$y_pred_high_threshold <- ifelse(test_data$prob >= 0.8, '1', '0')
test_data$y_pred_high_threshold <- factor(test_data$y_pred_high_threshold, levels = levels(df$Diabetes))

# Plot for lower threshold
p1 <- ggplot(test_data, aes(x = Scaled_Age, y = Scaled_Glucose, color = y_pred_low_threshold)) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c('1' = 'red', '0' = 'blue')) +
  labs(title = 'Scaled Age vs Scaled Plasma Glucose Concentration with r = 0.2',
       x = 'Scaled Age',
       y = 'Scaled Plasma Glucose Concentration',
       color = 'Predicted Class with r = 0.2') +
  theme_minimal() +
  theme(legend.position = "bottom")

# Plot for higher threshold
p2 <- ggplot(test_data, aes(x = Scaled_Age, y = Scaled_Glucose, color = y_pred_high_threshold)) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c('1' = 'red', '0' = 'blue')) +
  labs(title = 'Scaled Age vs Scaled Plasma Glucose Concentration with r = 0.8',
       x = 'Scaled Age',
       y = 'Scaled Plasma Glucose Concentration',
       color = 'Predicted Class with r = 0.8') +
  theme_minimal() +
  theme(legend.position = "bottom")

# Print the plots
print(p1)
print(p2)


##################################Task 5##################################
library(ggplot2)
library(caret)
library(dplyr)

# Assuming 'df_filtered' is your DataFrame and it already includes 'x1' and 'x2'
df_filtered$z1 <- df_filtered$Plasma_glucose_concentration^4
df_filtered$z2 <- df_filtered$Plasma_glucose_concentration^3 * df_filtered$Age
df_filtered$z3 <- df_filtered$Plasma_glucose_concentration^2 * df_filtered$Age^2
df_filtered$z4 <- df_filtered$Plasma_glucose_concentration * df_filtered$Age^3
df_filtered$z5 <- df_filtered$Age^4

# Define the features and the target variable
X <- df_filtered[, c('Plasma_glucose_concentration', 'Age', 'z1', 'z2', 'z3', 'z4', 'z5')]
y <- df_filtered$Diabetes

# Split the data into training and test sets
set.seed(42)  # For reproducibility
train_index <- createDataPartition(y, p = 0.8, list = FALSE)
X_train <- X[train_index, ]
y_train <- y[train_index]
X_test <- X[-train_index, ]
y_test <- y[-train_index]

# Train the model
model <- glm(y_train ~ ., data = as.data.frame(X_train), family = 'binomial')

# Predict on the training set
y_train_pred <- predict(model, newdata = X_train, type = "response")
y_train_pred_class <- ifelse(y_train_pred > 0.5, 1, 0)

# Compute the misclassification rate
misclassification_rate <- mean(y_train != y_train_pred_class)
cat(sprintf("Misclassification Rate on Training Set: %f\n", misclassification_rate))

# Plotting
# Convert predictions to a factor to match the actual y values
# Convert predictions to a factor to match the actual y values
y_train_pred_class <- factor(ifelse(y_train_pred > 0.5, 1, 0), levels = c(0, 1))

# Include the predicted classes into the training data frame for plotting
X_train$PredictedClass <- y_train_pred_class

# Plotting with Age on the x-axis and Plasma Glucose Concentration on the y-axis
ggplot(X_train, aes(x = Age, y = Plasma_glucose_concentration, color = PredictedClass)) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c('0' = 'blue', '1' = 'red')) +
  labs(title = 'Age vs Plasma Glucose Concentration with Polynomial Features',
       x = 'Age',
       y = 'Plasma Glucose Concentration',
       color = 'Predicted Class') +
  theme_minimal() +
  theme(legend.position = "bottom")


