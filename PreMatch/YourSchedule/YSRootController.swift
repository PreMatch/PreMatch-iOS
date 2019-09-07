//
//  YSRootController.swift
//  PreMatch
//
//  Created by Michael Peng on 9/6/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class YSRootController: UIViewController, ResourceUser {
    
    @IBOutlet weak var mustLinkTitle: UILabel!
    @IBOutlet weak var mustLinkSubtitle: UILabel!
    @IBOutlet weak var table: UITableView!
    
    let dataSource = YSRootDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resourcesDidUpdate()
        table.dataSource = dataSource
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        table.dataSource = dataSource
    }
    
    func resourcesDidUpdate() {
        let scheduleExists = ResourceProvider.schedule() != nil
        if scheduleExists {
            table.reloadData()
        }
        
        table.isHidden = !scheduleExists
        mustLinkTitle.isHidden = scheduleExists
        mustLinkSubtitle.isHidden = scheduleExists
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
