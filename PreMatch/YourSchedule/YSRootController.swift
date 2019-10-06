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
    var delegate: YSRootTableDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resourcesDidUpdate()
        table.dataSource = dataSource
        delegate = YSRootTableDelegate(self)
        table.delegate = delegate
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
    // MARK: - Navigation */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? YSBlockDetailController,
            let sendingCell = sender as? YSTableCell,
            let block = sendingCell.block else { return }
        destination.prepare(forBlock: block)
    }

}

class YSRootTableDelegate: NSObject, UITableViewDelegate {
    let rootView: UIViewController
    
    init(_ root: UIViewController) {
        rootView = root
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? YSTableCell else { return }
        cell.handleSelection(view: rootView)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
