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

    @IBAction func checkReportsAction(_ sender: UIButton) {
        FlaatService.downloadAndAnalyzeReports { (infected) -> Void in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Check Completed",
                    message: infected ? "You contacted someone with COVID-19" : "No contacts with COVID-19 found", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))

                self.present(alert, animated: true)
            }
        }
    }
}

