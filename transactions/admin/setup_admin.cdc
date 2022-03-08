import Necryptolis from "../../contracts/Necryptolis.cdc"


// this transaction adds a Necryptolis admin resource to a second provided account
transaction {
  prepare(acct: AuthAccount, newAdmin: AuthAccount) {
    let adminRef = acct.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath)
            ?? panic("Could not borrow a reference to the Necryptolis Admin resource")
    newAdmin.save(<- adminRef.createNewAdmin(), to: Necryptolis.NecryptolisAdminStoragePath)              
  }
}
