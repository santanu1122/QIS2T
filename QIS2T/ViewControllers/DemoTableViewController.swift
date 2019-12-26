//
//  DemoTableViewController.swift
//  QIS2T
//
//  Created by Santanu Das Adhikary. on 24/12/19.
//  Copyright © 2019 Santanu Das Adhikary. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift
import Toast_Swift

class DemoTableViewController: ExpandingTableViewController {

    fileprivate var scrollOffsetY: CGFloat = 0
    private var numberOfSections = 1
    private var numberOfRows = 1
    private var dataArray = [SpeechTextItem]()
        
    private var cellsIdentifiers = [
        "CustomTableViewCell",
        "loadingViewCell"
    ]
    
    var selectedText: String = ""
    private var textAvelebelity = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        
        print(String("select text ==> \(selectedText)"))
        
        fetchAllDictionaryDetails()
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
}

// MARK: Helpers

extension DemoTableViewController {
    fileprivate func configureNavBar() {
        navigationItem.rightBarButtonItem?.image = navigationItem.rightBarButtonItem?.image!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
    }
}

extension DemoTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if dataArray.count > 0 {
            let cellIdentifier = cellsIdentifiers[0]
            let dataObject = dataArray[indexPath.row]
            
            //let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            
            let cell :CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CustomTableViewCell
            //print(dataObject.text)
            cell.dictionaryText.text = String("Text : \(dataObject.text)")
            cell.textFrequency.text = String("Frequency : \(String(dataObject.frequency))")
            
            //print(String("Text : \(dataObject.text) and selected text : \(selectedText)") )
            
            if selectedText.lowercased() == dataObject.text.lowercased() {
                cell.backgroundColor = .yellow
            }
            
            return cell
            
        } else {
            return tableView.dequeueReusableCell(withIdentifier: cellsIdentifiers[1], for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return dataArray.count > 0 ? 84: UIScreen.main.bounds.height
    }
}

// MARK: Actions

extension DemoTableViewController {

    @IBAction func backButtonHandler(_: AnyObject) {
        // buttonAnimation
        let viewControllers: [DemoViewController?] = navigationController?.viewControllers.map { $0 as? DemoViewController } ?? []

        for viewController in viewControllers {
            if let rightButton = viewController?.navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(false)
            }
        }
        popTransitionAnimation()
    }
}

// MARK: UIScrollViewDelegate

extension DemoTableViewController {

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -25 , let navigationController = navigationController {
            // buttonAnimation
            for case let viewController as DemoViewController in navigationController.viewControllers {
                if case let rightButton as AnimatingBarButton = viewController.navigationItem.rightBarButtonItem {
                    rightButton.animationSelected(false)
                }
            }
            popTransitionAnimation()
        }
        scrollOffsetY = scrollView.contentOffset.y
    }
}

extension DemoTableViewController {
    
    func fetchAllDictionaryDetails() {
    
      // API end point
      let todoEndpoint: String = "http://a.galactio.com/interview/dictionary-v2.json"
    
      // Data request
      // TO DO - Network checking
        
      AF.request(todoEndpoint).responseData { response in
          switch response.result {
          case .success(let value):
            
              // use swifty json for json parshing
              let json = try? JSON(data: value)
            
              let dataList: Array<JSON> = json!["dictionary"].arrayValue
              for item in dataList {
                // convert to lower case
                let dataString = item["word"].string
                // get data frequency
                let dataFrequency = item["frequency"].int
                // serached data
                
                let searchedData = self.searchForTextFromDatabase(dataString)
                if searchedData != nil {
                    // update frequency if it's changed - data from API - true
                    if self.selectedText.lowercased() == dataString?.lowercased() {
                        self.textAvelebelity = true
                        self.updateTextFrequency(dataString)
                    }
                } else {
                    // new phrase , save into database
                    self.saveTheText(dataString,dataFrequency ?? 0)
                }
              }
            
              // fetch data

              self.dataArray = self.getAllPhrasesFromDatabase()
              self.numberOfRows = self.dataArray.count
              
              self.tableView.isHidden = false
              self.tableView.reloadData()
            
              if !self.textAvelebelity && self.selectedText.count > 0 {
                // create a new style
                var style = ToastStyle()
                style.messageColor = .white
                
                self.view.makeToast("The text is not available in our dictionary!!", duration: 3.0, position: .center, style: style)
              }
            
          case .failure(let error):
              print(error.localizedDescription)
          }
      }
    }
    
    //MARK: DB Actions
    
    // Save data
    func saveTheText(_ text: String?,_ frequency: Int) {
        guard let text = text else {
            return
        }
        
        let newTextItem = SpeechTextItem()
        newTextItem.text = text
        newTextItem.frequency = frequency
        let realm = try! Realm()
        try! realm.write {
            realm.add(newTextItem)
        }
    }
    
    // update data frequency
    func updateTextFrequency(_ text: String?) {
        guard let text = text else {
            return
        }
        
        let realm = try! Realm()
        let predicate = NSPredicate(format: "text contains[c] %@", text)
        let restObject = realm.objects(SpeechTextItem.self).filter(predicate)
        
        if restObject.count > 0 {
            if let SpeechTextItem = restObject.first {
                try! realm.write {
                    SpeechTextItem.frequency = (restObject.first?.frequency ?? 0)+1
                }
            }
        }
    }
    
    // search for existing text in the database
    func searchForTextFromDatabase(_ text:String?)->SpeechTextItem? {
        guard let text = text else {
            return SpeechTextItem()
        }
        
        let realm = try! Realm()
        let predicate = NSPredicate(format: "text contains[c] %@", text)
        let restObject = realm.objects(SpeechTextItem.self).filter(predicate)
        
        return restObject.first
    }
    
    // get all items from database
    func getAllPhrasesFromDatabase()->Array<SpeechTextItem> {
        let realm = try! Realm()
        let allPhrases = realm.objects(SpeechTextItem.self)
        
        var array = [SpeechTextItem]()
        for result in allPhrases {
            array.append(result)
        }
        return array
    }
}

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dictionaryText: UILabel!
    @IBOutlet weak var textFrequency: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}

class loadingViewCell: UITableViewCell {
    @IBOutlet private weak var avatarImageView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
