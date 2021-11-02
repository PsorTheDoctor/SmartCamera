//
//  HomeViewController.swift
//  SmartCamera
//
//  Created by Adam Wolkowycki on 01/11/2021.
//

import UIKit

class HomeViewController: UIViewController, UISearchResultsUpdating {
    
    let SearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SearchController.searchResultsUpdater = self
        navigationItem.searchController = SearchController
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // guard let text = searchController.searchBar.text else { return }
    }
}
