library("lpSolveAPI")
library("magrittr")
source("../r-utils/util.r")

dea_prob <- read.lp("./data/metropolis_national_bank.lp")

objectives <- list(
  c(10, 31, 0), c(15, 25, 0), c(20, 30, 0),
  c(23, 23, 0), c(30, 20, 0)
)

for (i in seq_along(objectives)) {
  dea_prob <- dea_prob %T>%
    set.objfn(objectives[[i]]) %T>%
    name.lp(sprintf("Branch %d", i))

  print(dea_prob)

  print(lp_do(solve, dea_prob))

  print(lp_do(get.variables, dea_prob, vlabels = c(
    "Loans", "Deposit", "Expense"
  )))

  print(lp_do(get.objective, dea_prob))

  print(lp_do(get.constraints, dea_prob, clabels = c(
    "10 Loans + 31 Deposit - 100 Expense",
    "15 Loans + 25 Deposit - 100 Expense",
    "20 Loans + 30 Deposit - 100 Expense",
    "23 Loans + 23 Deposit - 100 Expense",
    "30 Loans + 20 Deposit - 100 Expense"
  )))
}
