import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Random "mo:base/Random";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor {
  public type RecordMut = {
    var blob: Blob;
    var time: Time.Time;
  };
  
  public type Record = {
    blob: Blob;
    time: Time.Time;
  };
  
  // Number of records to keep in memory
  let MAX = 100;

  // Past records are stored in a circular buffer.
  stable var records : [RecordMut] = Array.tabulate<RecordMut>(MAX, func(_:Nat) : RecordMut {{ var blob = Blob.fromArray([]); var time = 0 : Time.Time }});
  
  // Next record index.
  stable var next = 0 : Nat;

  func get(i : Nat) : Record {
    let record = records[i % MAX];
    { blob = record.blob; time = record.time }
  };

  func set(index : Nat, record : Record) {
    let i = index % MAX;
    records[i].blob := record.blob;
    records[i].time := record.time;
  };

  /// Similar to Random.blob(), but also return an index number and a timestamp.
  public func blob() : async (Nat, Record) {
     let blob = await Random.blob(); 
     if (next == 0 or not Blob.equal(get(next - 1).blob, blob)) {
        set(next, { blob = blob; time = Time.now() });
        next := next + 1;
     };
     (next - 1, get(next - 1))
  };

  /// Lookup past record of the given index. Return null if the record was not found.
  public query func lookup(index : Nat) : async ?Record {
    if (index < next and index + MAX >= next) {
      ?get(index)
    } else {
      null
    }
  };

  func append(buf: Buffer.Buffer<Nat8>, text: Text) {
    for (c in Text.toIter(text)) {
      buf.add(Nat8.fromNat(Nat32.toNat(Char.toNat32(c))));
    }
  };

  func appendNat8s(buf: Buffer.Buffer<Nat8>, n : Nat, v : Nat8) {
     var i = 0;
     while (i < n) {
       buf.add(v);
       i := i + 1;
     }
  };

  func appendBlob(buf: Buffer.Buffer<Nat8>, blob: Blob) {
    func toHex(c : Nat8) : Nat8 {
      if (c < 10) { c + 48 } else { c + 87 }
    };
    for (c in Iter.fromArray(Blob.toArray(blob))) {
      buf.add(toHex(Nat8.div(c, 16)));
      buf.add(toHex(Nat8.rem(c, 16)))
    }
  };

  // Parse URL for a numeric index.
  func parseIndex(url : Text) : ?Nat {
    var n = 0;
    var parsed = false;
    for (c in Text.toIter(url)) {
      let i = Nat32.toNat(Char.toNat32(c));
      if (i >= 48 and i <= 58) {
        parsed := true;
        n := n * 10;
        n := n + i - 48;
        if (n > next) { return null };
      }
    };
    if (parsed) { ?n } else { null }
  };

  public query func http_request(request: { url: Text; method: Text; body: [Nat8]; headers: [(Text, Text)] }) : async { body: [Nat8]; headers: [(Text, Text)]; status_code: Nat16 } {
    let index = parseIndex(request.url);
    let buf = Buffer.Buffer<Nat8>(15000);
    append(buf, "<html><title>Randomness Oracle on the Internet Computer</title><body><h1>Randomness Oracle (version 0)</h1>");
    append(buf, "<h2>Past ");
    append(buf, Nat.toText(MAX));
    append(buf, " Requests</h2><div><pre>");
    var i = next;
    let n = Text.size(Nat.toText(i));
    appendNat8s(buf, n + 2, 32);
    append(buf, "32-byte randomness                                                timestamp (ns)</pre><pre>");
    appendNat8s(buf, n + 2, 32);
    append(buf, "-------------------------------------------------------------------------------------</pre>");
    while (i > 0 and i + MAX > next) {
      i := i - 1;
      let j = Nat.toText(i);
      let m = Text.size(j);
      let record = get(i);
      append(buf, "<pre id='");
      append(buf, j);
      if (?i == index) { append(buf, "' style='background-color: #ff0") };
      append(buf, "'>");
      if (n > m) { appendNat8s(buf, n - m, 32) };
      append(buf, j);
      append(buf, ". ");
      appendBlob(buf, record.blob);
      append(buf, ", ");
      append(buf, Int.toText(record.time));
      append(buf, "</pre>");
    };
    append(buf,  "</div></body></html>");
    { body = buf.toArray(); headers = []; status_code = 200; }  
  }
}
