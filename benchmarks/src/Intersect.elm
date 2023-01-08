module Intersect exposing (folding, folding_DotDot, recursion_DotDot, recursion_thrice_DotDot, recursion_twice_DotDot, toList, toList_DotDot)

import Dict exposing (Dict)
import DictDotDot as DDD
import List.Extra


toList : Dict comparable v -> Dict comparable v -> Dict comparable v
toList l r =
    let
        go : Dict comparable v -> List ( comparable, v ) -> List comparable -> Dict comparable v
        go acc lleft rleft =
            case lleft of
                [] ->
                    acc

                ( lheadKey, lheadValue ) :: ltail ->
                    case List.Extra.dropWhile (\rk -> rk < lheadKey) rleft of
                        [] ->
                            acc

                        (rheadKey :: rtail) as rNext ->
                            if lheadKey == rheadKey then
                                go (Dict.insert lheadKey lheadValue acc) ltail rtail

                            else
                                go acc (List.Extra.dropWhile (\( lk, _ ) -> lk < rheadKey) ltail) rNext
    in
    go Dict.empty (Dict.toList l) (Dict.keys r)


folding : Dict comparable v -> Dict comparable v -> Dict comparable v
folding l r =
    Dict.foldl
        (\lkey lvalue ( acc, queue ) ->
            case List.Extra.dropWhile (\rkey -> rkey < lkey) queue of
                [] ->
                    ( acc, [] )

                (qhead :: qtail) as newQueue ->
                    if qhead == lkey then
                        ( Dict.insert lkey lvalue acc, qtail )

                    else
                        ( acc, newQueue )
        )
        ( Dict.empty, Dict.keys r )
        l
        |> Tuple.first


toList_DotDot : DDD.Dict comparable v -> DDD.Dict comparable v -> DDD.Dict comparable v
toList_DotDot l r =
    let
        go : DDD.Dict comparable v -> List ( comparable, v ) -> List comparable -> DDD.Dict comparable v
        go acc lleft rleft =
            case lleft of
                [] ->
                    acc

                ( lheadKey, lheadValue ) :: ltail ->
                    case List.Extra.dropWhile (\rk -> rk < lheadKey) rleft of
                        [] ->
                            acc

                        (rheadKey :: rtail) as rNext ->
                            if lheadKey == rheadKey then
                                go (DDD.insert lheadKey lheadValue acc) ltail rtail

                            else
                                go acc (List.Extra.dropWhile (\( lk, _ ) -> lk < rheadKey) ltail) rNext
    in
    go DDD.empty (DDD.toList l) (DDD.keys r)


folding_DotDot : DDD.Dict comparable v -> DDD.Dict comparable v -> DDD.Dict comparable v
folding_DotDot l r =
    DDD.foldl
        (\lkey lvalue ( acc, queue ) ->
            case List.Extra.dropWhile (\rkey -> rkey < lkey) queue of
                [] ->
                    ( acc, [] )

                (qhead :: qtail) as newQueue ->
                    if qhead == lkey then
                        ( DDD.insert lkey lvalue acc, qtail )

                    else
                        ( acc, newQueue )
        )
        ( DDD.empty, DDD.keys r )
        l
        |> Tuple.first


recursion_DotDot : DDD.Dict comparable v -> DDD.Dict comparable v -> DDD.Dict comparable v
recursion_DotDot l r =
    let
        rkeys : List comparable
        rkeys =
            DDD.keys r

        go : ( DDD.Dict comparable v, List comparable ) -> DDD.Dict comparable v -> ( DDD.Dict comparable v, List comparable )
        go (( dacc, rleft ) as acc) lnode =
            case lnode of
                DDD.RBEmpty_elm_builtin ->
                    acc

                DDD.RBBlackMissing_elm_builtin c ->
                    go acc c

                DDD.RBNode_elm_builtin _ lkey lvalue childLT childGT ->
                    case rleft of
                        [] ->
                            acc

                        rhead :: rtail ->
                            if rhead > lkey then
                                -- We can skip the left tree and this node
                                go acc childGT

                            else if rhead == lkey then
                                -- We can skip the left tree, and insert this node
                                go ( DDD.insert lkey lvalue dacc, rtail ) childGT

                            else
                                let
                                    (( daccAL, rleftAL ) as afterLeft) =
                                        go acc childLT
                                in
                                case List.Extra.dropWhile (\rkey -> rkey < lkey) rleftAL of
                                    [] ->
                                        afterLeft

                                    rheadAL :: rtailAL ->
                                        if rheadAL == lkey then
                                            go ( DDD.insert lkey lvalue daccAL, rtailAL ) childGT

                                        else
                                            go afterLeft childGT
    in
    go ( DDD.empty, rkeys ) l
        |> Tuple.first


type QueueNode comparable v
    = KeyValue comparable v
    | Tree (DDD.Dict comparable v)


recursion_twice_DotDot : DDD.Dict comparable v -> DDD.Dict comparable v -> DDD.Dict comparable v
recursion_twice_DotDot l r =
    let
        unpack : List (QueueNode comparable v) -> Maybe ( comparable, v, List (QueueNode comparable v) )
        unpack queue =
            case queue of
                [] ->
                    Nothing

                h :: t ->
                    case h of
                        KeyValue k v ->
                            Just ( k, v, t )

                        Tree DDD.RBEmpty_elm_builtin ->
                            unpack t

                        Tree (DDD.RBNode_elm_builtin _ key value childLT childGT) ->
                            unpack (Tree childLT :: KeyValue key value :: Tree childGT :: t)

                        Tree (DDD.RBBlackMissing_elm_builtin c) ->
                            -- This doesn't happen in practice, performance is irrelevant
                            unpack (Tree c :: t)

        unpackWhileDroppingLT : comparable -> List (QueueNode comparable v) -> Maybe ( comparable, List (QueueNode comparable v) )
        unpackWhileDroppingLT compareKey queue =
            case queue of
                [] ->
                    Nothing

                h :: t ->
                    case h of
                        KeyValue v _ ->
                            if v < compareKey then
                                unpackWhileDroppingLT compareKey t

                            else
                                Just ( v, t )

                        Tree DDD.RBEmpty_elm_builtin ->
                            unpackWhileDroppingLT compareKey t

                        Tree (DDD.RBNode_elm_builtin _ key value childLT childGT) ->
                            if key < compareKey then
                                unpackWhileDroppingLT compareKey (Tree childGT :: t)

                            else if key == compareKey then
                                unpackWhileDroppingLT compareKey (KeyValue key value :: Tree childGT :: t)

                            else
                                unpackWhileDroppingLT compareKey (Tree childLT :: KeyValue key value :: Tree childGT :: t)

                        Tree (DDD.RBBlackMissing_elm_builtin c) ->
                            -- This doesn't happen in practice, performance is irrelevant
                            unpackWhileDroppingLT compareKey (Tree c :: t)

        go : ( DDD.Dict comparable v, List (QueueNode comparable v) ) -> DDD.Dict comparable v -> ( DDD.Dict comparable v, List (QueueNode comparable v) )
        go (( dacc, rleft ) as acc) lnode =
            case lnode of
                DDD.RBEmpty_elm_builtin ->
                    acc

                DDD.RBBlackMissing_elm_builtin c ->
                    go acc c

                DDD.RBNode_elm_builtin _ lkey lvalue childLT childGT ->
                    case unpack rleft of
                        Nothing ->
                            acc

                        Just ( rhead, rheadvalue, rtail ) ->
                            if rhead > lkey then
                                -- We can skip the left tree and this node
                                go acc childGT

                            else if rhead == lkey then
                                -- We can skip the left tree, and insert this node
                                go ( DDD.insert lkey lvalue dacc, rtail ) childGT

                            else
                                let
                                    (( daccAL, rleftAL ) as afterLeft) =
                                        go ( dacc, KeyValue rhead rheadvalue :: rtail ) childLT
                                in
                                case unpackWhileDroppingLT lkey rleftAL of
                                    Nothing ->
                                        afterLeft

                                    Just ( rheadAL, rtailAL ) ->
                                        if rheadAL == lkey then
                                            go ( DDD.insert lkey lvalue daccAL, rtailAL ) childGT

                                        else
                                            go afterLeft childGT
    in
    go ( DDD.empty, [ Tree r ] ) l
        |> Tuple.first


type alias State comparable v =
    Maybe ( comparable, v, List (QueueNode comparable v) )


recursion_thrice_DotDot : DDD.Dict comparable v -> DDD.Dict comparable v -> DDD.Dict comparable v
recursion_thrice_DotDot l r =
    let
        unpack : List (QueueNode comparable v) -> State comparable v
        unpack queue =
            case queue of
                [] ->
                    Nothing

                h :: t ->
                    case h of
                        KeyValue k v ->
                            Just ( k, v, t )

                        Tree DDD.RBEmpty_elm_builtin ->
                            unpack t

                        Tree (DDD.RBNode_elm_builtin _ key value childLT childGT) ->
                            unpack (Tree childLT :: KeyValue key value :: Tree childGT :: t)

                        Tree (DDD.RBBlackMissing_elm_builtin c) ->
                            -- This doesn't happen in practice, performance is irrelevant
                            unpack (Tree c :: t)

        unpackWhileDroppingLT : comparable -> List (QueueNode comparable v) -> State comparable v
        unpackWhileDroppingLT compareKey queue =
            case queue of
                [] ->
                    Nothing

                h :: t ->
                    case h of
                        KeyValue k v ->
                            if k < compareKey then
                                unpackWhileDroppingLT compareKey t

                            else
                                Just ( k, v, t )

                        Tree DDD.RBEmpty_elm_builtin ->
                            unpackWhileDroppingLT compareKey t

                        Tree (DDD.RBNode_elm_builtin _ key value childLT childGT) ->
                            if key < compareKey then
                                unpackWhileDroppingLT compareKey (Tree childGT :: t)

                            else if key == compareKey then
                                unpackWhileDroppingLT compareKey (KeyValue key value :: Tree childGT :: t)

                            else
                                unpackWhileDroppingLT compareKey (Tree childLT :: KeyValue key value :: Tree childGT :: t)

                        Tree (DDD.RBBlackMissing_elm_builtin c) ->
                            -- This doesn't happen in practice, performance is irrelevant
                            unpackWhileDroppingLT compareKey (Tree c :: t)

        go : DDD.Dict comparable v -> State comparable v -> State comparable v -> DDD.Dict comparable v
        go dacc lleft rleft =
            case lleft of
                Nothing ->
                    dacc

                Just ( lkey, lvalue, ltail ) ->
                    case rleft of
                        Nothing ->
                            dacc

                        Just ( rkey, _, rtail ) ->
                            if lkey < rkey then
                                go dacc lleft (unpackWhileDroppingLT lkey rtail)

                            else if lkey > rkey then
                                go dacc (unpackWhileDroppingLT rkey ltail) rleft

                            else
                                go (DDD.insert lkey lvalue dacc) (unpack ltail) (unpack rtail)
    in
    go DDD.empty (unpack [ Tree l ]) (unpack [ Tree r ])
