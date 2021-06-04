//
//  DecriptedViewController.swift
//  JWTDesktopSwift
//
//  Created by Lobanov Dmitry on 01.10.16.
//  Copyright © 2016 JWTIO. All rights reserved.
//

import Cocoa
import JWT
import JWTDesktopSwiftToolkit
//import JW

class DecriptedViewController: NSViewController {
    // MARK: - Outlets
    @IBOutlet weak var collectionView: NSCollectionView!

    // MARK: - CollectionView Convenients
    let collectionViewItemIdentifier = NSUserInterfaceItemIdentifier(NSStringFromClass(DecriptedCollectionViewItem.self))

    // MARK: - Builder
    var builder : JWTBuilder? {
        didSet {
            self.reloadData()
            self.reloadCollectionView()
        }
    }
    
    // MARK: - ResultType
    var resultType: JWTCodingResultType? {
        didSet {
            self.reloadData()
            self.reloadCollectionView()
        }
    }
    
    // MARK: - Cached vars
    var cachedResultArray : [[String: Any]]?
    var cachedErrorDictionary : [String: String]?

    // MARK: - Texts vars
    var errorText: String { return String.json(cachedErrorDictionary) }
    var headerText: String { return String.json(cachedResultArray?[0]) }
    var payloadText: String { return String.json(cachedResultArray?[1]) }
    
    // MARK: - Setup
    func setupUIElements() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.minItemSize = NSZeroSize
        self.collectionView.maxItemSize = NSZeroSize
        self.collectionView.register(DecriptedCollectionViewItem.self, forItemWithIdentifier: self.collectionViewItemIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUIElements()
        NotificationCenter.default.addObserver(self, selector: #selector(DecriptedViewController.reload), name: NSWindow.didResizeNotification, object: nil)
    }
    
    // MARK: - Reload
    @objc func reload() {
        reloadCollectionView()
    }
    func reloadCollectionView() {
        self.collectionView.reloadData()
    }
    func reloadData() {
        self.cachedResultArray = nil
        self.cachedErrorDictionary = nil
        if let resultType = self.resultType {
            if let successResult = resultType.successResult, let dictionary = successResult.headerAndPayloadDictionary {
                let serializer = JWTClaimsSetSerializerBase.init()
                serializer.skipClaimsProviderLookupCheck = true
                let value = successResult.claimsSetStorage.flatMap(serializer.dictionary)
                self.cachedResultArray = [
                    ["header" : dictionary[JWTCodingResultComponents.headers!] ?? ""],
                    ["payload": dictionary[JWTCodingResultComponents.payload!] ?? ""],
                    ["claims": value ?? ""]
                ]
            }
            else {
                let errorDescription = resultType.errorResult?.error?.localizedDescription ?? "UnknownError! Report about it!"
                self.cachedErrorDictionary = [
                    "error" : errorDescription
                ]
            }
        }
        else {
            let result = self.builder?.decode
            if let error = self.builder?.jwtError {
                self.cachedErrorDictionary = [
                    "Error" : error.localizedDescription
                ]
            }
            else if let dictionary = result {
                self.cachedResultArray = [
                    ["header" : dictionary["header"] ?? ""],
                    ["payload" : dictionary["payload"] ?? ""]
                ]
            }
        }
    }
    
    // MARK: - Collection Helpers.
    func textForItem(indexPath: IndexPath) -> String {
        var text : String = ""
        
        if self.cachedErrorDictionary != nil {
            text = self.errorText
        }
        else if self.cachedResultArray != nil {
            text = String.json(cachedResultArray?[indexPath.item])
        }
        
        return text
    }
    
    func color(indexPath: IndexPath) -> NSColor {
        var color = NSColor.black
        if self.cachedErrorDictionary != nil {
            color = TokenTextType.header.color
        }
        else if (self.cachedResultArray != nil) {
            color = (indexPath.item == 0 ? TokenTextType.header : TokenTextType.payload).color
        }
        return color
    }
}

extension DecriptedViewController {
    func countOfItems() -> Int {
        if self.cachedErrorDictionary != nil {
            return 1
        }
        else if let array = self.cachedResultArray {
            return array.count
        }
        else {
            return 0
        }
    }
}

extension DecriptedViewController : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        let stringToDisplay = self.textForItem(indexPath: indexPath)
        let width = collectionView.frame.size.width
        let estimatedSize = (stringToDisplay as NSString).boundingRect(with: CGSize(width:width, height: 10000), options: [NSString.DrawingOptions.usesLineFragmentOrigin, NSString.DrawingOptions.usesFontLeading], attributes: nil)
        let height = estimatedSize.size.height
        let size = CGSize(width:width, height:height)
        return size
    }
}

extension DecriptedViewController : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.countOfItems()
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: self.collectionViewItemIdentifier, for: indexPath)
        
        let decriptedItem = item as! DecriptedCollectionViewItem;

        decriptedItem.update(text: self.textForItem(indexPath: indexPath))
        decriptedItem.update(textColor: self.color(indexPath: indexPath))
        
        return item;
    }
}
