# Honeycomb Marker Action

Records a [deploy marker](https://docs.honeycomb.io/api/markers/create-a-marker) in Honeycomb, so
deploys show as vertical lines on latency and error charts.

A marker never fails the calling workflow: a missing key skips, and a failed request warns.

## Usage

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
| `api-key` | yes | — | Honeycomb key with the **Manage Markers** permission. Empty makes the action a no-op. |
| `message` | yes | — | Marker label. Sanitized and truncated to 120 characters. |
| `type` | no | `deploy` | Markers sharing a type share a color. |
| `dataset` | no | `__all__` | Dataset slug to mark. |
| `url` | no | the workflow run | URL the marker links to. |

## The API key

Must be a **Configuration** key — created per environment under Environments → *your environment* →
API Keys → Configuration — carrying only the **Markers** permission. Its value is the **Token**, a
single opaque string.

Two other Honeycomb key types will not work here:

- **Ingest keys** have one permission, whether they may create datasets.
- **Management keys** are org-scoped and formatted `<Key ID>:<Secret>`. If your key contains a colon,
  it is the wrong type.

Keys belong to one environment, so dev and prod need separate keys and separate secrets.

## Why `dataset` defaults to `__all__`

Honeycomb markers belong to a dataset, and a dataset-scoped marker only renders on queries against
that dataset. On an environment-wide board — one that breaks down by `service.name` across services —
such a marker is invisible. `__all__` makes it environment-wide so it renders everywhere.

The trade-off: if several services deploy at once, every service's chart shows all of those markers.
Put the service name in `message` so they stay readable. Pass an explicit `dataset` when you want a
marker confined to one service.

## Notes for callers

- **A green step does not mean the marker posted.** The action always exits 0 by design. The log line
  is the evidence: `✅ Honeycomb marker created on '<dataset>': <message>`.
- `message` is reduced to `A-Za-z0-9 ._/()-` before being placed in the JSON body, so branch names
  cannot break or inject into the request.
