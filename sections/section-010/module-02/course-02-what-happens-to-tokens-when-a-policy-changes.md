# What Happens To Tokens When A Policy Changes

A token does not contain the rules of its policies. It contains only their names. This single fact decides what happens when you edit a policy at midday while hundreds of applications run with tokens that carry it. This part shows when a change takes effect, what a deleted policy does, and how a token gets policies from sources other than its own list.

## Names are resolved at request time

When a client sends a request, OpenBao looks up the token, reads its list of policy names, loads the current text of each policy and builds the set of rules for that request. The text is not copied into the token when the token is created.

Prove it with the policy `team-app` and a token that carries it. Create the token and test one path:

```sh
TOKEN=$(bao token create -policy=team-app -ttl=30m -field=token)
bao token capabilities "$TOKEN" secret/data/billing/db
```

The answer is `deny`. Now give the policy a rule for the billing secret, without creating a new token:

```sh
bao policy write team-app - <<'POLICY'
path "secret/data/inventory/*" {
  capabilities = ["read"]
}
path "secret/data/billing/db" {
  capabilities = ["read"]
}
POLICY
bao token capabilities "$TOKEN" secret/data/billing/db
```

This time the answer is `read`. The same token, created before the change, got the new right at once. The reverse is just as true: removing a rule takes the right away from every existing token on the next request. A policy change is a deployment to every token with that name.

## A deleted policy gives nothing

A token can carry the name of a policy that does not exist. OpenBao does not refuse the token and does not warn. It simply finds no rules for that name. Delete the policy and ask again:

```sh
bao policy delete team-app
bao token lookup "$TOKEN"
bao token capabilities "$TOKEN" secret/data/inventory/db
```

The lookup still lists `team-app` in the field `policies`. The capabilities answer is `deny` on the inventory secret, and the answer on `secret/data/billing/db` is `deny` too. If you create the policy again with the same name, the token works again. This makes policy deletion safe in one sense, because nothing is granted by accident, and confusing in another, because a token looks fine and fails every request.

## Policies from more than one place

The token lookup shows several fields that look alike. The field `policies` is the full list that applies. The field `token_policies` lists the policies attached directly to the token. The field `identity_policies` lists policies the token gets through its identity entity and the identity groups that entity belongs to. The final set is the union of all of them, so removing a policy from the token alone does not take away a right that a group still grants.

Look at all three on your token:

```sh
bao token lookup -format=json "$TOKEN"
```

In the output find `policies`, `token_policies` and `identity_policies`. For a token created with `bao token create`, there is no entity, so `identity_policies` is empty. A token created by logging in with an auth method that has an entity gets the entity's policies in addition.

## Who may attach which policy

Creating a token with policies is itself a permission. A token that is not root and has no `sudo` on the path can only create child tokens whose policies are a subset of its own. Try it with a limited token:

```sh
bao policy write token-maker - <<'POLICY'
path "auth/token/create" {
  capabilities = ["update"]
}
POLICY
MAKER=$(bao token create -policy=token-maker -ttl=15m -field=token)
BAO_TOKEN=$MAKER bao token create -policy=default -ttl=5m
BAO_TOKEN=$MAKER bao token create -policy=team-app -ttl=5m
```

The first child token is created, because `default` is a policy the parent holds. The second is refused: the parent does not hold `team-app`, so it may not hand it out. This rule stops a token that can create tokens from creating a more powerful token than itself.

You now know that policies are looked up by name on every request, that deleting a policy removes its rights without removing the name from tokens, and that a token's final rights are the union of its own, entity and group policies. The next part returns to the rules themselves and looks at parameter constraints more closely.

## Common pitfalls

> [!WARNING]
> - **Assuming a policy change waits for a new token.** It applies to existing tokens on their next request.
> - **Deleting a policy to "fix" a token.** The token keeps the name and you lose the ability to see why it fails. Remove the name from the token's source instead, or write the policy again.
> - **Forgetting identity policies.** A right can come from an entity or a group. Check `identity_policies` in the token lookup before you search the token's own list.
> - **Giving `auth/token/create` to a limited token without thinking.** It can create children with any subset of its own policies and the default one.
