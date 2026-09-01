# Honeycomb Marker Action

Records a [deploy marker](https://docs.honeycomb.io/api/markers/create-a-marker) in Honeycomb, so
deploys show as vertical lines on latency and error charts.

```yaml
- name: Honeycomb deploy marker
  uses: patriotsoftware/honeycomb-marker-action@v1
  with:
    api-key: ${{ secrets.HONEYCOMB_MARKER_API_KEY_DEV }}
    message: suite ${{ github.sha }}
```

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `api-key` | yes | — | Key with the **Markers** permission. Empty makes this a no-op. |
| `message` | yes | — | Marker label. Sanitized, truncated to 120 characters. |
| `type` | no | `deploy` | Markers sharing a type share a color. |
| `dataset` | no | `__all__` | Dataset to mark. `__all__` is environment-wide. |
| `url` | no | the workflow run | URL the marker links to. |
| `start-time` | no | — | Unix seconds the deploy began. Draws a range instead of a point. |
| `end-time` | no | now | Unix seconds the deploy ended. |

## Marking a deploy as a range

Capture the time before deploying and pass it as `start-time`; `end-time` defaults to now.
Honeycomb draws a shaded band, so you can see whether a change happened during the rollout
or after it settled.

```yaml
- id: t0
  run: echo "start=$(date +%s)" >> $GITHUB_OUTPUT

- name: Deploy
  ...

- uses: patriotsoftware/honeycomb-marker-action@v1
  with:
    api-key: ${{ secrets.HONEYCOMB_MARKER_API_KEY_DEV }}
    message: suite ${{ github.sha }}
    start-time: ${{ steps.t0.outputs.start }}
```

## The API key

A **Configuration** key, created per environment under Environments → *environment* → API Keys →
Configuration, with only the **Markers** permission. Use its **Token**.

Ingest keys and Management keys do not work. If your key contains a colon, it is the wrong type.
Keys belong to one environment, so dev and prod need separate keys.

## Notes

- `dataset` defaults to `__all__` because a dataset-scoped marker only renders on queries against
  that dataset — invisible on environment-wide boards. The cost is that simultaneous deploys all
  show on every chart, so put the service name in `message`.
- Never fails the caller: missing key skips, non-2xx warns, always exits 0. A green step is not
  proof the marker posted — look for `✅ Honeycomb marker created`.
