

lp_do <- function(fn, value, dv_labels = c(""), constr_lables = c("")) {
    fn_name <- sprintf("%s", as.character(substitute(fn)))
    switch(fn_name,
           "solve" = {
               result <- fn(value)
               if (result == 0) {
                    return("Optimal solution found!")
                } else if (result == 2) {
                    return("The model is infeasible.")
                } else if (result == 3) {
                    return("The model is unbounded.")
                } else {
                    return(sprintf("Check documentation for status: %s", result))
                }
           },
           "get.objective" = {
                   sense <- substr(lp.control(value)$sense, 1, 3)
                   return(sprintf("Z %s = %g", sense, fn(value)))
           },
           "get.variables" = {
                   dv <- fn(value)

                   if (length(dv_labels) != length(dv)) {
                       return(dv)
                   }
                   else {
                       dv_df <-  data.frame(
                           DV = dv_labels,
                           Values = dv
                       )

                       return(dv_df)
                   }
           },
           "get.constraints" = {
                   dv <- fn(value)
                   if (length(constr_lables) != length(dv)) {
                       return(dv)
                   }
                   else {
                       fmted_lables <- lapply(constr_lables, function (x) {return(sprintf("%s ->", x))})
                       dv_df <-  data.frame(
                           Constraints = unlist(fmted_lables),
                           Answers = dv
                       )

                       return(dv_df)
                   }
           }
          )
}

library("lpSolveAPI")
lp_prob <- read.lp("data/PP_umuoh.lp")

lp_prob

lp_do(solve, lp_prob)

lp_do(get.variables, lp_prob, dv_labels = c("Q1", "S1", "Q2", "S2", "Q3" ,"S3", "Q4", "S4"))

lp_do(get.objective, lp_prob)

lp_do(get.constraints, lp_prob, constr_lables = c("Q1 - S1 = 100","S1 + Q2 - S2 = 200", "S2 + Q3 - S3 = 150", "S3 + Q4 - S4 = 400"))

lp_prob_4 <- read.lp("data/PP_umuoh_4.lp")

lp_prob_4

lp_do(solve, lp_prob_4)

lp_do(get.objective, lp_prob_4)

lp_do(get.variables, lp_prob_4, dv_labels = c("Q1", "S1", "B1", "Q2", "S2", "B2", "Q3" ,"S3", "B3", "Q4", "S4", "B4"))

lp_do(get.constraints, lp_prob_4, constr_lables = c(
    "Q1 - S1 = 100",
    "S1 + Q2 - S2 = 200",
    "S2 + Q3 - S3 = 150",
    "S3 + Q4 - S4 = 400",
    "Q1 <= 400 B1",
    "Q2 <= 400 B2",
    "Q3 <= 300 B3",
    "Q4 <= 300 B4"
))

lp_prob_5 <- read.lp("data/PP_umuoh_5.lp")

lp_prob_5

lp_do(solve, lp_prob_5)

lp_do(get.objective, lp_prob_5)

lp_do(get.variables, lp_prob_5)

lp_do(get.constraints, lp_prob_5, constr_lables = c(
    "+Q1 -150 B1 >= 0",
    "+Q2 -150 B2 >= 0",
    "+Q3 -150 B3 >= 0",
    "+Q4 -150 B4 >= 0",
    "+R1 -1000 B1 <= 0",
    "+R2 -1000 B2 <= 0",
    "+R3 -1000 B3 <= 0",
    "+R4 -1000 B4 <= 0",
    "+R5 -1000 B5 <= 0",
    "+Q1 +R1 -S1 = 100",
    "+S1 +Q2 +R2 -S2 = 200",
    "+S2 +Q3 +R3 -S3 = 150",
    "+S3 +Q4 +R4 -S4 = 400"
))
