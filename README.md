# Assignment 3 — CI/CD with GitHub Actions

A small Bash diagnostic application (`app/app.sh`) with a local CI pipeline
implemented in GitHub Actions. The pipeline lints the code, runs the test
suite, and builds/smoke-tests a Docker image. There is no cloud deployment.

## Structure

```
assignment-3/
├── README.md
├── app/
│   └── app.sh                 # CLI: system-info / check-host / check-port / help
├── scripts/
│   ├── lint.sh                  # Required-file + bash -n checks (+ optional ShellCheck)
│   └── build.sh                  # Docker build + smoke tests
├── tests/
│   └── test.sh                    # 10 application tests
├── .github/workflows/ci.yml       # validate -> test -> docker pipeline
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh                        # Instructor-supplied local grader
```

## Application

```bash
./app/app.sh system-info
./app/app.sh check-host <host>
./app/app.sh check-port <host> <port>
./app/app.sh help
```

- `system-info` — displays hostname, user, date/time, OS, kernel, uptime.
- `check-host` — validates, resolves, and pings `<host>`.
- `check-port` — validates `<host>`/`<port>` (1–65535) and checks TCP
  connectivity using Bash's `/dev/tcp`.
- `help` — usage information.
- Any invalid command or invalid/missing argument returns **exit code 2**.

## Linting

```bash
./scripts/lint.sh
```

Confirms all required files exist and runs `bash -n` against every Bash
script. If `shellcheck` is installed it also runs `shellcheck -S warning`
as an extra (non-required) check.

## Tests

```bash
./tests/test.sh
```

10 tests covering: `help`, `system-info`, an invalid command, a missing
command, `check-host` with a missing host, `check-host` with a valid host,
`check-port` with a missing port, a non-numeric port, and out-of-range
ports (`0` and `65536`).

## Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
```

`scripts/build.sh` builds the image and runs smoke tests, including an
invalid-command test that must return a non-zero exit code:

```bash
./scripts/build.sh
```

Also runnable via Compose:

```bash
docker compose run --rm devops-tool system-info
```

## GitHub Actions (`.github/workflows/ci.yml`)

Runs on every `push` and `pull_request`, with three jobs enforced in order
via `needs:`:

```
validate  →  test  →  docker
```

- **validate** — installs ShellCheck and runs `scripts/lint.sh`.
- **test** — runs `tests/test.sh` (`needs: validate`).
- **docker** — runs `scripts/build.sh`, which builds the image and
  smoke-tests it (`needs: test`).

## CI failure demonstration

To prove the pipeline actually enforces these checks, a dedicated branch
(`ci-failure-demo`) was pushed with a deliberately broken script (a Bash
syntax error), which failed the **validate** job — and correctly skipped
the **test** and **docker** jobs, since both depend on `validate` via
`needs:`. The syntax error was then fixed and pushed again on the same
branch, after which the full `validate → test → docker` pipeline passed.
The branch was opened as [PR #1](../../pull/1) (both the `push` and
`pull_request` triggers were exercised) and merged into `main`.

- Failing run (syntax error): [`36042790922`](../../actions/runs/36042790922)
- Fixed/passing run: [`36042851882`](../../actions/runs/36042851882)
- `pull_request`-triggered run on PR #1: [`36042946748`](../../actions/runs/36042946748)

## Testing (local grader)

```bash
chmod +x grade.sh app/*.sh scripts/*.sh tests/*.sh
./grade.sh
```

`grade.sh` checks repository structure, Bash syntax, executable
permissions, workflow triggers/jobs/`needs:` dependencies, application
behavior and exit codes, linting, the Docker build and smoke tests, the
student test suite, and basic Git history.

## Assumptions

- The base Docker image is `alpine:3.19`; only the packages the app needs
  are installed (`bash`, `coreutils`, `procps`, `iproute2`, `iputils`,
  `bind-tools`).
- Host resolution tries `getent`, then a Python `socket.gethostbyname`
  fallback, then treats a literal dotted-quad string as already resolved
  — this keeps `check-host`/`check-port` portable between the CI's Ubuntu
  runner, the Alpine container, and a developer's local machine.
- No secrets, tokens, or machine-specific hardcoded values are committed.

## Git Workflow

History includes multiple meaningful commits, feature branches merged
into `main`, and the CI-failure-then-fix branch described above. See
`git log --graph --oneline --all` and the GitHub Actions run history.
