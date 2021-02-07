//
//  FolderTreeCell.swift
//  Vienna
//
//  Copyright 2017 Joshua Pore
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa

class FolderTreeCell: NSTableCellView {
    
    @IBOutlet weak var refreshProgressIndicator: NSProgressIndicator?
    @IBOutlet weak var auxiliaryImageView: NSImageView?
    @IBOutlet weak var stackView: NSStackView?
    @IBOutlet weak var unreadCountButton: NSButton?
    
    @objc var inProgress = false {
        didSet {
            if (inProgress == true) {
                auxiliaryImageView?.image = nil
                stackView?.views[3].isHidden = true
                stackView?.views[4].isHidden = false
                refreshProgressIndicator?.startAnimation(nil)
            } else {
                refreshProgressIndicator?.stopAnimation(nil)
                stackView?.views[4].isHidden = true
            }
        }
    }
    
    @objc var didError = false {
        didSet {
            if (didError == true) {
                auxiliaryImageView?.image = #imageLiteral(resourceName: "folderError.tiff")
                stackView?.views[3].isHidden = false
                
            } else {
                auxiliaryImageView?.image = nil
                stackView?.views[3].isHidden = true
            }
        }
    }
    
    @objc var unreadCount = 0 {
        didSet {
            unreadCountButton?.title = "\(unreadCount)"
            if (unreadCount > 0) {
                stackView?.views[2].isHidden = false
            } else {
                stackView?.views[2].isHidden = true
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
