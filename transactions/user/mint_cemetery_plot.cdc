import Necryptolis from "../../contracts/Necryptolis.cdc"
import FUSD from "../../contracts/FUSD.cdc"

transaction(left: Int32, top: Int32, width: UInt16, height: UInt16, recipientAddr: Address) {
  let plotMinterRef: &Necryptolis.PlotMinter?
  let mainFusdVault: &FUSD.Vault?

  prepare(acct: AuthAccount) {
    self.plotMinterRef = acct.borrow<&Necryptolis.PlotMinter>(from: Necryptolis.PlotMinterStoragePath) ?? panic("No PlotMinter in acct storage")
    self.mainFusdVault = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD vault in acct storage")
  }

  execute {   
        let plotPrice = Necryptolis.getPlotPrice(width: width, height: height, left: left, top: top)
        let paymentVault <- self.mainFusdVault!.withdraw(amount: plotPrice)
        
        let recipient = getAccount(recipientAddr)

        let receiverRef = recipient.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()!   
        // Mint a new NFT
        let cemeteryPlot <- self.plotMinterRef!.mintCemeteryPlot(left: left, top: top, width: width, height: height, buyerPayment: <- paymentVault)

        receiverRef.deposit(token: <- cemeteryPlot)
  }
}
