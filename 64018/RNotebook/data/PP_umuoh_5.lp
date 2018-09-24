/* Objective function */
min: +12 Q1 +10 R1 +2 S1 +14 Q2 +12 R2 +2 S2 +16 Q3 +14 R3 +2 S3 +18 Q4 +16 R4 +2 S4;

/* Constraints */
+Q1 -150 B1 >= 0;
+Q2 -150 B2 >= 0;
+Q3 -150 B3 >= 0;
+Q4 -150 B4 >= 0;
+R1 -1000 B1 <= 0;
+R2 -1000 B2 <= 0;
+R3 -1000 B3 <= 0;
+R4 -1000 B4 <= 0;
+R5 -1000 B5 <= 0;
+Q1 +R1 -S1 = 100;
+S1 +Q2 +R2 -S2 = 200;
+S2 +Q3 +R3 -S3 = 150;
+S3 +Q4 +R4 -S4 = 400;

/* Variable bounds */
Q1 <= 150;
Q2 <= 150;
Q3 <= 150;
Q4 <= 150;
B1 <= 1;
B2 <= 1;
B3 <= 1;
B4 <= 1;

/* Integer definitions */
int B1,B2,B3,B4;
