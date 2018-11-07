/* Stage 1 */

/* Objective function */
min: 2 y2p + 3 y3p;

/* Constraints */
5 x1 + 3 x2 + 4 x3 - y2p + y2n = 40;
5 x1 + 7 x2 + 8 x3 - y3p +  y3n = 55;

x1 >= 0;
x2 >= 0;

y1n >= 0;
y2n >= 0;
