import PlaygroundSupport
import SceneKit
import ARKit
import UIKit
import Foundation

public var playerColors: [UIColor] = []

public class GameSceneView: ARSCNView, ARSCNViewDelegate, SCNPhysicsContactDelegate, ARSessionDelegate{
    
    var contactFlag = false
    
    var playerId = 0
    var playerNames:[String] = []
    var winCountForPlayer:[Int:Int] = [:]
    
    var tttCube: TTTCube? = nil
    
    var playerLabels: [UILabel] = []
    
    var bgMusicTimer = Timer()
    
    var middle = SCNNode()
    
    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        let scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(GameSceneView.sceenTapped(recognizer:)))
        self.addGestureRecognizer(recognizer)
        
        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -0.25, z: 0)
        scene.physicsWorld.contactDelegate = self
        
        self.scene = scene
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerLabels()
    }
    
    public func setup(names: [String], colors: [UIColor]){
        self.session.run(ARWorldTrackingConfiguration())

        if(names.count > 4){
            fatalError("Too many items in the `playerNames` array.")
        }else if (names.count == 0){
            fatalError("Help! I cannot play without players :( \n\n(Put at least one name in the `playerNames` and one color in the ´playerColrs´ array.)")
        }else if (colors.count > 4){
            fatalError("Too many items in the `playerColors` array.")
        }else if (colors.count != names.count){
            fatalError("Both, the `playerNames` array and the `playerColors` have to have the same number of items.")
        }
        
        playerNames = names
        playerColors = colors.map { (c) -> UIColor in
            c.withAlphaComponent(0.75)
        }
        
        for i in 1...playerNames.count{
            let newLabel = UILabel()
            newLabel.textColor = playerColors[i-1]
            playerLabels.append(newLabel)
            self.addSubview(newLabel)
        }
        
        for pl in 0..<playerNames.count {
            winCountForPlayer[pl] = 0
        }
        
        tttCube = TTTCube()
        
        updatePlayerLabels()
        
        tttCube!.renderCube(scene: scene)
        middle = scene.rootNode.childNode(withName: "111", recursively: false)!
        bgMusicTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { (timer) in
            let bgAudio = Sound(instument: Sound.Instrument.piano, key: Sound.Key(rawValue: self.playerId)!).playRandomSceneNote()!
            bgAudio.volume = 0.1
            bgAudio.reverbBlend = 0.5
            self.middle.runAction(SCNAction.playAudio(bgAudio, waitForCompletion: false))
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatePlayerLabels(){
        guard playerNames.count != 0 else {
            return
        }
        for i in 0...playerNames.count-1{
            playerLabels[i].text = "\(playerNames[i]): \(winCountForPlayer[i] ?? 0)"
            if i == playerId{
                playerLabels[i].font = UIFont.boldSystemFont(ofSize: 22)
            }else{
                playerLabels[i].font = UIFont.systemFont(ofSize: 18)
            }
            playerLabels[i].sizeToFit()
            playerLabels[i].reloadInputViews()
            var labelOrigin = CGPoint()
            switch i {
            case 0:
                labelOrigin = CGPoint.zero
            case 1:
                labelOrigin = CGPoint(x: self.frame.width - playerLabels[i].frame.width, y: 0)
            case 2:
                labelOrigin = CGPoint(x: 0, y: self.frame.height - playerLabels[i].frame.height)
            case 3:
                labelOrigin = CGPoint(x: self.frame.width - playerLabels[i].frame.width, y: self.frame.height - playerLabels[i].frame.height)
            default:
                break
            }
            playerLabels[i].frame.origin = labelOrigin
        }
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var ball = SCNNode()
        var block = SCNNode()
        if(contact.nodeA.name == "ball"){
            ball = contact.nodeA
            block = contact.nodeB
        }else{
            ball = contact.nodeB
            block = contact.nodeA
        }
        guard ball.parent != nil else {
            return
        }
        
        ball.removeAllActions()
        ball.removeFromParentNode()
        
        if tttCube!.player(player: playerId, hitBlockWith: block.name!) {
            //playPlayerNote
            let explosionPartickle = SCNParticleSystem(named: "BallExplosion", inDirectory: nil)
            let explosionNode = SCNNode()
            explosionNode.addParticleSystem(explosionPartickle!)
            explosionNode.position = contact.contactPoint
            explosionNode.runAction(.sequence([.wait(duration: 1.0), .removeFromParentNode()]))
            scene.rootNode.addChildNode(explosionNode)
            
            let rows = tttCube!.checkForWin(with: block.name!)
            guard rows >= 0 else{
                scene.rootNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 2), SCNAction.customAction(duration: 0) { (n, t) in
                    PlaygroundPage.current.assessmentStatus = .fail(hints: ["It's a tie.... Maybe try it with less players the next time 😉"], solution: nil)
                    }]))
                return
            }
            
            winCountForPlayer[playerId]! += rows
            
            let winSound = Sound(instument: Sound.Instrument.guitar, key: Sound.Key(rawValue: playerId)!)
            if(rows > 0){
                var melody:[SCNAction] = []
                
                if winCountForPlayer[playerId]! >= 3{
                    let finishParticle = SCNParticleSystem(named: "Confetti", inDirectory: nil)
                    let finishNode = SCNNode()
                    finishNode.addParticleSystem(finishParticle!)
                    finishNode.position = SCNVector3(x:0, y:1, z: 0)
                    scene.rootNode.addChildNode(finishNode)
                    for i in 0...4{
                        melody.append(SCNAction.playAudio(winSound.play(note: i)[0], waitForCompletion: false))
                        melody.append(SCNAction.wait(duration: 0.375))
                    }
                    bgMusicTimer.invalidate()
                    tttCube!.playerWin{
                        PlaygroundPage.current.assessmentStatus = .pass(message: "Congrats \(self.playerNames[self.playerId])! **You did it!**  Thanks for playing 🦊")
                        return
                    }
                }else{
                    melody = [SCNAction.playAudio(winSound.playRandomSceneNote()!, waitForCompletion: true)]
                }
                middle.runAction(SCNAction.sequence(melody))
            }else{
                block.runAction(SCNAction.playAudio(winSound.playRandomSceneNote()!, waitForCompletion: true))
            }
        }else{
            //playEnemyNote / wrongNote / noNote?
            let enemyId = tttCube!.getPlayerFor(blockNamed: block.name!)
            block.runAction(SCNAction.playAudio(Sound(instument: .guitar, key: Sound.Key(rawValue: enemyId)!).playRandomSceneNote()!, waitForCompletion: true))
        }
        DispatchQueue.main.async {
            if self.winCountForPlayer[self.playerId]! < 3{
                self.playerId = self.playerId+1 >= self.playerNames.count ? 0: self.playerId+1
                self.updatePlayerLabels()
            }else{
                self.playerLabels[self.playerId].text = "\(self.playerNames[self.playerId]): \(self.winCountForPlayer[self.playerId] ?? 0)"
                self.playerLabels[self.playerId].sizeToFit()
            }
        }
    }
    
    @objc
    func sceenTapped(recognizer: UITapGestureRecognizer) {
        guard (scene.rootNode.childNode(withName: "ball", recursively: false) == nil) else {
            return
        }
        //renderWholeCube(frame: session.currentFrame!)
        
        //do stuff
        let ball = SCNSphere(radius: 0.005)
        ball.firstMaterial?.diffuse.contents = playerColors[playerId].withAlphaComponent(0.8)
        let ballNode = SCNNode(geometry: ball)
        ballNode.name = "ball"
        ballNode.position = (self.pointOfView?.position)!
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ball, options: nil))
        ballNode.physicsBody?.categoryBitMask = BallCategoryBitMask
        ballNode.physicsBody?.collisionBitMask = BlockCategoryBitMask
        ballNode.physicsBody?.contactTestBitMask = BlockCategoryBitMask
        ballNode.physicsBody?.applyForce(projectedDirection(pt: recognizer.location(in: self)), asImpulse: true)
        ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.5), SCNAction.customAction(duration: 0) { (n, t) in
            DispatchQueue.main.async {
                self.playerId = self.playerId+1 >= self.playerNames.count ? 0: self.playerId+1
                self.updatePlayerLabels()
            }
            }, SCNAction.removeFromParentNode()]))
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
}
