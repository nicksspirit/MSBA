#!/usr/bin/env python
# coding: utf-8

from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.space import MultiGrid
from mesa.visualization.modules import CanvasGrid
from mesa.visualization.ModularVisualization import ModularServer
from typing import Tuple
import numpy as np

Heading = Tuple[int, int]


class Person(Agent):
    """An agent with fixed initial wealth."""

    def __init__(self, unique_id, model: Model, relationship: str, heading: Heading):
        super().__init__(unique_id, model)
        self.personality = 'brave'
        self.relationship = relationship
        self.heading = heading

    def step(self):
        if self.personality == 'coward':
            self.act_cowardly()
        else:
            self.act_bravely()

    def act_cowardly(self):
        friend = self.random.choice([
            agent for agent in self.model.schedule.agents
            if agent.relationship == 'friend'
        ])
        enemy = self.random.choice([
            agent for agent in self.model.schedule.agents
            if agent.relationship == 'enemy'
        ])
        friend_x, friend_y = friend.pos
        enemy_x, enemy_y = enemy.pos

        x_cor: int = np.clip(friend_x + (friend_x - enemy_x) / 2, 1, self.model.grid.width - 1)
        y_cor: int = np.clip(friend_y + (friend_y - enemy_y) / 2, 1, self.model.grid.height - 1)

        self.model.grid.move_agent(self, (int(x_cor), int(y_cor)))

    def act_bravely(self):
        friend = self.random.choice([
            agent for agent in self.model.schedule.agents
            if agent.relationship == 'friend'
        ])
        enemy = self.random.choice([
            agent for agent in self.model.schedule.agents
            if agent.relationship == 'enemy'
        ])
        friend_x, friend_y = friend.pos
        enemy_x, enemy_y = enemy.pos

        x_cor = np.clip(friend_x + enemy_x / 2, 1, self.model.grid.width - 1)
        y_cor = np.clip(friend_y + enemy_y / 2, 1, self.model.grid.height - 1)

        self.model.grid.move_agent(self, (int(x_cor), int(y_cor)))


class EnvironmentModel(Model):
    """A model with some number of agents."""

    def __init__(self, n, width, height):
        self.num_agents = n
        self.grid = MultiGrid(width, height, False)
        self.schedule = RandomActivation(self)
        self.headings = ((1, 0), (0, 1), (-1, 0), (0, -1))
        self.running = True

        # Create agents
        for i in range(self.num_agents):
            relationship = self.random.choice(['friend', 'enemy'])
            heading = self.random.choice(self.headings)

            # Add the agent to a random grid cell
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)

            person = Person(i, self, relationship, heading)

            self.schedule.add(person)
            self.grid.place_agent(person, (x, y))

    def step(self):
        '''Advance the model by one step.'''
        self.schedule.step()


def agent_portrayal(agent: Person):
    portrayal = {
        "Filled": "true",
        "Layer": 0,
        "relationship": ['Course 1', 'Course 2'],
        "Shape": "arrowHead",
        # arrowHead configs
        "scale": 1,
        "heading_x": agent.heading[0],
        "heading_y": agent.heading[1],
    }

    if agent.personality == 'coward':
        portrayal["Color"] = "red"
    else:
        portrayal["Color"] = "blue"

    return portrayal


if __name__ == '__main__':
    WIDTH = 100
    HEIGHT = 100

    grid = CanvasGrid(agent_portrayal, WIDTH, HEIGHT, 1000, 1000)
    server = ModularServer(EnvironmentModel, [grid], "Environment Model", {
        "n": 100,
        "width": WIDTH,
        "height": HEIGHT,
    })

    server.port = 8521  # The default
    server.launch()
