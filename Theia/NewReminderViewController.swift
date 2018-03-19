//
//  NewReminderViewController.swift
//  Theia
//
//  Created by Michael Tang on 2/20/18.
//  Copyright © 2018 Michael Tang. All rights reserved.
//

import UIKit

class NewReminderViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate {

    
    @IBOutlet weak var eventTitle: UITextField!
    @IBOutlet weak var remindOnDateSwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var currentDate:Date = Date()
    var reminderInstance:Reminders!
    
    var eventTitleFromSegue:String = ""
    var recognizedText:String = ""
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.eventTitle.text = eventTitleFromSegue
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.eventTitle.delegate = self
        
        
        self.datePicker.setValue(UIColor.white, forKey: "textColor")
        self.datePicker.backgroundColor = UIColor(red: 66/255, green: 66/255, blue: 66/255, alpha: 1)
        
        
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "done"){
            if(!(self.eventTitle.text?.isEmpty)!){
                self.currentDate = Date(timeIntervalSinceNow: TimeInterval(0))
                recognizedText = self.eventTitle.text!
                let timeDifference:Double = self.datePicker.date.timeIntervalSince(self.currentDate)
                
                self.reminderInstance = Reminders(title: recognizedText, timeDifference: timeDifference, notify: remindOnDateSwitch.isOn)
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.eventTitle.resignFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
