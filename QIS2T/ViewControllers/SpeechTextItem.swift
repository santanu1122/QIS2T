//
//  SpeechTextItem.swift
//  QIS2T
//
//  Created by Santanu Das Adhikary. on 24/12/19.
//  Copyright © 2019 Santanu Das Adhikary. All rights reserved.
//

import RealmSwift

class SpeechTextItem: Object {
    @objc dynamic var text = ""
    @objc dynamic var frequency = 0
    
    convenience init(text: String, frequency:Int) {
        self.init()
        self.text = text
        self.frequency = frequency
    }
}
