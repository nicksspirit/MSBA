/* Objective function */
min: 12Q1 + 2S1 + 14Q2 + 2S2 + 16Q3 + 2S3+ 18Q4 + 2S4;

/* Constraints */
Q1 <= 400;
Q2 <= 400;
Q3 <= 300;
Q4 <= 300;
Q1 - S1 = 100;
S1 + Q2 - S2 = 200;
S2 + Q3 - S3 = 150;
S3 + Q4 - S4 = 400;
