

```python
import pandas as pd
import pulp as lp
from typing import Sequence, Any
from operator import iadd
from collections import defaultdict
from functools import reduce
```

This is the logic I followed:

We have 21 students who need to be assigned into 7 groups of 3.

We have data on the following traits of the students: 
    1. Academic background
    2. Programming experience
    3. Comfort with public speaking
    
Academic background and programming experience carries a weight of 40% while Comfort with public speaking carries a wieght of 20%

__Variables__

Xij = 1, if person i belongs to group j; 0 otherwise

__Constraints__

* A person can belong to no more than one group.
* A group can only have 3 students.
* Each group must meet a minimum value for each trait. (Reviewing the dataset my group and I came up with minimum values through experimentation)

__Objective__

This is maximization problem where I try to maximize the programming experience and academic background for each group. We can also use the other characteristics, or all of them.

Let's create helper functions to assist in operating on the model.


```python
def create_prob(prob_name: str, sense: int) -> lp.LpProblem:
    return lp.LpProblem(prob_name, sense)


def add_obj_fn(lp_prob: lp.LpProblem, dvar: lp.LpAffineExpression) -> lp.LpProblem:
    return iadd(lp_prob, dvar)


def add_constraint(lp_prob: lp.LpProblem, constrs: Sequence[lp.LpConstraint]) -> lp.LpProblem:
   return reduce(iadd, constrs, lp_prob)


def head(x: Sequence) -> Any:
    return x[0]
```

Using pandas we will read a csv having containing all the information regarding students.


```python
df = pd.read_csv('data/class-stats.csv')
```


```python
df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Name</th>
      <th>ACA_BKG</th>
      <th>PG_EXP</th>
      <th>PB_SPK</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>Omeike Stanley</td>
      <td>2</td>
      <td>3</td>
      <td>5</td>
    </tr>
    <tr>
      <th>1</th>
      <td>Muoh Uzoma</td>
      <td>4</td>
      <td>5</td>
      <td>5</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Palaniappan Sakana</td>
      <td>4</td>
      <td>3</td>
      <td>5</td>
    </tr>
    <tr>
      <th>3</th>
      <td>Kosanam Srihari</td>
      <td>4</td>
      <td>3</td>
      <td>4</td>
    </tr>
    <tr>
      <th>4</th>
      <td>Marjanovic Marianne</td>
      <td>2</td>
      <td>1</td>
      <td>5</td>
    </tr>
  </tbody>
</table>
</div>



Let's view a summary of the dataset


```python
df.describe()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>ACA_BKG</th>
      <th>PG_EXP</th>
      <th>PB_SPK</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>count</th>
      <td>21.000000</td>
      <td>21.000000</td>
      <td>21.000000</td>
    </tr>
    <tr>
      <th>mean</th>
      <td>2.333333</td>
      <td>1.904762</td>
      <td>4.000000</td>
    </tr>
    <tr>
      <th>std</th>
      <td>1.064581</td>
      <td>1.179185</td>
      <td>0.774597</td>
    </tr>
    <tr>
      <th>min</th>
      <td>1.000000</td>
      <td>1.000000</td>
      <td>3.000000</td>
    </tr>
    <tr>
      <th>25%</th>
      <td>2.000000</td>
      <td>1.000000</td>
      <td>3.000000</td>
    </tr>
    <tr>
      <th>50%</th>
      <td>2.000000</td>
      <td>1.000000</td>
      <td>4.000000</td>
    </tr>
    <tr>
      <th>75%</th>
      <td>3.000000</td>
      <td>3.000000</td>
      <td>5.000000</td>
    </tr>
    <tr>
      <th>max</th>
      <td>4.000000</td>
      <td>5.000000</td>
      <td>5.000000</td>
    </tr>
  </tbody>
</table>
</div>




```python
model = create_prob('Group Assignment Prob', lp.LpMaximize)
```


```python
students: pd.DataFrame = df.loc[:, ['Name']]
aca_bkg: pd.Series = df.loc[:, 'ACA_BKG']
pg_exp: pd.Series = df.loc[:, 'PG_EXP']
pb_spk: pd.Series = df.loc[:, 'PB_SPK']
```

Groups range from 1 to 7


```python
groups: pd.Series = pd.Series([f'G{i}' for i in range(1, 8)], dtype=str)
```


```python
print(groups)
```

    0    G1
    1    G2
    2    G3
    3    G4
    4    G5
    5    G6
    6    G7
    dtype: object


`X_ij` is our decision variable where

`i` represent students from 1..21
`j` represent groups from 1..7


```python
indv_group = [(j, head(i)) for j in groups for i in students.values]
```


```python
X_ij = lp.LpVariable.dicts('X_ij',
                           indv_group,
                           lowBound=0,
                           upBound=1,
                           cat='Binary')
```


```python
sum_of_var = [
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))] +
    0.3 * aca_bkg[i] * 0.3 * pg_exp[i] * X_ij[(group, head(val))]
    for group in groups for i, val in enumerate(students.values)
]

# Objective Function
obj_fn = lp.lpSum(sum_of_var)
```

# Constraints

## Individual contraints 

The first set of contraints is that every student has an equal chance of being in a group


```python
const_for_indv1 = lp.lpSum([X_ij[(group, 'Omeike Stanley')] for group in groups]) == 1
const_for_indv2 = lp.lpSum([X_ij[(group, 'Muoh Uzoma')] for group in groups]) == 1
const_for_indv3 = lp.lpSum([X_ij[(group, 'Palaniappan Sakana')] for group in groups]) == 1
const_for_indv4 = lp.lpSum([X_ij[(group, 'Kosanam Srihari')] for group in groups]) == 1
const_for_indv5 = lp.lpSum([X_ij[(group, 'Marjanovic Marianne')] for group in groups]) == 1
const_for_indv6 = lp.lpSum([X_ij[(group, 'Tomar Nancy')] for group in groups]) == 1
const_for_indv7 = lp.lpSum([X_ij[(group, 'Padhye Manali')] for group in groups]) == 1
const_for_indv8 = lp.lpSum([X_ij[(group, 'Qutub Manar')] for group in groups]) == 1
const_for_indv9 = lp.lpSum([X_ij[(group, 'Agrawal Meetali')] for group in groups]) == 1
const_for_indv10 = lp.lpSum([X_ij[(group, 'Steen Jason')] for group in groups]) == 1
const_for_indv11 = lp.lpSum([X_ij[(group, 'Kamat Nandan')] for group in groups]) == 1
const_for_indv12 = lp.lpSum([X_ij[(group, 'Johns Andrew')] for group in groups]) == 1
const_for_indv13 = lp.lpSum([X_ij[(group, 'Samba Choe')] for group in groups]) == 1
const_for_indv14 = lp.lpSum([X_ij[(group, 'Rogers Kareem')] for group in groups]) == 1
const_for_indv15 = lp.lpSum([X_ij[(group, 'Soma Vipin')] for group in groups]) == 1
const_for_indv16 = lp.lpSum([X_ij[(group, 'Thakur Akhil')] for group in groups]) == 1
const_for_indv17 = lp.lpSum([X_ij[(group, 'Xu Yuqiao')] for group in groups]) == 1
const_for_indv18 = lp.lpSum([X_ij[(group, 'Li Lin')] for group in groups]) == 1
const_for_indv19 = lp.lpSum([X_ij[(group, 'Kanabar Sonal')] for group in groups]) == 1
const_for_indv20 = lp.lpSum([X_ij[(group, 'Sudalagunta Spandana')] for group in groups]) == 1
const_for_indv21 = lp.lpSum([X_ij[(group, 'Zhao Yuhan')] for group in groups]) == 1
```

## Group contraints

### A group can only be composed of 3 students


```python
const_for_g1 = lp.lpSum([X_ij[('G1', head(i))] for i in students.values]) == 3
const_for_g2 = lp.lpSum([X_ij[('G2', head(i))] for i in students.values]) == 3
const_for_g3 = lp.lpSum([X_ij[('G3', head(i))] for i in students.values]) == 3
const_for_g4 = lp.lpSum([X_ij[('G4', head(i))] for i in students.values]) == 3
const_for_g5 = lp.lpSum([X_ij[('G5', head(i))] for i in students.values]) == 3
const_for_g6 = lp.lpSum([X_ij[('G6', head(i))] for i in students.values]) == 3
const_for_g7 = lp.lpSum([X_ij[('G7', head(i))] for i in students.values]) == 3
```

### The academic background of a group should be greater than 2


```python
# ACA_BKG for group
aca_bkg_for_g1 = lp.lpSum([aca_bkg[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g2 = lp.lpSum([aca_bkg[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g3 = lp.lpSum([aca_bkg[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g4 = lp.lpSum([aca_bkg[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g5 = lp.lpSum([aca_bkg[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g6 = lp.lpSum([aca_bkg[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 2
aca_bkg_for_g7 = lp.lpSum([aca_bkg[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 2
```

 ### The public speaking level or level of comfort of a group should be greater than 3


```python
# PB_SPK for group
#
pb_spk_for_g1 = lp.lpSum([pb_spk[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g2 = lp.lpSum([pb_spk[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g3 = lp.lpSum([pb_spk[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g4 = lp.lpSum([pb_spk[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g5 = lp.lpSum([pb_spk[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g6 = lp.lpSum([pb_spk[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 3
pb_spk_for_g7 = lp.lpSum([pb_spk[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 3
```

 ### The programming experience of a group should be greater than 3


```python
# PG_EXP for group
#
pg_exp_for_g1 = lp.lpSum([pg_exp[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g2 = lp.lpSum([pg_exp[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g3 = lp.lpSum([pg_exp[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g4 = lp.lpSum([pg_exp[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g5 = lp.lpSum([pg_exp[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g6 = lp.lpSum([pg_exp[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 4
pg_exp_for_g7 = lp.lpSum([pg_exp[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 4
```

### We then add the objective function and all the contraints to the model


```python
model = add_obj_fn(model, obj_fn)

model = add_constraint(model, (
    const_for_indv1, const_for_indv2, const_for_indv3, const_for_indv4,
    const_for_indv5, const_for_indv6, const_for_indv7, const_for_indv8,
    const_for_indv9, const_for_indv10, const_for_indv11, const_for_indv12,
    const_for_indv13, const_for_indv14, const_for_indv15, const_for_indv16,
    const_for_indv17, const_for_indv18, const_for_indv19, const_for_indv20,
    const_for_indv21,
))

model = add_constraint(model, (
    const_for_g1,
    const_for_g2,
    const_for_g3,
    const_for_g4,
    const_for_g5,
    const_for_g6,
    const_for_g7,
))

model = add_constraint(model, (
    aca_bkg_for_g1,
    aca_bkg_for_g2,
    aca_bkg_for_g3,
    aca_bkg_for_g4,
    aca_bkg_for_g5,
    aca_bkg_for_g6,
    aca_bkg_for_g7,
))

model = add_constraint(model, (
    pg_exp_for_g1,
    pg_exp_for_g2,
    pg_exp_for_g3,
    pg_exp_for_g4,
    pg_exp_for_g5,
    pg_exp_for_g6,
    pg_exp_for_g7,
))
```

### Let's view the summary of the lp problem


```python
model
```




    Group Assignment Prob:
    MAXIMIZE
    7.5600000000000005*X_ij_('G1',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G1',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G1',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G1',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G1',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G1',_'Li_Lin') + 1.2599999999999998*X_ij_('G1',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G1',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G1',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G1',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G1',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G1',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G1',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G1',_'Samba_Choe') + 1.8900000000000001*X_ij_('G1',_'Soma_Vipin') + 1.89*X_ij_('G1',_'Steen_Jason') + 0.6299999999999999*X_ij_('G1',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G1',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G1',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G1',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G1',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G2',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G2',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G2',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G2',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G2',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G2',_'Li_Lin') + 1.2599999999999998*X_ij_('G2',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G2',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G2',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G2',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G2',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G2',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G2',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G2',_'Samba_Choe') + 1.8900000000000001*X_ij_('G2',_'Soma_Vipin') + 1.89*X_ij_('G2',_'Steen_Jason') + 0.6299999999999999*X_ij_('G2',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G2',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G2',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G2',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G2',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G3',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G3',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G3',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G3',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G3',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G3',_'Li_Lin') + 1.2599999999999998*X_ij_('G3',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G3',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G3',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G3',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G3',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G3',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G3',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G3',_'Samba_Choe') + 1.8900000000000001*X_ij_('G3',_'Soma_Vipin') + 1.89*X_ij_('G3',_'Steen_Jason') + 0.6299999999999999*X_ij_('G3',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G3',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G3',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G3',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G3',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G4',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G4',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G4',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G4',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G4',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G4',_'Li_Lin') + 1.2599999999999998*X_ij_('G4',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G4',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G4',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G4',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G4',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G4',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G4',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G4',_'Samba_Choe') + 1.8900000000000001*X_ij_('G4',_'Soma_Vipin') + 1.89*X_ij_('G4',_'Steen_Jason') + 0.6299999999999999*X_ij_('G4',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G4',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G4',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G4',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G4',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G5',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G5',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G5',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G5',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G5',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G5',_'Li_Lin') + 1.2599999999999998*X_ij_('G5',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G5',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G5',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G5',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G5',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G5',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G5',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G5',_'Samba_Choe') + 1.8900000000000001*X_ij_('G5',_'Soma_Vipin') + 1.89*X_ij_('G5',_'Steen_Jason') + 0.6299999999999999*X_ij_('G5',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G5',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G5',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G5',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G5',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G6',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G6',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G6',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G6',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G6',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G6',_'Li_Lin') + 1.2599999999999998*X_ij_('G6',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G6',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G6',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G6',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G6',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G6',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G6',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G6',_'Samba_Choe') + 1.8900000000000001*X_ij_('G6',_'Soma_Vipin') + 1.89*X_ij_('G6',_'Steen_Jason') + 0.6299999999999999*X_ij_('G6',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G6',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G6',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G6',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G6',_'Zhao_Yuhan') + 7.5600000000000005*X_ij_('G7',_'Agrawal_Meetali') + 1.2599999999999998*X_ij_('G7',_'Johns_Andrew') + 2.5199999999999996*X_ij_('G7',_'Kamat_Nandan') + 1.2599999999999998*X_ij_('G7',_'Kanabar_Sonal') + 7.5600000000000005*X_ij_('G7',_'Kosanam_Srihari') + 1.2599999999999998*X_ij_('G7',_'Li_Lin') + 1.2599999999999998*X_ij_('G7',_'Marjanovic_Marianne') + 12.600000000000001*X_ij_('G7',_'Muoh_Uzoma') + 3.7800000000000002*X_ij_('G7',_'Omeike_Stanley') + 1.8900000000000001*X_ij_('G7',_'Padhye_Manali') + 7.5600000000000005*X_ij_('G7',_'Palaniappan_Sakana') + 7.5600000000000005*X_ij_('G7',_'Qutub_Manar') + 1.2599999999999998*X_ij_('G7',_'Rogers_Kareem') + 1.2599999999999998*X_ij_('G7',_'Samba_Choe') + 1.8900000000000001*X_ij_('G7',_'Soma_Vipin') + 1.89*X_ij_('G7',_'Steen_Jason') + 0.6299999999999999*X_ij_('G7',_'Sudalagunta_Spandana') + 1.2599999999999998*X_ij_('G7',_'Thakur_Akhil') + 1.2599999999999998*X_ij_('G7',_'Tomar_Nancy') + 1.2599999999999998*X_ij_('G7',_'Xu_Yuqiao') + 0.6299999999999999*X_ij_('G7',_'Zhao_Yuhan') + 0.0
    SUBJECT TO
    _C1: X_ij_('G1',_'Omeike_Stanley') + X_ij_('G2',_'Omeike_Stanley')
     + X_ij_('G3',_'Omeike_Stanley') + X_ij_('G4',_'Omeike_Stanley')
     + X_ij_('G5',_'Omeike_Stanley') + X_ij_('G6',_'Omeike_Stanley')
     + X_ij_('G7',_'Omeike_Stanley') = 1
    
    _C2: X_ij_('G1',_'Muoh_Uzoma') + X_ij_('G2',_'Muoh_Uzoma')
     + X_ij_('G3',_'Muoh_Uzoma') + X_ij_('G4',_'Muoh_Uzoma')
     + X_ij_('G5',_'Muoh_Uzoma') + X_ij_('G6',_'Muoh_Uzoma')
     + X_ij_('G7',_'Muoh_Uzoma') = 1
    
    _C3: X_ij_('G1',_'Palaniappan_Sakana') + X_ij_('G2',_'Palaniappan_Sakana')
     + X_ij_('G3',_'Palaniappan_Sakana') + X_ij_('G4',_'Palaniappan_Sakana')
     + X_ij_('G5',_'Palaniappan_Sakana') + X_ij_('G6',_'Palaniappan_Sakana')
     + X_ij_('G7',_'Palaniappan_Sakana') = 1
    
    _C4: X_ij_('G1',_'Kosanam_Srihari') + X_ij_('G2',_'Kosanam_Srihari')
     + X_ij_('G3',_'Kosanam_Srihari') + X_ij_('G4',_'Kosanam_Srihari')
     + X_ij_('G5',_'Kosanam_Srihari') + X_ij_('G6',_'Kosanam_Srihari')
     + X_ij_('G7',_'Kosanam_Srihari') = 1
    
    _C5: X_ij_('G1',_'Marjanovic_Marianne') + X_ij_('G2',_'Marjanovic_Marianne')
     + X_ij_('G3',_'Marjanovic_Marianne') + X_ij_('G4',_'Marjanovic_Marianne')
     + X_ij_('G5',_'Marjanovic_Marianne') + X_ij_('G6',_'Marjanovic_Marianne')
     + X_ij_('G7',_'Marjanovic_Marianne') = 1
    
    _C6: X_ij_('G1',_'Tomar_Nancy') + X_ij_('G2',_'Tomar_Nancy')
     + X_ij_('G3',_'Tomar_Nancy') + X_ij_('G4',_'Tomar_Nancy')
     + X_ij_('G5',_'Tomar_Nancy') + X_ij_('G6',_'Tomar_Nancy')
     + X_ij_('G7',_'Tomar_Nancy') = 1
    
    _C7: X_ij_('G1',_'Padhye_Manali') + X_ij_('G2',_'Padhye_Manali')
     + X_ij_('G3',_'Padhye_Manali') + X_ij_('G4',_'Padhye_Manali')
     + X_ij_('G5',_'Padhye_Manali') + X_ij_('G6',_'Padhye_Manali')
     + X_ij_('G7',_'Padhye_Manali') = 1
    
    _C8: X_ij_('G1',_'Qutub_Manar') + X_ij_('G2',_'Qutub_Manar')
     + X_ij_('G3',_'Qutub_Manar') + X_ij_('G4',_'Qutub_Manar')
     + X_ij_('G5',_'Qutub_Manar') + X_ij_('G6',_'Qutub_Manar')
     + X_ij_('G7',_'Qutub_Manar') = 1
    
    _C9: X_ij_('G1',_'Agrawal_Meetali') + X_ij_('G2',_'Agrawal_Meetali')
     + X_ij_('G3',_'Agrawal_Meetali') + X_ij_('G4',_'Agrawal_Meetali')
     + X_ij_('G5',_'Agrawal_Meetali') + X_ij_('G6',_'Agrawal_Meetali')
     + X_ij_('G7',_'Agrawal_Meetali') = 1
    
    _C10: X_ij_('G1',_'Steen_Jason') + X_ij_('G2',_'Steen_Jason')
     + X_ij_('G3',_'Steen_Jason') + X_ij_('G4',_'Steen_Jason')
     + X_ij_('G5',_'Steen_Jason') + X_ij_('G6',_'Steen_Jason')
     + X_ij_('G7',_'Steen_Jason') = 1
    
    _C11: X_ij_('G1',_'Kamat_Nandan') + X_ij_('G2',_'Kamat_Nandan')
     + X_ij_('G3',_'Kamat_Nandan') + X_ij_('G4',_'Kamat_Nandan')
     + X_ij_('G5',_'Kamat_Nandan') + X_ij_('G6',_'Kamat_Nandan')
     + X_ij_('G7',_'Kamat_Nandan') = 1
    
    _C12: X_ij_('G1',_'Johns_Andrew') + X_ij_('G2',_'Johns_Andrew')
     + X_ij_('G3',_'Johns_Andrew') + X_ij_('G4',_'Johns_Andrew')
     + X_ij_('G5',_'Johns_Andrew') + X_ij_('G6',_'Johns_Andrew')
     + X_ij_('G7',_'Johns_Andrew') = 1
    
    _C13: X_ij_('G1',_'Samba_Choe') + X_ij_('G2',_'Samba_Choe')
     + X_ij_('G3',_'Samba_Choe') + X_ij_('G4',_'Samba_Choe')
     + X_ij_('G5',_'Samba_Choe') + X_ij_('G6',_'Samba_Choe')
     + X_ij_('G7',_'Samba_Choe') = 1
    
    _C14: X_ij_('G1',_'Rogers_Kareem') + X_ij_('G2',_'Rogers_Kareem')
     + X_ij_('G3',_'Rogers_Kareem') + X_ij_('G4',_'Rogers_Kareem')
     + X_ij_('G5',_'Rogers_Kareem') + X_ij_('G6',_'Rogers_Kareem')
     + X_ij_('G7',_'Rogers_Kareem') = 1
    
    _C15: X_ij_('G1',_'Soma_Vipin') + X_ij_('G2',_'Soma_Vipin')
     + X_ij_('G3',_'Soma_Vipin') + X_ij_('G4',_'Soma_Vipin')
     + X_ij_('G5',_'Soma_Vipin') + X_ij_('G6',_'Soma_Vipin')
     + X_ij_('G7',_'Soma_Vipin') = 1
    
    _C16: X_ij_('G1',_'Thakur_Akhil') + X_ij_('G2',_'Thakur_Akhil')
     + X_ij_('G3',_'Thakur_Akhil') + X_ij_('G4',_'Thakur_Akhil')
     + X_ij_('G5',_'Thakur_Akhil') + X_ij_('G6',_'Thakur_Akhil')
     + X_ij_('G7',_'Thakur_Akhil') = 1
    
    _C17: X_ij_('G1',_'Xu_Yuqiao') + X_ij_('G2',_'Xu_Yuqiao')
     + X_ij_('G3',_'Xu_Yuqiao') + X_ij_('G4',_'Xu_Yuqiao')
     + X_ij_('G5',_'Xu_Yuqiao') + X_ij_('G6',_'Xu_Yuqiao')
     + X_ij_('G7',_'Xu_Yuqiao') = 1
    
    _C18: X_ij_('G1',_'Li_Lin') + X_ij_('G2',_'Li_Lin') + X_ij_('G3',_'Li_Lin')
     + X_ij_('G4',_'Li_Lin') + X_ij_('G5',_'Li_Lin') + X_ij_('G6',_'Li_Lin')
     + X_ij_('G7',_'Li_Lin') = 1
    
    _C19: X_ij_('G1',_'Kanabar_Sonal') + X_ij_('G2',_'Kanabar_Sonal')
     + X_ij_('G3',_'Kanabar_Sonal') + X_ij_('G4',_'Kanabar_Sonal')
     + X_ij_('G5',_'Kanabar_Sonal') + X_ij_('G6',_'Kanabar_Sonal')
     + X_ij_('G7',_'Kanabar_Sonal') = 1
    
    _C20: X_ij_('G1',_'Sudalagunta_Spandana')
     + X_ij_('G2',_'Sudalagunta_Spandana') + X_ij_('G3',_'Sudalagunta_Spandana')
     + X_ij_('G4',_'Sudalagunta_Spandana') + X_ij_('G5',_'Sudalagunta_Spandana')
     + X_ij_('G6',_'Sudalagunta_Spandana') + X_ij_('G7',_'Sudalagunta_Spandana')
     = 1
    
    _C21: X_ij_('G1',_'Zhao_Yuhan') + X_ij_('G2',_'Zhao_Yuhan')
     + X_ij_('G3',_'Zhao_Yuhan') + X_ij_('G4',_'Zhao_Yuhan')
     + X_ij_('G5',_'Zhao_Yuhan') + X_ij_('G6',_'Zhao_Yuhan')
     + X_ij_('G7',_'Zhao_Yuhan') = 1
    
    _C22: X_ij_('G1',_'Agrawal_Meetali') + X_ij_('G1',_'Johns_Andrew')
     + X_ij_('G1',_'Kamat_Nandan') + X_ij_('G1',_'Kanabar_Sonal')
     + X_ij_('G1',_'Kosanam_Srihari') + X_ij_('G1',_'Li_Lin')
     + X_ij_('G1',_'Marjanovic_Marianne') + X_ij_('G1',_'Muoh_Uzoma')
     + X_ij_('G1',_'Omeike_Stanley') + X_ij_('G1',_'Padhye_Manali')
     + X_ij_('G1',_'Palaniappan_Sakana') + X_ij_('G1',_'Qutub_Manar')
     + X_ij_('G1',_'Rogers_Kareem') + X_ij_('G1',_'Samba_Choe')
     + X_ij_('G1',_'Soma_Vipin') + X_ij_('G1',_'Steen_Jason')
     + X_ij_('G1',_'Sudalagunta_Spandana') + X_ij_('G1',_'Thakur_Akhil')
     + X_ij_('G1',_'Tomar_Nancy') + X_ij_('G1',_'Xu_Yuqiao')
     + X_ij_('G1',_'Zhao_Yuhan') = 3
    
    _C23: X_ij_('G2',_'Agrawal_Meetali') + X_ij_('G2',_'Johns_Andrew')
     + X_ij_('G2',_'Kamat_Nandan') + X_ij_('G2',_'Kanabar_Sonal')
     + X_ij_('G2',_'Kosanam_Srihari') + X_ij_('G2',_'Li_Lin')
     + X_ij_('G2',_'Marjanovic_Marianne') + X_ij_('G2',_'Muoh_Uzoma')
     + X_ij_('G2',_'Omeike_Stanley') + X_ij_('G2',_'Padhye_Manali')
     + X_ij_('G2',_'Palaniappan_Sakana') + X_ij_('G2',_'Qutub_Manar')
     + X_ij_('G2',_'Rogers_Kareem') + X_ij_('G2',_'Samba_Choe')
     + X_ij_('G2',_'Soma_Vipin') + X_ij_('G2',_'Steen_Jason')
     + X_ij_('G2',_'Sudalagunta_Spandana') + X_ij_('G2',_'Thakur_Akhil')
     + X_ij_('G2',_'Tomar_Nancy') + X_ij_('G2',_'Xu_Yuqiao')
     + X_ij_('G2',_'Zhao_Yuhan') = 3
    
    _C24: X_ij_('G3',_'Agrawal_Meetali') + X_ij_('G3',_'Johns_Andrew')
     + X_ij_('G3',_'Kamat_Nandan') + X_ij_('G3',_'Kanabar_Sonal')
     + X_ij_('G3',_'Kosanam_Srihari') + X_ij_('G3',_'Li_Lin')
     + X_ij_('G3',_'Marjanovic_Marianne') + X_ij_('G3',_'Muoh_Uzoma')
     + X_ij_('G3',_'Omeike_Stanley') + X_ij_('G3',_'Padhye_Manali')
     + X_ij_('G3',_'Palaniappan_Sakana') + X_ij_('G3',_'Qutub_Manar')
     + X_ij_('G3',_'Rogers_Kareem') + X_ij_('G3',_'Samba_Choe')
     + X_ij_('G3',_'Soma_Vipin') + X_ij_('G3',_'Steen_Jason')
     + X_ij_('G3',_'Sudalagunta_Spandana') + X_ij_('G3',_'Thakur_Akhil')
     + X_ij_('G3',_'Tomar_Nancy') + X_ij_('G3',_'Xu_Yuqiao')
     + X_ij_('G3',_'Zhao_Yuhan') = 3
    
    _C25: X_ij_('G4',_'Agrawal_Meetali') + X_ij_('G4',_'Johns_Andrew')
     + X_ij_('G4',_'Kamat_Nandan') + X_ij_('G4',_'Kanabar_Sonal')
     + X_ij_('G4',_'Kosanam_Srihari') + X_ij_('G4',_'Li_Lin')
     + X_ij_('G4',_'Marjanovic_Marianne') + X_ij_('G4',_'Muoh_Uzoma')
     + X_ij_('G4',_'Omeike_Stanley') + X_ij_('G4',_'Padhye_Manali')
     + X_ij_('G4',_'Palaniappan_Sakana') + X_ij_('G4',_'Qutub_Manar')
     + X_ij_('G4',_'Rogers_Kareem') + X_ij_('G4',_'Samba_Choe')
     + X_ij_('G4',_'Soma_Vipin') + X_ij_('G4',_'Steen_Jason')
     + X_ij_('G4',_'Sudalagunta_Spandana') + X_ij_('G4',_'Thakur_Akhil')
     + X_ij_('G4',_'Tomar_Nancy') + X_ij_('G4',_'Xu_Yuqiao')
     + X_ij_('G4',_'Zhao_Yuhan') = 3
    
    _C26: X_ij_('G5',_'Agrawal_Meetali') + X_ij_('G5',_'Johns_Andrew')
     + X_ij_('G5',_'Kamat_Nandan') + X_ij_('G5',_'Kanabar_Sonal')
     + X_ij_('G5',_'Kosanam_Srihari') + X_ij_('G5',_'Li_Lin')
     + X_ij_('G5',_'Marjanovic_Marianne') + X_ij_('G5',_'Muoh_Uzoma')
     + X_ij_('G5',_'Omeike_Stanley') + X_ij_('G5',_'Padhye_Manali')
     + X_ij_('G5',_'Palaniappan_Sakana') + X_ij_('G5',_'Qutub_Manar')
     + X_ij_('G5',_'Rogers_Kareem') + X_ij_('G5',_'Samba_Choe')
     + X_ij_('G5',_'Soma_Vipin') + X_ij_('G5',_'Steen_Jason')
     + X_ij_('G5',_'Sudalagunta_Spandana') + X_ij_('G5',_'Thakur_Akhil')
     + X_ij_('G5',_'Tomar_Nancy') + X_ij_('G5',_'Xu_Yuqiao')
     + X_ij_('G5',_'Zhao_Yuhan') = 3
    
    _C27: X_ij_('G6',_'Agrawal_Meetali') + X_ij_('G6',_'Johns_Andrew')
     + X_ij_('G6',_'Kamat_Nandan') + X_ij_('G6',_'Kanabar_Sonal')
     + X_ij_('G6',_'Kosanam_Srihari') + X_ij_('G6',_'Li_Lin')
     + X_ij_('G6',_'Marjanovic_Marianne') + X_ij_('G6',_'Muoh_Uzoma')
     + X_ij_('G6',_'Omeike_Stanley') + X_ij_('G6',_'Padhye_Manali')
     + X_ij_('G6',_'Palaniappan_Sakana') + X_ij_('G6',_'Qutub_Manar')
     + X_ij_('G6',_'Rogers_Kareem') + X_ij_('G6',_'Samba_Choe')
     + X_ij_('G6',_'Soma_Vipin') + X_ij_('G6',_'Steen_Jason')
     + X_ij_('G6',_'Sudalagunta_Spandana') + X_ij_('G6',_'Thakur_Akhil')
     + X_ij_('G6',_'Tomar_Nancy') + X_ij_('G6',_'Xu_Yuqiao')
     + X_ij_('G6',_'Zhao_Yuhan') = 3
    
    _C28: X_ij_('G7',_'Agrawal_Meetali') + X_ij_('G7',_'Johns_Andrew')
     + X_ij_('G7',_'Kamat_Nandan') + X_ij_('G7',_'Kanabar_Sonal')
     + X_ij_('G7',_'Kosanam_Srihari') + X_ij_('G7',_'Li_Lin')
     + X_ij_('G7',_'Marjanovic_Marianne') + X_ij_('G7',_'Muoh_Uzoma')
     + X_ij_('G7',_'Omeike_Stanley') + X_ij_('G7',_'Padhye_Manali')
     + X_ij_('G7',_'Palaniappan_Sakana') + X_ij_('G7',_'Qutub_Manar')
     + X_ij_('G7',_'Rogers_Kareem') + X_ij_('G7',_'Samba_Choe')
     + X_ij_('G7',_'Soma_Vipin') + X_ij_('G7',_'Steen_Jason')
     + X_ij_('G7',_'Sudalagunta_Spandana') + X_ij_('G7',_'Thakur_Akhil')
     + X_ij_('G7',_'Tomar_Nancy') + X_ij_('G7',_'Xu_Yuqiao')
     + X_ij_('G7',_'Zhao_Yuhan') = 3
    
    _C29: 4 X_ij_('G1',_'Agrawal_Meetali') + 2 X_ij_('G1',_'Johns_Andrew')
     + 2 X_ij_('G1',_'Kamat_Nandan') + 2 X_ij_('G1',_'Kanabar_Sonal')
     + 4 X_ij_('G1',_'Kosanam_Srihari') + 2 X_ij_('G1',_'Li_Lin')
     + 2 X_ij_('G1',_'Marjanovic_Marianne') + 4 X_ij_('G1',_'Muoh_Uzoma')
     + 2 X_ij_('G1',_'Omeike_Stanley') + X_ij_('G1',_'Padhye_Manali')
     + 4 X_ij_('G1',_'Palaniappan_Sakana') + 4 X_ij_('G1',_'Qutub_Manar')
     + 2 X_ij_('G1',_'Rogers_Kareem') + 2 X_ij_('G1',_'Samba_Choe')
     + X_ij_('G1',_'Soma_Vipin') + 3 X_ij_('G1',_'Steen_Jason')
     + X_ij_('G1',_'Sudalagunta_Spandana') + 2 X_ij_('G1',_'Thakur_Akhil')
     + 2 X_ij_('G1',_'Tomar_Nancy') + 2 X_ij_('G1',_'Xu_Yuqiao')
     + X_ij_('G1',_'Zhao_Yuhan') >= 2
    
    _C30: 4 X_ij_('G2',_'Agrawal_Meetali') + 2 X_ij_('G2',_'Johns_Andrew')
     + 2 X_ij_('G2',_'Kamat_Nandan') + 2 X_ij_('G2',_'Kanabar_Sonal')
     + 4 X_ij_('G2',_'Kosanam_Srihari') + 2 X_ij_('G2',_'Li_Lin')
     + 2 X_ij_('G2',_'Marjanovic_Marianne') + 4 X_ij_('G2',_'Muoh_Uzoma')
     + 2 X_ij_('G2',_'Omeike_Stanley') + X_ij_('G2',_'Padhye_Manali')
     + 4 X_ij_('G2',_'Palaniappan_Sakana') + 4 X_ij_('G2',_'Qutub_Manar')
     + 2 X_ij_('G2',_'Rogers_Kareem') + 2 X_ij_('G2',_'Samba_Choe')
     + X_ij_('G2',_'Soma_Vipin') + 3 X_ij_('G2',_'Steen_Jason')
     + X_ij_('G2',_'Sudalagunta_Spandana') + 2 X_ij_('G2',_'Thakur_Akhil')
     + 2 X_ij_('G2',_'Tomar_Nancy') + 2 X_ij_('G2',_'Xu_Yuqiao')
     + X_ij_('G2',_'Zhao_Yuhan') >= 2
    
    _C31: 4 X_ij_('G3',_'Agrawal_Meetali') + 2 X_ij_('G3',_'Johns_Andrew')
     + 2 X_ij_('G3',_'Kamat_Nandan') + 2 X_ij_('G3',_'Kanabar_Sonal')
     + 4 X_ij_('G3',_'Kosanam_Srihari') + 2 X_ij_('G3',_'Li_Lin')
     + 2 X_ij_('G3',_'Marjanovic_Marianne') + 4 X_ij_('G3',_'Muoh_Uzoma')
     + 2 X_ij_('G3',_'Omeike_Stanley') + X_ij_('G3',_'Padhye_Manali')
     + 4 X_ij_('G3',_'Palaniappan_Sakana') + 4 X_ij_('G3',_'Qutub_Manar')
     + 2 X_ij_('G3',_'Rogers_Kareem') + 2 X_ij_('G3',_'Samba_Choe')
     + X_ij_('G3',_'Soma_Vipin') + 3 X_ij_('G3',_'Steen_Jason')
     + X_ij_('G3',_'Sudalagunta_Spandana') + 2 X_ij_('G3',_'Thakur_Akhil')
     + 2 X_ij_('G3',_'Tomar_Nancy') + 2 X_ij_('G3',_'Xu_Yuqiao')
     + X_ij_('G3',_'Zhao_Yuhan') >= 2
    
    _C32: 4 X_ij_('G4',_'Agrawal_Meetali') + 2 X_ij_('G4',_'Johns_Andrew')
     + 2 X_ij_('G4',_'Kamat_Nandan') + 2 X_ij_('G4',_'Kanabar_Sonal')
     + 4 X_ij_('G4',_'Kosanam_Srihari') + 2 X_ij_('G4',_'Li_Lin')
     + 2 X_ij_('G4',_'Marjanovic_Marianne') + 4 X_ij_('G4',_'Muoh_Uzoma')
     + 2 X_ij_('G4',_'Omeike_Stanley') + X_ij_('G4',_'Padhye_Manali')
     + 4 X_ij_('G4',_'Palaniappan_Sakana') + 4 X_ij_('G4',_'Qutub_Manar')
     + 2 X_ij_('G4',_'Rogers_Kareem') + 2 X_ij_('G4',_'Samba_Choe')
     + X_ij_('G4',_'Soma_Vipin') + 3 X_ij_('G4',_'Steen_Jason')
     + X_ij_('G4',_'Sudalagunta_Spandana') + 2 X_ij_('G4',_'Thakur_Akhil')
     + 2 X_ij_('G4',_'Tomar_Nancy') + 2 X_ij_('G4',_'Xu_Yuqiao')
     + X_ij_('G4',_'Zhao_Yuhan') >= 2
    
    _C33: 4 X_ij_('G5',_'Agrawal_Meetali') + 2 X_ij_('G5',_'Johns_Andrew')
     + 2 X_ij_('G5',_'Kamat_Nandan') + 2 X_ij_('G5',_'Kanabar_Sonal')
     + 4 X_ij_('G5',_'Kosanam_Srihari') + 2 X_ij_('G5',_'Li_Lin')
     + 2 X_ij_('G5',_'Marjanovic_Marianne') + 4 X_ij_('G5',_'Muoh_Uzoma')
     + 2 X_ij_('G5',_'Omeike_Stanley') + X_ij_('G5',_'Padhye_Manali')
     + 4 X_ij_('G5',_'Palaniappan_Sakana') + 4 X_ij_('G5',_'Qutub_Manar')
     + 2 X_ij_('G5',_'Rogers_Kareem') + 2 X_ij_('G5',_'Samba_Choe')
     + X_ij_('G5',_'Soma_Vipin') + 3 X_ij_('G5',_'Steen_Jason')
     + X_ij_('G5',_'Sudalagunta_Spandana') + 2 X_ij_('G5',_'Thakur_Akhil')
     + 2 X_ij_('G5',_'Tomar_Nancy') + 2 X_ij_('G5',_'Xu_Yuqiao')
     + X_ij_('G5',_'Zhao_Yuhan') >= 2
    
    _C34: 4 X_ij_('G6',_'Agrawal_Meetali') + 2 X_ij_('G6',_'Johns_Andrew')
     + 2 X_ij_('G6',_'Kamat_Nandan') + 2 X_ij_('G6',_'Kanabar_Sonal')
     + 4 X_ij_('G6',_'Kosanam_Srihari') + 2 X_ij_('G6',_'Li_Lin')
     + 2 X_ij_('G6',_'Marjanovic_Marianne') + 4 X_ij_('G6',_'Muoh_Uzoma')
     + 2 X_ij_('G6',_'Omeike_Stanley') + X_ij_('G6',_'Padhye_Manali')
     + 4 X_ij_('G6',_'Palaniappan_Sakana') + 4 X_ij_('G6',_'Qutub_Manar')
     + 2 X_ij_('G6',_'Rogers_Kareem') + 2 X_ij_('G6',_'Samba_Choe')
     + X_ij_('G6',_'Soma_Vipin') + 3 X_ij_('G6',_'Steen_Jason')
     + X_ij_('G6',_'Sudalagunta_Spandana') + 2 X_ij_('G6',_'Thakur_Akhil')
     + 2 X_ij_('G6',_'Tomar_Nancy') + 2 X_ij_('G6',_'Xu_Yuqiao')
     + X_ij_('G6',_'Zhao_Yuhan') >= 2
    
    _C35: 4 X_ij_('G7',_'Agrawal_Meetali') + 2 X_ij_('G7',_'Johns_Andrew')
     + 2 X_ij_('G7',_'Kamat_Nandan') + 2 X_ij_('G7',_'Kanabar_Sonal')
     + 4 X_ij_('G7',_'Kosanam_Srihari') + 2 X_ij_('G7',_'Li_Lin')
     + 2 X_ij_('G7',_'Marjanovic_Marianne') + 4 X_ij_('G7',_'Muoh_Uzoma')
     + 2 X_ij_('G7',_'Omeike_Stanley') + X_ij_('G7',_'Padhye_Manali')
     + 4 X_ij_('G7',_'Palaniappan_Sakana') + 4 X_ij_('G7',_'Qutub_Manar')
     + 2 X_ij_('G7',_'Rogers_Kareem') + 2 X_ij_('G7',_'Samba_Choe')
     + X_ij_('G7',_'Soma_Vipin') + 3 X_ij_('G7',_'Steen_Jason')
     + X_ij_('G7',_'Sudalagunta_Spandana') + 2 X_ij_('G7',_'Thakur_Akhil')
     + 2 X_ij_('G7',_'Tomar_Nancy') + 2 X_ij_('G7',_'Xu_Yuqiao')
     + X_ij_('G7',_'Zhao_Yuhan') >= 2
    
    _C36: 3 X_ij_('G1',_'Agrawal_Meetali') + X_ij_('G1',_'Johns_Andrew')
     + 2 X_ij_('G1',_'Kamat_Nandan') + X_ij_('G1',_'Kanabar_Sonal')
     + 3 X_ij_('G1',_'Kosanam_Srihari') + X_ij_('G1',_'Li_Lin')
     + X_ij_('G1',_'Marjanovic_Marianne') + 5 X_ij_('G1',_'Muoh_Uzoma')
     + 3 X_ij_('G1',_'Omeike_Stanley') + 3 X_ij_('G1',_'Padhye_Manali')
     + 3 X_ij_('G1',_'Palaniappan_Sakana') + 3 X_ij_('G1',_'Qutub_Manar')
     + X_ij_('G1',_'Rogers_Kareem') + X_ij_('G1',_'Samba_Choe')
     + 3 X_ij_('G1',_'Soma_Vipin') + X_ij_('G1',_'Steen_Jason')
     + X_ij_('G1',_'Sudalagunta_Spandana') + X_ij_('G1',_'Thakur_Akhil')
     + X_ij_('G1',_'Tomar_Nancy') + X_ij_('G1',_'Xu_Yuqiao')
     + X_ij_('G1',_'Zhao_Yuhan') >= 4
    
    _C37: 3 X_ij_('G2',_'Agrawal_Meetali') + X_ij_('G2',_'Johns_Andrew')
     + 2 X_ij_('G2',_'Kamat_Nandan') + X_ij_('G2',_'Kanabar_Sonal')
     + 3 X_ij_('G2',_'Kosanam_Srihari') + X_ij_('G2',_'Li_Lin')
     + X_ij_('G2',_'Marjanovic_Marianne') + 5 X_ij_('G2',_'Muoh_Uzoma')
     + 3 X_ij_('G2',_'Omeike_Stanley') + 3 X_ij_('G2',_'Padhye_Manali')
     + 3 X_ij_('G2',_'Palaniappan_Sakana') + 3 X_ij_('G2',_'Qutub_Manar')
     + X_ij_('G2',_'Rogers_Kareem') + X_ij_('G2',_'Samba_Choe')
     + 3 X_ij_('G2',_'Soma_Vipin') + X_ij_('G2',_'Steen_Jason')
     + X_ij_('G2',_'Sudalagunta_Spandana') + X_ij_('G2',_'Thakur_Akhil')
     + X_ij_('G2',_'Tomar_Nancy') + X_ij_('G2',_'Xu_Yuqiao')
     + X_ij_('G2',_'Zhao_Yuhan') >= 4
    
    _C38: 3 X_ij_('G3',_'Agrawal_Meetali') + X_ij_('G3',_'Johns_Andrew')
     + 2 X_ij_('G3',_'Kamat_Nandan') + X_ij_('G3',_'Kanabar_Sonal')
     + 3 X_ij_('G3',_'Kosanam_Srihari') + X_ij_('G3',_'Li_Lin')
     + X_ij_('G3',_'Marjanovic_Marianne') + 5 X_ij_('G3',_'Muoh_Uzoma')
     + 3 X_ij_('G3',_'Omeike_Stanley') + 3 X_ij_('G3',_'Padhye_Manali')
     + 3 X_ij_('G3',_'Palaniappan_Sakana') + 3 X_ij_('G3',_'Qutub_Manar')
     + X_ij_('G3',_'Rogers_Kareem') + X_ij_('G3',_'Samba_Choe')
     + 3 X_ij_('G3',_'Soma_Vipin') + X_ij_('G3',_'Steen_Jason')
     + X_ij_('G3',_'Sudalagunta_Spandana') + X_ij_('G3',_'Thakur_Akhil')
     + X_ij_('G3',_'Tomar_Nancy') + X_ij_('G3',_'Xu_Yuqiao')
     + X_ij_('G3',_'Zhao_Yuhan') >= 4
    
    _C39: 3 X_ij_('G4',_'Agrawal_Meetali') + X_ij_('G4',_'Johns_Andrew')
     + 2 X_ij_('G4',_'Kamat_Nandan') + X_ij_('G4',_'Kanabar_Sonal')
     + 3 X_ij_('G4',_'Kosanam_Srihari') + X_ij_('G4',_'Li_Lin')
     + X_ij_('G4',_'Marjanovic_Marianne') + 5 X_ij_('G4',_'Muoh_Uzoma')
     + 3 X_ij_('G4',_'Omeike_Stanley') + 3 X_ij_('G4',_'Padhye_Manali')
     + 3 X_ij_('G4',_'Palaniappan_Sakana') + 3 X_ij_('G4',_'Qutub_Manar')
     + X_ij_('G4',_'Rogers_Kareem') + X_ij_('G4',_'Samba_Choe')
     + 3 X_ij_('G4',_'Soma_Vipin') + X_ij_('G4',_'Steen_Jason')
     + X_ij_('G4',_'Sudalagunta_Spandana') + X_ij_('G4',_'Thakur_Akhil')
     + X_ij_('G4',_'Tomar_Nancy') + X_ij_('G4',_'Xu_Yuqiao')
     + X_ij_('G4',_'Zhao_Yuhan') >= 4
    
    _C40: 3 X_ij_('G5',_'Agrawal_Meetali') + X_ij_('G5',_'Johns_Andrew')
     + 2 X_ij_('G5',_'Kamat_Nandan') + X_ij_('G5',_'Kanabar_Sonal')
     + 3 X_ij_('G5',_'Kosanam_Srihari') + X_ij_('G5',_'Li_Lin')
     + X_ij_('G5',_'Marjanovic_Marianne') + 5 X_ij_('G5',_'Muoh_Uzoma')
     + 3 X_ij_('G5',_'Omeike_Stanley') + 3 X_ij_('G5',_'Padhye_Manali')
     + 3 X_ij_('G5',_'Palaniappan_Sakana') + 3 X_ij_('G5',_'Qutub_Manar')
     + X_ij_('G5',_'Rogers_Kareem') + X_ij_('G5',_'Samba_Choe')
     + 3 X_ij_('G5',_'Soma_Vipin') + X_ij_('G5',_'Steen_Jason')
     + X_ij_('G5',_'Sudalagunta_Spandana') + X_ij_('G5',_'Thakur_Akhil')
     + X_ij_('G5',_'Tomar_Nancy') + X_ij_('G5',_'Xu_Yuqiao')
     + X_ij_('G5',_'Zhao_Yuhan') >= 4
    
    _C41: 3 X_ij_('G6',_'Agrawal_Meetali') + X_ij_('G6',_'Johns_Andrew')
     + 2 X_ij_('G6',_'Kamat_Nandan') + X_ij_('G6',_'Kanabar_Sonal')
     + 3 X_ij_('G6',_'Kosanam_Srihari') + X_ij_('G6',_'Li_Lin')
     + X_ij_('G6',_'Marjanovic_Marianne') + 5 X_ij_('G6',_'Muoh_Uzoma')
     + 3 X_ij_('G6',_'Omeike_Stanley') + 3 X_ij_('G6',_'Padhye_Manali')
     + 3 X_ij_('G6',_'Palaniappan_Sakana') + 3 X_ij_('G6',_'Qutub_Manar')
     + X_ij_('G6',_'Rogers_Kareem') + X_ij_('G6',_'Samba_Choe')
     + 3 X_ij_('G6',_'Soma_Vipin') + X_ij_('G6',_'Steen_Jason')
     + X_ij_('G6',_'Sudalagunta_Spandana') + X_ij_('G6',_'Thakur_Akhil')
     + X_ij_('G6',_'Tomar_Nancy') + X_ij_('G6',_'Xu_Yuqiao')
     + X_ij_('G6',_'Zhao_Yuhan') >= 4
    
    _C42: 3 X_ij_('G7',_'Agrawal_Meetali') + X_ij_('G7',_'Johns_Andrew')
     + 2 X_ij_('G7',_'Kamat_Nandan') + X_ij_('G7',_'Kanabar_Sonal')
     + 3 X_ij_('G7',_'Kosanam_Srihari') + X_ij_('G7',_'Li_Lin')
     + X_ij_('G7',_'Marjanovic_Marianne') + 5 X_ij_('G7',_'Muoh_Uzoma')
     + 3 X_ij_('G7',_'Omeike_Stanley') + 3 X_ij_('G7',_'Padhye_Manali')
     + 3 X_ij_('G7',_'Palaniappan_Sakana') + 3 X_ij_('G7',_'Qutub_Manar')
     + X_ij_('G7',_'Rogers_Kareem') + X_ij_('G7',_'Samba_Choe')
     + 3 X_ij_('G7',_'Soma_Vipin') + X_ij_('G7',_'Steen_Jason')
     + X_ij_('G7',_'Sudalagunta_Spandana') + X_ij_('G7',_'Thakur_Akhil')
     + X_ij_('G7',_'Tomar_Nancy') + X_ij_('G7',_'Xu_Yuqiao')
     + X_ij_('G7',_'Zhao_Yuhan') >= 4
    
    VARIABLES
    0 <= X_ij_('G1',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G1',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G1',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G1',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G1',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G1',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G1',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G1',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G1',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G1',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G1',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G1',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G1',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G1',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G1',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G1',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G1',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G1',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G1',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G1',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G1',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G2',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G2',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G2',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G2',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G2',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G2',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G2',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G2',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G2',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G2',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G2',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G2',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G2',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G2',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G2',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G2',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G2',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G2',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G2',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G2',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G2',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G3',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G3',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G3',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G3',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G3',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G3',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G3',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G3',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G3',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G3',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G3',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G3',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G3',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G3',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G3',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G3',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G3',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G3',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G3',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G3',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G3',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G4',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G4',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G4',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G4',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G4',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G4',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G4',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G4',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G4',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G4',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G4',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G4',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G4',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G4',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G4',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G4',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G4',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G4',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G4',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G4',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G4',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G5',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G5',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G5',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G5',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G5',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G5',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G5',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G5',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G5',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G5',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G5',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G5',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G5',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G5',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G5',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G5',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G5',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G5',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G5',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G5',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G5',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G6',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G6',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G6',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G6',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G6',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G6',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G6',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G6',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G6',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G6',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G6',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G6',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G6',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G6',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G6',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G6',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G6',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G6',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G6',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G6',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G6',_'Zhao_Yuhan') <= 1 Integer
    0 <= X_ij_('G7',_'Agrawal_Meetali') <= 1 Integer
    0 <= X_ij_('G7',_'Johns_Andrew') <= 1 Integer
    0 <= X_ij_('G7',_'Kamat_Nandan') <= 1 Integer
    0 <= X_ij_('G7',_'Kanabar_Sonal') <= 1 Integer
    0 <= X_ij_('G7',_'Kosanam_Srihari') <= 1 Integer
    0 <= X_ij_('G7',_'Li_Lin') <= 1 Integer
    0 <= X_ij_('G7',_'Marjanovic_Marianne') <= 1 Integer
    0 <= X_ij_('G7',_'Muoh_Uzoma') <= 1 Integer
    0 <= X_ij_('G7',_'Omeike_Stanley') <= 1 Integer
    0 <= X_ij_('G7',_'Padhye_Manali') <= 1 Integer
    0 <= X_ij_('G7',_'Palaniappan_Sakana') <= 1 Integer
    0 <= X_ij_('G7',_'Qutub_Manar') <= 1 Integer
    0 <= X_ij_('G7',_'Rogers_Kareem') <= 1 Integer
    0 <= X_ij_('G7',_'Samba_Choe') <= 1 Integer
    0 <= X_ij_('G7',_'Soma_Vipin') <= 1 Integer
    0 <= X_ij_('G7',_'Steen_Jason') <= 1 Integer
    0 <= X_ij_('G7',_'Sudalagunta_Spandana') <= 1 Integer
    0 <= X_ij_('G7',_'Thakur_Akhil') <= 1 Integer
    0 <= X_ij_('G7',_'Tomar_Nancy') <= 1 Integer
    0 <= X_ij_('G7',_'Xu_Yuqiao') <= 1 Integer
    0 <= X_ij_('G7',_'Zhao_Yuhan') <= 1 Integer




```python
model.solve()
```




    1




```python
lp.LpStatus[model.status]
```




    'Optimal'




```python
lp.value(model.objective)
```




    67.41




```python
groups_dict = defaultdict(list)

for group, student in X_ij:
    assign_status = lp.value(X_ij[(group, student)])
    if assign_status == 0:
        continue
    groups_dict[group].append(student)
```


```python
group_df = pd.DataFrame(groups_dict)
```

### The group assignment is as follows


```python
group_df
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>G1</th>
      <th>G2</th>
      <th>G3</th>
      <th>G4</th>
      <th>G5</th>
      <th>G6</th>
      <th>G7</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>Palaniappan Sakana</td>
      <td>Kosanam Srihari</td>
      <td>Agrawal Meetali</td>
      <td>Qutub Manar</td>
      <td>Omeike Stanley</td>
      <td>Marjanovic Marianne</td>
      <td>Muoh Uzoma</td>
    </tr>
    <tr>
      <th>1</th>
      <td>Tomar Nancy</td>
      <td>Johns Andrew</td>
      <td>Thakur Akhil</td>
      <td>Rogers Kareem</td>
      <td>Kamat Nandan</td>
      <td>Padhye Manali</td>
      <td>Steen Jason</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Xu Yuqiao</td>
      <td>Sudalagunta Spandana</td>
      <td>Zhao Yuhan</td>
      <td>Soma Vipin</td>
      <td>Samba Choe</td>
      <td>Li Lin</td>
      <td>Kanabar Sonal</td>
    </tr>
  </tbody>
</table>
</div>


