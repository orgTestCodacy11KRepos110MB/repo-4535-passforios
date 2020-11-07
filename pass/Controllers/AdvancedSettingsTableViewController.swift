//
//  AdvancedSettingsTableViewController.swift
//  pass
//
//  Created by Mingshen Sun on 7/2/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import passKit
import SVProgressHUD
import UIKit

class AdvancedSettingsTableViewController: UITableViewController {
    @IBOutlet var encryptInASCIIArmoredTableViewCell: UITableViewCell!
    @IBOutlet var gitSignatureTableViewCell: UITableViewCell!
    @IBOutlet var eraseDataTableViewCell: UITableViewCell!
    @IBOutlet var discardChangesTableViewCell: UITableViewCell!
    let passwordStore = PasswordStore.shared

    let encryptInASCIIArmoredSwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.onTintColor = Colors.systemBlue
        uiSwitch.sizeToFit()
        uiSwitch.addTarget(self, action: #selector(encryptInASCIIArmoredAction(_:)), for: UIControl.Event.valueChanged)
        return uiSwitch
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        encryptInASCIIArmoredSwitch.isOn = Defaults.encryptInArmored
        encryptInASCIIArmoredTableViewCell.accessoryView = encryptInASCIIArmoredSwitch
        encryptInASCIIArmoredTableViewCell.selectionStyle = .none
        setGitSignatureText()
    }

    private func setGitSignatureText() {
        let gitSignatureName = passwordStore.gitSignatureForNow?.name ?? ""
        let gitSignatureEmail = passwordStore.gitSignatureForNow?.email ?? ""
        gitSignatureTableViewCell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        gitSignatureTableViewCell.detailTextLabel?.text = "\(gitSignatureName) <\(gitSignatureEmail)>"
        if Defaults.gitSignatureName == nil, Defaults.gitSignatureEmail == nil {
            gitSignatureTableViewCell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            gitSignatureTableViewCell.detailTextLabel?.text = "NotSet".localize()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView.cellForRow(at: indexPath) == eraseDataTableViewCell {
            let alert = UIAlertController(title: "ErasePasswordStoreData?".localize(), message: "EraseExplanation.".localize(), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(
                UIAlertAction(title: "ErasePasswordStoreData".localize(), style: UIAlertAction.Style.destructive) { [unowned self] _ -> Void in
                    SVProgressHUD.show(withStatus: "Erasing...".localize())
                    self.passwordStore.erase()
                    self.navigationController!.popViewController(animated: true)
                    SVProgressHUD.showSuccess(withStatus: "Done".localize())
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            )
            alert.addAction(UIAlertAction.dismiss())
            present(alert, animated: true, completion: nil)
        } else if tableView.cellForRow(at: indexPath) == discardChangesTableViewCell {
            let alert = UIAlertController(title: "DiscardAllLocalChanges?".localize(), message: "DiscardExplanation.".localize(), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(
                UIAlertAction(title: "DiscardAllLocalChanges".localize(), style: UIAlertAction.Style.destructive) { [unowned self] _ -> Void in
                    SVProgressHUD.show(withStatus: "Resetting...".localize())
                    do {
                        let numberDiscarded = try self.passwordStore.reset()
                        self.navigationController!.popViewController(animated: true)
                        SVProgressHUD.showSuccess(withStatus: "DiscardedCommits(%d)".localize(numberDiscarded))
                        SVProgressHUD.dismiss(withDelay: 1)
                    } catch {
                        Utils.alert(title: "Error".localize(), message: error.localizedDescription, controller: self, completion: nil)
                    }
                }
            )
            alert.addAction(UIAlertAction.dismiss())
            present(alert, animated: true, completion: nil)
        }
    }

    @objc
    func encryptInASCIIArmoredAction(_: Any?) {
        Defaults.encryptInArmored = encryptInASCIIArmoredSwitch.isOn
    }

    @IBAction
    private func saveGitConfigSetting(segue: UIStoryboardSegue) {
        if let controller = segue.source as? GitConfigSettingsTableViewController {
            if let gitSignatureName = controller.nameTextField.text,
               let gitSignatureEmail = controller.emailTextField.text {
                Defaults.gitSignatureName = gitSignatureName.isEmpty ? nil : gitSignatureName
                Defaults.gitSignatureEmail = gitSignatureEmail.isEmpty ? nil : gitSignatureEmail
            }
            setGitSignatureText()
        }
    }
}
