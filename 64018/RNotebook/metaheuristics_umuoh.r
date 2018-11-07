library(GenSA)
library(ggplot2)
library(GA)
library(magrittr)
library(quantmod)
library(PerformanceAnalytics)
library(knitr)

tickers <- c("GE", "IBM", "GOOG", "AMZN", "AAPL")
getSymbols(tickers, from = "2012-10-01", to = "2018-10-31")
P <- NULL

for (ticker in tickers) {
    tmp <- Cl(to.monthly(eval(parse(text = ticker))))
    P <- cbind(P, tmp)
}

colnames(P) <- tickers

R <- diff(log(P))
R <- R[-1, ]
mu <- colMeans(R)
sigma <- cov(R)

pContribCVaR <- ES(
    weights = rep(0.2, 5),
    method = "gaussian",
    portfolio_method = "component",
    mu = mu,
    sigma = sigma
) %>%
    extract("pct_contrib_ES")

pb_obj <- function(w) {
    if (sum(w) == 0) {
        w <- w + 1e-2
    }
    w <- w / sum(w)

    CVaR <- ES(
        weights = w,
        method = "gaussian",
        portfolio_method = "component",
        mu = mu,
        sigma = sigma
    )

    tmp1 <- CVaR$ES
    tmp2 <- max(CVaR$pct_contrib_ES - 0.225, 0)
    out <- tmp1 + 1e3 * tmp2

    return(out)
}

stock_percentage <- function(weight_vals) {
    return(weight_vals %>%
        divide_by(sum(weight_vals)) %>%
        multiply_by(100) %>%
        round(2)
    )
}

set.seed(1234)

sa_prob <- GenSA(
    fn = pb_obj,
    lower = rep(0, 5),
    upper = rep(1, 5),
    control = list(
        smooth = FALSE,
        max.call = 3000
    )
)

sa_prob %>% extract("value")

sa_prob %>% extract("par")

sa_prob %>% extract("counts")

rbind(tickers, stock_percentage(sa_prob$par))

ga_prob <- ga(
    type = "real-valued",
    fitness = function(w) -pb_obj(w),
    lower = rep(0,5),
    upper = rep(1,5),
    popSize = 50
)
summary(ga_prob)
plot(ga_prob)

rbind(tickers, stock_percentage(ga_prob@solution))

ga_solutions <- c(ga_prob@solution, ga_prob@fitnessValue)
sa_soultions <- c(sa_prob$par, sa_prob$value)

p <- matrix(
    c(ga_solutions, sa_soultions),
    ncol = 2
)

rownames(p) <- c( "GE", "IBM", "GOOG", "AMZN", "AAPL", "Fitness Value")
colnames(p) <- c("Genetic Algorithm", "Simulated Annealing")

as.table(p) %>% kable(caption = "")

ga_percentages <- c(stock_percentage(ga_prob@solution))
sa_percentages <- c(stock_percentage(sa_prob$par))

p <- matrix(
    c(ga_percentages, sa_percentages),
    ncol = 2
)

rownames(p) <- c( "GE", "IBM", "GOOG", "AMZN", "AAPL")
colnames(p) <- c("Genetic Algorithm", "Simulated Annealing")

as.table(p) %>% kable(caption = "")

x <- c(61, 63, 67, 69, 70, 74, 76, 81, 86, 91, 95, 97)
y <- c(4.28, 4.08, 4.42, 4.17, 4.48, 4.3, 4.82, 4.7, 5.11, 5.13, 5.64, 5.56)

ssyy <- sum((y - mean(y)) ^ 2)
ssxy <- sum((x - mean(x)) * (y - mean(y)))
ssx <- sum((x - mean(x)) ^ 2)
b1 <- ssxy/ssx
b0 <- mean(y) - b1 * mean(x)

print(b1)
print(b0)

linear_model <- lm(y ~ x)

summary(linear_model)

obj <- function (r) {
    fn <- function (b0, b1) {
        return (sum(y - (b0 + b1 * x)) ^ 2)
    }
    return (fn(r[1], r[2]))
}

ubound <- c(2, 1)
lbound <- c(0, 0)

ga_search <- ga(
    type = "real-valued",
    fitness = function (x) -obj(x),
    lower = lbound,
    upper = ubound,
    popSize = 50
)

summary(ga_search)
plot(ga_search)

par <- c(1, 0)

sa_search <- GenSA(
    par = par,
    lower = lbound,
    upper = ubound,
    fn = obj
)

sa_search %>% extract("value")

sa_search %>% extract("par")

sa_search %>% extract("counts")

dataset <- data.frame(x, y)

ggplot(dataset, aes(x = x, y = y)) +
    ggtitle(
        "Regression Line of Genetic Algoritm (GA),\nGenetic Algoritm (GA),\nSimulated Anealing (SA),\nand normal Linear Regression (LM)",
        subtitle = "A comparison between GA, SA, and LM"
    ) +
    geom_point(shape=1) +

    # Add linear regression lines
    geom_smooth(method=lm, se=FALSE, col = "green") +

    # Simulated Annealing Regression Line
    geom_abline(
        intercept = sa_search$par[1],
        slope = sa_search$par[2],
        col = "blue"
    ) +

    # Genetic Algorithm Regression Line
    geom_abline(
        intercept = ga_search@solution[1],
        slope = ga_search@solution[2],
        col = "red"
    ) +
    geom_text(aes(
        x = 70,
        y = 5.4,
        label = sprintf("GA -> Y = %g + %g * X", ga_search@solution[1], ga_search@solution[2]),
        color = "GA"
    )) +
    geom_text(aes(
        x = 70,
        y = 5.2,
        label = sprintf("SA -> Y = %g + %g * X", sa_search$par[1], sa_search$par[2]),
        color = "SA"
    )) +
    geom_text(aes(
        x = 70,
        y = 5.0,
        label = sprintf("LM -> Y = %g + %g * X", b0, b1),
        color = "LM"
    ))

# plot(x, y, col = "red", xlab = "X", ylab = "Y")
# abline(c(ga_search@solution), col = "red")
# abline(c(sa_search$par), col = "blue")
