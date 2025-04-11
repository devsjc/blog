---
title: "How uv Helps Me To Not Hate Python"
subtitle: "And how to let it help you, too"
description: "A guide to using uv across the python development lifecycle."
author: devsjc
date: 2025-04-11
tags: [uv, python, guide]
---

I'm not a huge fan of Python. Or at least, that's the shortest way to describe how, whilst it's
undeniably extremely capable and accessible at the same time, it is also sprawling with libraries
and tools, has an ecosystem that doesn't feel unified, makes it easy to profliferate bad practice,
and makes it hard to ensure proper code safety. Using it and reading it has always felt like a
chore; packaging and deploying it to production like a recipie for disaster.

Compared to carrying out the development lifecycle in other languages, like Rust or Go, where
types are static and tools are unified, Python has always felt like it got in the way more than it
enabled.

But now `uv` has come along, and made a lot of my dislikes about Python redundant.

For Local development
=====================

I have [already written a blog post](https://devsjc.github.io/blog/20240627-the-complete-guide-to-pyproject-toml/)
on using `pyproject.toml` to manage Python projects, in which the claim is made that it can be laid
out in a tool-agnostic manner. Helpfully, `uv` isn't bucking that trend, and so, provided that I
am cloning a repository that has a `pyproject.toml` file similar to as in that post, getting started
with development is extremely quick:

```bash
$ git clone git@github.com:some-user/some-repo.git
$ cd some-repo
$ uv sync
```

Because `uv` manages dependencies sensibly (pinning versions in `pyproject.toml` and using a
lockfile), creating the environment for someone else's `uv`-managed project actually works! It may
seem like a very low bar, but from all previous experience working with Python, where it was
anyone's guess as to whether a project would work out of the box, this is, all the same, a bar that
warranted clearing!

If I'm lucky enough to have the chance to do some greenfield development, creating a well-laid-out
project is equally simple:

```bash
$ uv init --app --package some-package --build-backend setuptools
$ cd some-package
$ uv venv
```

This creates a new directory called `some-package` with a `pyproject.toml` file, a `README.md`,
and a `src` directory with a folder for the python package inside, as well as a `.venv` folder.
Adding dependencies and installing them to the virtual environment is then done by `uv add`:

```bash
$ uv add requests
```

It feels like using some language that isn't Python, where the package manager is sensible and
dependencies are well managed.

