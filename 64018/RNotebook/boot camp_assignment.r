
company_df <- read.csv(
  file = file.choose(),
  header = T,
  sep = ",",
  na.strings = "?",
  stringsAsFactors = F
)

company_df[1:5, ]

summary(company_df)

sprintf("The total number of employees in Happy Co. is %d", nrow(company_df))

png(filename = "salary_vs_experience.png")

plot(
  x = company_df$YearsExperience,
  y = company_df$Salary,
  xlab = "Experience",
  ylab = "Salary",
  main = "Salary vs Experience"
)

dev.off()
