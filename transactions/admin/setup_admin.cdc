import Necryptolis from "../../contracts/Necryptolis.cdc"

// this transaction adds an ChessCombo admin resource to a second provided account
transaction {
  prepare(acct: AuthAccount, acct2: AuthAccount) {
    let adminRef = acct.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath)
            ?? panic("Could not borrow a reference to the Chess Combo Admin resource")

    if acct2.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath) == nil {
        acct2.save(<- adminRef.createNewAdmin(), to: Necryptolis.NecryptolisAdminStoragePath)  
    }                
  }
}
