/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A collection view displaying a list of products. The list of products is parsed in from a plist.
*/


import UIKit

class CatalogCollectionViewController: UICollectionViewController {
    // MARK: Properties
    
    static let reuseIdentifier = "ProductCell"
    static let segueIdentifier = "ProductDetailSegue"

    lazy var products: [Product] = {
        // Populate the products array from a plist.
        let productsURL = NSBundle.mainBundle().URLForResource("ProductsList", withExtension: "plist")!
        
        let unarchivedProducts = NSArray(contentsOfURL: productsURL) as! [[String: AnyObject]]
        
        return unarchivedProducts.map { Product(dictionary: $0) }
    }()
    
    // MARK: View Life Cycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == CatalogCollectionViewController.segueIdentifier else { return }

        let viewController = segue.destinationViewController as! ProductTableViewController

        guard let indexPath = collectionView?.indexPathsForSelectedItems()?.first else { return }
        
        viewController.product = products[indexPath.row]
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CatalogCollectionViewController.reuseIdentifier, forIndexPath: indexPath) as! ProductCell
    
        // Configure the cell.
        let product = products[indexPath.row]
        cell.titleLabel.text = product.name
        cell.priceLabel.text = product.price
        cell.subtitleLabel.text = product.description
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(CatalogCollectionViewController.segueIdentifier, sender: self)
    }
}
