//
//  NotificationSelectionTableController.swift
//  PreMatch
//
//  Created by Michael Peng on 8/11/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UIKit

class NOSelectionController: UITableViewController {
    var hubDelegate: NotificationHubTransition?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.row == 0) {
            hubDelegate?.transitionTo(identifier: "d")
        }
    }
    
    
}
