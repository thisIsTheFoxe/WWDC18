//#-hidden-code
//
//  Contents.swift
//
//  Made by: Henrik Storch
//
//#-end-hidden-code
/*:
 # **Hello and welcome to my Scholarship PlaygroundBook.**
    
 This year I had a lot of fun with [ARKit](glossary://AR).
 
 Last year I made a .playgrounbook about [pentatonics](glossary://pentatonics). This became very handy and helpful filling this book with life.
 
 But before I reveal what I produced this year, I want you to get comfortable with my [physics world](glossary://physicsWorld).
 
 * callout(Task):
 Tap the screen and throw balls at the [emoji](glossary://emoji), to get to know the gravity.

 **Hint:** You can also add, remove or change the [emojis](glossary://emoji) and the background-color in the code below. But keep in mind that you need at least one emoji-[String](glossary://String) 😉.
 
 - - -
 When you think you are finished, you can go to the **[next page](@next)**.
 
*/

//#-hidden-code
//
import PlaygroundSupport
import Foundation
import UIKit
//#-code-completion(everything, hide)
//#-code-completion(literal, show, color, string, nil)
//
let scene = EmojiGameView(frame: CGRect(x:0, y:0, width: 512, height:768))
//
//TODO: make pictures availale!
//#-end-hidden-code
//customize the emojis array with your own emojis
let emojis = /*#-editable-code*/["🧐", "😀", "☺️"]/*#-end-editable-code*/

//choose a background color or delete it (meaning: set it to "nil")
let background: UIColor? = /*#-editable-code*/#colorLiteral(red: 0.6148781447, green: 0.4668025014, blue: 1, alpha: 1)/*#-end-editable-code*/

//setup the scene with the emojis specified above
scene.setEmojis(emojis, withBackgroundColor: background)
//#-hidden-code
//

/*guard #available(iOS 11.0, *) else{
 fatalError("Sadly this Device doesn't support ARKit and therfore cannot run this PlaygroundBook.")
 }*/
PlaygroundPage.current.liveView = scene
//
//#-end-hidden-code

