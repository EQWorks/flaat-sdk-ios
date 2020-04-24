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

                self.showSimpleAlert(title: "Error",
                    message: "Failed to upload report",
                    buttonTitle: "Close")
            } else {
                NSLog("Report upload succeeded")

                self.showSimpleAlert(title: "Report Upload",
                    message: "Successfully uploaded report",
                    buttonTitle: "Close")
            }
        }
    }

    @IBAction func checkReportsAction(_ sender: UIButton) {
        FlaatService.downloadAndAnalyzeReports { (infected) -> Void in
            DispatchQueue.main.async {
                self.showSimpleAlert(title: "Check Completed",
                    message: infected ? "You contacted someone with COVID-19" : "No contacts with COVID-19 found",
                    buttonTitle: "Close")
            }
        }
    }

    private func showSimpleAlert(title: String, message: String, buttonTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
}

