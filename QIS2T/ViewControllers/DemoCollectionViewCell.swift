//
//  DemoCollectionViewCell.swift
//  QIS2T
//
//  Created by Santanu Das Adhikary. on 24/12/19.
//  Copyright © 2019 Santanu Das Adhikary. All rights reserved.
//

import UIKit

class DemoCollectionViewCell: BasePageCollectionCell {

    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var customTitle: UILabel!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet var microphoneStatusTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        customTitle.layer.shadowRadius = 2
        customTitle.layer.shadowOffset = CGSize(width: 0, height: 3)
        customTitle.layer.shadowOpacity = 0.2
    }
}
