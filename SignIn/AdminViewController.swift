//
//  Copyright (c) 2015 Momoko Saunders. All rights reserved.
//

import Foundation
import UIKit

class AdminViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UITabBarControllerDelegate, PersonDetailViewControllerDelegate {
    
    var filteredContacts = [Contact]()
    let contactLog = ContactLog()
    let shopUseLog = ShopUseLog()
    var selectedContact : Contact?
    let organizationLog = OrganizationLog()
    var password = UITextField()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listOfPeopleTableView: UITableView!

    @IBAction func signOutContact(sender: AnyObject) {
        let cell = sender.view as! ContactTableViewCell
        let indexPath = listOfPeopleTableView.indexPathForCell(cell)?.row
        if let index = filteredContacts[indexPath!] as Contact! {
            shopUseLog.signOutContact(index)
            whosInTheShop(self)
        }
    }
    
    @IBAction func whosInTheShop(sender: AnyObject) {
        filteredContacts = usersWhoAreLoggedIn()
        listOfPeopleTableView.reloadData()
    }
    
    @IBAction func allVolunteers(sender: AnyObject) {
        filteredContacts = shopUseLog.contactsOfVolunteer()
        listOfPeopleTableView.reloadData()
    }
    
    @IBAction func currentMembers(sender: AnyObject) {
        filteredContacts = contactLog.currentMembers()
        listOfPeopleTableView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.tabBarController?.delegate = self
    }
    
    override func viewDidLoad() {
        filteredContacts = usersWhoAreLoggedIn()
        let rightBarButton = UIBarButtonItem(image: UIImage(named: "email"), style: .Plain, target: self, action: "showFilterAlert")
        let leftBarButton = UIBarButtonItem(image: UIImage(named: "myAccount"), style: .Plain, target: self, action: "showMyAccountViewController")
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    override func viewDidAppear(animated: Bool) {
        // if user has a password and is coming from the other tab
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Person Detail Segue" {
            let vc = segue.destinationViewController as! PersonDetailViewController
            vc.contact = selectedContact
            vc.delegate = self
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if self.tabBarController?.selectedIndex == 1 && organizationLog.hasPassword() {
            showPassWordAlert()
        }
    }
    
    func showMyAccountViewController() {
        performSegueWithIdentifier("My Account Segue", sender: self)
    }
    
    func showPassWordAlert() {
        let alert = UIAlertController(title: "Password", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Enter Password:"
            textField.secureTextEntry = true
            self.password = textField
        })
        alert.addAction(UIAlertAction(title: "Submit", style: UIAlertActionStyle.Default, handler: { alert in
            if self.password.text != self.organizationLog.organizationLog.first?.password {
                self.tabBarController?.selectedIndex = 0
            }
        }))
        alert.addAction(UIAlertAction(title: "Forgot Password", style: .Default, handler: { alert in
            //send email?
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showFilterAlert() {
        let alert = UIAlertController(title: "Filter", message: "What reports do you want to send?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Contacts", style: UIAlertActionStyle.Default, handler: { alert in
            self.sendData(self, dataType: self.contactLog.returnAllContactsAsCommaSeporatedString())
        }))
        alert.addAction(UIAlertAction(title: "Members", style: UIAlertActionStyle.Default, handler: { alert in
            self.sendData(self, dataType: self.contactLog.returnAllMembersAsCommaSeporatedString())
        }))
        alert.addAction(UIAlertAction(title: "Volunteers", style: UIAlertActionStyle.Default, handler: { alert in
            self.sendData(self, dataType: self.contactLog.returnAllVolunteersAsCommaSeporatedString())
        }))
        alert.addAction(UIAlertAction(title: "Shop Use", style: UIAlertActionStyle.Default, handler: { alert in
            self.sendData(self, dataType: self.shopUseLog.shopUseLogAsCommaSeporatedString())
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // this is a copy of the function used in Sign In, is there a way to move this to ContactLog?
    func usersWhoAreLoggedIn() -> [Contact] {
        var loggedInUsers = [Contact]()
        for contact in ContactLog().allContacts {
            if contact.recentUse!.timeIntervalSinceNow > 0 {
                loggedInUsers.append(contact)
            }
        }
        return loggedInUsers
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.characters.count == 1 && searchText == "" {
            listOfPeopleTableView.reloadData()
        }
        else {
            _searchContactsWithSubstring(searchText)
        }
    }
    
    func _searchContactsWithSubstring(substring: String) {
        let fullContactList = contactLog.allContacts
        let predicate = NSPredicate(format: "firstName BEGINSWITH[cd] %@ OR lastName BEGINSWITH[cd] %@ OR pin BEGINSWITH[cd] %@ OR emailAddress BEGINSWITH[cd] %@", substring, substring, substring, substring)
        filteredContacts = (fullContactList as NSArray).filteredArrayUsingPredicate(predicate) as! [Contact]
        listOfPeopleTableView.reloadData()
    }
    
    func sendData(sender: AnyObject, dataType: String) {
        let fileName = getDocumentsDirectory().stringByAppendingPathComponent("data.csv")
        let activityItem:NSURL = NSURL(fileURLWithPath:fileName)
        var string = ""
        do { try string = String(contentsOfURL: activityItem)
            print(string)
        } catch let error as NSError {
            print("Could not create file \(error)")
        }
        let activityItems = [activityItem]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypeAddToReadingList]
        presentViewController(activityVC, animated: true, completion: nil)
        
        activityVC.completionWithItemsHandler = {activity, success, items, error in
            if !success {
                return
            }
        }
    }
    
    func sendDataFile(sender: AnyObject, dataFile: NSData) {
        let activityItems = [dataFile]
        let activityViewController = UIActivityViewController(activityItems: activityItems as [AnyObject], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePrint, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypeAddToReadingList]
        presentViewController(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = {activity, success, items, error in
            if !success {
                return
            }
        }
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func didMakeChangesToContactOnEditVC() {
        listOfPeopleTableView.reloadData()
    }
}

// Mark: - TableView Delegate -
extension AdminViewController {
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count;
    }
    func tableView(tableView: UITableView!,
        cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
            var cell = ContactTableViewCell()
            cell = listOfPeopleTableView.dequeueReusableCellWithIdentifier("CustomCell") as! ContactTableViewCell
            let contact = filteredContacts[indexPath.row]
            let membership = contact.valueForKey("membership") as? Membership
            var title = contact.valueForKey("firstName") as? String
            if title == "" {
                title = contact.valueForKey("lastName") as? String
            }
            let membershipType = membership?.membershipType
            cell.titleLabel.text = title
            cell.detailLabel.text = membershipType // soon to be minutes of shopUse
           // cell.time.text = ShopUseLog().timeOfCurrentShopUseForContact(contact)
            cell.circleView.image = UIImage(named: "circle")
            cell.circleView.tintColor = contactLog.colourOfContact(contact)
            // add gesture recognizer
            let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: "signOutContact:")
            gestureRecognizer.direction = .Left
            cell.addGestureRecognizer(gestureRecognizer)
            return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedContact = filteredContacts[indexPath.row]
        performSegueWithIdentifier("Person Detail Segue", sender: self)
    }
}
