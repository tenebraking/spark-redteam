# Vercel capture endpoint

Logs every inbound request as a `CAPTURE` line in Vercel runtime logs. Suitable for any vector surface.

## Deploy

```bash
cd capture/vercel-endpoint
npm install -g vercel   # if not already installed
vercel deploy --prod
```

Set the `FAKE_KEY` environment variable in the Vercel project settings to the synthetic key string you want embedded in the fake traceback error message.

## Reading captures

In the Vercel dashboard, open the project → **Logs** → filter by the search term `CAPTURE`. Each line is a JSON object containing the full request: method, path, headers, query params, and body.

The GAS endpoint forwards its captures here via POST to `/capture`, so a single Vercel project covers both surfaces.
