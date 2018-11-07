lp_do <- function(fn, value, vlabels = c(""), clabels = c("")) {
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

      if (length(vlabels) != length(dv)) {
        return(dv)
      }
      else {
        dv_df <- data.frame(
          DV = vlabels,
          Values = dv
        )

        return(dv_df)
      }
    },
    "get.constraints" = {
      dv <- fn(value)
      if (length(clabels) != length(dv)) {
        return(dv)
      }
      else {
        fmted_lables <- lapply(clabels, function(x) {
          return(sprintf("%s ->", x))
        })
        dv_df <- data.frame(
          Constraints = unlist(fmted_lables),
          Answers = dv
        )

        return(dv_df)
      }
    }
  )
}