//
//  String+FormatData.swift
//  NewsReader
//
//  Created by Ivan Ermak on 8/8/19.
//  Copyright © 2019 Ivan Ermak. All rights reserved.
//

import Foundation
extension String {
    func formatDate() -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        let date = dateFormat.date(from: self)!
        let newFormat = DateFormatter()
        newFormat.dateFormat = "HH:mm  dd MMM yyyy"
        let dateString = newFormat.string(from: date)
        return dateString
    }
}
