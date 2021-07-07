//
//  LaunchGroupChatVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/5.
//

import UIKit
import RxCocoa
import RxDataSources
import OpenIM
import OpenIMUI

class LaunchGroupChatVC: BaseViewController {

    @IBOutlet var memberView: GroupMemberView!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        reqFriend()
        
        memberView.layout.scrollDirection = .horizontal
        memberView.layout.itemSize = CGSize(width: 34, height: 34)
        memberView.layout.sectionInset = UIEdgeInsets(top: 7, left: 22, bottom: 7, right: 22)
        
        memberView.didSelectUser = { [weak self] user in
            guard let self = self else { return }
            for (section, sectionModel) in self.relay.value.enumerated() {
                if let row = sectionModel.items.firstIndex(of: user) {
                    self.tableView.deselectRow(at: IndexPath(row: row, section: section), animated: true)
                    break
                }
            }
        }
    }
    
    
    private let relay = BehaviorRelay<[SectionModel<String, OIMUserInfo>]>(value: [])
    
    private func bindAction() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, OIMUserInfo>>(
            configureCell: { _, tv, _, element in
                let cell = tv.dequeueReusableCell(withIdentifier: "cell")! as! LaunchGroupChatCell
                cell.model = element

                return cell
            },
            canMoveRowAtIndexPath: { _, _ in
                return false
            },
            sectionIndexTitles: { dataSource in
                dataSource.sectionModels.map({ $0.model })
            }
        )
        
        tableView.isEditing = true
        tableView.register(AddressBookHeaderView.eec.nib(), forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(LaunchGroupChatCell.eec.nib(), forCellReuseIdentifier: "cell")
        
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        relay
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(OIMUserInfo.self)
            .subscribe(onNext: { [unowned self] model in
                self.memberView.add(user: model)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.modelDeselected(OIMUserInfo.self)
            .subscribe(onNext: { model in
                self.memberView.remove(user: model)
            })
            .disposed(by: disposeBag)
    }
    
    private func reqFriend() {
        rxRequest(showError: false, callback: { OIMManager.getFriendList($0) })
            .subscribe(onSuccess: { [unowned self] array in
                self.refresh(array: array)
            })
            .disposed(by: disposeBag)
    }
    
    private func refresh(array: [OIMUserInfo]) {
        let items = array
            .sorted(by: { (model0, model1) -> Bool in
                return model0.getName() < model1.getName()
            })
            .reduce(into: [String: SectionModel<String, OIMUserInfo>](), { (result, model) in
                let key: String = {
                    let name = model.getName()
                    if name.count > 0 {
                        let first = String(name.first!)
                        if Int(first) == nil {
                            return String(first.eec_pinyin().first!)
                        }
                    }
                    return "*"
                }()

                if result[key] == nil {
                    result[key] = SectionModel<String, OIMUserInfo>(model: key, items: [])
                }
                result[key]!.items.append(model)
            })
            .reduce(into: [SectionModel<String, OIMUserInfo>]()) { (result, args) in
                let (_, value) = args
                result.append(value)
            }
            .sorted { (model0, model1) -> Bool in
                return model0.model < model1.model
            }
        
        relay.accept(items)
    }
    
    @IBAction func completeAction() {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        let uids = indexPaths.map { indexPath -> String in
            let section = relay.value[indexPath.section]
            return section.items[indexPath.row].uid
        }
        let param = OIMGroupInfoParam(groupName: "", notification: "", introduction: "", faceUrl: "")
        rxRequest(showLoading: true, callback: { OIMManager.createGroup(param, uids: uids, callback: $0) })
            .subscribe(onSuccess: { gid in
                EEChatVC.show(groupID: gid, popCount: 1)
            })
            .disposed(by: disposeBag)
        
    }
    
}

extension LaunchGroupChatVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as! AddressBookHeaderView
        view.titleLabel.text = relay.value[section].model
        return view
    }
}