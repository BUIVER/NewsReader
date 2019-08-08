//
//  NewsCell.swift
//  News Reader
//
//  Created by Alexey on 10.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit

class NewsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = ""
        self.descriptionLabel.text = ""
        self.dateLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func fillNewsCell(_ item: Item) {
        self.titleLabel.text = item.title
        self.descriptionLabel.text = item.minifiedDescription
        self.dateLabel.text = item.date?.formatDate()
    }
}

