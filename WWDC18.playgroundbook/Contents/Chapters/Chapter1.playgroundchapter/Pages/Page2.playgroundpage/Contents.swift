//#-hidden-code
//
//  Contents.swift
//
//  Made by: Henrik Storch
//
//#-end-hidden-code
/*:
 
 Well done.
 Let's get real now:
 My idea for this year: [Tic-Tac-Toe](glossary://Tic-Tac-Toe)
 but not just any, nooo... **3D Tic-Tac-Toe**!
 
 ## Rules are simple:
 1. Tap the screen to throw a ball.
 2. Each time you hit a block you will hear a sound. If you miss, it's the next players turn.
 3. If you get a "3 in a row", you get a point.
 4. Whoever first has 3 points wins the game!
 
 * callout(Notice):
 Similar to the last page you can [customize](glossary://customize) the `playerNames` and `playerColors` [arrays](glossary://array). By doing that you can also change the number of players 😉
 Keep in mind tho that both arrays need the same number of items in order to [setup](glossary://setup) the game.
 
 - - -
 
Thank you very much for playing and have a wonderful day! ^-^
 */
//#-hidden-code
//
import Foundation
import UIKit
import PlaygroundSupport

let game = GameSceneView(frame: CGRect(x:0, y:0, width: 512, height:768))
//#-code-completion(everything, hide)
//#-code-completion(literal, show, color, string)
//#-code-completion(keyword, show, let)
//
//#-end-hidden-code
//#-editable-code
//choose your player names
let playerNames = ["<#your name#>", "Player2", "Player3", "Player4"]
//choose your colors
let playerColors = [#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)]
//#-end-editable-code
//prepare the game scene
game.setup(names: playerNames, colors: playerColors)
//#-hidden-code
//
PlaygroundPage.current.liveView = game
//
//#-end-hidden-code
