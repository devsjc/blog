---
title: "The Complete Guide To pyproject.toml"
subtitle: "The simplest way to manage and package python projects"
description: "A walkthrough detailing a python setup that ditches poetry, setup.py, and even requirements.txt."
author: devsjc
date: 15 September, 2023
tags: [pyproject, python, packaging]
---

*Just looking for a `pyproject.toml` to copy to your new project? See the [accompanying gist](https://gist.github.com/devsjc/86b896611d780e3e3c937b9c48682f31)!*

Background: Why do we need pyproject?
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

> Note: `zsh` users (that's likely you if you're using a Mac) will need to escape the square brackets with a backslash, e.g. `pip install -e .\[test\]`! This is because `zsh` uses square brackets for pattern matching[[9]](https://zsh.sourceforge.io/Guide/zshguide05.html#l135).

Now we also want to lint our project to ensure consistency of code, but again, we don't want to include their distributions in our production build as, again, they aren't necessary for running the service - so we do the same thing, this time with a linting section:

```toml
[project.optional-dependencies]
test = [
    "moto[s3] == 4.2.11",
    "pytest == 8.2.0",
    "behave == 1.2.6",
]
lint = [
    "ruff == 0.4.4",
    "mypy == 1.10.0",
]
```

Now, developers can install the linting requirements as above, swapping `test` for `lint`. 

This separation is useful as it clearly defines the concerns each requirement corresponds to, but it might get annoying for a developer adding features to the codebase to remember to install both the `test` and `lint` optional dependencies every time they set up their virtual environment. Thankfully, we can make an easy shorthand for them whilst keeping the modularity brought by the separation of dependencies.

```toml
[project.optional-dependencies]
test = [
    "moto[s3] == 4.2.11",
    "pytest == 8.2.0",
    "behave == 1.2.6",
]
lint = [
    "ruff == 0.4.4",
    "mypy == 1.10.0",
]
dev = [
    "cool-python-project[test,lint]",
]
```

Here we have added a `dev` section to out optional dependencies, intended for local development, which installs all the optional groups required for that task - in this case, `test` and `lint`. Note that `cool-python-project` must be taken verbatim from the `name` field in the `[project]` section, so change this accordingly! Now all a new developer has to do is 

```bash
$ pip install -e .[dev]
```

to pull in everything they might need, but someone else who just wants to run the test suite can still do so, as we haven't lost the granularity of pulling only the necessary requirements for testing.


Phew! We've entirely replaced `requirements.txt` and some, enabling extra useful functionality to boot. But now we've got our dependencies sorted, how do we make sure all developers are linting and formatting the code in the same way? Lets go about removing some more config files, and while we're at it, lets learn what we were on about in the `lint` dependency array with "ruff" and "mypy"...


Configuring Linters
===================

The next piece of functionality we'll glean from `pyproject.toml` is that provided by many tool-specific config, dot, and ini files - linting (and formatting, and fixing!). Using `pyproject.toml`, we'll remove the need for `mypy.ini`, `tox.ini`, and `.isort.cfg`, further reducing the file-soup in the root of our repository.


Ruff
----

There are many linting and fixing tools available for python (`Flake8`, `isort`, `Black` to name a few), all of which would often be configured in `setup.cfg`, `tox.ini`, or other tool-specific dotfiles. Even before we consolidate configuration to our `pyproject,toml` file, lets go one further and consolidate these tools into one first - `ruff`. If you've already heard of it, great! I hope you're using it already. If you haven't or aren't, now is a great time to start - it's quick[[10]](https://astral.sh/blog/the-ruff-formatter), it's fast[[11]](https://docs.astral.sh/ruff/#testimonials), and it's got pace[[12]](https://www.youtube.com/watch?v=AfQarImZ97Y&t=228s). It also bundles all three tools mentioned above, integrates well with IDEs, and of course, is configurable using `pyproject.toml`. Lets add a section for it, using some example values (but by no means the final word on how to configure ruff! It depends on your own or your organisations' preferences).


```toml
[tool.ruff]
line-length = 100
indent-width = 4

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"

[tool.ruff.lint]
select = [
    "F",   # pyflakes
    "E",   # pycodestyle
    "I",   # isort
    "ANN", # flake8 type annotations
    "RUF", # ruff-specific rules
]
fixable = ["ALL"]

[tool.ruff.lint.pydocstyle]
convention = "google"
```

I won't go into extreme detail about the above configuration, as a better reference would be the ruff docs themselves[[13]](https://docs.astral.sh/ruff/configuration/). It is worth noting that the headings and format of the ruff configuration section are subject to change, and the latest version of ruff may expect something different to what is shown in this post. So, make sure to give the documentation a read through in case of any unexpected errors!

In short, we've told ruff to expect a line length of 100 chars (agreeing with Linus Torvalds[[14]](https://linux.slashdot.org/story/20/05/31/211211/linus-torvalds-argues-against-80-column-line-length-coding-style-as-linux-kernel-deprecates-it)), an indent width of 4 spaces, and to use double quotes. We've also specified a set of rules to check against and fix, pulling from `flake8`, `pycodestyle`, `pyflakes` and `isort`. We can now run ruff against our codebase using 

```bash
$ ruff check --fix
```

For updates on file changes, we can also run `ruff check --watch`, but it's often easier to use some IDE integration (VSCode[[15]](https://marketplace.visualstudio.com/items?itemName=charliermarsh.ruff), JetBrains[[16]](https://plugins.jetbrains.com/plugin/20574-ruff), Vim[[17]](https://github.com/dense-analysis/ale)).

Adding ruff into the `pyproject.toml` configuration file like this, as well as pinning the version of ruff in the dependencies, ensures that any other developers of our code will have the same working configuration of ruff present to keep their code style consistent with the already existing codebase. In this manner, a uniform development experience can be had by all contributors.


MyPy
----

A blank project is also the best time[[18]](https://mypy.readthedocs.io/en/stable/existing_code.html) to integrate `mypy`, which bring static type checking to python *a la* compiled languages. The benefits of type safety and compiled languages, and the usage of mypy, is a blog post in itself; suffice to say here that our code will be more understandable to new developers and less error prone if we incorporate type hints and utilise a type checker such as mypy. I would make the argument that we should absolutely include it in our new-fangled `pyproject.toml`-based python program being set up here, and so, as with ruff, we will add a section for it:

```toml
[tool.mypy]
python_version = "3.12"
warn_return_any = true
disallow_untyped_defs = true
```

The python version should match the version of python you're using in your virtual environment. Now we can run

```bash
$ mypy .
```

to type-check any code we have in our codebase, and act on any errors accordingly. For more in depth usage instructions, see the mypy documentation[[19]](https://mypy.readthedocs.io/en/stable/index.html). Again, there are integrations available for your usual IDEs (VSCode[[20]](https://github.com/microsoft/vscode-mypy), JetBrains[[21]](https://github.com/leinardi/mypy-pycharm), Vim[[22]](https://github.com/dense-analysis/ale)).


Alright! Our development environment is in great shape! Anyone trying to work on our codebase needs only python and pip to follow a frictionless entrypoint to consistent coding bliss. I can already picture the glorious short, easy-to-understand nature of the "Development" section of the README! So now lets switch our focus to building our code, and see how the `pyproject.toml` file once again lets us keep things consolidated.


Packaging for Distribution
==========================

If your project is intended as use as an installable library, or a command line tool, chances are you're going to want to publish a distribution of it to PyPi. Building an `sdist` or `wheel` requires the use of a build backend, as mentioned in the [Background](#background-why-do-we-need-pyproject). Here, we'll use setuptools. 
TODO - talk about entrypoints, metadata, versioning


Multi-stage Dockerfiles
=======================
TODO

Bonus: Efficient GitHub Actions usage
=====================================

Bonus: Automatic Documentation
==============================
