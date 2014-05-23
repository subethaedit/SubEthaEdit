(* Fibonacci Number formula from Wikipedia's F# article *)
let rec fib n =
    match n with
    | 0 | 1 -> n
    | _ -> fib (n - 1) + fib (n - 2)
 
(* An alternative approach - a lazy recursive sequence of Fibonacci numbers *)
let rec fibs = Seq.cache <| seq { yield! [1; 1]                                  
                                  for x, y in Seq.zip fibs <| Seq.skip 1 fibs -> x + y }
 
(* Another approach - a lazy infinite sequence of Fibonacci numbers *)
let fibSeq = Seq.unfold (fun (a,b) -> Some(a+b, (b, a+b))) (1,1)
 
(* Print even fibs *)
[1 .. 10]
|> List.map     fib
|> List.filter  (fun n -> (n % 2) = 0)
|> printlist
 
(* Same thing, using sequence expressions *)
[ for i in 1..10 do
    let r = fib i
    if r % 2 = 0 then yield r ]
|> printlist
