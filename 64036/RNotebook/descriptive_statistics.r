library(magrittr)
library(corrplot)
load("./data/Financial.rda")

head(Financial)

lapply(colnames(Financial), paste)

fn_names <- c("Mean", "Median", "Standard Deviation")
fn <- list(mean, median, sd)

for (i in seq_along(fn)) {
  out <- sprintf("%s: %g", fn_names[i], fn[[i]](Financial$rev))
  print(out)
}


max(Financial$rev)

Financial[which.max(Financial$rev), ]

Financial[which.min(Financial$rev), ]

Financial$assets %>%
  order() %>%
  tail(5) %>%
  `[`(Financial, ., )

minus <- `-`
pow <- `^`
divide_by <- `/`

st_dev <- Financial$roe %>%
  mean() %>%
  minus(Financial$roe, .) %>%
  pow(2) %>%
  sum() %>%
  divide_by(length(Financial$roe)) %>%
  sqrt()

print(st_dev)

mean_roe <- mean(Financial$roe)
mean_roe

mean_roe_diff <- Financial$roe - mean_roe
print(head(mean_roe_diff, 10))

squared_diff <- mean_roe_diff^2
print(head(squared_diff, 10))

squared_diff_sum <- sum(squared_diff)
squared_diff_sum

stdev <- sqrt(squared_diff_sum / length(Financial$roe))
stdev

ib_stdev <- sd(Financial$roe)
ib_stdev

skewness <- function(x) {
  return(x %>%
    mean() %>%
    minus(x, .) %>%
    divide_by(sd(x)) %>%
    pow(3) %>%
    mean())
}

skewness(Financial$assets)

col_names <- c("rev", "assets", "roe", "ppe", "dps")

for (i in seq_along(col_names)) {
  col_data <- Financial[col_names][[i]]
  out <- sprintf("Skewness of %s is %g", col_names[i], skewness(col_data))
  print(out)
}

hist(Financial$assets, n = 100)

hist(Financial$dps, n = 100)

boxplot(Financial[c("yield", "dps")])

sprintf("stdev of yield: %g", sd(Financial$yield))
sprintf("stdev of dps: %g", sd(Financial$dps))

corrplot(cor(Financial[, 3:9]))
