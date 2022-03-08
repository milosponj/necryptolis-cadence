import Necryptolis from "../../contracts/Necryptolis.cdc"

transaction(left: Int32, top: Int32, width: UInt16, height: UInt16, recipientAddr: Address) {
  let adminRef: &Necryptolis.Admin?

  prepare(acct: AuthAccount) {
    self.adminRef = acct.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath) ?? panic("No Admin in acct storage")
  }

  execute {   
        // Mint a new NFT
        let cemeteryPlot <- self.adminRef!.mintCemeteryPlot(left: left, top: top, width: width, height: height)

        let recipient = getAccount(recipientAddr)

        let receiverRef = recipient.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()!   

        receiverRef.deposit(token: <- cemeteryPlot)
  }
}
