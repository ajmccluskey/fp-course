import Test.Tasty

import Course.FunctorTest
import Course.ApplicativeTest
import Course.ValidationTest

main :: IO ()
main =
  defaultMain $ testGroup "Course" [
    test_Validation
  , test_Functor
  , test_Applicative
  ]
