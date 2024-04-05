{-# LANGUAGE CApiFFI #-}

module MyLib where

foreign import capi "bubbletea-capi.h Add" c_add :: Int -> Int -> Int

someFunc :: IO ()
someFunc = putStrLn "someFunc"
