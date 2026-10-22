#!/usr/bin/env bash
# PASS when: Confirms a token with inventory-app reads both inventory secrets.
set -uo pipefail

# --- shared helpers (ATS115) -------------------------------------------------
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
BAO_URL="http://openbao.localtest.me:8200"

# tester ARGS: runs a command in the tester pod (curl and jq) inside the cluster.
tester() { kubectl -n clients exec -i deploy/tester -- "$@"; }

# jqt FILTER: runs jq in the tester pod on standard input.
jqt() { tester jq -r "$1"; }

# root_token / unseal_key: the lab-only values in the Secret openbao-init.
root_token() { kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d; }
unseal_key() { kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d; }

# bao_with TOKEN ARGS: runs the bao CLI inside openbao-0 with the given token.
bao_with() {
  local token="$1"; shift
  kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$token" bao "$@"
}

# bao_root ARGS: runs the bao CLI inside openbao-0 with the lab-only root token.
bao_root() { bao_with "$(root_token)" "$@"; }

# api TOKEN METHOD PATH [JSON]: calls the OpenBao HTTP API from the tester pod
# and prints the response body. An empty TOKEN sends no token header.
api() {
  local token="$1" method="$2" path="$3" body="${4:-}"
  local header=()
  [ -n "$token" ] && header=(-H "X-Vault-Token: $token")
  if [ -n "$body" ]; then
    printf '%s' "$body" | tester curl -sS -X "$method" ${header[@]+"${header[@]}"} \
      -H 'Content-Type: application/json' --data-binary @- "$BAO_URL/v1/$path"
  else
    tester curl -sS -X "$method" ${header[@]+"${header[@]}"} "$BAO_URL/v1/$path"
  fi
}

# api_status TOKEN METHOD PATH [JSON]: prints only the HTTP status code.
api_status() {
  local token="$1" method="$2" path="$3" body="${4:-}"
  local header=()
  [ -n "$token" ] && header=(-H "X-Vault-Token: $token")
  if [ -n "$body" ]; then
    printf '%s' "$body" | tester curl -s -o /dev/null -w '%{http_code}' -X "$method" ${header[@]+"${header[@]}"} \
      -H 'Content-Type: application/json' --data-binary @- "$BAO_URL/v1/$path"
  else
    tester curl -s -o /dev/null -w '%{http_code}' -X "$method" ${header[@]+"${header[@]}"} "$BAO_URL/v1/$path"
  fi
}

# token_for POLICY...: creates a 15-minute token with the given policies.
token_for() {
  local args=()
  for policy in "$@"; do args+=("-policy=$policy"); done
  bao_root token create -ttl=15m -field=token "${args[@]}"
}

# userpass_login USER PASSWORD: prints a client token for a userpass user.
userpass_login() {
  api "" POST "auth/userpass/login/$1" "{\"password\":\"$2\"}" | jqt '.auth.client_token // empty'
}

# wait_for_openbao: waits until OpenBao answers and reports that it is unsealed.
wait_for_openbao() {
  local sealed
  for _ in $(seq 1 100); do
    sealed="$(tester curl -fsS "$BAO_URL/v1/sys/seal-status" 2>/dev/null | tester jq -r '.sealed' 2>/dev/null || true)"
    [ "$sealed" = "false" ] && return 0
    sleep 3
  done
  echo "OpenBao did not answer unsealed in time." >&2
  return 1
}

# unseal_openbao: unseals openbao-0 with the lab-only key when it is sealed.
unseal_openbao() {
  for _ in $(seq 1 100); do
    kubectl -n openbao exec openbao-0 -- true >/dev/null 2>&1 && break
    sleep 3
  done
  kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 \
    bao operator unseal "$(unseal_key)" >/dev/null 2>&1 || true
  wait_for_openbao
}

# restart_openbao: the chart uses the OnDelete update strategy, so a changed
# configuration only applies after the pod is deleted. A new pod starts sealed.
restart_openbao() {
  kubectl -n openbao delete pod openbao-0 --wait=true >/dev/null
  sleep 5
  unseal_openbao
}

# record_baseline KEY VALUE / baseline KEY: values the graders compare against.
record_baseline() {
  kubectl -n openbao get configmap lab-baseline >/dev/null 2>&1 || \
    kubectl -n openbao create configmap lab-baseline >/dev/null
  kubectl -n openbao patch configmap lab-baseline --type merge -p "{\"data\":{\"$1\":\"$2\"}}" >/dev/null
}
baseline() { kubectl -n openbao get configmap lab-baseline -o jsonpath="{.data.$1}"; }

# manifest_dir: prints the folder that holds this environment's manifests.
manifest_dir() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for candidate in "$here/../manifests" "./manifests" "$here/manifests"; do
    [ -d "$candidate" ] && { echo "$candidate"; return 0; }
  done
  echo "manifests"
}

# enable_kv: enables KV version 2 at secret/ once.
enable_kv() {
  bao_root secrets list -format=json | jqt 'has("secret/")' | grep -q true || \
    bao_root secrets enable -path=secret -version=2 kv >/dev/null
}

pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --- end of shared helpers ----------------------------------------------------

TOKEN="$(token_for inventory-app)"
for secret in db api; do
  code="$(api_status "$TOKEN" GET "secret/data/inventory/$secret")"
  [ "$code" = "200" ] || fail "a token with inventory-app cannot read secret/inventory/$secret (HTTP $code)."
done
pass "a token with inventory-app reads secret/inventory/db and secret/inventory/api."
