# Lazy linked list implementation #

## Overview

The package implements lazy linked list that can be found in functional languages like _Scheme_ or _Haskell_.
To tell a linked list from a WL `List`, the former may be named listcons.
This document refers listconses as just lists unless confusing.

A list is either `Nil` or consists of a head and a tail: `head : tail`.
*Hereafter a colon `:` actually means `\[Colon]` (`∶`, entered as `ESC : ESC`), not `\[RawColon]` on a keyboard.*

A listcons can be converted to a List and vice versa by `ToList` and `ListCons`.

In a proper list a tail (if any) is a proper list in its turn.
A list doesn’t need to be proper; actually, to test this, one must evaluate a tail, which breaks laziness
(it can be done via `ProperListConsQ`).
Thus, a finite proper list has form `a1 : (a2 : ... : (aN : Nil)...)` when evaluated.
Prentheses may be omitted as `:` is made right-associative: `a1 : a2 : ... : aN : Nil`.

Head and tail are extracted by `First[list]` and `Rest[list]` in consistency with WL structures.
`Length`, `Append(To)`, and `Prepend(To)` work as with WL `List`s; so does `Take` and `Drop` in their simpliest form with an integer.

`Map`, `Fold`, and `FoldRight` works as usual in their simpliest form.

Tests include `ListConsQ` and `ProperListConsQ`, the latter breaking laziness.

A tail of a lazy list can be (recursively) evalueted by `UnLazy`.

Due to the laziness, lists may be infinite like is the predefined `IntegerStream[n]` and `$IntegerStream ≡ IntegerStream[1]`.
Some operations cause infinite recurtion on infinite lists (`ProperListConsQ`, `UnLazy`, `ToList`, `Take` with a positive, `Drop`, `Append`).

__N. B.:__ Do not use not yet overloaded functions like ~~`Last`, `Most`, `Apply`, `MapIndexed`, etc.~~ on linked lists!
They may give unexpected results without a message.


## Examples

Here are some examples. Each comment represents a result as is and the one passed through `UnLazy` (if applicable and differs).
`⟂` means an infinite recursion.

```mma
ints = $IntegerStream
  (* ⟶ 1 : IntegerStream[1 + 1]
     ⟶ ⟂ *)

ListConsQ[ints]
  (* ⟶ True *)

ProperListConsQ[ints]
  (* ⟶ ⟂ *)

Take[ints, 5]
  (* ⟶ 1 : Take[IntegerStream[1 + 1], 5 - 1]
     ⟶ 1 : 2 : 3 : 4 : 5 : Nil *)

Drop[%, 2]
  (* ⟶ 3 : Take[IntegerStream[3 + 1], 3 - 1]
     ⟶ 3 : 4 : 5 : Nil *)

#^2 & /@ %
  (* ⟶ 9 : (#^2 &) /@ Take[IntegerStream[3 + 1], 3 - 1]
     ⟶ 9 : 16 : 25 : Nil *)

% // ToList
  (* ⟶ {9, 16, 25} *)
```
