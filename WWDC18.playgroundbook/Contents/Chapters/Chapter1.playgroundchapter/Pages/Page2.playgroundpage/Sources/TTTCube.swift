import Foundation
import SceneKit
import SpriteKit
import PlaygroundSupport

public let BallCategoryBitMask  : Int = 0x1 << 1
public let BlockCategoryBitMask: Int = 0x1 << 2
public let NoCategoryBitMask: Int = 0x1 << 3

public class TTTCube{
    
    struct Cube {
        let x: Int
        let y: Int
        let z: Int
        
        var scnNode: SCNNode
        
        var note: String?
        var belongsTo: Int //Player or -1 if empty
    }
    
    var playerId = 0
    
    var tttCube: [[[Cube]]] = []
    
    let tttCubeNode = SCNNode()
    
    var fullRows = 0
    
    public init() {
        let smallCube = SCNBox(width: 0.09, height:0.09, length: 0.09, chamferRadius: 0)
        smallCube.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.75)
        let smallCubeShape = SCNPhysicsShape(geometry: smallCube, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox])
        
        for x in 0...2{
            var cube2: [[Cube]] = []
            for y in 0...2{
                var cube1: [Cube] = []
                for z in 0...2{
                    var node = SCNNode()
                    let pos = SCNVector3(Double(x)*0.1, Double(y)*0.1, (Double(z)*0.1) - 1)
                    if (x,y,z) == (1,1,1){
                        let bigCube = SCNBox(width: 0.25, height:0.25, length: 0.25, chamferRadius: 0)
                        bigCube.firstMaterial?.diffuse.contents = UIColor.darkGray
                        node = SCNNode(geometry: bigCube)
                        node.position = pos
                        node.name = "111"
                    }else{
                        node = SCNNode(geometry: smallCube.copy() as! SCNBox)
                        node.name = "\(x)\(y)\(z)"
                        node.position = pos
                        node.physicsBody = SCNPhysicsBody(type: .static, shape: smallCubeShape)
                        node.physicsBody?.categoryBitMask = BlockCategoryBitMask
                        node.physicsBody?.collisionBitMask = BallCategoryBitMask
                        node.physicsBody?.contactTestBitMask = BallCategoryBitMask
                    }
                    cube1.append(Cube(x: x, y: y, z: z, scnNode: node, note: nil, belongsTo: -1))
                }
                cube2.append(cube1)
            }
            tttCube.append(cube2)
        }
    }
    
    public func playerWin(completion: @escaping () -> Void){
        let smallCube = SCNBox(width: 0.09, height:0.09, length: 0.09, chamferRadius: 0)
        let smallCubeShape = SCNPhysicsShape(geometry: smallCube, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox])
        for x in 0...2{
            for y in 0...2{
                for z in 0...2{
                    if (x,y,z) == (1,1,1){
                        let anitGravity = SCNPhysicsField.radialGravity()
                        anitGravity.strength = -0.25
                        tttCube[x][y][z].scnNode.physicsField = anitGravity
                    }
                    tttCube[x][y][z].scnNode.physicsBody? = SCNPhysicsBody(type: .dynamic, shape: smallCubeShape)
                    tttCube[x][y][z].scnNode.physicsBody?.mass = 10
                    tttCube[x][y][z].scnNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 10), SCNAction.removeFromParentNode(), SCNAction.customAction(duration: 0) { (n, t) in
                            completion()
                        }]))
                }
            }
        }
    }
    
    public func renderCube(scene: SCNScene){
        for x in 0...2{
            for y in 0...2{
                for z in 0...2{
                    scene.rootNode.addChildNode(tttCube[x][y][z].scnNode)
                }
            }
        }
    }
    
    public func getCubeNode() -> SCNNode{
        return tttCubeNode
    }
    
    public func getPlayerFor(blockNamed: String) -> Int{
        let x = Int(String(blockNamed[blockNamed.index(blockNamed.startIndex, offsetBy: 0)]))!
        let y = Int(String(blockNamed[blockNamed.index(blockNamed.startIndex, offsetBy: 1)]))!
        let z = Int(String(blockNamed[blockNamed.index(blockNamed.startIndex, offsetBy: 2)]))!
        return tttCube[x][y][z].belongsTo
    }
    
    public func player(player: Int, hitBlockWith name: String) -> Bool {
        let x = Int(String(name[name.index(name.startIndex, offsetBy: 0)]))!
        let y = Int(String(name[name.index(name.startIndex, offsetBy: 1)]))!
        let z = Int(String(name[name.index(name.startIndex, offsetBy: 2)]))!

        playerId = player
        guard tttCube[x][y][z].belongsTo == -1 else{
            return false
        }
        
        //tttCube[x][y][z].scnNode.runAction(SCNAction.rotateBy(x: CGFloat.pi, y: CGFloat.pi, z: CGFloat.pi, duration: 1.0))
        let material = SCNMaterial()
        material.diffuse.contents = playerColors[player]
        tttCube[x][y][z].scnNode.geometry?.firstMaterial = material
        
        //let audio = SCNAudioSource(fileNamed: )
        
        tttCube[x][y][z].belongsTo = player
        
        return true
    }
    
    func threeInARow(coordinates: [(x:Int,y:Int,z:Int)]?){
        guard coordinates != nil else {
            return
        }
                
        let material = SCNMaterial()
        var r:CGFloat=0,g:CGFloat=0,b:CGFloat=0,a:CGFloat=0
        
        playerColors[playerId].getRed(&r, green: &g, blue: &b, alpha: &a)
        let darkColor = UIColor(red: min(r/1.25,1.0), green: min(g/1.25,1.0), blue: min(b/1.25,1.0), alpha: 0.9)

        material.diffuse.contents = darkColor
        //block.geometry?.firstMaterial = material
        for coord in coordinates!{
            tttCube[coord.x][coord.y][coord.z].scnNode.geometry?.firstMaterial = material
        }
        fullRows += 1
        return
    }
    
    //FIXME: Diag bug
    
    public func checkForWin(with name: String) -> Int {
        fullRows = 0
        let x = Int(String(name[name.index(name.startIndex, offsetBy: 0)]))!
        let y = Int(String(name[name.index(name.startIndex, offsetBy: 1)]))!
        let z = Int(String(name[name.index(name.startIndex, offsetBy: 2)]))!
        var bFlag = false
        for x in 0...2{
            for y in 0...2{
                for z in 0...2{
                    if(tttCube[x][y][z].belongsTo == -1 && (x,y,z) != (1,1,1)){
                        bFlag = true
                        break
                    }
                }
            }
        }
        guard bFlag else {
            return -1
        }
        
        if ((tttCube[0][0][0].belongsTo, tttCube[0][0][1].belongsTo) == (tttCube[0][0][1].belongsTo, tttCube[0][0][2].belongsTo) && tttCube[0][0][2].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (0,0,1) || (x,y,z) == (0,0,2)){
                threeInARow(coordinates: [(0,0,0), (0,0,1), (0,0,2)])
            }
        }
        if ((tttCube[0][1][0].belongsTo, tttCube[0][1][1].belongsTo) == (tttCube[0][1][1].belongsTo, tttCube[0][1][2].belongsTo) && tttCube[0][1][2].belongsTo != -1){
            if((x,y,z) == (0,1,0) || (x,y,z) == (0,1,1) || (x,y,z) == (0,1,2)){
                threeInARow(coordinates: [(0,1,0), (0,1,1), (0,1,2)])
            }
        }
        if ((tttCube[0][2][0].belongsTo, tttCube[0][2][1].belongsTo) == (tttCube[0][2][1].belongsTo, tttCube[0][2][2].belongsTo) && tttCube[0][2][2].belongsTo != -1){
            if((x,y,z) == (0,2,0) || (x,y,z) == (0,2,1) || (x,y,z) == (0,2,2)){
                threeInARow(coordinates: [(0,2,0), (0,2,1), (0,2,2)])
            }
        }
        if((tttCube[0][0][0].belongsTo, tttCube[1][0][0].belongsTo) == (tttCube[1][0][0].belongsTo, tttCube[2][0][0].belongsTo) && tttCube[2][0][0].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (1,0,0) || (x,y,z) == (2,0,0)){
                threeInARow(coordinates: [(0,0,0), (1,0,0), (2,0,0)])
            }
        }
        if((tttCube[0][1][0].belongsTo, tttCube[1][1][0].belongsTo) == (tttCube[1][1][0].belongsTo, tttCube[2][1][0].belongsTo) && tttCube[2][1][0].belongsTo != -1){
            if((x,y,z) == (0,1,0) || (x,y,z) == (1,1,0) || (x,y,z) == (2,1,0)){
                threeInARow(coordinates: [(0,1,0), (1,1,0), (2,1,0)])
            }
        }
        if((tttCube[0][2][0].belongsTo, tttCube[1][2][0].belongsTo) == (tttCube[1][2][0].belongsTo, tttCube[2][2][0].belongsTo) && tttCube[2][2][0].belongsTo != -1){
            if((x,y,z) == (0,2,0) || (x,y,z) == (1,2,0) || (x,y,z) == (2,2,0)){
                threeInARow(coordinates: [(0,2,0), (1,2,0), (2,2,0)])
            }
        }
        
        if((tttCube[2][0][0].belongsTo, tttCube[2][0][1].belongsTo) == (tttCube[2][0][1].belongsTo, tttCube[2][0][2].belongsTo) && tttCube[2][0][2].belongsTo != -1){
            if((x,y,z) == (2,0,0) || (x,y,z) == (2,0,1) || (x,y,z) == (2,0,2)){
                threeInARow(coordinates: [(2,0,0), (2,0,1), (2,0,2)])
            }
        }
        if((tttCube[2][1][0].belongsTo, tttCube[2][1][1].belongsTo) == (tttCube[2][1][1].belongsTo, tttCube[2][1][2].belongsTo) && tttCube[2][1][2].belongsTo != -1){
            if((x,y,z) == (2,1,0) || (x,y,z) == (2,1,1) || (x,y,z) == (2,1,2)){
                threeInARow(coordinates: [(2,1,0), (2,1,1), (2,1,2)])
            }
        }
        if((tttCube[2][2][0].belongsTo, tttCube[2][2][1].belongsTo) == (tttCube[2][2][1].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (2,2,0) || (x,y,z) == (2,2,1) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(2,2,0), (2,2,1), (2,2,2)])
            }
        }
        if((tttCube[0][0][2].belongsTo, tttCube[1][0][2].belongsTo) == (tttCube[1][0][2].belongsTo, tttCube[2][0][2].belongsTo) && tttCube[2][0][2].belongsTo != -1){
            if((x,y,z) == (0,0,2) || (x,y,z) == (1,0,2) || (x,y,z) == (2,0,2)){
                threeInARow(coordinates: [(0,0,2), (1,0,2), (2,0,2)])
            }
        }
        if((tttCube[0][1][2].belongsTo, tttCube[1][1][2].belongsTo) == (tttCube[1][1][2].belongsTo, tttCube[2][1][2].belongsTo) && tttCube[2][1][2].belongsTo != -1){
            if((x,y,z) == (0,1,2) || (x,y,z) == (1,1,2) || (x,y,z) == (2,1,2)){
                threeInARow(coordinates: [(0,1,2), (1,1,2), (2,1,2)])
            }
        }
        if((tttCube[0][2][2].belongsTo, tttCube[1][2][2].belongsTo) == (tttCube[1][2][2].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (0,2,2) || (x,y,z) == (1,2,2) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(0,2,2), (1,2,2), (2,2,2)])
            }//middle bottum and up:
            
        }
        if((tttCube[0][0][1].belongsTo, tttCube[1][0][1].belongsTo) == (tttCube[1][0][1].belongsTo, tttCube[2][0][1].belongsTo) && tttCube[2][0][1].belongsTo != -1){
            if((x,y,z) == (0,0,1) || (x,y,z) == (1,0,1) || (x,y,z) == (2,0,1)){
                threeInARow(coordinates: [(0,0,1), (1,0,1), (2,0,1)])
            }
        }
        if((tttCube[0][2][1].belongsTo, tttCube[1][2][1].belongsTo) == (tttCube[1][2][1].belongsTo, tttCube[2][2][1].belongsTo) && tttCube[2][2][1].belongsTo != -1){
            if((x,y,z) == (0,2,1) || (x,y,z) == (1,2,1) || (x,y,z) == (2,2,1)){
                threeInARow(coordinates: [(0,2,1), (1,2,1), (2,2,1)])
            }
        }
        if((tttCube[1][0][0].belongsTo, tttCube[1][0][1].belongsTo) == (tttCube[1][0][1].belongsTo, tttCube[1][0][2].belongsTo) && tttCube[1][0][2].belongsTo != -1){
            if((x,y,z) == (1,0,0) || (x,y,z) == (1,0,1) || (x,y,z) == (1,0,2)){
                threeInARow(coordinates: [(1,0,0), (1,0,1), (1,0,2)])
            }
        }
        if((tttCube[1][2][0].belongsTo, tttCube[1][2][1].belongsTo) == (tttCube[1][2][1].belongsTo, tttCube[1][2][2].belongsTo) && tttCube[1][2][2].belongsTo != -1){
            if((x,y,z) == (1,2,0) || (x,y,z) == (1,2,1) || (x,y,z) == (1,2,2)){
                threeInARow(coordinates: [(1,2,0), (1,2,1), (1,2,2)])
            }
        }
        
        if((tttCube[0][0][0].belongsTo, tttCube[0][1][0].belongsTo) == (tttCube[0][1][0].belongsTo, tttCube[0][2][0].belongsTo) && tttCube[0][2][0].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (0,1,0) || (x,y,z) == (0,2,0)){
                threeInARow(coordinates: [(0,0,0), (0,1,0), (0,2,0)])
            }
        }
        if((tttCube[1][0][0].belongsTo, tttCube[1][1][0].belongsTo) == (tttCube[1][1][0].belongsTo, tttCube[1][2][0].belongsTo) && tttCube[1][2][0].belongsTo != -1){
            if((x,y,z) == (1,0,0) || (x,y,z) == (1,1,0) || (x,y,z) == (1,2,0)){
                threeInARow(coordinates: [(1,0,0), (1,1,0), (1,2,0)])
            }
        }
        if((tttCube[2][0][0].belongsTo, tttCube[2][1][0].belongsTo) == (tttCube[2][1][0].belongsTo, tttCube[2][2][0].belongsTo) && tttCube[2][2][0].belongsTo != -1){
            if((x,y,z) == (2,0,0) || (x,y,z) == (2,1,0) || (x,y,z) == (2,2,0)){
                threeInARow(coordinates: [(2,0,0), (2,1,0), (2,2,0)])
            }
        }
        if((tttCube[0][0][2].belongsTo, tttCube[0][1][2].belongsTo) == (tttCube[0][1][2].belongsTo, tttCube[0][2][2].belongsTo) && tttCube[0][2][2].belongsTo != -1){
            if((x,y,z) == (0,0,2) || (x,y,z) == (0,1,2) || (x,y,z) == (0,2,2)){
                threeInARow(coordinates: [(0,0,2), (0,1,2), (0,2,2)])
            }
        }
        if((tttCube[1][0][2].belongsTo, tttCube[1][1][2].belongsTo) == (tttCube[1][1][2].belongsTo, tttCube[1][2][2].belongsTo) && tttCube[1][2][2].belongsTo != -1){
            if((x,y,z) == (1,0,2) || (x,y,z) == (1,1,2) || (x,y,z) == (1,2,2)){
                threeInARow(coordinates: [(1,0,2), (1,1,2), (1,2,2)])
            }
        }
        if((tttCube[2][0][2].belongsTo, tttCube[2][1][2].belongsTo) == (tttCube[2][1][2].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (2,0,2) || (x,y,z) == (2,1,2) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(2,0,2), (2,1,2), (2,2,2)])
            }
        }
            
        if ((tttCube[0][0][1].belongsTo, tttCube[0][1][1].belongsTo) == (tttCube[0][1][1].belongsTo, tttCube[0][2][1].belongsTo) && tttCube[0][2][1].belongsTo != -1){
            if((x,y,z) == (0,0,1) || (x,y,z) == (0,1,1) || (x,y,z) == (0,2,1)){
                threeInARow(coordinates: [(0,0,1), (0,1,1), (0,2,1)])
            }
        }
        if((tttCube[2][0][1].belongsTo, tttCube[2][1][1].belongsTo) == (tttCube[2][1][1].belongsTo, tttCube[2][2][1].belongsTo) && tttCube[2][2][1].belongsTo != -1){
            if((x,y,z) == (2,0,1) || (x,y,z) == (2,1,1) || (x,y,z) == (2,2,1)){
                threeInARow(coordinates: [(2,0,1), (2,1,1), (2,2,1)])
            }
        }
//Diag:
        if ((tttCube[0][0][0].belongsTo, tttCube[0][1][1].belongsTo) == (tttCube[0][1][1].belongsTo, tttCube[0][2][2].belongsTo) && tttCube[0][2][2].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (0,1,1) || (x,y,z) == (0,2,2)){
                threeInARow(coordinates: [(0,0,0), (0,1,1), (0,2,2)])
            }
        }
        if((tttCube[0][2][0].belongsTo, tttCube[0][1][1].belongsTo) == (tttCube[0][1][1].belongsTo, tttCube[0][0][2].belongsTo) && tttCube[0][0][2].belongsTo != -1){
            if((x,y,z) == (0,2,0) || (x,y,z) == (0,1,1) || (x,y,z) == (0,0,2)){
                threeInARow(coordinates: [(0,2,0), (0,1,1), (0,0,2)])
            }
        }
        if((tttCube[2][0][0].belongsTo, tttCube[2][1][1].belongsTo) == (tttCube[2][1][1].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (2,0,0) || (x,y,z) == (2,1,1) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(2,0,0), (2,1,1), (2,2,2)])
            }
        }
        if((tttCube[2][2][0].belongsTo, tttCube[2][1][1].belongsTo) == (tttCube[2][1][1].belongsTo, tttCube[2][0][2].belongsTo) && tttCube[2][0][2].belongsTo != -1){
            if((x,y,z) == (2,2,0) || (x,y,z) == (2,1,1) || (x,y,z) == (2,0,2)){
                threeInARow(coordinates: [(2,2,0), (2,1,1), (2,0,2)])
            }
        }
            
        if ((tttCube[0][0][0].belongsTo, tttCube[1][1][0].belongsTo) == (tttCube[1][1][0].belongsTo, tttCube[2][2][0].belongsTo) && tttCube[2][2][0].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (1,1,0) || (x,y,z) == (2,2,0)){
                threeInARow(coordinates: [(0,0,0), (1,1,0), (2,2,0)])
            }
        }
        if((tttCube[0][2][0].belongsTo, tttCube[1][1][0].belongsTo) == (tttCube[1][1][0].belongsTo, tttCube[2][0][0].belongsTo) && tttCube[2][0][0].belongsTo != -1){
            if((x,y,z) == (0,2,0) || (x,y,z) == (1,1,0) || (x,y,z) == (2,0,0)){
                threeInARow(coordinates: [(0,2,0), (1,1,0), (2,0,0)])
            }
        }
        if((tttCube[0][0][2].belongsTo, tttCube[1][1][2].belongsTo) == (tttCube[1][1][2].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (0,0,2) || (x,y,z) == (1,1,2) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(0,0,2), (1,1,2), (2,2,2)])
            }
        }
        if((tttCube[0][2][2].belongsTo, tttCube[1][1][2].belongsTo) == (tttCube[1][1][2].belongsTo, tttCube[2][0][2].belongsTo) && tttCube[2][0][2].belongsTo != -1){
            if((x,y,z) == (0,2,2) || (x,y,z) == (1,1,2) || (x,y,z) == (2,0,2)){
                threeInARow(coordinates: [(0,2,2), (1,1,2), (2,0,2)])
            }
        }
            
        if ((tttCube[0][0][0].belongsTo, tttCube[1][0][1].belongsTo) == (tttCube[1][0][1].belongsTo, tttCube[2][0][2].belongsTo) && tttCube[2][0][2].belongsTo != -1){
            if((x,y,z) == (0,0,0) || (x,y,z) == (1,0,1) || (x,y,z) == (2,0,2)){
                threeInARow(coordinates: [(0,0,0), (1,0,1), (2,0,2)])
            }
        }
        if((tttCube[0][0][2].belongsTo, tttCube[1][0][1].belongsTo) == (tttCube[1][0][1].belongsTo, tttCube[2][0][0].belongsTo) && tttCube[2][0][0].belongsTo != -1){
            if((x,y,z) == (0,0,2) || (x,y,z) == (1,0,1) || (x,y,z) == (2,0,0)){
                threeInARow(coordinates: [(0,0,2), (1,0,1), (2,0,0)])
            }
        }
        if((tttCube[0][2][0].belongsTo, tttCube[1][2][1].belongsTo) == (tttCube[1][2][1].belongsTo, tttCube[2][2][2].belongsTo) && tttCube[2][2][2].belongsTo != -1){
            if((x,y,z) == (0,2,0) || (x,y,z) == (1,2,1) || (x,y,z) == (2,2,2)){
                threeInARow(coordinates: [(0,2,0), (1,2,1), (2,2,2)])
            }
        }
        if((tttCube[0][2][2].belongsTo, tttCube[1][2][1].belongsTo) == (tttCube[1][2][1].belongsTo, tttCube[2][2][0].belongsTo) && tttCube[2][2][0].belongsTo != -1){
            if((x,y,z) == (0,2,2) || (x,y,z) == (1,2,1) || (x,y,z) == (2,2,0)){
                threeInARow(coordinates: [(0,2,2), (1,2,1), (2,2,0)])
            }
        }
        
        /*if(x != 1) {    //on x=0 or x=2 side
            if(y == 1){
                if z == 1{
                    //middle
                    if (tttCube[x][1][1].belongsTo, tttCube[x][0][0].belongsTo) == (tttCube[x][0][0].belongsTo, tttCube[x][2][2].belongsTo)
                    || (tttCube[x][1][1].belongsTo, tttCube[x][0][2].belongsTo) == (tttCube[x][0][2].belongsTo, tttCube[x][2][0].belongsTo)
                    || (tttCube[x][1][1].belongsTo, tttCube[x][1][0].belongsTo) == (tttCube[x][1][0].belongsTo, tttCube[x][1][2].belongsTo)
                    || (tttCube[x][1][1].belongsTo, tttCube[x][0][1].belongsTo) == (tttCube[x][0][1].belongsTo, tttCube[x][2][1].belongsTo){
                        return true
                    }else {return false}
                }else{  //y still 1
                    //edge
                    if (tttCube[x][1][0].belongsTo, tttCube[x][1][1].belongsTo) == (tttCube[x][1][1].belongsTo, tttCube[x][1][2].belongsTo)
                    || (tttCube[x][1][z].belongsTo, tttCube[x][0][z].belongsTo) == (tttCube[x][0][z].belongsTo, tttCube[x][2][z].belongsTo)
                    || (tttCube[0][1][z].belongsTo, tttCube[1][1][z].belongsTo) == (tttCube[1][1][z].belongsTo, tttCube[2][1][z].belongsTo){
                        return true
                    }else {return false}
                }
            }else{//y not 1
                if z == 1{
                    //edge
                    if (tttCube[x][0][1].belongsTo, tttCube[x][1][1].belongsTo) == (tttCube[x][1][1].belongsTo, tttCube[x][2][1].belongsTo)
                    || (tttCube[x][y][0].belongsTo, tttCube[x][y][1].belongsTo) == (tttCube[x][y][1].belongsTo, tttCube[x][y][2].belongsTo)
                    || (tttCube[0][y][1].belongsTo, tttCube[1][y][z].belongsTo) == (tttCube[1][y][z].belongsTo, tttCube[2][y][z].belongsTo){
                        return true
                    }else {return false}
                }else{  //CORNER! //1st straight 2nd diagonal
                    if (tttCube[0][y][z].belongsTo, tttCube[1][y][z].belongsTo) == (tttCube[1][y][z].belongsTo, tttCube[2][y][z].belongsTo)
                    || (tttCube[x][y][0].belongsTo, tttCube[x][y][1].belongsTo) == (tttCube[x][y][1].belongsTo, tttCube[x][y][2].belongsTo)
                    || (tttCube[x][0][z].belongsTo, tttCube[x][1][z].belongsTo) == (tttCube[x][1][z].belongsTo, tttCube[x][2][z].belongsTo) //Diag:
                    ||(tttCube[x][0][1].belongsTo, tttCube[x][1][1].belongsTo) == (tttCube[x][1][1].belongsTo, tttCube[x][2][1].belongsTo)
                    || (tttCube[x][0][1].belongsTo, tttCube[x][1][1].belongsTo) == (tttCube[x][1][1].belongsTo, tttCube[x][2][1].belongsTo)
                    || (tttCube[x][0][1].belongsTo, tttCube[x][1][1].belongsTo) == (tttCube[x][1][1].belongsTo, tttCube[x][2][1].belongsTo){
                        
                    }
                    /*if y == 0{
                        
                    }else{
                        
                    }*/
                }
            }
            
            
            /*if y != 1, z != 1{      //on x,y,z corner
                
            }else{
                if y != 1 || z != 1{
                    //on edge
                }else{
                    //Middle
                }
            }*/
        }else if y != 1{
            if(x == 1){
                if z == 1{
                    //middle
                }else{
                    //corner
                }
            }else {
                //corner
            }
        }else if z != 1{
            if(x == 1){
                if y == 1{
                    //middle
                }else{
                    //corner
                }
            }else {
                //corner
            }
        }*/
        return fullRows
    }
    
   /* func checkMiddle(x:Int, y:Int, z:Int) -> Bool {
        if x == 0{
            
        }if y == 0{
            
        }else{
            
        }
        
        return true
    }*/
    
}
