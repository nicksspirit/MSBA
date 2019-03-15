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

    def __init__(self, unique_id, model: Model, major: str, act: int, gpa: int, enroll_stat: str):
        super().__init__(unique_id, model)
        self.grades: List[Grade] = []
        self.MAJOR = major
        self.ACT = act
        self.HS_GPA = gpa
        self.enrollment_stat = enroll_stat
        self.COL_GPA: int = 0
        self.total_credit_hrs = 0

    def _calc_col_gpa(self):
        grade_scores = [get_grade_score(letter_grade) for _, letter_grade in self.grades]

        self.COL_GPA = np.mean(grade_scores)

    @property
    def total_credit_hrs(self):
        return self.total_credit_hrs

    @total_credit_hrs.setter
    def total_credit_hrs(self, value: int) -> None:

        if self.enrollment_stat == 'PT' and self.total_credit_hrs <= 11:
            return
        elif self.total_credit_hrs >= 21:
            self.total_credit_hrs = 21
        else:
            self.total_credit_hrs = value


class Course(Agent):

    def __init__(self, unique_id, model: Model, level: str, credit_hrs: int, class_type: str, college: str, code: str):
        super().__init__(unique_id, model)
        self.level = level
        self.credit_hrs = credit_hrs
        self.class_type = class_type
        self.COLLEGE = college
        self.COURSE_CODE = code
