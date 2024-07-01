# Dockerfile

# Create a virtual environment and install dependencies
# * Only re-execute this step when pyproject.toml changes
# * Don't build a binary for the cool-python-project package
FROM python-3.12 AS build-reqs
WORKDIR /app
COPY pyproject.toml pyproject.toml
RUN python -m venv /venv
RUN /venv/bin/pip install -q .

# Build binary for the package and install code
# * The README.md is required for the long description
FROM build-reqs AS build-app
COPY src src
COPY README.md README.md
RUN /venv/bin/pip install .

# Copy the virtualenv into a distroless image
# * These are small images that only contain the runtime dependencies
FROM gcr.io/distroless/python3-debian11
WORKDIR /app
COPY --from=build-app /venv /venv
ENTRYPOINT ["/venv/bin/coolprojectcli"]
