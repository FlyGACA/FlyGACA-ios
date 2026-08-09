# Corpus signing — Ed25519 for the remote quiz corpus

`ContentRefresher` (ContentKit, Phase 4) refreshes quiz content from
`https://flygaca.com/data/quiz.json` into a cache that `ContentStore` prefers
over the bundled snapshot. Because that channel can replace what every app
studies from, the corpus is only accepted with a valid **detached Ed25519
signature**: `quiz.json.sig`, served from the same directory, base64 over the
exact `quiz.json` bytes. Verification uses CryptoKit
(`Curve25519.Signing.PublicKey.isValidSignature(_:for:)`) — see
`apple/FlyGACAKit/Sources/ContentKit/CorpusSignatureVerifier.swift`.

## Fail closed

Apps **reject unsigned or badly-signed corpora, always**. Any of these throws
`ContentRefreshError.invalidSignature` and leaves the existing cache
untouched (the refresher already degrades safely by keeping it):

- `quiz.json.sig` missing, unreachable, or not a 200
- signature not decodable base64, or simply not valid for the served bytes
- `FGCorpusPublicKey` **absent or malformed** in the app's Info.plist — the
  verifier logs that signing is not configured (`FlyGACA.ContentKit` /
  `CorpusSignatureVerifier` in Console.app) and rejects every refresh

A build without the key therefore never adopts remote content; it keeps
working on the bundled snapshot.

## One-time: generate the keypair

```bash
bash scripts/sign-corpus.sh genkey
```

Writes `secrets/corpus-ed25519-private.pem` (deploy secret — **never commit**;
store it in the deploy secret manager) and prints the base64 raw public key.

## Wire the public key into the apps

The key is shared by all six apps, so set it once in
`apple/Apps/Shared/App-Shared.xcconfig`:

```
INFOPLIST_KEY_FGCorpusPublicKey = <base64 from genkey>
```

That lands in every generated Info.plist as `FGCorpusPublicKey`, which
`CorpusSignatureVerifier(bundle: .main)` reads. Regenerate the project
(`npm run ios:generate`) after editing the xcconfig.

## Publish pipeline

Every publish of `quiz.json` must sign and upload the signature **in the same
deploy**, next to the corpus:

```bash
bash scripts/sign-corpus.sh sign <private-key.pem> public/data/quiz.json
# produces public/data/quiz.json.sig — upload both files together
```

The `sign` step also prints the public key — confirm it matches the
`INFOPLIST_KEY_FGCorpusPublicKey` the apps ship before deploying.

## Rotation

Old builds fail closed on unknown keys, so rotation order matters:

1. Ship an app update carrying the **new** `FGCorpusPublicKey`.
2. Only then start publishing corpora signed with the new private key.

Apps that haven't updated simply keep their bundled/cached snapshot until
they update — no breakage, just no remote refresh.
