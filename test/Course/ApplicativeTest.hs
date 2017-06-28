{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Course.ApplicativeTest where

import           Test.Tasty            (TestTree, testGroup)
import           Test.Tasty.HUnit      (testCase, (@?=))
import           Test.Tasty.QuickCheck (testProperty)

import           Course.Applicative    (lift2, lift3, lift4, pure, replicateA,
                                        sequence, (*>), (<$>), (<*), (<*>))
import           Course.Core
import           Course.Id             (Id (..))
import           Course.List           (List (..), filter, length, listh,
                                        product, sum)
import           Course.Optional       (Optional (..))

test_Applicative :: TestTree
test_Applicative =
  testGroup "Applicative" [
    haveFmapTest
  , idTest
  , listTest
  , optionalTest
  , functionTest
  , lift2Test
  , rightApplyTest
  , leftApplyTest
  ]

haveFmapTest :: TestTree
haveFmapTest =
  testGroup "<$>" [
    testCase "fmap Id" $
      (+ 1) <$> (Id 2) @?= Id (3 :: Integer)
  , testCase "fmap empty List" $
      (+ 1) <$> Nil @?= Nil
  , testCase "fmap List" $
      (+ 1) <$> listh [1,2,3] @?= listh [2,3,4]
  ]

idTest :: TestTree
idTest =
  testGroup "Id instance" [
    testProperty "pure == Id" $
      \(x :: Integer) -> pure x == Id x
  , testCase "Applying within Id" $
      Id (+ 10) <*> Id 8 @?= Id 18
  ]

listTest :: TestTree
listTest =
  testGroup "List instance" [
    testProperty "pure" $
      \x -> pure x == (x :. Nil :: List Integer)
  , testCase "<*>" $
      (+1) :. (*2) :. Nil <*> listh [1,2,3] @?= listh [2,3,4,2,4,6]
  ]

optionalTest :: TestTree
optionalTest =
  testGroup "Optional instance" [
    testProperty "pure" $
      \(x :: Integer) -> pure x == Full x
  , testCase "Full <*> Full" $
      Full (+8) <*> Full 7 @?= Full 15
  , testCase "Empty <*> Full" $
      Empty <*> Full "tilt" @?= (Empty :: Optional Integer)
  , testCase "Full <*> Empty" $
      Full (+8) <*> Empty @?= Empty
  ]

functionTest :: TestTree
functionTest =
  testGroup "Function instance" [
    testCase "addition" $
      ((+) <*> (+10)) 3 @?= 16
  , testCase "more addition" $
      ((+) <*> (+5)) 3 @?= 11
  , testCase "even more addition" $
      ((+) <*> (+5)) 1 @?= 7
  , testCase "addition and multiplication" $
      ((*) <*> (+10)) 3 @?= 39
  , testCase "more addition and multiplcation" $
      ((*) <*> (+2)) 3 @?= 15
  , testProperty "pure" $
      \(x :: Integer) (y :: Integer) -> pure x y == x
  ]

lift2Test :: TestTree
lift2Test =
  testGroup "lift2" [
    testCase "+ over Id" $
      lift2 (+) (Id 7) (Id 8) @?= Id 15
  , testCase "+ over List" $
      lift2 (+) (listh [1,2,3]) (listh [4,5]) @?= listh [5,6,6,7,7,8]
  , testCase "+ over Optional - all full" $
      lift2 (+) (Full 7) (Full 8) @?= Full 15
  , testCase "+ over Optional - first Empty" $
      lift2 (+) Empty (Full 8) @?= Empty
  , testCase "+ over Optional - second Empty" $
      lift2 (+) (Full 7) Empty @?= Empty
  , testCase "+ over functions" $
      lift2 (+) length sum (listh [4,5,6]) @?= 18
  ]

lift3Test :: TestTree
lift3Test =
  testGroup "lift3" [
    testCase "+ over Id" $
      lift3 (\a b c -> a + b + c) (Id 7) (Id 8) (Id 9) @?= Id 24
  , testCase "+ over List" $
      lift3 (\a b c -> a + b + c) (listh [1,2,3]) (listh [4,5]) (listh [6,7,8]) @?=
        listh [11,12,13,12,13,14,12,13,14,13,14,15,13,14,15,14,15,16]
  , testCase "+ over Optional" $
      lift3 (\a b c -> a + b + c) (Full 7) (Full 8) (Full 9) @?= Full 24
  , testCase "+ over Optional - third Empty" $
      lift3 (\a b c -> a + b + c) (Full 7) (Full 8) Empty @?= Empty
  , testCase "+ over Optional - first Empty" $
      lift3 (\a b c -> a + b + c) Empty (Full 8) (Full 9) @?= Empty
  , testCase "+ over Optional - first and second Empty" $
      lift3 (\a b c -> a + b + c) Empty Empty (Full 9) @?= Empty
  , testCase "+ over functions" $
      lift3 (\a b c -> a + b + c) length sum product (listh [4,5,6]) @?= 138
  ]

lift4Test :: TestTree
lift4Test =
  testGroup "lift4" [
    testCase "+ over Id" $
      lift4 (\a b c d -> a + b + c + d) (Id 7) (Id 8) (Id 9) (Id 10) @?= Id 34
  , testCase "+ over List" $
      lift4 (\a b c d -> a + b + c + d) (listh [1, 2, 3]) (listh [4, 5]) (listh [6, 7, 8]) (listh [9, 10]) @?=
        (listh [20,21,21,22,22,23,21,22,22,23,23,24,21,22,22,23,23,24,22,23,23,24,24,25,22,23,23,24,24,25,23,24,24,25,25,26])
  , testCase "+ over Optional" $
      lift4 (\a b c d -> a + b + c + d) (Full 7) (Full 8) (Full 9) (Full 10) @?= Full 34
  , testCase "+ over Optional - third Empty" $
      lift4 (\a b c d -> a + b + c + d) (Full 7) (Full 8) Empty  (Full 10) @?= Empty
  , testCase "+ over Optional - first Empty" $
      lift4 (\a b c d -> a + b + c + d) Empty (Full 8) (Full 9) (Full 10) @?= Empty
  , testCase "+ over Optional - first and second Empty" $
      lift4 (\a b c d -> a + b + c + d) Empty Empty (Full 9) (Full 10) @?= Empty
  , testCase "+ over functions" $
      lift4 (\a b c d -> a + b + c + d) length sum product (sum . filter even) (listh [4,5,6]) @?= 148
  ]

rightApplyTest :: TestTree
rightApplyTest =
  testGroup "rightApply" [
    testCase "*> over List" $
      listh [1,  2,  3] *> listh [4,  5,  6] @?= listh [4,5,6,4,5,6,4,5,6]
  , testCase "*> over List" $
      listh [1,  2] *> listh [4,  5,  6] @?= listh [4,5,6,4,5,6]
  , testCase "another *> over List" $
      listh [1,  2,  3] *> listh [4,  5] @?= listh [4,5,4,5,4,5]
  , testCase "*> over Optional" $
      Full 7 *> Full 8 @?= Full 8
  , testProperty "*> over List property" $
      \a b c x y z ->
        let l1 = (listh [a,  b,  c] :: List Integer)
            l2 = (listh [x,  y,  z] :: List Integer)
         in l1 *> l2 == listh [x,  y,  z,  x,  y,  z,  x,  y,  z]
  , testProperty "*> over Optional property" $
      \x y -> (Full x :: Optional Integer) *> (Full y :: Optional Integer) == Full y
  ]

leftApplyTest :: TestTree
leftApplyTest =
  testGroup "leftApply" [
    testCase "<* over List" $
      (1 :. 2 :. 3 :. Nil) <* (4 :. 5 :. 6 :. Nil) @?= listh [1,1,1,2,2,2,3,3,3]
  , testCase "another <* over List" $
      (1 :. 2 :. Nil) <* (4 :. 5 :. 6 :. Nil) @?= listh [1,1,1,2,2,2]
  , testCase "Yet another <* over List" $
      (1 :. 2 :. 3 :. Nil) <* (4 :. 5 :. Nil) @?= listh [1,1,2,2,3,3]
  , testCase "<* over Optional" $
      Full 7 <* Full 8 @?= Full 7
  , testProperty "<* over List property" $
      \x y z a b c ->
        let l1 = (x :. y :. z :. Nil) :: List Integer
            l2 = (a :. b :. c :. Nil) :: List Integer
         in l1 <* l2 == listh [x,  x,  x,  y,  y,  y,  z,  z,  z]
  , testProperty "<* over Optional property" $
      \x y -> Full (x :: Integer) <* Full (y :: Integer) == Full x
  ]

sequenceTest :: TestTree
sequenceTest =
  testGroup "sequence" [
    testCase "Id" $
      sequence (listh [Id 7, Id 8, Id 9]) @?= Id (listh [7,8,9])
  , testCase "List" $
      sequence ((1 :. 2 :. 3 :. Nil) :. (1 :. 2 :. Nil) :. Nil) @?= (listh <$> (listh [[1,1],[1,2],[2,1],[2,2],[3,1],[3,2]]))
  , testCase "" $
      sequence (Full 7 :. Empty :. Nil) @?= Empty
  , testCase "" $
      sequence (Full 7 :. Full 8 :. Nil) @?= Full (listh [7,8])
  , testCase "" $
      sequence ((*10) :. (+2) :. Nil) 6 @?= (listh [60,8])
  ]

replicateATest :: TestTree
replicateATest =
  testGroup "replicateA" [
    testCase "" $
      replicateA 4 (Id "hi") @?= Id (listh ["hi","hi","hi","hi"])
  , testCase "" $
      replicateA 4 (Full "hi") @?= Full (listh ["hi","hi","hi","hi"])
  , testCase "" $
      replicateA 4 Empty @?= (Empty :: Optional (List Integer))
  , testCase "" $
      replicateA 4 (*2) 5 @?= (listh [10,10,10,10])
  , testCase "" $
      let expected = listh <$> (listh ["aaa","aab","aac","aba","abb","abc","aca","acb","acc",
                                        "baa","bab","bac","bba","bbb","bbc","bca","bcb","bcc",
                                        "caa","cab","cac","cba","cbb","cbc","cca","ccb","ccc"])
       in replicateA 3 ('a' :. 'b' :. 'c' :. Nil) @?= expected
  ]
