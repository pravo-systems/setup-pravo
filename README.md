# setup-pravo

Installs the [pravo](https://github.com/pravo-systems/pravo) CLI on a GitHub Actions runner.

```yaml
- uses: pravo-systems/setup-pravo@v1
  with:
    version: 0.1.0-rc9   # or latest, the default
- run: pravo validate
```

The action downloads the archive for the runner from the release, checks it against `SHA256SUMS`, and adds `pravo` to `PATH`. Linux, macOS and Windows on amd64 and arm64 are supported.

| Input | Default | |
|---|---|---|
| `version` | `latest` | `0.1.0`, `v0.1.0` or `latest`. `latest` is the newest full release; a pre-release installs only when named. |
| `verify-attestation` | `false` | Also run `gh attestation verify` on the archive. |
| `token` | `github.token` | Resolves `latest` and avoids API rate limits. |

Outputs: `version` and `path`.

Pin a version in a pipeline that must not change under you. See "Run pravo in a pipeline" in the pravo docs for what to run next.
