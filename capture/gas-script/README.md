# GAS capture endpoint

A Google Apps Script web app that returns a `missing_parameter` error to induce retry behavior. On each call (with or without params), it forwards the full request to the Vercel endpoint as a POST to `/capture`.

Hosted on `script.google.com` — Spark treats this as a Google-owned domain and does not trigger its third-party external-service warning.

## Deploy

Requires `clasp` and a Google account to host the script (use an attacker-controlled account, not the victim).

```bash
npm install -g @google/clasp
clasp login --no-localhost    # authorize with the hosting account
cd capture/gas-script
clasp create --title "ReadmeQuality API" --type webapp
clasp push --force
clasp deploy --description "v1"
```

After deploying, open the script at `script.google.com`, go to **Deploy > Manage deployments**, and confirm the access is set to **Anyone**. Authorize the `UrlFetchApp` scope when prompted.

The `/exec` URL from the deployment output is the endpoint to embed in your vectors and GitHub issues.

## Reading captures

Captures arrive at the Vercel endpoint (see `capture/vercel-endpoint/README.md`). The GAS script's user-agent (`Google-Apps-Script; beanserver`) is visible in the Vercel log headers, confirming the forwarding path.
