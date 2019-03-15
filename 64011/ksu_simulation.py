#!/usr/bin/env python
# coding: utf-8

from mesa import Agent, Model
from typing import Tuple, List
import numpy as np

Grade = Tuple[int, str]


def get_grade_score(grade: str):
    grade_gpa = {
        'A': 4.0,
        'A-': 3.7,
        'B+': 3.3,
        'B': 3.0,
        'B-': 2.7,
        'C+': 2.3,
        'C': 2.0,
        'C-': 1.7,
        'D+': 1.3,
        'D': 1.0,
        'F': 0,
    }

    return grade_gpa.get(grade, 0)


class Student(Agent):

    def __init__(self, unique_id, model: Model, act, gpa, fuel_tank=100):
        super().__init__(unique_id, model)
        self.grades: List[Grade] = []
        self.MAJOR: str = ''
        self.ACT: int = act
        self.HS_GPA: int = gpa
        self.COL_GPA: int = 0
        self.total_credit_hrs = 0
        self.enrollment_stat = 'PT'

    def _calc_col_gpa(self):
        grade_scores = [get_grade_score(letter_grade) for _, letter_grade in self.grades]

        self.COL_GPA = np.mean(grade_scores)

    @property
    def total_credit_hrs(self):
        return self.total_credit_hrs

    @total_credit_hrs.setter
    def total_credit_hrs(self, value) -> None:

        if self.enrollment_stat == 'PT' and self.total_credit_hrs <= 11:
            return
        elif self.total_credit_hrs >= 21:
            self.total_credit_hrs = 21
        else:
            self.total_credit_hrs = value


class Course(Agent):
    def __init__(self, unique_id, model: Model):
        super().__init__(unique_id, model)
        self.level = 10000
        self.credit_hrs = 0
        self.class_type = 'TR'
        self.COLLEGE = ''
        self.COURSE_CODE = ''
