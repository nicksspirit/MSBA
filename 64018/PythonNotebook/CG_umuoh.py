import pandas as pd
import pulp as lp
from typing import Sequence, Any, DefaultDict
from operator import iadd
from collections import defaultdict
from functools import reduce, partial
from cytoolz import assoc

#  Create a partially applied function
#  for creating a new defaultdict which uses List as its factory
assoc_d = partial(assoc, factory=lambda: defaultdict(list))


def create_prob(prob_name: str, sense: int) -> lp.LpProblem:
    return lp.LpProblem(prob_name, sense)


def add_obj_fn(lp_prob: lp.LpProblem, dvar: lp.LpAffineExpression) -> lp.LpProblem:
    return iadd(lp_prob, dvar)


def add_constraint(lp_prob: lp.LpProblem, constrs: Sequence[lp.LpConstraint]) -> lp.LpProblem:
    return reduce(iadd, constrs, lp_prob)


def head(x: Sequence) -> Any:
    return x[0]


def get_groupings(x_ij: lp.LpProblem, dd: DefaultDict) -> DefaultDict:
    def group_up(group: str, student: str, dd: DefaultDict) -> DefaultDict:
        is_assigned = lp.value(x_ij[(group, student)])
        if not is_assigned:
            return assoc_d(dd, group, iadd(dd[group], []))
        return assoc_d(dd, group, iadd(dd[group], [student]))

    return reduce(lambda d, group: group_up(*group, d), x_ij, dd)


if __name__ == '__main__':
    df = pd.read_csv('./data/class-stats.csv')

    model = create_prob('Group Assignment Prob', lp.LpMaximize)

    students: pd.DataFrame = df.loc[:, ['Name']]

    aca_bkg: pd.Series = df.loc[:, 'ACA_BKG']

    pg_exp: pd.Series = df.loc[:, 'PG_EXP']

    pb_spk: pd.Series = df.loc[:, 'PB_SPK']

    groups: pd.Series = pd.Series([f'G{i}' for i in range(1, 8)], dtype=str)

    # Decision Variable
    indv_group = [(j, head(i)) for j in groups for i in students.values]

    X_ij = lp.LpVariable.dicts('X_ij',
                               indv_group,
                               lowBound=0,
                               upBound=1,
                               cat='Binary')

    # Objective Function
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

    obj_fn = lp.lpSum(sum_of_var)

    # Constraints
    #

    # Individual
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

    # Group
    const_for_g1 = lp.lpSum([X_ij[('G1', head(i))] for i in students.values]) == 3
    const_for_g2 = lp.lpSum([X_ij[('G2', head(i))] for i in students.values]) == 3
    const_for_g3 = lp.lpSum([X_ij[('G3', head(i))] for i in students.values]) == 3
    const_for_g4 = lp.lpSum([X_ij[('G4', head(i))] for i in students.values]) == 3
    const_for_g5 = lp.lpSum([X_ij[('G5', head(i))] for i in students.values]) == 3
    const_for_g6 = lp.lpSum([X_ij[('G6', head(i))] for i in students.values]) == 3
    const_for_g7 = lp.lpSum([X_ij[('G7', head(i))] for i in students.values]) == 3

    # ACA_BKG for group
    #
    aca_bkg_for_g1 = lp.lpSum([aca_bkg[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g2 = lp.lpSum([aca_bkg[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g3 = lp.lpSum([aca_bkg[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g4 = lp.lpSum([aca_bkg[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g5 = lp.lpSum([aca_bkg[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g6 = lp.lpSum([aca_bkg[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 2
    aca_bkg_for_g7 = lp.lpSum([aca_bkg[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 2

    # PB_SPK for group
    #
    pb_spk_for_g1 = lp.lpSum([pb_spk[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g2 = lp.lpSum([pb_spk[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g3 = lp.lpSum([pb_spk[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g4 = lp.lpSum([pb_spk[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g5 = lp.lpSum([pb_spk[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g6 = lp.lpSum([pb_spk[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 3
    pb_spk_for_g7 = lp.lpSum([pb_spk[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 3

    # PG_EXP for group
    #
    pg_exp_for_g1 = lp.lpSum([pg_exp[i] * X_ij[('G1', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g2 = lp.lpSum([pg_exp[i] * X_ij[('G2', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g3 = lp.lpSum([pg_exp[i] * X_ij[('G3', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g4 = lp.lpSum([pg_exp[i] * X_ij[('G4', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g5 = lp.lpSum([pg_exp[i] * X_ij[('G5', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g6 = lp.lpSum([pg_exp[i] * X_ij[('G6', head(st))] for i, st in enumerate(students.values)]) >= 4
    pg_exp_for_g7 = lp.lpSum([pg_exp[i] * X_ij[('G7', head(st))] for i, st in enumerate(students.values)]) >= 4

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

    model.solve()

    print(lp.LpStatus[model.status])
    print(f'Optimal value: {lp.value(model.objective)}')

    groups_dict: DefaultDict = get_groupings(X_ij, defaultdict(list))
    group_df: pd.DataFrame = pd.DataFrame(groups_dict)

    print(group_df)
