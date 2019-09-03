//
//  ViewController.swift
//  Sqlite Demo
//
//  Created by oceans on 03/09/19.
//  Copyright © 2019 Bhadresh Patoliya. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var db: OpaquePointer?
    var heroList = [Hero]()
    
    @IBOutlet weak var tblViewHeroes: UITableView!

    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textFieldPowerRanking: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("HeroesDatabase.sqlite")
        
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Heroes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, powerrank INTEGER)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
        readValues()
    }
    @IBAction func buttonSave(_ sender: UIButton) {
        let name = textFieldName.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let powerRanking = textFieldPowerRanking.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if(name?.isEmpty)!{
            textFieldName.layer.borderColor = UIColor.red.cgColor
            return
        }
        
        if(powerRanking?.isEmpty)!{
            textFieldName.layer.borderColor = UIColor.red.cgColor
            return
        }
        
        var stmt: OpaquePointer?
        
        let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (?,?)"
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        if sqlite3_bind_text(stmt, 1, name, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_bind_int(stmt, 2, (powerRanking! as NSString).intValue) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting hero: \(errmsg)")
            return
        }
        
        textFieldName.text=""
        textFieldPowerRanking.text=""
        
        readValues()
        
        print("Herro saved successfully")
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return heroList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        let hero: Hero
        hero = heroList[indexPath.row]
        cell.textLabel?.text = hero.name
        return cell
    }
    
    
    func readValues(){
        heroList.removeAll()
        
        let queryString = "SELECT * FROM Heroes"
        
        var stmt:OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = sqlite3_column_int(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let powerrank = sqlite3_column_int(stmt, 2)
            
            heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
        }
        
        self.tblViewHeroes.reloadData()
    }
    
 
    func createDirectory(directoryname:String) -> String {
        let documentsDirectoryPath:NSString = getDirectoryPath() as NSString
        let logsPath = documentsDirectoryPath.appendingPathComponent(directoryname)
        print("documentsPath1:\(logsPath)")
        do
        {
            try FileManager.default.createDirectory(atPath: logsPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        return logsPath
    }
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    func recursivePathsinDirectory(_ directoryPath: String?) -> NSArray? {
        let filePaths: NSMutableArray? = NSMutableArray()
        
        let filename:String = directoryPath!
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(filename) {
            let filePath = pathComponent.path
            let enumerator: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(atPath: filePath)
            while let filePath = enumerator?.nextObject() as? String {
                let itemPath = "\(path)/\(directoryPath!)\(filePath)"
                var actualObject: NSDictionary = NSDictionary()
                do {
                    actualObject = try FileManager.default.attributesOfItem(atPath: itemPath) as NSDictionary
                } catch {}
                if actualObject.allKeys.count > 0
                {
                    if actualObject.object(forKey: FileAttributeKey.type) as! String ==  FileAttributeType.typeDirectory.rawValue
                    {
                        filePaths!.add(itemPath)
                    }
                }
            }
        }
        return filePaths
    }
    func GetFullFilePathWithName(_ directoryPath: String?) -> String? {
        let filePath = "\(directoryPath!)"
        if FileManager.default.fileExists(atPath: filePath) {
            var counter: UInt = 1
            var newFilePath = "\(directoryPath!)_\(counter)"
            while FileManager.default.fileExists(atPath: newFilePath) {
                newFilePath = "\(directoryPath!)_\(counter)"
                counter += 1
            }
            return GetFullFilePathWithName(newFilePath)
        }
        return filePath
    }
    func createDirectoryWithPath(filepath:String)
    {
        do
        {
            try FileManager.default.createDirectory(atPath: filepath, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }

    func createfilePathWithTemplatename(TempName:String,DirName:String, isWebtemplate: Bool) -> String
    {
        let filename = "\(TempName)/\(DirName)"
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(filename) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
                if isWebtemplate == true
                {
                    return filePath
                }else{
                    let newfilePath = GetFullFilePathWithName(filePath)!
                    createDirectoryWithPath(filepath: newfilePath)
                    return newfilePath
                }
            } else {
                print("FILE NOT AVAILABLE")
                let newfilePath = GetFullFilePathWithName(filePath)!
                createDirectoryWithPath(filepath: newfilePath)
                return filePath
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
            return "Path not exist"
        }
    }
    
    //let fileManager = FileManager.default
    //if fileManager.fileExists(atPath: BGimgPath){
    //    let image = UIImage(contentsOfFile: BGimgPath)
    //}else{
    //    print("No Image")
    //}

}

