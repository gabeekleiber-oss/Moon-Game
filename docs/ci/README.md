# CI (not active yet)
`tests.yml` runs every headless test (`scripts/tools/run_tests.sh`) on each push and PR.
GitHub only lets a token with the `workflow` scope create files under `.github/workflows/`, so the agents' token cannot install it.
**Human, once:** `mkdir -p .github/workflows && git mv docs/ci/tests.yml .github/workflows/tests.yml && git commit -m "enable CI" && git push`
(or add the file in the GitHub web UI). After that a red X on a commit means a test failed.
