//
//  SpotListViewController.swift
//  Snacktacular
//
//  Created by Grace Carroll on 3/31/21.
//

import UIKit

class SpotListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    
    var spots = ["Island Creek Oysters", "El Pelon", "Shake Shack", "Pino's Pizza"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        configureSegmentedControl()

    }
    
    func configureSegmentedControl() {
        let orangeFontColor = [NSAttributedString.Key.foregroundColor : UIColor(named: "PrimaryColor") ?? UIColor.orange]
        let whiteFontColor = [NSAttributedString.Key.foregroundColor : UIColor.white]
        sortSegmentedControl.setTitleTextAttributes(orangeFontColor, for: .selected)
        sortSegmentedControl.setTitleTextAttributes(whiteFontColor, for: .normal)
        sortSegmentedControl.layer.borderColor = UIColor.white.cgColor
        sortSegmentedControl.layer.borderWidth = 1.0
         
    }
    
}

extension SpotListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spots.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SpotTableViewCell
        cell.nameLabel?.text = spots[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
}
