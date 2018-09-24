/* Objective function */
min: +12 Q1 +2 S1 +1000 B1 +14 Q2 +2 S2 +1000 B2 +16 Q3 +2 S3 +1000 B3 +18 Q4 +2 S4 +1000 B4;

/* Constraints */
+Q1 -S1 = 100;
+S1 +Q2 -S2 = 200;
+S2 +Q3 -S3 = 150;
+S3 +Q4 -S4 = 400;
+Q1 -400 B1 <= 0;
+Q2 -400 B2 <= 0;
+Q3 -300 B3 <= 0;
+Q4 -300 B4 <= 0;

/* Integer definitions */
int B1,B2,B3,B4;
