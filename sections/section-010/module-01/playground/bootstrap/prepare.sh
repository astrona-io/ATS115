#!/usr/bin/env bash
# Installs OpenBao for `ats-115-playground-010-01`: Helm 3.22.1 and the bao CLI 2.7.1 on
# the machine, the CoreDNS rewrite for openbao.localtest.me, the tester pod,
# and OpenBao v2.7.1 (chart 0.30.4), initialized and unsealed with one lab-only
# key share kept in the Secret openbao-init.
#
# Environment preparation only: it never creates what the task asks for.
set -euo pipefail

HELM_VERSION="3.22.1"
OPENBAO_VERSION="2.7.1"
OPENBAO_CHART_VERSION="0.30.4"
OPENBAO_HOST="openbao.localtest.me"
INIT_MODE="${INIT_MODE:-unsealed}"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[playground] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
have_bao=""
command -v bao >/dev/null 2>&1 && have_bao=$(bao version 2>/dev/null | awk '{print $2}' | sed 's/^v//')
if [ "$have_bao" != "$OPENBAO_VERSION" ]; then
  echo "[playground] Downloading the bao CLI ${OPENBAO_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/openbao_${OPENBAO_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK"
  install -m 0755 "$WORK/bao" "$BIN_DIR/bao"
fi
helm version --short
bao version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One address for the reader's machine and the cluster: openbao.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# this CoreDNS block sends the same name to the OpenBao Service in the cluster.
# The answer is rewritten back to the asked name: Go programs ignore DNS
# answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$OPENBAO_HOST"; then
  echo "[playground] Adding the CoreDNS rewrite for ${OPENBAO_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex openbao\\.localtest\\.me openbao.openbao.svc.cluster.local"
        print "        answer name openbao\\.openbao\\.svc\\.cluster\\.local openbao.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n clients rollout status deployment/tester --timeout=300s

echo "[playground] Installing OpenBao (chart ${OPENBAO_CHART_VERSION})..."
helm repo add openbao https://openbao.github.io/openbao-helm >/dev/null 2>&1 || true
helm repo update openbao >/dev/null
# No --wait: a sealed OpenBao pod is never Ready, by design.
helm upgrade --install openbao openbao/openbao --version "$OPENBAO_CHART_VERSION" \
  --namespace openbao --create-namespace \
  --values "$MANIFEST_DIR/openbao-values.yaml"
for _ in $(seq 1 120); do
  [ "$(kubectl -n openbao get pod openbao-0 -o jsonpath='{.status.containerStatuses[0].started}' 2>/dev/null)" = "true" ] && break
  sleep 5
done

bao_in_pod() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 bao "$@"; }

if [ "$INIT_MODE" = "unsealed" ]; then
  if ! kubectl -n openbao get secret openbao-init >/dev/null 2>&1; then
    echo "[playground] Initializing OpenBao with one lab-only unseal key..."
    INIT_JSON="$(bao_in_pod operator init -key-shares=1 -key-threshold=1 -format=json)"
    UNSEAL_KEY="$(printf '%s' "$INIT_JSON" | sed -n 's/.*"unseal_keys_b64": *\[ *"\([^"]*\)".*/\1/p' | head -1)"
    ROOT_TOKEN="$(printf '%s' "$INIT_JSON" | sed -n 's/.*"root_token": *"\([^"]*\)".*/\1/p' | head -1)"
    [ -z "$UNSEAL_KEY" ] && UNSEAL_KEY="$(printf '%s' "$INIT_JSON" | tr -d '\n ' | sed -n 's/.*"unseal_keys_b64":\["\([^"]*\)".*/\1/p')"
    kubectl -n openbao create secret generic openbao-init \
      --from-literal=unseal-key="$UNSEAL_KEY" --from-literal=root-token="$ROOT_TOKEN"
  fi
  UNSEAL_KEY="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
  bao_in_pod operator unseal "$UNSEAL_KEY" >/dev/null
  kubectl -n openbao wait --for=condition=Ready pod/openbao-0 --timeout=300s
fi

echo "[playground] Ready."
kubectl -n openbao get pods
echo "[playground] Start the port-forward in a second terminal before you use bao:"
echo "  kubectl -n openbao port-forward svc/openbao 8200:8200"
echo "  export BAO_ADDR=http://openbao.localtest.me:8200"

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

echo "[seed] Enabling KV version 2 at secret/ and writing the example secrets..."
enable_kv
bao_root kv put secret/inventory/db username=inventory password=inv-db-password >/dev/null
bao_root kv put secret/inventory/api key=inv-api-key >/dev/null
bao_root kv put secret/inventory/reports schedule=daily >/dev/null
bao_root kv put secret/billing/db username=billing password=bill-db-password >/dev/null
bao_root kv put secret/billing/admin username=root password=bill-admin-password >/dev/null
bao_root kv put secret/billing/reports schedule=weekly >/dev/null
bao_root kv put secret/ci/registry username=ci password=ci-registry-password >/dev/null

echo "[playground] Starting objects ready."
