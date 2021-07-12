//
//  SessionListCell.swift
//  EEChat
//
//  Created by Snow on 2021/5/25.
//

import UIKit
import OpenIM
import OpenIMUI

class SessionListCell: UITableViewCell {
    
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var unreadLabel: UILabel!

    var model: OIMConversation! {
        didSet {
            avatarView.setImage(with: URL(string: model.faceUrl),
                                placeholder: UIImage(named: "icon_default_avatar"))
            nameLabel.text = model.showName
            
            var isDraft = false
            let (timestamp, text): (TimeInterval, String) = {
                if let text = NSAttributedString.from(base64Encoded: model.draftText)?.string, !text.isEmpty {
                    isDraft = true
                    return (model.draftTimestamp, text)
                }
                if let message = model.latestMsg?.toUIMessage() {
                    return (message.sendTime, LocalizedString(message.content.description))
                }
                return (model.draftTimestamp, "")
            }()
            
            if isDraft {
                let prefix = LocalizedString("[Draft]")
                let attributedText = NSMutableAttributedString(string: prefix + text)
                attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: prefix.count))
                contentLabel.attributedText = attributedText
            } else {
                contentLabel.text = text
            }
            timeLabel.text = OIMDateFormatter.shared.format(timestamp)
            
            unreadLabel.superview?.isHidden = model.unreadCount == 0
            unreadLabel.text = model.unreadCount < 99 ? model.unreadCount.description : "99+"
        }
    }
    
}
