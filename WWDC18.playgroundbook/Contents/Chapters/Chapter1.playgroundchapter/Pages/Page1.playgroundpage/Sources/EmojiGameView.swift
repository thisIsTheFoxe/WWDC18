import PlaygroundSupport
import ARKit
import SpriteKit
import UIKit
import Foundation

@available(iOS 11.0, *)
public class EmojiGameView: ARSCNView, SCNPhysicsContactDelegate{
    
    let BallCategoryBitMask  : Int = 0x1 << 1
    let EmojiCategoryBitMask: Int = 0x1 << 2
    
    var emojiIndex = 0
    var emojiDamage = 0
    var bgColor: UIColor = UIColor.clear
    
    var emojis: [String] = []
    
    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        
        self.autoenablesDefaultLighting = true
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(EmojiGameView.sceneTapped(sender: )))
        self.addGestureRecognizer(recognizer)
        
        let scene = SCNScene()
        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -0.25, z: 0)
        scene.physicsWorld.contactDelegate = self
        
        self.scene = scene

        self.session.run(ARWorldTrackingConfiguration())
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print(aDecoder)
    }

    public func setEmojis(_ emojis:[String], withBackgroundColor color: UIColor?){
       if(emojis.count > 5){
            fatalError("You may be a bit too exited about this page 😄. Remember that the main part is on the next page 😉")
        }
        if(emojis.count <= 0){
            fatalError("Well, if that's what you want: Here you have 0 emojis: \n(fill the `emojis` array to get the code running)")
        }
        
        if(color != nil){
            bgColor = color!
        }
        
        self.emojis = emojis
        
        let geo = SCNCapsule(capRadius: 0.25, height: 1)
        geo.firstMaterial?.diffuse.contents = getEmojiImage(emoji: emojis[0])
        let node = SCNNode(geometry: geo)
        node.position = SCNVector3(x:0, y: 0, z: -1.5)
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: geo, options: nil))
        node.physicsBody?.categoryBitMask = EmojiCategoryBitMask
        node.physicsBody?.collisionBitMask = BallCategoryBitMask
        node.physicsBody?.contactTestBitMask = BallCategoryBitMask
        node.constraints = [SCNBillboardConstraint()]
        let musicSource = SCNAudioSource(fileNamed: "BeautifulDreamMono")!
        musicSource.volume = 0.1
        node.runAction(SCNAction.repeatForever(SCNAction.playAudio(musicSource, waitForCompletion: true)))
        self.scene.rootNode.addChildNode(node)
    }
    
    @objc
    func sceneTapped(sender: UITapGestureRecognizer) {
        guard (scene.rootNode.childNode(withName: "ball", recursively: false) == nil) else {
            return
        }
        
        let ball = SCNSphere(radius: 0.005)
        ball.firstMaterial?.diffuse.contents = UIColor.purple
        let ballNode = SCNNode(geometry: ball)
        ballNode.name = "ball"
        ballNode.position = (self.pointOfView?.position)!
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ball, options: nil))
        ballNode.physicsBody?.categoryBitMask = BallCategoryBitMask
        ballNode.physicsBody?.collisionBitMask = EmojiCategoryBitMask
        ballNode.physicsBody?.contactTestBitMask = EmojiCategoryBitMask
        ballNode.physicsBody?.applyForce(projectedDirection(pt: sender.location(in: self)), asImpulse: true)
        ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.5), SCNAction.removeFromParentNode()]))
        self.scene.rootNode.addChildNode(ballNode)
    }
    
    func projectedDirection(pt: CGPoint?) -> SCNVector3 {
        guard pt != nil else {
            return SCNVector3(0, 0, 1)
        }
        
        let farPt  = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 1))
        let nearPt = self.unprojectPoint(SCNVector3(Float(pt!.x), Float(pt!.y), 0))
        
        return SCNVector3((farPt.x - nearPt.x)/1000, (farPt.y - nearPt.y)/1000, (farPt.z - nearPt.z)/1000)
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var ball = SCNNode()
        var block = SCNNode()
        
        if contact.nodeA.name == "ball"{
            ball = contact.nodeA
            block = contact.nodeB
        }else{
            ball = contact.nodeB
            block = contact.nodeA
        }
        
        guard ball.parent != nil else{
            return
        }
        
        ball.removeAllActions()
        ball.removeFromParentNode()
        
        let soundSource = Sound(instument: Sound.Instrument.guitar, key: Sound.Key.C).playRandomSceneNote()!
        let sound = SCNNode()
        sound.runAction(SCNAction.playAudio(soundSource, waitForCompletion: true))
        scene.rootNode.addChildNode(sound)
        
        
        emojiDamage += 1
        
        guard emojiDamage % 2 == 0 else {
            return
        }
        emojiIndex += 1
        guard emojiIndex < emojis.count else {
            let finishParticle = SCNParticleSystem(named: "Confetti", inDirectory: nil)
            let finishNode = SCNNode()
            finishNode.addParticleSystem(finishParticle!)
            finishNode.position = SCNVector3(x:0, y:2, z: 0)
            scene.rootNode.addChildNode(finishNode)
            block.runAction(SCNAction.sequence([SCNAction.wait(duration: 7),SCNAction.customAction(duration: 0, action: { (n, t) in
                PlaygroundPage.current.assessmentStatus = .pass(message: "### Well done, let's continue...                \n[**Next Page**](@next)")
            }), SCNAction.removeFromParentNode()]))
            return
        }
        block.geometry?.firstMaterial?.diffuse.contents = getEmojiImage(emoji: emojis[emojiIndex])
    }
    
    func getEmojiImage(emoji: String) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 0)
        let c = UIGraphicsGetCurrentContext()
        c?.translateBy(x: 25, y: 25)
        //UIColor.yellow.set()
        emoji.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: 55, height: 55)), withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 50), NSAttributedStringKey.backgroundColor: bgColor])
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
