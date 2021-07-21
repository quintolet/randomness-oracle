# Verifiable Randomness on the Internet Computer

The [Internet Computer] offers unpredictable and tamper-proof secure randomness.
But how do one prove that the randomness used in some computation actually comes from the system?

The solution is to use a **Randomness Oracle**:
- It supplies the same system secure randomness to the caller, and at the same time also keeps a record of them.
- People can later lookup these record and check if the claimed randomness actually came from the oracle.
- If the oracle canister is public and trustworthy, then we can convince ourselves that there was indeed no foul play.

## Usage

Version 0 of the randomness oracle has been deployed to [ptodj-lqaaa-aaaah-qaeaq-cai], with the following [Candid] interface:

```
type Record = 
 record {
   "blob": blob;
   time: int;
 };
service : {
  blob: () -> (nat, Record);
  lookup: (nat) -> (opt Record) query;
}
```

It also offers a [web interface](https://ptodj-lqaaa-aaaah-qaeaq-cai.raw.ic0.app) where the recent requests of randomness can be reviewed.
A numeric index can be append to the URL to highlight a specific request.

## Verification

The program is compiled with [Motoko compiler 0.6.4 (source 67yal6bh-5a7b5brp-b6xhbdww-3sbniiwz)](https://github.com/dfinity/motoko/releases/tag/0.6.4).
```
$ git clone -b dfx-0.7.2 https://github.com/dfinity/motoko-base 
$ moc --package base ./motoko-base/src src/oracle.mo -o oracle.wasm
$ sha256sum oracle.wasm

6bec5358708c44d0d7d932c85e1c394ee6b74012ea086cb835bc4ffe21ba1c3e  oracle.wasm
```

We can check its controller and program hash from the [Candid UI](https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=e3mmv-5qaaa-aaaah-aadma-cai).
Just enter the oracle's canister id *ptodj-lqaaa-aaaah-qaeaq-cai* in the *canister_id* input box.
The output will be something like below:
```
(record {status=variant {running}; memory_size=461781; cycles=6070821583178;
settings=record {freezing_threshold=2592000; controllers=vec {principal 
"e3mmv-5qaaa-aaaah-aadma-cai"}; memory_allocation=0; compute_allocation=0}; 
module_hash=opt vec {107; 236; 83; 88; 112; 140; 68; 208; 215; 217; 50; 200; 
94; 28; 57; 78; 230; 183; 64; 18; 234; 8; 108; 184; 53; 188; 79; 254; 33; 
186; 28; 62}})
```

The `module_hash` part needs some decoding, but it is the same as the sha256 of the compiled Wasm binary:
```
$ printf %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x \
  107 236 83 88 112 140 68 208 215 217 50 200 94 28 57 78 230 183 64 18 \
  234 8 108 184 53 188 79 254 33 186 28 62

6bec5358708c44d0d7d932c85e1c394ee6b74012ea086cb835bc4ffe21ba1c3e
```

Thanks to the [blackhole] canister, the randomness oracle canister is **immutable** when its only controller is the blackhole.
It can only do as prescribed by [its source code](https://github.com/quintolet/randomness-oracle/blob/main/src/oracle.mo):
*to provide publicly verifiable system randomness*.

## Version History

- Version 0 keeps the most recent 100 requested randomness for the public to check.
  It does not charge the caller, so please feel free to donate some cycles to canister *ptodj-lqaaa-aaaah-qaeaq-cai* if you like this service.

[blackhole]: https://github.com/ninegua/ic-blackhole
[Candid]: https://github.com/dfinity/candid
[ptodj-lqaaa-aaaah-qaeaq-cai]: https://ic.rocks/principal/ptodj-lqaaa-aaaah-qaeaq-cai
[Internet Computer]: https://internetcomputer.org
