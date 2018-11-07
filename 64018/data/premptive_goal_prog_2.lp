/* Stage 2 */

/* Objective function */
min: 5 y1n + 4 y2n;

/* Constraints */
12 x1 + 9 x2 + 15 x3 - y1p + y1n = 125;
5 x1 + 3 x2 + 4 x3  + y2n = 40;
5 x1 + 7 x2 + 8 x3  + y3n = 55;

x1 >= 0;
x2 >= 0;

y1p >= 0;
y2p >= 0;
y3p >= 0;

y1n >= 0;
y2n >= 0;
y3n >= 0;
