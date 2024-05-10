---
title: "The Complete Guide To pyproject.toml"
subtitle: "The simplest way to manage and package python projects"
description: "A walkthrough detailing a python setup that ditches poetry, setup.py, and even requirements.txt."
author: devsjc
date: 15 September, 2023
tags: [pyproject, python, packaging]
---

Background: Why use pyproject at all?
=====================================

Let's get the elephant in the room out of the way first, because I know what some of you are thinking: Isn't pyproject.toml the [poetry](https://python-poetry.org/) configuration file? Well, yes it is, but you might not know that it's actually a general python project configuration file that works with many build frontends and backends[[1]](https://packaging.python.org/en/latest/tutorials/packaging-projects/#choosing-a-build-backend), poetry being one such frontend example. So this blog won't be talking about poetry at all. In fact, in favour of creating the most ubiquitous, understandable, and portable python project setup possible, I'll be explaining how to use pyproject with the most widely used build frontend - `pip` - and backend - `setuptools`[[2]](https://drive.google.com/file/d/1U5d5SiXLVkzDpS0i1dJIA4Hu5Qg704T9/view).

So what is wrong with the current way of packaging python projects that might warrant a switch to pyproject-based management? Consider the following not-too-far-fetched pattern for the root of a python repo:

```
cool-python-service
├── requirements.txt
├── requirements-dev.txt
├── setup.py
├── setup.cfg
├── README.md
├── mypy.ini
├── tox.ini
├── .isort.cfg
├── environment.yaml
└── main.py
```

So many files! Lets talk through why each of these files are here, and why they perhaps shouldn't be.

It has been known for a long time the security risk posed by `setup.py` files[[3]](https://www.siliconrepublic.com/enterprise/python-package-security-flaw-setup-vulnerability-hack-developers) - the code within is executed on download of a `sdist` format package by pip, and since it's editable by the author of the package, could contain malicious code. This is partially solved by the introduction of `wheels` and the use of the declarative `setup.cfg`, often used to defining linting configuration and package metadata, but you will regularly still encounter a "dummy" `setup.py` even in projects defined through `setup.cfg`. The `requirements.txt` file, whilst at first order seems to be alright at describing the package dependencies, falls down when you want to separate development dependencies from the subset of those required purely to run an app in production - so you might end up with mulitple requirements files for different contexts. Furthermore, installing a project that is structured like this (with source files alongside configuration files) for local development has knock on effects on writing tests, as imports may be inaccurate reflections[[4]](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/) of their path when installed as a full package. The `environment.yaml` is an example of a virtual-environment-specific dependency file. The inclusion of these types of files serves to reduce the portability of a package, as they require specific tools to be installed outside of the standard python toolkit to begin to work on the project. Finally, the various configuration files for linters and the like (`mypy.ini`, `.isort.cfg` etc.) add further clutter, diluting the repo root and reducing the speed with which a newly-onboarded developer can parse where the important parts of the repository lie. 

The good news is, all of the functionality found in these files can be incorporated neatly into a single, declarative file: `pyproject.toml`. This isn't new news by any stretch, but the lack of uptake and understanding I have experienced has compelled me to write this guide to hopefully aid in moving the community forward to a more straightforward python packaging setup.

But don't just take my word for it! In case you needed any more convincing, the official python.org packaging guide[[5]](https://packaging.python.org/en/latest/tutorials/packaging-projects/) specifies `pyproject.toml` as the recommended way to specify all the metadata, dependencies and build tools required to package a project. And to restate the title, it is agnostic to your environment manager: all it needs is `pip`, which comes preinstalled with most python environments[[6]](https://pip.pypa.io/en/stable/installation/#installation). As such it is an eminently portable setup, reducing the friction for developers working on the code.

Lets get to work cleaning up the roots of those repos!


Ditching requirements.txt
=========================

The first piece of functionality we'll investigate is that of managing your dependencies with `pyproject.toml`. The main metadata section of the `pyproject.toml` file comes under the `[project]` header, and its this section that dependencies are defined, using the `dependencies` key. Lets create a basic file with the mandatory keys, and add some dependencies. Remember to first create a new virtual environment with your favourite virtual environment tool (most likely `venv` [[2]](https://drive.google.com/file/d/1U5d5SiXLVkzDpS0i1dJIA4Hu5Qg704T9/view))!

```toml
[project]
name = "cool-python-project"
version = "0.1.0"
dependencies = [
    "numpy == 1.24.2",
    "structlog == 22.1.0"
]
```

Since pip doesn't yet have the functionality for automatically modifying `pyproject.toml` files[[7]](https://discuss.python.org/t/poetry-add-but-for-pep-621/22957/21), these requirements are added in manually, pinning them at the version desired by the developer. Whilst you can specify unversioned dependencies, lets leave that habit at the door along with the `requirements.txt` that encourage it! Now we can install the desired packages into our virtual environment with 

```bash
$ pip install -e .
```

The dependencies will now be installed into the `site_packages` folder of your virtual environment. (For non-python users, this is similar to a `node-modules` or `vendor` folder - it's where your build frontend stores dependency source code.)


Editable and normal installations
---------------------------------

What's that `-e` flag? This tells pip to perform an *editable* install, which is the install mode best for development of a project. Normally when you install a dependency (such as `requests`), pip copies the source code files as distributed into your site-packages folder. When you instantiate or import the package, it reads the code from that folder. But when you're developing your own project, you want your changes to the source code to be immediately reflected in instantiation, for instance when importing into tests or trying out command-line invocations. As such, you can instruct pip to install your project in editable mode, which means imports of the project resolve at the source code in the repo. This then acts as the source of truth for the package (instead of a copy in `site-packages`) and enables you to quickly iterate on and test code changes. This is a golden rule when developing with a `pyproject.toml` file: *when working locally, always do an editable install of your package*.

It is all to easy to mess up your PYTHONPATH, and accidentally import your package in normal mode, halting development progress whilst you recreate your virtual environment. You can (and should) further ensure import consistency by laying out your python project in the `src` layout, again as recommended by `python.org`[[4]](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/).

For more information on editable installations, see the Setuptools' guide to Development Mode[[8]](https://setuptools.pypa.io/en/latest/userguide/development_mode.html).


Optional dependencies
---------------------

The `pyproject.toml` file improves upon `requirements.txt` by allowing the specification of *optional dependencies* - dependencies required for parts of local development of the project, but not integral to running it when distributed. These could be test- or [linting](#configuring-linters)-specific requirements, and can be grouped by a key describing their utility in the `pyproject.toml` file.

For instance, say our project has its test suite written in [pytest](https://pypi.org/project/pytest/), with a few [behave](https://pypi.org/project/behave/) features thrown in. Furthermore, these tests are running against mock s3 services requiring the [moto](https://pypi.org/project/moto) library. The moto wheel is nearly 4 Mb by itself, which may not sound a lot, but these numbers add up as more external libraries are pulled in: failure to keep an eye on dependency sizes leads to bloated, slow-to-download dockerfiles, wheels, long build pipelines, and frustrated developers! So lets be vigilant and namespace these requirements under an optional dependency group:

```toml
[project.optional-dependencies]
test = [
    "moto[s3] == 4.2.11",
    "pytest == 8.2.0",
    "behave == 1.2.6",
]
```

Now, as before, running `pip install -e .` installs only the dependencies specified in the `dependencies` array under the `[project]` heading. To install the test dependencies as well, we have to explicitly request them:

```bash
$ pip install -e .[test]
```

Note: [zsh](https://www.zsh.org/) users (that's likely you if you're using a Mac) will need to escape the square brackets with a backslash (`pip install -e .\[test\]`)!


Configuring Linters
===================
TODO - talk about ruff, mypy


Packaging for Distribution
==========================
TODO - talk about entrypoints, metadata, versioning


Multi-stage Dockerfiles
=======================
TODO

Bonus: Efficient GitHub Actions usage
=====================================

Bonus: Automatic Documentation
==============================
