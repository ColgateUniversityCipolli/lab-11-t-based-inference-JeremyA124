# Load necessary libraries
library(tidyverse) # for data manipulation and visualization
library(pwr) # for power analysis
library(effectsize) # for effect size calculations

# Set the random seed for reproducibility
set.seed(7272)

# Perform a power analysis for a one-sample t-test with a medium effect size (d = 0.65)
# Desired power = 0.80, two-sided alternative hypothesis
pwr.t.test(d = 0.65, 
           power = 0.80,
           type = "one.sample",
           alternative = "two.sided")

# Load data from CSV files for "Closer" and "Farther" conditions
Closer.dat <- read_csv("C_vals.csv")
Farther.dat <- read_csv("F_vals.csv")

# Combine the data into a single tibble and calculate the difference between Closer and Farther values
full.dat <- tibble(
  Farther = Farther.dat$data,
  Closer = Closer.dat$data
) %>%
  mutate(
    Difference = Closer - Farther # Calculate the difference
  )

# Reshape data to a long format for plotting
plot.full.dat <- pivot_longer(
  full.dat,
  cols = everything(),       # Reshape all columns to long format
  names_to = "type",         # Column names become the 'type' variable
  values_to = "values"       # Column values become the 'values' variable
)

# Create a boxplot of the 'Closer' and 'Farther' values
ggplot(data = plot.full.dat) +
  geom_boxplot(aes(x = type, y = values, color = type), show.legend = FALSE) + # Boxplot with color by 'type'
  coord_flip() + # Flip axes for horizontal boxplot
  theme_bw() + # Use black-and-white theme
  labs(x = "Syllables", # Label the x-axis
       y = expression(Delta*F/F~"(%)")) + # Label the y-axis with a mathematical expression
  geom_hline(yintercept = 0, linetype = "dashed") # Add a dashed horizontal line at y = 0

# Calculate mean and standard deviation for 'Closer' and 'Farther', then filter the data
plot.full.dat.error <- plot.full.dat %>%
  group_by(type) %>%
  summarize(mean_value = mean(values), # Mean of values
            sd_value = sd(values)) %>% # Standard deviation of values
  filter(type %in% c("Closer", "Farther")) # Filter for Closer and Farther types

# Modify the data to add a 'pair_group' variable for pairing data points
plot.full.dat <- plot.full.dat %>%
  filter(type %in% c("Closer", "Farther")) %>%
  mutate(pair_group = rep(1:25, each = 2)) # Create a group for pairs of data

# Create a scatterplot with error bars and mean line for 'Closer' and 'Farther'
ggplot(data = plot.full.dat) +
  geom_point(aes(x = type, y = values, color = type), shape = 1, show.legend = FALSE) + # Scatter points
  geom_line(aes(x = type, y = values, group = pair_group), alpha = 0.1) + # Lines connecting paired points
  geom_errorbar(data = plot.full.dat.error, aes(
    x = type,
    ymin = mean_value - sd_value,  # Lower error bound
    ymax = mean_value + sd_value  # Upper error bound
  ), width = 0.1,
  size = .7) + # Error bars
  geom_line(data = plot.full.dat.error, aes(x = type, y = mean_value, group = 1), size = .8) + # Mean line
  geom_hline(yintercept = 0, linetype = "dashed") + # Horizontal line at y = 0
  labs(x = NULL, # Remove x-axis label
       y = expression(Delta*F/F~"(%)")) + # Y-axis label
  ylim(c(-0.6, 0.4)) + # Set y-axis limits
  scale_x_discrete(limits = c("Farther", "Closer")) + # Set x-axis categories
  annotate("segment", x = "Farther", y = 0.38, xend = "Closer", yend = 0.38, size = .8) + # Line annotation
  annotate("text", x = 1.5, y = .4, label = "***", size = 4) # Text annotation for significance

# Perform t-test for 'Closer' data, testing if the mean is 0
t.test(full.dat$Closer,
       mu = 0,
       alternative = 'two.sided')

# Perform t-test for 'Closer' data, testing if the mean is greater than 0
t.test(full.dat$Closer,
       mu = 0 ,
       alternative = 'greater')

# Calculate Hedges' g for the 'Closer' data
hedges_g(full.dat$Closer)

# Perform t-test for 'Farther' data, testing if the mean is 0
t.test(full.dat$Farther,
       mu = 0,
       alternative = 'two.sided')

# Perform t-test for 'Farther' data, testing if the mean is less than 0
t.test(full.dat$Farther,
       mu = 0,
       alternative = 'less')

# Calculate Hedges' g for the 'Farther' data
hedges_g(full.dat$Farther)

# Perform t-test for the 'Difference' data, testing if the mean is 0
t.test(full.dat$Difference,
       mu = 0,
       alternative = 'two.sided')

# Calculate Hedges' g for the 'Difference' data
hedges_g(full.dat$Difference)

# Generate a t-distribution with 24 degrees of freedom
t.dist.dat <- tibble(x = seq(-20, 20, 0.01, lenght.out = 1000)) %>%
  mutate(ts = dt(x, df = 24))

# Set resampling parameters
resample.size <- 1000 # Number of resamples
n <- nrow(full.dat) # Sample size

# Create empty tibble to store resampling statistics for 'Closer'
resamples.Closer <- tibble(
  x.bar = rep(NA, resample.size), # A place to save the resampling statistics
  s.x = rep(NA, resample.size), # Standard deviation for each resample
  t.stat = rep(NA, resample.size) # t-statistic for each resample
) 

# Create empty tibble to store resampling statistics for 'Farther'
resamples.Farther <- tibble(
  x.bar = rep(NA, resample.size), # A place to save the resampling statistics
  s.x = rep(NA, resample.size),
  t.stat = rep(NA, resample.size)
) 

# Create empty tibble to store resampling statistics for 'Difference'
resamples.Difference <- tibble(
  x.bar = rep(NA, resample.size), # A place to save the resampling statistics
  s.x = rep(NA, resample.size),
  t.stat = rep(NA, resample.size)
) 

# Function to perform t-resampling
t.resamples <- function(resamples.data,
                        data,
                        n,
                        resample.size) {
  mu.0 <- 0 # Null hypothesis mean (0)
  for (i in 1:resample.size) {
    curr.sample <- sample(data, size = n, replace = TRUE) # Resample with replacement
    resamples.data$x.bar[i] <- mean(curr.sample) # Sample mean
    resamples.data$s.x[i] <- sd(curr.sample) # Sample standard deviation
    resamples.data$t.stat[i] <- (resamples.data$x.bar[i] - mu.0) / (resamples.data$s.x[i] / sqrt(n)) # t-statistic
  }
  return(resamples.data)
}

# Perform t-resampling for Closer, Farther, and Difference
resamples.Closer <- t.resamples(resamples.Closer, full.dat$Closer, n, resample.size)
resamples.Farther <- t.resamples(resamples.Farther, full.dat$Farther, n, resample.size)
resamples.Difference <- t.resamples(resamples.Difference, full.dat$Difference, n, resample.size)

# Set t-statistic breaks and calculate corresponding x-bar breaks
t.breaks <- c(-20, -10, 10, 20, 
              qt(1 - 0.05, df = 24),
              8.3024)
xbar.breaks <- t.breaks * sd(full.dat$Closer) / sqrt(length(full.dat$Closer))

# Create a plot with t-distribution, resampled t-statistics, and p-value areas for Closer
ggplot() +
  geom_line(data = t.dist.dat, aes(x = x, y = ts, color = "Null")) +
  geom_ribbon(data = subset(t.dist.dat, x >= qt(1 - 0.05, df = 24)),
              aes(x = x, ymin = 0, ymax = ts, fill = "Rejection Region"), 
              alpha = 0.5) +
  geom_ribbon(data = subset(t.dist.dat, x >= 8.3024),
              aes(x = x, ymin = 0, ymax = ts, fill = "p-value"), 
              alpha = 0.25) +
  geom_density(data = resamples.Closer, 
               aes(x = t.stat, color = "Resampled")) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("black", "red")) +
  scale_fill_manual("", values = c("lightblue", "yellow")) + 
  theme_bw() +
  theme(legend.position = "bottom") +
  ggtitle("T-Test for the Closer Responses Population Mean",
          subtitle = bquote(H[0]:mu[X] == 0 ~ "vs" ~ H[a]:mu[X] > 0)) +
  scale_x_continuous("t", 
                     breaks = t.breaks, labels = round(t.breaks, 2),
                     sec.axis = sec_axis(~ .,
                                         breaks = t.breaks, labels = round(xbar.breaks, 2),
                                         name = "Mean of Closer Responses")) +
  labs(x = "t",
       y = "Density")

# Set t-statistic breaks and calculate corresponding x-bar breaks for Farther
t.breaks <- c(-20, -10, 10, 20, 
              qt(1 - 0.05, df = 24),
              -7.779)
xbar.breaks <- t.breaks * sd(full.dat$Farther) / sqrt(length(full.dat$Farther))

# Create a plot with t-distribution, resampled t-statistics, and p-value areas for Farther
ggplot() +
  geom_line(data = t.dist.dat, aes(x = x, y = ts, color = "Null")) +
  geom_ribbon(data = subset(t.dist.dat, x <= qt(0.05, df = 24)),
              aes(x = x, ymin = 0, ymax = ts, fill = "Rejection Region"), 
              alpha = 0.5) +
  geom_ribbon(data = subset(t.dist.dat, x >= 8.3024),
              aes(x = x, ymin = 0, ymax = ts, fill = "p-value"), 
              alpha = 0.25) +
  geom_density(data = resamples.Farther, 
               aes(x = t.stat, color = "Resampled")) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("black", "red")) +
  scale_fill_manual("", values = c("lightblue", "yellow")) + 
  theme_bw() +
  theme(legend.position = "bottom") +
  ggtitle("T-Test for the Further Responses Population Mean",
          subtitle = bquote(H[0]:mu[X] == 0 ~ "vs" ~ H[a]:mu[X] < 0)) +
  scale_x_continuous("t", 
                     breaks = t.breaks, labels = round(t.breaks, 2),
                     sec.axis = sec_axis(~ .,
                                         breaks = t.breaks, labels = round(xbar.breaks, 2),
                                         name = "Mean of Further Responses")) +
  labs(x = "t",
       y = "Density")

# Set t-statistic breaks and calculate corresponding x-bar breaks for Difference
t.breaks <- c(-20, -10, 10, 20, 
              qt(1 - 0.05, df = 24),
              8.5109)
xbar.breaks <- t.breaks * t.breaks * sd(full.dat$Difference) / sqrt(length(full.dat$Difference))

# Create a plot with t-distribution, resampled t-statistics, and p-value areas for Difference
ggplot() +
  geom_line(data = t.dist.dat, aes(x = x, y = ts, color = "Null")) +
  geom_ribbon(data = subset(t.dist.dat, x >= qt(1 - 0.025, df = 24)),
              aes(x = x, ymin = 0, ymax = ts, fill = "Rejection Region"), 
              alpha = 0.5) +
  geom_ribbon(data = subset(t.dist.dat, x <= qt(0.025, df = 24)),
              aes(x = x, ymin = 0, ymax = ts, fill = "Rejection Region"), 
              alpha = 0.5) +
  geom_ribbon(data = subset(t.dist.dat, x >= 8.3024),
              aes(x = x, ymin = 0, ymax = ts, fill = "p-value"), 
              alpha = 0.25) +
  geom_density(data = resamples.Closer, 
               aes(x = t.stat, color = "Resampled")) +
  geom_hline(yintercept = 0) +
  scale_color_manual("", values = c("black", "red")) +
  scale_fill_manual("", values = c("lightblue", "yellow")) + 
  theme_bw() +
  theme(legend.position = "bottom") +
  ggtitle("T-Test for the Difference Between ``Populations`` Population Mean",
          subtitle = bquote(H[0]:mu[X] == 0 ~ "vs" ~ H[a]:mu[X] != 0)) +
  scale_x_continuous("t", 
                     breaks = t.breaks, labels = round(t.breaks, 2),
                     sec.axis = sec_axis(~ .,
                                         breaks = t.breaks, labels = round(xbar.breaks, 2),
                                         name = "Mean of Difference Between Populations")) +
  labs(x = "t",
       y = "Density")





