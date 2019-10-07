//
//  ControlsViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

//
//  LightViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 12/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import MBProgressHUD
import UIKit

class ControlListViewController: UIViewController {
    var device: Device?

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.title = "Controls"
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")

        let colors = Colors()
        view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.controlLayer
        backgroundLayer!.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)

        updateDeviceAttributes()
    }

    func updateDeviceAttributes() {
        showLoader(message: "Getting info")
        NetworkManager.shared.getDeviceThingShadow(nodeID: (device?.node_id)!) { response in
            if let image = response {
                if let dynamicParams = self.device?.dynamicParams {
                    for index in dynamicParams.indices {
                        if let reportedValue = image[dynamicParams[index].name ?? ""] {
                            dynamicParams[index].value = reportedValue
                        }
                    }
                }
                if let staticParams = self.device?.staticParams {
                    for index in staticParams.indices {
                        if let reportedValue = image[staticParams[index].name ?? ""] {
                            staticParams[index].value = reportedValue
                        }
                    }
                }
            }
            Utility.hideLoader(view: self.view)
            self.tableView.reloadData()
        }
    }

    func showLoader(message: String) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.backgroundView.blurEffectStyle = .dark
            loader.bezelView.backgroundColor = UIColor.white
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
    @objc func setBrightness(_: UISlider) {}

    func getTableViewGenericCell<Element>(attribute: Attribute, indexPath: IndexPath) -> GenericControlTableViewCell<Element> {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell<Element>
        cell.controlName.text = attribute.name
        cell.controlValue = attribute.value as? Element
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: DynamicAttribute, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == "esp-ui-slider" || dynamicAttribute.bounds != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
            if let bounds = dynamicAttribute.bounds {
                cell.slider.value = dynamicAttribute.value as? Float ?? 100
                cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                cell.slider.maximumValue = bounds["max"] as? Float ?? 100
            }
            cell.device = device
            cell.dataType = dynamicAttribute.dataType
            if let attributeName = dynamicAttribute.name {
                cell.attributeKey = attributeName
            }
            cell.sliderValue.text = cell.attributeKey + ": \(Int(cell.slider.value))"
            return cell
        } else if dynamicAttribute.uiType == "esp-ui-toggle" || dynamicAttribute.dataType?.lowercased() == "bool" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.controlName.text = dynamicAttribute.name
            cell.device = device
            if let attributeName = dynamicAttribute.name {
                cell.attributeKey = attributeName
            }
            if let switchState = dynamicAttribute.value as? Bool {
                cell.toggleSwitch.setOn(switchState, animated: true)
            }

            return cell
        } else {
            if dynamicAttribute.dataType?.lowercased() == "int" {
                let cell: GenericControlTableViewCell<Int> = getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                return cell
            } else if dynamicAttribute.dataType?.lowercased() == "bool" {
                let cell: GenericControlTableViewCell<Bool> = getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                return cell
            } else if dynamicAttribute.dataType?.lowercased() == "float" {
                let cell: GenericControlTableViewCell<Float> = getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                return cell
            } else {
                let cell: GenericControlTableViewCell<String> = getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                return cell
            }
        }
    }
}

extension ControlListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 12))
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
}

extension ControlListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (device?.dynamicParams?.count ?? 0) + (device?.staticParams?.count ?? 0)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= device?.dynamicParams?.count ?? 0 {
            let staticControl = device?.staticParams![indexPath.section - (device?.dynamicParams?.count ?? 0)]
            if staticControl?.dataType?.lowercased() == "int" {
                let cell: GenericControlTableViewCell<Int> = getTableViewGenericCell(attribute: staticControl!, indexPath: indexPath)
                return cell
            } else if staticControl?.dataType?.lowercased() == "bool" {
                let cell: GenericControlTableViewCell<Bool> = getTableViewGenericCell(attribute: staticControl!, indexPath: indexPath)
                return cell
            } else if staticControl?.dataType?.lowercased() == "float" {
                let cell: GenericControlTableViewCell<Float> = getTableViewGenericCell(attribute: staticControl!, indexPath: indexPath)
                return cell
            } else {
                let cell: GenericControlTableViewCell<String> = getTableViewGenericCell(attribute: staticControl!, indexPath: indexPath)
                return cell
            }
        } else {
            let control = device?.dynamicParams![indexPath.section]
            return getTableViewCellBasedOn(dynamicAttribute: control!, indexPath: indexPath)
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 80.0
    }
}
