//
//  QueryViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/24/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class QueryViewController: UIViewController {

    //MARK: Properties
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let calendar = ResourceProvider.calendar() {
            datePicker.minimumDate = calendar.interval.start
            datePicker.maximumDate = calendar.interval.end
        }
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
