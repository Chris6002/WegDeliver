//
//  ViewProductionViewController.swift
//  WegDeliver
//
//  Created by Tianyou Xiao on 1/27/18.
//  Copyright © 2018 Qiuyue Sun. All rights reserved.
//

import UIKit

class ViewProductCollection: UITableViewController{
    var product:[Item] = []
   
    override func viewDidLoad() {
        super.viewDidLoad()
        getProduct()
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        let insets = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "All Product"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return product.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PVCell", for: indexPath) as! PVCell
        let category = product[indexPath.row]
        
        cell.name.text = category.name
        cell.descrip = category.description
        cell.it = category
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                let cell = sender as? PVCell
            //let product = Product(name:(cell?.name.text)!,price:1.234,unit:"/per");
                let nextView = segue.destination as! ViewProductVC
                nextView.title = cell?.name.text
                nextView.nameLabel = (cell?.name.text)!
        nextView.it = (cell?.it)!
        nextView.des = (cell?.descrip)!
    }
    
    func getProduct(){
        var keyRequest = URLRequest(url: URL(string: "https://login.microsoftonline.com/1318d57f-757b-45b3-b1b0-9b3c3842774f/oauth2/token")!)
        keyRequest.httpMethod = "POST"
        keyRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let code = "client_id=24960d97-4fbe-433d-ab8a-efeb89aa524e&grant_type=client_credentials&resource=https://wegmans-es.azure-api.net&client_secret=A8N7VeeCdFD5N4OxeQT1gFaXNStrxieEplYl3SYdxTs=".data(using:String.Encoding.ascii, allowLossyConversion: false)
        keyRequest.httpBody = code
        let keyTask = URLSession.shared.dataTask(with: keyRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil{
                return
            }
            if let data = data{
                var authorization = ""
                do {
                    let jsonObject: Any = try JSONSerialization.jsonObject(with: data, options: [])
                    let jsonDict = jsonObject as! [String:String]
                    let tokenType = jsonDict["token_type"]
                    let accessToken = jsonDict["access_token"]
                    authorization = tokenType! + " " + accessToken!
                }
                catch let error {
                    print("JSON Parse Error")
                    return
                }
                
                //Request product info by search criterion
                let productSearchURL = URL(string: "https://wegmans-es.azure-api.net/productpublic/producthierarchies/Marketing/EZ%20Meals/Asian")!;
                
                var productRequest = URLRequest(url: productSearchURL)
                productRequest.httpMethod = "GET"
                productRequest.addValue("dbf9da0bc0814d07b6687136b4b36dd7", forHTTPHeaderField: "Product-Subscription-Key")
                productRequest.addValue(authorization, forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: productRequest) { (data, response, error) in
                    if error != nil{
                        return
                    }
                    if let data = data, let string = String(data: data, encoding: .utf8) {
                        print("Product Request")
                       // print(string)
                        do{
                            let prodFromJson = try JSONSerialization.jsonObject(with: data, options: [])
                            let prodTree = hierarchy(json: prodFromJson as! [String: Any])
                            let prodArr = prodTree?.nodes[0].childNodes[0].childNodes
                            //print(prodArr)
                            
                            //print(self.product)
                            
                            DispatchQueue.main.async(){
                                self.product = prodArr!
                                print(self.product)
                                self.tableView.reloadData()
                            }
                        }catch let error{
                            print("Prod JSON Parse error!")
                        }
                    }else{
                        print("failed")
                    }
                }.resume()

            }
            
        }
        keyTask.resume()
        
    }
    
}

extension URL {
    
    func withQueries(_ queries: [String: String]) -> URL? {
        
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queries.flatMap { URLQueryItem(name: $0.0, value: $0.1) }
        return components?.url
    }
}

class hierarchy{
    var name: String
    var nodes: [LevelOne]
    init?(json: [String: Any]){
        guard let name = json["Name"] as? String,
              let nodesJson = json["Nodes"] as? [[String: Any]]
        else{ return nil }
        var nodes: [LevelOne] = []
        for string in nodesJson{
            guard let node = LevelOne(json: string) else {return nil}
            nodes.append(node)
        }
        self.name = name
        self.nodes = nodes
    }
}

class LevelOne{
    var description: String
    var level: String
    var childNodes: [LevelTwo]
    init?(json: [String: Any]){
        guard let description = json["Description"] as? String,
              let level = json["Level"] as? String,
              let childNodesJson = json["ChildNodes"] as? [[String: Any]]
        else{ return nil }
        var childNodes: [LevelTwo] = []
        for string in childNodesJson{
            guard let childNode = LevelTwo(json: string) else {return nil}
            childNodes.append(childNode)
        }
        self.description = description
        self.level = level
        self.childNodes = childNodes
    }
}

class LevelTwo{
    var description: String
    var level: String
    var childNodes: [Item]
    init?(json: [String: Any]){
        guard let description = json["Description"] as? String,
              let level = json["Level"] as? String,
            let childNodesJson = json["ChildNodes"] as? [[String: Any]]
        else{ return nil }
        var childNodes: [Item] = []
        for string in childNodesJson{
            guard let childNode = Item(json: string) else {return nil}
            childNodes.append(childNode)
        }
        self.description = description
        self.level = level
        self.childNodes = childNodes
    }
}

class Item: CustomStringConvertible{
    var name: String = ""
    var level: String = ""
    var sku: Int = 0
    var description: String{
        return "Name: " + name + " SKU: " + sku.description
    }
    init?(json: [String: Any]){
        guard let name = json["Description"] as? String,
              let level = json["Level"] as? String,
              let sku = json["Sku"] as? Int
        else{ return nil}
        self.name = name
        self.level = level
        self.sku = sku
    }
    init(){
       
    }
}
