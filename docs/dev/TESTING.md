# Testing a local BoostBox instance

This guide walks through testing a BoostBox instance you are running locally (e.g. at `http://localhost:8080`). You need BoostBox running and `curl`; a browser is optional. The default API key is `v4v4me` (override with `BB_ALLOWED_KEYS`).

---

## Step 1: Check the server

Confirm the server is up with the health endpoint:

```sh
curl -s http://localhost:8080/health
```

Expected: HTTP 200 and body `{"status":"ok"}`.

---

## Step 2: Send a boost (POST)

POST one boost with full test data. Required fields: `action`, `split`, `value_msat`, `value_msat_total`, `timestamp`. The example below also includes optional fields so the stored payload is easy to recognize when you view it.

```sh
curl -s -X POST http://localhost:8080/boost \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: v4v4me" \
  -d '{"action":"boost","split":1,"value_msat":639000,"value_msat_total":639000,"timestamp":"2025-11-02T16:30:00Z","app_name":"My Awesome Player","sender_name":"Satoshi","message":"Best episode ever!","feed_guid":"72d5e069-f907-5ee7-b0d7-45404f4f0aa5","feed_title":"LINUX Unplugged","item_guid":"4c0a537d-10c6-40ca-b44c-9a43891313c6","item_title":"639: The Mess Machine"}'
```

Expected: HTTP 201 Created and a JSON body with `id`, `url`, and `desc`. Copy the `id` (or the full `url`) for the next step.

Example response:

```json
{
  "id": "01K9R9E2JNE1CR0ME6CFM45T8E",
  "url": "http://localhost:8080/boost/01K9R9E2JNE1CR0ME6CFM45T8E",
  "desc": "rss::payment::boost http://localhost:8080/boost/01K9R9E2JNE1CR0ME6CFM45T8E Best episode ever!"
}
```

---

## Step 3: View the stored data

BoostBox does **not** ship a CLI to list or browse stored boosts. You view a boost by calling **GET /boost/{id}**: the response is an HTML page (human-readable) and the same JSON is in the **x-rss-payment** HTTP header (URL-encoded).

**Browser:** Open the `url` from the POST response in your browser (e.g. `http://localhost:8080/boost/01K9R9E2JNE1CR0ME6CFM45T8E`). The page shows a human-readable view of the metadata.

**curl:** Replace `<id>` with the `id` from your POST response.

```sh
curl -i http://localhost:8080/boost/<id>
```

The response body is HTML; the same JSON is in the **x-rss-payment** header (URL-encoded). To print only that header:

```sh
curl -sD - http://localhost:8080/boost/<id> | grep -i x-rss-payment
```

To URL-decode the value (e.g. with Python): pipe the header value into `python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip().split(' ', 1)[1]))"` or decode it in a browser dev tools / an online decoder.

---

## API docs (optional)

- **Swagger UI:** [http://localhost:8080/docs](http://localhost:8080/docs)
- **OpenAPI JSON:** [http://localhost:8080/openapi.json](http://localhost:8080/openapi.json)

Use these for interactive requests and the full API spec.
