//
//  ViewController.swift
//  NewsPlayer
//
//  Created by YAMAMOTOKenta on 9/11/15.
//  Copyright (c) 2015 ymkjp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func load(sender: UIBarButtonItem) {
        fetchData()
    }
    
    func fetchData() {
        let credentialsPath = NSBundle.mainBundle().pathForResource("Credentials", ofType: "plist")
        let credentials = NSDictionary(contentsOfFile: credentialsPath!)
        
        let apiKey:String = credentials!.objectForKey("Google API Key") as! String
        let channelId = "UCGCZAYq5Xxojl_tSXcVJhiQ"
        let URL = NSURL(string: "https://www.googleapis.com/youtube/v3/activities?part=snippet%2CcontentDetails&channelId=\(channelId)&key=\(apiKey)")
        let req = NSURLRequest(URL: URL!)
        let connection: NSURLConnection = NSURLConnection(request: req, delegate: self, startImmediately: false)!
        
        NSURLConnection.sendAsynchronousRequest(req,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: response)
    }
    
    func response(res: NSURLResponse!, data: NSData!, error: NSError!){
        // @todo Handle error
        let json:NSDictionary = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments, error: nil) as! NSDictionary
        
        let res:NSArray = json.objectForKey("items")as! NSArray
        
        for var i=0 ; i<res.count ; i++ {
            var snippet:NSDictionary = res[i].objectForKey("snippet") as! NSDictionary
            var title:String = snippet.objectForKey("title") as! String
            
            println(title)
        }
    }
}

