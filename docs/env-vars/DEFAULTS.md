# Default settings

When you run BoostBox with `nix run` (e.g. `nix run github:noblepayne/boostbox`) or run the binary without setting environment variables, the application uses the built-in defaults below. These match the fallback values in the application code.

## Variables with defaults

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `ENV` | `PROD` | Runtime environment: `DEV`, `STAGING`, or `PROD`. |
| `BB_PORT` | `8080` | Port the webserver listens on. |
| `BB_BASE_URL` | `http://localhost:8080` | Public base URL of the service; used to build response URLs. |
| `BB_ALLOWED_KEYS` | `v4v4me` | Comma-separated API keys required in the `X-Api-Key` header for `POST /boost`. |
| `BB_MAX_BODY` | `102400` | Max request body size in bytes (~100KB). |
| `BB_STORAGE` | `FS` | Backend for metadata: `FS` (filesystem) or `S3`. |
| `BB_FS_ROOT_PATH` | `boosts` | When `BB_STORAGE=FS`, root directory where metadata files are stored. |

## Notes

- **BB_FS_ROOT_PATH**: The default `boosts` is a *relative* path, resolved from the process current working directory (where the JVM was started). Use an absolute path (e.g. `/var/lib/boostbox`) for a fixed location.
- **S3 storage**: When `BB_STORAGE=S3`, you must set `BB_S3_ENDPOINT`, `BB_S3_REGION`, `BB_S3_ACCESS_KEY`, `BB_S3_SECRET_KEY`, and `BB_S3_BUCKET`; there are no defaults for these.

When running BoostBox as a NixOS service via the [NixOS module](../../module.nix), some of these are overridden (e.g. `BB_FS_ROOT_PATH=/var/lib/boostbox`, `ENV=PROD`, and port from the service config).
