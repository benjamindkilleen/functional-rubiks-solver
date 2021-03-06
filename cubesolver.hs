import Test

import Cube
import WhiteCross
import Control.Monad.State
import System.Random
import System.IO

{- randomize cube -}

type RandState a = State StdGen a

randR :: Random a => (a, a) -> RandState a
randR (low, high) = do
  gen <- get
  let (x, gen') = randomR (low, high) gen
  put gen'
  return x

rotRandFace :: Cube -> RandState Cube
rotRandFace cube = do
  i <- randR (0,1)
  j <- randR (0,5)
  let dir  = [CW, CCW] !! i
      face = [U, L, F, R, B, D] !! j
  return $ rotate dir face cube

rotRandFaceNTimes :: Int -> Cube -> RandState Cube
rotRandFaceNTimes 0 cube = return cube
rotRandFaceNTimes n cube = do
  newCube <- rotRandFace cube
  shuffledCube <- rotRandFaceNTimes (n-1) newCube
  return shuffledCube

newCube :: StdGen -> Cube
newCube gen = evalState (rotRandFaceNTimes 1000 solvedCube) gen

{- user input for a cube -}

faceToName :: Face -> String
faceToName U = "up"
faceToName L = "left"
faceToName F = "front"
faceToName R = "right"
faceToName B = "back"
faceToName D = "down"

colorToFace :: String -> IO Face
colorToFace "w" = return U
colorToFace "g" = return L
colorToFace "r" = return F
colorToFace "b" = return R
colorToFace "o" = return B
colorToFace "y" = return D
colorToFace _ = do
  putStrLn "Enter one of the following:"
  putStrLn "\"w\" (white)"
  putStrLn "\"g\" (green)"
  putStrLn "\"r\" (red)"
  putStrLn "\"b\" (blue)"
  putStrLn "\"o\" (orange)"
  putStrLn "\"y\" (yellow)"
  color <- getLine
  colorToFace color

askAboutColor :: Face -> IO Face
askAboutColor a = do
  putStrLn $ "What is the color on the " ++ faceToName a ++ " tile? (w/g/r/b/o/y)"
  color <- getLine
  colorToFace color

askAboutBlockP :: BlockP -> IO BlockT
askAboutBlockP (Corner a b c) = do
  putStrLn $ "Examine the corner block on the " ++
    faceToName a ++ ", " ++ faceToName b ++ ", and " ++ faceToName c ++ " faces."
  x <- askAboutColor a
  y <- askAboutColor b
  z <- askAboutColor c
  return $ Corner (Tile a x) (Tile b y) (Tile c z)
askAboutBlockP (Edge a b) = do
  putStrLn $ "Examine the edge block on the " ++
    faceToName a ++ " and " ++ faceToName b ++ " faces."
  x <- askAboutColor a
  y <- askAboutColor b
  return $ Edge (Tile a x) (Tile b y)

askAboutCube :: IO Cube
askAboutCube = do
  putStrLn "Orient your cube with the red face forward and white face up."
  putStrLn "Keep it in this orientation at all times."
  b1  <- askAboutBlockP $ Corner F U L
  b2  <- askAboutBlockP $ Edge   F U
  b3  <- askAboutBlockP $ Corner F U R
  b4  <- askAboutBlockP $ Edge   F R
  b5  <- askAboutBlockP $ Corner F D R
  b6  <- askAboutBlockP $ Edge   F D
  b7  <- askAboutBlockP $ Corner F D L
  b8  <- askAboutBlockP $ Edge   F L
  b9  <- askAboutBlockP $ Edge   L U
  b10 <- askAboutBlockP $ Edge   R U
  b11 <- askAboutBlockP $ Edge   R D
  b12 <- askAboutBlockP $ Edge   L D
  b13 <- askAboutBlockP $ Corner B U L
  b14 <- askAboutBlockP $ Edge   B U
  b15 <- askAboutBlockP $ Corner B U R
  b16 <- askAboutBlockP $ Edge   B R
  b17 <- askAboutBlockP $ Corner B D R
  b18 <- askAboutBlockP $ Edge   B D
  b19 <- askAboutBlockP $ Corner B D L
  b20 <- askAboutBlockP $ Edge   B L
  return $ Cube [b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,
                 b11,b12,b13,b14,b15,b16,b17,b18,b19,b20]

solveSpecificCube :: IO ()
solveSpecificCube = do
  cube <- askAboutCube
  putStrLn "Double check your cube:"
  print cube
  let check = do
        putStrLn "Are all the tiles correct? (y/n)"
        input <- getLine
        case input of
          "y" -> solveCube cube
          "n" -> solveSpecificCube
          _   -> putStrLn "\"y\" (yes) OR \"n\" (no)" >> check
  check

{- UI -}

solveCube :: Cube -> IO ()
solveCube cube = do
  putStrLn "Press enter to get solution"
  getLine
  putStrLn "Do these steps in order, keeping red facing forward and white up:"
  print $ runSteps solve cube
  putStrLn "And we have..."
  print $ runCube solve cube

solveRandomCube :: IO ()
solveRandomCube = do
  gen <- newStdGen
  let cube = newCube gen
  putStrLn $ "Generating random cube:"
  print cube
  solveCube cube

main :: IO ()
main = do
  putStrLn "Solve random cube? (y/n)"
  input <- getLine
  case input of
    "y" -> solveRandomCube
    _   -> solveSpecificCube
  main