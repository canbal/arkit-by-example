//
//  MessageView.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import Foundation
import UIKit

class MessageView : UIVisualEffectView {
    public var currentMessage: String? = nil
    public var nextMessage: String? = nil
    public var timer: Timer? = nil
    
    public func queueMessage(message: String) {
        // If we are currently showing a message, queue the next message. We will show
        // it once the previous message has disappeared. If multiple messages come in
        // we only care about showing the last one
        if (currentMessage != nil) {
            nextMessage = message
            return;
        }
        
        nextMessage = message
        showNextMessage()
    }
    
    func showNextMessage() {
        currentMessage = nextMessage;
        nextMessage = nil;
        
        if (currentMessage == nil) {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.alpha = 0
            }, completion: { finished in return })
            return
        }
        
        let label = contentView.subviews[0] as! UILabel
        label.text = currentMessage

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.alpha = 1
        }, completion: { finished in
            // Wait 5 seconds
            self.timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: { timer in
                self.showNextMessage()
            })
        })
    }
}
