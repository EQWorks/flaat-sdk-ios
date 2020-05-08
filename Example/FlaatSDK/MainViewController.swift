import UIKit
import FlaatSDK

class MainViewController: UIViewController {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendReportAction(_ sender: UIButton) {
        activityIndicator.startAnimating()
        sender.isEnabled = false

        var reportMetadata = ReportMetadata.default()
        reportMetadata.validationInfo = ["pin": "test-pin"]

        FlaatService.shared.uploadReport(metadata: reportMetadata) { [weak self] (error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                sender.isEnabled = true
                self.activityIndicator.stopAnimating()

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
    }

    @IBAction func checkReportsAction(_ sender: UIButton) {
        activityIndicator.startAnimating()
        sender.isEnabled = false

        FlaatService.shared.downloadAndAnalyzeReports { [weak self] (infectedResult) -> Void in
            DispatchQueue.main.async {
                guard let self = self else { return }
                sender.isEnabled = true
                self.activityIndicator.stopAnimating()

                switch infectedResult {
                case .failure(let error):
                    NSLog("Report download and analysis failed: \(error)")

                    self.showSimpleAlert(title: "Check Failed",
                        message: "An error occurred when downloading and analyzing reports",
                        buttonTitle: "Close")
                case .success(let status):
                    var message = "You contacted someone with COVID-19"
                    if case ExposureStatus.noExposure = status {
                        message = "No contacts with COVID-19 found"
                    }
                    self.showSimpleAlert(title: "Check Completed",
                        message: message,
                        buttonTitle: "Close")

                }
            }
        }
    }

    private func showSimpleAlert(title: String, message: String, buttonTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
}

