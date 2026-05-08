FROM buildkite/plugin-tester

RUN apk add --no-cache grep

# bats-mock/stub.bash references BATS_TEST_TMPDIR at file-load time (before
# BATS sets it), which breaks gather-tests when -u is active in test files.
ENV BATS_TEST_TMPDIR=/tmp
