import UIKit
import FlaatSDK

class MainViewController: UIViewController {



    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendReportAction(_ sender: UIButton) {
        FlaatService.uploadReport(validationPin: "test-pin") { (error) in
            if let error = error {
                NSLog("Could not upload report: \(error)")
            } else {
                NSLog("Report upload succeeded")
            }
        }
    }
}

