---
title: "The Complete Guide To pyproject.toml"
subtitle: "The simplest way to manage and package python projects"
description: "A walkthrough detailing a python setup that ditches poetry, setup.py, and even requirements.txt."
author: devsjc
date: 15 September, 2023
tags: [pyproject, python, packaging]
---

Background: Why should I use pyproject at all?
==============================================

Let's get the elephant in the room out of the way first, because I know what some of you are thinking: Isn't pyproject.toml the [poetry](https://python-poetry.org/) configuration file? Well, yes it is, but you might not know that it's actually a general python project configuration file that works with [many build frontends and backends](https://packaging.python.org/en/latest/tutorials/packaging-projects/#choosing-a-build-backend). So this blog won't be talking about poetry at all. In fact, in favour of creating the most ubiquitous, understandable, and portable python project setup possible, I'll be explaining how to use pyproject with the best known build frontend - `pip`, and possibly the best known build backend, `setuptools`.

So what is wrong with the current way of packaging python projects that might warrant a switch to pyproject-based management? Consider a familiar pattern for the root of a python repo:

```
cool-python-service
├── requirements.txt
├── setup.py
├── setup.cfg
├── README.md
└── main.py
```

It has been known for a long time the [security risk](https://www.siliconrepublic.com/enterprise/python-package-security-flaw-setup-vulnerability-hack-developers) posed by `setup.py` files - the code within is executed on download of a `sdist` format package by pip, and since it's editable by the author of the package, could contain malicious code. This is partially solved by the introduction of `wheels` and the use of the  declarative `setup.cfg`, often used to defining linting configuration and package metadata, but you will regularly still encounter a "dummy" `setup.py` even in projects defined through `setup.cfg`. The `requirements.txt` file, whilst at first order seems to be alright at describing the package dependencies, falls down when you want to separate development dependencies from the subset of those required purely to run an app in production. Installing a project that is structured like this for local development has knock on effects on writing tests, as imports may be inaccurate reflections of their path when installed as a full package. As well as those listed above, you might also see virtual environment specific dependency files, which serve to reduce the portability of a package, requiring specific tools to be installed that are not part of the standard python installation to begin to work on the project.

The good news is, all of the functionality found in these files can be incorporated neatly into a single, declarative file: `pyproject.toml`. This isn't new news by any stretch, but the lack of uptake and understanding I have experienced has compelled me to write this guide to hopefully aid in moving the community forward to a more straightforward python packaging setup.

But don't just take my word for it! In case you needed any more convincing, the official [python.org packaging guide](https://packaging.python.org/en/latest/tutorials/packaging-projects/) specifies `pyproject.toml` as the recommended way to specify all the metadata, dependencies and build tools required to package a project. And to restate the title, it is agnostic to your environment manager: all it needs is `pip`, which comes preinstalled with [most python environments](https://discuss.python.org/t/poetry-add-but-for-pep-621/22957/21). As such it is an eminently portable setup, reducing the friction for developers working on the code.

Lets get to work cleaning up the roots of those repos!


Ditching requirements.txt
=========================

The first piece of functionality we'll investigate is that of managing your dependencies with `pyproject.toml`. The main metadata section of the `pyproject.toml` file comes under the `[project]` header, and its this section that dependencies are defined, using the `dependencies` key. Lets create a basic file with the mandatory keys, and add some dependencies. Remember to create a new virtual environment with your favourite venv tool first!

```toml
[project]
name = "cool-python-project"
version = "0.1.0"
dependencies = [
    "numpy == 1.24.2",
    "pathlib == 1.0.1",
    "structlog == 22.1.0"
]
```

Since pip [doesn't yet](https://discuss.python.org/t/poetry-add-but-for-pep-621/22957/21) have the functionality for automatically modifying `pyproject.toml` files, these requirements are added in manually, pinning them at the version desired by the developer. Whilst you can specify unversioned dependencies, lets leave that habit at the door along with the `requirements.txt` that encourage it! Now we can install the desired packages into our virtual environment with 

```bash
$ pip install -e .
```

The dependencies will now be installed into the `site_packages` folder of your virtual environment.

Editable and normal installations
---------------------------------

What's that `-e` flag? This tells pip to perform an *editable* install, which is the install mode best for development of a project. Normally when you install a project, pip copies the source code files as distributed into your site-packages folder. When you instantiate the package, it reads the code from that folder. But when you're developing a project, you want your changes to the source code to be reflected in imports of your package, for instance when writing tests or trying out command-line invocations. As such, you can instruct pip to install your project in editable mode, which means imports of the project resolve at the source code in the repo. This then acts as the source of truth for the package and enables you to quickly iterate on and test code changes. This is a golden rule when developing with a `pyproject.toml` file: when working locally, *always do an editable install of your package*.

It is all to easy to mess up your PYTHONPATH, and import your package in normal mode, halting development progress whilst you recreate your virtual environment. You can (and should) further ensure import consistency by laying out your python project in the `src` layout, again as [recommended by `python.org`](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/). 

Optional dependencies
---------------------

The `pyproject.toml` file improves upon `requirements.txt` by allowing the specification of *development dependencies* - dependencies required for local development of the project, but not integral to running it when distributed. These could be test-specific or [linting](TODO: Link to Linting Section) requirements, and can be grouped by a key describing their utility in the `pyproject.toml` file.
