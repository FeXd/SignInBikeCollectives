//
//  Copyright (c) 2015 Momoko Saunders. All rights reserved.
//

import Foundation

class ShopUseLog: NSObject {

    var shopUseLog : [ShopUse]
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    override init(){
        shopUseLog = []
        let fetchRequest = NSFetchRequest(entityName: "ShopUse")
        
        do { if let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [ShopUse] {
                shopUseLog = fetchedResults}
            else {
              assertionFailure("Could not executeFetchRequest")
            }
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        super.init()
    }
    
    func deleteShopUsesForContact(contact: Contact) {
        for shopUse in contact.shopUse! {
            managedObjectContext.deleteObject(shopUse as! NSManagedObject)
        }
    }
    
    func deleteSignalShopUse(shopUse: AnyObject) {
        managedObjectContext.deleteObject(shopUse as! NSManagedObject)
    }
    
    func createShopUseWithContact(contact: Contact, id: Int) {
        let entity = NSEntityDescription.entityForName("ShopUse", inManagedObjectContext: managedObjectContext)
        
        let shopUse = ShopUse(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)

        shopUse.signIn = NSDate()
        shopUse.signOut = NSDate().dateByAddingTimeInterval(2*60*60)
        shopUse.type = TypeLog().getType(id)

        shopUse.contact = contact
        shopUse.contact!.recentUse = shopUse.signOut
        shopUse.contact!.recentUseType = "shopUse"
        ContactLog().saveContact(contact)

        var error: NSError?
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
            print("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    func signOutContact(contact: Contact) {
        // Get the most recent shopUse
        let use = ShopUseLog().getMostRecentShopUseForContact(contact)
        // Set the signOut to now
        use.signOut = NSDate()
        // reset the recentUse time
        contact.recentUse = NSDate()
    }

    // this is just an experiement showing a better way t ouse fetch requests.
    // it's not actually used here.
//    func findMostRecentShopUseForContact(contact: Contact) -> ShopUse {
//        var log = []
//        let recentUseFetchRequest = NSFetchRequest(entityName: "ShopUse")
//        let predicate = NSPredicate(format: "contact == %@ && signOut > NSDate", contact)
//        //let sortDescriptor
//        //set fetch limit, so that the fetch request only returns one.
//        recentUseFetchRequest.predicate = predicate
//        do { if let recentUseFetch = try managedObjectContext.executeFetchRequest(recentUseFetchRequest) as? [ShopUse] {
//            log =  recentUseFetch}
//        else {
//            assertionFailure("Could not executeFetchRequest")
//            }
//        } catch let error as NSError {
//            print("Could not fetch \(error)")
//        }
//        return log.firstObject! as! ShopUse
//    }
    func getShopUsesForContact(contact: Contact) -> [ShopUse] {
        var log = [ShopUse]()
        let FetchRequest = NSFetchRequest(entityName: "ShopUse")
        let predicate = NSPredicate(format: "contact == %@", contact)
        FetchRequest.predicate = predicate
        do { if let FetchedResults = try managedObjectContext.executeFetchRequest(FetchRequest) as? [ShopUse] {
            log = FetchedResults }
        else {
            assertionFailure("Could not executeFetchRequest")
            }
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        // this breaks when you try to logout someone who is not logged in,
        // which you can do from the admin members or volunteers filter
        return log
    }
    
    func getMostRecentShopUseForContact(contact: Contact) -> ShopUse {
        var log = [ShopUse]()
        let FetchRequest = NSFetchRequest(entityName: "ShopUse")
        let predicate = NSPredicate(format: "signOut == %@", contact.recentUse!)
        FetchRequest.predicate = predicate
        do { if let FetchedResults = try managedObjectContext.executeFetchRequest(FetchRequest) as? [ShopUse] {
            log = FetchedResults }
        else {
            assertionFailure("Could not executeFetchRequest")
            }
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        // this breaks when you try to logout someone who is not logged in, 
        // which you can do from the admin members or volunteers filter
        return log[0]
    }
    
    func loggedInContacts() -> [Contact] {
        let loggedInContacts = ContactLog().allContacts
        var newContacts = [Contact]()
        for user in loggedInContacts {
            if user.recentUse!.timeIntervalSinceNow > 0 {
                newContacts.append(user)
            }
        }
        return newContacts
    }
    
    func numberOfHoursLoggedByContact(contact: Contact, typeTitle: String) -> String {
        var totalHoursOfShopUse = 0
        for shopUseHour in contact.shopUse! {
            if shopUseHour.type!!.title! == typeTitle {
                let shopUseInstance = Int(shopUseHour.signIn!!.timeIntervalSinceNow - shopUseHour.signOut!!.timeIntervalSinceNow)
                totalHoursOfShopUse = totalHoursOfShopUse + shopUseInstance
            }
        }
        totalHoursOfShopUse = totalHoursOfShopUse/(60 * 60) * -1
        return String(totalHoursOfShopUse)

    }

    func hourlyTotalForThisMonth(contact: Contact, typeTitle: String) -> String {
        var hourlyTotalForThisMonth = 0
        for shopUseHour in contact.shopUse! {
            if isDateInThisMonth(shopUseHour.signIn!!) && shopUseHour.type!!.title == typeTitle {
                var shopUseInstance = Int(shopUseHour.signIn!!.timeIntervalSinceNow - shopUseHour.signOut!!.timeIntervalSinceNow)
                shopUseInstance = shopUseInstance/(60 * 60) * -1
                hourlyTotalForThisMonth = hourlyTotalForThisMonth + shopUseInstance
            }
        }
        return String(hourlyTotalForThisMonth)
    }
    
    func hourlyTotalForLastMonth(contact: Contact, typeTitle: String) -> String {
        var hourlyTotalForThisMonth = 0
        for shopUseHour in contact.shopUse! {
            if isDateInLastMonth(shopUseHour.signIn!!) && shopUseHour.type!!.title == typeTitle {
                var shopUseInstance = Int(shopUseHour.signIn!!.timeIntervalSinceNow - shopUseHour.signOut!!.timeIntervalSinceNow)
                shopUseInstance = shopUseInstance/(60 * 60) * -1
                hourlyTotalForThisMonth = hourlyTotalForThisMonth + shopUseInstance
            }
        }
        return String(hourlyTotalForThisMonth)
    }

    func isDateInThisMonth(date: NSDate) -> Bool {
        var bool = true
        let calendar = NSCalendar.currentCalendar()
        let thisMonth = calendar.component(.Month, fromDate: NSDate())
        let dateComponets = calendar.component(.Month, fromDate: date)
        if thisMonth == dateComponets {
            bool = true
        } else {
            bool = false
        }
        return bool
    }
    
    func isDateInLastMonth(date: NSDate) -> Bool {
        var bool = true
        let calendar = NSCalendar.currentCalendar()
        let thisMonth = calendar.component(.Month, fromDate: NSDate()) - 1
        let dateComponets = calendar.component(.Month, fromDate: date)
        if thisMonth == dateComponets {
            bool = true
        } else {
            bool = false
        }
        return bool
    }
    
    func contactsOfVolunteers() -> [Contact] {
        var contacts = [Contact]()
        // this is ugly, can i make it better?
        // fetchrequest! nope, that's worse
        let allContacts = ContactLog().allContacts
        // creates duplicates...
        for contact in allContacts {
            if contact.shopUse!.count > 0 {
                for use in contact.shopUse! {
                    if use.type!!.title! == "Volunteer" {
                        contacts.append(contact)
                    }
                }
            }
        }
        return contacts
    }
    
    func contactsOfVolunteer() -> [Contact] {
        var contacts = [Contact]()
        var shopUseArray = [ShopUse]()
        let fetchRequest = NSFetchRequest(entityName: "ShopUse")
        let predicateVolunteerType = NSPredicate(format: "type == %@", TypeLog().getType(1))
        fetchRequest.predicate = predicateVolunteerType
        
        do { if let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [ShopUse] {
            shopUseArray = fetchedResults}
        else {
            assertionFailure("Could not executeFetchRequest")
            }
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        
        for use in shopUseArray {
            contacts.append(use.contact!)
        }
        let unique = Array(Set(contacts))
        
         return unique
    }
}
