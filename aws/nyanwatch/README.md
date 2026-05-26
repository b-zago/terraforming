# nyanwatch

## What it does:

1. Gets endpoints to check from SSM Parameter Store
2. Checks for their status
3. Checks according to dynamodb which services just got down since last run, or which are now OK since last run.
4. Notifies with discord DM via [nyanify](https://github.com/b-zago/nyanify)(my webhook for discord DMs) of service status change.

## How it's built

![Diagram](./docs/naynwatch.diagram.svg)

Code that runs on lambda along with GH workflow [here](https://github.com/b-zago/nyanwatch)

## TODOs

- [ ] Automate updating SSM Parameter
