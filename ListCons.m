(* ::Package:: *)

(* ::Section:: *)
(*Begin*)


BeginPackage["ListCons`"];


`Private`formatUsage[`Private`str_] := StringReplace[`Private`str,
  "`" ~~ Shortest[`Private`s__] ~~ "`" :>
    "\!\(\*StyleBox[\(" <> StringReplace[`Private`s, {
       RegularExpression["(?!</)_"] ~~
       Shortest[`Private`i__] ~~
       RegularExpression["(?!</)_"] :>
         "\*StyleBox[\(" <> `Private`i <> "\), \"TI\"]",
       "/_" -> "_"
  }] <> "\),\"MR\",ShowStringCharacters->True]\)"];


ListCons::usage = "`ListCons[{_x1_, _x2_, _..._}]` creates a listcons from a WL `List`." //`Private`formatUsage;
ListConsQ::usage = "`ListConsQ[_expr_]` tests if `_expr_` is a listcons, i.e. either `Nil` or `_Colon`.
Note that it returns `True` for improper lists due to laziness. \
See `ProperListConsQ`." //`Private`formatUsage;
ProperListConsQ::usage = "`ProperListConsQ[_expr_]` tests if `_expr_` is a proper listcons, \
i.e. either `Nil` or `(/_ \[Colon] /_?ProperListConsQ)`.
Note: it evaluates all tails, breaking laziness." //`Private`formatUsage;
Nil::usage = "`Nil` is the empty listcons." //`Private`formatUsage;
Colon::usage = "`_x_ \[Colon] _xs_` is an nonempty listcons.\n" //`Private`formatUsage //# <> Colon::usage &;
ToList::usage = "`ToList[_listcons_]` creates WL List from `_listcons_`." //`Private`formatUsage;
UnLazy::usage = "`UnLazy[_listcons_]` evaluates all lazy tails in `_listcons_`." //`Private`formatUsage;
FoldRight::usage = "`FoldRight[_f_, _[init]_, _listcons_] folds `_listcons_` like `Fold` from the right." //`Private`formatUsage;
IntegerStream::usage = "`IntegerStream[_from_]` is a stream (infinite listcons) \
of consecutive integers starting from `_from_`." //`Private`formatUsage;
$IntegerStream::usage = "`$IntegerStream` is `IntegerStream[1]`." //`Private`formatUsage;


Begin["`Private`"];


(* ::Section:: *)
(*Code*)


(* ::Subsection:: *)
(*Messages*)


General::listcons = "A listsons expected at position `2`\[NoBreak] in \[NoBreak]`1`\[NoBreak].";


(* ::Subsection:: *)
(*Rest (tail) is lazy*)


SetAttributes[Colon, HoldRest];


(* ::Subsection:: *)
(*Make Colon right-associative*)


x__ \[Colon] y_ \[Colon] zs_ := x \[Colon] (y \[Colon] zs);


(* ::Subsection:: *)
(*Constructor from List*)


ListCons[{}] = Nil;
ListCons[{x_, xs___}] := x \[Colon] xs \[Colon] Nil;
ListCons[args___] /; Message[ListCons::argx, ListCons, Length[{args}]] = $Failed;
ListCons[nonlist_] /; Message[ListCons::list, ListCons, 1] = $Failed;


(* ::Subsection:: *)
(*Tests*)


ListConsQ[Nil] = ListConsQ[_Colon] = True;
ListConsQ[_] = False;
ListConsQ[args___] /; Message[ListConsQ::argx, ListConsQ, Length[{args}]] = $Failed;


ProperListConsQ[Nil] = True;
ProperListConsQ[_ \[Colon] xs_] := ProperListConsQ[xs];
ProperListConsQ[_] = False;
ProperListConsQ[args___] /; Message[ProperListConsQ::argx, ProperListConsQ, Length[{args}]] = $Failed;


(* ::Subsection:: *)
(*Formatting*)


(* ::Text:: *)
(*Flatten on display*)


Format[x__ \[Colon] (y_ \[Colon] zs_)] := Defer[x \[Colon] y \[Colon] zs];


(* ::Subsection:: *)
(*Taking heads and tails*)


First[x_ \[Colon] _] ^:= x;  (* known as 'head' in lisp *)
Rest[_ \[Colon] xs_] ^:= xs; (* known as 'tail' in lisp *)

Nil::struct = "Taking `1` of Nil";
(f: (First|Rest))[Nil] /;
  Message[Nil::struct, f] ^= $Failed;

Length[Nil] ^= 0;
Length[_ \[Colon] xs_] ^:= 1 + Length[xs];

Prepend[Nil, elem_] ^:= elem \[Colon] Nil;
Prepend[xs_Colon, elem_] ^:= elem \[Colon] xs;

Append[Nil, elem_] ^:= elem \[Colon] Nil;
Append[x_ \[Colon] xs_, elem_] ^:= x \[Colon] Append[xs, elem];


Colon /: Take[x_ \[Colon] xs_, n_Integer /; n>0] := x \[Colon] Take[xs, n-1];
Colon /: Take[_ \[Colon] _, 0] = Nil;
Colon /: Take[l_Colon, n_Integer /; n<0] := With[{ul = UnLazy[l]}, Drop[ul, Length[ul] + n]];
Nil   /: Take[Nil, n_] = Nil;



Colon /: Drop[   x_ \[Colon] xs_, n_Integer /; n>0] := Drop[xs, n-1];
Colon /: Drop[l_Colon, 0] = l;
Colon /: Drop[l_Colon, n_Integer /; n<0] := With[{ul = UnLazy[l]}, Take[ul, Length[ul] + n]];
Nil   /: Drop[Nil, n_] = Nil;


(* ::Subsubsection:: *)
(*Make List*)


ToList[Nil] := {};
ToList[x_ \[Colon] xs_] := With[{ tail = ToList[xs] },
  Prepend[tail, x] /; Head[tail] === List];

ToList[args___] /; Message[ToList::argx, ToList, Length@{args}] = $Failed;
ToList[_] /; Message[ToList::listcons, ToList, 1] = $Failed;


(* ::Subsection:: *)
(*Evaluate all tails*)


UnLazy[Nil] ^= Nil;
UnLazy[x_ \[Colon] xs_] ^:= With[{ xse = UnLazy[xs] }, x \[Colon] xse];
UnLazy[args___] /; Message[UnLazy::argx, UnLazy, Length@{args}] = $Failed;
UnLazy[_] /; Message[UnLazy::listcons, UnLazy, 1] = $Failed;


(* ::Subsection:: *)
(*Map / Fold*)


Colon /: Map[fn_, x_ \[Colon] xs_] := fn[x] \[Colon] Map[fn, xs];
Nil   /: Map[_, Nil] = Nil;

(* Operator form *)
If[ $VersionNumber >= 10,
  Colon /: Map[fn_][x_ \[Colon] xs_] := Map[fn, x \[Colon] xs];
  Nil /: Map[fn_][Nil] = Nil;
]


Colon /: Fold[fn_, z_, x_ \[Colon] xs_] := Fold[fn, fn[z, x], xs];
Nil   /: Fold[  _, z_, Nil] := z;
Colon /: Fold[fn_, x_ \[Colon] xs_] := Fold[fn, x, xs];
Nil   /: e: Fold[_, Nil] /;
  Message[Nil::args, HoldForm[e]] = $Failed;
Colon /: FoldRight[fn_, z_, x_ \[Colon] xs_] := fn[x, Fold[fn, z, xs]];
Nil   /: FoldRight[  _, z_, Nil] := z;

(* Operator form - do we need it?
Colon/:HoldPattern@Fold[fn_][x_\[Colon]xs_]:=Fold[fn,x,xs]
Nil/:e:(_Fold|_FoldRight)[fn_][Nil]:=$Failed/;Message[Nil::args,HoldForm@e];
Colon/:FoldRight[fn_][x_\[Colon]xs_]:=FoldRight[fn,x,xs]*)


(* ::Subsubsection:: *)
(*Integer stream*)


IntegerStream[x_] := x \[Colon] IntegerStream[x+1];


$IntegerStream = IntegerStream[1];


(* ::Section:: *)
(*End*)


End[];
EndPackage[];
