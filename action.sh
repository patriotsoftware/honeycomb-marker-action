#!/bin/bash
# No `set -e`: a marker is an annotation, never a reason to fail a deploy.
set -uo pipefail

if [[ -z "${INPUT_API_KEY}" ]]; then
    echo "::notice::Honeycomb marker skipped — no API key configured."
    exit 0
fi

DATASET="${INPUT_DATASET:-__all__}"
TYPE="${INPUT_TYPE:-deploy}"
URL="${INPUT_URL:-$DEFAULT_URL}"

# Reduce to characters that need no JSON escaping, so the body can be built with
# printf. jq is not guaranteed on every runner image, and the message often carries
# a branch name, which is attacker-influenceable input going into a JSON document.
MESSAGE="$(printf '%s' "${INPUT_MESSAGE}" | tr -cd 'A-Za-z0-9 ._/()-' | cut -c1-120)"

if [[ -z "${MESSAGE}" ]]; then
    echo "::warning::Honeycomb marker skipped — message was empty after sanitizing."
    exit 0
fi

# Unquoted numbers in the body, so accept only digits.
is_epoch() { [[ "$1" =~ ^[0-9]{1,11}$ ]]; }

TIMES=""
if is_epoch "${INPUT_START_TIME:-}"; then
    END_TIME="${INPUT_END_TIME:-}"
    is_epoch "${END_TIME}" || END_TIME="$(date +%s)"
    TIMES="$(printf ',"start_time":%s,"end_time":%s' "${INPUT_START_TIME}" "${END_TIME}")"
elif is_epoch "${INPUT_END_TIME:-}"; then
    TIMES="$(printf ',"end_time":%s' "${INPUT_END_TIME}")"
fi

HTTP_CODE="$(curl -sS -o /tmp/hny-marker.out -w '%{http_code}' \
    --max-time 20 --retry 2 --retry-connrefused \
    -X POST "https://api.honeycomb.io/1/markers/${DATASET}" \
    -H "X-Honeycomb-Team: ${INPUT_API_KEY}" \
    -H 'Content-Type: application/json' \
    -d "$(printf '{"message":"%s","type":"%s","url":"%s"%s}' "${MESSAGE}" "${TYPE}" "${URL}" "${TIMES}")" \
    || echo 000)"

if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "201" ]]; then
    echo "✅ Honeycomb marker created on '${DATASET}': ${MESSAGE}"
else
    # Printed only on failure, and never the key.
    echo "::warning::Honeycomb marker failed for '${DATASET}' (HTTP ${HTTP_CODE}). Workflow is unaffected."
    head -c 500 /tmp/hny-marker.out 2>/dev/null || true
fi

exit 0
